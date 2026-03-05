# HazardManager.gd
# Central coordinator for hazard creature spawning and behavior.
# Tracks which hazard types are allowed, their personality (foe→friend),
# and spawner behavior mode. ProximitySpawner calls request_spawn_permission().

extends Node

const STAGES_FILE = "res://commons/maps/soft_stages.json"
const SAVE_FILE = "user://hazard_progression.json"

const PERSONALITY_ORDER = ["foe", "wary", "neutral", "curious", "friend"]
const BEHAVIOR_ORDER = ["dormant", "active", "aggressive"]

# Current state
var _all_stages: Dictionary = {}
var _completed_sequences: Array[String] = []
var _allowed_types: Dictionary = {}        # type_id -> true
var _personalities: Dictionary = {}        # type_id -> personality string
var _personality_overrides: Dictionary = {} # player-driven overrides (befriending)
var _spawner_behavior: String = "dormant"
var _max_concurrent: int = 1
var _current_stage_order: int = 0

# Signals
signal hazard_types_updated(allowed_types: Array[String])
signal hazard_personality_changed(hazard_type: String, new_personality: String)
signal spawner_behavior_changed(new_behavior: String)
signal hazard_befriended(hazard_type: String)
signal stage_advanced(sequence_name: String)

func _ready():
	_load_stages()
	_load_saved_progress()
	_rebuild_state()
	call_deferred("_connect_progression_signals")
	print("HazardManager: Initialized with %d stages, %d completed sequences, %d hazard types allowed" % [
		_all_stages.size(), _completed_sequences.size(), _allowed_types.size()
	])

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

func is_hazard_type_allowed(hazard_type: String) -> bool:
	return _allowed_types.has(hazard_type)

func get_allowed_hazard_types() -> Array[String]:
	var types: Array[String] = []
	for t in _allowed_types.keys():
		types.append(str(t))
	return types

func get_hazard_personality(hazard_type: String) -> String:
	# Player overrides take precedence
	if _personality_overrides.has(hazard_type):
		return _personality_overrides[hazard_type]
	return _personalities.get(hazard_type, "foe")

func get_spawner_behavior() -> String:
	return _spawner_behavior

func get_max_concurrent() -> int:
	return _max_concurrent

func get_current_stage_order() -> int:
	return _current_stage_order

## Called by ProximitySpawner before instantiating a creature.
func request_spawn_permission(hazard_type: String) -> bool:
	if not is_hazard_type_allowed(hazard_type):
		return false
	# Could add concurrent count check here in the future
	return true

## Called when a player befriends a creature through direct interaction.
func befriend_hazard(hazard_type: String) -> void:
	_personality_overrides[hazard_type] = "friend"
	_personalities[hazard_type] = "friend"
	save_state()
	hazard_befriended.emit(hazard_type)
	hazard_personality_changed.emit(hazard_type, "friend")
	print("HazardManager: '%s' befriended!" % hazard_type)

# ---------------------------------------------------------------------------
# Debug
# ---------------------------------------------------------------------------

func force_advance_to(sequence_name: String) -> void:
	if not _all_stages.has(sequence_name):
		push_warning("HazardManager: Unknown sequence '%s'" % sequence_name)
		return
	var target_order: int = _all_stages[sequence_name].get("order", 0)
	for seq_id in _all_stages.keys():
		var stage = _all_stages[seq_id]
		if stage.get("order", 0) <= target_order and not _completed_sequences.has(seq_id):
			_completed_sequences.append(seq_id)
	_rebuild_state()
	save_state()

func reset_progression() -> void:
	_completed_sequences.clear()
	_personality_overrides.clear()
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
		print("HazardManager: Connected to MapProgressionManager.sequence_completed")
	else:
		push_warning("HazardManager: MapProgressionManager not found or missing signal")

	var scene_mgr = get_node_or_null("/root/SceneManager")
	if scene_mgr and scene_mgr.has_signal("sequence_completed"):
		if not scene_mgr.sequence_completed.is_connected(_on_scene_sequence_completed):
			scene_mgr.sequence_completed.connect(_on_scene_sequence_completed)

func _on_sequence_completed(sequence_name: String) -> void:
	_advance_stage(sequence_name)

func _on_scene_sequence_completed(sequence_name: String, _data: Dictionary) -> void:
	_advance_stage(sequence_name)

func _advance_stage(sequence_name: String) -> void:
	if _completed_sequences.has(sequence_name):
		return
	if not _all_stages.has(sequence_name):
		return

	_completed_sequences.append(sequence_name)
	_rebuild_state()
	save_state()

	stage_advanced.emit(sequence_name)
	print("HazardManager: Stage advanced — '%s' (order %d, %d types allowed, behavior: %s)" % [
		sequence_name, _current_stage_order, _allowed_types.size(), _spawner_behavior
	])

# ---------------------------------------------------------------------------
# State rebuild
# ---------------------------------------------------------------------------

func _rebuild_state() -> void:
	var old_types = _allowed_types.duplicate()
	var old_behavior = _spawner_behavior

	_allowed_types.clear()
	_personalities.clear()
	_spawner_behavior = "dormant"
	_max_concurrent = 1
	_current_stage_order = 0

	# Sort completed sequences by order
	var ordered: Array[Dictionary] = []
	for seq_id in _completed_sequences:
		if not _all_stages.has(seq_id):
			continue
		var stage = _all_stages[seq_id]
		ordered.append({"id": seq_id, "order": stage.get("order", 0), "stage": stage})
	ordered.sort_custom(func(a, b): return a["order"] < b["order"])

	for entry in ordered:
		var haz: Dictionary = entry["stage"].get("hazards", {})
		var order: int = entry["order"]

		# Unlock types are cumulative
		for t in haz.get("unlock_types", []):
			_allowed_types[t] = true

		# Personality shifts layer on top (later stages override earlier)
		for type_id in haz.get("personality_shift", {}).keys():
			var new_p: String = haz["personality_shift"][type_id]
			var current_p: String = _personalities.get(type_id, "foe")
			# Only advance personality, never regress
			if PERSONALITY_ORDER.find(new_p) > PERSONALITY_ORDER.find(current_p):
				_personalities[type_id] = new_p

		# Spawner behavior: use highest completed
		var stage_behavior: String = haz.get("spawner_behavior", "dormant")
		if BEHAVIOR_ORDER.find(stage_behavior) > BEHAVIOR_ORDER.find(_spawner_behavior):
			_spawner_behavior = stage_behavior

		# Max concurrent: use latest
		if order > _current_stage_order:
			_current_stage_order = order
			_max_concurrent = haz.get("max_concurrent", _max_concurrent)

	# Apply player overrides on top
	for type_id in _personality_overrides.keys():
		_personalities[type_id] = _personality_overrides[type_id]

	# Emit signals for changes
	if _allowed_types.keys() != old_types.keys():
		hazard_types_updated.emit(get_allowed_hazard_types())
	if _spawner_behavior != old_behavior:
		spawner_behavior_changed.emit(_spawner_behavior)

# ---------------------------------------------------------------------------
# JSON loading
# ---------------------------------------------------------------------------

func _load_stages() -> void:
	if not FileAccess.file_exists(STAGES_FILE):
		push_error("HazardManager: Stages file not found: %s" % STAGES_FILE)
		return

	var file = FileAccess.open(STAGES_FILE, FileAccess.READ)
	if not file:
		push_error("HazardManager: Could not open stages file")
		return

	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	if json.parse(json_text) != OK:
		push_error("HazardManager: Failed to parse stages file: %s" % json.get_error_message())
		return

	var data: Dictionary = json.data
	_all_stages = data.get("stages", {})

# ---------------------------------------------------------------------------
# Save / Load
# ---------------------------------------------------------------------------

func save_state() -> void:
	var save_data = {
		"completed_sequences": _completed_sequences,
		"personality_overrides": _personality_overrides,
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
		_personality_overrides = data.get("personality_overrides", {})
