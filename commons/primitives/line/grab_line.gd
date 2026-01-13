extends XRToolsPickable
class_name GrabLine

## Grabbable stick with draggable tip for resizing
## Grab the handle to move, grab the tip sphere to resize

@export_group("Line Properties")
@export var line_length: float = 0.5:
	set(value):
		line_length = clamp(value, min_length, max_length)
		_update_line_mesh()
@export var line_thickness: float = 0.015
@export var min_length: float = 0.05
@export var max_length: float = 5.0
@export var line_color: Color = Color(1.0, 0.0, 1.0, 1.0)

@export_group("Display")
@export var show_length_label: bool = true

var _line_mesh: MeshInstance3D
var _cylinder_mesh: CylinderMesh
var _line_material: StandardMaterial3D
var _length_label: Label3D
var _tip_marker: Node3D
var _tip_pickable: XRToolsPickable
var _tip_grabbed: bool = false

func _ready() -> void:
	super()
	_setup_line_mesh()
	_setup_tip_marker()
	_setup_tip_pickable()
	if show_length_label:
		_setup_length_label()
	_update_line_mesh()

func _setup_line_mesh() -> void:
	_line_mesh = MeshInstance3D.new()
	_line_mesh.name = "LineMesh"
	add_child(_line_mesh)

	_cylinder_mesh = CylinderMesh.new()
	_cylinder_mesh.top_radius = line_thickness
	_cylinder_mesh.bottom_radius = line_thickness
	_cylinder_mesh.radial_segments = 8
	_cylinder_mesh.rings = 0
	_line_mesh.mesh = _cylinder_mesh

	_line_material = StandardMaterial3D.new()
	_line_material.albedo_color = line_color
	_line_material.metallic = 0.6
	_line_material.roughness = 0.2
	_line_material.emission_enabled = true
	_line_material.emission = line_color
	_line_material.emission_energy_multiplier = 0.5
	_line_mesh.material_override = _line_material

func _setup_tip_marker() -> void:
	_tip_marker = Node3D.new()
	_tip_marker.name = "TipMarker"
	add_child(_tip_marker)

func _setup_tip_pickable() -> void:
	# Create simple tip pickable sphere
	_tip_pickable = XRToolsPickable.new()
	_tip_pickable.name = "TipSphere"
	_tip_pickable.freeze = true  # Stay attached to tip, no gravity

	# Collision shape
	var collision = CollisionShape3D.new()
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = 0.04
	collision.shape = sphere_shape
	_tip_pickable.add_child(collision)

	# Visible mesh
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "MeshInstance3D"
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.03
	sphere_mesh.height = 0.06
	mesh_instance.mesh = sphere_mesh

	var mat = StandardMaterial3D.new()
	mat.albedo_color = line_color.lightened(0.2)
	mat.metallic = 0.7
	mat.roughness = 0.2
	mat.emission_enabled = true
	mat.emission = line_color
	mat.emission_energy_multiplier = 0.5
	mesh_instance.material_override = mat
	_tip_pickable.add_child(mesh_instance)

	add_child(_tip_pickable)

	_tip_pickable.picked_up.connect(_on_tip_picked_up)
	_tip_pickable.dropped.connect(_on_tip_dropped)

func _setup_length_label() -> void:
	_length_label = Label3D.new()
	_length_label.name = "LengthLabel"
	_length_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_length_label.font_size = 24
	_length_label.modulate = Color(1.0, 1.0, 1.0, 0.8)
	_length_label.outline_size = 4
	_length_label.outline_modulate = Color(0, 0, 0, 1)
	_length_label.scale = Vector3.ONE * 0.1
	add_child(_length_label)

func _update_line_mesh() -> void:
	if not _cylinder_mesh:
		return

	_cylinder_mesh.height = line_length

	if _line_mesh:
		# Line extends along X axis from handle
		_line_mesh.position = Vector3(line_length / 2.0, 0, 0)
		_line_mesh.rotation_degrees = Vector3(0, 0, 90)

	if _tip_marker:
		_tip_marker.position = Vector3(line_length, 0, 0)

	# Update tip pickable position (only if not being dragged)
	if _tip_pickable and not _tip_grabbed:
		_tip_pickable.position = Vector3(line_length, 0, 0)

	if _length_label:
		_length_label.text = "%.2fm" % line_length
		_length_label.position = Vector3(line_length / 2.0, 0.05, 0)

func _process(_delta: float) -> void:
	if _tip_grabbed and _tip_pickable:
		# Calculate new length from tip position
		var tip_local = _tip_pickable.position
		line_length = tip_local.x

func _on_tip_picked_up(_pickable) -> void:
	_tip_grabbed = true

func _on_tip_dropped(_pickable) -> void:
	_tip_grabbed = false
	# Snap tip back to correct position
	if _tip_pickable:
		_tip_pickable.position = Vector3(line_length, 0, 0)

func get_tip_position() -> Vector3:
	return _tip_marker.global_position if _tip_marker else global_position + global_transform.basis.x * line_length

func get_tip_transform() -> Transform3D:
	return _tip_marker.global_transform if _tip_marker else Transform3D(global_transform.basis, get_tip_position())

func set_line_color(color: Color) -> void:
	line_color = color
	if _line_material:
		_line_material.albedo_color = color
		_line_material.emission = color
