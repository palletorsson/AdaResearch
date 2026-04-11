# sphere_low.gd - Low poly sphere (8 rings, 8 radial segments)
extends MeshInstance3D

# @identity
# essence: SphereMesh(rings=1, radial_segments=10) — a coarse sphere approximation revealing polygon faces
# desire: learner clearly sees the triangles that constitute the sphere — the illusion of roundness dissolves
# critical_parameter: rings=1 and radial_segments=10 — the minimum that still reads as "sphere-like"
# triggers: nothing — static; placed first in the resolution comparison trio
# emerges: that "low poly" is not a failure — it is a deliberate aesthetic that exposes the underlying geometry
# needs: [missing VR controls — static display only]
# relationships: first in the trio with sphere_mid and sphere_high; grid material makes faces visible
# truth: the low-poly sphere is more honest than the high-poly one — it does not pretend to be smooth

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
