extends JointDemoBase

var seat: RigidBody3D

func _build_demo():
	var frame_left := create_static_box("FrameLeft", Vector3(0.4, 4.0, 0.4), Vector3(-2.0, 3.0, -1.5), Color(0.5, 0.5, 0.55))
	var frame_right := create_static_box("FrameRight", Vector3(0.4, 4.0, 0.4), Vector3(2.0, 3.0, -1.5), Color(0.5, 0.5, 0.55))

	var beam := create_static_box("TopBeam", Vector3(4.5, 0.4, 0.4), Vector3(0.0, 5.0, -1.5), Color(0.5, 0.5, 0.55))

	var anchor := StaticBody3D.new()
	anchor.name = "SwingAnchor"
	anchor.position = Vector3(0.0, 4.7, -1.5)
	add_child(anchor)

	var link_top := create_cylinder("LinkTop", 0.08, 1.0, Vector3(0.0, 3.9, -1.5), 0.5, Color(0.8, 0.8, 0.8))
	link_top.angular_damp = 0.1
	var link_bottom := create_cylinder("LinkBottom", 0.08, 1.0, Vector3(0.0, 2.9, -1.5), 0.5, Color(0.8, 0.8, 0.8))

	seat = create_box("Seat", Vector3(1.2, 0.2, 0.6), Vector3(0.0, 2.2, -1.5), 1.2, Color(0.9, 0.4, 0.2))
	seat.linear_damp = 0.05

	var joint_top := PinJoint3D.new()
	joint_top.node_a = anchor.get_path()
	joint_top.node_b = link_top.get_path()
	joint_top.position = anchor.position
	joint_top.set_exclude_nodes_from_collision(true)
	add_child(joint_top)

	var joint_mid := PinJoint3D.new()
	joint_mid.node_a = link_top.get_path()
	joint_mid.node_b = link_bottom.get_path()
	joint_mid.position = Vector3(0.0, 3.4, -1.5)
	joint_mid.set_exclude_nodes_from_collision(true)
	add_child(joint_mid)

	var joint_bottom := PinJoint3D.new()
	joint_bottom.node_a = link_bottom.get_path()
	joint_bottom.node_b = seat.get_path()
	joint_bottom.position = Vector3(0.0, 2.5, -1.5)
	joint_bottom.set_exclude_nodes_from_collision(true)
	add_child(joint_bottom)

	add_label("Chain Swing", Vector3(0.0, 4.0, -3.5))

func _process(delta):
	if Input.is_action_pressed("ui_right"):
		seat.apply_central_force(Vector3(5.0, 0.0, 0.0))
	elif Input.is_action_pressed("ui_left"):
		seat.apply_central_force(Vector3(-5.0, 0.0, 0.0))

