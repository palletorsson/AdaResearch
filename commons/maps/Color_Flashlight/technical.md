# Color_Flashlight - Technical Tutorial

*This tutorial builds on Color_Walls (continuous gradients) and closes the color sequence by isolating additive light control as a final implementation pattern before returning to the Lab.*

## The Concept as Scene Data

Color_Flashlight is driven by one map interactable entry:

```json
[" ", " ", " ", " ", " ", "flashlight_demo:180", " ", " ", " ", " ", " "]
```

That artifact resolves to:
- `res://algorithms/effects/flashlight_demo/flashlight_demo.tscn`

The demo scene then instantiates four copies of one grabbable flashlight scene and assigns each a different `light_color`.

## Core Scene Composition

The composition in `flashlight_demo.tscn` is explicit and easy to extend:

```tscn
[node name="RedFlashlight" parent="." instance=ExtResource("1_flashlight")]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -1.5, 0.6, 3)

[node name="ColorSetter" type="Node3D" parent="RedFlashlight"]
script = ExtResource("2_color")
light_color = Color(1, 0, 0, 1)

[node name="GreenFlashlight" parent="." instance=ExtResource("1_flashlight")]
[node name="BlueFlashlight" parent="." instance=ExtResource("1_flashlight")]
[node name="WhiteFlashlight" parent="." instance=ExtResource("1_flashlight")]
```

The scene also adds:
- a dark `WorldEnvironment` (`ambient_light_energy = 0.15`)
- a white `Canvas` target mesh for beam readability

## Color Assignment Script

The color logic lives in `flashlight_color.gd`:

```gdscript
extends Node3D

@export var light_color: Color = Color.WHITE
@export var target_path: NodePath

func _ready() -> void:
	var target_root = _resolve_target_root()

	var spot = _find_spot_light(target_root)
	if spot:
		spot.light_color = light_color
	else:
		push_warning("FlashlightColor: No SpotLight3D found in %s" % target_root.name)

	var lens = _find_lens_mesh(target_root)
	if lens and lens is MeshInstance3D:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = light_color.lerp(Color.WHITE, 0.5)
		mat.emission_enabled = true
		mat.emission = light_color * 0.5
		lens.material_override = mat
```

Two implementation details matter:
1. It sets both the beam (`SpotLight3D.light_color`) and the physical lens tint, so rendered object and emitted light stay visually coherent.
2. It warns if no spotlight is found, which makes broken scene wiring visible during iteration.

## Robust Node Resolution

The helper search is recursive and allows flexible scene nesting:

```gdscript
func _find_spot_light(node: Node) -> SpotLight3D:
	for child in node.get_children():
		if child is SpotLight3D:
			return child
		var found = _find_spot_light(child)
		if found:
			return found
	return null
```

Because this search does not require fixed child names, the same `ColorSetter` script can be reused if the flashlight scene hierarchy changes.

## XR Pickable Flashlight Pattern

Each flashlight instance is itself an XR Tools pickable object (`flashlight.tscn`):

```tscn
[node name="Flashlight" instance=ExtResource("1_pickable")]
freeze = true

[node name="SpotLight3D" type="SpotLight3D" parent="."]
light_energy = 12.0
spot_range = 20.0
spot_angle = 25.0

[node name="GrabPointHandLeft" parent="." instance=ExtResource("4_grab_left")]
[node name="GrabPointHandRight" parent="." instance=ExtResource("3_grab_right")]
```

This gives you:
- standard grab behavior from `pickable.tscn`
- hand-specific grab points for stable controller alignment
- reusable highlight ring support

## Why Dark Context Is Required

The map pairs `flashlight_demo` with `dark_sphere` (`res://commons/primitives/sphere/dark_sphere.tscn`), which is a large black inward sphere:

```tscn
[sub_resource type="SphereMesh" id="SphereMesh_s108s"]
radius = 80.0

[sub_resource type="StandardMaterial3D" id="StandardMaterial3D_r6p2k"]
albedo_color = Color(0, 0, 0, 1)
```

Technically, this removes background visual noise and makes beam/surface interaction readable at a glance.

## Key Takeaway

Color_Flashlight uses a compact pattern that is useful beyond this map: instantiate one reusable XR pickable light object, then configure behavior per-instance through exported color parameters. Combined with a dark environment and neutral target surface, this creates a reliable additive-color test rig where RGB overlap is legible and physically intuitive in VR.
