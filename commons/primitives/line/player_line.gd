extends Node3D

# Line from origin to player camera
@export var line_thickness: float = 0.01
@export var line_color: Color = Color(1.0, 0.3, 0.8, 1.0)

var line: MeshInstance3D
var origin_point: Vector3 = Vector3.ZERO
var camera: XRCamera3D

func _ready():
	create_line()
	find_camera()

func find_camera():
	# Find XRCamera3D in the scene tree
	var root = get_tree().root
	camera = find_node_by_type(root, "XRCamera3D")
	if not camera:
		push_warning("PlayerLine: Could not find XRCamera3D in scene")

func find_node_by_type(node: Node, type_name: String) -> Node:
	if node.get_class() == type_name:
		return node
	for child in node.get_children():
		var result = find_node_by_type(child, type_name)
		if result:
			return result
	return null

func create_line():
	line = MeshInstance3D.new()

	var cylinder = CylinderMesh.new()
	cylinder.height = 1.0
	cylinder.top_radius = line_thickness
	cylinder.bottom_radius = line_thickness
	cylinder.radial_segments = 8

	line.mesh = cylinder

	# Create glossy emissive material
	var material = StandardMaterial3D.new()
	material.albedo_color = line_color
	material.metallic = 0.8
	material.roughness = 0.1
	material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	material.emission_enabled = true
	material.emission = line_color
	line.material_override = material

	add_child(line)

func _process(_delta):
	if not camera or not is_instance_valid(camera):
		find_camera()
		return

	update_line_to_camera()

func update_line_to_camera():
	if not line or not camera:
		return

	var camera_pos = camera.global_position
	var cylinder = line.mesh as CylinderMesh
	if cylinder == null:
		return

	var distance = origin_point.distance_to(camera_pos)
	cylinder.height = distance

	# Position at center between origin and camera
	var center_pos = (origin_point + camera_pos) / 2.0
	line.global_position = center_pos

	# Orient the line from origin to camera
	var direction = (camera_pos - origin_point).normalized()
	if direction.length() > 0.001:
		var up = Vector3.UP
		var right = direction.cross(up).normalized()
		if right.length() < 0.001:
			right = Vector3.RIGHT
			up = right.cross(direction).normalized()
		else:
			up = right.cross(direction).normalized()

		line.global_transform.basis = Basis(right, direction, up)
