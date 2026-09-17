# ground_cover.gd — the ring's ground-cover recipe, shared.
#
# BiomeRingComponent scatters low-poly ground cover (grass blades, flower caps,
# toadstools, fern, reed, bush) as MultiMeshes in the ring around a grid map.
# The biome vitrine (commons/artifacts/biome_vitrine) scatters the same cover
# over a square patch inside a glass cage. The kingdom table, the meshes, the
# tints and the plant material live HERE so both draw the same plant; the ring
# delegates to these and builds the scene it built before the split —
# commons/testing/probe_ring_refactor.gd compares it against HEAD's ring.
#
# Preloaded by its users (not reached through the global class name) so it
# resolves on headless runs, like spawn_service.gd.
extends RefCounted
class_name BiomeGroundCover


## Which ground-cover types each kingdom brings. Order matters: the first
## type of a kingdom is placed first and the MultiMesh names follow it.
const KINGDOM_FOLIAGE: Dictionary = {
	"flower": ["grass", "flower"],
	"tree": ["grass", "tree", "bush"],
	"fungus": ["mushroom", "fern"],
	"creature": ["grass", "reed", "creature"],
}


## Foliage types for a kingdom list — first-seen order, no duplicates.
static func types_for_kingdoms(kingdoms: Array) -> Array[String]:
	var types: Array[String] = []
	for kingdom in kingdoms:
		var kingdom_types: Array = KINGDOM_FOLIAGE.get(str(kingdom), [])
		for t in kingdom_types:
			if t not in types:
				types.append(t as String)
	return types


## Simple meshes for each type — low-poly for the VR budget.
static func mesh_for(flora_type: String) -> Mesh:
	match flora_type:
		"grass":
			# Tall grass blade — billboard quad
			var mesh := QuadMesh.new()
			mesh.size = Vector2(0.12, 0.4)
			mesh.center_offset = Vector3(0, 0.2, 0)
			return mesh
		"flower":
			# Flower on stem — sphere cap on thin cylinder
			# Use a sphere for the bloom (MultiMesh can't combine meshes)
			var mesh := SphereMesh.new()
			mesh.radius = 0.06
			mesh.height = 0.12
			mesh.radial_segments = 6
			mesh.rings = 3
			return mesh
		"tree":
			# Taller tree — tapered cylinder trunk with spherical canopy implied by scale
			var mesh := CylinderMesh.new()
			mesh.top_radius = 0.5
			mesh.bottom_radius = 0.08
			mesh.height = 2.5
			mesh.radial_segments = 6
			return mesh
		"bush":
			# Dense low bush
			var mesh := SphereMesh.new()
			mesh.radius = 0.35
			mesh.height = 0.4
			mesh.radial_segments = 6
			mesh.rings = 3
			return mesh
		"mushroom":
			# Toadstool cap shape
			var mesh := CylinderMesh.new()
			mesh.top_radius = 0.15
			mesh.bottom_radius = 0.03
			mesh.height = 0.18
			mesh.radial_segments = 6
			return mesh
		"fern":
			# Wide fern frond
			var mesh := QuadMesh.new()
			mesh.size = Vector2(0.35, 0.3)
			mesh.center_offset = Vector3(0, 0.15, 0)
			return mesh
		"reed":
			# Tall thin reed
			var mesh := CylinderMesh.new()
			mesh.top_radius = 0.008
			mesh.bottom_radius = 0.015
			mesh.height = 0.7
			mesh.radial_segments = 3
			return mesh
		"creature":
			# Static creature silhouette — low-poly body shape
			var mesh := CapsuleMesh.new()
			mesh.radius = 0.12
			mesh.height = 0.35
			return mesh
		_:
			return null


## The tint for a type. Flower and creature draw from `rng`, in this order,
## so a caller that replaces the ring's private draw keeps the ring's sequence.
static func color_for(flora_type: String, rng: RandomNumberGenerator) -> Color:
	match flora_type:
		"grass":
			return Color(0.25, 0.45, 0.15)
		"flower":
			return Color(rng.randf_range(0.6, 1.0), rng.randf_range(0.3, 0.7), rng.randf_range(0.2, 0.5))
		"tree":
			return Color(0.2, 0.35, 0.12)
		"bush":
			return Color(0.18, 0.38, 0.1)
		"mushroom":
			return Color(0.6, 0.35, 0.2)
		"fern":
			return Color(0.15, 0.4, 0.1)
		"reed":
			return Color(0.35, 0.45, 0.2)
		"creature":
			# Warm earthy creatures — brown/orange tones
			return Color(rng.randf_range(0.4, 0.7), rng.randf_range(0.25, 0.45), rng.randf_range(0.1, 0.25))
		_:
			return Color(0.3, 0.4, 0.2)


## Ground: grey (clinical) to warm brown (natural) by density.
static func earth_material(density: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(
		lerpf(0.3, 0.22, density),
		lerpf(0.3, 0.2, density),
		lerpf(0.32, 0.16, density)
	)
	mat.roughness = 0.85
	return mat


## The plants' material: vertex tint, two-sided, a faint glow for dark VR.
static func foliage_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.emission_enabled = true
	mat.emission = Color(0.1, 0.15, 0.05)
	mat.emission_energy_multiplier = 0.3
	return mat
