# ===========================================================================
# NOC Example 6.4: Windmill
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D

## Example 6.4: Windmill — Expressive Physics
## HingeJoint3D with torque/force visualization, velocity-colored blades,
## wind particles, procedural audio, and VR controls
## Chapter 06: Physics Libraries

signal speed_changed(angular_velocity: float, rpm: float)
signal direction_changed(clockwise: bool)

# Export params
@export var blade_count: int = 4
@export var wind_strength: float = 2.0
@export var drag_coefficient: float = 0.3

# Physics state
var _motor_speed: float = 2.0
var _angular_velocity: float = 0.0
var _prev_angular_velocity: float = 0.0
var _torque: float = 0.0
var _was_clockwise: bool = true
var _rpm: float = 0.0

# Scene nodes
var _windmill: Node3D
var _blades: RigidBody3D
var _pole: StaticBody3D
var _hinge_joint: HingeJoint3D
var _hub_mesh: MeshInstance3D

# Blade tracking for velocity coloring
var _blade_meshes: Array[MeshInstance3D] = []
var _blade_materials: Array[StandardMaterial3D] = []

# Force/torque arrow visualization
var _force_mesh_instance: MeshInstance3D
var _force_mesh: ImmediateMesh
var _torque_mesh_instance: MeshInstance3D
var _torque_mesh: ImmediateMesh

# Wind particles
var _wind_particles: GPUParticles3D

# UI
var _info_label: Label3D
var _metrics_label: Label3D
var _wind_controller: ParameterController3D
var _drag_controller: ParameterController3D
var _blades_controller: ParameterController3D

# Audio
var _whoosh_player: AudioStreamPlayer3D
var _creak_player: AudioStreamPlayer3D
var _whoosh_stream: AudioStreamGenerator
var _creak_stream: AudioStreamGenerator
var _whoosh_playback: AudioStreamGeneratorPlayback
var _creak_playback: AudioStreamGeneratorPlayback
var _whoosh_phase: float = 0.0
var _creak_phase: float = 0.0
var _creak_timer: float = 0.0

func _ready() -> void:
	_create_ui()
	_create_controllers()
	_setup_force_arrows()
	_create_windmill()
	_setup_wind_particles()
	_setup_audio()
	_update_info_label()

func _process(delta: float) -> void:
	_read_physics_state()
	_update_blade_colors()
	_draw_force_arrows()
	_update_wind_particles()
	_update_info_label()
	_update_audio(delta)

	# Update motor speed from wind strength
	if _hinge_joint:
		_hinge_joint.set("motor/target_velocity", _motor_speed)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_UP:
				wind_strength = clamp(wind_strength + 0.5, 0.0, 10.0)
				_motor_speed = wind_strength
				_sync_controllers()
			KEY_DOWN:
				wind_strength = clamp(wind_strength - 0.5, 0.0, 10.0)
				_motor_speed = wind_strength
				_sync_controllers()
			KEY_SPACE:
				wind_strength = 0.0
				_motor_speed = 0.0
				_sync_controllers()
			KEY_R:
				reset()

# ---------------------------------------------------------------------------
# Physics state reading
# ---------------------------------------------------------------------------

func _read_physics_state() -> void:
	if not _blades:
		return
	_prev_angular_velocity = _angular_velocity
	_angular_velocity = _blades.angular_velocity.y
	_rpm = absf(_angular_velocity) * 60.0 / TAU
	_torque = wind_strength - drag_coefficient * absf(_angular_velocity)

	var is_clockwise := _angular_velocity >= 0.0
	if is_clockwise != _was_clockwise:
		_was_clockwise = is_clockwise
		direction_changed.emit(is_clockwise)

	if absf(_angular_velocity - _prev_angular_velocity) > 0.01:
		speed_changed.emit(_angular_velocity, _rpm)

# ---------------------------------------------------------------------------
# Windmill construction
# ---------------------------------------------------------------------------

func _create_windmill() -> void:
	_windmill = Node3D.new()
	_windmill.position = Vector3.ZERO
	add_child(_windmill)

	_create_pole()
	_create_blades()
	_create_hinge()

func _create_pole() -> void:
	_pole = StaticBody3D.new()
	_pole.position = Vector3(0, -0.1, 0)
	_windmill.add_child(_pole)

	var mesh_instance := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.02
	cylinder.bottom_radius = 0.025
	cylinder.height = 0.3
	mesh_instance.mesh = cylinder

	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.5, 0.45, 0.4)
	material.metallic = 0.3
	material.roughness = 0.7
	mesh_instance.material_override = material
	_pole.add_child(mesh_instance)

	var collision := CollisionShape3D.new()
	var cyl_shape := CylinderShape3D.new()
	cyl_shape.radius = 0.025
	cyl_shape.height = 0.3
	collision.shape = cyl_shape
	_pole.add_child(collision)

	# Hub at top
	_hub_mesh = MeshInstance3D.new()
	var hub_sphere := SphereMesh.new()
	hub_sphere.radius = 0.035
	hub_sphere.height = 0.07
	_hub_mesh.mesh = hub_sphere
	_hub_mesh.position = Vector3(0, 0.15, 0)

	var hub_mat := StandardMaterial3D.new()
	hub_mat.albedo_color = Color(0.7, 0.65, 0.6)
	hub_mat.metallic = 0.5
	hub_mat.roughness = 0.4
	_hub_mesh.material_override = hub_mat
	_pole.add_child(_hub_mesh)

func _create_blades() -> void:
	_blades = RigidBody3D.new()
	_blades.position = Vector3(0, 0.05, 0)
	_blades.mass = 1.0
	_blades.gravity_scale = 0.0
	_windmill.add_child(_blades)

	_blade_meshes.clear()
	_blade_materials.clear()

	for i in range(blade_count):
		var angle := TAU * float(i) / float(blade_count)
		var dir := Vector3(cos(angle), 0, sin(angle))
		var pos := dir * 0.1
		# Size: long along radial direction, thin vertically, narrow tangentially
		var size := Vector3(0.15, 0.02, 0.04)
		if blade_count > 2:
			# For 3+ blades, orient all blades radially
			var blade_mesh := MeshInstance3D.new()
			var box := BoxMesh.new()
			box.size = Vector3(0.15, 0.02, 0.04)
			blade_mesh.mesh = box
			blade_mesh.position = pos
			blade_mesh.rotation.y = -angle

			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(0.8, 0.4, 0.9)
			mat.emission_enabled = true
			mat.emission = Color(0.8, 0.4, 0.9) * 0.3
			mat.emission_energy_multiplier = 0.5
			blade_mesh.material_override = mat
			_blades.add_child(blade_mesh)
			_blade_meshes.append(blade_mesh)
			_blade_materials.append(mat)

			var collision := CollisionShape3D.new()
			var box_shape := BoxShape3D.new()
			box_shape.size = Vector3(0.15, 0.02, 0.04)
			collision.shape = box_shape
			collision.position = pos
			collision.rotation.y = -angle
			_blades.add_child(collision)
		else:
			# Legacy 2-blade cross pattern
			_create_blade_pair(pos, size, i)

	# Center hub on blades
	var center := MeshInstance3D.new()
	var center_sphere := SphereMesh.new()
	center_sphere.radius = 0.04
	center_sphere.height = 0.08
	center.mesh = center_sphere

	var center_mat := StandardMaterial3D.new()
	center_mat.albedo_color = Color(0.9, 0.7, 1.0)
	center_mat.emission_enabled = true
	center_mat.emission = Color(0.9, 0.7, 1.0) * 0.4
	center_mat.emission_energy_multiplier = 0.6
	center.material_override = center_mat
	_blades.add_child(center)

	var center_collision := CollisionShape3D.new()
	var center_shape := SphereShape3D.new()
	center_shape.radius = 0.04
	center_collision.shape = center_shape
	_blades.add_child(center_collision)

func _create_blade_pair(pos: Vector3, size: Vector3, _idx: int) -> void:
	# Used for 2-blade mode only
	var mesh_instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh_instance.mesh = box
	mesh_instance.position = pos

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.8, 0.4, 0.9)
	mat.emission_enabled = true
	mat.emission = Color(0.8, 0.4, 0.9) * 0.3
	mat.emission_energy_multiplier = 0.5
	mesh_instance.material_override = mat
	_blades.add_child(mesh_instance)
	_blade_meshes.append(mesh_instance)
	_blade_materials.append(mat)

	var collision := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = size
	collision.shape = box_shape
	collision.position = pos
	_blades.add_child(collision)

	# Opposite blade
	var mesh2 := MeshInstance3D.new()
	var box2 := BoxMesh.new()
	box2.size = size
	mesh2.mesh = box2
	mesh2.position = -pos

	var mat2 := StandardMaterial3D.new()
	mat2.albedo_color = Color(0.8, 0.4, 0.9)
	mat2.emission_enabled = true
	mat2.emission = Color(0.8, 0.4, 0.9) * 0.3
	mat2.emission_energy_multiplier = 0.5
	mesh2.material_override = mat2
	_blades.add_child(mesh2)
	_blade_meshes.append(mesh2)
	_blade_materials.append(mat2)

	var col2 := CollisionShape3D.new()
	var box_shape2 := BoxShape3D.new()
	box_shape2.size = size
	col2.shape = box_shape2
	col2.position = -pos
	_blades.add_child(col2)

func _create_hinge() -> void:
	_hinge_joint = HingeJoint3D.new()
	_hinge_joint.node_a = _pole.get_path()
	_hinge_joint.node_b = _blades.get_path()
	_hinge_joint.position = Vector3(0, 0.05, 0)
	_hinge_joint.set("angular_limit/enable", false)
	_hinge_joint.set("motor/enable", true)
	_hinge_joint.set("motor/target_velocity", _motor_speed)
	_hinge_joint.set("motor/max_impulse", 10.0)
	_windmill.add_child(_hinge_joint)

# ---------------------------------------------------------------------------
# Blade velocity coloring (blue → white → red)
# ---------------------------------------------------------------------------

func _update_blade_colors() -> void:
	var speed := absf(_angular_velocity)
	var max_speed := 10.0
	var t := clampf(speed / max_speed, 0.0, 1.0)

	# Blue (slow) → white (medium) → red (fast)
	var color: Color
	if t < 0.5:
		var s := t * 2.0
		color = Color(0.3 + 0.7 * s, 0.4 + 0.6 * s, 1.0)  # blue → white
	else:
		var s := (t - 0.5) * 2.0
		color = Color(1.0, 1.0 - 0.7 * s, 1.0 - 0.9 * s)  # white → red

	var emission_energy := 0.3 + 1.2 * t

	for mat in _blade_materials:
		mat.albedo_color = color
		mat.emission = color * 0.5
		mat.emission_energy_multiplier = emission_energy

# ---------------------------------------------------------------------------
# Force/torque arrow visualization (ImmediateMesh)
# ---------------------------------------------------------------------------

func _setup_force_arrows() -> void:
	# Wind force arrow (cyan)
	_force_mesh = ImmediateMesh.new()
	_force_mesh_instance = MeshInstance3D.new()
	_force_mesh_instance.mesh = _force_mesh
	var force_mat := StandardMaterial3D.new()
	force_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	force_mat.vertex_color_use_as_albedo = true
	_force_mesh_instance.material_override = force_mat
	add_child(_force_mesh_instance)

	# Torque arrow (orange)
	_torque_mesh = ImmediateMesh.new()
	_torque_mesh_instance = MeshInstance3D.new()
	_torque_mesh_instance.mesh = _torque_mesh
	var torque_mat := StandardMaterial3D.new()
	torque_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	torque_mat.vertex_color_use_as_albedo = true
	_torque_mesh_instance.material_override = torque_mat
	add_child(_torque_mesh_instance)

func _draw_force_arrows() -> void:
	_draw_wind_arrow()
	_draw_torque_arrow()

func _draw_wind_arrow() -> void:
	_force_mesh.clear_surfaces()
	if wind_strength < 0.01:
		return

	_force_mesh.surface_begin(Mesh.PRIMITIVE_LINES)

	var origin := Vector3(-0.3, 0.05, 0)
	var arrow_len := clampf(wind_strength * 0.04, 0.05, 0.35)
	var tip := origin + Vector3(arrow_len, 0, 0)
	var cyan := Color(0.2, 0.9, 1.0)

	# Shaft
	_force_mesh.surface_set_color(cyan)
	_force_mesh.surface_add_vertex(origin)
	_force_mesh.surface_set_color(cyan)
	_force_mesh.surface_add_vertex(tip)

	# Arrowhead
	var head_size := arrow_len * 0.25
	_force_mesh.surface_set_color(cyan)
	_force_mesh.surface_add_vertex(tip)
	_force_mesh.surface_set_color(cyan)
	_force_mesh.surface_add_vertex(tip + Vector3(-head_size, head_size * 0.5, 0))

	_force_mesh.surface_set_color(cyan)
	_force_mesh.surface_add_vertex(tip)
	_force_mesh.surface_set_color(cyan)
	_force_mesh.surface_add_vertex(tip + Vector3(-head_size, -head_size * 0.5, 0))

	# Label: "Wind"
	_force_mesh.surface_end()

func _draw_torque_arrow() -> void:
	_torque_mesh.clear_surfaces()
	if absf(_torque) < 0.01:
		return

	_torque_mesh.surface_begin(Mesh.PRIMITIVE_LINES)

	# Draw circular torque arrow around Y axis at hub height
	var hub_y := 0.05
	var radius := 0.06
	var segments := 16
	var arc_extent := clampf(absf(_torque) * 0.3, 0.3, 0.9)  # fraction of circle
	var sign_dir := 1.0 if _torque > 0.0 else -1.0
	var orange := Color(1.0, 0.6, 0.1)

	for i in range(segments):
		var t0 := float(i) / float(segments) * arc_extent * TAU * sign_dir
		var t1 := float(i + 1) / float(segments) * arc_extent * TAU * sign_dir
		var p0 := Vector3(cos(t0) * radius, hub_y, sin(t0) * radius)
		var p1 := Vector3(cos(t1) * radius, hub_y, sin(t1) * radius)
		_torque_mesh.surface_set_color(orange)
		_torque_mesh.surface_add_vertex(p0)
		_torque_mesh.surface_set_color(orange)
		_torque_mesh.surface_add_vertex(p1)

	# Arrowhead at end of arc
	var end_t := arc_extent * TAU * sign_dir
	var end_p := Vector3(cos(end_t) * radius, hub_y, sin(end_t) * radius)
	var tangent := Vector3(-sin(end_t), 0, cos(end_t)) * sign_dir
	var head_size := 0.02
	_torque_mesh.surface_set_color(orange)
	_torque_mesh.surface_add_vertex(end_p)
	_torque_mesh.surface_set_color(orange)
	_torque_mesh.surface_add_vertex(end_p - tangent * head_size + Vector3(0, head_size * 0.5, 0))
	_torque_mesh.surface_set_color(orange)
	_torque_mesh.surface_add_vertex(end_p)
	_torque_mesh.surface_set_color(orange)
	_torque_mesh.surface_add_vertex(end_p - tangent * head_size - Vector3(0, head_size * 0.5, 0))

	_torque_mesh.surface_end()

# ---------------------------------------------------------------------------
# Wind particles (GPUParticles3D)
# ---------------------------------------------------------------------------

func _setup_wind_particles() -> void:
	_wind_particles = GPUParticles3D.new()
	_wind_particles.amount = 40
	_wind_particles.lifetime = 1.5
	_wind_particles.explosiveness = 0.0
	_wind_particles.randomness = 0.3
	_wind_particles.position = Vector3(-0.4, 0.05, 0)

	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(1, 0, 0)
	mat.spread = 15.0
	mat.initial_velocity_min = 0.1
	mat.initial_velocity_max = 0.3
	mat.gravity = Vector3.ZERO
	mat.scale_min = 0.3
	mat.scale_max = 0.8
	mat.color = Color(0.6, 0.85, 1.0, 0.4)

	var color_ramp := GradientTexture1D.new()
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0.6, 0.85, 1.0, 0.5))
	gradient.set_color(1, Color(0.6, 0.85, 1.0, 0.0))
	color_ramp.gradient = gradient
	mat.color_ramp = color_ramp

	_wind_particles.process_material = mat

	# Draw pass: small sphere
	var draw_mesh := SphereMesh.new()
	draw_mesh.radius = 0.004
	draw_mesh.height = 0.008
	var draw_mat := StandardMaterial3D.new()
	draw_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	draw_mat.vertex_color_use_as_albedo = true
	draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	draw_mat.albedo_color = Color(0.6, 0.85, 1.0, 0.5)
	draw_mesh.material = draw_mat
	_wind_particles.draw_pass_1 = draw_mesh

	add_child(_wind_particles)

func _update_wind_particles() -> void:
	if not _wind_particles or not _wind_particles.process_material:
		return
	var mat: ParticleProcessMaterial = _wind_particles.process_material as ParticleProcessMaterial
	if mat:
		var speed_factor := clampf(wind_strength / 10.0, 0.0, 1.0)
		mat.initial_velocity_min = 0.05 + 0.35 * speed_factor
		mat.initial_velocity_max = 0.15 + 0.55 * speed_factor
		_wind_particles.emitting = wind_strength > 0.1
		_wind_particles.amount = int(lerp(15.0, 60.0, speed_factor))

# ---------------------------------------------------------------------------
# Procedural audio (whoosh + creak)
# ---------------------------------------------------------------------------

func _setup_audio() -> void:
	# Whoosh — continuous wind sound tied to speed
	_whoosh_stream = AudioStreamGenerator.new()
	_whoosh_stream.mix_rate = 22050.0
	_whoosh_stream.buffer_length = 0.1

	_whoosh_player = AudioStreamPlayer3D.new()
	_whoosh_player.stream = _whoosh_stream
	_whoosh_player.volume_db = -12.0
	_whoosh_player.max_distance = 3.0
	add_child(_whoosh_player)
	_whoosh_player.play()
	_whoosh_playback = _whoosh_player.get_stream_playback() as AudioStreamGeneratorPlayback

	# Creak — periodic mechanical stress
	_creak_stream = AudioStreamGenerator.new()
	_creak_stream.mix_rate = 22050.0
	_creak_stream.buffer_length = 0.1

	_creak_player = AudioStreamPlayer3D.new()
	_creak_player.stream = _creak_stream
	_creak_player.volume_db = -18.0
	_creak_player.max_distance = 2.0
	add_child(_creak_player)
	_creak_player.play()
	_creak_playback = _creak_player.get_stream_playback() as AudioStreamGeneratorPlayback

func _update_audio(_delta: float) -> void:
	_fill_whoosh()
	_fill_creak(_delta)

func _fill_whoosh() -> void:
	if not _whoosh_playback:
		return

	var frames := _whoosh_playback.get_frames_available()
	if frames <= 0:
		return

	var speed := absf(_angular_velocity)
	var volume := clampf(speed / 8.0, 0.0, 0.6)
	var freq := 80.0 + speed * 40.0  # Low rumble that rises with speed
	var mix_rate := _whoosh_stream.mix_rate

	for i in range(frames):
		_whoosh_phase += freq / mix_rate
		if _whoosh_phase > 1.0:
			_whoosh_phase -= 1.0
		# Band-limited noise-ish whoosh: modulated sine + noise
		var base_wave := sin(_whoosh_phase * TAU)
		var noise_val := sin(_whoosh_phase * TAU * 7.3) * 0.3 + sin(_whoosh_phase * TAU * 13.1) * 0.2
		var sample := (base_wave * 0.5 + noise_val) * volume
		_whoosh_playback.push_frame(Vector2(sample, sample))

func _fill_creak(_delta: float) -> void:
	if not _creak_playback:
		return

	var frames := _creak_playback.get_frames_available()
	if frames <= 0:
		return

	_creak_timer += _delta
	var speed := absf(_angular_velocity)
	# Creak happens periodically, more often at higher speeds
	var creak_interval := 2.0 / maxf(speed, 0.5)
	var creak_active := fmod(_creak_timer, creak_interval) < 0.15
	var creak_vol := clampf(speed / 6.0, 0.0, 0.3) if creak_active else 0.0
	var mix_rate := _creak_stream.mix_rate

	for i in range(frames):
		_creak_phase += 220.0 / mix_rate
		if _creak_phase > 1.0:
			_creak_phase -= 1.0
		# Metallic creak: sharp overtones
		var s := sin(_creak_phase * TAU * 3.0) * 0.5 + sin(_creak_phase * TAU * 5.7) * 0.3
		s *= creak_vol
		_creak_playback.push_frame(Vector2(s, s))

# ---------------------------------------------------------------------------
# UI
# ---------------------------------------------------------------------------

func _create_ui() -> void:
	_info_label = Label3D.new()
	_info_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_info_label.font_size = 28
	_info_label.outline_size = 4
	_info_label.modulate = Color(1.0, 0.9, 1.0)
	_info_label.position = Vector3(0, 0.7, 0)
	add_child(_info_label)

	_metrics_label = Label3D.new()
	_metrics_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_metrics_label.font_size = 20
	_metrics_label.outline_size = 3
	_metrics_label.modulate = Color(0.8, 0.9, 1.0)
	_metrics_label.position = Vector3(0, 0.55, 0)
	add_child(_metrics_label)

func _update_info_label() -> void:
	if _info_label:
		_info_label.text = "Windmill (HingeJoint3D) | %d Blades" % blade_count

	if _metrics_label:
		var dir_str := "CW" if _angular_velocity >= 0 else "CCW"
		_metrics_label.text = "ω: %.2f rad/s | RPM: %.1f | τ: %.2f Nm | %s\nWind: %.1f | Drag: %.2f" % [
			_angular_velocity, _rpm, _torque, dir_str, wind_strength, drag_coefficient
		]

func _create_controllers() -> void:
	# Wind strength slider
	_wind_controller = ParameterController3D.new()
	_wind_controller.parameter_name = "Wind Strength"
	_wind_controller.min_value = 0.0
	_wind_controller.max_value = 10.0
	_wind_controller.default_value = wind_strength
	_wind_controller.step_size = 0.5
	_wind_controller.position = Vector3(-0.25, -0.55, 0)
	_wind_controller.value_changed.connect(_on_wind_changed)
	add_child(_wind_controller)

	# Drag coefficient slider
	_drag_controller = ParameterController3D.new()
	_drag_controller.parameter_name = "Drag"
	_drag_controller.min_value = 0.0
	_drag_controller.max_value = 2.0
	_drag_controller.default_value = drag_coefficient
	_drag_controller.step_size = 0.1
	_drag_controller.position = Vector3(0.0, -0.55, 0)
	_drag_controller.value_changed.connect(_on_drag_changed)
	add_child(_drag_controller)

	# Blade count slider
	_blades_controller = ParameterController3D.new()
	_blades_controller.parameter_name = "Blades"
	_blades_controller.min_value = 2.0
	_blades_controller.max_value = 8.0
	_blades_controller.default_value = float(blade_count)
	_blades_controller.step_size = 1.0
	_blades_controller.position = Vector3(0.25, -0.55, 0)
	_blades_controller.value_changed.connect(_on_blades_changed)
	add_child(_blades_controller)

	var instructions := Label3D.new()
	instructions.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	instructions.font_size = 16
	instructions.modulate = Color(0.8, 1.0, 0.8)
	instructions.position = Vector3(0, -0.7, 0)
	instructions.text = "[↑/↓] Wind | [SPACE] Stop | [R] Reset"
	add_child(instructions)

func _on_wind_changed(value: float) -> void:
	wind_strength = value
	_motor_speed = wind_strength

func _on_drag_changed(value: float) -> void:
	drag_coefficient = value

func _on_blades_changed(value: float) -> void:
	var new_count := int(value)
	if new_count != blade_count:
		blade_count = new_count
		_rebuild_blades()

func _sync_controllers() -> void:
	if _wind_controller:
		_wind_controller.set_value(wind_strength)

# ---------------------------------------------------------------------------
# Blade rebuild (when count changes)
# ---------------------------------------------------------------------------

func _rebuild_blades() -> void:
	if not _blades or not _windmill:
		return

	# Store state
	var ang_vel := _blades.angular_velocity
	var rot := _blades.rotation

	# Remove old blades and hinge
	if _hinge_joint:
		_hinge_joint.queue_free()
		_hinge_joint = null
	_blades.queue_free()
	_blades = null
	_blade_meshes.clear()
	_blade_materials.clear()

	# Rebuild
	await get_tree().process_frame
	_create_blades()
	_create_hinge()

	# Restore state
	if _blades:
		_blades.rotation = rot
		_blades.angular_velocity = ang_vel

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

func reset() -> void:
	wind_strength = 2.0
	drag_coefficient = 0.3
	_motor_speed = wind_strength

	if _blades:
		_blades.angular_velocity = Vector3.ZERO
		_blades.rotation = Vector3.ZERO

	if _hinge_joint:
		_hinge_joint.set("motor/target_velocity", _motor_speed)

	_sync_controllers()
	if _drag_controller:
		_drag_controller.set_value(drag_coefficient)
	_update_info_label()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

func apply_grid_config(config: Dictionary) -> void:
	if config.has("blade_count"):
		blade_count = clampi(int(config.blade_count), 2, 8)
	if config.has("wind_strength"):
		wind_strength = clampf(float(config.wind_strength), 0.0, 10.0)
		_motor_speed = wind_strength
	if config.has("drag_coefficient"):
		drag_coefficient = clampf(float(config.drag_coefficient), 0.0, 2.0)

	# Rebuild with new params
	if _windmill:
		for child in _windmill.get_children():
			child.queue_free()
		_blade_meshes.clear()
		_blade_materials.clear()
		_hinge_joint = null
		_blades = null
		_pole = null
		# The config can arrive while this node is OUT of the tree: the grid defers
		# apply_grid_config, and composers (curation_station) configure what they build.
		# get_tree() is null there. Wait for a tree; a node never added never resumes.
		if not is_inside_tree():
			await tree_entered
		await get_tree().process_frame
		_create_pole()
		_create_blades()
		_create_hinge()

	_sync_controllers()
	if _drag_controller:
		_drag_controller.set_value(drag_coefficient)
	if _blades_controller:
		_blades_controller.set_value(float(blade_count))
	_update_info_label()
