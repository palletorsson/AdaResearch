# lab_scene.gd - Scene controller for lab.tscn
# Can be attached to root "Base" node or a child "LabScene" node

extends Node3D

# References - will find these in the scene tree
var lab_manager: LabManager
var xr_origin: Node3D
var base_root: Node3D

# State
var cube_triggered: bool = false

func _ready():
	print("LabScene: Initializing lab scene coordinator")
	
	# Get references based on attachment location
	if name == "Base":
		# Script attached to root Base node
		base_root = self
		lab_manager = find_child("LabManager", true, false)
		xr_origin = find_child("XROrigin3D", true, false)
	else:
		# Script attached to child node
		base_root = get_parent()
		lab_manager = base_root.find_child("LabManager", true, false)
		xr_origin = base_root.find_child("XROrigin3D", true, false)
	
	# Debug: Print what we found
	print("LabScene: Base root: %s" % base_root.name if base_root else "null")
	print("LabScene: Lab manager found: %s" % lab_manager.name if lab_manager else "null")
	print("LabScene: Lab manager type: %s" % lab_manager.get_class() if lab_manager else "null")
	
	# Additional debug: List all children
	print("LabScene: All children of base root:")
	if base_root:
		for child in base_root.get_children():
			print("  - %s (%s)" % [child.name, child.get_class()])
	
	if not lab_manager:
		print("LabScene: ERROR - LabManager not found!")
		return
	
	# Verify it's actually a LabManager
	if not lab_manager is LabManager:
		print("LabScene: ERROR - Found node named LabManager but it's not LabManager class!")
		print("  Node type: %s" % lab_manager.get_class())
		print("  Has artifact_activated signal: %s" % lab_manager.has_signal("artifact_activated"))
		return
	
	# Wait for SceneManager to be ready
	var scene_manager = await SceneManagerHelper.wait_for_scene_manager(self)
	
	# Connect to lab manager signals
	if lab_manager.has_signal("artifact_activated"):
		lab_manager.artifact_activated.connect(_on_artifact_activated)
		print("LabScene: Connected to artifact_activated signal")
	else:
		print("LabScene: WARNING - LabManager has no artifact_activated signal")
	
	if lab_manager.has_signal("progression_event"):
		lab_manager.progression_event.connect(_on_progression_event)
		print("LabScene: Connected to progression_event signal")
	else:
		print("LabScene: WARNING - LabManager has no progression_event signal")
	
	# Connect lab manager to SceneManager
	scene_manager.connect_to_lab_manager(lab_manager)
	
	print("LabScene: Lab scene ready - using SceneManager")

func _on_artifact_activated(artifact_id: String):
	"""Handle artifact activation"""
	print("LabScene: Handling activation of artifact: %s" % artifact_id)
	
	match artifact_id:
		"rotating_cube":
			_handle_cube_activation()
		"grid_display":
			_handle_grid_display_activation()
		"randomness_sign":
			_handle_randomness_activation()
		_:
			print("LabScene: Unknown artifact activated: %s" % artifact_id)

func _handle_cube_activation():
	"""Handle rotating cube activation - start array tutorial sequence"""
	if cube_triggered:
		return
	
	cube_triggered = true
	print("LabScene: Rotating cube activated - starting array tutorial sequence")
	
	# Use SceneManagerHelper to start sequence
	SceneManagerHelper.start_sequence("array_tutorial", self)

func _handle_grid_display_activation():
	"""Handle grid display interaction"""
	print("LabScene: Grid display activated")

func _handle_randomness_activation():
	"""Handle randomness sign interaction"""
	print("LabScene: Randomness sign activated")
	SceneManagerHelper.start_sequence("randomness_exploration", self)

func _on_progression_event(event_name: String, event_data: Dictionary):
	"""Handle progression events from artifacts"""
	print("LabScene: Progression event: %s with data: %s" % [event_name, event_data])
	
	match event_name:
		"sequence_triggered":
			var sequence_name = event_data.get("sequence_name", "")
			SceneManagerHelper.start_sequence(sequence_name, self)
