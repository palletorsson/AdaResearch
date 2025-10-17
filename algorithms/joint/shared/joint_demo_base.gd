extends Node3D

class_name JointDemoBase

func _ready():
	_setup_environment()
	_build_demo()

func _setup_environment():
	var light := DirectionalLight3D.new()
	light.name = "SunLight"
	light.rotation_degrees = Vector3(-50.0, -35.0, 0.0)
	light.light_energy = 1.4
	add_child(light)
	var ambient := WorldEnvironment.new()
	ambient.environment = Environment.new()
	ambient.environment.background_color = Color(0.08, 0.09, 0.12)
	ambient.environment.background_mode = Environment.BG_COLOR
	add_child(ambient)
	# Floor removed - joint demos now float in space
	var camera := Camera3D.new()
	camera.name = "DemoCamera"
	camera.position = Vector3(12.0, 9.0, 14.0)
	camera.look_at(Vector3(0.0, 3.0, 0.0), Vector3.UP)
	camera.current = true
	add_child(camera)

func _build_demo():
	# To be implemented by subclasses.
	pass

func create_box(name: String, size: Vector3, position: Vector3, mass: float = 1.0, color: Color = Color(0.8, 0.8, 0.85)) -> RigidBody3D:
	var body := RigidBody3D.new()
	body.name = name
	body.mass = mass
	body.position = position
	body.can_sleep = false
	body.contact_monitor = true
	body.max_contacts_reported = 8
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collider.shape = shape
	body.add_child(collider)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.4
	mesh.material_override = material
	body.add_child(mesh)
	add_child(body)
	return body

func create_static_box(name: String, size: Vector3, position: Vector3, color: Color = Color(0.6, 0.6, 0.65)) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = name
	body.position = position
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collider.shape = shape
	body.add_child(collider)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.6
	mesh.material_override = material
	body.add_child(mesh)
	add_child(body)
	return body

func create_cylinder(name: String, radius: float, height: float, position: Vector3, mass: float = 1.0, color: Color = Color(0.9, 0.6, 0.3)) -> RigidBody3D:
	var body := RigidBody3D.new()
	body.name = name
	body.mass = mass
	body.position = position
	body.can_sleep = false
	body.contact_monitor = true
	body.max_contacts_reported = 8
	var collider := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = radius
	shape.height = height
	collider.shape = shape
	body.add_child(collider)
	var mesh := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.bottom_radius = radius
	cylinder.top_radius = radius
	cylinder.height = height
	mesh.mesh = cylinder
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.3
	mesh.material_override = material
	body.add_child(mesh)
	add_child(body)
	return body

func create_sphere(name: String, radius: float, position: Vector3, mass: float = 1.0, color: Color = Color(0.7, 0.9, 1.0)) -> RigidBody3D:
	var body := RigidBody3D.new()
	body.name = name
	body.mass = mass
	body.position = position
	body.can_sleep = false
	body.contact_monitor = true
	body.max_contacts_reported = 8
	var collider := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = radius
	collider.shape = shape
	body.add_child(collider)
	var mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = radius
	mesh.mesh = sphere
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.2
	mesh.material_override = material
	body.add_child(mesh)
	add_child(body)
	return body

func add_label(text: String, position: Vector3) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.font_size = 20
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = position
	label.modulate = Color(1, 1, 1, 0.9)
	add_child(label)
	return label

func get_arrow_start_position(arrow: Node) -> Vector3:
	var node: Node3D = arrow.get_node_or_null("lineContainer/GrabSphere")
	if node:
		return node.global_position
	return (arrow as Node3D).global_position

func get_arrow_end_position(arrow: Node) -> Vector3:
	var node: Node3D = arrow.get_node_or_null("lineContainer/GrabSphere2")
	if node:
		return node.global_position
	return (arrow as Node3D).global_position
