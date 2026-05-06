# Constrained Door - Two-phase axis-restricted movement
# Uses a small grab cube as doorknob, door mesh follows as child
# Phase 1: Slide up (Y axis only)
# Phase 2: Slide sideways (X axis only)
extends Node3D

signal phase_changed(phase: int)
signal goal_reached

@export var target_y: float = 0.3  # How far up to slide
@export var target_x: float = 0.0  # X distance to slide in phase 2
@export var y_threshold: float = 0.08
@export var x_threshold: float = 0.08
@export var door_color: Color = Color(0.8, 0.3, 0.3)
@export var door_width: float = 0.6
@export var door_height: float = 1.2
@export var door_depth: float = 0.04
@export var knob_height: float = 0.6  # Height of doorknob on door
@export var mirror_knob: bool = false  # Put knob on opposite side

var _knob: RigidBody3D  # Small grab cube as doorknob
var _door_mesh: MeshInstance3D  # Visual door
var _current_phase: int = 1
var _is_grabbed: bool = false
var _goal_reached: bool = false
var _locked_rotation: Basis = Basis.IDENTITY

func _ready() -> void:
	_create_door_mesh()
	_create_knob()

func _create_door_mesh() -> void:
	# Create the visual door panel
	_door_mesh = MeshInstance3D.new()
	_door_mesh.name = "DoorMesh"

	var box = BoxMesh.new()
	box.size = Vector3(door_width, door_height, door_depth)
	_door_mesh.mesh = box

	# Position so bottom of door is at Y=0
	_door_mesh.position.y = door_height / 2.0

	# Material
	var material = StandardMaterial3D.new()
	material.albedo_color = door_color
	material.emission_enabled = true
	material.emission = door_color * 0.4
	material.roughness = 0.8
	_door_mesh.material_override = material

	add_child(_door_mesh)

func _create_knob() -> void:
	# Load small grab cube as doorknob
	var grab_cube_scene = load("res://commons/primitives/cubes/grab_cube.tscn")
	_knob = grab_cube_scene.instantiate()
	_knob.name = "Knob"

	# Keep knob small (default 0.1 size is fine)
	_knob.scale = Vector3(1.2, 1.2, 1.2)  # Slightly larger for easier grabbing

	# Position knob on the door at handle height
	# mirror_knob puts it on the opposite (left) side
	var knob_x = door_width * 0.35 if not mirror_knob else -door_width * 0.35
	_knob.position = Vector3(knob_x, knob_height, door_depth)

	# Lock rotation
	_knob.lock_rotation = true
	_knob.angular_damp = 100.0

	# Connect signals
	if _knob.has_signal("picked_up"):
		_knob.picked_up.connect(_on_picked_up)
	if _knob.has_signal("dropped"):
		_knob.dropped.connect(_on_dropped)

	add_child(_knob)
	_locked_rotation = _knob.basis

func _on_picked_up(_pickable) -> void:
	_is_grabbed = true

func _on_dropped(_pickable) -> void:
	_is_grabbed = false

func _physics_process(_delta: float) -> void:
	if not _knob:
		return

	# Force no rotation
	_knob.basis = _locked_rotation
	_knob.angular_velocity = Vector3.ZERO

	# Get knob position
	var knob_pos = _knob.position
	var start_knob_x = door_width * 0.35 if not mirror_knob else -door_width * 0.35
	var start_knob_y = knob_height
	var start_knob_z = door_depth

	match _current_phase:
		1:  # Y axis only - SLIDE UP
			# Lock X and Z
			knob_pos.x = start_knob_x
			knob_pos.z = start_knob_z
			# Clamp Y
			knob_pos.y = clamp(knob_pos.y, start_knob_y, start_knob_y + target_y + 0.05)

			# Check if reached Y target
			var y_moved = knob_pos.y - start_knob_y
			if y_moved >= target_y - y_threshold:
				_transition_to_phase_2()

		2:  # X axis only - SLIDE SIDEWAYS
			# Lock Y at raised position and Z
			knob_pos.y = start_knob_y + target_y
			knob_pos.z = start_knob_z
			# Allow X movement
			var x_min = min(start_knob_x, start_knob_x + target_x) - 0.02
			var x_max = max(start_knob_x, start_knob_x + target_x) + 0.02
			knob_pos.x = clamp(knob_pos.x, x_min, x_max)

			# Check if goal reached
			var x_moved = knob_pos.x - start_knob_x
			if not _goal_reached and abs(x_moved - target_x) < x_threshold:
				_goal_reached = true
				goal_reached.emit()

	# Apply constrained position to knob
	_knob.position = knob_pos

	# Move door mesh to follow knob movement
	var knob_offset_y = knob_pos.y - start_knob_y
	var knob_offset_x = knob_pos.x - start_knob_x
	_door_mesh.position.y = door_height / 2.0 + knob_offset_y
	_door_mesh.position.x = knob_offset_x

func _transition_to_phase_2() -> void:
	if _current_phase == 2:
		return
	_current_phase = 2
	phase_changed.emit(2)

func get_phase() -> int:
	return _current_phase

func is_goal_reached() -> bool:
	return _goal_reached

func reset() -> void:
	_current_phase = 1
	_goal_reached = false
	if _knob:
		var knob_x = door_width * 0.35 if not mirror_knob else -door_width * 0.35
		_knob.position = Vector3(knob_x, knob_height, door_depth)
	if _door_mesh:
		_door_mesh.position = Vector3(0, door_height / 2.0, 0)

# For compatibility with old code
func set_door_scale(_new_scale: Vector3) -> void:
	pass  # Door size is now set via exports
