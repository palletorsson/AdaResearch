# LabGridScene.gd - Updated with Progressive Map Support
extends Node3D

@onready var lab_grid_system = $"../LabGridSystem"
# No LabManager - progressive maps are handled by LabGridSystem itself

func _ready():
	print("LabGridScene: Initializing progressive lab scene...")
	
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
	
	# No LabManager in this scene - progressive maps handled by LabGridSystem
	
	# Handle scene user data and progressive map loading
	_process_scene_user_data()
	
	print("LabGridScene: Progressive lab scene ready")

func _process_scene_user_data():
	"""Process user data from staging/SceneManager with progressive map support"""
	var user_data = get_meta("scene_user_data", {})
	var staging_override = get_tree().current_scene.get_meta("lab_map_override", "")
	
	print("🔍 DEBUG: LabGridScene._process_scene_user_data() called")
	print("🔍 DEBUG: user_data = %s" % user_data)
	print("🔍 DEBUG: staging_override = '%s'" % staging_override)
	
	# ALSO check the staging node directly
	var staging_node = get_node("/root/VRStaging")
	if not staging_node:
		staging_node = get_node("/root/AdaVRStaging")
	
	var staging_lab_override = ""
	var staging_scene_data = {}
	
	if staging_node:
		staging_lab_override = staging_node.get_meta("lab_map_override", "")
		staging_scene_data = staging_node.get_meta("scene_user_data", {})
		print("🔍 DEBUG: staging_lab_override = '%s'" % staging_lab_override)
		print("🔍 DEBUG: staging_scene_data = %s" % staging_scene_data)
	
	if lab_grid_system:
		print("🔍 DEBUG: lab_grid_system found: %s" % lab_grid_system.name)
		print("🔍 DEBUG: lab_grid_system.map_name BEFORE = '%s'" % lab_grid_system.map_name)
	else:
		print("🔍 DEBUG: ❌ lab_grid_system NOT FOUND!")
	
	var map_override_applied = false
	
	# Try multiple sources for the lab map override
	var lab_map_name = ""
	
	# 1. Check staging node lab_map_override
	if not staging_lab_override.is_empty():
		lab_map_name = staging_lab_override
		print("🔍 DEBUG: Using staging lab_map_override: %s" % lab_map_name)
	# 2. Check staging scene_user_data for map_name
	elif staging_scene_data.has("map_name"):
		lab_map_name = staging_scene_data["map_name"]
		print("🔍 DEBUG: Using staging scene_user_data.map_name: %s" % lab_map_name)
	# 3. Check local user_data for lab_map_override
	elif user_data.has("lab_map_override"):
		lab_map_name = user_data["lab_map_override"]
		print("🔍 DEBUG: Using user_data.lab_map_override: %s" % lab_map_name)
	# 4. Check local user_data for map_name
	elif user_data.has("map_name"):
		lab_map_name = user_data["map_name"]
		print("🔍 DEBUG: Using user_data.map_name: %s" % lab_map_name)
	# 5. Check current scene root metadata
	elif not staging_override.is_empty():
		lab_map_name = staging_override
		print("🔍 DEBUG: Using scene root staging_override: %s" % lab_map_name)
	
	# Apply the lab map override if found
	if not lab_map_name.is_empty() and lab_grid_system and "map_name" in lab_grid_system:
		print("LabGridScene: 🎯 APPLYING LAB MAP OVERRIDE: %s" % lab_map_name)
		lab_grid_system.map_name = lab_map_name
		map_override_applied = true
		print("🔍 DEBUG: ✅ Set lab_grid_system.map_name = '%s'" % lab_map_name)
	
	if not map_override_applied:
		print("🔍 DEBUG: ⚠️ No map override found, using lab manager state")
		_use_lab_manager_state()
	
	if lab_grid_system:
		print("🔍 DEBUG: lab_grid_system.map_name AFTER = '%s'" % lab_grid_system.map_name)
	
	# Handle sequence completion when returning from other scenes
	if user_data.has("completion_data") or staging_scene_data.has("completion_data"):
		var completion_data = user_data.get("completion_data", staging_scene_data.get("completion_data", {}))
		_handle_sequence_completion(completion_data)

func _use_lab_manager_state():
	"""Use saved progression state to determine which map to load"""
	# Load saved progression from file
	var save_path = "user://lab_progression.save"
	var completed_sequences: Array[String] = []
	
	if FileAccess.file_exists(save_path):
		var file = FileAccess.open(save_path, FileAccess.READ)
		var save_data = file.get_var()
		file.close()
		
		var loaded_sequences = save_data.get("completed_sequences", [])
		for seq in loaded_sequences:
			completed_sequences.append(str(seq))
	
	# Determine map based on completed sequences
	var state_map = _determine_map_from_sequences(completed_sequences)
	print("LabGridScene: Using lab map based on completed sequences %s: %s" % [str(completed_sequences), state_map])
	
	if lab_grid_system and "map_name" in lab_grid_system:
		lab_grid_system.map_name = state_map

func _determine_map_from_sequences(completed_sequences: Array[String]) -> String:
	"""Determine which progressive lab map to load based on completed sequences"""
	# Progressive lab maps based on sequence completion
	if "advanced_concepts" in completed_sequences:
		return "Lab/map_data_complete"
	elif "geometric_algorithms" in completed_sequences:
		return "Lab/map_data_post_geometric"
	elif "randomness_exploration" in completed_sequences:
		return "Lab/map_data_post_random"
	elif "array_tutorial" in completed_sequences:
		return "Lab/map_data_post_array"
	else:
		return "Lab/map_data_init"  # Initial state

func _handle_sequence_completion(completion_data: Dictionary):
	"""Handle sequence completion when returning to lab"""
	if completion_data.has("sequence_completed"):
		var completed_sequence = completion_data["sequence_completed"]
		print("LabGridScene: 🎉 Processing sequence completion: %s" % completed_sequence)
		
		# Save the completed sequence to the progression file
		_save_sequence_completion(completed_sequence)
		
		# Determine the new progressive map to load
		var save_path = "user://lab_progression.save"
		var completed_sequences: Array[String] = []
		
		if FileAccess.file_exists(save_path):
			var file = FileAccess.open(save_path, FileAccess.READ)
			var save_data = file.get_var()
			file.close()
			
			var loaded_sequences = save_data.get("completed_sequences", [])
			for seq in loaded_sequences:
				completed_sequences.append(str(seq))
		
		var new_map = _determine_map_from_sequences(completed_sequences)
		print("LabGridScene: Should transition to map: %s" % new_map)
		
		# Force reload with the new progressive map
		if lab_grid_system and new_map != lab_grid_system.map_name:
			print("LabGridScene: 🔄 Transitioning lab from '%s' to '%s'" % [lab_grid_system.map_name, new_map])
			lab_grid_system.map_name = new_map
			
			# Trigger a reload of the lab grid system
			if lab_grid_system.has_method("reload_map_with_name"):
				lab_grid_system.reload_map_with_name(new_map)
			else:
				# Fallback: reload the scene
				get_tree().reload_current_scene()

func _save_sequence_completion(sequence_name: String):
	"""Save a completed sequence to the progression file"""
	var save_path = "user://lab_progression.save"
	var completed_sequences: Array[String] = []
	
	# Load existing data
	if FileAccess.file_exists(save_path):
		var file = FileAccess.open(save_path, FileAccess.READ)
		var save_data = file.get_var()
		file.close()
		
		var loaded_sequences = save_data.get("completed_sequences", [])
		for seq in loaded_sequences:
			completed_sequences.append(str(seq))
	
	# Add new sequence if not already completed
	if not sequence_name in completed_sequences:
		completed_sequences.append(sequence_name)
		print("LabGridScene: 📝 Saved sequence completion: %s" % sequence_name)
	
	# Save updated data
	var save_data = {
		"completed_sequences": completed_sequences,
		"timestamp": Time.get_datetime_string_from_system()
	}
	
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	file.store_var(save_data)
	file.close()

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
	print("LabGridScene: Lab generation complete")

func _on_lab_transition_complete(new_state: String):
	"""Handle lab transition completion"""
	print("LabGridScene: Lab transition complete - new state: %s" % new_state)

func _on_lab_artifact_activated(artifact_id: String):
	"""Handle lab artifact activation"""
	print("LabGridScene: Lab artifact activated: %s" % artifact_id)

func _on_lab_sequence_triggered(sequence_name: String):
	"""Handle lab sequence trigger"""
	print("LabGridScene: Lab sequence triggered: %s" % sequence_name)
	SceneManagerHelper.start_sequence(sequence_name, self)

# =============================================================================
# DEBUG METHODS
# =============================================================================

func force_complete_sequence(sequence_name: String):
	"""Force complete a sequence for testing"""
	print("LabGridScene: Force completing sequence: %s" % sequence_name)
	_save_sequence_completion(sequence_name)
	_handle_sequence_completion({"sequence_completed": sequence_name})

func reset_lab_progression():
	"""Reset lab progression for testing"""
	print("LabGridScene: Resetting lab progression")
	var save_path = "user://lab_progression.save"
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	file.store_var({"completed_sequences": [], "timestamp": Time.get_datetime_string_from_system()})
	file.close()
	
	# Reload to initial map
	if lab_grid_system:
		lab_grid_system.map_name = "Lab/map_data_init"
		if lab_grid_system.has_method("reload_map_with_name"):
			lab_grid_system.reload_map_with_name("Lab/map_data_init")
		else:
			# Fallback: reload the scene
			get_tree().reload_current_scene()

func print_lab_status():
	"""Print lab status for debugging"""
	var save_path = "user://lab_progression.save"
	var completed_sequences: Array[String] = []
	
	if FileAccess.file_exists(save_path):
		var file = FileAccess.open(save_path, FileAccess.READ)
		var save_data = file.get_var()
		file.close()
		
		var loaded_sequences = save_data.get("completed_sequences", [])
		for seq in loaded_sequences:
			completed_sequences.append(str(seq))
	
	print("=== LAB PROGRESSION STATUS ===")
	print("Completed sequences: %s" % str(completed_sequences))
	print("Current map: %s" % (lab_grid_system.map_name if lab_grid_system else "unknown"))
	print("Expected map: %s" % _determine_map_from_sequences(completed_sequences))
	print("===============================")
