
# ===============================================
# LabGridScene.gd
# Scene controller that integrates with SceneManager
# ===============================================

extends Node3D

@onready var lab_grid_system = $"../LabGridSystem"

func _ready():
	print("LabGridScene: Initializing lab grid scene...")
	
	# Wait for SceneManager
	var scene_manager = await SceneManagerHelper.wait_for_scene_manager(self)
	
	# Connect to lab grid system
	if lab_grid_system:
		scene_manager.connect_to_grid_system(lab_grid_system)
		
		# Connect lab-specific signals
		if lab_grid_system.has_signal("lab_artifact_activated"):
			lab_grid_system.lab_artifact_activated.connect(_on_lab_artifact_activated)
		
		if lab_grid_system.has_signal("lab_sequence_triggered"):
			lab_grid_system.lab_sequence_triggered.connect(_on_lab_sequence_triggered)
		
		if lab_grid_system.has_signal("map_generation_complete"):
			lab_grid_system.map_generation_complete.connect(_on_lab_generation_complete)
	
	# Handle scene user data
	_process_scene_user_data()
	
	print("LabGridScene: Lab grid scene ready")

func _process_scene_user_data():
	"""Process user data from staging/SceneManager"""
	var user_data = get_meta("scene_user_data", {})
	
	if user_data.has("map_name"):
		var lab_name = user_data.map_name
		print("LabGridScene: Setting lab map: %s" % lab_name)
		if lab_grid_system and "map_name" in lab_grid_system:
			lab_grid_system.map_name = lab_name
	
	if user_data.has("completion_data"):
		var completion_data = user_data.completion_data
		_handle_sequence_completion(completion_data)

func _handle_sequence_completion(completion_data: Dictionary):
	"""Handle sequence completion when returning to lab"""
	if completion_data.has("sequence_completed") and lab_grid_system:
		var completed_sequence = completion_data["sequence_completed"]
		print("LabGridScene: 🎉 Processing sequence completion: %s" % completed_sequence)
		
		# Wait for lab to be ready
		await _wait_for_lab_ready()
		
		# Complete the sequence in lab progression
		lab_grid_system.complete_sequence(completed_sequence)

func _wait_for_lab_ready():
	"""Wait for lab grid system to be ready"""
	if not lab_grid_system:
		return
	
	# Wait for generation to complete
	while not lab_grid_system.is_map_ready():
		await get_tree().process_frame
	
	# Wait one more frame for safety
	await get_tree().process_frame

func _on_lab_generation_complete():
	"""Handle lab generation completion"""
	print("LabGridScene: Lab generation complete - lab styling applied")

func _on_lab_artifact_activated(artifact_id: String):
	"""Handle lab artifact activation"""
	print("LabGridScene: Lab artifact activated: %s" % artifact_id)

func _on_lab_sequence_triggered(sequence_name: String):
	"""Handle lab sequence trigger"""
	print("LabGridScene: Lab sequence triggered: %s" % sequence_name)
	SceneManagerHelper.start_sequence(sequence_name, self)

# Debug methods
func force_complete_sequence(sequence_name: String):
	"""Force complete a sequence for testing"""
	if lab_grid_system:
		lab_grid_system.complete_sequence(sequence_name)

func reset_lab_progression():
	"""Reset lab progression for testing"""
	if lab_grid_system:
		lab_grid_system.reset_lab_progression()

func _input(event):
	# Debug keys
	if event.is_action_pressed("ui_accept"):  # Space
		print("LabGridScene: Debug - Force completing array_tutorial")
		force_complete_sequence("array_tutorial")
	
	if event.is_action_pressed("ui_cancel"):  # Escape
		print("LabGridScene: Debug - Resetting progression")
		reset_lab_progression()
