extends Node3D

# Simplified Learning Creature inspired by Carl Sims' approach
# This script creates a simple creature that learns to move through reinforcement learning

class_name SimplifiedCreature

# Body settings
@export var limb_length: float = 0.8
@export var limb_radius: float = 0.15
@export var torque_strength: float = 5.0
@export var creature_type: int = 0  # 0 = quadruped, 1 = biped, 2 = snake

# Learning parameters
@export var learning_rate: float = 0.1
@export var discount_factor: float = 0.95
@export var exploration_rate: float = 0.4
@export var exploration_decay: float = 0.995
@export var min_exploration_rate: float = 0.05
@export var update_frequency: float = 0.1

# References
var body_parts = []
var joints = []
var core_body = null
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
	
	# Create the body based on selected type
	match creature_type:
		0: create_quadruped()
		1: create_biped()
		2: create_snake()
		_: create_quadruped()
	
	# Initialize starting position
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

# Create a quadruped creature (4 legs)
func create_quadruped():
	# Create core body
	core_body = create_core()
	
	# Create 4 legs
	var leg_positions = [
		Vector3(1, 0, 1),   # Front right
		Vector3(1, 0, -1),  # Back right
		Vector3(-1, 0, 1),  # Front left
		Vector3(-1, 0, -1)  # Back left
	]
	
	for i in range(4):
		create_leg(core_body, leg_positions[i], i)

# Create a biped creature (2 legs)
func create_biped():
	# Create core body
	core_body = create_core()
	
	# Create 2 legs
	var leg_positions = [
		Vector3(0, 0, 0.6),  # Right leg
		Vector3(0, 0, -0.6)  # Left leg
	]
	
	for i in range(2):
		create_leg(core_body, leg_positions[i], i)

# Create a snake-like creature
func create_snake():
	# Create head segment
	core_body = create_segment(null, Vector3(0, 0.5, 0), 0)
	
	# Create body segments
	var prev_segment = core_body
	for i in range(1, 5):
		prev_segment = create_segment(prev_segment, Vector3(-limb_length * i, 0.5, 0), i)

func create_core():
	# Create the core body
	var core_body = RigidBody3D.new()
	core_body.name = "Core"
	core_body.mass = 3.0
	core_body.position = Vector3(0, limb_length + limb_radius, 0)
	
	var core_mesh = MeshInstance3D.new()
	core_mesh.mesh = BoxMesh.new()
	core_mesh.mesh.size = Vector3(limb_length * 2, limb_length * 0.5, limb_length * 1.5)
	
	var core_material = StandardMaterial3D.new()
	core_material.albedo_color = Color(0.8, 0.2, 0.2)
	core_mesh.material_override = core_material
	
	var core_collision = CollisionShape3D.new()
	var core_shape = BoxShape3D.new()
	core_shape.size = Vector3(limb_length * 2, limb_length * 0.5, limb_length * 1.5)
	core_collision.shape = core_shape
	
	core_body.add_child(core_mesh)
	core_body.add_child(core_collision)
	add_child(core_body)
	
	body_parts.append(core_body)
	return core_body

func create_leg(parent_body, offset, leg_index):
	# Calculate the attachment point on the parent
	var attach_pos = parent_body.position + Vector3(offset.x * limb_length, -limb_length * 0.25, offset.z * limb_length * 0.75)
	
	# Create upper leg
	var upper_leg = create_limb(
		"UpperLeg_" + str(leg_index), 
		attach_pos, 
		Vector3(0, -limb_length/2, 0)
	)
	
	# Create joint between core and upper leg
	var upper_joint = create_joint(
		parent_body, 
		upper_leg, 
		attach_pos,
		Vector3(-PI/6, -PI/6, -PI/6),  # Lower limits
		Vector3(PI/6, PI/6, PI/6)       # Upper limits
	)
	joints.append(upper_joint)
	
	# Create lower leg
	var lower_leg_pos = upper_leg.position + Vector3(0, -limb_length, 0)
	var lower_leg = create_limb(
		"LowerLeg_" + str(leg_index), 
		lower_leg_pos, 
		Vector3(0, -limb_length/2, 0)
	)
	
	# Create joint between upper and lower leg
	var knee_pos = upper_leg.position + Vector3(0, -limb_length, 0)
	var lower_joint = create_joint(
		upper_leg, 
		lower_leg, 
		knee_pos,
		Vector3(0, 0, 0),          # Lower limits (knees only bend in one direction)
		Vector3(PI/2, 0, 0)        # Upper limits
	)
	joints.append(lower_joint)
	
	# Create foot
	var foot_pos = lower_leg.position + Vector3(0, -limb_length, 0)
	var foot = create_limb(
		"Foot_" + str(leg_index), 
		foot_pos, 
		Vector3(0, -limb_radius/2, limb_length/2)
	)
	foot.scale = Vector3(limb_radius * 3, limb_radius, limb_length)
	
	# Create ankle joint
	var ankle_pos = lower_leg.position + Vector3(0, -limb_length, 0)
	var ankle_joint = create_joint(
		lower_leg, 
		foot, 
		ankle_pos,
		Vector3(-PI/6, -PI/6, -PI/6),  # Lower limits
		Vector3(PI/6, PI/6, PI/6)       # Upper limits
	)
	joints.append(ankle_joint)
	
	return upper_leg

func create_segment(parent_segment, position, segment_index):
	# Create a segment for snake-like creature
	var segment = RigidBody3D.new()
	segment.name = "Segment_" + str(segment_index)
	segment.mass = 1.0
	segment.position = position
	
	var segment_mesh = MeshInstance3D.new()
	segment_mesh.mesh = CapsuleMesh.new()
	segment_mesh.mesh.radius = limb_radius
	segment_mesh.mesh.height = limb_length
	
	var segment_material = StandardMaterial3D.new()
	segment_material.albedo_color = Color(0.2, 0.6, 0.8)
	segment_mesh.material_override = segment_material
	
	var segment_collision = CollisionShape3D.new()
	var segment_shape = CapsuleShape3D.new()
	segment_shape.radius = limb_radius
	segment_shape.height = limb_length
	segment_collision.shape = segment_shape
	
	# Rotate to horizontal position
	var segment_basis = Basis(Vector3(0, 0, 1), PI/2)
	segment_mesh.transform.basis = segment_basis
	segment_collision.transform.basis = segment_basis
	
	segment.add_child(segment_mesh)
	segment.add_child(segment_collision)
	add_child(segment)
	
	body_parts.append(segment)
	
	# Connect to previous segment if exists
	if parent_segment:
		var joint_pos = Vector3(
			(parent_segment.position.x + segment.position.x) / 2,
			segment.position.y,
			segment.position.z
		)
		
		var joint = create_joint(
			parent_segment,
			segment,
			joint_pos,
			Vector3(0, -PI/6, -PI/6),   # Lower limits
			Vector3(0, PI/6, PI/6)       # Upper limits
		)
		joints.append(joint)
	
	return segment

func create_limb(limb_name, position, scale_vec=Vector3(1,1,1)):
	# Create a limb
	var limb = RigidBody3D.new()
	limb.name = limb_name
	limb.mass = 1.0
	limb.position = position
	
	var limb_mesh = MeshInstance3D.new()
	limb_mesh.mesh = CapsuleMesh.new()
	limb_mesh.mesh.radius = limb_radius
	limb_mesh.mesh.height = limb_length
	
	var limb_material = StandardMaterial3D.new()
	limb_material.albedo_color = Color(0.2, 0.6, 0.8)
	limb_mesh.material_override = limb_material
	
	var limb_collision = CollisionShape3D.new()
	var limb_shape = CapsuleShape3D.new()
	limb_shape.radius = limb_radius
	limb_shape.height = limb_length
	limb_collision.shape = limb_shape
	
	limb.add_child(limb_mesh)
	limb.add_child(limb_collision)
	add_child(limb)
	
	body_parts.append(limb)
	return limb

func create_joint(body_a, body_b, joint_position, lower_limits, upper_limits):
	# Create a 6DOF joint
	var joint = Generic6DOFJoint3D.new()
	joint.name = "Joint_" + body_a.name + "_" + body_b.name
	joint.node_a = body_a.get_path()
	joint.node_b = body_b.get_path()
	
	# Set joint position
	joint.global_position = joint_position
	
	# Configure joint limits
	# X axis rotation (pitch)
	joint.set_param_x(Generic6DOFJoint3D.PARAM_ANGULAR_LOWER_LIMIT, lower_limits.x)
	joint.set_param_x(Generic6DOFJoint3D.PARAM_ANGULAR_UPPER_LIMIT, upper_limits.x)
	
	# Y axis rotation (yaw)
	joint.set_param_y(Generic6DOFJoint3D.PARAM_ANGULAR_LOWER_LIMIT, lower_limits.y)
	joint.set_param_y(Generic6DOFJoint3D.PARAM_ANGULAR_UPPER_LIMIT, upper_limits.y)
	
	# Z axis rotation (roll)
	joint.set_param_z(Generic6DOFJoint3D.PARAM_ANGULAR_LOWER_LIMIT, lower_limits.z)
	joint.set_param_z(Generic6DOFJoint3D.PARAM_ANGULAR_UPPER_LIMIT, upper_limits.z)
	
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
	# Initialize state vector (joint angles)
	state = []
	for joint in joints:
		state.append(0)  # x angle (simplified to discrete values)
		state.append(0)  # y angle
		state.append(0)  # z angle
	
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
	# Update state vector with current joint angles
	state = []
	for joint in joints:
		# Check if joint is valid
		if not is_instance_valid(joint):
			state.append(0)
			state.append(0)
			state.append(0)
			continue
			
		var body_a_path = joint.node_a
		var body_b_path = joint.node_b
		
		# Check if paths are valid
		if body_a_path.is_empty() or body_b_path.is_empty():
			state.append(0)
			state.append(0)
			state.append(0)
			continue
		
		var body_a = get_node_or_null(body_a_path)
		var body_b = get_node_or_null(body_b_path)
		
		# Check if nodes are valid
		if not body_a or not body_b:
			state.append(0)
			state.append(0)
			state.append(0)
			continue
		
		# Get relative rotation in joint space
		var rel_rot = body_a.global_transform.basis.inverse() * body_b.global_transform.basis
		var euler = rel_rot.get_euler()
		
		# Discretize angles (simplify the state space)
		state.append(discretize_angle(euler.x))
		state.append(discretize_angle(euler.y))
		state.append(discretize_angle(euler.z))

func discretize_angle(angle):
	# Convert continuous angle to discrete bucket (3 buckets)
	# -1 = negative angle, 0 = near zero, 1 = positive angle
	if angle < -0.2:
		return -1
	elif angle > 0.2:
		return 1
	else:
		return 0

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
			# Use -1, 0, or 1 as actions (simplified)
			action[i] = [-1.0, 0.0, 1.0][randi() % 3]
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
	
	# Penalize if the creature is tipping over
	var up_dir = core_body.global_transform.basis.y
	var up_alignment = up_dir.dot(Vector3.UP)
	if up_alignment < 0.7:  # Core body is tilting too much
		reward *= 0.5
	
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
	return current_distance < 0.1 and episode_reward > 5.0

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
		core_body.global_position = Vector3(0, limb_length + limb_radius, 0)
	
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
			elif event.keycode == KEY_1:
				# Switch to quadruped
				change_creature_type(0)
			elif event.keycode == KEY_2:
				# Switch to biped
				change_creature_type(1)
			elif event.keycode == KEY_3:
				# Switch to snake
				change_creature_type(2)

func change_creature_type(type):
	# Clean up existing creature
	for body in body_parts:
		if is_instance_valid(body):
			body.queue_free()
	
	for joint in joints:
		if is_instance_valid(joint):
			joint.queue_free()
	
	body_parts.clear()
	joints.clear()
	
	# Set new type
	creature_type = type
	
	# Create new creature
	match creature_type:
		0: create_quadruped()
		1: create_biped()
		2: create_snake()
		_: create_quadruped()
	
	# Reset learning
	starting_position = core_body.global_position if core_body else Vector3(0, 1, 0)
	last_position = starting_position
	
	path_points.clear()
	add_path_point(starting_position)
	
	episode_reward = 0.0
	episode_count = 0
	
	initialize_learning()
	start_learning()
