# Color Rainbow

Move through the spectrum. Hue is an angle on a circle.

Cycle through hue.

```gdscript
var hue_time: float = 0.0

func _process(delta: float) -> void:
    hue_time = fmod(hue_time + delta * 0.2, 1.0)
    var color := Color.from_hsv(hue_time, 1.0, 1.0)
    apply_current_color(color)
```

hue_time wraps at 1.0. At speed 0.2, one full cycle takes 5 seconds.

Build a rainbow emitter.

```gdscript
class_name RainbowEmitter extends Node3D

@export var cycle_speed: float = 0.15
@export var saturation: float = 0.9
@export var value: float = 0.9

var phase: float = 0.0

func _process(delta: float) -> void:
    phase = fmod(phase + delta * cycle_speed, 1.0)
    var current := Color.from_hsv(phase, saturation, value)
    update_emission(current)
```

Per-emitter phase and speed. A row of emitters with staggered phases produces a running gradient.

Stagger phases along a corridor.

```gdscript
func spawn_corridor_of_emitters(count: int, length: float) -> void:
    for i in count:
        var em := RainbowEmitter.new()
        em.position = Vector3(0, 2, -i * length / count)
        em.phase = float(i) / count
        add_child(em)
```

Each emitter starts at a different point in the hue cycle. Over time, they all cycle through the full spectrum.

Interpolate hue between two colours.

```gdscript
func lerp_hue(a: Color, b: Color, t: float) -> Color:
    var ha := a.h; var hb := b.h
    var diff: float = hb - ha
    if abs(diff) > 0.5:
        if diff > 0: ha += 1.0
        else: hb += 1.0
    var new_h: float = fmod(lerp(ha, hb, t), 1.0)
    return Color.from_hsv(new_h, lerp(a.s, b.s, t), lerp(a.v, b.v, t))
```

Handle the wrap-around. Interpolating from red (0.0) to violet (0.83) through the short arc gives the classical rainbow; through the long arc, mud.

Build a temporal gradient on a surface.

```gdscript
func rainbow_texture(width: int, height: int, time_offset: float = 0.0) -> ImageTexture:
    var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
    for x in width:
        var hue: float = fmod(float(x) / width + time_offset, 1.0)
        var color := Color.from_hsv(hue, 1.0, 1.0)
        for y in height:
            image.set_pixel(x, y, color)
    return ImageTexture.create_from_image(image)
```

Horizontal sweep through hue. Shifting time_offset scrolls the gradient.

Drop a grabbable Mario cube in the corridor.

```gdscript
func spawn_mario_cube() -> RigidBody3D:
    var cube := RigidBody3D.new()
    cube.mesh = preload("res://commons/color/mario_cube.tscn").instantiate()
    cube.add_to_group("grabbable")
    add_child(cube)
    return cube
```

A grabbable artifact the learner can pull out of the rainbow and inspect. Its material stays fixed as a colour sample.

Display the current hue value.

```gdscript
func update_hue_label(label: Label3D, color: Color) -> void:
    label.text = "h=%.2f s=%.2f v=%.2f" % [color.h, color.s, color.v]
```

The label updates as the colour changes. Reads like a frequency meter rather than a colour name.

You can now build rainbow emitters with staggered phases, interpolate hue around the circle, generate a rainbow texture, and track hue live. Color_Pillar extends colour into a mixable, stackable form.
