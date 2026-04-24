# Random Rotate Random XYZ

Three axes, three independent rolls. Build the orientation generator that proves 3D randomness is qualitatively different.

Declare the triple roll.

```gdscript
class_name TripleRoll
extends Node3D

var x_angle: float = 0.0
var y_angle: float = 0.0
var z_angle: float = 0.0
```

Three angles, three floats. Each is rolled independently.

Roll all three.

```gdscript
func roll() -> void:
    x_angle = randf() * TAU
    y_angle = randf() * TAU
    z_angle = randf() * TAU
    rotation = Vector3(x_angle, y_angle, z_angle)
```

Three calls to randf, three assignments. The resulting orientation is almost never anything the learner would predict.

Animate a continuous roll.

```gdscript
func _process(dt: float) -> void:
    if auto_roll:
        x_angle += randf_range(-1.0, 1.0) * dt
        y_angle += randf_range(-1.0, 1.0) * dt
        z_angle += randf_range(-1.0, 1.0) * dt
        rotation = Vector3(x_angle, y_angle, z_angle)
```

Auto-roll adds noise to the angles each frame. The object tumbles irregularly. No two frames share an orientation.

Expose axis buttons.

```gdscript
func _on_axis_button_pressed(axis: String) -> void:
    match axis:
        "x": x_angle = randf() * TAU
        "y": y_angle = randf() * TAU
        "z": z_angle = randf() * TAU
    rotation = Vector3(x_angle, y_angle, z_angle)
```

Three buttons let the learner reroll one axis at a time. The other two stay put. The interaction isolates each axis.

Sample from hardware entropy.

```gdscript
func hardware_roll() -> float:
    var t := Time.get_ticks_usec()
    return float((t ^ (t >> 7)) & 0xffff) / float(0xffff) * TAU
```

Hardware entropy replaces the PRNG. Same shape, different source. The method swaps cleanly.

Record the roll history.

```gdscript
func log_roll() -> void:
    rolls.append(Vector3(x_angle, y_angle, z_angle))
```

The log stores each orientation. A small panel plots the history as a scatter of rotated arrows.

Show the Euler angles.

```gdscript
func readout_euler(label: Label3D) -> void:
    label.text = "X: %5.1f°\nY: %5.1f°\nZ: %5.1f°" % [
        rad_to_deg(x_angle), rad_to_deg(y_angle), rad_to_deg(z_angle)
    ]
```

The readout shows degrees. Three independent numbers describe the orientation. The tutorial refuses to collapse them into one.

You have seen randomness expand into three dimensions. The next map, Random Walk, turns randomness into a path.
<<</MAP>>>

Save the current orientation as a preset.

```gdscript
func save_preset(name: String) -> void:
    presets[name] = Vector3(x_angle, y_angle, z_angle)
```

Presets capture a favourite orientation. The learner can return to a surprise they liked.

Animate between presets.

```gdscript
func tween_to_preset(name: String) -> void:
    if not presets.has(name): return
    var target: Vector3 = presets[name]
    create_tween().tween_property(self, "rotation", target, 0.8)
```

A tween smoothly rotates from the current angle to the preset. The transition reads as a handwritten arc.
