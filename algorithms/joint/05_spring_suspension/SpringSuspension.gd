extends "res://algorithms/joint/shared/joint_demo_base.gd"

var wheel: RigidBody3D
var suspension: Generic6DOFJoint3D

func _build_demo():
	var chassis := create_static_box("Chassis", Vector3(4.0, 0.4, 2.0), Vector3(0.0, 3.0, 0.0), Color(0.5, 0.5, 0.6))

	wheel = create_cylinder("Wheel", 0.7, 0.4, Vector3(0.0, 1.6, 0.0), 2.0, Color(0.2, 0.2, 0.8))
	wheel.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	wheel.angular_damp = 0.8

	suspension = Generic6DOFJoint3D.new()
	suspension.name = "Suspension"
	suspension.node_a = chassis.get_path()
	suspension.node_b = wheel.get_path()
	suspension.position = Vector3(0.0, 2.6, 0.0)
	suspension.rotation = Vector3.ZERO
	# Lock lateral translation
	suspension.set_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, true)
	suspension.set_param_x(Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT, 0.0)
	suspension.set_param_x(Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT, 0.0)
	suspension.set_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, true)
	suspension.set_param_z(Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT, 0.0)
	suspension.set_param_z(Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT, 0.0)
	# Allow vertical travel with spring behaviour
	suspension.set_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, true)
	suspension.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT, -0.6)
	suspension.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT, 0.25)
	suspension.set_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_SPRING, true)
	suspension.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_SPRING_STIFFNESS, 30.0)
	suspension.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_SPRING_DAMPING, 3.5)
	# Lock rotations to keep wheel upright
	suspension.set_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT, true)
	suspension.set_param_x(Generic6DOFJoint3D.PARAM_ANGULAR_LOWER_LIMIT, 0.0)
	suspension.set_param_x(Generic6DOFJoint3D.PARAM_ANGULAR_UPPER_LIMIT, 0.0)
	suspension.set_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT, true)
	suspension.set_param_y(Generic6DOFJoint3D.PARAM_ANGULAR_LOWER_LIMIT, 0.0)
	suspension.set_param_y(Generic6DOFJoint3D.PARAM_ANGULAR_UPPER_LIMIT, 0.0)
	suspension.set_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT, true)
	suspension.set_param_z(Generic6DOFJoint3D.PARAM_ANGULAR_LOWER_LIMIT, 0.0)
	suspension.set_param_z(Generic6DOFJoint3D.PARAM_ANGULAR_UPPER_LIMIT, 0.0)
	suspension.set_exclude_nodes_from_collision(true)
	add_child(suspension)

	add_label("Damped Spring Suspension", Vector3(0.0, 4.2, 2.5))

func _process(delta):
	if Input.is_action_just_pressed("ui_accept"):
		wheel.apply_impulse(Vector3(0.0, 6.0, 0.0))
