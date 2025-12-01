extends Node3D

class_name VectorSceneBase

const VECTOR_SCENE := preload("res://commons/primitives/line/line.tscn")
const SCENE_SCALE: float = 0.33

# Shared Resources (Lazy Initialization)
static var _shared_cylinder_mesh: CylinderMesh
static var _shared_cone_mesh: CylinderMesh
static var _shared_sphere_mesh: SphereMesh
static var _shared_ball_mesh: SphereMesh
static var _shared_floor_mesh: PlaneMesh
static var _material_cache: Dictionary = {} # Color (as String) -> StandardMaterial3D

var environment_root: Node3D
var info_root: Node3D

func _ready():
	environment_root = Node3D.new()
	environment_root.name = "Environment"
	add_child(environment_root)
	info_root = Node3D.new()
	info_root.name = "Info"
	add_child(info_root)
	_init_shared_resources()
	_create_origin_marker()

func _init_shared_resources():
	if _shared_cylinder_mesh == null:
		_shared_cylinder_mesh = CylinderMesh.new()
		_shared_cylinder_mesh.height = 1.0 # Unit height for scaling
		_shared_cylinder_mesh.top_radius = 0.01
		_shared_cylinder_mesh.bottom_radius = 0.01
		_shared_cylinder_mesh.radial_segments = 12

	if _shared_cone_mesh == null:
		_shared_cone_mesh = CylinderMesh.new()
		_shared_cone_mesh.height = 0.2
		_shared_cone_mesh.bottom_radius = 0.05
		_shared_cone_mesh.top_radius = 0.0
		_shared_cone_mesh.radial_segments = 16

	if _shared_sphere_mesh == null:
		_shared_sphere_mesh = SphereMesh.new()
		_shared_sphere_mesh.radius = 0.5 # Diameter 1.0
		_shared_sphere_mesh.height = 1.0
		_shared_sphere_mesh.radial_segments = 18
		_shared_sphere_mesh.rings = 12

	if _shared_ball_mesh == null:
		_shared_ball_mesh = SphereMesh.new()
		_shared_ball_mesh.radius = 0.5
		_shared_ball_mesh.height = 1.0
		_shared_ball_mesh.radial_segments = 32
		_shared_ball_mesh.rings = 16

	if _shared_floor_mesh == null:
		_shared_floor_mesh = PlaneMesh.new()
		_shared_floor_mesh.size = Vector2(1.0, 1.0) # Scale to size

func _get_shared_material(color: Color, unlit: bool = false) -> StandardMaterial3D:
	var key = str(color) + ("_unlit" if unlit else "_lit")
	if _material_cache.has(key):
		return _material_cache[key]
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	if unlit:
		mat.emission_enabled = true
		mat.emission = color * 0.8
		mat.roughness = 0.2
		mat.metallic = 0.0
	else:
		mat.roughness = 1.0
		mat.metallic = 0.0
		mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	
	_material_cache[key] = mat
	return mat

func spawn_vector(origin: Vector3, vector: Vector3, color: Color, name: String, allow_grab: bool = true) -> Node3D:
	var arrow: Node3D = VECTOR_SCENE.instantiate()
	arrow.name = name.replace(" ", "_")
	arrow.position = origin * SCENE_SCALE
	var line_node = arrow.get_node("lineContainer")
	if line_node:
		line_node.set("vector_name", name)
		line_node.set("line_color", color)
	var start_node: Node3D = arrow.get_node_or_null("lineContainer/GrabSphere")
	var end_node: Node3D = arrow.get_node_or_null("lineContainer/GrabSphere2")
	if start_node:
		start_node.position = Vector3.ZERO
	if end_node:
		end_node.position = vector * SCENE_SCALE
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
		end_node.position = vector * SCENE_SCALE
	var line_container = arrow.get_node_or_null("lineContainer")
	if line_container and line_container.has_method("refresh_connections"):
		line_container.refresh_connections()

func get_vector(arrow: Node) -> Vector3:
	if arrow == null:
		return Vector3.ZERO
	if arrow.has_method("get_vector"):
		return arrow.get_vector()
	var start_node: Node3D = arrow.get_node_or_null("lineContainer/GrabSphere")
	var end_node: Node3D = arrow.get_node_or_null("lineContainer/GrabSphere2")
	if start_node and end_node:
		return (end_node.global_position - start_node.global_position) / SCENE_SCALE
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
		
		var scaled_length = length * SCENE_SCALE
		
		# Cylinder
		var mesh = MeshInstance3D.new()
		mesh.mesh = _shared_cylinder_mesh
		mesh.material_override = _get_shared_material(axis_data.color, true)
		mesh.transform.basis = _basis_from_direction(axis_data.dir)
		# Scale height to length
		mesh.scale.y = scaled_length
		mesh.position = axis_data.dir * (scaled_length * 0.5)
		axis_root.add_child(mesh)
		
		# Tip
		var tip = MeshInstance3D.new()
		tip.mesh = _shared_cone_mesh
		tip.material_override = _get_shared_material(axis_data.color, true)
		tip.transform.basis = _basis_from_direction(axis_data.dir)
		tip.position = axis_data.dir * scaled_length
		axis_root.add_child(tip)
		
		var label = Label3D.new()
		label.text = axis_data.label
		label.font_size = 32
		label.modulate = axis_data.color
		label.position = axis_data.dir * (scaled_length + 0.25 * SCENE_SCALE)
		environment_root.add_child(label)

func create_floor(size: float = 6.0, color: Color = Color(0.1, 0.1, 0.12, 1.0)):
	var floor = MeshInstance3D.new()
	floor.mesh = _shared_floor_mesh
	floor.material_override = _get_shared_material(color, false)
	floor.scale = Vector3(size, 1.0, size) * SCENE_SCALE
	floor.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	floor.position = Vector3(0.0, -0.05, 0.0) * SCENE_SCALE
	environment_root.add_child(floor)

func create_info_panel(text: String, position: Vector3) -> Label3D:
	var label = Label3D.new()
	label.text = text
	label.font_size = 16
	label.modulate = Color.PALE_TURQUOISE
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = position * SCENE_SCALE
	info_root.add_child(label)
	return label

func create_ball(position: Vector3, radius: float = 0.18, mass: float = 1.0, color: Color = Color(0.9, 0.4, 0.8, 1.0)) -> RigidBody3D:
	# Physics-enabled ball with collider and visible mesh
	var body := RigidBody3D.new()
	body.name = "Ball"
	body.position = position * SCENE_SCALE
	body.mass = mass
	body.can_sleep = false
	body.contact_monitor = true
	body.max_contacts_reported = 8

	var scaled_radius = radius * SCENE_SCALE

	var collider := CollisionShape3D.new()
	var sphere_shape := SphereShape3D.new()
	sphere_shape.radius = scaled_radius
	collider.shape = sphere_shape
	body.add_child(collider)

	var mesh := MeshInstance3D.new()
	mesh.mesh = _shared_ball_mesh
	# Scale mesh to match radius (shared mesh is dia=1, rad=0.5 -> scale=radius*2)
	var scale_factor = scaled_radius * 2.0
	mesh.scale = Vector3.ONE * scale_factor
	
	var material = _get_shared_material(color, false)
	# The original create_ball had emission enabled for the ball. 
	# We can create a custom unlit variant or reuse the lit one and add emission logic?
	# Original: emission enabled, emission = color * 0.3, roughness = 0.3
	# Let's create a custom one-off if it differs, or update _get_shared_material to support this.
	# For now, let's use unlit for ball to keep it glowing as before?
	# Original code: emission = color * 0.3 (dimmer than unlit * 0.8)
	# Let's stick to creating a new material for the ball to match exact style, 
	# or accept slight visual change.
	# Better: Cache it with a specific key suffix
	mesh.material_override = _get_shared_material_custom_emission(color, 0.3)
	
	body.add_child(mesh)

	add_child(body)
	return body

func _get_shared_material_custom_emission(color: Color, emission_mult: float) -> StandardMaterial3D:
	var key = str(color) + "_emit_" + str(emission_mult)
	if _material_cache.has(key):
		return _material_cache[key]
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color * emission_mult
	mat.roughness = 0.3
	mat.metallic = 0.0
	_material_cache[key] = mat
	return mat

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
	mesh.mesh = _shared_sphere_mesh
	# Shared sphere radius is 0.5 (dia 1). We want radius 0.05 (dia 0.1). Scale = 0.1.
	# Apply global scale to this too? Yes, likely.
	mesh.scale = Vector3.ONE * 0.1 * SCENE_SCALE
	
	var material = _get_shared_material_custom_emission(Color.WHITE, 0.5)
	mesh.material_override = material
	environment_root.add_child(mesh)

func _build_unlit_material(color: Color) -> StandardMaterial3D:
	# Kept for backward compatibility if needed, but delegating to shared
	return _get_shared_material(color, true)

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
