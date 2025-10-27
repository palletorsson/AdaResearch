# CubeAgentWalkController.gd
# Simple procedural walking controller for cube agents
# Uses sinusoidal joint movements to create walking motion

extends Node
class_name CubeAgentWalkController

# References
@export var agent_builder: CubeAgentBuilder
@export var walk_speed: float = 2.0
@export var step_frequency: float = 1.5  # Steps per second
@export var step_height: float = 50.0  # Force amplitude
@export var balance_strength: float = 20.0

# State
var time_elapsed: float = 0.0
var is_walking: bool = false
var walk_direction: Vector3 = Vector3.FORWARD

# Body part references (cached)
var left_leg_cubes: Array = []
var right_leg_cubes: Array = []
var left_arm_cubes: Array = []
var right_arm_cubes: Array = []
var torso_cubes: Array = []
var root_body: RigidBody3D = null

func _ready() -> void:
	if not agent_builder:
		agent_builder = get_parent() as CubeAgentBuilder

	if agent_builder:
		# Wait for agent to be built
		if agent_builder.agent_built.is_connected(_on_agent_built):
			return
		agent_builder.agent_built.connect(_on_agent_built)
	else:
		push_error("CubeAgentWalkController: No agent builder found!")

func _on_agent_built() -> void:
	print("CubeAgentWalkController: Agent built, caching body parts...")
	_cache_body_parts()

	# Start walking automatically for testing
	start_walking(Vector3.FORWARD)

func _cache_body_parts() -> void:
	if not agent_builder:
		return

	left_leg_cubes = agent_builder.get_body_part("left_leg")
	right_leg_cubes = agent_builder.get_body_part("right_leg")
	left_arm_cubes = agent_builder.get_body_part("left_arm")
	right_arm_cubes = agent_builder.get_body_part("right_arm")
	torso_cubes = agent_builder.get_body_part("torso")
	root_body = agent_builder.get_root_body()

	print("CubeAgentWalkController: Cached %d body parts" % (
		left_leg_cubes.size() + right_leg_cubes.size() +
		left_arm_cubes.size() + right_arm_cubes.size() + torso_cubes.size()
	))

func _physics_process(delta: float) -> void:
	if not is_walking or not root_body:
		return

	time_elapsed += delta

	# Apply walking forces
	_apply_leg_movement(delta)
	_apply_arm_swing(delta)
	_apply_balance(delta)
	_apply_forward_movement(delta)

func _apply_leg_movement(delta: float) -> void:
	# Alternating leg movement using sine waves
	var phase = time_elapsed * step_frequency * TAU

	# Left leg (starts forward)
	var left_phase = sin(phase)
	var left_force_y = step_height * max(0, left_phase)  # Only push up
	var left_force_z = step_height * left_phase * 0.5  # Forward/backward

	for cube in left_leg_cubes:
		if cube is RigidBody3D:
			cube.apply_central_force(Vector3(0, left_force_y, left_force_z))

	# Right leg (opposite phase)
	var right_phase = sin(phase + PI)
	var right_force_y = step_height * max(0, right_phase)
	var right_force_z = step_height * right_phase * 0.5

	for cube in right_leg_cubes:
		if cube is RigidBody3D:
			cube.apply_central_force(Vector3(0, right_force_y, right_force_z))

func _apply_arm_swing(delta: float) -> void:
	# Arms swing opposite to legs for natural walking
	var phase = time_elapsed * step_frequency * TAU

	# Left arm (swings opposite to left leg)
	var left_swing = sin(phase + PI) * 20.0
	for cube in left_arm_cubes:
		if cube is RigidBody3D:
			cube.apply_torque(Vector3(left_swing * 0.1, 0, left_swing))

	# Right arm (swings opposite to right leg)
	var right_swing = sin(phase) * 20.0
	for cube in right_arm_cubes:
		if cube is RigidBody3D:
			cube.apply_torque(Vector3(right_swing * 0.1, 0, right_swing))

func _apply_balance(delta: float) -> void:
	if not root_body:
		return

	# Keep torso upright
	var current_rotation = root_body.global_transform.basis.get_euler()

	# Calculate corrective torque to keep upright
	var target_rotation = Vector3.ZERO
	var rotation_error = target_rotation - current_rotation

	# Apply corrective torque
	var balance_torque = rotation_error * balance_strength
	root_body.apply_torque(balance_torque)

	# Also apply to torso cubes
	for cube in torso_cubes:
		if cube is RigidBody3D:
			cube.apply_torque(balance_torque * 0.3)

func _apply_forward_movement(delta: float) -> void:
	if not root_body:
		return

	# Apply forward force to move in walk direction
	var forward_force = walk_direction.normalized() * walk_speed
	root_body.apply_central_force(forward_force)

	# Also push torso forward
	for cube in torso_cubes:
		if cube is RigidBody3D:
			cube.apply_central_force(forward_force * 0.3)

# Public API

func start_walking(direction: Vector3 = Vector3.FORWARD) -> void:
	is_walking = true
	walk_direction = direction.normalized()
	print("CubeAgentWalkController: Started walking in direction %s" % direction)

func stop_walking() -> void:
	is_walking = false
	print("CubeAgentWalkController: Stopped walking")

func set_walk_direction(direction: Vector3) -> void:
	walk_direction = direction.normalized()

func set_walk_speed(speed: float) -> void:
	walk_speed = speed

func toggle_walking() -> void:
	if is_walking:
		stop_walking()
	else:
		start_walking()
