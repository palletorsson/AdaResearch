extends JointDemoBase

var bob: RigidBody3D

func _build_demo():
	var anchor := StaticBody3D.new()
	anchor.name = "Anchor"
	anchor.position = Vector3(0.0, 5.0, 0.0)
	var anchor_shape := CollisionShape3D.new()
	anchor_shape.shape = SphereShape3D.new()
	(anchor_shape.shape as SphereShape3D).radius = 0.2
	anchor.add_child(anchor_shape)
	var anchor_mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.2
	anchor_mesh.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.9, 0.4)
	anchor_mesh.material_override = mat
	anchor.add_child(anchor_mesh)
	add_child(anchor)

	bob = create_sphere("Bob", 0.45, Vector3(0.0, 2.5, 0.0), 2.0, Color(0.4, 0.7, 1.0))
	bob.linear_damp = 0.02
	bob.angular_damp = 0.02

	var joint := PinJoint3D.new()
	joint.name = "PinJoint"
	joint.node_a = anchor.get_path()
	joint.node_b = bob.get_path()
	joint.position = anchor.position
	joint.set_exclude_nodes_from_collision(true)
	add_child(joint)

	add_label("Pin Joint Pendulum", Vector3(0.0, 4.0, 2.5))

func _process(delta):
	if Input.is_action_just_pressed("ui_accept"):
		bob.apply_impulse(Vector3.RIGHT * 1.5 + Vector3.FORWARD * 0.8)

