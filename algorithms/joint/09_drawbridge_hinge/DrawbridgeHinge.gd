extends JointDemoBase

var hinge: HingeJoint3D

func _build_demo():
	var tower := create_static_box("Tower", Vector3(4.0, 6.0, 2.0), Vector3(-2.0, 3.0, 0.0), Color(0.45, 0.45, 0.5))

	var bridge := create_box("Bridge", Vector3(6.0, 0.4, 3.0), Vector3(1.5, 1.0, 0.0), 12.0, Color(0.5, 0.3, 0.2))

	hinge = HingeJoint3D.new()
	hinge.name = "BridgeHinge"
	hinge.node_a = tower.get_path()
	hinge.node_b = bridge.get_path()
	hinge.position = Vector3(-1.0, 1.8, 0.0)
	hinge.rotation = Vector3(0.0, 0.0, deg_to_rad(90.0))
	hinge.set_flag(HingeJoint3D.FLAG_USE_LIMIT, true)
	hinge.set_param(HingeJoint3D.PARAM_LIMIT_LOWER, deg_to_rad(-85.0))
	hinge.set_param(HingeJoint3D.PARAM_LIMIT_UPPER, deg_to_rad(5.0))
	hinge.set_flag(HingeJoint3D.FLAG_USE_MOTOR, true)
	hinge.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, 0.0)
	hinge.set_param(HingeJoint3D.PARAM_MOTOR_MAX_TORQUE, 120.0)
	hinge.set_exclude_nodes_from_collision(true)
	add_child(hinge)

	add_label("Motorised Drawbridge", Vector3(0.0, 4.0, 3.5))

func _physics_process(delta):
	var velocity := 0.0
	if Input.is_action_pressed("ui_up"):
		velocity = 1.2
	elif Input.is_action_pressed("ui_down"):
		velocity = -1.2
	hinge.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, velocity)


