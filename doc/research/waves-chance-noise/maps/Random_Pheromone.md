# Random_Pheromone

**Authored extension — outside the current museum route. Batch: R-EXT. Implementation pending.**

[Read the shared handoff](../HANDOFF.md) · [All maps](../all-maps.md)

## When does a path begin choosing its next visitor?

Body/layer: Agents, a decaying signal and a terrain that keeps another history.

Proposed primary encounter: `pheromone_terrain`.

## Starting evidence

Outside the active route. Visits deposit pheromone and alter height; the signal decays separately. trail/sniff/avoid/grid rule variants and seeded warmup already exist. These are genuine stateful processes, unlike a stateless field lookup.

Current map dimensions: {'width': 13, 'depth': 14, 'max_height': 3}. Current final: 411 words.

Current primaries: pheromone_terrain. Book anchors: pheromone_terrain.

Source agreement is not proof of runtime reachability or lesson quality.

## Build the encounter

1. Build a matched attraction/avoidance comparison from the same initial state using existing rule modes; expose a local reset and one clearly named rule choice.
2. Show pheromone strength and accumulated height separately, switching or pairing their readouts from the same state. Keep deposition and decay rates fixed initially.
3. Fit the evolving terrain within a stable observation border. Verify collider updates if a player can walk it; the agents' grid traversal and the player's body may use different representations.

## Revise final.md

1. Find a repeated route, then ask what the next walker is actually reading.
2. Compare following a trace with avoiding it before calling either best.
3. Read deposit, decay and next-step choice as distinct operations.
4. Let an old high ridge lose its current scent. State precisely where history persists, then distinguish this feedback from the stateless noise mixer.

**Code to trace and quote after implementation:** pheromone_terrain.gd: _walk_step, _decay_pheromones, _choose_next_position, _update_mesh and rule configs.

## Evidence to return

- At fixed timestep and seed, replay the initial run and log rule differences.
- Show pheromone decays while accumulated height follows its separate rule.
- Check index boundaries and any terrain collision updates.

Also return the shared handoff report: source fingerprints, actual control path, museum captures, changed files and remaining limitations.

## Room for a better solution

Turn the traces into scent, glow or another legible local signal. Avoid describing a globally optimal path or attributing intent the algorithm does not have.

**Reusable method:** R3 explicit time; R4 sample-to-body mapping; R6 local state/seed.

## Open and inspect

- Map: `commons/maps/Random_Pheromone/map_data.json`
- Book and supporting texts: `commons/maps/Random_Pheromone/`
- [Primary view](http://localhost:3003/necklace/thread?map=Random_Pheromone&role=primary)
- [Museum Progress](http://localhost:3003/museum-progress?sequence=randomness&room=Random_Pheromone)
- `res://algorithms/randomness/pheromone_terrain/pheromone_terrain.tscn`
- `algorithms/randomness/pheromone_terrain/pheromone_terrain.gd`
- `commons/resourses/shaders/SimpleGrid.gdshader`

Direct scene resources are entry points. Read inherited scripts, child scenes and shader bindings needed to establish the actual behaviour.
