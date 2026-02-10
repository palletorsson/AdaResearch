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
@export var skip_menu: bool = false  # Skip menu and load directly into lab

# Transition speed configuration
@export var quick_transition_duration: float = 0.3  # Fast fades for in-sequence transitions
@export var normal_transition_duration: float = 1.0  # Standard VR-comfortable fades
var _use_quick_transition: bool = false  # Set by AdaSceneManager for in-sequence transitions

# Signal emitted when staging is complete
signal staging_complete

# Node references (specific to our lab system)
var map_progression_manager = null
var grid_system_manager = null

func _ready() -> void:
	# Do not initialise if in the editor
	if Engine.is_editor_hint():
		return

	# Specify the camera to track (logic from XRToolsStaging)
	if xr_camera:
		xr_camera.current = true # Ensure camera is active
		
		# FIX: Clear default staging environment so WorldEnvironment can take over
		xr_camera.environment = null
		
		var loading_screen = find_child("LoadingScreen", true, false)
		if loading_screen:
			loading_screen.set_camera(xr_camera)
			# Ensure loading screen is hidden so we can see the menu
			loading_screen.visible = false
	
	# Disable prompt for continue to avoid blocking input
	prompt_for_continue = false
	
	print("AdaVRStaging: Starting initialization with consolidated architecture...")
	
	# DEBUG: Check for duplicate WorldEnvironments
	var envs = find_children("*", "WorldEnvironment", true, false)
	if envs.size() > 1:
		print("AdaVRStaging: WARNING - Found %d WorldEnvironment nodes (Parent might contain one)" % envs.size())
	
	# Ensure pointers are visible
	var left_pointer = find_child("FunctionPointerLeft", true, false)
	var right_pointer = find_child("FunctionPointerRight", true, false)
	if left_pointer: left_pointer.visible = true
	if right_pointer: right_pointer.visible = true
	
	# Ensure menu is visible
	var menu = find_child("MainMenu3D", true, false)
	if menu:
		menu.visible = true
		print("AdaVRStaging: MainMenu3D set to visible")
	
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
		
		print("AdaVRStaging: âœ… follow_speed curve created successfully")
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
	# Check for MainMenu3D
	var menu = find_child("MainMenu3D", true, false)

	# Skip menu if configured - go directly to lab with loading screen
	if skip_menu:
		print("AdaVRStaging: Skipping menu, loading directly into lab...")
		if menu:
			menu.visible = false
		# Hide pointers during load
		var left_pointer = find_child("FunctionPointerLeft", true, false)
		var right_pointer = find_child("FunctionPointerRight", true, false)
		if left_pointer: left_pointer.visible = false
		if right_pointer: right_pointer.visible = false

		# Show loading screen and load lab
		await _load_lab_with_loading_screen()
		return

	if menu:
		print("AdaVRStaging: Menu found, waiting for user input")
		if not menu.start_game_requested.is_connected(_on_menu_start_game):
			menu.start_game_requested.connect(_on_menu_start_game)
		if not menu.quit_requested.is_connected(_on_menu_quit):
			menu.quit_requested.connect(_on_menu_quit)

		# Preload the lab scene in background while showing menu
		_preload_lab_scene()
		return

	print("AdaVRStaging: Starting game with consolidated system")

	if use_lab_system:
		await _setup_lab_system()
	else:
		await _setup_basic_vr_scene()

var _preload_started: bool = false

func _load_lab_with_loading_screen():
	"""Load lab scene directly with loading screen visible"""
	var loading_screen = $LoadingScreen
	if loading_screen:
		# Show loading screen immediately
		loading_screen.progress = 0.0
		loading_screen.enable_press_to_continue = false
		loading_screen.follow_camera = true
		loading_screen.visible = true

	# Start threaded loading
	ResourceLoader.load_threaded_request(main_lab_scene)

	# Update progress bar while loading
	if loading_screen:
		while true:
			var progress := []
			var status = ResourceLoader.load_threaded_get_status(main_lab_scene, progress)

			if status == ResourceLoader.THREAD_LOAD_LOADED:
				loading_screen.progress = 1.0
				print("AdaVRStaging: Lab scene loaded!")
				break
			elif status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				loading_screen.progress = progress[0]
				await get_tree().create_timer(0.05).timeout
			elif status == ResourceLoader.THREAD_LOAD_FAILED:
				print("AdaVRStaging: ERROR - Lab scene failed to load!")
				break
			else:
				await get_tree().create_timer(0.05).timeout

		# Brief pause at 100%
		await get_tree().create_timer(0.3).timeout
		loading_screen.visible = false

	# Now setup the lab system (scene is cached, will be instant)
	prompt_for_continue = false
	if use_lab_system:
		await _setup_lab_system()
	else:
		await _setup_basic_vr_scene()

func _preload_lab_scene():
	"""Start preloading the lab scene in the background while menu is visible"""
	if _preload_started:
		return

	_preload_started = true
	print("AdaVRStaging: Starting background preload of lab scene...")

	# Start threaded loading - this runs in background
	ResourceLoader.load_threaded_request(main_lab_scene)

	# Optionally monitor preload progress (for debugging)
	if OS.is_debug_build():
		_monitor_preload()

func _monitor_preload():
	"""Monitor preload progress in debug builds"""
	while true:
		var progress := []
		var status = ResourceLoader.load_threaded_get_status(main_lab_scene, progress)

		if status == ResourceLoader.THREAD_LOAD_LOADED:
			print("AdaVRStaging: Lab scene preloaded successfully!")
			break
		elif status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			print("AdaVRStaging: Preload progress: %.0f%%" % (progress[0] * 100))
			await get_tree().create_timer(0.5).timeout
		elif status == ResourceLoader.THREAD_LOAD_FAILED:
			print("AdaVRStaging: ERROR - Lab scene preload failed!")
			break
		else:
			# THREAD_LOAD_INVALID_RESOURCE
			await get_tree().create_timer(0.1).timeout

func _show_loading_progress():
	"""Show loading screen with progress bar while scene loads"""
	var loading_screen = $LoadingScreen
	if not loading_screen:
		return

	# Show loading screen
	loading_screen.progress = 0.0
	loading_screen.enable_press_to_continue = false
	loading_screen.follow_camera = true
	loading_screen.visible = true

	# Update progress until loaded
	while true:
		var progress := []
		var status = ResourceLoader.load_threaded_get_status(main_lab_scene, progress)

		if status == ResourceLoader.THREAD_LOAD_LOADED:
			loading_screen.progress = 1.0
			break
		elif status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			loading_screen.progress = progress[0]
			await get_tree().create_timer(0.1).timeout
		else:
			# Failed or invalid
			break

	# Brief pause at 100% for visual feedback
	await get_tree().create_timer(0.2).timeout

	# Hide loading screen (load_scene will handle actual scene transition)
	loading_screen.visible = false

func _on_menu_start_game():
	var menu = find_child("MainMenu3D", true, false)
	if menu:
		menu.visible = false
		# Disable pointers on staging rig to avoid conflict with game rig
		var left_pointer = find_child("FunctionPointerLeft", true, false)
		var right_pointer = find_child("FunctionPointerRight", true, false)
		if left_pointer: left_pointer.visible = false
		if right_pointer: right_pointer.visible = false

	print("AdaVRStaging: Menu start requested")

	# Check if preload is still in progress - if so, show loading screen
	var status = ResourceLoader.load_threaded_get_status(main_lab_scene)
	if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		print("AdaVRStaging: Scene still loading, showing loading screen...")
		await _show_loading_progress()

	# Force prompt_for_continue to false just in case
	prompt_for_continue = false
	
	if use_lab_system:
		await _setup_lab_system()
	else:
		await _setup_basic_vr_scene()

func _on_menu_quit():
	print("AdaVRStaging: Menu quit requested")
	get_tree().quit()

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

func _on_scene_visible_handler(scene, _user_data):
	"""Connected to XRToolsStaging scene_visible signal"""
	print("AdaVRStaging: Scene visible - %s" % scene.name if scene else "null")

func _on_scene_exiting_handler(scene, _user_data):
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
	
	# Minimal wait - just one frame for node initialization (delay already in load_scene)
	await get_tree().process_frame
	
	# Configure the grid system to load the specified map
	var map_name = user_data.get("map_name", "Lab")
	print("AdaVRStaging: Setting grid system map to: %s" % map_name)
	
	if grid_system.has_method("load_map"):
		grid_system.load_map(map_name)
	elif grid_system.has_method("set") and "map_name" in grid_system:
		grid_system.set("map_name", map_name)
		if grid_system.has_method("generate_layout"):
			grid_system.generate_layout()
	
	print("AdaVRStaging: âœ… Scene setup complete")

# Utility functions
func get_scene_loaded() -> bool:
	return current_scene != null

# Support for scene switching
func switch_to_scene(scene_path: String, user_data = null):
	print("AdaVRStaging: Switching to scene: %s" % scene_path)
	load_scene(scene_path, user_data)

## Override load_scene to support quick transitions for in-sequence map changes
func load_scene(p_scene_path: String, user_data = null) -> void:
	# Check if this is an in-sequence transition (same scene type, just different map)
	var is_in_sequence = user_data is Dictionary and user_data.has("sequence_data")
	_use_quick_transition = is_in_sequence
	
	var fade_duration = quick_transition_duration if _use_quick_transition else normal_transition_duration
	var tracking_delay = 0.02 if _use_quick_transition else 0.1  # Minimal delay for fast transitions
	
	if _use_quick_transition:
		print("AdaVRStaging: âš¡ Quick transition mode (%.1fs fades)" % fade_duration)
	
	# Do not load if in the editor
	if Engine.is_editor_hint():
		return
	if !xr_origin or !xr_camera:
		return
	
	# Start threaded loading - if cached, returns immediately
	ResourceLoader.load_threaded_request(p_scene_path)
	
	# If a current scene exists, fade it out
	if current_scene:
		# Call scene methods if they exist (XRToolsSceneBase compatibility)
		if current_scene.has_method("scene_pre_exiting"):
			current_scene.scene_pre_exiting(user_data)
		_safe_remove_signals(current_scene)
		
		# Fade to black (quick or normal)
		if _tween:
			_tween.kill()
		_tween = get_tree().create_tween()
		_tween.tween_method(set_fade, 0.0, 1.0, fade_duration)
		await _tween.finished
		
		emit_signal("scene_exiting", current_scene, user_data)
		if current_scene.has_method("scene_exiting"):
			current_scene.scene_exiting(user_data)
		$Scene.remove_child(current_scene)
		current_scene.queue_free()
		current_scene = null
	
	# Only show loading screen if needed (not for quick transitions with cached scenes)
	var show_loading = prompt_for_continue or \
		ResourceLoader.load_threaded_get_status(p_scene_path) != ResourceLoader.THREAD_LOAD_LOADED
	
	# Skip loading screen entirely for quick transitions if scene is cached
	if _use_quick_transition and ResourceLoader.load_threaded_get_status(p_scene_path) == ResourceLoader.THREAD_LOAD_LOADED:
		show_loading = false
	
	if show_loading:
		xr_origin.set_process_internal(true)
		xr_origin.current = true
		xr_camera.current = true
		$LoadingScreen.progress = 0.0
		$LoadingScreen.enable_press_to_continue = false
		$LoadingScreen.follow_camera = true
		$LoadingScreen.visible = true
		switching_to_loading_scene.emit(user_data)
		
		if _tween:
			_tween.kill()
		_tween = get_tree().create_tween()
		_tween.tween_method(set_fade, 1.0, 0.0, fade_duration)
		await _tween.finished
	
	# Wait for scene to load if not ready
	if $LoadingScreen.visible:
		var res: ResourceLoader.ThreadLoadStatus
		while true:
			var progress := []
			res = ResourceLoader.load_threaded_get_status(p_scene_path, progress)
			if res != ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				break
			$LoadingScreen.progress = progress[0]
			await get_tree().create_timer(0.05).timeout  # Faster polling
		
		if res != ResourceLoader.THREAD_LOAD_LOADED:
			push_error("Error ", res, " loading resource ", p_scene_path)
			breakpoint
			get_tree().quit(1)
		
		if prompt_for_continue and not _use_quick_transition:
			$LoadingScreen.enable_press_to_continue = true
			await $LoadingScreen.continue_pressed
		
		if _tween:
			_tween.kill()
		_tween = get_tree().create_tween()
		_tween.tween_method(set_fade, 0.0, 1.0, fade_duration)
		await _tween.finished
		
		$LoadingScreen.follow_camera = false
		$LoadingScreen.visible = false
		xr_origin.set_process_internal(false)
	
	# Instantiate the new scene
	var new_scene: PackedScene = ResourceLoader.load_threaded_get(p_scene_path)
	current_scene = new_scene.instantiate()
	current_scene_path = p_scene_path
	$Scene.add_child(current_scene)
	_safe_add_signals(current_scene)
	
	# Small delay for VR tracking (shorter for quick transitions)
	await get_tree().create_timer(tracking_delay).timeout
	if current_scene.has_method("scene_loaded"):
		current_scene.scene_loaded(user_data)
	scene_loaded.emit(current_scene, user_data)
	
	# Fade in (quick or normal)
	if _tween:
		_tween.kill()
	_tween = get_tree().create_tween()
	_tween.tween_method(set_fade, 1.0, 0.0, fade_duration)
	await _tween.finished
	
	# Report scene visible
	if current_scene.has_method("scene_visible"):
		current_scene.scene_visible(user_data)
	scene_visible.emit(current_scene, user_data)
	
	# Reset quick transition flag
	_use_quick_transition = false

# Safe signal helpers for scenes that may not extend XRToolsSceneBase
func _safe_add_signals(p_scene: Node):
	"""Add scene signals if they exist"""
	if p_scene.has_signal("request_exit_to_main_menu"):
		if not p_scene.request_exit_to_main_menu.is_connected(_on_exit_to_main_menu):
			p_scene.request_exit_to_main_menu.connect(_on_exit_to_main_menu)
	if p_scene.has_signal("request_load_scene"):
		if not p_scene.request_load_scene.is_connected(_on_load_scene):
			p_scene.request_load_scene.connect(_on_load_scene)
	if p_scene.has_signal("request_reset_scene"):
		if not p_scene.request_reset_scene.is_connected(_on_reset_scene):
			p_scene.request_reset_scene.connect(_on_reset_scene)
	if p_scene.has_signal("request_quit"):
		if not p_scene.request_quit.is_connected(_on_quit):
			p_scene.request_quit.connect(_on_quit)

func _safe_remove_signals(p_scene: Node):
	"""Remove scene signals if connected"""
	if p_scene.has_signal("request_exit_to_main_menu"):
		if p_scene.request_exit_to_main_menu.is_connected(_on_exit_to_main_menu):
			p_scene.request_exit_to_main_menu.disconnect(_on_exit_to_main_menu)
	if p_scene.has_signal("request_load_scene"):
		if p_scene.request_load_scene.is_connected(_on_load_scene):
			p_scene.request_load_scene.disconnect(_on_load_scene)
	if p_scene.has_signal("request_reset_scene"):
		if p_scene.request_reset_scene.is_connected(_on_reset_scene):
			p_scene.request_reset_scene.disconnect(_on_reset_scene)
	if p_scene.has_signal("request_quit"):
		if p_scene.request_quit.is_connected(_on_quit):
			p_scene.request_quit.disconnect(_on_quit)

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
