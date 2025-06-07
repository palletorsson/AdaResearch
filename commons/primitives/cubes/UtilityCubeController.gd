# UtilityCubeController.gd
# Chapter 8: The Smart Utility Cube
# Dynamic behavior system with JSON configuration

extends "res://commons/scenes/mapobjects/TeleportController.gd"

@export var utility_type: String = "teleporter"
@export var config_file: String = ""
@export var auto_configure: bool = true

var behavior_manager: Node
var config_loader: Node
var current_behaviors: Array[String] = []
var utility_config: Dictionary = {}

# Universal utility signals
signal utility_configured(type: String, config: Dictionary)
signal behavior_changed(old_behavior: String, new_behavior: String)
signal utility_triggered(utility_type: String, data: Dictionary)

func _ready():
	# Create behavior system
	_setup_behavior_system()
	
	# Load configuration
	if auto_configure:
		_load_utility_configuration()
	
	# Call parent ready after our setup
	super()
	
	print("UtilityCubeController: Smart utility cube ready - type: %s" % utility_type)

func _setup_behavior_system():
	# Create behavior manager
	behavior_manager = Node.new()
	behavior_manager.name = "BehaviorManager"
	add_child(behavior_manager)
	
	# Create config loader
	config_loader = Node.new()
	config_loader.name = "ConfigLoader"
	add_child(config_loader)

func _load_utility_configuration():
	# Load from metadata first
	var grid_metadata = get_meta("utility_definition", {})
	if not grid_metadata.is_empty():
		utility_config = grid_metadata
		print("UtilityCubeController: Loaded config from grid metadata")
	
	# Load from file if specified
	elif not config_file.is_empty():
		utility_config = _load_config_from_file(config_file)
	
	# Apply default config based on type
	else:
		utility_config = _get_default_config_for_type(utility_type)
	
	# Apply the configuration
	_apply_utility_configuration()

func _load_config_from_file(file_path: String) -> Dictionary:
	if not FileAccess.file_exists(file_path):
		print("UtilityCubeController: Config file not found: %s" % file_path)
		return {}
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	if json.parse(json_text) == OK:
		return json.data
	
	return {}

func _get_default_config_for_type(type: String) -> Dictionary:
	match type:
		"teleporter":
			return {
				"destination": "next_map",
				"activation_method": "touch",
				"charge_time": 2.0,
				"portal_color": [0, 1, 1, 1]
			}
		"pickup":
			return {
				"interaction_type": "grab",
				"hover_effects": true,
				"physics_enabled": false
			}
		"trigger":
			return {
				"trigger_area_size": [2.0, 2.0, 2.0],
				"activation_method": "proximity",
				"repeatable": true
			}
		"physics":
			return {
				"mass": 1.0,
				"bounce": 0.5,
				"friction": 0.7,
				"impulse_strength": 5.0
			}
		_:
			return {}

func _apply_utility_configuration():
	print("UtilityCubeController: Applying configuration for type: %s" % utility_type)
	
	# Apply type-specific configuration
	match utility_type:
		"teleporter":
			_configure_as_teleporter()
		"pickup":
			_configure_as_pickup()
		"trigger":
			_configure_as_trigger()
		"physics":
			_configure_as_physics()
		"hybrid":
			_configure_as_hybrid()
	
	# Emit configuration complete signal
	utility_configured.emit(utility_type, utility_config)

func _configure_as_teleporter():
	# Set teleporter properties
	if utility_config.has("destination"):
		destination = utility_config["destination"]
	
	if utility_config.has("activation_method"):
		activation_method = utility_config["activation_method"]
	
	if utility_config.has("charge_time"):
		charge_time = utility_config["charge_time"]
	
	if utility_config.has("portal_color"):
		var color_array = utility_config["portal_color"]
		portal_color = Color(color_array[0], color_array[1], color_array[2], color_array[3])
	
	_add_behavior("teleporter")

func _configure_as_pickup():
	# Configure pickup behavior
	if utility_config.has("hover_effects"):
		var hover_enabled = utility_config["hover_effects"]
		# Apply to existing pickup controller properties
	
	_add_behavior("pickup")

func _configure_as_trigger():
	# Configure trigger area
	if utility_config.has("trigger_area_size"):
		var size_array = utility_config["trigger_area_size"]
		_setup_trigger_area(Vector3(size_array[0], size_array[1], size_array[2]))
	
	_add_behavior("trigger")

func _configure_as_physics():
	# Add physics behavior if not already present
	if not _has_behavior("physics"):
		_add_physics_body()
	
	_add_behavior("physics")

func _configure_as_hybrid():
	# Multiple behaviors for hybrid utility
	var behaviors = utility_config.get("behaviors", ["pickup", "teleporter"])
	for behavior in behaviors:
		_add_behavior(behavior)

func _add_behavior(behavior_name: String):
	if behavior_name not in current_behaviors:
		current_behaviors.append(behavior_name)
		print("UtilityCubeController: Added behavior: %s" % behavior_name)

func _has_behavior(behavior_name: String) -> bool:
	return behavior_name in current_behaviors

func _setup_trigger_area(area_size: Vector3):
	# Create or modify trigger area
	var trigger_area = find_child("TriggerArea", false, false)
	if not trigger_area:
		trigger_area = Area3D.new()
		trigger_area.name = "TriggerArea"
		add_child(trigger_area)
		
		var collision_shape = CollisionShape3D.new()
		var box_shape = BoxShape3D.new()
		collision_shape.shape = box_shape
		trigger_area.add_child(collision_shape)
	
	# Set size
	var collision_shape = trigger_area.find_child("CollisionShape3D", false, false)
	if collision_shape and collision_shape.shape is BoxShape3D:
		collision_shape.shape.size = area_size

func _add_physics_body():
	# Convert to physics if needed
	print("UtilityCubeController: Adding physics behavior")
	# This would require more complex restructuring

# Override parent activation to use utility system
func _activate_teleporter():
	# Emit universal utility signal
	var trigger_data = {
		"utility_type": utility_type,
		"destination": destination,
		"position": global_position,
		"config": utility_config
	}
	
	utility_triggered.emit(utility_type, trigger_data)
	
	# Call parent if it's a teleporter
	if utility_type == "teleporter" or _has_behavior("teleporter"):
		super()

# Public API for runtime reconfiguration
func set_utility_type(new_type: String):
	var old_type = utility_type
	utility_type = new_type
	
	# Clear existing behaviors
	current_behaviors.clear()
	
	# Reconfigure
	_load_utility_configuration()
	
	behavior_changed.emit(old_type, new_type)

func update_config(new_config: Dictionary):
	utility_config.merge(new_config, true)
	_apply_utility_configuration()

func get_current_behaviors() -> Array[String]:
	return current_behaviors.duplicate()

func get_utility_config() -> Dictionary:
	return utility_config.duplicate()

# Debug methods
func print_utility_status():
	print("=== UTILITY CUBE STATUS ===")
	print("Type: %s" % utility_type)
	print("Behaviors: %s" % str(current_behaviors))
	print("Config keys: %s" % str(utility_config.keys()))
	print("Active: %s" % is_inside_tree())
	print("============================")
