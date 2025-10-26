# torus_low.gd - Low poly torus (8 ring segments, 6 radial segments)
extends MeshInstance3D

func _ready():
	var torus_mesh = TorusMesh.new()
	torus_mesh.inner_radius = 0.3
	torus_mesh.outer_radius = 0.6
	torus_mesh.ring_segments = 8
	torus_mesh.rings = 6

	mesh = torus_mesh

	# Apply grid material
	const GridMaterialFactory = preload("res://commons/primitives/shared/grid_material_factory.gd")
	material_override = GridMaterialFactory.make(Color(0.5, 0.3, 0.9), {})
