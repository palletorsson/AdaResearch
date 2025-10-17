# AdaSceneManager.gd - COMPLETE VERSION WITH PROGRESSION SUPPORT
# Universal scene transition manager - now as singleton with lab progression
# Add this script as AutoLoad in Project Settings with name "SceneManager"

extends Node
class_name AdaSceneManager

# Singleton instance
static var instance: AdaSceneManager

# Scene references and paths
const GRID_SCENE_PATH = "res://commons/scenes/grid.tscn"
const LAB_SCENE_PATH = "res://commons/scenes/lab.tscn"

# Transition types
enum TransitionType {
	ARTIFACT_ACTIVATION,
	TELEPORTER,
	TRIGGER_ZONE,
	SEQUENCE_COMPLETE,
	MANUAL_LOAD,
	RETURN_TO_HUB
}

# State tracking
var current_scene_type: String = ""
var current_sequence_data: Dictionary = {}
var staging_ref: Node = null
var transition_history: Array = []

# Progression integration
var lab_manager_ref: LabManager = null
var map_progression_manager_ref = null

# Sequence data loaded from JSON
var sequence_configs: Dictionary = {}
const SEQUENCES_JSON_PATH = "res://commons/maps/map_sequences.json"

# Signals
signal scene_transition_started(from_scene: String, to_scene: String, transition_type: TransitionType)
signal scene_transition_completed(scene_name: String, user_data: Dictionary)
signal sequence_started(sequence_name: String, sequence_data: Dictionary)
signal sequence_completed(sequence_name: String, completion_data: Dictionary)

func _init():
	# Ensure singleton pattern
	if instance == null:
		instance = self
		print("AdaSceneManager: Singleton instance created")
	else:
		print("AdaSceneManager: ERROR - Multiple instances detected!")
		queue_free()

func _ready():
	if instance != self:
		return
		
	print("AdaSceneManager: Singleton initialized - Universal transition system ready")
	print("AdaSceneManager: Handles artifact, teleporter, trigger, and sequence transitions")
	
	# Load sequence configurations from JSON (REQUIRED)
	_load_sequence_configurations()
	
	# Connect to other managers
	_connect_to_managers()

# =============================================================================
# SINGLETON ACCESS
# =============================================================================

static func get_instance() -> AdaSceneManager:
	"""Get the singleton instance"""
	if instance == null:
		push_error("AdaSceneManager: Singleton not initialized!")
	return instance

static func is_available() -> bool:
	"""Check if singleton is available"""
	return instance != null

# =============================================================================
# MANAGER CONNECTIONS
# =============================================================================

func _connect_to_managers():
	"""Connect to other manager systems"""
	# Connect to MapProgressionManager if available
	map_progression_manager_ref = get_node_or_null("/root/MapProgressionManager")
	if map_progression_manager_ref:
		print("AdaSceneManager: Connected to MapProgressionManager")

func connect_to_lab_manager(lab_manager: LabManager):
	"""Connect to lab manager with progressive lab support"""
	lab_manager_ref = lab_manager
	
	if lab_manager:
		# Connect existing signals
		if not lab_manager.artifact_activated.is_connected(_on_artifact_activated):
			lab_manager.artifact_activated.connect(_on_artifact_activated)
		if not lab_manager.progression_event.is_connected(_on_progression_event):
			lab_manager.progression_event.connect(_on_progression_event)
		
		# Connect new progressive lab signals
		if lab_manager.has_signal("lab_state_changed") and not lab_manager.lab_state_changed.is_connected(_on_lab_state_changed):
			lab_manager.lab_state_changed.connect(_on_lab_state_changed)
		
		if lab_manager.has_signal("lab_map_transition_complete") and not lab_manager.lab_map_transition_complete.is_connected(_on_lab_map_transition_complete):
			lab_manager.lab_map_transition_complete.connect(_on_lab_map_transition_complete)
		
		print("AdaSceneManager: ✅ Connected to LabManager with progressive lab support")


func connect_to_grid_system(grid_system: Node):
	"""Connect to grid system for teleporter/trigger events"""
	if grid_system and grid_system.has_signal("interactable_activated"):
		if not grid_system.interactable_activated.is_connected(_on_interactable_activated):
			grid_system.interactable_activated.connect(_on_interactable_activated)
			print("AdaSceneManager: Connected to GridSystem")

# =============================================================================
# SEQUENCE CONFIGURATION LOADING (REQUIRED - NO FALLBACK)
# =============================================================================

func _load_sequence_configurations():
	"""Load sequence configurations from JSON file - REQUIRED"""
	print("AdaSceneManager: Loading sequence configurations from JSON...")
	
	if not FileAccess.file_exists(SEQUENCES_JSON_PATH):
		push_error("AdaSceneManager: CRITICAL - Sequences JSON file not found: %s" % SEQUENCES_JSON_PATH)
		push_error("AdaSceneManager: Create the file with proper sequence definitions")
		return
	
	var file = FileAccess.open(SEQUENCES_JSON_PATH, FileAccess.READ)
	if not file:
		push_error("AdaSceneManager: CRITICAL - Could not open sequences file: %s" % SEQUENCES_JSON_PATH)
		return
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_text)
	
	if parse_result != OK:
		push_error("AdaSceneManager: CRITICAL - Failed to parse sequences JSON: %s" % json.get_error_message())
		push_error("AdaSceneManager: Check JSON syntax in: %s" % SEQUENCES_JSON_PATH)
		return
	
	var json_data = json.data
	sequence_configs = json_data.get("sequences", {})
	
	if sequence_configs.is_empty():
		push_error("AdaSceneManager: CRITICAL - No sequences found in JSON file")
		push_error("AdaSceneManager: Check 'sequences' section in: %s" % SEQUENCES_JSON_PATH)
		return
	
	print("AdaSceneManager: ✅ Successfully loaded %d sequence configurations from JSON" % sequence_configs.size())
	
	# Log loaded sequences for verification
	for sequence_name in sequence_configs.keys():
		var config = sequence_configs[sequence_name]
		var maps = config.get("maps", [])
		print("  → %s: %d maps (%s)" % [sequence_name, maps.size(), str(maps)])

# =============================================================================
# ARTIFACT SEQUENCE MAPPING
# =============================================================================

func _get_sequence_for_artifact(artifact_id: String) -> String:
	"""Get sequence name for artifact from grid_artifacts.json"""
	const ARTIFACTS_JSON_PATH = "res://commons/artifacts/grid_artifacts.json"
	
	if not FileAccess.file_exists(ARTIFACTS_JSON_PATH):
		print("AdaSceneManager: Artifacts JSON not found: %s" % ARTIFACTS_JSON_PATH)
		return ""
	
	var file = FileAccess.open(ARTIFACTS_JSON_PATH, FileAccess.READ)
	if not file:
		print("AdaSceneManager: Could not open artifacts file")
		return ""
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_text)
	
	if parse_result != OK:
		print("AdaSceneManager: Failed to parse artifacts JSON")
		return ""
	
	var artifacts_data = json.data.get("artifacts", {})
	
	if artifacts_data.has(artifact_id):
		var artifact_info = artifacts_data[artifact_id]
		var sequence = artifact_info.get("sequence", "")
		if sequence and sequence != null:
			return sequence
	
	return ""

# =============================================================================
# SIGNAL HANDLERS
# =============================================================================

func _on_artifact_activated(artifact_id: String):
	print("AdaSceneManager: Artifact activated: %s" % artifact_id)
	
	# First, try to get sequence from artifacts registry
	var sequence_name = _get_sequence_for_artifact(artifact_id)
	
	if sequence_name and not sequence_name.is_empty():
		print("AdaSceneManager: Found sequence '%s' for artifact '%s'" % [sequence_name, artifact_id])
		request_transition({
			"type": TransitionType.ARTIFACT_ACTIVATION,
			"source": artifact_id,
			"action": "start_sequence",
			"sequence": sequence_name
		})
		return
	
	# Fallback to hardcoded mappings for special cases
	match artifact_id:
		"rotating_cube":
			request_transition({
				"type": TransitionType.ARTIFACT_ACTIVATION,
				"source": "rotating_cube",
				"action": "start_sequence",
				"sequence": "array_tutorial",
				"first_map": "Tutorial_Single"
			})
		_:
			print("AdaSceneManager: No sequence mapping found for artifact: %s" % artifact_id)

func _on_interactable_activated(object_id: String, position: Vector3, data: Dictionary):
	print("AdaSceneManager: Interactable activated: %s" % object_id)
	
	if data.has("transition_trigger"):
		var trigger_data = data["transition_trigger"]
		trigger_data["type"] = TransitionType.TRIGGER_ZONE
		trigger_data["source"] = object_id
		request_transition(trigger_data)

func _on_progression_event(event_name: String, event_data: Dictionary):
	print("AdaSceneManager: Progression event: %s" % event_name)
	
	match event_name:
		"sequence_triggered":
			var sequence_name = event_data.get("sequence_name", "")
			request_transition({
				"type": TransitionType.ARTIFACT_ACTIVATION,
				"action": "start_sequence",
				"sequence": sequence_name
			})
		"sequence_completed":
			request_transition({
				"type": TransitionType.SEQUENCE_COMPLETE,
				"action": "return_to_hub",
				"completion_data": event_data
			})

# =============================================================================
# UNIVERSAL TRANSITION REQUEST SYSTEM
# =============================================================================

func request_transition(transition_request: Dictionary):
	print("AdaSceneManager: Processing transition request: %s" % transition_request)
	
	var transition_type = transition_request.get("type", TransitionType.MANUAL_LOAD)
	var action = transition_request.get("action", "")
	
	transition_history.append({
		"timestamp": Time.get_datetime_string_from_system(),
		"request": transition_request
	})
	
	match action:
		"start_sequence":
			_start_sequence_from_request(transition_request)
		"load_map":
			_load_specific_map(transition_request)
		"next_in_sequence":
			_advance_sequence()
		"next":
			# NEW: Handle generic "next" action using map_sequences.json
			var current_map = transition_request.get("current_map_name", "")
			if current_map.is_empty():
				# Try to get map name from utility data or other sources
				current_map = transition_request.get("utility_data", {}).get("current_map", "")
			_handle_next_action(current_map)
		"return_to_hub":
			_return_to_hub(transition_request.get("completion_data", {}))
		_:
			print("AdaSceneManager: Unknown action: %s" % action)

func _start_sequence_from_request(request: Dictionary):
	var sequence_name = request.get("sequence", "")
	
	if not sequence_configs.has(sequence_name):
		push_error("AdaSceneManager: Unknown sequence: %s" % sequence_name)
		print("AdaSceneManager: Available sequences: %s" % str(sequence_configs.keys()))
		print("AdaSceneManager: Check your sequence configuration in: %s" % SEQUENCES_JSON_PATH)
		return
	
	var config = sequence_configs[sequence_name]
	current_sequence_data = {
		"sequence_name": sequence_name,
		"maps": config.get("maps", []),
		"current_step": 0,
		"return_to": config.get("return_to", "lab"),
		"transition_source": request,
		"sequence_info": {
			"name": config.get("name", sequence_name),
			"description": config.get("description", ""),
			"total_maps": config.get("maps", []).size()
		}
	}
	
	print("AdaSceneManager: Starting sequence '%s' with %d maps" % [sequence_name, current_sequence_data.maps.size()])
	
	# Emit sequence started signal
	sequence_started.emit(sequence_name, current_sequence_data)
	
	_load_grid_scene_with_first_map()

func _load_specific_map(request: Dictionary):
	var map_name = request.get("destination", "")
	var spawn_point = request.get("spawn_point", "default")
	
	if map_name.is_empty():
		print("AdaSceneManager: No destination specified in request")
		return
	
	var scene_data = {
		"map_name": map_name,
		"spawn_point": spawn_point,
		"scene_manager": self,
		"transition_source": request
	}
	
	_load_scene_with_data(GRID_SCENE_PATH, scene_data)

func _load_grid_scene_with_first_map():
	if current_sequence_data.is_empty():
		push_error("AdaSceneManager: ERROR - No sequence data")
		return
	
	var maps = current_sequence_data.get("maps", [])
	if maps.is_empty():
		push_error("AdaSceneManager: ERROR - No maps in sequence")
		return
	
	var first_map = maps[0]
	print("AdaSceneManager: Loading grid scene with map: %s" % first_map)
	
	var grid_scene_data = {
		"sequence_data": current_sequence_data,
		"initial_map": first_map,
		"scene_manager": self
	}
	
	_load_scene_with_data(GRID_SCENE_PATH, grid_scene_data)

func _restore_sequence_context(sequence_data: Dictionary):
	"""Restore sequence context when transitioning between maps in a sequence"""
	if sequence_data.is_empty():
		print("AdaSceneManager: No sequence data to restore")
		return
		
	current_sequence_data = sequence_data
	print("AdaSceneManager: ✅ Restored sequence context: %s (step %d/%d)" % [
		current_sequence_data.get("sequence_name", "unknown"),
		current_sequence_data.get("current_step", 0) + 1,
		current_sequence_data.get("maps", []).size()
	])

func _handle_next_action(current_map_name: String):
	"""Handle 'next' action by analyzing current map against sequence configuration"""
	print("AdaSceneManager: Handling 'next' action from map: %s" % current_map_name)
	
	# Find which sequence contains this map
	var sequence_info = _find_sequence_containing_map(current_map_name)
	
	if sequence_info.is_empty():
		print("AdaSceneManager: Map '%s' not found in any sequence - cannot advance" % current_map_name)
		return
	
	var sequence_name = sequence_info["sequence_name"]
	var maps = sequence_info["maps"]
	var current_step = sequence_info["current_step"]
	
	print("AdaSceneManager: Found map in sequence '%s' at step %d/%d" % [sequence_name, current_step + 1, maps.size()])
	
	# Set sequence context if not already active
	if current_sequence_data.is_empty():
		_activate_sequence_context(sequence_name, current_step)
	
	# Determine next action
	if current_step + 1 >= maps.size():
		# Last map in sequence - complete and return to lab
		_complete_sequence(sequence_name, maps)
	else:
		# Advance to next map in sequence
		_advance_to_next_map(sequence_name, maps, current_step)

func _find_sequence_containing_map(map_name: String) -> Dictionary:
	"""Find which sequence contains the given map and return sequence info"""
	for sequence_name in sequence_configs.keys():
		var config = sequence_configs[sequence_name]
		var maps = config.get("maps", [])
		
		var map_index = maps.find(map_name)
		if map_index >= 0:
			return {
				"sequence_name": sequence_name,
				"maps": maps,
				"current_step": map_index,
				"config": config
			}
	
	return {}

func _activate_sequence_context(sequence_name: String, current_step: int):
	"""Activate sequence context for an already-started sequence"""
	var config = sequence_configs[sequence_name]
	current_sequence_data = {
		"sequence_name": sequence_name,
		"maps": config.get("maps", []),
		"current_step": current_step,
		"return_to": config.get("return_to", "lab"),
		"sequence_info": {
			"name": config.get("name", sequence_name),
			"description": config.get("description", ""),
			"total_maps": config.get("maps", []).size()
		}
	}
	print("AdaSceneManager: ✅ Activated sequence context: %s" % sequence_name)

func _complete_sequence(sequence_name: String, maps: Array):
	"""Complete the sequence and return to lab"""
	print("AdaSceneManager: Completing sequence: %s" % sequence_name)
	
	var completion_data = {
		"sequence_completed": sequence_name,
		"maps_completed": maps,
		"total_maps": maps.size(),
		"completion_timestamp": Time.get_datetime_string_from_system()
	}
	
	sequence_completed.emit(sequence_name, completion_data)
	_return_to_hub(completion_data)

func _advance_to_next_map(sequence_name: String, maps: Array, current_step: int):
	"""Advance to the next map in the sequence"""
	current_sequence_data.current_step = current_step + 1
	var next_map = maps[current_sequence_data.current_step]
	
	print("AdaSceneManager: Advancing sequence '%s' to map: %s (%d/%d)" % [sequence_name, next_map, current_step + 2, maps.size()])
	
	var scene_data = {
		"sequence_data": current_sequence_data,
		"map_name": next_map,
		"scene_manager": self
	}
	
	_load_scene_with_data(GRID_SCENE_PATH, scene_data)

func _advance_sequence():
	if current_sequence_data.is_empty():
		print("AdaSceneManager: No active sequence to advance")
		return
	
	var maps = current_sequence_data.get("maps", [])
	var current_step = current_sequence_data.get("current_step", 0)
	
	if current_step + 1 >= maps.size():
		# Sequence complete - return to hub with completion data
		var completion_data = {
			"sequence_completed": current_sequence_data.sequence_name,
			"maps_completed": maps,
			"total_maps": maps.size(),
			"completion_timestamp": Time.get_datetime_string_from_system()
		}
		
		# Emit sequence completion signal
		sequence_completed.emit(current_sequence_data.sequence_name, completion_data)
		
		_return_to_hub(completion_data)
		return
	
	current_sequence_data.current_step = current_step + 1
	var next_map = maps[current_sequence_data.current_step]
	
	print("AdaSceneManager: Advancing sequence to map: %s (%d/%d)" % [next_map, current_step + 2, maps.size()])
	
	var scene_data = {
		"sequence_data": current_sequence_data,
		"map_name": next_map,
		"scene_manager": self
	}
	
	_load_scene_with_data(GRID_SCENE_PATH, scene_data)

# Enhanced return to hub with lab state consideration
func _return_to_hub(completion_data: Dictionary = {}):
	print("AdaSceneManager: Returning to lab hub with completion data")
	print("AdaSceneManager: Completion data: %s" % completion_data)
	
	# Extract sequence completion information
	var completed_sequence = ""
	if current_sequence_data.has("sequence_name"):
		completed_sequence = current_sequence_data["sequence_name"]
		completion_data["sequence_completed"] = completed_sequence
		completion_data["maps_completed"] = current_sequence_data.get("maps", [])
		completion_data["total_maps"] = current_sequence_data.get("maps", []).size()
		completion_data["completion_timestamp"] = Time.get_datetime_string_from_system()
		
		# TODO: Skip sequence saving for now - just direct to correct lab map
		print("AdaSceneManager: ⏭️ Skipping sequence saving - direct map transition for: %s" % completed_sequence)
		
		# Notify MapProgressionManager if available
		if map_progression_manager_ref and map_progression_manager_ref.has_method("complete_map"):
			for map_name in current_sequence_data.get("maps", []):
				map_progression_manager_ref.complete_map(map_name)
	
	# Clear current sequence
	current_sequence_data.clear()
	
	# Determine appropriate lab map based on progression
	var lab_map_name = _determine_lab_map_for_return(completed_sequence)
	
	# Prepare lab scene data with completion information
	var lab_scene_data = {
		"return_from": "grid",
		"completion_data": completion_data,
		"scene_manager": self,
		"completed_sequence": completed_sequence,
		"lab_map_override": lab_map_name  # New: specify which lab map to load
	}
	
	print("AdaSceneManager: 🎉 Sequence '%s' completed - returning to lab state: %s" % [completed_sequence, lab_map_name])
	print("AdaSceneManager: 🔍 DEBUG - lab_scene_data = %s" % lab_scene_data)
	
	# Load lab scene
	_load_scene_with_data(LAB_SCENE_PATH, lab_scene_data)

# Enhanced scene loading with lab map override support

func _load_scene_with_data(scene_path: String, scene_data: Dictionary):
	var staging = _get_vr_staging()
	if not staging:
		push_error("AdaSceneManager: ERROR - Could not find VR staging")
		return
	
	var from_scene = current_scene_type
	var to_scene = "lab" if scene_path == LAB_SCENE_PATH else "grid"
	
	current_scene_type = to_scene
	
	print("🔍 DEBUG: AdaSceneManager._load_scene_with_data() called")
	print("🔍 DEBUG: scene_path = %s" % scene_path)
	print("🔍 DEBUG: to_scene = %s" % to_scene)
	print("🔍 DEBUG: scene_data = %s" % scene_data)
	
	# CRITICAL FIX: Set scene_data on staging BEFORE anything else
	staging.set_meta("scene_data", scene_data)
	print("🔍 DEBUG: ✅ Set staging scene_data")
	
	# Handle lab map override for progressive loading - THIS IS THE KEY FIX!
	if scene_data.has("lab_map_override") and to_scene == "lab":
		var lab_override = scene_data["lab_map_override"]
		staging.set_meta("lab_map_override", lab_override)
		
		# ALSO set it in the scene_data so LabGridScene can find it
		scene_data["map_name"] = lab_override
		staging.set_meta("scene_user_data", scene_data)
		
		print("🔍 DEBUG: ✅ Set lab_map_override = '%s'" % lab_override)
		print("🔍 DEBUG: ✅ Set scene_user_data with map_name = '%s'" % lab_override)
	else:
		# Make sure scene_user_data is set for non-lab scenes too
		staging.set_meta("scene_user_data", scene_data)
		print("🔍 DEBUG: ✅ Set scene_user_data for non-lab scene")
	
	var transition_type = scene_data.get("transition_source", {}).get("type", TransitionType.MANUAL_LOAD)
	scene_transition_started.emit(from_scene, to_scene, transition_type)
	
	# Add completion data to staging metadata for lab to access
	if scene_data.has("completion_data"):
		staging.set_meta("completion_data", scene_data["completion_data"])
		print("🔍 DEBUG: ✅ Set completion_data")
	
	# Connect to staging signals for scene completion handling
	if staging.has_signal("scene_loaded") and not staging.scene_loaded.is_connected(_on_staging_scene_loaded):
		staging.scene_loaded.connect(_on_staging_scene_loaded)
	
	if staging.has_signal("scene_visible") and not staging.scene_visible.is_connected(_on_staging_scene_visible):
		staging.scene_visible.connect(_on_staging_scene_visible)
	
	print("🔍 DEBUG: About to call staging.load_scene()")
	staging.load_scene(scene_path, scene_data)

func _on_staging_scene_loaded(scene: Node, user_data: Dictionary):
	"""Handle when staging has loaded a scene"""
	print("AdaSceneManager: Scene loaded by staging: %s" % scene.name)
	
	# Emit our own signal
	scene_transition_completed.emit(current_scene_type, user_data)
	
	# If returning to lab with completion data, notify lab manager
	if current_scene_type == "lab" and user_data.has("completion_data"):
		var completion_data = user_data["completion_data"]
		
		# Wait for lab scene to initialize
		await get_tree().process_frame
		await get_tree().process_frame
		
		# Find and notify lab manager directly
		var lab_manager = scene.find_child("LabManager", true, false)
		if lab_manager and lab_manager.has_method("_on_scene_transition_completed"):
			lab_manager._on_scene_transition_completed("lab", user_data)
		
		# Also notify via reference if connected
		if lab_manager_ref and completion_data.has("sequence_completed"):
			var completed_sequence = completion_data["sequence_completed"]
			print("AdaSceneManager: 🔄 Notifying LabManager of sequence completion: %s" % completed_sequence)
			lab_manager_ref._on_sequence_completed(completed_sequence)

func _on_staging_scene_visible(scene: Node, user_data: Dictionary):
	"""Handle when staging scene becomes visible"""
	print("AdaSceneManager: Scene visible: %s" % scene.name)

func _get_vr_staging() -> Node:
	if staging_ref:
		return staging_ref
	
	var potential_paths = ["/root/VRStaging", "/root/AdaVRStaging"]
	
	for path in potential_paths:
		var staging = get_node_or_null(path)
		if staging:
			staging_ref = staging
			return staging_ref
	
	var tree_root = get_tree().current_scene
	if tree_root and ("staging" in tree_root.name.to_lower() or "vr" in tree_root.name.to_lower()):
		staging_ref = tree_root
		return staging_ref
	
	print("AdaSceneManager: WARNING - VR Staging not found")
	return null

# =============================================================================
# PUBLIC API
# =============================================================================

func load_map(map_name: String, spawn_point: String = "default"):
	request_transition({
		"type": TransitionType.MANUAL_LOAD,
		"action": "load_map",
		"destination": map_name,
		"spawn_point": spawn_point
	})

func start_sequence(sequence_name: String):
	# Validate sequence exists before starting
	if not sequence_configs.has(sequence_name):
		push_error("AdaSceneManager: Cannot start unknown sequence: %s" % sequence_name)
		print("AdaSceneManager: Available sequences: %s" % str(sequence_configs.keys()))
		return
		
	request_transition({
		"type": TransitionType.MANUAL_LOAD,
		"action": "start_sequence",
		"sequence": sequence_name
	})

func return_to_lab(completion_data: Dictionary = {}):
	request_transition({
		"type": TransitionType.RETURN_TO_HUB,
		"action": "return_to_hub",
		"completion_data": completion_data
	})

func get_current_sequence_data() -> Dictionary:
	return current_sequence_data

func get_current_scene_type() -> String:
	return current_scene_type

func is_in_sequence() -> bool:
	return not current_sequence_data.is_empty()

func get_transition_history() -> Array:
	return transition_history

func set_staging_reference(staging: Node):
	staging_ref = staging
	print("AdaSceneManager: Staging reference set to: %s" % staging.name)

# TODO: Implement _save_sequence_completion() later when needed

# =============================================================================
# PROGRESSION INTEGRATION
# =============================================================================

func force_complete_sequence(sequence_name: String):
	"""Force complete a sequence for testing progression"""
	print("AdaSceneManager: 🔧 Force completing sequence: %s" % sequence_name)
	
	var completion_data = {
		"sequence_completed": sequence_name,
		"force_completed": true,
		"completion_timestamp": Time.get_datetime_string_from_system()
	}
	
	# Notify lab manager directly
	if lab_manager_ref:
		lab_manager_ref._on_sequence_completed(sequence_name)
	
	# Emit signal
	sequence_completed.emit(sequence_name, completion_data)

func get_lab_manager() -> LabManager:
	"""Get reference to connected lab manager"""
	return lab_manager_ref

func notify_sequence_completion(sequence_name: String, completion_data: Dictionary = {}):
	"""Manually notify of sequence completion (for external integrations)"""
	print("AdaSceneManager: Manual sequence completion notification: %s" % sequence_name)
	
	if lab_manager_ref:
		lab_manager_ref._on_sequence_completed(sequence_name)
	
	sequence_completed.emit(sequence_name, completion_data)

# =============================================================================
# CONFIGURATION VALIDATION
# =============================================================================

func validate_sequence_config() -> Dictionary:
	"""Validate the loaded sequence configuration"""
	var validation = {
		"valid": true,
		"errors": [],
		"warnings": [],
		"sequences_found": sequence_configs.size()
	}
	
	if sequence_configs.is_empty():
		validation.valid = false
		validation.errors.append("No sequences loaded")
		return validation
	
	# Validate each sequence
	for sequence_name in sequence_configs.keys():
		var config = sequence_configs[sequence_name]
		
		if not config.has("maps") or config.maps.is_empty():
			validation.valid = false
			validation.errors.append("Sequence '%s' has no maps defined" % sequence_name)
		
		if not config.has("return_to"):
			validation.warnings.append("Sequence '%s' has no return_to defined" % sequence_name)
	
	return validation

# Get available sequences for UI/debugging
func get_available_sequences() -> Array:
	return sequence_configs.keys()

# =============================================================================
# DEBUG AND TESTING
# =============================================================================

func print_scene_manager_status():
	"""Print comprehensive status information"""
	print("=== ADASCENEMANAGER STATUS ===")
	print("Current scene type: %s" % current_scene_type)
	print("In sequence: %s" % is_in_sequence())
	if is_in_sequence():
		print("Current sequence: %s" % current_sequence_data.get("sequence_name", "unknown"))
		print("Sequence step: %d/%d" % [
			current_sequence_data.get("current_step", 0) + 1,
			current_sequence_data.get("maps", []).size()
		])
	print("Lab manager connected: %s" % (lab_manager_ref != null))
	print("Staging reference: %s" % (staging_ref != null))
	print("Available sequences: %s" % str(sequence_configs.keys()))
	print("Transition history entries: %d" % transition_history.size())
	print("==============================")

func get_debug_info() -> Dictionary:
	"""Get debug information as dictionary"""
	return {
		"current_scene_type": current_scene_type,
		"in_sequence": is_in_sequence(),
		"current_sequence_data": current_sequence_data,
		"lab_manager_connected": lab_manager_ref != null,
		"staging_connected": staging_ref != null,
		"available_sequences": sequence_configs.keys(),
		"transition_history_count": transition_history.size(),
		"last_transition": transition_history[-1] if transition_history.size() > 0 else {}
	}

# Auto-connect methods for easy integration
func auto_connect_to_scene():
	"""Automatically connect to available systems in current scene"""
	print("AdaSceneManager: Auto-connecting to scene systems...")
	
	var current_scene = get_tree().current_scene
	if not current_scene:
		return
	
	# Try to find and connect to lab manager
	var lab_manager = current_scene.find_child("LabManager", true, false)
	if lab_manager and lab_manager is LabManager:
		connect_to_lab_manager(lab_manager)
	
	# Try to find and connect to grid system
	var grid_system = current_scene.find_child("GridSystem", true, false)
	if grid_system:
		connect_to_grid_system(grid_system)
	
	print("AdaSceneManager: Auto-connection complete")

# Handle lab state changes
func _on_lab_state_changed(new_state: String, unlocked_artifacts: Array):
	"""Handle lab state transitions"""
	print("AdaSceneManager: Lab state changed to: %s" % new_state)
	print("AdaSceneManager: Newly unlocked artifacts: %s" % str(unlocked_artifacts))

# Handle lab map transition completion
func _on_lab_map_transition_complete(new_state: String):
	"""Handle completion of lab map transitions"""
	print("AdaSceneManager: Lab map transition complete - new state: %s" % new_state)



func _determine_lab_map_for_return(completed_sequence: String) -> String:
	"""Determine lab map using consolidated sequence_configs"""
	
	# Use already-loaded sequence_configs (no additional file I/O needed)
	if sequence_configs.has(completed_sequence):
		var sequence = sequence_configs[completed_sequence]
		var lab_map = sequence.get("lab_map", "Lab/map_data_init")
		print("AdaSceneManager: 🎯 Sequence '%s' → lab map: %s" % [completed_sequence, lab_map])
		return lab_map
	
	# Use consolidated fallback
	var fallback = sequence_configs.get("fallback_lab_map", "Lab/map_data_init")
	print("AdaSceneManager: ⚠️ No mapping for sequence '%s', using fallback: %s" % [completed_sequence, fallback])
	return fallback
