# Point Trace: encounter reference

Companion to the revised final.md, updated 16 September 2026.

The required reading now follows draw_dot, draw_stick and whiteboard. The telemetry and automatic-writing desk remain secondary encounters; [detours.md](detours.md) retains their questions. All nine map placements remain. The older book and supporting drafts are preserved in [the previous texts](../../../doc/space/point-trace-focus-2026-09-16/previous/).

## Three decisions in the recorder

The installed drawing dots use a 5 mm movement threshold and 4096-point capacity. The gate compares current world position with `_last_global_position`. On passing the gate, that reference updates **before** shaping and duplicate rejection. It is therefore not necessarily the last position retained in the trail, and the distance check is not simply movement since the previous engine frame.

In free space, the first dot adds no recording lattice; the red, green and blue variants round to 10, 40 and 80 mm. After shaping, a consecutive duplicate is rejected. Calls, movement-qualified readings and retained points are different counts. The straight connecting segments may be diagonal. Sampling cadence and spatial rounding are distinct causes of changes in a drawn curve.

The display shows retained count/capacity, movement threshold and lattice spacing. It shows the last ten retained positions, in world metres with at least three decimal places. An eighteen-point trail therefore displays rows 9–18 while the earlier points remain in the trail. The display previously rounded more coarsely than the recorder; that was a reporting defect, not evidence that the saved positions were identical.

## Capacity and persistence

Default live-trail fading is off in these placements. Above capacity the oldest point is removed; row numbers address the current list and shift when its first element is removed. Capacity is not a fixed duration. A smaller capacity would make eviction easier to witness, but is not an installed control. Some plinth traces are generated demonstrations, not recovered visitor gestures.

Releasing a drawing dot or stick publishes a copy of its retained positions to TraceData when there are at least two positions. That store survives room changes in the current game; this is not a disk-save promise. The whiteboard image takes another route.

## Board and other records

The board has its own pens. Contact requires the nib within 35 mm of the plane and inside its edges. Lifting beyond that allowance makes the next contact start a new stroke. Coordinates are transformed into the board's frame, optionally rounded to the pen's lattice, then mapped to a 1024 × 768 pixel canvas. NO GRID omits one rounding operation; it does not remove pixels. The brush connects accepted contacts without having measured every filled pixel.

The paired telemetry panels label a found controller node TRACKING and their synthetic fallback DEMO FEED. The current source lookup does not validate an active pose or the driven rig, so the label alone cannot establish live input. The automatic-writing desk uses available headset-camera position changes to alter amplitude, with fallback demonstration motion. Neither establishes attention or a confession.

## Further code from the earlier passage

These excerpts are preserved from the preceding chapter version for reference. They include illustrative reductions; consult the surrounding notes and technical.md before treating one as a complete implementation.

```gdscript
var dist = current_global.distance_to(_last_global_position)

if dist < min_segment_distance:
    if fade_trail:
        _cleanup_old_points()
        _rebuild_trail()
    _refresh_data_table_if_due()
    return
```

```gdscript
var s: float = resolution_mm / 1000.0
rec = Vector3(snappedf(rec.x, s), snappedf(rec.y, s), snappedf(rec.z, s))
```
