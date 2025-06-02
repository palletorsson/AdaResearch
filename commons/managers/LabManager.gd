# LabManager.gd - Artifact lifecycle management only
extends Node3D
class_name LabManager

# Artifact management (NOT behavior)
var artifact_definitions: Dictionary = {}
var artifact_system_state: Dictionary = {}
var artifact_instances: Dictionary = {}

# Progression tracking
var progression_manager: MapProgressionManager
var current_lab_state: String = "initial"

# Signals
signal artifact_unlocked(artifact_id: String)
signal lab_state_changed(new_state: String)

func _ready():
	print("LabManager: Initializing artifact management system")
	progression_manager = MapProgressionManager.get_instance()
	
	_load_artifact_definitions()
	_load_artifact_system_state()
	_create_active_artifacts()
	
	print("LabManager: Managing %d artifact definitions" % artifact_definitions.size())

func _load_artifact_definitions():
	"""Load artifact definitions from JSON"""
	var artifacts_path = "res://commons/artifacts/lab_artifacts.json"
	
	if not FileAccess.file_exists(artifacts_path):
		print("LabManager: ERROR - lab_artifacts.json not found")
		return
	
	var file = FileAccess.open(artifacts_path, FileAccess.READ)
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	if json.parse(json_text) == OK:
		var data = json.data
		artifact_definitions = data.get("artifact_definitions", {})
		print("LabManager: Loaded %d artifact definitions" % artifact_definitions.size())

func _load_artifact_system_state():
	"""Load system state from JSON"""
	var system_path = "res://commons/artifacts/lab_artifact_system.json"
	
	if not FileAccess.file_exists(system_path):
		print("LabManager: Using default system state")
		artifact_system_state = _get_default_system_state()
		return
	
	var file = FileAccess.open(system_path, FileAccess.READ)
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	if json.parse(json_text) == OK:
		artifact_system_state = json.data
		print("LabManager: Loaded artifact system state")

func _get_default_system_state() -> Dictionary:
	"""Default system state - only rotating cube active"""
	return {
		"current_state": {
			"active_artifacts": ["rotating_cube"],
			"lab_lighting": "minimal_cube_focused"
		},
		"artifact_states": {
			"rotating_cube": {"status": "active"},
			"grid_display": {"status": "hidden"},
			"randomness_sign": {"status": "hidden"}
		}
	}

func _create_active_artifacts():
	"""Create and position active artifacts"""
	var active_artifacts = artifact_system_state.get("current_state", {}).get("active_artifacts", ["rotating_cube"])
	
	for artifact_id in active_artifacts:
		_instantiate_artifact(artifact_id)

func _instantiate_artifact(artifact_id: String):
	"""Instantiate an artifact from its tscn and position it"""
	if not artifact_definitions.has(artifact_id):
		print("LabManager: No definition for artifact: %s" % artifact_id)
		return
	
	if artifact_instances.has(artifact_id):
		print("LabManager: Artifact %s already exists" % artifact_id)
		return
	
	var definition = artifact_definitions[artifact_id]
	var tscn_path = definition.get("tscn_path", "")
	
	if not ResourceLoader.exists(tscn_path):
		print("LabManager: Artifact scene not found: %s" % tscn_path)
		return
	
	# Load and instantiate the artifact scene
	var artifact_scene = load(tscn_path)
	var artifact_instance = artifact_scene.instantiate()
	
	# Apply management properties ONLY
	_apply_artifact_positioning(artifact_instance, definition)
	_connect_artifact_management_signals(artifact_instance, artifact_id)
	_add_artifact_lighting_if_specified(artifact_instance, definition)
	
	# Add to scene and track
	add_child(artifact_instance)
	artifact_instances[artifact_id] = artifact_instance
	
	print("LabManager: Instantiated artifact: %s" % artifact_id)

func _apply_artifact_positioning(artifact_instance: Node3D, definition: Dictionary):
	"""Apply position, rotation, scale from definition"""
	var position = definition.get("position", [0, 0, 0])
	var rotation = definition.get("rotation", [0, 0, 0])
	var scale = definition.get("scale", [1, 1, 1])
	
	artifact_instance.position = Vector3(position[0], position[1], position[2])
	artifact_instance.rotation_degrees = Vector3(rotation[0], rotation[1], rotation[2])
	artifact_instance.scale = Vector3(scale[0], scale[1], scale[2])

func _connect_artifact_management_signals(artifact_instance: Node3D, artifact_id: String):
	"""Connect artifact signals for management purposes only"""
	# Connect common artifact signals that affect management
	if artifact_instance.has_signal("artifact_activated"):
		artifact_instance.artifact_activated.connect(_on_artifact_activated.bind(artifact_id))
	
	if artifact_instance.has_signal("sequence_triggered"):
		artifact_instance.sequence_triggered.connect(_on_sequence_triggered.bind(artifact_id))
	
	# Do NOT configure internal artifact behavior - tscn handles that

func _add_artifact_lighting_if_specified(artifact_instance: Node3D, definition: Dictionary):
	"""Add management lighting if specified in definition"""
	var lighting = definition.get("lighting", {})
	
	if lighting.get("add_focused_light", false):
		var light = OmniLight3D.new()
		light.name = "ManagementLight"
		
		var light_color = lighting.get("light_color", [1.0, 1.0, 1.0])
		light.light_color = Color(light_color[0], light_color[1], light_color[2])
		light.light_energy = lighting.get("light_intensity", 2.0)
		light.omni_range = lighting.get("light_range", 3.0)
		light.position = Vector3(0, 0.5, 0)
		
		artifact_instance.add_child(light)

# Management signal handlers
func _on_artifact_activated(artifact_id: String):
	"""Handle artifact activation for management purposes"""
	print("LabManager: Artifact activated: %s" % artifact_id)
	
	# Update progression and unlock new artifacts
	_handle_artifact_progression(artifact_id)

func _on_sequence_triggered(artifact_id: String, sequence_name: String):
	"""Handle sequence trigger for management purposes"""
	print("LabManager: Sequence '%s' triggered by %s" % [sequence_name, artifact_id])
	
	# Management can track this for progression
	_handle_sequence_progression(artifact_id, sequence_name)

func _handle_artifact_progression(artifact_id: String):
	"""Handle progression unlocks when artifact is activated"""
	# Check what should be unlocked based on this activation
	for check_artifact_id in artifact_definitions.keys():
		var definition = artifact_definitions[check_artifact_id]
		var unlock_conditions = definition.get("unlock_conditions", [])
		
		# Simple check - if this artifact triggered unlocks another
		var unlock_trigger = artifact_id + "_triggered"
		if unlock_trigger in unlock_conditions:
			_unlock_artifact(check_artifact_id)

func _unlock_artifact(artifact_id: String):
	"""Unlock and instantiate a new artifact"""
	if artifact_instances.has(artifact_id):
		return  # Already exists
	
	print("LabManager: Unlocking artifact: %s" % artifact_id)
	
	# Add to active artifacts
	var current_state = artifact_system_state.get("current_state", {})
	var active_artifacts = current_state.get("active_artifacts", [])
	
	if not artifact_id in active_artifacts:
		active_artifacts.append(artifact_id)
		_instantiate_artifact(artifact_id)
		
		# Update system state
		artifact_system_state["artifact_states"][artifact_id]["status"] = "active"
		
		# Emit unlock signal
		artifact_unlocked.emit(artifact_id)

func _handle_sequence_progression(artifact_id: String, sequence_name: String):
	"""Track sequence progression for future unlocks"""
	# This is where the manager tracks educational progress
	# without interfering with the actual sequence execution
	pass

# Public API - Management functions only
func get_active_artifacts() -> Array:
	return artifact_system_state.get("current_state", {}).get("active_artifacts", [])

func get_artifact_instance(artifact_id: String) -> Node3D:
	return artifact_instances.get(artifact_id, null)

func is_artifact_active(artifact_id: String) -> bool:
	return artifact_instances.has(artifact_id)

func force_unlock_artifact(artifact_id: String):
	"""Force unlock for testing"""
	_unlock_artifact(artifact_id)

func get_artifact_definitions() -> Dictionary:
	return artifact_definitions
