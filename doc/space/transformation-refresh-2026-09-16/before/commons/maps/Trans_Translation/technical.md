# Translation as transport

The carrier normalises its direction and defines its target:

```gdscript
target_position = initial_position + (move_direction * move_distance)
```

Each frame advances towards the target by at most speed times elapsed seconds. The same displacement is added to its detected rider:

```gdscript
global_position = global_position.move_toward(target_position, move_speed * delta)
var movement_delta = global_position - previous_position
carried_player.global_position += movement_delta
```

The latter two lines execute when a valid carried player exists. Contact with each pickup's Area3D calls collect(). Thirteen pickups use motion=slide: a vertical sine oscillation with the default 0.2 m amplitude and bob speed 2, without spin or a scale pulse. The carrier supplies the longer approach while each pickup rises and falls.

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
