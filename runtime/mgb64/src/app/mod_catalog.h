// mod_catalog.h — ROM-free discovery and validation for local mod packages.
//
// This is deliberately independent of ImGui, SDL, Lua, and the game engine so
// launcher UI, author tools, and tests share one manifest contract.
#ifndef MGB64_MOD_CATALOG_H
#define MGB64_MOD_CATALOG_H

#include <string>
#include <vector>

namespace modplatform {

struct ModManifest {
    std::string directory;
    std::string id;
    std::string name;
    std::string version;
    std::string author;
    std::string description;
    std::string entrypoint;
};

struct ModProblem {
    std::string path;
    std::string message;
};

struct ModCatalog {
    std::string root;
    std::vector<ModManifest> mods;
    std::vector<ModProblem> problems;
};

// Parse one v1 manifest.toml and validate its required fields and entrypoint.
// The supported v1 grammar is intentionally small: top-level key/value pairs,
// quoted UTF-8 strings, and an integer manifest_version.
bool parseManifest(const std::string &manifestPath, ModManifest &out, std::string &error);

// Discover immediate child directories containing manifest.toml. A missing
// root is an empty catalog, not an error; scanning never creates or edits files.
ModCatalog scanCatalog(const std::string &root);

}  // namespace modplatform

#endif  // MGB64_MOD_CATALOG_H
