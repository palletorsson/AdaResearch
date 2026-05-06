@tool
extends XRToolsPickable
class_name GrabDisk

## A small grabable disk that represents a color
## Supports visual color mixing through transparency and blend modes

enum BlendType { ADDITIVE, SUBTRACTIVE }

@export var disk_color: Color = Color.WHITE : set = _set_disk_color
@export var blend_type: BlendType = BlendType.ADDITIVE : set = _set_blend_type
@export var radius: float = 0.1
@export var height: float = 0.02
@export var snap_to_shelf: bool = true

# Internal references
var _mesh_instance: MeshInstance3D
var _original_material: StandardMaterial3D

func _ready() -> void:
	super()
	
	_mesh_instance = $MeshInstance3D
	if _mesh_instance:
		_update_mesh()
		_update_material()

	if not Engine.is_editor_hint():
		# Connect signals
		picked_up.connect(_on_picked_up)
		dropped.connect(_on_dropped)

func _set_disk_color(new_color: Color) -> void:
	disk_color = new_color
	if is_inside_tree():
		_update_material()

func _set_blend_type(new_type: BlendType) -> void:
	blend_type = new_type
	if is_inside_tree():
		_update_material()

func _update_mesh() -> void:
	if not _mesh_instance:
		return
		
	var mesh = CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	_mesh_instance.mesh = mesh
	
	# Update collision shape to match
	var col = $CollisionShape3D
	if col:
		var shape = CylinderShape3D.new()
		shape.radius = radius
		shape.height = height
		col.shape = shape

func _update_material() -> void:
	if not _mesh_instance:
		return
		
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	if blend_type == BlendType.ADDITIVE:
		# Additive: RGB mixing (Red + Green + Blue = White)
		mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		mat.albedo_color = Color(disk_color.r, disk_color.g, disk_color.b, 0.7)
	else:
		# Subtractive: CMY mixing (Cyan + Magenta + Yellow = Black)
		mat.blend_mode = BaseMaterial3D.BLEND_MODE_MUL
		mat.albedo_color = Color(disk_color.r, disk_color.g, disk_color.b, 0.8)
	
	_mesh_instance.material_override = mat

# When picked up
func _on_picked_up(_pickable) -> void:
	# Add custom pickup logic here (e.g. glow)
	pass

func _on_dropped(_pickable) -> void:
	# Add custom drop logic here
	if snap_to_shelf:
		# TODO: Implement shelf snap logic if needed
		pass
