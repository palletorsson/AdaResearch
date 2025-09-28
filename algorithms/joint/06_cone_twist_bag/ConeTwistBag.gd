extends JointDemoBase

var bag: RigidBody3D

func _build_demo():
	var beam := create_static_box("Beam", Vector3(6.0, 0.3, 0.5), Vector3(0.0, 5.0, 0.0), Color(0.4, 0.4, 0.45))

	var anchor := StaticBody3D.new()
	anchor.name = "BagAnchor"
	anchor.position = Vector3(0.0, 4.6, 0.0)
	var shape := CollisionShape3D.new()
	shape.shape = SphereShape3D.new()
	(shape.shape as SphereShape3D).radius = 0.15
	anchor.add_child(shape)
	add_child(anchor)

	bag = create_cylinder("PunchBag", 0.4, 1.4, Vector3(0.0, 2.5, 0.0), 3.5, Color(0.9, 0.3, 0.3))
	bag.linear_damp = 0.05
	bag.angular_damp = 0.1

	var joint := ConeTwistJoint3D.new()
	joint.name = "BagJoint"
	joint.node_a = anchor.get_path()
	joint.node_b = bag.get_path()
	joint.position = anchor.position
	joint.swing_span = deg_to_rad(45.0)
	joint.twist_span = deg_to_rad(15.0)
	joint.bias = 0.3
	joint.softness = 0.8
	joint.relaxation = 1.0
	joint.set_exclude_nodes_from_collision(true)
	add_child(joint)

	add_label("Cone Twist Punching Bag", Vector3(0.0, 4.0, 2.8))

func _process(delta):
	if Input.is_action_just_pressed("ui_accept"):
		bag.apply_impulse((Vector3.FORWARD + Vector3.RIGHT) * 4.0)

