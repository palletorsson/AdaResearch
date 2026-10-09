# Random_Cubes

**Authored extension — outside the current museum route. Batch: R-EXT. Implementation pending.**

[Read the shared handoff](../HANDOFF.md) · [All maps](../all-maps.md)

## Does a convincing die prove a fair procedure?

Body/layer: A thrown body, its settled orientation and a tally.

Proposed primary encounter: `dice_throw`.

## Starting evidence

Outside the active route. dice_throw creates a pickable physical die, reads a settled face and produces reward balls. Reset controls and several warrant views already exist. A physical simulation is not automatically a uniform six-way draw. Platform/wall recovery on 10 September: 2 interior cells restored as platforms; 33 boundary cells made explicit w. Keep museum.wall_height: 3 and existing gate-depth settings. See structure-recovery.html and doc/space/sequence-platform-recovery-2026-09-10/.

Current map dimensions: {'width': 13, 'depth': 20, 'max_height': 3}. Current final: 410 words.

Current primaries: dice_throw. Book anchors: dice_throw.

Source agreement is not proof of runtime reachability or lesson quality.

## Build the encounter

1. Keep the die on its existing rimmed table with reachable reset and clear settled-face readout. Contain and cap reward balls so they do not become corridor obstacles.
2. Show individual outcomes and a growing tally. Use the existing assay/net views where useful; include unresolved tilted/edge cases rather than silently counting them as a face.
3. An optional beside-it uniform integer generator can make a precise contrast. Label it as a second procedure and keep sample count/face colours comparable.

## Revise final.md

1. Throw first, then compare the face the eye sees with the one the program counted.
2. Repeat and let the tally grow without promising fairness from a short run.
3. Read the upward-normal/settling decision; locate the interval between moving body and accepted symbol.
4. Ask what the tally can support and what the collision model decided before the throw.

**Code to trace and quote after implementation:** dice_throw.gd: _read_dice_result, FACE_NORMALS, settling logic, _update_stats, _clean_reward_balls.

## Evidence to return

- Test six clearly settled orientations and ambiguous edge/tilted cases.
- Check actual pickup/drop and both reset paths.
- Observe bounded reward bodies and distinguish empirical counts from a fairness guarantee.

Also return the shared handoff report: source fingerprints, actual control path, museum captures, changed files and remaining limitations.

## Room for a better solution

Casino, assay desk or surreal oversized die all remain possible. Do not let the spectacle obscure which process produced a number.

**Reusable method:** R2 housed readout; R7 measurement contract; R8 bounded simulation.

## Open and inspect

- Map: `commons/maps/Random_Cubes/map_data.json`
- Book and supporting texts: `commons/maps/Random_Cubes/`
- [Primary view](http://localhost:3003/necklace/thread?map=Random_Cubes&role=primary)
- [Museum Progress](http://localhost:3003/museum-progress?sequence=randomness&room=Random_Cubes)
- `res://algorithms/randomness/dice_throw/dice_throw.tscn`
- `algorithms/randomness/dice_throw/dice_throw.gd`

Direct scene resources are entry points. Read inherited scripts, child scenes and shader bindings needed to establish the actual behaviour.
