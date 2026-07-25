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
const HangarKit = preload("res://commons/artifacts/_hangar/hangar_kit.gd")

# ── Machine Body (cabinet grammar, vertical dialect: "ledger column") ────────
# You FACE this machine: mass rises, the sign sits in the cap, the three
# readouts stack down the front, the keypad rests on a wedge shoulder.
@export var body_width: float = 0.44
@export var body_height: float = 0.95
@export var body_depth: float = 0.24
## Lifts the whole machine so the keypad lands in the VR reach band (0.75-1.35 m).
## Built DOWNWARD from y=0 by HangarKit.plinth, so auto-grounding does the lift.
@export var plinth_height: float = 0.62
@export var finish: String = "terminal"
@export var wear: float = 0.10
@export var unit_code: String = "PR-17"

# ── LCG Parameters ───────────────────────────────────────────────────────────
@export var lcg_multiplier: int = 1664525
@export var lcg_increment: int = 1013904223
@export var lcg_modulus: int = 0  # 0 = 2^32 (use overflow)
@export var initial_seed: int = 42

# ── Colors ───────────────────────────────────────────────────────────────────
# Derived from HangarKit.finish_palette(finish) in _ready(), so one word
# ("rams" / "terminal") re-skins the whole machine and the family stays one set.
# The screen GLASS keeps the family's canonical blue-shifted tone regardless of
# finish — glass is glass; only body/panel/accent follow the dialect.
var color_body: Color = Color(0.14, 0.14, 0.155)
var color_accent: Color = Color(0.85, 0.30, 0.12)
var color_display_bg: Color = Color(0.05, 0.10, 0.06)
var color_display_text: Color = Color(0.45, 0.95, 0.50)
var color_formula: Color = Color(0.72, 0.74, 0.80)
const GLASS_TONE := Color(0.04, 0.05, 0.08)

# Front-face geometry, filled by _create_cabinet() and read by the screen seats.
var _face_z: float = 0.12
var _cab: Node3D

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
	_resolve_palette()
	_create_plinth()
	_create_machine_body()
	_create_display_panel()
	_create_formula_display()
	_create_history_panel()
	_create_vr_controls()
	_update_display()


## One palette word drives every part (kit finish system).
func _resolve_palette() -> void:
	var pal: Dictionary = HangarKit.finish_palette(finish)
	color_body = pal["body"]
	color_accent = pal["accent"]
	color_display_bg = pal["screen"]
	color_display_text = pal["text"]
	color_formula = pal["panel"].lightened(0.55)


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

## The footing. HangarKit.plinth builds DOWNWARD from y=0, so every authored
## body coordinate stays put and auto-grounding supplies the lift that puts the
## keypad in the reach band (G5) — the plinth is not a redesign of the face.
func _create_plinth() -> void:
	var p: Node3D = HangarKit.plinth(
		body_width + 0.06, body_depth + 0.10, plinth_height,
		finish, wear, color_accent, unit_code)
	if p:
		add_child(p)


## The body. One shell, side flanks, a service column of vent slats, and a cap
## carrying the sign band — the title is BAKED INTO the cap, not floating above
## it (G1: no text outside the body).
func _create_machine_body() -> void:
	var cab := Node3D.new()
	cab.name = "Cabinet"
	cab.set_meta("housing", true)
	add_child(cab)
	_cab = cab
	_face_z = body_depth * 0.5

	var shell: StandardMaterial3D = HangarKit.finish_body(finish, color_body, wear)
	var panel: StandardMaterial3D = HangarKit.painted_metal(
		Color(0.09, 0.09, 0.105), wear, 0.4, 0.5)
	var steel: StandardMaterial3D = HangarKit.worn_metal(color_body.lightened(0.10))
	var accent: StandardMaterial3D = HangarKit.emissive(color_accent, 2.2)

	# main shell
	cab.add_child(HangarKit.box(
		Vector3(0, body_height * 0.5, 0),
		Vector3(body_width, body_height, body_depth), shell))

	# side flanks, full height — the vertical dialect's shoulders
	for sx in [-1.0, 1.0]:
		cab.add_child(HangarKit.box(
			Vector3(sx * (body_width * 0.5 + 0.018), body_height * 0.5, 0.0),
			Vector3(0.036, body_height, body_depth + 0.02), steel))

	# cap plate + the sign band baked flush into it, over a full-width ember line
	var cap_y: float = body_height + 0.028
	cab.add_child(HangarKit.box(
		Vector3(0, cap_y, 0), Vector3(body_width + 0.05, 0.056, body_depth + 0.03), steel))
	var sign: MeshInstance3D = HangarKit.stencil(
		"PSEUDO-RANDOM GENERATOR", Vector2(body_width * 0.92, 0.030),
		color_accent.lightened(0.35))
	if sign:
		sign.position = Vector3(0, cap_y, (body_depth + 0.03) * 0.5 + 0.003)
		cab.add_child(sign)
	# ember stripe under the cap lip (G7)
	cab.add_child(HangarKit.box(
		Vector3(0, body_height - 0.006, _face_z + 0.004),
		Vector3(body_width * 0.98, 0.007, 0.006), accent))

	# service: vent slats low on the shell face, beside the keypad shoulder
	for i in range(4):
		cab.add_child(HangarKit.box(
			Vector3(0.0, 0.075 + float(i) * 0.022, _face_z + 0.002),
			Vector3(body_width * 0.52, 0.010, 0.005), panel))

	# bolted panel line down each flank
	cab.add_child(HangarKit.bolts(
		Vector3(-body_width * 0.5 + 0.022, 0.10, _face_z + 0.004),
		Vector3(-body_width * 0.5 + 0.022, body_height - 0.10, _face_z + 0.004),
		5, 0.0055, steel))
	cab.add_child(HangarKit.bolts(
		Vector3(body_width * 0.5 - 0.022, 0.10, _face_z + 0.004),
		Vector3(body_width * 0.5 - 0.022, body_height - 0.10, _face_z + 0.004),
		5, 0.0055, steel))

	# the family's three-colour bar, low on the face
	var bar: Node3D = HangarKit.three_color_bar(body_width * 0.42, 0.013)
	if bar:
		bar.position = Vector3(0.0, 0.040, _face_z + 0.005)
		cab.add_child(bar)

	# grime where the shell meets the plinth cap
	var gb: MeshInstance3D = HangarKit.grime_band(
		body_width * 0.9, 0.05, _face_z + 0.003, color_body)
	if gb:
		gb.position.y = 0.026
		cab.add_child(gb)


# ═════════════════════════════════════════════════════════════════════════════
# DISPLAYS
# ═════════════════════════════════════════════════════════════════════════════

func _create_display_panel() -> void:
	# READOUT board — the instrument's answer: seed + step on the header row,
	# the current number and its 0-1 float below. Seated at eye height.
	_readout_width = body_width * 0.78
	_readout_board = _seat_screen(
		"Readout", "NUMBER", 0.74, Vector2(_readout_width, 0.17), true)
	_rebuild_readout_board()


func _create_formula_display() -> void:
	# FORMULA board — the arithmetic. The formula line, the live per-phase
	# computation (colour-coded), and the LCG parameters. Rebuilt each phase.
	_formula_width = body_width * 0.78
	_formula_board = _seat_screen(
		"Formula", "ARITHMETIC", 0.55, Vector2(_formula_width, 0.15), false)
	_rebuild_formula_board()


func _create_history_panel() -> void:
	# HISTORY board — the emitted sequence, where periodicity becomes visible.
	_history_width = body_width * 0.78
	_history_board = _seat_screen(
		"History", "SEQUENCE", 0.36, Vector2(_history_width, 0.15), false)
	_rebuild_history_board()


## Seats one screen INTO the shell: a milled dark pocket, the lit display face,
## the family's glass over it, a header tag and an ember lip. Returns the board
## container the text block is repainted onto. A screen without a pocket is a
## poster taped to the body (G6) — the pocket is what makes it an instrument.
func _seat_screen(node_name: String, header: String, y: float,
		size: Vector2, lit: bool) -> Node3D:
	var w: float = size.x
	var h: float = size.y
	var dark: StandardMaterial3D = HangarKit.painted_metal(
		Color(0.07, 0.075, 0.09), wear, 0.35, 0.55)
	var accent: StandardMaterial3D = HangarKit.emissive(color_accent, 2.0)

	# milled pocket — the recess the screen sits in
	_cab.add_child(HangarKit.box(
		Vector3(0.0, y, _face_z + 0.002),
		Vector3(w + 0.026, h + 0.030, 0.014), dark))

	# display face (self-lit when it carries the live number)
	var face_mat: StandardMaterial3D
	if lit:
		face_mat = HangarKit.emissive(color_display_bg, 0.45)
	else:
		face_mat = HangarKit.painted_metal(color_display_bg, 0.05, 0.1, 0.5)
	_cab.add_child(HangarKit.box(
		Vector3(0.0, y, _face_z + 0.008), Vector3(w, h, 0.005), face_mat))

	# glass over the screen — the family's canonical tone, finish-independent
	var glass := StandardMaterial3D.new()
	glass.albedo_color = GLASS_TONE
	glass.roughness = 0.15
	glass.emission_enabled = true
	glass.emission = Color(0.05, 0.08, 0.12)
	glass.emission_energy_multiplier = 0.5
	_cab.add_child(HangarKit.box(
		Vector3(0.0, y, _face_z + 0.0125), Vector3(w, h, 0.004), glass))

	# ember lip along the pocket's top edge
	_cab.add_child(HangarKit.box(
		Vector3(0.0, y + h * 0.5 + 0.010, _face_z + 0.010),
		Vector3(w + 0.026, 0.005, 0.005), accent))

	# header tag, stencilled onto the shell just above the pocket
	var tag: MeshInstance3D = HangarKit.stencil(
		header, Vector2(w * 0.44, 0.017), color_accent.lightened(0.30))
	if tag:
		tag.position = Vector3(-w * 0.26, y + h * 0.5 + 0.026, _face_z + 0.004)
		_cab.add_child(tag)

	var board := Node3D.new()
	board.name = node_name + "Board"
	board.position = Vector3(0.0, y, _face_z + 0.016)
	_cab.add_child(board)
	return board


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
	# The keypad rests on a WEDGE SHOULDER cantilevered off the shell, so the
	# controls meet the body instead of hanging in air. The plinth below puts
	# this shoulder inside the VR reach band (G5).
	var shoulder_y: float = 0.18
	var wedge_w: float = body_width * 0.82
	var wedge_d: float = 0.17
	var steel: StandardMaterial3D = HangarKit.worn_metal(color_body.lightened(0.10))
	var shoulder: MeshInstance3D = HangarKit.wedge(
		wedge_w, 0.13, wedge_d, 0.055, steel)
	if shoulder:
		shoulder.position = Vector3(0.0, shoulder_y, _face_z - 0.002)
		_cab.add_child(shoulder)

	# FRAMELESS: the wedge shoulder IS the faceplate, so the panel contributes
	# only its controls. RackTemplates' own cream plate + copper accent strip live
	# in _add_panel(); skipping it keeps a light Braun faceplate from being bolted
	# onto a dark terminal body, and removes the off-family accent at the source.
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	var panel: Node3D = RackTpl.create_panel("", [
		[
			{"type": "button", "label": "CRANK"},
			{"type": "button", "label": "RESET"},
			{"type": "button", "label": "SEED"},
		],
	], true)
	# Seated ON the wedge's sloped top face, tilted to match its rake.
	panel.position = Vector3(0.0, shoulder_y + 0.062, _face_z + wedge_d * 0.52)
	panel.rotation_degrees = Vector3(-32, 0, 0)
	_align_panel_to_family(panel)
	_cab.add_child(panel)

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


## RackTemplates panels ship with their own COPPER accent (0.75,0.38,0.13) — a
## near-miss of the family accent, which reads as a different manufacturer bolted
## onto the machine (G4). Because the panel is seated INSIDE the housing here, it
## is part of this body and must speak its palette: retint the imported accent
## rather than parenting the panel outside the cabinet to hide it from the rule.
func _align_panel_to_family(node: Node) -> void:
	if node is MeshInstance3D:
		var mi: MeshInstance3D = node
		var mat: Material = mi.material_override
		if mat is StandardMaterial3D:
			var sm: StandardMaterial3D = mat
			var c: Color = sm.albedo_color
			# copper-ish: warm, mid-red, low blue — the RackTemplates accent family
			if c.r > 0.55 and c.g > 0.25 and c.g < 0.55 and c.b < 0.30:
				var fresh: StandardMaterial3D = sm.duplicate()
				fresh.albedo_color = color_accent
				if fresh.emission_enabled:
					fresh.emission = color_accent
				mi.material_override = fresh
	for child in node.get_children():
		_align_panel_to_family(child)


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
