# SceneManager.gd
# Universal scene transition manager - handles ALL types of transitions via signals
# Scales from simple cube activation to complex teleporter/trigger systems

extends Node
class_name SceneManager

# Scene references and paths
const GRID_SCENE_PATH = "res://commons/scenes/grid.tscn"
const LAB_SCENE_PATH = "res://commons/scenes/lab.tscn"

# Transition types
enum TransitionType {
	ARTIFACT_ACTIVATION,    # Cube, display, sign activation
	TELEPORTER,            # Teleporter utility activation
	TRIGGER_ZONE,          # Spatial trigger zones
	SEQUENCE_COMPLETE,     # End of map sequence
	MANUAL_LOAD,          # Direct scene load
	RETURN_TO_HUB         # Return to lab hub
}

# State tracking
var current_scene_type: String = ""
var current_sequence_data: Dictionary = {}
var staging_ref: Node = null
var transition_history: Array = []

# Signals
signal scene_transition_started(from_scene: String, to_scene: String, transition_type: TransitionType)
signal scene_transition_completed(scene_name: String, user_data: Dictionary)
signal sequence_started(sequence_name: String, sequence_data: Dictionary)

func _ready():
	print("SceneManager: Initialized - Universal transition system ready")
	print("SceneManager: Handles artifact, teleporter, trigger, and sequence transitions")

# =============================================================================
# CONNECTION METHODS - Connect various systems to SceneManager
# =============================================================================

# Connect to lab manager for artifact activations
func connect_to_lab_manager(lab_manager: LabManager):
	if lab_manager:
		pass
		# E 0:00:06:634   SceneManager.gd:44 @ connect_to_lab_manager(): Signal 'artifact_activated' is already connected to given callable 'Node(SceneManager)::_on_artifact_activated' in that object.
		# lab_manager.artifact_activated.connect(_on_artifact_activated)
		# E 0:00:06:635   SceneManager.gd:45 @ connect_to_lab_manager(): Signal 'progression_event' is already connected to given callable 'Node(SceneManager)::_on_progression_event' in that object.
		#lab_manager.progression_event.connect(_on_progression_event)
		# print("SceneManager: Connected to LabManager")

# Connect to grid system for teleporter/trigger events
func connect_to_grid_system(grid_system: Node):
	if grid_system:
		# Connect to utility signals
		if grid_system.has_signal("utility_activated"):
			grid_system.utility_activated.connect(_on_utility_activated)
		
		# Connect to interactable signals  
		if grid_system.has_signal("interactable_activated"):
			grid_system.interactable_activated.connect(_on_interactable_activated)
		
		print("SceneManager: Connected to GridSystem")

# Connect to any trigger zones in current scene
func connect_to_trigger_zones():
	var trigger_zones = get_tree().get_nodes_in_group("trigger_zones")
	for zone in trigger_zones:
		if zone.has_signal("zone_triggered"):
			zone.zone_triggered.connect(_on_trigger_zone_activated)
	
	print("SceneManager: Connected to %d trigger zones" % trigger_zones.size())

# =============================================================================
# SIGNAL HANDLERS - Handle different types of transition triggers
# =============================================================================

# Handle artifact activation (cube, displays, signs)
func _on_artifact_activated(artifact_id: String):
	print("SceneManager: Artifact activated: %s" % artifact_id)
	
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
			print("SceneManager: Unhandled artifact: %s" % artifact_id)

# Handle utility activation (teleporters, exits, etc.)
func _on_utility_activated(utility_type: String, position: Vector3, utility_data: Dictionary):
	print("SceneManager: Utility activated: %s at %s" % [utility_type, position])
	
	match utility_type:
		"t", "teleporter":  # Teleporter activation
			var destination = utility_data.get("destination", "")
			request_transition({
				"type": TransitionType.TELEPORTER,
				"source": "teleporter",
				"destination": destination,
				"spawn_point": utility_data.get("spawn_point", "default")
			})

		_:
			print("SceneManager: Unhandled utility type: %s" % utility_type)

# Handle interactable activation (algorithms, triggers)
func _on_interactable_activated(object_id: String, position: Vector3, data: Dictionary):
	print("SceneManager: Interactable activated: %s" % object_id)
	
	# Check if this interactable triggers a transition
	if data.has("transition_trigger"):
		var trigger_data = data["transition_trigger"]
		trigger_data["type"] = TransitionType.TRIGGER_ZONE
		trigger_data["source"] = object_id
		request_transition(trigger_data)

# Handle trigger zone activation
func _on_trigger_zone_activated(zone_id: String, trigger_data: Dictionary):
	print("SceneManager: Trigger zone activated: %s" % zone_id)
	
	trigger_data["type"] = TransitionType.TRIGGER_ZONE
	trigger_data["source"] = zone_id
	request_transition(trigger_data)

# Handle progression events
func _on_progression_event(event_name: String, event_data: Dictionary):
	print("SceneManager: Progression event: %s" % event_name)
	
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

# Universal transition request handler
func request_transition(transition_request: Dictionary):
	print("SceneManager: Processing transition request: %s" % transition_request)
	
	var transition_type = transition_request.get("type", TransitionType.MANUAL_LOAD)
	var action = transition_request.get("action", "")
	
	# Add to history
	transition_history.append({
		"timestamp": Time.get_datetime_string_from_system(),
		"request": transition_request
	})
	
	# Route based on action type
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
			print("SceneManager: Unknown action: %s" % action)

# Start sequence from transition request
func _start_sequence_from_request(request: Dictionary):
	var sequence_name = request.get("sequence", "")
	
	# Define sequence configurations
	var sequence_configs = {
		"array_tutorial": {
			"maps": ["Tutorial_Single", "Tutorial_Row", "Tutorial_2D", "Tutorial_Disco"],
			"return_to": "lab"
		},
		"randomness_exploration": {
			"maps": ["Random_0", "Random_1", "Random_2"],
			"return_to": "lab"
		},
		"geometric_algorithms": {
			"maps": ["Geometric_1", "Geometric_2"],
			"return_to": "lab"
		}
	}
	
	if not sequence_configs.has(sequence_name):
		print("SceneManager: Unknown sequence: %s" % sequence_name)
		return
	
	var config = sequence_configs[sequence_name]
	current_sequence_data = {
		"sequence_name": sequence_name,
		"maps": config.maps,
		"current_step": 0,
		"return_to": config.return_to,
		"transition_source": request
	}
	
	_load_grid_scene_with_first_map()

# Load specific map directly
func _load_specific_map(request: Dictionary):
	var map_name = request.get("destination", "")
	var spawn_point = request.get("spawn_point", "default")
	
	if map_name.is_empty():
		print("SceneManager: No destination specified in request")
		return
	
	var scene_data = {
		"map_name": map_name,
		"spawn_point": spawn_point,
		"scene_manager": self,
		"transition_source": request
	}
	
	_load_scene_with_data(GRID_SCENE_PATH, scene_data)

# Load grid scene with the first map in sequence
func _load_grid_scene_with_first_map():
	if current_sequence_data.is_empty():
		print("SceneManager: ERROR - No sequence data")
		return
	
	var maps = current_sequence_data.get("maps", [])
	if maps.is_empty():
		print("SceneManager: ERROR - No maps in sequence")
		return
	
	var first_map = maps[0]
	print("SceneManager: Loading grid scene with map: %s" % first_map)
	
	var grid_scene_data = {
		"sequence_data": current_sequence_data,
		"initial_map": first_map,
		"scene_manager": self
	}
	
	_load_scene_with_data(GRID_SCENE_PATH, grid_scene_data)

# Advance to next map in current sequence
func _advance_sequence():
	if current_sequence_data.is_empty():
		print("SceneManager: No active sequence to advance")
		return
	
	var maps = current_sequence_data.get("maps", [])
	var current_step = current_sequence_data.get("current_step", 0)
	
	if current_step + 1 >= maps.size():
		# Sequence complete - return to hub
		_return_to_hub({"sequence_completed": current_sequence_data.sequence_name})
		return
	
	# Advance to next map
	current_sequence_data.current_step = current_step + 1
	var next_map = maps[current_sequence_data.current_step]
	
	print("SceneManager: Advancing sequence to map: %s (%d/%d)" % [next_map, current_step + 1, maps.size()])
	
	var scene_data = {
		"sequence_data": current_sequence_data,
		"map_name": next_map,
		"scene_manager": self
	}
	
	_load_scene_with_data(GRID_SCENE_PATH, scene_data)

# Return to lab hub
func _return_to_hub(completion_data: Dictionary = {}):
	print("SceneManager: Returning to lab hub")
	print("SceneManager: Completion data: %s" % completion_data)
	
	current_sequence_data.clear()
	
	var lab_scene_data = {
		"return_from": "grid",
		"completion_data": completion_data,
		"scene_manager": self
	}
	
	_load_scene_with_data(LAB_SCENE_PATH, lab_scene_data)

# =============================================================================
# CORE SCENE LOADING
# =============================================================================

# Universal scene loading with data
func _load_scene_with_data(scene_path: String, scene_data: Dictionary):
	var staging = _get_vr_staging()
	if not staging:
		print("SceneManager: ERROR - Could not find VR staging")
		return
	
	var from_scene = current_scene_type
	var to_scene = "lab" if scene_path == LAB_SCENE_PATH else "grid"
	
	current_scene_type = to_scene
	staging.set_meta("scene_data", scene_data)
	
	var transition_type = scene_data.get("transition_source", {}).get("type", TransitionType.MANUAL_LOAD)
	scene_transition_started.emit(from_scene, to_scene, transition_type)
	
	staging.load_scene(scene_path, scene_data)

# Get VR staging node  
func _get_vr_staging() -> Node:
	if staging_ref:
		return staging_ref
	
	# Try multiple paths to find VR staging
	var potential_paths = [
		"/root/VRStaging",
		"/root/AdaVRStaging" 
	]
	
	for path in potential_paths:
		var staging = get_node_or_null(path)
		if staging:
			staging_ref = staging
			return staging_ref
	
	# Try current scene if it's staging
	var tree_root = get_tree().current_scene
	if tree_root and ("staging" in tree_root.name.to_lower() or "vr" in tree_root.name.to_lower()):
		staging_ref = tree_root
		return staging_ref
	
	print("SceneManager: WARNING - VR Staging not found")
	return null

# =============================================================================
# PUBLIC API
# =============================================================================

# Public transition methods for external systems
func load_map(map_name: String, spawn_point: String = "default"):
	"""Load a specific map directly"""
	request_transition({
		"type": TransitionType.MANUAL_LOAD,
		"action": "load_map",
		"destination": map_name,
		"spawn_point": spawn_point
	})

func start_sequence(sequence_name: String):
	"""Start a specific sequence"""
	request_transition({
		"type": TransitionType.MANUAL_LOAD,
		"action": "start_sequence",
		"sequence": sequence_name
	})

func return_to_lab(completion_data: Dictionary = {}):
	"""Return to lab with optional completion data"""
	request_transition({
		"type": TransitionType.RETURN_TO_HUB,
		"action": "return_to_hub",
		"completion_data": completion_data
	})

# State queries
func get_current_sequence_data() -> Dictionary:
	return current_sequence_data

func get_current_scene_type() -> String:
	return current_scene_type

func is_in_sequence() -> bool:
	return not current_sequence_data.is_empty()

func get_transition_history() -> Array:
	return transition_history

# Setup methods
func set_staging_reference(staging: Node):
	staging_ref = staging
	print("SceneManager: Staging reference set to: %s" % staging.name)

func auto_connect_to_scene():
	"""Automatically connect to current scene systems"""
	var scene = get_tree().current_scene if get_tree() else null
	if not scene:
		print("SceneManager: No current scene available for auto-connection")
		return
	
	print("SceneManager: Auto-connecting to scene: %s" % scene.name)
	
	# Connect to grid system if present
	var grid_system = scene.find_child("GridSystem", true, false)
	if not grid_system:
		grid_system = scene.find_child("multiLayerGrid", true, false)
	if grid_system:
		connect_to_grid_system(grid_system)
		print("SceneManager: Connected to grid system: %s" % grid_system.name)
	
	# Connect to lab manager if present
	var lab_manager = scene.find_child("LabManager", true, false)
	if lab_manager and lab_manager is LabManager:
		connect_to_lab_manager(lab_manager)
		print("SceneManager: Connected to lab manager: %s" % lab_manager.name)
	
	# Connect to trigger zones
	connect_to_trigger_zones()
	
	print("SceneManager: Auto-connection complete")

# =============================================================================
# LEGACY COMPATIBILITY (remove later)
# =============================================================================

# Legacy methods for backward compatibility
func complete_sequence(completion_data: Dictionary):
	return_to_lab(completion_data)

# Remove these when updating old code:
func _start_randomness_sequence():
	start_sequence("randomness_exploration")

func _start_geometric_sequence(): 
	start_sequence("geometric_algorithms")
