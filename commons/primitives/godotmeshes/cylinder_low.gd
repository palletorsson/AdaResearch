# cylinder_low.gd - Low poly cylinder (8 radial segments)
extends MeshInstance3D

func _ready():
	var cyl_mesh = CylinderMesh.new()
	cyl_mesh.top_radius = 0.4
	cyl_mesh.bottom_radius = 0.4
	cyl_mesh.height = 1.0
	cyl_mesh.radial_segments = 8
	cyl_mesh.rings = 1

	mesh = cyl_mesh

	# Apply grid material
	const GridMaterialFactory = preload("res://commons/primitives/shared/grid_material_factory.gd")
	material_override = GridMaterialFactory.make(Color(0.9, 0.3, 0.5), {})
