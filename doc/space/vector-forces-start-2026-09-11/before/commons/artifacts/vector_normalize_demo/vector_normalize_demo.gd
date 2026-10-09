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

## DNA (stage 2 — variation, promoted 2026-07-29)
##   input_mode      — the vector you are handed. The @identity names input
##                     magnitude as the critical parameter: a long V is
##                     compressed to unit, a short V is stretched to unit, a
##                     unit V is left alone. Direction is held fixed across all
##                     three, so only the claim about magnitude varies.
##   reference_mode  — what "length one" is measured against: a shell you can
##                     see, three great circles, or nothing but the readout.
## Both defaults reproduce the pre-promotion artifact exactly.

const INPUT_MODES: Array[String] = ["long", "short", "unit"]
const REFERENCE_MODES: Array[String] = ["sphere", "rings", "none"]

## The vector handed to the learner (all three share one direction).
##   long  — (1.2, 0.8, 0.4), |V| ≈ 1.49: normalization shrinks it (shipped)
##   short — the same direction at |V| ≈ 0.37: normalization grows it
##   unit  — already length 1: normalization is a no-op, its fixed point
@export_enum("long", "short", "unit") var input_mode: String = "long"

## How unit length is shown.
##   sphere — translucent unit shell plus three wireframe rings (shipped)
##   rings  — the three great circles alone; unit-ness as outline, not volume
##   none   — no reference geometry; |V̂| = 1.000 is claimed only by the numbers
@export_enum("sphere", "rings", "none") var reference_mode: String = "sphere"

const BASE_INPUT: Vector3 = Vector3(1.2, 0.8, 0.4)

var vector_v: Node3D
var unit_vector: Node3D
var unit_sphere: MeshInstance3D
var info_label: Label
var unit_label: Label3D
var _ring_nodes: Array[Node3D] = []
var _ring_materials: Array[StandardMaterial3D] = []

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
	vector_v = spawn_vector(Vector3.ZERO, _input_vector(), Color(0.5, 0.5, 0.6, 0.6), "Vector V")
	
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

	# The reference geometry is always built and only ever hidden, so any mode
	# stays reachable later without tearing the scene down.
	_apply_reference_visibility()

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
	_ring_nodes.append(mmi)
	_ring_materials.append(mat)

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
	# With the shell hidden the slider would be dead, so it drives the rings
	# instead — at the slider's 0.5 rest position they keep their built alpha.
	if reference_mode == "rings":
		for mat in _ring_materials:
			mat.albedo_color.a = val * 0.5

# ── DNA plumbing ──────────────────────────────────────────────────────────────

func _input_vector() -> Vector3:
	if input_mode == "short":
		return BASE_INPUT * 0.25
	if input_mode == "unit":
		return BASE_INPUT.normalized()
	return BASE_INPUT

func _apply_input_vector() -> void:
	# spawn_vector's convention: the end handle sits at vector * SCENE_SCALE.
	var end_node: Node3D = _cached_vector_nodes.get("end")
	if end_node == null:
		return
	end_node.position = _input_vector() * SCENE_SCALE
	var line_container: Node3D = _cached_vector_nodes.get("line_container")
	if line_container and line_container.has_method("refresh_connections"):
		line_container.refresh_connections()

func _apply_reference_visibility() -> void:
	if unit_sphere:
		unit_sphere.visible = (reference_mode == "sphere")
	var rings_on: bool = (reference_mode != "none")
	for ring in _ring_nodes:
		if is_instance_valid(ring):
			ring.visible = rings_on

## Grid config arrives deferred, after _ready(). Nothing here rebuilds the
## scene: both axes are re-applied in place, so an existing placement that
## passes no config (or a config naming neither axis) is left exactly as built.
## Deliberately does NOT chain to the base apply_grid_config — this demo builds
## inline in _ready() rather than in build_scene(), so the base's rebuild() path
## would blank it.
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data == null or config_data.is_empty():
		return
	if config_data.has("input_mode"):
		var new_input: String = str(config_data["input_mode"]).strip_edges().to_lower()
		if INPUT_MODES.has(new_input) and new_input != input_mode:
			input_mode = new_input
			_apply_input_vector()
	if config_data.has("reference_mode"):
		var new_ref: String = str(config_data["reference_mode"]).strip_edges().to_lower()
		if REFERENCE_MODES.has(new_ref) and new_ref != reference_mode:
			reference_mode = new_ref
			_apply_reference_visibility()
