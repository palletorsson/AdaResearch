extends Node3D

# @identity
# essence: When dt > sqrt(2m/k), energy grows exponentially. The simulation lies, then screams.
# desire: To break. To show the learner the exact moment physics stops being physics.
# critical_parameter: dt (timestep) — the hidden lambda. Too small: nothing happens fast enough. Too large: everything explodes.
# triggers: dt ramp crosses stability threshold → STABLE becomes DRIFTING becomes EXPLODED, auto-reset → cycle repeats
# emerges: The stability boundary from the interaction of spring stiffness and timestep. Chaos from deterministic math.
# needs: Manual dt VR slider [missing — auto-ramp only]. Stiffness slider [missing]. Reset button [has auto-reset].
# relationships: Completes PhysicsSim_Foundations truth statement. Depends on verlet_integration (uses same method). Contrasts with fluid_simulation (SPH has its own CFL condition).
# truth: Knowing where the illusion breaks is more important than knowing how it works.

## Simulation Instability — crank the timestep until physics explodes.
##
## Three spring-connected masses run with a visible dt slider.
## At low dt: stable oscillation, energy conserved.
## At medium dt: energy drifts, orbits precess.
## At high dt: the jelly-of-death — exponential energy gain, positions fly to infinity.
## A reset button brings it back. The learner feels WHY the method matters.

var _masses: Array[Dictionary] = []
var _springs: Array[Dictionary] = []
var _dt := 0.016  # starts stable
var _time := 0.0
var _total_energy_initial := 0.0
var _multi_mesh: MultiMesh
var _multi_mesh_instance: MultiMeshInstance3D
var _line_mesh: ImmediateMesh
var _line_instance: MeshInstance3D
var _line_material: StandardMaterial3D
var _label_dt: Label3D
var _label_energy: Label3D
var _label_status: Label3D
var _exploded := false

const NUM_MASSES := 6
const REST_LENGTH := 1.5
const STIFFNESS := 40.0
const DAMPING := 0.2
const MASS := 1.0


func _ready() -> void:
	_setup_masses()
	_setup_rendering()
	_setup_labels()
	_total_energy_initial = _compute_energy()


func _setup_masses() -> void:
	# Ring of masses connected by springs
	for i in NUM_MASSES:
		var angle := float(i) / NUM_MASSES * TAU
		var pos := Vector3(cos(angle) * 2.5, 2.0, sin(angle) * 2.5)
		# Give slight random velocity for motion
		var vel := Vector3(sin(angle) * 0.5, randf_range(-0.2, 0.2), -cos(angle) * 0.5)
		_masses.append({
			"pos": pos,
			"prev_pos": pos - vel * _dt,
			"vel": vel,
			"mass": MASS
		})

	# Connect adjacent masses with springs
	for i in NUM_MASSES:
		var j := (i + 1) % NUM_MASSES
		_springs.append({
			"a": i, "b": j,
			"rest": REST_LENGTH,
			"k": STIFFNESS
		})
	# Cross springs for stability
	for i in NUM_MASSES:
		var j := (i + 2) % NUM_MASSES
		_springs.append({
			"a": i, "b": j,
			"rest": REST_LENGTH * 1.8,
			"k": STIFFNESS * 0.5
		})


func _setup_rendering() -> void:
	_multi_mesh = MultiMesh.new()
	_multi_mesh.transform_format = MultiMesh.TRANSFORM_3D
	_multi_mesh.use_colors = true
	_multi_mesh.instance_count = NUM_MASSES
	_multi_mesh.visible_instance_count = NUM_MASSES

	var sphere := SphereMesh.new()
	sphere.radius = 0.2
	sphere.height = 0.4
	sphere.radial_segments = 12
	sphere.rings = 6
	_multi_mesh.mesh = sphere

	_multi_mesh_instance = MultiMeshInstance3D.new()
	_multi_mesh_instance.multimesh = _multi_mesh
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission_energy_multiplier = 1.0
	_multi_mesh_instance.material_override = mat
	add_child(_multi_mesh_instance)

	_line_mesh = ImmediateMesh.new()
	_line_instance = MeshInstance3D.new()
	_line_instance.mesh = _line_mesh
	_line_material = StandardMaterial3D.new()
	_line_material.albedo_color = Color(0.6, 0.8, 1.0, 0.5)
	_line_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_line_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_line_instance.material_override = _line_material
	add_child(_line_instance)


func _setup_labels() -> void:
	var title := Label3D.new()
	title.text = "Simulation Instability"
	title.font_size = 22
	title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	title.position = Vector3(0.0, 6.0, 3.0)
	title.modulate = Color(1, 1, 1, 0.9)
	add_child(title)

	_label_dt = Label3D.new()
	_label_dt.font_size = 18
	_label_dt.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label_dt.position = Vector3(0.0, 5.2, 3.0)
	_label_dt.modulate = Color(1.0, 0.9, 0.3, 0.9)
	add_child(_label_dt)

	_label_energy = Label3D.new()
	_label_energy.font_size = 14
	_label_energy.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label_energy.position = Vector3(0.0, 4.5, 3.0)
	_label_energy.modulate = Color(0.3, 1.0, 0.5, 0.8)
	add_child(_label_energy)

	_label_status = Label3D.new()
	_label_status.font_size = 20
	_label_status.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label_status.position = Vector3(0.0, 3.5, 3.0)
	add_child(_label_status)

	var hint := Label3D.new()
	hint.text = "dt ramps up automatically"
	hint.font_size = 12
	hint.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	hint.position = Vector3(0.0, 2.8, 3.0)
	hint.modulate = Color(1, 1, 1, 0.5)
	add_child(hint)


func _process(delta: float) -> void:
	_time += delta

	# Ramp dt over time: stable for 5s, then slowly increase
	if _time < 5.0:
		_dt = 0.016
	elif _time < 20.0:
		# Ramp from 0.016 to 0.15 over 15 seconds
		var t := (_time - 5.0) / 15.0
		_dt = lerp(0.016, 0.15, t * t)
	else:
		_dt = 0.15

	# Auto-reset after explosion
	if _exploded:
		if _time > 25.0:
			_reset()
		_render()
		return

	# Verlet integration step with current dt
	_step_verlet()

	# Check for explosion
	var energy := _compute_energy()
	var energy_ratio := energy / maxf(_total_energy_initial, 0.001)

	if energy_ratio > 100.0 or _has_nan():
		_exploded = true
		_label_status.text = "EXPLODED"
		_label_status.modulate = Color(1.0, 0.2, 0.1, 1.0)
	elif energy_ratio > 5.0:
		_label_status.text = "UNSTABLE"
		_label_status.modulate = Color(1.0, 0.6, 0.1, 0.9)
	elif energy_ratio > 1.5:
		_label_status.text = "DRIFTING"
		_label_status.modulate = Color(1.0, 0.9, 0.3, 0.8)
	else:
		_label_status.text = "STABLE"
		_label_status.modulate = Color(0.3, 1.0, 0.5, 0.8)

	_label_dt.text = "dt = %.4f" % _dt
	_label_energy.text = "energy: %.1f (initial: %.1f, ratio: %.1fx)" % [energy, _total_energy_initial, energy_ratio]

	_render()


func _step_verlet() -> void:
	# Compute spring forces
	var forces: Array[Vector3] = []
	for _i in NUM_MASSES:
		forces.append(Vector3(0.0, -2.0, 0.0))  # gravity

	for spring in _springs:
		var a: int = spring["a"]
		var b: int = spring["b"]
		var diff: Vector3 = _masses[b]["pos"] - _masses[a]["pos"]
		var dist := diff.length()
		if dist < 0.001:
			continue
		var dir := diff / dist
		var stretch: float = dist - float(spring["rest"])
		var force: Vector3 = dir * float(spring["k"]) * stretch

		# Damping
		var vel_diff: Vector3 = _masses[b]["vel"] - _masses[a]["vel"]
		force += dir * vel_diff.dot(dir) * DAMPING

		forces[a] += force
		forces[b] -= force

	# Verlet step
	for i in NUM_MASSES:
		var m: Dictionary = _masses[i]
		var acc: Vector3 = forces[i] / m["mass"]
		var new_pos: Vector3 = 2.0 * m["pos"] - m["prev_pos"] + acc * _dt * _dt
		m["vel"] = (new_pos - m["pos"]) / maxf(_dt, 0.0001)
		m["prev_pos"] = m["pos"]
		m["pos"] = new_pos


func _compute_energy() -> float:
	var ke := 0.0
	for m in _masses:
		ke += 0.5 * m["mass"] * m["vel"].length_squared()

	var pe := 0.0
	for spring in _springs:
		var dist: float = (_masses[spring["b"]]["pos"] - _masses[spring["a"]]["pos"]).length()
		var stretch: float = dist - float(spring["rest"])
		pe += 0.5 * float(spring["k"]) * stretch * stretch

	# Gravitational PE
	for m in _masses:
		pe += m["mass"] * 2.0 * m["pos"].y

	return ke + pe


func _has_nan() -> bool:
	for m in _masses:
		if is_nan(m["pos"].x) or is_nan(m["pos"].y) or is_nan(m["pos"].z):
			return true
		if m["pos"].length() > 1000.0:
			return true
	return false


func _reset() -> void:
	_masses.clear()
	_springs.clear()
	_time = 0.0
	_dt = 0.016
	_exploded = false
	_label_status.text = "STABLE"
	_label_status.modulate = Color(0.3, 1.0, 0.5, 0.8)
	_setup_masses()
	_total_energy_initial = _compute_energy()


func _render() -> void:
	for i in NUM_MASSES:
		var pos: Vector3 = _masses[i]["pos"]
		if is_nan(pos.x):
			pos = Vector3.ZERO
		# Clamp for visual sanity
		pos = pos.clampf(-50.0, 50.0) if false else pos
		if pos.length() > 50.0:
			pos = pos.normalized() * 50.0

		var energy_ratio := _compute_energy() / maxf(_total_energy_initial, 0.001)
		var color: Color
		if energy_ratio < 1.5:
			color = Color(0.3, 0.7, 1.0)
		elif energy_ratio < 5.0:
			color = Color(1.0, 0.8, 0.2)
		else:
			color = Color(1.0, 0.2, 0.1)

		var xform := Transform3D.IDENTITY
		xform.origin = pos
		_multi_mesh.set_instance_transform(i, xform)
		_multi_mesh.set_instance_color(i, color)

	# Draw springs
	_line_mesh.clear_surfaces()
	_line_mesh.surface_begin(Mesh.PRIMITIVE_LINES, _line_material)
	for spring in _springs:
		var pa: Vector3 = _masses[spring["a"]]["pos"]
		var pb: Vector3 = _masses[spring["b"]]["pos"]
		if is_nan(pa.x) or is_nan(pb.x):
			continue
		if pa.length() > 50.0 or pb.length() > 50.0:
			continue
		_line_mesh.surface_add_vertex(pa)
		_line_mesh.surface_add_vertex(pb)
	_line_mesh.surface_end()


func apply_grid_config(config: Dictionary) -> void:
	pass
