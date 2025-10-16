# ===========================================================================
# NOC Example 8.6: Recursive Tree
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D

## Example 8.6: Recursive Tree
## 3D branching tree structure grown recursively
## Chapter 08: Fractals

@export var recursion_depth: int = 4
@export var branch_angle: float = 25.0  # Degrees
@export var length_reduction: float = 0.67
@export var thickness_reduction: float = 0.7
@export var animate_growth: bool = true

var branches: Array[MeshInstance3D] = []

# Animation
var current_growth_depth: int = 0
var growth_timer: float = 0.0
var growth_speed: float = 0.8  # Seconds per level

# Initial branch parameters
var initial_length: float = 0.15
var initial_thickness: float = 0.01

# UI
var info_label: Label3D
var angle_controller: ParameterController3D

# Pink gradient for branches (trunk to tips)
var trunk_color: Color = Color(0.8, 0.5, 0.7, 1.0)  # Purple-pink trunk
var branch_color: Color = Color(1.0, 0.7, 0.9, 1.0)  # Pink branches
var tip_color: Color = Color(1.0, 0.6, 1.0, 1.0)     # Bright pink tips

func _ready():
	# Create UI
	create_info_label()
	create_angle_controller()

	# Use scene/map position; no hardcoded override

	if animate_growth:
		current_growth_depth = 0
	else:
		grow_tree(Vector3.ZERO, Vector3.UP, initial_length, initial_thickness, recursion_depth)
		current_growth_depth = recursion_depth

	update_info_label()
	print("Example 8.6: Recursive Tree - Depth: %d, Angle: %.1f°" % [recursion_depth, branch_angle])

func _process(delta):
	if animate_growth and current_growth_depth < recursion_depth:
		growth_timer += delta
		if growth_timer >= growth_speed:
			growth_timer = 0.0
			current_growth_depth += 1
			clear_branches()
			grow_tree(Vector3.ZERO, Vector3.UP, initial_length, initial_thickness, current_growth_depth)
			update_info_label()

func create_info_label():
	"""Create info label"""
	info_label = Label3D.new()
	info_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	info_label.font_size = 28
	info_label.outline_size = 4
	info_label.modulate = Color(1.0, 0.9, 1.0)
	info_label.position = Vector3(0, 0.7, 0)
	add_child(info_label)

func create_angle_controller():
	"""Create 3D controller for branch angle"""
	angle_controller = ParameterController3D.new()
	angle_controller.parameter_name = "Branch Angle"
	angle_controller.min_value = 10.0
	angle_controller.max_value = 60.0
	angle_controller.default_value = branch_angle
	angle_controller.step_size = 1.0
	angle_controller.position = Vector3(0, 0.6, 0)
	angle_controller.value_changed.connect(_on_angle_changed)
	add_child(angle_controller)

func _on_angle_changed(new_angle: float):
	"""Update branch angle and redraw tree"""
	branch_angle = new_angle
	clear_branches()
	grow_tree(Vector3.ZERO, Vector3.UP, initial_length, initial_thickness, current_growth_depth)
	print("Branch angle changed to: %.1f°" % branch_angle)

func update_info_label():
	"""Update info label"""
	if info_label:
		var branch_count = branches.size()
		info_label.text = "Recursive Tree\nDepth: %d\nBranches: %d" % [current_growth_depth, branch_count]

func grow_tree(start_pos: Vector3, direction: Vector3, length: float, thickness: float, depth: int):
	"""Recursively grow the tree"""
	if depth <= 0 or length < 0.01:
		return

	# Calculate end position
	var end_pos = start_pos + direction * length

	# Create branch
	create_branch(start_pos, end_pos, thickness, depth)

	# Calculate color based on depth (gradient from trunk to tips)
	var depth_ratio = float(depth) / float(recursion_depth)

	# Create child branches
	if depth > 1:
		# Right branch
		var right_dir = rotate_vector_around_axis(direction, Vector3.FORWARD, deg_to_rad(branch_angle))
		grow_tree(end_pos, right_dir, length * length_reduction, thickness * thickness_reduction, depth - 1)

		# Left branch
		var left_dir = rotate_vector_around_axis(direction, Vector3.FORWARD, deg_to_rad(-branch_angle))
		grow_tree(end_pos, left_dir, length * length_reduction, thickness * thickness_reduction, depth - 1)

		# Optional: Add a middle branch for fuller tree
		if depth > 2:
			grow_tree(end_pos, direction, length * length_reduction * 0.8, thickness * thickness_reduction, depth - 2)

func create_branch(start: Vector3, end: Vector3, thickness: float, depth: int):
	"""Create a cylindrical branch"""
	var branch = MeshInstance3D.new()

	var direction = end - start
	var length = direction.length()
	var midpoint = start + direction / 2.0

	# Create cylinder
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = thickness
	cylinder.bottom_radius = thickness * 1.2  # Slightly thicker at bottom
	cylinder.height = length

	branch.mesh = cylinder
	branch.position = midpoint

	# Orient cylinder along the branch direction
	# CylinderMesh in Godot is aligned with Y-axis by default
	if length > 0.001:
		var direction_normalized = direction.normalized()
		# Create a basis that aligns Y-axis (cylinder's up) with the branch direction
		var basis = Basis()
		basis.y = direction_normalized
		# Choose perpendicular X axis
		var perp = Vector3.RIGHT
		if abs(direction_normalized.dot(Vector3.RIGHT)) > 0.9:
			perp = Vector3.FORWARD
		basis.x = perp.cross(direction_normalized).normalized()
		basis.z = basis.x.cross(direction_normalized).normalized()
		branch.basis = basis

	# Color gradient based on depth
	var depth_ratio = float(depth) / float(recursion_depth)
	var color = trunk_color.lerp(tip_color, 1.0 - depth_ratio)

	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color * 0.4
	material.emission_energy_multiplier = 0.6

	branch.material_override = material

	add_child(branch)
	branches.append(branch)

func rotate_vector_around_axis(vec: Vector3, axis: Vector3, angle: float) -> Vector3:
	"""Rotate a vector around an arbitrary axis"""
	var rotation_basis = Basis(axis.normalized(), angle)
	return rotation_basis * vec

func clear_branches():
	"""Clear all branches"""
	for branch in branches:
		branch.queue_free()
	branches.clear()

func increase_depth():
	"""Increase recursion depth"""
	recursion_depth += 1
	current_growth_depth = recursion_depth
	clear_branches()
	grow_tree(Vector3.ZERO, Vector3.UP, initial_length, initial_thickness, recursion_depth)
	update_info_label()
	print("Recursion depth increased to: %d" % recursion_depth)

func decrease_depth():
	"""Decrease recursion depth"""
	if recursion_depth > 1:
		recursion_depth -= 1
		current_growth_depth = recursion_depth
		clear_branches()
		grow_tree(Vector3.ZERO, Vector3.UP, initial_length, initial_thickness, recursion_depth)
		update_info_label()
		print("Recursion depth decreased to: %d" % recursion_depth)

func reset():
	"""Reset growth animation"""
	current_growth_depth = 0
	growth_timer = 0.0
	clear_branches()
	update_info_label()
	print("Tree reset")
