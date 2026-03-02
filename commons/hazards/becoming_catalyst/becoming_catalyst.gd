# BecomingCatalyst.gd
# The Becoming Catalyst — an evolving hand force that grows with the curriculum.
# Not a weapon of destruction but a tool of transformation, becoming, and
# boundary dissolution.  Each Lab sequence unlocks a new expressive mode.
#
# Pickup behavior: the crystal shrinks into the hand and is absorbed.
# The hand permanently gains its power — trigger fires projectiles.
# The crystal is consumed. The hand is free to grab other things.
#
# QFEP arc: from order (primitives) through entropy (randomness) to the
# edge of chaos (fractals, L-systems) and collective emergence (swarm).
extends XRToolsPickable
class_name BecomingCatalyst

# ── Mode Definitions ──────────────────────────────────────────────────────
# Each entry maps a mode_id to its metadata and factory script.
const MODE_DEFS: Array[Dictionary] = [
	{"id": "primitives",     "order": 1,  "name": "Primitives",     "sequence": "primitives",         "script": "res://commons/hazards/becoming_catalyst/modes/mode_primitives.gd"},
	{"id": "transformation", "order": 2,  "name": "Transformation", "sequence": "transformation",     "script": "res://commons/hazards/becoming_catalyst/modes/mode_transformation.gd"},
	{"id": "chromatic",      "order": 3,  "name": "Chromatic",      "sequence": "color",              "script": "res://commons/hazards/becoming_catalyst/modes/mode_chromatic.gd"},
	{"id": "forces",         "order": 4,  "name": "Forces",         "sequence": "forces",             "script": "res://commons/hazards/becoming_catalyst/modes/mode_forces.gd"},
	{"id": "waveform",       "order": 6,  "name": "Waveform",       "sequence": "wavefunctions",      "script": "res://commons/hazards/becoming_catalyst/modes/mode_waveform.gd"},
	{"id": "chaos",          "order": 7,  "name": "Chaos",          "sequence": "randomness",         "script": "res://commons/hazards/becoming_catalyst/modes/mode_chaos.gd"},
	{"id": "fractal",        "order": 10, "name": "Fractal",        "sequence": "fractals",           "script": "res://commons/hazards/becoming_catalyst/modes/mode_fractal.gd"},
	{"id": "cellular",       "order": 9,  "name": "Cellular",       "sequence": "cellularautomata",   "script": "res://commons/hazards/becoming_catalyst/modes/mode_cellular.gd"},
	{"id": "branching",      "order": 11, "name": "Branching",      "sequence": "lsystems",           "script": "res://commons/hazards/becoming_catalyst/modes/mode_branching.gd"},
	{"id": "swarm",          "order": 14, "name": "Swarm",          "sequence": "swarmintelligence",  "script": "res://commons/hazards/becoming_catalyst/modes/mode_swarm.gd"},
]

# ── State ─────────────────────────────────────────────────────────────────
var unlocked_modes: Array[String] = ["primitives"]
var current_mode_index: int = 0
var fire_cooldown: float = 0.0
var is_held: bool = false
var _absorbed: bool = false
var controller: XRController3D = null

# Mode switching debounce
var _stick_debounce: float = 0.0
const STICK_THRESHOLD := 0.7
const STICK_COOLDOWN := 0.3

# Tip marker — where projectiles spawn
var _tip: Marker3D = null
var _mode_label: Label3D = null
var _mode_label_timer: float = 0.0
var _collision_shape: CollisionShape3D = null

# Held glow
var _held_glow: OmniLight3D = null
var _pickup_tween: Tween = null

# ── Signals ───────────────────────────────────────────────────────────────
signal mode_changed(mode_id: String)
signal mode_unlocked(mode_id: String)
signal projectile_fired(mode_id: String, position: Vector3)

# ═════════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	super()

	_setup_physics()
	_build_tip()
	_build_mode_label()
	_load_unlocked_modes()

	add_to_group("catalyst")
	add_to_group("tool")

	# XRToolsPickable signals
	picked_up.connect(_on_picked_up)
	dropped.connect(_on_dropped)

	# Glow light (visible only when held)
	_held_glow = OmniLight3D.new()
	_held_glow.name = "HeldGlow"
	_held_glow.light_color = Color(0.7, 0.7, 1.0)
	_held_glow.light_energy = 0.0
	_held_glow.omni_range = 0.8
	_held_glow.omni_attenuation = 2.0
	add_child(_held_glow)

	# Build initial visual
	_rebuild_visual()

	# Try to connect to progression managers
	call_deferred("_connect_progression_signals")

	print("[Catalyst] Ready — modes: %s" % [unlocked_modes])

func _physics_process(delta: float) -> void:
	fire_cooldown = maxf(0.0, fire_cooldown - delta)
	_stick_debounce = maxf(0.0, _stick_debounce - delta)

	# Mode label fade
	if _mode_label_timer > 0.0:
		_mode_label_timer -= delta
		if _mode_label_timer <= 0.0 and _mode_label:
			_mode_label.visible = false

	# Hand glow pulse — the absorbed power breathes
	if is_held and _held_glow:
		var pulse := 1.5 + sin(Time.get_ticks_msec() / 400.0) * 0.5
		_held_glow.light_energy = pulse

	# Mode switching (only when held)
	if is_held:
		_check_mode_switch()

# ═════════════════════════════════════════════════════════════════════════
# FIRING
# ═════════════════════════════════════════════════════════════════════════

## Called by XRToolsFunctionPickup when the trigger is pressed (pre-absorb only).
func action() -> void:
	super()
	if not _absorbed:
		_fire()

## Direct controller button handler — the primary trigger path once absorbed.
func _on_controller_button(button_name: String) -> void:
	if button_name == "trigger_click":
		_fire()

func _fire() -> void:
	if not is_held or fire_cooldown > 0.0:
		return

	var mode_def := _get_current_mode_def()
	if mode_def.is_empty():
		return

	# Fire from the controller (hand), not the crystal
	var spawn_pos: Vector3
	var fire_dir: Vector3
	if controller:
		spawn_pos = controller.global_position + controller.global_transform.basis.z * -0.1
		fire_dir = -controller.global_transform.basis.z
	else:
		spawn_pos = global_position
		fire_dir = -global_transform.basis.z

	# Load the mode script and call its factory
	var mode_script: GDScript = load(mode_def["script"])
	if mode_script == null:
		push_warning("[Catalyst] Could not load mode script: %s" % mode_def["script"])
		return

	var projectile: CatalystProjectile = mode_script.create_projectile(spawn_pos, fire_dir)
	if projectile == null:
		return

	get_tree().current_scene.add_child(projectile)
	projectile.global_position = spawn_pos

	fire_cooldown = mode_script.FIRE_RATE if "FIRE_RATE" in mode_script else 0.4
	projectile_fired.emit(mode_def["id"], spawn_pos)

	# Haptic kick
	if controller:
		controller.trigger_haptic_pulse("haptic", 0.0, 0.08, 0.35, 0.0)

# ═════════════════════════════════════════════════════════════════════════
# MODE SWITCHING
# ═════════════════════════════════════════════════════════════════════════

func _check_mode_switch() -> void:
	if not controller or _stick_debounce > 0.0:
		return
	if unlocked_modes.size() <= 1:
		return

	var stick := controller.get_vector2("primary")
	if stick.x > STICK_THRESHOLD:
		_switch_mode(1)
		_stick_debounce = STICK_COOLDOWN
	elif stick.x < -STICK_THRESHOLD:
		_switch_mode(-1)
		_stick_debounce = STICK_COOLDOWN

func _switch_mode(direction: int) -> void:
	var new_index := (current_mode_index + direction) % unlocked_modes.size()
	if new_index < 0:
		new_index = unlocked_modes.size() - 1
	if new_index == current_mode_index:
		return

	current_mode_index = new_index
	var mode_id := unlocked_modes[current_mode_index]

	_show_mode_label()
	mode_changed.emit(mode_id)

	# Haptic tick
	if controller:
		controller.trigger_haptic_pulse("haptic", 0.0, 0.04, 0.15, 0.0)

	print("[Catalyst] Switched to mode: %s" % mode_id)

func _show_mode_label() -> void:
	if not _mode_label:
		return
	var mode_def := _get_current_mode_def()
	_mode_label.text = mode_def.get("name", "???")
	_mode_label.modulate = CatalystVisual.get_mode_color(mode_def.get("id", ""))
	_mode_label.visible = true
	_mode_label_timer = 2.0

func _get_current_mode_def() -> Dictionary:
	if current_mode_index < 0 or current_mode_index >= unlocked_modes.size():
		return {}
	var mode_id := unlocked_modes[current_mode_index]
	for def in MODE_DEFS:
		if def["id"] == mode_id:
			return def
	return {}

# ═════════════════════════════════════════════════════════════════════════
# PROGRESSION — MODE UNLOCKING
# ═════════════════════════════════════════════════════════════════════════

func _connect_progression_signals() -> void:
	# Try LabManager first (has is_sequence_completed)
	var lab_mgr := _find_lab_manager()
	if lab_mgr and lab_mgr.has_method("is_sequence_completed"):
		# Check already-completed sequences
		for mode_def in MODE_DEFS:
			if lab_mgr.is_sequence_completed(mode_def["sequence"]):
				_unlock_mode(mode_def["id"], false)

	# Listen for future completions from AdaSceneManager
	var scene_mgr := get_node_or_null("/root/AdaSceneManager")
	if scene_mgr and scene_mgr.has_signal("sequence_completed"):
		if not scene_mgr.sequence_completed.is_connected(_on_sequence_completed):
			scene_mgr.sequence_completed.connect(_on_sequence_completed)
			print("[Catalyst] Connected to AdaSceneManager.sequence_completed")

	# Also try MapProgressionManager
	var map_prog := get_node_or_null("/root/MapProgressionManager")
	if map_prog and map_prog.has_signal("sequence_completed"):
		if not map_prog.sequence_completed.is_connected(_on_map_progression_sequence_completed):
			map_prog.sequence_completed.connect(_on_map_progression_sequence_completed)
			print("[Catalyst] Connected to MapProgressionManager.sequence_completed")

func _on_sequence_completed(sequence_name: String, _completion_data: Dictionary) -> void:
	for mode_def in MODE_DEFS:
		if mode_def["sequence"] == sequence_name:
			_unlock_mode(mode_def["id"], true)

func _on_map_progression_sequence_completed(sequence_name: String) -> void:
	for mode_def in MODE_DEFS:
		if mode_def["sequence"] == sequence_name:
			_unlock_mode(mode_def["id"], true)

func _unlock_mode(mode_id: String, notify: bool = true) -> void:
	if mode_id in unlocked_modes:
		return
	unlocked_modes.append(mode_id)
	_save_unlocked_modes()
	_rebuild_visual()
	if notify:
		mode_unlocked.emit(mode_id)
		print("[Catalyst] 🌀 Unlocked mode: %s" % mode_id)

func unlock_all_modes() -> void:
	"""Debug: unlock everything."""
	for mode_def in MODE_DEFS:
		_unlock_mode(mode_def["id"], false)
	_rebuild_visual()
	print("[Catalyst] All modes unlocked")

func _find_lab_manager() -> Node:
	# LabManager could be autoload or in scene tree
	var mgr := get_node_or_null("/root/LabManager")
	if mgr:
		return mgr
	# Search scene tree
	var tree := get_tree()
	if tree:
		for node in tree.get_nodes_in_group("lab_manager"):
			return node
	return null

# ═════════════════════════════════════════════════════════════════════════
# SAVE / LOAD
# ═════════════════════════════════════════════════════════════════════════

const SAVE_PATH := "user://catalyst_modes.save"

func _save_unlocked_modes() -> void:
	var data := {
		"unlocked": unlocked_modes.duplicate(),
		"last_mode": unlocked_modes[current_mode_index] if current_mode_index < unlocked_modes.size() else "primitives",
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()

func _load_unlocked_modes() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var text := file.get_as_text()
	file.close()
	var data = JSON.parse_string(text)
	if data is Dictionary and data.has("unlocked"):
		unlocked_modes.clear()
		for mode_id in data["unlocked"]:
			unlocked_modes.append(str(mode_id))
		# Ensure primitives always present
		if "primitives" not in unlocked_modes:
			unlocked_modes.insert(0, "primitives")
		# Restore last mode
		if data.has("last_mode"):
			var idx := unlocked_modes.find(str(data["last_mode"]))
			if idx >= 0:
				current_mode_index = idx

# ═════════════════════════════════════════════════════════════════════════
# VISUAL CONSTRUCTION
# ═════════════════════════════════════════════════════════════════════════

func _rebuild_visual() -> void:
	CatalystVisual.build_crystal(self, unlocked_modes)

func _setup_physics() -> void:
	mass = 0.25
	gravity_scale = 1.0
	linear_damp = 1.0
	angular_damp = 2.0

	# Configure the CollisionShape3D inherited from pickable.tscn
	_collision_shape = get_node_or_null("CollisionShape3D") as CollisionShape3D
	if _collision_shape:
		var capsule := CapsuleShape3D.new()
		capsule.radius = 0.06
		capsule.height = 0.22
		_collision_shape.shape = capsule
	else:
		# Fallback: create one if not instanced from pickable.tscn
		_collision_shape = CollisionShape3D.new()
		_collision_shape.name = "CollisionShape3D"
		var capsule := CapsuleShape3D.new()
		capsule.radius = 0.06
		capsule.height = 0.22
		_collision_shape.shape = capsule
		add_child(_collision_shape)

func _build_tip() -> void:
	_tip = Marker3D.new()
	_tip.name = "Tip"
	_tip.position = Vector3(0, 0.12, 0)  # Top of crystal
	add_child(_tip)

func _build_mode_label() -> void:
	_mode_label = Label3D.new()
	_mode_label.name = "ModeLabel"
	_mode_label.position = Vector3(0, 0.2, 0)
	_mode_label.pixel_size = 0.002
	_mode_label.font_size = 32
	_mode_label.outline_size = 4
	_mode_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_mode_label.no_depth_test = true
	_mode_label.visible = false
	add_child(_mode_label)

# ═════════════════════════════════════════════════════════════════════════
# XR-TOOLS PICKABLE CALLBACKS
# ═════════════════════════════════════════════════════════════════════════

func _on_picked_up(_pickable) -> void:
	is_held = true

	# Find controller
	var pickup_node = get_picked_up_by()
	if pickup_node:
		var parent = pickup_node.get_parent()
		while parent and not parent is XRController3D:
			parent = parent.get_parent()
		if parent is XRController3D:
			controller = parent
			if not controller.button_pressed.is_connected(_on_controller_button):
				controller.button_pressed.connect(_on_controller_button)

	# Shrink into hand, then absorb permanently
	if _pickup_tween and _pickup_tween.is_running():
		_pickup_tween.kill()
	_pickup_tween = create_tween()
	_pickup_tween.tween_property(self, "scale", Vector3(0.01, 0.01, 0.01), 0.35) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	_pickup_tween.tween_callback(_absorb_into_hand)

	# Haptic pulse — absorbing the crystal
	if controller:
		controller.trigger_haptic_pulse("haptic", 0.0, 0.15, 0.4, 0.0)

## Crystal is consumed — reparent to controller, release FunctionPickup hold.
func _absorb_into_hand() -> void:
	_absorbed = true

	# Remember controller before let_go triggers _on_dropped
	var ctrl := controller

	# Release from FunctionPickup so the hand is free to grab other things
	var holder = get_picked_up_by()
	if holder and is_picked_up():
		let_go(holder, Vector3.ZERO, Vector3.ZERO)

	# Restore state that _on_dropped cleared
	controller = ctrl
	is_held = true

	# Kill physics — we're a ghost node now
	freeze = true
	collision_layer = 0
	collision_mask = 0
	if _collision_shape:
		_collision_shape.disabled = true

	# Reconnect trigger (let_go → _on_dropped may have disconnected it)
	if controller and not controller.button_pressed.is_connected(_on_controller_button):
		controller.button_pressed.connect(_on_controller_button)

	# Reparent to the controller so we follow the hand
	call_deferred("_deferred_reparent")

	# Hand glow
	if _held_glow:
		var mode_color := CatalystVisual.get_mode_color(unlocked_modes[current_mode_index])
		_held_glow.light_color = mode_color
		_held_glow.light_energy = 1.5

func _deferred_reparent() -> void:
	if not is_instance_valid(controller):
		return
	var old_parent := get_parent()
	if old_parent:
		old_parent.remove_child(self)
	controller.add_child(self)
	position = Vector3.ZERO
	scale = Vector3(0.01, 0.01, 0.01)

func _on_dropped(_pickable) -> void:
	if _absorbed:
		# let_go() fired this during absorption — ignore it
		return

	is_held = false
	if controller and controller.button_pressed.is_connected(_on_controller_button):
		controller.button_pressed.disconnect(_on_controller_button)
	controller = null

	if _held_glow:
		_held_glow.light_energy = 0.0
	if _mode_label:
		_mode_label.visible = false

# ═════════════════════════════════════════════════════════════════════════
# GRID INTEGRATION
# ═════════════════════════════════════════════════════════════════════════

func apply_grid_config(config_data: Dictionary) -> void:
	configure(config_data)

func configure(config_data: Dictionary) -> void:
	if config_data.is_empty():
		return
	# Debug: unlock all modes
	if config_data.has("all_modes"):
		unlock_all_modes()
	# Unlock a specific mode
	if config_data.has("start_mode"):
		_unlock_mode(str(config_data["start_mode"]))
	# Unlock up to a specific mode by order
	if config_data.has("unlock_to"):
		var target_order := int(config_data["unlock_to"])
		for mode_def in MODE_DEFS:
			if mode_def["order"] <= target_order:
				_unlock_mode(mode_def["id"], false)
