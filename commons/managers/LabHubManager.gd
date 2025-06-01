# LabHubManager.gd
# Manages only the lab environment as a persistent hub
# Completely decoupled from sequence management

extends Node3D
class_name LabHubManager

# Lab state - only what belongs to the lab itself
var collected_artifacts: Dictionary = {}
var artifact_display_slots: Array[Node3D] = []
var sequence_portals: Dictionary = {}
var is_first_visit: bool = true
var lab_evolution_stage: int = 0

# Physical lab components
var lab_table: Node3D
var artifact_displays: Node3D
var portal_area: Node3D
var tutorial_trigger: TutorialTriggerCube

# Configuration
const MAX_DISPLAY_SLOTS = 9
const PORTAL_POSITIONS = [
	Vector3(3, 1, 1),    # Array tutorial portal
	Vector3(-3, 1, 1),   # Sorting portal
	Vector3(1, 1, -3),   # Randomness portal
	Vector3(-1, 1, -3)   # Advanced portal
]

# Signals
signal artifact_placed(artifact_name: String)
signal portal_activated(portal_id: String)
signal lab_state_changed()
signal tutorial_requested()

func _ready():
	print("LabHubManager: Initializing persistent lab hub")
	_setup_lab_environment()
	_load_lab_state()
	_setup_tutorial_trigger()

func _setup_lab_environment():
	"""Setup the basic lab environment - table, lighting, etc."""
	print("LabHubManager: Setting up lab environment")
	
	# Create main lab table
	lab_table = Node3D.new()
	lab_table.name = "LabTable"
	lab_table.position = Vector3(0, 1, 0)
	add_child(lab_table)
	
	# Create artifact display area
	artifact_displays = Node3D.new()
	artifact_displays.name = "ArtifactDisplays"
	lab_table.add_child(artifact_displays)
	
	# Create portal area
	portal_area = Node3D.new()
	portal_area.name = "PortalArea"
	add_child(portal_area)
	
	# Setup display slots
	_setup_display_slots()
	
	print("LabHubManager: Lab environment ready")

func _setup_display_slots():
	"""Create physical display positions for artifacts"""
	var slot_positions = [
		Vector3(0, 0.1, 0),      # Center
		Vector3(0.7, 0.1, 0),    # East
		Vector3(-0.7, 0.1, 0),   # West
		Vector3(0, 0.1, 0.7),    # South
		Vector3(0, 0.1, -0.7),   # North
		Vector3(0.5, 0.1, 0.5),  # Southeast
		Vector3(-0.5, 0.1, 0.5), # Southwest
		Vector3(0.5, 0.1, -0.5), # Northeast
		Vector3(-0.5, 0.1, -0.5) # Northwest
	]
	
	for i in range(MAX_DISPLAY_SLOTS):
		var slot = Node3D.new()
		slot.name = "DisplaySlot_%d" % i
		slot.position = slot_positions[i]
		artifact_displays.add_child(slot)
		artifact_display_slots.append(slot)

func _setup_tutorial_trigger():
	"""Setup the tutorial trigger cube for first-time visitors"""
	if is_first_visit:
		print("LabHubManager: Setting up tutorial trigger cube")
		tutorial_trigger = TutorialTriggerCube.new()
		tutorial_trigger.name = "TutorialTrigger"
		tutorial_trigger.position = Vector3(0, 1.1, 0)
		tutorial_trigger.tutorial_requested.connect(_on_tutorial_requested)
		lab_table.add_child(tutorial_trigger)

func _load_lab_state():
	"""Load the persistent lab state"""
	# TODO: Load from save file
	print("LabHubManager: Loading lab state")
	
	# For now, start fresh
	is_first_visit = true
	lab_evolution_stage = 0
	collected_artifacts.clear()

func add_collected_artifact(artifact_data: Dictionary):
	"""Add a new artifact to the lab display"""
	var artifact_id = artifact_data.get("id", "")
	if artifact_id.is_empty():
		print("LabHubManager: ERROR - Artifact missing ID")
		return
	
	if artifact_id in collected_artifacts:
		print("LabHubManager: Artifact '%s' already in collection" % artifact_id)
		return
	
	print("LabHubManager: Adding artifact '%s' to lab" % artifact_id)
	collected_artifacts[artifact_id] = artifact_data
	
	# Create visual display
	var display_object = _create_artifact_display(artifact_data)
	if display_object:
		_place_on_display(display_object, artifact_id)
		artifact_placed.emit(artifact_id)
		_check_lab_evolution()

func _create_artifact_display(artifact_data: Dictionary) -> Node3D:
	"""Create a visual representation of the artifact"""
	var display = ArtifactDisplay.new()
	display.setup_display(artifact_data)
	return display

func _place_on_display(display_object: Node3D, artifact_id: String):
	"""Place artifact display on an available slot"""
	for i in range(artifact_display_slots.size()):
		var slot = artifact_display_slots[i]
		if slot.get_child_count() == 0:  # Empty slot
			slot.add_child(display_object)
			print("LabHubManager: Placed '%s' on display slot %d" % [artifact_id, i])
			return
	
	print("LabHubManager: WARNING - No empty display slots available")

func create_sequence_portal(portal_config: Dictionary):
	"""Create a portal to a specific sequence"""
	var portal_id = portal_config.get("id", "")
	if portal_id.is_empty():
		return
	
	if portal_id in sequence_portals:
		print("LabHubManager: Portal '%s' already exists" % portal_id)
		return
	
	print("LabHubManager: Creating portal for sequence '%s'" % portal_id)
	var portal = SequencePortal.new()
	portal.setup_portal(portal_config)
	portal.portal_entered.connect(_on_portal_entered)
	
	# Position the portal
	var position_index = sequence_portals.size()
	if position_index < PORTAL_POSITIONS.size():
		portal.position = PORTAL_POSITIONS[position_index]
	
	portal_area.add_child(portal)
	sequence_portals[portal_id] = portal

func unlock_sequence_portal(sequence_id: String):
	"""Unlock a sequence portal when requirements are met"""
	if sequence_id in sequence_portals:
		var portal = sequence_portals[sequence_id]
		portal.unlock()
		print("LabHubManager: Unlocked portal to '%s'" % sequence_id)

func has_artifact(artifact_id: String) -> bool:
	"""Check if lab has a specific artifact"""
	return artifact_id in collected_artifacts

func get_unlocked_sequences() -> Array[String]:
	"""Get list of unlocked sequence IDs"""
	var unlocked: Array[String] = []
	for portal_id in sequence_portals:
		var portal = sequence_portals[portal_id]
		if portal.is_unlocked():
			unlocked.append(portal_id)
	return unlocked

func _check_lab_evolution():
	"""Check if the lab should evolve based on collected artifacts"""
	var artifact_count = collected_artifacts.size()
	var new_stage = artifact_count / 3  # Evolve every 3 artifacts
	
	if new_stage > lab_evolution_stage:
		lab_evolution_stage = new_stage
		_evolve_lab()

func _evolve_lab():
	"""Evolve the lab environment"""
	print("LabHubManager: Lab evolving to stage %d" % lab_evolution_stage)
	
	match lab_evolution_stage:
		1:
			_unlock_basic_portals()
		2:
			_upgrade_lighting()
		3:
			_add_advanced_displays()
	
	lab_state_changed.emit()

func _unlock_basic_portals():
	"""Unlock basic sequence portals"""
	create_sequence_portal({
		"id": "array_tutorial",
		"name": "Array Fundamentals", 
		"requirements": [],
		"color": Color.CYAN
	})

func _upgrade_lighting():
	"""Improve lab lighting"""
	print("LabHubManager: Upgrading lab lighting")
	# TODO: Add better lighting effects

func _add_advanced_displays():
	"""Add advanced display capabilities"""
	print("LabHubManager: Adding advanced displays")
	# TODO: Add holographic displays

func _on_tutorial_requested():
	"""Handle tutorial trigger from the rotating cube"""
	print("LabHubManager: Tutorial requested - forwarding to transition manager")
	tutorial_requested.emit()
	
	# Remove tutorial trigger after first use
	if tutorial_trigger:
		tutorial_trigger.queue_free()
		tutorial_trigger = null
		is_first_visit = false

func _on_portal_entered(sequence_id: String):
	"""Handle portal activation"""
	print("LabHubManager: Portal to '%s' activated" % sequence_id)
	portal_activated.emit(sequence_id)

func save_lab_state():
	"""Save the current lab state"""
	var state = {
		"collected_artifacts": collected_artifacts,
		"lab_evolution_stage": lab_evolution_stage,
		"is_first_visit": is_first_visit,
		"unlocked_sequences": get_unlocked_sequences(),
		"timestamp": Time.get_unix_time_from_system()
	}
	
	# TODO: Save to file
	print("LabHubManager: Lab state saved")

# Public API
func get_lab_status() -> Dictionary:
	return {
		"artifact_count": collected_artifacts.size(),
		"evolution_stage": lab_evolution_stage,
		"unlocked_portals": get_unlocked_sequences(),
		"display_slots_used": _count_used_display_slots(),
		"first_visit": is_first_visit
	}

func _count_used_display_slots() -> int:
	var count = 0
	for slot in artifact_display_slots:
		if slot.get_child_count() > 0:
			count += 1
	return count 
