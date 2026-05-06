# sphere_mid.gd - Medium poly sphere (16 rings, 16 radial segments)
extends MeshInstance3D

# @identity
# essence: SphereMesh(rings=7, radial_segments=7) — mid-resolution sphere where the trade-off is legible
# desire: learner sees the transitional zone — faces are visible but the sphere reads as round at a distance
# critical_parameter: rings=7 and radial_segments=7 — the middle ground where geometry meets perception
# triggers: nothing — static; placed between sphere_low and sphere_high in the comparison trio
# emerges: the subjective nature of "enough resolution" — what counts as smooth depends on viewing distance
# needs: [missing VR controls — static display only]
# relationships: middle of the trio with sphere_low and sphere_high; cyan color distinguishes it from siblings
# truth: resolution is a budget decision — there is no correct polygon count, only contextually sufficient ones

func _ready():
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.5
	sphere_mesh.height = 1.0
	sphere_mesh.radial_segments = 7
	sphere_mesh.rings = 7

	mesh = sphere_mesh

	# Apply grid material
	const GridMaterialFactory = preload("res://commons/primitives/shared/grid_material_factory.gd")
	material_override = GridMaterialFactory.make(Color(0.3, 0.8, 0.9), {})
