# Color Flashlight

Colour is not property but event. Light hits surface; colour happens.

Spawn a flashlight.

```gdscript
class_name Flashlight extends Node3D

@export var light_color: Color = Color(1.0, 0.95, 0.8)
@export var light_intensity: float = 5.0

var light: SpotLight3D

func _ready() -> void:
    light = SpotLight3D.new()
    light.light_color = light_color
    light.light_energy = light_intensity
    light.spot_range = 8.0
    light.spot_angle = 30.0
    add_child(light)
```

SpotLight3D is Godot's cone-shaped light. Colour, intensity, range, and angle are exposed.

Toggle the flashlight.

```gdscript
var is_on: bool = true

func toggle() -> void:
    is_on = not is_on
    light.visible = is_on
```

When off, the scene goes dark. Objects lose their visible colour.

Change the light's hue.

```gdscript
func set_light_hue(hue: float) -> void:
    light_color = Color.from_hsv(hue, 1.0, 1.0)
    light.light_color = light_color
```

Rotate the flashlight's colour through the spectrum. Surfaces respond differently to each hue.

Observe reflection.

```gdscript
# A red object's material:
var red_mat := StandardMaterial3D.new()
red_mat.albedo_color = Color(1.0, 0.0, 0.0)
red_mat.roughness = 0.5
```

Under white light, the red wall looks red. Under blue light, it looks dark — the red pigment absorbs blue.

Use a per-instance material for MultiMesh.

```gdscript
class_name ColoredMultiMesh extends MultiMeshInstance3D

func _ready() -> void:
    multimesh = MultiMesh.new()
    multimesh.transform_format = MultiMesh.TRANSFORM_3D
    multimesh.use_colors = true
    multimesh.instance_count = 64

func set_instance_color(i: int, color: Color) -> void:
    multimesh.set_instance_color(i, color)
```

Each instance carries its own colour. The GPU renders them all in one draw call.

Integrate NextCube's colour code.

```gdscript
func apply_next_cube_palette(cube: Node3D, palette_index: int) -> void:
    var palette := NEXT_CUBE_PALETTE
    cube.set_cube_color(palette[palette_index])
```

NEXT_CUBE_PALETTE is a constant array of colours. The index selects one; the cube's method applies it to all sub-meshes.

Toggle fluorescence on a material.

```gdscript
func make_fluorescent(mesh: MeshInstance3D, emission_color: Color, energy: float = 1.5) -> void:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color.WHITE
    mat.emission_enabled = true
    mat.emission = emission_color
    mat.emission_energy_multiplier = energy
    mesh.material_override = mat
```

Emissive materials appear to glow. Fluorescent paint under UV is the physical analogue.

Trigger a completion cue.

```gdscript
func on_sequence_complete() -> void:
    var save := get_tree().get_first_node_in_group("save_manager")
    save.mark_milestone("color_complete")
    unlock_next_sequences(["forces", "array_tutorial", "wavefunctions"])
```

Completing this map is the gate that opens Forces, Array Tutorial, and Wavefunctions. The save manager records the milestone.

You can now build a flashlight, toggle it, change its hue, render MultiMesh instances with per-instance colour, and make materials fluorescent. Chamber_Color extends colour into a chamber encounter.

Clone a colour with an offset.

```gdscript
func tinted_clone(base: Color, offset: Vector3) -> Color:
    return Color(base.r + offset.x, base.g + offset.y, base.b + offset.z, base.a).clamp()
```

Offset each channel separately. Clamping keeps the result in valid range.
