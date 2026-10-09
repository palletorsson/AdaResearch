# The Moving Boundary — read the timed study

**Learning elements — proposed focus**

*The labels below set the revision focus; the existing lesson still needs alignment.*

- Shared control values
- Coordinated transforms
- Occupancy conditions
- Reset sequences

The three zones use position, rotation and size as timed obstacles. The floor remains level, and a bypass remains available. Watch a complete cycle from beside the lane before choosing to enter it. The source artifacts are `pusher_block.gd`, `rotation_cube.gd` and `grower_block.gd`; the middle zone also retains four `free_ball_launcher` instances.

## Translate between endpoints, with a pause

The pusher caches a world-space start and endpoint:

```gdscript
_end_pos = _start_pos + push_axis.normalized() * push_distance
```

A late grid configuration refreshes this cached endpoint and its direction arrow. Without that refresh, a block configured for Z could keep the default path along X.

During the moving part of its physics update:

```gdscript
var speed_normalized: float = push_speed / push_distance
_t += _direction * speed_normalized * delta
_t = clampf(_t, 0.0, 1.0)
var target_pos: Vector3 = _start_pos.lerp(_end_pos, _t)
_body.global_position = target_pos
```

At `_t = 0` or `_t = 1`, the block waits for `pause_time`, then reverses `_direction`. The moving surface is an `AnimatableBody3D`.

| Placement (x,z) | Direction | Travel | Speed | One-way time | Pause at each end |
|---|---|---|---|---|---|
| (3,3) | +Z | 2 m | 1.5 m/s | about 1.33 s | 1.5 s |
| (7,3) | +Z | 2 m | 2 m/s | 1 s | 1 s |
| (5,5) | −Z | 2 m | 1.8 m/s | about 1.11 s | 1.2 s |

Each token places the block centre 0.49 m above the floor, half its 0.98 m side. Its cached endpoints therefore keep the whole block above the deck. The three paths are separate and stop before the solid transverse walls. The eastern route avoids these lanes. Compare travel and waiting by choosing a lane, rather than treating progress through the room as proof that its timing was learned.

## Rotate a wall profile

The middle zone places `rc:90:y:4:-0.6` and `rc:90:y:3:-0.6`. These are step-and-pause rotation cubes, not continuous revolving walls. Their box profile is 2.2 × 2.2 × 1 metre; the authored vertical offset sinks part of that profile below the deck.

```gdscript
mesh_instance.rotation_degrees = rotation_axis * current_angle
static_body.transform = mesh_instance.transform
```

The angle moves between zero and ninety degrees around Y at 45 degrees per second. Each turn takes two seconds; pauses are four and three seconds respectively. Measure the available width beside a slab at both orientations. Its own dimensions are fixed while its projection across the route changes.

## Grow from the floor on a clock

All three map tokens specify `min:0.3`, `max:3.5`, `speed:0.15`, `anchor:floor`, and `plinth:0`. Configuration reaches the live artifact.

```gdscript
_time += delta * grow_speed * TAU
```

For floor anchoring, the interpolation value is:

```gdscript
var t: float = (1.0 - cos(_time)) * 0.5
var current_scale: float = lerpf(min_scale, max_scale, t)
```

All three growers share this rate and small starting configuration. The cosine starts this configuration small. A complete cycle takes `1.0 / grow_speed`, about 6.67 seconds. No visitor distance is read.

The artifact sets the same side length on its mesh and collision box. It keeps their centres half that length above the root's floor position:

```gdscript
var centre_y: float = s * 0.5 if anchor == "floor" else 0.0
_col_shape.position.y = centre_y
_mesh.position.y = centre_y
```

The `AnimatableBody3D` origin remains fixed. Updating the child geometry avoids its physics synchronization restoring an old body position while the collision shape has already changed size. Existing placements without `anchor:floor` retain their centre-anchored sine cycle.

## What to compare

Ask what stays invariant in the object, then ask what happens to the visitor's available space. Translation preserves the object's dimensions; rotation preserves its internal distances; this positive uniform scaling preserves proportions. Nonuniform scaling would change those proportions.

The legacy fire utilities have been removed, so their flames no longer occupy the observation floor. This is a ground-level study without an enforced failure consequence. A clear route around a lane is part of the current design; do not describe it as a lethal pit or a compulsory timing gate.

Compare clearances for particular bodies. A capsule test checks one radius and height. It does not stand in for all player sizes, locomotion choices or comfort needs.
