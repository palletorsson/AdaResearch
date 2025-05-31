# TaskSystem.gd
extends Node

# References to key components
var _task_manager: TaskManagerController = null
var _task_loader: TaskLoader = null 
var _tasks_data = null
var _task_scene_container: Node3D = null
var _grid_system = null

# References to other game systems
var _game_text_manager = null
var _mission_text: Label3D = null

# Path to task data
const ARTIFACT_DATA_PATH = "res://adaresearch/Common/Scripts/Managers/artifact_data.gd"

# Initialize the task system with required components
func initialize(
	task_manager: TaskManagerController, 
	task_loader: TaskLoader,
	task_scene_container: Node3D = null,
	game_text_manager = null,
	mission_text: Label3D = null,
	grid_system = null
) -> void:
	_task_manager = task_manager
	_task_loader = task_loader
	_task_scene_container = task_scene_container
	_game_text_manager = game_text_manager
	_mission_text = mission_text
	_grid_system = grid_system
	
	# Load task data
	_tasks_data = _load_task_data()
	
	# Initialize components with their dependencies
	if _task_loader and _task_manager and _tasks_data:
		_task_loader.initialize(_task_manager, _tasks_data)
		_task_manager.initialize(_task_scene_container, _game_text_manager, _mission_text)
		
		# Connect to grid system if available
		if _grid_system and _grid_system.has_signal("interactable_activated"):
			_grid_system.connect("interactable_activated", _on_grid_interactable_activated)

# Load task data from the specified path
func _load_task_data():
	if ResourceLoader.exists(ARTIFACT_DATA_PATH):
		var artifact_data_script = load(ARTIFACT_DATA_PATH)
		if artifact_data_script:
			var artifact_data_instance = artifact_data_script.new()
			print("TaskSystem: Loaded artifact data from %s" % ARTIFACT_DATA_PATH)
			return artifact_data_instance
		else:
			push_error("TaskSystem: Failed to load artifact data script: %s" % ARTIFACT_DATA_PATH)
	else:
		push_error("TaskSystem: Artifact data script not found: %s" % ARTIFACT_DATA_PATH)
	
	return null

# Handle grid system interactable activation
func _on_grid_interactable_activated(algorithm_id: String, position: Vector3i, data = null) -> void:
	if _task_manager:
		# Check if this algorithm ID corresponds to a task
		var task = _task_manager.get_task_by_lookup_name(algorithm_id)
		if task:
			# Either activate or update progress for the task
			if not _task_manager.is_task_active(algorithm_id):
				_task_manager.activate_task(algorithm_id)
			else:
				_task_manager.update_task_progress(algorithm_id)
		
		print("TaskSystem: Grid interactable activated: %s at %s" % [algorithm_id, position])

# Make task data accessible to other components
func get_tasks_json():
	if _tasks_data and _tasks_data.has_constant("ARTIFACTS_JSON"):
		return _tasks_data.ARTIFACTS_JSON
	return []

# Getters for system components
func get_task_manager() -> TaskManagerController:
	return _task_manager

func get_task_loader() -> TaskLoader:
	return _task_loader

func get_tasks_data():
	return _tasks_data

func get_task_scene_container() -> Node3D:
	return _task_scene_container

func get_game_text_manager():
	return _game_text_manager

func get_mission_text() -> Label3D:
	return _mission_text

func get_grid_system():
	return _grid_system

# Task management convenience methods

func activate_task(lookup_name: String) -> bool:
	if _task_manager:
		return _task_manager.activate_task(lookup_name)
	return false

func update_task_progress(lookup_name: String, amount: int = 1) -> bool:
	if _task_manager:
		return _task_manager.update_task_progress(lookup_name, amount)
	return false

func get_task_by_lookup_name(lookup_name: String) -> Task:
	if _task_manager:
		return _task_manager.get_task_by_lookup_name(lookup_name)
	return null

func get_all_tasks() -> Array:
	if _task_manager:
		return _task_manager.get_tasks()
	return []

# Add this method to check if a task is active
func is_task_active(lookup_name: String) -> bool:
	if _task_manager:
		return _task_manager.is_task_active(lookup_name)
	return false

# Add this method to check if a task is completed
func is_task_completed(lookup_name: String) -> bool:
	if _task_manager:
		return _task_manager.is_task_completed(lookup_name)
	return false
