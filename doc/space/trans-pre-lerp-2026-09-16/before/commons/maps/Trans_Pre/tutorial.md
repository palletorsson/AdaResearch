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
time_passed += delta
var bob_offset = sin(time_passed * bob_speed) * bob_height
global_position.y = original_y + bob_offset
```

`time_passed` adds each update's time interval. `sin` supplies a repeating value, and `bob_height` sets the size of the up-and-down movement. Add that offset to the starting height. For this introduction, recognise the resulting motion; the later wave lessons will explain sine in detail.

Rotation adds a turn around Y, the upright axis:

```gdscript
rotate_y(rotation_speed * delta)
```

`rotation_speed` sets the rate. Multiplying by the update's time interval gives the turn to add now. This runs alongside the translation.

Scale changes the visible cube's size:

```gdscript
_pulse_mesh.scale = _pulse_mesh_scale0 * s
```

`_pulse_mesh_scale0` is its saved starting scale. The factor `s` repeats between 0.7 and 1.3 in this example. A factor of one gives the starting size. The same factor is used along all three directions, keeping the cube's proportions.

The demonstration settings are `motion:still`, `motion:slide`, `motion:idle` and `motion:all`; all four use `hold:demo` so they remain available to inspect. The markers alongside them illustrate the same kinds of operation with their own timings.

On the platform, four ordinary collectible instances use `motion:all`. Find the rise and fall, the turn and the change in size before collecting one. The task is to recognise how the simple movements combine into a familiar game animation.
