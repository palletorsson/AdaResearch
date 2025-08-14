# LabGridSystem.gd - FIXED to respect progressive map files
extends GridSystem
class_name LabGridSystem

# Lab-specific styling
@export var lab_mode: bool = true
@export var lab_cube_color: Color = Color(0.95, 0.95, 0.98, 1.0)  # Off-white
@export var lab_ambient_color: Color = Color(0.9, 0.9, 1.0, 0.3)  # Cool lab lighting

# Progressive map support
var is_progressive_map: bool = false
var progression_state: String = "initial"

# Lab progression integration (keep for backwards compatibility)
var completed_sequences: Array[String] = []
var unlocked_artifacts: Array[String] = []

# Additional lab signals
signal lab_artifact_activated(artifact_id: String)
signal lab_sequence_triggered(sequence_name: String)
 
var show_grid

func _ready():
	print("LabGridSystem: Initializing lab variant of grid system...")
	
	# Set default map_name for lab if not already set
	if map_name.is_empty() or map_name == "Tutorial_Start":
		map_name = "Lab"
		print("LabGridSystem: Set default map_name to 'Lab'")
	
	# Check if this is a progressive map
	_check_for_progressive_map()
	
	# Initialize unlocked artifacts with default (only for non-progressive maps)
	if not is_progressive_map and unlocked_artifacts.is_empty():
		unlocked_artifacts.append("rotating_cube")
		print("LabGridSystem: Initialized with default unlocked artifact: rotating_cube")
	
	# Set lab-specific defaults
	if lab_mode:
		_apply_lab_styling()
	
	# Load lab progression (only for non-progressive maps)
	if not is_progressive_map:
		_load_lab_progression()
	
	# Call parent ready
	super()

func _check_for_progressive_map():
	"""Check if this is a progressive map file"""
	if map_name.begins_with("Lab/map_data_"):
		is_progressive_map = true
		
		# Extract progression state from map name
		var map_file = map_name.substr(4)  # Remove "Lab/" prefix
		match map_file:
			"map_data_init":
				progression_state = "initial"
			"map_data_post_array":
				progression_state = "post_array_tutorial"
			"map_data_post_random":
				progression_state = "post_randomness_exploration"
			"map_data_post_geometric":
				progression_state = "post_geometric_algorithms"
			"map_data_complete":
				progression_state = "all_complete"
			_:
				progression_state = "initial"
		
		print("LabGridSystem: ✅ Progressive map detected - state: %s" % progression_state)
	else:
		is_progressive_map = false
		progression_state = "initial"
		print("LabGridSystem: Standard lab map - using legacy progression system")

func _apply_lab_styling():
	"""Apply lab-specific visual styling"""
	print("LabGridSystem: Applying lab styling - off-white cubes")
	
	# Override show_grid to false for cleaner lab look
	show_grid = false
	
	# Connect to generation complete to apply lab materials
	if not map_generation_complete.is_connected(_on_lab_generation_complete):
		map_generation_complete.connect(_on_lab_generation_complete)

func _on_lab_generation_complete():
	"""Apply lab styling after grid generation"""
	print("LabGridSystem: Applying lab materials to generated cubes...")
	
	# Apply lab cube materials
	_apply_lab_cube_materials()
	
	# Apply lab lighting
	_apply_lab_lighting()
	
	# FIXED: Only filter artifacts if NOT using progressive maps
	if not is_progressive_map:
		print("LabGridSystem: Using legacy artifact filtering")
		_filter_artifacts_by_progression()
	else:
		print("LabGridSystem: ✅ Progressive map - artifacts already defined in JSON, skipping filtering")

func _apply_lab_cube_materials():
	"""Apply lab styling to all grid cubes while preserving grid shader effect"""
	if not structure_component:
		return
	
	var cube_positions = structure_component.get_all_cube_positions()
	print("LabGridSystem: Applying lab materials to %d cubes" % cube_positions.size())
	
	for position in cube_positions:
		var cube = structure_component.get_cube_at(position.x, position.y, position.z)
		if cube:
			_apply_lab_material_to_cube(cube)

func _apply_lab_material_to_cube(cube: Node3D):
	"""Apply lab styling to cube while keeping grid shader"""
	# Find the mesh instance in the cube
	var mesh_instance = _find_mesh_instance_in_cube(cube)
	if not mesh_instance:
		return
	
	# Check if it already has a shader material
	var current_material = mesh_instance.material_override
	if current_material and current_material is ShaderMaterial:
		# Duplicate the shader material to make it unique for this cube
		var lab_shader_material = current_material.duplicate() as ShaderMaterial
		
		# Update shader parameters for lab styling
		lab_shader_material.set_shader_parameter("modelColor", lab_cube_color)
		lab_shader_material.set_shader_parameter("wireframeColor", Color(0.7, 0.7, 0.7, 1.0))  # Gray wireframe
		lab_shader_material.set_shader_parameter("emissionColor", Color(0.6, 0.6, 0.6, 1.0))   # Gray emission
		lab_shader_material.set_shader_parameter("emission_strength", 0.5)  # Subtle emission
		lab_shader_material.set_shader_parameter("modelOpacity", 0.95)  # Slightly transparent
		
		# Apply the modified shader material
		mesh_instance.material_override = lab_shader_material
	else:
		# Fallback: create new shader material if none exists
		var lab_shader_material = ShaderMaterial.new()
		var grid_shader = load("res://commons/resourses/shaders/Grid.gdshader")
		lab_shader_material.shader = grid_shader
		
		# Set lab-appropriate shader parameters
		lab_shader_material.set_shader_parameter("modelColor", lab_cube_color)
		lab_shader_material.set_shader_parameter("wireframeColor", Color(0.7, 0.7, 0.7, 1.0))  # Gray wireframe
		lab_shader_material.set_shader_parameter("emissionColor", Color(0.6, 0.6, 0.6, 1.0))   # Gray emission
		lab_shader_material.set_shader_parameter("width", 8.0)
		lab_shader_material.set_shader_parameter("blur", 0.5)
		lab_shader_material.set_shader_parameter("emission_strength", 0.5)  # Subtle emission
		lab_shader_material.set_shader_parameter("modelOpacity", 0.95)
		
		mesh_instance.material_override = lab_shader_material

func _find_mesh_instance_in_cube(cube: Node3D) -> MeshInstance3D:
	"""Find MeshInstance3D in cube hierarchy"""
	# Check if cube itself is a MeshInstance3D
	if cube is MeshInstance3D:
		return cube as MeshInstance3D
	
	# Search children recursively
	for child in cube.get_children():
		if child is MeshInstance3D:
			return child as MeshInstance3D
		
		# Check grandchildren (for nested structures)
		var nested_mesh = _find_mesh_instance_in_cube(child)
		if nested_mesh:
			return nested_mesh
	
	return null

func _apply_lab_lighting():
	"""Apply lab-appropriate lighting"""
	print("LabGridSystem: Applying lab lighting")
	
	# Find world environment
	var world_env = get_tree().current_scene.find_child("WorldEnvironment", true, false)
	if world_env and world_env.environment:
		var env = world_env.environment
		
		# Apply lighting based on progression state
		if is_progressive_map:
			_apply_progressive_lighting(env)
		else:
			# Default lab lighting
			env.ambient_light_color = lab_ambient_color
			env.ambient_light_energy = 0.4
		
		print("LabGridSystem: Lab lighting applied for state: %s" % progression_state)

func _apply_progressive_lighting(env: Environment):
	"""Apply lighting based on progression state"""
	match progression_state:
		"initial":
			env.ambient_light_color = Color(0.1, 0.1, 0.2)
			env.ambient_light_energy = 0.1
		"post_array_tutorial":
			env.ambient_light_color = Color(0.2, 0.2, 0.3)
			env.ambient_light_energy = 0.2
		"post_randomness_exploration":
			env.ambient_light_color = Color(0.3, 0.3, 0.4)
			env.ambient_light_energy = 0.3
		"post_geometric_algorithms":
			env.ambient_light_color = Color(0.4, 0.4, 0.5)
			env.ambient_light_energy = 0.4
		"all_complete":
			env.ambient_light_color = Color(0.5, 0.5, 0.6)
			env.ambient_light_energy = 0.5
		_:
			env.ambient_light_color = lab_ambient_color
			env.ambient_light_energy = 0.4

func _load_lab_progression():
	"""Load lab progression state (legacy system only)"""
	if is_progressive_map:
		print("LabGridSystem: Skipping legacy progression load - using progressive map")
		return
	
	var save_path = "user://lab_progression.save"
	
	if FileAccess.file_exists(save_path):
		var file = FileAccess.open(save_path, FileAccess.READ)
		var save_data = file.get_var()
		file.close()
		
		# Properly cast arrays to typed arrays
		var loaded_sequences = save_data.get("completed_sequences", [])
		var loaded_artifacts = save_data.get("unlocked_artifacts", ["rotating_cube"])
		
		completed_sequences.clear()
		for seq in loaded_sequences:
			completed_sequences.append(str(seq))
		
		unlocked_artifacts.clear()
		for artifact in loaded_artifacts:
			unlocked_artifacts.append(str(artifact))
		
		print("LabGridSystem: Loaded lab progression - unlocked: %s" % str(unlocked_artifacts))
	else:
		print("LabGridSystem: Starting fresh lab progression")

func _save_lab_progression():
	"""Save lab progression state (legacy system only)"""
	if is_progressive_map:
		return  # Don't save for progressive maps
	
	var save_data = {
		"completed_sequences": completed_sequences,
		"unlocked_artifacts": unlocked_artifacts,
		"timestamp": Time.get_datetime_string_from_system()
	}
	
	var file = FileAccess.open("user://lab_progression.save", FileAccess.WRITE)
	file.store_var(save_data)
	file.close()

func _filter_artifacts_by_progression():
	"""Filter interactables based on progression (LEGACY SYSTEM ONLY)"""
	# Disabled per project setup: always show all artifacts in legacy maps
	print("LabGridSystem: Legacy filtering disabled - showing all artifacts")
	return

# PROGRESSION MANAGEMENT (Legacy system only)

func complete_sequence(sequence_name: String):
	"""Complete a sequence and unlock new artifacts (LEGACY SYSTEM ONLY)"""
	if is_progressive_map:
		print("LabGridSystem: Sequence completion handled by LabManager for progressive maps")
		return
	
	if sequence_name in completed_sequences:
		return
	
	completed_sequences.append(sequence_name)
	print("LabGridSystem: 🎉 Sequence completed: %s" % sequence_name)
	
	# Determine what to unlock
	var newly_unlocked = _get_artifacts_to_unlock(sequence_name)
	
	for artifact_id in newly_unlocked:
		if not artifact_id in unlocked_artifacts:
			unlocked_artifacts.append(artifact_id)
			print("LabGridSystem: ✨ Unlocked artifact: %s" % artifact_id)
	
	# Save progression
	_save_lab_progression()
	
	# Update visible artifacts
	if newly_unlocked.size() > 0:
		_filter_artifacts_by_progression()
		_show_unlock_effects(newly_unlocked)

func _get_artifacts_to_unlock(sequence_name: String) -> Array[String]:
	"""Get artifacts to unlock for completing a sequence (LEGACY)"""
	match sequence_name:
		"array_tutorial":
			return ["xyz_coordinates", "grid_display"]
		"randomness_exploration":
			return ["probability_sphere", "randomness_sign"]
		"geometric_algorithms":
			return ["disco_floor"]
		_:
			return []

func _show_unlock_effects(unlocked_artifacts_list: Array[String]):
	"""Show visual effects for newly unlocked artifacts"""
	if not interactables_component:
		return
	
	print("LabGridSystem: Showing unlock effects for: %s" % str(unlocked_artifacts_list))
	
	var interactable_positions = interactables_component.get_all_interactable_positions()
	
	for position in interactable_positions:
		var interactable = interactables_component.get_interactable_at(position.x, position.y, position.z)
		if interactable:
			var artifact_lookup_name = interactable.get_meta("artifact_lookup_name", "")
			
			if artifact_lookup_name in unlocked_artifacts_list:
				interactable.visible = true
				_play_unlock_effect(interactable)

func _play_unlock_effect(artifact: Node3D):
	"""Play unlock effect for an artifact"""
	print("LabGridSystem: ✨ Playing unlock effect")
	
	# Simple scale-up effect
	var original_scale = artifact.scale
	var tween = create_tween()
	
	# Scale down then up for "pop" effect
	tween.tween_property(artifact, "scale", original_scale * 0.1, 0.2)
	tween.tween_property(artifact, "scale", original_scale * 1.2, 0.3)
	tween.tween_property(artifact, "scale", original_scale, 0.2)

# OVERRIDE INTERACTABLE ACTIVATION

func _on_interactable_activated(object_id: String, position: Vector3, data: Dictionary):
	"""Override interactable activation to add lab-specific handling"""
	print("LabGridSystem: Lab interactable activated: %s" % object_id)
	
	# Check if it's an artifact activation
	var artifact_lookup_name = data.get("lookup_name", object_id)
	
	# Emit lab-specific signals
	lab_artifact_activated.emit(artifact_lookup_name)
	
	# Handle specific lab artifacts
	match artifact_lookup_name:
		"rotating_cube":
			print("LabGridSystem: 🎯 Rotating cube activated - triggering array tutorial")
			lab_sequence_triggered.emit("array_tutorial")
		"randomness_sign":
			print("LabGridSystem: 🎯 Randomness sign activated - triggering randomness exploration")
			lab_sequence_triggered.emit("randomness_exploration")
		_:
			# Call parent method for normal handling
			super._on_interactable_activated(object_id, position, data)

# UTILITY OVERRIDES FOR LAB-SPECIFIC BEHAVIOR


func _on_utility_activated(utility_type: String, position: Vector3, data: Dictionary):
	"""Override utility activation for lab-specific handling"""
	print("LabGridSystem: Lab utility activated - %s" % utility_type)
	
	# Handle lab teleporter differently
	if utility_type == "t":
		print("LabGridSystem: 🚀 Lab teleporter activated")
		
		var destination = data.get("destination", "")
		
		# Check if destination is a sequence name (no map extension)
		var sequence_name = ""
		if _is_sequence_name(destination):
			sequence_name = destination
			print("LabGridSystem: Direct sequence teleporter: '%s'" % sequence_name)
		else:
			# Legacy: map name, try to determine sequence
			sequence_name = _get_sequence_for_map(destination)
			print("LabGridSystem: Map-based teleporter '%s' -> sequence '%s'" % [destination, sequence_name])
		
		# Find SceneManager and request transition
		var scene_manager = _find_scene_manager()
		if scene_manager:
			if sequence_name:
				print("LabGridSystem: Starting sequence '%s'" % sequence_name)
				scene_manager.request_transition({
					"type": 1, # TransitionType.TELEPORTER
					"action": "start_sequence",
					"sequence": sequence_name,
					"source": "lab_teleporter",
					"position": position
				})
			else:
				print("LabGridSystem: Loading single map '%s'" % destination)
				scene_manager.request_transition({
					"type": 1, # TransitionType.TELEPORTER
					"action": "load_map",
					"destination": destination,
					"source": "lab_teleporter",
					"position": position
				})
	else:
		# Call parent method for other utilities
		super._on_utility_activated(utility_type, position, data)

# SEQUENCE MANAGEMENT HELPERS

func _is_sequence_name(name: String) -> bool:
	"""Check if the name is a sequence name rather than a map name"""
	var known_sequences = [
		"array_tutorial",
		"randomness_exploration", 
		"geometric_algorithms",
		"advanced_concepts",
		"wavefunctions"
	]
	return name in known_sequences

func _get_sequence_for_map(map_name: String) -> String:
	"""Determine which sequence a map belongs to based on map_sequences.json"""
	var sequence_mappings = {
		"Tutorial_Single": "array_tutorial",
		"Tutorial_Col": "array_tutorial", 
		"Tutorial_Row": "array_tutorial",
		"Tutorial_2D": "array_tutorial",
		"Tutorial_Disco": "array_tutorial",
		"Random_0": "randomness_exploration",
		"Random_1": "randomness_exploration",
		"Random_2": "randomness_exploration", 
		"Random_3": "randomness_exploration",
		"Geometric_1": "geometric_algorithms",
		"Geometric_2": "geometric_algorithms",
		"Geometric_3": "geometric_algorithms",
		"Advanced_1": "advanced_concepts",
		"Advanced_2": "advanced_concepts",
		"Advanced_3": "advanced_concepts",
		"Advanced_Final": "advanced_concepts"
	}
	
	return sequence_mappings.get(map_name, "")
# PUBLIC API EXTENSIONS

func get_lab_info() -> Dictionary:
	"""Get lab-specific information"""
	var base_info = get_current_map_info()
	base_info.merge({
		"lab_mode": lab_mode,
		"lab_cube_color": lab_cube_color,
		"is_progressive_map": is_progressive_map,
		"progression_state": progression_state,
		"progression": {
			"completed_sequences": completed_sequences,
			"unlocked_artifacts": unlocked_artifacts
		}
	})
	return base_info

func is_artifact_unlocked(artifact_id: String) -> bool:
	"""Check if artifact is unlocked"""
	if is_progressive_map:
		# For progressive maps, all artifacts in the JSON are "unlocked"
		return true
	else:
		return artifact_id in unlocked_artifacts

func get_unlocked_artifacts() -> Array[String]:
	"""Get list of unlocked artifacts"""
	return unlocked_artifacts.duplicate()

func force_unlock_artifact(artifact_id: String):
	print("LabGridSystem: Artifact filtering disabled - all artifacts visible")
	return
	"""Force unlock an artifact for testing (legacy system only)"""
	if is_progressive_map:
		print("LabGridSystem: Cannot force unlock artifacts in progressive map mode")
		return
	
	if not artifact_id in unlocked_artifacts:
		unlocked_artifacts.append(artifact_id)
		_save_lab_progression()
		_filter_artifacts_by_progression()
		print("LabGridSystem: 🔧 Force unlocked: %s" % artifact_id)

func reset_lab_progression():
	"""Reset lab progression for testing (legacy system only)"""
	if is_progressive_map:
		print("LabGridSystem: Cannot reset progression in progressive map mode")
		return
	
	completed_sequences.clear()
	unlocked_artifacts.clear()
	unlocked_artifacts.append("rotating_cube")
	_save_lab_progression()
	_filter_artifacts_by_progression()
	print("LabGridSystem: 🔄 Lab progression reset")

# DEBUG METHODS

func print_lab_status():
	"""Print lab-specific status"""
	print("=== LAB GRID SYSTEM STATUS ===")
	print("Lab mode: %s" % lab_mode)
	print("Lab cube color: %s" % lab_cube_color)
	print("Is progressive map: %s" % is_progressive_map)
	print("Progression state: %s" % progression_state)
	print("Map name: %s" % map_name)
	
	if not is_progressive_map:
		print("Completed sequences: %s" % str(completed_sequences))
		print("Unlocked artifacts: %s" % str(unlocked_artifacts))
	else:
		print("Progressive map - artifacts defined in JSON")
	
	# Call parent status
	print_component_status()
	print("=============================")

# Apply lab styling when cube size changes
func _on_cube_size_changed():
	"""Reapply lab styling when cube size changes"""
	if lab_mode and is_map_ready():
		call_deferred("_apply_lab_cube_materials")

# RELOAD MAP FUNCTIONALITY

func reload_map_with_name(new_map_name: String):
	"""Reload the grid system with a new map name"""
	print("LabGridSystem: Reloading with new map: %s" % new_map_name)
	
	# Update the map name
	map_name = new_map_name
	
	# Check if this is a progressive map
	_check_for_progressive_map()
	
	# Trigger the standard reload mechanism
	reload_map = true
