# prng_crank_machine.gd
# PRNG Crank Machine — a physical hand-crank pseudo-random number generator
# Pull the VR lever → LCG formula animates step by step → number appears on display
# Shows the deterministic nature of PRNG: same seed → same sequence
#
# LCG: state = (state × 1664525 + 1013904223) mod 2^32
# QFEP: Determinism masquerading as randomness — structure hidden in sequence.
#
# @identity
# essence: x_{n+1} = (a·x_n + c) mod m — linear congruential generator
# desire: crank the machine, watch arithmetic unfold, feel determinism wearing randomness as a mask
# critical_parameter: initial_seed — same seed reproduces the entire sequence
# triggers: _crank() → 4-phase animation (multiply, add, mod, result) with color-coded transitions
# emerges: the history panel reveals periodicity — given enough cranks, the sequence must repeat
# needs: VR push buttons [has] for CRANK/RESET/SEED
# relationships: contrasts with trng_vs_prng; feeds slot_machine understanding of pseudo-randomness
# truth: Determinism is not the opposite of randomness — it is randomness with a forgotten origin.

extends Node3D

class_name PrngCrankMachine

# ── Machine Body ─────────────────────────────────────────────────────────────
@export var body_width: float = 0.4
@export var body_height: float = 0.5
@export var body_depth: float = 0.2
@export var pedestal_height: float = 0.7

# ── LCG Parameters ───────────────────────────────────────────────────────────
@export var lcg_multiplier: int = 1664525
@export var lcg_increment: int = 1013904223
@export var lcg_modulus: int = 0  # 0 = 2^32 (use overflow)
@export var initial_seed: int = 42

# ── Colors ───────────────────────────────────────────────────────────────────
@export var color_body: Color = Color(0.12, 0.12, 0.15)
@export var color_accent: Color = Color(0.6, 0.4, 0.1)  # Brass
@export var color_display_bg: Color = Color(0.02, 0.05, 0.02)
@export var color_display_text: Color = Color(0.2, 1.0, 0.3)  # Green LED
@export var color_formula: Color = Color(0.8, 0.8, 0.9)

# ── Internal ─────────────────────────────────────────────────────────────────
var _state: int = 42
var _step_count: int = 0
var _history: Array[int] = []

var _display_label: Label3D
var _formula_label: Label3D
var _step_label: Label3D
var _state_label: Label3D
var _history_label: Label3D
var _seed_label: Label3D

# Animation state
var _is_animating: bool = false
var _anim_phase: int = 0  # 0=idle, 1=multiply, 2=add, 3=mod, 4=done
var _anim_timer: float = 0.0
var _anim_intermediate: int = 0

const MAX_HISTORY := 12
const PHASE_DURATION := 0.6  # Seconds per animation phase
const PUSH_BUTTON = preload("res://commons/interactables/push_button.tscn")


# ═════════════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	_state = initial_seed
	_create_pedestal()
	_create_machine_body()
	_create_display_panel()
	_create_formula_display()
	_create_history_panel()
	_create_vr_controls()
	_update_display()


func _process(delta: float) -> void:
	if not _is_animating:
		return

	_anim_timer += delta

	if _anim_timer >= PHASE_DURATION:
		_anim_timer = 0.0
		_advance_animation()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_SPACE:
				_crank()
			KEY_R:
				_reset()


# ═════════════════════════════════════════════════════════════════════════════
# LCG CORE
# ═════════════════════════════════════════════════════════════════════════════

func _crank() -> void:
	if _is_animating:
		return

	_is_animating = true
	_anim_phase = 1
	_anim_timer = 0.0
	_anim_intermediate = _state

	# Phase 1: Show multiplication
	_formula_label.text = "state × %d" % lcg_multiplier
	_state_label.text = "%d × %d" % [_state, lcg_multiplier]
	_state_label.modulate = Color(1.0, 0.7, 0.3)


func _advance_animation() -> void:
	match _anim_phase:
		1:
			# Multiply done → show result, start add
			_anim_intermediate = _state * lcg_multiplier
			_anim_phase = 2
			_formula_label.text = "... + %d" % lcg_increment
			_state_label.text = "%d + %d" % [_anim_intermediate, lcg_increment]
			_state_label.modulate = Color(0.3, 0.8, 1.0)

		2:
			# Add done → show result, start mod
			_anim_intermediate = _anim_intermediate + lcg_increment
			_anim_phase = 3
			_formula_label.text = "... mod 2^32"
			_state_label.text = "%d mod 4294967296" % _anim_intermediate
			_state_label.modulate = Color(1.0, 0.5, 0.8)

		3:
			# Mod done → final result
			var new_state: int
			if lcg_modulus == 0:
				new_state = (_state * lcg_multiplier + lcg_increment) & 0xFFFFFFFF
			else:
				new_state = (_state * lcg_multiplier + lcg_increment) % lcg_modulus

			_state = new_state
			_step_count += 1
			_history.append(_state)
			if _history.size() > MAX_HISTORY:
				_history.pop_front()

			_anim_phase = 4
			_formula_label.text = "state = (state × a + c) mod m"
			_state_label.text = "→ %d" % _state
			_state_label.modulate = color_display_text

		4:
			# Animation complete
			_is_animating = false
			_anim_phase = 0
			_update_display()


# ═════════════════════════════════════════════════════════════════════════════
# MACHINE BODY
# ═════════════════════════════════════════════════════════════════════════════

func _create_pedestal() -> void:
	var mesh := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.08
	cyl.bottom_radius = 0.12
	cyl.height = pedestal_height
	mesh.mesh = cyl

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.18, 0.18, 0.2)
	mat.metallic = 0.5
	mat.roughness = 0.4
	mesh.material_override = mat
	mesh.position = Vector3(0, pedestal_height / 2.0, 0)
	add_child(mesh)


func _create_machine_body() -> void:
	var body := Node3D.new()
	body.name = "MachineBody"
	body.position = Vector3(0, pedestal_height, 0)
	add_child(body)

	# Main housing
	var housing := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(body_width, body_height, body_depth)
	housing.mesh = box

	var mat := StandardMaterial3D.new()
	mat.albedo_color = color_body
	mat.metallic = 0.6
	mat.roughness = 0.35
	housing.material_override = mat
	housing.position = Vector3(0, body_height / 2.0, 0)
	body.add_child(housing)

	# Brass trim strips (top and bottom)
	var trim_mat := StandardMaterial3D.new()
	trim_mat.albedo_color = color_accent
	trim_mat.metallic = 0.8
	trim_mat.roughness = 0.2
	trim_mat.emission_enabled = true
	trim_mat.emission = color_accent * 0.15
	trim_mat.emission_energy_multiplier = 0.1

	for y_offset in [0.01, body_height - 0.01]:
		var trim := MeshInstance3D.new()
		var trim_box := BoxMesh.new()
		trim_box.size = Vector3(body_width + 0.005, 0.012, body_depth + 0.005)
		trim.mesh = trim_box
		trim.material_override = trim_mat
		trim.position = Vector3(0, y_offset, 0)
		body.add_child(trim)

	# Side decorative bolts
	var bolt_mesh := SphereMesh.new()
	bolt_mesh.radius = 0.008
	bolt_mesh.height = 0.016

	for x_sign in [-1, 1]:
		for y in [0.08, body_height - 0.08]:
			var bolt := MeshInstance3D.new()
			bolt.mesh = bolt_mesh
			bolt.material_override = trim_mat
			bolt.position = Vector3(
				x_sign * (body_width / 2.0 + 0.001),
				y,
				0
			)
			body.add_child(bolt)

	# Nameplate
	var nameplate := Label3D.new()
	nameplate.text = "LCG-32"
	nameplate.pixel_size = 0.001
	nameplate.font_size = 14
	nameplate.modulate = color_accent
	nameplate.position = Vector3(0, body_height + 0.02, body_depth / 2.0 + 0.001)
	nameplate.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(nameplate)

	# Title above
	var title := Label3D.new()
	title.text = "PSEUDO-RANDOM\nNUMBER GENERATOR"
	title.pixel_size = 0.0015
	title.font_size = 14
	title.modulate = Color(0.85, 0.85, 0.9)
	title.position = Vector3(0, body_height + 0.1, 0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(title)


# ═════════════════════════════════════════════════════════════════════════════
# DISPLAYS
# ═════════════════════════════════════════════════════════════════════════════

func _create_display_panel() -> void:
	var panel_y := pedestal_height + body_height * 0.65
	var panel_z := body_depth / 2.0 + 0.002

	# Display background (dark screen)
	var screen := MeshInstance3D.new()
	var screen_box := BoxMesh.new()
	screen_box.size = Vector3(body_width * 0.85, 0.08, 0.003)
	screen.mesh = screen_box

	var screen_mat := StandardMaterial3D.new()
	screen_mat.albedo_color = color_display_bg
	screen_mat.emission_enabled = true
	screen_mat.emission = color_display_bg
	screen_mat.emission_energy_multiplier = 0.05
	screen.material_override = screen_mat
	screen.position = Vector3(0, panel_y, panel_z)
	add_child(screen)

	# Main number display
	_display_label = Label3D.new()
	_display_label.name = "NumberDisplay"
	_display_label.text = "42"
	_display_label.pixel_size = 0.002
	_display_label.font_size = 28
	_display_label.modulate = color_display_text
	_display_label.position = Vector3(0, panel_y, panel_z + 0.003)
	_display_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_display_label)

	# Step counter
	_step_label = Label3D.new()
	_step_label.name = "StepLabel"
	_step_label.text = "step: 0"
	_step_label.pixel_size = 0.001
	_step_label.font_size = 16
	_step_label.modulate = Color(0.5, 0.8, 0.5)
	_step_label.position = Vector3(body_width * 0.35, panel_y + 0.045, panel_z + 0.003)
	_step_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_step_label)

	# Seed display
	_seed_label = Label3D.new()
	_seed_label.name = "SeedLabel"
	_seed_label.text = "seed: %d" % initial_seed
	_seed_label.pixel_size = 0.001
	_seed_label.font_size = 16
	_seed_label.modulate = Color(0.6, 0.6, 0.5)
	_seed_label.position = Vector3(-body_width * 0.35, panel_y + 0.045, panel_z + 0.003)
	_seed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_child(_seed_label)


func _create_formula_display() -> void:
	var formula_y := pedestal_height + body_height * 0.42
	var panel_z := body_depth / 2.0 + 0.002

	# Formula background
	var bg := MeshInstance3D.new()
	var bg_box := BoxMesh.new()
	bg_box.size = Vector3(body_width * 0.85, 0.065, 0.003)
	bg.mesh = bg_box
	var bg_mat := StandardMaterial3D.new()
	bg_mat.albedo_color = Color(0.04, 0.04, 0.06)
	bg.material_override = bg_mat
	bg.position = Vector3(0, formula_y, panel_z)
	add_child(bg)

	# Formula text
	_formula_label = Label3D.new()
	_formula_label.name = "FormulaLabel"
	_formula_label.text = "state = (state × a + c) mod m"
	_formula_label.pixel_size = 0.001
	_formula_label.font_size = 16
	_formula_label.modulate = color_formula
	_formula_label.position = Vector3(0, formula_y + 0.015, panel_z + 0.003)
	_formula_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_formula_label)

	# Animated state computation label
	_state_label = Label3D.new()
	_state_label.name = "StateLabel"
	_state_label.text = ""
	_state_label.pixel_size = 0.001
	_state_label.font_size = 14
	_state_label.modulate = Color(0.7, 0.7, 0.75)
	_state_label.position = Vector3(0, formula_y - 0.015, panel_z + 0.003)
	_state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_state_label)

	# Parameters label below
	var params := Label3D.new()
	params.text = "a = %d    c = %d    m = 2^32" % [lcg_multiplier, lcg_increment]
	params.pixel_size = 0.0008
	params.font_size = 14
	params.modulate = Color(0.45, 0.45, 0.5)
	params.position = Vector3(0, formula_y - 0.045, panel_z + 0.003)
	params.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(params)


func _create_history_panel() -> void:
	var hist_y := pedestal_height + body_height * 0.15
	var panel_z := body_depth / 2.0 + 0.002

	# History background
	var bg := MeshInstance3D.new()
	var bg_box := BoxMesh.new()
	bg_box.size = Vector3(body_width * 0.85, 0.08, 0.003)
	bg.mesh = bg_box
	var bg_mat := StandardMaterial3D.new()
	bg_mat.albedo_color = Color(0.03, 0.03, 0.05)
	bg.material_override = bg_mat
	bg.position = Vector3(0, hist_y, panel_z)
	add_child(bg)

	# History label header
	var header := Label3D.new()
	header.text = "sequence:"
	header.pixel_size = 0.0008
	header.font_size = 16
	header.modulate = Color(0.5, 0.5, 0.55)
	header.position = Vector3(-body_width * 0.38, hist_y + 0.032, panel_z + 0.003)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_child(header)

	# History numbers
	_history_label = Label3D.new()
	_history_label.name = "HistoryLabel"
	_history_label.text = ""
	_history_label.pixel_size = 0.0007
	_history_label.font_size = 16
	_history_label.modulate = Color(0.4, 0.7, 0.4)
	_history_label.position = Vector3(0, hist_y - 0.005, panel_z + 0.003)
	_history_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_history_label)


# ═════════════════════════════════════════════════════════════════════════════
# DISPLAY UPDATES
# ═════════════════════════════════════════════════════════════════════════════

func _update_display() -> void:
	# Number display — show as both decimal and 0-1 float
	var normalized := float(_state & 0xFFFFFFFF) / 4294967296.0
	_display_label.text = "%d\n%.6f" % [_state & 0xFFFFFFFF, normalized]

	_step_label.text = "step: %d" % _step_count
	_state_label.text = ""

	# History
	if _history.is_empty():
		_history_label.text = str(initial_seed)
	else:
		var lines := ""
		var per_line := 4
		for i in range(_history.size()):
			if i > 0 and i % per_line == 0:
				lines += "\n"
			lines += "%d  " % (_history[i] & 0xFFFFFFFF)
		_history_label.text = lines


# ═════════════════════════════════════════════════════════════════════════════
# VR CONTROLS
# ═════════════════════════════════════════════════════════════════════════════

func _create_vr_controls() -> void:
	var panel := Node3D.new()
	panel.name = "ControlPanel"
	panel.position = Vector3(0, pedestal_height - 0.05, body_depth / 2.0 + 0.12)
	panel.rotation_degrees = Vector3(-25, 0, 0)
	add_child(panel)

	# Panel backing
	var back := MeshInstance3D.new()
	var back_mesh := BoxMesh.new()
	back_mesh.size = Vector3(0.35, 0.08, 0.008)
	back.mesh = back_mesh
	var back_mat := StandardMaterial3D.new()
	back_mat.albedo_color = Color(0.06, 0.06, 0.08)
	back.material_override = back_mat
	back.position.z = -0.008
	panel.add_child(back)

	# CRANK button (main action)
	var crank_btn := PUSH_BUTTON.instantiate()
	crank_btn.name = "CrankBtn"
	crank_btn.position = Vector3(-0.1, 0.0, 0)
	crank_btn.scale = Vector3(0.8, 0.8, 0.8)  # Slightly larger — primary action
	panel.add_child(crank_btn)
	_add_button_label(crank_btn, "CRANK")

	var crank_area := crank_btn.get_node_or_null("InteractableAreaButton")
	if crank_area:
		crank_area.button_pressed.connect(func(_b): _crank())

	# RESET button
	var reset_btn := PUSH_BUTTON.instantiate()
	reset_btn.name = "ResetBtn"
	reset_btn.position = Vector3(0.0, 0.0, 0)
	reset_btn.scale = Vector3(0.65, 0.65, 0.65)
	panel.add_child(reset_btn)
	_add_button_label(reset_btn, "RESET")

	var reset_area := reset_btn.get_node_or_null("InteractableAreaButton")
	if reset_area:
		reset_area.button_pressed.connect(func(_b): _reset())

	# SEED button (randomize seed)
	var seed_btn := PUSH_BUTTON.instantiate()
	seed_btn.name = "SeedBtn"
	seed_btn.position = Vector3(0.1, 0.0, 0)
	seed_btn.scale = Vector3(0.65, 0.65, 0.65)
	panel.add_child(seed_btn)
	_add_button_label(seed_btn, "SEED")

	var seed_area := seed_btn.get_node_or_null("InteractableAreaButton")
	if seed_area:
		seed_area.button_pressed.connect(func(_b): _randomize_seed())


func _add_button_label(btn: Node, text: String) -> void:
	var lbl := Label3D.new()
	lbl.text = text
	lbl.pixel_size = 0.001
	lbl.font_size = 16
	lbl.position = Vector3(0, -0.022, 0)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.add_child(lbl)


# ═════════════════════════════════════════════════════════════════════════════
# ACTIONS
# ═════════════════════════════════════════════════════════════════════════════

func _reset() -> void:
	_state = initial_seed
	_step_count = 0
	_history.clear()
	_is_animating = false
	_anim_phase = 0
	_seed_label.text = "seed: %d" % initial_seed
	_update_display()


func _randomize_seed() -> void:
	initial_seed = randi() & 0xFFFFFFFF
	_state = initial_seed
	_step_count = 0
	_history.clear()
	_is_animating = false
	_anim_phase = 0
	_seed_label.text = "seed: %d" % initial_seed
	_update_display()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
