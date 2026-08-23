// ui_mods.cpp — launcher surface for local, asset-free mod packages.
#include "ui_launcher.h"
#include "app_config.h"
#include "app_theme.h"
#include "mod_catalog.h"
#include "ui_common.h"

#include "imgui.h"
#include <SDL.h>

#include <cstdlib>
#include <filesystem>
#include <algorithm>
#include <string>

namespace {

modplatform::ModCatalog gCatalog;

bool isEnabled(const LauncherState &state, const std::string &id) {
    return std::find(state.enabledMods.begin(), state.enabledMods.end(), id) != state.enabledMods.end();
}

void setEnabled(LauncherState &state, const std::string &id, bool enabled) {
    auto found = std::find(state.enabledMods.begin(), state.enabledMods.end(), id);
    if (enabled && found == state.enabledMods.end()) state.enabledMods.push_back(id);
    if (!enabled && found != state.enabledMods.end()) state.enabledMods.erase(found);
    AppConfig::set("mod_enabled." + id, enabled ? "1" : "0");
    AppConfig::save();
}

void refreshCatalog(LauncherState &state, modplatform::ModCatalog &catalog) {
    state.modsRoot = modplatform::configuredModsRoot();
    catalog = modplatform::scanCatalog(state.modsRoot);
    state.enabledMods.clear();
    AppConfig::load();
    const bool enableAll = std::getenv("MGB64_MODS_ENABLE_ALL") != nullptr;
    for (const modplatform::ModManifest &mod : catalog.mods) {
        if (enableAll || AppConfig::get("mod_enabled." + mod.id, "0") == "1")
            state.enabledMods.push_back(mod.id);
    }
}

void openModsFolder(const std::string &root) {
    namespace fs = std::filesystem;
    std::error_code ec;
    fs::create_directories(root, ec);
    if (ec) return;
    const std::string absolute = fs::absolute(root, ec).generic_string();
    const std::string url = absolute.empty() || absolute.front() != '/'
        ? "file:///" + absolute
        : "file://" + absolute;
    if (!ec) SDL_OpenURL(url.c_str());
}

}  // namespace

void ModsPanel_ensureInit(LauncherState &s) {
    if (s.modsInitialized) return;
    refreshCatalog(s, gCatalog);
    s.modsInitialized = true;
}

void ModsPanel_draw(LauncherState &s, LauncherAction & /*out*/) {
    ModsPanel_ensureInit(s);
    modplatform::ModCatalog &catalog = gCatalog;

    ui::SectionHeader("Mods", "Discover local Lua packages now; sandboxed execution is the next milestone.");
    if (ImGui::Button("Open Mods Folder", ui::kBtnSecondary())) openModsFolder(s.modsRoot);
    ImGui::SameLine();
    if (ImGui::Button("Refresh", ImVec2(120, ui::kBtnSecondary().y))) {
        refreshCatalog(s, catalog);
    }
    ui::Gap(ui::kGapXS);
    ui::TextSubtle("Folder: %s", s.modsRoot.c_str());
    ui::TextSubtle("Only checked packages execute when Play is pressed. Each receives an isolated, bounded Lua state.");
    ui::Gap(ui::kGapM);

    if (catalog.mods.empty() && catalog.problems.empty()) {
        ImGui::TextUnformatted("No mods found");
        ui::Gap(ui::kGapXS);
        ui::TextSubtle("Add a package folder containing manifest.toml and a Lua entrypoint, then refresh.");
    }

    for (size_t i = 0; i < catalog.mods.size(); ++i) {
        const modplatform::ModManifest &mod = catalog.mods[i];
        const std::string cardId = "##mod-" + std::to_string(i);
        if (ui::CardBegin(cardId.c_str(), AppTheme::primary(), 132.0f)) {
            bool enabled = isEnabled(s, mod.id);
            const std::string checkboxId = "Enabled##" + mod.id;
            if (ImGui::Checkbox(checkboxId.c_str(), &enabled)) setEnabled(s, mod.id, enabled);
            ImGui::SameLine();
            ImGui::Text("%s  v%s", mod.name.c_str(), mod.version.c_str());
            ImGui::SameLine();
            ImGui::PushStyleColor(ImGuiCol_Text, AppTheme::accent());
            ImGui::TextUnformatted(enabled ? "Ready" : "Disabled");
            ImGui::PopStyleColor();
            if (!mod.author.empty()) ui::TextSubtle("by %s  \xE2\x80\xA2  %s", mod.author.c_str(), mod.id.c_str());
            else ui::TextSubtle("%s", mod.id.c_str());
            if (!mod.description.empty()) ImGui::TextWrapped("%s", mod.description.c_str());
            ui::TextSubtle("Entrypoint: %s", mod.entrypoint.c_str());
            ui::CardEnd();
        }
        ui::Gap(ui::kGapS);
    }

    if (!catalog.problems.empty()) {
        ui::Gap(ui::kGapS);
        ImGui::PushStyleColor(ImGuiCol_Text, ImVec4(1.0f, 0.46f, 0.38f, 1.0f));
        ImGui::Text("%d package problem%s", static_cast<int>(catalog.problems.size()),
                    catalog.problems.size() == 1 ? "" : "s");
        ImGui::PopStyleColor();
        for (const modplatform::ModProblem &problem : catalog.problems) {
            ImGui::BulletText("%s", problem.message.c_str());
            ui::TextSubtle("%s", problem.path.c_str());
        }
    }
}
