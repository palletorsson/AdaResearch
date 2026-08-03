# oscillation_controlled_cube.gd
# The "mario cube" that responds to pendulum control
# Pendulum Y â†’ cube Y translation (up/down)
# Pendulum angular velocity â†’ cube rotation speed
# Pendulum amplitude â†’ cube scale pulse

extends Node3D

class_name OscillationControlledCube


# @identity
# essence: cube.y = A*sin(t), cube.rotation = R*sin(t), cube.scale = lerp(min,max,sin(t))
# desire: Watch a cube translate, rotate, and scale simultaneously driven by a single oscillation source
# critical_parameter: the connected oscillation signal — one driver controls all three transformations
# triggers: external oscillation_updated signal maps y_offset, angular_velocity, amplitude to transform channels
# emerges: the unity of transformation types — all are manifestations of the same underlying oscillation
# needs: VR observation [has], guide rails [has], connection to control_pendulum [has]
# relationships: depends on control_pendulum oscillation signal; contrasts with rotating_cube_demo (multi-transform vs single rotation); unlocks transformation-as-oscillation
# truth: Translation, rotation, and scaling are three faces of the same oscillation projected onto different axes.

const CUBE_SCENE = preload("res://commons/primitives/cubes/cube_scene.tscn")

@export var cube_size: float = 0.3
@export var translation_scale: float = 0.2
@export var rotation_scale: float = 2.0
@export var scale_range: Vector2 = Vector2(0.8, 1.2)
@export var show_guides: bool = true
@export var cube_color: Color = Color(0.2, 0.6, 0.9)

@export var pendulum_path: NodePath

## AXIS — WHAT A STATE PERSISTS AS once the cube has left it. Not the mapping, not the
## translation/rotation/scale channels, not the pendulum that drives them: that is what this
## artifact TEACHES and it runs identically at every value. What the demonstration decides is
## whether one oscillation driving three transforms is a present-tense fact — this height,
## this heading, this size, now — or something that leaves a record.
##
## Adopted word for word — and value for value — from [[mystic_writing_pad]], where the
## vocabulary comes from, and shared with its two siblings in this registry,
## [[y_oscillation_cube]] and [[rotating_cube_demo]]. This one is the richest of the three,
## because what it has to keep is not a position but a whole STATE: height, heading and size
## together. A ghost here is the full transform, not a dot.
##
##   none      the legacy lineage, byte for byte — space does not keep it. The rail, the arc
##             and the mapping panel stand, the cube runs all three channels at once, and
##             nothing is left behind it. This artifact has never kept anything, and saying
##             so is a true statement about it rather than a shortfall
##   trace     the past stays ON THE SURFACE at one strength. Sixteen ghosts, every one the
##             same ink, no fade — accumulation without depth
##   lattice   a state counts only where it is legal. Nine rungs stand the full travel beside
##             the rail and every ghost's height is quantised onto them, so the record is a
##             stair of stations instead of a continuum
##   archive   nothing sinks past recall. Twenty-four ghosts at full brightness, none dimmed
##             by age, the whole swept envelope standing at once
##   wax       a depth that keeps the lot, each older state fainter than the last, until the
##             oldest is barely there
##
## STRICTLY ADDITIVE. "none" builds nothing and records nothing, so all five existing
## placements render exactly as before; the recording hook in _on_oscillation_updated is one
## integer compare on that path. Nothing here reads or writes translation_scale,
## rotation_scale, scale_range, the pendulum connection or the colour feedback.
@export_enum("none", "trace", "lattice", "archive", "wax") var retention: String = "none"
const RETENTIONS: PackedStringArray = ["none", "trace", "lattice", "archive", "wax"]

var _cube_instance: Node3D
var _cube_mesh: MeshInstance3D
var _label: Label3D
var _breakdown_label: Label3D
var _pendulum: Node  # ControlPendulum

# Guide visuals
var _vertical_rail: MeshInstance3D
var _rail_top_marker: MeshInstance3D
var _rail_bottom_marker: MeshInstance3D
var _rotation_arc: MeshInstance3D
var _mapping_panel: Node3D

var _base_position: Vector3
var _current_rotation: float = 0.0

func _ready():
	_base_position = position
	_create_cube()
	_create_label()
	_create_guides()

	# Try to find and connect to pendulum
	call_deferred("_connect_pendulum")

	# DNA, LAST: the retention pass runs after the whole legacy build exists. "none" returns
	# on the first line, so the shipped lineage keeps its exact children in their exact order.
	var _r: String = str(retention).strip_edges().to_lower()
	retention = _r if RETENTIONS.has(_r) else "none"
	_apply_retention()

func _connect_pendulum():
	if pendulum_path:
		_pendulum = get_node_or_null(pendulum_path)
	
	if not _pendulum:
		# Search for ControlPendulum in parent
		var parent = get_parent()
		if parent:
			for child in parent.get_children():
				if child is ControlPendulum:
					_pendulum = child
					break
	
	if _pendulum and _pendulum.has_signal("oscillation_updated"):
		_pendulum.oscillation_updated.connect(_on_oscillation_updated)
		print("OscillationControlledCube connected to pendulum")

func _create_cube():
	_cube_instance = CUBE_SCENE.instantiate()
	_cube_instance.scale = Vector3.ONE * cube_size
	add_child(_cube_instance)
	
	# Get the mesh for color customization
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
		mat.set_shader_parameter("emissionColor", cube_color * 1.2)
		mat.set_shader_parameter("modelColor", cube_color * 0.2)

func _create_label():
	_label = Label3D.new()
	_label.pixel_size = 0.001
	_label.font_size = 48
	_label.outline_size = 6
	_label.text = "Controlled by pendulum"
	_label.position = Vector3(0, cube_size + 0.15, 0)
	_label.modulate = Color(0.6, 0.8, 1.0)
	add_child(_label)


func _create_guides():
	if not show_guides:
		return
	
	# Vertical rail (Y translation range)
	_create_vertical_rail()
	
	# Rotation arc indicator
	_create_rotation_arc()
	
	# Mapping breakdown panel
	_create_mapping_panel()


func _create_vertical_rail():
	var rail_height = translation_scale * 2.0 + cube_size
	
	_vertical_rail = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.006
	cylinder.bottom_radius = 0.006
	cylinder.height = rail_height
	_vertical_rail.mesh = cylinder
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.6, 0.8, 0.5)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(0.2, 0.5, 0.7)
	mat.emission_energy_multiplier = 0.3
	_vertical_rail.material_override = mat
	
	_vertical_rail.position = Vector3(cube_size * 0.8, rail_height / 2.0, 0)
	add_child(_vertical_rail)
	
	# Top marker
	_rail_top_marker = _create_guide_marker(Color(0.3, 0.8, 0.4))
	_rail_top_marker.position = Vector3(cube_size * 0.8, rail_height, 0)
	add_child(_rail_top_marker)
	
	# Bottom marker  
	_rail_bottom_marker = _create_guide_marker(Color(0.8, 0.4, 0.3))
	_rail_bottom_marker.position = Vector3(cube_size * 0.8, 0, 0)
	add_child(_rail_bottom_marker)
	
	# Y label
	var y_label = Label3D.new()
	y_label.pixel_size = 0.001
	y_label.font_size = 32
	y_label.text = "Y"
	y_label.position = Vector3(cube_size * 1.1, rail_height / 2.0, 0)
	y_label.modulate = Color(0.4, 0.7, 0.9)
	add_child(y_label)


func _create_guide_marker(color: Color) -> MeshInstance3D:
	var marker = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.015
	sphere.height = 0.03
	marker.mesh = sphere
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.5
	marker.material_override = mat
	
	return marker


func _create_rotation_arc():
	_rotation_arc = MeshInstance3D.new()
	_rotation_arc.position.y = 0.01
	add_child(_rotation_arc)
	_update_rotation_arc()


func _update_rotation_arc():
	var mesh = ImmediateMesh.new()
	var radius = cube_size * 0.6
	var segments = 24
	
	mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	
	# Full circle to show rotation range
	for i in range(segments + 1):
		var t = float(i) / segments
		var angle = t * TAU
		var x = sin(angle) * radius
		var z = cos(angle) * radius
		
		var color = Color(0.7, 0.5, 0.3, 0.4)
		mesh.surface_set_color(color)
		mesh.surface_add_vertex(Vector3(x, 0, z))
	
	mesh.surface_end()
	
	# Arrow indicator at current position
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	mesh.surface_set_color(Color(1.0, 0.8, 0.3))
	mesh.surface_add_vertex(Vector3.ZERO)
	mesh.surface_add_vertex(Vector3(0, 0, radius))
	mesh.surface_end()
	
	_rotation_arc.mesh = mesh


func _create_mapping_panel():
	_breakdown_label = Label3D.new()
	_breakdown_label.pixel_size = 0.001
	_breakdown_label.font_size = 40
	_breakdown_label.outline_size = 4
	_breakdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_breakdown_label.text = "MAPPINGS:\ny_offset â†’ Y pos\nang_vel â†’ rotation\namplitude â†’ scale"
	_breakdown_label.position = Vector3(-cube_size * 2.0, cube_size * 0.3, 0)
	_breakdown_label.modulate = Color(0.7, 0.8, 0.9)
	add_child(_breakdown_label)

func _on_oscillation_updated(y_offset: float, angular_velocity: float, amplitude: float):
	# Translation: pendulum Y â†’ cube Y
	position.y = _base_position.y + y_offset * translation_scale
	
	# Rotation: angular velocity â†’ rotation speed
	_current_rotation += angular_velocity * rotation_scale * get_process_delta_time()
	_cube_instance.rotation.y = _current_rotation
	
	# Scale: amplitude â†’ scale pulse
	var scale_factor = lerp(scale_range.x, scale_range.y, amplitude)
	_cube_instance.scale = Vector3.ONE * cube_size * scale_factor
	
	# Update main label
	_label.text = "Y: %.2f\nSpin: %.1fÂ°\nScale: %.2f" % [
		position.y - _base_position.y,
		rad_to_deg(_current_rotation),
		scale_factor
	]
	
	# Update breakdown label with real-time mappings
	if _breakdown_label and show_guides:
		_breakdown_label.text = "MAPPINGS:\ny_offset %.2f â†’ Y %.2f\nang_vel %.2f â†’ Î¸ %.1fÂ°\namplitude %.2f â†’ s %.2f" % [
			y_offset, position.y - _base_position.y,
			angular_velocity, rad_to_deg(fmod(_current_rotation, TAU)),
			amplitude, scale_factor
		]
	
	# Update rotation arc indicator
	if _rotation_arc and show_guides:
		_rotation_arc.rotation.y = _current_rotation
	
	# Color feedback based on amplitude
	_update_color_feedback(amplitude)

	# RETENTION, LAST: _ret_stride is 0 on the legacy "none" path, so this is one integer
	# compare per update and nothing else changes.
	if _ret_stride > 0:
		_ret_record(position.y - _base_position.y, _current_rotation, scale_factor)


func _update_color_feedback(intensity: float):
	if not _cube_mesh:
		return
	
	var mat = _cube_mesh.material_override
	if not mat or not mat is ShaderMaterial:
		return
	
	var current_color = Color(
		cube_color.r + intensity * 0.3,
		cube_color.g,
		cube_color.b - intensity * 0.2
	)
	
	mat.set_shader_parameter("wireframeColor", current_color)
	mat.set_shader_parameter("emissionColor", current_color * (1.0 + intensity * 0.6))
	mat.set_shader_parameter("emission_strength", 0.3 + intensity * 0.5)

func _process(_delta):
	# Fallback: if no pendulum connected, do default oscillation
	if not _pendulum:
		var t = Time.get_ticks_msec() / 1000.0
		var y_offset = sin(t * 2.0) * 0.3
		var ang_vel = cos(t * 2.0) * 1.5
		var amp = (sin(t * 0.5) + 1.0) * 0.5
		_on_oscillation_updated(y_offset, ang_vel, amp)

func apply_grid_config(config_data: Dictionary):
	for key in config_data:
		if key in self:
			set(key, config_data[key])
	# Only a token that actually names the axis re-runs the pass; everything else keeps the
	# behaviour this function has always had.
	if config_data.has("retention"):
		var _r: String = str(config_data["retention"]).strip_edges().to_lower()
		retention = _r if RETENTIONS.has(_r) else "none"
		_apply_retention()


# ── RETENTION ────────────────────────────────────────────────────────────────
# One axis, five moments, shared word for word with mystic_writing_pad.gd and with the two
# sibling motion demos in this registry. Everything below runs AFTER the legacy _ready()
# body; "none" returns on the first line and records nothing, so the shipped lineage is
# untouched — same children, same order, same mapping panel, same colour feedback.
#
# THE COMPENSATING HOST. This artifact translates its OWN ROOT (_on_oscillation_updated
# writes position.y), so a child added to it would ride the motion and record nothing. The
# record therefore lives under one host node whose local Y is driven to the negative of the
# live offset, which pins it in world space while the cube moves through it.

## Frames between samples. 0 means "keep nothing" — the legacy `none` path.
var _ret_stride: int = 0
var _ret_tick: int = 0
## Rung spacing in metres for `lattice`. 0.0 means "do not quantise".
var _ret_snap_y: float = 0.0
var _ret_host: Node3D = null
var _ret_ghosts: Array[MeshInstance3D] = []

const RET_TRACE_COUNT := 16
const RET_ARCHIVE_COUNT := 24
const RET_LATTICE_COUNT := 12
const RET_WAX_COUNT := 10
const RET_LATTICE_RUNGS := 9


func _apply_retention() -> void:
	if _ret_host != null and is_instance_valid(_ret_host):
		remove_child(_ret_host)
		_ret_host.queue_free()
	_ret_host = null
	_ret_ghosts.clear()
	_ret_stride = 0
	_ret_tick = 0
	_ret_snap_y = 0.0
	if retention == "none" or not RETENTIONS.has(retention):
		return                       # the legacy lineage keeps nothing at all

	var host := Node3D.new()
	host.name = "RetentionRecord"
	add_child(host)
	_ret_host = host

	# The band the record has to span in Y. The driver feeds y_offset in roughly [-0.3, 0.3]
	# and the cube multiplies it by translation_scale, so one translation_scale brackets the
	# travel with room either side — not the rail's own 2 x figure, which is drawn far taller
	# than anything the cube has ever reached (see the note in _create_vertical_rail).
	var travel: float = translation_scale
	match retention:
		"trace":
			_ret_stride = 4
			_ret_build_ghosts(host, RET_TRACE_COUNT, 0.30, 0.22, false)
		"archive":
			_ret_stride = 3
			_ret_build_ghosts(host, RET_ARCHIVE_COUNT, 0.55, 0.55, false)
		"lattice":
			_ret_stride = 5
			_ret_snap_y = travel / float(maxi(RET_LATTICE_RUNGS - 1, 1))
			_ret_build_ghosts(host, RET_LATTICE_COUNT, 0.40, 0.30, false)
			_ret_build_rule(host, travel)
		"wax":
			_ret_stride = 4
			_ret_build_ghosts(host, RET_WAX_COUNT, 0.34, 0.45, true)
		_:
			pass


## Builds the ghost stack. `graded` weights each ghost by age (the wax depth); otherwise every
## ghost carries the same ink, which is what makes `trace` accumulation-without-depth and
## `archive` a refusal to let anything sink.
func _ret_build_ghosts(host: Node3D, count: int, alpha: float, emission: float, graded: bool) -> void:
	for i in range(count):
		var f: float = float(i) / float(maxi(count - 1, 1))
		var a: float = alpha
		var e: float = emission
		if graded:
			a = alpha * (1.0 - 0.88 * f)
			e = emission * (1.0 - 0.85 * f)
		var mi := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(cube_size, cube_size, cube_size)
		mi.mesh = box
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(cube_color.r, cube_color.g, cube_color.b, maxf(a, 0.02))
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.emission_enabled = true
		mat.emission = cube_color
		mat.emission_energy_multiplier = maxf(e, 0.0)
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		mi.material_override = mat
		mi.visible = false
		host.add_child(mi)
		_ret_ghosts.append(mi)


## LATTICE only — the ruled ladder the heights are quantised onto, standing the full travel
## on the far side of the cube from the guide rail. Without the drawing, quantisation looks
## like a stutter; with it, it looks like a rule.
func _ret_build_rule(host: Node3D, travel: float) -> void:
	var ink := StandardMaterial3D.new()
	ink.albedo_color = Color(0.72, 0.80, 0.88, 0.75)
	ink.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ink.emission_enabled = true
	ink.emission = Color(0.55, 0.72, 0.88)
	ink.emission_energy_multiplier = 0.45

	var rx: float = -cube_size * 0.8
	for k in range(RET_LATTICE_RUNGS):
		var f: float = float(k) / float(maxi(RET_LATTICE_RUNGS - 1, 1))
		var ry: float = -travel * 0.5 + travel * f
		var major: bool = (k == 0) or (k == RET_LATTICE_RUNGS - 1) or (k * 2 == RET_LATTICE_RUNGS - 1)
		var wide: float = cube_size * (0.70 if major else 0.42)
		var bar := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(wide, 0.005, 0.012)
		bar.mesh = bm
		bar.material_override = ink
		bar.position = Vector3(rx - wide * 0.5, ry, 0)
		host.add_child(bar)

	var stile := MeshInstance3D.new()
	var sm := BoxMesh.new()
	sm.size = Vector3(0.007, travel, 0.012)
	stile.mesh = sm
	stile.material_override = ink
	stile.position = Vector3(rx, 0, 0)
	host.add_child(stile)


## One sample. The host is pinned against the root's live translation first, so the record
## stays where it was laid down; then the stack shifts by one and the newest ghost takes the
## current state — height, heading and size together.
func _ret_record(dy: float, rot: float, scale_factor: float) -> void:
	if _ret_host == null or not is_instance_valid(_ret_host):
		return
	_ret_host.position.y = -dy
	_ret_tick += 1
	if _ret_stride <= 0 or (_ret_tick % _ret_stride) != 0:
		return
	var n: int = _ret_ghosts.size()
	if n == 0:
		return
	for i in range(n - 1, 0, -1):
		_ret_ghosts[i].transform = _ret_ghosts[i - 1].transform
		_ret_ghosts[i].visible = _ret_ghosts[i - 1].visible
	var g: MeshInstance3D = _ret_ghosts[0]
	var y: float = dy
	if _ret_snap_y > 0.0:
		y = snappedf(y, _ret_snap_y)
	g.position = Vector3(0, y, 0)
	g.rotation = Vector3(0, rot, 0)
	g.scale = Vector3.ONE * maxf(scale_factor, 0.01)
	g.visible = true
