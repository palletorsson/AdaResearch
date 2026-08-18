# CheckpointManager.gd
# Autoload singleton managing checkpoint saves and respawns
# Add to Project Settings > AutoLoad

extends Node

const SAVE_PATH = "user://checkpoint.save"

# Current checkpoint data
var current_checkpoint: Dictionary = {}

# All registered checkpoints in current scene
var registered_checkpoints: Dictionary = {}  # checkpoint_id → Checkpoint node

# Signals
signal checkpoint_saved(checkpoint_id: String, position: Vector3)
signal respawn_started()
signal respawn_completed(position: Vector3)
signal checkpoints_cleared()

func _ready() -> void:
	_load_from_disk()
	print("[CheckpointManager] Initialized")

# ============================================================================
# CHECKPOINT REGISTRATION
# ============================================================================

func register_checkpoint(checkpoint: Node) -> void:
	"""Register a checkpoint node for tracking"""
	if not checkpoint:
		return
	
	var cp_id = checkpoint.checkpoint_id if checkpoint.get("checkpoint_id") else str(checkpoint.get_instance_id())
	registered_checkpoints[cp_id] = checkpoint
	
	# If this checkpoint was previously activated, restore its state
	if current_checkpoint.get("checkpoint_id") == cp_id:
		if checkpoint.has_method("_set_visual_state"):
			checkpoint.call("_set_visual_state", true)
		checkpoint.is_activated = true

func unregister_checkpoint(checkpoint_id: String) -> void:
	"""Remove a checkpoint from tracking"""
	registered_checkpoints.erase(checkpoint_id)

func clear_registrations() -> void:
	"""Clear all registered checkpoints (call on scene change)"""
	registered_checkpoints.clear()

# ============================================================================
# SAVE CHECKPOINT
# ============================================================================

func save_checkpoint(checkpoint: Node) -> void:
	"""Save player state at checkpoint"""
	var player = _get_player()
	if not player:
		push_warning("[CheckpointManager] No player found, cannot save checkpoint")
		return
	
	var cp_id = checkpoint.checkpoint_id if checkpoint.get("checkpoint_id") else str(checkpoint.get_instance_id())
	var cp_position = checkpoint.global_position if checkpoint is Node3D else Vector3.ZERO
	
	current_checkpoint = {
		"checkpoint_id": cp_id,
		"position": _vector_to_dict(cp_position),
		"player_rotation": _vector_to_dict(player.global_rotation),
		"health": _get_player_health(),
		"map_name": _get_current_map(),
		"timestamp": Time.get_unix_time_from_system()
	}
	
	_save_to_disk()
	checkpoint_saved.emit(cp_id, cp_position)
	print("[CheckpointManager] Saved checkpoint: %s at %s" % [cp_id, cp_position])

func save_position(position: Vector3, checkpoint_id: String = "manual") -> void:
	"""Save a manual checkpoint at specific position"""
	var player = _get_player()
	
	current_checkpoint = {
		"checkpoint_id": checkpoint_id,
		"position": _vector_to_dict(position),
		"player_rotation": _vector_to_dict(player.global_rotation if player else Vector3.ZERO),
		"health": _get_player_health(),
		"map_name": _get_current_map(),
		"timestamp": Time.get_unix_time_from_system()
	}
	
	_save_to_disk()
	checkpoint_saved.emit(checkpoint_id, position)

# ============================================================================
# RESPAWN
# ============================================================================

func respawn_at_checkpoint() -> void:
	"""Respawn player at last checkpoint"""
	respawn_started.emit()
	
	if current_checkpoint.is_empty():
		print("[CheckpointManager] No checkpoint saved, restarting map")
		_restart_current_map()
		return
	
	var target_map = current_checkpoint.get("map_name", "")
	var current_map = _get_current_map()
	
	# If different map, need to load it first
	if target_map != "" and target_map != current_map:
		print("[CheckpointManager] Loading map: %s" % target_map)
		await _load_map(target_map)
		# Wait for scene to settle
		# out-of-tree guard: get_tree() is null once a map is torn down
		if not is_inside_tree():
			await tree_entered
		await get_tree().process_frame
		# out-of-tree guard: get_tree() is null once a map is torn down
		if not is_inside_tree():
			await tree_entered
		await get_tree().process_frame
	
	# Restore player state
	_restore_player_state()

func _restore_player_state() -> void:
	"""Restore player position, rotation, health from checkpoint"""
	var player = _get_player()
	if not player:
		push_warning("[CheckpointManager] No player found for respawn")
		respawn_completed.emit(Vector3.ZERO)
		return
	
	# Position
	var pos = _dict_to_vector(current_checkpoint.get("position", {}))
	pos.y += 0.5  # Slight lift to avoid floor clipping
	player.global_position = pos
	
	# Rotation
	var rot = _dict_to_vector(current_checkpoint.get("player_rotation", {}))
	player.global_rotation = rot
	
	# Health
	var health = current_checkpoint.get("health", 100.0)
	_set_player_health(health)
	
	print("[CheckpointManager] Respawned at: %s" % pos)
	respawn_completed.emit(pos)

# ============================================================================
# CHECKPOINT QUERIES
# ============================================================================

func has_checkpoint() -> bool:
	"""Check if a checkpoint is saved"""
	return not current_checkpoint.is_empty()

func get_checkpoint_position() -> Vector3:
	"""Get saved checkpoint position"""
	return _dict_to_vector(current_checkpoint.get("position", {}))

func get_checkpoint_id() -> String:
	"""Get saved checkpoint ID"""
	return current_checkpoint.get("checkpoint_id", "")

func get_checkpoint_map() -> String:
	"""Get map name where checkpoint was saved"""
	return current_checkpoint.get("map_name", "")

# ============================================================================
# CLEAR / RESET
# ============================================================================

func clear_checkpoints() -> void:
	"""Clear all checkpoint data (for new game)"""
	current_checkpoint = {}
	
	# Reset visual state of all registered checkpoints
	for cp_id in registered_checkpoints:
		var checkpoint = registered_checkpoints[cp_id]
		if is_instance_valid(checkpoint):
			checkpoint.is_activated = false
			if checkpoint.has_method("_set_visual_state"):
				checkpoint.call("_set_visual_state", false)
	
	_delete_save_file()
	checkpoints_cleared.emit()
	print("[CheckpointManager] Checkpoints cleared")

# ============================================================================
# PERSISTENCE
# ============================================================================

func _save_to_disk() -> void:
	"""Persist checkpoint to disk"""
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(current_checkpoint)
		file.close()

func _load_from_disk() -> void:
	"""Load checkpoint from disk"""
	if not FileAccess.file_exists(SAVE_PATH):
		return
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var data = file.get_var()
		file.close()
		if data is Dictionary:
			current_checkpoint = data
			print("[CheckpointManager] Loaded checkpoint: %s" % current_checkpoint.get("checkpoint_id", "unknown"))

func _delete_save_file() -> void:
	"""Remove checkpoint save file"""
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

func _get_player() -> Node3D:
	"""Find player node"""
	# Try GameManager first
	if has_node("/root/GameManager"):
		var gm = get_node("/root/GameManager")
		if gm.has_method("get_player"):
			var player = gm.get_player()
			if is_instance_valid(player):
				return player
	
	# Search by group
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0] as Node3D
	
	var player_bodies = get_tree().get_nodes_in_group("player_body")
	if player_bodies.size() > 0:
		return player_bodies[0] as Node3D
	
	# Search by name
	var scene = get_tree().current_scene
	if scene:
		for name in ["XROrigin3D", "DesktopPlayer", "Player", "PlayerBody"]:
			var node = scene.find_child(name, true, false)
			if node is Node3D:
				return node
	
	return null

func _get_player_health() -> float:
	"""Get player health from GameManager"""
	if has_node("/root/GameManager"):
		var gm = get_node("/root/GameManager")
		if gm.has_method("get_health"):
			return gm.get_health()
	return 100.0

func _set_player_health(health: float) -> void:
	"""Set player health via GameManager"""
	if has_node("/root/GameManager"):
		var gm = get_node("/root/GameManager")
		if gm.has_method("set_health"):
			gm.set_health(health)

func _get_current_map() -> String:
	"""Get current map name from GameManager"""
	if has_node("/root/GameManager"):
		var gm = get_node("/root/GameManager")
		if gm.has_method("get_current_map"):
			return gm.get_current_map()
	return ""

func _restart_current_map() -> void:
	"""Restart the current map"""
	get_tree().reload_current_scene()

func _load_map(map_name: String) -> void:
	"""Load a different map"""
	# Try AdaSceneManager
	if has_node("/root/AdaSceneManager"):
		var sm = get_node("/root/AdaSceneManager")
		if sm.has_method("load_map"):
			await sm.load_map(map_name)
			return
	
	# Fallback: just reload
	# out-of-tree guard: get_tree() is null once a map is torn down
	if not is_inside_tree():
		return
	get_tree().reload_current_scene()

func _vector_to_dict(v: Vector3) -> Dictionary:
	"""Convert Vector3 to serializable dictionary"""
	return {"x": v.x, "y": v.y, "z": v.z}

func _dict_to_vector(d: Dictionary) -> Vector3:
	"""Convert dictionary back to Vector3"""
	return Vector3(d.get("x", 0.0), d.get("y", 0.0), d.get("z", 0.0))
