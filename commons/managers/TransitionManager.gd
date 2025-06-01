# TransitionManager.gd
# Handles all scene transitions between lab hub and sequences
# Keeps them completely decoupled

extends Node
class_name TransitionManager

# Current state
var current_location: String = "lab"
var return_data: Dictionary = {}
var sequence_progress: Dictionary = {}

# References
var lab_hub: LabHubManager
var sequence_manager: SequenceManager
var staging: XRToolsStaging
var grid_system: Node3D

# Signals
signal location_changed(from: String, to: String)
signal sequence_started(sequence_id: String)
signal sequence_completed(sequence_id: String, artifacts: Array)
signal returned_to_lab()

func _ready():
	print("TransitionManager: Initializing transition system")

func initialize(staging_ref: XRToolsStaging, grid_ref: Node3D):
	"""Initialize with necessary references"""
	staging = staging_ref
	grid_system = grid_ref
	
	print("TransitionManager: Initialized with staging and grid system")

func set_lab_hub(hub: LabHubManager):
	"""Connect to the lab hub"""
	lab_hub = hub
	
	# Connect lab hub signals
	lab_hub.tutorial_requested.connect(_on_tutorial_requested)
	lab_hub.portal_activated.connect(_on_portal_activated)
	
	print("TransitionManager: Connected to lab hub")

func set_sequence_manager(seq_manager: SequenceManager):
	"""Connect to the sequence manager"""
	sequence_manager = seq_manager
	
	# Connect sequence manager signals
	sequence_manager.sequence_completed.connect(_on_sequence_completed)
	
	print("TransitionManager: Connected to sequence manager")

func _on_tutorial_requested():
	"""Handle tutorial request from lab"""
	print("TransitionManager: Tutorial requested - starting array tutorial")
	go_to_sequence("array_tutorial")

func _on_portal_activated(sequence_id: String):
	"""Handle portal activation from lab"""
	print("TransitionManager: Portal activated for sequence '%s'" % sequence_id)
	go_to_sequence(sequence_id)

func go_to_sequence(sequence_id: String):
	"""Transition from lab to a sequence"""
	print("TransitionManager: Transitioning to sequence '%s'" % sequence_id)
	
	# Save lab state before leaving
	_save_lab_state()
	
	# Update location
	var previous_location = current_location
	current_location = sequence_id
	
	# Load the sequence
	if _load_sequence(sequence_id):
		location_changed.emit(previous_location, sequence_id)
		sequence_started.emit(sequence_id)
	else:
		print("TransitionManager: ERROR - Failed to load sequence '%s'" % sequence_id)
		current_location = previous_location

func return_to_lab(collected_artifacts: Array = []):
	"""Return from sequence to lab"""
	print("TransitionManager: Returning to lab with %d artifacts" % collected_artifacts.size())
	
	# Process collected artifacts
	for artifact_data in collected_artifacts:
		if lab_hub:
			lab_hub.add_collected_artifact(artifact_data)
	
	# Update location
	var previous_location = current_location
	current_location = "lab"
	
	# Load lab scene
	if _load_lab():
		location_changed.emit(previous_location, "lab")
		returned_to_lab.emit()
		
		# Restore lab state
		_restore_lab_state()
	else:
		print("TransitionManager: ERROR - Failed to return to lab")

func _load_sequence(sequence_id: String) -> bool:
	"""Load a specific sequence"""
	if not sequence_manager:
		print("TransitionManager: No sequence manager available")
		return false
	
	# Get sequence data
	var sequences_data = _load_sequences_data()
	if not sequences_data.has(sequence_id):
		print("TransitionManager: Unknown sequence '%s'" % sequence_id)
		return false
	
	var sequence_def = sequences_data[sequence_id]
	print("TransitionManager: Loading sequence '%s'" % sequence_def.get("name", sequence_id))
	
	# Start the sequence
	sequence_manager.start_sequence(sequence_id, sequence_def, staging)
	return true

func _load_lab() -> bool:
	"""Load the lab scene"""
	if not grid_system:
		print("TransitionManager: No grid system available")
		return false
	
	print("TransitionManager: Loading lab scene")
	
	# Load lab map
	if grid_system.has_method("load_map"):
		grid_system.load_map("Lab")
		return true
	elif grid_system.has_method("set") and "map_name" in grid_system:
		grid_system.set("map_name", "Lab")
		if grid_system.has_method("generate_layout"):
			grid_system.generate_layout()
		return true
	
	print("TransitionManager: Grid system doesn't support map loading")
	return false

func _load_sequences_data() -> Dictionary:
	"""Load sequence definitions"""
	const SEQUENCES_FILE = "res://commons/maps/map_sequences.json"
	
	if not ResourceLoader.exists(SEQUENCES_FILE):
		print("TransitionManager: Sequences file not found")
		return {}
	
	var file = FileAccess.open(SEQUENCES_FILE, FileAccess.READ)
	if not file:
		print("TransitionManager: Failed to open sequences file")
		return {}
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		print("TransitionManager: Failed to parse sequences JSON")
		return {}
	
	return json.data.get("sequences", {})

func _save_lab_state():
	"""Save current lab state before leaving"""
	if not lab_hub:
		return
	
	return_data = {
		"lab_status": lab_hub.get_lab_status(),
		"player_position": _get_player_position(),
		"timestamp": Time.get_unix_time_from_system()
	}
	
	print("TransitionManager: Lab state saved")

func _restore_lab_state():
	"""Restore lab state after returning"""
	if return_data.is_empty():
		return
	
	# TODO: Restore player position and other state
	print("TransitionManager: Lab state restored")
	
	# Clear return data
	return_data.clear()

func _get_player_position() -> Vector3:
	"""Get current player position"""
	# TODO: Get actual player position from XR system
	return Vector3.ZERO

func _on_sequence_completed(sequence_id: String):
	"""Handle sequence completion"""
	print("TransitionManager: Sequence '%s' completed" % sequence_id)
	
	# Determine what artifacts were collected
	var collected_artifacts = _get_sequence_rewards(sequence_id)
	
	# Return to lab with artifacts
	return_to_lab(collected_artifacts)
	
	sequence_completed.emit(sequence_id, collected_artifacts)

func _get_sequence_rewards(sequence_id: String) -> Array:
	"""Get artifacts that should be awarded for completing sequence"""
	var sequences_data = _load_sequences_data()
	if not sequences_data.has(sequence_id):
		return []
	
	var sequence_def = sequences_data[sequence_id]
	var reward_artifacts = sequence_def.get("reward_artifacts", [])
	
	# Convert artifact names to artifact data
	var artifact_objects = []
	for artifact_name in reward_artifacts:
		var artifact_data = {
			"id": artifact_name,
			"name": artifact_name.replace("_", " ").capitalize(),
			"description": "Earned from completing %s" % sequence_def.get("name", sequence_id),
			"source_sequence": sequence_id,
			"unlock_time": Time.get_unix_time_from_system()
		}
		artifact_objects.append(artifact_data)
	
	return artifact_objects

# Public API
func get_current_location() -> String:
	return current_location

func is_in_lab() -> bool:
	return current_location == "lab"

func is_in_sequence() -> bool:
	return current_location != "lab"

func get_available_sequences() -> Array[String]:
	"""Get list of available sequences"""
	var sequences_data = _load_sequences_data()
	return sequences_data.keys()

func can_access_sequence(sequence_id: String) -> bool:
	"""Check if player can access a sequence"""
	if not lab_hub:
		return false
	
	var sequences_data = _load_sequences_data()
	if not sequences_data.has(sequence_id):
		return false
	
	var sequence_def = sequences_data[sequence_id]
	var requirements = sequence_def.get("prerequisites", [])
	
	# Check if all requirements are met
	for req in requirements:
		if not lab_hub.has_artifact(req):
			return false
	
	return true

func force_return_to_lab():
	"""Force return to lab (for debugging)"""
	print("TransitionManager: Force returning to lab")
	return_to_lab() 