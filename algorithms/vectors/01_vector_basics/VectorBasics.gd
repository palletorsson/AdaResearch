extends "res://algorithms/vectors/shared/vector_scene_base.gd"

const SpringScaleScript = preload("res://algorithms/vectors/shared/gadgets/spring_scale_gadget.gd")

var vector_a: Node3D
var unit_vector: Node3D
var component_vectors := {
	"x": null,
	"y": null,
	"z": null
}
var info_label: Label3D
var spring_gadget: Node3D
var _magnitude_dots: MultiMeshInstance3D
var _magnitude_label: Label3D
static var _mag_dot_mesh: SphereMesh

# Cached references to avoid get_node in _process
var _cached_vector_a_nodes: Dictionary = {}
var _cached_unit_vector_nodes: Dictionary = {}
var _cached_component_nodes: Dictionary = {
	"x": {},
	"y": {},
	"z": {}
}

func _ready():
	super._ready()
	# Half-size for exhibition display
	scale = Vector3(0.5, 0.5, 0.5)

	create_axes(1.5)
	vector_a = spawn_vector(Vector3.ZERO, Vector3(1.5, 1.0, 0.5), Color(0.95, 0.85, 0.2, 1.0), "Vector a")
	unit_vector = spawn_vector(Vector3.ZERO, Vector3(1, 0, 0), Color(1.0, 0.5, 0.85, 1.0), "Unit a", false)
	# Component colors use soft pastels for clarity
	component_vectors["x"] = spawn_vector(Vector3.ZERO, Vector3(1.5, 0, 0), Color(1.0, 0.65, 0.85, 0.85), "a_x", false) # pink
	component_vectors["y"] = spawn_vector(Vector3.ZERO, Vector3(0, 1.0, 0), Color(0.6, 1.0, 0.7, 0.85), "a_y", false) # light green
	component_vectors["z"] = spawn_vector(Vector3.ZERO, Vector3(0, 0, 0.5), Color(0.6, 0.8, 1.0, 0.85), "a_z", false) # light blue

	# Magnitude bracket (dashed arc from origin toward tip)
	_magnitude_dots = _create_magnitude_dots()
	environment_root.add_child(_magnitude_dots)
	_magnitude_label = _create_mag_label()
	info_label = create_info_panel("Vector Basics", Vector3(0, 2.5, -0.8), Vector2(2.4, 1.0), "v = |v| * v-hat", "Magnitude and direction")

	# Spring scale gadget
	spring_gadget = SpringScaleScript.new()
	spring_gadget.position = Vector3(-0.6, 0, 0)
	add_child(spring_gadget)

	# Cache nodes for performance
	_cache_vector_nodes(vector_a, _cached_vector_a_nodes)
	_cache_vector_nodes(unit_vector, _cached_unit_vector_nodes)
	_cache_vector_nodes(component_vectors["x"], _cached_component_nodes["x"])
	_cache_vector_nodes(component_vectors["y"], _cached_component_nodes["y"])
	_cache_vector_nodes(component_vectors["z"], _cached_component_nodes["z"])

func _process(_delta):
	var vec = _get_vector_fast(vector_a, _cached_vector_a_nodes)
	_update_unit_vector(vec)
	_update_components(vec)
	_update_magnitude_arc(vec)
	_update_info(vec)
	if spring_gadget:
		spring_gadget.update_from_vectors(vec, Vector3.ZERO)

func _cache_vector_nodes(arrow: Node3D, cache_dict: Dictionary):
	if arrow == null: return
	cache_dict["start"] = arrow.get_node_or_null("lineContainer/GrabSphere")
	cache_dict["end"] = arrow.get_node_or_null("lineContainer/GrabSphere2")
	cache_dict["line_container"] = arrow.get_node_or_null("lineContainer")

func _get_vector_fast(arrow: Node3D, cache_dict: Dictionary) -> Vector3:
	# Faster version of get_vector using cached nodes
	var start: Node3D = cache_dict.get("start")
	var end: Node3D = cache_dict.get("end")
	if start and end:
		return end.global_position - start.global_position
	# Fallback if cache failed (shouldn't happen if structure is static)
	if arrow.has_method("get_vector"):
		return arrow.get_vector()
	return Vector3.ZERO

func _update_vector_fast(_arrow: Node3D, vector: Vector3, cache_dict: Dictionary):
	var end_node: Node3D = cache_dict.get("end")
	if end_node:
		end_node.position = vector
	var line_container: Node3D = cache_dict.get("line_container")
	if line_container and line_container.has_method("refresh_connections"):
		line_container.refresh_connections()

func _update_unit_vector(vec: Vector3):
	var magnitude = vec.length()
	if magnitude > 0.001:
		var hat = vec / magnitude
		_update_vector_fast(unit_vector, hat, _cached_unit_vector_nodes)
	else:
		_update_vector_fast(unit_vector, Vector3.ZERO, _cached_unit_vector_nodes)

func _update_components(vec: Vector3):
	_update_vector_fast(component_vectors["x"], Vector3(vec.x, 0.0, 0.0), _cached_component_nodes["x"])
	_update_vector_fast(component_vectors["y"], Vector3(0.0, vec.y, 0.0), _cached_component_nodes["y"])
	_update_vector_fast(component_vectors["z"], Vector3(0.0, 0.0, vec.z), _cached_component_nodes["z"])

func _update_info(vec: Vector3):
	var magnitude = vec.length()
	var hat = vec / magnitude if magnitude > 0.001 else Vector3.ZERO
	var builder := []
	builder.append("a = (%.2f, %.2f, %.2f)" % [vec.x, vec.y, vec.z])
	builder.append("|a| = %.2f" % magnitude)
	builder.append("a-hat = (%.2f, %.2f, %.2f)" % [hat.x, hat.y, hat.z])
	builder.append("x: %.2f  y: %.2f  z: %.2f" % [vec.x, vec.y, vec.z])
	info_label.text = "\n".join(builder)

# â”€â”€ Magnitude arc (dotted quarter-arc from X-axis toward vector) â”€â”€

func _create_magnitude_dots() -> MultiMeshInstance3D:
	if _mag_dot_mesh == null:
		_mag_dot_mesh = SphereMesh.new()
		_mag_dot_mesh.radius = 0.008
		_mag_dot_mesh.height = 0.016
		_mag_dot_mesh.radial_segments = 6
		_mag_dot_mesh.rings = 3
	var mmi = MultiMeshInstance3D.new()
	mmi.name = "MagnitudeArc"
	mmi.multimesh = MultiMesh.new()
	mmi.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	mmi.multimesh.mesh = _mag_dot_mesh
	mmi.multimesh.instance_count = 24
	mmi.multimesh.visible_instance_count = 0
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.95, 0.85, 0.2, 0.6)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mmi.material_override = mat
	return mmi

func _create_mag_label() -> Label3D:
	var label = Label3D.new()
	label.text = "|a|"
	label.font_size = 14
	label.modulate = Color(0.95, 0.85, 0.2, 0.9)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.render_priority = 100
	label.outline_size = 2
	label.outline_modulate = Color(0, 0, 0, 0.6)
	environment_root.add_child(label)
	return label

func _update_magnitude_arc(vec: Vector3):
	var mag = vec.length()
	if mag < 0.01:
		_magnitude_dots.multimesh.visible_instance_count = 0
		_magnitude_label.visible = false
		return
	_magnitude_label.visible = true
	# Arc radius = 0.3 of magnitude (so it sits inside the vector)
	var arc_radius = mag * 0.35
	var num_dots = 16
	_magnitude_dots.multimesh.visible_instance_count = num_dots
	# Arc sweeps from +X axis toward vector direction in the XY plane of the vector
	var dir = vec.normalized()
	var x_axis = Vector3.RIGHT
	for i in range(num_dots):
		var t = float(i) / float(num_dots - 1)
		var p = x_axis.slerp(dir, t) * arc_radius
		_magnitude_dots.multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY, p))
	# Label at midpoint of arc, slightly outward
	var mid_dir = x_axis.slerp(dir, 0.5).normalized()
	_magnitude_label.position = mid_dir * (arc_radius + 0.04)
	_magnitude_label.text = "|a| = %.2f" % mag
