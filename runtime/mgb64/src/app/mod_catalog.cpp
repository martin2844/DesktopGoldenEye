#include "mod_catalog.h"

#include <algorithm>
#include <cctype>
#include <filesystem>
#include <fstream>
#include <map>
#include <sstream>

namespace modplatform {
namespace {

namespace fs = std::filesystem;

std::string trim(const std::string &value) {
    size_t first = 0;
    while (first < value.size() && std::isspace(static_cast<unsigned char>(value[first]))) ++first;
    size_t last = value.size();
    while (last > first && std::isspace(static_cast<unsigned char>(value[last - 1]))) --last;
    return value.substr(first, last - first);
}

std::string valueWithoutComment(const std::string &value) {
    bool quoted = false;
    bool escaped = false;
    for (size_t i = 0; i < value.size(); ++i) {
        const char c = value[i];
        if (escaped) {
            escaped = false;
        } else if (c == '\\' && quoted) {
            escaped = true;
        } else if (c == '"') {
            quoted = !quoted;
        } else if (c == '#' && !quoted) {
            return trim(value.substr(0, i));
        }
    }
    return trim(value);
}

bool parseString(const std::string &raw, std::string &out) {
    if (raw.size() < 2 || raw.front() != '"') return false;
    out.clear();
    for (size_t i = 1; i < raw.size(); ++i) {
        const char c = raw[i];
        if (c == '"') return i == raw.size() - 1;
        if (c != '\\') {
            out.push_back(c);
            continue;
        }
        if (++i >= raw.size() - 1) return false;
        switch (raw[i]) {
            case '\\': out.push_back('\\'); break;
            case '"': out.push_back('"'); break;
            case 'n': out.push_back('\n'); break;
            case 'r': out.push_back('\r'); break;
            case 't': out.push_back('\t'); break;
            default: return false;
        }
    }
    return false;
}

bool validId(const std::string &id) {
    if (id.empty() || id.size() > 96) return false;
    if (!std::isalnum(static_cast<unsigned char>(id.front()))) return false;
    return std::all_of(id.begin(), id.end(), [](unsigned char c) {
        return std::isalnum(c) || c == '.' || c == '_' || c == '-';
    });
}

bool safeEntrypoint(const std::string &entrypoint) {
    if (entrypoint.empty()) return false;
    if (entrypoint.find(':') != std::string::npos) return false;
    fs::path path(entrypoint);
    if (path.is_absolute() || path.extension() != ".lua") return false;
    for (const fs::path &part : path) {
        if (part == "..") return false;
    }
    return true;
}

}  // namespace

bool parseManifest(const std::string &manifestPath, ModManifest &out, std::string &error) {
    std::ifstream input(manifestPath);
    if (!input) {
        error = "cannot open manifest.toml";
        return false;
    }

    std::map<std::string, std::string> values;
    int manifestVersion = -1;
    std::string line;
    int lineNumber = 0;
    size_t inputBytes = 0;
    bool sawManifestVersion = false;
    while (std::getline(input, line)) {
        ++lineNumber;
        inputBytes += line.size() + 1;
        if (line.size() > 8192 || inputBytes > 65536) {
            error = "manifest exceeds the 64 KiB or 8 KiB-per-line limit";
            return false;
        }
        const std::string cleaned = trim(valueWithoutComment(line));
        if (cleaned.empty()) continue;
        const size_t equals = cleaned.find('=');
        if (equals == std::string::npos) {
            error = "line " + std::to_string(lineNumber) + ": expected key = value";
            return false;
        }
        const std::string key = trim(cleaned.substr(0, equals));
        const std::string raw = trim(cleaned.substr(equals + 1));
        if (key == "manifest_version") {
            if (sawManifestVersion) {
                error = "duplicate field: manifest_version";
                return false;
            }
            if (raw != "1") {
                error = "manifest_version must be 1";
                return false;
            }
            manifestVersion = 1;
            sawManifestVersion = true;
            continue;
        }
        std::string value;
        if (!parseString(raw, value)) {
            error = "line " + std::to_string(lineNumber) + ": expected a quoted string";
            return false;
        }
        if (!values.emplace(key, value).second) {
            error = "duplicate field: " + key;
            return false;
        }
    }

    if (manifestVersion != 1) {
        error = "missing manifest_version = 1";
        return false;
    }
    const char *required[] = {"id", "name", "version", "entrypoint"};
    for (const char *key : required) {
        if (values[key].empty()) {
            error = std::string("missing required field: ") + key;
            return false;
        }
    }
    if (!validId(values["id"])) {
        error = "id must start with a letter or digit and contain only letters, digits, '.', '_' or '-'";
        return false;
    }
    if (!safeEntrypoint(values["entrypoint"])) {
        error = "entrypoint must be a relative .lua path without '..'";
        return false;
    }

    const fs::path manifest(manifestPath);
    const fs::path packageDir = manifest.parent_path();
    std::error_code ec;
    const fs::path entryPath = packageDir / fs::path(values["entrypoint"]);
    if (!fs::is_regular_file(entryPath, ec)) {
        error = "entrypoint does not exist: " + values["entrypoint"];
        return false;
    }
    const fs::path canonicalPackage = fs::weakly_canonical(packageDir, ec);
    if (ec) {
        error = "cannot resolve package directory: " + ec.message();
        return false;
    }
    const fs::path canonicalEntry = fs::weakly_canonical(entryPath, ec);
    if (ec) {
        error = "cannot resolve entrypoint: " + ec.message();
        return false;
    }
    const fs::path relativeEntry = canonicalEntry.lexically_relative(canonicalPackage);
    if (relativeEntry.empty() || relativeEntry.is_absolute() || *relativeEntry.begin() == "..") {
        error = "entrypoint resolves outside the package";
        return false;
    }

    out = {};
    out.directory = packageDir.string();
    out.id = values["id"];
    out.name = values["name"];
    out.version = values["version"];
    out.author = values["author"];
    out.description = values["description"];
    out.entrypoint = values["entrypoint"];
    error.clear();
    return true;
}

ModCatalog scanCatalog(const std::string &root) {
    ModCatalog catalog;
    catalog.root = root;
    std::error_code ec;
    if (!fs::exists(root, ec)) return catalog;
    if (!fs::is_directory(root, ec)) {
        catalog.problems.push_back({root, "mods root is not a directory"});
        return catalog;
    }

    std::vector<fs::path> packages;
    for (fs::directory_iterator it(root, fs::directory_options::skip_permission_denied, ec), end;
         !ec && it != end; it.increment(ec)) {
        const fs::file_status status = it->symlink_status(ec);
        if (ec) break;
        if (fs::is_directory(status) && !fs::is_symlink(status)) packages.push_back(it->path());
    }
    if (ec) {
        catalog.problems.push_back({root, "could not enumerate mods directory: " + ec.message()});
        return catalog;
    }
    std::sort(packages.begin(), packages.end());

    std::map<std::string, std::string> ids;
    for (const fs::path &package : packages) {
        const fs::path manifestPath = package / "manifest.toml";
        if (!fs::is_regular_file(manifestPath, ec)) continue;
        ModManifest manifest;
        std::string error;
        if (!parseManifest(manifestPath.string(), manifest, error)) {
            catalog.problems.push_back({manifestPath.string(), error});
            continue;
        }
        auto prior = ids.find(manifest.id);
        if (prior != ids.end()) {
            catalog.problems.push_back({manifestPath.string(),
                "duplicate mod id '" + manifest.id + "' (already used by " + prior->second + ")"});
            continue;
        }
        ids[manifest.id] = manifestPath.string();
        catalog.mods.push_back(std::move(manifest));
    }
    std::sort(catalog.mods.begin(), catalog.mods.end(), [](const ModManifest &a, const ModManifest &b) {
        return a.name < b.name;
    });
    return catalog;
}

}  // namespace modplatform
