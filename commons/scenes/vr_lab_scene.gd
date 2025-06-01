# VRLabScene.gd
# Script for the base VR lab scene that manages grid system initialization
# Handles loading maps into the grid system and lab management

extends Node3D

# Components
@onready var grid_system = $multiLayerGrid
@onready var lab_manager = $LabManager
@onready var xr_origin = $XROrigin3D

# Configuration
var map_name: String = "Lab"
var user_data: Dictionary = {}
var initialization_complete: bool = false

func _ready():
	print("VRLabScene: Scene _ready() called - starting initialization...")
	
	# Add a safety timeout for initialization
	var timer = Timer.new()
	timer.wait_time = 2.0
	timer.timeout.connect(_on_initialization_timeout)
	timer.one_shot = true
	add_child(timer)
	timer.start()
	
	# Initialize components with error handling
	call_deferred("_safe_initialize")

func _safe_initialize():
	print("VRLabScene: Safe initialization starting...")
	
	# Initialize components step by step
	_initialize_lab_system()
	
	# Load initial map with delay to avoid race conditions
	call_deferred("_load_initial_map")
	
	print("VRLabScene: Safe initialization completed")
	initialization_complete = true

func _on_initialization_timeout():
	if not initialization_complete:
		print("VRLabScene: WARNING - Initialization timeout reached, forcing completion")
		initialization_complete = true

func _initialize_lab_system():
	print("VRLabScene: Initializing lab system...")
	
	if lab_manager:
		print("VRLabScene: Lab manager found: %s" % lab_manager.name)
	else:
		print("VRLabScene: Lab manager not found")
	
	if grid_system:
		print("VRLabScene: Grid system found: %s" % grid_system.name)
		print("VRLabScene: Grid system type: %s" % grid_system.get_class())
		
		# Try to connect signals with error handling
		_safe_connect_grid_signals()
	else:
		print("VRLabScene: WARNING - Grid system not found!")

func _safe_connect_grid_signals():
	if not grid_system:
		return
	
	# Check for common grid system signals
	if grid_system.has_signal("interactable_activated"):
		grid_system.interactable_activated.connect(_on_interactable_activated)
		print("VRLabScene: Connected to grid interactable_activated signal")
	else:
		print("VRLabScene: Grid system has no interactable_activated signal")

func _load_initial_map():
	print("VRLabScene: Loading initial map...")
	
	# Check if we received scene data from staging
	var scene_data = get_meta("scene_user_data", {})
	if not scene_data.is_empty():
		map_name = scene_data.get("map_name", "Lab")
		user_data = scene_data.get("user_data", {})
		print("VRLabScene: Using scene data - map: %s" % map_name)
	
	if not grid_system:
		print("VRLabScene: No grid system available - skipping map load")
		return
	
	print("VRLabScene: Grid system available, attempting map load...")
	
	# Try different approaches to load the map
	var load_attempted = false
	
	# Approach 1: Direct property setting
	if "map_name" in grid_system:
		print("VRLabScene: Setting grid_system.map_name = '%s'" % map_name)
		grid_system.map_name = map_name
		load_attempted = true
	else:
		print("VRLabScene: Grid system does not have map_name property")
	
	# Approach 2: Reload trigger
	if "reload_map" in grid_system and load_attempted:
		print("VRLabScene: Triggering reload_map")
		grid_system.reload_map = true
	else:
		print("VRLabScene: Grid system does not have reload_map property")
	
	# Approach 3: Method calls
	if grid_system.has_method("load_map_data"):
		print("VRLabScene: Calling load_map_data() method")
		grid_system.load_map_data()
	else:
		print("VRLabScene: Grid system has no load_map_data method")
	
	print("VRLabScene: Map loading attempts completed")

# Handle grid system interactable activation
func _on_interactable_activated(object_id, position, data):
	print("VRLabScene: Interactable activated - ID: %s, Position: %s" % [object_id, position])
	
	# Let lab manager handle the interaction if it exists
	if lab_manager and lab_manager.has_method("handle_interactable_activation"):
		lab_manager.handle_interactable_activation(object_id, position, data)

# Public API for external systems
func load_new_map(new_map_name: String):
	print("VRLabScene: Loading new map: %s" % new_map_name)
	map_name = new_map_name
	_load_initial_map()

func get_current_map() -> String:
	return map_name

func get_grid_system() -> Node3D:
	return grid_system

func get_lab_manager() -> Node:
	return lab_manager

# Handle scene data from staging system
func set_scene_user_data(data: Dictionary):
	user_data = data
	set_meta("scene_user_data", data)
	print("VRLabScene: Received scene user data: %s" % data) 