# Task.gd
class_name Task
extends RefCounted

# Define the properties of a task
var task_name: String
var lookup_name: String
var description: String
var start_string: String
var task_world_position: Vector3
var is_complete: bool = false
var success_string: String
var task_space: String
var target_object: String
var amount_required: int
var amount_collected: int = 0
var amount_tick: float
var amount_multiplier: float
var audio_start_file_path: String
var audio_complete_file_path: String
var scene_path: String
var task_scene: Node3D = null

# Signal for task completion
signal task_completed(task)
signal task_progress_updated(task, previous_amount, current_amount)

# Initialize a task
func _init(
		task_name: String,
		lookup_name: String,
		description: String,
		start_string: String,
		task_world_position: Vector3,
		success_string: String,
		task_space: String,
		target_object: String,
		amount_required: int,
		amount_tick: float,
		amount_multiplier: float,
		audio_start_file_path: String,
		audio_complete_file_path: String,
		scene_path: String = ""
	):
	self.task_name = task_name
	self.lookup_name = lookup_name
	self.description = description
	self.start_string = start_string
	self.task_world_position = task_world_position
	self.success_string = success_string
	self.task_space = task_space
	self.target_object = target_object
	self.amount_required = amount_required
	self.amount_tick = amount_tick
	self.amount_multiplier = amount_multiplier
	self.audio_start_file_path = audio_start_file_path
	self.audio_complete_file_path = audio_complete_file_path
	self.scene_path = scene_path

# Mark the task as completed
func complete():
	if not is_complete:
		is_complete = true
		task_completed.emit(self)
	
# Update progress towards task completion
func update_progress(amount: int) -> bool:
	if is_complete:
		return false
		
	var previous_amount = amount_collected
	amount_collected += amount
	
	# Emit progress signal
	task_progress_updated.emit(self, previous_amount, amount_collected)
	
	# Check if task is complete
	if amount_collected >= amount_required:
		complete()
		return true
	
	return false

# Get completion percentage
func get_completion_percentage() -> float:
	return float(amount_collected) / float(amount_required) * 100.0

# Reset the task
func reset():
	var was_complete = is_complete
	is_complete = false
	amount_collected = 0
	if was_complete:
		# You might want a signal for task reset as well
		pass

# Load the task scene
func load_scene() -> Node3D:
	if scene_path.is_empty():
		return null
		
	if task_scene != null:
		return task_scene
		
	if ResourceLoader.exists(scene_path):
		var scene_resource = load(scene_path)
		if scene_resource is PackedScene:
			task_scene = scene_resource.instantiate()
			if task_scene is Node3D:
				# Initialize the task scene with this task data
				if task_scene.has_method("initialize_with_task"):
					task_scene.initialize_with_task(self)
				return task_scene
			else:
				task_scene = null
				push_error("Task scene is not a Node3D: " + scene_path)
	else:
		push_error("Task scene does not exist: " + scene_path)
		
	return null

# Unload the task scene
func unload_scene() -> void:
	if task_scene != null:
		if task_scene.is_inside_tree():
			task_scene.queue_free()
		task_scene = null

# Debugging utility
func task_to_string() -> String:
	return "Task(task_name: %s, lookup_name: %s, description: %s, start_string: %s, task_world_position: %s, is_complete: %s, success_string: %s, task_space: %s, target_object: %s, amount_required: %d, amount_collected: %d, amount_tick: %f, amount_multiplier: %f, scene_path: %s)" % [
		task_name, lookup_name, description, start_string, str(task_world_position), str(is_complete), success_string, task_space, target_object, amount_required, amount_collected, amount_tick, amount_multiplier, scene_path
	]
