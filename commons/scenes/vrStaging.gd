@tool
class_name AdaVRStaging
extends XRToolsStaging

## VR Staging System for Ada Research
##
## This staging system manages scene loading and VR initialization for the consolidated architecture

# Lab System Configuration (new variables specific to our implementation)
@export var use_lab_system: bool = true
@export var start_with_grid_system: bool = true
@export var main_lab_scene: String = "res://commons/scenes/lab.tscn"
@export var preferred_grid_map: String = "Lab"

# Signal emitted when staging is complete
signal staging_complete

# Node references (specific to our lab system)
var map_progression_manager = null
var grid_system_manager = null

func _ready() -> void:
	# Call parent ready function
	super()
	
	print("AdaVRStaging: Starting initialization with consolidated architecture...")
	
	# FIX: Set up the loading screen curve to prevent errors
	_fix_loading_screen_curve()
	
	# CONNECT to XRToolsStaging signals properly
	_connect_staging_signals()
	
	# Show startup configuration
	if OS.is_debug_build():
		_show_startup_info()
	
	# Start the game system
	_start_game()

func _fix_loading_screen_curve():
	"""Fix the follow_speed curve to prevent the null error"""
	print("AdaVRStaging: Fixing loading screen follow_speed curve...")
	
	# Find the loading screen
	var loading_screen = find_child("LoadingScreen", true, false)
	if not loading_screen:
		print("AdaVRStaging: No LoadingScreen found to fix")
		return
	
	# Check if follow_speed curve exists
	if not loading_screen.follow_speed:
		print("AdaVRStaging: Creating missing follow_speed curve")
		
		# Create a new curve
		var curve = Curve.new()
		
		# Add points for smooth camera following (Godot 4 uses Vector2)
		curve.add_point(Vector2(0.0, 0.0))  # Start slow
		curve.add_point(Vector2(1.0, 2.0))  # End faster
		
		# Set the curve
		loading_screen.follow_speed = curve
		
		print("AdaVRStaging: ✅ follow_speed curve created successfully")
	else:
		print("AdaVRStaging: follow_speed curve already exists")

func _connect_staging_signals():
	"""Connect to XRToolsStaging signals properly"""
	print("AdaVRStaging: Connecting to XRToolsStaging signals...")
	
	# Connect to scene loaded signal
	if has_signal("scene_loaded") and not scene_loaded.is_connected(_on_scene_loaded_handler):
		scene_loaded.connect(_on_scene_loaded_handler)
		print("AdaVRStaging: Connected to scene_loaded signal")
	
	# Connect to scene visible signal  
	if has_signal("scene_visible") and not scene_visible.is_connected(_on_scene_visible_handler):
		scene_visible.connect(_on_scene_visible_handler)
		print("AdaVRStaging: Connected to scene_visible signal")
	
	# Connect to scene exiting signal
	if has_signal("scene_exiting") and not scene_exiting.is_connected(_on_scene_exiting_handler):
		scene_exiting.connect(_on_scene_exiting_handler)
		print("AdaVRStaging: Connected to scene_exiting signal")

func _start_game():
	print("AdaVRStaging: Starting game with consolidated system")
	
	if use_lab_system:
		await _setup_lab_system()
	else:
		await _setup_basic_vr_scene()

func _setup_lab_system():
	"""Setup lab system - loads lab.tscn directly"""
	print("AdaVRStaging: Loading lab.tscn for hub experience")
	
	var user_data = {
		"system_mode": "lab_hub",
		"staging_ref": self
	}
	
	# Load lab.tscn (which contains LabManager and rotating cube)
	await load_scene(main_lab_scene, user_data)
	print("AdaVRStaging: Lab hub loaded")

func _setup_basic_vr_scene():
	print("AdaVRStaging: Setting up basic VR scene")
	
	# Just load the main scene without special configuration
	print("AdaVRStaging: Loading main scene: %s" % main_scene)
	await load_scene(main_scene)
	print("AdaVRStaging: Basic VR scene load completed")

func _show_startup_info():
	print("=== AdaVRStaging Startup Info ===")
	print("Use lab system: %s" % use_lab_system)
	print("Start with grid system: %s" % start_with_grid_system)
	print("Preferred grid map: %s" % preferred_grid_map)
	print("Main scene: %s" % main_scene)
	print("===============================")

# FIXED: Event handlers for staging system (connected to signals)
func _on_scene_loaded_handler(scene, user_data):
	"""Connected to XRToolsStaging scene_loaded signal"""
	print("AdaVRStaging: Scene loaded successfully - %s" % scene.name if scene else "null")
	
	# Pass user data to the scene if it has the method
	if scene and user_data and scene.has_method("set_scene_user_data"):
		scene.set_scene_user_data(user_data)
		print("AdaVRStaging: Passed user data to scene: %s" % user_data)
	elif scene and user_data:
		# Fallback: set as metadata
		scene.set_meta("scene_user_data", user_data)
		print("AdaVRStaging: Set user data as metadata: %s" % user_data)
	
	# Setup the scene
	if scene and user_data:
		await _setup_scene_systems(scene, user_data)
	
	# Only show prompt to continue the first time
	prompt_for_continue = false

func _on_scene_visible_handler(scene, user_data):
	"""Connected to XRToolsStaging scene_visible signal"""
	print("AdaVRStaging: Scene visible - %s" % scene.name if scene else "null")

func _on_scene_exiting_handler(scene, user_data):
	"""Connected to XRToolsStaging scene_exiting signal"""
	print("AdaVRStaging: Scene exiting - %s" % scene.name if scene else "null")

func _setup_scene_systems(scene: Node, user_data: Dictionary):
	print("AdaVRStaging: Setting up scene systems...")
	
	# Find the grid system in the scene - prioritize new consolidated system
	var grid_system = scene.find_child("GridSystem", true, false)
	if not grid_system:
		# Fallback to legacy names
		grid_system = scene.find_child("multiLayerGrid", true, false)
	
	if not grid_system:
		print("AdaVRStaging: No grid system found in scene")
		return
	
	print("AdaVRStaging: Found grid system: %s" % grid_system.name)
	
	# Wait for the grid system to initialize
	print("AdaVRStaging: Waiting for grid system to initialize...")
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.1).timeout
	
	# Configure the grid system to load the specified map
	var map_name = user_data.get("map_name", "Lab")
	print("AdaVRStaging: Setting grid system map to: %s" % map_name)
	
	if grid_system.has_method("load_map"):
		grid_system.load_map(map_name)
	elif grid_system.has_method("set") and "map_name" in grid_system:
		grid_system.set("map_name", map_name)
		if grid_system.has_method("generate_layout"):
			grid_system.generate_layout()
	
	print("AdaVRStaging: ✅ Scene setup complete")

# Utility functions
func get_scene_loaded() -> bool:
	return current_scene != null

# Support for scene switching
func switch_to_scene(scene_path: String, user_data = null):
	print("AdaVRStaging: Switching to scene: %s" % scene_path)
	load_scene(scene_path, user_data)

# Manager initialization
func _initialize_managers():
	print("AdaVRStaging: Initializing managers...")
	
	# Get map progression manager
	map_progression_manager = get_node_or_null("/root/MapProgressionManager")
	if not map_progression_manager:
		print("AdaVRStaging: WARNING - MapProgressionManager not found")
	
	# Create grid system manager
	if not grid_system_manager:
		grid_system_manager = VRGridSystemManager.new()
		grid_system_manager.name = "VRGridSystemManager"
		add_child(grid_system_manager)
		print("AdaVRStaging: Grid system manager created")
	
	print("AdaVRStaging: Managers initialized")

# OPTIONAL: Simple loading text enhancement
func _update_loading_screen_text(level_name: String, description: String = ""):
	"""Simple function to update loading screen text"""
	var loading_screen = find_child("LoadingScreen", true, false)
	if not loading_screen:
		return
	
	# Try to find a label in the loading screen
	var label = loading_screen.find_child("Label3D", true, false)
	if not label:
		# Create a simple label if none exists
		label = Label3D.new()
		label.name = "LevelInfoLabel"
		label.position = Vector3(0, -2, 0)  # Below the splash screen
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		loading_screen.add_child(label)
	
	# Update the text
	var text = "Loading: %s" % level_name
	if not description.is_empty():
		text += "\n%s" % description
	text += "\n\nHold Trigger to Continue"
	
	label.text = text
	print("AdaVRStaging: Updated loading screen text for: %s" % level_name)

# Simple API to update loading text from external systems
func set_loading_level_info(level_name: String, description: String = ""):
	"""Public API to set loading screen level information"""
	_update_loading_screen_text(level_name, description)
