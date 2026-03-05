# EcosystemManager.gd
# Orchestrates the progressive "allow" system for world visual complexity.
# Tracks which visual features are unlocked as the player completes sequences.
# Consumers (morphology generators, terrain, ambient FX) query is_allowed() before producing output.

extends Node

const STAGES_FILE = "res://commons/maps/soft_stages.json"
const SAVE_FILE = "user://ecosystem_progression.json"

# Current state — rebuilt from completed sequences + soft_stages.json
var _all_stages: Dictionary = {}
var _completed_sequences: Array[String] = []
var _allowed_flags: Dictionary = {}  # flag_name -> true (acts as Set)
var _current_kingdoms: Array[String] = []
var _current_vegetation_density: float = 0.0
var _current_terrain_mode: String = "flat"
var _current_ambient_preset: String = "empty_lab"
var _current_stage_order: int = 0

# Signals
signal allow_flags_changed(flags: Array[String])
signal vegetation_config_changed(config: Dictionary)
signal terrain_mode_changed(new_mode: String)
signal nature_kingdoms_changed(kingdoms: Array[String])
signal ecosystem_stage_advanced(sequence_name: String)

func _ready():
	_load_stages()
	_load_saved_progress()
	_rebuild_state()
	call_deferred("_connect_progression_signals")
	print("EcosystemManager: Initialized with %d stages, %d completed sequences, %d flags active" % [
		_all_stages.size(), _completed_sequences.size(), _allowed_flags.size()
	])

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

func is_allowed(flag: String) -> bool:
	return _allowed_flags.has(flag)

func get_all_allowed_flags() -> Array[String]:
	var flags: Array[String] = []
	for f in _allowed_flags.keys():
		flags.append(str(f))
	return flags

func get_vegetation_density() -> float:
	return _current_vegetation_density

func get_morphology_lod() -> int:
	# Higher vegetation density = lower LOD (more detail)
	if _current_vegetation_density >= 0.7:
		return 0
	elif _current_vegetation_density >= 0.4:
		return 1
	elif _current_vegetation_density >= 0.1:
		return 2
	return 3

func get_allowed_kingdoms() -> Array[String]:
	return _current_kingdoms.duplicate()

func is_kingdom_allowed(kingdom: String) -> bool:
	return _current_kingdoms.has(kingdom)

func get_terrain_mode() -> String:
	return _current_terrain_mode

func get_ambient_preset() -> String:
	return _current_ambient_preset

func get_current_stage_order() -> int:
	return _current_stage_order

func get_ecosystem_config() -> Dictionary:
	return {
		"allowed_flags": get_all_allowed_flags(),
		"kingdoms": get_allowed_kingdoms(),
		"vegetation_density": _current_vegetation_density,
		"terrain_mode": _current_terrain_mode,
		"ambient_preset": _current_ambient_preset,
		"stage_order": _current_stage_order,
		"lod": get_morphology_lod(),
	}

# ---------------------------------------------------------------------------
# Debug
# ---------------------------------------------------------------------------

func force_advance_to(sequence_name: String) -> void:
	if not _all_stages.has(sequence_name):
		push_warning("EcosystemManager: Unknown sequence '%s'" % sequence_name)
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
		print("EcosystemManager: Connected to MapProgressionManager.sequence_completed")
	else:
		push_warning("EcosystemManager: MapProgressionManager not found or missing signal")

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

	ecosystem_stage_advanced.emit(sequence_name)
	print("EcosystemManager: Stage advanced — '%s' (order %d, %d flags)" % [
		sequence_name, _current_stage_order, _allowed_flags.size()
	])

# ---------------------------------------------------------------------------
# State rebuild
# ---------------------------------------------------------------------------

func _rebuild_state() -> void:
	var old_flags = _allowed_flags.duplicate()
	var old_terrain = _current_terrain_mode
	var old_kingdoms = _current_kingdoms.duplicate()

	_allowed_flags.clear()
	_current_kingdoms.clear()
	_current_vegetation_density = 0.0
	_current_terrain_mode = "flat"
	_current_ambient_preset = "empty_lab"
	_current_stage_order = 0

	for seq_id in _completed_sequences:
		if not _all_stages.has(seq_id):
			continue
		var stage = _all_stages[seq_id]
		var order: int = stage.get("order", 0)
		var eco: Dictionary = stage.get("ecosystem", {})

		# Allow flags are cumulative
		for flag in eco.get("allow_flags", []):
			_allowed_flags[flag] = true

		# Kingdoms — union across all completed stages
		for k in eco.get("nature_kingdoms", []):
			if not _current_kingdoms.has(k):
				_current_kingdoms.append(k)

		# Latest-value properties (use highest order)
		if order > _current_stage_order:
			_current_stage_order = order
			_current_vegetation_density = eco.get("vegetation_density", _current_vegetation_density)
			_current_terrain_mode = eco.get("terrain_mode", _current_terrain_mode)
			_current_ambient_preset = eco.get("ambient_preset", _current_ambient_preset)

	# Emit signals for changes
	if _allowed_flags.keys() != old_flags.keys():
		allow_flags_changed.emit(get_all_allowed_flags())
	if _current_terrain_mode != old_terrain:
		terrain_mode_changed.emit(_current_terrain_mode)
	if _current_kingdoms != old_kingdoms:
		nature_kingdoms_changed.emit(_current_kingdoms)

	vegetation_config_changed.emit(get_ecosystem_config())

# ---------------------------------------------------------------------------
# JSON loading
# ---------------------------------------------------------------------------

func _load_stages() -> void:
	if not FileAccess.file_exists(STAGES_FILE):
		push_error("EcosystemManager: Stages file not found: %s" % STAGES_FILE)
		return

	var file = FileAccess.open(STAGES_FILE, FileAccess.READ)
	if not file:
		push_error("EcosystemManager: Could not open stages file")
		return

	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	if json.parse(json_text) != OK:
		push_error("EcosystemManager: Failed to parse stages file: %s" % json.get_error_message())
		return

	var data: Dictionary = json.data
	_all_stages = data.get("stages", {})

# ---------------------------------------------------------------------------
# Save / Load
# ---------------------------------------------------------------------------

func save_state() -> void:
	var save_data = {
		"completed_sequences": _completed_sequences,
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
