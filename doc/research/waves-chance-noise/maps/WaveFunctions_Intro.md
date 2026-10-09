# WaveFunctions_Intro

**Active hall 1 in wavefunctions. Batch: PILOT. Partial probe evidence; required pickup/release untested.**

[Read the shared handoff](../HANDOFF.md) · [All maps](../all-maps.md)

## When a body returns to the same place, what has changed?

Body/layer: A suspended body; the player's releasing hand.

Proposed primary encounter: `control_pendulum`.

## Starting evidence

The grabbable bob integrates angular acceleration, velocity and angle in _physics_process. Existing regime/evidence configurations include free/damped/driven behaviour and trace/longhand views; exports are not proof of visitor controls. The room also contains many transformation cubes. Structure recovery on 10 September: interior 2 cells are one-metre platforms, perimeter 2 cells are explicit w walls, museum.wall_height is 3, and gate_depth_rows is 0. Preserve this contract; see recovery.html and the dated doc/space archive.

Current map dimensions: {'width': 13, 'depth': 22, 'max_height': 4}. Current final: 613 words.

Current primaries: control_pendulum. Book anchors: control_pendulum.

Source agreement is not proof of runtime reachability or lesson quality.

## Build the encounter

1. Give the bob an open, reachable installation with its complete swing clear of plinth, neighbouring exhibits and circulation. Keep a still reference and a visible centre crossing; retain useful transformation comparisons as secondary.
2. Start with one release experiment. Offer a deliberate reveal of angle and signed angular velocity, using the existing evidence modes where suitable. If a damping comparison is added, change only that setting; do not introduce every regime at once.
3. Check the initial cube collection against old map structure before consolidating. Preserve meaningful stationary/prescribed-motion examples so a calculated pendulum is distinguishable from a cube following sin(time).

## Revise final.md

1. Open with two visits to the centre that travel in opposite directions; invite a release before explaining.
2. Describe position, direction and turning points, then connect the short integration excerpt to the force work already learned.
3. Let a second release trouble a prediction. Avoid promising exact small-angle behaviour at large releases.
4. End with the need to keep a record: the next room gives elapsed history a spatial direction.

**Code to trace and quote after implementation:** control_pendulum.gd: _physics_process, _damping_multiplier, _on_bob_dropped. Quote the actual angle/velocity update; do not replace it with y=sin(t).

## Evidence to return

- Exercise the real pickup/drop path and confirm the bob is reachable at both release positions.
- Record two centre crossings with opposite angular velocities; demonstrate the selected regime with its actual config.
- Measure the full installation bounds and check player clearance during a swing.

Also return the shared handoff report: source fingerprints, actual control path, museum captures, changed files and remaining limitations.

## Room for a better solution

Choose the casing, material and way the motion leaves evidence. A delicate instrument or an oversized suspended body can both work if the reference remains readable.

**Reusable method:** R1 controlled comparison; R2 housed readout; R3 explicit time.

## Open and inspect

- Map: `commons/maps/WaveFunctions_Intro/map_data.json`
- Book and supporting texts: `commons/maps/WaveFunctions_Intro/`
- [Primary view](http://localhost:3003/necklace/thread?map=WaveFunctions_Intro&role=primary)
- [Museum Progress](http://localhost:3003/museum-progress?sequence=wavefunctions&room=WaveFunctions_Intro)
- `res://commons/artifacts/control_pendulum/control_pendulum.tscn`
- `commons/artifacts/control_pendulum/control_pendulum.gd`

Direct scene resources are entry points. Read inherited scripts, child scenes and shader bindings needed to establish the actual behaviour.
