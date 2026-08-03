# rotating_cube_demo.gd
# Simple continuous rotation demonstration
# Shows: θ += ω·dt (angle increases by angular velocity × time)
# The simplest form of rotational motion - constant spin

extends Node3D

class_name RotatingCubeDemo


# @identity
# essence: theta(t) = omega * t, displayed with circular trail and angle readout
# desire: Watch a single cube rotate at constant angular velocity with its circular path traced
# critical_parameter: rotation_speed (omega) — the angular velocity in radians per second
# triggers: continuous time integration rotates the cube; trail mesh shows the circular orbit
# emerges: the connection between angular velocity, period, and the circular path
# needs: VR observation [has], speed adjustment [missing], angle readout [has]
# relationships: depends on basic rotation math; contrasts with y_oscillation_cube (rotation vs translation); unlocks angular velocity intuition
# truth: Rotation at constant speed is the simplest periodic motion — the mother of all oscillation.

const CUBE_SCENE = preload("res://commons/primitives/cubes/cube_scene.tscn")

@export var cube_size: float = 0.3
@export var rotation_speed: float = 1.5  # ω in radians/second
@export var cube_color: Color = Color(0.9, 0.6, 0.2)
@export var show_labels: bool = true
@export var show_trail: bool = true

## AXIS — WHAT AN ANGLE PERSISTS AS once the cube has turned past it. Not omega, not the
## period, not theta += omega*dt: that is what this artifact TEACHES and it runs identically
## at every value. What the demonstration decides is whether rotation is a present-tense
## fact — this face, pointing there, now — or something that leaves a record, and what kind
## of record a space is willing to hold.
##
## Adopted word for word — and value for value — from [[mystic_writing_pad]], where the
## vocabulary comes from, and shared with its two siblings in this registry,
## [[y_oscillation_cube]] and [[oscillation_controlled_cube]]. Three demonstrations of the
## same claim (a body moves, and something or nothing is kept of where it has been) should
## not use three different words for it.
##
##   none      space does not keep it. The cube turns on bare ground: no path drawn, no
##             heading marked — a present with no past
##   trace     the legacy lineage, byte for byte — the orbit circle inked on the ground and
##             the heading arrow riding it. The path stays ON THE SURFACE at one strength:
##             accumulation without depth
##   lattice   an angle counts only where it is legal. A ruled dial of twenty-four stations
##             replaces the continuous circle and the heading SNAPS to the nearest one, so
##             the turn is countable instead of smooth
##   archive   nothing sinks past recall. Twelve past orientations stand at once, every
##             thirty degrees, none dimmed by age — the cube becomes the twelve-sided drum
##             its rotation has been sweeping all along
##   wax       a depth that keeps the lot, each older heading fainter than the last. Eight
##             ghosts fan back behind the live cube and thin out until the horizon takes them
##
## `trace` is this artifact's default because `trace` is what it already was: a circle on the
## ground and an arrow, shipped since it was written. STRICTLY ADDITIVE — nothing here reads
## or writes rotation_speed, _current_angle, the labels or the colour pulse.
@export_enum("none", "trace", "lattice", "archive", "wax") var retention: String = "trace"
const RETENTIONS: PackedStringArray = ["none", "trace", "lattice", "archive", "wax"]

var _cube_instance: Node3D
var _cube_mesh: MeshInstance3D
var _label: Label3D
var _formula_label: Label3D
var _ground_arc: MeshInstance3D
var _direction_indicator: MeshInstance3D

var _current_angle: float = 0.0  # θ in radians


func _ready():
	_create_cube()
	_create_ground_arc()
	_create_direction_indicator()
	_create_labels()
	# DNA, LAST: the retention pass runs after the whole legacy build exists. "trace" returns
	# on the first line, so the shipped lineage keeps its exact children in their exact order.
	var _r: String = str(retention).strip_edges().to_lower()
	retention = _r if RETENTIONS.has(_r) else "trace"
	_apply_retention()


func _create_cube():
	_cube_instance = CUBE_SCENE.instantiate()
	_cube_instance.scale = Vector3.ONE * cube_size
	_cube_instance.position.y = cube_size / 2.0
	add_child(_cube_instance)
	
	# Get mesh for color
	var static_body = _cube_instance.get_node_or_null("CubeBaseStaticBody3D")
	if static_body:
		_cube_mesh = static_body.get_node_or_null("CubeBaseMesh")
		_apply_cube_color()


func _apply_cube_color():
	if not _cube_mesh:
		return
	
	var mat = _cube_mesh.material_override
	if mat and mat is ShaderMaterial:
		mat.set_shader_parameter("wireframeColor", cube_color)
		mat.set_shader_parameter("emissionColor", cube_color * 1.3)
		mat.set_shader_parameter("modelColor", cube_color * 0.2)


func _create_ground_arc():
	# Circle on ground showing rotation path
	_ground_arc = MeshInstance3D.new()
	_ground_arc.position.y = 0.005
	add_child(_ground_arc)
	
	var mesh = ImmediateMesh.new()
	var radius = cube_size * 0.7
	var segments = 32
	
	mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	
	for i in range(segments + 1):
		var t = float(i) / segments
		var angle = t * TAU
		var x = sin(angle) * radius
		var z = cos(angle) * radius
		mesh.surface_set_color(Color(0.5, 0.4, 0.3, 0.5))
		mesh.surface_add_vertex(Vector3(x, 0, z))
	
	mesh.surface_end()
	_ground_arc.mesh = mesh


func _create_direction_indicator():
	# Arrow showing current rotation angle
	_direction_indicator = MeshInstance3D.new()
	
	var mesh = ImmediateMesh.new()
	var radius = cube_size * 0.7
	
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	mesh.surface_set_color(Color(1.0, 0.8, 0.3))
	mesh.surface_add_vertex(Vector3.ZERO)
	mesh.surface_add_vertex(Vector3(0, 0, radius))
	mesh.surface_end()
	
	# Arrow head
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	mesh.surface_set_color(Color(1.0, 0.8, 0.3))
	var tip = Vector3(0, 0, radius)
	var left = Vector3(-0.02, 0, radius - 0.04)
	var right = Vector3(0.02, 0, radius - 0.04)
	mesh.surface_add_vertex(tip)
	mesh.surface_add_vertex(left)
	mesh.surface_add_vertex(right)
	mesh.surface_end()
	
	_direction_indicator.mesh = mesh
	_direction_indicator.position.y = 0.01
	add_child(_direction_indicator)


func _create_labels():
	if not show_labels:
		return
	
	# Real-time values
	_label = Label3D.new()
	_label.pixel_size = 0.001
	_label.font_size = 56
	_label.outline_size = 6
	_label.text = "θ = 0.0°\nω = %.2f rad/s" % rotation_speed
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_label.position = Vector3(-cube_size * 1.5, cube_size * 1.5, 0)
	_label.modulate = Color(1.0, 0.9, 0.8)
	add_child(_label)
	
	# Formula - the key concept
	_formula_label = Label3D.new()
	_formula_label.pixel_size = 0.001
	_formula_label.font_size = 72
	_formula_label.outline_size = 8
	_formula_label.text = "θ += ω · dt"
	_formula_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_formula_label.position = Vector3(0, -0.08, cube_size)
	_formula_label.rotation.x = -PI / 6
	_formula_label.modulate = Color(1.0, 0.85, 0.5)
	add_child(_formula_label)
	
	# Title
	var title = Label3D.new()
	title.pixel_size = 0.001
	title.font_size = 48
	title.outline_size = 4
	title.text = "CONTINUOUS ROTATION"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector3(0, cube_size + 0.2, 0)
	title.modulate = Color(0.9, 0.8, 0.6)
	add_child(title)


func _process(delta):
	# The core formula: θ += ω · dt
	_current_angle += rotation_speed * delta
	
	# Keep angle in 0 to TAU range for display
	while _current_angle >= TAU:
		_current_angle -= TAU
	
	# Apply rotation to cube
	_cube_instance.rotation.y = _current_angle
	
	# Update direction indicator. RETENTION "lattice" only: the heading lands on a station.
	# _ret_snap is 0.0 on every other value, so the legacy path takes the else branch.
	if _direction_indicator:
		if _ret_snap > 0.0:
			_direction_indicator.rotation.y = snappedf(_current_angle, _ret_snap)
		else:
			_direction_indicator.rotation.y = _current_angle

	# RETENTION "wax" only: the fan of older headings follows the live one. _ret_fan_step is
	# 0.0 on every other value, so this compare is the whole cost on the legacy path.
	if _ret_fan_step > 0.0:
		for i in range(_ret_ghosts.size()):
			_ret_ghosts[i].rotation.y = _current_angle - float(i + 1) * _ret_fan_step

	# Update label
	if _label:
		var degrees = rad_to_deg(_current_angle)
		_label.text = "θ = %.1f°\nω = %.2f rad/s\ndt = %.3fs" % [degrees, rotation_speed, delta]
	
	# Subtle color pulse
	_update_color_pulse()


func _update_color_pulse():
	if not _cube_mesh:
		return
	
	var mat = _cube_mesh.material_override
	if not mat or not mat is ShaderMaterial:
		return
	
	# Pulse based on rotation angle
	var pulse = (sin(_current_angle * 4.0) + 1.0) / 2.0 * 0.3
	mat.set_shader_parameter("emission_strength", 0.4 + pulse)


# Public API

func set_rotation_speed(speed: float) -> void:
	rotation_speed = speed


func get_rotation_speed() -> float:
	return rotation_speed


func get_current_angle_degrees() -> float:
	return rad_to_deg(_current_angle)


func get_current_angle_radians() -> float:
	return _current_angle


func reset() -> void:
	_current_angle = 0.0


func get_cube_instance() -> Node3D:
	return _cube_instance

func apply_grid_config(config_data: Dictionary):
	for key in config_data:
		if key in self:
			set(key, config_data[key])
	# Only a token that actually names the axis re-runs the pass; everything else keeps the
	# behaviour this function has always had.
	if config_data.has("retention"):
		var _r: String = str(config_data["retention"]).strip_edges().to_lower()
		retention = _r if RETENTIONS.has(_r) else "trace"
		_apply_retention()


# ── RETENTION ────────────────────────────────────────────────────────────────
# One axis, five moments, shared word for word with mystic_writing_pad.gd and with the two
# sibling motion demos in this registry. Everything below runs AFTER the legacy _ready()
# body; "trace" returns on the first line, so the shipped lineage is untouched — same ground
# arc, same arrow, same labels, same colour pulse.

## Station spacing in radians for `lattice`. 0.0 means "do not snap" — every other value.
var _ret_snap: float = 0.0
## Angular gap between successive `wax` ghosts. 0.0 means "no fan" — every other value.
var _ret_fan_step: float = 0.0
## Ghost cubes built by `archive` and `wax`, freed before a rebuild.
var _ret_ghosts: Array[MeshInstance3D] = []
## The dial built by `lattice`, freed before a rebuild.
var _ret_dial: Node3D = null

const RET_DIAL_STATIONS := 24
const RET_ARCHIVE_FACES := 12
const RET_WAX_GHOSTS := 8


func _apply_retention() -> void:
	if retention == "trace" or not RETENTIONS.has(retention):
		return                       # the legacy lineage: the inked circle and the arrow

	for g in _ret_ghosts:
		if is_instance_valid(g):
			remove_child(g)
			g.queue_free()
	_ret_ghosts.clear()
	if _ret_dial != null and is_instance_valid(_ret_dial):
		remove_child(_ret_dial)
		_ret_dial.queue_free()
	_ret_dial = null
	_ret_snap = 0.0
	_ret_fan_step = 0.0

	match retention:
		"none":
			# Space keeps nothing: the drawn path and the heading both go.
			if _ground_arc != null and is_instance_valid(_ground_arc):
				remove_child(_ground_arc)
				_ground_arc.queue_free()
				_ground_arc = null
			if _direction_indicator != null and is_instance_valid(_direction_indicator):
				remove_child(_direction_indicator)
				_direction_indicator.queue_free()
				_direction_indicator = null
		"lattice":
			# The continuous circle is replaced by countable stations.
			if _ground_arc != null and is_instance_valid(_ground_arc):
				remove_child(_ground_arc)
				_ground_arc.queue_free()
				_ground_arc = null
			_ret_snap = TAU / float(RET_DIAL_STATIONS)
			_ret_build_dial()
		"archive":
			_ret_build_ring()
		"wax":
			_ret_fan_step = 0.16
			_ret_build_fan()
		_:
			pass


## LATTICE — the dial. Twenty-four radial stations on the ground, every sixth one long, plus
## a rim; the heading arrow lands on one of them and never between. A turn you can count.
func _ret_build_dial() -> void:
	var dial := Node3D.new()
	dial.name = "RetentionDial"
	dial.position.y = 0.006
	add_child(dial)
	_ret_dial = dial

	var tick := StandardMaterial3D.new()
	tick.albedo_color = Color(0.85, 0.70, 0.40, 0.85)
	tick.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	tick.emission_enabled = true
	tick.emission = Color(0.90, 0.72, 0.35)
	tick.emission_energy_multiplier = 0.55

	var r: float = cube_size * 0.7
	for k in range(RET_DIAL_STATIONS):
		var a: float = TAU * float(k) / float(RET_DIAL_STATIONS)
		var major: bool = (k % 6) == 0
		var length: float = cube_size * (0.34 if major else 0.16)
		var bar := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.010, 0.005, length)
		bar.mesh = bm
		bar.material_override = tick
		bar.position = Vector3(sin(a) * (r + length * 0.5), 0, cos(a) * (r + length * 0.5))
		bar.rotation.y = a
		dial.add_child(bar)

	# A thin rim tying the stations into one instrument rather than loose marks.
	for k2 in range(RET_DIAL_STATIONS * 2):
		var a2: float = TAU * float(k2) / float(RET_DIAL_STATIONS * 2)
		var seg := MeshInstance3D.new()
		var sm := BoxMesh.new()
		sm.size = Vector3(0.008, 0.004, r * TAU / float(RET_DIAL_STATIONS * 2) * 0.9)
		seg.mesh = sm
		seg.material_override = tick
		seg.position = Vector3(sin(a2) * r, 0, cos(a2) * r)
		seg.rotation.y = a2
		dial.add_child(seg)


## ARCHIVE — twelve past orientations standing at once, every thirty degrees, none dimmed.
## They occupy the same place as the live cube, so their union is the twelve-sided drum the
## rotation has been sweeping out from the start: the record IS the swept solid.
func _ret_build_ring() -> void:
	for k in range(RET_ARCHIVE_FACES):
		var ghost: MeshInstance3D = _ret_make_ghost(cube_size * 0.98, 0.30, 0.55)
		ghost.rotation.y = TAU * float(k) / float(RET_ARCHIVE_FACES)
		add_child(ghost)
		_ret_ghosts.append(ghost)


## WAX — eight ghosts fanning back behind the live heading, each fainter and slightly smaller
## than the one in front of it, until the oldest is barely there. A depth under the surface,
## not marks on it.
func _ret_build_fan() -> void:
	for k in range(RET_WAX_GHOSTS):
		var f: float = float(k) / float(maxi(RET_WAX_GHOSTS - 1, 1))
		var ghost: MeshInstance3D = _ret_make_ghost(
			cube_size * (0.96 - 0.22 * f), 0.34 - 0.28 * f, 0.50 - 0.40 * f)
		add_child(ghost)
		_ret_ghosts.append(ghost)


## A translucent stand-in for the cube: same box, same colour, no collider and no shader
## dependency — a record of the body, not another body.
func _ret_make_ghost(size: float, alpha: float, emission: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(size, size, size)
	mi.mesh = box

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(cube_color.r, cube_color.g, cube_color.b, maxf(alpha, 0.02))
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = cube_color
	mat.emission_energy_multiplier = maxf(emission, 0.0)
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = mat
	mi.position.y = cube_size / 2.0
	return mi
