extends JointDemoBase

var wheel: RigidBody3D
var rod: RigidBody3D

func _build_demo():
	var base := StaticBody3D.new()
	base.name = "AxleBlock"
	base.position = Vector3(0.0, 2.0, 0.0)
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.6, 0.6, 0.6)
	collider.shape = shape
	base.add_child(collider)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.6, 0.6, 0.6)
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.35, 0.35, 0.4)
	mesh.material_override = mat
	base.add_child(mesh)
	add_child(base)

	wheel = create_cylinder("CrankWheel", 0.9, 0.3, Vector3(0.0, 2.0, 0.0), 3.0, Color(0.8, 0.3, 0.3))
	wheel.physics_material_override = PhysicsMaterial.new()
	wheel.physics_material_override.friction = 0.4

	rod = create_box("ConnectingRod", Vector3(1.8, 0.2, 0.2), Vector3(1.8, 2.0, 0.0), 1.5, Color(0.2, 0.6, 0.9))

	var hinge := HingeJoint3D.new()
	hinge.name = "WheelHinge"
	hinge.node_a = base.get_path()
	hinge.node_b = wheel.get_path()
	hinge.position = base.position
	hinge.rotation = Vector3.ZERO
	hinge.set_flag(HingeJoint3D.FLAG_USE_MOTOR, true)
	hinge.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, 2.5)
	hinge.set_param(HingeJoint3D.PARAM_MOTOR_MAX_TORQUE, 50.0)
	hinge.set_flag(HingeJoint3D.FLAG_USE_LIMIT, false)
	add_child(hinge)

	var link := PinJoint3D.new()
	link.name = "RodLink"
	link.node_a = wheel.get_path()
	link.node_b = rod.get_path()
	link.position = wheel.position + Vector3(0.9, 0.0, 0.0)
	link.set_exclude_nodes_from_collision(true)
	add_child(link)

	var guide := SliderJoint3D.new()
	guide.name = "RodGuide"
	guide.node_a = base.get_path()
	guide.node_b = rod.get_path()
	guide.position = Vector3(2.5, 2.0, 0.0)
	guide.set_flag(SliderJoint3D.FLAG_ENABLE_LINEAR_LIMIT, true)
	guide.set_param(SliderJoint3D.PARAM_LINEAR_LIMIT_LOWER, -0.8)
	guide.set_param(SliderJoint3D.PARAM_LINEAR_LIMIT_UPPER, 0.8)
	add_child(guide)

	add_label("Powered Hinge Crank", Vector3(1.5, 3.5, 2.5))


