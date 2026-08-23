// mod_runtime.h — isolated, bounded Lua execution for explicitly enabled mods.
#ifndef MGB64_MOD_RUNTIME_H
#define MGB64_MOD_RUNTIME_H

#include "mod_catalog.h"

#include <memory>
#include <string>
#include <vector>

namespace modplatform {

struct ModLoadReport {
    size_t loaded = 0;
    std::vector<ModProblem> problems;

    bool ok() const { return problems.empty(); }
};

class ModSession {
public:
    ModSession();
    ~ModSession();
    ModSession(const ModSession &) = delete;
    ModSession &operator=(const ModSession &) = delete;

    // Loads the explicitly enabled IDs as one transaction. Each package gets a
    // separate Lua state. One failure closes every state loaded by this call.
    ModLoadReport load(const ModCatalog &catalog, const std::vector<std::string> &enabledIds);
    void unload();
    size_t size() const;

private:
    struct Impl;
    std::unique_ptr<Impl> impl_;
};

}  // namespace modplatform

#endif  // MGB64_MOD_RUNTIME_H
