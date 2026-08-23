#include "mod_catalog.h"

#include <filesystem>
#include <fstream>
#include <iostream>
#include <string>

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

}  // namespace

int main() {
    const fs::path root = fs::temp_directory_path() / "mgb64-mod-catalog-test";
    std::error_code ec;
    fs::remove_all(root, ec);

    writeFile(root / "hello" / "manifest.toml",
              "manifest_version = 1\n"
              "id = \"example.hello\"\n"
              "name = \"Hello Facility\"\n"
              "version = \"0.1.0\"\n"
              "author = \"Test Agent\"\n"
              "description = \"A harmless test package.\"\n"
              "entrypoint = \"main.lua\"\n");
    writeFile(root / "hello" / "main.lua", "-- execution intentionally not part of catalog tests\n");

    writeFile(root / "escape" / "manifest.toml",
              "manifest_version = 1\n"
              "id = \"example.escape\"\n"
              "name = \"Escape\"\n"
              "version = \"1.0.0\"\n"
              "entrypoint = \"../outside.lua\"\n");

    writeFile(root / "duplicate" / "manifest.toml",
              "manifest_version = 1\n"
              "id = \"example.hello\"\n"
              "name = \"Duplicate\"\n"
              "version = \"1.0.0\"\n"
              "entrypoint = \"main.lua\"\n");
    writeFile(root / "duplicate" / "main.lua", "-- duplicate id\n");

    writeFile(root / "drive-relative" / "manifest.toml",
              "manifest_version = 1\n"
              "id = \"example.drive-relative\"\n"
              "name = \"Drive Relative\"\n"
              "version = \"1.0.0\"\n"
              "entrypoint = \"C:outside.lua\"\n");

    writeFile(root / "duplicate-field" / "manifest.toml",
              "manifest_version = 1\n"
              "id = \"example.first\"\n"
              "id = \"example.second\"\n"
              "name = \"Duplicate Field\"\n"
              "version = \"1.0.0\"\n"
              "entrypoint = \"main.lua\"\n");
    writeFile(root / "duplicate-field" / "main.lua", "-- duplicate field\n");

    const modplatform::ModCatalog catalog = modplatform::scanCatalog(root.string());
    check(catalog.mods.size() == 1, "one valid package should be discovered");
    check(catalog.problems.size() == 4, "unsafe, duplicate-id, and duplicate-field packages should be reported");
    if (!catalog.mods.empty()) {
        check(catalog.mods[0].id == "example.hello", "manifest id should round-trip");
        check(catalog.mods[0].entrypoint == "main.lua", "entrypoint should round-trip");
    }

    modplatform::ModManifest parsed;
    std::string error;
    check(modplatform::parseManifest((root / "hello" / "manifest.toml").string(), parsed, error),
          "valid manifest should parse directly");
    check(!modplatform::parseManifest((root / "escape" / "manifest.toml").string(), parsed, error),
          "parent traversal entrypoint should be rejected");

    fs::remove_all(root, ec);
    if (failures) return 1;
    std::cout << "mod catalog tests passed\n";
    return 0;
}
