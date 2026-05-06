# ===========================================================================
# NOC Example 5.9: Flocking — Neighborhood Viz & Predator/Prey
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# Elevated: neighborhood radius visualization per agent, predictive avoidance
# via velocity-projected future positions, predator/prey dynamics with role
# coloring, ImmediateMesh connection lines, MultiMesh boid rendering,
# VR sliders for live parameter exploration.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D

## Example 5.9: Flocking — Neighborhood & Predator/Prey
## Boids with visible influence radii, velocity-based avoidance, and chase/flee roles
## Chapter 05: Autonomous Agents


# ── Constants ──────────────────────────────────────────────────────────
const CONTROLLER_SCENE := preload("res://spatial_ui/parameter_controller_3d.tscn")

# ── Tunable parameters ────────────────────────────────────────────────
var num_boids: int = 40
var num_predators: int = 3
var alignment_weight: float = 1.0
var cohesion_weight: float = 1.0
var separation_weight: float = 1.5
var neighbor_radius: float = 0.15
var separation_radius: float = 0.06
var predator_speed_mult: float = 1.15
var prey_speed_mult: float = 1.0
var avoidance_lookahead: float = 0.3   # seconds of velocity projection
var show_neighborhoods: bool = true

# ── Boid state arrays ─────────────────────────────────────────────────
enum Role { PREY, PREDATOR }
var _positions: Array[Vector3] = []
var _velocities: Array[Vector3] = []
var _accelerations: Array[Vector3] = []
var _roles: Array[int] = []         # Role enum
var _max_speeds: Array[float] = []
var _max_forces: Array[float] = []
var _neighbor_counts: Array[int] = []

# ── Visual nodes ─────────────────────────────────────────────────────
var _boid_mm: MultiMesh
var _boid_mmi: MultiMeshInstance3D

# Neighborhood rings + connections
var _hood_im: ImmediateMesh
var _hood_mi: MeshInstance3D

# Velocity vectors + avoidance lines
var _vel_im: ImmediateMesh
var _vel_mi: MeshInstance3D

# Predator chase/prey flee lines
var _chase_im: ImmediateMesh
var _chase_mi: MeshInstance3D

# Info label
var _info_label: Label3D

# VR controllers
var _sep_ctrl: Node3D
var _predator_ctrl: Node3D
var _radius_ctrl: Node3D
var _speed_ctrl: Node3D

# ── Bounds ───────────────────────────────────────────────────────────
var _bounds_x := 0.45
var _bounds_y_lo := 0.05
var _bounds_y_hi := 0.95
var _bounds_z := 0.35

# ── Colors ───────────────────────────────────────────────────────────
var _prey_color := Color(0.3, 0.85, 0.95)     # cyan
var _predator_color := Color(1.0, 0.35, 0.2)  # red-orange
var _flee_color := Color(0.95, 0.9, 0.3)      # yellow flash when fleeing
var _hunt_color := Color(1.0, 0.15, 0.05)     # deep red when hunting


func _ready() -> void:
	_init_boids()
	_setup_multimesh()
	_setup_hood_mesh()
	_setup_vel_mesh()
	_setup_chase_mesh()
	_setup_labels()
	_setup_controllers()


# ── Boid initialization ──────────────────────────────────────────────

func _init_boids() -> void:
	var total := num_boids + num_predators
	_positions.resize(total)
	_velocities.resize(total)
	_accelerations.resize(total)
	_roles.resize(total)
	_max_speeds.resize(total)
	_max_forces.resize(total)
	_neighbor_counts.resize(total)

	for i in total:
		_positions[i] = Vector3(
			randf_range(-_bounds_x, _bounds_x),
			randf_range(_bounds_y_lo + 0.1, _bounds_y_hi - 0.1),
			randf_range(-_bounds_z, _bounds_z)
		)
		_velocities[i] = Vector3(
			randf_range(-0.1, 0.1),
			randf_range(-0.1, 0.1),
			randf_range(-0.05, 0.05)
		)
		_accelerations[i] = Vector3.ZERO
		_neighbor_counts[i] = 0

		if i < num_boids:
			_roles[i] = Role.PREY
			_max_speeds[i] = 0.25 * prey_speed_mult
			_max_forces[i] = 0.04
		else:
			_roles[i] = Role.PREDATOR
			_max_speeds[i] = 0.25 * predator_speed_mult
			_max_forces[i] = 0.06


# ── MultiMesh for boid bodies ────────────────────────────────────────

func _setup_multimesh() -> void:
	_boid_mm = MultiMesh.new()
	_boid_mm.transform_format = MultiMesh.TRANSFORM_3D
	_boid_mm.use_colors = true
	_boid_mm.instance_count = _positions.size()

	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.02
	cone.height = 0.06
	cone.radial_segments = 6
	_boid_mm.mesh = cone

	_boid_mmi = MultiMeshInstance3D.new()
	_boid_mmi.multimesh = _boid_mm
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission = Color(0.5, 0.5, 0.5)
	mat.emission_energy_multiplier = 1.5
	_boid_mmi.material_override = mat
	add_child(_boid_mmi)


# ── ImmediateMesh setups ─────────────────────────────────────────────

func _create_im_pair(alpha_transparent: bool = true) -> Array:
	var im := ImmediateMesh.new()
	var mi := MeshInstance3D.new()
	mi.mesh = im
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	if alpha_transparent:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mi.material_override = mat
	add_child(mi)
	return [im, mi]


func _setup_hood_mesh() -> void:
	var pair := _create_im_pair()
	_hood_im = pair[0]
	_hood_mi = pair[1]


func _setup_vel_mesh() -> void:
	var pair := _create_im_pair()
	_vel_im = pair[0]
	_vel_mi = pair[1]


func _setup_chase_mesh() -> void:
	var pair := _create_im_pair()
	_chase_im = pair[0]
	_chase_mi = pair[1]


# ── Labels ───────────────────────────────────────────────────────────

func _setup_labels() -> void:
	_info_label = Label3D.new()
	_info_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_info_label.font_size = 22
	_info_label.outline_size = 4
	_info_label.modulate = Color(1.0, 0.85, 1.0)
	_info_label.position = Vector3(0, 1.0, 0)
	add_child(_info_label)


# ── VR controllers ───────────────────────────────────────────────────

func _setup_controllers() -> void:
	var y_pos := -0.6

	_sep_ctrl = CONTROLLER_SCENE.instantiate()
	_sep_ctrl.parameter_name = "Separation"
	_sep_ctrl.min_value = 0.0
	_sep_ctrl.max_value = 4.0
	_sep_ctrl.default_value = separation_weight
	_sep_ctrl.step_size = 0.1
	_sep_ctrl.position = Vector3(-0.3, y_pos, 0)
	_sep_ctrl.value_changed.connect(func(v: float) -> void: separation_weight = v)
	add_child(_sep_ctrl)

	_predator_ctrl = CONTROLLER_SCENE.instantiate()
	_predator_ctrl.parameter_name = "Predators"
	_predator_ctrl.min_value = 0.0
	_predator_ctrl.max_value = 8.0
	_predator_ctrl.default_value = float(num_predators)
	_predator_ctrl.step_size = 1.0
	_predator_ctrl.position = Vector3(-0.1, y_pos, 0)
	_predator_ctrl.value_changed.connect(func(v: float) -> void: _adjust_predator_count(int(v)))
	add_child(_predator_ctrl)

	_radius_ctrl = CONTROLLER_SCENE.instantiate()
	_radius_ctrl.parameter_name = "Neighborhood"
	_radius_ctrl.min_value = 0.05
	_radius_ctrl.max_value = 0.35
	_radius_ctrl.default_value = neighbor_radius
	_radius_ctrl.step_size = 0.01
	_radius_ctrl.position = Vector3(0.1, y_pos, 0)
	_radius_ctrl.value_changed.connect(func(v: float) -> void:
		neighbor_radius = v
		separation_radius = v * 0.4
	)
	add_child(_radius_ctrl)

	_speed_ctrl = CONTROLLER_SCENE.instantiate()
	_speed_ctrl.parameter_name = "Pred Speed"
	_speed_ctrl.min_value = 0.8
	_speed_ctrl.max_value = 1.6
	_speed_ctrl.default_value = predator_speed_mult
	_speed_ctrl.step_size = 0.05
	_speed_ctrl.position = Vector3(0.3, y_pos, 0)
	_speed_ctrl.value_changed.connect(func(v: float) -> void:
		predator_speed_mult = v
		_update_speeds()
	)
	add_child(_speed_ctrl)


# ── Main loop ────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	var total := _positions.size()
	if total == 0:
		return

	# Reset neighbor counts
	for i in total:
		_neighbor_counts[i] = 0

	# Compute steering forces
	for i in total:
		if _roles[i] == Role.PREY:
			_flock_prey(i)
		else:
			_flock_predator(i)

	# Integrate
	for i in total:
		_velocities[i] += _accelerations[i]
		_velocities[i] = _velocities[i].limit_length(_max_speeds[i])
		_positions[i] += _velocities[i] * delta * 60.0
		_accelerations[i] = Vector3.ZERO
		_wrap_bounds(i)

	# Update visuals
	_update_multimesh()
	_draw_neighborhoods()
	_draw_velocity_vectors()
	_draw_chase_lines()
	_update_label()


# ── Prey flocking (classic boids + flee from predators) ──────────────

func _flock_prey(idx: int) -> void:
	var pos := _positions[idx]
	var vel := _velocities[idx]
	var total := _positions.size()

	var sep_sum := Vector3.ZERO
	var sep_count := 0
	var ali_sum := Vector3.ZERO
	var ali_count := 0
	var coh_sum := Vector3.ZERO
	var coh_count := 0

	# Flee from predators
	var flee_sum := Vector3.ZERO
	var flee_count := 0

	for j in total:
		if j == idx:
			continue
		var d := pos.distance_to(_positions[j])

		if _roles[j] == Role.PREDATOR:
			# Flee radius is larger than neighbor radius
			var flee_radius := neighbor_radius * 2.0
			if d > 0 and d < flee_radius:
				# Predictive avoidance: project predator future position
				var future_pred := _positions[j] + _velocities[j] * avoidance_lookahead * 60.0
				var future_self := pos + vel * avoidance_lookahead * 60.0
				var future_d := future_self.distance_to(future_pred)
				if future_d < flee_radius:
					var diff := (pos - future_pred).normalized() / maxf(d, 0.01)
					flee_sum += diff
					flee_count += 1
		else:
			# Normal flocking with same-role neighbors
			if d > 0 and d < separation_radius:
				var diff := (pos - _positions[j]).normalized() / maxf(d, 0.01)
				sep_sum += diff
				sep_count += 1

			if d > 0 and d < neighbor_radius:
				ali_sum += _velocities[j]
				coh_sum += _positions[j]
				ali_count += 1
				coh_count += 1
				_neighbor_counts[idx] += 1

	# Separation
	if sep_count > 0:
		sep_sum = (sep_sum / float(sep_count)).normalized() * _max_speeds[idx]
		sep_sum = (sep_sum - vel).limit_length(_max_forces[idx])
		_accelerations[idx] += sep_sum * separation_weight

	# Alignment
	if ali_count > 0:
		ali_sum = (ali_sum / float(ali_count)).normalized() * _max_speeds[idx]
		ali_sum = (ali_sum - vel).limit_length(_max_forces[idx])
		_accelerations[idx] += ali_sum * alignment_weight

	# Cohesion
	if coh_count > 0:
		var target := coh_sum / float(coh_count)
		var desired := (target - pos).normalized() * _max_speeds[idx]
		var steer := (desired - vel).limit_length(_max_forces[idx])
		_accelerations[idx] += steer * cohesion_weight

	# Flee
	if flee_count > 0:
		flee_sum = (flee_sum / float(flee_count)).normalized() * _max_speeds[idx]
		flee_sum = (flee_sum - vel).limit_length(_max_forces[idx] * 2.0)
		_accelerations[idx] += flee_sum * 2.5


# ── Predator steering (chase nearest prey + avoid other predators) ───

func _flock_predator(idx: int) -> void:
	var pos := _positions[idx]
	var vel := _velocities[idx]
	var total := _positions.size()

	# Find nearest prey using predictive interception
	var nearest_prey := -1
	var nearest_d := INF
	for j in total:
		if _roles[j] != Role.PREY:
			continue
		# Predict where prey will be
		var future_prey := _positions[j] + _velocities[j] * avoidance_lookahead * 60.0
		var d := pos.distance_to(future_prey)
		if d < nearest_d:
			nearest_d = d
			nearest_prey = j

	# Chase nearest prey
	if nearest_prey >= 0:
		var target := _positions[nearest_prey] + _velocities[nearest_prey] * avoidance_lookahead * 30.0
		var desired := (target - pos).normalized() * _max_speeds[idx]
		var steer := (desired - vel).limit_length(_max_forces[idx])
		_accelerations[idx] += steer * 1.5
		_neighbor_counts[idx] = 1  # show as "tracking"

	# Separate from other predators
	var sep_sum := Vector3.ZERO
	var sep_count := 0
	for j in total:
		if j == idx or _roles[j] != Role.PREDATOR:
			continue
		var d := pos.distance_to(_positions[j])
		if d > 0 and d < separation_radius * 2.0:
			var diff := (pos - _positions[j]).normalized() / maxf(d, 0.01)
			sep_sum += diff
			sep_count += 1

	if sep_count > 0:
		sep_sum = (sep_sum / float(sep_count)).normalized() * _max_speeds[idx]
		sep_sum = (sep_sum - vel).limit_length(_max_forces[idx])
		_accelerations[idx] += sep_sum * 1.5


# ── Bounds wrapping ──────────────────────────────────────────────────

func _wrap_bounds(idx: int) -> void:
	var p := _positions[idx]
	if p.x < -_bounds_x:
		p.x = _bounds_x
	elif p.x > _bounds_x:
		p.x = -_bounds_x
	if p.y < _bounds_y_lo:
		p.y = _bounds_y_hi
	elif p.y > _bounds_y_hi:
		p.y = _bounds_y_lo
	if p.z < -_bounds_z:
		p.z = _bounds_z
	elif p.z > _bounds_z:
		p.z = -_bounds_z
	_positions[idx] = p


# ── MultiMesh update ─────────────────────────────────────────────────

func _update_multimesh() -> void:
	var total := _positions.size()
	if _boid_mm.instance_count != total:
		_boid_mm.instance_count = total

	for i in total:
		var pos := _positions[i]
		var vel := _velocities[i]

		# Orient cone to face velocity direction
		var t := Transform3D()
		t.origin = pos
		if vel.length() > 0.001:
			var dir := vel.normalized()
			var up := Vector3.UP
			if absf(dir.dot(up)) > 0.99:
				up = Vector3.FORWARD
			t = t.looking_at(pos + dir, up)
			t.basis = t.basis * Basis(Vector3.RIGHT, -PI / 2.0)
		_boid_mm.set_instance_transform(i, t)

		# Color by role and state
		var color: Color
		if _roles[i] == Role.PREDATOR:
			# Pulse red based on speed (hunting intensity)
			var speed_t := clampf(vel.length() / _max_speeds[i], 0, 1)
			color = _predator_color.lerp(_hunt_color, speed_t * 0.5)
			color.a = 1.0
		else:
			# Prey: cyan when calm, yellow flash when fleeing fast
			var speed_t := clampf(vel.length() / _max_speeds[i], 0, 1)
			color = _prey_color.lerp(_flee_color, speed_t * 0.4)
			# Brighten slightly based on neighbor count
			var hood_t := clampf(float(_neighbor_counts[i]) / 6.0, 0, 1)
			color = color.lerp(Color(0.6, 1.0, 0.8), hood_t * 0.2)
			color.a = 1.0
		_boid_mm.set_instance_color(i, color)


# ── Neighborhood ring visualization ──────────────────────────────────

func _draw_neighborhoods() -> void:
	_hood_im.clear_surfaces()
	if not show_neighborhoods:
		return

	var total := _positions.size()
	_hood_im.surface_begin(Mesh.PRIMITIVE_LINES)

	var ring_segments := 16
	for i in total:
		# Only draw rings for prey (predators have different viz)
		if _roles[i] != Role.PREY:
			continue
		# Only draw if boid has neighbors (to avoid visual clutter)
		if _neighbor_counts[i] == 0:
			continue

		var pos := _positions[i]
		var hood_t := clampf(float(_neighbor_counts[i]) / 6.0, 0, 1)
		var alpha := 0.08 + 0.15 * hood_t
		var ring_color := Color(0.3, 0.8, 0.9, alpha)

		# Draw ring in XY plane around boid
		for s in ring_segments:
			var a0 := float(s) / float(ring_segments) * TAU
			var a1 := float(s + 1) / float(ring_segments) * TAU
			var p0 := pos + Vector3(cos(a0) * neighbor_radius, sin(a0) * neighbor_radius, 0)
			var p1 := pos + Vector3(cos(a1) * neighbor_radius, sin(a1) * neighbor_radius, 0)
			_hood_im.surface_set_color(ring_color)
			_hood_im.surface_add_vertex(p0)
			_hood_im.surface_set_color(ring_color)
			_hood_im.surface_add_vertex(p1)

		# Draw connection lines to neighbors
		for j in total:
			if j <= i or _roles[j] != Role.PREY:
				continue
			var d := pos.distance_to(_positions[j])
			if d > 0 and d < neighbor_radius:
				var conn_alpha := (1.0 - d / neighbor_radius) * 0.2
				var conn_color := Color(0.4, 0.9, 1.0, conn_alpha)
				_hood_im.surface_set_color(conn_color)
				_hood_im.surface_add_vertex(pos)
				_hood_im.surface_set_color(conn_color)
				_hood_im.surface_add_vertex(_positions[j])

	_hood_im.surface_end()


# ── Velocity vector visualization ────────────────────────────────────

func _draw_velocity_vectors() -> void:
	_vel_im.clear_surfaces()
	var total := _positions.size()
	_vel_im.surface_begin(Mesh.PRIMITIVE_LINES)

	for i in total:
		var pos := _positions[i]
		var vel := _velocities[i]
		if vel.length() < 0.001:
			continue

		# Short velocity arrow
		var tip := pos + vel.normalized() * 0.05
		var color: Color
		if _roles[i] == Role.PREDATOR:
			color = Color(1.0, 0.4, 0.2, 0.5)
		else:
			color = Color(0.3, 0.8, 0.9, 0.35)

		_vel_im.surface_set_color(color)
		_vel_im.surface_add_vertex(pos)
		_vel_im.surface_set_color(color)
		_vel_im.surface_add_vertex(tip)

		# Predictive avoidance projection (faint dotted look — just longer line)
		if _roles[i] == Role.PREY:
			var future_pos := pos + vel * avoidance_lookahead * 60.0
			var proj_color := Color(0.5, 0.9, 1.0, 0.1)
			_vel_im.surface_set_color(proj_color)
			_vel_im.surface_add_vertex(tip)
			_vel_im.surface_set_color(Color(0.5, 0.9, 1.0, 0.02))
			_vel_im.surface_add_vertex(future_pos)

	_vel_im.surface_end()


# ── Predator chase lines ─────────────────────────────────────────────

func _draw_chase_lines() -> void:
	_chase_im.clear_surfaces()
	var total := _positions.size()
	_chase_im.surface_begin(Mesh.PRIMITIVE_LINES)

	for i in total:
		if _roles[i] != Role.PREDATOR:
			continue

		var pos := _positions[i]
		var nearest_prey := -1
		var nearest_d := INF

		for j in total:
			if _roles[j] != Role.PREY:
				continue
			var d := pos.distance_to(_positions[j])
			if d < nearest_d:
				nearest_d = d
				nearest_prey = j

		if nearest_prey >= 0 and nearest_d < neighbor_radius * 3.0:
			# Chase line: red fading with distance
			var alpha := (1.0 - nearest_d / (neighbor_radius * 3.0)) * 0.4
			var chase_color := Color(1.0, 0.2, 0.1, alpha)
			_chase_im.surface_set_color(chase_color)
			_chase_im.surface_add_vertex(pos)
			_chase_im.surface_set_color(Color(1.0, 0.2, 0.1, alpha * 0.3))
			_chase_im.surface_add_vertex(_positions[nearest_prey])

			# Danger ring around targeted prey
			var prey_pos := _positions[nearest_prey]
			var danger_color := Color(1.0, 0.3, 0.15, alpha * 0.5)
			var segs := 12
			var r := 0.03
			for s in segs:
				var a0 := float(s) / float(segs) * TAU
				var a1 := float(s + 1) / float(segs) * TAU
				_chase_im.surface_set_color(danger_color)
				_chase_im.surface_add_vertex(prey_pos + Vector3(cos(a0) * r, sin(a0) * r, 0))
				_chase_im.surface_set_color(danger_color)
				_chase_im.surface_add_vertex(prey_pos + Vector3(cos(a1) * r, sin(a1) * r, 0))

	_chase_im.surface_end()


# ── Info label ───────────────────────────────────────────────────────

func _update_label() -> void:
	var prey_count := 0
	var pred_count := 0
	for r in _roles:
		if r == Role.PREY:
			prey_count += 1
		else:
			pred_count += 1
	_info_label.text = "Flocking | %d prey  %d predators | radius %.2f" % [
		prey_count, pred_count, neighbor_radius
	]


# ── Predator count adjustment ────────────────────────────────────────

func _adjust_predator_count(new_count: int) -> void:
	new_count = clampi(new_count, 0, 8)
	var current_pred := 0
	for r in _roles:
		if r == Role.PREDATOR:
			current_pred += 1

	if new_count == current_pred:
		return

	if new_count > current_pred:
		# Add predators
		var to_add := new_count - current_pred
		for _k in to_add:
			_positions.append(Vector3(
				randf_range(-_bounds_x, _bounds_x),
				randf_range(_bounds_y_lo + 0.1, _bounds_y_hi - 0.1),
				randf_range(-_bounds_z, _bounds_z)
			))
			_velocities.append(Vector3(randf_range(-0.1, 0.1), randf_range(-0.1, 0.1), randf_range(-0.05, 0.05)))
			_accelerations.append(Vector3.ZERO)
			_roles.append(Role.PREDATOR)
			_max_speeds.append(0.25 * predator_speed_mult)
			_max_forces.append(0.06)
			_neighbor_counts.append(0)
	else:
		# Remove predators from end
		var to_remove := current_pred - new_count
		var removed := 0
		for i in range(_positions.size() - 1, -1, -1):
			if removed >= to_remove:
				break
			if _roles[i] == Role.PREDATOR:
				_positions.remove_at(i)
				_velocities.remove_at(i)
				_accelerations.remove_at(i)
				_roles.remove_at(i)
				_max_speeds.remove_at(i)
				_max_forces.remove_at(i)
				_neighbor_counts.remove_at(i)
				removed += 1

	num_predators = new_count
	_boid_mm.instance_count = _positions.size()


func _update_speeds() -> void:
	for i in _positions.size():
		if _roles[i] == Role.PREDATOR:
			_max_speeds[i] = 0.25 * predator_speed_mult
		else:
			_max_speeds[i] = 0.25 * prey_speed_mult


# ── Input ────────────────────────────────────────────────────────────

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_N:
			show_neighborhoods = not show_neighborhoods
		elif event.keycode == KEY_R:
			_reset_all()


func _reset_all() -> void:
	_positions.clear()
	_velocities.clear()
	_accelerations.clear()
	_roles.clear()
	_max_speeds.clear()
	_max_forces.clear()
	_neighbor_counts.clear()
	_init_boids()
	_boid_mm.instance_count = _positions.size()


# ── Cleanup ──────────────────────────────────────────────────────────

func _exit_tree() -> void:
	if _hood_im:
		_hood_im.clear_surfaces()
	if _vel_im:
		_vel_im.clear_surfaces()
	if _chase_im:
		_chase_im.clear_surfaces()


# ── Grid config ──────────────────────────────────────────────────────

func apply_grid_config(config: Dictionary) -> void:
	if config.has("num_boids"):
		num_boids = clampi(int(config.num_boids), 5, 80)

	if config.has("num_predators"):
		num_predators = clampi(int(config.num_predators), 0, 8)

	if config.has("alignment_weight"):
		alignment_weight = clampf(float(config.alignment_weight), 0.0, 4.0)

	if config.has("cohesion_weight"):
		cohesion_weight = clampf(float(config.cohesion_weight), 0.0, 4.0)

	if config.has("separation_weight"):
		separation_weight = clampf(float(config.separation_weight), 0.0, 4.0)
		if _sep_ctrl:
			_sep_ctrl.set_value(separation_weight)

	if config.has("neighbor_radius"):
		neighbor_radius = clampf(float(config.neighbor_radius), 0.05, 0.35)
		separation_radius = neighbor_radius * 0.4
		if _radius_ctrl:
			_radius_ctrl.set_value(neighbor_radius)

	if config.has("predator_speed"):
		predator_speed_mult = clampf(float(config.predator_speed), 0.8, 1.6)
		if _speed_ctrl:
			_speed_ctrl.set_value(predator_speed_mult)

	if config.has("avoidance_lookahead"):
		avoidance_lookahead = clampf(float(config.avoidance_lookahead), 0.1, 1.0)

	if config.has("show_neighborhoods"):
		show_neighborhoods = bool(config.show_neighborhoods)

	_reset_all()
