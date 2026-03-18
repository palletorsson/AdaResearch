# ===========================================================================
# NOC Exercise 5.4: Wander Steering — Path Trail & Perlin Noise
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# Elevated: age-fading path trail, Perlin noise wander for smooth motion,
# seek-blend toward goal markers, wander circle + projected target viz,
# VR sliders for parameter exploration.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D

## Exercise 5.4: Wander Steering — Path Trail & Perlin Noise
## Smooth noise-driven wander with seek blending and fading trail
## Chapter 05: Autonomous Agents


# ── Constants ──────────────────────────────────────────────────────────
const CONTROLLER_SCENE := preload("res://spatial_ui/parameter_controller_3d.tscn")

# ── Tunable parameters ────────────────────────────────────────────────
var wander_radius := 0.08
var wander_distance := 0.15
var noise_increment := 0.02       # how fast noise evolves (smoothness)
var seek_weight := 0.0            # blend: 0 = pure wander, 1 = pure seek
var max_speed := 0.3
var max_force := 0.05
var trail_length := 300

# ── Vehicle state ─────────────────────────────────────────────────────
var _position := Vector3(0, 0.5, 0)
var _velocity := Vector3(0.15, 0, 0.1)
var _acceleration := Vector3.ZERO
var _noise_x := 0.0               # noise offset for wander angle (XY plane)
var _noise_z := 0.0               # noise offset for wander Z component

# ── Trail history ─────────────────────────────────────────────────────
var _trail_positions: Array[Vector3] = []
var _trail_speeds: Array[float] = []
var _max_speed_seen := 0.001

# ── Seek goals ────────────────────────────────────────────────────────
var _goals: Array[Vector3] = []
var _current_goal_idx := 0
var _goal_switch_timer := 0.0

# ── Wander geometry (for visualization) ──────────────────────────────
var _wander_circle_center := Vector3.ZERO
var _wander_target := Vector3.ZERO

# ── Visual nodes ──────────────────────────────────────────────────────
var _vehicle_mesh: MeshInstance3D
var _vehicle_mat: StandardMaterial3D

# Trail
var _trail_im: ImmediateMesh
var _trail_mi: MeshInstance3D

# Glow overlay (recent trail)
var _glow_im: ImmediateMesh
var _glow_mi: MeshInstance3D

# Wander circle + target line
var _wander_im: ImmediateMesh
var _wander_mi: MeshInstance3D

# Goal markers
var _goal_im: ImmediateMesh
var _goal_mi: MeshInstance3D

# Labels
var _info_label: Label3D

# VR controllers
var _radius_ctrl: Node3D
var _noise_ctrl: Node3D
var _seek_ctrl: Node3D
var _trail_ctrl: Node3D

# ── Bounding ──────────────────────────────────────────────────────────
var _bounds := 0.4


func _ready() -> void:
	_init_noise()
	_setup_goals()
	_setup_vehicle()
	_setup_trail_meshes()
	_setup_wander_mesh()
	_setup_goal_mesh()
	_setup_labels()
	_setup_controllers()


# ── Perlin noise implementation (value noise with smoothstep) ────────
# Godot doesn't expose 1D Perlin, so we use a hash-based value noise.

var _perm: Array[int] = []

func _init_noise() -> void:
	_perm.resize(512)
	var base: Array[int] = []
	base.resize(256)
	for i in 256:
		base[i] = i
	# Fisher-Yates shuffle
	for i in range(255, 0, -1):
		var j := randi_range(0, i)
		var tmp := base[i]
		base[i] = base[j]
		base[j] = tmp
	for i in 256:
		_perm[i] = base[i]
		_perm[i + 256] = base[i]

	# Randomize noise offsets so each instance is unique
	_noise_x = randf() * 1000.0
	_noise_z = randf() * 1000.0 + 500.0

func _noise_1d(x: float) -> float:
	# Value noise with cosine interpolation, returns -1..1
	var xi := int(floorf(x)) & 255
	var xf := x - floorf(x)
	var t := xf * xf * (3.0 - 2.0 * xf)  # smoothstep
	var a := (_perm[xi] / 255.0) * 2.0 - 1.0
	var b := (_perm[(xi + 1) & 255] / 255.0) * 2.0 - 1.0
	return lerpf(a, b, t)


# ── Seek goals setup ─────────────────────────────────────────────────

func _setup_goals() -> void:
	# 4 goal markers in a diamond pattern
	_goals = [
		Vector3(-0.25, 0.5, -0.2),
		Vector3(0.25, 0.3, 0.15),
		Vector3(-0.15, 0.7, 0.2),
		Vector3(0.2, 0.6, -0.15),
	]
	_current_goal_idx = 0


# ── Vehicle visual ───────────────────────────────────────────────────

func _setup_vehicle() -> void:
	_vehicle_mesh = MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.025
	cone.height = 0.07
	cone.radial_segments = 6
	_vehicle_mesh.mesh = cone

	_vehicle_mat = StandardMaterial3D.new()
	_vehicle_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_vehicle_mat.albedo_color = Color(1.0, 0.7, 0.9)
	_vehicle_mat.emission_enabled = true
	_vehicle_mat.emission = Color(1.0, 0.6, 0.85)
	_vehicle_mat.emission_energy_multiplier = 3.0
	_vehicle_mesh.material_override = _vehicle_mat
	add_child(_vehicle_mesh)


# ── Trail meshes ─────────────────────────────────────────────────────

func _setup_trail_meshes() -> void:
	# Main trail
	_trail_im = ImmediateMesh.new()
	_trail_mi = MeshInstance3D.new()
	_trail_mi.mesh = _trail_im
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_trail_mi.material_override = mat
	add_child(_trail_mi)

	# Glow overlay
	_glow_im = ImmediateMesh.new()
	_glow_mi = MeshInstance3D.new()
	_glow_mi.mesh = _glow_im
	var gmat := StandardMaterial3D.new()
	gmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	gmat.vertex_color_use_as_albedo = true
	gmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gmat.emission_enabled = true
	gmat.emission = Color(1.0, 0.6, 0.85)
	gmat.emission_energy_multiplier = 2.0
	_glow_mi.material_override = gmat
	add_child(_glow_mi)


# ── Wander circle visualization ──────────────────────────────────────

func _setup_wander_mesh() -> void:
	_wander_im = ImmediateMesh.new()
	_wander_mi = MeshInstance3D.new()
	_wander_mi.mesh = _wander_im
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_wander_mi.material_override = mat
	add_child(_wander_mi)


# ── Goal marker mesh ─────────────────────────────────────────────────

func _setup_goal_mesh() -> void:
	_goal_im = ImmediateMesh.new()
	_goal_mi = MeshInstance3D.new()
	_goal_mi.mesh = _goal_im
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_goal_mi.material_override = mat
	add_child(_goal_mi)


# ── Labels ────────────────────────────────────────────────────────────

func _setup_labels() -> void:
	_info_label = Label3D.new()
	_info_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_info_label.font_size = 22
	_info_label.outline_size = 4
	_info_label.modulate = Color(1.0, 0.85, 1.0)
	_info_label.position = Vector3(0, 0.95, 0)
	add_child(_info_label)


# ── VR controllers ───────────────────────────────────────────────────

func _setup_controllers() -> void:
	var y_pos := -_bounds - 0.18

	_radius_ctrl = CONTROLLER_SCENE.instantiate()
	_radius_ctrl.parameter_name = "Wander Radius"
	_radius_ctrl.min_value = 0.02
	_radius_ctrl.max_value = 0.2
	_radius_ctrl.default_value = wander_radius
	_radius_ctrl.step_size = 0.01
	_radius_ctrl.position = Vector3(-0.3, y_pos, 0)
	_radius_ctrl.value_changed.connect(func(v: float) -> void: wander_radius = v)
	add_child(_radius_ctrl)

	_noise_ctrl = CONTROLLER_SCENE.instantiate()
	_noise_ctrl.parameter_name = "Noise Speed"
	_noise_ctrl.min_value = 0.005
	_noise_ctrl.max_value = 0.1
	_noise_ctrl.default_value = noise_increment
	_noise_ctrl.step_size = 0.005
	_noise_ctrl.position = Vector3(-0.1, y_pos, 0)
	_noise_ctrl.value_changed.connect(func(v: float) -> void: noise_increment = v)
	add_child(_noise_ctrl)

	_seek_ctrl = CONTROLLER_SCENE.instantiate()
	_seek_ctrl.parameter_name = "Seek Blend"
	_seek_ctrl.min_value = 0.0
	_seek_ctrl.max_value = 1.0
	_seek_ctrl.default_value = seek_weight
	_seek_ctrl.step_size = 0.05
	_seek_ctrl.position = Vector3(0.1, y_pos, 0)
	_seek_ctrl.value_changed.connect(func(v: float) -> void: seek_weight = v)
	add_child(_seek_ctrl)

	_trail_ctrl = CONTROLLER_SCENE.instantiate()
	_trail_ctrl.parameter_name = "Trail"
	_trail_ctrl.min_value = 50.0
	_trail_ctrl.max_value = 600.0
	_trail_ctrl.default_value = float(trail_length)
	_trail_ctrl.step_size = 50.0
	_trail_ctrl.position = Vector3(0.3, y_pos, 0)
	_trail_ctrl.value_changed.connect(func(v: float) -> void: trail_length = int(v))
	add_child(_trail_ctrl)


# ── Main loop ────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	# Compute steering forces
	var wander_force := _compute_wander()
	var seek_force := _compute_seek()

	# Blend wander and seek
	var blended := wander_force * (1.0 - seek_weight) + seek_force * seek_weight
	_acceleration += blended

	# Integrate
	_velocity += _acceleration
	_velocity = _velocity.limit_length(max_speed)
	_position += _velocity * delta * 60.0
	_acceleration = Vector3.ZERO

	# Wrap bounds
	_wrap_bounds()

	# Goal switching — cycle when close
	_goal_switch_timer += delta
	if _goals.size() > 0:
		var goal := _goals[_current_goal_idx]
		if _position.distance_to(goal) < 0.08 or _goal_switch_timer > 8.0:
			_current_goal_idx = (_current_goal_idx + 1) % _goals.size()
			_goal_switch_timer = 0.0

	# Record trail
	var speed := _velocity.length()
	_trail_positions.append(_position)
	_trail_speeds.append(speed)
	if speed > _max_speed_seen:
		_max_speed_seen = speed
	while _trail_positions.size() > trail_length:
		_trail_positions.remove_at(0)
		_trail_speeds.remove_at(0)

	# Update visuals
	_vehicle_mesh.position = _position
	_orient_vehicle()
	_update_vehicle_glow(speed)
	_rebuild_trail()
	_rebuild_glow_overlay()
	_draw_wander_geometry()
	_draw_goals()
	_update_label(speed)


# ── Perlin noise wander ─────────────────────────────────────────────

func _compute_wander() -> Vector3:
	_noise_x += noise_increment
	_noise_z += noise_increment

	# Sample noise for wander angle in XY and Z offset
	var angle_xy := _noise_1d(_noise_x) * TAU       # full circle range
	var z_offset := _noise_1d(_noise_z) * wander_radius  # Z wander

	# Project circle center ahead of vehicle
	var heading := _velocity.normalized() if _velocity.length() > 0.001 else Vector3.RIGHT
	_wander_circle_center = _position + heading * wander_distance

	# Compute target point on wander circle (3D)
	var circle_offset := Vector3(
		cos(angle_xy) * wander_radius,
		sin(angle_xy) * wander_radius,
		z_offset
	)
	_wander_target = _wander_circle_center + circle_offset

	# Steer toward target
	var desired := (_wander_target - _position).normalized() * max_speed
	var steer := (desired - _velocity).limit_length(max_force)
	return steer


# ── Seek toward current goal ─────────────────────────────────────────

func _compute_seek() -> Vector3:
	if _goals.is_empty():
		return Vector3.ZERO
	var goal := _goals[_current_goal_idx]
	var desired := (goal - _position).normalized() * max_speed
	var steer := (desired - _velocity).limit_length(max_force)
	return steer


# ── Bounds wrapping ──────────────────────────────────────────────────

func _wrap_bounds() -> void:
	if _position.x < -_bounds:
		_position.x = _bounds
	elif _position.x > _bounds:
		_position.x = -_bounds
	if _position.y < 0.05:
		_position.y = 0.95
	elif _position.y > 0.95:
		_position.y = 0.05
	if _position.z < -_bounds:
		_position.z = _bounds
	elif _position.z > _bounds:
		_position.z = -_bounds


# ── Vehicle orientation ──────────────────────────────────────────────

func _orient_vehicle() -> void:
	if _velocity.length() > 0.001:
		var dir := _velocity.normalized()
		# Point cone tip in direction of travel
		_vehicle_mesh.look_at(_position + dir, Vector3.UP)
		_vehicle_mesh.rotate_object_local(Vector3.RIGHT, -PI / 2.0)


func _update_vehicle_glow(speed: float) -> void:
	var t := clampf(speed / maxf(_max_speed_seen, 0.001), 0.0, 1.0)
	_vehicle_mat.emission = Color(1.0, 0.5 + 0.3 * (1.0 - t), 0.75 + 0.2 * (1.0 - t))
	_vehicle_mat.emission_energy_multiplier = 2.0 + 4.0 * t


# ── Velocity → color gradient (age-fading) ──────────────────────────

func _trail_color(speed_val: float, age_t: float) -> Color:
	# age_t: 0 = oldest, 1 = newest
	var t := clampf(speed_val / maxf(_max_speed_seen, 0.001), 0.0, 1.0)
	var r: float
	var g: float
	var b: float

	# Pink → magenta → violet → blue gradient based on speed
	if t < 0.33:
		var s := t * 3.0
		r = 0.9 - 0.3 * s
		g = 0.4 + 0.1 * s
		b = 0.7 + 0.2 * s
	elif t < 0.66:
		var s := (t - 0.33) * 3.0
		r = 0.6 - 0.2 * s
		g = 0.5 - 0.2 * s
		b = 0.9
	else:
		var s := (t - 0.66) * 3.0
		r = 0.4 - 0.2 * s
		g = 0.3 + 0.4 * s
		b = 0.9 + 0.1 * s

	# Age-based alpha: old trail fades to transparent
	var alpha := 0.08 + 0.92 * age_t
	return Color(r, g, b, alpha)


# ── Trail rendering ──────────────────────────────────────────────────

func _rebuild_trail() -> void:
	_trail_im.clear_surfaces()
	var count := _trail_positions.size()
	if count < 2:
		return

	_trail_im.surface_begin(Mesh.PRIMITIVE_LINES)
	for i in range(1, count):
		var age_t := float(i) / float(count)
		var color := _trail_color(_trail_speeds[i], age_t)
		_trail_im.surface_set_color(color)
		_trail_im.surface_add_vertex(_trail_positions[i - 1])
		_trail_im.surface_set_color(color)
		_trail_im.surface_add_vertex(_trail_positions[i])
	_trail_im.surface_end()


func _rebuild_glow_overlay() -> void:
	_glow_im.clear_surfaces()
	var count := _trail_positions.size()
	var glow_start := int(count * 0.9)
	if glow_start >= count - 1:
		return

	_glow_im.surface_begin(Mesh.PRIMITIVE_LINES)
	for i in range(glow_start + 1, count):
		var local_t := float(i - glow_start) / float(count - glow_start)
		var t := clampf(_trail_speeds[i] / maxf(_max_speed_seen, 0.001), 0.0, 1.0)
		var color := Color(1.0, 0.6 + 0.3 * (1.0 - t), 0.8 + 0.2 * (1.0 - t), local_t)
		_glow_im.surface_set_color(color)
		_glow_im.surface_add_vertex(_trail_positions[i - 1])
		_glow_im.surface_set_color(color)
		_glow_im.surface_add_vertex(_trail_positions[i])
	_glow_im.surface_end()


# ── Wander circle + target point visualization ───────────────────────

func _draw_wander_geometry() -> void:
	_wander_im.clear_surfaces()
	_wander_im.surface_begin(Mesh.PRIMITIVE_LINES)

	var circle_color := Color(1.0, 0.7, 0.9, 0.35)
	var target_color := Color(1.0, 0.4, 0.7, 0.8)
	var line_color := Color(1.0, 0.85, 0.95, 0.25)

	# Draw wander circle (in the plane perpendicular to velocity)
	var segments := 24
	var heading := _velocity.normalized() if _velocity.length() > 0.001 else Vector3.RIGHT
	# Use a simple XY circle at the circle center for clarity
	for i in range(segments):
		var a0 := float(i) / float(segments) * TAU
		var a1 := float(i + 1) / float(segments) * TAU
		var p0 := _wander_circle_center + Vector3(cos(a0) * wander_radius, sin(a0) * wander_radius, 0)
		var p1 := _wander_circle_center + Vector3(cos(a1) * wander_radius, sin(a1) * wander_radius, 0)
		_wander_im.surface_set_color(circle_color)
		_wander_im.surface_add_vertex(p0)
		_wander_im.surface_set_color(circle_color)
		_wander_im.surface_add_vertex(p1)

	# Line from vehicle to circle center
	_wander_im.surface_set_color(line_color)
	_wander_im.surface_add_vertex(_position)
	_wander_im.surface_set_color(line_color)
	_wander_im.surface_add_vertex(_wander_circle_center)

	# Line from circle center to target point
	_wander_im.surface_set_color(target_color)
	_wander_im.surface_add_vertex(_wander_circle_center)
	_wander_im.surface_set_color(target_color)
	_wander_im.surface_add_vertex(_wander_target)

	# Target crosshair
	var cross_size := 0.015
	_wander_im.surface_set_color(target_color)
	_wander_im.surface_add_vertex(_wander_target + Vector3(-cross_size, 0, 0))
	_wander_im.surface_set_color(target_color)
	_wander_im.surface_add_vertex(_wander_target + Vector3(cross_size, 0, 0))
	_wander_im.surface_set_color(target_color)
	_wander_im.surface_add_vertex(_wander_target + Vector3(0, -cross_size, 0))
	_wander_im.surface_set_color(target_color)
	_wander_im.surface_add_vertex(_wander_target + Vector3(0, cross_size, 0))
	_wander_im.surface_set_color(target_color)
	_wander_im.surface_add_vertex(_wander_target + Vector3(0, 0, -cross_size))
	_wander_im.surface_set_color(target_color)
	_wander_im.surface_add_vertex(_wander_target + Vector3(0, 0, cross_size))

	_wander_im.surface_end()


# ── Goal marker drawing ──────────────────────────────────────────────

func _draw_goals() -> void:
	_goal_im.clear_surfaces()
	_goal_im.surface_begin(Mesh.PRIMITIVE_LINES)

	for i in _goals.size():
		var goal := _goals[i]
		var is_active := (i == _current_goal_idx)
		var base_alpha := 0.6 if is_active else 0.2
		var color := Color(0.3, 1.0, 0.5, base_alpha) if is_active else Color(0.5, 0.7, 0.5, base_alpha)

		# Diamond marker
		var s := 0.025 if is_active else 0.015
		_goal_im.surface_set_color(color)
		_goal_im.surface_add_vertex(goal + Vector3(0, s, 0))
		_goal_im.surface_set_color(color)
		_goal_im.surface_add_vertex(goal + Vector3(s, 0, 0))

		_goal_im.surface_set_color(color)
		_goal_im.surface_add_vertex(goal + Vector3(s, 0, 0))
		_goal_im.surface_set_color(color)
		_goal_im.surface_add_vertex(goal + Vector3(0, -s, 0))

		_goal_im.surface_set_color(color)
		_goal_im.surface_add_vertex(goal + Vector3(0, -s, 0))
		_goal_im.surface_set_color(color)
		_goal_im.surface_add_vertex(goal + Vector3(-s, 0, 0))

		_goal_im.surface_set_color(color)
		_goal_im.surface_add_vertex(goal + Vector3(-s, 0, 0))
		_goal_im.surface_set_color(color)
		_goal_im.surface_add_vertex(goal + Vector3(0, s, 0))

		# Seek line from vehicle to active goal (when seek is active)
		if is_active and seek_weight > 0.01:
			var seek_color := Color(0.3, 1.0, 0.5, seek_weight * 0.4)
			_goal_im.surface_set_color(seek_color)
			_goal_im.surface_add_vertex(_position)
			_goal_im.surface_set_color(seek_color)
			_goal_im.surface_add_vertex(goal)

	_goal_im.surface_end()


# ── Labels ────────────────────────────────────────────────────────────

func _update_label(speed: float) -> void:
	if not _info_label:
		return
	var mode_str := "Wander"
	if seek_weight > 0.01:
		mode_str = "Wander + Seek (%.0f%%)" % (seek_weight * 100.0)
	_info_label.text = "%s  |  Speed: %.2f  |  Trail: %d" % [mode_str, speed, _trail_positions.size()]


# ── Input ─────────────────────────────────────────────────────────────

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE or event.keycode == KEY_R:
			_reset_vehicle()


func _reset_vehicle() -> void:
	_position = Vector3(
		randf_range(-0.2, 0.2),
		randf_range(0.3, 0.7),
		randf_range(-0.2, 0.2)
	)
	_velocity = Vector3(
		randf_range(-0.15, 0.15),
		randf_range(-0.1, 0.1),
		randf_range(-0.15, 0.15)
	)
	_acceleration = Vector3.ZERO
	_trail_positions.clear()
	_trail_speeds.clear()
	_max_speed_seen = 0.001
	_noise_x = randf() * 1000.0
	_noise_z = randf() * 1000.0 + 500.0
	_current_goal_idx = 0
	_goal_switch_timer = 0.0


# ── Cleanup ───────────────────────────────────────────────────────────

func _exit_tree() -> void:
	if _trail_im:
		_trail_im.clear_surfaces()
	if _glow_im:
		_glow_im.clear_surfaces()
	if _wander_im:
		_wander_im.clear_surfaces()
	if _goal_im:
		_goal_im.clear_surfaces()


# ── Grid config ───────────────────────────────────────────────────────

func apply_grid_config(config: Dictionary) -> void:
	if config.has("wander_radius"):
		wander_radius = clampf(float(config.wander_radius), 0.02, 0.2)
		if _radius_ctrl:
			_radius_ctrl.set_value(wander_radius)

	if config.has("noise_speed"):
		noise_increment = clampf(float(config.noise_speed), 0.005, 0.1)
		if _noise_ctrl:
			_noise_ctrl.set_value(noise_increment)

	if config.has("seek_blend"):
		seek_weight = clampf(float(config.seek_blend), 0.0, 1.0)
		if _seek_ctrl:
			_seek_ctrl.set_value(seek_weight)

	if config.has("trail_length"):
		trail_length = clampi(int(config.trail_length), 50, 600)
		if _trail_ctrl:
			_trail_ctrl.set_value(float(trail_length))

	_reset_vehicle()
