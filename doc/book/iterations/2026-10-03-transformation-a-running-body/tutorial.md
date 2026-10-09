# A body that changes

In the last lesson, you placed three bodies. They stayed where you put them. Now keep one cube and change its position while the scene runs. Then add a turn and a change in size.

Open `trans_pre.tscn` in the [shared starter](../../../doc/book/studies/ada-xr-starter/README.md). Edit `studies/trans_pre/motion.gd`. The supplied `Cube` makes a 0.6-metre box with a dark mark on one face. The room and the small numerical display are also supplied. Every lesson object is created in code.

## 1. Let the clock run

The study starts with:

```gdscript
var stage := 0
var elapsed := 0.0
```

Run it. The cube stays still, but the elapsed time below it increases.

Point Zero counted frames. Here `_process(delta)` receives the time since the previous frame, in seconds:

```gdscript
    elapsed += delta
```

Adding those intervals gives us a clock. The animation will use seconds, so rendering more frames does not make it run faster.

## 2. Move between two heights

Set `stage` to `1` and run again. The cube rises, reverses and returns. These variables determine its journey:

```gdscript
var centre := Vector3(0, 1.3, 0)
var travel := 0.25
var leg_seconds := 1.5
```

The centre starts 1.3 metres above the floor. Its lower and upper limits are 1.05 and 1.55 metres. `travel` is the distance from the middle to either end.

Inside `_process`, one value carries time into position:

```gdscript
    var t := pingpong(elapsed / leg_seconds + 0.5, 1.0)
    if stage >= 1:
        cube.position.y = lerp(centre.y - travel, centre.y + travel, t)
```

`pingpong` produces a value that travels from 0 to 1 and back at a steady rate. The added `0.5` starts it halfway up. `lerp` uses that value to choose a position between the two heights: 0 gives the lower end, 1 the upper end, and 0.5 their midpoint.

`if stage >= 1` runs this indented line whenever the stage is at least 1. The later stages will keep this movement.

Set `travel` to `0.4`. The cube now reaches 0.9 and 1.7 metres. Restore `0.25`, then set `leg_seconds` to `3.0`. The distance stays fixed; the journey slows. This value is the time between the ends. A complete return takes twice as long. Because we start in the middle, the first arrival takes only half a leg.

Restore `leg_seconds` to `1.5` before continuing.

## 3. Add a turn

Set `stage` to `2`. The same cube keeps rising and falling, and now turns:

```gdscript
    if stage >= 2:
        cube.rotate_y(turn_speed * delta)
```

The dark mark lets you follow a particular face. The turn is around the cube's centre, about the vertical Y axis. Its centre still follows the same path.

`turn_speed` is `TAU / 8.0` radians per second. `TAU` is one complete turn in radians, so this setting takes eight seconds per turn. Multiplying by `delta` gives the angle to add in this frame. Change the divisor to `4.0` for a four-second turn, then restore `8.0`.

## 4. Change size as well

Set `stage` to `3`:

```gdscript
    if stage >= 3:
        var factor: float = lerp(1.0 - pulse, 1.0 + pulse, t)
        cube.scale = Vector3.ONE * factor
```

With `pulse` at `0.3`, the factor travels between 0.7 and 1.3. `Vector3.ONE` is `(1, 1, 1)`: multiplying all three components by the same factor preserves the cube's proportions. Its mesh remains 0.6 metres wide; the displayed width ranges from 0.42 to 0.78 metres.

The assignment writes a new scale each frame. It does not keep multiplying the previous scale. The same `t` drives height and size, so the cube is largest at the top. Turning has its own rate.

Try `pulse` at `0.1`. Keep a version whose timing and extent you like. You can now change a body's position, orientation and size without rebuilding its mesh.

For a short comparison, [replace steady travel with sine](tutorial-sine.md). The endpoints stay fixed; the way the cube arrives changes.

The museum adds touch detection and collection to these operations. This reduced study animates a visible body. In the next hall, a moving surface will also have to support the visitor.
