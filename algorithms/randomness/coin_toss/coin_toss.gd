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
# critical_parameter: the coin's global_transform.basis.y — dot product with world UP determines heads vs tails
# triggers: _on_coin_dropped() sets thrown=true; velocity settling below threshold for 0.6s reads result
# emerges: the history ribbon (HHTTHHTHT...) looks random but its running average is a straight line to 0.5
# needs: XRToolsPickable coins [has]; tray + landing pad [has]; refill button [has]
# relationships: simplest case of dice_throw (2 faces vs 6); feeds galton_board (each peg is a coin toss)
# truth: The Bernoulli trial is the hydrogen atom of randomness — everything complex is built from binary choices.

extends Node3D

class_name CoinToss

const BakedText = preload("res://commons/utils/baked_text_albedo.gd")

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
@export var pad_color: Color = Color(0.08, 0.3, 0.1)  # Green felt

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

const READOUT_COLOR := Color(0.85, 0.88, 0.95)
const READOUT_ACCENT := Color(1.0, 0.82, 0.3)

var _history: Array[String] = []  # Last N results

const MAX_COINS := 8
const MAX_HISTORY := 30
const PICKABLE_SCENE = preload("res://addons/godot-xr-tools/objects/pickable.tscn")
const HIGHLIGHT_RING_SCENE = preload("res://addons/godot-xr-tools/objects/highlight/highlight_ring.tscn")


# ═════════════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	_create_pedestal()
	_create_tray()
	_create_landing_pad()
	_create_labels()
	_create_vr_controls()
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

	var heads_mat := StandardMaterial3D.new()
	heads_mat.albedo_color = color_heads
	heads_mat.metallic = 0.7
	heads_mat.roughness = 0.25
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
	tails_mat.albedo_color = color_tails
	tails_mat.metallic = 0.8
	tails_mat.roughness = 0.2
	tails_mesh.material_override = tails_mat
	tails_mesh.position.y = -coin_thickness / 4.0
	rb.add_child(tails_mesh)

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
		# Sub line reads dimmer — tint just the second quad.
		var kids := title_board.get_children()
		if kids.size() >= 2 and kids[1] is MeshInstance3D:
			var m = (kids[1] as MeshInstance3D).material_override
			if m is StandardMaterial3D:
				m.albedo_color = Color(0.62, 0.63, 0.72)
		title_board.position = Vector3(0.0, 0.30, 0.0)
		_board_anchor.add_child(title_board)

	# READOUT holder (rebuilt on change) — sits mid-band.
	_readout_holder = Node3D.new()
	_readout_holder.name = "ReadoutHolder"
	_readout_holder.position = Vector3(0.0, 0.10, 0.0)
	_board_anchor.add_child(_readout_holder)

	# HISTORY holder (rebuilt on change) — bottom band, clear gap below readout.
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


func _update_display() -> void:
	_rebuild_readout()
	_rebuild_history()
	_rebuild_result()


# ── Board rebuilders — each guarded by a cache string so the texture is only
#    re-baked when its content actually changes (no per-frame churn). ─────────

func _rebuild_readout() -> void:
	# The stats/count READOUT — all figures consolidated onto ONE multi-line
	# board so they can never overlap each other.
	var text: String
	if _total_flips == 0:
		text = "Flips: 0\n\nGrab a coin\nand toss it!"
	else:
		var ratio := float(_heads_count) / float(_total_flips)
		text = "H / T  =  %d / %d   (%.1f%%)\nHeads: %d\nTails: %d\nRatio: %.4f  (→ 0.5000)" % [
			_heads_count, _tails_count, ratio * 100.0,
			_heads_count, _tails_count, ratio
		]
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
	var panel: Node3D = RackTpl.create_panel("COIN TOSS", [
		[
			{"type": "button", "label": "REFILL"},
			{"type": "button", "label": "CLEAR"},
		],
	])
	panel.position = Vector3(-0.15, pedestal_height + 0.05, 0.12)
	panel.rotation_degrees = Vector3(-25, 0, 0)
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


func apply_grid_config(config: Dictionary) -> void:
	pass
