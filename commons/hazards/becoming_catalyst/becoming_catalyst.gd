# @identity
# essence: mode(curriculum_progress) -> hand_force(type) -- a held tool that evolves through the curriculum
# desire: an evolving hand force tracking player progression, from slow cubes to swarm intelligence
# critical_parameter: current_mode_index / unlocked_modes -- curriculum stage determines the tool's current power
# triggers: XRToolsPickable grab/release; mode cycling through unlocked abilities; curriculum progression unlocks
# emerges: the tool that grows with the learner -- same object, different capability at each understanding stage
# needs: XRToolsPickable [has]; mode system [has]; fire cooldown [has]; curriculum tracking [has]
# relationships: companion to loving_triangle (tool + atom pair); embodies Q-FEP progression across all sequences
# truth: the catalyst does not change the world -- it changes what the holder can do in the world.

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
var _pickup_controller_name: String = ""  # Remember which controller picked us up

# Mode switching debounce
var _stick_debounce: float = 0.0
const STICK_THRESHOLD := 0.7
const STICK_COOLDOWN := 0.8

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

	# Mode switching disabled on controller thumbstick — use the bracelet instead

# ═════════════════════════════════════════════════════════════════════════
# FIRING
# ═════════════════════════════════════════════════════════════════════════

## Called by XRToolsFunctionPickup when the trigger is pressed while held.
## Pre-absorption: do nothing — the catalyst must absorb first before firing.
## Post-absorption: never called because let_go() releases from FunctionPickup.
func action() -> void:
	super()

## Direct controller button handler — fires on A/X face button (ax_button).
## Trigger is reserved for XRTools interactions (grab, poke, etc.).
func _on_controller_button(button_name: String) -> void:
	if button_name == "ax_button":
		# Don't fire while the hand is busy holding/picking up another object
		if _is_hand_busy():
			return
		_fire()

## Check if FunctionPickup on this controller is currently holding a pickable.
func _is_hand_busy() -> bool:
	if not is_instance_valid(controller):
		return false
	for child in controller.get_children():
		if child is XRToolsFunctionPickup:
			if is_instance_valid(child.picked_up_object):
				return true
	return false

func _fire() -> void:
	if not is_held or fire_cooldown > 0.0:
		return

	var mode_def := _get_current_mode_def()
	if mode_def.is_empty():
		return

	# Fire where the controller points (local -Z, same axis as FunctionPointer ray)
	var spawn_pos: Vector3
	var fire_dir: Vector3
	if controller:
		fire_dir = -controller.global_transform.basis.z
		spawn_pos = controller.global_position + fire_dir * 0.15
	else:
		fire_dir = -global_transform.basis.z
		spawn_pos = global_position

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

	# Keep bracelet in sync with thumbstick switching
	var cap_mgr = get_node_or_null("/root/CatalystCapabilityManager")
	if cap_mgr and cap_mgr.has_method("get_bracelet"):
		var bracelet = cap_mgr.get_bracelet()
		if bracelet and bracelet.has_method("sync_to_mode"):
			bracelet.sync_to_mode(current_mode_index)

	# Haptic tick
	if controller:
		controller.trigger_haptic_pulse("haptic", 0.0, 0.04, 0.15, 0.0)

	print("[Catalyst] Switched to mode: %s" % mode_id)

## Set mode by absolute index (called by capacity bracelet).
func set_mode_index(index: int) -> void:
	if index < 0 or index >= unlocked_modes.size() or index == current_mode_index:
		return
	current_mode_index = index
	var mode_id := unlocked_modes[current_mode_index]
	_show_mode_label()
	_rebuild_visual()
	mode_changed.emit(mode_id)
	# Don't call bracelet.sync_to_mode here — the bracelet initiated this change
	if controller:
		controller.trigger_haptic_pulse("haptic", 0.0, 0.04, 0.15, 0.0)
	print("[Catalyst] Set mode to: %s" % mode_id)

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

	# Find controller — walk up from the holder node
	controller = _find_xr_controller()
	if controller:
		_pickup_controller_name = controller.name
		print("[Catalyst] Picked up — controller: '%s' (path: %s)" % [controller.name, controller.get_path()])
		if not controller.button_pressed.is_connected(_on_controller_button):
			controller.button_pressed.connect(_on_controller_button)
	else:
		print("[Catalyst] WARNING: Could not find XRController3D in pickup hierarchy")

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

## Remove any previously absorbed catalyst on the given controller.
func _replace_existing_catalyst(ctrl: XRController3D) -> void:
	if not is_instance_valid(ctrl):
		return
	var existing := get_tree().get_nodes_in_group("catalyst")
	for cat in existing:
		if cat == self:
			continue
		if not is_instance_valid(cat):
			continue
		if cat.get("_absorbed") and cat.get("controller") == ctrl:
			# Disconnect old catalyst's button handler
			if ctrl.button_pressed.is_connected(cat._on_controller_button):
				ctrl.button_pressed.disconnect(cat._on_controller_button)
			cat.queue_free()
			print("[Catalyst] Replaced previous catalyst on '%s'" % ctrl.name)

## Crystal is consumed — reparent to controller, release FunctionPickup hold.
func _absorb_into_hand() -> void:
	_absorbed = true

	# If controller reference was lost, try to recover — prefer the SAME hand
	if not is_instance_valid(controller):
		print("[Catalyst] Controller lost since pickup, recovering...")
		# Method A: Walk up from current holder (most reliable)
		var holder = get_picked_up_by()
		if holder:
			var node = holder
			while node:
				if node is XRController3D:
					controller = node
					print("[Catalyst] Recovered controller from holder chain: '%s'" % controller.name)
					break
				node = node.get_parent()
		# Method B: Find controller by saved name
		if not is_instance_valid(controller) and not _pickup_controller_name.is_empty():
			controller = _find_controller_by_name(_pickup_controller_name)
			if controller:
				print("[Catalyst] Recovered controller by saved name: '%s'" % controller.name)
		# Method C: General fallback
		if not is_instance_valid(controller):
			controller = _find_xr_controller()
			if controller:
				print("[Catalyst] Fallback controller: '%s'" % controller.name)

	# Remove any previous catalyst on this controller — only one at a time
	_replace_existing_catalyst(controller)

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

## Auto-absorb onto a controller without pickup animation.
## Used by CatalystCapabilityManager to restore catalyst after scene transitions.
func auto_absorb(ctrl: XRController3D) -> void:
	# Remove any previous catalyst on this controller — only one at a time
	_replace_existing_catalyst(ctrl)

	_absorbed = true
	is_held = true
	controller = ctrl
	_pickup_controller_name = ctrl.name

	# Kill physics
	freeze = true
	collision_layer = 0
	collision_mask = 0
	if _collision_shape:
		_collision_shape.disabled = true

	# Connect trigger
	if not controller.button_pressed.is_connected(_on_controller_button):
		controller.button_pressed.connect(_on_controller_button)

	# Reparent to controller — tiny and invisible
	var old_parent := get_parent()
	if old_parent:
		old_parent.remove_child(self)
	controller.add_child(self)
	position = Vector3.ZERO
	scale = Vector3(0.01, 0.01, 0.01)
	visible = false  # Absorbed crystals are invisible

	# Hand glow
	if _held_glow and current_mode_index < unlocked_modes.size():
		var mode_color := CatalystVisual.get_mode_color(unlocked_modes[current_mode_index])
		_held_glow.light_color = mode_color
		_held_glow.light_energy = 1.5

	print("[Catalyst] Auto-absorbed onto '%s' with %d modes: %s" % [
		controller.name, unlocked_modes.size(), unlocked_modes])

func _deferred_reparent() -> void:
	if not is_instance_valid(controller):
		print("[Catalyst] _deferred_reparent: controller INVALID, aborting")
		return
	print("[Catalyst] _deferred_reparent: reparenting to controller '%s' (path: %s, global_pos: %s)" % [
		controller.name, controller.get_path(), controller.global_position])
	var old_parent := get_parent()
	if old_parent:
		old_parent.remove_child(self)
	controller.add_child(self)
	position = Vector3.ZERO
	scale = Vector3(0.01, 0.01, 0.01)

	# Notify the capability manager to spawn the bracelet on this controller
	var cap_mgr = get_node_or_null("/root/CatalystCapabilityManager")
	if cap_mgr and cap_mgr.has_method("spawn_bracelet_on_controller"):
		print("[Catalyst] Requesting bracelet spawn on controller '%s'" % controller.name)
		cap_mgr.spawn_bracelet_on_controller(controller)
	else:
		print("[Catalyst] WARNING: CatalystCapabilityManager not found or missing spawn method")

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
# CONTROLLER FINDING
# ═════════════════════════════════════════════════════════════════════════

func _find_xr_controller() -> XRController3D:
	# Method 1: Walk up from the holder (FunctionPickup → ... → XRController3D)
	var pickup_node = get_picked_up_by()
	if pickup_node:
		var node = pickup_node
		while node:
			if node is XRController3D:
				return node
			node = node.get_parent()

	# Method 2: Walk up from self (pickable may already be reparented under controller)
	var node = get_parent()
	while node:
		if node is XRController3D:
			return node
		node = node.get_parent()

	# Method 3: Search the scene tree for any XRController3D
	for child in get_tree().root.get_children():
		var found := _find_controller_recursive(child)
		if found:
			return found

	return null

func _find_controller_recursive(node: Node) -> XRController3D:
	if node is XRController3D:
		return node
	for child in node.get_children():
		var found := _find_controller_recursive(child)
		if found:
			return found
	return null

## Find a specific controller by name (recursive search).
func _find_controller_by_name(ctrl_name: String) -> XRController3D:
	for child in get_tree().root.get_children():
		var found := _find_named_controller_recursive(child, ctrl_name)
		if found:
			return found
	return null

func _find_named_controller_recursive(node: Node, ctrl_name: String) -> XRController3D:
	if node is XRController3D and node.name == ctrl_name:
		return node
	for child in node.get_children():
		var found := _find_named_controller_recursive(child, ctrl_name)
		if found:
			return found
	return null

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
