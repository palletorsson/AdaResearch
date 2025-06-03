# SceneManager.gd
# New consolidated scene manager for handling transitions between lab and grid scenes
# Replaces deprecated sequence/task managers

extends Node
class_name SceneManager

# Scene references and paths
const GRID_SCENE_PATH = "res://commons/scenes/grid.tscn"
const LAB_SCENE_PATH = "res://commons/scenes/lab.tscn"

# State tracking
var current_scene_type: String = ""
var sequence_data: Dictionary = {}
var staging_ref: Node = null

# Signals
signal scene_transition_started(from_scene: String, to_scene: String)
signal scene_transition_completed(scene_name: String)
signal sequence_started(sequence_name: String)

func _ready():
	print("SceneManager: Initialized - ready to handle cube → grid transitions")

# Connect to lab manager's cube activation
func connect_to_lab_manager(lab_manager: LabManager):
	if lab_manager:
		lab_manager.artifact_activated.connect(_on_artifact_activated)
		lab_manager.progression_event.connect(_on_progression_event)
		print("SceneManager: Connected to LabManager")

# Handle artifact activation from lab
func _on_artifact_activated(artifact_id: String):
	match artifact_id:
		"rotating_cube":
			_start_array_tutorial_sequence()
		_:
			print("SceneManager: Unhandled artifact: %s" % artifact_id)

# Handle progression events from lab
func _on_progression_event(event_name: String, event_data: Dictionary):
	match event_name:
		"sequence_triggered":
			var sequence_name = event_data.get("sequence_name", "")
			_start_sequence(sequence_name)

# Start the array tutorial sequence
func _start_array_tutorial_sequence():
	print("SceneManager: Starting array tutorial sequence")
	
	# Define the array tutorial sequence
	sequence_data = {
		"sequence_name": "array_tutorial",
		"maps": ["Tutorial_Single", "Tutorial_Row", "Tutorial_2D", "Tutorial_Disco"],
		"current_step": 0,
		"return_to": "lab"
	}
	
	_load_grid_scene_with_first_map()

# Start any sequence by name
func _start_sequence(sequence_name: String):
	print("SceneManager: Starting sequence: %s" % sequence_name)
	
	match sequence_name:
		"array_tutorial":
			_start_array_tutorial_sequence()
		"randomness_exploration":
			_start_randomness_sequence()
		"geometric_algorithms":
			_start_geometric_sequence()
		_:
			print("SceneManager: Unknown sequence: %s" % sequence_name)

# Load grid scene with the first map in sequence
func _load_grid_scene_with_first_map():
	if sequence_data.is_empty():
		print("SceneManager: ERROR - No sequence data")
		return
	
	var maps = sequence_data.get("maps", [])
	if maps.is_empty():
		print("SceneManager: ERROR - No maps in sequence")
		return
	
	var first_map = maps[0]
	print("SceneManager: Loading grid scene with map: %s" % first_map)
	
	# Prepare scene data for grid.tscn
	var grid_scene_data = {
		"sequence_data": sequence_data,
		"initial_map": first_map,
		"scene_manager": self
	}
	
	# Get VR staging reference and load grid scene
	var staging = _get_vr_staging()
	if staging:
		current_scene_type = "grid"
		staging.set_meta("sequence_data", sequence_data)
		scene_transition_started.emit("lab", "grid")
		staging.load_scene(GRID_SCENE_PATH, grid_scene_data)
	else:
		print("SceneManager: ERROR - Could not find VR staging")

# Return to lab with completion data
func return_to_lab(completion_data: Dictionary = {}):
	print("SceneManager: Returning to lab")
	print("SceneManager: Completion data: %s" % completion_data)
	
	var staging = _get_vr_staging()
	if staging:
		current_scene_type = "lab"
		staging.set_meta("completion_data", completion_data)
		scene_transition_started.emit("grid", "lab")
		staging.load_scene(LAB_SCENE_PATH, {"return_from": "grid"})
	else:
		print("SceneManager: ERROR - Could not find VR staging for return")

# Get VR staging node
func _get_vr_staging() -> Node:
	if staging_ref:
		return staging_ref
	
	# Try to find VR staging
	var potential_staging = get_node_or_null("/root/VRStaging")
	if potential_staging:
		staging_ref = potential_staging
		return staging_ref
	
	# Alternative paths
	var tree_root = get_tree().current_scene
	if tree_root and tree_root.name == "VRStaging":
		staging_ref = tree_root
		return staging_ref
	
	print("SceneManager: WARNING - VR Staging not found")
	return null

# Start randomness sequence (placeholder)
func _start_randomness_sequence():
	sequence_data = {
		"sequence_name": "randomness_exploration", 
		"maps": ["Random_0", "Random_1", "Random_2"],
		"current_step": 0,
		"return_to": "lab"
	}
	_load_grid_scene_with_first_map()

# Start geometric sequence (placeholder)
func _start_geometric_sequence():
	sequence_data = {
		"sequence_name": "geometric_algorithms",
		"maps": ["Geometric_1", "Geometric_2"], 
		"current_step": 0,
		"return_to": "lab"
	}
	_load_grid_scene_with_first_map()

# Public API
func get_current_sequence_data() -> Dictionary:
	return sequence_data

func get_current_scene_type() -> String:
	return current_scene_type

func set_staging_reference(staging: Node):
	staging_ref = staging
	print("SceneManager: Staging reference set")

# Handle sequence completion (called from grid scene)
func complete_sequence(completion_data: Dictionary):
	sequence_started.emit(completion_data.get("sequence_name", ""))
	return_to_lab(completion_data)
