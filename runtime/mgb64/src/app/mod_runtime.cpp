#include "mod_runtime.h"

extern "C" {
#include <lauxlib.h>
#include <lua.h>
#include <lualib.h>
}

#include <algorithm>
#include <chrono>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <iterator>
#include <memory>
#include <set>
#include <string>
#include <vector>

namespace modplatform {
namespace {

constexpr size_t kLuaMemoryLimit = 8 * 1024 * 1024;
constexpr auto kLuaSetupBudget = std::chrono::milliseconds(250);

void setProcessEnv(const char *key, const char *value) {
#if defined(_WIN32)
    _putenv_s(key, value ? value : "");
#else
    if (value) setenv(key, value, 1);
    else unsetenv(key);
#endif
}

struct HostMutations {
    bool unlockCaptured = false;
    bool unlockHadValue = false;
    std::string unlockPrevious;

    void setUnlockAllLevels(bool enabled) {
        if (!unlockCaptured) {
            if (const char *value = std::getenv("GE007_UNLOCK_ALL_LEVELS")) {
                unlockHadValue = true;
                unlockPrevious = value;
            }
            unlockCaptured = true;
        }
        setProcessEnv("GE007_UNLOCK_ALL_LEVELS", enabled ? "1" : nullptr);
    }

    void restore() {
        if (unlockCaptured) {
            setProcessEnv("GE007_UNLOCK_ALL_LEVELS",
                          unlockHadValue ? unlockPrevious.c_str() : nullptr);
        }
        unlockCaptured = false;
        unlockHadValue = false;
        unlockPrevious.clear();
    }
};

struct LuaState {
    lua_State *state = nullptr;
    size_t allocated = 0;
    size_t memoryLimit = kLuaMemoryLimit;
    std::chrono::steady_clock::time_point deadline;

    ~LuaState() {
        if (state) lua_close(state);
    }
};

void *boundedAlloc(void *user, void *ptr, size_t oldSize, size_t newSize) {
    LuaState &owner = *static_cast<LuaState *>(user);
    if (newSize == 0) {
        std::free(ptr);
        if (ptr) owner.allocated = oldSize > owner.allocated ? 0 : owner.allocated - oldSize;
        return nullptr;
    }
    const size_t base = !ptr ? owner.allocated
                             : (oldSize > owner.allocated ? 0 : owner.allocated - oldSize);
    if (newSize > owner.memoryLimit || base > owner.memoryLimit - newSize) return nullptr;
    void *next = std::realloc(ptr, newSize);
    if (next) owner.allocated = base + newSize;
    return next;
}

void budgetHook(lua_State *state, lua_Debug * /*debug*/) {
    LuaState *owner = *static_cast<LuaState **>(lua_getextraspace(state));
    if (owner && std::chrono::steady_clock::now() > owner->deadline) {
        luaL_error(state, "mod setup exceeded the 250 ms time budget");
    }
}

void removeGlobal(lua_State *state, const char *name) {
    lua_pushnil(state);
    lua_setglobal(state, name);
}

void openSafeLibraries(lua_State *state) {
    luaL_requiref(state, "_G", luaopen_base, 1);
    lua_pop(state, 1);
    luaL_requiref(state, LUA_TABLIBNAME, luaopen_table, 1);
    lua_pop(state, 1);
    luaL_requiref(state, LUA_STRLIBNAME, luaopen_string, 1);
    lua_pop(state, 1);
    luaL_requiref(state, LUA_MATHLIBNAME, luaopen_math, 1);
    lua_pop(state, 1);
    luaL_requiref(state, LUA_UTF8LIBNAME, luaopen_utf8, 1);
    lua_pop(state, 1);

    // No filesystem, process, module loader, dynamic code loader, or debug API.
    removeGlobal(state, "dofile");
    removeGlobal(state, "loadfile");
    removeGlobal(state, "load");
    removeGlobal(state, "require");
    removeGlobal(state, "package");
    removeGlobal(state, "io");
    removeGlobal(state, "os");
    removeGlobal(state, "debug");
}

int apiLog(lua_State *state) {
    const char *modId = lua_tostring(state, lua_upvalueindex(1));
    const char *message = luaL_checkstring(state, 1);
    std::fprintf(stderr, "[MOD %s] %s\n", modId ? modId : "?", message);
    return 0;
}

int apiUnlockAllLevels(lua_State *state) {
    HostMutations *host = static_cast<HostMutations *>(lua_touserdata(state, lua_upvalueindex(1)));
    luaL_checktype(state, 1, LUA_TBOOLEAN);
    if (host) host->setUnlockAllLevels(lua_toboolean(state, 1) != 0);
    return 0;
}

void pushApi(lua_State *state, const std::string &modId, HostMutations *host) {
    lua_newtable(state);
    lua_pushlstring(state, modId.data(), modId.size());
    lua_setfield(state, -2, "mod_id");
    lua_pushlstring(state, modId.data(), modId.size());
    lua_pushcclosure(state, apiLog, 1);
    lua_setfield(state, -2, "log");

    lua_newtable(state);
    lua_pushlightuserdata(state, host);
    lua_pushcclosure(state, apiUnlockAllLevels, 1);
    lua_setfield(state, -2, "unlock_all_levels");
    lua_setfield(state, -2, "game");
}

bool loadOne(const ModManifest &manifest, HostMutations *host,
             std::unique_ptr<LuaState> &out, std::string &error) {
    auto owner = std::make_unique<LuaState>();
#if LUA_VERSION_NUM >= 505
    const auto ticks = std::chrono::steady_clock::now().time_since_epoch().count();
    const unsigned seed = static_cast<unsigned>(ticks ^ reinterpret_cast<std::uintptr_t>(owner.get()));
    owner->state = lua_newstate(boundedAlloc, owner.get(), seed);
#else
    owner->state = lua_newstate(boundedAlloc, owner.get());
#endif
    if (!owner->state) {
        error = "could not create bounded Lua state";
        return false;
    }
    *static_cast<LuaState **>(lua_getextraspace(owner->state)) = owner.get();
    openSafeLibraries(owner->state);
    owner->deadline = std::chrono::steady_clock::now() + kLuaSetupBudget;
    lua_sethook(owner->state, budgetHook, LUA_MASKCOUNT, 10000);

    const std::filesystem::path entry =
        std::filesystem::path(manifest.directory) / manifest.entrypoint;
    std::error_code fileError;
    const uintmax_t entrySize = std::filesystem::file_size(entry, fileError);
    if (fileError || entrySize > 256 * 1024) {
        error = fileError ? "could not read Lua entrypoint: " + fileError.message()
                          : "Lua entrypoint exceeds the 256 KiB limit";
        return false;
    }
    std::ifstream input(entry, std::ios::binary);
    const std::string source((std::istreambuf_iterator<char>(input)),
                             std::istreambuf_iterator<char>());
    if (source.size() != entrySize) {
        error = "could not read the complete Lua entrypoint";
        return false;
    }
    if (luaL_loadbufferx(owner->state, source.data(), source.size(),
                         entry.string().c_str(), "t") != LUA_OK ||
        lua_pcall(owner->state, 0, 1, 0) != LUA_OK) {
        error = lua_tostring(owner->state, -1) ? lua_tostring(owner->state, -1)
                                               : "unknown Lua entrypoint error";
        return false;
    }

    if (lua_isfunction(owner->state, -1)) {
        // Function-returning entries receive the same API as table.on_load.
    } else if (lua_istable(owner->state, -1)) {
        lua_getfield(owner->state, -1, "on_load");
        lua_remove(owner->state, -2);
        if (!lua_isfunction(owner->state, -1)) {
            error = "entrypoint table must define on_load(api)";
            return false;
        }
    } else {
        error = "entrypoint must return a function or a table with on_load(api)";
        return false;
    }

    pushApi(owner->state, manifest.id, host);
    if (lua_pcall(owner->state, 1, 0, 0) != LUA_OK) {
        error = lua_tostring(owner->state, -1) ? lua_tostring(owner->state, -1)
                                               : "unknown Lua on_load error";
        return false;
    }
    lua_sethook(owner->state, nullptr, 0, 0);
    out = std::move(owner);
    return true;
}

}  // namespace

struct ModSession::Impl {
    std::vector<std::unique_ptr<LuaState>> states;
    HostMutations host;
};

ModSession::ModSession() : impl_(std::make_unique<Impl>()) {}
ModSession::~ModSession() = default;

ModLoadReport ModSession::load(const ModCatalog &catalog,
                               const std::vector<std::string> &enabledIds) {
    unload();
    ModLoadReport report;
    const std::set<std::string> enabled(enabledIds.begin(), enabledIds.end());
    for (const std::string &id : enabled) {
        auto found = std::find_if(catalog.mods.begin(), catalog.mods.end(),
            [&](const ModManifest &manifest) { return manifest.id == id; });
        if (found == catalog.mods.end()) {
            report.problems.push_back({catalog.root, "enabled mod is missing or invalid: " + id});
            break;
        }
        std::unique_ptr<LuaState> state;
        std::string error;
        if (!loadOne(*found, &impl_->host, state, error)) {
            report.problems.push_back({found->directory, "failed to load '" + id + "': " + error});
            break;
        }
        impl_->states.push_back(std::move(state));
    }
    if (!report.ok()) {
        unload();
        report.loaded = 0;
        return report;
    }
    report.loaded = impl_->states.size();
    return report;
}

void ModSession::unload() {
    impl_->states.clear();
    impl_->host.restore();
}

size_t ModSession::size() const {
    return impl_->states.size();
}

}  // namespace modplatform
