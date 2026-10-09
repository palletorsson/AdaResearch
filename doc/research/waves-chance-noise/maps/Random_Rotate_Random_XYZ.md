# Random_Rotate_Random_XYZ

**Authored extension — outside the current museum route. Batch: R-EXT. Implementation pending.**

[Read the shared handoff](../HANDOFF.md) · [All maps](../all-maps.md)

## Which changes make an arrangement harder to inhabit?

Body/layer: A repeated array under angular perturbation.

Proposed primary encounter: `random_decay_multimesh`.

## Starting evidence

Outside the active route. Current primary changes drift, rotation and colour, with different rates for the cube and prism stacks. It has TOGGLE/RESET; several rotation-specific artifacts are also placed. Its 'decay' is not an entropy measurement. Platform/wall recovery on 10 September: 45 interior cells restored as platforms; 47 boundary cells made explicit w. Keep museum.wall_height: 3 and existing gate-depth settings. See structure-recovery.html and doc/space/sequence-platform-recovery-2026-09-10/.

Current map dimensions: {'width': 12, 'depth': 17, 'max_height': 2}. Current final: 409 words.

Current primaries: random_decay_multimesh. Book anchors: random_decay_multimesh.

Source agreement is not proof of runtime reachability or lesson quality.

## Build the encounter

1. Start with a matched reference and a rotation-only array. Disable translation, sinking, scale and colour variation for that first comparison; inspect whether the existing rotation artifacts provide a clearer implementation.
2. Offer axis-specific or combined angular perturbation and a controlled magnitude at the same sample cadence and seed. Reuse the existing process controls.
3. Build a short collidable strip only if the bodily question is traversal. Keep the separate full decay presentation optional and label its extra variables.

## Revise final.md

1. Recognise the same cubes, then find the gap or alignment that has changed.
2. Pause a rotation-only comparison and separate centre positions from edge directions.
3. Read the actual angular update, connecting to Trans_Rotation's axes and composition.
4. Ask which body can pass at the tested angle; call changed connectivity/reachability precisely, not 'topological entropy' without a defined measure.

**Code to trace and quote after implementation:** random_decay_multimesh.gd: _advance_layer, _create_vr_controls; inspect Random_Rotate_Random_XYZ and SlopeGradientCubes if promoting a more appropriate lead.

## Evidence to return

- Prove scale/position/material stay fixed in the rotation-only mode.
- Replay the angular sequence at the chosen simulation cadence.
- Check traversability against actual colliders if claimed; update primary/book anchors together if the lead changes.

Also return the shared handoff report: source fingerprints, actual control path, museum captures, changed files and remaining limitations.

## Room for a better solution

Fable may promote the better existing rotation artifact instead of forcing decay to teach everything. Document why it makes the question clearer.

**Reusable method:** R1 controlled comparison; R4 sample-to-body mapping; R6 local state/seed.

## Open and inspect

- Map: `commons/maps/Random_Rotate_Random_XYZ/map_data.json`
- Book and supporting texts: `commons/maps/Random_Rotate_Random_XYZ/`
- [Primary view](http://localhost:3003/necklace/thread?map=Random_Rotate_Random_XYZ&role=primary)
- [Museum Progress](http://localhost:3003/museum-progress?sequence=randomness&room=Random_Rotate_Random_XYZ)
- `res://algorithms/randomness/randomdecay/scenes/random_decay_multimesh.tscn`
- `algorithms/randomness/randomdecay/scripts/random_decay_multimesh.gd`

Direct scene resources are entry points. Read inherited scripts, child scenes and shader bindings needed to establish the actual behaviour.
