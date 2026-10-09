# Randomness_10_PRINT_Algorithm

**Authored extension — outside the current museum route. Batch: R-EXT. Implementation pending.**

[Read the shared handoff](../HANDOFF.md) · [All maps](../all-maps.md)

## How much world can two choices make?

Body/layer: A binary mark, a wall and an agent's proposed path.

Proposed primary encounter: `ten_print_maze_3d`.

## Starting evidence

Outside the active route. The generator has stroke/character/wall/tile modes, random diagonals, an ant/navigation grid and timed wall changes. It uses global seed/random calls; a new local RNG is needed for reliable isolation. Animated walls and navigation must be checked for agreement. Platform/wall recovery on 10 September: 1 interior cells restored as platforms; 0 boundary cells made explicit w. Keep museum.wall_height: 3 and existing gate-depth settings. See structure-recovery.html and doc/space/sequence-platform-recovery-2026-09-10/.

Current map dimensions: {'width': 13, 'depth': 14, 'max_height': 6}. Current final: 424 words.

Current primaries: ten_print_maze_3d. Book anchors: ten_print_maze_3d.

Source agreement is not proof of runtime reachability or lesson quality.

## Build the encounter

1. Begin with one fixed seeded diagonal field. Present the same choices as marks and walls using existing impression configurations.
2. Make wall mutation a second, explicit intervention; synchronise visible orientation, collision and navigation or clearly keep the agent demonstration separate.
3. Fit an optional walkable version to the room using original layout evidence. Do not promise a solvable maze from independent diagonals; keep a bypass and show disconnected regions honestly.

## Revise final.md

1. Let a slash become an obstruction by changing its embodiment.
2. Read one binary choice before showing the nested grid loop.
3. Follow a predicted path and notice whether the wall or the navigation model disagrees.
4. Leave with a distinction between generating marks and guaranteeing passage; avoid a historical attribution beyond checked sources.

**Code to trace and quote after implementation:** ten_print_maze.gd: generate_maze, build_navigation_grid, _on_wall_timer_timeout, impression methods. Inspect any repeated randi/seed use across mutations.

## Evidence to return

- The mark and wall views encode the same stored diagonal matrix.
- After mutation, navigation/collision match the shown wall or the limitation is explicit.
- Load/reload without changing unrelated seeded artifacts.

Also return the shared handoff report: source fingerprints, actual control path, museum captures, changed files and remaining limitations.

## Room for a better solution

Fable chooses printed tile, glass partition or a more theatrical translation. The same binary data must remain traceable.

**Reusable method:** R4 sample-to-body mapping; R5 arena boundary; R6 local state/seed.

## Open and inspect

- Map: `commons/maps/Randomness_10_PRINT_Algorithm/map_data.json`
- Book and supporting texts: `commons/maps/Randomness_10_PRINT_Algorithm/`
- [Primary view](http://localhost:3003/necklace/thread?map=Randomness_10_PRINT_Algorithm&role=primary)
- [Museum Progress](http://localhost:3003/museum-progress?sequence=randomness&room=Randomness_10_PRINT_Algorithm)
- `res://algorithms/randomness/generative/tenprintantmaze/ten_print_maze_3d.tscn`
- `algorithms/randomness/generative/tenprintantmaze/ten_print_maze.gd`

Direct scene resources are entry points. Read inherited scripts, child scenes and shader bindings needed to establish the actual behaviour.
