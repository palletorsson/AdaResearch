# LabManager.gd - Simplified lab hub manager for lab.tscn
extends Node3D
class_name LabManager

# Scene management
@onready var artifact_pedestals = $ArtifactPedestals
@onready var sequence_portals = $SequencePortals

# Progress tracking
var unlocked_sequences: Array[String] = ["array_tutorial"]
var collected_artifacts: Dictionary = {}

# Signals
signal sequence_requested(sequence_name: String)

func _ready():
	print("LabManager: Initializing lab hub")
	_setup_sequence_portals()
	_load_progress()
	_update_displays()

func _setup_sequence_portals():
	print("LabManager: Setting up sequence portals")
	
	# Find and configure array tutorial portal
	var array_portal = sequence_portals.find_child("ArrayTutorialPortal")
	if array_portal:
		array_portal.body_entered.connect(_on_portal_entered.bind("array_tutorial"))
		print("LabManager: Array tutorial portal configured")

func _on_portal_entered(body: Node3D, sequence_name: String):
	if body.name.begins_with("PlayerBody") or body.has_method("is_player"):
		print("LabManager: Player entered %s portal" % sequence_name)
		_start_sequence(sequence_name)

func _start_sequence(sequence_name: String):
	if sequence_name in unlocked_sequences:
		print("LabManager: Starting sequence '%s'" % sequence_name)
		sequence_requested.emit(sequence_name)
		_transition_to_grid_scene(sequence_name)
	else:
		print("LabManager: Sequence '%s' not unlocked yet" % sequence_name)

func _transition_to_grid_scene(sequence_name: String):
	print("LabManager: Transitioning to grid scene for '%s'" % sequence_name)
	
	# Store sequence info for grid scene
	var sequence_data = {
		"sequence_name": sequence_name,
		"return_to": "lab"
	}
	
	# Use staging to load grid scene
	var staging = get_node("/root/VRStaging")
	if staging and staging.has_method("load_scene"):
		staging.set_meta("sequence_data", sequence_data)
		staging.load_scene("res://commons/scenes/grid.tscn")
	else:
		print("LabManager: ERROR - Could not access VRStaging")

func _load_progress():
	print("LabManager: Loading progress from MapProgressionManager")
	
	# Get progress from progression manager
	if MapProgressionManager:
		var completed_maps = MapProgressionManager.get_completed_maps()
		var unlocked_maps = MapProgressionManager.get_unlocked_maps()
		
		print("LabManager: Completed maps: %s" % str(completed_maps))
		print("LabManager: Unlocked maps: %s" % str(unlocked_maps))
		
		# Update unlocked sequences based on progress
		_update_unlocked_sequences(completed_maps)

func _update_unlocked_sequences(completed_maps: Array):
	# Start with array tutorial always available
	unlocked_sequences = ["array_tutorial"]
	
	# Unlock more sequences based on completion
	if "Tutorial_Disco" in completed_maps:
		unlocked_sequences.append("randomness_exploration")
	
	print("LabManager: Unlocked sequences: %s" % str(unlocked_sequences))

func _update_displays():
	print("LabManager: Updating artifact displays")
	_update_artifact_pedestals()
	_update_portal_states()

func _update_artifact_pedestals():
	# Update artifact displays based on collected artifacts
	for i in range(artifact_pedestals.get_child_count()):
		var pedestal = artifact_pedestals.get_child(i)
		if i < collected_artifacts.size():
			_display_artifact_on_pedestal(pedestal, i)
		else:
			_clear_pedestal(pedestal)

func _display_artifact_on_pedestal(pedestal: Node3D, artifact_index: int):
	# Create visual representation of artifact
	var artifact_mesh = pedestal.find_child("ArtifactMesh")
	if not artifact_mesh:
		artifact_mesh = MeshInstance3D.new()
		artifact_mesh.name = "ArtifactMesh"
		pedestal.add_child(artifact_mesh)
	
	# Simple sphere for now - can be improved later
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.2
	artifact_mesh.mesh = sphere_mesh
	
	print("LabManager: Displayed artifact %d on pedestal" % artifact_index)

func _clear_pedestal(pedestal: Node3D):
	var artifact_mesh = pedestal.find_child("ArtifactMesh")
	if artifact_mesh:
		artifact_mesh.queue_free()

func _update_portal_states():
	# Update portal visual states based on unlocked sequences
	for portal in sequence_portals.get_children():
		var sequence_name = portal.name.replace("Portal", "").to_snake_case()
		var is_unlocked = sequence_name in unlocked_sequences
		_set_portal_state(portal, is_unlocked)

func _set_portal_state(portal: Node3D, unlocked: bool):
	var portal_mesh = portal.find_child("PortalMesh")
	if portal_mesh:
		var material = portal_mesh.get_surface_override_material(0)
		if not material:
			material = StandardMaterial3D.new()
			portal_mesh.set_surface_override_material(0, material)
		
		if unlocked:
			material.albedo_color = Color.GREEN
			material.emission = Color.GREEN * 0.3
		else:
			material.albedo_color = Color.GRAY
			material.emission = Color.BLACK

# Called when returning from grid scene with artifacts
func add_artifacts(artifacts: Array):
	print("LabManager: Adding artifacts: %s" % str(artifacts))
	
	for artifact in artifacts:
		if artifact.has("id"):
			collected_artifacts[artifact.id] = artifact
	
	_update_displays()

# Public API
func get_unlocked_sequences() -> Array[String]:
	return unlocked_sequences

func is_sequence_unlocked(sequence_name: String) -> bool:
	return sequence_name in unlocked_sequences 
