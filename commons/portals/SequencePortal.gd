# SequencePortal.gd
# Individual portal to a sequence - visual gateway in the lab
# Appears when requirements are met

extends Node3D
class_name SequencePortal

# Configuration
@export var sequence_id: String = ""
@export var portal_name: String = ""
@export var unlock_requirements: Array[String] = []
@export var portal_color: Color = Color.CYAN
@export var portal_size: float = 1.0

# State
var is_portal_unlocked: bool = false
var is_visible: bool = false
var preview_info: Dictionary = {}

# Visual components
var portal_mesh: MeshInstance3D
var portal_light: OmniLight3D
var interaction_area: Area3D
var info_label: Label3D

# Animation
var rotation_speed: float = 20.0
var pulse_speed: float = 2.0
var hover_height: float = 0.1

# Signals
signal portal_entered(sequence_id: String)
signal portal_focused(sequence_id: String)
signal portal_unfocused(sequence_id: String)

func _ready():
	print("SequencePortal: Initializing portal for sequence '%s'" % sequence_id)
	_setup_visual_components()
	_setup_interaction()
	_update_visibility()

func setup_portal(config: Dictionary):
	"""Configure the portal from a dictionary"""
	sequence_id = config.get("id", sequence_id)
	portal_name = config.get("name", config.get("id", "Unknown"))
	unlock_requirements = config.get("requirements", [])
	portal_color = Color(config.get("color", Color.CYAN))
	preview_info = config.get("preview", {})
	
	print("SequencePortal: Configured portal '%s' (%s)" % [portal_name, sequence_id])
	_update_visual_style()

func _setup_visual_components():
	"""Create the visual representation of the portal"""
	# Main portal ring
	portal_mesh = MeshInstance3D.new()
	var torus_mesh = TorusMesh.new()
	torus_mesh.inner_radius = portal_size * 0.3
	torus_mesh.outer_radius = portal_size * 0.5
	torus_mesh.rings = 16
	torus_mesh.ring_segments = 32
	portal_mesh.mesh = torus_mesh
	
	# Create material
	var material = StandardMaterial3D.new()
	material.albedo_color = portal_color
	material.emission = portal_color * 0.5
	material.metallic = 0.8
	material.roughness = 0.2
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color.a = 0.8
	portal_mesh.material_override = material
	
	add_child(portal_mesh)
	
	# Portal light
	portal_light = OmniLight3D.new()
	portal_light.light_color = portal_color
	portal_light.light_energy = 2.0
	portal_light.omni_range = 5.0
	add_child(portal_light)
	
	# Info label
	info_label = Label3D.new()
	info_label.text = portal_name
	info_label.position = Vector3(0, portal_size + 0.5, 0)
	info_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(info_label)
	
	print("SequencePortal: Visual components created")

func _setup_interaction():
	"""Setup interaction detection"""
	interaction_area = Area3D.new()
	interaction_area.name = "InteractionArea"
	
	var collision_shape = CollisionShape3D.new()
	var shape = CylinderShape3D.new()
	shape.height = portal_size * 2
	shape.top_radius = portal_size
	shape.bottom_radius = portal_size
	collision_shape.shape = shape
	
	interaction_area.add_child(collision_shape)
	add_child(interaction_area)
	
	# Connect signals
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)
	interaction_area.area_entered.connect(_on_area_entered)
	
	print("SequencePortal: Interaction setup complete")

func _update_visual_style():
	"""Update visual appearance based on current state"""
	if not portal_mesh or not portal_mesh.material_override:
		return
	
	var material = portal_mesh.material_override as StandardMaterial3D
	if not material:
		return
	
	if is_portal_unlocked:
		# Unlocked: bright and inviting
		material.albedo_color = portal_color
		material.emission = portal_color * 0.5
		material.albedo_color.a = 0.8
		portal_light.light_energy = 2.0
		info_label.modulate = Color.WHITE
	else:
		# Locked: dim and grayed out
		material.albedo_color = portal_color * 0.3
		material.emission = portal_color * 0.1
		material.albedo_color.a = 0.3
		portal_light.light_energy = 0.5
		info_label.modulate = Color.GRAY

func _update_visibility():
	"""Update visibility based on unlock state"""
	visible = is_visible and (is_portal_unlocked or _should_show_locked())

func _should_show_locked() -> bool:
	"""Determine if locked portal should be visible as a preview"""
	# Show locked portals if they're close to being unlocked
	return true  # For now, always show

func _process(delta):
	if not visible:
		return
	
	# Rotate portal
	rotation_degrees.y += rotation_speed * delta
	
	# Pulse effect
	var pulse = sin(Time.get_time_dict_from_system().second * pulse_speed)
	if portal_light:
		var base_energy = 2.0 if is_portal_unlocked else 0.5
		portal_light.light_energy = base_energy + pulse * 0.5
	
	# Hover effect
	var hover_offset = sin(Time.get_time_dict_from_system().second * 1.5) * hover_height
	position.y += hover_offset * delta

func unlock():
	"""Unlock this portal"""
	if is_portal_unlocked:
		return
	
	print("SequencePortal: Unlocking portal '%s'" % portal_name)
	is_portal_unlocked = true
	is_visible = true
	_update_visual_style()
	_update_visibility()
	
	# Play unlock effect
	_play_unlock_effect()

func lock():
	"""Lock this portal"""
	print("SequencePortal: Locking portal '%s'" % portal_name)
	is_portal_unlocked = false
	_update_visual_style()

func show_portal():
	"""Make portal visible"""
	is_visible = true
	_update_visibility()

func hide_portal():
	"""Hide portal"""
	is_visible = false
	_update_visibility()

func _play_unlock_effect():
	"""Play visual effect when portal unlocks"""
	# TODO: Add particle effects, sound, etc.
	print("SequencePortal: Playing unlock effect for '%s'" % portal_name)

func _on_body_entered(body):
	"""Handle player entering portal area"""
	if not is_portal_unlocked:
		_show_locked_message()
		return
	
	if _is_player_body(body):
		print("SequencePortal: Player entered portal '%s'" % portal_name)
		portal_focused.emit(sequence_id)
		_start_entry_sequence(body)

func _on_body_exited(body):
	"""Handle player leaving portal area"""
	if _is_player_body(body):
		print("SequencePortal: Player left portal '%s'" % portal_name)
		portal_unfocused.emit(sequence_id)

func _on_area_entered(area):
	"""Handle area-based interaction"""
	if "Hand" in area.name and is_portal_unlocked:
		print("SequencePortal: Hand interaction with portal '%s'" % portal_name)
		_trigger_portal_entry()

func _start_entry_sequence(body):
	"""Start the portal entry sequence"""
	print("SequencePortal: Starting entry sequence for '%s'" % portal_name)
	
	# Add brief delay for dramatic effect
	await get_tree().create_timer(1.0).timeout
	_trigger_portal_entry()

func _trigger_portal_entry():
	"""Actually trigger the portal entry"""
	print("SequencePortal: Activating portal to '%s'" % sequence_id)
	portal_entered.emit(sequence_id)

func _show_locked_message():
	"""Show message when trying to enter locked portal"""
	print("SequencePortal: Portal '%s' is locked" % portal_name)
	# TODO: Show UI message about requirements

func _is_player_body(body: Node3D) -> bool:
	"""Check if body belongs to player"""
	return body.name.contains("Hand") or body.get_parent().name.contains("Hand")

# Public API
func is_unlocked() -> bool:
	return is_portal_unlocked

func get_sequence_id() -> String:
	return sequence_id

func get_portal_name() -> String:
	return portal_name

func get_requirements() -> Array[String]:
	return unlock_requirements

func can_be_unlocked(available_artifacts: Array[String]) -> bool:
	"""Check if portal can be unlocked with given artifacts"""
	for req in unlock_requirements:
		if not req in available_artifacts:
			return false
	return true 
