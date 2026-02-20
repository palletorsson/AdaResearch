# coin_toss.gd
# Coin Toss — the simplest random experiment
# Grab a coin from the tray, flick/throw it. Lands heads or tails.
# A counter tracks the ratio converging to 0.5 over many tosses.
#
# QFEP: Bernoulli trial — the atom of probability. p = 0.5 as perfect symmetry.

extends Node3D

class_name CoinToss

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
var _ratio_label: Label3D
var _result_label: Label3D
var _stats_label: Label3D
var _history_label: Label3D
var _history: Array[String] = []  # Last N results

const MAX_COINS := 8
const MAX_HISTORY := 30
const PUSH_BUTTON = preload("res://commons/interactables/push_button.tscn")


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
	var rb := RigidBody3D.new()
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
	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = coin_radius
	shape.height = coin_thickness
	col.shape = shape
	rb.add_child(col)

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

	return rb


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
	# Title
	var title := Label3D.new()
	title.text = "COIN TOSS"
	title.pixel_size = 0.002
	title.font_size = 18
	title.modulate = Color(0.9, 0.9, 0.95)
	title.position = Vector3(0.17, pedestal_height + 0.25, -0.15)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)

	var sub := Label3D.new()
	sub.text = "Bernoulli Trial  p = 0.5"
	sub.pixel_size = 0.0014
	sub.font_size = 11
	sub.modulate = Color(0.6, 0.6, 0.7)
	sub.position = Vector3(0.17, pedestal_height + 0.22, -0.15)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(sub)

	# Big ratio display
	_ratio_label = Label3D.new()
	_ratio_label.name = "RatioLabel"
	_ratio_label.text = "H/T = ?/?"
	_ratio_label.pixel_size = 0.003
	_ratio_label.font_size = 24
	_ratio_label.modulate = Color(1.0, 0.95, 0.5)
	_ratio_label.position = Vector3(0.17, pedestal_height + 0.14, -0.15)
	_ratio_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_ratio_label)

	# Result flash
	_result_label = Label3D.new()
	_result_label.name = "ResultLabel"
	_result_label.text = ""
	_result_label.pixel_size = 0.006
	_result_label.font_size = 48
	_result_label.modulate = Color(1.0, 0.9, 0.3)
	_result_label.position = Vector3(0.35, 0.5, 0)
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_result_label)

	# Stats
	_stats_label = Label3D.new()
	_stats_label.name = "StatsLabel"
	_stats_label.text = "Flips: 0\n\nGrab a coin\nand toss it!"
	_stats_label.pixel_size = 0.0012
	_stats_label.font_size = 10
	_stats_label.modulate = Color(0.75, 0.75, 0.8)
	_stats_label.position = Vector3(0.17, pedestal_height + 0.04, -0.15)
	_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_child(_stats_label)

	# History ribbon
	_history_label = Label3D.new()
	_history_label.name = "HistoryLabel"
	_history_label.text = ""
	_history_label.pixel_size = 0.001
	_history_label.font_size = 10
	_history_label.modulate = Color(0.5, 0.5, 0.55)
	_history_label.position = Vector3(0.17, pedestal_height - 0.02, -0.15)
	_history_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_history_label)


func _update_display() -> void:
	if _total_flips == 0:
		return

	var ratio := float(_heads_count) / float(_total_flips)

	_ratio_label.text = "H/T = %d/%d  (%.1f%%)" % [_heads_count, _tails_count, ratio * 100.0]

	var last := _history[_history.size() - 1] if _history.size() > 0 else ""
	_result_label.text = last
	if last == "H":
		_result_label.modulate = color_heads
	else:
		_result_label.modulate = color_tails

	_stats_label.text = "Flips: %d\nHeads: %d\nTails: %d\nRatio: %.4f\n(→ 0.5000)" % [
		_total_flips, _heads_count, _tails_count, ratio
	]

	_history_label.text = " ".join(_history)


# ═════════════════════════════════════════════════════════════════════════════
# VR CONTROLS
# ═════════════════════════════════════════════════════════════════════════════

func _create_vr_controls() -> void:
	var panel := Node3D.new()
	panel.name = "ControlPanel"
	panel.position = Vector3(-0.15, pedestal_height - 0.15, 0)
	panel.rotation_degrees = Vector3(-20, 30, 0)
	add_child(panel)

	var back := MeshInstance3D.new()
	var back_mesh := BoxMesh.new()
	back_mesh.size = Vector3(0.15, 0.06, 0.006)
	back.mesh = back_mesh
	var back_mat := StandardMaterial3D.new()
	back_mat.albedo_color = Color(0.06, 0.06, 0.08)
	back.material_override = back_mat
	back.position.z = -0.006
	panel.add_child(back)

	# REFILL button — respawn coins in tray
	var refill_btn := PUSH_BUTTON.instantiate()
	refill_btn.name = "RefillBtn"
	refill_btn.position = Vector3(-0.04, 0.0, 0)
	refill_btn.scale = Vector3(0.6, 0.6, 0.6)
	panel.add_child(refill_btn)
	_add_button_label(refill_btn, "REFILL")

	var refill_area := refill_btn.get_node_or_null("InteractableAreaButton")
	if refill_area:
		refill_area.button_pressed.connect(func(_b): _refill_tray())

	# CLEAR button
	var clear_btn := PUSH_BUTTON.instantiate()
	clear_btn.name = "ClearBtn"
	clear_btn.position = Vector3(0.04, 0.0, 0)
	clear_btn.scale = Vector3(0.6, 0.6, 0.6)
	panel.add_child(clear_btn)
	_add_button_label(clear_btn, "CLEAR")

	var clear_area := clear_btn.get_node_or_null("InteractableAreaButton")
	if clear_area:
		clear_area.button_pressed.connect(func(_b): _reset_stats())


func _add_button_label(btn: Node, text: String) -> void:
	var lbl := Label3D.new()
	lbl.text = text
	lbl.pixel_size = 0.001
	lbl.font_size = 8
	lbl.position = Vector3(0, -0.02, 0)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.add_child(lbl)


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
	_ratio_label.text = "H/T = ?/?"
	_result_label.text = ""
	_stats_label.text = "Flips: 0\n\nGrab a coin\nand toss it!"
	_history_label.text = ""
