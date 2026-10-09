# Color Nails

Apply colour to a surface. Palette as data, surface as canvas.

Define a colour.

```gdscript
var red := Color(1.0, 0.0, 0.0)
var custom := Color.from_hsv(0.33, 0.8, 0.7)  # saturated green
```

Colour is four floats — red, green, blue, alpha. The from_hsv constructor takes hue, saturation, value instead.

Build a palette.

```gdscript
var palette: Array[Color] = [
    Color.RED, Color.ORANGE, Color.YELLOW,
    Color.GREEN, Color.BLUE, Color.PURPLE,
]
```

A typed array of Color. Access by index; mutate by assignment.

Apply a colour to a mesh.

```gdscript
func apply_color(mesh: MeshInstance3D, color: Color) -> void:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    mesh.material_override = material
```

material_override replaces the default surface material. The colour is the new albedo.

Select a palette index by nail.

```gdscript
class_name NailColorController extends Node3D

var selected_index: int = 0

func _on_nail_pressed(index: int) -> void:
    selected_index = index
    emit_signal("color_selected", palette[index])
```

One nail per palette entry. Pressing a nail emits the signal with the chosen colour.

Apply to a hand model.

```gdscript
func paint_hand(hand: Node3D, color: Color) -> void:
    for mesh in hand.find_children("", "MeshInstance3D"):
        apply_color(mesh, color)
```

Recursive find for every mesh under the hand. Each is retinted to the selected colour.

Add hue display.

```gdscript
func hsv_of(color: Color) -> Vector3:
    return Vector3(color.h, color.s, color.v)
```

Godot's Color exposes h, s, v directly. The Vector3 packaging is just for display.

Save the selected palette to disk.

```gdscript
func save_palette(path: String) -> void:
    var file := FileAccess.open(path, FileAccess.WRITE)
    for c in palette:
        file.store_line("%f %f %f %f" % [c.r, c.g, c.b, c.a])
```

One colour per line, four floats each. The file is human-readable.

Load a palette back.

```gdscript
func load_palette(path: String) -> Array[Color]:
    var loaded: Array[Color] = []
    var file := FileAccess.open(path, FileAccess.READ)
    while not file.eof_reached():
        var parts := file.get_line().split_whitespace()
        if parts.size() == 4:
            loaded.append(Color(float(parts[0]), float(parts[1]), float(parts[2]), float(parts[3])))
    return loaded
```

Parse four floats per line. The loaded palette can be applied directly to any nail controller.

You can now build a palette, apply colours to meshes, select palette entries by nail, and persist palettes to disk. Color_Grid_Pallet extends colour into a grid-based canvas.

Clone a colour with an offset.

```gdscript
func tinted_clone(base: Color, offset: Vector3) -> Color:
    return Color(base.r + offset.x, base.g + offset.y, base.b + offset.z, base.a).clamp()
```

Offset each channel separately. Clamping keeps the result in valid range.
