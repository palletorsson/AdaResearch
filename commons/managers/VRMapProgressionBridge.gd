# VRMapProgressionBridge.gd
# Bridges VR staging system with map progression management
# Handles dynamic scene generation and progression-based navigation

extends Node
class_name VRMapProgressionBridge

# References
var staging: XRToolsStaging
var progression_manager: MapProgressionManager
var dynamic_map_system: DynamicMapSystem

# Current state
var current_map_name: String = ""
var next_target_map: String = ""

# Signals
signal map_transition_requested(map_name: String)
signal map_completed_in_vr(map_name: String)
signal progression_updated(completed_maps: Array, unlocked_maps: Array)

# Scene paths
const VR_MAP_SCENE_BASE = "res://adaresearch/Common/Scenes/Maps/base.tscn"
const VR_MENU_SCENE = "res://adaresearch/Common/Scenes/Maps/vr_progression_menu.tscn"

func _ready():
	# Initialize progression manager if not already loaded
	if not progression_manager:
		progression_manager = MapProgressionManager.new()
		add_child(progression_manager)
	
	# Connect to progression manager signals
	if progression_manager:
		progression_manager.map_completed.connect(_on_map_completed)
		progression_manager.map_unlocked.connect(_on_map_unlocked)
		progression_manager.progression_loaded.connect(_on_progression_loaded)
	
	print("VRMapProgressionBridge: Initialized")

# Initialize with staging reference
func initialize_with_staging(staging_ref: XRToolsStaging):
	staging = staging_ref
	if staging:
		# Connect to staging signals
		staging.scene_loaded.connect(_on_vr_scene_loaded)
		staging.scene_visible.connect(_on_vr_scene_visible)
		print("VRMapProgressionBridge: Connected to staging system")

# Load a map in VR based on progression
func load_map_in_vr(map_name: String, user_data = null):
	if not staging:
		push_error("VRMapProgressionBridge: No staging reference available")
		return
	
	if not progression_manager:
		push_error("VRMapProgressionBridge: No progression manager available")
		return
	
	print("VRMapProgressionBridge: Loading map '%s' in VR" % map_name)
	
	# Check if map is unlocked
	if not progression_manager.is_map_unlocked(map_name):
		print("VRMapProgressionBridge: Map '%s' is not unlocked yet" % map_name)
		# Load menu instead
		staging.load_scene(VR_MENU_SCENE, {"blocked_map": map_name})
		return
	
	# Update current map
	current_map_name = map_name
	progression_manager.current_map = map_name
	
	# Generate or load VR scene for this map
	var scene_path = _get_or_generate_vr_scene(map_name)
	if scene_path:
		# Pass map data to the scene
		var scene_user_data = {
			"map_name": map_name,
			"progression_bridge": self,
			"user_data": user_data
		}
		staging.load_scene(scene_path, scene_user_data)
	else:
		push_error("VRMapProgressionBridge: Failed to load scene for map '%s'" % map_name)

# Get or generate VR scene for a map
func _get_or_generate_vr_scene(map_name: String) -> String:
	# Check if static VR scene exists
	var static_scene_path = "res://adaresearch/Common/Scenes/Maps/" + map_name.to_lower() + ".tscn"
	if ResourceLoader.exists(static_scene_path):
		print("VRMapProgressionBridge: Using static VR scene for '%s'" % map_name)
		return static_scene_path
	
	# Generate dynamic VR scene
	print("VRMapProgressionBridge: Generating dynamic VR scene for '%s'" % map_name)
	var generated_scene = DynamicMapSystem.generate_map_scene(map_name, {
		"vr_mode": true,
		"progression_bridge": self
	})
	
	if generated_scene:
		# Save temporarily and return path
		var temp_path = "user://generated_vr_" + map_name + ".tscn"
		if ResourceSaver.save(generated_scene, temp_path) == OK:
			return temp_path
	
	# Fallback to base scene
	print("VRMapProgressionBridge: Falling back to base VR scene for '%s'" % map_name)
	return VR_MAP_SCENE_BASE

# Complete current map and progress
func complete_current_map():
	if current_map_name.is_empty():
		print("VRMapProgressionBridge: No current map to complete")
		return
	
	print("VRMapProgressionBridge: Completing map '%s'" % current_map_name)
	
	# Mark map as completed in progression system
	var newly_unlocked = progression_manager.complete_map(current_map_name)
	
	# Emit signal
	map_completed_in_vr.emit(current_map_name)
	progression_updated.emit(progression_manager.completed_maps, progression_manager.unlocked_maps)
	
	# Get next map
	var next_map = progression_manager.get_next_map(current_map_name)
	if not next_map.is_empty():
		next_target_map = next_map
		print("VRMapProgressionBridge: Next map available: '%s'" % next_map)
	else:
		print("VRMapProgressionBridge: No next map available")
	
	return newly_unlocked

# Navigate to next map in progression
func go_to_next_map():
	if next_target_map.is_empty():
		var next_map = progression_manager.get_next_map(current_map_name)
		if next_map.is_empty():
			print("VRMapProgressionBridge: No next map in progression")
			load_main_menu()
			return
		next_target_map = next_map
	
	load_map_in_vr(next_target_map)

# Navigate to previous map (if possible)
func go_to_previous_map():
	var previous_map = _get_previous_map(current_map_name)
	if not previous_map.is_empty():
		load_map_in_vr(previous_map)
	else:
		load_main_menu()

# Get a previous map in progression
func _get_previous_map(map_name: String) -> String:
	if not progression_manager:
		return ""
	
	# Find a map that unlocks the current map
	for check_map in progression_manager.map_metadata.keys():
		var metadata = progression_manager.map_metadata[check_map]
		var unlocks = metadata.get("unlocks", [])
		if map_name in unlocks:
			return check_map
	
	return ""

# Load main menu
func load_main_menu():
	if staging:
		staging.load_scene(VR_MENU_SCENE)

# Get available maps for navigation
func get_available_maps() -> Array[String]:
	if not progression_manager:
		return []
	
	return progression_manager.unlocked_maps

# Check if a specific map is available
func is_map_available(map_name: String) -> bool:
	if not progression_manager:
		return false
	
	return progression_manager.is_map_unlocked(map_name)

# Get current progression status
func get_progression_status() -> Dictionary:
	if not progression_manager:
		return {}
	
	return {
		"current_map": current_map_name,
		"completed_maps": progression_manager.completed_maps,
		"unlocked_maps": progression_manager.unlocked_maps,
		"total_maps": progression_manager.map_metadata.size(),
		"completion_percentage": float(progression_manager.completed_maps.size()) / float(progression_manager.map_metadata.size()) * 100.0
	}

# Signal handlers
func _on_map_completed(map_name: String):
	print("VRMapProgressionBridge: Map '%s' completed in progression system" % map_name)

func _on_map_unlocked(map_name: String):
	print("VRMapProgressionBridge: Map '%s' unlocked" % map_name)

func _on_progression_loaded():
	print("VRMapProgressionBridge: Progression configuration loaded")

func _on_vr_scene_loaded(scene, user_data):
	print("VRMapProgressionBridge: VR scene loaded")
	
	# Check if scene has a grid system that needs map configuration
	if user_data and typeof(user_data) == TYPE_DICTIONARY:
		var map_name = user_data.get("map_name", "")
		if not map_name.is_empty():
			_configure_scene_for_map(scene, map_name)

func _on_vr_scene_visible(scene, user_data):
	print("VRMapProgressionBridge: VR scene visible")

# Configure a VR scene for a specific map
func _configure_scene_for_map(scene, map_name: String):
	print("VRMapProgressionBridge: Configuring scene for map '%s'" % map_name)
	
	# Find grid system in the scene
	var grid_system = _find_grid_system_in_scene(scene)
	if grid_system:
		# Set the map name on the grid system
		if grid_system.has_method("set_map_name"):
			grid_system.set_map_name(map_name)
		elif "map_name" in grid_system:
			grid_system.map_name = map_name
		
		# Reload the map if needed
		if grid_system.has_method("reload_map_setter"):
			grid_system.reload_map_setter(true)
	else:
		print("VRMapProgressionBridge: No grid system found in scene")

# Find grid system in a VR scene
func _find_grid_system_in_scene(scene):
	# Look for different grid system types
	var grid_names = ["multiLayerGrid", "GridSystemEnhanced", "GridSystem", "multi_layer_grid"]
	
	for grid_name in grid_names:
		var grid = scene.find_child(grid_name, true, false)
		if grid:
			return grid
	
	# Search by class name
	return _find_node_by_class(scene, "GridSystemEnhanced") or _find_node_by_class(scene, "GridSystem")

# Find node by class name
func _find_node_by_class(parent: Node, _class_name: String) -> Node:
	for child in parent.get_children():
		if child.get_script() and child.get_script().get_global_name() == _class_name:
			return child
		var found = _find_node_by_class(child, _class_name)
		if found:
			return found
	return null

# Load starting map based on progression
func load_starting_map():
	if not progression_manager:
		push_error("VRMapProgressionBridge: No progression manager available")
		return
	
	var starting_map = progression_manager.get_starting_map()
	if starting_map.is_empty():
		starting_map = "menu"
	
	load_map_in_vr(starting_map)

# Quick access methods for common navigation
func restart_current_map():
	if not current_map_name.is_empty():
		load_map_in_vr(current_map_name)

func skip_to_map(map_name: String):
	if progression_manager and progression_manager.settings.get("allow_map_skipping", false):
		load_map_in_vr(map_name)
	else:
		print("VRMapProgressionBridge: Map skipping not allowed") 
