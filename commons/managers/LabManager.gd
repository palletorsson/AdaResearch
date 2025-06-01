# LabManager.gd
# Central science lab hub that manages sequences and progressive artifact revelation
# Simplified version with auto-triggering rotating cube

extends Node3D
class_name LabManager

# Lab state
var unlocked_sequences: Array[String] = []
var completed_sequences: Array[String] = []
var active_artifacts: Array[String] = []

# Data loaded from JSON files
var sequences_data: Dictionary = {}
var artifacts_data: Dictionary = {}

# Data file paths
const SEQUENCES_FILE = "res://commons/maps/map_sequences.json"
const ARTIFACTS_FILE = "res://commons/artifacts/lab_artifacts.json"

# References
var sequence_manager: SequenceManager
var staging: XRToolsStaging
var lab_table: Node3D
var spawned_artifacts: Dictionary = {}
var rotating_cube: RotatingCubeArtifact

# Signals
signal sequence_started(sequence_name: String)
signal sequence_completed(sequence_name: String, rewards: Array[String])
signal artifact_unlocked(artifact_name: String)

func _ready():
	print("LabManager: Initializing simplified lab with auto-triggering cube")
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
				print("LabManager: Loaded %d sequences" % sequences_data.size())
			else:
				print("LabManager: ERROR - Failed to parse sequences JSON")
	else:
		print("LabManager: WARNING - Sequences file not found")
	
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
				print("LabManager: Loaded %d artifacts" % artifacts_data.size())
			else:
				print("LabManager: ERROR - Failed to parse artifacts JSON")
	else:
		print("LabManager: WARNING - Artifacts file not found")

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
	print("LabManager: Loading progression state")
	
	# Start with just the rotating cube that auto-triggers
	unlocked_sequences = ["array_tutorial"]
	active_artifacts = ["rotating_cube"]

func _spawn_initial_artifacts():
	print("LabManager: Spawning initial rotating cube")
	_spawn_artifact("rotating_cube")

func _spawn_artifact(artifact_name: String):
	if artifact_name in spawned_artifacts:
		print("LabManager: Artifact '%s' already spawned" % artifact_name)
		return
	
	# For rotating cube, create it directly (simplified)
	if artifact_name == "rotating_cube":
		_create_rotating_cube()
		return
	
	print("LabManager: Other artifacts will be spawned after sequences are completed")

func _create_rotating_cube():
	print("LabManager: Creating auto-triggering rotating cube")
	
	# Create rotating cube artifact
	rotating_cube = RotatingCubeArtifact.new()
	rotating_cube.name = "RotatingCube"
	rotating_cube.position = Vector3(0.0, 1.1, 0.0)  # Center of table
	
	# Connect signals
	rotating_cube.sequence_triggered.connect(_on_cube_sequence_triggered)
	rotating_cube.artifact_activated.connect(_on_cube_activated)
	
	# Add to lab table
	lab_table.add_child(rotating_cube)
	spawned_artifacts["rotating_cube"] = rotating_cube
	
	print("LabManager: Rotating cube created and will auto-trigger in 5 seconds")

func _on_cube_activated():
	print("LabManager: Rotating cube activated!")

func _on_cube_sequence_triggered(sequence_name: String):
	print("LabManager: Cube triggered sequence: %s" % sequence_name)
	start_sequence(sequence_name)

func start_sequence(sequence_name: String):
	if not sequences_data.has(sequence_name):
		print("LabManager: ERROR - Unknown sequence '%s'" % sequence_name)
		return
	
	var sequence_def = sequences_data[sequence_name]
	print("LabManager: Starting sequence '%s'" % sequence_name)
	
	# Start the sequence through the sequence manager
	if sequence_manager and staging:
		sequence_manager.start_sequence(sequence_name, sequence_def, staging)
		sequence_started.emit(sequence_name)
	else:
		print("LabManager: ERROR - Missing sequence manager or staging reference")

func _on_sequence_completed(sequence_name: String):
	print("LabManager: Sequence '%s' completed! Player returned to lab" % sequence_name)
	
	# Mark as completed
	completed_sequences.append(sequence_name)
	
	# Get rewards and spawn new artifacts
	if sequences_data.has(sequence_name):
		var sequence_def = sequences_data[sequence_name]
		var reward_artifacts = sequence_def.get("reward_artifacts", [])
		
		print("LabManager: Spawning %d reward artifacts" % reward_artifacts.size())
		for artifact_name in reward_artifacts:
			if not artifact_name in active_artifacts:
				active_artifacts.append(artifact_name)
				# TODO: Create the reward artifacts (for now just log)
				print("LabManager: Reward artifact '%s' unlocked" % artifact_name)
	
	# Check for newly unlocked sequences
	_check_and_unlock_sequences()
	
	sequence_completed.emit(sequence_name, [])

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
			print("LabManager: Unlocked new sequence '%s'" % sequence_name)

# Public API
func get_lab_status() -> Dictionary:
	return {
		"unlocked_sequences": unlocked_sequences,
		"completed_sequences": completed_sequences,
		"active_artifacts": active_artifacts,
		"completion_percentage": float(completed_sequences.size()) / float(sequences_data.size()) * 100.0
	}

func force_trigger_cube():
	"""Force the rotating cube to trigger immediately"""
	if rotating_cube:
		rotating_cube.force_trigger()

func debug_start_sequence(sequence_name: String):
	"""Debug method to start any sequence"""
	start_sequence(sequence_name) 
