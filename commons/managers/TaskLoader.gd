# TaskLoader.gd
extends Node
class_name TaskLoader

# References to other components (will be set by external caller)
var task_manager_controller: TaskManagerController = null
var tasks_data = null
var debug_label: Label3D = null

# Task List
var tasks: Array[Task] = []
var loading_complete: bool = false

signal tasks_loaded(tasks)

func _ready() -> void:
	# Check if references are set, otherwise try to find them automatically
	_ensure_references()
	
	# Wait one frame to ensure all nodes are ready
	await get_tree().process_frame
	load_tasks()

# Make sure all necessary references are set
func _ensure_references() -> void:
	# Only try to find references if they haven't been explicitly set
	if task_manager_controller == null:
		task_manager_controller = TaskSystem.get_task_manager()
		
	if tasks_data == null:
		tasks_data = TaskSystem.get_tasks_data()
	
	# Debug label is optional, so we don't need to ensure it

# Initialize with required references
func initialize(manager: TaskManagerController, data, debug_lbl: Label3D = null) -> void:
	task_manager_controller = manager
	tasks_data = data
	debug_label = debug_lbl

# Load tasks from the embedded JSON data in TasksData
func load_tasks() -> void:
	_ensure_references()
	
	if not task_manager_controller:
		_log_error("TaskManagerController not found.")
		return
	
	if not tasks_data or not tasks_data.has_method("get_tasks_json"):
		_log_error("TasksData resource not valid or missing get_tasks_json method.")
		return
	
	# Rest of the load_tasks method remains the same...
	# ...

# Logging helpers
func _log_info(message: String) -> void:
	print("TaskLoader: " + message)
	if debug_label:
		debug_label.text = message

func _log_error(message: String) -> void:
	push_error("TaskLoader: " + message)
	if debug_label:
		debug_label.text = "ERROR: " + message
