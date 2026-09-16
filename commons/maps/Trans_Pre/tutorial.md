# Trans_Pre — making the animated pickup

Start with the cube learned in Primitives. Add three operations to make the Mario-style pickup used in this room.

| Stage | What to watch | Name |
|---|---|---|
| 1 | A still cube | Starting form |
| 2 | The cube moves up and down | Translation: change position |
| 3 | It also turns | Rotation: change facing |
| 4 | It also grows and shrinks | Scale: change size |

Each example keeps the movements introduced before it. Ask the learner to spot the new movement before naming it.

The room uses four instances of `commons/scenes/mapobjects/pick_up_cube.tscn`. The following excerpts come from its `pick_up_cube.gd` script.

Translation changes the vertical position:

```gdscript
global_position.y = lerp(original_y - bob_height, original_y + bob_height, t)
```

`lerp(a, b, t)` chooses a value between `a` and `b`: zero gives the first endpoint, one the second, and 0.5 the midpoint. The endpoints here sit `bob_height` below and above the saved starting height.

The script adds `delta` to `time_passed` each update, then repeats the journey with:

```gdscript
var t: float = pingpong(time_passed / maxf(lerp_duration, 0.001) + 0.5, 1.0)
```

`pingpong` moves the number back and forth between zero and one. Each leg takes `lerp_duration` seconds, set to 1.5 here. Adding 0.5 starts the cube halfway, at its authored height. `maxf` protects against a zero duration. This gives constant speed on each leg and a change of direction at each endpoint. Wave functions come later.

Rotation adds a turn around Y, the upright axis:

```gdscript
rotate_y(rotation_speed * delta)
```

`rotation_speed` sets the rate. Multiplying by the update's time interval gives the turn to add now. This runs alongside the translation.

Scale changes the visible cube's size:

```gdscript
var size_factor: float = lerp(1.0 - pulse_scale, 1.0 + pulse_scale, t)
_apply_pulse(size_factor)
```

With `pulse_scale = 0.3`, the factor travels between 0.7 and 1.3. `_apply_pulse` multiplies the saved mesh scale by that factor. A factor of one gives the starting size. All three directions use the same factor, keeping the cube's proportions.

The demonstration settings are `motion:still`, `motion:slide`, `motion:idle` and `motion:all`; all four use `hold:demo` so they remain available to inspect. All eight pickup cubes in this hall use `motion_curve:lerp`. The translation marker uses straight travel, the rotation marker uses continuous turning, and the scale marker also uses linear interpolation. They have their own clocks and do not control the pickups.

On the platform, four ordinary collectible instances use `motion:all`. Find the rise and fall, the turn and the change in size before collecting one. The task is to recognise how the simple movements combine into a familiar game animation.
