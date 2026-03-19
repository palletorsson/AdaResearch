extends Node3D

# @identity
# essence: x(t+dt) = 2x(t) - x(t-dt) + a(t)*dt². No velocity. Positions remember.
# desire: To show that forgetting velocity makes physics better. To make the learner SEE energy conservation.
# critical_parameter: dt — at small dt, Euler and Verlet look the same. At large dt, Euler escapes, Verlet stays.
# triggers: dt ramp → Euler spirals outward while Verlet precesses, ghost line → shows the position-differencing trick
# emerges: Energy conservation from symplecticity. Stability from time-reversibility. Orbits from F=ma without velocity.
# needs: Manual dt VR slider [missing — auto-ramp only]. Side-by-side comparison [has]. Energy readouts [has].
# relationships: Depends on newtons_laws (F=ma is the input). Unlocks cloth_simulation (Verlet holds cloth together). Contrasts with numerical_integration (three methods compared).
# truth: The most stable integration method is the one that forgot to track the thing everyone assumed was essential.

## Verlet Integration — the algorithm made visible.
##
## Two particles orbit a central attractor under identical forces.
## Left: Euler integration (x += v*dt, v += a*dt) — energy drifts, orbit spirals.
## Right: Verlet integration (x_new = 2x - x_prev + a*dt²) — no velocity, energy bounded.
##
## The learner sees:
## - Euler's orbit spiraling outward (energy gain) or inward (energy loss)
## - Verlet's orbit staying bounded, precessing but never escaping
## - The position-history trick: two dots (current, previous) compute the next
## - A dt slider that shows Verlet degrading gracefully while Euler explodes
##
## x(t+dt) = 2x(t) - x(t-dt) + a(t)·dt²

const TRAIL_LENGTH := 300
const ATTRACTOR_STRENGTH := 50.0
const INITIAL_SPEED := 4.5
const INITIAL_RADIUS := 3.0
const SEPARATION := 8.0  # distance between the two demos

var _dt := 0.02
var _time := 0.0

# Euler state
var _euler_pos := Vector3.ZERO
var _euler_vel := Vector3.ZERO
var _euler_trail: Array[Vector3] = []
var _euler_energy_initial := 0.0

# Verlet state
var _verlet_pos := Vector3.ZERO
var _verlet_prev := Vector3.ZERO
var _verlet_trail: Array[Vector3] = []
var _verlet_energy_initial := 0.0

# Rendering
var _euler_sphere: MeshInstance3D
var _verlet_sphere: MeshInstance3D
var _verlet_prev_sphere: MeshInstance3D
var _attractor_left: MeshInstance3D
var _attractor_right: MeshInstance3D
var _euler_trail_mesh: ImmediateMesh
var _euler_trail_instance: MeshInstance3D
var _verlet_trail_mesh: ImmediateMesh
var _verlet_trail_instance: MeshInstance3D
var _ghost_line_mesh: ImmediateMesh
var _ghost_line_instance: MeshInstance3D

# Labels
var _label_euler_energy: Label3D
var _label_verlet_energy: Label3D
var _label_dt: Label3D
var _label_equation: Label3D

# dt slider ramp
var _auto_ramp := true
var _ramp_phase := 0  # 0=stable, 1=ramping, 2=exploded, 3=reset


func _ready() -> void:
	_setup_particles()
	_setup_attractors()
	_setup_trails()
	_setup_ghost_line()
	_setup_labels()
	_reset_simulation()


func _setup_particles() -> void:
	# Euler particle (red)
	_euler_sphere = _make_sphere(0.15, Color(1.0, 0.3, 0.2))
	_euler_sphere.name = "EulerParticle"
	add_child(_euler_sphere)

	# Verlet particle (blue) — current position
	_verlet_sphere = _make_sphere(0.15, Color(0.2, 0.5, 1.0))
	_verlet_sphere.name = "VerletParticle"
	add_child(_verlet_sphere)

	# Verlet previous position (ghost, dimmer)
	_verlet_prev_sphere = _make_sphere(0.10, Color(0.2, 0.5, 1.0, 0.3))
	_verlet_prev_sphere.name = "VerletPrevious"
	add_child(_verlet_prev_sphere)


func _setup_attractors() -> void:
	# Left attractor (for Euler)
	_attractor_left = _make_sphere(0.3, Color(1.0, 0.9, 0.3))
	_attractor_left.position = Vector3(-SEPARATION * 0.5, 2.0, 0.0)
	add_child(_attractor_left)

	# Right attractor (for Verlet)
	_attractor_right = _make_sphere(0.3, Color(1.0, 0.9, 0.3))
	_attractor_right.position = Vector3(SEPARATION * 0.5, 2.0, 0.0)
	add_child(_attractor_right)


func _setup_trails() -> void:
	# Euler trail (red)
	_euler_trail_mesh = ImmediateMesh.new()
	_euler_trail_instance = MeshInstance3D.new()
	_euler_trail_instance.mesh = _euler_trail_mesh
	var emat := StandardMaterial3D.new()
	emat.albedo_color = Color(1.0, 0.3, 0.2, 0.4)
	emat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	emat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_euler_trail_instance.material_override = emat
	add_child(_euler_trail_instance)

	# Verlet trail (blue)
	_verlet_trail_mesh = ImmediateMesh.new()
	_verlet_trail_instance = MeshInstance3D.new()
	_verlet_trail_instance.mesh = _verlet_trail_mesh
	var vmat := StandardMaterial3D.new()
	vmat.albedo_color = Color(0.2, 0.5, 1.0, 0.4)
	vmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	vmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_verlet_trail_instance.material_override = vmat
	add_child(_verlet_trail_instance)


func _setup_ghost_line() -> void:
	# Line showing the position-differencing trick
	_ghost_line_mesh = ImmediateMesh.new()
	_ghost_line_instance = MeshInstance3D.new()
	_ghost_line_instance.mesh = _ghost_line_mesh
	var gmat := StandardMaterial3D.new()
	gmat.albedo_color = Color(0.5, 0.8, 1.0, 0.3)
	gmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ghost_line_instance.material_override = gmat
	add_child(_ghost_line_instance)


func _setup_labels() -> void:
	var title := Label3D.new()
	title.text = "Verlet vs Euler Integration"
	title.font_size = 22
	title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	title.position = Vector3(0.0, 6.5, 3.0)
	title.modulate = Color(1, 1, 1, 0.9)
	add_child(title)

	_label_equation = Label3D.new()
	_label_equation.text = "Verlet: x_new = 2x - x_prev + a*dt^2    (no velocity)"
	_label_equation.font_size = 13
	_label_equation.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label_equation.position = Vector3(0.0, 5.8, 3.0)
	_label_equation.modulate = Color(0.5, 0.8, 1.0, 0.7)
	add_child(_label_equation)

	# Euler label
	var euler_label := Label3D.new()
	euler_label.text = "EULER"
	euler_label.font_size = 18
	euler_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	euler_label.position = Vector3(-SEPARATION * 0.5, 5.0, 2.0)
	euler_label.modulate = Color(1.0, 0.3, 0.2, 0.8)
	add_child(euler_label)

	var euler_eq := Label3D.new()
	euler_eq.text = "v += a*dt\nx += v*dt"
	euler_eq.font_size = 11
	euler_eq.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	euler_eq.position = Vector3(-SEPARATION * 0.5, 4.4, 2.0)
	euler_eq.modulate = Color(1.0, 0.3, 0.2, 0.5)
	add_child(euler_eq)

	# Verlet label
	var verlet_label := Label3D.new()
	verlet_label.text = "VERLET"
	verlet_label.font_size = 18
	verlet_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	verlet_label.position = Vector3(SEPARATION * 0.5, 5.0, 2.0)
	verlet_label.modulate = Color(0.2, 0.5, 1.0, 0.8)
	add_child(verlet_label)

	var verlet_eq := Label3D.new()
	verlet_eq.text = "x_new = 2x - x_prev + a*dt^2\n(no velocity variable)"
	verlet_eq.font_size = 11
	verlet_eq.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	verlet_eq.position = Vector3(SEPARATION * 0.5, 4.4, 2.0)
	verlet_eq.modulate = Color(0.2, 0.5, 1.0, 0.5)
	add_child(verlet_eq)

	_label_euler_energy = Label3D.new()
	_label_euler_energy.font_size = 12
	_label_euler_energy.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label_euler_energy.position = Vector3(-SEPARATION * 0.5, 3.6, 2.0)
	add_child(_label_euler_energy)

	_label_verlet_energy = Label3D.new()
	_label_verlet_energy.font_size = 12
	_label_verlet_energy.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label_verlet_energy.position = Vector3(SEPARATION * 0.5, 3.6, 2.0)
	add_child(_label_verlet_energy)

	_label_dt = Label3D.new()
	_label_dt.font_size = 16
	_label_dt.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label_dt.position = Vector3(0.0, 5.2, 3.0)
	_label_dt.modulate = Color(1.0, 0.9, 0.3, 0.8)
	add_child(_label_dt)


func _reset_simulation() -> void:
	_dt = 0.02
	_time = 0.0
	_ramp_phase = 0

	var center_left := _attractor_left.position
	var center_right := _attractor_right.position

	# Euler: circular orbit start
	_euler_pos = center_left + Vector3(INITIAL_RADIUS, 0.0, 0.0)
	_euler_vel = Vector3(0.0, 0.0, INITIAL_SPEED)
	_euler_trail.clear()

	# Verlet: same orbit, position-based
	_verlet_pos = center_right + Vector3(INITIAL_RADIUS, 0.0, 0.0)
	var initial_vel := Vector3(0.0, 0.0, INITIAL_SPEED)
	_verlet_prev = _verlet_pos - initial_vel * _dt  # bootstrap: prev = pos - v*dt
	_verlet_trail.clear()

	_euler_energy_initial = _compute_euler_energy()
	_verlet_energy_initial = _compute_verlet_energy()


func _process(delta: float) -> void:
	_time += delta

	# Auto-ramp dt
	if _auto_ramp:
		if _time < 8.0:
			_dt = 0.02  # stable
			_ramp_phase = 0
		elif _time < 25.0:
			var t := (_time - 8.0) / 17.0
			_dt = lerp(0.02, 0.08, t * t)
			_ramp_phase = 1
		elif _time < 30.0:
			_dt = 0.08
			_ramp_phase = 2
		else:
			_reset_simulation()
			return

	# Step both integrators
	_step_euler()
	_step_verlet()

	# Record trails
	_euler_trail.append(_euler_pos)
	if _euler_trail.size() > TRAIL_LENGTH:
		_euler_trail.pop_front()

	_verlet_trail.append(_verlet_pos)
	if _verlet_trail.size() > TRAIL_LENGTH:
		_verlet_trail.pop_front()

	# Update visuals
	_render()
	_update_labels()


func _step_euler() -> void:
	# Classic Euler: v += a*dt, x += v*dt
	var center := _attractor_left.position
	var diff := center - _euler_pos
	var dist := diff.length()
	if dist < 0.3:
		dist = 0.3
	var acc := diff.normalized() * ATTRACTOR_STRENGTH / (dist * dist)

	_euler_vel += acc * _dt
	_euler_pos += _euler_vel * _dt


func _step_verlet() -> void:
	# Verlet: x_new = 2x - x_prev + a*dt²  (NO velocity)
	var center := _attractor_right.position
	var diff := center - _verlet_pos
	var dist := diff.length()
	if dist < 0.3:
		dist = 0.3
	var acc := diff.normalized() * ATTRACTOR_STRENGTH / (dist * dist)

	var new_pos := 2.0 * _verlet_pos - _verlet_prev + acc * _dt * _dt
	_verlet_prev = _verlet_pos
	_verlet_pos = new_pos


func _compute_euler_energy() -> float:
	var center := _attractor_left.position
	var ke := 0.5 * _euler_vel.length_squared()
	var dist := (_euler_pos - center).length()
	var pe := -ATTRACTOR_STRENGTH / maxf(dist, 0.3)
	return ke + pe


func _compute_verlet_energy() -> float:
	var center := _attractor_right.position
	# Reconstruct velocity from positions
	var vel := (_verlet_pos - _verlet_prev) / maxf(_dt, 0.001)
	var ke := 0.5 * vel.length_squared()
	var dist := (_verlet_pos - center).length()
	var pe := -ATTRACTOR_STRENGTH / maxf(dist, 0.3)
	return ke + pe


func _render() -> void:
	# Particle positions
	if _euler_pos.length() < 100.0:
		_euler_sphere.position = _euler_pos
		_euler_sphere.visible = true
	else:
		_euler_sphere.visible = false

	_verlet_sphere.position = _verlet_pos
	_verlet_prev_sphere.position = _verlet_prev

	# Euler trail
	_draw_trail(_euler_trail_mesh, _euler_trail, _euler_trail_instance)

	# Verlet trail
	_draw_trail(_verlet_trail_mesh, _verlet_trail, _verlet_trail_instance)

	# Ghost line: prev → current → (projected next)
	_ghost_line_mesh.clear_surfaces()
	var gmat := _ghost_line_instance.material_override
	_ghost_line_mesh.surface_begin(Mesh.PRIMITIVE_LINES, gmat)
	# prev to current
	_ghost_line_mesh.surface_add_vertex(_verlet_prev)
	_ghost_line_mesh.surface_add_vertex(_verlet_pos)
	# current to projected next (showing the position-difference extrapolation)
	var projected := 2.0 * _verlet_pos - _verlet_prev
	_ghost_line_mesh.surface_add_vertex(_verlet_pos)
	_ghost_line_mesh.surface_add_vertex(projected)
	_ghost_line_mesh.surface_end()


func _draw_trail(mesh: ImmediateMesh, trail: Array[Vector3], instance: MeshInstance3D) -> void:
	mesh.clear_surfaces()
	if trail.size() < 2:
		return
	var mat := instance.material_override
	mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, mat)
	for pt in trail:
		if pt.length() < 100.0:
			mesh.surface_add_vertex(pt)
	mesh.surface_end()


func _update_labels() -> void:
	_label_dt.text = "dt = %.4f" % _dt

	var euler_e := _compute_euler_energy()
	var euler_ratio := euler_e / maxf(absf(_euler_energy_initial), 0.001)
	if _euler_pos.length() < 100.0:
		_label_euler_energy.text = "energy: %.1f (%.0f%%)" % [euler_e, euler_ratio * 100]
		if absf(euler_ratio) > 2.0:
			_label_euler_energy.modulate = Color(1.0, 0.3, 0.1, 0.9)
		else:
			_label_euler_energy.modulate = Color(1.0, 0.6, 0.2, 0.7)
	else:
		_label_euler_energy.text = "ESCAPED"
		_label_euler_energy.modulate = Color(1.0, 0.2, 0.1, 1.0)

	var verlet_e := _compute_verlet_energy()
	var verlet_ratio := verlet_e / maxf(absf(_verlet_energy_initial), 0.001)
	_label_verlet_energy.text = "energy: %.1f (%.0f%%)" % [verlet_e, verlet_ratio * 100]
	if absf(verlet_ratio - 1.0) < 0.2:
		_label_verlet_energy.modulate = Color(0.3, 1.0, 0.5, 0.8)
	else:
		_label_verlet_energy.modulate = Color(1.0, 0.8, 0.2, 0.8)


func _make_sphere(radius: float, color: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var smesh := SphereMesh.new()
	smesh.radius = radius
	smesh.height = radius * 2.0
	mesh.mesh = smesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if color.a < 1.0 else BaseMaterial3D.TRANSPARENCY_DISABLED
	mat.emission_enabled = true
	mat.emission = color * 0.5
	mat.emission_energy_multiplier = 1.0
	mat.roughness = 0.2
	mesh.material_override = mat
	return mesh


func apply_grid_config(config: Dictionary) -> void:
	pass
