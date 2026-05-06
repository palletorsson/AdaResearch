extends GrabLine
class_name GrabLineDrawer

## GrabLine variant that draws trails from the tip when moved

@export_group("Drawing Settings")
@export var trail_color: Color = Color(0.2, 0.8, 1.0, 0.9)
@export var trail_width: float = 0.02
@export var trail_length: int = 300
@export var min_draw_distance: float = 0.008
@export var fade_trail: bool = true

@export_group("Tip Visual")
@export var drawer_tip_color: Color = Color(0.2, 0.8, 1.0, 1.0)
@export var drawer_tip_size: float = 0.02

var _is_drawing: bool = false
var _trail_points: Array[Vector3] = []
var _trail_mesh: MeshInstance3D
var _trail_material: StandardMaterial3D
var _drawer_tip_mesh: MeshInstance3D
var _drawer_tip_light: OmniLight3D
var _last_draw_pos: Vector3

func _ready() -> void:
	super()
	_setup_drawer_tip()
	_setup_trail()

func _setup_drawer_tip() -> void:
	if not _tip_marker:
		return

	_drawer_tip_mesh = MeshInstance3D.new()
	_drawer_tip_mesh.name = "DrawerTipMesh"
	var sphere = SphereMesh.new()
	sphere.radius = drawer_tip_size
	sphere.height = drawer_tip_size * 2
	_drawer_tip_mesh.mesh = sphere

	var mat = StandardMaterial3D.new()
	mat.albedo_color = drawer_tip_color
	mat.emission_enabled = true
	mat.emission = drawer_tip_color
	mat.emission_energy_multiplier = 1.5
	_drawer_tip_mesh.material_override = mat
	_tip_marker.add_child(_drawer_tip_mesh)

	_drawer_tip_light = OmniLight3D.new()
	_drawer_tip_light.name = "DrawerTipLight"
	_drawer_tip_light.light_color = drawer_tip_color
	_drawer_tip_light.light_energy = 0.3
	_drawer_tip_light.omni_range = 0.2
	_tip_marker.add_child(_drawer_tip_light)

func _setup_trail() -> void:
	_trail_mesh = MeshInstance3D.new()
	_trail_mesh.name = "TrailMesh"
	_trail_mesh.top_level = true
	get_tree().root.call_deferred("add_child", _trail_mesh)

	_trail_material = StandardMaterial3D.new()
	_trail_material.albedo_color = trail_color
	_trail_material.emission_enabled = true
	_trail_material.emission = trail_color
	_trail_material.emission_energy_multiplier = 1.5
	_trail_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_trail_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_trail_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_trail_mesh.material_override = _trail_material

func _process(delta: float) -> void:
	super(delta)

	# Draw when tip is grabbed and being moved
	var should_draw = _tip_grabbed

	if should_draw:
		_is_drawing = true
		_update_tip_glow(true)
		_add_trail_point()
	else:
		_is_drawing = false
		_update_tip_glow(false)

	_update_trail_mesh()

func _add_trail_point() -> void:
	var tip_pos = get_tip_position()

	if _trail_points.is_empty() or tip_pos.distance_to(_last_draw_pos) > min_draw_distance:
		_trail_points.push_front(tip_pos)
		_last_draw_pos = tip_pos

		if _trail_points.size() > trail_length:
			_trail_points.resize(trail_length)

func _update_trail_mesh() -> void:
	if _trail_points.size() < 2 or not _trail_mesh:
		return

	var vertices = PackedVector3Array()
	var colors = PackedColorArray()
	var normals = PackedVector3Array()

	for i in range(_trail_points.size() - 1):
		var p1 = _trail_points[i]
		var p2 = _trail_points[i + 1]

		var dir = (p2 - p1).normalized()
		var up = Vector3.UP
		if abs(dir.dot(up)) > 0.9:
			up = Vector3.RIGHT
		var right = dir.cross(up).normalized() * trail_width * 0.5

		var alpha1 = 1.0
		var alpha2 = 1.0
		if fade_trail:
			alpha1 = 1.0 - (float(i) / float(_trail_points.size()))
			alpha2 = 1.0 - (float(i + 1) / float(_trail_points.size()))

		var color1 = Color(trail_color.r, trail_color.g, trail_color.b, trail_color.a * alpha1)
		var color2 = Color(trail_color.r, trail_color.g, trail_color.b, trail_color.a * alpha2)

		var v1 = p1 - right
		var v2 = p1 + right
		var v3 = p2 - right
		var v4 = p2 + right
		var normal = dir.cross(right).normalized()

		vertices.append(v1); colors.append(color1); normals.append(normal)
		vertices.append(v2); colors.append(color1); normals.append(normal)
		vertices.append(v3); colors.append(color2); normals.append(normal)

		vertices.append(v2); colors.append(color1); normals.append(normal)
		vertices.append(v4); colors.append(color2); normals.append(normal)
		vertices.append(v3); colors.append(color2); normals.append(normal)

	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_NORMAL] = normals

	var arr_mesh = ArrayMesh.new()
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	_trail_mesh.mesh = arr_mesh

func _update_tip_glow(active: bool) -> void:
	if _drawer_tip_mesh and _drawer_tip_mesh.material_override:
		var mat = _drawer_tip_mesh.material_override as StandardMaterial3D
		mat.emission_energy_multiplier = 3.0 if active else 1.5

	if _drawer_tip_light:
		_drawer_tip_light.light_energy = 0.8 if active else 0.3

func clear_trail() -> void:
	_trail_points.clear()
	if _trail_mesh:
		_trail_mesh.mesh = null

func _exit_tree() -> void:
	if _trail_mesh and is_instance_valid(_trail_mesh):
		_trail_mesh.queue_free()
