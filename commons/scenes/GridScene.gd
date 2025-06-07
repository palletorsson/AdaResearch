# grid_scene.gd - Script for grid.tscn using SceneManagerHelper
# Inherits from XRToolsSceneBase via base.tscn (preserves VR functionality)

extends Node3D

@onready var grid_system = $"../GridSystem"

# Sequence management
var sequence_data: Dictionary = {}
var current_map_index: int = 0

func _ready():
	print("GridScene: Initializing with SceneManagerHelper integration")
	
	# Wait for SceneManager to be ready
	var scene_manager = await SceneManagerHelper.wait_for_scene_manager(self)
	
	# Connect to grid system if available
	if grid_system:
		scene_manager.connect_to_grid_system(grid_system)
		
		# Connect to grid system signals for sequence management
		if grid_system.has_signal("map_generation_complete"):
			grid_system.map_generation_complete.connect(_on_map_generation_complete)
	
	# Handle scene user data from staging
	_process_scene_user_data()
	
	print("GridScene: Grid scene ready with SceneManagerHelper")

func _process_scene_user_data():
	"""Process user data passed from staging/SceneManager"""
	var user_data = get_meta("scene_user_data", {})
	
	if user_data.has("sequence_data"):
		sequence_data = user_data.sequence_data
		current_map_index = sequence_data.get("current_step", 0)
		print("GridScene: Loaded sequence data: %s" % sequence_data.get("sequence_name", "unknown"))
	
	if user_data.has("initial_map"):
		var initial_map = user_data.initial_map
		print("GridScene: Setting initial map: %s" % initial_map)
		_configure_grid_system_for_map(initial_map)

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

func _on_map_generation_complete():
	"""Handle grid system completing map generation"""
	print("GridScene: Map generation complete")
	
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
