extends JointDemoBase

var slider: SliderJoint3D
var timer := 0.0
var direction := 1.0

func _build_demo():
	var frame := StaticBody3D.new()
	frame.name = "Frame"
	frame.position = Vector3(0.0, 2.0, 0.0)
	var shape := CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	(shape.shape as BoxShape3D).size = Vector3(0.5, 4.0, 2.0)
	frame.add_child(shape)
	add_child(frame)

	var piston := create_box("Piston", Vector3(0.5, 0.8, 1.8), Vector3(1.5, 2.0, 0.0), 2.0, Color(0.8, 0.8, 0.3))
	piston.linear_damp = 0.2
	piston.angular_damp = 1.0

	slider = SliderJoint3D.new()
	slider.name = "PressSlider"
	slider.node_a = frame.get_path()
	slider.node_b = piston.get_path()
	slider.position = Vector3(0.75, 2.0, 0.0)
	slider.set_flag(SliderJoint3D.FLAG_ENABLE_LINEAR_LIMIT, true)
	slider.set_param(SliderJoint3D.PARAM_LINEAR_LIMIT_LOWER, -1.0)
	slider.set_param(SliderJoint3D.PARAM_LINEAR_LIMIT_UPPER, 1.0)
	slider.set_flag(SliderJoint3D.FLAG_ENABLE_LINEAR_SPRING, true)
	slider.set_param(SliderJoint3D.PARAM_LINEAR_SPRING_STIFFNESS, 10.0)
	slider.set_param(SliderJoint3D.PARAM_LINEAR_SPRING_DAMPING, 1.4)
	slider.set_flag(SliderJoint3D.FLAG_ENABLE_LINEAR_MOTOR, true)
	slider.set_param(SliderJoint3D.PARAM_LINEAR_MOTOR_TARGET_VELOCITY, 3.0)
	slider.set_param(SliderJoint3D.PARAM_LINEAR_MOTOR_FORCE_LIMIT, 100.0)
	slider.set_exclude_nodes_from_collision(true)
	add_child(slider)

	add_label("Slider Joint Piston Press", Vector3(1.5, 3.5, 2.5))

func _physics_process(delta):
	timer += delta
	if timer > 2.5:
		timer = 0.0
		direction *= -1.0
		slider.set_param(SliderJoint3D.PARAM_LINEAR_MOTOR_TARGET_VELOCITY, 3.0 * direction)



