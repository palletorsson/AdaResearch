# LabManager.gd - Enhanced with progression system
extends Node3D
class_name LabManager

# JSON data
var artifact_definitions: Dictionary = {}
var artifact_system_state: Dictionary = {}

# Artifact tracking
var active_artifacts: Dictionary = {}
var current_lab_state: String = "initial"

# Lab scene reference (for signaling)
var lab_scene: Node3D

# Progression tracking
var completed_sequences: Array[String] = []

# Signals for lab scene coordination
signal artifact_activated(artifact_id: String)
signal progression_event(event_name: String, event_data: Dictionary)
signal lab_state_changed(new_state: String, unlocked_artifacts: Array)

func _ready():
	print("LabManager: Initializing enhanced lab system with progression")
	
	# Get lab scene reference
	lab_scene = get_parent()
	
	# Load JSON configurations
	_load_json_data()
	
	# Load saved progression state
	_load_progression_state()
	
	# Create artifacts based on current state
	_create_artifacts_from_current_state()
	
	# Setup scene manager connection
	_setup_scene_manager()
	
	# Connect to external progression signals
	_connect_progression_signals()

func _load_json_data():
	"""Load both JSON files"""
	_load_artifact_definitions()
	_load_artifact_system_state()

func _load_artifact_definitions():
	"""Load artifact definitions from JSON"""
	var path = "res://commons/artifacts/lab_artifacts.json"
	
	if not FileAccess.file_exists(path):
		print("LabManager: ERROR - lab_artifacts.json not found")
		return
	
	var file = FileAccess.open(path, FileAccess.READ)
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_text)
	
	if parse_result == OK:
		artifact_definitions = json.data.get("artifacts", {})
		print("LabManager: Loaded %d artifact definitions" % artifact_definitions.size())
	else:
		print("LabManager: ERROR - Failed to parse lab_artifacts.json: %s" % json.get_error_message())

func _load_artifact_system_state():
	"""Load system state from JSON"""
	var path = "res://commons/artifacts/lab_artifact_system.json"
	
	if not FileAccess.file_exists(path):
		print("LabManager: ERROR - lab_artifact_system.json not found")
		return
	
	var file = FileAccess.open(path, FileAccess.READ)
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	if json.parse(json_text) == OK:
		artifact_system_state = json.data
		current_lab_state = artifact_system_state.get("lab_state", "initial")
		print("LabManager: Loaded artifact system state - current state: %s" % current_lab_state)

func _load_progression_state():
	"""Load progression state from save file"""
	var save_path = "user://lab_progression.save"
	
	if FileAccess.file_exists(save_path):
		var file = FileAccess.open(save_path, FileAccess.READ)
		var save_data = file.get_var()
		file.close()
		
		completed_sequences = save_data.get("completed_sequences", [])
		current_lab_state = save_data.get("current_lab_state", "initial")
		
		print("LabManager: Loaded progression - completed sequences: %s" % str(completed_sequences))
		print("LabManager: Current lab state: %s" % current_lab_state)
	else:
		print("LabManager: No progression save found - starting fresh")

func _save_progression_state():
	"""Save progression state to file"""
	var save_data = {
		"completed_sequences": completed_sequences,
		"current_lab_state": current_lab_state,
		"timestamp": Time.get_datetime_string_from_system()
	}
	
	var file = FileAccess.open("user://lab_progression.save", FileAccess.WRITE)
	file.store_var(save_data)
	file.close()
	
	print("LabManager: Progression saved")

func _create_artifacts_from_current_state():
	"""Create artifacts based on current progression state"""
	var state_config = _get_state_configuration(current_lab_state)
	var visible_artifacts = state_config.get("visible_artifacts", ["rotating_cube"])
	
	print("LabManager: Creating artifacts for state '%s': %s" % [current_lab_state, str(visible_artifacts)])
	
	# Clear existing artifacts
	_clear_all_artifacts()
	
	# Create visible artifacts
	for artifact_id in visible_artifacts:
		_instantiate_artifact(artifact_id)
	
	# Apply lighting configuration
	_apply_lighting_from_state(current_lab_state)

func _get_state_configuration(state_name: String) -> Dictionary:
	"""Get configuration for a specific state"""
	var progression_states = artifact_system_state.get("progression_states", {})
	return progression_states.get(state_name, {"visible_artifacts": ["rotating_cube"]})

func _instantiate_artifact(artifact_id: String):
	"""Instantiate an artifact from definition"""
	if not artifact_definitions.has(artifact_id):
		print("LabManager: No definition for artifact: %s" % artifact_id)
		return
	
	var definition = artifact_definitions[artifact_id]
	var tscn_path = definition.get("scene", "")
	
	if not ResourceLoader.exists(tscn_path):
		print("LabManager: Artifact scene not found: %s" % tscn_path)
		return
	
	# Load and instantiate
	var artifact_scene = load(tscn_path)
	var artifact_instance = artifact_scene.instantiate()
	
	# Apply transform from definition
	_apply_artifact_transform(artifact_instance, definition)
	
	# Connect signals
	_connect_artifact_signals(artifact_instance, artifact_id)
	
	# Add lighting if specified
	_add_artifact_lighting(artifact_instance, definition)
	
	# Add to scene
	add_child(artifact_instance)
	active_artifacts[artifact_id] = artifact_instance
	
	print("LabManager: ✅ Created artifact '%s'" % artifact_id)

func _apply_artifact_transform(artifact_instance: Node3D, definition: Dictionary):
	"""Apply position, rotation, and scale from definition"""
	var pos = definition.get("position", [0, 0, 0])
	var rot = definition.get("rotation", [0, 0, 0])
	var scale_def = definition.get("scale", [1, 1, 1])
	
	artifact_instance.position = Vector3(pos[0], pos[1], pos[2])
	artifact_instance.rotation_degrees = Vector3(rot[0], rot[1], rot[2])
	artifact_instance.scale = Vector3(scale_def[0], scale_def[1], scale_def[2])

func _connect_artifact_signals(artifact_instance: Node3D, artifact_id: String):
	"""Connect artifact signals"""
	if artifact_instance.has_signal("artifact_activated"):
		artifact_instance.artifact_activated.connect(_on_artifact_activated.bind(artifact_id))
	
	if artifact_instance.has_signal("sequence_triggered"):
		artifact_instance.sequence_triggered.connect(_on_sequence_triggered.bind(artifact_id))

func _add_artifact_lighting(artifact_instance: Node3D, definition: Dictionary):
	"""Add lighting if specified in definition"""
	var lighting = definition.get("lighting", {})
	
	if lighting.get("add_focused_light", false):
		var light = OmniLight3D.new()
		light.name = "ArtifactLight"
		
		var light_color = lighting.get("light_color", [1.0, 1.0, 1.0])
		light.light_color = Color(light_color[0], light_color[1], light_color[2])
		light.light_energy = lighting.get("light_intensity", 2.0)
		light.omni_range = lighting.get("light_range", 3.0)
		
		var light_pos = lighting.get("light_position", [0, 0.5, 0])
		light.position = Vector3(light_pos[0], light_pos[1], light_pos[2])
		
		artifact_instance.add_child(light)

func _apply_lighting_from_state(state_name: String):
	"""Apply lab lighting based on state"""
	var lighting_configs = artifact_system_state.get("lighting_configurations", {})
	var state_config = _get_state_configuration(state_name)
	var lighting_mode = state_config.get("lighting_mode", "minimal_cube_focused")
	
	if lighting_configs.has(lighting_mode):
		var config = lighting_configs[lighting_mode]
		
		# Apply to world environment
		var world_env = get_node("../WorldEnvironment")
		if world_env and world_env.environment:
			var env = world_env.environment
			env.ambient_light_energy = config.get("ambient_energy", 0.1)
		
		print("LabManager: Applied lighting mode: %s" % lighting_mode)

func _setup_scene_manager():
	"""Setup scene manager connection"""
	var scene_manager = get_node_or_null("/root/SceneManager")
	if scene_manager:
		scene_manager.connect_to_lab_manager(self)
		print("LabManager: Connected to SceneManager")

func _connect_progression_signals():
	"""Connect to external progression systems"""
	# Connect to MapProgressionManager if available
	var map_progression = get_node_or_null("/root/MapProgressionManager")
	if map_progression and map_progression.has_signal("sequence_completed"):
		map_progression.sequence_completed.connect(_on_sequence_completed)
		print("LabManager: Connected to MapProgressionManager")
	
	# Connect to SceneManager for sequence completion events
	var scene_manager = get_node_or_null("/root/SceneManager")
	if scene_manager and scene_manager.has_signal("scene_transition_completed"):
		scene_manager.scene_transition_completed.connect(_on_scene_transition_completed)
		print("LabManager: Connected to SceneManager transitions")

# PROGRESSION EVENT HANDLERS

func _on_sequence_completed(sequence_name: String):
	"""Handle sequence completion from external systems"""
	print("LabManager: 🎉 Sequence completed: %s" % sequence_name)
	
	if sequence_name in completed_sequences:
		print("LabManager: Sequence already completed, ignoring")
		return
	
	# Add to completed sequences
	completed_sequences.append(sequence_name)
	
	# Process sequence rewards
	_process_sequence_rewards(sequence_name)
	
	# Save progression
	_save_progression_state()

func _process_sequence_rewards(sequence_name: String):
	"""Process rewards for completing a sequence"""
	var sequence_rewards = artifact_system_state.get("sequence_rewards", {})
	
	if not sequence_rewards.has(sequence_name):
		print("LabManager: No rewards defined for sequence: %s" % sequence_name)
		return
	
	var rewards = sequence_rewards[sequence_name]
	
	# Get artifacts to unlock
	var artifacts_to_unlock = rewards.get("artifacts_to_unlock", [])
	var new_state = rewards.get("new_state", current_lab_state)
	
	print("LabManager: 🎁 Processing rewards for %s:" % sequence_name)
	print("  - Artifacts to unlock: %s" % str(artifacts_to_unlock))
	print("  - New state: %s" % new_state)
	
	# Update lab state
	if new_state != current_lab_state:
		_transition_to_state(new_state, artifacts_to_unlock)

func _transition_to_state(new_state: String, newly_unlocked: Array = []):
	"""Transition to a new lab state"""
	var old_state = current_lab_state
	current_lab_state = new_state
	
	print("LabManager: 🔄 Transitioning from '%s' to '%s'" % [old_state, new_state])
	
	# Create artifacts for new state
	_create_artifacts_from_current_state()
	
	# Show unlock effects for new artifacts
	_show_unlock_effects(newly_unlocked)
	
	# Emit progression events
	lab_state_changed.emit(new_state, newly_unlocked)
	
	# Save progression
	_save_progression_state()

func _show_unlock_effects(unlocked_artifacts: Array):
	"""Show visual effects for newly unlocked artifacts"""
	for artifact_id in unlocked_artifacts:
		if active_artifacts.has(artifact_id):
			_play_unlock_effect(active_artifacts[artifact_id])

func _play_unlock_effect(artifact: Node3D):
	"""Play unlock effect for an artifact"""
	print("LabManager: ✨ Playing unlock effect for artifact")
	
	# Simple scale-up effect
	var original_scale = artifact.scale
	var tween = create_tween()
	
	# Scale down then up for "pop" effect
	tween.tween_property(artifact, "scale", original_scale * 0.1, 0.2)
	tween.tween_property(artifact, "scale", original_scale * 1.2, 0.3)
	tween.tween_property(artifact, "scale", original_scale, 0.2)

func _on_scene_transition_completed(scene_name: String, user_data: Dictionary):
	"""Handle scene transition completion - check for returning from sequences"""
	if scene_name == "lab" and user_data.has("completion_data"):
		var completion_data = user_data["completion_data"]
		
		if completion_data.has("sequence_completed"):
			var completed_sequence = completion_data["sequence_completed"]
			print("LabManager: 🔄 Player returned from sequence: %s" % completed_sequence)
			_on_sequence_completed(completed_sequence)

# SIGNAL HANDLERS (existing)

func _on_artifact_activated(artifact_id: String):
	"""Forward artifact activation to lab scene"""
	print("LabManager: Artifact '%s' activated - forwarding to lab scene" % artifact_id)
	artifact_activated.emit(artifact_id)

func _on_sequence_triggered(artifact_id: String, sequence_name: String):
	"""Forward sequence trigger to lab scene"""
	print("LabManager: Sequence '%s' triggered by '%s'" % [sequence_name, artifact_id])
	
	var event_data = {
		"artifact_id": artifact_id,
		"sequence_name": sequence_name,
		"trigger_type": "sequence"
	}
	progression_event.emit("sequence_triggered", event_data)

# UTILITY METHODS

func _clear_all_artifacts():
	"""Clear all active artifacts"""
	for artifact_id in active_artifacts.keys():
		var artifact = active_artifacts[artifact_id]
		if is_instance_valid(artifact):
			artifact.queue_free()
	
	active_artifacts.clear()

# PUBLIC API

func get_active_artifacts() -> Array:
	"""Get list of currently active artifact IDs"""
	return active_artifacts.keys()

func get_artifact_instance(artifact_id: String) -> Node3D:
	"""Get instance of a specific artifact"""
	return active_artifacts.get(artifact_id, null)

func is_artifact_active(artifact_id: String) -> bool:
	"""Check if an artifact is currently active"""
	return active_artifacts.has(artifact_id)

func get_current_lab_state() -> String:
	"""Get current lab progression state"""
	return current_lab_state

func get_completed_sequences() -> Array[String]:
	"""Get list of completed sequences"""
	return completed_sequences.duplicate()

func is_sequence_completed(sequence_name: String) -> bool:
	"""Check if a specific sequence has been completed"""
	return sequence_name in completed_sequences

func force_unlock_sequence_rewards(sequence_name: String):
	"""Force unlock rewards for a sequence (for testing)"""
	print("LabManager: 🔧 Force unlocking rewards for: %s" % sequence_name)
	_on_sequence_completed(sequence_name)

func reset_progression():
	"""Reset all progression (for testing)"""
	print("LabManager: 🔄 Resetting all progression")
	completed_sequences.clear()
	current_lab_state = "initial"
	_create_artifacts_from_current_state()
	_save_progression_state()

func preview_state(state_name: String):
	"""Preview a specific state (for testing)"""
	print("LabManager: 👁️ Previewing state: %s" % state_name)
	var old_state = current_lab_state
	current_lab_state = state_name
	_create_artifacts_from_current_state()
	
	# Revert after 5 seconds
	await get_tree().create_timer(5.0).timeout
	current_lab_state = old_state
	_create_artifacts_from_current_state()

# DEBUG METHODS

func print_progression_status():
	"""Print current progression status"""
	print("=== LAB PROGRESSION STATUS ===")
	print("Current state: %s" % current_lab_state)
	print("Completed sequences: %s" % str(completed_sequences))
	print("Active artifacts: %s" % str(active_artifacts.keys()))
	print("Available states: %s" % str(artifact_system_state.get("progression_states", {}).keys()))
	print("==============================")

func get_progression_info() -> Dictionary:
	"""Get comprehensive progression information"""
	return {
		"current_state": current_lab_state,
		"completed_sequences": completed_sequences.duplicate(),
		"active_artifacts": active_artifacts.keys(),
		"available_states": artifact_system_state.get("progression_states", {}).keys(),
		"sequence_rewards": artifact_system_state.get("sequence_rewards", {}).keys()
	}
