# TaskManagerController.gd
extends Node
class_name TaskManagerController

# Task Lists
var tasks: Array[Task] = []
var active_tasks: Array[Task] = []
var completed_tasks: Array[Task] = []

# External component references (will be set via initialize())
var task_scene_container: Node3D = null
var game_text_manager = null
var mission_text: Label3D = null
var debug_label: Label3D = null

# Signals
signal task_activated(task)
signal task_progress_updated(task, previous_progress, current_progress)
signal task_completed(task)
signal xp_updated(amount)

# Task status
enum TaskStatus { INACTIVE, ACTIVE, COMPLETED }

# Initialize with required references
func initialize(
	scene_container: Node3D = null, 
	text_manager = null, 
	mission_label: Label3D = null, 
	debug_lbl: Label3D = null
) -> void:
	task_scene_container = scene_container
	game_text_manager = text_manager
	mission_text = mission_label
	debug_label = debug_lbl
	
	# If we still have a direct child Label3D, use it for debugging
	if debug_label == null and has_node("Label3D"):
		debug_label = get_node("Label3D")

# Set tasks in the manager
func set_tasks(new_tasks: Array) -> String:
	tasks = []
	# Convert generic array to typed array
	for task in new_tasks:
		if task is Task:
			tasks.append(task)
			# Connect to task signals
			#task.task_completed.connect(_on_task_completed)
			#task.task_progress_updated.connect(_on_task_progress_updated)
	
	_log_info("Set " + str(tasks.size()) + " tasks")
	
	# Update GameManager if available
	if GameManager and GameManager.has_method("set_tasks"):
		var result = GameManager.set_tasks(tasks)
		if result:
			return "Tasks set in GameManager and TaskManager"
		else:
			return "Error setting tasks in GameManager"
	else:
		return "Tasks set in TaskManager only"

# Activate a task by lookup name
func activate_task(lookup_name: String) -> bool:
	var task = get_task_by_lookup_name(lookup_name)
	if not task:
		_log_error("Task not found: " + lookup_name)
		return false
		
	return _activate_task(task)

# Internal method to activate a task
func _activate_task(task: Task) -> bool:
	if task in active_tasks:
		_log_info("Task already active: " + task.task_name)
		return false
		
	if task in completed_tasks:
		_log_info("Task already completed: " + task.task_name)
		return false
	
	active_tasks.append(task)
	
	# Update UI
	if mission_text:
		mission_text.text = task.description
		# Clear mission text after a delay
		get_tree().create_timer(5.0).timeout.connect(func(): 
			if mission_text and mission_text.text == task.description:
				mission_text.text = ""
		)
	
	# Update game text manager
	if game_text_manager and game_text_manager.has_method("add_string_to_list"):
		game_text_manager.add_string_to_list(task.description)
		_log_info("Task description added to game text: " + task.description)
	
	# Update GameManager
	if GameManager and GameManager.has_method("set_message"):
		GameManager.set_message(task.description)
	
	# Load and instantiate the task scene if it has one
	if not task.scene_path.is_empty():
		_load_task_scene(task)
	
	_log_info("Task activated: " + task.task_name)
	task_activated.emit(task)
	return true
# Function to get a task by its lookup name
func get_task_by_lookup_name(lookup_name: String) -> Task:
	# Input validation
	if lookup_name.is_empty():
		push_error("TaskManagerController: Cannot get task with empty lookup name")
		return null
	
	# Search through all tasks
	for task in tasks:
		if task.lookup_name == lookup_name:
			return task
	
	# No matching task found
	_log_info("Task with lookup name '%s' not found" % lookup_name)
	return null

# Function to load a task's scene
func load_task_scene(task: Task) -> Node3D:
	# Input validation
	if not task:
		push_error("TaskManagerController: Cannot load scene for null task")
		return null
	
	if task.scene_path.is_empty():
		_log_info("Task '%s' has no scene path defined" % task.task_name)
		return null
	
	# First check if the task already has a loaded scene
	if task.task_scene != null:
		# If the scene is already in the tree, just return it
		if task.task_scene.is_inside_tree():
			return task.task_scene
		
		# If it's not in the tree but is instantiated, return it for the caller to add
		return task.task_scene
	
	# Load the task scene
	var task_scene = task.load_scene()
	if not task_scene:
		push_error("TaskManagerController: Failed to load scene for task '%s' from path: %s" % [task.task_name, task.scene_path])
		return null
	
	# Set up the scene with task data if it has the initialize_with_task method
	if task_scene.has_method("initialize_with_task"):
		task_scene.initialize_with_task(task)
	
	_log_info("Loaded scene for task: %s" % task.task_name)
	
	# The caller will need to add this to the scene tree
	return task_scene

# Helper function to add a task scene to the container
func add_task_scene_to_container(task: Task) -> Node3D:
	# Load the task scene
	var task_scene = load_task_scene(task)
	if not task_scene:
		return null
	
	# Add to the container if it exists
	if task_scene_container:
		task_scene_container.add_child(task_scene)
		_log_info("Added task scene to container: %s" % task.task_name)
		return task_scene
	
	# If no container exists, add to self
	add_child(task_scene)
	_log_info("Added task scene (no container): %s" % task.task_name)
	return task_scene

# Function to unload a task scene
func unload_task_scene(task: Task) -> bool:
	if not task:
		return false
	
	if task.task_scene:
		task.unload_scene()
		_log_info("Unloaded scene for task: %s" % task.task_name)
		return true
	
	return false
	
func _load_task_scene(task): 
	pass

# Logging helpers
func _log_info(message: String) -> void:
	print("TaskManager: " + message)
	if debug_label:
		debug_label.text = message

func _log_error(message: String) -> void:
	push_error("TaskManager: " + message)
	if debug_label:
		debug_label.text = "ERROR: " + message

# TaskManagerController.gd
# Add these methods to your existing TaskManagerController class

# Check if a task is active
func is_task_active(lookup_name: String) -> bool:
	var task = get_task_by_lookup_name(lookup_name)
	if task:
		return task in active_tasks
	return false

# Check if a task is completed
func is_task_completed(lookup_name: String) -> bool:
	var task = get_task_by_lookup_name(lookup_name)
	if task:
		return task in completed_tasks
	return false

# Get a task's current progress percentage
func get_task_progress(lookup_name: String) -> float:
	var task = get_task_by_lookup_name(lookup_name)
	if task:
		return float(task.amount_collected) / float(task.amount_required) * 100.0
	return 0.0

# Get all tasks in a specific space
func get_tasks_by_space(space_name: String) -> Array:
	var space_tasks = []
	for task in tasks:
		if task.task_space == space_name:
			space_tasks.append(task)
	return space_tasks

# Get all tasks targeting a specific object
func get_tasks_by_target_object(target_object_name: String) -> Array:
	var object_tasks = []
	for task in tasks:
		if task.target_object == target_object_name:
			object_tasks.append(task)
	return object_tasks

# Get closest task to a world position
func get_closest_task(world_position: Vector3) -> Task:
	var closest_task = null
	var closest_distance = INF
	
	for task in tasks:
		var distance = world_position.distance_to(task.task_world_position)
		if distance < closest_distance:
			closest_distance = distance
			closest_task = task
	
	return closest_task

# Reset a specific task
func reset_task(lookup_name: String) -> bool:
	var task = get_task_by_lookup_name(lookup_name)
	if task:
		task.reset()
		if task in completed_tasks:
			completed_tasks.erase(task)
		if task in active_tasks:
			active_tasks.erase(task)
		return true
	return false
