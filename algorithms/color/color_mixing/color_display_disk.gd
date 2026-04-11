extends Node3D
class_name MirroredDisplayDisk

## A large disk that mirrors a single small disk's position, rotation, color, and blend mode
## Positioned 3 meters in front of the tracked disk

@export var tracked_disk_path: NodePath
@export var display_radius: float = 0.5  # 1 meter diameter
@export var display_height: float = 0.05
@export var offset_distance: float = 3.0  # 3 meters in front

var _mesh_instance: MeshInstance3D
var _tracked_disk: GrabDisk

func _ready() -> void:
	_create_display_mesh()
	_resolve_tracked_disk()

func _process(_delta: float) -> void:
	if _tracked_disk:
		_update_from_tracked_disk()

func _create_display_mesh() -> void:
	# Create mesh instance
	_mesh_instance = MeshInstance3D.new()
	add_child(_mesh_instance)
	
	# Create cylinder mesh
	var mesh = CylinderMesh.new()
	mesh.top_radius = display_radius
	mesh.bottom_radius = display_radius
	mesh.height = display_height
	_mesh_instance.mesh = mesh
	
	# Create material
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color.WHITE
	_mesh_instance.material_override = mat

func _resolve_tracked_disk() -> void:
	var node = get_node_or_null(tracked_disk_path)
	if node and node is GrabDisk:
		_tracked_disk = node
	else:
		push_warning("MirroredDisplayDisk: Could not find GrabDisk at path: " + str(tracked_disk_path))

func _update_from_tracked_disk() -> void:
	if not _tracked_disk or not _mesh_instance:
		return
	
	# Update material to match the tracked disk's blend mode and color
	var mat = _mesh_instance.material_override as StandardMaterial3D
	if mat:
		# Match blend type (ADDITIVE or SUBTRACTIVE)
		if _tracked_disk.blend_type == GrabDisk.BlendType.ADDITIVE:
			mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
			mat.albedo_color = Color(_tracked_disk.disk_color.r, _tracked_disk.disk_color.g, _tracked_disk.disk_color.b, 0.7)
		else:  # SUBTRACTIVE
			mat.blend_mode = BaseMaterial3D.BLEND_MODE_MUL
			mat.albedo_color = Color(_tracked_disk.disk_color.r, _tracked_disk.disk_color.g, _tracked_disk.disk_color.b, 0.8)
	
	# Update position: mirror the small disk's position, offset 3 meters to opposite side (positive Z)
	var tracked_pos = _tracked_disk.global_position
	global_position = tracked_pos + Vector3(0, 0, offset_distance)
	
	# Update rotation: mirror the small disk's rotation
	global_rotation = _tracked_disk.global_rotation

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
