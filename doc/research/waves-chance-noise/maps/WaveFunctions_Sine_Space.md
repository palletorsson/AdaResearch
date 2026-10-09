# WaveFunctions_Sine_Space

**Active hall 3 in wavefunctions. Batch: W1. Runtime report reviewed; actual input and headset pending.**

[Read the shared handoff](../HANDOFF.md) · [All maps](../all-maps.md)

## What kinds of passage can a repeating rule make?

Body/layer: The world around the player's moving body.

Proposed primary encounter: `sine_wall_corridor`.

## Starting evidence

Runtime fixes produce a 7 m corridor with 4.5 fundamental cycles, floor at its origin, a thin supporting collision slab and no wall collision. One case remains at the west nook; rolling colour balls were removed from this hall. 57 probe checks report no failures: emitted controls, local-X gap and capsule routes. Shared sculpture-clear rectangles reserve the approach. Actual desktop input and headset checks remain open; see runtime-review.html.

Current map dimensions: {'width': 14, 'depth': 36, 'max_height': 8}. Current final: 1035 words.

Current primaries: sine_wall_corridor, sine_flow_tray. Book anchors: sine_flow_tray, sine_wall_corridor.

Source agreement is not proof of runtime reachability or lesson quality.

## Build the encounter

1. Retain an observation route through or alongside the animated installation. Establish actual world bounds, orientation and minimum gap before calling it traversable architecture.
2. Make amplitude and the relative phase of the two walls available as separate comparisons. Keep frequency and material stable initially; add local freeze for inspecting the same instant if needed.
3. Choose an honest physical contract: static collidable demonstration states rebuilt on deliberate changes, or animated visual skins around a stable passage. If animated collision is chosen, test the update budget and trapping cases. Mark the simulation's boundary and retain a clear museum bypass.

## Revise final.md

1. Enter through a gap and notice how facing surfaces disagree; let the body supply the first question.
2. Compare moving the viewer through space with holding position while phase changes.
3. Read one actual sine contribution before the sum. Distinguish wavelength across space from temporal rate.
4. Return to the gap: a visible wall and a colliding wall may have different powers. End at the sound room on the current route, not an absent extension.

**Code to trace and quote after implementation:** SineWallCorridor.gd: _wave_displacement, _create_wall_mesh, gap_at, gap_range, _evaluate_color. Running phase enters once via phase_shift; x-gap compares matching local Z coordinates.

## Evidence to return

- Measure minimum clearance across the exposed parameter range.
- Walk the implemented route with the actual player collider; record which surfaces collide.
- Verify freeze/parameter changes reach the displayed material or mesh and do not leave stale colliders.

Also return the shared handoff report: source fingerprints, actual control path, museum captures, changed files and remaining limitations.

## Room for a better solution

Plush folds, architectural ribs or a translucent membrane are welcome. Choose a material that makes the crests and the gap readable.

**Reusable method:** R1 controlled comparison; R4 sample-to-body mapping; R5 museum/arena boundary.

## Open and inspect

- Map: `commons/maps/WaveFunctions_Sine_Space/map_data.json`
- Book and supporting texts: `commons/maps/WaveFunctions_Sine_Space/`
- [Primary view](http://localhost:3003/necklace/thread?map=WaveFunctions_Sine_Space&role=primary)
- [Museum Progress](http://localhost:3003/museum-progress?sequence=wavefunctions&room=WaveFunctions_Sine_Space)
- `res://algorithms/wavefunctions/sine_wall/sine_wall_corridor.tscn`
- `algorithms/wavefunctions/sine_wall/SineWallCorridor.gd`
- `res://commons/artifacts/sine_flow_tray/sine_flow_tray.tscn`
- `commons/artifacts/sine_flow_tray/sine_flow_tray.gd`

Direct scene resources are entry points. Read inherited scripts, child scenes and shader bindings needed to establish the actual behaviour.
