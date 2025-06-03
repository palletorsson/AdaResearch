# lab_scene.gd - Updated to use SceneManagerHelper
# Inherits from XRToolsSceneBase via base.tscn (preserves VR functionality)

extends Node3D

# References
@onready var lab_manager = $"."
@onready var xr_origin = $"../XROrigin3D"

# State
var cube_triggered: bool = false

func _ready():
	print("LabScene: Initializing lab scene coordinator")
	
	# Wait for SceneManager to be ready from BaseSceneAddon
	var scene_manager = await SceneManagerHelper.wait_for_scene_manager(self)
	
	# Connect to lab manager signals
	if lab_manager:
		lab_manager.artifact_activated.connect(_on_artifact_activated)
		lab_manager.progression_event.connect(_on_progression_event)
		
		# Connect lab manager to SceneManager
		scene_manager.connect_to_lab_manager(lab_manager)
	
	print("LabScene: Lab scene ready - using base SceneManager")

func _on_artifact_activated(artifact_id: String):
	"""Handle artifact activation - make smart decisions"""
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
	print("LabScene: Grid display activated - could show array tutorial")
	# Future: Could load array visualization sequence

func _handle_randomness_activation():
	"""Handle randomness sign interaction"""
	print("LabScene: Randomness sign activated - could load randomness sequence")
	SceneManagerHelper.start_sequence("randomness_exploration", self)

func _on_progression_event(event_name: String, event_data: Dictionary):
	"""Handle progression events from artifacts"""
	print("LabScene: Progression event: %s with data: %s" % [event_name, event_data])
	
	match event_name:
		"sequence_triggered":
			var sequence_name = event_data.get("sequence_name", "")
			SceneManagerHelper.start_sequence(sequence_name, self)
