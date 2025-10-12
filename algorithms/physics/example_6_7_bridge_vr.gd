# ===========================================================================
# NOC Example 6.7: Bridge
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D

## Example 6.7: Bridge
## Chain of rigid bodies connected by joints forming a bridge
## Chapter 06: Physics Libraries

var bridge_planks: Array[RigidBody3D] = []
var bridge_joints: Array[Generic6DOFJoint3D] = []
var left_anchor: StaticBody3D
var right_anchor: StaticBody3D

# Bridge parameters
@export var num_planks: int = 12
@export var plank_size: Vector3 = Vector3(0.12, 0.02, 0.08)
@export var plank_spacing: float = 0.005
@export var bridge_width: float = 0.8

# Test objects
var test_balls: Array[RigidBody3D] = []
var spawn_timer: float = 0.0
var auto_spawn: bool = true

# UI
var info_label: Label3D

func _ready():

	# Create UI
	create_info_label()

	# Create bridge
	create_bridge()

	print("Example 6.7: Bridge - Chain of joints forming suspension bridge")

func _process(delta):
	if auto_spawn:
		spawn_timer += delta
		if spawn_timer >= 2.0:
			spawn_timer = 0.0
			spawn_test_ball()

	# Clean up fallen balls
	cleanup_fallen_balls()

	update_info_label()

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			spawn_test_ball()
		elif event.keycode == KEY_R:
			reset()
		elif event.keycode == KEY_T:
			auto_spawn = !auto_spawn

func create_info_label():
	"""Create info label"""
	info_label = Label3D.new()
	info_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	info_label.font_size = 28
	info_label.outline_size = 4
	info_label.modulate = Color(1.0, 0.9, 1.0)
	info_label.position = Vector3(0, 0.6, 0)
	add_child(info_label)

	var instructions = Label3D.new()
	instructions.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	instructions.font_size = 18
	instructions.modulate = Color(0.8, 1.0, 0.8)
	instructions.position = Vector3(0, 0.5, 0)
	instructions.text = "[SPACE] Spawn Ball | [T] Toggle Auto | [R] Reset"
	add_child(instructions)

func update_info_label():
	"""Update info label"""
	if info_label:
		info_label.text = "Bridge (%d Planks)\nBalls: %d" % [num_planks, test_balls.size()]

func create_bridge():
	"""Create suspension bridge"""
	# Create anchors at both ends
	create_anchors()

	# Calculate plank width
	var total_plank_width = plank_size.x + plank_spacing
	var bridge_length = total_plank_width * num_planks

	# Starting position for first plank
	var start_x = -bridge_length / 2.0 + plank_size.x / 2.0

	# Create planks and connect them
	var previous_node: Node3D = left_anchor

	for i in range(num_planks):
		var x_pos = start_x + i * total_plank_width
		var plank = create_plank(Vector3(x_pos, 0.2, 0), i)
		bridge_planks.append(plank)

		# Create joint to previous plank/anchor
		var joint = create_bridge_joint(previous_node, plank, i)
		bridge_joints.append(joint)

		previous_node = plank

	# Connect last plank to right anchor
	var final_joint = create_bridge_joint(previous_node, right_anchor, num_planks)
	bridge_joints.append(final_joint)

func create_anchors():
	"""Create fixed anchor points at both ends"""
	var anchor_y = 0.25
	var anchor_spacing = bridge_width / 2.0

	# Left anchor
	left_anchor = create_anchor(Vector3(-anchor_spacing, anchor_y, 0))
	add_child(left_anchor)

	# Right anchor
	right_anchor = create_anchor(Vector3(anchor_spacing, anchor_y, 0))
	add_child(right_anchor)

func create_anchor(pos: Vector3) -> StaticBody3D:
	"""Create single anchor point"""
	var anchor = StaticBody3D.new()
	anchor.position = pos

	# Visual
	var mesh_instance = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(0.06, 0.08, 0.06)
	mesh_instance.mesh = box

	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.5, 0.5, 0.5, 1.0)
	mesh_instance.material_override = material

	anchor.add_child(mesh_instance)

	# Collision
	var collision = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(0.06, 0.08, 0.06)
	collision.shape = box_shape
	anchor.add_child(collision)

	return anchor

func create_plank(pos: Vector3, index: int) -> RigidBody3D:
	"""Create single bridge plank"""
	var plank = RigidBody3D.new()
	plank.position = pos
	plank.mass = 0.5
	add_child(plank)

	# Plank mesh
	var mesh_instance = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = plank_size
	mesh_instance.mesh = box

	var material = StandardMaterial3D.new()
	# Gradient along bridge
	var t = float(index) / float(num_planks - 1)
	var color = Color(1.0, 0.6, 1.0).lerp(Color(0.9, 0.5, 0.8), t)
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color * 0.3
	material.emission_energy_multiplier = 0.5

	mesh_instance.material_override = material
	plank.add_child(mesh_instance)

	# Collision
	var collision = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = plank_size
	collision.shape = box_shape
	plank.add_child(collision)

	return plank

func create_bridge_joint(node_a: Node3D, node_b: Node3D, index: int) -> Generic6DOFJoint3D:
	"""Create joint between bridge segments"""
	var joint = Generic6DOFJoint3D.new()
	joint.node_a = node_a.get_path()
	joint.node_b = node_b.get_path()

	# Position at connection point
	var connection_pos = Vector3.ZERO
	if node_a == left_anchor:
		connection_pos = left_anchor.global_position + Vector3(plank_size.x / 2.0, 0, 0)
	elif node_b == right_anchor:
		connection_pos = right_anchor.global_position - Vector3(plank_size.x / 2.0, 0, 0)
	else:
		connection_pos = node_a.global_position + Vector3(plank_size.x / 2.0 + plank_spacing / 2.0, 0, 0)

	joint.global_position = connection_pos

	# Configure joint for bridge-like flexibility
	# Linear: Very tight (planks stay connected)
	for axis in ["x", "y", "z"]:
		joint.set("linear_limit_%s/enabled" % axis, true)
		joint.set("linear_limit_%s/upper_distance" % axis, 0.005)
		joint.set("linear_limit_%s/lower_distance" % axis, -0.005)

	# Angular: Allow rotation for flexibility
	# X-axis (roll) - limited
	joint.set("angular_limit_x/enabled", true)
	joint.set("angular_limit_x/upper_angle", deg_to_rad(10))
	joint.set("angular_limit_x/lower_angle", deg_to_rad(-10))
	joint.set("angular_limit_x/softness", 0.8)

	# Y-axis (yaw) - very limited
	joint.set("angular_limit_y/enabled", true)
	joint.set("angular_limit_y/upper_angle", deg_to_rad(5))
	joint.set("angular_limit_y/lower_angle", deg_to_rad(-5))

	# Z-axis (pitch) - more flexible for bridge sag
	joint.set("angular_limit_z/enabled", true)
	joint.set("angular_limit_z/upper_angle", deg_to_rad(20))
	joint.set("angular_limit_z/lower_angle", deg_to_rad(-20))
	joint.set("angular_limit_z/softness", 0.9)
	joint.set("angular_limit_z/damping", 0.5)

	add_child(joint)
	return joint

func spawn_test_ball():
	"""Spawn ball to test bridge"""
	var ball = RigidBody3D.new()
	ball.position = Vector3(randf_range(-0.3, 0.3), 0.5, 0)
	ball.mass = 1.0
	add_child(ball)

	# Ball mesh
	var mesh_instance = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.04
	mesh_instance.mesh = sphere

	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.5, 0.5, 1.0, 1.0)
	material.emission_enabled = true
	material.emission = Color(0.5, 0.5, 1.0) * 0.5
	mesh_instance.material_override = material

	ball.add_child(mesh_instance)

	# Collision
	var collision = CollisionShape3D.new()
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = 0.04
	collision.shape = sphere_shape
	ball.add_child(collision)

	test_balls.append(ball)

func cleanup_fallen_balls():
	"""Remove balls that fell too far"""
	var to_remove: Array[RigidBody3D] = []

	for ball in test_balls:
		if ball.global_position.y < -0.5:
			to_remove.append(ball)

	for ball in to_remove:
		test_balls.erase(ball)
		ball.queue_free()

func reset():
	"""Reset bridge and balls"""
	# Remove test balls
	for ball in test_balls:
		ball.queue_free()
	test_balls.clear()

	# Remove old bridge
	for plank in bridge_planks:
		plank.queue_free()
	bridge_planks.clear()

	for joint in bridge_joints:
		joint.queue_free()
	bridge_joints.clear()

	if left_anchor:
		left_anchor.queue_free()
	if right_anchor:
		right_anchor.queue_free()

	# Recreate bridge
	spawn_timer = 0.0
	create_bridge()
