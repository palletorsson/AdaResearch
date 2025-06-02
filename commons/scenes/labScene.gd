# lab_scene.gd - Smart lab scene coordinator
extends Node3D

# References
@onready var lab_manager = $LabManager
@onready var xr_origin = $XROrigin3D

# State
var cube_triggered: bool = false

func _ready():
	print("LabScene: Initializing lab scene coordinator")
	
	# Wait for lab manager to initialize
	await get_tree().process_frame
	
	# Connect to lab manager signals
	if lab_manager:
		lab_manager.artifact_activated.connect(_on_artifact_activated)
		lab_manager.progression_event.connect(_on_progression_event)
	
	print("LabScene: Lab scene ready - artifacts controlled by JSON system")

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
	"""Handle rotating cube activation - load first grid map"""
	if cube_triggered:
		return
	
	cube_triggered = true
	print("LabScene: Rotating cube activated - loading first grid map")
	
	# Use VRMapDiscovery to find first map
	var discovery = VRMapDiscovery.discover_available_maps()
	var first_map = VRMapDiscovery.determine_starting_map_from_list(discovery.maps)
	
	if first_map.is_empty():
		first_map = "Tutorial_Single"
	
	print("LabScene: Loading grid scene with map: %s" % first_map)
	_load_grid_scene(first_map)

func _handle_grid_display_activation():
	"""Handle grid display interaction"""
	print("LabScene: Grid display activated - could show array tutorial")
	# Future: Could load array visualization sequence

func _handle_randomness_activation():
	"""Handle randomness sign interaction"""
	print("LabScene: Randomness sign activated - could load randomness sequence")
	# Future: Could load randomness exploration sequence

func _on_progression_event(event_name: String, event_data: Dictionary):
	"""Handle progression events from artifacts"""
	print("LabScene: Progression event: %s with data: %s" % [event_name, event_data])
	
	match event_name:
		"sequence_triggered":
			var artifact_id = event_data.get("artifact_id", "")
			var sequence_name = event_data.get("sequence_name", "")
			_handle_sequence_trigger(artifact_id, sequence_name)

func _handle_sequence_trigger(artifact_id: String, sequence_name: String):
	"""Handle sequence triggers from artifacts"""
	print("LabScene: Sequence '%s' triggered by '%s'" % [sequence_name, artifact_id])
	
	# This is where sequence manager integration would go
	# For now, just load first grid map
	if artifact_id == "rotating_cube":
		_handle_cube_activation()

func _load_grid_scene(map_name: String):
	"""Load grid scene with specified map"""
	var staging = get_meta("staging_ref", null)
	if staging and staging.has_method("load_scene"):
		var grid_data = {
			"map_name": map_name,
			"system_mode": "educational_grid",
			"return_to": "lab"
		}
		staging.load_scene("res://commons/scenes/grid.tscn", grid_data)
	else:
		print("LabScene: ERROR - No staging reference")
