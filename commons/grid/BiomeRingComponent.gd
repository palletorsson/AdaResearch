# BiomeRingComponent.gd — Natural landscape surrounding grid maps
#
# Generates a biome ring around the grid with three concentric zones:
#   1. Transition strip (1-2m): grid floor → sparse grass/moss
#   2. Wild biome ring (5-10m): full living ground + foliage
#   3. Fog fade (3-4m): world dissolves into mist
#
# Density and kingdom types are driven by EcosystemManager's soft_stage.
# Early maps get no ring (clinical). Late maps get a full living landscape.
#
# Usage:
#   var ring := BiomeRingComponent.new()
#   add_child(ring)
#   ring.generate(grid_dims, cube_size, terrain_mode, kingdoms, density)

class_name BiomeRingComponent
extends Node3D


# ─────────────────────────────────────────────────────────────
#  Configuration
# ─────────────────────────────────────────────────────────────

## Width of the biome ring (meters beyond grid edge).
var ring_width: float = 8.0

## Width of the fog fade zone (meters beyond ring).
var fade_width: float = 4.0

## Ground mesh subdivision density.
var ground_subdivisions: int = 32

## Maximum Perlin height variation in the ring.
var height_variation: float = 0.25

## Foliage instances per square meter at peak density.
var foliage_density_per_sqm: float = 3.0


# ─────────────────────────────────────────────────────────────
#  Foliage type mapping
# ─────────────────────────────────────────────────────────────

const KINGDOM_FOLIAGE: Dictionary = {
	"flower": ["grass", "flower"],
	"tree": ["grass", "tree", "bush"],
	"fungus": ["mushroom", "fern"],
	"creature": ["grass", "reed"],
}


# ─────────────────────────────────────────────────────────────
#  State
# ─────────────────────────────────────────────────────────────

var _ground_mesh: MeshInstance3D = null
var _foliage_instances: Array[MultiMeshInstance3D] = []
var _critter_spawner = null  # CritterSpawner (loaded dynamically)
var _rng: RandomNumberGenerator = null


# ═══════════════════════════════════════════════════════════════
# GENERATION
# ═══════════════════════════════════════════════════════════════

func generate(grid_dims: Vector3i, cube_size: float, terrain_mode: String,
		kingdoms: Array, density: float) -> void:

	# No ring for barren maps
	if density < 0.05:
		return

	_rng = RandomNumberGenerator.new()
	_rng.seed = hash(str(grid_dims))

	var grid_w: float = float(grid_dims.x) * cube_size
	var grid_d: float = float(grid_dims.z) * cube_size
	var grid_center := Vector3(grid_w * 0.5, 0, grid_d * 0.5)

	# Scale ring width by density (early = thin, late = wide)
	ring_width = lerpf(3.0, 10.0, density)
	fade_width = lerpf(2.0, 5.0, density)

	# Build ground
	_build_ring_ground(grid_w, grid_d, grid_center, terrain_mode, density)

	# Place foliage (MultiMesh — simple decorative meshes)
	_place_foliage(grid_w, grid_d, grid_center, kingdoms, density)

	# Spawn living CritterEntity organisms for late-sequence maps
	_spawn_living_organisms(grid_center, kingdoms, density)

	print("[BiomeRing] Generated: %.0fx%.0f grid, ring=%.1fm, fade=%.1fm, density=%.2f, kingdoms=%s" % [
		grid_w, grid_d, ring_width, fade_width, density, str(kingdoms)
	])


# ═══════════════════════════════════════════════════════════════
# GROUND MESH — Large plane with living ground shader
# ═══════════════════════════════════════════════════════════════

func _build_ring_ground(grid_w: float, grid_d: float, grid_center: Vector3,
		terrain_mode: String, density: float) -> void:

	_ground_mesh = MeshInstance3D.new()
	_ground_mesh.name = "BiomeGround"

	# The ground covers grid + ring + fade
	var total_w: float = grid_w + (ring_width + fade_width) * 2.0
	var total_d: float = grid_d + (ring_width + fade_width) * 2.0

	var plane := PlaneMesh.new()
	plane.size = Vector2(total_w, total_d)
	plane.subdivide_width = ground_subdivisions
	plane.subdivide_depth = ground_subdivisions
	_ground_mesh.mesh = plane

	# Position: centered on grid, slightly below grid floor
	_ground_mesh.position = grid_center + Vector3(0, -0.05, 0)

	# Material
	if terrain_mode in ["growth", "self_generating"]:
		# Use living ground shader with procedurally seeded presence
		var shader_path: String = "res://algorithms/nature_system/shaders/living_ground.gdshader"
		if ResourceLoader.exists(shader_path):
			var shader: Shader = load(shader_path)
			var mat := ShaderMaterial.new()
			mat.shader = shader
			mat.set_shader_parameter("world_size", Vector2(total_w, total_d))
			mat.set_shader_parameter("world_offset", Vector2(grid_center.x, grid_center.z))

			# Create and seed a presence grid for the ring
			var presence_texture := _create_ring_presence(
				grid_w, grid_d, total_w, total_d, density
			)
			mat.set_shader_parameter("presence_map", presence_texture)
			_ground_mesh.material_override = mat
		else:
			_ground_mesh.material_override = _create_earth_material(density)
	elif terrain_mode == "noise":
		# Warm earth with noise — no presence, just color
		_ground_mesh.material_override = _create_earth_material(density)
	else:
		# Flat — simple warm earth
		_ground_mesh.material_override = _create_earth_material(density)

	add_child(_ground_mesh)


func _create_earth_material(density: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	# Blend from grey (clinical) to warm brown (natural) based on density
	mat.albedo_color = Color(
		lerpf(0.3, 0.22, density),
		lerpf(0.3, 0.2, density),
		lerpf(0.32, 0.16, density)
	)
	mat.roughness = 0.85
	return mat


# ═══════════════════════════════════════════════════════════════
# PRESENCE GRID — Procedurally seeded for ring area
# ═══════════════════════════════════════════════════════════════

func _create_ring_presence(grid_w: float, grid_d: float,
		total_w: float, total_d: float, density: float) -> ImageTexture:

	var res: int = 128
	var img := Image.create(res, res, false, Image.FORMAT_RGBA8)

	var half_gw: float = grid_w * 0.5
	var half_gd: float = grid_d * 0.5
	var half_tw: float = total_w * 0.5
	var half_td: float = total_d * 0.5

	for y in res:
		for x in res:
			# Map pixel to world coordinates (centered on grid)
			var wx: float = lerpf(-half_tw, half_tw, float(x) / float(res))
			var wz: float = lerpf(-half_td, half_td, float(y) / float(res))

			# Distance from grid edge
			var dx: float = maxf(absf(wx) - half_gw, 0.0)
			var dz: float = maxf(absf(wz) - half_gd, 0.0)
			var edge_dist: float = maxf(dx, dz)

			# Inside grid = no presence (grid floor covers it)
			if edge_dist < 0.5:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
				continue

			# Ring zone = presence based on distance
			var ring_t: float = clampf(edge_dist / ring_width, 0.0, 1.0)

			# Fade out at outer edge
			var fade_start: float = ring_width
			var fade_t: float = clampf((edge_dist - fade_start) / fade_width, 0.0, 1.0)
			var fade_mult: float = 1.0 - fade_t * fade_t  # quadratic fade

			# Noise-based kingdom mixing
			var noise_seed: float = wx * 0.3 + wz * 0.7
			var tree_p: float = _simple_noise(wx * 0.15, wz * 0.15) * density * fade_mult
			var flower_p: float = _simple_noise(wx * 0.2 + 5.0, wz * 0.2 + 3.0) * density * fade_mult * 0.7
			var fungus_p: float = _simple_noise(wx * 0.25 + 10.0, wz * 0.25 + 7.0) * density * fade_mult * 0.5

			# Increase presence toward middle of ring (peak at ring_t=0.5)
			var ring_strength: float = 4.0 * ring_t * (1.0 - ring_t)  # parabolic
			tree_p *= ring_strength
			flower_p *= ring_strength
			fungus_p *= ring_strength

			img.set_pixel(x, y, Color(
				clampf(tree_p, 0, 1),
				0.0,  # creature = trails, not seeded
				clampf(flower_p, 0, 1),
				clampf(fungus_p, 0, 1)
			))

	return ImageTexture.create_from_image(img)


func _simple_noise(x: float, y: float) -> float:
	# Simple hash-based noise (no import needed)
	var n: float = sin(x * 12.9898 + y * 78.233) * 43758.5453
	return fract(n) if n > 0 else fract(-n)


func fract(x: float) -> float:
	return x - floorf(x)


# ═══════════════════════════════════════════════════════════════
# FOLIAGE — MultiMesh instances in the ring
# ═══════════════════════════════════════════════════════════════

func _place_foliage(grid_w: float, grid_d: float, grid_center: Vector3,
		kingdoms: Array, density: float) -> void:

	# Determine which foliage types to use
	var types: Array[String] = []
	for kingdom in kingdoms:
		var kingdom_types: Array = KINGDOM_FOLIAGE.get(str(kingdom), [])
		for t in kingdom_types:
			if t not in types:
				types.append(t as String)

	if types.is_empty():
		types = ["grass"]

	var half_gw: float = grid_w * 0.5
	var half_gd: float = grid_d * 0.5

	# For each foliage type, create a MultiMesh
	for flora_type in types:
		var mesh: Mesh = _get_foliage_mesh(flora_type)
		if not mesh:
			continue

		# Collect positions
		var transforms: Array[Transform3D] = []
		var colors: Array[Color] = []

		var total_area: float = (grid_w + ring_width * 2) * (grid_d + ring_width * 2) - grid_w * grid_d
		var target_count: int = int(total_area * foliage_density_per_sqm * density)
		target_count = mini(target_count, 500)  # Cap for performance

		var type_fraction: float = 1.0 / float(types.size())
		var this_count: int = int(float(target_count) * type_fraction)

		for _i in this_count:
			# Random position in the ring area
			var wx: float = _rng.randf_range(-(half_gw + ring_width), half_gw + ring_width)
			var wz: float = _rng.randf_range(-(half_gd + ring_width), half_gd + ring_width)

			# Skip if inside grid
			if absf(wx) < half_gw and absf(wz) < half_gd:
				continue

			# Distance from grid edge
			var dx: float = maxf(absf(wx) - half_gw, 0.0)
			var dz: float = maxf(absf(wz) - half_gd, 0.0)
			var edge_dist: float = maxf(dx, dz)

			# Skip if in fog zone
			if edge_dist > ring_width:
				continue

			# Density curve: sparse near grid, peaks mid-ring, thins at edge
			var ring_t: float = edge_dist / ring_width
			var local_density: float = 4.0 * ring_t * (1.0 - ring_t)  # parabolic

			if _rng.randf() > local_density:
				continue

			# Position
			var world_pos := grid_center + Vector3(wx, 0.0, wz)
			# Height variation
			world_pos.y = _simple_noise(wx * 0.5, wz * 0.5) * height_variation

			# Random rotation and slight scale variation
			var t := Transform3D.IDENTITY
			t = t.rotated(Vector3.UP, _rng.randf_range(0, TAU))
			var s: float = _rng.randf_range(0.6, 1.2)
			t = t.scaled(Vector3(s, s, s))
			t.origin = world_pos

			transforms.append(t)

			# Color tint based on flora type
			var tint := _get_foliage_color(flora_type)
			tint.r += _rng.randf_range(-0.05, 0.05)
			tint.g += _rng.randf_range(-0.05, 0.05)
			tint.b += _rng.randf_range(-0.05, 0.05)
			colors.append(tint)

		if transforms.is_empty():
			continue

		# Build MultiMesh
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = mesh
		mm.instance_count = transforms.size()

		for i in transforms.size():
			mm.set_instance_transform(i, transforms[i])
			mm.set_instance_color(i, colors[i])

		var mmi := MultiMeshInstance3D.new()
		mmi.name = "BiomeFoliage_%s" % flora_type
		mmi.multimesh = mm

		# Simple material
		var mat := StandardMaterial3D.new()
		mat.vertex_color_use_as_albedo = true
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		mmi.material_override = mat

		add_child(mmi)
		_foliage_instances.append(mmi)


func _get_foliage_mesh(flora_type: String) -> Mesh:
	# Simple meshes for each type — low-poly for VR budget
	match flora_type:
		"grass":
			var mesh := QuadMesh.new()
			mesh.size = Vector2(0.15, 0.3)
			mesh.center_offset = Vector3(0, 0.15, 0)
			return mesh
		"flower":
			var mesh := SphereMesh.new()
			mesh.radius = 0.08
			mesh.height = 0.16
			mesh.radial_segments = 4
			mesh.rings = 2
			return mesh
		"tree":
			var mesh := CylinderMesh.new()
			mesh.top_radius = 0.3
			mesh.bottom_radius = 0.05
			mesh.height = 1.2
			mesh.radial_segments = 5
			return mesh
		"bush":
			var mesh := SphereMesh.new()
			mesh.radius = 0.25
			mesh.height = 0.35
			mesh.radial_segments = 5
			mesh.rings = 3
			return mesh
		"mushroom":
			var mesh := CylinderMesh.new()
			mesh.top_radius = 0.12
			mesh.bottom_radius = 0.03
			mesh.height = 0.15
			mesh.radial_segments = 5
			return mesh
		"fern":
			var mesh := QuadMesh.new()
			mesh.size = Vector2(0.3, 0.25)
			mesh.center_offset = Vector3(0, 0.12, 0)
			return mesh
		"reed":
			var mesh := CylinderMesh.new()
			mesh.top_radius = 0.01
			mesh.bottom_radius = 0.015
			mesh.height = 0.5
			mesh.radial_segments = 3
			return mesh
		_:
			return null


# ═══════════════════════════════════════════════════════════════
# LIVING ORGANISMS — DNA-driven CritterEntity instances
# ═══════════════════════════════════════════════════════════════

## Spawn real CritterEntity organisms in the biome ring.
## Only activates for late-sequence maps where kingdoms include living types.
## density > 0.3: a few L-system trees replace some MultiMesh cylinders
## density > 0.5: DNA flowers with real morphology join
## creature kingdom: actual walking/roaming entities appear
func _spawn_living_organisms(center: Vector3, kingdoms: Array, density: float) -> void:
	# Need at least moderate density for living organisms (performance budget)
	if density < 0.3:
		return

	# Create a container for living organisms
	var nature_root := Node3D.new()
	nature_root.name = "LivingOrganisms"
	add_child(nature_root)

	# Create spawner
	_critter_spawner = CritterSpawner.new(nature_root)
	_critter_spawner.default_lod = 2  # Medium detail for ring organisms
	_critter_spawner.max_population = int(density * 20)  # Scale with density: 6-20

	var ring_radius: float = ring_width * 0.6  # Spawn in the mid-ring zone

	# Kingdom 0 = tree: L-system trees with real morphology (density > 0.3)
	if "tree" in kingdoms:
		var tree_count: int = int(density * 6)  # 2-6 trees
		_critter_spawner.seed_population(0, tree_count, center, ring_radius)
		print("[BiomeRing] Spawned %d living trees" % tree_count)

	# Kingdom 2 = flower: DNA-driven petal flowers (density > 0.5)
	if "flower" in kingdoms and density > 0.5:
		var flower_count: int = int(density * 5)  # 3-5 flowers
		_critter_spawner.seed_population(2, flower_count, center, ring_radius)
		print("[BiomeRing] Spawned %d living flowers" % flower_count)

	# Kingdom 3 = fungus: morphology fungi (density > 0.5)
	if "fungus" in kingdoms and density > 0.5:
		var fungus_count: int = int(density * 3)  # 2-3 fungi
		_critter_spawner.seed_population(3, fungus_count, center, ring_radius)
		print("[BiomeRing] Spawned %d living fungi" % fungus_count)

	# Kingdom 1 = creature: walking/roaming entities (only when creature kingdom unlocked)
	if "creature" in kingdoms:
		var creature_count: int = int(density * 8)  # 6-8 creatures
		_critter_spawner.seed_population(1, creature_count, center, ring_radius)
		print("[BiomeRing] Spawned %d living creatures" % creature_count)


func _get_foliage_color(flora_type: String) -> Color:
	match flora_type:
		"grass":
			return Color(0.25, 0.45, 0.15)
		"flower":
			return Color(_rng.randf_range(0.6, 1.0), _rng.randf_range(0.3, 0.7), _rng.randf_range(0.2, 0.5))
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
		_:
			return Color(0.3, 0.4, 0.2)
