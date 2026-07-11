# CatalystCapabilityManager.gd
# Bridges catalyst mode unlocking with player capabilities.
# Tracks capacity ladder level (L1-L6), hand verbs, and movement abilities.
# Dual-listen: MapProgressionManager.sequence_completed + BecomingCatalyst.mode_unlocked.

extends Node

const STAGES_FILE = "res://commons/maps/soft_stages.json"
const SAVE_FILE = "user://capability_progression.json"

const CAPACITY_NAMES = ["", "Observe", "Touch", "Manipulate", "Construct", "Control", "Embody"]

# Friend powers — the lasting player ability granted the FIRST time a creature
# of a given catalyst-mode lineage is converted all the way to FRIEND.
# Keyed by the mode_id that locked the foe (CatalystFoe._locked_mode_id).
# Editor-tool modes are deliberately absent: converting is the only way in.
const FRIEND_POWERS = {
	"primitives":     {"power": "shield",      "label": "Shield",      "description": "A friend orbits you and absorbs one hit."},
	"transformation": {"power": "porter",      "label": "Porter",      "description": "A friend shoves path blocks to bridge gaps."},
	"chromatic":      {"power": "neutralizer", "label": "Neutralizer", "description": "A friend standing in a danger zone mutes its damage."},
	"forces":         {"power": "launcher",    "label": "Launcher",    "description": "Friends cluster underfoot and boost your jump."},
	"waveform":       {"power": "calmer",      "label": "Calmer",      "description": "A friend emits a slow-wave that halves nearby foe speed."},
	"chaos":          {"power": "decoy",       "label": "Decoy",       "description": "Foes chase the chaotic friend instead of you."},
	"cellular":       {"power": "replicator",  "label": "Replicator",  "description": "A friend's conversions yield two friends."},
	"fractal":        {"power": "splitter",    "label": "Splitter",    "description": "A friend splits in two when hit instead of reverting."},
	"branching":      {"power": "bridger",     "label": "Bridger",     "description": "A friend grows a walkable tendril over hazards."},
	"swarm":          {"power": "escort",      "label": "Escort",      "description": "The flock forms a shield-wall around you."},
}

# Current state
var _all_stages: Dictionary = {}
var _completed_sequences: Array[String] = []
var _capacity_level: int = 1
var _hand_verbs: Dictionary = {}             # verb -> true (acts as Set)
var _movement_abilities: Dictionary = {}     # ability -> true
var _catalyst_modes: Array[String] = []
var _friend_powers: Dictionary = {}          # power -> mode_id that granted it
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
signal friend_power_granted(mode_id: String, power: String)

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
# Public API — Friend Powers
# ---------------------------------------------------------------------------

## Called by creatures (CatalystFoe / HazardCreatureBase) the moment a
## conversion reaches FRIEND. The first conversion of a mode-lineage grants
## its power permanently; repeats are no-ops.
func grant_friend_power(mode_id: String) -> void:
	var def: Dictionary = FRIEND_POWERS.get(mode_id, {})
	if def.is_empty():
		return  # editor tools / unknown modes grant nothing
	var power: String = str(def["power"])
	if _friend_powers.has(power):
		return
	_friend_powers[power] = mode_id
	save_state()
	friend_power_granted.emit(mode_id, power)
	capability_unlocked.emit(power)
	print("CatalystCapabilityManager: Friend power granted — '%s' (from mode '%s')" % [power, mode_id])

func has_friend_power(power: String) -> bool:
	return _friend_powers.has(power)

func get_friend_powers() -> Array[String]:
	var powers: Array[String] = []
	for p in _friend_powers.keys():
		powers.append(str(p))
	return powers

## Label + description for HUD / text screens. Empty dict if unknown.
func get_friend_power_info(power: String) -> Dictionary:
	for mode_id in FRIEND_POWERS.keys():
		var def: Dictionary = FRIEND_POWERS[mode_id]
		if str(def["power"]) == power:
			var out: Dictionary = def.duplicate()
			out["mode_id"] = mode_id
			return out
	return {}

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

	# Use the modes of the catalyst that's NOW a child of the controller —
	# i.e., the one the player just picked up. Falling back to "first
	# catalyst in scene" was the bug: ghost auto-absorbed catalysts
	# could come first and bring voxel_editor along with them.
	var bracelet_modes: Array = []
	var active_cat: Node = null
	for child in controller.get_children():
		if child.is_in_group("catalyst"):
			active_cat = child
			break
	if active_cat and "unlocked_modes" in active_cat:
		for m in active_cat.unlocked_modes:
			var id := str(m)
			if id not in bracelet_modes:
				bracelet_modes.append(id)
		print("[BraceletMgr] Using active catalyst '%s' with %d modes" % [active_cat.name, bracelet_modes.size()])
	else:
		# Fallback: any catalyst in scene (legacy path)
		for cat in get_tree().get_nodes_in_group("catalyst"):
			if "unlocked_modes" in cat:
				for m in cat.unlocked_modes:
					var id := str(m)
					if id not in bracelet_modes:
						bracelet_modes.append(id)
				break
		print("[BraceletMgr] No active catalyst on controller, fell back to scene scan")

	# Final fallback: use manager's accumulated modes if no catalyst in scene
	if bracelet_modes.is_empty():
		bracelet_modes = _catalyst_modes.duplicate()

	# Last resort: ensure at least voxel_editor
	if bracelet_modes.is_empty():
		print("[BraceletMgr] WARNING: no modes found, adding 'voxel_editor' fallback")
		bracelet_modes.append("voxel_editor")

	print("[BraceletMgr] Activating bracelet with %d modes: %s" % [bracelet_modes.size(), bracelet_modes])

	# Activate with only the unlocked modes — no "show all dimmed" display
	if _bracelet.has_method("activate"):
		_bracelet.activate(bracelet_modes, controller, true)
	else:
		push_error("[BraceletMgr] Bracelet has NO activate() method — script not attached?")

	# Link to the active catalyst (the one on the controller) for sync.
	if active_cat and _bracelet.has_method("link_catalyst"):
		_bracelet.link_catalyst(active_cat)

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
		"friend_powers": get_friend_powers(),
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
	_friend_powers.clear()
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

	# Event-driven unlock: a stage may declare capability.unlock_event so the
	# capability lands at the sequence's THEME MOMENT (e.g. crossing Trans_Pit)
	# instead of waiting for the sequence boundary. sequence_completed above
	# stays the fallback — _advance_stage dedupes.
	if mpm and mpm.has_signal("map_completed"):
		if not mpm.map_completed.is_connected(_on_map_completed):
			mpm.map_completed.connect(_on_map_completed)

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

	# Re-spawn catalyst + bracelet on scene transitions (in-memory only, no disk save)
	if _bracelet_activated and node is XRController3D:
		call_deferred("_try_respawn_bracelet_on_controller", node)

func _on_sequence_completed(sequence_name: String) -> void:
	_advance_stage(sequence_name)

## Theme-event unlock, variant A: a declared map is the sequence's theme
## moment. Fires the stage's capability early when that map completes.
func _on_map_completed(map_name: String) -> void:
	for seq_id in _all_stages.keys():
		if _completed_sequences.has(seq_id):
			continue
		var ev: Dictionary = _get_unlock_event(seq_id)
		if ev.is_empty():
			continue
		if str(ev.get("type", "")) == "map_completed" and str(ev.get("map", "")) == map_name:
			print("CatalystCapabilityManager: Theme event — '%s' completed unlocks '%s' early" % [
				map_name, seq_id])
			_advance_stage(seq_id)

## Theme-event unlock, variant B: an artifact/trigger in the world calls this
## directly when the player ENACTS the sequence's theme. Only honoured if the
## stage declares an unlock_event of type "theme" (data-gated — nothing can
## unlock a sequence that didn't opt in).
func notify_theme_event(sequence_name: String) -> void:
	if _completed_sequences.has(sequence_name):
		return
	var ev: Dictionary = _get_unlock_event(sequence_name)
	if str(ev.get("type", "")) != "theme":
		return
	print("CatalystCapabilityManager: Theme event enacted — unlocking '%s' early" % sequence_name)
	_advance_stage(sequence_name)

func _get_unlock_event(sequence_name: String) -> Dictionary:
	if not _all_stages.has(sequence_name):
		return {}
	var cap: Dictionary = _all_stages[sequence_name].get("capability", {})
	var ev = cap.get("unlock_event", {})
	return ev if ev is Dictionary else {}

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

	print("[BraceletMgr] _try_respawn: re-spawning catalyst + bracelet on '%s'" % ctrl_id)

	# Respawn absorbed catalyst first (so bracelet can link to it)
	_respawn_absorbed_catalyst(controller as XRController3D)

	# Then respawn bracelet
	spawn_bracelet_on_controller(controller as XRController3D)

## Silently re-create an absorbed catalyst on the controller after scene transition.
## The catalyst loads its saved modes and auto-absorbs without pickup animation.
func _respawn_absorbed_catalyst(ctrl: XRController3D) -> void:
	# Check if there's already a catalyst absorbed on this controller
	var existing_catalysts = get_tree().get_nodes_in_group("catalyst")
	for cat in existing_catalysts:
		if cat.get_parent() == ctrl:
			print("[BraceletMgr] Catalyst already on controller '%s', skip respawn" % ctrl.name)
			return

	var catalyst_scene = load("res://commons/hazards/becoming_catalyst/becoming_catalyst.tscn")
	if catalyst_scene == null:
		push_error("[BraceletMgr] FAILED to load becoming_catalyst.tscn")
		return

	# Add to scene tree first so _ready() fires and loads saved modes
	var catalyst = catalyst_scene.instantiate()
	get_tree().current_scene.add_child(catalyst)

	# Auto-absorb onto the controller
	if catalyst.has_method("auto_absorb"):
		catalyst.auto_absorb(ctrl)
		print("[BraceletMgr] Catalyst respawned and auto-absorbed on '%s'" % ctrl.name)
	else:
		push_error("[BraceletMgr] Catalyst missing auto_absorb() method")

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
	var payload: Dictionary = {
		"completed_sequences": _completed_sequences,
		"catalyst_modes": _catalyst_modes,
		"friend_powers": _friend_powers,
		"bracelet_activated": _bracelet_activated,
		"bracelet_tracker": _bracelet_tracker,
	}
	var f: FileAccess = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if f == null:
		push_warning("CatalystCapabilityManager: Could not write %s" % SAVE_FILE)
		return
	f.store_string(JSON.stringify(payload, "\t"))
	f.close()

func _load_saved_progress() -> void:
	if not FileAccess.file_exists(SAVE_FILE):
		return
	var f: FileAccess = FileAccess.open(SAVE_FILE, FileAccess.READ)
	if f == null:
		return
	var json: JSON = JSON.new()
	var text: String = f.get_as_text()
	f.close()
	if json.parse(text) != OK:
		push_warning("CatalystCapabilityManager: Corrupt save %s — starting fresh" % SAVE_FILE)
		return
	if not (json.data is Dictionary):
		return
	var data: Dictionary = json.data
	_completed_sequences.clear()
	for s in data.get("completed_sequences", []):
		_completed_sequences.append(str(s))
	_catalyst_modes.clear()
	for m in data.get("catalyst_modes", []):
		_catalyst_modes.append(str(m))
	_friend_powers.clear()
	var fp = data.get("friend_powers", {})
	if fp is Dictionary:
		for k in fp.keys():
			_friend_powers[str(k)] = str(fp[k])
	_bracelet_activated = bool(data.get("bracelet_activated", false))
	_bracelet_tracker = str(data.get("bracelet_tracker", ""))
	print("CatalystCapabilityManager: Loaded progression — %d sequences, %d modes, %d friend powers" % [
		_completed_sequences.size(), _catalyst_modes.size(), _friend_powers.size()])
