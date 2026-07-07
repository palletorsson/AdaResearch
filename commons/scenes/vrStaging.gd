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
@export var spawn_map_loader_button_actions: PackedStringArray = PackedStringArray()  # disabled 2026-06-03 — no controller button spawns the VR map-loader kiosk (was ["primary_click"]; B is reserved for catalyst map-save). Re-add to restore.
@export var spawn_map_loader_keyboard_key: Key = KEY_B
@export var map_loader_spawn_distance: float = 1.8
@export var map_loader_spawn_height: float = 1.6

# Transition speed configuration
@export var quick_transition_duration: float = 0.3  # Fast fades for in-sequence transitions
@export var normal_transition_duration: float = 1.0  # Standard VR-comfortable fades
@export var force_fast_transition_fade: bool = true
@export var force_loading_screen_for_all_transitions: bool = true
@export var wait_for_map_generation_before_reveal: bool = true
var _use_quick_transition: bool = false  # Set by AdaSceneManager for in-sequence transitions

const VR_MAP_LOADER_KIOSK_SCENE_PATH := "res://algorithms/wavefunctions/mariocontrol/kiosk.tscn"
const SPAWNED_MAP_LOADER_GROUP := "desktop_spawned_map_loader_kiosk"
const MAP_LOADER_SPAWN_COOLDOWN_MS := 250
const MAP_READY_TIMEOUT_SEC := 20.0

# Signal emitted when staging is complete
signal staging_complete

# Node references (specific to our lab system)
var map_progression_manager = null
var grid_system_manager = null
var _spawn_map_loader_action_down: bool = false
var _spawn_map_loader_key_down: bool = false
var _last_map_loader_spawn_ms: int = -100000

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
	_connect_map_loader_spawn_button_signals()
	
	# Show startup configuration
	if OS.is_debug_build():
		_show_startup_info()
	
	# Start the game system
	_start_game()

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_handle_map_loader_spawn_shortcut()
	_poll_quest_reload(delta)

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
	# Disable pointers on staging rig to avoid conflict with game rig
	var left_pointer = find_child("FunctionPointerLeft", true, false)
	var right_pointer = find_child("FunctionPointerRight", true, false)
	if left_pointer: left_pointer.visible = false
	if right_pointer: right_pointer.visible = false

	print("AdaVRStaging: Menu start requested")

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

# Standalone dev loop: tools/push_map_to_quest.ps1 adb-pushes a map to the headset and writes its
# name to override_map/_start.txt in the app's files dir. If present, boot straight into that map
# (the map DATA itself is picked up by GridDataComponent's override). Android only; empty on desktop.
func _pushed_start_map() -> String:
	if not OS.has_feature("android"):
		return ""
	var rel := "override_map/_start.txt"
	var candidates := ["user://" + rel]
	var udir := OS.get_user_data_dir().replace("\\", "/")   # /data/user/0/<pkg>/files
	var segs := udir.split("/", false)
	var fi := segs.find("files")
	if fi > 0:
		candidates.append("/storage/emulated/0/Android/data/%s/files/%s" % [segs[fi - 1], rel])
	for c in candidates:
		if FileAccess.file_exists(c):
			return FileAccess.get_file_as_string(c).strip_edges()
	return ""


# Hot-reload hook: push_map_to_quest.ps1 -Live writes user://reload_signal.txt ("<map>\n<token>")
# into the app's files/ via run-as WHILE the game is running. Poll it ~2x/sec; on a new token,
# reload that map from disk in place (no relaunch) via the grid's reload_map_setter.
var _current_grid_system: Node = null
var _reload_poll_accum: float = 0.0
var _last_reload_token: String = ""

func _poll_quest_reload(delta: float) -> void:
	_reload_poll_accum += delta
	if _reload_poll_accum < 0.5:
		return
	_reload_poll_accum = 0.0
	var path := "user://reload_signal.txt"
	if not FileAccess.file_exists(path):
		return
	var content := FileAccess.get_file_as_string(path)
	if content == _last_reload_token or content.strip_edges() == "":
		return
	_last_reload_token = content
	var want_map := content.split("\n")[0].strip_edges()
	if want_map != "":
		_live_reload(want_map)

func _live_reload(want_map: String) -> void:
	if _current_grid_system == null or not is_instance_valid(_current_grid_system):
		return
	# Don't stack reloads: if a (re)generation is still running, retry next poll instead of piling
	# a second build on top of an unfinished one.
	if "generation_in_progress" in _current_grid_system and bool(_current_grid_system.get("generation_in_progress")):
		_last_reload_token = ""   # re-detect the same signal next tick
		return
	# Drop the spawned biome/ground nodes the in-place reload leaves behind — _clear_all_components
	# doesn't touch them (they sit on the GridSystem, outside the cleared components), so without
	# this each reload stacks another copy. Free immediately so the rebuild starts from a clean grid.
	for n in ["BiomeAccrual", "GroundLayer"]:
		var leftover = _current_grid_system.get_node_or_null(n)
		if leftover and is_instance_valid(leftover):
			leftover.free()
	if "map_name" in _current_grid_system and str(_current_grid_system.get("map_name")) != want_map:
		_current_grid_system.set("map_name", want_map)
	print("AdaVRStaging: hot-reload -> %s" % want_map)
	if _current_grid_system.has_method("reload_map_setter"):
		_current_grid_system.reload_map_setter(true)
	elif _current_grid_system.has_method("_reload_current_map"):
		_current_grid_system.call("_reload_current_map")

# FIXED: Event handlers for staging system (connected to signals)
func _on_scene_loaded_handler(scene, user_data):
	"""Connected to XRToolsStaging scene_loaded signal"""
	print("AdaVRStaging: Scene loaded successfully - %s" % scene.name if scene else "null")
	_connect_map_loader_spawn_button_signals()
	
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
	_current_grid_system = grid_system
	# Prime the hot-reload token so we only react to a NEW push, not a stale signal at launch.
	if FileAccess.file_exists("user://reload_signal.txt"):
		_last_reload_token = FileAccess.get_file_as_string("user://reload_signal.txt")
	
	# Minimal wait - just one frame for node initialization (delay already in load_scene)
	await get_tree().process_frame
	
	# Configure the grid system to load the specified map
	var map_name = user_data.get("map_name", "Lab")
	# Standalone dev loop: an adb-pushed map (push_map_to_quest.ps1) sets the start map.
	var _pushed := _pushed_start_map()
	if _pushed != "":
		map_name = _pushed
		print("AdaVRStaging: pushed start map → loading '%s'" % map_name)
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
	
	var fade_duration = quick_transition_duration if (force_fast_transition_fade or _use_quick_transition) else normal_transition_duration
	var tracking_delay = 0.02 if _use_quick_transition else 0.1  # Minimal delay for fast transitions
	
	if force_fast_transition_fade:
		print("AdaVRStaging: Fast transition fades enabled (%.1fs)" % fade_duration)
	elif _use_quick_transition:
		print("AdaVRStaging: Quick transition mode (%.1fs fades)" % fade_duration)
	
	# Do not load if in the editor
	if Engine.is_editor_hint():
		return
	if !xr_origin or !xr_camera:
		return
	
	# Start threaded loading - if cached, returns immediately
	ResourceLoader.load_threaded_request(p_scene_path)
	
	# If a current scene exists, notify it before transition
	if current_scene:
		# Call scene methods if they exist (XRToolsSceneBase compatibility)
		if current_scene.has_method("scene_pre_exiting"):
			current_scene.scene_pre_exiting(user_data)
		_safe_remove_signals(current_scene)

	# Always fade to black, including menu/startup transitions where current_scene is null
	if _tween:
		_tween.kill()
	_tween = get_tree().create_tween()
	_tween.tween_method(set_fade, 0.0, 1.0, fade_duration)
	await _tween.finished

	# Unload previous scene after fade-out
	if current_scene:
		emit_signal("scene_exiting", current_scene, user_data)
		if current_scene.has_method("scene_exiting"):
			current_scene.scene_exiting(user_data)
		$Scene.remove_child(current_scene)
		current_scene.queue_free()
		current_scene = null
	
	# Keep the menu hidden once a transition begins
	var menu: Node = find_child("MainMenu3D", true, false)
	if menu:
		menu.visible = false

	# Show loading for all transitions unless explicitly disabled
	var show_loading = force_loading_screen_for_all_transitions or \
		prompt_for_continue or \
		ResourceLoader.load_threaded_get_status(p_scene_path) != ResourceLoader.THREAD_LOAD_LOADED
	
	if show_loading:
		_update_loading_screen_for_transition(p_scene_path, user_data, "Streaming shell")
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
	var loading_screen_visible: bool = $LoadingScreen.visible
	if loading_screen_visible:
		var res: ResourceLoader.ThreadLoadStatus
		while true:
			var progress := []
			res = ResourceLoader.load_threaded_get_status(p_scene_path, progress)
			if res != ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				break
			$LoadingScreen.progress = progress[0]
			await get_tree().create_timer(0.05).timeout  # Faster polling

		if res == ResourceLoader.THREAD_LOAD_LOADED:
			$LoadingScreen.progress = 1.0
			_update_loading_screen_for_transition(p_scene_path, user_data, "Constructing destination")
		
		if res != ResourceLoader.THREAD_LOAD_LOADED:
			push_error("Error ", res, " loading resource ", p_scene_path)
			push_error("Failed to load scene resource: ", p_scene_path, " (status: ", res, "). Shutting down.")
			get_tree().quit(1)
		
		if prompt_for_continue and not _use_quick_transition:
			$LoadingScreen.enable_press_to_continue = true
			await $LoadingScreen.continue_pressed
		
	# Instantiate the new scene
	var new_scene: PackedScene = ResourceLoader.load_threaded_get(p_scene_path)
	current_scene = new_scene.instantiate()
	current_scene_path = p_scene_path
	$Scene.add_child(current_scene)
	_safe_add_signals(current_scene)
	
	# Small delay for VR tracking (shorter for quick transitions)
	await get_tree().create_timer(tracking_delay).timeout
	if is_instance_valid(current_scene) and current_scene.has_method("scene_loaded"):
		current_scene.scene_loaded(user_data)
	if is_instance_valid(current_scene):
		scene_loaded.emit(current_scene, user_data)

	if loading_screen_visible and wait_for_map_generation_before_reveal:
		await _await_scene_content_ready(current_scene, p_scene_path, user_data)

	if loading_screen_visible:
		_update_loading_screen_for_transition(p_scene_path, user_data, "Link established")
		if _tween:
			_tween.kill()
		_tween = get_tree().create_tween()
		_tween.tween_method(set_fade, 0.0, 1.0, fade_duration)
		await _tween.finished
		
		$LoadingScreen.follow_camera = false
		$LoadingScreen.visible = false
		xr_origin.set_process_internal(false)
	
	# Fade in (quick or normal)
	if _tween:
		_tween.kill()
	_tween = get_tree().create_tween()
	_tween.tween_method(set_fade, 1.0, 0.0, fade_duration)
	await _tween.finished
	
	# Report scene visible
	if is_instance_valid(current_scene) and current_scene.has_method("scene_visible"):
		current_scene.scene_visible(user_data)
	if is_instance_valid(current_scene):
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

func _handle_map_loader_spawn_shortcut() -> void:
	var action_down := _is_spawn_map_loader_action_down()
	if action_down and not _spawn_map_loader_action_down:
		_trigger_map_loader_spawn()
	_spawn_map_loader_action_down = action_down

	var key_down := Input.is_key_pressed(spawn_map_loader_keyboard_key) or Input.is_physical_key_pressed(spawn_map_loader_keyboard_key)
	if key_down and not _spawn_map_loader_key_down:
		_trigger_map_loader_spawn()
	_spawn_map_loader_key_down = key_down

func _is_spawn_map_loader_action_down() -> bool:
	for action_name in spawn_map_loader_button_actions:
		var action_key := StringName(action_name)
		if InputMap.has_action(action_key) and Input.is_action_pressed(action_key):
			return true

	return false

func _connect_map_loader_spawn_button_signals() -> void:
	for controller in _get_staging_controllers():
		if not controller or not controller.has_signal("button_pressed"):
			continue

		var callback := _on_map_loader_controller_button_pressed.bind(String(controller.name))
		if not controller.is_connected("button_pressed", callback):
			controller.connect("button_pressed", callback)

func _on_map_loader_controller_button_pressed(button_action: StringName, controller_name: String) -> void:
	if not _matches_map_loader_spawn_action(button_action):
		return

	print("AdaVRStaging: Spawn map loader with %s on %s" % [button_action, controller_name])
	_trigger_map_loader_spawn()

func _matches_map_loader_spawn_action(action_name: StringName) -> bool:
	var action_text := String(action_name).strip_edges().to_lower()
	for configured_action in spawn_map_loader_button_actions:
		if action_text == String(configured_action).strip_edges().to_lower():
			return true
	return false

func _trigger_map_loader_spawn() -> void:
	var now_ms := Time.get_ticks_msec()
	if now_ms - _last_map_loader_spawn_ms < MAP_LOADER_SPAWN_COOLDOWN_MS:
		return

	_last_map_loader_spawn_ms = now_ms
	_spawn_or_move_map_loader_kiosk()

func _get_staging_controllers() -> Array[Node]:
	var controllers: Array[Node] = []
	var controller_paths: Array[NodePath] = [
		NodePath("XROrigin3D/RightHandController"),
		NodePath("XROrigin3D/LeftHandController")
	]

	for controller_path in controller_paths:
		var controller = get_node_or_null(controller_path)
		if controller and controller is Node:
			controllers.append(controller as Node)

	for controller_candidate in find_children("*", "XRController3D", true, false):
		if controller_candidate is Node and not controllers.has(controller_candidate):
			controllers.append(controller_candidate as Node)

	for node_candidate in find_children("*", "", true, false):
		if not (node_candidate is Node):
			continue
		var node := node_candidate as Node
		if not node.has_method("is_button_pressed") or not node.has_signal("button_pressed"):
			continue
		if not controllers.has(node):
			controllers.append(node)

	return controllers

func _spawn_or_move_map_loader_kiosk() -> void:
	var target_root: Node = current_scene
	if target_root == null:
		target_root = get_node_or_null("Scene")
	if target_root == null:
		target_root = self

	var existing_kiosk := _find_spawned_map_loader_kiosk(target_root)
	var spawn_transform := _build_map_loader_spawn_transform()
	if existing_kiosk:
		existing_kiosk.global_transform = spawn_transform
		print("AdaVRStaging: Moved map loader kiosk in front of player")
		return

	var kiosk_scene = load(VR_MAP_LOADER_KIOSK_SCENE_PATH)
	if not (kiosk_scene is PackedScene):
		push_warning("AdaVRStaging: Map loader kiosk scene missing: %s" % VR_MAP_LOADER_KIOSK_SCENE_PATH)
		return

	var kiosk_instance = (kiosk_scene as PackedScene).instantiate()
	if not (kiosk_instance is Node3D):
		if kiosk_instance and kiosk_instance is Node:
			(kiosk_instance as Node).queue_free()
		push_warning("AdaVRStaging: Map loader kiosk root must be Node3D")
		return

	target_root.add_child(kiosk_instance)
	var kiosk_node := kiosk_instance as Node3D
	kiosk_node.global_transform = spawn_transform
	kiosk_node.add_to_group(SPAWNED_MAP_LOADER_GROUP)
	print("AdaVRStaging: Spawned map loader kiosk")

func _find_spawned_map_loader_kiosk(target_root: Node) -> Node3D:
	var scene_tree := get_tree()
	if not scene_tree:
		return null

	for node_candidate in scene_tree.get_nodes_in_group(SPAWNED_MAP_LOADER_GROUP):
		if not (node_candidate is Node3D):
			continue
		var node3d := node_candidate as Node3D
		if node3d == target_root or target_root.is_ancestor_of(node3d):
			return node3d

	return null

func _build_map_loader_spawn_transform() -> Transform3D:
	var source_camera: Camera3D = xr_camera
	if source_camera == null:
		source_camera = get_viewport().get_camera_3d()

	var source_position := Vector3.ZERO
	var source_forward := Vector3.FORWARD
	if source_camera:
		source_position = source_camera.global_position
		source_forward = -source_camera.global_transform.basis.z
	elif xr_origin:
		source_position = xr_origin.global_position
		source_forward = -xr_origin.global_transform.basis.z

	var forward_flat := Vector3(source_forward.x, 0.0, source_forward.z)
	if forward_flat.length_squared() <= 0.0001:
		forward_flat = Vector3(0.0, 0.0, -1.0)
	forward_flat = forward_flat.normalized()

	var spawn_position := source_position + forward_flat * map_loader_spawn_distance
	spawn_position.y = _resolve_map_loader_spawn_height(source_position.y)

	return Transform3D(Basis.IDENTITY, spawn_position)

func _resolve_map_loader_spawn_height(_fallback_source_y: float) -> float:
	return map_loader_spawn_height

func _find_player_body_node3d() -> Node3D:
	var scene_tree := get_tree()
	if not scene_tree:
		return null

	for node_candidate in scene_tree.get_nodes_in_group("player_body"):
		if node_candidate is Node3D:
			return node_candidate as Node3D

	if xr_origin:
		var player_body = xr_origin.find_child("PlayerBody", true, false)
		if player_body is Node3D:
			return player_body as Node3D

	return null

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
	if prompt_for_continue:
		text += "\n\nHold Trigger to Continue"
	
	label.text = text
	print("AdaVRStaging: Updated loading screen text for: %s" % level_name)

# Simple API to update loading text from external systems
func set_loading_level_info(level_name: String, description: String = ""):
	"""Public API to set loading screen level information"""
	_update_loading_screen_text(level_name, description)

func _await_scene_content_ready(scene: Node, scene_path: String, _user_data = null) -> void:
	var readiness_node := _find_scene_readiness_node(scene)
	if not readiness_node:
		return

	var started_wait_ms := Time.get_ticks_msec()
	var loading_screen = find_child("LoadingScreen", true, false)
	while is_instance_valid(readiness_node) and readiness_node.has_method("is_map_ready") and not readiness_node.is_map_ready():
		var elapsed_sec := float(Time.get_ticks_msec() - started_wait_ms) / 1000.0
		if elapsed_sec >= MAP_READY_TIMEOUT_SEC:
			push_warning("AdaVRStaging: Timed out waiting for map readiness for %s" % scene_path)
			break
		if loading_screen and loading_screen.visible:
			loading_screen.progress = 0.94 + (0.04 * abs(sin(elapsed_sec * 3.5)))
		await get_tree().process_frame

	if loading_screen and loading_screen.visible:
		loading_screen.progress = 1.0

func _find_scene_readiness_node(scene: Node) -> Node:
	if not scene:
		return null

	var direct_grid := scene.find_child("GridSystem", true, false)
	if direct_grid and direct_grid.has_method("is_map_ready"):
		return direct_grid

	var lab_grid := scene.find_child("LabGridSystem", true, false)
	if lab_grid and lab_grid.has_method("is_map_ready"):
		return lab_grid

	for child in scene.find_children("*", "", true, false):
		if child and child.has_method("is_map_ready"):
			return child

	return null

func _update_loading_screen_for_transition(scene_path: String, user_data, stage_name: String) -> void:
	var target_name := _get_loading_target_name(scene_path, user_data)
	var process_lines := _build_loading_process_lines(scene_path, user_data)
	var description := "%s\n\n%s" % [stage_name, "\n".join(process_lines)]
	_update_loading_screen_text(target_name, description)

func _coerce_transition_scene_data(user_data) -> Dictionary:
	if user_data is Dictionary:
		return user_data
	return {}

func _get_loading_target_name(scene_path: String, user_data) -> String:
	var scene_data: Dictionary = _coerce_transition_scene_data(user_data)
	var target_name := str(scene_data.get("map_name", scene_data.get("lab_map_override", scene_data.get("destination", ""))))

	if target_name.is_empty() and scene_data.has("sequence_data"):
		var sequence_data: Dictionary = scene_data.get("sequence_data", {})
		var sequence_name := str(sequence_data.get("sequence_name", "")).strip_edges()
		if not sequence_name.is_empty():
			target_name = "Sequence: %s" % sequence_name.replace("_", " ")

	if target_name.is_empty() and scene_path == main_lab_scene:
		var completed_sequence := str(scene_data.get("completed_sequence", "")).strip_edges()
		if not completed_sequence.is_empty():
			target_name = "Lab after %s" % completed_sequence.replace("_", " ")
		else:
			target_name = "Lab hub"

	if target_name.is_empty():
		target_name = scene_path.get_file().get_basename().replace("_", " ")

	return target_name.replace("Lab/", "Lab: ")

func _build_loading_process_lines(scene_path: String, user_data) -> Array[String]:
	var scene_data: Dictionary = _coerce_transition_scene_data(user_data)
	var process_lines: Array[String] = []
	var map_name := str(scene_data.get("map_name", scene_data.get("lab_map_override", ""))).strip_edges()

	if scene_path == main_lab_scene or map_name.begins_with("Lab/"):
		process_lines.append("- restoring lab state")
		process_lines.append("- assembling geometry lattice")
		process_lines.append("- waking unlocked artifacts")
		process_lines.append("- stabilizing ambient light")
	else:
		process_lines.append("- reading map_data.json")
		process_lines.append("- assembling structure grid")
		process_lines.append("- placing utilities and spawn points")
		process_lines.append("- instantiating artifacts")
		process_lines.append("- warming ambient audio")

	if scene_data.has("sequence_data"):
		var sequence_data: Dictionary = scene_data.get("sequence_data", {})
		var current_step := int(sequence_data.get("current_step", 0)) + 1
		var sequence_maps: Array = sequence_data.get("maps", [])
		var total_steps: int = sequence_maps.size()
		if total_steps > 0:
			process_lines.append("- sequence step %d of %d" % [current_step, total_steps])

	return process_lines
