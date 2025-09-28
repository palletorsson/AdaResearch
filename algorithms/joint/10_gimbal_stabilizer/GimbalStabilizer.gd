extends JointDemoBase

var yaw_hinge: HingeJoint3D
var pitch_hinge: HingeJoint3D

func _build_demo():
	var pedestal := create_static_box("Pedestal", Vector3(1.0, 1.5, 1.0), Vector3(0.0, 0.75, 0.0), Color(0.3, 0.3, 0.35))

	var yaw_frame := create_box("YawFrame", Vector3(0.4, 2.5, 2.5), Vector3(0.0, 2.8, 0.0), 5.0, Color(0.6, 0.6, 0.7))
	var pitch_frame := create_box("PitchFrame", Vector3(2.5, 0.4, 2.5), Vector3(0.0, 2.8, 0.0), 4.0, Color(0.55, 0.55, 0.7))
	var payload := create_box("Payload", Vector3(1.2, 0.8, 1.2), Vector3(0.0, 2.8, 0.0), 2.0, Color(0.9, 0.45, 0.2))

	yaw_hinge = HingeJoint3D.new()
	yaw_hinge.name = "YawJoint"
	yaw_hinge.node_a = pedestal.get_path()
	yaw_hinge.node_b = yaw_frame.get_path()
	yaw_hinge.position = Vector3(0.0, 2.0, 0.0)
	yaw_hinge.rotation = Vector3(0.0, 0.0, 0.0)
	yaw_hinge.set_flag(HingeJoint3D.FLAG_USE_LIMIT, false)
	yaw_hinge.set_flag(HingeJoint3D.FLAG_USE_MOTOR, true)
	yaw_hinge.set_param(HingeJoint3D.PARAM_MOTOR_MAX_TORQUE, 60.0)
	yaw_hinge.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, 0.0)
	add_child(yaw_hinge)

	pitch_hinge = HingeJoint3D.new()
	pitch_hinge.name = "PitchJoint"
	pitch_hinge.node_a = yaw_frame.get_path()
	pitch_hinge.node_b = pitch_frame.get_path()
	pitch_hinge.position = Vector3(0.0, 2.8, 0.0)
	pitch_hinge.rotation = Vector3(0.0, 0.0, deg_to_rad(90.0))
	pitch_hinge.set_flag(HingeJoint3D.FLAG_USE_LIMIT, true)
	pitch_hinge.set_param(HingeJoint3D.PARAM_LIMIT_LOWER, deg_to_rad(-45.0))
	pitch_hinge.set_param(HingeJoint3D.PARAM_LIMIT_UPPER, deg_to_rad(45.0))
	pitch_hinge.set_flag(HingeJoint3D.FLAG_USE_MOTOR, true)
	pitch_hinge.set_param(HingeJoint3D.PARAM_MOTOR_MAX_TORQUE, 40.0)
	pitch_hinge.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, 0.0)
	add_child(pitch_hinge)

	var payload_joint := PinJoint3D.new()
	payload_joint.node_a = pitch_frame.get_path()
	payload_joint.node_b = payload.get_path()
	payload_joint.position = payload.position
	payload_joint.set_exclude_nodes_from_collision(true)
	add_child(payload_joint)

	add_label("Dual Hinge Gimbal", Vector3(0.0, 4.5, 3.0))

func _physics_process(delta):
	var yaw_velocity := 0.0
	if Input.is_action_pressed("ui_left"):
		yaw_velocity = -1.5
	elif Input.is_action_pressed("ui_right"):
		yaw_velocity = 1.5
	yaw_hinge.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, yaw_velocity)

	var pitch_velocity := 0.0
	if Input.is_action_pressed("ui_up"):
		pitch_velocity = 1.2
	elif Input.is_action_pressed("ui_down"):
		pitch_velocity = -1.2
	pitch_hinge.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, pitch_velocity)
