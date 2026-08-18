# ===========================================================================
# NOC Example 3.5: Simple Harmonic Motion — Elevated
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# Elevated features:
#   - Damped oscillation with configurable decay coefficient
#   - Coupled oscillators showing beats and resonance
#   - Energy visualization (kinetic + potential bars)
#   - Full apply_grid_config() integration
#
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D
const ARTIFACT_SCENE_PRESENTER := preload("res://commons/artifacts/ArtifactScenePresenter.gd")


# --- Configurable parameters ---
@export var amplitude: float = 0.2
@export var frequency_a: float = 1.5
@export var frequency_b: float = 1.8
@export var damping_coeff: float = 0.15
@export var coupling_strength: float = 0.3
@export var show_coupled: bool = true

# --- Internal state ---
var _time: float = 0.0

# Oscillator A (damped)
var _pos_a: float = 0.0
var _vel_a: float = 0.0

# Oscillator B (coupled partner)
var _pos_b: float = 0.0
var _vel_b: float = 0.0

# Scene nodes
var _sim_root: Node3D
var _bob_a: MeshInstance3D
var _bob_b: MeshInstance3D
var _spring_line_a: MeshInstance3D
var _spring_line_b: MeshInstance3D
var _trail_mesh_inst: MeshInstance3D
var _energy_mesh_inst: MeshInstance3D
var _envelope_mesh_inst: MeshInstance3D
var _title_label: Label3D
var _status_label: Label3D
var _energy_label: Label3D
var _control_panel: Node3D

# Trail history
var _trail_a: Array[Vector3] = []
var _trail_b: Array[Vector3] = []
const MAX_TRAIL := 200

# Layout constants
const ANCHOR_Y := 0.75
const BOB_REST_Y := 0.45
const ENERGY_BAR_X := -0.35
const ENERGY_BAR_WIDTH := 0.015
const ENERGY_BAR_MAX_H := 0.2

# Materials
var _mat_unshaded: StandardMaterial3D
var _mat_bob_a: StandardMaterial3D
var _mat_bob_b: StandardMaterial3D


func _ready() -> void:
	_create_materials()
	_setup_scene()
	_setup_labels()
	_setup_vr_controls()
	_reset_oscillators()
	call_deferred("_apply_standard_presentation")
	set_process(true)


func _create_materials() -> void:
	_mat_unshaded = StandardMaterial3D.new()
	_mat_unshaded.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_unshaded.vertex_color_use_as_albedo = true
	_mat_unshaded.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat_unshaded.cull_mode = BaseMaterial3D.CULL_DISABLED

	_mat_bob_a = StandardMaterial3D.new()
	_mat_bob_a.albedo_color = Color(0.95, 0.45, 0.55)
	_mat_bob_a.emission_enabled = true
	_mat_bob_a.emission = Color(0.95, 0.45, 0.55)
	_mat_bob_a.emission_energy_multiplier = 1.5

	_mat_bob_b = StandardMaterial3D.new()
	_mat_bob_b.albedo_color = Color(0.45, 0.65, 0.95)
	_mat_bob_b.emission_enabled = true
	_mat_bob_b.emission = Color(0.45, 0.65, 0.95)
	_mat_bob_b.emission_energy_multiplier = 1.5


func _setup_scene() -> void:
	_sim_root = Node3D.new()
	add_child(_sim_root)

	# Bob A — primary oscillator (warm pink)
	_bob_a = MeshInstance3D.new()
	var sphere_a := SphereMesh.new()
	sphere_a.radius = 0.04
	sphere_a.height = sphere_a.radius * 2.0
	_bob_a.mesh = sphere_a
	_bob_a.material_override = _mat_bob_a
	_sim_root.add_child(_bob_a)

	# Bob B — coupled oscillator (cool blue)
	_bob_b = MeshInstance3D.new()
	var sphere_b := SphereMesh.new()
	sphere_b.radius = 0.035
	sphere_b.height = sphere_b.radius * 2.0
	_bob_b.mesh = sphere_b
	_bob_b.material_override = _mat_bob_b
	_sim_root.add_child(_bob_b)

	# Spring lines
	_spring_line_a = MeshInstance3D.new()
	_spring_line_a.material_override = _mat_unshaded
	_sim_root.add_child(_spring_line_a)

	_spring_line_b = MeshInstance3D.new()
	_spring_line_b.material_override = _mat_unshaded
	_sim_root.add_child(_spring_line_b)

	# Trail mesh
	_trail_mesh_inst = MeshInstance3D.new()
	_trail_mesh_inst.material_override = _mat_unshaded
	_trail_mesh_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_sim_root.add_child(_trail_mesh_inst)

	# Energy bar mesh
	_energy_mesh_inst = MeshInstance3D.new()
	_energy_mesh_inst.material_override = _mat_unshaded
	_energy_mesh_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_sim_root.add_child(_energy_mesh_inst)

	# Damping envelope mesh
	_envelope_mesh_inst = MeshInstance3D.new()
	_envelope_mesh_inst.material_override = _mat_unshaded
	_envelope_mesh_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_sim_root.add_child(_envelope_mesh_inst)


func _setup_labels() -> void:
	_title_label = Label3D.new()
	_title_label.text = "SIMPLE HARMONIC MOTION"
	_title_label.font_size = 20
	_title_label.pixel_size = 0.001
	_title_label.position = Vector3(0, ANCHOR_Y + 0.12, 0)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.modulate = Color(0.95, 0.85, 0.7)
	_title_label.outline_size = 4
	_title_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	_sim_root.add_child(_title_label)

	_status_label = Label3D.new()
	_status_label.font_size = 14
	_status_label.pixel_size = 0.001
	_status_label.position = Vector3(0, ANCHOR_Y + 0.06, 0)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.modulate = Color(0.85, 0.85, 0.9)
	_status_label.outline_size = 3
	_status_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	_sim_root.add_child(_status_label)

	_energy_label = Label3D.new()
	_energy_label.font_size = 12
	_energy_label.pixel_size = 0.001
	_energy_label.position = Vector3(ENERGY_BAR_X, BOB_REST_Y + ENERGY_BAR_MAX_H + 0.04, 0)
	_energy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_energy_label.modulate = Color(0.8, 0.9, 0.8)
	_energy_label.outline_size = 3
	_energy_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	_sim_root.add_child(_energy_label)


func _setup_vr_controls() -> void:
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	_control_panel = RackTpl.create_parameter_panel(
		3, ["DAMPING", "COUPLING", "FREQ B"],
		[damping_coeff / 0.5, coupling_strength, (frequency_b - 0.5) / 3.5]
	)
	_control_panel.position = Vector3(0.45, 0.35, 0.18)
	_control_panel.rotation_degrees = Vector3(-20, -25, 0)
	add_child(_control_panel)

	var damp_slider: Node = _control_panel.get_node_or_null("Param_0")
	var couple_slider: Node = _control_panel.get_node_or_null("Param_1")
	var freq_slider: Node = _control_panel.get_node_or_null("Param_2")

	if damp_slider and damp_slider.has_signal("slider_moved"):
		damp_slider.slider_moved.connect(func(_n) -> void:
			if damp_slider.has_method("get_normalized_value"):
				damping_coeff = damp_slider.get_normalized_value() * 0.5
		)
	if couple_slider and couple_slider.has_signal("slider_moved"):
		couple_slider.slider_moved.connect(func(_n) -> void:
			if couple_slider.has_method("get_normalized_value"):
				coupling_strength = couple_slider.get_normalized_value()
		)
	if freq_slider and freq_slider.has_signal("slider_moved"):
		freq_slider.slider_moved.connect(func(_n) -> void:
			if freq_slider.has_method("get_normalized_value"):
				frequency_b = 0.5 + freq_slider.get_normalized_value() * 3.5
		)

	var reset_btn: Node = _control_panel.get_node_or_null("ResetButton")
	if reset_btn:
		var area := reset_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b: bool) -> void: _reset_oscillators())


func _reset_oscillators() -> void:
	_time = 0.0
	_pos_a = amplitude
	_vel_a = 0.0
	_pos_b = -amplitude * 0.5 if show_coupled else 0.0
	_vel_b = 0.0
	_trail_a.clear()
	_trail_b.clear()


func _process(delta: float) -> void:
	_time += delta
	_step_physics(delta)
	_update_bobs()
	_update_spring_lines()
	_update_trails()
	_update_energy_bars()
	_update_envelope()
	_update_labels_text()


func _step_physics(delta: float) -> void:
	# Oscillator A: damped harmonic motion
	# x'' = -ω²x - 2γx'  (+ coupling)
	var omega_a := frequency_a * TAU
	var acc_a := -omega_a * omega_a * _pos_a - 2.0 * damping_coeff * _vel_a

	# Oscillator B: second natural frequency
	var omega_b := frequency_b * TAU
	var acc_b := -omega_b * omega_b * _pos_b - 2.0 * damping_coeff * _vel_b

	# Coupling force: proportional to displacement difference
	if show_coupled:
		var coupling_force := coupling_strength * omega_a * omega_a * (_pos_b - _pos_a)
		acc_a += coupling_force
		acc_b -= coupling_force

	# Symplectic Euler integration (energy-preserving for undamped case)
	_vel_a += acc_a * delta
	_pos_a += _vel_a * delta

	_vel_b += acc_b * delta
	_pos_b += _vel_b * delta


func _update_bobs() -> void:
	var y_a := BOB_REST_Y + _pos_a
	_bob_a.position = Vector3(0.08, y_a, 0)

	_bob_b.visible = show_coupled
	if show_coupled:
		var y_b := BOB_REST_Y + _pos_b
		_bob_b.position = Vector3(-0.08, y_b, 0)

	# Record trail
	_trail_a.append(_bob_a.position)
	if _trail_a.size() > MAX_TRAIL:
		_trail_a.pop_front()

	if show_coupled:
		_trail_b.append(_bob_b.position)
		if _trail_b.size() > MAX_TRAIL:
			_trail_b.pop_front()


func _update_spring_lines() -> void:
	# Spring line A: anchor to bob
	var anchor_a := Vector3(0.08, ANCHOR_Y, 0)
	_spring_line_a.mesh = _build_spring_coil(anchor_a, _bob_a.position, Color(0.95, 0.55, 0.65, 0.7))

	# Spring line B
	_spring_line_b.visible = show_coupled
	if show_coupled:
		var anchor_b := Vector3(-0.08, ANCHOR_Y, 0)
		_spring_line_b.mesh = _build_spring_coil(anchor_b, _bob_b.position, Color(0.55, 0.7, 0.95, 0.7))


func _build_spring_coil(from: Vector3, to: Vector3, color: Color) -> ImmediateMesh:
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	var dir := (to - from).normalized()
	var length := from.distance_to(to)
	var coils := 10
	var coil_r := 0.015
	for i in range(coils * 4 + 1):
		var t := float(i) / (coils * 4)
		var pos := from + dir * (length * t)
		var angle := t * coils * TAU
		var offset := Vector3(cos(angle), 0, sin(angle)) * coil_r
		im.surface_set_color(color)
		im.surface_add_vertex(pos + offset)
	im.surface_end()
	return im


func _update_trails() -> void:
	var im := ImmediateMesh.new()

	# Trail A (pink/warm)
	if _trail_a.size() >= 2:
		im.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
		for i in range(_trail_a.size()):
			var t := float(i) / _trail_a.size()
			im.surface_set_color(Color(0.95, 0.55, 0.65, t * 0.5))
			im.surface_add_vertex(_trail_a[i] + Vector3(0, 0, -0.01))
		im.surface_end()

	# Trail B (blue/cool)
	if show_coupled and _trail_b.size() >= 2:
		im.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
		for i in range(_trail_b.size()):
			var t := float(i) / _trail_b.size()
			im.surface_set_color(Color(0.45, 0.65, 0.95, t * 0.5))
			im.surface_add_vertex(_trail_b[i] + Vector3(0, 0, -0.01))
		im.surface_end()

	_trail_mesh_inst.mesh = im


func _update_energy_bars() -> void:
	var im := ImmediateMesh.new()
	var omega_a := frequency_a * TAU

	# Oscillator A energies
	var ke_a := 0.5 * _vel_a * _vel_a
	var pe_a := 0.5 * omega_a * omega_a * _pos_a * _pos_a
	var total_a := ke_a + pe_a
	var max_e := maxf(amplitude * amplitude * omega_a * omega_a * 0.5, 0.001)

	# Kinetic energy bar (yellow-orange)
	var ke_h := clampf(ke_a / max_e, 0.0, 1.0) * ENERGY_BAR_MAX_H
	var pe_h := clampf(pe_a / max_e, 0.0, 1.0) * ENERGY_BAR_MAX_H
	var total_h := clampf(total_a / max_e, 0.0, 1.0) * ENERGY_BAR_MAX_H

	var bx := ENERGY_BAR_X
	var by := BOB_REST_Y - ENERGY_BAR_MAX_H * 0.5

	# KE bar
	_draw_bar(im, Vector3(bx - 0.025, by, 0), ENERGY_BAR_WIDTH, ke_h, Color(0.95, 0.75, 0.2, 0.85))
	# PE bar
	_draw_bar(im, Vector3(bx, by, 0), ENERGY_BAR_WIDTH, pe_h, Color(0.3, 0.8, 0.5, 0.85))
	# Total bar
	_draw_bar(im, Vector3(bx + 0.025, by, 0), ENERGY_BAR_WIDTH, total_h, Color(0.9, 0.9, 0.9, 0.6))

	if show_coupled:
		var omega_b := frequency_b * TAU
		var ke_b := 0.5 * _vel_b * _vel_b
		var pe_b := 0.5 * omega_b * omega_b * _pos_b * _pos_b
		var total_b := ke_b + pe_b
		var max_e_b := maxf(amplitude * amplitude * omega_b * omega_b * 0.5, 0.001)

		var bx2 := ENERGY_BAR_X - 0.1
		_draw_bar(im, Vector3(bx2 - 0.025, by, 0), ENERGY_BAR_WIDTH, clampf(ke_b / max_e_b, 0.0, 1.0) * ENERGY_BAR_MAX_H, Color(0.75, 0.6, 0.15, 0.7))
		_draw_bar(im, Vector3(bx2, by, 0), ENERGY_BAR_WIDTH, clampf(pe_b / max_e_b, 0.0, 1.0) * ENERGY_BAR_MAX_H, Color(0.2, 0.6, 0.4, 0.7))
		_draw_bar(im, Vector3(bx2 + 0.025, by, 0), ENERGY_BAR_WIDTH, clampf(total_b / max_e_b, 0.0, 1.0) * ENERGY_BAR_MAX_H, Color(0.7, 0.7, 0.8, 0.5))

	_energy_mesh_inst.mesh = im


func _draw_bar(im: ImmediateMesh, origin: Vector3, w: float, h: float, color: Color) -> void:
	if h < 0.001:
		return
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var hw := w * 0.5
	var p0 := origin + Vector3(-hw, 0, 0)
	var p1 := origin + Vector3(hw, 0, 0)
	var p2 := origin + Vector3(hw, h, 0)
	var p3 := origin + Vector3(-hw, h, 0)
	# Triangle 1
	im.surface_set_color(color)
	im.surface_add_vertex(p0)
	im.surface_set_color(color)
	im.surface_add_vertex(p1)
	im.surface_set_color(color)
	im.surface_add_vertex(p2)
	# Triangle 2
	im.surface_set_color(color)
	im.surface_add_vertex(p0)
	im.surface_set_color(color)
	im.surface_add_vertex(p2)
	im.surface_set_color(color)
	im.surface_add_vertex(p3)
	im.surface_end()


func _update_envelope() -> void:
	# Draw damping envelope: A * e^(-γt) as fading dashed lines
	if damping_coeff < 0.001:
		_envelope_mesh_inst.mesh = null
		return
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES)
	var segments := 60
	var t_span := 4.0 / maxf(damping_coeff, 0.01)
	t_span = minf(t_span, 10.0)
	for i in range(segments):
		var t0 := float(i) / segments * t_span
		var t1 := float(i + 1) / segments * t_span
		var env0 := amplitude * exp(-damping_coeff * t0)
		var env1 := amplitude * exp(-damping_coeff * t1)
		var x0 := -0.25 + 0.5 * (t0 / t_span)
		var x1 := -0.25 + 0.5 * (t1 / t_span)
		var alpha := 0.15 + 0.35 * (1.0 - float(i) / segments)
		# Upper envelope
		im.surface_set_color(Color(0.9, 0.7, 0.3, alpha))
		im.surface_add_vertex(Vector3(x0, BOB_REST_Y + env0, -0.02))
		im.surface_set_color(Color(0.9, 0.7, 0.3, alpha))
		im.surface_add_vertex(Vector3(x1, BOB_REST_Y + env1, -0.02))
		# Lower envelope
		im.surface_set_color(Color(0.9, 0.7, 0.3, alpha))
		im.surface_add_vertex(Vector3(x0, BOB_REST_Y - env0, -0.02))
		im.surface_set_color(Color(0.9, 0.7, 0.3, alpha))
		im.surface_add_vertex(Vector3(x1, BOB_REST_Y - env1, -0.02))
	im.surface_end()
	_envelope_mesh_inst.mesh = im


func _update_labels_text() -> void:
	var omega_a := frequency_a * TAU
	var ke := 0.5 * _vel_a * _vel_a
	var pe := 0.5 * omega_a * omega_a * _pos_a * _pos_a

	var mode_text := "DAMPED" if damping_coeff > 0.01 else "UNDAMPED"
	if show_coupled:
		# Detect beats: coupled oscillators with close frequencies
		var freq_ratio := frequency_b / maxf(frequency_a, 0.01)
		if absf(freq_ratio - 1.0) < 0.25:
			mode_text += " + BEATS"
		else:
			mode_text += " + COUPLED"

	_status_label.text = "%s  |  A: %.3f  ω: %.1f  γ: %.2f" % [mode_text, _pos_a, frequency_a, damping_coeff]
	_energy_label.text = "KE %.3f  PE %.3f" % [ke, pe]


func _apply_standard_presentation() -> void:
	# out-of-tree guard: get_tree() is null once a map is torn down
	if not is_inside_tree():
		await tree_entered
	await get_tree().process_frame
	# out-of-tree guard: get_tree() is null once a map is torn down
	if not is_inside_tree():
		await tree_entered
	await get_tree().process_frame
	ARTIFACT_SCENE_PRESENTER.present(self, _sim_root)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("amplitude"):
		amplitude = float(config_data["amplitude"])
	if config_data.has("frequency_a"):
		frequency_a = float(config_data["frequency_a"])
	if config_data.has("frequency"):
		frequency_a = float(config_data["frequency"])
	if config_data.has("frequency_b"):
		frequency_b = float(config_data["frequency_b"])
	if config_data.has("damping"):
		damping_coeff = float(config_data["damping"])
	if config_data.has("damping_coeff"):
		damping_coeff = float(config_data["damping_coeff"])
	if config_data.has("coupling"):
		coupling_strength = float(config_data["coupling"])
	if config_data.has("coupling_strength"):
		coupling_strength = float(config_data["coupling_strength"])
	if config_data.has("show_coupled"):
		show_coupled = bool(config_data["show_coupled"])

	_reset_oscillators()


