# Color Pillar

Pillars collect colour. Mixing reveals process.

Build a pillar of coloured segments.

```gdscript
class_name ColorPillar extends Node3D

@export var segments: int = 12

func _ready() -> void:
    for i in segments:
        var segment := MeshInstance3D.new()
        segment.mesh = CylinderMesh.new()
        segment.position.y = i * 0.4
        var hue: float = float(i) / segments
        var mat := StandardMaterial3D.new()
        mat.albedo_color = Color.from_hsv(hue, 0.9, 0.9)
        segment.material_override = mat
        add_child(segment)
```

Twelve segments. Each carries a different hue. The stack reads as a vertical palette.

Grab a colour stick from the pillar.

```gdscript
class_name ColorStick extends RigidBody3D

@export var source_color: Color

func _on_grab_released() -> void:
    apply_to_world(source_color)
```

Releasing the stick applies its colour to whatever it touches. The stick becomes a paint-pickup.

Mix two colours additively.

```gdscript
func mix_additive(a: Color, b: Color) -> Color:
    return Color(
        min(1.0, a.r + b.r),
        min(1.0, a.g + b.g),
        min(1.0, a.b + b.b),
    )
```

Red plus green makes yellow. Red plus green plus blue makes white. This is how light mixes.

Mix two colours subtractively.

```gdscript
func mix_subtractive(a: Color, b: Color) -> Color:
    return Color(a.r * b.r, a.g * b.g, a.b * b.b)
```

Cyan times magenta makes blue. Paint mixing: each pigment absorbs certain wavelengths. Multiplication models absorption.

Build a mixing station.

```gdscript
class_name MixingStation extends Node3D

var input_colors: Array[Color] = []

func add_input(color: Color) -> void:
    input_colors.append(color)
    recompute_output()

func recompute_output() -> Color:
    if input_colors.is_empty(): return Color.BLACK
    var result: Color = input_colors[0]
    for i in range(1, input_colors.size()):
        result = mix_additive(result, input_colors[i])
    return result
```

Accumulate inputs; recompute on each addition. The output updates continuously.

Visualise a spectrum.

```gdscript
func spawn_spectrum_visualizer() -> void:
    for i in 32:
        var hue: float = float(i) / 32
        var bar := MeshInstance3D.new()
        bar.mesh = BoxMesh.new()
        bar.scale = Vector3(0.1, 1.0, 0.1)
        bar.position = Vector3(i * 0.15, 0, 0)
        var mat := StandardMaterial3D.new()
        mat.albedo_color = Color.from_hsv(hue, 1.0, 1.0)
        bar.material_override = mat
        add_child(bar)
```

Thirty-two vertical bars across the hue circle. A compact spectrum display.

Demonstrate flashlight-dependent colour.

```gdscript
func apply_flashlight_color(target: Node3D, light_color: Color) -> void:
    for mesh in target.find_children("", "MeshInstance3D"):
        var mat: StandardMaterial3D = mesh.material_override
        if mat:
            mat.albedo_color = mix_subtractive(mat.albedo_color, light_color)
```

A red object under green light absorbs most of the illumination and appears dark. The multiplicative mix is physically accurate.

You can now build a pillar of colour samples, grab colour sticks, mix additively or subtractively, display a spectrum, and apply flashlight-dependent colour. Color_Paint extends into gestural application.
