# grid_scene.gd - Script for grid.tscn using SceneManagerHelper
# Inherits from XRToolsSceneBase via base.tscn (preserves VR functionality)

extends Node3D

# Entry scene preloads
const CORRIDOR_SCENE = preload("res://commons/structures/corridor/CorridorScene.tscn")
const ONE_CUBE_ENTRY = preload("res://commons/structures/entry/OneCubeEntry.tscn")

@onready var grid_system = $"../GridSystem"

# Sequence management
var sequence_data: Dictionary = {}
var current_map_index: int = 0

func _ready():
	print("GridScene: Initializing with SceneManagerHelper integration")

	# Connect to grid system signal BEFORE any await
	if grid_system:
		if grid_system.has_signal("map_generation_complete"):
			grid_system.map_generation_complete.connect(_on_map_generation_complete)
			print("GridScene: Connected to map_generation_complete signal")

		# Deferred fallback in case signal was missed
		call_deferred("_deferred_entry_check")

	# Wait for SceneManager to be ready
	var scene_manager = await SceneManagerHelper.wait_for_scene_manager(self)

	# Connect to grid system if available
	if grid_system:
		scene_manager.connect_to_grid_system(grid_system)
	
	# Handle scene user data from staging
	call_deferred("_process_scene_user_data")
	
	print("GridScene: Grid scene ready with SceneManagerHelper")

func _process_scene_user_data():
	"""Process user data passed from staging/SceneManager"""
	var user_data = get_meta("scene_user_data", {})
	
	if user_data.has("sequence_data"):
		sequence_data = user_data.sequence_data
		current_map_index = sequence_data.get("current_step", 0)
		print("GridScene: Loaded sequence data: %s" % sequence_data.get("sequence_name", "unknown"))
		
		# CRITICAL: Pass sequence data to GridSystem
		if grid_system:
			grid_system.set_meta("current_sequence", sequence_data)
			print("GridScene: ✅ Passed sequence data to GridSystem: %s" % sequence_data.get("sequence_name", "unknown"))
	
	if user_data.has("initial_map"):
		var initial_map = user_data.initial_map
		print("GridScene: Setting initial map: %s" % initial_map)
		_configure_grid_system_for_map(initial_map)
	elif user_data.has("map_name"):
		var map_name = user_data.map_name
		print("GridScene: Setting map from user_data: %s" % map_name)
		_configure_grid_system_for_map(map_name)

func _configure_grid_system_for_map(map_name: String):
	"""Configure grid system to load specific map"""
	if not grid_system:
		return
	
	print("GridScene: Configuring grid system for map: %s" % map_name)
	
	# Set map name
	if "map_name" in grid_system:
		grid_system.map_name = map_name
	
	# Trigger reload if needed
	if grid_system.has_method("reload_map_async"):
		await grid_system.reload_map_async()
	elif grid_system.has_method("reload_map_with_name"):
		grid_system.reload_map_with_name(map_name)
	else:
		# Fallback: reload the scene
		get_tree().reload_current_scene()

func _spawn_entry_by_type():
	"""Spawn entry based on map settings - corridor for Lab, one_cube for others"""
	var enter_type = "one_cube"  # Default

	# Get enter_type from map settings
	if grid_system and grid_system.get_data_component():
		var settings = grid_system.get_data_component().get_settings()
		if settings.has("enter_type"):
			enter_type = settings["enter_type"]

	print("GridScene: Spawning entry type '%s'" % enter_type)

	# Clear any existing entry
	var existing = get_node_or_null("ActiveEntry")
	if existing:
		existing.queue_free()

	# Spawn based on type
	var instance: Node3D
	if enter_type == "corridor":
		instance = CORRIDOR_SCENE.instantiate()
		instance.position = Vector3.ZERO
	else:
		instance = ONE_CUBE_ENTRY.instantiate()
		instance.position = Vector3(0, 0, -1)

	instance.name = "ActiveEntry"
	add_child(instance)
	print("GridScene: Spawned %s at position %s" % [enter_type, instance.position])

func _deferred_entry_check():
	"""Fallback check after a frame - spawn entry if not already done"""
	await get_tree().process_frame  # Wait one more frame for map data
	var existing = get_node_or_null("ActiveEntry")
	if not existing:
		print("GridScene: Deferred fallback - spawning entry")
		_spawn_entry_by_type()

func _on_map_generation_complete():
	"""Handle grid system completing map generation"""
	print("GridScene: Map generation complete")

	# Spawn entry based on map settings
	_spawn_entry_by_type()
	
	# Add exit trigger if in sequence
	if not sequence_data.is_empty():
		_setup_sequence_exit_trigger()

func _setup_sequence_exit_trigger():
	"""Setup automatic sequence progression trigger"""
	print("GridScene: Setting up sequence exit trigger")
	
	# Create a timer for automatic progression (remove this in production)
	var auto_advance_timer = Timer.new()
	auto_advance_timer.wait_time = 10.0  # 10 seconds for testing
	auto_advance_timer.one_shot = true
	auto_advance_timer.timeout.connect(_on_auto_advance_timeout)
	add_child(auto_advance_timer)
	auto_advance_timer.start()
	
	print("GridScene: Auto-advance timer started (10 seconds)")

func _on_auto_advance_timeout():
	"""Handle automatic sequence advancement (for testing)"""
	print("GridScene: Auto-advancing sequence")
	SceneManagerHelper.advance_sequence(self)

# Public methods for sequence management
func advance_sequence():
	"""Advance to next map in sequence"""
	SceneManagerHelper.advance_sequence(self)

func complete_sequence():
	"""Complete the current sequence and return to lab"""
	print("GridScene: Sequence complete - returning to lab")
	
	var completion_data = {
		"sequence_completed": sequence_data.get("sequence_name", "unknown"),
		"maps_completed": sequence_data.get("maps", []),
		"completion_time": Time.get_datetime_string_from_system()
	}
	
	SceneManagerHelper.return_to_lab(completion_data, self)

func handle_teleporter_activation(destination: String):
	"""Handle teleporter activation in grid scene"""
	match destination:
		"next":
			SceneManagerHelper.advance_sequence(self)
		"lab", "menu":
			SceneManagerHelper.return_to_lab({}, self)
		_:
			SceneManagerHelper.load_map(destination, "default", self)

# Debug helper
func _input(event):
	if event.is_action_pressed("ui_accept"):  # Space or Enter key
		print("GridScene: Manual sequence advance triggered")
		SceneManagerHelper.advance_sequence(self)
