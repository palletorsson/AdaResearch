# coin_toss.gd
# Coin Toss — the simplest random experiment
# Grab a coin from the tray, flick/throw it. Lands heads or tails.
# A counter tracks the ratio converging to 0.5 over many tosses.
#
# QFEP: Bernoulli trial — the atom of probability. p = 0.5 as perfect symmetry.
#
# @identity
# essence: X ~ Bernoulli(0.5) — the atom of all probability
# desire: grab a coin, toss it, watch H/T ratio crawl toward 0.5000 one flip at a time
# critical_parameter: the coin's global_transform.basis.y — dot product with world UP determines heads vs tails; disclosure — how much of that test, and of the conditions feeding it, the console shows (oracle | tally | ledger | works | origin)
# triggers: _on_coin_dropped() sets thrown=true; velocity settling below threshold for 0.6s reads result
# emerges: the history ribbon (HHTTHHTHT...) looks random but its running average is a straight line to 0.5; at disclosure:origin the launch gauges show the spin and drop that decided it, and the fairness starts to look like ignorance
# needs: XRToolsPickable coins [has]; tray + landing pad [has]; refill button [has]
# relationships: simplest case of dice_throw (2 faces vs 6); feeds galton_board (each peg is a coin toss)
# truth: The Bernoulli trial is the hydrogen atom of randomness — everything complex is built from binary choices.

extends Node3D

class_name CoinToss

const BakedText = preload("res://commons/utils/baked_text_albedo.gd")
const HangarKit = preload("res://commons/artifacts/_hangar/hangar_kit.gd")

# ─────────────────────────────────────────────────────────────────────────────
# STAGE-2 DNA PROMOTION (2026-07-27), the junior half of a KIN PAIR. The full
# argument lives in prng_crank_machine.gd; the short version is that these two
# artifacts are this project's whole claim about randomness — the coin is the
# canonical FAIR source, the LCG is a deterministic machine in costume — and the
# axis worth having on either is not what its housing is made of but how much of
# its own workings it admits.
#
#   disclosure    oracle  <  tally  <  ledger  <  works  <  origin
#
# ONE VOCABULARY, TWO ARTIFACTS. The ladder and its reader are defined ONCE, in
# prng_crank_machine.gd, and this file parses its token through that exact
# function. That is deliberate: the exhibits family shipped `guard` as two
# disjoint word-lists on two siblings and needed a whole convergence pass to
# reunite them. Preload rather than the global class_name — the packaging family
# proved class_name lookups are not reliable headless, and every frame of the
# evidence loop is rendered headless.
#
# WHAT THE RUNGS MEAN ON A COIN:
#
#   oracle  the console face is a bolted blanking plate. No screen, no tally, no
#           ribbon — and the coins themselves are blank slugs, both faces the same
#           dull metal with no H, no T, no gold, no silver. The machine announces
#           the result on its crown and there is no way to check it against the
#           object. This is the coin toss as a verdict.
#   tally   the screen returns with the counts and nothing else. How many heads,
#           how many tails. Aggregate without account.
#   ledger  + the record: the ribbon (HHTTHT...) and, when nothing has been thrown
#           yet, its ruled empty slots. An empty ledger is still ruled paper, and
#           showing the ruling is what makes the record a promise rather than a
#           surprise.
#   works   + the model's claim about the tally: the ratio line with its arrow to
#           0.5000, the percentage, and BERNOULLI TRIAL P = 0.5 on the sign cap.
#           This is the artifact as it has always shipped, byte for byte.
#   origin  + the launch gauges: SPIN, DROP, TILT, read off the coin at the moment
#           of release. Diaconis's point made furniture — a tossed coin is
#           ordinary deterministic mechanics, and it looks fair because nobody
#           writes the initial conditions down. This rung writes them down.
#
# THE ASYMMETRY, DECLARED. The prng's ladder mostly SWAPS surfaces; this one
# mostly adds and subtracts text on one screen, because a coin console has one
# screen and a crank machine has three seats. So the tally→ledger step here is
# carried by the ribbon and its ruled empty row rather than by a whole pocket
# appearing. The same step on the prng is a whole pocket appearing. Across a room
# the token never goes quiet on both siblings at once.
#
# NOT TOUCHED: the physics, the 0.6 s settle threshold, the dot-product test, the
# statistics. A settling-time knob would have been the easy promotion and it is
# invisible to a still and irrelevant to the identity. Every rung tosses the same
# coin and counts it the same way.
# ─────────────────────────────────────────────────────────────────────────────

## The family's ladder, defined once next door. Preloaded (not class_name) so the
## reference survives headless parsing.
const Disclosure = preload("res://algorithms/randomness/prng_crank_machine/prng_crank_machine.gd")

## THE AXIS — how much of its own workings this console admits. Same five rungs,
## same order, same spellings as prng_crank_machine. `works` is the legacy default.
@export_enum("oracle", "tally", "ledger", "works", "origin") var disclosure: String = "works"

## Rank of the current rung, 0..4, read through the family's one table.
func _rung() -> int:
	return int(Disclosure.DISCLOSURE_RUNGS.get(disclosure, 3))

## Housing finish — "rams" (light Braun default) or "terminal" (dark console).
## Every colour derives from HangarKit.finish_palette(), so one word re-skins
## the whole body instead of a dozen hand-typed constants.
@export var finish: String = "terminal"
@export var wear: float = 0.10
@export var unit_code: String = "CT-04"


# ── Coin ─────────────────────────────────────────────────────────────────────
@export var coin_radius: float = 0.025
@export var coin_thickness: float = 0.003
@export var coin_mass: float = 0.03
@export var coin_bounce: float = 0.35
@export var color_heads: Color = Color(0.85, 0.72, 0.2)   # Gold
@export var color_tails: Color = Color(0.75, 0.75, 0.78)   # Silver

# ── Tray ─────────────────────────────────────────────────────────────────────
@export var tray_radius: float = 0.12
@export var tray_height: float = 0.02
@export var pedestal_height: float = 0.9
@export var tray_color: Color = Color(0.12, 0.12, 0.15)

# ── Landing Pad ──────────────────────────────────────────────────────────────
@export var pad_radius: float = 0.2
@export var pad_color: Color = Color(0.12, 0.12, 0.135)  # anthracite landing felt (family palette; green is off-family)

# ── Internal ─────────────────────────────────────────────────────────────────
var _coins: Array[RigidBody3D] = []
var _coin_states: Dictionary = {}  # instance_id → { settled: bool, result: "" }
var _total_flips: int = 0
var _heads_count: int = 0
var _tails_count: int = 0
# ── Display boards (2D-in-3D baked-text, one body — no floating labels) ───────
# Anchor for the consolidated readout stack; each board owns a vertical band
# with gaps so nothing overlaps. Boards are rebuilt only when their text
# changes (cache-string guarded) to avoid per-frame texture churn.
var _board_anchor: Node3D            # holds title + readout + history boards
var _readout_holder: Node3D          # the rebuilt stats/ratio block lives here
var _history_holder: Node3D          # the rebuilt history ribbon lives here
var _result_holder: Node3D           # the big H/T flash near the landing pad
var _readout_cache: String = ""
var _history_cache: String = ""
var _result_cache: String = ""
# disclosure:origin — the hidden variables of the last toss, read off the coin at
# the instant it leaves the hand. Display only: nothing here feeds the physics or
# the result, it is the record of conditions that were always there and never shown.
var _gauge_holder: Node3D            # the rebuilt fills + value texts
var _gauge_face_z: float = -0.168    # the backboard face the cluster is seated on
var _launch_spin: float = 0.0        # rad/s at release
var _launch_drop: float = 0.0        # metres above the console base at release
var _launch_tilt: float = 0.0        # degrees between the coin's face normal and world up

const READOUT_COLOR := Color(0.85, 0.88, 0.95)
const READOUT_ACCENT := Color(1.0, 0.82, 0.3)

var _history: Array[String] = []  # Last N results

const MAX_COINS := 8
const MAX_HISTORY := 30
## disclosure:oracle — the unmarked slug's face. Deliberately the dullest metal in
## the family palette: not a third coin colour, an ABSENCE of one.
const BLANK_FACE := Color(0.33, 0.34, 0.36)
## disclosure:ledger — the empty record, drawn as ruled slots. Ten because that is
## what fits the readout width at 0.034 line height without wrapping.
const LEDGER_RULE := "_ _ _ _ _ _ _ _ _ _"
const PICKABLE_SCENE = preload("res://addons/godot-xr-tools/objects/pickable.tscn")
const HIGHLIGHT_RING_SCENE = preload("res://addons/godot-xr-tools/objects/highlight/highlight_ring.tscn")


# ═════════════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	# The grid sets config_* metadata SYNCHRONOUSLY before add_child and calls
	# apply_grid_config() call_deferred, i.e. after this. So the read that decides
	# geometry has to happen here, first.
	_read_meta_overrides()
	_create_pedestal()
	_create_tray()
	_create_landing_pad()
	_create_labels()
	_create_vr_controls()
	_create_cabinet()
	_spawn_coins_in_tray()


func _process(_delta: float) -> void:
	# Check each active coin for settling
	for coin in _coins:
		if not is_instance_valid(coin):
			continue

		var state: Dictionary = _coin_states.get(coin.get_instance_id(), {})
		if state.get("settled", false):
			continue

		var vel := coin.linear_velocity.length()
		var ang := coin.angular_velocity.length()

		# Has it been thrown? (moved away from tray)
		if not state.get("thrown", false):
			if vel > 0.5 or coin.global_position.y > global_position.y + pedestal_height + 0.2:
				state["thrown"] = true
				state["settle_timer"] = 0.0
				_coin_states[coin.get_instance_id()] = state
			continue

		# Settling check
		if vel < 0.03 and ang < 0.2:
			state["settle_timer"] = state.get("settle_timer", 0.0) + _delta
			if state["settle_timer"] > 0.6:
				state["settled"] = true
				_coin_states[coin.get_instance_id()] = state
				_read_coin_result(coin)
		else:
			state["settle_timer"] = 0.0
			_coin_states[coin.get_instance_id()] = state

		# Cleanup coins that fell too far
		if coin.global_position.y < global_position.y - 3.0:
			_coin_states.erase(coin.get_instance_id())
			_coins.erase(coin)
			coin.queue_free()


# ═════════════════════════════════════════════════════════════════════════════
# PEDESTAL + TRAY
# ═════════════════════════════════════════════════════════════════════════════

func _create_pedestal() -> void:
	var body := StaticBody3D.new()
	body.name = "Pedestal"

	# Column
	var mesh := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.04
	cyl.bottom_radius = 0.06
	cyl.height = pedestal_height
	mesh.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.2, 0.22)
	mat.metallic = 0.5
	mat.roughness = 0.4
	mesh.material_override = mat
	mesh.position = Vector3(0, pedestal_height / 2.0, 0)
	body.add_child(mesh)

	add_child(body)


func _create_tray() -> void:
	var body := StaticBody3D.new()
	body.name = "Tray"

	# Tray base (flat disk)
	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = tray_radius
	shape.height = 0.008
	col.shape = shape
	body.add_child(col)

	var mesh := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = tray_radius
	cyl.bottom_radius = tray_radius
	cyl.height = 0.008
	mesh.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tray_color
	mat.metallic = 0.6
	mat.roughness = 0.3
	mesh.material_override = mat
	body.add_child(mesh)

	# Rim
	var rim_mat := StandardMaterial3D.new()
	rim_mat.albedo_color = Color(0.25, 0.25, 0.3)
	rim_mat.metallic = 0.7

	# Simple rim via thin torus approximation (8 segments)
	var rim_segments := 24
	for i in range(rim_segments):
		var angle := float(i) / float(rim_segments) * TAU
		var rim_body := StaticBody3D.new()

		var rim_col := CollisionShape3D.new()
		var rim_shape := BoxShape3D.new()
		rim_shape.size = Vector3(0.025, tray_height, 0.006)
		rim_col.shape = rim_shape
		rim_body.add_child(rim_col)

		var rim_mesh := MeshInstance3D.new()
		var rim_box := BoxMesh.new()
		rim_box.size = rim_shape.size
		rim_mesh.mesh = rim_box
		rim_mesh.material_override = rim_mat
		rim_body.add_child(rim_mesh)

		rim_body.position = Vector3(
			cos(angle) * tray_radius,
			tray_height / 2.0,
			sin(angle) * tray_radius
		)
		rim_body.rotation.y = -angle + PI / 2.0
		body.add_child(rim_body)

	body.position = Vector3(0, pedestal_height, 0)
	add_child(body)


# ═════════════════════════════════════════════════════════════════════════════
# LANDING PAD
# ═════════════════════════════════════════════════════════════════════════════

func _create_landing_pad() -> void:
	# A felt pad on the floor where coins land
	var body := StaticBody3D.new()
	body.name = "LandingPad"

	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = pad_radius
	shape.height = 0.01
	col.shape = shape
	body.add_child(col)

	var mesh := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = pad_radius
	cyl.bottom_radius = pad_radius
	cyl.height = 0.01
	mesh.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.albedo_color = pad_color
	mat.roughness = 0.95
	mesh.material_override = mat
	body.add_child(mesh)

	var phys := PhysicsMaterial.new()
	phys.bounce = 0.1
	phys.friction = 0.9
	body.physics_material_override = phys

	body.position = Vector3(0.35, 0.005, 0)
	add_child(body)


# ═════════════════════════════════════════════════════════════════════════════
# COINS
# ═════════════════════════════════════════════════════════════════════════════

func _spawn_coins_in_tray() -> void:
	for i in range(MAX_COINS):
		var coin := _create_coin()
		# Stack coins slightly offset in the tray
		var angle := float(i) / float(MAX_COINS) * TAU
		var r := tray_radius * 0.4
		coin.position = Vector3(
			cos(angle) * r,
			pedestal_height + 0.015 + i * (coin_thickness + 0.002),
			sin(angle) * r
		)
		add_child(coin)
		_coins.append(coin)
		_coin_states[coin.get_instance_id()] = { "settled": false, "thrown": false, "settle_timer": 0.0 }


func _create_coin() -> RigidBody3D:
	# Same grab/pick principle as grab_paper: XRTools pickable base + custom cylinder body
	var rb: XRToolsPickable = PICKABLE_SCENE.instantiate() as XRToolsPickable
	if rb == null:
		push_error("CoinToss: Failed to instantiate XRTools pickable for coin.")
		return RigidBody3D.new()

	rb.freeze = true
	rb.release_mode = XRToolsPickable.ReleaseMode.UNFROZEN
	rb.press_to_hold = true
	rb.ranged_grab_method = XRToolsPickable.RangedMethod.NONE
	rb.second_hand_grab = XRToolsPickable.SecondHandGrab.SECOND
	rb.mass = coin_mass
	rb.gravity_scale = 1.2
	rb.linear_damp = 0.2
	rb.angular_damp = 0.3
	rb.continuous_cd = true

	var phys := PhysicsMaterial.new()
	phys.bounce = coin_bounce
	phys.friction = 0.4
	rb.physics_material_override = phys

	# Collision — cylinder
	var col: CollisionShape3D = rb.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if col == null:
		col = CollisionShape3D.new()
		rb.add_child(col)
	var shape := CylinderShape3D.new()
	shape.radius = coin_radius
	shape.height = coin_thickness
	col.shape = shape

	# Highlight ring (same XR highlight behavior as grab_paper)
	var highlight: Node3D = HIGHLIGHT_RING_SCENE.instantiate() as Node3D
	if highlight:
		var ring_scale_raw: float = (coin_radius * 2.4) / 0.05
		var ring_scale: float = ring_scale_raw if ring_scale_raw > 1.0 else 1.0
		highlight.scale = Vector3.ONE * ring_scale
		rb.add_child(highlight)

	# Heads side (+Y) — gold
	var heads_mesh := MeshInstance3D.new()
	heads_mesh.name = "HeadsMesh"
	var heads_cyl := CylinderMesh.new()
	heads_cyl.top_radius = coin_radius
	heads_cyl.bottom_radius = coin_radius
	heads_cyl.height = coin_thickness / 2.0
	heads_cyl.radial_segments = 24
	heads_mesh.mesh = heads_cyl

	# disclosure:oracle — a BLANK SLUG. Both faces the same dull metal, no gold, no
	# silver, no letters: the machine's word is the only account of the outcome and
	# the object itself will not corroborate it. The dot-product test underneath is
	# untouched — the coin still lands heads exactly as often. Only your ability to
	# check it is gone, which is the whole of what this rung claims.
	var marked: bool = _rung() >= 1
	var heads_mat := StandardMaterial3D.new()
	heads_mat.albedo_color = color_heads if marked else BLANK_FACE
	heads_mat.metallic = 0.7
	heads_mat.roughness = 0.25 if marked else 0.55
	if marked:
		heads_mat.emission_enabled = true
		heads_mat.emission = color_heads * 0.2
		heads_mat.emission_energy_multiplier = 0.15
	heads_mesh.material_override = heads_mat
	heads_mesh.position.y = coin_thickness / 4.0
	rb.add_child(heads_mesh)

	# Tails side (-Y) — silver
	var tails_mesh := MeshInstance3D.new()
	tails_mesh.name = "TailsMesh"
	var tails_cyl := CylinderMesh.new()
	tails_cyl.top_radius = coin_radius
	tails_cyl.bottom_radius = coin_radius
	tails_cyl.height = coin_thickness / 2.0
	tails_cyl.radial_segments = 24
	tails_mesh.mesh = tails_cyl

	var tails_mat := StandardMaterial3D.new()
	tails_mat.albedo_color = color_tails if marked else BLANK_FACE
	tails_mat.metallic = 0.8
	tails_mat.roughness = 0.2 if marked else 0.55
	tails_mesh.material_override = tails_mat
	tails_mesh.position.y = -coin_thickness / 4.0
	rb.add_child(tails_mesh)

	if not marked:
		# no pips either — an unmarked token has no readable face
		if rb.has_signal("picked_up"):
			rb.picked_up.connect(_on_coin_picked_up.bind(rb))
		if rb.has_signal("dropped"):
			rb.dropped.connect(_on_coin_dropped.bind(rb))
		return rb

	# "H" pip on heads side
	var h_label := Label3D.new()
	h_label.text = "H"
	h_label.pixel_size = 0.0005
	h_label.font_size = 24
	h_label.modulate = Color(0.4, 0.3, 0.05)
	h_label.position = Vector3(0, coin_thickness / 2.0 + 0.0005, 0)
	h_label.rotation_degrees.x = -90
	h_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	h_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rb.add_child(h_label)

	# "T" pip on tails side
	var t_label := Label3D.new()
	t_label.text = "T"
	t_label.pixel_size = 0.0005
	t_label.font_size = 24
	t_label.modulate = Color(0.3, 0.3, 0.35)
	t_label.position = Vector3(0, -(coin_thickness / 2.0 + 0.0005), 0)
	t_label.rotation_degrees.x = 90
	t_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rb.add_child(t_label)

	if rb.has_signal("picked_up"):
		rb.picked_up.connect(_on_coin_picked_up.bind(rb))
	if rb.has_signal("dropped"):
		rb.dropped.connect(_on_coin_dropped.bind(rb))

	return rb


func _on_coin_picked_up(_pickable, coin: RigidBody3D) -> void:
	if not is_instance_valid(coin):
		return
	var state: Dictionary = _coin_states.get(coin.get_instance_id(), {})
	state["settled"] = false
	state["thrown"] = false
	state["settle_timer"] = 0.0
	_coin_states[coin.get_instance_id()] = state


func _on_coin_dropped(_pickable, coin: RigidBody3D) -> void:
	if not is_instance_valid(coin):
		return
	var state: Dictionary = _coin_states.get(coin.get_instance_id(), {})
	state["settled"] = false
	state["thrown"] = true
	state["settle_timer"] = 0.0
	_coin_states[coin.get_instance_id()] = state
	# disclosure:origin — write the initial conditions down. A pure read of state
	# the engine already has: no velocity is set, no transform is touched, the coin
	# falls exactly as it would at any other rung.
	if _gauge_holder != null:
		_launch_spin = coin.angular_velocity.length()
		_launch_drop = maxf(0.0, coin.global_position.y - global_position.y)
		var face_up: Vector3 = coin.global_transform.basis.y.normalized()
		_launch_tilt = rad_to_deg(acos(clampf(face_up.dot(Vector3.UP), -1.0, 1.0)))
		_rebuild_gauges()


func _read_coin_result(coin: RigidBody3D) -> void:
	# Which way is +Y facing? If dot(local_up, world_up) > 0, heads is up
	var local_up := coin.global_transform.basis.y.normalized()
	var dot := local_up.dot(Vector3.UP)

	var result: String
	if dot > 0.1:
		result = "H"
		_heads_count += 1
	elif dot < -0.1:
		result = "T"
		_tails_count += 1
	else:
		# Landed on edge — extremely rare, count as re-flip
		result = "E"

	if result != "E":
		_total_flips += 1
		_history.append(result)
		if _history.size() > MAX_HISTORY:
			_history.pop_front()

	_update_display()


# ═════════════════════════════════════════════════════════════════════════════
# DISPLAY
# ═════════════════════════════════════════════════════════════════════════════

func _create_labels() -> void:
	# One instrument body on the console face. Boards share a fixed-orientation
	# anchor and are stacked with clear vertical gaps so no two ever overlap:
	#   TITLE board   (static, top)
	#   READOUT board (dynamic multi-line — ratio + counts on ONE plate)
	#   HISTORY board (dynamic ribbon, below)
	# The big H/T flash lives on its own board out by the landing pad.
	_board_anchor = Node3D.new()
	_board_anchor.name = "ReadoutBoards"
	_board_anchor.position = Vector3(0.17, pedestal_height + 0.02, -0.15)
	add_child(_board_anchor)

	# TITLE + subtitle — one static two-line board.
	var title_board := BakedText.make_text_block(
		["COIN TOSS", "Bernoulli Trial   p = 0.5"],
		Color(0.9, 0.92, 0.97), 0.045, 0.36, 0.014, true)
	if title_board:
		title_board.name = "TitleBoard"
		# Sub line reads dimmer — tint just the second quad.
		var kids := title_board.get_children()
		if kids.size() >= 2 and kids[1] is MeshInstance3D:
			var m = (kids[1] as MeshInstance3D).material_override
			if m is StandardMaterial3D:
				m.albedo_color = Color(0.62, 0.63, 0.72)
		title_board.position = Vector3(0.0, 0.30, 0.0)
		_board_anchor.add_child(title_board)

	# READOUT holder (rebuilt on change) — sits mid-band. From `tally` up: the rung
	# below it has no screen to put a readout on.
	if _rung() >= 1:
		_readout_holder = Node3D.new()
		_readout_holder.name = "ReadoutHolder"
		_readout_holder.position = Vector3(0.0, 0.10, 0.0)
		_board_anchor.add_child(_readout_holder)

	# HISTORY holder (rebuilt on change) — bottom band, clear gap below readout.
	# From `ledger` up: the record is exactly what that rung is named for.
	if _rung() >= 2:
		_history_holder = Node3D.new()
		_history_holder.name = "HistoryHolder"
		_history_holder.position = Vector3(0.0, -0.10, 0.0)
		_board_anchor.add_child(_history_holder)

	# RESULT flash holder — separate board out at the landing pad.
	_result_holder = Node3D.new()
	_result_holder.name = "ResultHolder"
	_result_holder.position = Vector3(0.35, 0.5, 0.0)
	add_child(_result_holder)

	# Prime the boards with their idle text.
	_rebuild_readout()
	_rebuild_history()
	_rebuild_result()


## THE CABINET — propagation no. 4: the coin-toss console. The tray keeps
## its pedestal (the machine's leg); a BACKBOARD rises behind it carrying
## the readout screen (the floating board stack re-homes onto the glass),
## the result flash, and the sign band; the REFILL/CLEAR pad seats on a
## wedge beside the tray; vents, maroon trim, base skirt. One body.
func _create_cabinet() -> void:
	var ph: float = pedestal_height
	var bb_w: float = 0.56
	var bb_z: float = -0.205
	var bb_bot: float = ph - 0.12
	var bb_top: float = ph + 0.78
	var cap_h: float = 0.10

	var cab := Node3D.new()
	cab.name = "Cabinet"
	add_child(cab)

	# ── One palette word drives every part (kit finish system) ──────────
	var pal: Dictionary = HangarKit.finish_palette(finish)
	var col_body: Color = pal["body"]
	var col_panel: Color = pal["panel"]
	var col_accent: Color = pal["accent"]
	var ew: float = float(pal["wear"]) if finish.to_lower() == "terminal" else wear
	var shell: StandardMaterial3D = HangarKit.finish_body(finish, col_body, ew)
	var dark: StandardMaterial3D = HangarKit.painted_metal(Color(0.09, 0.09, 0.105), ew, 0.4, 0.5)
	var maroon: StandardMaterial3D = HangarKit.painted_metal(Color(0.30, 0.11, 0.09), ew)
	var steel: StandardMaterial3D = HangarKit.worn_metal(col_panel)
	var glass_mat := StandardMaterial3D.new()
	glass_mat.albedo_color = Color(0.04, 0.05, 0.08)
	glass_mat.roughness = 0.15
	glass_mat.emission_enabled = true
	glass_mat.emission = Color(0.05, 0.08, 0.12)
	glass_mat.emission_energy_multiplier = 0.6
	var accent: StandardMaterial3D = HangarKit.emissive(col_accent, 2.2)

	# backboard slab
	var bb := MeshInstance3D.new()
	var bb_mesh := BoxMesh.new()
	bb_mesh.size = Vector3(bb_w, bb_top - bb_bot, 0.07)
	bb.mesh = bb_mesh
	bb.material_override = shell
	bb.position = Vector3(0.0, (bb_bot + bb_top) / 2.0, bb_z)
	cab.add_child(bb)
	# maroon side trims
	for sx in [-1.0, 1.0]:
		var trim := MeshInstance3D.new()
		var trim_mesh := BoxMesh.new()
		trim_mesh.size = Vector3(0.05, bb_top - bb_bot, 0.09)
		trim.mesh = trim_mesh
		trim.material_override = maroon
		trim.position = Vector3(sx * (bb_w / 2.0 + 0.025), (bb_bot + bb_top) / 2.0, bb_z)
		cab.add_child(trim)

	# inset readout screen — the board stack re-homes onto this glass
	var scr_w: float = 0.42
	var scr_h: float = 0.40
	var scr_y: float = ph + 0.26
	var face_z: float = bb_z + 0.037
	if _rung() >= 1:
		var pocket := MeshInstance3D.new()
		var pocket_mesh := BoxMesh.new()
		pocket_mesh.size = Vector3(scr_w + 0.02, scr_h + 0.04, 0.014)
		pocket.mesh = pocket_mesh
		pocket.material_override = dark
		pocket.position = Vector3(0.0, scr_y, face_z + 0.002)
		cab.add_child(pocket)
		var glass := MeshInstance3D.new()
		var glass_mesh := BoxMesh.new()
		glass_mesh.size = Vector3(scr_w, scr_h, 0.006)
		glass.mesh = glass_mesh
		glass.material_override = glass_mat
		glass.position = Vector3(0.0, scr_y - 0.006, face_z + 0.010)
		cab.add_child(glass)
		var head_tag: Node3D = BakedText.make_tag(
			"TALLY", Color(0.92, 0.93, 0.97), 0.020,
			Color(0.055, 0.06, 0.075), true, Color(0.86, 0.30, 0.10))
		if head_tag:
			head_tag.position = Vector3(0.0, scr_y + scr_h / 2.0 + 0.012, face_z + 0.014)
			cab.add_child(head_tag)
		var stripe := MeshInstance3D.new()
		var stripe_mesh := BoxMesh.new()
		stripe_mesh.size = Vector3(scr_w + 0.02, 0.005, 0.004)
		stripe.mesh = stripe_mesh
		stripe.material_override = accent
		stripe.position = Vector3(0.0, scr_y + scr_h / 2.0 - 0.002, face_z + 0.012)
		cab.add_child(stripe)
	else:
		# disclosure:oracle — the screen seat, screwed shut. The rebate, the plate,
		# two bolt lines, and nothing lit. This removes the single brightest thing on
		# the artifact, which is the point: the console is still here, it has simply
		# stopped accounting for itself.
		var rebate := MeshInstance3D.new()
		var rebate_mesh := BoxMesh.new()
		rebate_mesh.size = Vector3(scr_w + 0.05, scr_h + 0.07, 0.004)
		rebate.mesh = rebate_mesh
		rebate.material_override = dark
		rebate.position = Vector3(0.0, scr_y, face_z + 0.001)
		cab.add_child(rebate)
		var cover := MeshInstance3D.new()
		var cover_mesh := BoxMesh.new()
		cover_mesh.size = Vector3(scr_w + 0.02, scr_h + 0.04, 0.010)
		cover.mesh = cover_mesh
		cover.material_override = shell
		cover.position = Vector3(0.0, scr_y, face_z + 0.005)
		cab.add_child(cover)
		for bx in [-1.0, 1.0]:
			cab.add_child(HangarKit.bolts(
				Vector3(float(bx) * (scr_w / 2.0 - 0.005), scr_y - scr_h / 2.0 + 0.010, face_z + 0.011),
				Vector3(float(bx) * (scr_w / 2.0 - 0.005), scr_y + scr_h / 2.0 + 0.010, face_z + 0.011),
				4, 0.007, steel))

	# retire the floating title (the cap sign owns the name now); re-home the
	# live boards INTO the screen, result flash to the backboard's crown
	if _board_anchor != null and is_instance_valid(_board_anchor):
		var tb: Node = _board_anchor.get_node_or_null("TitleBoard")
		if tb != null:
			tb.queue_free()
		_board_anchor.position = Vector3(0.0, scr_y - 0.04, face_z + 0.014)
	if _result_holder != null and is_instance_valid(_result_holder):
		_result_holder.position = Vector3(0.0, bb_top - 0.06, bb_z + 0.06)  # seated on the crown, not floating above the cap

	# keypad wedge (left of the tray, on the console deck)
	var wedge := _make_wedge(0.20, 0.13, 0.060, 0.018, dark)
	wedge.position = Vector3(-0.205, ph + 0.055, -0.005)
	cab.add_child(wedge)
	# deck under wedge + tray shoulder — ties pedestal, tray and pad together
	var deck := MeshInstance3D.new()
	var deck_mesh := BoxMesh.new()
	deck_mesh.size = Vector3(0.62, 0.05, 0.34)
	deck.mesh = deck_mesh
	deck.material_override = shell
	deck.position = Vector3(-0.04, ph - 0.028, -0.02)
	cab.add_child(deck)

	# vent slats at the backboard base
	for gi in range(5):
		var slat := MeshInstance3D.new()
		var slat_mesh := BoxMesh.new()
		slat_mesh.size = Vector3(0.30, 0.008, 0.010)
		slat.mesh = slat_mesh
		slat.material_override = dark
		slat.position = Vector3(0.0, bb_bot + 0.03 + float(gi) * 0.020, face_z + 0.002)
		cab.add_child(slat)

	# sign cap
	var cap := MeshInstance3D.new()
	var cap_mesh := BoxMesh.new()
	cap_mesh.size = Vector3(bb_w + 0.10, cap_h, 0.11)
	cap.mesh = cap_mesh
	cap.material_override = shell
	cap.position = Vector3(0.0, bb_top + cap_h / 2.0, bb_z)
	cab.add_child(cap)
	var cap_stripe := MeshInstance3D.new()
	var cap_stripe_mesh := BoxMesh.new()
	cap_stripe_mesh.size = Vector3(bb_w + 0.10, 0.006, 0.004)
	cap_stripe.mesh = cap_stripe_mesh
	cap_stripe.material_override = accent
	cap_stripe.position = Vector3(0.0, bb_top + 0.004, bb_z + 0.058)
	cab.add_child(cap_stripe)
	var sign := MeshInstance3D.new()
	var sign_mesh := BoxMesh.new()
	sign_mesh.size = Vector3(bb_w - 0.02, 0.066, 0.012)
	sign.mesh = sign_mesh
	sign.material_override = dark
	sign.position = Vector3(0.0, bb_top + cap_h / 2.0, bb_z + 0.056)
	cab.add_child(sign)
	var sign_title: Node3D = BakedText.make_tag(
		"COIN TOSS", Color(0.93, 0.94, 0.97), 0.030,
		Color(0.07, 0.075, 0.09), false, Color(0, 0, 0, 0))
	if sign_title:
		sign_title.position = Vector3(0.0, bb_top + cap_h / 2.0 + 0.012, bb_z + 0.064)
		cab.add_child(sign_title)
	# The MODEL, printed on the building. p = 0.5 is not an observation, it is the
	# claim the tally is being measured against — so it belongs to `works`, the rung
	# where the machine starts explaining itself, and not to the rungs that only
	# count. The name COIN TOSS above it stays at every rung: a machine may decline
	# to explain itself, it may not decline to say what it is.
	if _rung() >= 3:
		var sign_sub: Node3D = BakedText.make_tag(
			"BERNOULLI TRIAL  P = 0.5", Color(0.55, 0.58, 0.66), 0.014,
			Color(0.07, 0.075, 0.09), false, Color(0, 0, 0, 0))
		if sign_sub:
			sign_sub.position = Vector3(0.0, bb_top + cap_h / 2.0 - 0.018, bb_z + 0.064)
			cab.add_child(sign_sub)

	# base skirt around the pedestal foot
	var skirt := MeshInstance3D.new()
	var skirt_mesh := BoxMesh.new()
	skirt_mesh.size = Vector3(0.40, 0.07, 0.40)
	skirt.mesh = skirt_mesh
	skirt.material_override = dark
	skirt.position = Vector3(0.0, 0.035, -0.06)
	cab.add_child(skirt)


## Right-triangle prism shoulder (shared cabinet grammar — see galton_board).

	# ── Kit details: the manufactured read the station props carry ──────
	cab.add_child(HangarKit.bolts(
		Vector3(bb_w / 2.0 + 0.02, bb_bot + 0.06, bb_z + 0.040),
		Vector3(bb_w / 2.0 + 0.02, bb_top - 0.08, bb_z + 0.040),
		7, 0.008, steel))
	var bar: Node3D = HangarKit.three_color_bar(0.24, 0.015)
	if bar:
		bar.position = Vector3(0.0, scr_y - scr_h / 2.0 - 0.055, bb_z + 0.042)
		cab.add_child(bar)
	var code: MeshInstance3D = HangarKit.stencil(unit_code, Vector2(0.11, 0.028),
		col_accent.lightened(0.25))
	if code:
		code.position = Vector3(-bb_w / 2.0 + 0.09, bb_bot + 0.10, bb_z + 0.040)
		cab.add_child(code)
	var gb: MeshInstance3D = HangarKit.grime_band(bb_w * 0.9, 0.05, bb_z + 0.038, col_body)
	if gb:
		gb.position.y = bb_bot              # keep the kit's baked z
		cab.add_child(gb)

	_build_launch_gauges(cab, face_z, col_accent)


## disclosure:origin — the launch gauge cluster, in the open band of backboard
## between the screen's TALLY tag (top edge 1.384) and the result flash on the
## crown. Three lit windows: SPIN, DROP, TILT, read off the coin at release.
##
## This is the rung's whole argument. A tossed coin is not random — it is rigid-body
## mechanics with a known solution, and Diaconis showed a machine that flips heads
## every single time. It reads as fair because the initial conditions are never
## written down. So the top of this ladder is not more statistics; it is the three
## numbers the fairness was hiding behind.
##
## DISPLAY ONLY. Nothing here is read back by the physics, the settle test or the
## tally. The gauges report conditions that were always present and never shown.
func _build_launch_gauges(cab: Node3D, face_z: float, col_accent: Color) -> void:
	if _rung() < 4:
		return
	var dark: StandardMaterial3D = HangarKit.painted_metal(Color(0.07, 0.075, 0.09), wear, 0.35, 0.55)
	var accent: StandardMaterial3D = HangarKit.emissive(col_accent, 2.2)
	var screen: StandardMaterial3D = HangarKit.emissive(Color(0.05, 0.10, 0.06), 0.5)
	# milled surround + ember rule, same grammar as the screen pocket below it
	cab.add_child(HangarKit.box(
		Vector3(0.0, 1.458, face_z + 0.002), Vector3(0.50, 0.138, 0.014), dark))
	cab.add_child(HangarKit.box(
		Vector3(0.0, 1.5285, face_z + 0.010), Vector3(0.50, 0.004, 0.005), accent))
	var head: MeshInstance3D = HangarKit.stencil(
		"INITIAL CONDITIONS", Vector2(0.28, 0.016), col_accent.lightened(0.30))
	if head:
		head.position = Vector3(0.0, 1.512, face_z + 0.012)
		cab.add_child(head)
	var labels: Array = ["SPIN", "DROP", "TILT"]
	for k in range(3):
		var gx: float = -0.16 + 0.16 * float(k)
		cab.add_child(HangarKit.box(
			Vector3(gx, 1.447, face_z + 0.008), Vector3(0.145, 0.078, 0.005), screen))
		cab.add_child(HangarKit.box(
			Vector3(gx, 1.449, face_z + 0.012), Vector3(0.118, 0.020, 0.004),
			HangarKit.painted_metal(Color(0.04, 0.06, 0.05), wear, 0.15, 0.70)))
		var lab: MeshInstance3D = HangarKit.stencil(
			str(labels[k]), Vector2(0.072, 0.013), Color(0.62, 0.66, 0.72))
		if lab:
			lab.position = Vector3(gx, 1.474, face_z + 0.013)
			cab.add_child(lab)
	_gauge_face_z = face_z
	_gauge_holder = Node3D.new()
	_gauge_holder.name = "LaunchGauges"
	cab.add_child(_gauge_holder)
	_rebuild_gauges()


## Repaint the three fills and their value lines. Called once at build and again on
## every release. At rest all three read zero and the fills are a 10 mm nub hard
## against the left stop — an instrument at zero, not an instrument pretending.
func _rebuild_gauges() -> void:
	if _gauge_holder == null:
		return
	var face_z: float = _gauge_face_z
	for c in _gauge_holder.get_children():
		c.queue_free()
	var lit: StandardMaterial3D = HangarKit.emissive(Color(0.45, 0.95, 0.50), 1.9)
	var fracs: Array = [
		clampf(_launch_spin / 25.0, 0.0, 1.0),
		clampf(_launch_drop / 1.6, 0.0, 1.0),
		clampf(_launch_tilt / 180.0, 0.0, 1.0),
	]
	var texts: Array = [
		"%.1f rad/s" % _launch_spin,
		"%.2f m" % _launch_drop,
		"%d deg" % int(round(_launch_tilt)),
	]
	for k in range(3):
		var gx: float = -0.16 + 0.16 * float(k)
		var fw: float = maxf(0.010, 0.118 * float(fracs[k]))
		_gauge_holder.add_child(HangarKit.box(
			Vector3(gx - 0.059 + fw * 0.5, 1.449, face_z + 0.015),
			Vector3(fw, 0.016, 0.005), lit))
		var val: MeshInstance3D = BakedText.make_label_mesh(
			str(texts[k]), Color(0.72, 0.88, 0.76), Vector2(0.100, 0.014), 1400, true)
		if val:
			val.position = Vector3(gx, 1.424, face_z + 0.013)
			_gauge_holder.add_child(val)


func _make_wedge(w: float, h: float, d_bottom: float, d_top: float, mat: Material) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var x0: float = -w / 2.0
	var x1: float = w / 2.0
	var y0: float = -h / 2.0
	var y1: float = h / 2.0
	var bbl := Vector3(x0, y0, 0.0)
	var bbr := Vector3(x1, y0, 0.0)
	var btl := Vector3(x0, y1, 0.0)
	var btr := Vector3(x1, y1, 0.0)
	var fbl := Vector3(x0, y0, d_bottom)
	var fbr := Vector3(x1, y0, d_bottom)
	var ftl := Vector3(x0, y1, d_top)
	var ftr := Vector3(x1, y1, d_top)
	var faces := [
		[fbl, fbr, ftr, ftl],
		[bbr, bbl, btl, btr],
		[bbl, fbl, ftl, btl],
		[fbr, bbr, btr, ftr],
		[btl, ftl, ftr, btr],
		[bbl, bbr, fbr, fbl],
	]
	for f in faces:
		st.add_vertex(f[0]); st.add_vertex(f[1]); st.add_vertex(f[2])
		st.add_vertex(f[0]); st.add_vertex(f[2]); st.add_vertex(f[3])
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = mat
	return mi


func _update_display() -> void:
	_rebuild_readout()
	_rebuild_history()
	_rebuild_result()


# ── Board rebuilders — each guarded by a cache string so the texture is only
#    re-baked when its content actually changes (no per-frame churn). ─────────

func _rebuild_readout() -> void:
	# The stats/count READOUT — all figures consolidated onto ONE multi-line
	# board so they can never overlap each other.
	if _readout_holder == null:
		return                      # disclosure:oracle — there is no screen to write on
	var r: int = _rung()
	var text: String
	if r >= 3:
		# WORKS / ORIGIN — the legacy strings, byte for byte, arrow and all.
		if _total_flips == 0:
			text = "Flips: 0\n\nGrab a coin\nand toss it!"
		else:
			var ratio := float(_heads_count) / float(_total_flips)
			text = "H / T  =  %d / %d   (%.1f%%)\nHeads: %d\nTails: %d\nRatio: %.4f  (→ 0.5000)" % [
				_heads_count, _tails_count, ratio * 100.0,
				_heads_count, _tails_count, ratio
			]
	else:
		# TALLY / LEDGER — the raw counts only. The percentage and the "→ 0.5000"
		# are not observations, they are the model's claim about the observation,
		# and a machine that only counts has not made that claim yet.
		text = "Heads: %d\nTails: %d" % [_heads_count, _tails_count]
		if r >= 2:
			# LEDGER — the record's own heading, and its ruled slots while empty.
			text += "\n\nsequence:"
			if _history.is_empty():
				text += "\n" + LEDGER_RULE
	if text == _readout_cache:
		return
	_readout_cache = text
	for c in _readout_holder.get_children():
		c.queue_free()
	var lines := text.split("\n")
	var arr: Array = []
	for l in lines:
		arr.append(l)
	var block := BakedText.make_text_block(arr, READOUT_COLOR, 0.034, 0.36, 0.012, true)
	if block:
		_readout_holder.add_child(block)


func _rebuild_history() -> void:
	# The history ribbon (HHTTHT...) on its own spaced board.
	if _history_holder == null:
		return                      # disclosure:oracle|tally — no record is kept on the face
	var text := " ".join(_history)
	if text == _history_cache:
		return
	_history_cache = text
	for c in _history_holder.get_children():
		c.queue_free()
	if text.strip_edges() == "":
		return
	var tag := BakedText.make_tag(text, Color(0.6, 0.62, 0.68), 0.05,
		Color(0.06, 0.07, 0.09), false, READOUT_ACCENT)
	if tag:
		_history_holder.add_child(tag)


func _rebuild_result() -> void:
	# The big single-glyph H/T flash out at the landing pad.
	var last := _history[_history.size() - 1] if _history.size() > 0 else ""
	if last == _result_cache:
		return
	_result_cache = last
	for c in _result_holder.get_children():
		c.queue_free()
	if last == "":
		return
	var col := color_heads if last == "H" else color_tails
	var flash := BakedText.make_tag(last, col, 0.22, Color(0.05, 0.06, 0.08),
		true, col)
	if flash:
		_result_holder.add_child(flash)


# ═════════════════════════════════════════════════════════════════════════════
# VR CONTROLS
# ═════════════════════════════════════════════════════════════════════════════

func _create_vr_controls() -> void:
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	var panel: Node3D = RackTpl.create_panel("", [
		[
			{"type": "button", "label": "REFILL"},
			{"type": "button", "label": "CLEAR"},
		],
	])
	# seated on the console's wedge shoulder (all-in-one body)
	panel.position = Vector3(-0.205, pedestal_height + 0.06, 0.055)
	panel.rotation_degrees = Vector3(-18, 0, 0)
	panel.scale = Vector3(0.8, 0.8, 0.8)
	add_child(panel)

	# REFILL (Btn_0)
	var refill_btn: Node = panel.find_child("Btn_0", true, false)
	if refill_btn:
		var area = refill_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _refill_tray())

	# CLEAR (Btn_1)
	var clear_btn: Node = panel.find_child("Btn_1", true, false)
	if clear_btn:
		var area = clear_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _reset_stats())


func _refill_tray() -> void:
	# Remove all existing coins
	for coin in _coins:
		if is_instance_valid(coin):
			_coin_states.erase(coin.get_instance_id())
			coin.queue_free()
	_coins.clear()

	# Spawn fresh
	_spawn_coins_in_tray()


func _reset_stats() -> void:
	_total_flips = 0
	_heads_count = 0
	_tails_count = 0
	_history.clear()
	_rebuild_readout()
	_rebuild_history()
	_rebuild_result()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


## LATENT BUG PAID (2026-07-27): this was `pass`. GridInteractablesComponent parsed
## every `#token: value` on a coin_toss placement, logged it, stashed it as metadata
## and then nothing on this artifact ever read it back — so any map that tried to
## configure a coin toss was configuring nothing, silently. It reads its metadata now.
## The grid sets that metadata BEFORE add_child and calls this method deferred, so
## _ready does the read that decides geometry; this is the re-read for direct callers.
func apply_grid_config(config: Dictionary) -> void:
	for k in config.keys():
		set_meta("config_%s" % str(k), config[k])
	_read_meta_overrides()


func _read_meta_overrides() -> void:
	if has_meta("config_disclosure"):
		disclosure = Disclosure.disclosure_name(str(get_meta("config_disclosure")))
