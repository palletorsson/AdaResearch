# AdaSceneManager.gd - RENAMED TO AVOID GODOT CLASS COLLISION
# Universal scene transition manager - now as singleton
# Add this script as AutoLoad in Project Settings with name "AdaSceneManager"

extends Node
class_name AdaSceneManager

# Singleton instance
static var instance: AdaSceneManager

# Scene references and paths
const GRID_SCENE_PATH = "res://commons/scenes/grid.tscn"
const LAB_SCENE_PATH = "res://commons/scenes/lab.tscn"

# Transition types
enum TransitionType {
	ARTIFACT_ACTIVATION,
	TELEPORTER,
	TRIGGER_ZONE,
	SEQUENCE_COMPLETE,
	MANUAL_LOAD,
	RETURN_TO_HUB
}

# State tracking
var current_scene_type: String = ""
var current_sequence_data: Dictionary = {}
var staging_ref: Node = null
var transition_history: Array = []

# Sequence data loaded from JSON
var sequence_configs: Dictionary = {}
const SEQUENCES_JSON_PATH = "res://commons/maps/map_sequences.json"

# Signals
signal scene_transition_started(from_scene: String, to_scene: String, transition_type: TransitionType)
signal scene_transition_completed(scene_name: String, user_data: Dictionary)
signal sequence_started(sequence_name: String, sequence_data: Dictionary)

func _init():
	# Ensure singleton pattern
	if instance == null:
		instance = self
		print("AdaSceneManager: Singleton instance created")
	else:
		print("AdaSceneManager: ERROR - Multiple instances detected!")
		queue_free()

func _ready():
	if instance != self:
		return
		
	print("AdaSceneManager: Singleton initialized - Universal transition system ready")
	print("AdaSceneManager: Handles artifact, teleporter, trigger, and sequence transitions")
	
	# Load sequence configurations from JSON
	_load_sequence_configurations()

# =============================================================================
# SINGLETON ACCESS
# =============================================================================

static func get_instance() -> AdaSceneManager:
	"""Get the singleton instance"""
	if instance == null:
		push_error("AdaSceneManager: Singleton not initialized!")
	return instance

static func is_available() -> bool:
	"""Check if singleton is available"""
	return instance != null

# =============================================================================
# SEQUENCE CONFIGURATION LOADING
# =============================================================================

func _load_sequence_configurations():
	"""Load sequence configurations from JSON file"""
	print("AdaSceneManager: Loading sequence configurations from JSON...")
	
	if not FileAccess.file_exists(SEQUENCES_JSON_PATH):
		print("AdaSceneManager: WARNING - Sequences JSON file not found: %s" % SEQUENCES_JSON_PATH)
		_create_fallback_sequences()
		return
	
	var file = FileAccess.open(SEQUENCES_JSON_PATH, FileAccess.READ)
	if not file:
		print("AdaSceneManager: ERROR - Could not open sequences file")
		_create_fallback_sequences()
		return
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_text)
	
	if parse_result != OK:
		print("AdaSceneManager: ERROR - Failed to parse sequences JSON: %s" % json.get_error_message())
		_create_fallback_sequences()
		return
	
	var json_data = json.data
	sequence_configs = json_data.get("sequences", {})
	
	if sequence_configs.is_empty():
		print("AdaSceneManager: WARNING - No sequences found in JSON file")
		_create_fallback_sequences()
		return
	
	print("AdaSceneManager: Loaded %d sequence configurations from JSON" % sequence_configs.size())
	
	# Log loaded sequences for debugging
	for sequence_name in sequence_configs.keys():
		var config = sequence_configs[sequence_name]
		var maps = config.get("maps", [])
		print("  → %s: %d maps (%s)" % [sequence_name, maps.size(), str(maps)])

func _create_fallback_sequences():
	"""Create fallback sequences if JSON loading fails"""
	print("AdaSceneManager: Creating fallback sequence configurations")
	
	sequence_configs = {
		"array_tutorial": {
			"maps": ["Tutorial_Single", "Tutorial_Row", "Tutorial_2D", "Tutorial_Disco"],
			"return_to": "lab",
			"name": "Array Tutorial (Fallback)",
			"description": "Basic array concepts tutorial sequence"
		},
		"randomness_exploration": {
			"maps": ["Random_0", "Random_1", "Random_2"],
			"return_to": "lab",
			"name": "Randomness Exploration (Fallback)",
			"description": "Explore randomness and probability"
		},
		"geometric_algorithms": {
			"maps": ["Geometric_1", "Geometric_2"],
			"return_to": "lab",
			"name": "Geometric Algorithms (Fallback)",
			"description": "Geometric algorithm visualization"
		}
	}
	
	print("AdaSceneManager: Created %d fallback sequences" % sequence_configs.size())

# =============================================================================
# SIMPLIFIED CONNECTION METHODS
# =============================================================================

func connect_to_lab_manager(lab_manager: LabManager):
	"""Connect to lab manager for artifact activations"""
	if lab_manager and not lab_manager.artifact_activated.is_connected(_on_artifact_activated):
		lab_manager.artifact_activated.connect(_on_artifact_activated)
		lab_manager.progression_event.connect(_on_progression_event)
		print("AdaSceneManager: Connected to LabManager")

func connect_to_grid_system(grid_system: Node):
	"""Connect to grid system for teleporter/trigger events"""
	if grid_system and not grid_system.interactable_activated.is_connected(_on_interactable_activated):
		grid_system.interactable_activated.connect(_on_interactable_activated)
		print("AdaSceneManager: Connected to GridSystem")

# =============================================================================
# SIGNAL HANDLERS
# =============================================================================

func _on_artifact_activated(artifact_id: String):
	print("AdaSceneManager: Artifact activated: %s" % artifact_id)
	
	match artifact_id:
		"rotating_cube":
			request_transition({
				"type": TransitionType.ARTIFACT_ACTIVATION,
				"source": "rotating_cube",
				"action": "start_sequence",
				"sequence": "array_tutorial",
				"first_map": "Tutorial_Single"
			})
		"grid_display":
			request_transition({
				"type": TransitionType.ARTIFACT_ACTIVATION,
				"source": "grid_display", 
				"action": "start_sequence",
				"sequence": "array_visualization"
			})
		"randomness_sign":
			request_transition({
				"type": TransitionType.ARTIFACT_ACTIVATION,
				"source": "randomness_sign",
				"action": "start_sequence", 
				"sequence": "randomness_exploration"
			})
		_:
			print("AdaSceneManager: Unhandled artifact: %s" % artifact_id)

func _on_interactable_activated(object_id: String, position: Vector3, data: Dictionary):
	print("AdaSceneManager: Interactable activated: %s" % object_id)
	
	if data.has("transition_trigger"):
		var trigger_data = data["transition_trigger"]
		trigger_data["type"] = TransitionType.TRIGGER_ZONE
		trigger_data["source"] = object_id
		request_transition(trigger_data)

func _on_progression_event(event_name: String, event_data: Dictionary):
	print("AdaSceneManager: Progression event: %s" % event_name)
	
	match event_name:
		"sequence_triggered":
			var sequence_name = event_data.get("sequence_name", "")
			request_transition({
				"type": TransitionType.ARTIFACT_ACTIVATION,
				"action": "start_sequence",
				"sequence": sequence_name
			})
		"sequence_completed":
			request_transition({
				"type": TransitionType.SEQUENCE_COMPLETE,
				"action": "return_to_hub",
				"completion_data": event_data
			})

# =============================================================================
# UNIVERSAL TRANSITION REQUEST SYSTEM
# =============================================================================

func request_transition(transition_request: Dictionary):
	print("AdaSceneManager: Processing transition request: %s" % transition_request)
	
	var transition_type = transition_request.get("type", TransitionType.MANUAL_LOAD)
	var action = transition_request.get("action", "")
	
	transition_history.append({
		"timestamp": Time.get_datetime_string_from_system(),
		"request": transition_request
	})
	
	match action:
		"start_sequence":
			_start_sequence_from_request(transition_request)
		"load_map":
			_load_specific_map(transition_request)
		"next_in_sequence":
			_advance_sequence()
		"return_to_hub":
			_return_to_hub(transition_request.get("completion_data", {}))
		_:
			print("AdaSceneManager: Unknown action: %s" % action)

func _start_sequence_from_request(request: Dictionary):
	var sequence_name = request.get("sequence", "")
	
	if not sequence_configs.has(sequence_name):
		print("AdaSceneManager: Unknown sequence: %s" % sequence_name)
		print("AdaSceneManager: Available sequences: %s" % str(sequence_configs.keys()))
		return
	
	var config = sequence_configs[sequence_name]
	current_sequence_data = {
		"sequence_name": sequence_name,
		"maps": config.get("maps", []),
		"current_step": 0,
		"return_to": config.get("return_to", "lab"),
		"transition_source": request,
		"sequence_info": {
			"name": config.get("name", sequence_name),
			"description": config.get("description", ""),
			"total_maps": config.get("maps", []).size()
		}
	}
	
	print("AdaSceneManager: Starting sequence '%s' with %d maps" % [sequence_name, current_sequence_data.maps.size()])
	
	_load_grid_scene_with_first_map()

func _load_specific_map(request: Dictionary):
	var map_name = request.get("destination", "")
	var spawn_point = request.get("spawn_point", "default")
	
	if map_name.is_empty():
		print("AdaSceneManager: No destination specified in request")
		return
	
	var scene_data = {
		"map_name": map_name,
		"spawn_point": spawn_point,
		"scene_manager": self,
		"transition_source": request
	}
	
	_load_scene_with_data(GRID_SCENE_PATH, scene_data)

func _load_grid_scene_with_first_map():
	if current_sequence_data.is_empty():
		print("AdaSceneManager: ERROR - No sequence data")
		return
	
	var maps = current_sequence_data.get("maps", [])
	if maps.is_empty():
		print("AdaSceneManager: ERROR - No maps in sequence")
		return
	
	var first_map = maps[0]
	print("AdaSceneManager: Loading grid scene with map: %s" % first_map)
	
	var grid_scene_data = {
		"sequence_data": current_sequence_data,
		"initial_map": first_map,
		"scene_manager": self
	}
	
	_load_scene_with_data(GRID_SCENE_PATH, grid_scene_data)

func _advance_sequence():
	if current_sequence_data.is_empty():
		print("AdaSceneManager: No active sequence to advance")
		return
	
	var maps = current_sequence_data.get("maps", [])
	var current_step = current_sequence_data.get("current_step", 0)
	
	if current_step + 1 >= maps.size():
		_return_to_hub({"sequence_completed": current_sequence_data.sequence_name})
		return
	
	current_sequence_data.current_step = current_step + 1
	var next_map = maps[current_sequence_data.current_step]
	
	print("AdaSceneManager: Advancing sequence to map: %s (%d/%d)" % [next_map, current_step + 2, maps.size()])
	
	var scene_data = {
		"sequence_data": current_sequence_data,
		"map_name": next_map,
		"scene_manager": self
	}
	
	_load_scene_with_data(GRID_SCENE_PATH, scene_data)

func _return_to_hub(completion_data: Dictionary = {}):
	print("AdaSceneManager: Returning to lab hub")
	print("AdaSceneManager: Completion data: %s" % completion_data)
	
	current_sequence_data.clear()
	
	var lab_scene_data = {
		"return_from": "grid",
		"completion_data": completion_data,
		"scene_manager": self
	}
	
	_load_scene_with_data(LAB_SCENE_PATH, lab_scene_data)

func _load_scene_with_data(scene_path: String, scene_data: Dictionary):
	var staging = _get_vr_staging()
	if not staging:
		print("AdaSceneManager: ERROR - Could not find VR staging")
		return
	
	var from_scene = current_scene_type
	var to_scene = "lab" if scene_path == LAB_SCENE_PATH else "grid"
	
	current_scene_type = to_scene
	staging.set_meta("scene_data", scene_data)
	
	var transition_type = scene_data.get("transition_source", {}).get("type", TransitionType.MANUAL_LOAD)
	scene_transition_started.emit(from_scene, to_scene, transition_type)
	
	staging.load_scene(scene_path, scene_data)

func _get_vr_staging() -> Node:
	if staging_ref:
		return staging_ref
	
	var potential_paths = ["/root/VRStaging", "/root/AdaVRStaging"]
	
	for path in potential_paths:
		var staging = get_node_or_null(path)
		if staging:
			staging_ref = staging
			return staging_ref
	
	var tree_root = get_tree().current_scene
	if tree_root and ("staging" in tree_root.name.to_lower() or "vr" in tree_root.name.to_lower()):
		staging_ref = tree_root
		return staging_ref
	
	print("AdaSceneManager: WARNING - VR Staging not found")
	return null

# =============================================================================
# PUBLIC API
# =============================================================================

func load_map(map_name: String, spawn_point: String = "default"):
	request_transition({
		"type": TransitionType.MANUAL_LOAD,
		"action": "load_map",
		"destination": map_name,
		"spawn_point": spawn_point
	})

func start_sequence(sequence_name: String):
	request_transition({
		"type": TransitionType.MANUAL_LOAD,
		"action": "start_sequence",
		"sequence": sequence_name
	})

func return_to_lab(completion_data: Dictionary = {}):
	request_transition({
		"type": TransitionType.RETURN_TO_HUB,
		"action": "return_to_hub",
		"completion_data": completion_data
	})

func get_current_sequence_data() -> Dictionary:
	return current_sequence_data

func get_current_scene_type() -> String:
	return current_scene_type

func is_in_sequence() -> bool:
	return not current_sequence_data.is_empty()

func get_transition_history() -> Array:
	return transition_history

func set_staging_reference(staging: Node):
	staging_ref = staging
	print("AdaSceneManager: Staging reference set to: %s" % staging.name)
