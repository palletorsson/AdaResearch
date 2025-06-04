# GridArtifactRegistry.gd
extends Node
class_name GridArtifactRegistry

# Path to the JSON file containing artifact definitions
const ARTIFACT_DATA_PATH = "res://commons/artifacts/grid_artifacts.json"

# Main registry of artifacts
var artifacts: Dictionary = {}

# Cache of loaded scenes
var _loaded_scenes: Dictionary = {}

# Signal emitted when the registry is fully loaded
signal registry_loaded

func _ready():
	# Load the artifact data on startup
	load_artifact_data()

# Load artifact data from JSON file
func load_artifact_data() -> void:
	artifacts.clear()
	_loaded_scenes.clear()
	
	var file = FileAccess.open(ARTIFACT_DATA_PATH, FileAccess.READ)
	if not file:
		push_error("Failed to open artifact data file: %s" % ARTIFACT_DATA_PATH)
		return
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_text)
	if error != OK:
		push_error("Failed to parse artifact data JSON: %s at line %d" % [json.get_error_message(), json.get_error_line()])
		return
	
	var data = json.get_data()
	if not data is Dictionary:
		push_error("Artifact data JSON does not contain a root object")
		return
	
	if not data.has("artifacts") or not data["artifacts"] is Dictionary:
		push_error("Artifact data JSON missing 'artifacts' object")
		return
	
	# Process each artifact entry
	var artifact_data = data["artifacts"]
	for artifact_id in artifact_data.keys():
		var artifact = artifact_data[artifact_id]
		if not artifact is Dictionary:
			push_warning("Skipping invalid artifact entry (not a Dictionary): %s" % artifact_id)
			continue
		
		if not artifact.has("scene"):
			push_warning("Skipping artifact entry missing scene field: %s" % artifact_id)
			continue
		
		artifacts[artifact_id] = artifact
	
	print("Loaded %d artifact definitions from %s" % [artifacts.size(), ARTIFACT_DATA_PATH])
	emit_signal("registry_loaded")

# Get an artifact's metadata by ID
func get_artifact(id: String) -> Dictionary:
	if artifacts.has(id):
		return artifacts[id]
	return {}

# Get an artifact's scene instance by ID
func get_artifact_scene(id: String) -> Node:
	# Return from cache if already loaded
	if _loaded_scenes.has(id) and is_instance_valid(_loaded_scenes[id]):
		return _loaded_scenes[id]
	
	# Try to load the scene
	if artifacts.has(id):
		var artifact = artifacts[id]
		if artifact.has("scene"):
			var scene_path = artifact["scene"]
			if ResourceLoader.exists(scene_path):
				var scene_resource = load(scene_path)
				if scene_resource is PackedScene:
					var instance = scene_resource.instantiate()
					
					# Store in cache
					_loaded_scenes[id] = instance
					
					# Add metadata to the instance
					if instance.has_method("set_artifact_metadata"):
						instance.set_artifact_metadata(artifact)
					else:
						# Add basic properties directly
						instance.set("artifact_id", id)
						instance.set("artifact_name", artifact.get("name", "Unknown Artifact"))
						
					return instance
	
	push_warning("Failed to load artifact scene with ID: %s" % id)
	return null

# Get an array of all artifact IDs
func get_all_artifact_ids() -> Array:
	return artifacts.keys()

# Get an array of artifact IDs filtered by type
func get_artifact_ids_by_type(artifact_type: String) -> Array:
	var result = []
	for id in artifacts.keys():
		var artifact = artifacts[id]
		if artifact.has("artifact_type") and artifact["artifact_type"] == artifact_type:
			result.append(id)
	return result

# Get all available artifact types
func get_all_artifact_types() -> Array:
	var types = {}
	for id in artifacts.keys():
		var artifact = artifacts[id]
		if artifact.has("artifact_type"):
			types[artifact["artifact_type"]] = true
	return types.keys()
