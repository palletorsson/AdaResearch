extends Node3D

# Reinforcement Learning Creature with Random Joints
# This script creates a creature with random joints that learns to move through reinforcement learning

class_name RLCreature

# Settings for body generation
@export var num_limbs: int = 5
@export var min_limb_length: float = 0.5
@export var max_limb_length: float = 1.5
@export var limb_radius: float = 0.1
@export var joint_size: float = 0.15
@export var torque_strength: float = 2.0

# Learning parameters
@export var learning_rate: float = 0.1
@export var discount_factor: float = 0.9
@export var exploration_rate: float = 0.3
@export var exploration_decay: float = 0.995
@export var min_exploration_rate: float = 0.01
@export var update_frequency: float = 0.1

# References
var body_parts = []
var joints = []
var core_body = null  # Reference to the main body
var starting_position = Vector3.ZERO
var last_position = Vector3.ZERO
var current_distance = 0.0

# Learning components
var q_table = {}
var state = []
var action = []
var timer = 0.0
var episode_reward = 0.0
var episode_count = 0

# Debug visualization
var path_points = []
var start_marker = null
var path_instance = null

# UI elements
var ui_root
var stats_label

func _ready():
	randomize()
	
	# Create the environment
	create_environment()
	
	# Create the UI
	create_ui()
	
	# Create debug visualization
	create_debug_visualization()
	
	# Create the body
	create_body()
	
	# Initialize starting position (use the core body position)
	starting_position = core_body.global_position if core_body else Vector3(0, 1, 0)
	last_position = starting_position
	
	# Add first path point
	add_path_point(starting_position)
	
	# Initialize state and action vectors
	initialize_learning()
	
	# Start training
	start_learning()

func _process(delta):
	# Update timer
	timer += delta
	
	# Calculate distance traveled horizontally (on X-Z plane)
	if core_body:
		var current_pos = core_body.global_position
		
		# Calculate horizontal distance (only X and Z coordinates)
		var horizontal_distance = Vector2(current_pos.x, current_pos.z).distance_to(Vector2(starting_position.x, starting_position.z))
		current_distance = horizontal_distance
		
		# Update path visualization periodically
		if fmod(timer, 0.5) < delta:
			add_path_point(current_pos)
	
	# Update UI
	update_ui()
	
	# Update learning at intervals
	if timer >= update_frequency:
		timer = 0.0
		update_learning()

func create_environment():
	# Create a floor
	var floor_mesh = PlaneMesh.new()
	floor_mesh.size = Vector2(50.0, 50.0)
	
	var floor_instance = MeshInstance3D.new()
	floor_instance.mesh = floor_mesh
	floor_instance.name = "Floor"
	
	var floor_material = StandardMaterial3D.new()
	floor_material.albedo_color = Color(0.3, 0.3, 0.3)
	floor_instance.material_override = floor_material
	
	var floor_body = StaticBody3D.new()
	floor_body.name = "FloorBody"
	
	var floor_collision = CollisionShape3D.new()
	var floor_shape = BoxShape3D.new()
	floor_shape.size = Vector3(50.0, 0.1, 50.0)
	floor_collision.shape = floor_shape
	
	floor_body.add_child(floor_collision)
	floor_instance.add_child(floor_body)
	add_child(floor_instance)
	
	# Setup grid for reference
	create_grid()
	
	# Set up camera
	var camera = Camera3D.new()
	camera.name = "Camera"
	camera.position = Vector3(0, 3, 8)
	camera.rotation = Vector3(-0.2, 0, 0)
	add_child(camera)

func create_grid():
	# Create a grid on the floor for distance reference
	var grid_lines = ImmediateMesh.new()
	var grid_instance = MeshInstance3D.new()
	grid_instance.mesh = grid_lines
	grid_instance.name = "Grid"
	
	var grid_material = StandardMaterial3D.new()
	grid_material.albedo_color = Color(0.5, 0.5, 0.5, 0.5)
	grid_instance.material_override = grid_material
	
	# Draw grid lines
	grid_lines.clear_surfaces()
	grid_lines.surface_begin(Mesh.PRIMITIVE_LINES, grid_material)
	
	var grid_size = 20
	var grid_step = 2.0
	
	for i in range(-grid_size, grid_size + 1):
		# X lines
		grid_lines.surface_add_vertex(Vector3(i * grid_step, 0.01, -grid_size * grid_step))
		grid_lines.surface_add_vertex(Vector3(i * grid_step, 0.01, grid_size * grid_step))
		
		# Z lines
		grid_lines.surface_add_vertex(Vector3(-grid_size * grid_step, 0.01, i * grid_step))
		grid_lines.surface_add_vertex(Vector3(grid_size * grid_step, 0.01, i * grid_step))
	
	grid_lines.surface_end()
	add_child(grid_instance)

func create_debug_visualization():
	# Create a node for path visualization
	path_instance = ImmediateMesh.new()
	var path_mesh_instance = MeshInstance3D.new()
	path_mesh_instance.mesh = path_instance
	path_mesh_instance.name = "PathVisualization"
	
	var path_material = StandardMaterial3D.new()
	path_material.albedo_color = Color(1.0, 0.5, 0.0)
	path_material.flags_unshaded = true
	path_mesh_instance.material_override = path_material
	
	add_child(path_mesh_instance)
	
	# Create start marker
	start_marker = CSGSphere3D.new()
	start_marker.name = "StartMarker"
	start_marker.radius = 0.2
	
	var marker_material = StandardMaterial3D.new()
	marker_material.albedo_color = Color(0.0, 1.0, 0.0)
	start_marker.material = marker_material
	
	add_child(start_marker)

func add_path_point(point):
	path_points.append(Vector3(point.x, 0.05, point.z))  # Keep y slightly above floor
	update_path_visualization()

func update_path_visualization():
	# Set start marker position
	if start_marker:
		start_marker.position = Vector3(starting_position.x, 0.2, starting_position.z)
	
	# Update path lines
	if path_instance and path_points.size() > 1:
		path_instance.clear_surfaces()
		path_instance.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
		
		for point in path_points:
			path_instance.surface_add_vertex(point)
		
		path_instance.surface_end()

func create_ui():
	ui_root = Control.new()
	ui_root.name = "UI"
	ui_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	stats_label = Label.new()
	stats_label.position = Vector2(20, 20)
	stats_label.size = Vector2(400, 200)
	
	ui_root.add_child(stats_label)
	add_child(ui_root)

func update_ui():
	var text = "Episode: %d\n" % episode_count
	text += "Distance: %.2f\n" % current_distance
	text += "Reward: %.2f\n" % episode_reward
	text += "Exploration Rate: %.2f\n" % exploration_rate
	
	if core_body:
		text += "Position: (%.1f, %.1f, %.1f)\n" % [
			core_body.global_position.x,
			core_body.global_position.y,
			core_body.global_position.z
		]
	
	stats_label.text = text

func create_body():
	# Create the core/center body
	core_body = create_core()
	
	# Create random limbs
	for i in range(num_limbs):
		create_limb(core_body, i)

func create_core():
	# Create the core body
	var core_body = RigidBody3D.new()
	core_body.name = "Core"
	core_body.mass = 2.0
	core_body.position = Vector3(0, 1, 0)
	
	var core_mesh = MeshInstance3D.new()
	core_mesh.mesh = SphereMesh.new()
	core_mesh.mesh.radius = 0.3
	core_mesh.mesh.height = 0.6
	
	var core_material = StandardMaterial3D.new()
	core_material.albedo_color = Color(0.9, 0.1, 0.1)
	core_mesh.material_override = core_material
	
	var core_collision = CollisionShape3D.new()
	var core_shape = SphereShape3D.new()
	core_shape.radius = 0.3
	core_collision.shape = core_shape
	
	core_body.add_child(core_mesh)
	core_body.add_child(core_collision)
	add_child(core_body)
	
	body_parts.append(core_body)
	return core_body

func create_limb(parent_body, limb_index):
	# Generate random limb properties
	var limb_length = randf_range(min_limb_length, max_limb_length)
	var angle_h = randf_range(0, TAU)
	var angle_v = randf_range(-PI/4, PI/4)
	
	# Calculate direction
	var direction = Vector3(
		cos(angle_h) * cos(angle_v),
		sin(angle_v),
		sin(angle_h) * cos(angle_v)
	).normalized()
	
	# Create limb
	var limb_body = RigidBody3D.new()
	limb_body.name = "Limb_" + str(limb_index)
	limb_body.mass = 1.0
	
	# Position the limb at an offset from the parent
	var parent_radius = 0.3 if parent_body.name == "Core" else limb_radius
	var offset = direction * (parent_radius + limb_length / 2 + joint_size)
	limb_body.position = parent_body.position + offset
	
	# Create limb mesh
	var limb_mesh = MeshInstance3D.new()
	limb_mesh.mesh = CylinderMesh.new()
	limb_mesh.mesh.top_radius = limb_radius
	limb_mesh.mesh.bottom_radius = limb_radius
	limb_mesh.mesh.height = limb_length
	
	# Align cylinder with direction
	var limb_basis = Basis()
	var up_vector = Vector3(0, 1, 0)
	if direction.normalized().dot(up_vector) < 0.99:
		# Create a basis that rotates from up to the direction vector
		var axis = up_vector.cross(direction).normalized()
		var angle = up_vector.angle_to(direction)
		limb_basis = Basis(axis, angle)
	limb_mesh.transform.basis = limb_basis
	
	# Create limb material
	var limb_material = StandardMaterial3D.new()
	limb_material.albedo_color = Color(0.2, 0.6, 0.8)
	limb_mesh.material_override = limb_material
	
	# Create limb collision
	var limb_collision = CollisionShape3D.new()
	var limb_shape = CylinderShape3D.new()
	limb_shape.radius = limb_radius
	limb_shape.height = limb_length
	limb_collision.shape = limb_shape
	limb_collision.transform.basis = limb_basis
	
	limb_body.add_child(limb_mesh)
	limb_body.add_child(limb_collision)
	add_child(limb_body)
	
	body_parts.append(limb_body)
	
	# Create joint
	var joint = create_joint(parent_body, limb_body, parent_body.position + direction * parent_radius)
	joints.append(joint)
	
	# Recursively create additional limbs with decreasing probability
	if randf() < 0.5 and limb_index < num_limbs - 1:
		create_limb(limb_body, limb_index + 1)
	
	return limb_body

func create_joint(body_a, body_b, joint_position):
	# Create a 6DOF joint
	var joint = Generic6DOFJoint3D.new()
	joint.name = "Joint_" + body_a.name + "_" + body_b.name
	joint.node_a = body_a.get_path()
	joint.node_b = body_b.get_path()
	
	# Set joint position
	joint.position = joint_position
	
	# Configure joint limits
	# X axis rotation (pitch)
	joint.set_param_x(Generic6DOFJoint3D.PARAM_ANGULAR_LOWER_LIMIT, -PI/4)
	joint.set_param_x(Generic6DOFJoint3D.PARAM_ANGULAR_UPPER_LIMIT, PI/4)
	
	# Y axis rotation (yaw)
	joint.set_param_y(Generic6DOFJoint3D.PARAM_ANGULAR_LOWER_LIMIT, -PI/4)
	joint.set_param_y(Generic6DOFJoint3D.PARAM_ANGULAR_UPPER_LIMIT, PI/4)
	
	# Z axis rotation (roll)
	joint.set_param_z(Generic6DOFJoint3D.PARAM_ANGULAR_LOWER_LIMIT, -PI/4)
	joint.set_param_z(Generic6DOFJoint3D.PARAM_ANGULAR_UPPER_LIMIT, PI/4)
	
	# Disable linear motion
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
	return joint

func initialize_learning():
	# Initialize state vector (joint angles and body velocities)
	state = []
	for joint in joints:
		state.append(0.0)  # x angle
		state.append(0.0)  # y angle
		state.append(0.0)  # z angle
	
	# Initialize action vector (torque to apply to each joint)
	action = []
	for i in range(joints.size() * 3):  # 3 axes per joint
		action.append(0.0)

func start_learning():
	# Initialize state
	update_state()
	
	# Start with a random action
	exploration_rate = 1.0
	choose_action()

func update_state():
	# Update state vector with current joint angles and body velocities
	state = []
	for joint in joints:
		# Check if joint is valid
		if not is_instance_valid(joint):
			state.append(0.0)
			state.append(0.0)
			state.append(0.0)
			continue
			
		var body_a_path = joint.node_a
		var body_b_path = joint.node_b
		
		# Check if paths are valid
		if body_a_path.is_empty() or body_b_path.is_empty():
			state.append(0.0)
			state.append(0.0)
			state.append(0.0)
			continue
		
		var body_a = get_node_or_null(body_a_path)
		var body_b = get_node_or_null(body_b_path)
		
		# Check if nodes are valid
		if not body_a or not body_b:
			state.append(0.0)
			state.append(0.0)
			state.append(0.0)
			continue
		
		# Get relative rotation in joint space
		var rel_rot = body_a.global_transform.basis.inverse() * body_b.global_transform.basis
		var euler = rel_rot.get_euler()
		
		# Add joint angles to state
		state.append(discretize_angle(euler.x))
		state.append(discretize_angle(euler.y))
		state.append(discretize_angle(euler.z))

func discretize_angle(angle):
	# Convert continuous angle to discrete bucket (5 buckets)
	return floor((angle + PI/2) * 5 / PI) as int

func get_state_key():
	# Convert state vector to string key for q-table
	return str(state)

func choose_action():
	var state_key = get_state_key()
	
	# Initialize state in q_table if not exists
	if not q_table.has(state_key):
		q_table[state_key] = []
		for i in range(action.size()):
			q_table[state_key].append(0.0)
	
	# Exploration vs exploitation
	if randf() < exploration_rate:
		# Explore: choose random action
		for i in range(action.size()):
			action[i] = randf_range(-1.0, 1.0)
	else:
		# Exploit: choose best action
		action = q_table[state_key].duplicate()
	
	# Apply action (torques to joints)
	apply_action()

func apply_action():
	# Apply torques to each joint based on action vector
	var action_idx = 0
	for joint_idx in range(joints.size()):
		if joint_idx >= joints.size() or action_idx + 2 >= action.size():
			break
			
		var joint = joints[joint_idx]
		
		# Check if joint is valid
		if not is_instance_valid(joint):
			action_idx += 3
			continue
			
		var body_b_path = joint.node_b
		
		if body_b_path.is_empty():
			action_idx += 3
			continue
			
		var body_b = get_node_or_null(body_b_path)
		if not body_b or not body_b is RigidBody3D:
			action_idx += 3
			continue
		
		# Apply torque around each axis
		var torque = Vector3(
			action[action_idx] * torque_strength,
			action[action_idx + 1] * torque_strength,
			action[action_idx + 2] * torque_strength
		)
		
		# Convert torque to global coordinates
		torque = body_b.global_transform.basis * torque
		body_b.apply_torque(torque)
		
		action_idx += 3

func update_learning():
	# Make sure core body exists
	if not core_body or not is_instance_valid(core_body):
		return
		
	# Calculate reward (distance moved from last position)
	var current_pos = core_body.global_position
	var dx = current_pos.x - last_position.x
	var dz = current_pos.z - last_position.z
	
	# Calculate distance moved
	var dist_moved = sqrt(dx*dx + dz*dz)
	
	# Calculate reward (prioritize forward movement)
	var reward = dist_moved
	
	# Bonus for moving forward along X axis
	if dx > 0:
		reward *= 1.5
	
	# Update episode reward
	episode_reward += reward
	
	# Get current state key
	var old_state_key = get_state_key()
	
	# Store current position for next update
	last_position = current_pos
	
	# Update state
	update_state()
	
	# Get new state key
	var new_state_key = get_state_key()
	
	# Initialize new state in q_table if not exists
	if not q_table.has(new_state_key):
		q_table[new_state_key] = []
		for i in range(action.size()):
			q_table[new_state_key].append(0.0)
	
	# Update Q-values using Q-learning formula
	for i in range(action.size()):
		if i >= q_table[old_state_key].size() or i >= q_table[new_state_key].size():
			break
			
		var old_q = q_table[old_state_key][i]
		
		# Find max future Q-value
		var max_future_q = 0.0
		if q_table[new_state_key].size() > 0:
			max_future_q = q_table[new_state_key].max()
			
		var new_q = old_q + learning_rate * (reward + discount_factor * max_future_q - old_q)
		q_table[old_state_key][i] = new_q
	
	# Choose next action
	choose_action()
	
	# Decay exploration rate
	exploration_rate = max(min_exploration_rate, exploration_rate * exploration_decay)
	
	# Check if episode should end (creature fell or stuck)
	if current_pos.y < 0.2 or is_stuck():
		end_episode()

func is_stuck():
	# Check if the creature is stuck (not moving for a while)
	return current_distance < 0.1 and episode_reward > 10.0

func end_episode():
	episode_count += 1
	print("Episode %d ended. Total reward: %.2f, Distance: %.2f" % [episode_count, episode_reward, current_distance])
	
	# Reset the creature
	for body in body_parts:
		if is_instance_valid(body):
			body.linear_velocity = Vector3.ZERO
			body.angular_velocity = Vector3.ZERO
	
	# Move back to starting position
	if is_instance_valid(core_body):
		core_body.global_position = Vector3(0, 1, 0)
	
	# Reset learning variables
	episode_reward = 0.0
	
	# Reset position tracking
	starting_position = core_body.global_position if core_body else Vector3(0, 1, 0)
	last_position = starting_position
	
	# Reset path visualization
	path_points.clear()
	add_path_point(starting_position)
	
	# Slightly increase exploration to try new movements
	exploration_rate = min(exploration_rate * 1.2, 0.3)
	
	# Continue learning
	update_state()
	choose_action()

# Input for debugging and control
func _input(event):
	if event is InputEventKey:
		if event.pressed:
			if event.keycode == KEY_SPACE:
				# Reset creature
				end_episode()
			elif event.keycode == KEY_E:
				# Toggle exploration mode
				exploration_rate = 1.0 if exploration_rate < 0.5 else 0.01
