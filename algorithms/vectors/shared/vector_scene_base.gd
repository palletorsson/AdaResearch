extends Node3D

class_name VectorSceneBase

const VECTOR_SCENE := preload("res://commons/primitives/line/line.tscn")

var environment_root: Node3D
var info_root: Node3D

func _ready():
	environment_root = Node3D.new()
	environment_root.name = "Environment"
	add_child(environment_root)
	info_root = Node3D.new()
	info_root.name = "Info"
	add_child(info_root)
	_create_origin_marker()

func spawn_vector(origin: Vector3, vector: Vector3, color: Color, name: String, allow_grab: bool = true) -> Node3D:
	var arrow: Node3D = VECTOR_SCENE.instantiate()
	arrow.name = name.replace(" ", "_")
	arrow.position = origin
	var line_node = arrow.get_node("lineContainer")
	if line_node:
		line_node.set("vector_name", name)
		line_node.set("line_color", color)
	var start_node: Node3D = arrow.get_node_or_null("lineContainer/GrabSphere")
	var end_node: Node3D = arrow.get_node_or_null("lineContainer/GrabSphere2")
	if start_node:
		start_node.position = Vector3.ZERO
	if end_node:
		end_node.position = vector
	if not allow_grab:
		_disable_grab_sphere(start_node)
		_disable_grab_sphere(end_node)
	add_child(arrow)
	return arrow

func update_vector(arrow: Node3D, vector: Vector3):
	if arrow == null:
		return
	var end_node: Node3D = arrow.get_node_or_null("lineContainer/GrabSphere2")
	if end_node:
		end_node.position = vector
	if arrow.has_method("refresh_connections"):
		arrow.refresh_connections()

func get_vector(arrow: Node) -> Vector3:
	if arrow == null:
		return Vector3.ZERO
	if arrow.has_method("get_vector"):
		return arrow.get_vector()
	var start_node: Node3D = arrow.get_node_or_null("lineContainer/GrabSphere")
	var end_node: Node3D = arrow.get_node_or_null("lineContainer/GrabSphere2")
	if start_node and end_node:
		return end_node.global_position - start_node.global_position
	return Vector3.ZERO

func create_axes(length: float = 3.0):
	var axes = [
		{ "dir": Vector3.RIGHT, "color": Color(1.0, 0.2, 0.2, 1.0), "label": "X" },
		{ "dir": Vector3.UP, "color": Color(0.2, 1.0, 0.2, 1.0), "label": "Y" },
		{ "dir": Vector3.BACK, "color": Color(0.2, 0.6, 1.0, 1.0), "label": "Z" }
	]
	for axis_data in axes:
		var axis_root = Node3D.new()
		axis_root.name = "%s_axis" % axis_data.label
		environment_root.add_child(axis_root)
		var cylinder = CylinderMesh.new()
		cylinder.height = length
		cylinder.top_radius = 0.01
		cylinder.bottom_radius = 0.01
		cylinder.radial_segments = 12
		var mesh = MeshInstance3D.new()
		mesh.mesh = cylinder
		mesh.material_override = _build_unlit_material(axis_data.color)
		mesh.transform.basis = _basis_from_direction(axis_data.dir)
		mesh.position = axis_data.dir * (length * 0.5)
		axis_root.add_child(mesh)
		var arrow_cone = CylinderMesh.new()
		arrow_cone.height = 0.2
		arrow_cone.bottom_radius = 0.05
		arrow_cone.top_radius = 0.0
		var tip = MeshInstance3D.new()
		tip.mesh = arrow_cone
		tip.material_override = _build_unlit_material(axis_data.color)
		tip.transform.basis = _basis_from_direction(axis_data.dir)
		tip.position = axis_data.dir * length
		axis_root.add_child(tip)
		var label = Label3D.new()
		label.text = axis_data.label
		label.font_size = 32
		label.modulate = axis_data.color
		label.position = axis_data.dir * (length + 0.25)
		environment_root.add_child(label)

func create_floor(size: float = 6.0, color: Color = Color(0.1, 0.1, 0.12, 1.0)):
	var plane = PlaneMesh.new()
	plane.size = Vector2(size, size)
	var floor = MeshInstance3D.new()
	floor.mesh = plane
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	material.metallic = 0.0
	material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	floor.material_override = material
	floor.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	floor.position = Vector3(0.0, -0.05, 0.0)
	environment_root.add_child(floor)

func create_info_panel(text: String, position: Vector3) -> Label3D:
	var label = Label3D.new()
	label.text = text
	label.font_size = 24
	label.modulate = Color(1.0, 1.0, 1.0, 0.9)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = position
	info_root.add_child(label)
	return label

func create_ball(position: Vector3, radius: float = 0.18, mass: float = 1.0, color: Color = Color(0.9, 0.4, 0.8, 1.0)) -> RigidBody3D:
	# Physics-enabled ball with collider and visible mesh
	var body := RigidBody3D.new()
	body.name = "Ball"
	body.position = position
	body.mass = mass
	body.can_sleep = false
	body.contact_monitor = true
	body.max_contacts_reported = 8

	var collider := CollisionShape3D.new()
	var sphere_shape := SphereShape3D.new()
	sphere_shape.radius = radius
	collider.shape = sphere_shape
	body.add_child(collider)

	var mesh := MeshInstance3D.new()
	var sphere_mesh := SphereMesh.new()
	sphere_mesh.radius = radius
	# Ensure perfect sphere dimensions
	sphere_mesh.height = radius * 2.0
	sphere_mesh.radial_segments = 32
	sphere_mesh.rings = 16
	mesh.mesh = sphere_mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color * 0.3
	material.roughness = 0.3
	mesh.material_override = material
	body.add_child(mesh)

	add_child(body)
	return body

func _disable_grab_sphere(grab_node: Node):
	if grab_node == null:
		return
	if grab_node.has_method("set_freeze_enabled"):
		grab_node.set_freeze_enabled(true)
	if grab_node.has_method("set_pickable"):
		grab_node.set_pickable(false)
	if grab_node.has_method("set_process"):
		grab_node.set_process(false)
	if grab_node.has_method("set_physics_process"):
		grab_node.set_physics_process(false)
	var collider: CollisionShape3D = grab_node.get_node_or_null("CollisionShape3D")
	if collider:
		collider.disabled = true
	var mesh = grab_node.get_node_or_null("MeshInstance3D")
	if mesh:
		mesh.visible = false
	var highlight = grab_node.get_node_or_null("HighlightRing")
	if highlight:
		highlight.visible = false
	var label = grab_node.get_node_or_null("Label3D")
	if label:
		label.visible = false

func _create_origin_marker():
	var mesh = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.05
	# Force perfect sphere dimensions to avoid any elongated appearance
	sphere.height = sphere.radius * 2.0
	sphere.radial_segments = 18
	sphere.rings = 12
	mesh.mesh = sphere
	mesh.scale = Vector3.ONE
	mesh.transform = Transform3D.IDENTITY
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 1.0, 1.0, 1.0)
	material.emission_enabled = true
	material.emission = Color(1.0, 1.0, 1.0, 1.0) * 0.5
	mesh.material_override = material
	environment_root.add_child(mesh)

func _build_unlit_material(color: Color) -> StandardMaterial3D:
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color * 0.8
	material.roughness = 0.2
	material.metallic = 0.0
	return material

func _basis_from_direction(direction: Vector3) -> Basis:
	var dir = direction.normalized()
	var up = Vector3.UP
	if abs(dir.dot(up)) > 0.999:
		up = Vector3.FORWARD
	var right = dir.cross(up).normalized()
	if right.length() <= 0.001:
		right = Vector3.RIGHT
		up = right.cross(dir).normalized()
	else:
		up = right.cross(dir).normalized()
	return Basis(right, dir, up)

func get_arrow_start_position(arrow: Node) -> Vector3:
	var node: Node3D = arrow.get_node_or_null("lineContainer/GrabSphere")
	if node:
		return node.global_position
	return arrow.global_position

func get_arrow_end_position(arrow: Node) -> Vector3:
	var node: Node3D = arrow.get_node_or_null("lineContainer/GrabSphere2")
	if node:
		return node.global_position
	return arrow.global_position
