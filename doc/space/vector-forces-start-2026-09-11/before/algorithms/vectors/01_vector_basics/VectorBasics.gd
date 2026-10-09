extends "res://algorithms/vectors/shared/vector_scene_base.gd"

# @identity
# essence: v = |v| * v-hat. A vector is magnitude times direction. Decompose into (x,y,z) components.
# desire: To grab an arrow and stretch it — watching magnitude, unit vector, and components all update as one system.
# critical_parameter: The dragged endpoint of vector_a. Its position simultaneously defines magnitude, direction, and all three components.
# triggers: Drag endpoint → magnitude arc sweeps, unit vector rescales, component arrows resize along axes, spring gadget deflects
# emerges: The magnitude arc dotting from the x-axis toward the vector tip. The spring scale responding to vector length like a physical instrument.
# needs: Grabbable vector endpoint [has], component decomposition [has], spring scale gadget [has], reading axis that hides/shows the components [has, 2026-07-29]. Missing: an in-world VR button to switch reading without a map edit.
# relationships: Entry point for all vector artifacts. Foundation for basis_vectors_rig (decomposition) and dot_product_projector (magnitude in dot product formula).
# truth: A vector is not a number and not a point. It is a displacement — a difference between two positions, carrying both how far and which way.

const SpringScaleScript = preload("res://algorithms/vectors/shared/gadgets/spring_scale_gadget.gd")

# ── DNA (promoted 2026-07-29, stage 2) ───────────────────────────────────────
# reading — which decomposition the bench asserts is what a vector IS.
#   full      every apparatus at once (the historical build)
#   polar     v = |v| * v-hat: magnitude arc, unit vector, spring scale. No components.
#   cartesian v = (x, y, z): the three component arrows. No unit vector, no arc, no spring.
#   bare      the arrow and the axes. Refuses both decompositions; a vector is a displacement.
# The artifact's own truth is "a vector is not a number and not a point" — which
# reading you leave on is the claim about what it is instead.
@export_enum("full", "polar", "cartesian", "bare") var reading: String = "full"

# reference — the direction the magnitude arc sweeps FROM. It was hard-coded to
# Vector3.RIGHT, quietly privileging +X as the frame every angle is read against.
#   x / y / z  a chosen world axis
#   ground     the vector's own horizontal shadow, so the arc reads elevation
@export_enum("x", "y", "z", "ground") var reference: String = "x"

var vector_a: Node3D
var unit_vector: Node3D
var component_vectors := {
	"x": null,
	"y": null,
	"z": null
}
var info_label: Label
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

func _ready() -> void:
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

	_apply_reading()

func _process(_delta):
	var vec = _get_vector_fast(vector_a, _cached_vector_a_nodes)
	_update_unit_vector(vec)
	_update_components(vec)
	_update_magnitude_arc(vec)
	_update_info(vec)
	if spring_gadget:
		spring_gadget.update_from_vectors(vec, Vector3.ZERO)

func _cache_vector_nodes(arrow: Node3D, cache_dict: Dictionary) -> void:
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

func _update_vector_fast(_arrow: Node3D, vector: Vector3, cache_dict: Dictionary) -> void:
	var end_node: Node3D = cache_dict.get("end")
	if end_node:
		end_node.position = vector
	var line_container: Node3D = cache_dict.get("line_container")
	if line_container and line_container.has_method("refresh_connections"):
		line_container.refresh_connections()

func _update_unit_vector(vec: Vector3) -> void:
	var magnitude = vec.length()
	if magnitude > 0.001:
		var hat = vec / magnitude
		_update_vector_fast(unit_vector, hat, _cached_unit_vector_nodes)
	else:
		_update_vector_fast(unit_vector, Vector3.ZERO, _cached_unit_vector_nodes)

func _update_components(vec: Vector3) -> void:
	_update_vector_fast(component_vectors["x"], Vector3(vec.x, 0.0, 0.0), _cached_component_nodes["x"])
	_update_vector_fast(component_vectors["y"], Vector3(0.0, vec.y, 0.0), _cached_component_nodes["y"])
	_update_vector_fast(component_vectors["z"], Vector3(0.0, 0.0, vec.z), _cached_component_nodes["z"])

func _update_info(vec: Vector3) -> void:
	if info_label == null:
		return
	var magnitude = vec.length()
	var hat = vec / magnitude if magnitude > 0.001 else Vector3.ZERO
	var builder := []
	builder.append("a = (%.2f, %.2f, %.2f)" % [vec.x, vec.y, vec.z])
	builder.append("|a| = %.2f" % magnitude)
	if _shows_direction():
		builder.append("a-hat = (%.2f, %.2f, %.2f)" % [hat.x, hat.y, hat.z])
	if _shows_components():
		builder.append("x: %.2f  y: %.2f  z: %.2f" % [vec.x, vec.y, vec.z])
	info_label.text = "\n".join(builder)

# ── Reading (which decomposition the bench argues for) ──────────────────────

func _shows_direction() -> bool:
	return reading == "full" or reading == "polar"

func _shows_components() -> bool:
	return reading == "full" or reading == "cartesian"

## Show/hide the apparatus that belongs to the current reading. Pure visibility —
## every node stays built and stays updated, so switching reading is instant and
## "full" is byte-for-byte the historical scene.
func _apply_reading() -> void:
	var show_polar: bool = _shows_direction()
	var show_cart: bool = _shows_components()
	if unit_vector:
		unit_vector.visible = show_polar
	for key in ["x", "y", "z"]:
		var comp = component_vectors.get(key)
		if comp is Node3D:
			(comp as Node3D).visible = show_cart
	if _magnitude_dots:
		_magnitude_dots.visible = show_polar
	if _magnitude_label:
		_magnitude_label.visible = show_polar
	if spring_gadget:
		spring_gadget.visible = show_polar

## The direction the magnitude arc sweeps from — the frame the angle is read
## against. There is no privileged one; "x" is only the historical default.
func _reference_axis(vec: Vector3) -> Vector3:
	var axis: Vector3 = Vector3.RIGHT
	if reference == "y":
		axis = Vector3.UP
	elif reference == "z":
		axis = Vector3.BACK
	elif reference == "ground":
		var flat: Vector3 = Vector3(vec.x, 0.0, vec.z)
		if flat.length() > 0.001:
			axis = flat.normalized()
	return axis

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

func _update_magnitude_arc(vec: Vector3) -> void:
	if _magnitude_dots == null or _magnitude_label == null:
		return
	if not _magnitude_dots.visible:
		return  # reading hides the arc; leave it alone
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
	# Arc sweeps from the reference axis toward the vector direction
	var dir = vec.normalized()
	var x_axis: Vector3 = _reference_axis(vec)
	for i in range(num_dots):
		var t = float(i) / float(num_dots - 1)
		var p = x_axis.slerp(dir, t) * arc_radius
		_magnitude_dots.multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY, p))
	# Label at midpoint of arc, slightly outward
	var mid_dir = x_axis.slerp(dir, 0.5).normalized()
	_magnitude_label.position = mid_dir * (arc_radius + 0.04)
	_magnitude_label.text = "|a| = %.2f" % mag

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


## Deliberately does NOT chain to the base implementation: the base rebuild()
## re-runs build_scene(), which this subclass does not use (it builds inline in
## _ready), so chaining would empty every shipped placement. Both axes here are
## applied live, so nothing is ever torn down.
func apply_grid_config(config: Dictionary) -> void:
	if config == null or config.is_empty():
		return
	if config.has("reference"):
		var r: String = str(config["reference"])
		if r in ["x", "y", "z", "ground"]:
			reference = r  # read per frame; no rebuild
	if config.has("reading"):
		var m: String = str(config["reading"])
		if m in ["full", "polar", "cartesian", "bare"] and m != reading:
			reading = m
			# Only re-dress once _ready has actually built the scene.
			if unit_vector != null:
				_apply_reading()
