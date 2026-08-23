#include "mod_catalog.h"
#include "mod_runtime.h"

#include <filesystem>
#include <fstream>
#include <cstdlib>
#include <iostream>
#include <string>
#include <vector>

namespace fs = std::filesystem;

namespace {

int failures = 0;

void check(bool condition, const char *message) {
    if (!condition) {
        std::cerr << "FAIL: " << message << "\n";
        ++failures;
    }
}

void writeFile(const fs::path &path, const std::string &contents) {
    fs::create_directories(path.parent_path());
    std::ofstream out(path);
    out << contents;
}

void writeManifest(const fs::path &root, const std::string &folder,
                   const std::string &id, const std::string &name) {
    writeFile(root / folder / "manifest.toml",
              "manifest_version = 1\n"
              "id = \"" + id + "\"\n"
              "name = \"" + name + "\"\n"
              "version = \"0.1.0\"\n"
              "entrypoint = \"main.lua\"\n");
}

}  // namespace

int main() {
    const fs::path root = fs::temp_directory_path() / "mgb64-mod-runtime-test";
    std::error_code ec;
    fs::remove_all(root, ec);

    writeManifest(root, "safe", "example.safe", "Safe API Test");
    writeFile(root / "safe" / "main.lua",
              "return function(api)\n"
              "  assert(api.mod_id == 'example.safe')\n"
              "  assert(type(api.log) == 'function')\n"
              "  assert(type(api.game.unlock_all_levels) == 'function')\n"
              "  assert(os == nil and io == nil and package == nil and debug == nil)\n"
              "  assert(dofile == nil and loadfile == nil and load == nil and require == nil)\n"
              "  api.game.unlock_all_levels(true)\n"
              "  api.log('sandbox checks passed')\n"
              "end\n");

    const char *priorUnlockRaw = std::getenv("GE007_UNLOCK_ALL_LEVELS");
    const bool hadPriorUnlock = priorUnlockRaw != nullptr;
    const std::string priorUnlock = priorUnlockRaw ? priorUnlockRaw : "";

    modplatform::ModCatalog catalog = modplatform::scanCatalog(root.string());
    modplatform::ModSession session;
    modplatform::ModLoadReport report = session.load(catalog, {"example.safe"});
    check(report.ok(), "safe package should load");
    check(report.loaded == 1 && session.size() == 1, "one isolated state should remain active");
    check(std::getenv("GE007_UNLOCK_ALL_LEVELS") &&
              std::string(std::getenv("GE007_UNLOCK_ALL_LEVELS")) == "1",
          "semantic unlock operation should apply for the live session");
    session.unload();
    const char *restoredUnlock = std::getenv("GE007_UNLOCK_ALL_LEVELS");
    check(hadPriorUnlock ? restoredUnlock && priorUnlock == restoredUnlock : restoredUnlock == nullptr,
          "session unload should restore host state");

    writeManifest(root, "timeout", "example.timeout", "Time Budget Test");
    writeFile(root / "timeout" / "main.lua",
              "return function(api)\n"
              "  while true do end\n"
              "end\n");
    catalog = modplatform::scanCatalog(root.string());
    report = session.load(catalog, {"example.safe", "example.timeout"});
    check(!report.ok(), "runaway setup should fail");
    check(report.loaded == 0 && session.size() == 0, "failed transaction should unload earlier states");
    if (!report.problems.empty()) {
        check(report.problems[0].message.find("time budget") != std::string::npos,
              "runaway failure should name the time budget");
    }

    report = session.load(catalog, {"example.missing"});
    check(!report.ok() && session.size() == 0, "missing enabled package should fail closed");

    writeManifest(root, "memory", "example.memory", "Memory Budget Test");
    writeFile(root / "memory" / "main.lua",
              "return function(api)\n"
              "  local chunks = {}\n"
              "  for i = 1, 20000 do chunks[i] = string.rep('x', 1024) end\n"
              "end\n");
    catalog = modplatform::scanCatalog(root.string());
    report = session.load(catalog, {"example.memory"});
    check(!report.ok() && session.size() == 0, "memory abuse should fail within the state quota");

    fs::remove_all(root, ec);
    if (failures) return 1;
    std::cout << "mod runtime tests passed\n";
    return 0;
}
