# lab_scene.gd - Simplified version with better error handling
extends Node3D

# State
var cube_triggered: bool = false
var lab_manager: LabManager = null
var scene_manager: SceneManager = null

func _ready():
	print("LabScene: Starting initialization...")
	
	# Wait a moment for everything to be ready
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Find lab manager with multiple strategies
	_find_lab_manager()
	
	if not lab_manager:
		print("LabScene: ERROR - Could not find LabManager!")
		return
	
	print("LabScene: Found LabManager: %s" % lab_manager.name)
	
	# Wait for SceneManager
	print("LabScene: Waiting for SceneManager...")
	scene_manager = await SceneManagerHelper.wait_for_scene_manager(self)
	
	if not scene_manager:
		print("LabScene: ERROR - Could not get SceneManager!")
		return
	
	print("LabScene: Got SceneManager: %s" % scene_manager.name)
	
	# Connect signals
	_connect_signals()
	
	print("LabScene: Lab scene ready!")

func _find_lab_manager():
	"""Try multiple strategies to find the LabManager"""
	var strategies = [
		# Strategy 1: Direct child
		func(): return get_node_or_null("LabManager"),
		# Strategy 2: Sibling
		func(): return get_parent().get_node_or_null("LabManager") if get_parent() else null,
		# Strategy 3: Find in tree
		func(): return get_tree().current_scene.find_child("LabManager", true, false) if get_tree() and get_tree().current_scene else null,
		# Strategy 4: Search all children
		func(): return _search_for_lab_manager(get_tree().current_scene) if get_tree() and get_tree().current_scene else null
	]
	
	for strategy in strategies:
		var found = strategy.call()
		if found and found is LabManager:
			lab_manager = found
			print("LabScene: Found LabManager using strategy")
			return
	
	print("LabScene: No LabManager found with any strategy")

func _search_for_lab_manager(node: Node) -> LabManager:
	"""Recursively search for LabManager"""
	if not node:
		return null
	
	if node is LabManager:
		return node
	
	for child in node.get_children():
		var found = _search_for_lab_manager(child)
		if found:
			return found
	
	return null

func _connect_signals():
	"""Connect to lab manager and scene manager signals"""
	if not lab_manager or not scene_manager:
		return
	
	# Connect to lab manager signals
	if lab_manager.has_signal("artifact_activated"):
		lab_manager.artifact_activated.connect(_on_artifact_activated)
		print("LabScene: Connected to artifact_activated")
	else:
		print("LabScene: WARNING - LabManager has no artifact_activated signal")
	
	if lab_manager.has_signal("progression_event"):
		lab_manager.progression_event.connect(_on_progression_event)
		print("LabScene: Connected to progression_event")
	
	# Connect lab manager to scene manager
	if scene_manager.has_method("connect_to_lab_manager"):
		scene_manager.connect_to_lab_manager(lab_manager)
		print("LabScene: Connected LabManager to SceneManager")

func _on_artifact_activated(artifact_id: String):
	"""Handle artifact activation"""
	print("LabScene: Artifact activated: %s" % artifact_id)
	
	match artifact_id:
		"rotating_cube":
			_handle_cube_activation()
		"grid_display":
			print("LabScene: Grid display activated")
		"randomness_sign":
			print("LabScene: Randomness sign activated")
			SceneManagerHelper.start_sequence("randomness_exploration", self)
		_:
			print("LabScene: Unknown artifact: %s" % artifact_id)

func _handle_cube_activation():
	"""Handle rotating cube activation"""
	if cube_triggered:
		print("LabScene: Cube already triggered")
		return
	
	cube_triggered = true
	print("LabScene: Rotating cube activated - starting array tutorial sequence")
	
	# Use SceneManagerHelper to start sequence
	SceneManagerHelper.start_sequence("array_tutorial", self)

func _on_progression_event(event_name: String, event_data: Dictionary):
	"""Handle progression events"""
	print("LabScene: Progression event: %s" % event_name)
	
	match event_name:
		"sequence_triggered":
			var sequence_name = event_data.get("sequence_name", "")
			SceneManagerHelper.start_sequence(sequence_name, self)
