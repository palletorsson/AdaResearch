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
	"""Determine which progressive lab map to load based on completed sequences using JSON config"""
	var progression_config = _load_lab_progression_config()
	
	if not progression_config:
		print("LabGridScene: ERROR - Failed to load progression config, using fallback")
		return "Lab/map_data_init"
	
	# Check debug override first
	var debug_overrides = progression_config.get("debug_overrides", {})
	var force_lab_map = debug_overrides.get("force_lab_map", null)
	if force_lab_map:
		print("LabGridScene: 🔧 DEBUG OVERRIDE - Forcing lab map: %s" % force_lab_map)
		return force_lab_map
	
	# Validate progression if enabled
	var validation_rules = progression_config.get("validation_rules", {})
	if validation_rules.get("enforce_dependencies", true):
		completed_sequences = _validate_and_fix_progression(completed_sequences, progression_config)
	
	# Check progression rules in order
	var progression_mapping = progression_config.get("progression_mapping", {})
	var rules = progression_mapping.get("rules", [])
	
	for rule in rules:
		var required_sequences = rule.get("required_sequences", [])
		var lab_map = rule.get("lab_map", "")
		
		# Check if all required sequences are completed
		var all_met = true
		for required_seq in required_sequences:
			if not str(required_seq) in completed_sequences:
				all_met = false
				break
		
		if all_met:
			print("LabGridScene: 📍 Progression rule matched: %s → %s" % [str(required_sequences), lab_map])
			return lab_map
	
	# No rules matched, use fallback
	var fallback_map = progression_mapping.get("fallback_map", "Lab/map_data_init")
	print("LabGridScene: 📍 No progression rules matched, using fallback: %s" % fallback_map)
	return fallback_map

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

func _input(event):
	"""Handle debug input for lab progression"""
	if event.is_action_pressed("ui_accept"):  # Space key
		print("🔍 Debug: Checking lab status...")
		print_lab_status()
	elif event.is_action_pressed("ui_select"):  # Shift key (or other key)
		print("🔧 Debug: Running progression fix...")
		fix_progression_issue()
	elif event.is_action_pressed("ui_cancel"):  # Escape key
		print("🔄 Debug: Resetting lab progression...")
		reset_lab_progression()
	elif Input.is_action_just_pressed("ui_home"):  # Home key - immediate force load
		print("🎯 Debug: Force loading post-array map...")
		force_load_post_array_map()

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

func fix_progression_issue():
	"""Fix the progression issue - reset to only array_tutorial if geometric_algorithms is incorrectly present"""
	var save_path = "user://lab_progression.save"
	var completed_sequences: Array[String] = []
	
	# Check current state
	if FileAccess.file_exists(save_path):
		var file = FileAccess.open(save_path, FileAccess.READ)
		var save_data = file.get_var()
		file.close()
		
		var loaded_sequences = save_data.get("completed_sequences", [])
		for seq in loaded_sequences:
			completed_sequences.append(str(seq))
	
	print("🔍 Current progression before fix: %s" % str(completed_sequences))
	
	# If geometric_algorithms is present but randomness_exploration is not, it's incorrect
	if "geometric_algorithms" in completed_sequences and "randomness_exploration" not in completed_sequences:
		print("🚨 DETECTED ISSUE: geometric_algorithms completed without randomness_exploration!")
		print("🔧 Fixing progression to correct state...")
		
		# Reset to correct progression: only array_tutorial if that's what should be completed
		var corrected_sequences = []
		if "array_tutorial" in completed_sequences:
			corrected_sequences.append("array_tutorial")
		
		var save_data = {
			"completed_sequences": corrected_sequences,
			"timestamp": Time.get_datetime_string_from_system(),
			"fixed_by_system": true
		}
		
		var file = FileAccess.open(save_path, FileAccess.WRITE)
		file.store_var(save_data)
		file.close()
		
		print("✅ Fixed progression to: %s" % str(corrected_sequences))
		print("🔄 You should now reload the lab scene to see the correct state")
		
		# Determine correct map and reload if possible
		var correct_map = _determine_map_from_sequences(corrected_sequences)
		print("📍 Correct lab map should be: %s" % correct_map)
		
		if lab_grid_system:
			lab_grid_system.map_name = correct_map
			if lab_grid_system.has_method("reload_map_with_name"):
				lab_grid_system.reload_map_with_name(correct_map)
			else:
				print("🔄 Reload the scene to apply the fix")
	else:
		print("✅ Progression looks correct, no fix needed")

func _load_lab_progression_config() -> Dictionary:
	"""Load lab progression configuration from JSON"""
	var config_path = "res://commons/maps/Lab/lab_map_progression.json"
	
	if not FileAccess.file_exists(config_path):
		print("LabGridScene: ERROR - Lab progression config not found: %s" % config_path)
		return {}
	
	var file = FileAccess.open(config_path, FileAccess.READ)
	if not file:
		print("LabGridScene: ERROR - Could not open lab progression config")
		return {}
	
	var content = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(content)
	
	if parse_result != OK:
		print("LabGridScene: ERROR - Failed to parse lab progression JSON: %s" % json.error_string)
		return {}
	
	print("LabGridScene: ✅ Loaded lab progression config")
	return json.data

func _validate_and_fix_progression(completed_sequences: Array[String], config: Dictionary) -> Array[String]:
	"""Validate progression dependencies and fix invalid sequences"""
	var dependencies = config.get("sequence_dependencies", {})
	var validation_rules = config.get("validation_rules", {})
	var auto_fix = validation_rules.get("auto_fix_invalid_progression", true)
	var log_issues = validation_rules.get("log_progression_issues", true)
	
	var valid_sequences: Array[String] = []
	var issues_found = false
	
	# Check each completed sequence for valid dependencies
	for sequence in completed_sequences:
		var required_deps = dependencies.get(str(sequence), [])
		var dependencies_met = true
		
		# Check if all dependencies are in the valid sequences list
		for dep in required_deps:
			if not str(dep) in valid_sequences:
				dependencies_met = false
				break
		
		if dependencies_met:
			valid_sequences.append(str(sequence))
		else:
			issues_found = true
			if log_issues:
				print("LabGridScene: ⚠️ PROGRESSION ISSUE: '%s' completed without dependencies %s" % [sequence, str(required_deps)])
	
	if issues_found:
		if auto_fix and log_issues:
			print("LabGridScene: 🔧 Auto-fixing progression from %s to %s" % [str(completed_sequences), str(valid_sequences)])
		elif not auto_fix:
			print("LabGridScene: ❌ Progression issues found but auto-fix disabled")
			return completed_sequences
	
	return valid_sequences

func force_load_post_array_map():
	"""Immediately force load the post-array map regardless of progression"""
	print("LabGridScene: 🎯 FORCE LOADING POST-ARRAY MAP")
	
	# Update progression to only array_tutorial
	var save_path = "user://lab_progression.save"
	var save_data = {
		"completed_sequences": ["array_tutorial"],
		"timestamp": Time.get_datetime_string_from_system(),
		"forced_by_user": true
	}
	
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	file.store_var(save_data)
	file.close()
	
	# Force load the post-array map
	var target_map = "Lab/map_data_post_array"
	print("LabGridScene: 🚀 Loading map: %s" % target_map)
	
	if lab_grid_system:
		lab_grid_system.map_name = target_map
		if lab_grid_system.has_method("reload_map_with_name"):
			lab_grid_system.reload_map_with_name(target_map)
		else:
			get_tree().reload_current_scene()
	else:
		print("LabGridScene: ❌ No lab_grid_system found, cannot reload")
	
	print("LabGridScene: ✅ Post-array map should now be loaded!")
