# Randomness as shared experiment

**14 October 2026 · Proposed research route, particle tutorial path and implementation specification.**

The author asked Ada to move from explaining known results toward building experiments through which author and visitor can learn something not known in advance. The accepted cycle ends with an observation leading to another change, beyond a successful replay.

Start with the [hall proposal](HALLS.md) for order and existing/new artifacts. Read the [final-text draft](FINAL.md) for the proposed voice. The [specification](SPEC.md) and [task queue](TASKS.md) make the work concrete.

| Read | Purpose |
| --- | --- |
| [Hall order and artifacts](HALLS.md) | Eighteen stops in eight movements, retained side visits, four new artifact proposals and seven transfers |
| [Particle tutorial path](PARTICLE_PATH.md) | Seven continuing lessons: five existing halls, a new field lab and the shared rule workshop |
| [Final text](FINAL.md) | Sequence-level editorial draft from the supplied research map; not deployed into hall texts |
| [Specification](SPEC.md) | Problem, stories, agreed/proposed decisions, testing and limits |
| [Tasks](TASKS.md) | Twenty dependency-ordered work items in the existing local tracker |
| [Source findings](FINDINGS.md) | Reuse, claims needing repair, and untested behaviour |
| [Inventory](INVENTORY.md) | All 31 selected map spaces including the museum-only interlude; 111 distinct placed artifacts |
| [Original text](SOURCE.md) | Exact copy of the supplied research map |
| [Decision record](DECISIONS.md) | Author-accepted direction versus proposals |
| [Route manifest](route.json) | Machine-readable proposal; not installed |
| [Validation](validation.json) | References, coverage, dependencies and freshness; no runtime certificate |

The route has **15 existing core hosts and three new hall proposals**. The particle branch adds one more new hall and shares the Rule Workshop. Twelve existing randomness/noise sequence halls remain side visits; Biome Cage is also retained. Genetic Evolution and QFEP Sandbox remain later returns with preparation.

The baseline distinguishes sequence files from current museum configuration: 14 randomness teaching maps become 15 museum spaces with Biome Cage; Noise has 11 sequence maps but 10 museum spaces; particles has a sequence but no Endless Museum chapter. This pass changes no live route.

The first build should be one complete seed-bench cycle: keep a baseline, change one interpretation, compare, retain, replay, reconstruct and identify a further change. Grow the route from the evidence of that encounter.

Run the adjacent validate_plan.py to recheck this package. audit_inventory.py replaces the source snapshot; reread changed behavioural evidence before relying on a new hash. build_plan.py regenerates proposals; preserve task statuses and decisions before running it after implementation begins.
