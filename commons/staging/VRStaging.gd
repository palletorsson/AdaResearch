# VRStaging.gd - Updated to use lab-centric architecture
extends XRToolsStaging
class_name AdaVRStaging

# Scene paths
const LAB_SCENE = "res://commons/scenes/lab.tscn"
const GRID_SCENE = "res://commons/scenes/grid.tscn" 
const BASE_SCENE = "res://commons/scenes/base.tscn"

# Configuration
@export var use_lab_system: bool = true
@export var start_with_grid_system: bool = false  # Changed default to false
@export var preferred_grid_map: String = "Tutorial_2D"
@export var main_scene: String = LAB_SCENE  # Changed to lab scene

func _ready():
	print("VRStaging: Starting initialization with lab-centric architecture...")
	
	print("=== VR Staging Startup Info (Lab-Centric) ===")
	print("Use lab system: %s" % use_lab_system)
	print("Start with grid system: %s" % start_with_grid_system)
	print("Preferred grid map: %s" % preferred_grid_map)
	print("Main scene: %s" % main_scene)
	print("==========================================")
	
	# Always start with lab scene in new architecture
	if use_lab_system:
		print("VRStaging: Starting with lab hub scene")
		load_scene(LAB_SCENE)
	else:
		print("VRStaging: Using base scene for compatibility")
		load_scene(BASE_SCENE)

func load_scene(scene_path: String):
	print("VRStaging: Loading scene: %s" % scene_path)
	
	# Store current scene info
	current_scene_path = scene_path
	
	# Load and switch to the scene
	var scene_resource = load(scene_path)
	if scene_resource:
		# Set scene metadata before loading
		_set_scene_metadata(scene_path)
		
		# Call parent load_scene with the resource
		super.load_scene(scene_resource)
		
		# Setup scene-specific systems after loading
		await scene_loaded
		_setup_scene_systems(scene_path)
	else:
		print("VRStaging: ERROR - Could not load scene: %s" % scene_path)

func _set_scene_metadata(scene_path: String):
	var metadata = {
		"scene_path": scene_path,
		"load_time": Time.get_unix_time_from_system()
	}
	
	# Add scene-specific metadata
	if scene_path == LAB_SCENE:
		metadata["scene_type"] = "lab_hub"
		metadata["system_mode"] = "progression"
	elif scene_path == GRID_SCENE:
		metadata["scene_type"] = "sequence_execution"
		metadata["system_mode"] = "active_learning"
	else:
		metadata["scene_type"] = "base"
		metadata["system_mode"] = "general"
	
	set_meta("scene_metadata", metadata)
	print("VRStaging: Set scene metadata: %s" % str(metadata))

func _setup_scene_systems(scene_path: String):
	print("VRStaging: Setting up systems for scene: %s" % scene_path)
	
	match scene_path:
		LAB_SCENE:
			_setup_lab_systems()
		GRID_SCENE:
			_setup_grid_systems()
		BASE_SCENE:
			_setup_base_systems()
		_:
			print("VRStaging: Unknown scene type, using default setup")

func _setup_lab_systems():
	print("VRStaging: Setting up lab hub systems")
	
	# Find and initialize lab manager
	var lab_manager = current_scene.find_child("LabManager", true, false)
	if lab_manager:
		print("VRStaging: Found LabManager, checking for completion data")
		
		# Check if returning from grid with completion data
		if has_meta("completion_data"):
			var completion_data = get_meta("completion_data")
			print("VRStaging: Processing completion data: %s" % str(completion_data))
			
			# Pass artifacts to lab manager
			if completion_data.has("artifacts") and lab_manager.has_method("add_artifacts"):
				lab_manager.add_artifacts(completion_data.artifacts)
			
			# Clear completion data
			remove_meta("completion_data")
	else:
		print("VRStaging: WARNING - LabManager not found in lab scene")

func _setup_grid_systems():
	print("VRStaging: Setting up grid sequence systems")
	
	# Find and initialize sequence runner
	var sequence_runner = current_scene.find_child("SequenceRunner", true, false)
	if sequence_runner:
		print("VRStaging: Found SequenceRunner")
		
		# Connect sequence completion signal
		if sequence_runner.has_signal("sequence_completed"):
			sequence_runner.sequence_completed.connect(_on_sequence_completed)
	else:
		print("VRStaging: WARNING - SequenceRunner not found in grid scene")

func _setup_base_systems():
	print("VRStaging: Setting up base/compatibility systems")
	# This would be the old complex system if needed for backwards compatibility

func _on_sequence_completed(sequence_name: String, artifacts: Array):
	print("VRStaging: Sequence '%s' completed with %d artifacts" % [sequence_name, artifacts.size()])
	
	# This will be handled by SequenceRunner's _return_to_lab method
	# No additional processing needed here

# Public API for scene transitions
func start_sequence(sequence_name: String):
	print("VRStaging: Starting sequence '%s'" % sequence_name)
	
	# Store sequence data
	var sequence_data = {
		"sequence_name": sequence_name,
		"start_time": Time.get_unix_time_from_system(),
		"return_to": "lab"
	}
	
	set_meta("sequence_data", sequence_data)
	load_scene(GRID_SCENE)

func return_to_lab(completion_data: Dictionary = {}):
	print("VRStaging: Returning to lab")
	
	if not completion_data.is_empty():
		set_meta("completion_data", completion_data)
	
	load_scene(LAB_SCENE)

# Compatibility methods
func get_current_scene_type() -> String:
	if has_meta("scene_metadata"):
		var metadata = get_meta("scene_metadata")
		return metadata.get("scene_type", "unknown")
	return "unknown"

func is_in_lab() -> bool:
	return get_current_scene_type() == "lab_hub"

func is_in_sequence() -> bool:
	return get_current_scene_type() == "sequence_execution" 