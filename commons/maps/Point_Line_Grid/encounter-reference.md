# Point–Line–Grid: encounter reference

Companion to final.md, updated 16 September 2026. The primary route is snapping sphere, walking recorder, replay field, numbered plan: repeatable addresses become a resource for arranging space. The existing technical.md supplies the fuller source walkthrough. [Detours](detours.md) preserve the room's secondary encounters, and the [editorial record](../../../doc/space/point-grid-focus-2026-09-16/README.md) keeps the preceding texts.

## Different grids, different frames

The held snapping tool uses a 0.05 m world grid. Its table records retained samples and lattice indices, not a raw-versus-rounded comparison. On release it corrects the handle position so that the sampled marker aligns to the lattice; the release callback can append the position even if already retained.

For a fixed origin and spacing, the snap function treats input positions with the same rounded output as equivalent. Drawing a lattice alone does not impose that equivalence on a recorder or a moving body.

The walking recorder follows the walking body on desktop. In VR it combines camera world X/Z with rig-origin world Y, then converts to its own frame and rounds local X/Z to a one-metre lattice. It adds a display-height offset. Leaning and stepping can both move its chosen point; it does not record footsteps. Consecutive duplicates are suppressed. The record holds up to 1024 positions with sample times and speeds; fading is off. The finer reference is sampled too. Direct segments can cross untraversed ground.

Rounding regions extend halfway between lattice nodes. Their boundaries need not coincide with a separate visible grid drawing. Reapplying the same rounding rule to a rounded position leaves it unchanged (idempotence); this does not establish that the first application preserved every difference.

## Replay and its account

TraceData copies at least two retained positions from a released drawing dot or stick. The store does not include the original pen colour, timestamps or interpretation. It is shared across rooms in the running game, without a disk-save operation here. The whiteboard and player_trace do not publish this record.

The replay subtracts the source bounding-box centre and enlarges fivefold, reduced if needed to keep the longest dimension within five metres. Pink shows that transformation. Green then snaps all three displayed axes to 1/6 m; a mesh needs at least two surviving points. Source positions remain unchanged.

Recentring and scaling operate on stored positions; they do not require integer grid indices or prior snapping. The replay extends Trace's retained list into another use, while the green version supplies the additional grid comparison. Keep that distinction when describing this room's progression: addresses help specify and repeat placement, but they are not a prerequisite for transformation.

The panel reports the latest source count/length, enlargement and display pitch. Its source-world rows advance ten per page every two seconds. Its summary covers the latest ten releases; older meshes can remain. Source and displayed lengths are different quantities.

## The placed plan

The current map places `plan_vitrine`, which wraps `simulation_grid`; the book now anchors the placed wrapper. Its five-by-five one-metre cells have a continuous floor collider. Glass panes visually enclose the plan but carry no colliders. The wrapper also contains controller-mounted drawing behavior; that is not a promised desktop interaction or a newly headset-verified encounter in this writing pass.

Separately, the museum basin for grid_lines has a one-metre depth and a glass lid supplied by the museum builder. The grid lines themselves have no floor collider. Changing walking-grid spacing or origin through new controls remains future work.

## Further code from the earlier passage

These excerpts are preserved from the preceding chapter version for reference. They include illustrative reductions; consult the surrounding notes and technical.md before treating one as a complete implementation.

```gdscript
position_sample.x = camera.global_position.x
position_sample.z = camera.global_position.z
```
