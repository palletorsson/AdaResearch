# ===========================================================================
# QuantumField — Particle Creation, Feynman Diagrams & Field Dynamics
# Interactive quantum field theory visualization in VR
# Elevated features:
#   - Particle creation/annihilation with pair production and decay
#   - Feynman diagram rendering with propagators and vertices
#   - Nonlinear field dynamics with self-interaction (φ⁴ theory)
#   - Configurable via apply_grid_config()
# License: CC BY-NC-SA 3.0 derivative
# ===========================================================================

extends Node3D

## Quantum field theory visualization with three modes:
## FIELD shows a scalar field on a grid with vacuum fluctuations and nonlinear
## self-interaction (φ⁴ potential); PARTICLES visualizes pair creation and
## annihilation events with worldlines; FEYNMAN draws interactive Feynman
## diagrams for fundamental QED/QCD processes.

# --- Configuration ---
@export var grid_res: int = 32
@export var field_spacing: float = 0.12
@export var step_speed: float = 1.0
@export var vacuum_strength: float = 0.2
@export var coupling_lambda: float = 0.5
@export var mass_param: float = 1.0

# --- Mode ---
enum Mode { FIELD, PARTICLES, FEYNMAN }
var _mode: int = Mode.FIELD

# --- Field state (FIELD mode) ---
var _phi: Array = []        # field values φ(x,z)
var _phi_dot: Array = []    # time derivatives ∂φ/∂t
const FIELD_DT := 0.02

# --- Particle state (PARTICLES mode) ---
var _particles: Array = []   # Array[Dict] — active particles
var _worldlines: Array = []  # Array[Array[Vector3]] — trails
var _annihilation_flashes: Array = []  # Array[Dict] — {pos, life}
const MAX_PARTICLES := 24
const WORLDLINE_LEN := 80
const PAIR_INTERVAL := 1.5
var _pair_timer: float = 0.0

# --- Feynman diagram state (FEYNMAN mode) ---
enum Diagram { QED_SCATTER, PAIR_PRODUCTION, GLUON_LOOP, COMPTON }
var _diagram: int = Diagram.QED_SCATTER
const DIAGRAM_NAMES := ["e⁻e⁻ → e⁻e⁻", "γ → e⁺e⁻", "Gluon loop", "Compton"]
var _diagram_anim: float = 0.0

# --- Internal ---
var _time: float = 0.0

# --- ImmediateMesh rendering ---
var _field_im: ImmediateMesh
var _field_mi: MeshInstance3D
var _particle_im: ImmediateMesh
var _particle_mi: MeshInstance3D
var _diagram_im: ImmediateMesh
var _diagram_mi: MeshInstance3D
var _overlay_im: ImmediateMesh
var _overlay_mi: MeshInstance3D

# Materials
var _mat_unshaded: StandardMaterial3D
var _mat_alpha: StandardMaterial3D

# Labels
var _title_label: Label3D
var _info_label: Label3D
var _state_label: Label3D

# VR controls
const BUTTON_SCENE = preload("res://commons/interactables/push_button.tscn")
const SLIDER_SCENE = preload("res://commons/interactables/slider_horizontal.tscn")
var _mode_button: Node3D
var _action_button: Node3D
var _reset_button: Node3D
var _coupling_slider: Node3D
var _mass_slider: Node3D

# Colors
const COL_FIELD_LOW := Color(0.08, 0.05, 0.35, 0.85)
const COL_FIELD_MID := Color(0.0, 0.7, 0.9, 0.85)
const COL_FIELD_HIGH := Color(1.0, 0.4, 0.1, 0.9)
const COL_ELECTRON := Color(0.3, 0.6, 1.0, 0.9)
const COL_POSITRON := Color(1.0, 0.35, 0.4, 0.9)
const COL_PHOTON := Color(1.0, 1.0, 0.3, 0.85)
const COL_GLUON := Color(0.2, 1.0, 0.4, 0.85)
const COL_VERTEX := Color(1.0, 1.0, 1.0, 0.95)
const COL_PROPAGATOR := Color(0.6, 0.6, 0.8, 0.6)
const COL_FLASH := Color(1.0, 0.95, 0.7, 0.9)
const COL_POTENTIAL := Color(0.5, 0.2, 0.8, 0.4)
const COL_GRID := Color(0.25, 0.3, 0.45, 0.2)


func _ready() -> void:
	_create_materials()
	_create_mesh_instances()
	_create_labels()
	_create_vr_controls()
	_init_field()
	_init_mode()


func _process(delta: float) -> void:
	_time += delta * step_speed
	match _mode:
		Mode.FIELD:
			_step_field(delta)
			_draw_field()
		Mode.PARTICLES:
			_step_particles(delta)
			_draw_particles()
		Mode.FEYNMAN:
			_diagram_anim += delta * step_speed * 0.5
			_draw_feynman()
	_update_labels()


# =========================================================================
# Materials
# =========================================================================

func _create_materials() -> void:
	_mat_unshaded = StandardMaterial3D.new()
	_mat_unshaded.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_unshaded.vertex_color_use_as_albedo = true
	_mat_unshaded.cull_mode = BaseMaterial3D.CULL_DISABLED

	_mat_alpha = StandardMaterial3D.new()
	_mat_alpha.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_alpha.vertex_color_use_as_albedo = true
	_mat_alpha.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mat_alpha.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA


# =========================================================================
# Mesh instances
# =========================================================================

func _create_mesh_instances() -> void:
	_field_im = ImmediateMesh.new()
	_field_mi = MeshInstance3D.new()
	_field_mi.mesh = _field_im
	_field_mi.material_override = _mat_alpha
	add_child(_field_mi)

	_particle_im = ImmediateMesh.new()
	_particle_mi = MeshInstance3D.new()
	_particle_mi.mesh = _particle_im
	_particle_mi.material_override = _mat_alpha
	add_child(_particle_mi)

	_diagram_im = ImmediateMesh.new()
	_diagram_mi = MeshInstance3D.new()
	_diagram_mi.mesh = _diagram_im
	_diagram_mi.material_override = _mat_alpha
	add_child(_diagram_mi)

	_overlay_im = ImmediateMesh.new()
	_overlay_mi = MeshInstance3D.new()
	_overlay_mi.mesh = _overlay_im
	_overlay_mi.material_override = _mat_unshaded
	add_child(_overlay_mi)


# =========================================================================
# Labels
# =========================================================================

func _create_labels() -> void:
	_title_label = Label3D.new()
	_title_label.font_size = 28
	_title_label.outline_size = 4
	_title_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_title_label.position = Vector3(0, 2.4, 0)
	_title_label.modulate = Color.WHITE
	add_child(_title_label)

	_info_label = Label3D.new()
	_info_label.font_size = 22
	_info_label.outline_size = 3
	_info_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_info_label.position = Vector3(0, 2.0, 0)
	_info_label.modulate = Color(0.85, 0.9, 1.0)
	add_child(_info_label)

	_state_label = Label3D.new()
	_state_label.font_size = 20
	_state_label.outline_size = 3
	_state_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_state_label.position = Vector3(0, -1.4, 0)
	_state_label.modulate = Color(0.7, 0.8, 1.0)
	add_child(_state_label)


# =========================================================================
# VR controls
# =========================================================================

func _create_vr_controls() -> void:
	_mode_button = BUTTON_SCENE.instantiate()
	_mode_button.position = Vector3(-1.6, -1.0, 0)
	add_child(_mode_button)
	var btn_mode = _mode_button.get_node_or_null("InteractableAreaButton")
	if btn_mode:
		btn_mode.button_pressed.connect(_cycle_mode)

	_action_button = BUTTON_SCENE.instantiate()
	_action_button.position = Vector3(-0.8, -1.0, 0)
	add_child(_action_button)
	var btn_action = _action_button.get_node_or_null("InteractableAreaButton")
	if btn_action:
		btn_action.button_pressed.connect(_on_action_pressed)

	_reset_button = BUTTON_SCENE.instantiate()
	_reset_button.position = Vector3(0.0, -1.0, 0)
	add_child(_reset_button)
	var btn_reset = _reset_button.get_node_or_null("InteractableAreaButton")
	if btn_reset:
		btn_reset.button_pressed.connect(_on_reset)

	_coupling_slider = SLIDER_SCENE.instantiate()
	_coupling_slider.position = Vector3(1.2, -0.8, 0)
	add_child(_coupling_slider)
	_coupling_slider.set_param_name("Coupling λ")
	_coupling_slider.set_normalized_value(coupling_lambda / 2.0)
	_coupling_slider.slider_moved.connect(_on_coupling_changed)

	_mass_slider = SLIDER_SCENE.instantiate()
	_mass_slider.position = Vector3(1.2, -1.2, 0)
	add_child(_mass_slider)
	_mass_slider.set_param_name("Mass m")
	_mass_slider.set_normalized_value(mass_param / 3.0)
	_mass_slider.slider_moved.connect(_on_mass_changed)


func _cycle_mode() -> void:
	_mode = (_mode + 1) % 3
	_init_mode()


func _on_action_pressed() -> void:
	match _mode:
		Mode.FIELD:
			# Inject a field excitation (particle-like lump)
			_inject_excitation()
		Mode.PARTICLES:
			# Force a pair creation event
			_create_pair()
		Mode.FEYNMAN:
			# Cycle diagram type
			_diagram = (_diagram + 1) % 4
			_diagram_anim = 0.0


func _on_reset() -> void:
	_init_field()
	_particles.clear()
	_worldlines.clear()
	_annihilation_flashes.clear()
	_pair_timer = 0.0
	_diagram_anim = 0.0
	_init_mode()


func _on_coupling_changed(_value: float) -> void:
	coupling_lambda = _coupling_slider.get_normalized_value() * 2.0


func _on_mass_changed(_value: float) -> void:
	mass_param = _mass_slider.get_normalized_value() * 3.0


func _init_mode() -> void:
	_field_mi.visible = (_mode == Mode.FIELD)
	_particle_mi.visible = (_mode == Mode.PARTICLES)
	_diagram_mi.visible = (_mode == Mode.FEYNMAN)
	_overlay_mi.visible = true

	_coupling_slider.visible = (_mode == Mode.FIELD)
	_mass_slider.visible = (_mode == Mode.FIELD or _mode == Mode.PARTICLES)

	match _mode:
		Mode.FIELD:
			_init_field()
		Mode.PARTICLES:
			_particles.clear()
			_worldlines.clear()
			_annihilation_flashes.clear()
			_pair_timer = 0.0
		Mode.FEYNMAN:
			_diagram_anim = 0.0


# =========================================================================
# Field dynamics (FIELD mode) — φ⁴ scalar field theory
# =========================================================================

func _init_field() -> void:
	var n := grid_res * grid_res
	_phi.resize(n)
	_phi_dot.resize(n)
	for i in range(n):
		_phi[i] = randf_range(-0.05, 0.05)
		_phi_dot[i] = 0.0


func _inject_excitation() -> void:
	# Gaussian lump at a random position
	var cx := randi_range(grid_res / 4, 3 * grid_res / 4)
	var cz := randi_range(grid_res / 4, 3 * grid_res / 4)
	var sigma := 2.5
	var amp := 1.5
	for iz in range(grid_res):
		for ix in range(grid_res):
			var dx := float(ix - cx)
			var dz := float(iz - cz)
			var r2 := dx * dx + dz * dz
			_phi[iz * grid_res + ix] += amp * exp(-r2 / (2.0 * sigma * sigma))


func _step_field(delta: float) -> void:
	# Klein-Gordon equation with φ⁴ self-interaction:
	# ∂²φ/∂t² = ∇²φ - m²φ - λφ³ + vacuum noise
	var n := grid_res
	var dt := FIELD_DT * step_speed
	var m2 := mass_param * mass_param
	var lam := coupling_lambda

	for _substep in range(3):
		var new_phi_dot := _phi_dot.duplicate()
		for iz in range(n):
			for ix in range(n):
				var idx := iz * n + ix
				var p: float = _phi[idx]

				# Discrete Laplacian (2D)
				var left: float = _phi[idx - 1] if ix > 0 else p
				var right: float = _phi[idx + 1] if ix < n - 1 else p
				var up: float = _phi[(iz - 1) * n + ix] if iz > 0 else p
				var down: float = _phi[(iz + 1) * n + ix] if iz < n - 1 else p
				var lap := (left + right + up + down - 4.0 * p) / (field_spacing * field_spacing)

				# φ⁴ equation of motion
				var force := lap - m2 * p - lam * p * p * p

				# Tiny vacuum fluctuations
				force += randf_range(-vacuum_strength, vacuum_strength) * 0.3

				new_phi_dot[idx] = (_phi_dot[idx] + force * dt) * 0.998  # slight damping

		_phi_dot = new_phi_dot
		for i in range(_phi.size()):
			_phi[i] += _phi_dot[i] * dt


func _draw_field() -> void:
	_field_im.clear_surfaces()
	_field_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	var n := grid_res
	var half := float(n) * field_spacing * 0.5
	var height_scale := 1.2

	# Draw field as heightmap quads
	for iz in range(n - 1):
		for ix in range(n - 1):
			var x0 := ix * field_spacing - half
			var x1 := (ix + 1) * field_spacing - half
			var z0 := iz * field_spacing - half
			var z1 := (iz + 1) * field_spacing - half

			var p00: float = _phi[iz * n + ix]
			var p10: float = _phi[iz * n + ix + 1]
			var p01: float = _phi[(iz + 1) * n + ix]
			var p11: float = _phi[(iz + 1) * n + ix + 1]

			var v00 := Vector3(x0, p00 * height_scale, z0)
			var v10 := Vector3(x1, p10 * height_scale, z0)
			var v01 := Vector3(x0, p01 * height_scale, z1)
			var v11 := Vector3(x1, p11 * height_scale, z1)

			var c00 := _field_color(p00)
			var c10 := _field_color(p10)
			var c01 := _field_color(p01)
			var c11 := _field_color(p11)

			# Two triangles per quad with per-vertex color
			_im_tri_colored(_field_im, v00, c00, v10, c10, v01, c01)
			_im_tri_colored(_field_im, v10, c10, v11, c11, v01, c01)

	_field_im.surface_end()

	# Draw potential curve V(φ) as overlay
	_overlay_im.clear_surfaces()
	_overlay_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	_draw_potential_curve()
	_overlay_im.surface_end()


func _field_color(val: float) -> Color:
	var t := clampf((val + 2.0) / 4.0, 0.0, 1.0)
	if t < 0.5:
		return COL_FIELD_LOW.lerp(COL_FIELD_MID, t * 2.0)
	return COL_FIELD_MID.lerp(COL_FIELD_HIGH, (t - 0.5) * 2.0)


func _draw_potential_curve() -> void:
	# V(φ) = ½m²φ² + ¼λφ⁴  — Mexican hat when m² < 0
	var cx := -2.0
	var cy := 1.5
	var scale_x := 0.3
	var scale_y := 0.5
	var m2 := mass_param * mass_param
	var lam := coupling_lambda
	var steps := 40

	for i in range(steps):
		var t0 := -3.0 + 6.0 * float(i) / steps
		var t1 := -3.0 + 6.0 * float(i + 1) / steps
		var v0 := 0.5 * m2 * t0 * t0 + 0.25 * lam * t0 * t0 * t0 * t0
		var v1 := 0.5 * m2 * t1 * t1 + 0.25 * lam * t1 * t1 * t1 * t1
		v0 = clampf(v0, -5.0, 5.0)
		v1 = clampf(v1, -5.0, 5.0)
		_im_line_3d(_overlay_im,
			Vector3(cx + t0 * scale_x, cy + v0 * scale_y, 0.01),
			Vector3(cx + t1 * scale_x, cy + v1 * scale_y, 0.01),
			0.015, COL_POTENTIAL)

	# Axis lines
	_im_line_3d(_overlay_im,
		Vector3(cx - 1.0, cy, 0.01), Vector3(cx + 1.0, cy, 0.01),
		0.008, COL_GRID)
	_im_line_3d(_overlay_im,
		Vector3(cx, cy - 0.3, 0.01), Vector3(cx, cy + 1.5, 0.01),
		0.008, COL_GRID)


# =========================================================================
# Particle creation/annihilation (PARTICLES mode)
# =========================================================================

func _create_pair() -> void:
	if _particles.size() >= MAX_PARTICLES:
		return
	var spawn_x := randf_range(-1.5, 1.5)
	var spawn_z := randf_range(-1.0, 1.0)
	var spawn_pos := Vector3(spawn_x, 0, spawn_z)
	var angle := randf() * TAU
	var speed := randf_range(0.3, 0.8)
	var dir := Vector3(cos(angle), 0, sin(angle)) * speed

	# Particle
	_particles.append({
		"pos": spawn_pos,
		"vel": dir,
		"charge": -1,
		"life": randf_range(3.0, 6.0),
		"max_life": 6.0,
	})
	_worldlines.append([spawn_pos])

	# Antiparticle (opposite direction)
	_particles.append({
		"pos": spawn_pos,
		"vel": -dir,
		"charge": 1,
		"life": randf_range(3.0, 6.0),
		"max_life": 6.0,
	})
	_worldlines.append([spawn_pos])


func _step_particles(delta: float) -> void:
	_pair_timer += delta * step_speed
	if _pair_timer >= PAIR_INTERVAL and _particles.size() < MAX_PARTICLES:
		_pair_timer = 0.0
		_create_pair()

	# Update positions and worldlines
	var dt := delta * step_speed
	for i in range(_particles.size() - 1, -1, -1):
		var p: Dictionary = _particles[i]
		p.life -= dt
		if p.life <= 0:
			# Particle decays — flash
			_annihilation_flashes.append({"pos": p.pos, "life": 0.4})
			_particles.remove_at(i)
			if i < _worldlines.size():
				_worldlines.remove_at(i)
			continue

		# Slight curve from "magnetic field" (charge-dependent)
		var cross_vel: Vector3 = Vector3(-p.vel.z, 0, p.vel.x) * 0.3 * p.charge
		p.vel += cross_vel * dt
		p.vel = p.vel.normalized() * p.vel.length()  # preserve speed
		p.pos += p.vel * dt

		# Bounce at boundaries
		if absf(p.pos.x) > 2.0:
			p.vel.x *= -1.0
		if absf(p.pos.z) > 1.5:
			p.vel.z *= -1.0

		# Update worldline
		if i < _worldlines.size():
			_worldlines[i].append(p.pos)
			if _worldlines[i].size() > WORLDLINE_LEN:
				_worldlines[i].pop_front()

	# Check for annihilation (particle meets antiparticle)
	for i in range(_particles.size()):
		for j in range(i + 1, _particles.size()):
			if i >= _particles.size() or j >= _particles.size():
				break
			var pi: Dictionary = _particles[i]
			var pj: Dictionary = _particles[j]
			if pi.charge != pj.charge and pi.pos.distance_to(pj.pos) < 0.2:
				# Annihilation event — photon flash
				var mid: Vector3 = (pi.pos + pj.pos) * 0.5
				_annihilation_flashes.append({"pos": mid, "life": 0.6})
				# Remove higher index first
				_particles.remove_at(j)
				if j < _worldlines.size():
					_worldlines.remove_at(j)
				_particles.remove_at(i)
				if i < _worldlines.size():
					_worldlines.remove_at(i)
				break

	# Decay flashes
	for i in range(_annihilation_flashes.size() - 1, -1, -1):
		_annihilation_flashes[i].life -= dt
		if _annihilation_flashes[i].life <= 0:
			_annihilation_flashes.remove_at(i)


func _draw_particles() -> void:
	_particle_im.clear_surfaces()
	_particle_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	# Draw worldlines
	for wi in range(_worldlines.size()):
		if wi >= _particles.size():
			break
		var trail: Array = _worldlines[wi]
		var charge: int = _particles[wi].charge
		var base_col := COL_ELECTRON if charge < 0 else COL_POSITRON
		for ti in range(trail.size() - 1):
			var alpha := float(ti) / maxf(trail.size(), 1.0) * 0.6
			var col := base_col
			col.a = alpha
			_im_line_3d(_particle_im, trail[ti], trail[ti + 1], 0.01, col)

	# Draw particle positions as circles
	for p in _particles:
		var col := COL_ELECTRON if p.charge < 0 else COL_POSITRON
		var life_frac: float = p.life / p.max_life
		col.a = clampf(life_frac, 0.3, 0.9)
		_im_circle(_particle_im, p.pos + Vector3(0, 0.01, 0), 0.06, col, 8)
		# Charge indicator: + or - as tiny cross/dash
		if p.charge > 0:
			_im_line_3d(_particle_im, p.pos + Vector3(-0.03, 0.02, 0), p.pos + Vector3(0.03, 0.02, 0), 0.008, COL_VERTEX)
			_im_line_3d(_particle_im, p.pos + Vector3(0, -0.01, 0), p.pos + Vector3(0, 0.05, 0), 0.008, COL_VERTEX)
		else:
			_im_line_3d(_particle_im, p.pos + Vector3(-0.03, 0.02, 0), p.pos + Vector3(0.03, 0.02, 0), 0.008, COL_VERTEX)

	# Annihilation flashes — expanding rings
	for flash in _annihilation_flashes:
		var frac: float = 1.0 - flash.life / 0.6
		var r: float = 0.05 + frac * 0.3
		var fc := COL_FLASH
		fc.a = (1.0 - frac) * 0.8
		_im_circle(_particle_im, flash.pos + Vector3(0, 0.02, 0), r, fc, 12)
		# Photon wavy lines emanating from flash (two directions)
		if frac < 0.8:
			var wave_len: float = frac * 1.0
			_draw_wavy_line(_particle_im, flash.pos, flash.pos + Vector3(wave_len, 0.3 * frac, 0), 6, 0.05, COL_PHOTON)
			_draw_wavy_line(_particle_im, flash.pos, flash.pos + Vector3(-wave_len, 0.3 * frac, 0), 6, 0.05, COL_PHOTON)

	_particle_im.surface_end()

	# Draw creation/annihilation count overlay
	_overlay_im.clear_surfaces()
	_overlay_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	# Boundary box
	_im_line_3d(_overlay_im, Vector3(-2.0, 0, -1.5), Vector3(2.0, 0, -1.5), 0.008, COL_GRID)
	_im_line_3d(_overlay_im, Vector3(2.0, 0, -1.5), Vector3(2.0, 0, 1.5), 0.008, COL_GRID)
	_im_line_3d(_overlay_im, Vector3(2.0, 0, 1.5), Vector3(-2.0, 0, 1.5), 0.008, COL_GRID)
	_im_line_3d(_overlay_im, Vector3(-2.0, 0, 1.5), Vector3(-2.0, 0, -1.5), 0.008, COL_GRID)

	_overlay_im.surface_end()


# =========================================================================
# Feynman diagrams (FEYNMAN mode)
# =========================================================================

func _draw_feynman() -> void:
	_diagram_im.clear_surfaces()
	_diagram_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	_overlay_im.clear_surfaces()
	_overlay_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	var anim := clampf(_diagram_anim, 0.0, 3.0)

	match _diagram:
		Diagram.QED_SCATTER:
			_draw_qed_scatter(anim)
		Diagram.PAIR_PRODUCTION:
			_draw_pair_production(anim)
		Diagram.GLUON_LOOP:
			_draw_gluon_loop(anim)
		Diagram.COMPTON:
			_draw_compton(anim)

	# Diagram frame
	_im_quad(_overlay_im,
		Vector3(-2.0, -1.2, -0.01), Vector3(2.0, -1.2, -0.01),
		Vector3(2.0, 1.8, -0.01), Vector3(-2.0, 1.8, -0.01),
		Color(0.05, 0.05, 0.12, 0.3))

	# Time arrow at bottom
	_im_line_3d(_overlay_im, Vector3(-1.8, -1.0, 0.01), Vector3(1.8, -1.0, 0.01), 0.01, COL_GRID)
	# Arrowhead
	_im_triangle(_overlay_im,
		Vector3(1.8, -1.0, 0.01),
		Vector3(1.7, -0.95, 0.01),
		Vector3(1.7, -1.05, 0.01), COL_GRID)

	_diagram_im.surface_end()
	_overlay_im.surface_end()


func _draw_qed_scatter(anim: float) -> void:
	# e⁻ + e⁻ → e⁻ + e⁻ (Møller scattering via virtual photon)
	var cx := 0.0
	var cy := 0.3
	var span := 1.5

	# Incoming electrons (solid lines with arrows)
	var in1_start := Vector3(cx - span, cy + 0.6, 0)
	var in1_end := Vector3(cx - 0.15, cy + 0.15, 0)
	var in2_start := Vector3(cx - span, cy - 0.6, 0)
	var in2_end := Vector3(cx - 0.15, cy - 0.15, 0)

	var prog1 := clampf(anim / 1.0, 0.0, 1.0)
	_draw_fermion_line(_diagram_im, in1_start, in1_start.lerp(in1_end, prog1), COL_ELECTRON, prog1)
	_draw_fermion_line(_diagram_im, in2_start, in2_start.lerp(in2_end, prog1), COL_ELECTRON, prog1)

	# Vertices
	if anim > 0.8:
		_im_circle(_diagram_im, in1_end, 0.04, COL_VERTEX, 8)
		_im_circle(_diagram_im, in2_end, 0.04, COL_VERTEX, 8)

	# Virtual photon (wavy line between vertices)
	if anim > 1.0:
		var photon_prog := clampf((anim - 1.0) / 0.8, 0.0, 1.0)
		var p_start := Vector3(cx - 0.15, cy + 0.15, 0)
		var p_end_t := p_start.lerp(Vector3(cx - 0.15, cy - 0.15, 0), photon_prog)
		_draw_wavy_line(_diagram_im, p_start, p_end_t, 8, 0.06, COL_PHOTON)

	# Outgoing electrons
	if anim > 1.8:
		var out_prog := clampf((anim - 1.8) / 1.0, 0.0, 1.0)
		var out1_start := Vector3(cx - 0.15, cy + 0.15, 0)
		var out1_end := Vector3(cx + span, cy + 0.6, 0)
		var out2_start := Vector3(cx - 0.15, cy - 0.15, 0)
		var out2_end := Vector3(cx + span, cy - 0.6, 0)
		_draw_fermion_line(_diagram_im, out1_start, out1_start.lerp(out1_end, out_prog), COL_ELECTRON, out_prog)
		_draw_fermion_line(_diagram_im, out2_start, out2_start.lerp(out2_end, out_prog), COL_ELECTRON, out_prog)


func _draw_pair_production(anim: float) -> void:
	# γ → e⁺ + e⁻ (pair production near nucleus)
	var cx := 0.0
	var cy := 0.3
	var span := 1.5

	# Incoming photon
	var photon_start := Vector3(cx - span, cy, 0)
	var vertex := Vector3(cx, cy, 0)
	var prog1 := clampf(anim / 1.2, 0.0, 1.0)
	_draw_wavy_line(_diagram_im, photon_start, photon_start.lerp(vertex, prog1), 10, 0.08, COL_PHOTON)

	# Vertex
	if anim > 1.0:
		_im_circle(_diagram_im, vertex, 0.05, COL_VERTEX, 10)

	# Outgoing e⁻ and e⁺
	if anim > 1.2:
		var out_prog := clampf((anim - 1.2) / 1.2, 0.0, 1.0)
		var e_end := Vector3(cx + span, cy + 0.7, 0)
		var p_end := Vector3(cx + span, cy - 0.7, 0)
		_draw_fermion_line(_diagram_im, vertex, vertex.lerp(e_end, out_prog), COL_ELECTRON, out_prog)
		_draw_fermion_line(_diagram_im, vertex, vertex.lerp(p_end, out_prog), COL_POSITRON, out_prog)

	# Nucleus (heavy line at bottom — virtual photon source)
	if anim > 0.5:
		var nuc_col := COL_PROPAGATOR
		nuc_col.a = 0.4
		_im_line_3d(_diagram_im, Vector3(cx - 0.5, cy - 1.0, 0), Vector3(cx + 0.5, cy - 1.0, 0), 0.03, nuc_col)
		# Virtual photon to vertex
		_draw_wavy_line(_diagram_im, Vector3(cx, cy - 1.0, 0), vertex, 6, 0.04,
			Color(COL_PHOTON.r, COL_PHOTON.g, COL_PHOTON.b, 0.35))


func _draw_gluon_loop(anim: float) -> void:
	# Gluon self-energy loop (one-loop correction)
	var cx := 0.0
	var cy := 0.3
	var span := 1.5

	# Incoming gluon
	var in_start := Vector3(cx - span, cy, 0)
	var loop_left := Vector3(cx - 0.5, cy, 0)
	var prog1 := clampf(anim / 0.8, 0.0, 1.0)
	_draw_curly_line(_diagram_im, in_start, in_start.lerp(loop_left, prog1), 12, 0.06, COL_GLUON)

	# Loop (two gluon arcs forming a circle)
	if anim > 0.8:
		var loop_prog := clampf((anim - 0.8) / 1.2, 0.0, 1.0)
		var loop_center := Vector3(cx, cy, 0)
		var loop_r := 0.45
		var segs := int(loop_prog * 20)
		for si in range(segs):
			var a0 := TAU * float(si) / 20.0
			var a1 := TAU * float(si + 1) / 20.0
			var p0 := loop_center + Vector3(cos(a0), sin(a0), 0) * loop_r
			var p1 := loop_center + Vector3(cos(a1), sin(a1), 0) * loop_r
			_im_line_3d(_diagram_im, p0, p1, 0.018, COL_GLUON)

		# Vertices at loop entry/exit
		_im_circle(_diagram_im, loop_left, 0.04, COL_VERTEX, 8)
		_im_circle(_diagram_im, Vector3(cx + 0.5, cy, 0), 0.04, COL_VERTEX, 8)

	# Outgoing gluon
	if anim > 2.0:
		var out_prog := clampf((anim - 2.0) / 0.8, 0.0, 1.0)
		var loop_right := Vector3(cx + 0.5, cy, 0)
		var out_end := Vector3(cx + span, cy, 0)
		_draw_curly_line(_diagram_im, loop_right, loop_right.lerp(out_end, out_prog), 12, 0.06, COL_GLUON)


func _draw_compton(anim: float) -> void:
	# Compton scattering: e⁻ + γ → e⁻ + γ
	var cx := 0.0
	var cy := 0.3
	var span := 1.5

	var v1 := Vector3(cx - 0.5, cy, 0)
	var v2 := Vector3(cx + 0.5, cy, 0)

	# Incoming electron
	var prog1 := clampf(anim / 0.8, 0.0, 1.0)
	var in_e := Vector3(cx - span, cy - 0.3, 0)
	_draw_fermion_line(_diagram_im, in_e, in_e.lerp(v1, prog1), COL_ELECTRON, prog1)

	# Incoming photon
	var in_g := Vector3(cx - span, cy + 0.8, 0)
	_draw_wavy_line(_diagram_im, in_g, in_g.lerp(v1, prog1), 8, 0.06, COL_PHOTON)

	# Vertices
	if anim > 0.6:
		_im_circle(_diagram_im, v1, 0.04, COL_VERTEX, 8)
		_im_circle(_diagram_im, v2, 0.04, COL_VERTEX, 8)

	# Internal electron propagator
	if anim > 0.8:
		var mid_prog := clampf((anim - 0.8) / 0.8, 0.0, 1.0)
		_draw_fermion_line(_diagram_im, v1, v1.lerp(v2, mid_prog), COL_PROPAGATOR, mid_prog)

	# Outgoing electron and photon
	if anim > 1.6:
		var out_prog := clampf((anim - 1.6) / 1.0, 0.0, 1.0)
		var out_e := Vector3(cx + span, cy - 0.3, 0)
		var out_g := Vector3(cx + span, cy + 0.8, 0)
		_draw_fermion_line(_diagram_im, v2, v2.lerp(out_e, out_prog), COL_ELECTRON, out_prog)
		_draw_wavy_line(_diagram_im, v2, v2.lerp(out_g, out_prog), 8, 0.06, COL_PHOTON)


# =========================================================================
# Feynman diagram line helpers
# =========================================================================

func _draw_fermion_line(im: ImmediateMesh, from: Vector3, to: Vector3, col: Color, _progress: float) -> void:
	# Solid line with arrowhead
	_im_line_3d(im, from, to, 0.015, col)
	# Arrow at midpoint
	var mid := (from + to) * 0.5
	var dir := (to - from).normalized()
	var perp := Vector3(-dir.z, 0, dir.x) if dir.length() > 0.01 else Vector3.UP
	var arrow_size := 0.04
	_im_triangle(im,
		mid + dir * arrow_size,
		mid - dir * arrow_size * 0.5 + perp * arrow_size * 0.5,
		mid - dir * arrow_size * 0.5 - perp * arrow_size * 0.5, col)


func _draw_wavy_line(im: ImmediateMesh, from: Vector3, to: Vector3, waves: int, amp: float, col: Color) -> void:
	# Photon propagator — sinusoidal
	var dir := to - from
	var length := dir.length()
	if length < 0.01:
		return
	var tangent := dir.normalized()
	var normal := Vector3(-tangent.z, tangent.y, tangent.x)
	if normal.length_squared() < 0.01:
		normal = Vector3(0, 1, 0)
	normal = normal.normalized()
	var segs := waves * 4
	for i in range(segs):
		var t0 := float(i) / segs
		var t1 := float(i + 1) / segs
		var wave0 := sin(t0 * waves * TAU) * amp
		var wave1 := sin(t1 * waves * TAU) * amp
		var p0 := from + tangent * (t0 * length) + normal * wave0
		var p1 := from + tangent * (t1 * length) + normal * wave1
		_im_line_3d(im, p0, p1, 0.01, col)


func _draw_curly_line(im: ImmediateMesh, from: Vector3, to: Vector3, curls: int, amp: float, col: Color) -> void:
	# Gluon propagator — corkscrew/curly pattern
	var dir := to - from
	var length := dir.length()
	if length < 0.01:
		return
	var tangent := dir.normalized()
	var normal := Vector3(-tangent.z, tangent.y, tangent.x)
	if normal.length_squared() < 0.01:
		normal = Vector3(0, 1, 0)
	normal = normal.normalized()
	var segs := curls * 6
	for i in range(segs):
		var t0 := float(i) / segs
		var t1 := float(i + 1) / segs
		# Half-circle loops (curly appearance)
		var angle0 := t0 * curls * TAU
		var angle1 := t1 * curls * TAU
		var offset0 := sin(angle0) * amp
		var offset1 := sin(angle1) * amp
		# Add a second harmonic for curliness
		offset0 += sin(angle0 * 2.0) * amp * 0.3
		offset1 += sin(angle1 * 2.0) * amp * 0.3
		var p0 := from + tangent * (t0 * length) + normal * offset0
		var p1 := from + tangent * (t1 * length) + normal * offset1
		_im_line_3d(im, p0, p1, 0.012, col)


# =========================================================================
# Labels
# =========================================================================

func _update_labels() -> void:
	match _mode:
		Mode.FIELD:
			_title_label.text = "Quantum Field — φ⁴ Theory"
			var energy := _compute_field_energy()
			_info_label.text = "V(φ) = ½m²φ² + ¼λφ⁴  |  E = %.2f" % energy
			_state_label.text = "λ = %.2f  m = %.2f  |  %d×%d lattice" % [coupling_lambda, mass_param, grid_res, grid_res]
		Mode.PARTICLES:
			_title_label.text = "Particle Creation & Annihilation"
			var n_elec := 0
			var n_posi := 0
			for p in _particles:
				if p.charge < 0:
					n_elec += 1
				else:
					n_posi += 1
			_info_label.text = "e⁻: %d  e⁺: %d  |  pairs: %d" % [n_elec, n_posi, mini(n_elec, n_posi)]
			_state_label.text = "Pair creation from vacuum  |  charge conservation"
		Mode.FEYNMAN:
			_title_label.text = "Feynman Diagram"
			_info_label.text = DIAGRAM_NAMES[_diagram]
			_state_label.text = "→ solid: fermion  ∿ wavy: photon  ⌇ curly: gluon"


func _compute_field_energy() -> float:
	var energy := 0.0
	var n := grid_res
	var m2 := mass_param * mass_param
	var lam := coupling_lambda
	for iz in range(n):
		for ix in range(n):
			var idx := iz * n + ix
			var p: float = _phi[idx]
			var pd: float = _phi_dot[idx]
			# Kinetic + potential energy density
			energy += 0.5 * pd * pd + 0.5 * m2 * p * p + 0.25 * lam * p * p * p * p
	return energy / float(n * n)


# =========================================================================
# ImmediateMesh drawing helpers
# =========================================================================

func _im_quad(im: ImmediateMesh, a: Vector3, b: Vector3, c: Vector3, d: Vector3, col: Color) -> void:
	im.surface_set_color(col)
	im.surface_set_normal(Vector3.FORWARD)
	im.surface_add_vertex(a)
	im.surface_add_vertex(b)
	im.surface_add_vertex(c)
	im.surface_add_vertex(a)
	im.surface_add_vertex(c)
	im.surface_add_vertex(d)


func _im_triangle(im: ImmediateMesh, a: Vector3, b: Vector3, c: Vector3, col: Color) -> void:
	im.surface_set_color(col)
	im.surface_set_normal(Vector3.FORWARD)
	im.surface_add_vertex(a)
	im.surface_add_vertex(b)
	im.surface_add_vertex(c)


func _im_tri_colored(im: ImmediateMesh, a: Vector3, ca: Color, b: Vector3, cb: Color, c: Vector3, cc: Color) -> void:
	im.surface_set_normal(Vector3.FORWARD)
	im.surface_set_color(ca)
	im.surface_add_vertex(a)
	im.surface_set_color(cb)
	im.surface_add_vertex(b)
	im.surface_set_color(cc)
	im.surface_add_vertex(c)


func _im_circle(im: ImmediateMesh, center: Vector3, radius: float, col: Color, segs: int) -> void:
	for i in range(segs):
		var a0 := TAU * i / segs
		var a1 := TAU * (i + 1) / segs
		im.surface_set_color(col)
		im.surface_set_normal(Vector3.UP)
		im.surface_add_vertex(center)
		im.surface_add_vertex(center + Vector3(cos(a0), 0, sin(a0)) * radius)
		im.surface_add_vertex(center + Vector3(cos(a1), 0, sin(a1)) * radius)


func _im_line_3d(im: ImmediateMesh, from: Vector3, to: Vector3, width: float, col: Color) -> void:
	var dir := (to - from).normalized()
	var perp := dir.cross(Vector3.UP)
	if perp.length_squared() < 0.001:
		perp = dir.cross(Vector3.RIGHT)
	perp = perp.normalized() * width * 0.5
	im.surface_set_color(col)
	im.surface_set_normal((dir.cross(perp)).normalized())
	im.surface_add_vertex(from - perp)
	im.surface_add_vertex(to - perp)
	im.surface_add_vertex(to + perp)
	im.surface_add_vertex(from - perp)
	im.surface_add_vertex(to + perp)
	im.surface_add_vertex(from + perp)


# =========================================================================
# apply_grid_config
# =========================================================================

func apply_grid_config(config: Dictionary) -> void:
	if config.has("grid_res"):
		grid_res = clampi(int(config["grid_res"]), 8, 64)
	if config.has("field_spacing"):
		field_spacing = clampf(float(config["field_spacing"]), 0.05, 0.5)
	if config.has("step_speed"):
		step_speed = clampf(float(config["step_speed"]), 0.1, 5.0)
	if config.has("vacuum_strength"):
		vacuum_strength = clampf(float(config["vacuum_strength"]), 0.0, 1.0)
	if config.has("coupling_lambda"):
		coupling_lambda = clampf(float(config["coupling_lambda"]), 0.0, 2.0)
	if config.has("mass_param"):
		mass_param = clampf(float(config["mass_param"]), 0.1, 3.0)
	if config.has("mode"):
		var m := str(config["mode"]).to_upper()
		match m:
			"FIELD": _mode = Mode.FIELD
			"PARTICLES": _mode = Mode.PARTICLES
			"FEYNMAN": _mode = Mode.FEYNMAN
	if config.has("diagram"):
		var d := str(config["diagram"]).to_upper()
		match d:
			"QED_SCATTER": _diagram = Diagram.QED_SCATTER
			"PAIR_PRODUCTION": _diagram = Diagram.PAIR_PRODUCTION
			"GLUON_LOOP": _diagram = Diagram.GLUON_LOOP
			"COMPTON": _diagram = Diagram.COMPTON
	_init_mode()


# =========================================================================
# Cleanup
# =========================================================================

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()
