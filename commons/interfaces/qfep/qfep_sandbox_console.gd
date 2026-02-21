# qfep_sandbox_console.gd
# Full QFEP parameter control panel
# Combines lambda slider, phi slider, F meter, E(S) meter, and real-time visualization
# Find the edge of chaos. You have earned the force.

extends Node3D

class_name QFEPSandboxConsole

signal lambda_changed(value: float)
signal phi_changed(value: float)
signal regime_changed(regime: String)

## QFEP Parameters
@export var lambda: float = 0.4:
	set(v):
		lambda = clampf(v, 0.0, 1.0)
		_update_all()
		lambda_changed.emit(lambda)

@export var phi: float = 0.5:
	set(v):
		phi = clampf(v, 0.0, 1.0)
		_update_all()
		phi_changed.emit(phi)

## Console layout
@export var panel_width: float = 2.0
@export var panel_height: float = 1.5

# QFEP Colors
const COLOR_ORDER := Color(0.15, 0.25, 0.85)
const COLOR_EDGE := Color(0.2, 1.0, 0.45)
const COLOR_CHAOS := Color(0.95, 0.15, 0.1)

# Computed QFEP values
var _free_energy: float = 0.0  # F = E - λS
var _entropy: float = 0.0      # S = f(lambda)
var _energy: float = 0.0       # E = cost of current config
var _surprise: float = 0.0     # E(S) = expected surprise
var _current_regime: String = ""

# VR interactables
const PUSH_BUTTON = preload("res://commons/interactables/push_button.tscn")
const SLIDER_HORIZONTAL = preload("res://commons/interactables/slider_horizontal.tscn")

# Visual components
var _panel_mesh: MeshInstance3D
var _lambda_bar: MeshInstance3D
var _lambda_bar_mat: StandardMaterial3D
var _phi_bar: MeshInstance3D
var _phi_bar_mat: StandardMaterial3D
var _f_meter: MeshInstance3D
var _f_meter_mat: StandardMaterial3D
var _es_meter: MeshInstance3D
var _es_meter_mat: StandardMaterial3D
var _regime_label: Label3D
var _values_label: Label3D
var _title_label: Label3D
var _formula_label: Label3D
var _particles: GPUParticles3D
var _orb_mesh: MeshInstance3D
var _orb_mat: StandardMaterial3D
var _time: float = 0.0

func _ready() -> void:
	_build_console_panel()
	_build_lambda_control()
	_build_phi_control()
	_build_meters()
	_build_mini_orb()
	_build_labels()
	_build_vr_controls()
	_compute_qfep()
	_update_all()

	add_to_group("qfep_lambda_controllers")
	add_to_group("qfep_phi_controllers")
	add_to_group("qfep_reactive")

	print("QFEPSandboxConsole: F = E - λS | Find the edge of chaos")

# ---------------------------------------------------------------------------
# Console panel — dark backing
# ---------------------------------------------------------------------------

func _build_console_panel() -> void:
	_panel_mesh = MeshInstance3D.new()
	_panel_mesh.name = "ConsolePanel"
	var box := BoxMesh.new()
	box.size = Vector3(panel_width, panel_height, 0.05)
	_panel_mesh.mesh = box
	_panel_mesh.position = Vector3(0, panel_height / 2.0, 0)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.03, 0.05, 0.08, 0.92)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.metallic = 0.1
	mat.roughness = 0.9
	_panel_mesh.material_override = mat
	add_child(_panel_mesh)

	# Border glow
	var border := MeshInstance3D.new()
	var border_box := BoxMesh.new()
	border_box.size = Vector3(panel_width + 0.02, panel_height + 0.02, 0.04)
	border.mesh = border_box
	border.position = Vector3(0, panel_height / 2.0, -0.005)

	var border_mat := StandardMaterial3D.new()
	border_mat.albedo_color = Color(0.1, 0.3, 0.6, 0.4)
	border_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	border_mat.emission_enabled = true
	border_mat.emission = Color(0.15, 0.4, 0.8)
	border_mat.emission_energy_multiplier = 0.5
	border.material_override = border_mat
	add_child(border)

# ---------------------------------------------------------------------------
# Lambda control bar
# ---------------------------------------------------------------------------

func _build_lambda_control() -> void:
	var bar_width: float = panel_width * 0.7
	var bar_y: float = panel_height * 0.75

	# Background track
	var track := MeshInstance3D.new()
	var track_mesh := BoxMesh.new()
	track_mesh.size = Vector3(bar_width, 0.04, 0.03)
	track.mesh = track_mesh
	track.position = Vector3(0, bar_y, 0.03)
	var track_mat := StandardMaterial3D.new()
	track_mat.albedo_color = Color(0.15, 0.15, 0.2)
	track.material_override = track_mat
	add_child(track)

	# Lambda fill bar
	_lambda_bar = MeshInstance3D.new()
	_lambda_bar.name = "LambdaBar"
	var fill_mesh := BoxMesh.new()
	fill_mesh.size = Vector3(bar_width * lambda, 0.035, 0.035)
	_lambda_bar.mesh = fill_mesh
	_lambda_bar.position = Vector3(-bar_width * (1.0 - lambda) / 2.0, bar_y, 0.035)

	_lambda_bar_mat = StandardMaterial3D.new()
	_lambda_bar_mat.albedo_color = COLOR_EDGE
	_lambda_bar_mat.emission_enabled = true
	_lambda_bar_mat.emission = COLOR_EDGE
	_lambda_bar_mat.emission_energy_multiplier = 0.8
	_lambda_bar.material_override = _lambda_bar_mat
	add_child(_lambda_bar)

	# Lambda label
	var lbl := Label3D.new()
	lbl.text = "λ  Lambda (entropy drive)"
	lbl.font_size = 16
	lbl.position = Vector3(-bar_width / 2.0, bar_y + 0.06, 0.04)
	lbl.modulate = Color(0.7, 0.8, 0.9)
	lbl.outline_size = 2
	lbl.outline_modulate = Color.BLACK
	add_child(lbl)

# ---------------------------------------------------------------------------
# Phi control bar
# ---------------------------------------------------------------------------

func _build_phi_control() -> void:
	var bar_width: float = panel_width * 0.7
	var bar_y: float = panel_height * 0.55

	var track := MeshInstance3D.new()
	var track_mesh := BoxMesh.new()
	track_mesh.size = Vector3(bar_width, 0.04, 0.03)
	track.mesh = track_mesh
	track.position = Vector3(0, bar_y, 0.03)
	var track_mat := StandardMaterial3D.new()
	track_mat.albedo_color = Color(0.15, 0.15, 0.2)
	track.material_override = track_mat
	add_child(track)

	_phi_bar = MeshInstance3D.new()
	_phi_bar.name = "PhiBar"
	var fill_mesh := BoxMesh.new()
	fill_mesh.size = Vector3(bar_width * phi, 0.035, 0.035)
	_phi_bar.mesh = fill_mesh
	_phi_bar.position = Vector3(-bar_width * (1.0 - phi) / 2.0, bar_y, 0.035)

	_phi_bar_mat = StandardMaterial3D.new()
	_phi_bar_mat.albedo_color = Color(0.8, 0.5, 1.0)
	_phi_bar_mat.emission_enabled = true
	_phi_bar_mat.emission = Color(0.8, 0.5, 1.0)
	_phi_bar_mat.emission_energy_multiplier = 0.6
	_phi_bar.material_override = _phi_bar_mat
	add_child(_phi_bar)

	var lbl := Label3D.new()
	lbl.text = "φ  Phi (integrated information)"
	lbl.font_size = 16
	lbl.position = Vector3(-bar_width / 2.0, bar_y + 0.06, 0.04)
	lbl.modulate = Color(0.8, 0.7, 1.0)
	lbl.outline_size = 2
	lbl.outline_modulate = Color.BLACK
	add_child(lbl)

# ---------------------------------------------------------------------------
# F and E(S) meters
# ---------------------------------------------------------------------------

func _build_meters() -> void:
	var meter_width: float = panel_width * 0.3
	var meter_y: float = panel_height * 0.25

	# F meter (Free Energy)
	_f_meter = MeshInstance3D.new()
	_f_meter.name = "FMeter"
	var f_mesh := BoxMesh.new()
	f_mesh.size = Vector3(meter_width, 0.12, 0.03)
	_f_meter.mesh = f_mesh
	_f_meter.position = Vector3(-panel_width * 0.2, meter_y, 0.035)
	_f_meter_mat = StandardMaterial3D.new()
	_f_meter_mat.albedo_color = Color(0.2, 0.6, 1.0)
	_f_meter_mat.emission_enabled = true
	_f_meter_mat.emission = Color(0.2, 0.6, 1.0)
	_f_meter_mat.emission_energy_multiplier = 0.5
	_f_meter.material_override = _f_meter_mat
	add_child(_f_meter)

	var f_label := Label3D.new()
	f_label.text = "F = E - λS"
	f_label.font_size = 14
	f_label.position = Vector3(-panel_width * 0.2, meter_y + 0.1, 0.04)
	f_label.modulate = Color(0.6, 0.8, 1.0)
	f_label.outline_size = 2
	f_label.outline_modulate = Color.BLACK
	add_child(f_label)

	# E(S) meter (Expected Surprise)
	_es_meter = MeshInstance3D.new()
	_es_meter.name = "ESMeter"
	var es_mesh := BoxMesh.new()
	es_mesh.size = Vector3(meter_width, 0.12, 0.03)
	_es_meter.mesh = es_mesh
	_es_meter.position = Vector3(panel_width * 0.2, meter_y, 0.035)
	_es_meter_mat = StandardMaterial3D.new()
	_es_meter_mat.albedo_color = Color(1.0, 0.6, 0.2)
	_es_meter_mat.emission_enabled = true
	_es_meter_mat.emission = Color(1.0, 0.6, 0.2)
	_es_meter_mat.emission_energy_multiplier = 0.5
	_es_meter.material_override = _es_meter_mat
	add_child(_es_meter)

	var es_label := Label3D.new()
	es_label.text = "E(S) surprise"
	es_label.font_size = 14
	es_label.position = Vector3(panel_width * 0.2, meter_y + 0.1, 0.04)
	es_label.modulate = Color(1.0, 0.8, 0.6)
	es_label.outline_size = 2
	es_label.outline_modulate = Color.BLACK
	add_child(es_label)

# ---------------------------------------------------------------------------
# Mini orb — small state indicator
# ---------------------------------------------------------------------------

func _build_mini_orb() -> void:
	_orb_mesh = MeshInstance3D.new()
	_orb_mesh.name = "MiniOrb"
	var sphere := SphereMesh.new()
	sphere.radius = 0.08
	sphere.height = 0.16
	_orb_mesh.mesh = sphere
	_orb_mesh.position = Vector3(0, panel_height * 0.25, 0.06)

	_orb_mat = StandardMaterial3D.new()
	_orb_mat.albedo_color = COLOR_EDGE
	_orb_mat.emission_enabled = true
	_orb_mat.emission = COLOR_EDGE
	_orb_mat.emission_energy_multiplier = 2.0
	_orb_mesh.material_override = _orb_mat
	add_child(_orb_mesh)

	# Particles around orb
	_particles = GPUParticles3D.new()
	_particles.amount = 30
	_particles.lifetime = 1.5
	_particles.position = _orb_mesh.position

	var pmat := ParticleProcessMaterial.new()
	pmat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pmat.emission_sphere_radius = 0.1
	pmat.direction = Vector3(0, 1, 0)
	pmat.spread = 180.0
	pmat.initial_velocity_min = 0.02
	pmat.initial_velocity_max = 0.08
	pmat.gravity = Vector3.ZERO
	_particles.process_material = pmat

	var pmesh := SphereMesh.new()
	pmesh.radius = 0.006
	pmesh.height = 0.012
	_particles.draw_pass_1 = pmesh
	add_child(_particles)

# ---------------------------------------------------------------------------
# Labels
# ---------------------------------------------------------------------------

func _build_labels() -> void:
	_title_label = Label3D.new()
	_title_label.text = "QFEP SANDBOX"
	_title_label.font_size = 24
	_title_label.position = Vector3(0, panel_height - 0.05, 0.04)
	_title_label.modulate = Color.WHITE
	_title_label.outline_size = 4
	_title_label.outline_modulate = Color.BLACK
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_title_label)

	_formula_label = Label3D.new()
	_formula_label.text = "F = E - λS   |   minimize surprise"
	_formula_label.font_size = 14
	_formula_label.position = Vector3(0, panel_height - 0.15, 0.04)
	_formula_label.modulate = Color(0.6, 0.7, 0.85)
	_formula_label.outline_size = 2
	_formula_label.outline_modulate = Color.BLACK
	_formula_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_formula_label)

	_values_label = Label3D.new()
	_values_label.text = ""
	_values_label.font_size = 16
	_values_label.position = Vector3(0, panel_height * 0.1, 0.04)
	_values_label.modulate = Color.WHITE
	_values_label.outline_size = 3
	_values_label.outline_modulate = Color.BLACK
	_values_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_values_label)

	_regime_label = Label3D.new()
	_regime_label.text = ""
	_regime_label.font_size = 20
	_regime_label.position = Vector3(0, 0.05, 0.04)
	_regime_label.modulate = COLOR_EDGE
	_regime_label.outline_size = 4
	_regime_label.outline_modulate = Color.BLACK
	_regime_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_regime_label)

# ---------------------------------------------------------------------------
# VR Controls
# ---------------------------------------------------------------------------

func _build_vr_controls() -> void:
	# Lambda up/down buttons
	if PUSH_BUTTON:
		var btn_lambda_up := PUSH_BUTTON.instantiate()
		btn_lambda_up.name = "LambdaUp"
		btn_lambda_up.position = Vector3(panel_width * 0.42, panel_height * 0.75, 0.05)
		btn_lambda_up.scale = Vector3(0.3, 0.3, 0.3)
		add_child(btn_lambda_up)
		if btn_lambda_up.has_signal("button_pressed"):
			btn_lambda_up.button_pressed.connect(func(_b): lambda = clampf(lambda + 0.05, 0.0, 1.0))

		var btn_lambda_down := PUSH_BUTTON.instantiate()
		btn_lambda_down.name = "LambdaDown"
		btn_lambda_down.position = Vector3(-panel_width * 0.42, panel_height * 0.75, 0.05)
		btn_lambda_down.scale = Vector3(0.3, 0.3, 0.3)
		add_child(btn_lambda_down)
		if btn_lambda_down.has_signal("button_pressed"):
			btn_lambda_down.button_pressed.connect(func(_b): lambda = clampf(lambda - 0.05, 0.0, 1.0))

		# Phi up/down buttons
		var btn_phi_up := PUSH_BUTTON.instantiate()
		btn_phi_up.name = "PhiUp"
		btn_phi_up.position = Vector3(panel_width * 0.42, panel_height * 0.55, 0.05)
		btn_phi_up.scale = Vector3(0.3, 0.3, 0.3)
		add_child(btn_phi_up)
		if btn_phi_up.has_signal("button_pressed"):
			btn_phi_up.button_pressed.connect(func(_b): phi = clampf(phi + 0.05, 0.0, 1.0))

		var btn_phi_down := PUSH_BUTTON.instantiate()
		btn_phi_down.name = "PhiDown"
		btn_phi_down.position = Vector3(-panel_width * 0.42, panel_height * 0.55, 0.05)
		btn_phi_down.scale = Vector3(0.3, 0.3, 0.3)
		add_child(btn_phi_down)
		if btn_phi_down.has_signal("button_pressed"):
			btn_phi_down.button_pressed.connect(func(_b): phi = clampf(phi - 0.05, 0.0, 1.0))

		# Reset button
		var btn_reset := PUSH_BUTTON.instantiate()
		btn_reset.name = "ResetBtn"
		btn_reset.position = Vector3(panel_width * 0.35, 0.05, 0.05)
		btn_reset.scale = Vector3(0.3, 0.3, 0.3)
		add_child(btn_reset)
		if btn_reset.has_signal("button_pressed"):
			btn_reset.button_pressed.connect(func(_b): _reset_to_edge())

# ---------------------------------------------------------------------------
# QFEP Computation
# ---------------------------------------------------------------------------

func _compute_qfep() -> void:
	# Entropy: increases with lambda
	_entropy = lambda * lambda * 2.0  # S ∈ [0, 2]

	# Energy: cost of maintaining pattern — low at extremes, high at edge
	# Bell curve peaked at edge of chaos
	var edge_dist: float = absf(lambda - 0.4)
	_energy = 1.0 - exp(-edge_dist * edge_dist / 0.05)

	# Free energy: F = E - λS
	_free_energy = _energy - lambda * _entropy

	# Expected surprise: decreases as phi increases (more integration = less surprise)
	_surprise = (1.0 - phi) * _entropy * 0.8

func _update_all() -> void:
	_compute_qfep()

	var color := _get_regime_color()
	var regime := _get_regime_name()

	# Update bars
	var bar_width: float = panel_width * 0.7
	if _lambda_bar and _lambda_bar.mesh:
		(_lambda_bar.mesh as BoxMesh).size.x = maxf(bar_width * lambda, 0.01)
		_lambda_bar.position.x = -bar_width * (1.0 - lambda) / 2.0
	if _lambda_bar_mat:
		_lambda_bar_mat.albedo_color = color
		_lambda_bar_mat.emission = color

	if _phi_bar and _phi_bar.mesh:
		(_phi_bar.mesh as BoxMesh).size.x = maxf(bar_width * phi, 0.01)
		_phi_bar.position.x = -bar_width * (1.0 - phi) / 2.0

	# Update meters
	var meter_width: float = panel_width * 0.3
	if _f_meter and _f_meter.mesh:
		var f_norm: float = clampf((_free_energy + 1.0) / 2.0, 0.05, 1.0)
		(_f_meter.mesh as BoxMesh).size.x = meter_width * f_norm
	if _es_meter and _es_meter.mesh:
		var s_norm: float = clampf(_surprise / 1.5, 0.05, 1.0)
		(_es_meter.mesh as BoxMesh).size.x = meter_width * s_norm

	# Update orb
	if _orb_mat:
		_orb_mat.albedo_color = color
		_orb_mat.emission = color

	# Update labels
	if _values_label:
		_values_label.text = "F=%.2f  S=%.2f  E=%.2f  E(S)=%.2f" % [_free_energy, _entropy, _energy, _surprise]
		_values_label.modulate = color

	if _regime_label:
		_regime_label.text = regime
		_regime_label.modulate = color

	if regime != _current_regime:
		_current_regime = regime
		regime_changed.emit(regime)

func _get_regime_color() -> Color:
	if lambda < 0.2:
		return COLOR_ORDER
	elif lambda < 0.35:
		return COLOR_ORDER.lerp(COLOR_EDGE, (lambda - 0.2) / 0.15)
	elif lambda <= 0.5:
		return COLOR_EDGE
	elif lambda < 0.7:
		return COLOR_EDGE.lerp(COLOR_CHAOS, (lambda - 0.5) / 0.2)
	else:
		return COLOR_CHAOS

func _get_regime_name() -> String:
	if lambda < 0.2:
		return "FROZEN — pure order"
	elif lambda < 0.35:
		return "CRYSTALLIZING — approaching edge"
	elif lambda <= 0.5:
		if phi > 0.5:
			return "EDGE OF CHAOS — φ HIGH — ALIVE"
		else:
			return "EDGE OF CHAOS — increase φ!"
	elif lambda < 0.7:
		return "TURBULENT — too much entropy"
	else:
		return "DISSOLVED — pure chaos"

func _reset_to_edge() -> void:
	lambda = 0.4
	phi = 0.5

func _process(delta: float) -> void:
	_time += delta

	# Keyboard fallback
	if Input.is_key_pressed(KEY_1):
		lambda = clampf(lambda - 0.4 * delta, 0.0, 1.0)
	if Input.is_key_pressed(KEY_2):
		lambda = clampf(lambda + 0.4 * delta, 0.0, 1.0)
	if Input.is_key_pressed(KEY_3):
		phi = clampf(phi - 0.4 * delta, 0.0, 1.0)
	if Input.is_key_pressed(KEY_4):
		phi = clampf(phi + 0.4 * delta, 0.0, 1.0)
	if Input.is_key_pressed(KEY_0):
		_reset_to_edge()

	# Orb animation
	if _orb_mat:
		var pulse_speed: float = 1.0 + lambda * 6.0
		_orb_mat.emission_energy_multiplier = 1.5 + sin(_time * pulse_speed) * 1.0

	if _orb_mesh:
		var wobble: float = lambda * 0.02
		_orb_mesh.position.x = sin(_time * 3.0) * wobble
		_orb_mesh.position.z = 0.06 + cos(_time * 2.0) * wobble

	# Particle response
	if _particles and _particles.process_material:
		var pmat := _particles.process_material as ParticleProcessMaterial
		_particles.amount = int(lerpf(5.0, 60.0, lambda))
		pmat.initial_velocity_max = lerpf(0.02, 0.15, lambda)

# Public API
func set_lambda(value: float) -> void:
	lambda = value

func set_phi(value: float) -> void:
	phi = value

func get_free_energy() -> float:
	return _free_energy

func get_regime() -> String:
	return _current_regime
