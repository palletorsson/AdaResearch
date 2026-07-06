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

const BakedText = preload("res://commons/utils/baked_text_albedo.gd")

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

# Board containers — each holds a baked-text block that is rebuilt when its
# values change. ONE BODY: one panel per role, never two boards overlapping.
var _readout_board: Node3D    # main number + normalized + step + seed
var _formula_board: Node3D    # formula line + live computation + params
var _history_board: Node3D    # sequence header + numbers

# Board face geometry (metres) reused by the rebuild helpers.
var _readout_width: float = 0.34
var _formula_width: float = 0.34
var _history_width: float = 0.34

# Animation state
var _is_animating: bool = false
var _anim_phase: int = 0  # 0=idle, 1=multiply, 2=add, 3=mod, 4=done
var _anim_timer: float = 0.0
var _anim_intermediate: int = 0

# Current text lines for the animated formula board (phase transitions edit these).
var _formula_line: String = "state = (state x a + c) mod m"
var _compute_line: String = ""
var _compute_color: Color = Color(0.7, 0.7, 0.75)

const MAX_HISTORY := 12
const PHASE_DURATION := 0.6  # Seconds per animation phase


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
	_formula_line = "state × %d" % lcg_multiplier
	_compute_line = "%d × %d" % [_state, lcg_multiplier]
	_compute_color = Color(1.0, 0.7, 0.3)
	_rebuild_formula_board()


func _advance_animation() -> void:
	match _anim_phase:
		1:
			# Multiply done → show result, start add
			_anim_intermediate = _state * lcg_multiplier
			_anim_phase = 2
			_formula_line = "... + %d" % lcg_increment
			_compute_line = "%d + %d" % [_anim_intermediate, lcg_increment]
			_compute_color = Color(0.3, 0.8, 1.0)
			_rebuild_formula_board()

		2:
			# Add done → show result, start mod
			_anim_intermediate = _anim_intermediate + lcg_increment
			_anim_phase = 3
			_formula_line = "... mod 2^32"
			_compute_line = "%d mod 4294967296" % _anim_intermediate
			_compute_color = Color(1.0, 0.5, 0.8)
			_rebuild_formula_board()

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
			_formula_line = "state = (state × a + c) mod m"
			_compute_line = "→ %d" % _state
			_compute_color = color_display_text
			_rebuild_formula_board()

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

	# Nameplate — a brass tag riveted to the front lip, just above the body.
	var nameplate := BakedText.make_tag(
		"LCG-32", color_accent, 0.028,
		Color(0.10, 0.09, 0.06), false, color_accent)
	if nameplate:
		nameplate.position = Vector3(0, body_height + 0.03, body_depth / 2.0 + 0.004)
		body.add_child(nameplate)

	# Title above — two spaced lines on one board, clear of the nameplate below.
	var title := BakedText.make_text_block(
		["PSEUDO-RANDOM", "NUMBER GENERATOR"],
		Color(0.85, 0.85, 0.9), 0.032, body_width * 1.15, 0.008, false)
	if title:
		title.position = Vector3(0, body_height + 0.13, 0.0)
		body.add_child(title)


# ═════════════════════════════════════════════════════════════════════════════
# DISPLAYS
# ═════════════════════════════════════════════════════════════════════════════

func _create_display_panel() -> void:
	# READOUT board — one screen carrying the whole instrument readout:
	# seed + step on the header row, the current number + its 0-1 float below.
	# Previously four separate Label3D nodes; now one rebuilt text block.
	var panel_y := pedestal_height + body_height * 0.66
	var panel_z := body_depth / 2.0 + 0.002
	_readout_width = body_width * 0.82

	_make_screen(Vector3(_readout_width, 0.11, 0.003),
		color_display_bg, Vector3(0, panel_y, panel_z), 0.05)

	_readout_board = Node3D.new()
	_readout_board.name = "ReadoutBoard"
	_readout_board.position = Vector3(0, panel_y, panel_z + 0.004)
	add_child(_readout_board)
	_rebuild_readout_board()


func _create_formula_display() -> void:
	# FORMULA board — the arithmetic. One screen: the formula line, the live
	# per-phase computation (colour-coded via the compute line), and the LCG
	# parameters. Rebuilt each animation phase so the crank drives the numbers.
	var formula_y := pedestal_height + body_height * 0.42
	var panel_z := body_depth / 2.0 + 0.002
	_formula_width = body_width * 0.82

	_make_screen(Vector3(_formula_width, 0.10, 0.003),
		Color(0.04, 0.04, 0.06), Vector3(0, formula_y, panel_z), 0.0)

	_formula_board = Node3D.new()
	_formula_board.name = "FormulaBoard"
	_formula_board.position = Vector3(0, formula_y, panel_z + 0.004)
	add_child(_formula_board)
	_rebuild_formula_board()


func _create_history_panel() -> void:
	# HISTORY board — the emitted sequence. Header + numbers on one screen.
	var hist_y := pedestal_height + body_height * 0.16
	var panel_z := body_depth / 2.0 + 0.002
	_history_width = body_width * 0.82

	_make_screen(Vector3(_history_width, 0.10, 0.003),
		Color(0.03, 0.03, 0.05), Vector3(0, hist_y, panel_z), 0.0)

	_history_board = Node3D.new()
	_history_board.name = "HistoryBoard"
	_history_board.position = Vector3(0, hist_y, panel_z + 0.004)
	add_child(_history_board)
	_rebuild_history_board()


## Opaque backing screen behind a board (the dark LCD plate).
func _make_screen(size: Vector3, bg: Color, pos: Vector3, emit_energy: float) -> void:
	var screen := MeshInstance3D.new()
	var screen_box := BoxMesh.new()
	screen_box.size = size
	screen.mesh = screen_box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = bg
	if emit_energy > 0.0:
		mat.emission_enabled = true
		mat.emission = bg
		mat.emission_energy_multiplier = emit_energy
	screen.material_override = mat
	screen.position = pos
	add_child(screen)


# ═════════════════════════════════════════════════════════════════════════════
# BOARD REBUILDS — clear the container, repaint one baked-text block onto it
# ═════════════════════════════════════════════════════════════════════════════

func _clear_board(board: Node3D) -> void:
	if board == null:
		return
	for c in board.get_children():
		c.queue_free()


func _rebuild_readout_board() -> void:
	if _readout_board == null:
		return
	_clear_board(_readout_board)
	var normalized := float(_state & 0xFFFFFFFF) / 4294967296.0
	var header := "seed: %d      step: %d" % [initial_seed, _step_count]
	var lines := [
		header,
		"%d" % (_state & 0xFFFFFFFF),
		"%.6f" % normalized,
	]
	var block := BakedText.make_text_block(
		lines, color_display_text, 0.03, _readout_width * 0.94, 0.006, true)
	if block:
		_readout_board.add_child(block)


func _rebuild_formula_board() -> void:
	if _formula_board == null:
		return
	_clear_board(_formula_board)
	# Formula + live computation share the same board; the compute line is
	# coloured by the current phase, the surrounding lines stay muted.
	var params := "a = %d    c = %d    m = 2^32" % [lcg_multiplier, lcg_increment]
	# Formula line (top), muted.
	var top := BakedText.make_text_block(
		[_formula_line], color_formula, 0.024, _formula_width * 0.94, 0.0, true)
	if top:
		top.position = Vector3(0, 0.03, 0.0)
		_formula_board.add_child(top)
	# Live computation line (middle), phase-coloured.
	if _compute_line != "":
		var mid := BakedText.make_text_block(
			[_compute_line], _compute_color, 0.022, _formula_width * 0.94, 0.0, true)
		if mid:
			mid.position = Vector3(0, 0.0, 0.0)
			_formula_board.add_child(mid)
	# Parameters line (bottom), dim.
	var bot := BakedText.make_text_block(
		[params], Color(0.45, 0.45, 0.5), 0.02, _formula_width * 0.94, 0.0, true)
	if bot:
		bot.position = Vector3(0, -0.03, 0.0)
		_formula_board.add_child(bot)


func _rebuild_history_board() -> void:
	if _history_board == null:
		return
	_clear_board(_history_board)
	var lines: Array = ["sequence:"]
	if _history.is_empty():
		lines.append(str(initial_seed))
	else:
		var row := ""
		var per_line := 4
		for i in range(_history.size()):
			if i > 0 and i % per_line == 0:
				lines.append(row.strip_edges())
				row = ""
			row += "%d  " % (_history[i] & 0xFFFFFFFF)
		if row.strip_edges() != "":
			lines.append(row.strip_edges())
	var block := BakedText.make_text_block(
		lines, Color(0.42, 0.72, 0.42), 0.02, _history_width * 0.94, 0.004, true)
	if block:
		_history_board.add_child(block)


# ═════════════════════════════════════════════════════════════════════════════
# DISPLAY UPDATES
# ═════════════════════════════════════════════════════════════════════════════

func _update_display() -> void:
	# Idle state — clear the live computation line and repaint all boards.
	_compute_line = ""
	_formula_line = "state = (state × a + c) mod m"
	_rebuild_readout_board()
	_rebuild_formula_board()
	_rebuild_history_board()


# ═════════════════════════════════════════════════════════════════════════════
# VR CONTROLS
# ═════════════════════════════════════════════════════════════════════════════

func _create_vr_controls() -> void:
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	var panel: Node3D = RackTpl.create_panel("PRNG CRANK", [
		[
			{"type": "button", "label": "CRANK"},
			{"type": "button", "label": "RESET"},
			{"type": "button", "label": "SEED"},
		],
	])
	panel.position = Vector3(0, pedestal_height - 0.05, body_depth / 2.0 + 0.12)
	panel.rotation_degrees = Vector3(-25, 0, 0)
	add_child(panel)

	# CRANK button (Btn_0)
	var crank_btn: Node = panel.find_child("Btn_0", true, false)
	if crank_btn:
		var area = crank_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _crank())

	# RESET button (Btn_1)
	var reset_btn: Node = panel.find_child("Btn_1", true, false)
	if reset_btn:
		var area = reset_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _reset())

	# SEED button (Btn_2)
	var seed_btn: Node = panel.find_child("Btn_2", true, false)
	if seed_btn:
		var area = seed_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _randomize_seed())


# ═════════════════════════════════════════════════════════════════════════════
# ACTIONS
# ═════════════════════════════════════════════════════════════════════════════

func _reset() -> void:
	_state = initial_seed
	_step_count = 0
	_history.clear()
	_is_animating = false
	_anim_phase = 0
	_update_display()


func _randomize_seed() -> void:
	initial_seed = randi() & 0xFFFFFFFF
	_state = initial_seed
	_step_count = 0
	_history.clear()
	_is_animating = false
	_anim_phase = 0
	_update_display()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
