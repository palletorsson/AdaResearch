# Translation as transport

The carrier normalises its direction and defines its target:

```gdscript
target_position = initial_position + (move_direction * move_distance)
```

Each frame advances towards the target by at most speed times elapsed seconds. The same displacement is added to its detected rider:

```gdscript
global_position = global_position.move_toward(target_position, move_speed * delta)
var movement_delta = global_position - previous_position
_translate_rider(carried_player, movement_delta)
```

The rider helper handles a desktop body or the VR tracking origin and its collision body; it applies an incremental displacement rather than teleporting the visitor to the destination. Contact with each pickup's Area3D calls collect(). Thirteen pickups use motion=slide: a vertical sine oscillation with the default 0.2 m amplitude and bob speed 2, without spin or a scale pulse. The carrier supplies the longer approach while each pickup rises and falls.

| Ride | Displacement | Starting deck |
| --- | --- | --- |
| First depth crossing | (0, 0, 6) | 0 m |
| Sideways | (8, 0, 0) | 0 m |
| Lift | (0, 3, 0) | 0 m |
| High crossing | (0, 0, 7) | 3 m |
| Return sideways | (-8, 0, 0) | 3 m |
| Escalator descent | (0, -3, 2) | 3 m |
| Diagonal | (8, 0, 8) | 0 m |

The escalator token is `tc:3.6055513:0,-3,2#deck:3`: direction (0,-3,2), normalised, and distance sqrt(13). Its standing surface moves from (3,3,35) to (3,0,37), meeting the platform beginning at z=38. The final diagonal uses direction (1,0,1), normalised, with distance sqrt(128), approximately 11.3137085 m. Rotation remains zero and ride_scale remains one on all carriers.

GridUtilitiesComponent seats the collider top, not the origin, on its starting deck before _ready. #deck:3 means three grid units above the arena's ground deck; GridSystem's museum origin is y=-0.5. The upward and downward lift sockets can therefore share the same type of empty cell while starting on different levels.

Run: Godot --headless --xr-mode off --path . --script res://commons/testing/probe_translation_course.gd

## A trace after the constraint — 23 September

Both exit studies use `#trace:on`. This opt-in passes `trace_motion` to their existing constrained doors. `accepted_motion_trace.gd` records the knob position after projection and clamping, and only while the pickup signal marks it held. It does not capture the tracked hand’s rejected displacement. The pale trace is displayed 9 cm forward of the sampled position to keep it visible in front of the door panel; the stored points are unshifted door-local coordinates.

Samples require 6 mm of movement. At most 256 positions remain, with old samples rolling off; reset clears the record. The tube radius is 4 mm, with six sides and one unshaded mesh per handle. No collider, new control, or movement constraint is added. Other placements retain their default untraced form.

The shared book illustration is rendered from the actual museum artifacts using separate supplied gestures. It compares a guided two-leg route, a direct free route and a curved free route. It is not a photograph of somebody’s headset trial.
