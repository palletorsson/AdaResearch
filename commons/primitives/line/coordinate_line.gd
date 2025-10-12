extends Node3D

@export var length: float = 1.5
@export var thickness: float = 0.01
@export var color: Color = Color(0.0, 0.0, 0.0, 1.0)  # black
@export var arrow_size: float = 0.06

var shaft: MeshInstance3D
var arrow: MeshInstance3D

func _ready():
	_build_geometry()

func _build_geometry():
	# Shaft (cylinder) oriented along +X by rotating 90° around Z so its local Y-axis aligns with world X
	shaft = MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.height = length
	cyl.top_radius = thickness
	cyl.bottom_radius = thickness
	cyl.radial_segments = 12
	shaft.mesh = cyl
	# center at origin; rotate so cylinder points along +X
	shaft.transform = Transform3D(Basis(Vector3(0,1,0), Vector3(-1,0,0), Vector3(0,0,1)), Vector3.ZERO)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.2
	shaft.material_override = mat
	add_child(shaft)

	# Arrow head (cone) placed at +X end
	arrow = MeshInstance3D.new()
	var cone := CylinderMesh.new()  # Use cylinder with top_radius = 0 to form a cone
	cone.top_radius = 0.0
	cone.bottom_radius = max(thickness * 3.0, 0.01)
	cone.height = arrow_size
	cone.radial_segments = 16
	arrow.mesh = cone
	# Place arrow at end of shaft; orient along +X
	var end_pos := Vector3(length * 0.5, 0.0, 0.0)
	var basis := Basis(Vector3(0,1,0), Vector3(-1,0,0), Vector3(0,0,1))
	arrow.transform = Transform3D(basis, end_pos)
	arrow.material_override = mat
	add_child(arrow)

func set_length(new_length: float):
	length = new_length
	_build_reset()

func set_thickness(new_thickness: float):
	thickness = new_thickness
	_build_reset()

func set_color(new_color: Color):
	color = new_color
	_build_reset()

func _build_reset():
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build_geometry()
