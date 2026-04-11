# ===========================================================================
# NOC Example 4.1: Single Particle — Force Field Playground
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# Elevated: multiple force fields (gravity wells, repellers, drag zones),
# velocity-colored trail, real-time force arrows, energy conservation display,
# VR sliders for parameter exploration.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D

## Example 4.1: Single Particle — Force Field Playground
## One particle navigating configurable force fields with full visualization
## Chapter 04: Particle Systems


# ── Force source types ─────────────────────────────────────────────────
enum ForceType { GRAVITY_WELL, REPELLER, DRAG_ZONE }

class ForceSource:
	var type: int  # ForceType enum
	var pos: Vector3
	var strength: float
	var radius: float
	var color: Color

	func _init(t: int, p: Vector3, s: float, r: float, c: Color):
		type = t
		pos = p
		strength = s
		radius = r
		color = c


# ── Particle state ─────────────────────────────────────────────────────
var _particle_pos := Vector3(0, 0.3, 0)
var _particle_vel := Vector3.ZERO
var _particle_acc := Vector3.ZERO
var _particle_mass := 1.0
var _particle_alive := true

# Trail history
var _trail_positions: Array[Vector3] = []
var _trail_velocities: Array[float] = []
var _max_trail := 400
var _max_velocity := 0.001

# Force sources
var _sources: Array = []

# Net force this frame (for arrow drawing)
var _net_force := Vector3.ZERO
var _per_source_forces: Array[Vector3] = []

# Energy tracking
var _kinetic_energy := 0.0
var _potential_energy := 0.0
var _total_energy := 0.0


# ── Tunable parameters ────────────────────────────────────────────────
var gravity_strength := 3.0
var repeller_strength := 2.5
var drag_coefficient := 0.92
var damping := 0.999


# ── Visual nodes ───────────────────────────────────────────────────────
var _particle_mesh_inst: MeshInstance3D
var _particle_mat: StandardMaterial3D

# Trail mesh (ImmediateMesh)
var _trail_im: ImmediateMesh
var _trail_mi: MeshInstance3D

# Glow overlay (recent trail segment)
var _glow_im: ImmediateMesh
var _glow_mi: MeshInstance3D

# Force arrow mesh
var _arrow_im: ImmediateMesh
var _arrow_mi: MeshInstance3D

# Force source visuals
var _source_im: ImmediateMesh
var _source_mi: MeshInstance3D

# Labels
var _info_label: Label3D
var _energy_label: Label3D

# VR sliders
var _gravity_ctrl: ParameterController3D
var _repeller_ctrl: ParameterController3D
var _drag_ctrl: ParameterController3D
var _trail_ctrl: ParameterController3D


# ── Bounding ───────────────────────────────────────────────────────────
var _bounds := 0.4  # half-extent of play area


func _ready() -> void:
	_setup_force_sources()
	_setup_particle_visual()
	_setup_trail_meshes()
	_setup_arrow_mesh()
	_setup_source_mesh()
	_setup_labels()
	_setup_controllers()
	_spawn_particle()


# ── Force source layout ───────────────────────────────────────────────

func _setup_force_sources() -> void:
	_sources.clear()

	# Gravity well (blue attractor) — lower-left
	_sources.append(ForceSource.new(
		ForceType.GRAVITY_WELL,
		Vector3(-0.2, -0.05, -0.1),
		gravity_strength,
		0.35,
		Color(0.2, 0.5, 1.0, 0.6)
	))

	# Gravity well (purple attractor) — upper-right
	_sources.append(ForceSource.new(
		ForceType.GRAVITY_WELL,
		Vector3(0.18, 0.2, 0.12),
		gravity_strength * 0.7,
		0.3,
		Color(0.6, 0.3, 1.0, 0.6)
	))

	# Repeller (red) — center
	_sources.append(ForceSource.new(
		ForceType.REPELLER,
		Vector3(0, 0.05, 0),
		repeller_strength,
		0.25,
		Color(1.0, 0.3, 0.3, 0.5)
	))

	# Drag zone (green) — right side
	_sources.append(ForceSource.new(
		ForceType.DRAG_ZONE,
		Vector3(0.25, 0.1, -0.15),
		drag_coefficient,
		0.2,
		Color(0.2, 0.8, 0.4, 0.3)
	))

	_per_source_forces.resize(_sources.size())
	for i in _sources.size():
		_per_source_forces[i] = Vector3.ZERO


# ── Particle visual ───────────────────────────────────────────────────

func _setup_particle_visual() -> void:
	_particle_mesh_inst = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.018
	sphere.height = 0.036
	_particle_mesh_inst.mesh = sphere

	_particle_mat = StandardMaterial3D.new()
	_particle_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_particle_mat.albedo_color = Color(1.0, 0.95, 0.8)
	_particle_mat.emission_enabled = true
	_particle_mat.emission = Color(1.0, 0.9, 0.7)
	_particle_mat.emission_energy_multiplier = 4.0
	_particle_mesh_inst.material_override = _particle_mat
	add_child(_particle_mesh_inst)


# ── Trail meshes ──────────────────────────────────────────────────────

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
	gmat.emission = Color(1.0, 0.8, 0.5)
	gmat.emission_energy_multiplier = 2.0
	_glow_mi.material_override = gmat
	add_child(_glow_mi)


# ── Arrow mesh (force vectors) ────────────────────────────────────────

func _setup_arrow_mesh() -> void:
	_arrow_im = ImmediateMesh.new()
	_arrow_mi = MeshInstance3D.new()
	_arrow_mi.mesh = _arrow_im
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	_arrow_mi.material_override = mat
	add_child(_arrow_mi)


# ── Force source field visualization ──────────────────────────────────

func _setup_source_mesh() -> void:
	_source_im = ImmediateMesh.new()
	_source_mi = MeshInstance3D.new()
	_source_mi.mesh = _source_im
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_source_mi.material_override = mat
	add_child(_source_mi)


# ── Labels ─────────────────────────────────────────────────────────────

func _setup_labels() -> void:
	_info_label = Label3D.new()
	_info_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_info_label.font_size = 24
	_info_label.outline_size = 4
	_info_label.modulate = Color(1.0, 0.95, 0.9)
	_info_label.position = Vector3(0, 0.58, 0)
	add_child(_info_label)

	_energy_label = Label3D.new()
	_energy_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_energy_label.font_size = 18
	_energy_label.outline_size = 3
	_energy_label.modulate = Color(0.7, 0.9, 1.0)
	_energy_label.position = Vector3(0, 0.50, 0)
	add_child(_energy_label)


# ── VR controllers ─────────────────────────────────────────────────────

func _setup_controllers() -> void:
	var y_pos := -_bounds - 0.18

	_gravity_ctrl = ParameterController3D.new()
	_gravity_ctrl.parameter_name = "Gravity"
	_gravity_ctrl.min_value = 0.0
	_gravity_ctrl.max_value = 8.0
	_gravity_ctrl.default_value = gravity_strength
	_gravity_ctrl.step_size = 0.1
	_gravity_ctrl.position = Vector3(-0.3, y_pos, 0)
	_gravity_ctrl.value_changed.connect(_on_gravity_changed)
	add_child(_gravity_ctrl)

	_repeller_ctrl = ParameterController3D.new()
	_repeller_ctrl.parameter_name = "Repel"
	_repeller_ctrl.min_value = 0.0
	_repeller_ctrl.max_value = 8.0
	_repeller_ctrl.default_value = repeller_strength
	_repeller_ctrl.step_size = 0.1
	_repeller_ctrl.position = Vector3(-0.1, y_pos, 0)
	_repeller_ctrl.value_changed.connect(_on_repeller_changed)
	add_child(_repeller_ctrl)

	_drag_ctrl = ParameterController3D.new()
	_drag_ctrl.parameter_name = "Drag"
	_drag_ctrl.min_value = 0.5
	_drag_ctrl.max_value = 1.0
	_drag_ctrl.default_value = drag_coefficient
	_drag_ctrl.step_size = 0.01
	_drag_ctrl.position = Vector3(0.1, y_pos, 0)
	_drag_ctrl.value_changed.connect(_on_drag_changed)
	add_child(_drag_ctrl)

	_trail_ctrl = ParameterController3D.new()
	_trail_ctrl.parameter_name = "Trail"
	_trail_ctrl.min_value = 50.0
	_trail_ctrl.max_value = 800.0
	_trail_ctrl.default_value = float(_max_trail)
	_trail_ctrl.step_size = 50.0
	_trail_ctrl.position = Vector3(0.3, y_pos, 0)
	_trail_ctrl.value_changed.connect(_on_trail_changed)
	add_child(_trail_ctrl)


# ── Controller callbacks ──────────────────────────────────────────────

func _on_gravity_changed(val: float) -> void:
	gravity_strength = val
	for src in _sources:
		if src.type == ForceType.GRAVITY_WELL:
			src.strength = val * (1.0 if _sources.find(src) == 0 else 0.7)

func _on_repeller_changed(val: float) -> void:
	repeller_strength = val
	for src in _sources:
		if src.type == ForceType.REPELLER:
			src.strength = val

func _on_drag_changed(val: float) -> void:
	drag_coefficient = val
	for src in _sources:
		if src.type == ForceType.DRAG_ZONE:
			src.strength = val

func _on_trail_changed(val: float) -> void:
	_max_trail = int(val)


# ── Spawn / reset ─────────────────────────────────────────────────────

func _spawn_particle() -> void:
	_particle_pos = Vector3(
		randf_range(-0.15, 0.15),
		randf_range(0.15, 0.35),
		randf_range(-0.15, 0.15)
	)
	_particle_vel = Vector3(
		randf_range(-0.3, 0.3),
		randf_range(0.2, 0.6),
		randf_range(-0.3, 0.3)
	)
	_particle_acc = Vector3.ZERO
	_particle_alive = true
	_trail_positions.clear()
	_trail_velocities.clear()
	_max_velocity = 0.001


# ── Physics step ──────────────────────────────────────────────────────

func _process(delta: float) -> void:
	if not _particle_alive:
		return

	# Accumulate forces
	_net_force = Vector3.ZERO
	for i in _sources.size():
		_per_source_forces[i] = _compute_force(_sources[i])
		_net_force += _per_source_forces[i]

	# Integrate
	_particle_acc = _net_force / _particle_mass
	_particle_vel += _particle_acc * delta
	_particle_vel *= damping
	_particle_pos += _particle_vel * delta

	# Bounce off bounds
	_bounce_bounds()

	# Record trail
	_trail_positions.append(_particle_pos)
	var speed := _particle_vel.length()
	_trail_velocities.append(speed)
	if speed > _max_velocity:
		_max_velocity = speed
	while _trail_positions.size() > _max_trail:
		_trail_positions.remove_at(0)
		_trail_velocities.remove_at(0)

	# Compute energy
	_kinetic_energy = 0.5 * _particle_mass * speed * speed
	_potential_energy = 0.0
	for src in _sources:
		if src.type == ForceType.GRAVITY_WELL:
			var dist := _particle_pos.distance_to(src.pos)
			_potential_energy -= src.strength * _particle_mass / maxf(dist, 0.01)
	_total_energy = _kinetic_energy + _potential_energy

	# Animate force source positions slightly
	_animate_sources(delta)

	# Update visuals
	_particle_mesh_inst.position = _particle_pos
	_update_particle_glow(speed)
	_rebuild_trail()
	_rebuild_glow_overlay()
	_draw_force_arrows()
	_draw_source_fields()
	_update_labels(speed)


func _compute_force(src: ForceSource) -> Vector3:
	match src.type:
		ForceType.GRAVITY_WELL:
			var dir := src.pos - _particle_pos
			var dist := dir.length()
			if dist < 0.01:
				return Vector3.ZERO
			dir = dir.normalized()
			# Inverse-square attraction, clamped
			var mag := src.strength / maxf(dist * dist, 0.04)
			return dir * minf(mag, 15.0)

		ForceType.REPELLER:
			var dir := _particle_pos - src.pos
			var dist := dir.length()
			if dist < 0.01:
				return Vector3(randf_range(-1, 1), 1, randf_range(-1, 1)).normalized() * src.strength
			dir = dir.normalized()
			var mag := src.strength / maxf(dist * dist, 0.04)
			return dir * minf(mag, 15.0)

		ForceType.DRAG_ZONE:
			var dist := _particle_pos.distance_to(src.pos)
			if dist < src.radius:
				# Apply drag: reduce velocity toward zero
				var drag_factor := 1.0 - (1.0 - src.strength) * (1.0 - dist / src.radius)
				return -_particle_vel * (1.0 - drag_factor) * 5.0
			return Vector3.ZERO

	return Vector3.ZERO


func _bounce_bounds() -> void:
	for axis in [0, 1, 2]:  # x, y, z
		if _particle_pos[axis] < -_bounds:
			_particle_pos[axis] = -_bounds
			_particle_vel[axis] = absf(_particle_vel[axis]) * 0.7
		elif _particle_pos[axis] > _bounds:
			_particle_pos[axis] = _bounds
			_particle_vel[axis] = -absf(_particle_vel[axis]) * 0.7


func _animate_sources(_delta: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	# Gentle orbit for gravity wells
	if _sources.size() > 0:
		_sources[0].pos.x = -0.2 + sin(t * 0.4) * 0.05
		_sources[0].pos.z = -0.1 + cos(t * 0.4) * 0.05
	if _sources.size() > 1:
		_sources[1].pos.x = 0.18 + cos(t * 0.3) * 0.04
		_sources[1].pos.z = 0.12 + sin(t * 0.3) * 0.04


# ── Velocity → color gradient ─────────────────────────────────────────

func _velocity_color(vel: float, age_t: float) -> Color:
	var t := clampf(vel / maxf(_max_velocity, 0.001), 0.0, 1.0)
	var r: float
	var g: float
	var b: float

	if t < 0.25:
		var s := t * 4.0
		r = 0.1
		g = 0.2 + 0.6 * s
		b = 0.9 - 0.2 * s
	elif t < 0.5:
		var s := (t - 0.25) * 4.0
		r = 0.1 + 0.5 * s
		g = 0.8
		b = 0.7 - 0.5 * s
	elif t < 0.75:
		var s := (t - 0.5) * 4.0
		r = 0.6 + 0.4 * s
		g = 0.8 - 0.2 * s
		b = 0.2 - 0.1 * s
	else:
		var s := (t - 0.75) * 4.0
		r = 1.0
		g = 0.6 - 0.5 * s
		b = 0.1

	var alpha := 0.15 + 0.85 * age_t
	return Color(r, g, b, alpha)


# ── Trail rendering ───────────────────────────────────────────────────

func _rebuild_trail() -> void:
	_trail_im.clear_surfaces()
	var count := _trail_positions.size()
	if count < 2:
		return

	_trail_im.surface_begin(Mesh.PRIMITIVE_LINES)
	for i in range(1, count):
		var age_t := float(i) / float(count)
		var color := _velocity_color(_trail_velocities[i], age_t)
		_trail_im.surface_set_color(color)
		_trail_im.surface_add_vertex(_trail_positions[i - 1])
		_trail_im.surface_set_color(color)
		_trail_im.surface_add_vertex(_trail_positions[i])
	_trail_im.surface_end()


func _rebuild_glow_overlay() -> void:
	_glow_im.clear_surfaces()
	var count := _trail_positions.size()
	var glow_start := int(count * 0.92)
	if glow_start >= count - 1:
		return

	_glow_im.surface_begin(Mesh.PRIMITIVE_LINES)
	for i in range(glow_start + 1, count):
		var local_t := float(i - glow_start) / float(count - glow_start)
		var vel := _trail_velocities[i]
		var t := clampf(vel / maxf(_max_velocity, 0.001), 0.0, 1.0)
		var color := Color(1.0, 0.7 + 0.3 * (1.0 - t), 0.4 + 0.4 * (1.0 - t), local_t)
		_glow_im.surface_set_color(color)
		_glow_im.surface_add_vertex(_trail_positions[i - 1])
		_glow_im.surface_set_color(color)
		_glow_im.surface_add_vertex(_trail_positions[i])
	_glow_im.surface_end()


func _update_particle_glow(speed: float) -> void:
	var t := clampf(speed / maxf(_max_velocity, 0.001), 0.0, 1.0)
	_particle_mat.emission = Color(1.0, 0.7 + 0.3 * (1.0 - t), 0.5 + 0.5 * (1.0 - t))
	_particle_mat.emission_energy_multiplier = 3.0 + 5.0 * t


# ── Force arrow drawing ──────────────────────────────────────────────

func _draw_force_arrows() -> void:
	_arrow_im.clear_surfaces()
	_arrow_im.surface_begin(Mesh.PRIMITIVE_LINES)

	# Per-source force arrows (colored by source)
	for i in _sources.size():
		var f := _per_source_forces[i]
		if f.length() < 0.01:
			continue
		var color: Color = _sources[i].color
		color.a = 1.0
		_draw_arrow(_particle_pos, f, color, 0.06)

	# Net force arrow (white, thicker visual weight)
	if _net_force.length() > 0.01:
		_draw_arrow(_particle_pos, _net_force, Color(1.0, 1.0, 1.0, 0.9), 0.08)

	_arrow_im.surface_end()


func _draw_arrow(origin: Vector3, force: Vector3, color: Color, scale: float) -> void:
	var dir := force.normalized()
	var len := clampf(force.length() * 0.02, 0.02, scale)
	var tip := origin + dir * len

	# Shaft
	_arrow_im.surface_set_color(color)
	_arrow_im.surface_add_vertex(origin)
	_arrow_im.surface_set_color(color)
	_arrow_im.surface_add_vertex(tip)

	# Arrowhead — find two perpendicular directions
	var perp := Vector3.UP
	if absf(dir.dot(Vector3.UP)) > 0.9:
		perp = Vector3.RIGHT
	var side := dir.cross(perp).normalized()
	var head_size := len * 0.3

	_arrow_im.surface_set_color(color)
	_arrow_im.surface_add_vertex(tip)
	_arrow_im.surface_set_color(color)
	_arrow_im.surface_add_vertex(tip - dir * head_size + side * head_size * 0.5)

	_arrow_im.surface_set_color(color)
	_arrow_im.surface_add_vertex(tip)
	_arrow_im.surface_set_color(color)
	_arrow_im.surface_add_vertex(tip - dir * head_size - side * head_size * 0.5)


# ── Source field visualization ────────────────────────────────────────

func _draw_source_fields() -> void:
	_source_im.clear_surfaces()
	_source_im.surface_begin(Mesh.PRIMITIVE_LINES)

	for src in _sources:
		var segments := 24
		var color: Color = src.color

		match src.type:
			ForceType.GRAVITY_WELL:
				# Concentric rings showing pull
				for ring in range(2):
					var r: float = src.radius * (0.5 + 0.5 * ring)
					_draw_circle(src.pos, r, segments, color)
				# Inward ticks
				for j in range(8):
					var angle := float(j) / 8.0 * TAU
					var outer: Vector3 = src.pos + Vector3(cos(angle), 0, sin(angle)) * src.radius
					var inner: Vector3 = src.pos + Vector3(cos(angle), 0, sin(angle)) * src.radius * 0.7
					_source_im.surface_set_color(color)
					_source_im.surface_add_vertex(outer)
					_source_im.surface_set_color(color)
					_source_im.surface_add_vertex(inner)

			ForceType.REPELLER:
				# Single ring
				_draw_circle(src.pos, src.radius, segments, color)
				# Outward ticks
				for j in range(8):
					var angle := float(j) / 8.0 * TAU
					var inner: Vector3 = src.pos + Vector3(cos(angle), 0, sin(angle)) * src.radius * 0.8
					var outer: Vector3 = src.pos + Vector3(cos(angle), 0, sin(angle)) * src.radius * 1.1
					_source_im.surface_set_color(color)
					_source_im.surface_add_vertex(inner)
					_source_im.surface_set_color(color)
					_source_im.surface_add_vertex(outer)

			ForceType.DRAG_ZONE:
				# Dashed ring
				_draw_circle(src.pos, src.radius, segments, color)
				# Cross-hatch interior
				for j in range(4):
					var angle := float(j) / 4.0 * TAU
					var a: Vector3 = src.pos + Vector3(cos(angle), 0, sin(angle)) * src.radius * 0.3
					var b: Vector3 = src.pos + Vector3(cos(angle + PI), 0, sin(angle + PI)) * src.radius * 0.3
					_source_im.surface_set_color(Color(color.r, color.g, color.b, 0.2))
					_source_im.surface_add_vertex(a)
					_source_im.surface_set_color(Color(color.r, color.g, color.b, 0.2))
					_source_im.surface_add_vertex(b)

	_source_im.surface_end()


func _draw_circle(center: Vector3, radius: float, segments: int, color: Color) -> void:
	for i in range(segments):
		var a0 := float(i) / float(segments) * TAU
		var a1 := float(i + 1) / float(segments) * TAU
		_source_im.surface_set_color(color)
		_source_im.surface_add_vertex(center + Vector3(cos(a0) * radius, 0, sin(a0) * radius))
		_source_im.surface_set_color(color)
		_source_im.surface_add_vertex(center + Vector3(cos(a1) * radius, 0, sin(a1) * radius))


# ── Labels ─────────────────────────────────────────────────────────────

func _update_labels(speed: float) -> void:
	if _info_label:
		_info_label.text = "Force Field Playground\nSpeed: %.2f  |  Trail: %d pts" % [speed, _trail_positions.size()]

	if _energy_label:
		_energy_label.text = "KE: %.3f  PE: %.3f  Total: %.3f" % [_kinetic_energy, _potential_energy, _total_energy]


# ── Input ──────────────────────────────────────────────────────────────

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			_spawn_particle()
		elif event.keycode == KEY_R:
			_spawn_particle()


# ── Cleanup ────────────────────────────────────────────────────────────

func _exit_tree() -> void:
	if _trail_im:
		_trail_im.clear_surfaces()
	if _glow_im:
		_glow_im.clear_surfaces()
	if _arrow_im:
		_arrow_im.clear_surfaces()
	if _source_im:
		_source_im.clear_surfaces()


# ── Grid config ────────────────────────────────────────────────────────

func apply_grid_config(config: Dictionary) -> void:
	if config.has("gravity"):
		gravity_strength = clampf(float(config.gravity), 0.0, 8.0)
		_on_gravity_changed(gravity_strength)
		if _gravity_ctrl:
			_gravity_ctrl.set_value(gravity_strength)

	if config.has("repel"):
		repeller_strength = clampf(float(config.repel), 0.0, 8.0)
		_on_repeller_changed(repeller_strength)
		if _repeller_ctrl:
			_repeller_ctrl.set_value(repeller_strength)

	if config.has("drag"):
		drag_coefficient = clampf(float(config.drag), 0.5, 1.0)
		_on_drag_changed(drag_coefficient)
		if _drag_ctrl:
			_drag_ctrl.set_value(drag_coefficient)

	if config.has("trail_length"):
		_max_trail = clampi(int(config.trail_length), 50, 800)
		if _trail_ctrl:
			_trail_ctrl.set_value(float(_max_trail))

	_spawn_particle()
