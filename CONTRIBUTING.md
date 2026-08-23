# Contributing during the planning phase

The repository is currently a feasibility and architecture plan. Small, evidence-backed changes are preferred.

Before proposing implementation work:

1. Identify the roadmap milestone and exit criterion it advances.
2. Record a decision in `docs/DECISIONS.md` when a public Interface, upstream dependency, artifact format, or platform promise changes.
3. Add or update a risk when evidence changes probability or impact.
4. Include a ROM-free test whenever possible; mark private ROM-backed tests explicitly.
5. Keep game data and derived assets out of Git.

Public Lua Interfaces are compatibility promises. Do not expose a new raw address or ad hoc helper merely because it is easy to wire. First determine which GoldenEye concept owns the behavior and whether the Interface can hide more implementation detail.

The initial implementation should use short-lived experiment branches until the Phase 0 baseline is selected. Experimental code must not silently turn a provisional decision into a permanent public Interface.
