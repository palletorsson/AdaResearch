# @identity
# essence: the VR hand is a repeller — drag the controller through the swarm and feel the force law you've selected
# desire: make a force law tactile — the difference between 1/r² and e^(-r) and r³ becomes a hand-feel, not a graph
# critical_parameter: force law selection (INVERSE_SQUARE / EXPONENTIAL / POLYNOMIAL) — it changes the falloff profile and therefore the response radius
# triggers: _ready() spawns particles + immediate mesh viz; _physics_process() reads controller transform and applies the chosen law to every particle
# emerges: a felt difference between gentle long-range push (inverse square) and sharp short-range slap (exponential / polynomial)
# needs: law selector dial [present]; strength slider [present]; particle count slider [present]
# relationships: hand-driven inverse of example_4_1_single_particle_vr (static fields); culmination of chapter 4 particle examples; bridges to physicssimulation where hand-controlled forces become physically modeled
# truth: A force law is a verb. Letting the player conjugate it with their own hand turns abstract physics into an interface — every gesture is an experiment.

# ===========================================================================
# NOC Example 4.6: Particle Repeller — VR Hand Interaction
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# Elevated: VR hand becomes the repeller (drag with controller),
# particle-particle collisions, multiple force law options
# (inverse-square, exponential, polynomial), velocity heatmap coloring,
# ImmediateMesh force field viz, VR sliders.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D

## Example 4.6: Particle Repeller — VR Hand Interaction
## Multi-particle system with hand-controlled repeller and configurable force laws
## Chapter 04: Particle Systems


# ── Force law types ──────────────────────────────────────────────────
enum ForceLaw { INVERSE_SQUARE, EXPONENTIAL, POLYNOMIAL }

const FORCE_LAW_NAMES := ["1/r²", "e^(-r)", "r³"]


# ── Particle data (struct-of-arrays for performance) ─────────────────
var _positions: Array[Vector3] = []
var _velocities: Array[Vector3] = []
var _lifespans: Array[float] = []
var _max_lifespans: Array[float] = []

var _max_particles := 200
var _particle_lifetime := 6.0
var _particle_radius := 0.012


# ── Emitter ──────────────────────────────────────────────────────────
var _emitter_pos := Vector3(0, 0.35, 0)
var _emission_rate := 18.0
var _emission_timer := 0.0


# ── Repeller ─────────────────────────────────────────────────────────
var _repeller_pos := Vector3.ZERO
var _repeller_strength := 3.0
var _repeller_radius := 0.22
var _vr_controller: XRController3D = null
var _hand_grip_active := false


# ── Force law ────────────────────────────────────────────────────────
var _force_law: int = ForceLaw.INVERSE_SQUARE


# ── Physics ──────────────────────────────────────────────────────────
var _gravity := Vector3(0, -0.6, 0)
var _damping := 0.998
var _bounds := 0.4
var _collision_enabled := true
var _collision_radius := 0.024  # 2× particle radius


# ── Velocity tracking ───────────────────────────────────────────────
var _max_velocity := 0.001


# ── Visual nodes ─────────────────────────────────────────────────────
# MultiMesh for particles (per-instance color)
var _mm_inst: MultiMeshInstance3D

# Repeller sphere
var _repeller_mesh_inst: MeshInstance3D
var _repeller_mat: StandardMaterial3D

# Force field visualization (ImmediateMesh)
var _field_im: ImmediateMesh
var _field_mi: MeshInstance3D

# Collision flash lines (ImmediateMesh)
var _flash_im: ImmediateMesh
var _flash_mi: MeshInstance3D

# Emitter marker
var _emitter_mesh_inst: MeshInstance3D

# Labels
var _info_label: Label3D
var _law_label: Label3D

# VR controllers
var _strength_ctrl: ParameterController3D
var _rate_ctrl: ParameterController3D
var _law_ctrl: ParameterController3D
var _collision_ctrl: ParameterController3D


# ── Collision flash buffer ───────────────────────────────────────────
var _collision_flashes: Array[Vector3] = []  # pairs of positions
const MAX_FLASHES := 20


func _ready() -> void:
	_find_vr_controller()
	_setup_multimesh()
	_setup_repeller_visual()
	_setup_emitter_visual()
	_setup_field_mesh()
	_setup_flash_mesh()
	_setup_labels()
	_setup_controllers()


# ── VR controller detection ──────────────────────────────────────────

func _find_vr_controller() -> void:
	# Walk up tree looking for XRController3D parent
	var node := get_parent()
	while node:
		if node is XRController3D:
			_vr_controller = node as XRController3D
			return
		node = node.get_parent()


# ── MultiMesh for particles ──────────────────────────────────────────

func _setup_multimesh() -> void:
	_mm_inst = MultiMeshInstance3D.new()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = _max_particles
	mm.visible_instance_count = 0
	mm.use_colors = true

	var sphere := SphereMesh.new()
	sphere.radius = _particle_radius
	sphere.height = _particle_radius * 2.0
	sphere.radial_segments = 8
	sphere.rings = 4
	mm.mesh = sphere

	_mm_inst.multimesh = mm

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(0.8, 0.6, 0.4)
	mat.emission_energy_multiplier = 1.5
	_mm_inst.material_override = mat

	add_child(_mm_inst)


# ── Repeller visual ─────────────────────────────────────────────────

func _setup_repeller_visual() -> void:
	_repeller_mesh_inst = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = _repeller_radius * 0.4
	sphere.height = _repeller_radius * 0.8
	_repeller_mesh_inst.mesh = sphere

	_repeller_mat = StandardMaterial3D.new()
	_repeller_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_repeller_mat.albedo_color = Color(1.0, 0.25, 0.25, 0.6)
	_repeller_mat.emission_enabled = true
	_repeller_mat.emission = Color(1.0, 0.3, 0.3)
	_repeller_mat.emission_energy_multiplier = 2.0
	_repeller_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_repeller_mesh_inst.material_override = _repeller_mat

	add_child(_repeller_mesh_inst)


# ── Emitter visual ──────────────────────────────────────────────────

func _setup_emitter_visual() -> void:
	_emitter_mesh_inst = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.025
	sphere.height = 0.05
	_emitter_mesh_inst.mesh = sphere

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.6, 0.9, 1.0, 0.8)
	mat.emission_enabled = true
	mat.emission = Color(0.6, 0.9, 1.0)
	mat.emission_energy_multiplier = 2.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_emitter_mesh_inst.material_override = mat
	_emitter_mesh_inst.position = _emitter_pos

	add_child(_emitter_mesh_inst)


# ── Force field ImmediateMesh ────────────────────────────────────────

func _setup_field_mesh() -> void:
	_field_im = ImmediateMesh.new()
	_field_mi = MeshInstance3D.new()
	_field_mi.mesh = _field_im
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_field_mi.material_override = mat
	add_child(_field_mi)


# ── Collision flash ImmediateMesh ────────────────────────────────────

func _setup_flash_mesh() -> void:
	_flash_im = ImmediateMesh.new()
	_flash_mi = MeshInstance3D.new()
	_flash_mi.mesh = _flash_im
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(1.0, 1.0, 0.8)
	mat.emission_energy_multiplier = 3.0
	_flash_mi.material_override = mat
	add_child(_flash_mi)


# ── Labels ───────────────────────────────────────────────────────────

func _setup_labels() -> void:
	_info_label = Label3D.new()
	_info_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_info_label.font_size = 24
	_info_label.outline_size = 4
	_info_label.modulate = Color(1.0, 0.95, 0.9)
	_info_label.position = Vector3(0, 0.58, 0)
	add_child(_info_label)

	_law_label = Label3D.new()
	_law_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_law_label.font_size = 18
	_law_label.outline_size = 3
	_law_label.modulate = Color(0.9, 0.7, 0.7)
	_law_label.position = Vector3(0, 0.50, 0)
	add_child(_law_label)


# ── VR controllers ───────────────────────────────────────────────────

func _setup_controllers() -> void:
	var y_pos := -_bounds - 0.18

	_strength_ctrl = ParameterController3D.new()
	_strength_ctrl.parameter_name = "Repel"
	_strength_ctrl.min_value = 0.5
	_strength_ctrl.max_value = 10.0
	_strength_ctrl.default_value = _repeller_strength
	_strength_ctrl.step_size = 0.1
	_strength_ctrl.position = Vector3(-0.3, y_pos, 0)
	_strength_ctrl.value_changed.connect(_on_strength_changed)
	add_child(_strength_ctrl)

	_rate_ctrl = ParameterController3D.new()
	_rate_ctrl.parameter_name = "Rate"
	_rate_ctrl.min_value = 2.0
	_rate_ctrl.max_value = 50.0
	_rate_ctrl.default_value = _emission_rate
	_rate_ctrl.step_size = 1.0
	_rate_ctrl.position = Vector3(-0.1, y_pos, 0)
	_rate_ctrl.value_changed.connect(_on_rate_changed)
	add_child(_rate_ctrl)

	# Force law selector: 0=inverse-square, 1=exponential, 2=polynomial
	_law_ctrl = ParameterController3D.new()
	_law_ctrl.parameter_name = "Law"
	_law_ctrl.min_value = 0.0
	_law_ctrl.max_value = 2.0
	_law_ctrl.default_value = 0.0
	_law_ctrl.step_size = 1.0
	_law_ctrl.position = Vector3(0.1, y_pos, 0)
	_law_ctrl.value_changed.connect(_on_law_changed)
	add_child(_law_ctrl)

	_collision_ctrl = ParameterController3D.new()
	_collision_ctrl.parameter_name = "Collide"
	_collision_ctrl.min_value = 0.0
	_collision_ctrl.max_value = 1.0
	_collision_ctrl.default_value = 1.0
	_collision_ctrl.step_size = 1.0
	_collision_ctrl.position = Vector3(0.3, y_pos, 0)
	_collision_ctrl.value_changed.connect(_on_collision_changed)
	add_child(_collision_ctrl)


# ── Controller callbacks ─────────────────────────────────────────────

func _on_strength_changed(val: float) -> void:
	_repeller_strength = val

func _on_rate_changed(val: float) -> void:
	_emission_rate = val

func _on_law_changed(val: float) -> void:
	_force_law = int(val)

func _on_collision_changed(val: float) -> void:
	_collision_enabled = val > 0.5


# ── Main loop ────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	_update_repeller_position(delta)
	_emit_particles(delta)
	_apply_forces(delta)
	if _collision_enabled:
		_resolve_collisions()
	_integrate_particles(delta)
	_remove_dead_particles()
	_update_multimesh()
	_draw_force_field()
	_draw_collision_flashes()
	_update_labels()



# ── Repeller position: VR hand or animated ───────────────────────────

func _update_repeller_position(_delta: float) -> void:
	# Try VR controller grip
	if _vr_controller:
		if _vr_controller.is_button_pressed("grip_click"):
			_hand_grip_active = true
			_repeller_pos = _vr_controller.global_position - global_position
		else:
			_hand_grip_active = false

	# Fallback: animated circular path
	if not _hand_grip_active:
		var t := Time.get_ticks_msec() / 1000.0
		_repeller_pos = Vector3(
			sin(t * 0.7) * 0.2,
			sin(t * 1.1) * 0.12,
			cos(t * 0.7) * 0.2
		)

	_repeller_mesh_inst.position = _repeller_pos

	# Pulse effect based on strength
	var pulse := 1.0 + sin(Time.get_ticks_msec() / 1000.0 * 4.0) * 0.1
	_repeller_mesh_inst.scale = Vector3.ONE * pulse

	# Glow intensity tracks strength
	var glow_t := clampf(_repeller_strength / 10.0, 0.0, 1.0)
	_repeller_mat.emission_energy_multiplier = 1.5 + 3.0 * glow_t
	if _hand_grip_active:
		_repeller_mat.emission = Color(1.0, 0.6, 0.2)
	else:
		_repeller_mat.emission = Color(1.0, 0.3, 0.3)


# ── Particle emission ───────────────────────────────────────────────

func _emit_particles(delta: float) -> void:
	_emission_timer += delta
	var interval := 1.0 / _emission_rate
	while _emission_timer >= interval and _positions.size() < _max_particles:
		_emission_timer -= interval
		_spawn_one_particle()


func _spawn_one_particle() -> void:
	var vel := Vector3(
		randf_range(-0.3, 0.3),
		randf_range(0.2, 0.6),
		randf_range(-0.3, 0.3)
	)
	_positions.append(_emitter_pos)
	_velocities.append(vel)
	var lifetime := _particle_lifetime * randf_range(0.8, 1.2)
	_lifespans.append(lifetime)
	_max_lifespans.append(lifetime)


# ── Force computation ────────────────────────────────────────────────

func _apply_forces(delta: float) -> void:
	for i in _positions.size():
		# Repeller force
		var dir := _positions[i] - _repeller_pos
		var dist := dir.length()
		if dist < 0.005:
			dir = Vector3(randf_range(-1, 1), 1, randf_range(-1, 1)).normalized()
			dist = 0.005
		else:
			dir = dir.normalized()

		var mag := _compute_force_magnitude(dist)
		_velocities[i] += dir * mag * delta

		# Gravity
		_velocities[i] += _gravity * delta

func _compute_force_magnitude(dist: float) -> float:
	var clamped := maxf(dist, 0.05)
	match _force_law:
		ForceLaw.INVERSE_SQUARE:
			# F = strength / r²
			return minf(_repeller_strength / (clamped * clamped), 20.0)
		ForceLaw.EXPONENTIAL:
			# F = strength * e^(-3r) — strong at close range, rapid falloff
			return minf(_repeller_strength * exp(-3.0 * clamped), 20.0)
		ForceLaw.POLYNOMIAL:
			# F = strength / r³ — sharper than inverse-square
			return minf(_repeller_strength / (clamped * clamped * clamped), 20.0)
	return 0.0


# ── Particle-particle collisions ────────────────────────────────────

func _resolve_collisions() -> void:
	_collision_flashes.clear()
	var count := _positions.size()
	var flash_count := 0

	for i in range(count):
		# Only check nearby pairs (skip if too many particles)
		var j_start := i + 1
		var j_end := mini(j_start + 30, count)  # limit per-particle checks
		for j in range(j_start, j_end):
			var diff := _positions[i] - _positions[j]
			var dist_sq := diff.length_squared()
			var min_dist := _collision_radius

			if dist_sq < min_dist * min_dist and dist_sq > 0.00001:
				var dist := sqrt(dist_sq)
				var normal := diff / dist

				# Separate particles
				var overlap := min_dist - dist
				_positions[i] += normal * overlap * 0.5
				_positions[j] -= normal * overlap * 0.5

				# Elastic collision response
				var rel_vel := _velocities[i] - _velocities[j]
				var vel_along_normal := rel_vel.dot(normal)

				if vel_along_normal > 0:
					continue  # Moving apart

				# Coefficient of restitution
				var impulse := vel_along_normal * 0.9
				_velocities[i] -= normal * impulse
				_velocities[j] += normal * impulse

				# Record flash
				if flash_count < MAX_FLASHES:
					var mid := (_positions[i] + _positions[j]) * 0.5
					_collision_flashes.append(mid)
					flash_count += 1


# ── Integration and bounds ───────────────────────────────────────────

func _integrate_particles(delta: float) -> void:
	_max_velocity = 0.001

	for i in _positions.size():
		_velocities[i] *= _damping
		_positions[i] += _velocities[i] * delta
		_lifespans[i] -= delta

		var speed := _velocities[i].length()
		if speed > _max_velocity:
			_max_velocity = speed

		# Bounce off bounds
		for axis in [0, 1, 2]:
			if _positions[i][axis] < -_bounds:
				_positions[i][axis] = -_bounds
				_velocities[i][axis] = absf(_velocities[i][axis]) * 0.6
			elif _positions[i][axis] > _bounds:
				_positions[i][axis] = _bounds
				_velocities[i][axis] = -absf(_velocities[i][axis]) * 0.6


# ── Remove dead particles ───────────────────────────────────────────

func _remove_dead_particles() -> void:
	var i := 0
	while i < _positions.size():
		if _lifespans[i] <= 0.0:
			# Swap with last
			var last := _positions.size() - 1
			_positions[i] = _positions[last]
			_velocities[i] = _velocities[last]
			_lifespans[i] = _lifespans[last]
			_max_lifespans[i] = _max_lifespans[last]
			_positions.pop_back()
			_velocities.pop_back()
			_lifespans.pop_back()
			_max_lifespans.pop_back()
		else:
			i += 1


# ── MultiMesh update ────────────────────────────────────────────────

func _update_multimesh() -> void:
	var mm := _mm_inst.multimesh
	var count := _positions.size()
	mm.visible_instance_count = count

	for i in count:
		mm.set_instance_transform(i, Transform3D(Basis(), _positions[i]))

		# Velocity → heatmap color
		var speed := _velocities[i].length()
		var color := _velocity_heatmap(speed, _lifespans[i] / _max_lifespans[i])
		mm.set_instance_color(i, color)


# ── Velocity → heatmap color (blue → cyan → yellow → red) ───────────

func _velocity_heatmap(speed: float, life_t: float) -> Color:
	var t := clampf(speed / maxf(_max_velocity, 0.001), 0.0, 1.0)
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

	var alpha := 0.3 + 0.7 * life_t
	return Color(r, g, b, alpha)


# ── Force field visualization ────────────────────────────────────────

func _draw_force_field() -> void:
	_field_im.clear_surfaces()
	_field_im.surface_begin(Mesh.PRIMITIVE_LINES)

	# Repeller boundary ring (horizontal)
	var segments := 32
	var base_color := Color(1.0, 0.35, 0.35, 0.5)
	if _hand_grip_active:
		base_color = Color(1.0, 0.6, 0.2, 0.6)

	_draw_ring(_repeller_pos, _repeller_radius, segments, base_color)

	# Inner ring
	_draw_ring(_repeller_pos, _repeller_radius * 0.5, segments, Color(base_color.r, base_color.g, base_color.b, 0.25))

	# Outward radial ticks showing force direction
	for j in range(12):
		var angle := float(j) / 12.0 * TAU
		var inner := _repeller_pos + Vector3(cos(angle), 0, sin(angle)) * _repeller_radius * 0.6
		var outer := _repeller_pos + Vector3(cos(angle), 0, sin(angle)) * _repeller_radius * 1.1
		_field_im.surface_set_color(base_color)
		_field_im.surface_add_vertex(inner)
		_field_im.surface_set_color(Color(base_color.r, base_color.g, base_color.b, 0.15))
		_field_im.surface_add_vertex(outer)

	# Force law indicator: draw sample force profile as radial lines
	var profile_color := Color(1.0, 0.8, 0.4, 0.3)
	for j in range(8):
		var angle := float(j) / 8.0 * TAU
		var dir := Vector3(cos(angle), 0, sin(angle))
		# Draw force magnitude at several distances
		var prev_pt := _repeller_pos + dir * 0.05
		for k in range(1, 6):
			var dist := 0.05 + float(k) * 0.06
			var mag := _compute_force_magnitude(dist)
			var height := clampf(mag * 0.01, 0.0, 0.08)
			var pt := _repeller_pos + dir * dist + Vector3.UP * height
			_field_im.surface_set_color(profile_color)
			_field_im.surface_add_vertex(prev_pt)
			_field_im.surface_set_color(profile_color)
			_field_im.surface_add_vertex(pt)
			prev_pt = pt

	_field_im.surface_end()


func _draw_ring(center: Vector3, radius: float, segs: int, color: Color) -> void:
	for i in range(segs):
		var a0 := float(i) / float(segs) * TAU
		var a1 := float(i + 1) / float(segs) * TAU
		_field_im.surface_set_color(color)
		_field_im.surface_add_vertex(center + Vector3(cos(a0) * radius, 0, sin(a0) * radius))
		_field_im.surface_set_color(color)
		_field_im.surface_add_vertex(center + Vector3(cos(a1) * radius, 0, sin(a1) * radius))


# ── Collision flash rendering ────────────────────────────────────────

func _draw_collision_flashes() -> void:
	_flash_im.clear_surfaces()
	if _collision_flashes.is_empty():
		return

	_flash_im.surface_begin(Mesh.PRIMITIVE_LINES)
	for pt in _collision_flashes:
		# Small cross at collision point
		var sz := 0.015
		var color := Color(1.0, 1.0, 0.6, 0.8)
		_flash_im.surface_set_color(color)
		_flash_im.surface_add_vertex(pt + Vector3(-sz, 0, 0))
		_flash_im.surface_set_color(color)
		_flash_im.surface_add_vertex(pt + Vector3(sz, 0, 0))
		_flash_im.surface_set_color(color)
		_flash_im.surface_add_vertex(pt + Vector3(0, -sz, 0))
		_flash_im.surface_set_color(color)
		_flash_im.surface_add_vertex(pt + Vector3(0, sz, 0))
		_flash_im.surface_set_color(color)
		_flash_im.surface_add_vertex(pt + Vector3(0, 0, -sz))
		_flash_im.surface_set_color(color)
		_flash_im.surface_add_vertex(pt + Vector3(0, 0, sz))
	_flash_im.surface_end()


# ── Labels ───────────────────────────────────────────────────────────

func _update_labels() -> void:
	if _info_label:
		var hand_str := " [VR Hand]" if _hand_grip_active else ""
		_info_label.text = "Particle Repeller%s\n%d particles | Strength: %.1f" % [
			hand_str, _positions.size(), _repeller_strength
		]

	if _law_label:
		var law_name: String = FORCE_LAW_NAMES[_force_law] if _force_law < FORCE_LAW_NAMES.size() else "?"
		var col_str := "ON" if _collision_enabled else "OFF"
		_law_label.text = "Force Law: %s | Collisions: %s" % [law_name, col_str]


# ── Input ────────────────────────────────────────────────────────────

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			# Burst emission
			for i in range(30):
				_spawn_one_particle()
		elif event.keycode == KEY_R:
			_positions.clear()
			_velocities.clear()
			_lifespans.clear()
			_max_lifespans.clear()
		elif event.keycode == KEY_F:
			_force_law = (_force_law + 1) % 3
			if _law_ctrl:
				_law_ctrl.set_value(float(_force_law))
		elif event.keycode == KEY_C:
			_collision_enabled = not _collision_enabled
			if _collision_ctrl:
				_collision_ctrl.set_value(1.0 if _collision_enabled else 0.0)


# ── Cleanup ──────────────────────────────────────────────────────────

func _exit_tree() -> void:
	if _field_im:
		_field_im.clear_surfaces()
	if _flash_im:
		_flash_im.clear_surfaces()


# ── Grid config ──────────────────────────────────────────────────────

func apply_grid_config(config: Dictionary) -> void:
	if config.has("repel_strength"):
		_repeller_strength = clampf(float(config.repel_strength), 0.5, 10.0)
		_on_strength_changed(_repeller_strength)
		if _strength_ctrl:
			_strength_ctrl.set_value(_repeller_strength)

	if config.has("emission_rate"):
		_emission_rate = clampf(float(config.emission_rate), 2.0, 50.0)
		_on_rate_changed(_emission_rate)
		if _rate_ctrl:
			_rate_ctrl.set_value(_emission_rate)

	if config.has("force_law"):
		_force_law = clampi(int(config.force_law), 0, 2)
		_on_law_changed(float(_force_law))
		if _law_ctrl:
			_law_ctrl.set_value(float(_force_law))

	if config.has("collisions"):
		_collision_enabled = bool(config.collisions)
		if _collision_ctrl:
			_collision_ctrl.set_value(1.0 if _collision_enabled else 0.0)

	# Clear and re-seed
	_positions.clear()
	_velocities.clear()
	_lifespans.clear()
	_max_lifespans.clear()
