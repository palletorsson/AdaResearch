@tool
class_name VRStaging
extends XRToolsStaging

## VR Staging System for Ada Research
##
## This staging system manages scene loading and VR initialization
## It provides proper startup sequencing and handles VR state transitions

var scene_is_loaded: bool = false

# Lab System Configuration
@export var use_lab_system: bool = true
@export var start_with_grid_system: bool = true
@export var preferred_grid_map: String = "Lab"

func _ready() -> void:
	# Call parent ready function
	super()
	
	print("VRStaging: Starting initialization...")
	
	# Show startup configuration
	if OS.is_debug_build():
		_show_startup_info()
	
	# Start the game system
	_start_game()

func _start_game():
	print("VRStaging: Starting game with lab system")
	
	if use_lab_system:
		await _setup_lab_system()
	else:
		await _setup_basic_vr_scene()

func _setup_lab_system():
	print("VRStaging: Setting up lab-centric system")
	
	# Load the main VR scene with lab configuration
	var user_data = {
		"map_name": preferred_grid_map,
		"system_mode": "lab",
		"staging_ref": self
	}
	
	# Check if the scene file exists
	if not ResourceLoader.exists(main_scene):
		print("VRStaging: ERROR - Main scene file does not exist: %s" % main_scene)
		return
	
	# Load the specified main scene
	print("VRStaging: Loading main scene: %s" % main_scene)
	print("VRStaging: Scene exists: %s" % ResourceLoader.exists(main_scene))
	
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
	print("=== VR Staging Startup Info ===")
	print("Use lab system: %s" % use_lab_system)
	print("Start with grid system: %s" % start_with_grid_system)
	print("Preferred grid map: %s" % preferred_grid_map)
	print("Main scene: %s" % main_scene)
	print("===============================")

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
	
	# Configure grid system directly if it exists
	if scene and user_data:
		await _configure_grid_system(scene, user_data)
	
	# Only show prompt to continue the first time
	prompt_for_continue = false
	scene_is_loaded = true

func _configure_grid_system(scene: Node, user_data: Dictionary):
	print("VRStaging: Looking for grid system to configure...")
	
	# Find the grid system in the scene
	var grid_system = scene.find_child("multiLayerGrid", true, false)
	if not grid_system:
		print("VRStaging: No grid system found in scene")
		return
	
	print("VRStaging: Found grid system: %s" % grid_system.name)
	print("VRStaging: Grid system class: %s" % grid_system.get_class())
	
	# Wait for the grid system to finish its _ready() function
	print("VRStaging: Waiting for grid system to initialize...")
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Get the map name from user data
	var map_name = user_data.get("map_name", "Lab")
	print("VRStaging: Setting grid system map to: %s" % map_name)
	
	# Check if the grid system is responding
	print("VRStaging: Checking if grid system is ready...")
	if not is_instance_valid(grid_system):
		print("VRStaging: ❌ Grid system is not valid")
		return
		
	print("VRStaging: ✅ Grid system is valid")
	
	# Check if algorithm registry is available and loaded
	print("VRStaging: Checking algorithm registry...")
	var algorithm_registry = grid_system.get("algorithm_registry")
	if algorithm_registry:
		var algorithm_count = algorithm_registry.get_all_algorithm_ids().size()
		print("VRStaging: Algorithm registry found with %d algorithms" % algorithm_count)
		
		if algorithm_count == 0:
			print("VRStaging: Waiting for algorithm registry to load...")
			# Wait for registry to load
			var max_wait_time = 5.0  # Maximum 5 seconds
			var wait_time = 0.0
			while algorithm_registry.get_all_algorithm_ids().size() == 0 and wait_time < max_wait_time:
				await get_tree().process_frame
				wait_time += get_process_delta_time()
			
			if algorithm_registry.get_all_algorithm_ids().size() > 0:
				print("VRStaging: ✅ Algorithm registry loaded with %d algorithms" % algorithm_registry.get_all_algorithm_ids().size())
			else:
				print("VRStaging: ⚠️ Algorithm registry still not loaded after timeout")
	else:
		print("VRStaging: ❌ No algorithm registry found in grid system")
	
	# Set the map name safely
	if grid_system.has_method("generate_layout"):
		print("VRStaging: Setting map_name directly without triggering setter...")
		# Set the map_name field directly without triggering the setter
		grid_system.set("map_name", map_name)
		print("VRStaging: ✅ Map name set to: %s" % grid_system.get("map_name"))
		
		print("VRStaging: Calling generate_layout() method...")
		grid_system.generate_layout()
		print("VRStaging: ✅ Grid layout generation completed")
	else:
		print("VRStaging: ❌ No generate_layout method available")
	
	print("VRStaging: Grid configuration completed")

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
