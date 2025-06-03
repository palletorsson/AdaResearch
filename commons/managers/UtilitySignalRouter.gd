# UtilitySignalRouter.gd
# Simple router that connects utility object signals to SceneManager
# Add this to utilities that should trigger scene transitions

extends Node
class_name UtilitySignalRouter

# Reference to scene manager
var scene_manager: SceneManager = null

func _ready():
	# Find scene manager
	scene_manager = _find_scene_manager()
	
	if scene_manager:
		print("UtilitySignalRouter: Connected to SceneManager")
	else:
		print("UtilitySignalRouter: WARNING - SceneManager not found")

# Find scene manager in the tree
func _find_scene_manager() -> SceneManager:
	# Try common locations
	var potential_managers = [
		get_node_or_null("/root/SceneManager"),
		get_tree().current_scene.find_child("SceneManager", true, false)
	]
	
	for manager in potential_managers:
		if manager and manager is SceneManager:
			return manager as SceneManager
	
	return null

# Connect a utility object to route its signals
func connect_utility(utility_object: Node3D, utility_type: String):
	if not scene_manager:
		return
	
	# Connect teleporter-specific signals
	if utility_type == "teleporter" and utility_object.has_signal("teleporter_activated"):
		utility_object.teleporter_activated.connect(_on_teleporter_activated.bind(utility_object))
		print("UtilitySignalRouter: Connected teleporter_activated signal")
	
	# Connect common utility signals
	if utility_object.has_signal("activated"):
		utility_object.activated.connect(_on_utility_activated.bind(utility_type, utility_object))
	
	if utility_object.has_signal("teleport_triggered"):
		utility_object.teleport_triggered.connect(_on_teleport_triggered.bind(utility_object))
	
	if utility_object.has_signal("zone_entered"):
		utility_object.zone_entered.connect(_on_zone_entered.bind(utility_type, utility_object))

# Handle teleporter activation - advance sequence
func _on_teleporter_activated(utility_object: Node3D):
	print("UtilitySignalRouter: Teleporter activated - requesting sequence advance")
	
	# Tell SceneManager to advance the current sequence
	scene_manager.request_transition({
		"type": SceneManager.TransitionType.TELEPORTER,
		"action": "next_in_sequence",
		"source": "teleporter",
		"position": utility_object.global_position
	})

# Handle utility activation
func _on_utility_activated(utility_type: String, utility_object: Node3D):
	var utility_data = {
		"position": utility_object.global_position,
		"name": utility_object.name
	}
	
	# Add utility-specific data
	if "destination" in utility_object:
		utility_data["destination"] = utility_object.destination
	
	if "destination_map" in utility_object:
		utility_data["destination"] = utility_object.destination_map
	
	if "spawn_point" in utility_object:
		utility_data["spawn_point"] = utility_object.spawn_point
	
	scene_manager._on_utility_activated(utility_type, utility_object.global_position, utility_data)

# Handle teleport activation (legacy - kept for compatibility)
func _on_teleport_activated(utility_object: Node3D, target_scene_path: String, target_map_name: String):
	var utility_data = {
		"position": utility_object.global_position,
		"name": utility_object.name,
		"destination": target_map_name
	}
	
	# Add spawn point if available
	if "spawn_point" in utility_object:
		utility_data["spawn_point"] = utility_object.spawn_point
	
	scene_manager._on_utility_activated("teleporter", utility_object.global_position, utility_data)

# Handle teleport triggers
func _on_teleport_triggered(utility_object: Node3D):
	_on_utility_activated("teleporter", utility_object)

# Handle zone entry
func _on_zone_entered(utility_type: String, utility_object: Node3D):
	var utility_data = {
		"position": utility_object.global_position,
		"zone_type": "entry"
	}
	scene_manager._on_utility_activated(utility_type, utility_object.global_position, utility_data)

# Static helper to add router to utility
static func add_to_utility(utility_object: Node3D, utility_type: String):
	var router = UtilitySignalRouter.new()
	router.name = "SignalRouter"
	utility_object.add_child(router)
	router.connect_utility(utility_object, utility_type)
	print("UtilitySignalRouter: Added router to %s (%s)" % [utility_object.name, utility_type])
