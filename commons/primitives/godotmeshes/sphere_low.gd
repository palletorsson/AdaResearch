# sphere_low.gd - Low poly sphere (8 rings, 8 radial segments)
extends MeshInstance3D

func _ready():
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.5
	sphere_mesh.height = 1.0
	sphere_mesh.radial_segments = 10
	sphere_mesh.rings = 1

	mesh = sphere_mesh

	# Apply grid material
	const GridMaterialFactory = preload("res://commons/primitives/shared/grid_material_factory.gd")
	material_override = GridMaterialFactory.make(Color(0.8, 0.3, 0.9), {})
