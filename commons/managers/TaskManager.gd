# TaskManager.gd
extends Node

signal task_started(task_id)
signal task_progress_signal(task_id, progress)
signal task_completed(task_id, xp_reward)

var tasks = {}
var active_tasks = {}
var task_progress = {}

func get_task(task_id: String) -> Dictionary:
	if tasks.has(task_id):
		return tasks[task_id]
	return {}

func add_task(task_id: String, task_data: Dictionary):
	"""Add a task definition to the manager"""
	tasks[task_id] = task_data

func start_task(task_id: String) -> bool:
	if not tasks.has(task_id):
		return false
		
	if active_tasks.has(task_id):
		return true  # Already started
	
	active_tasks[task_id] = true
	task_progress[task_id] = 0.0
	
	emit_signal("task_started", task_id)
	return true

func update_task_progress(task_id: String, progress_amount: float) -> void:
	if not active_tasks.has(task_id):
		return
		
	var task = tasks[task_id]
	var amount_required = task.get("amount_required", 1.0)
	var amount_tick = task.get("amount_tick", 1.0)
	
	task_progress[task_id] += progress_amount * amount_tick
	
	# Ensure we don't exceed 100%
	if task_progress[task_id] > amount_required:
		task_progress[task_id] = amount_required
		
	emit_signal("task_progress", task_id, task_progress[task_id] / amount_required)
	
	# Check if task is completed
	if task_progress[task_id] >= amount_required:
		complete_task(task_id)

func complete_task(task_id: String) -> void:
	if not active_tasks.has(task_id):
		return
		
	var task = tasks[task_id]
	var xp_reward = task.get("xp_reward", 10)  # Default XP reward if not specified
	
	# Mark as not active anymore
	active_tasks.erase(task_id)
	
	emit_signal("task_completed", task_id, xp_reward)
