# LabManager.gd - Simplified JSON reader and artifact instantiator
extends Node3D
class_name LabManager

# JSON data
var artifact_definitions: Dictionary = {}
var artifact_system_state: Dictionary = {}

# Artifact tracking
var active_artifacts: Dictionary = {}

# Lab scene reference (for signaling)
var lab_scene: Node3D

# Signals for lab scene coordination
signal artifact_activated(artifact_id: String)
signal progression_event(event_name: String, event_data: Dictionary)

func _ready():
	print("LabManager: Initializing as JSON-driven artifact loader")
	
	# Get lab scene reference
	lab_scene = get_parent()
	
	# Load JSON configurations
	_load_json_data()
	
	# Create artifacts based on system state
	_create_artifacts_from_system_state()

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
	
	print("LabManager: JSON text length: %d" % json_text.length())  # Debug
	
	var json = JSON.new()
	var parse_result = json.parse(json_text)
	
	if parse_result == OK:
		print("LabManager: JSON parsed successfully")  # Debug
		print("LabManager: JSON data keys: ", json.data.keys())  # Debug
		
		artifact_definitions = json.data.get("artifacts", {})
		print("LabManager: Artifact definitions type: %s" % typeof(artifact_definitions))  # Debug
		print("LabManager: Artifact definitions keys: %s" % artifact_definitions.keys())  # Debug
		print("LabManager: Loaded %d artifact definitions" % artifact_definitions.size())
	else:
		print("LabManager: ERROR - Failed to parse JSON: %s" % json.get_error_message())

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
		print("LabManager: Loaded artifact system state")

func _create_artifacts_from_system_state():
	"""Create only the artifacts specified as visible in system state"""
	var current_state = artifact_system_state.get("current_state", {})
	var visible_artifacts = current_state.get("visible_artifacts", [])
	
	print("LabManager: Creating visible artifacts: %s" % str(visible_artifacts))
	
	for artifact_id in visible_artifacts:
		_instantiate_artifact(artifact_id)
	
	# Apply lighting configuration
	_apply_lighting_from_system_state()

func _instantiate_artifact(artifact_id: String):
	"""Instantiate an artifact from definition - dumb loader only"""
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
	
	# Apply basic positioning from definition
	var position = definition.get("position", [0, 0, 0])
	var rotation = definition.get("rotation", [0, 0, 0])
	var scale_def = definition.get("scale", [1, 1, 1])
	
	artifact_instance.position = Vector3(position[0], position[1], position[2])
	artifact_instance.rotation_degrees = Vector3(rotation[0], rotation[1], rotation[2])
	artifact_instance.scale = Vector3(scale_def[0], scale_def[1], scale_def[2])
	
	# Connect signals (dumb connection - just forward to lab scene)
	_connect_artifact_signals(artifact_instance, artifact_id)
	
	# Add lighting if specified
	_add_artifact_lighting(artifact_instance, definition)
	
	# Add to scene
	add_child(artifact_instance)
	active_artifacts[artifact_id] = artifact_instance
	
	print("LabManager: Created artifact '%s' at %s" % [artifact_id, str(position)])

func _connect_artifact_signals(artifact_instance: Node3D, artifact_id: String):
	"""Connect artifact signals - just forward to lab scene"""
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

func _apply_lighting_from_system_state():
	"""Apply lab lighting based on system state"""
	var current_state = artifact_system_state.get("current_state", {})
	var lighting_mode = current_state.get("lab_lighting", "minimal_cube_focused")
	
	var lighting_configs = artifact_system_state.get("lighting_configurations", {})
	if lighting_configs.has(lighting_mode):
		var config = lighting_configs[lighting_mode]
		
		# Apply to world environment
		var world_env = get_node("../WorldEnvironment")
		if world_env and world_env.environment:
			var env = world_env.environment
			env.ambient_light_energy = config.get("ambient_energy", 0.1)
		
		print("LabManager: Applied lighting mode: %s" % lighting_mode)

# Signal handlers - just forward to lab scene
func _on_artifact_activated(artifact_id: String):
	"""Forward artifact activation to lab scene"""
	print("LabManager: Artifact '%s' activated - forwarding to lab scene" % artifact_id)
	artifact_activated.emit(artifact_id)

func _on_sequence_triggered(artifact_id: String, sequence_name: String):
	"""Forward sequence trigger to lab scene"""
	print("LabManager: Sequence '%s' triggered by '%s' - forwarding to lab scene" % [sequence_name, artifact_id])
	
	var event_data = {
		"artifact_id": artifact_id,
		"sequence_name": sequence_name,
		"trigger_type": "sequence"
	}
	progression_event.emit("sequence_triggered", event_data)

# Public API - simple queries only
func get_active_artifacts() -> Array:
	return active_artifacts.keys()

func get_artifact_instance(artifact_id: String) -> Node3D:
	return active_artifacts.get(artifact_id, null)

func is_artifact_active(artifact_id: String) -> bool:
	return active_artifacts.has(artifact_id)
