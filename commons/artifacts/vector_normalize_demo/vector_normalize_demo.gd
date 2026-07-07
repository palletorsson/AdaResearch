# vector_normalize_demo.gd
# Interactive vector normalization visualization
# Same style as VectorBasics - uses vector_scene_base
#
# Shows: V̂ = V / |V| (unit vector in same direction)
#
# @identity
# essence: Side-by-side display of a vector V and its normalized form V̂ = V/|V|, sharing direction but with unit length
# desire: To make the difference between direction and magnitude visible — same arrow, two scales, one geometric purpose
# critical_parameter: input vector magnitude — large input compresses to unit, tiny input expands; both arrive at length 1
# triggers: Any direction reads, only magnitude is removed; zero vector is the singular case where normalization fails
# emerges: Direction as a separable property of vectors — a vector is a magnitude and a unit, and unit vectors compose direction-only spaces
# needs: vector input controls [has], live normalization computation [has], unit-circle/sphere reference [has]
# relationships: Companion to vector_magnitude_demo (already voiced) in forces/Combat_Arena. Foundation for aim and direction artifacts
# truth: Normalization is the act of forgetting how far — keeping only which way. It is direction extracted from the vector.

extends "res://algorithms/vectors/shared/vector_scene_base.gd"

class_name VectorNormalizeDemo

var vector_v: Node3D
var unit_vector: Node3D
var unit_sphere: MeshInstance3D
var info_label: Label
var unit_label: Label3D

# Cached references
var _cached_vector_nodes: Dictionary = {}
var _cached_unit_nodes: Dictionary = {}

const ControlPanelScript = preload("res://commons/ui/control_panel.gd")
var _sphere_slider: Node

func _ready():
	super._ready()
	create_axes(1.5)
	
	# Create unit sphere (radius 1, transparent)
	_create_unit_sphere()
	
	# Main vector - faded (original)
	vector_v = spawn_vector(Vector3.ZERO, Vector3(1.2, 0.8, 0.4), Color(0.5, 0.5, 0.6, 0.6), "Vector V")
	
	# Unit vector - bright green
	unit_vector = spawn_vector(Vector3.ZERO, Vector3(1, 0, 0), Color(0.2, 1.0, 0.5, 1.0), "Unit V", false)
	
	# Info panel
	info_label = create_info_panel("Normalization", Vector3(0.6, 1.0, 0.0))
	
	# Unit vector label
	unit_label = Label3D.new()
	unit_label.pixel_size = 0.0025
	unit_label.font_size = 28
	unit_label.text = "VÌ‚"
	unit_label.modulate = Color(0.2, 1.0, 0.5)
	unit_label.outline_size = 8
	unit_label.outline_modulate = Color(0, 0, 0, 0.8)
	unit_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(unit_label)
	
	# Cache nodes
	_cache_vector_nodes(vector_v, _cached_vector_nodes)
	_cache_vector_nodes(unit_vector, _cached_unit_nodes)

	_setup_controls()

func _create_unit_sphere():
	unit_sphere = MeshInstance3D.new()
	unit_sphere.name = "UnitSphere"
	
	var sphere = SphereMesh.new()
	sphere.radius = 1.0 * SCENE_SCALE
	sphere.height = 2.0 * SCENE_SCALE
	sphere.radial_segments = 32
	sphere.rings = 16
	unit_sphere.mesh = sphere
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 1.0, 1.0, 0.08)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	unit_sphere.material_override = mat
	
	environment_root.add_child(unit_sphere)
	
	# Add wireframe rings for visibility
	_create_wireframe_ring(Vector3.UP, Color(0.4, 0.4, 0.5, 0.25))
	_create_wireframe_ring(Vector3.RIGHT, Color(0.4, 0.4, 0.5, 0.25))
	_create_wireframe_ring(Vector3.FORWARD, Color(0.4, 0.4, 0.5, 0.25))

func _create_wireframe_ring(normal: Vector3, color: Color):
	var segments = 48
	var radius = 1.0 * SCENE_SCALE

	# All segments have the same chord length
	var angle_step = TAU / segments
	var sample_p1: Vector3
	var sample_p2: Vector3
	if normal == Vector3.UP:
		sample_p1 = Vector3(1, 0, 0) * radius
		sample_p2 = Vector3(cos(angle_step), 0, sin(angle_step)) * radius
	elif normal == Vector3.RIGHT:
		sample_p1 = Vector3(0, 1, 0) * radius
		sample_p2 = Vector3(0, cos(angle_step), sin(angle_step)) * radius
	else:
		sample_p1 = Vector3(1, 0, 0) * radius
		sample_p2 = Vector3(cos(angle_step), sin(angle_step), 0) * radius
	var seg_length = (sample_p2 - sample_p1).length()

	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.003
	cylinder.bottom_radius = 0.003
	cylinder.height = seg_length

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = cylinder
	mm.instance_count = segments

	for i in range(segments):
		var angle1 = TAU * i / segments
		var angle2 = TAU * (i + 1) / segments

		var p1: Vector3
		var p2: Vector3

		if normal == Vector3.UP:
			p1 = Vector3(cos(angle1), 0, sin(angle1)) * radius
			p2 = Vector3(cos(angle2), 0, sin(angle2)) * radius
		elif normal == Vector3.RIGHT:
			p1 = Vector3(0, cos(angle1), sin(angle1)) * radius
			p2 = Vector3(0, cos(angle2), sin(angle2)) * radius
		else:
			p1 = Vector3(cos(angle1), sin(angle1), 0) * radius
			p2 = Vector3(cos(angle2), sin(angle2), 0) * radius

		var xf := Transform3D()
		xf.origin = (p1 + p2) / 2.0

		var direction = p2 - p1
		if direction.length() > 0.001:
			var up = Vector3.UP
			if abs(direction.normalized().dot(up)) > 0.99:
				up = Vector3.FORWARD
			xf.basis = Basis.looking_at(direction, up) * Basis(Vector3.RIGHT, PI / 2)

		mm.set_instance_transform(i, xf)

	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm

	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mmi.material_override = mat

	environment_root.add_child(mmi)

func _process(_delta):
	var vec = _get_vector_fast(vector_v, _cached_vector_nodes)
	_update_unit_vector(vec)
	_update_info(vec)
	_update_unit_label(vec)

func _cache_vector_nodes(arrow: Node3D, cache_dict: Dictionary):
	if arrow == null: return
	cache_dict["start"] = arrow.get_node_or_null("lineContainer/GrabSphere")
	cache_dict["end"] = arrow.get_node_or_null("lineContainer/GrabSphere2")
	cache_dict["line_container"] = arrow.get_node_or_null("lineContainer")

func _get_vector_fast(arrow: Node3D, cache_dict: Dictionary) -> Vector3:
	var start: Node3D = cache_dict.get("start")
	var end: Node3D = cache_dict.get("end")
	if start and end:
		return end.global_position - start.global_position
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
		var unit = vec / magnitude
		_update_vector_fast(unit_vector, unit, _cached_unit_nodes)
	else:
		_update_vector_fast(unit_vector, Vector3.ZERO, _cached_unit_nodes)

func _update_info(vec: Vector3):
	var magnitude = vec.length()
	var unit = vec.normalized() if magnitude > 0.001 else Vector3.ZERO
	
	var builder := []
	builder.append("V = (%.2f, %.2f, %.2f)" % [vec.x, vec.y, vec.z])
	builder.append("|V| = %.3f" % magnitude)
	builder.append("")
	builder.append("VÌ‚ = V / |V|")
	builder.append("VÌ‚ = (%.2f, %.2f, %.2f)" % [unit.x, unit.y, unit.z])
	builder.append("|VÌ‚| = 1.000")
	info_label.text = "\n".join(builder)

func _update_unit_label(vec: Vector3):
	var magnitude = vec.length()
	if magnitude > 0.001:
		var unit = vec.normalized()
		# Position at tip of unit vector, offset toward player
		unit_label.position = unit * 0.5 * SCENE_SCALE + Vector3(0, 0.06, 0.08)
		unit_label.visible = true
	else:
		unit_label.visible = false

func _setup_controls():
	# Canonical Braun ControlPanel (was a RackTemplates panel).
	var panel = ControlPanelScript.new()
	panel.title = "NORMALIZE"
	panel.position = Vector3(0, 0.5, 0.6)
	add_child(panel)
	_sphere_slider = panel.add_slider("SPHERE", "SPHERE")
	if _sphere_slider and _sphere_slider.has_method("set_normalized_value"):
		_sphere_slider.set_normalized_value(0.5)
	if _sphere_slider and _sphere_slider.has_signal("slider_moved"):
		_sphere_slider.slider_moved.connect(_on_sphere_opacity_changed)

func _on_sphere_opacity_changed():
	var val = _sphere_slider.get_normalized_value()
	if unit_sphere and unit_sphere.material_override:
		unit_sphere.material_override.albedo_color.a = val * 0.15

func apply_grid_config(config_data: Dictionary) -> void:
	pass
