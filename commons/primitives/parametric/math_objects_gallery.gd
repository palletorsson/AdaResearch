extends Node3D


# @identity
# essence: gallery[i] = parametric_surface(u, v, params[variation]) — museum of mathematical forms
# desire: Walk past a curated gallery of parametric surfaces, each with labeled variations
# critical_parameter: variations_per_object — controls how many parameter variants are shown per surface type
# triggers: _ready() generates the full grid of mathematical objects with labels
# emerges: a periodic table of mathematical shapes — comparison reveals what parameters do
# needs: VR walkthrough [has], interactive parameter tweaking [missing]
# relationships: depends on parametric surface generators (breather, Klein, torus knot, etc.); contrasts with sine_space (gallery vs immersive single surface); unlocks mathematical surface literacy
# truth: Every smooth surface is a parametric function of two variables — mathematics made solid.

@export var variations_per_object: int = 3
@export var row_spacing: float = 0.7
@export var col_spacing: float = 0.5
@export var target_size: float = 0.18
@export var base_height: float = 0.08

@export var show_labels: bool = true
@export var label_plate_width: float = 0.32
@export var label_plate_height: float = 0.08
@export var label_plate_color: Color = Color(0.95, 0.95, 0.97, 1.0)
@export var label_text_color: Color = Color(0.08, 0.08, 0.12, 1.0)
@export var label_z_offset: float = -0.18
@export var label_y_offset: float = -0.02

const LabelPlateScene = preload("res://commons/primitives/math_gallery/LabelPlate.tscn")
const PickableScene = preload("res://addons/godot-xr-tools/objects/pickable.tscn")

const OBJECTS := [
	{
		"name": "Dini Surface",
		"scene": "res://commons/primitives/parametric/dini_surface.tscn",
		"formula": "x=a cos u sin v, y=a sin u sin v, z=a(cos v+ln tan(v/2))+b u",
		"variants": [
			{"params": {"b": 0.15}},
			{"params": {"b": 0.22}},
			{"params": {"b": 0.32}}
		]
	},
	{
		"name": "Double Enneper",
		"scene": "res://commons/primitives/parametric/double_enneper.tscn",
		"formula": "x=u-u^3/3+u v^2, y=v-v^3/3+v u^2, z=u^2-v^2",
		"variants": [
			{"params": {"u_max": 1.6, "u_min": -1.6, "v_max": 1.6, "v_min": -1.6}},
			{"params": {"u_max": 2.0, "u_min": -2.0, "v_max": 2.0, "v_min": -2.0}},
			{"params": {"u_max": 2.4, "u_min": -2.4, "v_max": 2.4, "v_min": -2.4}}
		]
	},
	{
		"name": "Parametric",
		"scene": "res://commons/primitives/parametric/parametric.tscn",
		"formula": "x=cos v(1+cos u)sin(v/8), y=sin u sin(v/8)+1.5 cos(v/8)",
		"variants": [
			{"params": {"v_max": 10.0}},
			{"params": {"v_max": 12.57}},
			{"params": {"v_max": 15.0}}
		]
	},
	{
		"name": "Seashell",
		"scene": "res://commons/primitives/parametric/seashell.tscn",
		"formula": "r=s exp(u t), x=r(1-v/2π)cos v cos u, y=r(1-v/2π)cos v sin u",
		"variants": [
			{"params": {"spiral_tightness": 0.12, "shell_opening": 0.08}},
			{"params": {"spiral_tightness": 0.15, "shell_opening": 0.1}},
			{"params": {"spiral_tightness": 0.18, "shell_opening": 0.12}}
		]
	},
	{
		"name": "Wave Torus",
		"scene": "res://commons/primitives/parametric/wave_torus.tscn",
		"formula": "x=(R+r cos v)cos u, y=r sin v, z=(R+r cos v)sin u",
		"variants": [
			{"params": {"wave_amplitude": 0.015, "wave_frequency_u": 6.0}},
			{"params": {"wave_amplitude": 0.02, "wave_frequency_u": 8.0}},
			{"params": {"wave_amplitude": 0.03, "wave_frequency_u": 10.0}}
		]
	},
	{
		"name": "Trefoil Knot",
		"scene": "res://commons/primitives/parametric/trefoil_knot.tscn",
		"formula": "x=sin t+2 sin 2t, y=cos t-2 cos 2t, z=-sin 3t",
		"variants": [
			{"params": {"tube_radius": 0.12}},
			{"params": {"tube_radius": 0.15}},
			{"params": {"tube_radius": 0.18}}
		]
	},
	{
		"name": "Catenoid",
		"scene": "res://commons/primitives/parametric/catenoid.tscn",
		"formula": "x=c cosh(u/c)cos v, y=c cosh(u/c)sin v, z=u",
		"variants": [
			{"params": {"c": 0.45}},
			{"params": {"c": 0.5}},
			{"params": {"c": 0.6}}
		]
	},
	{
		"name": "Helicoid",
		"scene": "res://commons/primitives/parametric/helicoid.tscn",
		"formula": "x=u cos v, y=u sin v, z=p v",
		"variants": [
			{"params": {"pitch": 0.2}},
			{"params": {"pitch": 0.3}},
			{"params": {"pitch": 0.4}}
		]
	},
	{
		"name": "Breather Surface",
		"scene": "res://commons/primitives/parametric/breather_surface.tscn",
		"formula": "Sine-Gordon breather (soliton surface)",
		"variants": [
			{"params": {"aa": 0.3}},
			{"params": {"aa": 0.4}},
			{"params": {"aa": 0.55}}
		]
	},
	{
		"name": "Figure-Eight Knot",
		"scene": "res://commons/primitives/parametric/figure_eight_knot.tscn",
		"formula": "x=(2+cos2t)cos3t, y=(2+cos2t)sin3t, z=sin4t",
		"variants": [
			{"params": {"tube_radius": 0.1}},
			{"params": {"tube_radius": 0.12}},
			{"params": {"tube_radius": 0.14}}
		]
	},
	{
		"name": "Torus Knot",
		"scene": "res://commons/primitives/parametric/torus_knot.tscn",
		"formula": "x=(R+r cos qt)cos pt, y=(R+r cos qt)sin pt, z=r sin qt",
		"variants": [
			{"params": {"p": 2, "q": 3}},
			{"params": {"p": 3, "q": 5}},
			{"params": {"p": 4, "q": 7}}
		]
	}
]

func _ready() -> void:
	_build_gallery()

func _build_gallery() -> void:
	for child in get_children():
		child.queue_free()

	var cols = maxi(1, variations_per_object)
	var rows = OBJECTS.size()
	var width = float(cols - 1) * col_spacing
	var depth = float(rows - 1) * row_spacing
	var origin = Vector3(-width * 0.5, base_height, -depth * 0.5)

	for row in range(rows):
		var obj_def = OBJECTS[row]
		for col in range(cols):
			var obj = _spawn_object(obj_def, col)
			obj.position = origin + Vector3(col * col_spacing, 0.0, row * row_spacing)
			add_child(obj)
			call_deferred("_finalize_object", obj)

		if show_labels:
			var label = _make_label(obj_def)
			label.position = origin + Vector3(width * 0.5, label_y_offset, row * row_spacing + label_z_offset)
			add_child(label)

func _spawn_object(obj_def: Dictionary, variation_idx: int) -> Node3D:
	var scene_path = obj_def["scene"]
	var scene = load(scene_path)
	var instance = scene.instantiate()

	_apply_variation(instance, obj_def, variation_idx)

	var obj: Node3D
	if instance is XRToolsPickable:
		obj = instance
	else:
		var pickable = PickableScene.instantiate()
		pickable.name = obj_def["name"].replace(" ", "")
		pickable.add_child(instance)
		instance.position = Vector3.ZERO
		_ensure_pickable_collision(pickable, instance)
		obj = pickable

	_strip_editor_nodes(obj)
	return obj

func _apply_variation(instance: Node, obj_def: Dictionary, variation_idx: int) -> void:
	var variants: Array = obj_def.get("variants", [])
	if variants.size() > 0:
		var v = variants[variation_idx % variants.size()]
		var params: Dictionary = v.get("params", {})
		for key in params.keys():
			_set_if_has(instance, key, params[key])

	var base_color: Color = _get_color(instance)
	var color = _variant_color(base_color, variation_idx)
	_set_if_has(instance, "base_color", color)

func _variant_color(base: Color, idx: int) -> Color:
	var hsv = _rgb_to_hsv(base)
	var hue_shift = 0.12 * float(idx)
	var sat = clamp(hsv.y * (1.0 - 0.05 * idx), 0.2, 1.0)
	var val = clamp(hsv.z * (1.0 - 0.03 * idx), 0.35, 1.0)
	return _hsv_to_rgb(Vector3(fposmod(hsv.x + hue_shift, 1.0), sat, val))

func _get_color(instance: Node) -> Color:
	if _has_prop(instance, "base_color"):
		return instance.get("base_color")
	return Color(0.8, 0.8, 0.85, 1.0)

func _set_if_has(instance: Node, prop: String, value) -> void:
	if _has_prop(instance, prop):
		instance.set(prop, value)

func _has_prop(instance: Node, prop: String) -> bool:
	for info in instance.get_property_list():
		if info.name == prop:
			return true
	return false

func _normalize_object_scale(obj: Node3D) -> void:
	var mesh = _find_mesh(obj)
	if not mesh:
		return

	var aabb = mesh.get_aabb()
	var mesh_scale = mesh.transform.basis.get_scale()
	var size = Vector3(
		aabb.size.x * mesh_scale.x,
		aabb.size.y * mesh_scale.y,
		aabb.size.z * mesh_scale.z
	)
	var max_dim = max(size.x, max(size.y, size.z))
	if max_dim <= 0.0001:
		return

	var scale = target_size / max_dim
	obj.scale = Vector3.ONE * scale

func _snap_to_floor(obj: Node3D) -> void:
	var mesh = _find_mesh(obj)
	if not mesh:
		return
	var aabb = mesh.get_aabb()
	var min_y = aabb.position.y * mesh.transform.basis.get_scale().y
	obj.position.y = base_height - min_y * obj.scale.y

func _find_mesh(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D and node.mesh:
		return node
	for child in node.get_children():
		var found = _find_mesh(child)
		if found:
			return found
	return null

func _ensure_pickable_collision(pickable: Node3D, mesh_owner: Node) -> void:
	var collision = pickable.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if not collision:
		collision = CollisionShape3D.new()
		collision.name = "CollisionShape3D"
		pickable.add_child(collision)

	var mesh = _find_mesh(mesh_owner)
	if mesh:
		var aabb = mesh.get_aabb()
		var max_dim = max(aabb.size.x, max(aabb.size.y, aabb.size.z))
		var radius = max_dim * 0.6
		var sphere = SphereShape3D.new()
		sphere.radius = max(0.05, radius)
		collision.shape = sphere
		collision.position = Vector3.ZERO

func _update_pickable_collision(obj: Node3D) -> void:
	var collision = obj.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if not collision:
		return
	if collision.shape != null:
		return
	var mesh = _find_mesh(obj)
	if not mesh:
		return
	var aabb = mesh.get_aabb()
	var max_dim = max(aabb.size.x, max(aabb.size.y, aabb.size.z))
	var radius = max_dim * 0.6
	var sphere = SphereShape3D.new()
	sphere.radius = max(0.05, radius)
	collision.shape = sphere

func _strip_editor_nodes(node: Node) -> void:
	for child in node.get_children():
		if child is Camera3D or child is Light3D:
			child.queue_free()
		else:
			_strip_editor_nodes(child)

func _rgb_to_hsv(color: Color) -> Vector3:
	var r = color.r
	var g = color.g
	var b = color.b
	var max_val = max(r, max(g, b))
	var min_val = min(r, min(g, b))
	var delta = max_val - min_val
	var h = 0.0
	var s = 0.0 if max_val == 0.0 else delta / max_val
	var v = max_val
	if delta != 0.0:
		if max_val == r:
			h = (g - b) / delta
		elif max_val == g:
			h = 2.0 + (b - r) / delta
		else:
			h = 4.0 + (r - g) / delta
		h /= 6.0
		if h < 0.0:
			h += 1.0
	return Vector3(h, s, v)

func _hsv_to_rgb(hsv: Vector3) -> Color:
	var h = hsv.x * 6.0
	var s = hsv.y
	var v = hsv.z
	var i = int(h)
	var f = h - i
	var p = v * (1.0 - s)
	var q = v * (1.0 - s * f)
	var t = v * (1.0 - s * (1.0 - f))
	match i % 6:
		0:
			return Color(v, t, p, 1.0)
		1:
			return Color(q, v, p, 1.0)
		2:
			return Color(p, v, t, 1.0)
		3:
			return Color(p, q, v, 1.0)
		4:
			return Color(t, p, v, 1.0)
		_:
			return Color(v, p, q, 1.0)

func _make_label(obj_def: Dictionary) -> Node3D:
	var label = LabelPlateScene.instantiate()
	label.object_name = obj_def.get("name", "Object")
	label.formula = obj_def.get("formula", "")
	label.plate_width = label_plate_width
	label.plate_height = label_plate_height
	label.plate_color = label_plate_color
	label.text_color = label_text_color
	return label

func _finalize_object(obj: Node3D) -> void:
	_normalize_object_scale(obj)
	_snap_to_floor(obj)
	_update_pickable_collision(obj)
