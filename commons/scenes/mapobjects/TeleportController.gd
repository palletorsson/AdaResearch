# TeleportController.gd
# Chapter 7: The Teleporter Cube
# Handles teleportation with portal effects and scene transitions

extends "res://commons/primitives/cubes/VRGadgetController.gd"

@export var destination: String = ""
@export var activation_method: String = "touch"  # "touch", "proximity", "grab"
@export var portal_color: Color = Color.CYAN
@export var charge_time: float = 2.0

var portal_effect: GPUParticles3D
var beam_area: Area3D
var is_charging: bool = false
var charge_progress: float = 0.0
var players_in_beam: Array = []

# Teleporter-specific signals
signal teleporter_activated()
signal teleporter_charging(progress: float)
signal teleporter_ready()

func _ready():
	super()
	
	# Find teleporter components
	portal_effect = find_child("PortalEffect", false, false)
	beam_area = find_child("BeamArea", false, false)
	
	# Configure portal effect
	if portal_effect:
		portal_effect.emitting = false
		_configure_portal_effect()
	
	# Connect beam area for proximity activation
	if beam_area:
		beam_area.body_entered.connect(_on_player_entered_beam)
		beam_area.body_exited.connect(_on_player_exited_beam)
	
	print("TeleportController: Teleporter ready - destination: %s" % destination)

func _process(delta):
	super(delta)
	
	# Handle charging process
	if is_charging:
		charge_progress += delta / charge_time
		
		if charge_progress >= 1.0:
			_complete_teleport_charge()
		else:
			_update_charge_effects()
			teleporter_charging.emit(charge_progress)

func _configure_portal_effect():
	if not portal_effect:
		return
	
	# Set portal color and basic properties
	var material = portal_effect.process_material as ParticleProcessMaterial
	if material:
		material.color = portal_color
		material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE

func _on_player_entered_beam(body: Node3D):
	if _is_player_body(body):
		players_in_beam.append(body)
		print("TeleportController: Player entered teleport beam")
		
		if activation_method == "proximity":
			_start_teleport_sequence()

func _on_player_exited_beam(body: Node3D):
	if body in players_in_beam:
		players_in_beam.erase(body)
		print("TeleportController: Player exited teleport beam")
		
		if players_in_beam.is_empty() and is_charging:
			_cancel_teleport_sequence()

func _is_player_body(body: Node3D) -> bool:
	# Check if this is a player body (VR player, character body, etc.)
	return body.is_in_group("player") or "player" in body.name.to_lower()

# Override touch interaction for teleporter activation
func _trigger_touch_interaction(touch_position: Vector3):
	super(touch_position)
	
	if activation_method == "touch":
		_start_teleport_sequence()

# Override grab behavior for grab-based activation
func grabbed(grabber):
	super.grabbed(grabber)
	
	if activation_method == "grab":
		_start_teleport_sequence()

func _start_teleport_sequence():
	if is_charging or destination.is_empty():
		return
	
	print("TeleportController: Starting teleport sequence to: %s" % destination)
	is_charging = true
	charge_progress = 0.0
	
	# Start visual effects
	if portal_effect:
		portal_effect.emitting = true
	
	_start_charge_animation()

func _cancel_teleport_sequence():
	print("TeleportController: Teleport sequence cancelled")
	is_charging = false
	charge_progress = 0.0
	
	# Stop effects
	if portal_effect:
		portal_effect.emitting = false
	
	_stop_charge_animation()

func _complete_teleport_charge():
	print("TeleportController: Teleport fully charged - activating!")
	is_charging = false
	charge_progress = 1.0
	
	teleporter_ready.emit()
	
	# Trigger the actual teleportation
	_activate_teleporter()

func _activate_teleporter():
	print("TeleportController: 🚀 TELEPORTER ACTIVATED - Destination: %s" % destination)
	
	# Final visual effect
	_trigger_teleport_flash()
	
	# Emit the signal that grid system/scene manager will catch
	teleporter_activated.emit()
	
	# Reset state after brief delay
	await get_tree().create_timer(0.5).timeout
	_reset_teleporter_state()

func _trigger_teleport_flash():
	# Bright flash effect for teleportation
	if mesh_instance and mesh_instance.material_override:
		var material = mesh_instance.material_override as ShaderMaterial
		if material:
			material.set_shader_parameter("emissionColor", Color.WHITE)
			material.set_shader_parameter("emission_strength", 10.0)

func _reset_teleporter_state():
	# Reset all effects and state
	if portal_effect:
		portal_effect.emitting = false
	
	_stop_charge_animation()
	
	# Restore normal appearance
	if mesh_instance and mesh_instance.material_override:
		var material = mesh_instance.material_override as ShaderMaterial
		if material:
			material.set_shader_parameter("emissionColor", portal_color)
			material.set_shader_parameter("emission_strength", 2.0)

func _start_charge_animation():
	# Pulse effect during charging
	if animator:
		animator.scale_pulse_speed = 4.0
		animator.oscillation_speed = 3.0

func _stop_charge_animation():
	# Restore normal animation
	if animator:
		animator.scale_pulse_speed = 1.5
		animator.oscillation_speed = 2.0

func _update_charge_effects():
	# Update visual effects based on charge progress
	if mesh_instance and mesh_instance.material_override:
		var material = mesh_instance.material_override as ShaderMaterial
		if material:
			var intensity = 2.0 + charge_progress * 3.0
			material.set_shader_parameter("emission_strength", intensity)

# Public API
func set_destination(new_destination: String):
	destination = new_destination
	print("TeleportController: Destination set to: %s" % destination)

func get_destination() -> String:
	return destination

func is_teleporter_ready() -> bool:
	return not is_charging and not destination.is_empty()
