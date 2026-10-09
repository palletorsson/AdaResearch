# Point One: encounter reference

Companion to the revised final.md, 15 September 2026. These distinctions support the main encounters without requiring every reader to inspect them during the first walk.

## Counter and the empty centre

The opening `_count` example is a local illustrative counter. The installed panel reads `Engine.get_process_frames()`. Neither counts seconds. `_process(delta)` receives a frame interval; the opening example does not accumulate it. The folding-past construction uses ten cycling frames and does not archive the visitor's history.

`FOCUS = Vector3(0, 1.25, 0)` is local to the invisible point's case. Arrows and lines locate it; no point mesh is created. The neighbouring code screen describes a separate, non-executing example with a visible marker. Later stages accumulate `elapsed` and use that to select drawing. They do not reveal the invisible point.

## Coordinates and arrival

The WORLD card and coloured frame follow the same changing dark point the visitor picked up earlier. Point One uses `coordinate_id:point_one_main`, `external_point_id:point_one_main`, and a matching `readout_channel`. The frame creates no floating point of its own. Other points, including Fontana's embedded copy, are excluded by identity. The partition opening at row 8, columns 5–9, is widened to five floor cells. Its two-decimal formatting rounds a report, not the stored location. The frame uses `to_local()`; the world and local addresses must retain their reference frames. Drawn axes are finite, but the point can move beyond them.

The target centre is 1.20 m above its origin; the accepted radius is 0.45 m. It checks points in its coordinate-point group, requires no release, and rearms after departure. Intention and route are not inputs to that distance test.

The wireframe ring is deferred to Point_Triangle_Context; its duplicate was removed from Point One on 15 September 2026. That ring requests wireframe rendering while occupied and restores the previous view after the last visitor leaves. This can expose mesh edges; it cannot expose the target's acceptance comparison or give the invisible point triangles.

## Further code from the earlier passage

These excerpts are preserved from the preceding chapter version for reference. They include illustrative reductions; consult the surrounding notes and technical.md before treating one as a complete implementation.

```gdscript
var origin := Vector3.ZERO
```

```gdscript
func report_position(point: Node3D) -> String:
    var p := point.global_position
    return "(%.2f, %.2f, %.2f)" % [p.x, p.y, p.z]
```

```gdscript
@export var catch_radius: float = 0.45
@export var catch_height: float = 1.20

func accepts_position(p: Vector3) -> bool:
    var centre := global_position + Vector3(0.0, catch_height, 0.0)
    return p.distance_to(centre) <= catch_radius
```

## Revised first walk, 15 September 2026

Counter → folding past → origin → invisible point → code screen → changing point → coordinate readout and frame → arrival target. The origin marker stays at the room origin; only its reading order changes. Fontana and the floating field remain secondary encounters, without dedicated final.md passages.
