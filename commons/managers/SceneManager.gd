# SceneManager.gd
# Handles VR scene coordination and initialization (no UI)
# Part of the commons system for managing scene setup

extends Node
class_name SceneManager

# References
var staging_ref: XRToolsStaging
var lab_manager: LabManager
var grid_system: Node

# Signals
signal scene_setup_complete()
signal lab_manager_ready()
signal grid_system_ready()

func _ready():
	print("SceneManager: Ready")

# Called when scene is loaded by staging
func scene_loaded(user_data: Dictionary = {}):
	print("SceneManager: Scene loaded")
	
	# Store staging reference if provided
	if user_data.has("staging_ref"):
		staging_ref = user_data.staging_ref
		print("SceneManager: Staging reference set")
	
	# Initialize scene components
	_find_lab_manager()
	_initialize_lab_manager()
	_find_and_configure_grid_system()
	
	# Signal completion
	scene_setup_complete.emit()

# Find LabManager in the scene
func _find_lab_manager():
	lab_manager = get_tree().get_first_node_in_group("lab_manager")
	
	if not lab_manager:
		# Try finding by name
		lab_manager = find_child("LabManager", true, false)
	
	if not lab_manager:
		# Try finding in parent scene
		var parent = get_parent()
		if parent:
			lab_manager = parent.find_child("LabManager", true, false)
	
	if lab_manager:
		print("SceneManager: Found LabManager: %s" % lab_manager.name)
		lab_manager_ready.emit()
	else:
		print("SceneManager: WARNING - LabManager not found")

# Initialize the LabManager with staging reference
func _initialize_lab_manager():
	if not lab_manager:
		print("SceneManager: Cannot initialize LabManager - not found")
		return
	
	if not staging_ref:
		print("SceneManager: Cannot initialize LabManager - no staging reference")
		return
	
	print("SceneManager: Initializing LabManager with staging")
	lab_manager.initialize_with_staging(staging_ref)

# Find and configure the grid system
func _find_and_configure_grid_system():
	# Look for different grid system types
	var grid_names = ["multiLayerGrid", "GridSystemEnhanced", "GridSystem", "multi_layer_grid"]
	
	for grid_name in grid_names:
		grid_system = find_child(grid_name, true, false)
		if grid_system:
			print("SceneManager: Found grid system: %s" % grid_name)
			break
	
	if not grid_system:
		# Try finding in parent scene
		var parent = get_parent()
		if parent:
			for grid_name in grid_names:
				grid_system = parent.find_child(grid_name, true, false)
				if grid_system:
					print("SceneManager: Found grid system in parent: %s" % grid_name)
					break
	
	if grid_system:
		_configure_grid_system()
		grid_system_ready.emit()
	else:
		print("SceneManager: WARNING - Grid system not found")

# Configure the grid system for lab environment
func _configure_grid_system():
	if not grid_system:
		return
	
	print("SceneManager: Configuring grid system for lab environment")
	
	# Set map to Lab
	if "map_name" in grid_system:
		grid_system.map_name = "Lab"
	
	# Configure grid settings
	if "cube_size" in grid_system:
		grid_system.cube_size = 1.0
	if "gutter" in grid_system:
		grid_system.gutter = 0.0
	if "showgrid" in grid_system:
		grid_system.showgrid = false
	elif "show_grid" in grid_system:
		grid_system.show_grid = false
	
	# Enable JSON format preference if available
	if "prefer_json_format" in grid_system:
		grid_system.prefer_json_format = true
	
	# Generate/reload the grid
	if grid_system.has_method("generate_layout"):
		grid_system.generate_layout()
		print("SceneManager: Grid layout generated for Lab")
	elif grid_system.has_method("reload_map_setter"):
		grid_system.reload_map_setter(true)
		print("SceneManager: Grid reloaded for Lab")

# Public API
func get_lab_manager() -> LabManager:
	return lab_manager

func get_grid_system() -> Node:
	return grid_system

func is_setup_complete() -> bool:
	return lab_manager != null and grid_system != null 
