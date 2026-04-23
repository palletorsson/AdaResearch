# Fix Ordering Discovery

Discovery pass completed on 2026-04-17 for the `fix_ordering` goal.

## `fix_ordering.002` `array_tutorial`

Files:
- `commons/maps/sequences/array_tutorial.json`
- `doc/curriculum_audit/array_tutorial.md`

Current `maps` order:
1. `Tutorial_Pattern`
2. `Array_Patterns`
3. `Tutorial_Single`
4. `Tutorial_Row`
5. `Tutorial_2D_Build`
6. `Tutorial_3D`
7. `Tutorial_Disco`
8. `Chamber_Arrays`

Target order from the audit:
1. `Tutorial_Single`
2. `Tutorial_Row`
3. `Tutorial_2D_Build`
4. `Tutorial_3D`
5. `Tutorial_Pattern`
6. `Array_Patterns`
7. `Tutorial_Disco`
8. `Chamber_Arrays`

Notes:
- The sequence JSON already contains the relevant maps; this is a reorder, not a content addition.
- `artifact_groups` already imply the foundational ladder comes before pattern-heavy maps, so this task should only need a `maps[]` reorder.
- The audit also flags `Chamber_Arrays` missing from `artifact_groups` and a `Tutorial_2D_Build` metadata bug, but those are adjacent cleanup tasks, not required to complete the ordering fix itself.

## `fix_ordering.003` `cellularautomata`

Files:
- `commons/maps/sequences/cellularautomata.json`
- `doc/curriculum_audit/cellularautomata.md`

Current `maps` order:
1. `CA_Introduction`
2. `CA_ElementaryRules`
3. `CA_GameOfLife`
4. `CA_BeyondBinary`
5. `CA_ExpandingSpace`
6. `CA_SoftRules`
7. `CA_AgentsCircuits`
8. `CA_EdgeOfChaos`
9. `Chamber_CA`

Target order from the audit:
1. `CA_Introduction`
2. `CA_GameOfLife`
3. `CA_ElementaryRules`
4. `CA_BeyondBinary`
5. `CA_ExpandingSpace`
6. `CA_SoftRules`
7. `CA_EdgeOfChaos`
8. `CA_AgentsCircuits`
9. `Chamber_CA`

Notes:
- The strongest inconsistency is `CA_GameOfLife` versus `CA_ElementaryRules`; the audit explicitly says the intents describe Intro -> Life -> Elementary.
- The audit also recommends `CA_EdgeOfChaos` before `CA_AgentsCircuits`, so this is not only a one-swap fix if you want the full audit order applied.
- `artifact_groups` mirror the old order; if the sequence relies on their order downstream, update them to match `maps[]`.

## `fix_ordering.004` `swarmintelligence`

Files:
- `commons/maps/sequences/swarmintelligence.json`
- `doc/curriculum_audit/swarmintelligence.md`

Current `maps` order:
1. `SwarmIntelligence_PhysarumColony`
2. `SwarmIntelligence_FlowFields`
3. `SwarmIntelligence_Boids_Algorithm`
4. `SwarmIntelligence_Agent_Based_Modeling_ABM`
5. `SwarmIntelligence_Ant_Colony_Optimization`
6. `SwarmIntelligence_Particle_Swarm_Optimization`
7. `SwarmIntelligence_Swarm_Intelligence_Algorithms`
8. `Chamber_Swarm`

Target order from the audit:
1. `SwarmIntelligence_FlowFields`
2. `SwarmIntelligence_Boids_Algorithm`
3. `SwarmIntelligence_Agent_Based_Modeling_ABM`
4. `SwarmIntelligence_Ant_Colony_Optimization`
5. `SwarmIntelligence_Particle_Swarm_Optimization`
6. `SwarmIntelligence_PhysarumColony`
7. `SwarmIntelligence_Swarm_Intelligence_Algorithms`
8. `Chamber_Swarm`

Notes:
- The audit's core argument is conceptual: Physarum is the radical boundary case and lands better after the learner has already met fields, neighbors, and optimization.
- The task is a reorder only. The audit separately flags missing `self_organizing_patterns` and weak ABM anchoring, but those belong to different tasks.

## `fix_ordering.005` `Point_Lines`

Files:
- `commons/maps/Point_Lines/map_data.json`
- `tools/map_pathfinder.py`

Pathfinder result:
- `python tools/map_pathfinder.py check Point_Lines` returns `1 OK, 0 FAIL`.
- `python tools/map_pathfinder.py show Point_Lines` shows one unreachable artifact:
  - `dgrid` at `(6,26)` on void row 26

Notes:
- This is not currently a failing map.
- The task is a design decision, not a broken-path repair:
  - either bridge the late-map island to make `dgrid` reachable, or
  - accept it as a display/view-only element and document that choice so the audit does not keep reopening it.
