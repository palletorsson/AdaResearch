# VRMapProgressionBridge.gd
# Bridges VR staging system with map progression management
# Handles dynamic scene generation and progression-based navigation

extends Node
class_name VRMapProgressionBridge

# References
var staging: XRToolsStaging
var progression_manager: Node  # Changed from MapProgressionManager to generic Node
var dynamic_map_system: Node

# Current state
var current_map_name: String = ""
var next_target_map: String = ""

# Signals
signal map_transition_requested(map_name: String)
signal map_completed_in_vr(map_name: String)
signal progression_updated(completed_maps: Array, unlocked_maps: Array)

# Scene paths
const VR_MAP_SCENE_BASE = "res://commons/scenes/base.tscn"  # Updated path
const VR_MENU_SCENE = "res://commons/scenes/base.tscn"      # Fallback to base scene

func _ready():
	print("VRMapProgressionBridge: Initialized (without MapProgressionManager autoload)")

# Initialize with staging reference
func initialize_with_staging(staging_ref: XRToolsStaging):
	staging = staging_ref
	if staging:
		# Connect to staging signals if they exist
		if staging.has_signal("scene_loaded"):
			staging.scene_loaded.connect(_on_vr_scene_loaded)
		if staging.has_signal("scene_visible"):
			staging.scene_visible.connect(_on_vr_scene_visible)
		print("VRMapProgressionBridge: Connected to staging system")

# Load a map in VR based on progression
func load_map_in_vr(map_name: String, user_data = null):
	if not staging:
		push_error("VRMapProgressionBridge: No staging reference available")
		return
	
	print("VRMapProgressionBridge: Loading map '%s' in VR" % map_name)
	
	# Update current map
	current_map_name = map_name
	
	# Use base scene for now
	var scene_path = VR_MAP_SCENE_BASE
	
	# Pass map data to the scene
	var scene_user_data = {
		"map_name": map_name,
		"progression_bridge": self,
		"user_data": user_data
	}
	staging.load_scene(scene_path, scene_user_data)

# Simplified completion without progression manager
func complete_current_map():
	if current_map_name.is_empty():
		print("VRMapProgressionBridge: No current map to complete")
		return []
	
	print("VRMapProgressionBridge: Completing map '%s'" % current_map_name)
	
	# Emit signal
	map_completed_in_vr.emit(current_map_name)
	progression_updated.emit([], [])  # Empty arrays since no progression manager
	
	return []

# Navigate to next map in progression
func go_to_next_map():
	print("VRMapProgressionBridge: No progression system available - staying on current map")

# Navigate to previous map
func go_to_previous_map():
	print("VRMapProgressionBridge: No progression system available - staying on current map")

# Load main menu
func load_main_menu():
	if staging:
		staging.load_scene(VR_MAP_SCENE_BASE)

# Get available maps for navigation (simplified)
func get_available_maps() -> Array[String]:
	return ["Lab", "Tutorial_Single", "Tutorial_Row", "Tutorial_2D", "Tutorial_Disco"]

# Check if a specific map is available (simplified)
func is_map_available(map_name: String) -> bool:
	return map_name in get_available_maps()

# Get current progression status (simplified)
func get_progression_status() -> Dictionary:
	return {
		"current_map": current_map_name,
		"completed_maps": [],
		"unlocked_maps": get_available_maps(),
		"total_maps": get_available_maps().size(),
		"completion_percentage": 0.0
	}

# Stub methods for signal handlers
func _on_vr_scene_loaded(scene, user_data):
	print("VRMapProgressionBridge: VR scene loaded: %s" % scene.name if scene else "null")

func _on_vr_scene_visible():
	print("VRMapProgressionBridge: VR scene visible")

# Development methods
func skip_to_map(map_name: String):
	load_map_in_vr(map_name)

func restart_current_map():
	if not current_map_name.is_empty():
		load_map_in_vr(current_map_name) 
