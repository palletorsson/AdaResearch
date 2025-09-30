extends "res://algorithms/joint/shared/joint_demo_base.gd"

var lower: RigidBody3D

func _build_demo():
	var anchor := StaticBody3D.new()
	anchor.name = "Anchor"
	anchor.position = Vector3(0.0, 5.5, 0.0)
	var shape := CollisionShape3D.new()
	shape.shape = SphereShape3D.new()
	(shape.shape as SphereShape3D).radius = 0.2
	anchor.add_child(shape)
	add_child(anchor)

	var upper := create_cylinder("UpperRod", 0.12, 2.5, Vector3(0.0, 3.8, 0.0), 1.4, Color(0.8, 0.5, 0.3))
	upper.physics_material_override = PhysicsMaterial.new()
	upper.physics_material_override.friction = 0.2
	upper.physics_material_override.bounce = 0.1

	lower = create_cylinder("LowerRod", 0.12, 2.5, Vector3(0.0, 1.4, 0.0), 1.4, Color(0.3, 0.7, 0.9))

	var joint_top := PinJoint3D.new()
	joint_top.name = "JointTop"
	joint_top.node_a = anchor.get_path()
	joint_top.node_b = upper.get_path()
	joint_top.position = anchor.position
	joint_top.set_exclude_nodes_from_collision(true)
	add_child(joint_top)

	var joint_middle := PinJoint3D.new()
	joint_middle.name = "JointMiddle"
	joint_middle.node_a = upper.get_path()
	joint_middle.node_b = lower.get_path()
	joint_middle.position = upper.position - Vector3(0.0, 1.25, 0.0)
	joint_middle.set_exclude_nodes_from_collision(true)
	add_child(joint_middle)

	add_label("Double Pendulum", Vector3(0.0, 4.2, 3.0))
	# Nudge to start motion
	call_deferred("_nudge")

func _process(delta):
	if Input.is_action_just_pressed("ui_accept"):
		lower.apply_impulse(Vector3(2.0, 0.0, 1.0))

func _nudge():
	if is_instance_valid(lower):
		lower.apply_impulse(Vector3(1.2, 0.0, 0.6))
