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
# critical_parameter: initial_seed — same seed reproduces the entire sequence; disclosure — how much of that reproducibility the machine ADMITS on its face (oracle | tally | ledger | works | origin)
# triggers: _crank() → 4-phase animation (multiply, add, mod, result) with color-coded transitions
# emerges: the history panel reveals periodicity — given enough cranks, the sequence must repeat; at disclosure:oracle the same periodicity is still there and nothing on the machine will tell you
# needs: VR push buttons [has] for CRANK/RESET/SEED
# relationships: contrasts with trng_vs_prng; feeds slot_machine understanding of pseudo-randomness
# truth: Determinism is not the opposite of randomness — it is randomness with a forgotten origin.

extends Node3D

class_name PrngCrankMachine

const BakedText = preload("res://commons/utils/baked_text_albedo.gd")
const HangarKit = preload("res://commons/artifacts/_hangar/hangar_kit.gd")

# ─────────────────────────────────────────────────────────────────────────────
# STAGE-2 DNA PROMOTION (2026-07-27). THE KIN PAIR: prng_crank_machine and
# coin_toss, 98 placements between them, and together they are this project's
# whole claim about randomness. A coin is the canonical FAIR source. An LCG is a
# DETERMINISTIC machine wearing randomness as a costume. The gap between those
# two sentences is the artifact — and until today neither machine had a knob for
# it, because every promotion pass in this corpus so far has landed on the same
# question: what is the housing made of, which institution does it belong to.
# That is the right question for a plinth. It is the wrong question for a thing
# with a crank on it.
#
# For an instrument the register is nearly irrelevant. The axis that matters is
# epistemic — what the machine makes legible and what it hides:
#
#   disclosure   how much of its own workings the machine ADMITS
#
#     oracle  <  tally  <  ledger  <  works  <  origin
#
#   oracle  a number arrives. No seed, no step, no arithmetic, no history: the
#           two lower screen seats are covered by bolted blanking plates and the
#           readout carries ONE large number and nothing else. This is the API
#           call, the slot machine, the RNG behind the loot box. It computes
#           exactly what the default computes and tells you none of it.
#   tally   + the spread. The middle seat becomes a DISTRIBUTION pocket: eight
#           bins of the 32-bit output space, drawn as lit bars over a ruled
#           baseline. What ten thousand trials look like — never how one
#           happened. The statistical alibi: "the output is uniform" is a true
#           sentence that answers a different question.
#   ledger  + the record. The SEQUENCE pocket returns: every emitted value in
#           order, which is where periodicity becomes visible at all.
#   works   + the mechanism. The ARITHMETIC pocket returns with the recurrence,
#           the live per-phase computation and a, c, m — and the seed comes back
#           onto the readout header. THIS IS THE LEGACY LINEAGE, byte for byte.
#   origin  + the substrate. A backlit register window across the top of the
#           face: SEED 42 / STATE 0x0000002A and thirty-two bit lamps, MSB left.
#           The formula is a promise; the register is the evidence. At this rung
#           the machine's "random" number is thirty-two lamps you could copy down
#           by hand and replay tomorrow, and it says so before you touch it.
#
# WHAT IS DELIBERATELY NOT THE AXIS. PHASE_DURATION is the obvious knob — 0.6 s
# per animation phase, four phases, a machine's most tempting parameter is always
# its speed. It is invisible to a still frame (info_board was swept across five
# duration exports and produced six identical tiles), and worse, it is not what
# the identity is about: "watch arithmetic unfold" is a claim about legibility,
# not tempo. So the rate stays a const and the spatial axis its justification
# actually describes is what got built. initial_seed is likewise NOT promoted: it
# changes digits, not form, and sweeping it would produce five tiles that differ
# only in which numerals are painted on the same machine.
#
# WHAT IS FORECLOSED. There is no rung at which the machine shows nothing —
# `oracle` still emits its answer, because an instrument that reports nothing is
# not a quieter instrument, it is a broken one, and the curriculum needs the
# number. So this axis has no `none`, on purpose.
#
# NOT TOUCHED, AND NOT NEGOTIABLE: the LCG itself. state = (state × a + c) mod
# 2^32 runs identically at every rung, the same seed still reproduces the same
# sequence, and the crank still takes the same four phases whether or not anyone
# is being shown them. This axis changes what the machine SAYS about its work,
# never the work.
# ─────────────────────────────────────────────────────────────────────────────

## THE AXIS — how much of its own workings this machine admits. One ordered
## ladder, monotone in disclosure: each rung shows everything the rung below it
## shows, plus one more kind of account. `works` is the legacy default.
@export_enum("oracle", "tally", "ledger", "works", "origin") var disclosure: String = "works"

## The allow-list, in ladder order — the same five words the @export_enum above
## declares, in the same spelling and the same sequence. This is what _pick_axis
## checks a map token against; DISCLOSURE_RUNGS below is the same set carrying
## its rank. Two shapes of one table because the ladder is BOTH a membership test
## and an order, and the gates in this file are all `_rung() >= n`.
const DISCLOSURES: PackedStringArray = ["oracle", "tally", "ledger", "works", "origin"]

## The ladder, as rank. The family's canonical table — coin_toss reads its rung
## through THIS dictionary and THIS function (see disclosure_name below), so the
## two artifacts cannot drift into two vocabularies for one idea the way
## exhibit_furniture and exhibit_vitrine did with `guard`.
const DISCLOSURE_RUNGS := {
	"oracle": 0,   # the answer, nothing else
	"tally": 1,    # + the aggregate
	"ledger": 2,   # + the per-trial record
	"works": 3,    # + the mechanism           ← legacy default
	"origin": 4,   # + the state that produced it
}

## The family's one reader for a disclosure token. Static so coin_toss parses
## #disclosure: through this exact function rather than its own private copy.
## An unreadable word resolves to the legacy default rather than to silence —
## a typo must not quietly seal a machine that 112 rooms expect to be open.
static func disclosure_name(raw: String) -> String:
	var v: String = raw.strip_edges().to_lower()
	if DISCLOSURE_RUNGS.has(v):
		return v
	if v != "":
		push_warning("disclosure: unknown rung '%s' — falling back to 'works'" % v)
	return "works"


## The house-pattern reader, for this instance. Same rule as disclosure_name — lower,
## strip, fall back on anything unrecognised — but instance-scoped and generic over
## the allow-list, which is the shape apply_grid_config wires every axis through.
## Kept alongside the static one rather than folded into it because coin_toss calls
## disclosure_name WITHOUT an instance; a static method cannot become an instance
## method without breaking the kin link that keeps the two machines on one vocabulary.
func _pick_axis(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = raw.strip_edges().to_lower()
	if allowed.has(v):
		return v
	if v != "":
		push_warning("prng_crank_machine: unknown value '%s' — keeping '%s'" % [v, fallback])
	return fallback


## Rank of the current rung, 0..4. Every gate in this file is `_rung() >= n`.
func _rung() -> int:
	return int(DISCLOSURE_RUNGS.get(disclosure, 3))

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

# ── Lifecycle bookkeeping ────────────────────────────────────────────────────
## True once _build_all() has run. apply_grid_config arriving BEFORE this is a
## value change with no geometry to answer it — _ready will use the new value.
var _built: bool = false
## The top-level nodes THIS script added: the plinth and the cabinet (everything
## else is parented under the cabinet). A rebuild frees exactly these and nothing
## else — get_children() here would also destroy the grid's own label plates,
## packaging and tag markers, which are added by other systems after we build.
var _owned: Array[Node] = []

# ── Internal ─────────────────────────────────────────────────────────────────
var _state: int = 42
var _step_count: int = 0
var _history: Array[int] = []

# Board containers — each holds a baked-text block that is rebuilt when its
# values change. ONE BODY: one panel per role, never two boards overlapping.
var _readout_board: Node3D    # main number + normalized + step + seed
var _formula_board: Node3D    # formula line + live computation + params
var _history_board: Node3D    # sequence header + numbers
var _dist_board: Node3D       # disclosure:tally|ledger — the bar chart of the output spread
var _register_board: Node3D   # disclosure:origin — the seed line + 32 bit lamps

# Board face geometry (metres) reused by the rebuild helpers.
var _readout_width: float = 0.34
var _formula_width: float = 0.34
var _history_width: float = 0.34
var _dist_width: float = 0.34

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
const PHASE_DURATION := 0.6  # Seconds per animation phase — NOT a DNA axis; see the promotion block

## disclosure:tally|ledger — bins of the 32-bit output space on the DISTRIBUTION board.
const DIST_BINS := 8
## disclosure:origin — the register window: 32 bits, MSB first, two rows of 16.
const REGISTER_BITS := 32
const REGISTER_ROW := 16


# ═════════════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	# The grid sets config_* metadata SYNCHRONOUSLY before add_child (see
	# GridInteractablesComponent._apply_artifact_config, line 1162 vs 1187), so the
	# meta read must happen here, before any geometry exists. apply_grid_config()
	# arrives call_deferred — i.e. after this — and is a re-read, not the read.
	_read_meta_overrides()
	_state = initial_seed
	_build_all()
	_built = true


## The whole machine, SYNCHRONOUSLY. Every child this script owns exists by the time
## this returns, which is what lets _auto_ground_artifact measure a real AABB in the
## same deferred pass. Called once from _ready and again from _rebuild_now; it reads
## `disclosure` and nothing else, so calling it twice with the same rung produces the
## same geometry (no randf anywhere in this path — the machine's only entropy is the
## LCG, and that is state, not shape).
func _build_all() -> void:
	_resolve_palette()
	_create_plinth()
	_create_machine_body()
	_create_display_panel()
	_create_formula_display()
	_create_history_panel()
	_create_state_register()
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
		_owned.append(p)


## The body. One shell, side flanks, a service column of vent slats, and a cap
## carrying the sign band — the title is BAKED INTO the cap, not floating above
## it (G1: no text outside the body).
func _create_machine_body() -> void:
	var cab := Node3D.new()
	cab.name = "Cabinet"
	cab.set_meta("housing", true)
	add_child(cab)
	_owned.append(cab)
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
	# The MIDDLE SEAT — the machine's account of itself, and the rung that decides
	# which account. works/origin get the arithmetic (the legacy path, untouched);
	# tally/ledger get the distribution instead (the spread without the cause);
	# oracle gets a bolted plate over the hole.
	var r: int = _rung()
	if r >= 3:
		# FORMULA board — the arithmetic. The formula line, the live per-phase
		# computation (colour-coded), and the LCG parameters. Rebuilt each phase.
		_formula_width = body_width * 0.78
		_formula_board = _seat_screen(
			"Formula", "ARITHMETIC", 0.55, Vector2(_formula_width, 0.15), false)
		_rebuild_formula_board()
	elif r >= 1:
		_dist_width = body_width * 0.78
		_dist_board = _seat_screen(
			"Distribution", "DISTRIBUTION", 0.55, Vector2(_dist_width, 0.15), false)
		_rebuild_distribution_board()
	else:
		_blank_seat(0.55, Vector2(body_width * 0.78, 0.15))


func _create_history_panel() -> void:
	# The LOWER SEAT — the record. Present from `ledger` up; blanked below it,
	# because a machine that keeps no visible tape is a machine whose period you
	# cannot find.
	if _rung() >= 2:
		# HISTORY board — the emitted sequence, where periodicity becomes visible.
		_history_width = body_width * 0.78
		_history_board = _seat_screen(
			"History", "SEQUENCE", 0.36, Vector2(_history_width, 0.15), false)
		_rebuild_history_board()
	else:
		_blank_seat(0.36, Vector2(body_width * 0.78, 0.15))


## A screwed-down cover where a screen seat would be. The seat still exists — the
## rebate, the plate, the two bolt lines — the instrument simply declines to fill
## it, which is a different statement from never having had one. No emissive lip,
## no header stencil: everything this seat contributed to the face's light is
## gone, which is exactly the read.
func _blank_seat(y: float, size: Vector2) -> void:
	var w: float = size.x + 0.026
	var h: float = size.y + 0.030
	var shell: StandardMaterial3D = HangarKit.finish_body(finish, color_body, wear)
	var steel: StandardMaterial3D = HangarKit.worn_metal(color_body.lightened(0.10))
	var rebate: StandardMaterial3D = HangarKit.painted_metal(
		Color(0.07, 0.075, 0.09), wear, 0.35, 0.55)
	# the shadow rebate, so the plate reads as ADDED rather than as bare shell
	_cab.add_child(HangarKit.box(
		Vector3(0.0, y, _face_z + 0.001), Vector3(w + 0.012, h + 0.012, 0.004), rebate))
	_cab.add_child(HangarKit.box(
		Vector3(0.0, y, _face_z + 0.004), Vector3(w, h, 0.008), shell))
	for sx in [-1.0, 1.0]:
		_cab.add_child(HangarKit.bolts(
			Vector3(float(sx) * (w * 0.5 - 0.015), y - h * 0.5 + 0.018, _face_z + 0.010),
			Vector3(float(sx) * (w * 0.5 - 0.015), y + h * 0.5 - 0.018, _face_z + 0.010),
			3, 0.005, steel))


## disclosure:origin — the register window across the top of the face. Seated like
## every other pocket (milled surround, backlit plate, ember rule) so it reads as
## part of the machine and not as a sticker: the claim is that this was always
## inside, not that something was bolted on.
func _create_state_register() -> void:
	if _rung() < 4:
		return
	var w: float = body_width * 0.94
	var strip_y: float = 0.899
	var strip_h: float = 0.058
	var dark: StandardMaterial3D = HangarKit.painted_metal(
		Color(0.07, 0.075, 0.09), wear, 0.35, 0.55)
	var accent: StandardMaterial3D = HangarKit.emissive(color_accent, 2.0)
	# milled surround — sits between the READOUT's header stencil (top edge 0.8595)
	# and the shell's cap ember stripe (0.9405). Those two numbers are why the
	# window is 58 mm tall and not the 90 the band looks like it has.
	_cab.add_child(HangarKit.box(
		Vector3(0.0, strip_y, _face_z + 0.002), Vector3(w + 0.020, strip_h + 0.014, 0.014), dark))
	# backlit plate — the bits are read OFF a lit window, like a nixie bank
	_cab.add_child(HangarKit.box(
		Vector3(0.0, strip_y, _face_z + 0.008), Vector3(w, strip_h, 0.005),
		HangarKit.emissive(color_display_bg, 0.5)))
	# ember rule along the window's top edge (G7, same as every pocket lip)
	_cab.add_child(HangarKit.box(
		Vector3(0.0, strip_y + strip_h * 0.5 + 0.006, _face_z + 0.010),
		Vector3(w + 0.020, 0.004, 0.005), accent))
	var board := Node3D.new()
	board.name = "RegisterBoard"
	board.position = Vector3(0.0, strip_y, _face_z + 0.014)
	_cab.add_child(board)
	_register_board = board
	_rebuild_register()


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
	var r: int = _rung()
	if r <= 0:
		# ORACLE — the answer at three times the size and nothing to check it
		# against. No seed (where it came from), no step (how far in), no float
		# (what range it lives in). One number, filling the whole pocket, which is
		# how every random source most people actually use presents itself.
		var big := BakedText.make_text_block(
			["%d" % (_state & 0xFFFFFFFF)], color_display_text, 0.09,
			_readout_width * 0.94, 0.0, true)
		if big:
			_readout_board.add_child(big)
		return
	var lines: Array = []
	if r <= 2:
		# TALLY / LEDGER — how many and where in 0-1 it landed. Still no seed: the
		# origin is precisely what these two rungs withhold.
		lines = [
			"step: %d" % _step_count,
			"%d" % (_state & 0xFFFFFFFF),
			"%.6f" % normalized,
		]
	else:
		# WORKS / ORIGIN — the legacy three lines, byte for byte, six spaces and all.
		var header := "seed: %d      step: %d" % [initial_seed, _step_count]
		lines = [
			header,
			"%d" % (_state & 0xFFFFFFFF),
			"%.6f" % normalized,
		]
	var block := BakedText.make_text_block(
		lines, color_display_text, 0.03, _readout_width * 0.94, 0.006, true)
	if block:
		_readout_board.add_child(block)


## disclosure:tally|ledger — eight bins of the 32-bit output space. The aggregate
## claim: "the output is uniform." True, and an answer to a different question
## than the one the machine is being asked, which is why this rung sits BELOW the
## arithmetic rather than beside it.
func _dist_counts() -> Array:
	var counts: Array = []
	for i in range(DIST_BINS):
		counts.append(0)
	var samples: Array = []
	if _history.is_empty():
		samples.append(_state)     # at rest the machine's only sample is its seed
	else:
		for v in _history:
			samples.append(v)
	for s in samples:
		var u: int = int(s) & 0xFFFFFFFF
		var b: int = clampi(int(float(u) / 4294967296.0 * float(DIST_BINS)), 0, DIST_BINS - 1)
		counts[b] = int(counts[b]) + 1
	return counts


func _rebuild_distribution_board() -> void:
	if _dist_board == null:
		return
	_clear_board(_dist_board)
	var counts: Array = _dist_counts()
	var top: int = 1
	for c in counts:
		if int(c) > top:
			top = int(c)
	var w: float = _dist_width * 0.94
	var h: float = 0.100
	var base_y: float = -h * 0.5 - 0.008
	var slot: float = w / float(DIST_BINS)
	var trough: StandardMaterial3D = HangarKit.painted_metal(
		Color(0.06, 0.07, 0.06), wear, 0.20, 0.70)
	var lit: StandardMaterial3D = HangarKit.emissive(color_display_text, 1.9)
	var rail: StandardMaterial3D = HangarKit.emissive(color_accent, 1.6)
	# the ruled baseline — an instrument at rest is still ruled, and an empty
	# chart that shows its own axis is honest where a blank pocket is not
	_dist_board.add_child(HangarKit.box(
		Vector3(0.0, base_y, 0.001), Vector3(w, 0.004, 0.004), rail))
	for i in range(DIST_BINS):
		var cx: float = -w * 0.5 + slot * (float(i) + 0.5)
		_dist_board.add_child(HangarKit.box(
			Vector3(cx, base_y + h * 0.5, 0.0), Vector3(slot * 0.62, h, 0.004), trough))
		var frac: float = float(int(counts[i])) / float(top)
		var bh: float = maxf(0.006, h * frac)
		_dist_board.add_child(HangarKit.box(
			Vector3(cx, base_y + bh * 0.5, 0.003), Vector3(slot * 0.52, bh, 0.005), lit))


## disclosure:origin — the seed line and the thirty-two bit lamps. MSB left, high
## half on the upper row. Rebuilt with the state, because a register that does not
## move while the machine runs would be a decoration pretending to be evidence.
func _rebuild_register() -> void:
	if _register_board == null:
		return
	_clear_board(_register_board)
	var v: int = _state & 0xFFFFFFFF
	var hex: String = String.num_int64(v, 16).to_upper()
	while hex.length() < 8:
		hex = "0" + hex
	var line: MeshInstance3D = BakedText.make_label_mesh(
		"SEED %d    STATE 0x%s" % [initial_seed, hex],
		color_display_text, Vector2(body_width * 0.80, 0.020), 1400, true)
	if line:
		line.position = Vector3(0.0, 0.0155, 0.003)
		_register_board.add_child(line)
	var on_mat: StandardMaterial3D = HangarKit.emissive(color_display_text, 2.6)
	var off_mat: StandardMaterial3D = HangarKit.painted_metal(
		Color(0.05, 0.08, 0.05), wear, 0.10, 0.75)
	for row in range(2):                               # REGISTER_BITS / REGISTER_ROW
		for col in range(REGISTER_ROW):
			var idx: int = row * REGISTER_ROW + col
			var bit: int = REGISTER_BITS - 1 - idx     # MSB at the top left
			var on: bool = ((v >> bit) & 1) == 1
			var x: float = -0.180 + 0.024 * float(col)
			var y: float = -0.009 - 0.014 * float(row)
			_register_board.add_child(HangarKit.box(
				Vector3(x, y, 0.002), Vector3(0.016, 0.010, 0.004),
				on_mat if on else off_mat))


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
	# Every rebuild below is null-guarded, so a rung that did not build a board
	# simply skips it: the crank still runs, the state still advances, the machine
	# just says less about it.
	_compute_line = ""
	_formula_line = "state = (state × a + c) mod m"
	_rebuild_readout_board()
	_rebuild_formula_board()
	_rebuild_history_board()
	_rebuild_distribution_board()
	_rebuild_register()


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
	HangarKit.harmonize(panel, finish)
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


## LATENT BUG PAID (2026-07-27): this was `pass`. Every `#token: value` a map put
## on a prng_crank_machine placement was parsed, printed to the log by
## GridInteractablesComponent, stashed as metadata — and then silently discarded,
## because nothing on this artifact ever read the metadata back. The registry now
## derives its DNA block from this file, so a token that does nothing is a
## declaration that lies. It reads its metadata now.
##
## Ordering, which is the whole reason this is not just a setter: the grid sets
## config_* metadata BEFORE add_child and calls this method call_deferred, i.e.
## after _ready has already built the body. So _ready does the real read; this is
## the re-read for direct callers (packaging, tools, tests) AND the path that makes
## a late rung actually move the geometry.
##
## THE EARLY RETURNS ARE LOAD-BEARING — both of them, and the second one especially.
## curation_station.gd:367-372 calls apply_grid_config({"emissive": false}) on every
## artifact it curates, one line after _hide_labels() has turned billboarding off,
## darkened the modulate, zeroed outlines and hidden the back-plates. That dict
## carries no disclosure key. An unconditional rebuild there would free every child
## and build fresh billboarded, outlined labels, throwing away framing that is never
## re-applied — a silent regression on every curated shelf. So: unchanged rung means
## touch nothing and say nothing.
func apply_grid_config(config: Dictionary) -> void:
	# Snapshot every value that decides geometry. `disclosure` is the only one —
	# the LCG parameters and body dimensions are @export-only and no config key
	# reads them, so nothing else can change under us here.
	var before_disclosure: String = disclosure

	for k in config.keys():
		set_meta("config_%s" % str(k), config[k])
	_read_meta_overrides()

	if not _built:
		return                      # nothing built yet; _ready will use these values
	if disclosure == before_disclosure:
		return                      # curation_station's {"emissive": false} lands here
	_rebuild_now()
	print("[PrngCrankMachine] Config applied — disclosure=%s" % [disclosure])


## Tear down what this script built and build it again, INLINE. No call_deferred:
## a deferred rebuild would leave the node empty for a frame, and _auto_ground_artifact
## — which runs later in the same deferred queue — would measure a zero AABB, return
## early, and leave the machine ungrounded.
func _rebuild_now() -> void:
	for c in _owned:
		if is_instance_valid(c):
			remove_child(c)         # leaves the tree synchronously — no double-render
			c.queue_free()
	_owned.clear()
	# Cached refs point at freed nodes now. The board rebuilds are all null-guarded,
	# so clearing these is what keeps a rung that drops a pocket from repainting into
	# a corpse.
	_cab = null
	_readout_board = null
	_formula_board = null
	_history_board = null
	_dist_board = null
	_register_board = null
	_build_all()


func _read_meta_overrides() -> void:
	if has_meta("config_disclosure"):
		# Fallback is the LEGACY rung, not the current value: an unreadable word must
		# not quietly seal a machine that 50 rooms expect open. Same rule, same table,
		# same result as the static disclosure_name() coin_toss reads through.
		disclosure = _pick_axis(str(get_meta("config_disclosure")), DISCLOSURES, "works")
