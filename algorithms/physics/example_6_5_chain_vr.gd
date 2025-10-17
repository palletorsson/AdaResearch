# ===========================================================================
# NOC Example 6.5: Chain
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D

## Example 6.5: Chain/Rope
## Demonstrates Generic6DOFJoint3D for flexible connections
## Chapter 06: Physics Libraries

var chain_links: Array[RigidBody3D] = []
var chain_joints: Array[Generic6DOFJoint3D] = []
var anchor: StaticBody3D

# Chain parameters
@export var num_links: int = 8
@export var link_size: Vector3 = Vector3(0.05, 0.03, 0.03)
@export var link_spacing: float = 0.04

# UI
var info_label: Label3D
var grab_label: Label3D

# Interaction
var grabbed_link: RigidBody3D = null
var grab_joint: Generic6DOFJoint3D = null
var grab_anchor: Node3D = null
var controller_position: Vector3 = Vector3.ZERO

func _ready():

	# Create UI
	create_ui_labels()

	# Create chain
	create_chain()

	print("Example 6.5: Chain - Generic6DOFJoint3D flexible connections")

func _process(delta):
	# Animate controller position
	animate_controller(delta)

	# Update grabbed link
	if grabbed_link and grab_anchor:
		grab_anchor.global_position = controller_position

	update_info_label()

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			if grabbed_link:
				release_chain()
			else:
				grab_chain_end()
		elif event.keycode == KEY_R:
			reset()
		elif event.keycode == KEY_M:
			grab_middle_link()

func create_ui_labels():
	"""Create UI labels"""
	info_label = Label3D.new()
	info_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	info_label.font_size = 28
	info_label.outline_size = 4
	info_label.modulate = Color(1.0, 0.9, 1.0)
	info_label.position = Vector3(0, 0.6, 0)
	add_child(info_label)

	grab_label = Label3D.new()
	grab_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	grab_label.font_size = 18
	grab_label.modulate = Color(0.8, 1.0, 0.8)
	grab_label.position = Vector3(0, 0.5, 0)
	grab_label.text = "[SPACE] Grab End | [M] Grab Middle | [R] Reset"
	add_child(grab_label)

func update_info_label():
	"""Update info label"""
	if info_label:
		var status = "Swinging" if not grabbed_link else "Grabbed"
		info_label.text = "Chain (%d Links)\n%s" % [num_links, status]

func create_chain():
	"""Create chain with joints"""
	# Create anchor point at top
	create_anchor()

	# Create chain links
	var previous_link: Node3D = anchor

	for i in range(num_links):
		var link = create_link(i)
		chain_links.append(link)

		# Create joint connecting to previous link
		var joint = create_joint(previous_link, link, i)
		chain_joints.append(joint)

		previous_link = link

func create_anchor():
	"""Create static anchor point"""
	anchor = StaticBody3D.new()
	anchor.position = Vector3(0, 0.3, 0)
	add_child(anchor)

	# Visual anchor
	var mesh_instance = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.03
	mesh_instance.mesh = sphere

	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.7, 0.7, 0.7, 1.0)
	mesh_instance.material_override = material

	anchor.add_child(mesh_instance)

	# Collision
	var collision = CollisionShape3D.new()
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = 0.03
	collision.shape = sphere_shape
	anchor.add_child(collision)

func create_link(index: int) -> RigidBody3D:
	"""Create single chain link"""
	var link = RigidBody3D.new()
	link.position = anchor.position + Vector3(0, -(index + 1) * link_spacing, 0)
	link.mass = 0.2
	add_child(link)

	# Link mesh
	var mesh_instance = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = link_size
	mesh_instance.mesh = box

	var material = StandardMaterial3D.new()
	# Gradient from pink (top) to darker pink (bottom)
	var t = float(index) / float(num_links - 1)
	var color = Color(1.0, 0.6, 1.0).lerp(Color(0.8, 0.4, 0.7), t)
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color * 0.4
	material.emission_energy_multiplier = 0.6

	mesh_instance.material_override = material
	link.add_child(mesh_instance)

	# Collision
	var collision = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = link_size
	collision.shape = box_shape
	link.add_child(collision)

	return link

func create_joint(node_a: Node3D, node_b: Node3D, index: int) -> Generic6DOFJoint3D:
	"""Create 6DOF joint between two nodes"""
	var joint = Generic6DOFJoint3D.new()
	joint.node_a = node_a.get_path()
	joint.node_b = node_b.get_path()

	# Position joint between links
	if node_a == anchor:
		joint.position = anchor.position + Vector3(0, -link_spacing / 2, 0)
	else:
		joint.position = node_a.position + Vector3(0, -link_spacing / 2, 0)

	# Configure joint for chain-like behavior
	# Allow some angular movement but limit it

	# Linear limits (very tight - almost fixed position)
	for axis in ["x", "y", "z"]:
		joint.set("linear_limit_%s/enabled" % axis, true)
		joint.set("linear_limit_%s/upper_distance" % axis, 0.01)
		joint.set("linear_limit_%s/lower_distance" % axis, -0.01)

	# Angular limits (allow swinging)
	for axis in ["x", "y", "z"]:
		joint.set("angular_limit_%s/enabled" % axis, true)
		joint.set("angular_limit_%s/upper_angle" % axis, deg_to_rad(30))
		joint.set("angular_limit_%s/lower_angle" % axis, deg_to_rad(-30))
		joint.set("angular_limit_%s/softness" % axis, 0.9)
		joint.set("angular_limit_%s/damping" % axis, 1.0)

	add_child(joint)
	return joint

func animate_controller(delta: float):
	"""Animate controller position (simulates VR hand movement)"""
	var time = Time.get_ticks_msec() / 1000.0
	controller_position = Vector3(
		sin(time * 1.5) * 0.2,
		0.2 + cos(time * 1.2) * 0.1,
		cos(time * 1.3) * 0.15
	)

func grab_chain_end():
	"""Grab the last chain link"""
	if chain_links.is_empty():
		return

	grabbed_link = chain_links[chain_links.size() - 1]
	create_grab_joint()

func grab_middle_link():
	"""Grab middle chain link"""
	if chain_links.is_empty():
		return

	var middle_index = chain_links.size() / 2
	grabbed_link = chain_links[middle_index]
	create_grab_joint()

func create_grab_joint():
	"""Create grab joint to controller"""
	if not grabbed_link:
		return

	# Create anchor for controller
	grab_anchor = Node3D.new()
	add_child(grab_anchor)
	grab_anchor.global_position = controller_position

	# Create joint
	grab_joint = Generic6DOFJoint3D.new()
	grab_joint.node_a = grab_anchor.get_path()
	grab_joint.node_b = grabbed_link.get_path()

	# Tight grip (limited movement)
	for axis in ["x", "y", "z"]:
		grab_joint.set("linear_limit_%s/enabled" % axis, true)
		grab_joint.set("linear_limit_%s/upper_distance" % axis, 0.02)
		grab_joint.set("linear_limit_%s/lower_distance" % axis, -0.02)

	add_child(grab_joint)

	# Highlight grabbed link
	if grabbed_link.get_child_count() > 0:
		var mesh = grabbed_link.get_child(0)
		if mesh is MeshInstance3D and mesh.material_override:
			mesh.material_override.emission_energy_multiplier = 1.5

func release_chain():
	"""Release grabbed chain"""
	if grabbed_link:
		# Reset highlight
		if grabbed_link.get_child_count() > 0:
			var mesh = grabbed_link.get_child(0)
			if mesh is MeshInstance3D and mesh.material_override:
				mesh.material_override.emission_energy_multiplier = 0.6

	if grab_joint:
		grab_joint.queue_free()
		grab_joint = null

	if grab_anchor:
		grab_anchor.queue_free()
		grab_anchor = null

	grabbed_link = null

func reset():
	"""Reset chain"""
	release_chain()

	# Remove old chain
	for link in chain_links:
		link.queue_free()
	chain_links.clear()

	for joint in chain_joints:
		joint.queue_free()
	chain_joints.clear()

	if anchor:
		anchor.queue_free()

	# Recreate chain
	create_chain()
