# sphere_high.gd - High poly sphere (32 rings, 32 radial segments)
extends MeshInstance3D

# @identity
# essence: SphereMesh(rings=16, radial_segments=16) — a sphere approximated by many small triangles
# desire: learner sees that a smooth sphere in 3D is a polygon mesh — smoothness is a resolution choice
# critical_parameter: rings and radial_segments — together they determine polygon count and visual smoothness
# triggers: nothing — static; placed alongside sphere_low and sphere_mid for direct comparison
# emerges: the point where more polygons stop being visually distinguishable — the perceptual limit
# needs: [missing VR controls — static display only]
# relationships: comparison trio with sphere_low and sphere_mid; grid material makes polygon faces visible
# truth: there is no smooth sphere in real-time 3D — only denser approximations approaching one

func _ready():
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.5
	sphere_mesh.height = 1.0
	sphere_mesh.radial_segments = 16
	sphere_mesh.rings = 16

	mesh = sphere_mesh

	# Apply grid material
	const GridMaterialFactory = preload("res://commons/primitives/shared/grid_material_factory.gd")
	material_override = GridMaterialFactory.make(Color(0.9, 0.8, 0.3), {})
