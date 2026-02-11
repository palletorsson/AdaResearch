# torus_low.gd - Low poly torus with visible triangular structure
extends MeshInstance3D

func _ready():
	var torus_mesh = TorusMesh.new()
	torus_mesh.inner_radius = 0.3
	torus_mesh.outer_radius = 0.6
	torus_mesh.ring_segments = 8
	torus_mesh.rings = 6

	mesh = torus_mesh

	# Apply grid material with contrasting wireframe for visible segments
	const GridMaterialFactory = preload("res://commons/primitives/shared/grid_material_factory.gd")
	material_override = GridMaterialFactory.make(Color(0.4, 0.2, 0.6), {
		"wireframe_color": Color(1.0, 0.9, 0.7),  # Light yellow wireframe
		"wireframe_width": 3.0,
		"wireframe_brightness": 3.5
	})
