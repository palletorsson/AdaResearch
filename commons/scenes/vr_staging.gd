@tool
class_name VRStaging
extends XRToolsStaging

## VR Staging System for Ada Research - Decoupled Architecture
##
## This staging system manages scene loading and VR initialization
## Now uses the decoupled lab hub and transition manager system

# Scene tracking
var current_scene: Node = null
var scene_is_loaded: bool = false

# Lab System Configuration
@export var use_lab_system: bool = true
@export var start_with_grid_system: bool = true
@export var preferred_grid_map: String = "Lab"

# VR Staging System
# Manages VR-specific setup and staging functionality
extends Node3D
class_name AdaVRStaging

# Configuration variables
@export var main_scene: String = "res://commons/scenes/base.tscn"
@export var prompt_for_continue: bool = true

# Signal emitted when staging is complete
signal staging_complete

# Node references
var map_progression_manager = null
var grid_system_manager = null

func _ready() -> void:
	# Call parent ready function
	super()
	
	print("VRStaging: Starting initialization with decoupled architecture...")
	
	# Show startup configuration
	if OS.is_debug_build():
		_show_startup_info()
	
	# Start the game system
	_start_game()

func _start_game():
	print("VRStaging: Starting game with decoupled lab system")
	
	if use_lab_system:
		await _setup_decoupled_lab_system()
	else:
		await _setup_basic_vr_scene()

func _setup_decoupled_lab_system():
	print("VRStaging: Setting up decoupled lab-centric system")
	
	# Load the main VR scene with lab configuration
	var user_data = {
		"map_name": preferred_grid_map,
		"system_mode": "lab_hub",
		"staging_ref": self
	}
	
	# Check if the scene file exists
	if not ResourceLoader.exists(main_scene):
		print("VRStaging: ERROR - Main scene file does not exist: %s" % main_scene)
		return
	
	# Load the specified main scene
	print("VRStaging: Loading main scene: %s" % main_scene)
	
	# Call load_scene and await it since it's a coroutine
	print("VRStaging: Calling load_scene...")
	await load_scene(main_scene, user_data)
	print("VRStaging: load_scene completed")
	
	# Check if loading was successful
	if scene_is_loaded:
		print("VRStaging: ✅ Scene loaded successfully!")
	else:
		print("VRStaging: ❌ Scene loading failed or incomplete")

func _setup_basic_vr_scene():
	print("VRStaging: Setting up basic VR scene")
	
	# Just load the main scene without special configuration
	print("VRStaging: Loading main scene: %s" % main_scene)
	await load_scene(main_scene)
	print("VRStaging: Basic VR scene load completed")

func _show_startup_info():
	print("=== VR Staging Startup Info (Decoupled) ===")
	print("Use lab system: %s" % use_lab_system)
	print("Start with grid system: %s" % start_with_grid_system)
	print("Preferred grid map: %s" % preferred_grid_map)
	print("Main scene: %s" % main_scene)
	print("==========================================")

# Event handlers for staging system
func _on_scene_loaded(scene, user_data):
	print("VRStaging: Scene loaded successfully - %s" % scene.name if scene else "null")
	
	# Pass user data to the scene if it has the method
	if scene and user_data and scene.has_method("set_scene_user_data"):
		scene.set_scene_user_data(user_data)
		print("VRStaging: Passed user data to scene: %s" % user_data)
	elif scene and user_data:
		# Fallback: set as metadata
		scene.set_meta("scene_user_data", user_data)
		print("VRStaging: Set user data as metadata: %s" % user_data)
	
	# Setup the decoupled system
	if scene and user_data:
		await _setup_decoupled_managers(scene, user_data)
	
	# Only show prompt to continue the first time
	prompt_for_continue = false
	scene_is_loaded = true

func _setup_decoupled_managers(scene: Node, user_data: Dictionary):
	print("VRStaging: Setting up scene...")
	
	# Find the grid system in the scene
	var grid_system = scene.find_child("multiLayerGrid", true, false)
	if not grid_system:
		# Try looking for the new consolidated GridSystem
		grid_system = scene.find_child("GridSystem", true, false)
	
	if not grid_system:
		print("VRStaging: No grid system found in scene")
		return
	
	print("VRStaging: Found grid system: %s" % grid_system.name)
	
	# Wait for the grid system to initialize
	print("VRStaging: Waiting for grid system to initialize...")
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.1).timeout
	
	# Configure the grid system to load the specified map
	var map_name = user_data.get("map_name", "Lab")
	print("VRStaging: Setting grid system map to: %s" % map_name)
	
	if grid_system.has_method("load_map"):
		grid_system.load_map(map_name)
	elif grid_system.has_method("set") and "map_name" in grid_system:
		grid_system.set("map_name", map_name)
		if grid_system.has_method("generate_layout"):
			grid_system.generate_layout()
	
	print("VRStaging: ✅ Scene setup complete")

func _on_scene_exiting(_scene, _user_data):
	print("VRStaging: Scene exiting")
	scene_is_loaded = false

func _on_xr_started():
	print("VRStaging: XR started - user put on headset")
	# User put on headset or returned from system menu
	if scene_is_loaded:
		# No longer need prompt
		prompt_for_continue = false
		print("VRStaging: Removing continue prompt")

func _on_xr_ended():
	print("VRStaging: XR ended - user removed headset")
	# User removed headset or went to system menu
	prompt_for_continue = true
	
	if scene_is_loaded:
		print("VRStaging: Could pause game here")

# Utility functions
func get_current_scene():
	return current_scene

func is_scene_loaded() -> bool:
	return scene_is_loaded

# Support for scene switching
func switch_to_scene(scene_path: String, user_data = null):
	print("VRStaging: Switching to scene: %s" % scene_path)
	load_scene(scene_path, user_data)

# Debug methods
func debug_force_tutorial():
	"""Force start the tutorial for debugging"""
	if lab_hub_manager:
		lab_hub_manager.force_trigger_cube()

func debug_force_sequence(sequence_id: String):
	"""Force start a specific sequence for debugging"""
	if transition_manager:
		transition_manager.go_to_sequence(sequence_id)

func debug_return_to_lab():
	"""Force return to lab for debugging"""
	if transition_manager:
		transition_manager.force_return_to_lab() 

func _initialize_managers():
	print("VRStaging: Initializing managers...")
	
	# Get map progression manager
	map_progression_manager = get_node_or_null("/root/MapProgressionManager")
	if not map_progression_manager:
		print("VRStaging: WARNING - MapProgressionManager not found")
	
	# Create grid system manager
	grid_system_manager = VRGridSystemManager.new()
	grid_system_manager.name = "VRGridSystemManager"
	add_child(grid_system_manager)
	
	print("VRStaging: Managers initialized") 
