# CatalystCapabilityManager.gd
# Bridges catalyst mode unlocking with player capabilities.
# Tracks capacity ladder level (L1-L6), hand verbs, and movement abilities.
# Dual-listen: MapProgressionManager.sequence_completed + BecomingCatalyst.mode_unlocked.

extends Node

const STAGES_FILE = "res://commons/maps/soft_stages.json"
const SAVE_FILE = "user://capability_progression.json"

const CAPACITY_NAMES = ["", "Observe", "Touch", "Manipulate", "Construct", "Control", "Embody"]

# Current state
var _all_stages: Dictionary = {}
var _completed_sequences: Array[String] = []
var _capacity_level: int = 1
var _hand_verbs: Dictionary = {}             # verb -> true (acts as Set)
var _movement_abilities: Dictionary = {}     # ability -> true
var _catalyst_modes: Array[String] = []
var _current_stage_order: int = 0

# Bracelet state — persists across scenes
var _bracelet: Node = null
var _bracelet_activated: bool = false        # True once first catalyst is picked up
var _bracelet_controller: XRController3D = null
var _bracelet_tracker: String = ""           # Tracker name of the hand that picked up the catalyst

# Signals
signal capability_unlocked(capability_name: String)
signal capacity_level_changed(new_level: int)
signal hand_verbs_changed(verbs: Array[String])
signal movement_ability_unlocked(ability: String)
signal catalyst_mode_registered(mode_id: String)

func _ready():
	_load_stages()
	_load_saved_progress()
	_rebuild_state()
	call_deferred("_connect_progression_signals")
	call_deferred("_connect_catalyst_signals")
	print("CatalystCapabilityManager: Initialized — capacity L%d (%s), %d verbs, %d modes, bracelet_activated=%s, tracker='%s'" % [
		_capacity_level, get_capacity_level_name(), _hand_verbs.size(), _catalyst_modes.size(),
		_bracelet_activated, _bracelet_tracker
	])

# ---------------------------------------------------------------------------
# Public API — Capacity Ladder
# ---------------------------------------------------------------------------

func get_capacity_level() -> int:
	return _capacity_level

func get_capacity_level_name() -> String:
	if _capacity_level >= 1 and _capacity_level <= 6:
		return CAPACITY_NAMES[_capacity_level]
	return "Unknown"

# ---------------------------------------------------------------------------
# Public API — Hand Verbs
# ---------------------------------------------------------------------------

func is_hand_verb_available(verb: String) -> bool:
	return _hand_verbs.has(verb)

func get_available_hand_verbs() -> Array[String]:
	var verbs: Array[String] = []
	for v in _hand_verbs.keys():
		verbs.append(str(v))
	return verbs

# ---------------------------------------------------------------------------
# Public API — Movement Abilities
# ---------------------------------------------------------------------------

func is_movement_available(ability: String) -> bool:
	return _movement_abilities.has(ability)

func get_available_movement_abilities() -> Array[String]:
	var abilities: Array[String] = []
	for a in _movement_abilities.keys():
		abilities.append(str(a))
	return abilities

# ---------------------------------------------------------------------------
# Public API — Catalyst Modes
# ---------------------------------------------------------------------------

func get_unlocked_catalyst_modes() -> Array[String]:
	return _catalyst_modes.duplicate()

func is_catalyst_mode_unlocked(mode_id: String) -> bool:
	return _catalyst_modes.has(mode_id)

# ---------------------------------------------------------------------------
# Public API — Capacity Bracelet
# ---------------------------------------------------------------------------

## Spawn (or re-spawn) the bracelet on a controller. Called by BecomingCatalyst
## after absorb, and internally after scene transitions.
func spawn_bracelet_on_controller(controller: XRController3D) -> void:
	print("[BraceletMgr] spawn_bracelet_on_controller called — controller: '%s'" % [controller.name if controller else "NULL"])
	if not is_instance_valid(controller):
		print("[BraceletMgr] ABORT: controller invalid")
		return

	# Guard against duplicate spawns on the same controller
	if is_instance_valid(_bracelet) and _bracelet.get_parent() == controller:
		print("[BraceletMgr] SKIP: bracelet already on this controller")
		return

	# Clean up old bracelet if it exists
	if is_instance_valid(_bracelet):
		print("[BraceletMgr] Cleaning up old bracelet on '%s'" % [_bracelet.get_parent().name if _bracelet.get_parent() else "orphan"])
		_bracelet.queue_free()
		_bracelet = null

	# Load and instantiate bracelet scene
	var bracelet_scene = load("res://commons/hazards/becoming_catalyst/capacity_bracelet/capacity_bracelet.tscn")
	if bracelet_scene == null:
		push_error("[BraceletMgr] FAILED to load capacity_bracelet.tscn — check for script compile errors")
		return

	_bracelet = bracelet_scene.instantiate()
	if _bracelet == null:
		push_error("[BraceletMgr] FAILED to instantiate bracelet scene")
		return

	print("[BraceletMgr] Bracelet instantiated, parenting to controller '%s'" % controller.name)

	# Parent to controller at wrist offset — rotated so ring wraps around wrist
	controller.add_child(_bracelet)
	_bracelet.position = Vector3(0.02, -0.05, 0.18)  # Out from palm, down toward forearm, back toward wrist
	_bracelet.rotation_degrees = Vector3(90, 0, 0)   # Rotate so torus hole faces along arm

	# Use the current catalyst's own unlocked modes — not the accumulated history.
	# This way the bracelet reflects what THIS catalyst can do.
	var bracelet_modes: Array = []
	var catalysts = get_tree().get_nodes_in_group("catalyst")
	for cat in catalysts:
		if "unlocked_modes" in cat:
			for m in cat.unlocked_modes:
				var id := str(m)
				if id not in bracelet_modes:
					bracelet_modes.append(id)
			break  # Use the first catalyst found

	# Fallback: use manager's accumulated modes if no catalyst in scene
	if bracelet_modes.is_empty():
		bracelet_modes = _catalyst_modes.duplicate()

	# Last resort: ensure at least "primitives"
	if bracelet_modes.is_empty():
		print("[BraceletMgr] WARNING: no modes found, adding 'primitives' fallback")
		bracelet_modes.append("primitives")

	print("[BraceletMgr] Activating bracelet with %d modes: %s" % [bracelet_modes.size(), bracelet_modes])

	# Activate with the current catalyst's modes
	if _bracelet.has_method("activate"):
		_bracelet.activate(bracelet_modes, controller, true)
	else:
		push_error("[BraceletMgr] Bracelet has NO activate() method — script not attached?")

	# Link to the first catalyst in the scene for bidirectional sync
	for cat in catalysts:
		if _bracelet.has_method("link_catalyst"):
			_bracelet.link_catalyst(cat)
		break

	_bracelet_controller = controller
	_bracelet_activated = true
	# Remember which hand for re-spawning after scene transitions
	_bracelet_tracker = controller.tracker if "tracker" in controller else controller.name
	save_state()

	# Verify final state
	print("[BraceletMgr] DONE — bracelet visible=%s, scale=%s, parent='%s', global_pos=%s" % [
		_bracelet.visible, _bracelet.scale,
		_bracelet.get_parent().name if _bracelet.get_parent() else "NONE",
		_bracelet.global_position
	])

## Get the current bracelet instance (or null).
func get_bracelet() -> Node:
	if is_instance_valid(_bracelet):
		return _bracelet
	return null

## Check if bracelet has been activated (first catalyst picked up).
func is_bracelet_activated() -> bool:
	return _bracelet_activated

# ---------------------------------------------------------------------------
# Public API — Full Config
# ---------------------------------------------------------------------------

func get_capability_config() -> Dictionary:
	return {
		"capacity_level": _capacity_level,
		"capacity_name": get_capacity_level_name(),
		"hand_verbs": get_available_hand_verbs(),
		"movement_abilities": get_available_movement_abilities(),
		"catalyst_modes": get_unlocked_catalyst_modes(),
		"stage_order": _current_stage_order,
	}

func get_current_stage_order() -> int:
	return _current_stage_order

# ---------------------------------------------------------------------------
# Debug
# ---------------------------------------------------------------------------

func force_advance_to(sequence_name: String) -> void:
	if not _all_stages.has(sequence_name):
		push_warning("CatalystCapabilityManager: Unknown sequence '%s'" % sequence_name)
		return
	var target_order: int = _all_stages[sequence_name].get("order", 0)
	for seq_id in _all_stages.keys():
		var stage = _all_stages[seq_id]
		if stage.get("order", 0) <= target_order and not _completed_sequences.has(seq_id):
			_completed_sequences.append(seq_id)
	_rebuild_state()
	save_state()

func unlock_all_capabilities() -> void:
	for seq_id in _all_stages.keys():
		if not _completed_sequences.has(seq_id):
			_completed_sequences.append(seq_id)
	_rebuild_state()
	save_state()

func reset_progression() -> void:
	_completed_sequences.clear()
	_catalyst_modes.clear()
	_bracelet_activated = false
	_bracelet_tracker = ""
	if is_instance_valid(_bracelet):
		_bracelet.queue_free()
		_bracelet = null
	_bracelet_controller = null
	_rebuild_state()
	save_state()

# ---------------------------------------------------------------------------
# Progression signals
# ---------------------------------------------------------------------------

func _connect_progression_signals() -> void:
	var mpm = get_node_or_null("/root/MapProgressionManager")
	if mpm and mpm.has_signal("sequence_completed"):
		if not mpm.sequence_completed.is_connected(_on_sequence_completed):
			mpm.sequence_completed.connect(_on_sequence_completed)
		print("CatalystCapabilityManager: Connected to MapProgressionManager.sequence_completed")
	else:
		push_warning("CatalystCapabilityManager: MapProgressionManager not found or missing signal")

	var scene_mgr = get_node_or_null("/root/SceneManager")
	if scene_mgr and scene_mgr.has_signal("sequence_completed"):
		if not scene_mgr.sequence_completed.is_connected(_on_scene_sequence_completed):
			scene_mgr.sequence_completed.connect(_on_scene_sequence_completed)

func _connect_catalyst_signals() -> void:
	# BecomingCatalyst is a scene node, not an autoload. Find via group.
	var catalysts = get_tree().get_nodes_in_group("catalyst")
	for catalyst in catalysts:
		if catalyst.has_signal("mode_unlocked"):
			if not catalyst.mode_unlocked.is_connected(_on_catalyst_mode_unlocked):
				catalyst.mode_unlocked.connect(_on_catalyst_mode_unlocked)
				print("CatalystCapabilityManager: Connected to BecomingCatalyst.mode_unlocked")
		# Sync existing modes from the catalyst (e.g. the default "primitives")
		_sync_modes_from_catalyst(catalyst)

	# Re-check when scenes change (catalyst might appear later)
	if not get_tree().node_added.is_connected(_on_node_added):
		get_tree().node_added.connect(_on_node_added)

func _on_node_added(node: Node) -> void:
	# Connect to new catalysts
	if node.is_in_group("catalyst") and node.has_signal("mode_unlocked"):
		if not node.mode_unlocked.is_connected(_on_catalyst_mode_unlocked):
			node.mode_unlocked.connect(_on_catalyst_mode_unlocked)
		# Sync existing modes from the catalyst (e.g. the default "primitives")
		_sync_modes_from_catalyst(node)
		# Link bracelet to this catalyst if bracelet exists
		if is_instance_valid(_bracelet) and _bracelet.has_method("link_catalyst"):
			_bracelet.link_catalyst(node)

	# Re-spawn bracelet on new controller after scene transition
	if _bracelet_activated and node is XRController3D:
		# Wait a frame for the controller to be fully set up
		call_deferred("_try_respawn_bracelet_on_controller", node)

func _on_sequence_completed(sequence_name: String) -> void:
	_advance_stage(sequence_name)

func _on_scene_sequence_completed(sequence_name: String, _data: Dictionary) -> void:
	_advance_stage(sequence_name)

## Read unlocked_modes from a catalyst and merge any missing ones into _catalyst_modes.
func _sync_modes_from_catalyst(catalyst: Node) -> void:
	if not "unlocked_modes" in catalyst:
		return
	var changed := false
	for mode_id in catalyst.unlocked_modes:
		var id: String = str(mode_id)
		if not _catalyst_modes.has(id):
			_catalyst_modes.append(id)
			changed = true
	if changed:
		save_state()

func _on_catalyst_mode_unlocked(mode_id: String) -> void:
	if not _catalyst_modes.has(mode_id):
		_catalyst_modes.append(mode_id)
		save_state()
		catalyst_mode_registered.emit(mode_id)
		# Notify bracelet about the new mode
		if is_instance_valid(_bracelet) and _bracelet.has_method("_on_mode_unlocked"):
			_bracelet._on_mode_unlocked(mode_id)
		print("CatalystCapabilityManager: Catalyst mode registered — '%s'" % mode_id)

func _advance_stage(sequence_name: String) -> void:
	if _completed_sequences.has(sequence_name):
		return
	if not _all_stages.has(sequence_name):
		return

	_completed_sequences.append(sequence_name)
	var old_level = _capacity_level
	_rebuild_state()
	save_state()

	# Emit specific signals
	var cap: Dictionary = _all_stages[sequence_name].get("capability", {})
	for verb in cap.get("hand_verbs", []):
		capability_unlocked.emit(verb)
	for ability in cap.get("movement_abilities", []):
		if not _movement_abilities.has(ability):
			movement_ability_unlocked.emit(ability)
	if _capacity_level != old_level:
		capacity_level_changed.emit(_capacity_level)

	hand_verbs_changed.emit(get_available_hand_verbs())
	print("CatalystCapabilityManager: Stage advanced — '%s' (L%d %s, %d verbs)" % [
		sequence_name, _capacity_level, get_capacity_level_name(), _hand_verbs.size()
	])

# ---------------------------------------------------------------------------
# Bracelet re-spawn after scene transitions
# ---------------------------------------------------------------------------

func _try_respawn_bracelet_on_controller(controller: Node) -> void:
	if not is_instance_valid(controller) or not controller is XRController3D:
		return
	if not _bracelet_activated:
		print("[BraceletMgr] _try_respawn: bracelet not yet activated, skip")
		return

	# If a bracelet already exists and is parented, skip
	if is_instance_valid(_bracelet) and is_instance_valid(_bracelet.get_parent()):
		print("[BraceletMgr] _try_respawn: bracelet already exists on '%s', skip" % _bracelet.get_parent().name)
		return

	# Match the original hand — compare tracker name or node name
	var ctrl_id: String = ""
	if "tracker" in controller:
		ctrl_id = str(controller.tracker)
	if ctrl_id.is_empty():
		ctrl_id = controller.name
	if not _bracelet_tracker.is_empty() and ctrl_id != _bracelet_tracker:
		print("[BraceletMgr] _try_respawn: wrong hand '%s' (want '%s'), skip" % [ctrl_id, _bracelet_tracker])
		return

	print("[BraceletMgr] _try_respawn: re-spawning bracelet on '%s'" % ctrl_id)
	spawn_bracelet_on_controller(controller as XRController3D)

# ---------------------------------------------------------------------------
# State rebuild
# ---------------------------------------------------------------------------

func _rebuild_state() -> void:
	_hand_verbs.clear()
	_movement_abilities.clear()
	_capacity_level = 1
	_current_stage_order = 0

	for seq_id in _completed_sequences:
		if not _all_stages.has(seq_id):
			continue
		var stage = _all_stages[seq_id]
		var order: int = stage.get("order", 0)
		var cap: Dictionary = stage.get("capability", {})

		# Hand verbs are cumulative
		for verb in cap.get("hand_verbs", []):
			_hand_verbs[verb] = true

		# Movement abilities are cumulative
		for ability in cap.get("movement_abilities", []):
			_movement_abilities[ability] = true

		# Catalyst mode from stage data (supplements mode_unlocked signal)
		var mode_raw = cap.get("catalyst_mode", "")
		var mode: String = str(mode_raw) if mode_raw != null else ""
		if not mode.is_empty() and not _catalyst_modes.has(mode):
			_catalyst_modes.append(mode)

		# Capacity level: max across all completed stages
		var level: int = cap.get("capacity_level", 1)
		if level > _capacity_level:
			_capacity_level = level

		if order > _current_stage_order:
			_current_stage_order = order

# ---------------------------------------------------------------------------
# JSON loading
# ---------------------------------------------------------------------------

func _load_stages() -> void:
	if not FileAccess.file_exists(STAGES_FILE):
		push_error("CatalystCapabilityManager: Stages file not found: %s" % STAGES_FILE)
		return

	var file = FileAccess.open(STAGES_FILE, FileAccess.READ)
	if not file:
		push_error("CatalystCapabilityManager: Could not open stages file")
		return

	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	if json.parse(json_text) != OK:
		push_error("CatalystCapabilityManager: Failed to parse stages file: %s" % json.get_error_message())
		return

	var data: Dictionary = json.data
	_all_stages = data.get("stages", {})

# ---------------------------------------------------------------------------
# Save / Load
# ---------------------------------------------------------------------------

func save_state() -> void:
	var save_data = {
		"completed_sequences": _completed_sequences,
		"catalyst_modes": _catalyst_modes,
		"bracelet_activated": _bracelet_activated,
		"bracelet_tracker": _bracelet_tracker,
		"last_saved": Time.get_datetime_string_from_system()
	}
	var file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()

func _load_saved_progress() -> void:
	if not FileAccess.file_exists(SAVE_FILE):
		return

	var file = FileAccess.open(SAVE_FILE, FileAccess.READ)
	if not file:
		return

	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	if json.parse(json_text) == OK:
		var data: Dictionary = json.data
		_completed_sequences.clear()
		for seq in data.get("completed_sequences", []):
			_completed_sequences.append(str(seq))
		_catalyst_modes.clear()
		for mode in data.get("catalyst_modes", []):
			_catalyst_modes.append(str(mode))
		_bracelet_activated = data.get("bracelet_activated", false)
		_bracelet_tracker = str(data.get("bracelet_tracker", ""))
