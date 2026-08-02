# axis_translation_cube.gd
# Demonstrates translation along a single axis
# Shows: position changes from start → end with wait states
# Formula: position.axis = start + direction * progress
# Creates cube directly with Grid shader (correct sizing)

# @identity
# essence: position[axis] = start + direction * lerp(0, 1, progress) — pure single-axis translation animated
# desire: learner reads the label and watches the cube traverse one axis, internalising what "X translation" means
# critical_parameter: axis — X, Y, or Z; determines which coordinate changes while the others stay fixed
# triggers: VR speed slider (slider_horizontal) adjusts lerp speed live; ghost trail shows recent positions
# emerges: the orthogonality of axes — moving on X changes nothing about Y or Z, visually confirmed
# needs: [has slider_horizontal VR speed slider [has], has Label3D [has], trail ghosts [has]]
# relationships: shared script for x_translation_cube, y_translation_cube, z_translation_cube map artifacts
# truth: translation is the additive group action on position — it changes location while preserving orientation

extends Node3D

class_name AxisTranslationCube

const GRID_SHADER = preload("res://commons/resourses/shaders/Grid.gdshader")

enum Axis { X, Y, Z }
enum State { MOVING_POSITIVE, WAIT_POSITIVE, MOVING_NEGATIVE, WAIT_NEGATIVE }

## Which axis the cube translates along
@export var axis: Axis = Axis.Y
## Side length of the cube in meters
@export_range(0.01, 1.0, 0.01) var cube_size: float = 0.15
## Maximum distance from center the cube travels
@export_range(0.05, 2.0, 0.05) var travel_distance: float = 0.4
## Movement speed in units per second
@export_range(0.01, 5.0, 0.01) var travel_speed: float = 0.3
## Seconds to pause at each end before reversing
@export_range(0.0, 10.0, 0.1) var wait_time: float = 1.0
## Base color of the cube wireframe
@export var cube_color: Color = Color(0.3, 0.6, 1.0)
## Whether to show the rail and end markers
@export var show_rail: bool = true
## Whether to show trail ghost positions
@export var show_trail: bool = true
## Number of trail ghost positions to display
@export_range(1, 20) var trail_count: int = 4

# ── STAGE-2 DNA ───────────────────────────────────────────────────────────────
# ONE BODY, FOUR NAMES. x_translation_cube, y_translation_cube, z_translation_cube and
# axis_translation_cube are the same script and the same scene folder; the only thing that
# differs between the four .tscn files is `axis` (0/1/2) and a colour. The family's real
# axis was already here — it was just spelled into the lookup name instead of declared, so
# the sweep could never turn it and the registry read as four singletons at 29 placements.
#
## AXIS — COURSE. Which run of space the displacement happens along, named for what the
## motion MEANS to a standing body rather than for the letter of the coordinate. This is
## the DNA name for `axis` above; set THIS, not `axis`.
##
##   lateral  across, at shoulder height — the rail lies flat, left to right. The cube
##            passes the learner; nothing about it changes but where it is.
##   lift     up and down. THE DEFAULT and the legacy lineage: the rail stands vertical,
##            the cube rises and falls, and the two end markers sit above and below it.
##   depth    toward and away. The rail runs into the picture, so the SAME displacement is
##            read almost entirely as scale — which is the artifact's sharpest lesson and
##            the reason z_translation_cube is the most-placed member of the family.
##
## The rail is 0.95 m long against a 0.15 m cube, so this axis swings the largest element
## in the frame through 90°, and the live label and axis plate both change text with it.
@export_enum("lateral", "lift", "depth") var course: String = "lift"
const COURSES: PackedStringArray = ["lateral", "lift", "depth"]

## AXIS — ACCOUNT. What the artifact leaves standing in the room as evidence that a
## translation happened — the account it gives of its own operation. A still frame cannot
## hold a motion, only what the motion deposits, so this is the axis that actually argues:
## how much of the operation is admitted, and in what register — sampled, swept, terminal,
## written, or withheld.
##
## (Named `account`, not `record`: five instrument artifacts — seismograph, multimeter,
## holographicdisplay, atmosphericmonitoring, dual_display_test — already share a `record`
## axis meaning how much history a readout keeps, on the values instant|window|archive|
## margin. Same word, different question; two of those would have been a real collision.)
##
##   ghost     THE DEFAULT: the guide rail, a green and a red end marker, and four fading
##             ghost cubes shrinking back along the path. The path SAMPLED — the legacy
##             build, byte for byte.
##   sweep     no rail, no ghosts: one continuous wireframe bar the full length of the
##             travel, with the cube inside it. The path as a solid — every position the
##             cube will ever occupy, held at once.
##   terminus  no rail, no ghosts: two full-size cubes pinned at the two extremes and
##             nothing in between. Before and after, the way a textbook figure states a
##             translation — the claim that only the endpoints were ever the point.
##   formula   the operation written out instead of drawn: a raised plate carrying
##             "p'.y = p.y + d" and the interval d runs over, with the rail and the ghosts
##             gone. The algebra as the account.
##   none      the result only. A cube at a position, no rail, no markers, no ghosts, no
##             labels. Nothing in the frame says it ever moved, which is exactly what a
##             translation looks like once you stop watching.
@export_enum("ghost", "sweep", "terminus", "formula", "none") var account: String = "ghost"
const ACCOUNTS: PackedStringArray = ["ghost", "sweep", "terminus", "formula", "none"]

# Set from `account` in _read_dna(); "ghost" leaves all three true, which is the legacy path.
var _want_rail: bool = true
var _want_trail: bool = true
var _want_labels: bool = true

var _cube_mesh: MeshInstance3D
var _cube_material: ShaderMaterial
var _label: Label3D
var _formula_label: Label3D
var _rail: MeshInstance3D
var _start_marker: MeshInstance3D
var _end_marker: MeshInstance3D
var _trail_mm: MultiMesh
var _trail_mmi: MultiMeshInstance3D
var _speed_slider: Node3D
var _created_nodes: Array[Node] = []

var _base_position: Vector3 = Vector3.ZERO
var _current_offset: float = 0.0
var _state: State = State.MOVING_POSITIVE
var _state_timer: float = 0.0
var _trail_history: Array[float] = []


func _ready():
	_read_dna()
	_base_position = Vector3(cube_size / 2.0, cube_size / 2.0, cube_size / 2.0)
	_create_cube()
	_create_rail()
	_create_labels()
	_create_trail_ghosts()
	_setup_controls()
	# Appended LAST, so every node index and position above is untouched on the legacy
	# path. "ghost" falls through both of these and adds nothing at all.
	_build_account()
	_add_travel_anchor()


# The two DNA axes, read from the map's config_<key> metadata (GridInteractablesComponent
# sets those BEFORE add_child, so this runs before anything is built) and normalised so an
# unknown word keeps the default rather than silently rendering as one.
func _read_dna() -> void:
	if has_meta("config_course"):
		var c: String = str(get_meta("config_course")).strip_edges().to_lower()
		course = c if COURSES.has(c) else course
	if has_meta("config_account"):
		var r: String = str(get_meta("config_account")).strip_edges().to_lower()
		account = r if ACCOUNTS.has(r) else account
	# COURSE is the DNA name for `axis`; the three .tscn members carry it explicitly, so
	# this reproduces each of them exactly.
	match course:
		"lateral": axis = Axis.X
		"depth": axis = Axis.Z
		_: axis = Axis.Y
	# ACCOUNT decides which of the legacy pieces survive. "ghost" keeps all of them.
	match account:
		"sweep", "terminus", "formula":
			_want_rail = false
			_want_trail = false
		"none":
			_want_rail = false
			_want_trail = false
			_want_labels = false
		_:
			pass


func _create_cube():
	_cube_mesh = MeshInstance3D.new()

	var box = BoxMesh.new()
	box.size = Vector3(cube_size, cube_size, cube_size)
	_cube_mesh.mesh = box

	# Create Grid shader material
	_cube_material = ShaderMaterial.new()
	_cube_material.shader = GRID_SHADER
	_cube_material.set_shader_parameter("modelColor", cube_color * 0.2)
	_cube_material.set_shader_parameter("wireframeColor", cube_color)
	_cube_material.set_shader_parameter("emissionColor", cube_color * 1.2)
	_cube_material.set_shader_parameter("width", 3.0)
	_cube_material.set_shader_parameter("blur", 0.5)
	_cube_material.set_shader_parameter("emission_strength", 0.4)
	_cube_material.set_shader_parameter("show_interior", true)

	_cube_mesh.material_override = _cube_material
	_cube_mesh.position = _base_position
	add_child(_cube_mesh)
	_created_nodes.append(_cube_mesh)


func _create_rail():
	if not show_rail or not _want_rail:
		return

	_rail = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.008
	cylinder.bottom_radius = 0.008
	cylinder.height = travel_distance * 2 + cube_size
	_rail.mesh = cylinder

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.5, 0.6, 0.6)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(0.3, 0.5, 0.7)
	mat.emission_energy_multiplier = 0.2
	_rail.material_override = mat

	# Orient rail based on axis
	match axis:
		Axis.X:
			_rail.rotation.z = PI / 2
			_rail.position = Vector3(_base_position.x, _base_position.y + cube_size * 0.7, _base_position.z)
		Axis.Y:
			_rail.position = Vector3(_base_position.x + cube_size * 0.7, _base_position.y, _base_position.z)
		Axis.Z:
			_rail.rotation.x = PI / 2
			_rail.position = Vector3(_base_position.x, _base_position.y + cube_size * 0.7, _base_position.z)

	add_child(_rail)
	_created_nodes.append(_rail)

	# Create end markers
	_start_marker = _create_range_marker(Color(0.3, 0.8, 0.4))  # Green = positive
	_end_marker = _create_range_marker(Color(0.8, 0.4, 0.3))    # Red = negative

	_position_markers()
	add_child(_start_marker)
	add_child(_end_marker)
	_created_nodes.append(_start_marker)
	_created_nodes.append(_end_marker)


func _position_markers():
	var offset_vec = _get_axis_vector()
	match axis:
		Axis.X:
			_start_marker.position = _base_position + offset_vec * travel_distance + Vector3(0, cube_size * 0.7, 0)
			_end_marker.position = _base_position - offset_vec * travel_distance + Vector3(0, cube_size * 0.7, 0)
		Axis.Y:
			_start_marker.position = _base_position + offset_vec * travel_distance + Vector3(cube_size * 0.7, 0, 0)
			_end_marker.position = _base_position - offset_vec * travel_distance + Vector3(cube_size * 0.7, 0, 0)
		Axis.Z:
			_start_marker.position = _base_position + offset_vec * travel_distance + Vector3(0, cube_size * 0.7, 0)
			_end_marker.position = _base_position - offset_vec * travel_distance + Vector3(0, cube_size * 0.7, 0)


func _create_range_marker(color: Color) -> MeshInstance3D:
	var marker = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.02
	sphere.height = 0.04
	marker.mesh = sphere

	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.5
	marker.material_override = mat

	return marker


func _create_labels():
	if not _want_labels:
		return
	var axis_name = _get_axis_name()

	# Real-time values label
	_label = Label3D.new()
	_label.pixel_size = 0.001
	_label.font_size = 56
	_label.outline_size = 6
	_label.text = "%s = 0.00\nstate: moving" % axis_name
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_label.position = _base_position + Vector3(-cube_size * 1.5, travel_distance + 0.15, 0)
	_label.modulate = Color(0.8, 0.9, 1.0)
	add_child(_label)
	_created_nodes.append(_label)

	# Formula label (hidden by default - enable with show_formula export)
	_formula_label = Label3D.new()
	_formula_label.pixel_size = 0.001
	_formula_label.font_size = 72
	_formula_label.outline_size = 8
	_formula_label.text = "pos.%s += speed · dir" % axis_name.to_lower()
	_formula_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_formula_label.position = Vector3(_base_position.x, -0.08, _base_position.z + cube_size)
	_formula_label.rotation.x = -PI / 6
	_formula_label.modulate = Color(0.6, 0.85, 1.0)
	_formula_label.visible = false  # Hidden by default
	add_child(_formula_label)
	_created_nodes.append(_formula_label)

	# Axis indicator
	var axis_label = Label3D.new()
	axis_label.pixel_size = 0.001
	axis_label.font_size = 48
	axis_label.text = "%s-axis" % axis_name
	axis_label.position = _base_position + Vector3(cube_size * 1.0, travel_distance * 0.5, 0)
	axis_label.modulate = cube_color
	add_child(axis_label)
	_created_nodes.append(axis_label)


func _create_trail_ghosts():
	if not show_trail or not _want_trail:
		return

	# Use MultiMesh for all trail ghosts in a single draw call
	var box := BoxMesh.new()
	box.size = Vector3(cube_size, cube_size, cube_size)

	_trail_mm = MultiMesh.new()
	_trail_mm.transform_format = MultiMesh.TRANSFORM_3D
	_trail_mm.use_colors = true
	_trail_mm.mesh = box
	_trail_mm.instance_count = trail_count

	# Initialize all instances as hidden (zero scale) with per-ghost color/size
	for i in trail_count:
		var xf := Transform3D()
		var ghost_scale = 0.5 + float(i) / maxf(trail_count, 1) * 0.3
		xf = xf.scaled(Vector3(ghost_scale, ghost_scale, ghost_scale))
		xf.origin = _base_position
		_trail_mm.set_instance_transform(i, Transform3D(Basis.IDENTITY.scaled(Vector3.ZERO), Vector3.ZERO))
		var alpha = 0.1 + (float(i) / maxf(trail_count, 1)) * 0.2
		_trail_mm.set_instance_color(i, Color(cube_color.r, cube_color.g, cube_color.b, alpha))

	_trail_mmi = MultiMeshInstance3D.new()
	_trail_mmi.multimesh = _trail_mm

	# Shared material using Grid shader with vertex colors for alpha blending
	var mat := ShaderMaterial.new()
	mat.shader = GRID_SHADER
	mat.set_shader_parameter("modelColor", Color(cube_color.r * 0.2, cube_color.g * 0.2, cube_color.b * 0.2, 0.15))
	mat.set_shader_parameter("wireframeColor", Color(cube_color.r, cube_color.g, cube_color.b, 0.2))
	mat.set_shader_parameter("emissionColor", Color(cube_color.r, cube_color.g, cube_color.b, 0.1))
	mat.set_shader_parameter("width", 2.0)
	mat.set_shader_parameter("blur", 0.6)
	mat.set_shader_parameter("emission_strength", 0.2)
	mat.set_shader_parameter("show_interior", false)
	_trail_mmi.material_override = mat

	add_child(_trail_mmi)
	_created_nodes.append(_trail_mmi)

	# Pre-size trail history array
	_trail_history.resize(trail_count)
	for i in trail_count:
		_trail_history[i] = 0.0


func _setup_controls():
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	var panel: Node3D = RackTpl.create_panel("TRANSLATION", [
		[{"type": "slider_h", "label": "SPEED", "default": travel_speed / 5.0}],
	])
	panel.position = Vector3(0, 0.5, 0.6)
	panel.rotation_degrees = Vector3(-25, 0, 0)
	add_child(panel)
	_created_nodes.append(panel)
	_speed_slider = panel.find_child("Param_0", true, false)
	if _speed_slider and _speed_slider.has_signal("slider_moved"):
		_speed_slider.slider_moved.connect(_on_speed_changed)


func _on_speed_changed():
	var val = _speed_slider.get_normalized_value()
	travel_speed = val * 5.0


func _process(delta):
	_update_state(delta)
	_update_cube_position()
	_update_trail()
	_update_labels()
	_update_color_feedback()


func _update_state(delta: float):
	match _state:
		State.MOVING_POSITIVE:
			_current_offset += travel_speed * delta
			if _current_offset >= travel_distance:
				_current_offset = travel_distance
				_state = State.WAIT_POSITIVE
				_state_timer = 0.0

		State.WAIT_POSITIVE:
			_state_timer += delta
			if _state_timer >= wait_time:
				_state = State.MOVING_NEGATIVE

		State.MOVING_NEGATIVE:
			_current_offset -= travel_speed * delta
			if _current_offset <= -travel_distance:
				_current_offset = -travel_distance
				_state = State.WAIT_NEGATIVE
				_state_timer = 0.0

		State.WAIT_NEGATIVE:
			_state_timer += delta
			if _state_timer >= wait_time:
				_state = State.MOVING_POSITIVE


func _update_cube_position():
	var offset_vec = _get_axis_vector() * _current_offset
	_cube_mesh.position = _base_position + offset_vec


func _get_axis_vector() -> Vector3:
	match axis:
		Axis.X: return Vector3.RIGHT
		Axis.Y: return Vector3.UP
		Axis.Z: return Vector3.BACK
	return Vector3.UP


func _get_axis_name() -> String:
	match axis:
		Axis.X: return "X"
		Axis.Y: return "Y"
		Axis.Z: return "Z"
	return "Y"


func _get_direction_name() -> String:
	match _state:
		State.MOVING_POSITIVE:
			match axis:
				Axis.X: return "→ right"
				Axis.Y: return "↑ up"
				Axis.Z: return "← back"
		State.MOVING_NEGATIVE:
			match axis:
				Axis.X: return "← left"
				Axis.Y: return "↓ down"
				Axis.Z: return "→ forward"
		State.WAIT_POSITIVE, State.WAIT_NEGATIVE:
			return "⏸ wait"
	return ""


func _update_trail():
	if not show_trail or not _trail_mm:
		return

	# Shift history forward and insert current offset
	for i in range(trail_count - 1, 0, -1):
		_trail_history[i] = _trail_history[i - 1]
	_trail_history[0] = _current_offset

	var axis_vec = _get_axis_vector()
	for i in trail_count:
		var ghost_scale = 0.5 + float(i) / maxf(trail_count, 1) * 0.3
		var xf := Transform3D()
		xf = xf.scaled(Vector3(ghost_scale, ghost_scale, ghost_scale))
		xf.origin = _base_position + axis_vec * _trail_history[i]
		_trail_mm.set_instance_transform(i, xf)


func _update_labels():
	if _label:
		var axis_name = _get_axis_name()
		var state_name = _get_direction_name()
		_label.text = "%s = %.3f\n%s" % [
			axis_name.to_lower(),
			_current_offset,
			state_name
		]


func _update_color_feedback():
	if not _cube_material:
		return

	# Color intensity based on speed (brighter when moving)
	var is_moving = _state == State.MOVING_POSITIVE or _state == State.MOVING_NEGATIVE
	var intensity = 1.0 if is_moving else 0.5

	# Slight color shift based on direction
	var t = (_current_offset / maxf(travel_distance, 0.0001) + 1.0) / 2.0  # 0 to 1
	var current_color = cube_color.lerp(Color(0.4, 0.9, 0.4), t * 0.3)

	_cube_material.set_shader_parameter("wireframeColor", current_color)
	_cube_material.set_shader_parameter("emissionColor", current_color * (1.0 + intensity * 0.5))
	_cube_material.set_shader_parameter("emission_strength", 0.3 + intensity * 0.4)


func _exit_tree():
	for node in _created_nodes:
		if is_instance_valid(node):
			node.queue_free()
	_created_nodes.clear()


# Public API

func set_axis(new_axis: Axis) -> void:
	axis = new_axis


func set_travel_distance(d: float) -> void:
	travel_distance = d


func set_speed(s: float) -> void:
	travel_speed = s


func get_current_offset() -> float:
	return _current_offset


func is_waiting() -> bool:
	return _state == State.WAIT_POSITIVE or _state == State.WAIT_NEGATIVE


func reset() -> void:
	_current_offset = 0.0
	_state = State.MOVING_POSITIVE
	_state_timer = 0.0
	if _trail_history.size() > 0:
		for i in _trail_history.size():
			_trail_history[i] = 0.0


func apply_grid_config(config_data: Dictionary) -> void:
	# WAS `pass`. Nothing a map wrote ever reached this artifact, which is the second
	# reason the family shipped as four tokens: the only way to get a different axis was
	# to author a different scene. GridInteractablesComponent sets config_<key> metadata
	# BEFORE add_child, so _read_dna() in _ready() has normally already applied these; the
	# guard below makes this a no-op in that (and in every legacy) case.
	if config_data.is_empty():
		return
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	var was_course: String = course
	var was_account: String = account
	_read_dna()
	if course == was_course and account == was_account:
		return
	for node in _created_nodes:
		if is_instance_valid(node):
			node.queue_free()
	_created_nodes.clear()
	for c in get_children():
		c.queue_free()
	_trail_mm = null
	_trail_mmi = null
	_label = null
	_formula_label = null
	reset()
	_create_cube()
	_create_rail()
	_create_labels()
	_create_trail_ghosts()
	_setup_controls()
	_build_account()
	_add_travel_anchor()


# ── ACCOUNT ────────────────────────────────────────────────────────────────────
# What the translation leaves behind. Appended after the legacy build; "ghost" is the
# legacy build and adds nothing.
func _build_account() -> void:
	match account:
		"sweep":
			_account_sweep()
		"terminus":
			_account_terminus()
		"formula":
			_account_formula()
		"none":
			pass                                  # the result only — nothing to add
		_:
			pass                                  # "ghost" — the legacy lineage


## SWEEP — the path as a solid. One wireframe bar the full length of the travel, the cube
## sliding inside it. Where `ghost` samples four positions, this holds every position at
## once: the orbit of the group action drawn as a body rather than as a history.
func _account_sweep() -> void:
	var span: float = travel_distance * 2.0 + cube_size
	var thin: float = cube_size * 0.62
	var size := Vector3(thin, thin, thin)
	match axis:
		Axis.X: size.x = span
		Axis.Y: size.y = span
		Axis.Z: size.z = span
	var bar := MeshInstance3D.new()
	bar.name = "SweepBar"
	var box := BoxMesh.new()
	box.size = size
	bar.mesh = box
	var mat := ShaderMaterial.new()
	mat.shader = GRID_SHADER
	mat.set_shader_parameter("modelColor", Color(cube_color.r * 0.18, cube_color.g * 0.18, cube_color.b * 0.18, 0.35))
	mat.set_shader_parameter("wireframeColor", Color(cube_color.r, cube_color.g, cube_color.b, 0.85))
	mat.set_shader_parameter("emissionColor", cube_color * 0.8)
	mat.set_shader_parameter("width", 2.5)
	mat.set_shader_parameter("blur", 0.5)
	mat.set_shader_parameter("emission_strength", 0.3)
	mat.set_shader_parameter("show_interior", false)
	bar.material_override = mat
	bar.position = _base_position
	add_child(bar)
	_created_nodes.append(bar)


## TERMINUS — before and after, nothing between. Two solid cubes at the extremes of the
## travel: the dim one is where the object was, the bright one where it ended up. This is
## the figure a textbook draws, and its silence about the middle is the argument.
func _account_terminus() -> void:
	var offset: Vector3 = _get_axis_vector() * travel_distance
	_terminus_cube(_base_position - offset, 0.12, "TerminusBefore")
	_terminus_cube(_base_position + offset, 0.9, "TerminusAfter")


func _terminus_cube(at: Vector3, energy: float, node_name: String) -> void:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	var box := BoxMesh.new()
	box.size = Vector3(cube_size, cube_size, cube_size)
	mi.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(cube_color.r, cube_color.g, cube_color.b, 1.0)
	mat.roughness = 0.45
	mat.emission_enabled = true
	mat.emission = cube_color
	mat.emission_energy_multiplier = energy
	mi.material_override = mat
	mi.position = at
	add_child(mi)
	_created_nodes.append(mi)


## FORMULA — the operation written out instead of drawn. The rail and the ghosts are gone
## and the displacement is stated: an update rule and the interval its parameter runs over.
func _account_formula() -> void:
	var letter: String = _get_axis_name().to_lower()
	var plate := Label3D.new()
	plate.name = "FormulaPlate"
	plate.pixel_size = 0.0011
	plate.font_size = 64
	plate.outline_size = 8
	# Deliberately ASCII: this plate is rendered by whatever font the runtime hands a
	# Label3D, and an algebra glyph that falls back to a box is not the operation written
	# out. The dot in "speed · dir" on the legacy formula label is the one non-ASCII
	# character this artifact has ever proved it can draw.
	plate.text = "p'.%s = p.%s + d\nd = -%.2f .. +%.2f" % [
		letter, letter, travel_distance, travel_distance
	]
	plate.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	plate.modulate = Color(0.72, 0.88, 1.0)
	plate.position = _base_position + Vector3(0.0, travel_distance * 0.55, cube_size * 1.2)
	add_child(plate)
	_created_nodes.append(plate)


## The capture rig fits the frame by the subtree's bounding-box DIAGONAL, refitting for
## every variant. `none` and `terminus` remove the rail, which is the longest thing here,
## so without a constant-extent node the camera would move in for those two, every pixel
## would shift, and the bite report would be a picture of a zoom rather than of the axis.
##
## layers = 0, NOT visible = false: a zero-layer VisualInstance3D is in no camera's cull
## mask, draws nothing, and still reports its AABB. Its extent is exactly the rail's, so
## on the legacy path it adds nothing to the bounding box either.
func _add_travel_anchor() -> void:
	var span: float = travel_distance * 2.0 + cube_size
	var size := Vector3(cube_size, cube_size, cube_size)
	match axis:
		Axis.X: size.x = span
		Axis.Y: size.y = span
		Axis.Z: size.z = span
	var anchor := MeshInstance3D.new()
	anchor.name = "TravelAnchor"
	var box := BoxMesh.new()
	box.size = size
	anchor.mesh = box
	anchor.position = _base_position
	anchor.layers = 0
	anchor.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(anchor)
	_created_nodes.append(anchor)
