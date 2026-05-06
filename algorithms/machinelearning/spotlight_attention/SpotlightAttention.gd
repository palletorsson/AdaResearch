extends Node3D

@onready var spotlight: SpotLight3D = $SpotLight3D
@onready var objects_parent: Node3D = $Objects

var object_materials: Array[StandardMaterial3D] = []
var _xr_active: bool = false

func _ready() -> void:
	_xr_active = XRServer.primary_interface != null
	# Create a field of objects
	for i in range(100):
		var mesh_instance = BoxMesh.new()
		var material = StandardMaterial3D.new()
		material.albedo_color = Color.GRAY
		object_materials.append(material)
		
		var mesh_node = MeshInstance3D.new()
		mesh_node.mesh = mesh_instance
		mesh_node.material_override = material
		mesh_node.position = Vector3(randf_range(-10, 10), randf_range(-5, 5), randf_range(-10, 10))
		objects_parent.add_child(mesh_node)

func _input(event: InputEvent) -> void:
	if _xr_active and event is InputEventMouseMotion:
		return
	if event is InputEventMouseMotion:
		var mouse_pos = get_viewport().get_mouse_position()
		var ray_length = 100
		var from = get_viewport().get_camera_3d().project_ray_origin(mouse_pos)
		var to = from + get_viewport().get_camera_3d().project_ray_normal(mouse_pos) * ray_length
		spotlight.look_at(to)

func _process(_delta: float):
	for i in range(objects_parent.get_child_count()):
		var child = objects_parent.get_child(i) as MeshInstance3D
		var material = object_materials[i]
		
		var to_object = child.global_transform.origin - spotlight.global_transform.origin
		var angle = spotlight.global_transform.basis.z.angle_to(to_object.normalized())
		
		if angle < deg_to_rad(spotlight.spot_angle):
			material.albedo_color = Color.WHITE
		else:
			material.albedo_color = Color.GRAY

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
