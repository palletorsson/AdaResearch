class_name Turtle3D
extends Node3D

## 3D Turtle Graphics for L-System visualization
## Chapter 08: Fractals

# Cursor state
var cursor_transform: Transform3D = Transform3D.IDENTITY

# Drawing settings
var branch_length: float = 0.1
var branch_thickness: float = 0.005
var angle: float = deg_to_rad(25)  # Default angle for turns

# Stack for push/pop operations
var state_stack: Array = []

# Visual elements
var branches: Array[MeshInstance3D] = []
var leaves: Array[MeshInstance3D] = []

# Colors
var branch_color: Color = Color(0.6, 0.4, 0.3, 1.0)  # Brown
var leaf_color: Color = Color(0.3, 0.8, 0.4, 1.0)    # Green
var pink_branch_color: Color = Color(1.0, 0.7, 0.9, 1.0)  # Pink (alternative)

@export var use_pink_palette: bool = true

func _ready():
	if use_pink_palette:
		branch_color = pink_branch_color
		leaf_color = Color(1.0, 0.6, 1.0, 1.0)  # Bright pink for leaves

func reset():
	"""Reset turtle to origin"""
	cursor_transform = Transform3D.IDENTITY
	state_stack.clear()

	# Clear all branches and leaves
	for branch in branches:
		branch.queue_free()
	for leaf in leaves:
		leaf.queue_free()

	branches.clear()
	leaves.clear()

func forward(length: float = -1.0):
	"""Move forward and draw a branch"""
	if length < 0:
		length = branch_length

	var start_pos = cursor_transform.origin
	# Move along local Y (Up) which is our Forward
	cursor_transform = cursor_transform.translated_local(Vector3.UP * length)
	var end_pos = cursor_transform.origin

	# Create branch mesh
	create_branch(start_pos, end_pos)

func move_forward(length: float = -1.0):
	"""Move forward without drawing"""
	if length < 0:
		length = branch_length
	cursor_transform = cursor_transform.translated_local(Vector3.UP * length)

func turn_left(angle_deg: float = -1.0):
	"""Rotate left (around Local Z axis - Yaw)"""
	var turn_angle = deg_to_rad(angle_deg) if angle_deg >= 0 else angle
	# Rotate around local Z (Back)
	cursor_transform.basis = cursor_transform.basis.rotated(cursor_transform.basis.z, turn_angle)

func turn_right(angle_deg: float = -1.0):
	"""Rotate right (around Local Z axis - Yaw)"""
	var turn_angle = deg_to_rad(angle_deg) if angle_deg >= 0 else angle
	cursor_transform.basis = cursor_transform.basis.rotated(cursor_transform.basis.z, -turn_angle)

func pitch_up(angle_deg: float = -1.0):
	"""Rotate up (around Local X axis - Pitch)"""
	var turn_angle = deg_to_rad(angle_deg) if angle_deg >= 0 else angle
	# Rotate around local X (Right)
	cursor_transform.basis = cursor_transform.basis.rotated(cursor_transform.basis.x, turn_angle)

func pitch_down(angle_deg: float = -1.0):
	"""Rotate down (around Local X axis - Pitch)"""
	var turn_angle = deg_to_rad(angle_deg) if angle_deg >= 0 else angle
	cursor_transform.basis = cursor_transform.basis.rotated(cursor_transform.basis.x, -turn_angle)

func roll_clockwise(angle_deg: float = -1.0):
	"""Roll clockwise (around Local Y axis - Roll)"""
	var turn_angle = deg_to_rad(angle_deg) if angle_deg >= 0 else angle
	# Rotate around local Y (Forward/Up)
	cursor_transform.basis = cursor_transform.basis.rotated(cursor_transform.basis.y, turn_angle)

func roll_counterclockwise(angle_deg: float = -1.0):
	"""Roll counter-clockwise (around Local Y axis - Roll)"""
	var turn_angle = deg_to_rad(angle_deg) if angle_deg >= 0 else angle
	cursor_transform.basis = cursor_transform.basis.rotated(cursor_transform.basis.y, -turn_angle)

func push_state():
	"""Save current state to stack"""
	state_stack.append(cursor_transform)

func pop_state():
	"""Restore state from stack"""
	if state_stack.is_empty():
		return
	cursor_transform = state_stack.pop_back()

func create_branch(start: Vector3, end: Vector3):
	"""Create a cylindrical branch between two points"""
	var branch = MeshInstance3D.new()

	var direction = end - start
	var length = direction.length()
	var midpoint = start + direction / 2.0

	# Create cylinder
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = branch_thickness
	cylinder.bottom_radius = branch_thickness
	cylinder.height = length

	branch.mesh = cylinder
	branch.position = midpoint

	# Orient cylinder to match turtle's rotation
	# Since we move along local Y (Up), and Cylinder is Y-aligned, 
	# we can just copy the basis.
	branch.basis = cursor_transform.basis

	# Material
	var material = StandardMaterial3D.new()
	material.albedo_color = branch_color
	material.emission_enabled = true
	material.emission = branch_color * 0.3
	branch.material_override = material

	add_child(branch)
	branches.append(branch)

func create_leaf():
	"""Create a leaf at current position"""
	var leaf = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = branch_thickness * 2
	sphere.height = branch_thickness * 4
	leaf.mesh = sphere

	leaf.position = cursor_transform.origin

	var material = StandardMaterial3D.new()
	material.albedo_color = leaf_color
	material.emission_enabled = true
	material.emission = leaf_color * 0.5
	leaf.material_override = material

	add_child(leaf)
	leaves.append(leaf)

func interpret_lsystem(instructions: String, step_length: float = 0.1, turn_angle: float = 25.0):
	"""Interpret L-System string and draw"""
	reset()
	branch_length = step_length
	angle = deg_to_rad(turn_angle)

	for char in instructions:
		match char:
			"F":  # Move forward and draw
				forward()
			"G":  # Move forward and draw (alternative)
				forward()
			"f":  # Move forward without drawing
				move_forward()
			"+":  # Turn left
				turn_left()
			"-":  # Turn right
				turn_right()
			"&":  # Pitch down
				pitch_down()
			"^":  # Pitch up
				pitch_up()
			"\\": # Roll left
				roll_counterclockwise()
			"/":  # Roll right
				roll_clockwise()
			"<":  # Roll left (alias)
				roll_counterclockwise()
			">":  # Roll right (alias)
				roll_clockwise()
			"|":  # Turn around
				turn_left(180)
			"[":  # Push state
				push_state()
			"]":  # Pop state
				pop_state()
			"L":  # Draw leaf
				create_leaf()

func set_colors(branch_col: Color, leaf_col: Color):
	"""Set custom colors"""
	branch_color = branch_col
	leaf_color = leaf_col
