# CubeAgentBuilder.gd
# Builds an articulated cube-based character from agent_data.json
# Creates RigidBody3D cubes connected with Generic6DOFJoint3D joints

extends Node3D
class_name CubeAgentBuilder

# Agent properties
@export var agent_data_path: String = "res://commons/agent/agent_data.json"
@export var cube_size: float = 0.2  # Base cube size in meters
@export var cube_mass: float = 0.5  # Mass per cube
@export var joint_stiffness: float = 100.0
@export var joint_damping: float = 10.0

# Data structures
var agent_data: Dictionary = {}
var cube_bodies: Dictionary = {}  # Vector3i(x, y, z) -> RigidBody3D
var joints: Array[Generic6DOFJoint3D] = []
var body_parts: Dictionary = {
	"head": [],
	"torso": [],
	"left_arm": [],
	"right_arm": [],
	"left_leg": [],
	"right_leg": []
}

# References
var root_body: RigidBody3D = null  # Main torso body for control

# Signals
signal agent_built()
signal agent_build_failed(error: String)

func _ready() -> void:
	print("CubeAgentBuilder: Initializing...")
	build_agent()

func build_agent() -> void:
	print("CubeAgentBuilder: Building agent from %s" % agent_data_path)

	# Load agent data
	if not _load_agent_data():
		agent_build_failed.emit("Failed to load agent data")
		return

	# Generate cube bodies from structure
	_generate_cube_bodies()

	# Create joints
	_create_joints()

	# Classify body parts
	_classify_body_parts()

	# Set up physics properties
	_setup_physics()

	print("CubeAgentBuilder: Agent built successfully!")
	print("  Total cubes: %d" % cube_bodies.size())
	print("  Total joints: %d" % joints.size())
	agent_built.emit()

func _load_agent_data() -> bool:
	print("CubeAgentBuilder: Loading agent data from %s" % agent_data_path)

	if not FileAccess.file_exists(agent_data_path):
		push_error("CubeAgentBuilder: Agent data file not found: %s" % agent_data_path)
		return false

	var file = FileAccess.open(agent_data_path, FileAccess.READ)
	if not file:
		push_error("CubeAgentBuilder: Could not open agent data file")
		return false

	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_text)

	if parse_result != OK:
		push_error("CubeAgentBuilder: Failed to parse agent JSON: %s" % json.get_error_message())
		return false

	agent_data = json.data

	# Validate required fields
	if not agent_data.has("layers") or not agent_data["layers"].has("structure"):
		push_error("CubeAgentBuilder: Agent data missing required 'layers.structure' field")
		return false

	print("CubeAgentBuilder: Agent data loaded successfully")
	return true

func _generate_cube_bodies() -> void:
	print("CubeAgentBuilder: Generating cube bodies...")

	var structure = agent_data["layers"]["structure"]

	# Iterate through the grid (z, x format in JSON)
	for z in range(structure.size()):
		var row = structure[z]
		for x in range(row.size()):
			var height_str = str(row[x]).strip_edges()

			if height_str == "0" or height_str.is_empty():
				continue

			var height = float(height_str)
			if height <= 0.0:
				continue

			# Create stacked cubes for this grid position
			_create_cube_stack(x, z, height)

	print("CubeAgentBuilder: Created %d cube bodies" % cube_bodies.size())

func _create_cube_stack(grid_x: int, grid_z: int, height: float) -> void:
	# Calculate how many cubes to stack
	var num_cubes = max(1, int(ceil(height)))
	var cube_scale = height / float(num_cubes)

	var previous_body: RigidBody3D = null

	for y in range(num_cubes):
		var cube_body = _create_single_cube(grid_x, y, grid_z, cube_scale)

		if cube_body:
			# Store in dictionary
			cube_bodies[Vector3i(grid_x, y, grid_z)] = cube_body

			# Connect vertically stacked cubes with fixed joints
			if previous_body and y > 0:
				_create_fixed_joint(previous_body, cube_body)

			previous_body = cube_body

func _create_single_cube(grid_x: int, grid_y: int, grid_z: int, scale_factor: float) -> RigidBody3D:
	var cube_body = RigidBody3D.new()
	cube_body.name = "Cube_%d_%d_%d" % [grid_x, grid_y, grid_z]
	cube_body.mass = cube_mass * scale_factor

	# Calculate world position (center the agent)
	var world_x = (grid_x - 5.5) * cube_size
	var world_y = grid_y * cube_size * scale_factor + cube_size * scale_factor * 0.5
	var world_z = (grid_z - 6.0) * cube_size

	cube_body.position = Vector3(world_x, world_y, world_z)

	# Create mesh
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = BoxMesh.new()
	mesh_instance.mesh.size = Vector3(cube_size, cube_size * scale_factor, cube_size)

	# Create material
	var material = StandardMaterial3D.new()
	material.albedo_color = _get_cube_color(grid_x, grid_z)
	material.metallic = 0.3
	material.roughness = 0.7
	mesh_instance.material_override = material

	# Create collision shape
	var collision_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(cube_size, cube_size * scale_factor, cube_size)
	collision_shape.shape = box_shape

	cube_body.add_child(mesh_instance)
	cube_body.add_child(collision_shape)
	add_child(cube_body)

	return cube_body

func _get_cube_color(grid_x: int, grid_z: int) -> Color:
	# Color code body parts
	if grid_z == 0:
		return Color(1.0, 0.8, 0.6)  # Head - skin tone
	elif grid_z <= 2:
		return Color(0.9, 0.7, 0.5)  # Neck/shoulders
	elif grid_z <= 6:
		return Color(0.2, 0.4, 0.8)  # Torso - blue shirt
	elif grid_z <= 8:
		return Color(0.3, 0.3, 0.3)  # Upper legs - dark pants
	else:
		return Color(0.4, 0.3, 0.2)  # Lower legs/feet - shoes

func _create_joints() -> void:
	print("CubeAgentBuilder: Creating joints...")

	if not agent_data["layers"].has("joints"):
		print("CubeAgentBuilder: No joints layer found")
		return

	var joints_layer = agent_data["layers"]["joints"]

	for z in range(joints_layer.size()):
		var row = joints_layer[z]
		for x in range(row.size()):
			var joint_marker = str(row[x]).strip_edges()

			if joint_marker == "j":
				_create_joint_at_position(x, z)

	print("CubeAgentBuilder: Created %d joints" % joints.size())

func _create_joint_at_position(grid_x: int, grid_z: int) -> void:
	# Find the cube at this position
	var center_cube = _get_cube_at(grid_x, 0, grid_z)
	if not center_cube:
		print("CubeAgentBuilder: No cube found at joint position (%d, %d)" % [grid_x, grid_z])
		return

	# Find neighboring cubes to connect
	var neighbors = _get_neighbor_cubes(grid_x, grid_z)

	for neighbor in neighbors:
		if neighbor != center_cube:
			_create_articulated_joint(center_cube, neighbor, center_cube.position)

func _create_articulated_joint(body_a: RigidBody3D, body_b: RigidBody3D, joint_pos: Vector3) -> void:
	var joint = Generic6DOFJoint3D.new()
	joint.name = "Joint_%s_%s" % [body_a.name, body_b.name]

	# Set node paths
	joint.node_a = body_a.get_path()
	joint.node_b = body_b.get_path()

	# Position at midpoint
	joint.position = (body_a.position + body_b.position) * 0.5

	# Configure angular limits for realistic movement
	# X axis (pitch) - forward/backward bending
	joint.set_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT, true)
	joint.set_param_x(Generic6DOFJoint3D.PARAM_ANGULAR_LOWER_LIMIT, -PI/3)
	joint.set_param_x(Generic6DOFJoint3D.PARAM_ANGULAR_UPPER_LIMIT, PI/3)

	# Y axis (yaw) - left/right rotation
	joint.set_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT, true)
	joint.set_param_y(Generic6DOFJoint3D.PARAM_ANGULAR_LOWER_LIMIT, -PI/6)
	joint.set_param_y(Generic6DOFJoint3D.PARAM_ANGULAR_UPPER_LIMIT, PI/6)

	# Z axis (roll) - twisting
	joint.set_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT, true)
	joint.set_param_z(Generic6DOFJoint3D.PARAM_ANGULAR_LOWER_LIMIT, -PI/6)
	joint.set_param_z(Generic6DOFJoint3D.PARAM_ANGULAR_UPPER_LIMIT, PI/6)

	# Enable motors for control
	joint.set_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_MOTOR, true)
	joint.set_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_MOTOR, true)
	joint.set_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_MOTOR, true)

	# Set motor parameters
	joint.set_param_x(Generic6DOFJoint3D.PARAM_ANGULAR_MOTOR_TARGET_VELOCITY, 0.0)
	joint.set_param_x(Generic6DOFJoint3D.PARAM_ANGULAR_MOTOR_FORCE_LIMIT, joint_stiffness)

	# Disable linear motion (keep parts together)
	joint.set_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, true)
	joint.set_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, true)
	joint.set_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, true)

	joint.set_param_x(Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT, 0)
	joint.set_param_x(Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT, 0)
	joint.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT, 0)
	joint.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT, 0)
	joint.set_param_z(Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT, 0)
	joint.set_param_z(Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT, 0)

	add_child(joint)
	joints.append(joint)

	print("  Created joint between %s and %s" % [body_a.name, body_b.name])

func _create_fixed_joint(body_a: RigidBody3D, body_b: RigidBody3D) -> void:
	# Create a rigid joint for vertically stacked cubes (no movement)
	var joint = Generic6DOFJoint3D.new()
	joint.name = "FixedJoint_%s_%s" % [body_a.name, body_b.name]

	joint.node_a = body_a.get_path()
	joint.node_b = body_b.get_path()
	joint.position = (body_a.position + body_b.position) * 0.5

	# Lock all axes
	for axis in [Vector3.AXIS_X, Vector3.AXIS_Y, Vector3.AXIS_Z]:
		joint.set_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, true)
		joint.set_param_x(Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT, 0)
		joint.set_param_x(Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT, 0)

		joint.set_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT, true)
		joint.set_param_x(Generic6DOFJoint3D.PARAM_ANGULAR_LOWER_LIMIT, 0)
		joint.set_param_x(Generic6DOFJoint3D.PARAM_ANGULAR_UPPER_LIMIT, 0)

	add_child(joint)

func _get_cube_at(grid_x: int, grid_y: int, grid_z: int) -> RigidBody3D:
	var key = Vector3i(grid_x, grid_y, grid_z)
	return cube_bodies.get(key, null)

func _get_neighbor_cubes(grid_x: int, grid_z: int) -> Array[RigidBody3D]:
	var neighbors: Array[RigidBody3D] = []

	# Check adjacent grid positions
	var offsets = [
		Vector2i(-1, 0), Vector2i(1, 0),  # Left, right
		Vector2i(0, -1), Vector2i(0, 1)   # Forward, back
	]

	for offset in offsets:
		var nx = grid_x + offset.x
		var nz = grid_z + offset.y

		# Check all Y levels for this grid position
		for y in range(5):  # Check up to 5 levels
			var neighbor = _get_cube_at(nx, y, nz)
			if neighbor:
				neighbors.append(neighbor)

	return neighbors

func _classify_body_parts() -> void:
	print("CubeAgentBuilder: Classifying body parts...")

	# Simple classification based on grid position
	for key in cube_bodies.keys():
		var cube = cube_bodies[key]
		var grid_x = key.x
		var grid_z = key.z

		if grid_z == 0:
			body_parts["head"].append(cube)
		elif grid_z == 1:
			body_parts["head"].append(cube)  # Neck with head
		elif grid_z == 2 and grid_x < 4:
			body_parts["left_arm"].append(cube)
		elif grid_z == 2 and grid_x > 7:
			body_parts["right_arm"].append(cube)
		elif grid_z <= 6:
			body_parts["torso"].append(cube)
			if not root_body and grid_z == 4:  # Set torso center as root
				root_body = cube
		elif grid_x < 5:
			body_parts["left_leg"].append(cube)
		else:
			body_parts["right_leg"].append(cube)

	print("  Head: %d cubes" % body_parts["head"].size())
	print("  Torso: %d cubes" % body_parts["torso"].size())
	print("  Left arm: %d cubes" % body_parts["left_arm"].size())
	print("  Right arm: %d cubes" % body_parts["right_arm"].size())
	print("  Left leg: %d cubes" % body_parts["left_leg"].size())
	print("  Right leg: %d cubes" % body_parts["right_leg"].size())

func _setup_physics() -> void:
	print("CubeAgentBuilder: Setting up physics properties...")

	# Set up collision layers
	for cube in cube_bodies.values():
		cube.collision_layer = 2  # Agent layer
		cube.collision_mask = 1 | 2  # Collide with world and other agents

		# Add some damping for stability
		cube.linear_damp = 0.5
		cube.angular_damp = 0.5

# Public API

func get_root_body() -> RigidBody3D:
	return root_body

func get_body_part(part_name: String) -> Array:
	return body_parts.get(part_name, [])

func get_all_cubes() -> Array:
	return cube_bodies.values()

func apply_force_to_part(part_name: String, force: Vector3) -> void:
	var parts = get_body_part(part_name)
	for cube in parts:
		if cube is RigidBody3D:
			cube.apply_central_force(force)
