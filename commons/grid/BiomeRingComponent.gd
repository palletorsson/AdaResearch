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
	"creature": ["grass", "reed", "creature"],
}


# ─────────────────────────────────────────────────────────────
#  State
# ─────────────────────────────────────────────────────────────

var _ground_mesh: MeshInstance3D = null
var _foliage_instances: Array[MultiMeshInstance3D] = []
var _chunk_manager: ChunkManager = null
var _rng: RandomNumberGenerator = null
var _grid_w: float = 0.0
var _grid_d: float = 0.0


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

	_grid_w = float(grid_dims.x) * cube_size
	_grid_d = float(grid_dims.z) * cube_size
	var grid_w := _grid_w
	var grid_d := _grid_d
	var grid_center := Vector3(grid_w * 0.5, 0, grid_d * 0.5)

	# Scale ring width by density (early = thin, late = wide)
	ring_width = lerpf(3.0, 10.0, density)
	fade_width = lerpf(2.0, 5.0, density)

	# Build ground
	_build_ring_ground(grid_w, grid_d, grid_center, terrain_mode, density)

	# Place foliage (MultiMesh — static background fill, LOD 3 equivalent)
	_place_foliage(grid_w, grid_d, grid_center, kingdoms, density)

	# Spawn DNA organisms via ChunkManager (LOD 0-2 — real morphology near player)
	if density >= 0.1:
		_spawn_dna_organisms(grid_center, kingdoms, density)

	print("[BiomeRing] Generated: %.0fx%.0f grid, ring=%.1fm, fade=%.1fm, density=%.2f, kingdoms=%s, chunks=%s" % [
		grid_w, grid_d, ring_width, fade_width, density, str(kingdoms),
		"yes" if _chunk_manager else "no"
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
	_ground_mesh.position = grid_center + Vector3(0, -0.5, 0)

	# VR-safe ground shader — distance-based earth→grass→fade coloring
	var shader = load("res://commons/resourses/shaders/biome_ground.gdshader")
	if shader:
		var mat := ShaderMaterial.new()
		mat.shader = shader
		mat.set_shader_parameter("grid_size", Vector2(grid_w, grid_d))
		mat.set_shader_parameter("grid_center", Vector2(grid_center.x, grid_center.z))
		mat.set_shader_parameter("ring_width", ring_width)
		mat.set_shader_parameter("fade_width", fade_width)
		mat.set_shader_parameter("density", density)
		mat.render_priority = -1  # Render below other transparent objects
		_ground_mesh.material_override = mat
	else:
		_ground_mesh.material_override = _create_earth_material(density)

	add_child(_ground_mesh)

	# Walkable collision — covers grid + ring only (not fade zone)
	# Player falls off at the ring edge into void
	var walk_w: float = grid_w + ring_width * 2.0
	var walk_d: float = grid_d + ring_width * 2.0
	var body := StaticBody3D.new()
	body.name = "BiomeGroundBody"
	var col := CollisionShape3D.new()
	var col_shape := BoxShape3D.new()
	col_shape.size = Vector3(walk_w, 0.1, walk_d)
	col.shape = col_shape
	body.add_child(col)
	body.position = grid_center + Vector3(0, -0.55, 0)
	add_child(body)


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

	# Gate by grammar — drop foliage whose required form_type is not yet unlocked.
	# Before L-systems (seq 11), no trees or bushes. Before CA (seq 8), no mushrooms.
	# Before wavefunctions (seq 5), no reeds. Before swarm (seq 13), no creatures.
	var grammar = get_node_or_null("/root/GrammarOperationsManager")
	if grammar and grammar.has_method("filter_foliage_types"):
		var before: Array[String] = types.duplicate()
		types = grammar.filter_foliage_types(types)
		if types.size() < before.size():
			var dropped: Array[String] = []
			for t in before:
				if not types.has(t):
					dropped.append(t)
			print("[BiomeRing] Grammar gated foliage — dropped: %s" % str(dropped))

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

		# Material with subtle emission so plants glow slightly in dark VR
		var mat := StandardMaterial3D.new()
		mat.vertex_color_use_as_albedo = true
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		mat.emission_enabled = true
		mat.emission = Color(0.1, 0.15, 0.05)
		mat.emission_energy_multiplier = 0.3
		mmi.material_override = mat

		add_child(mmi)
		_foliage_instances.append(mmi)


func _get_foliage_mesh(flora_type: String) -> Mesh:
	# Simple meshes for each type — low-poly for VR budget
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


# ═══════════════════════════════════════════════════════════════
# DNA ORGANISMS — Real CritterDNA via ChunkManager (LOD 0-2)
# ═══════════════════════════════════════════════════════════════

func _spawn_dna_organisms(grid_center: Vector3, kingdoms: Array, density: float) -> void:
	_chunk_manager = ChunkManager.new()
	_chunk_manager.name = "BiomeChunkManager"

	# Population scales: early maps few, late maps many
	var pop := clampi(int(density * 40), 4, 40)

	# Spawn circle covers the entire ring zone around the grid.
	# center = grid center, radius = half-grid diagonal + ring width
	# This ensures organisms fill the ring, not just a circle.
	var half_diag := Vector2(_grid_w * 0.5, _grid_d * 0.5).length() if _grid_w > 0 else 10.0
	var total_radius := half_diag + ring_width

	_chunk_manager.chunk_size = 4.0
	_chunk_manager.max_population = pop
	_chunk_manager.spawn_radius = total_radius
	_chunk_manager.center_offset = grid_center
	_chunk_manager.lod_update_interval = 0.5
	_chunk_manager.creature_throttle_distance = 8.0

	# Override kingdoms/density
	var kingdom_strings: Array[String] = []
	for k in kingdoms:
		kingdom_strings.append(str(k))
	_chunk_manager.override_kingdoms = kingdom_strings
	_chunk_manager.override_density = density

	# Deterministic seeding
	_chunk_manager.rng_seed = _rng.seed

	# Store grid dimensions for inner-zone rejection
	_chunk_manager.set_meta("grid_half_w", _grid_w * 0.5)
	_chunk_manager.set_meta("grid_half_d", _grid_d * 0.5)
	_chunk_manager.set_meta("grid_center", grid_center)

	add_child(_chunk_manager)

	print("[BiomeRing] ChunkManager: pop=%d radius=%.1f kingdoms=%s density=%.2f" % [
		pop, total_radius, str(kingdom_strings), density
	])




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
		"creature":
			# Warm earthy creatures — brown/orange tones
			return Color(_rng.randf_range(0.4, 0.7), _rng.randf_range(0.25, 0.45), _rng.randf_range(0.1, 0.25))
		_:
			return Color(0.3, 0.4, 0.2)
