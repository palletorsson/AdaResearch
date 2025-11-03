# Part.gd
# Molecular part that can float idly or dock to a target position
# Designed for VR assembly of molecular/body/furniture structures
extends Node3D
class_name MolecularPart

@export_group("Float Behavior")
@export var idle_float_radius: float = 0.4
@export var idle_float_speed: float = 0.6
@export var float_noise_scale: float = 0.02

@export_group("Docking Behavior")
@export var dock_spring: float = 8.0
@export var dock_damp: float = 0.85
@export var dock_rotation_speed: float = 5.0

@export_group("Part Properties")
@export var part_id: String = ""
@export var part_type: String = ""
@export var part_mass: float = 0.5

# State
var target_active: bool = false
var target_pos: Vector3 = Vector3.ZERO
var target_rot: Basis = Basis.IDENTITY
var velocity: Vector3 = Vector3.ZERO
var time_offset: float = 0.0
var grabbed: bool = false  # Set by XR grab system

# References
var mesh_node: MeshInstance3D = null

func _ready() -> void:
	# Add random time offset for varied float patterns
	time_offset = randf() * TAU

	# Find mesh node
	mesh_node = get_node_or_null("Mesh")
	if not mesh_node:
		# Create mesh node if it doesn't exist
		mesh_node = MeshInstance3D.new()
		mesh_node.name = "Mesh"
		add_child(mesh_node)

func _process(delta: float) -> void:
	if grabbed:
		# Don't apply any automatic movement while grabbed
		velocity = Vector3.ZERO
		return

	if target_active:
		_dock_to_target(delta)
	else:
		_float_idle(delta)

func _dock_to_target(delta: float) -> void:
	"""Spring-based docking to target position"""
	var to_target = target_pos - global_position

	# Spring force toward target
	velocity = (velocity + to_target * dock_spring * delta) * dock_damp
	global_position += velocity * delta

	# Smooth rotation toward target
	if target_rot != Basis.IDENTITY:
		var current_basis = global_transform.basis
		global_transform.basis = current_basis.slerp(target_rot, dock_rotation_speed * delta)

func _float_idle(delta: float) -> void:
	"""Gentle floating motion using sine waves"""
	var t = Time.get_ticks_msec() / 1000.0 + time_offset
	var s = idle_float_speed

	# Multi-frequency sine wave for natural motion
	var offset = Vector3(
		sin(t * s) * cos(t * s * 0.7),
		sin(t * s * 1.3 + 1.7) * cos(t * s * 0.9),
		sin(t * s * 0.8 + 0.9) * cos(t * s * 1.1)
	) * float_noise_scale

	translate(offset)

	# Gentle rotation
	rotate_y(delta * 0.2)
	rotate_x(delta * 0.15)

func set_target(pos: Vector3, basis: Basis = Basis.IDENTITY) -> void:
	"""Set the target position and rotation for docking"""
	target_pos = pos
	target_rot = basis
	target_active = true
	velocity = Vector3.ZERO  # Reset velocity for smooth docking

func clear_target() -> void:
	"""Clear target and return to floating mode"""
	target_active = false
	velocity = Vector3.ZERO

func set_grabbed(is_grabbed: bool) -> void:
	"""Called by XR grab system"""
	grabbed = is_grabbed
	if grabbed:
		velocity = Vector3.ZERO

func is_docked() -> bool:
	"""Check if part is close to its target"""
	if not target_active:
		return false
	return global_position.distance_to(target_pos) < 0.05

func get_part_id() -> String:
	"""Return the part ID for assembly tracking"""
	return part_id

func get_part_type() -> String:
	"""Return the part type from catalog"""
	return part_type

func set_part_info(id: String, type: String) -> void:
	"""Set part identification info"""
	part_id = id
	part_type = type
