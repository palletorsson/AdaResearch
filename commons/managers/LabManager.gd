# LabManager.gd
# Central science lab hub that manages sequences and progressive artifact revelation
extends Node3D
class_name LabManager

# Lab state
var unlocked_sequences: Array[String] = []
var completed_sequences: Array[String] = []
var active_artifacts: Array[String] = []

# Data loaded from JSON files
var sequences_data: Dictionary = {}
var artifacts_data: Dictionary = {}
var progression_rules: Dictionary = {}

# Data file paths
const SEQUENCES_FILE = "res://commons/maps/map_sequences.json"
const ARTIFACTS_FILE = "res://commons/artifacts/lab_artifacts.json"

# References
var sequence_manager: SequenceManager
var staging: XRToolsStaging
var lab_table: Node3D
var spawned_artifacts: Dictionary = {}

# Signals
signal sequence_started(sequence_name: String)
signal sequence_completed(sequence_name: String, rewards: Array[String])
signal artifact_unlocked(artifact_name: String)
signal lab_fully_revealed()

func _ready():
	print("LabManager: Initializing science lab")
	_load_data_files()
	_setup_lab()
	_load_progression_state()
	_spawn_initial_artifacts()

# Load data from external JSON files
func _load_data_files():
	print("LabManager: Loading data from external files")
	
	# Load sequences data
	if ResourceLoader.exists(SEQUENCES_FILE):
		var sequences_file = FileAccess.open(SEQUENCES_FILE, FileAccess.READ)
		if sequences_file:
			var json_string = sequences_file.get_as_text()
			sequences_file.close()
			
			var json = JSON.new()
			var parse_result = json.parse(json_string)
			
			if parse_result == OK:
				var data = json.data
				sequences_data = data.get("sequences", {})
				progression_rules = data.get("progression_rules", {})
				print("LabManager: Loaded %d sequences from %s" % [sequences_data.size(), SEQUENCES_FILE])
			else:
				print("LabManager: ERROR - Failed to parse sequences JSON: %s" % json.error_string)
	else:
		print("LabManager: WARNING - Sequences file not found: %s" % SEQUENCES_FILE)
	
	# Load artifacts data  
	if ResourceLoader.exists(ARTIFACTS_FILE):
		var artifacts_file = FileAccess.open(ARTIFACTS_FILE, FileAccess.READ)
		if artifacts_file:
			var json_string = artifacts_file.get_as_text()
			artifacts_file.close()
			
			var json = JSON.new()
			var parse_result = json.parse(json_string)
			
			if parse_result == OK:
				var data = json.data
				artifacts_data = data.get("artifacts", {})
				print("LabManager: Loaded %d artifacts from %s" % [artifacts_data.size(), ARTIFACTS_FILE])
			else:
				print("LabManager: ERROR - Failed to parse artifacts JSON: %s" % json.error_string)
	else:
		print("LabManager: WARNING - Artifacts file not found: %s" % ARTIFACTS_FILE)

func initialize_with_staging(staging_ref: XRToolsStaging):
	staging = staging_ref
	
	# Create sequence manager
	sequence_manager = SequenceManager.new()
	sequence_manager.name = "SequenceManager"
	add_child(sequence_manager)
	
	# Connect signals
	sequence_manager.sequence_completed.connect(_on_sequence_completed)
	
	print("LabManager: Initialized with staging system")

func _setup_lab():
	# Find or create lab table
	lab_table = find_child("LabTable", true, false)
	if not lab_table:
		lab_table = Node3D.new()
		lab_table.name = "LabTable"
		add_child(lab_table)
		print("LabManager: Created lab table")

func _load_progression_state():
	# Load saved progression state
	# TODO: Implement save/load system
	print("LabManager: Loading progression state")
	
	# For now, start with just the rotating cube
	unlocked_sequences = ["array_tutorial"]
	active_artifacts = ["rotating_cube"]

func _spawn_initial_artifacts():
	print("LabManager: Spawning initial artifacts")
	
	for artifact_name in active_artifacts:
		_spawn_artifact(artifact_name)

func _spawn_artifact(artifact_name: String):
	if artifact_name in spawned_artifacts:
		print("LabManager: Artifact '%s' already spawned" % artifact_name)
		return
	
	if not artifacts_data.has(artifact_name):
		print("LabManager: ERROR - Unknown artifact '%s'" % artifact_name)
		return
	
	var artifact_def = artifacts_data[artifact_name]
	var scene_path = artifact_def.scene
	
	# Load artifact scene
	if ResourceLoader.exists(scene_path):
		var artifact_scene = load(scene_path)
		var artifact_instance = artifact_scene.instantiate()
		
		# Position the artifact (convert array to Vector3)
		var pos_array = artifact_def.position
		artifact_instance.position = Vector3(pos_array[0], pos_array[1], pos_array[2])
		
		var rot_array = artifact_def.rotation
		artifact_instance.rotation_degrees = Vector3(rot_array[0], rot_array[1], rot_array[2])
		
		# Set up interaction
		_setup_artifact_interaction(artifact_instance, artifact_name, artifact_def)
		
		# Add to lab table
		lab_table.add_child(artifact_instance)
		spawned_artifacts[artifact_name] = artifact_instance
		
		print("LabManager: Spawned artifact '%s' at %s" % [artifact_name, artifact_instance.position])
		artifact_unlocked.emit(artifact_name)
	else:
		print("LabManager: WARNING - Artifact scene not found: %s" % scene_path)
		# Create a placeholder
		_create_placeholder_artifact(artifact_name, artifact_def)

func _create_placeholder_artifact(artifact_name: String, artifact_def: Dictionary):
	# Create a simple placeholder cube
	var placeholder = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = Vector3(0.2, 0.2, 0.2)
	placeholder.mesh = mesh
	
	# Create material based on artifact type
	var material = StandardMaterial3D.new()
	if artifact_def.interaction == "touch_to_start_sequence":
		material.albedo_color = Color.CYAN
		material.emission = Color.CYAN * 0.3
	else:
		material.albedo_color = Color.YELLOW
		material.emission = Color.YELLOW * 0.2
	
	placeholder.material_override = material
	
	# Position the placeholder (convert array to Vector3)
	var pos_array = artifact_def.position
	placeholder.position = Vector3(pos_array[0], pos_array[1], pos_array[2])
	
	var rot_array = artifact_def.rotation
	placeholder.rotation_degrees = Vector3(rot_array[0], rot_array[1], rot_array[2])
	
	# Set up interaction
	_setup_artifact_interaction(placeholder, artifact_name, artifact_def)
	
	lab_table.add_child(placeholder)
	spawned_artifacts[artifact_name] = placeholder
	
	print("LabManager: Created placeholder for '%s'" % artifact_name)

func _setup_artifact_interaction(artifact: Node3D, artifact_name: String, artifact_def: Dictionary):
	# Add interaction area
	var interaction_area = Area3D.new()
	interaction_area.name = "InteractionArea"
	
	var collision_shape = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = 0.3
	collision_shape.shape = shape
	
	interaction_area.add_child(collision_shape)
	artifact.add_child(interaction_area)
	
	# Connect interaction signals
	interaction_area.body_entered.connect(_on_artifact_touched.bind(artifact_name, artifact_def))
	
	# Store metadata
	artifact.set_meta("artifact_name", artifact_name)
	artifact.set_meta("artifact_def", artifact_def)

func _on_artifact_touched(artifact_name: String, artifact_def: Dictionary, body: Node3D):
	# Check if it's the player
	if not _is_player_body(body):
		return
	
	print("LabManager: Player touched artifact '%s'" % artifact_name)
	
	match artifact_def.interaction:
		"touch_to_start_sequence":
			var sequence_name = artifact_def.sequence
			if sequence_name and _can_start_sequence(sequence_name):
				start_sequence(sequence_name)
		"pickup_and_examine":
			_examine_artifact(artifact_name, artifact_def)

func _is_player_body(body: Node3D) -> bool:
	# Check if the body belongs to the player
	return body.name.contains("Hand") or body.get_parent().name.contains("Hand")

func _can_start_sequence(sequence_name: String) -> bool:
	if sequence_name in completed_sequences:
		print("LabManager: Sequence '%s' already completed" % sequence_name)
		return false
	
	if not sequence_name in unlocked_sequences:
		print("LabManager: Sequence '%s' not unlocked yet" % sequence_name)
		return false
	
	if not sequences_data.has(sequence_name):
		print("LabManager: ERROR - Unknown sequence '%s'" % sequence_name)
		return false
	
	var sequence_def = sequences_data[sequence_name]
	for prereq in sequence_def.get("prerequisites", []):
		if not prereq in completed_sequences:
			print("LabManager: Sequence '%s' requires '%s' to be completed first" % [sequence_name, prereq])
			return false
	
	return true

func start_sequence(sequence_name: String):
	if not sequences_data.has(sequence_name):
		print("LabManager: ERROR - Unknown sequence '%s'" % sequence_name)
		return
	
	var sequence_def = sequences_data[sequence_name]
	print("LabManager: Starting sequence '%s'" % sequence_name)
	
	# Start the sequence
	sequence_manager.start_sequence(sequence_name, sequence_def, staging)
	sequence_started.emit(sequence_name)

func _on_sequence_completed(sequence_name: String):
	print("LabManager: Sequence '%s' completed!" % sequence_name)
	
	# Mark as completed
	completed_sequences.append(sequence_name)
	
	# Get rewards
	if not sequences_data.has(sequence_name):
		return
		
	var sequence_def = sequences_data[sequence_name]
	var reward_artifacts = sequence_def.get("reward_artifacts", [])
	
	# Spawn reward artifacts
	for artifact_name in reward_artifacts:
		if not artifact_name in active_artifacts:
			active_artifacts.append(artifact_name)
			_spawn_artifact(artifact_name)
	
	# Unlock new sequences if prerequisites are met
	_check_and_unlock_sequences()
	
	# Save progression
	_save_progression_state()
	
	sequence_completed.emit(sequence_name, reward_artifacts)
	
	# Check if lab is fully revealed
	if _is_lab_fully_revealed():
		lab_fully_revealed.emit()

func _check_and_unlock_sequences():
	for sequence_name in sequences_data.keys():
		if sequence_name in unlocked_sequences:
			continue
		
		var sequence_def = sequences_data[sequence_name]
		var can_unlock = true
		
		for prereq in sequence_def.get("prerequisites", []):
			if not prereq in completed_sequences:
				can_unlock = false
				break
		
		if can_unlock:
			unlocked_sequences.append(sequence_name)
			
			# Spawn trigger artifact if not already active
			var trigger_artifact = sequence_def.get("trigger_artifact", "")
			if trigger_artifact and not trigger_artifact in active_artifacts:
				active_artifacts.append(trigger_artifact)
				_spawn_artifact(trigger_artifact)
			
			print("LabManager: Unlocked sequence '%s'" % sequence_name)

func _is_lab_fully_revealed() -> bool:
	return completed_sequences.size() == sequences_data.size()

func _examine_artifact(artifact_name: String, artifact_def: Dictionary):
	print("LabManager: Examining artifact '%s': %s" % [artifact_name, artifact_def.description])
	# TODO: Show artifact examination UI

func _save_progression_state():
	# TODO: Implement save system
	print("LabManager: Saving progression state")

# Public API
func get_lab_status() -> Dictionary:
	return {
		"unlocked_sequences": unlocked_sequences,
		"completed_sequences": completed_sequences,
		"active_artifacts": active_artifacts,
		"completion_percentage": float(completed_sequences.size()) / float(sequences_data.size()) * 100.0
	}

func force_unlock_sequence(sequence_name: String):
	if not sequence_name in unlocked_sequences:
		unlocked_sequences.append(sequence_name)
		
		if sequences_data.has(sequence_name):
			var sequence_def = sequences_data[sequence_name]
			var trigger_artifact = sequence_def.get("trigger_artifact", "")
			if trigger_artifact and not trigger_artifact in active_artifacts:
				active_artifacts.append(trigger_artifact)
				_spawn_artifact(trigger_artifact)

func debug_spawn_artifact(artifact_name: String):
	if not artifact_name in active_artifacts:
		active_artifacts.append(artifact_name)
		_spawn_artifact(artifact_name)

# Data access methods
func get_sequences_data() -> Dictionary:
	return sequences_data

func get_artifacts_data() -> Dictionary:
	return artifacts_data

func get_progression_rules() -> Dictionary:
	return progression_rules 
