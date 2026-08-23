// ui_mods.cpp — launcher surface for local, asset-free mod packages.
#include "ui_launcher.h"
#include "app_theme.h"
#include "mod_catalog.h"
#include "ui_common.h"

#include "imgui.h"
#include <SDL.h>

#include <cstdlib>
#include <filesystem>
#include <string>

namespace {

std::string modsRoot() {
    if (const char *configured = std::getenv("MGB64_MODS_DIR")) {
        if (configured[0]) return configured;
    }
    return "mods";
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

void ModsPanel_draw(LauncherState & /*s*/, LauncherAction & /*out*/) {
    static std::string root;
    static modplatform::ModCatalog catalog;
    static bool initialized = false;
    if (!initialized) {
        root = modsRoot();
        catalog = modplatform::scanCatalog(root);
        initialized = true;
    }

    ui::SectionHeader("Mods", "Discover local Lua packages now; sandboxed execution is the next milestone.");
    if (ImGui::Button("Open Mods Folder", ui::kBtnSecondary())) openModsFolder(root);
    ImGui::SameLine();
    if (ImGui::Button("Refresh", ImVec2(120, ui::kBtnSecondary().y))) {
        root = modsRoot();
        catalog = modplatform::scanCatalog(root);
    }
    ui::Gap(ui::kGapXS);
    ui::TextSubtle("Folder: %s", root.c_str());
    ui::TextSubtle("Safety gate: packages are validated and listed, but no mod code is executed in this build.");
    ui::Gap(ui::kGapM);

    if (catalog.mods.empty() && catalog.problems.empty()) {
        ImGui::TextUnformatted("No mods found");
        ui::Gap(ui::kGapXS);
        ui::TextSubtle("Add a package folder containing manifest.toml and a Lua entrypoint, then refresh.");
    }

    for (size_t i = 0; i < catalog.mods.size(); ++i) {
        const modplatform::ModManifest &mod = catalog.mods[i];
        const std::string cardId = "##mod-" + std::to_string(i);
        if (ui::CardBegin(cardId.c_str(), AppTheme::primary(), 116.0f)) {
            ImGui::Text("%s  v%s", mod.name.c_str(), mod.version.c_str());
            ImGui::SameLine();
            ImGui::PushStyleColor(ImGuiCol_Text, AppTheme::accent());
            ImGui::TextUnformatted("Discovered");
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
