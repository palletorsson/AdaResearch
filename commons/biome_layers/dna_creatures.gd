# dna_creatures.gd
# Seq 12: proceduralgeneration. DNA-driven critters.
#
# Calls CritterSpawner.spawn() — the production DNA-driven critter pipeline
# (CritterEntity + bond/age/breed lifecycle) shared with Pokemon Studio and
# the painted-cell dispatcher. Each critter gets a walker-tuned CritterDNA
# whose per-creature variation comes from the rng seed (deterministic per
# context, so reloads place creatures in the same arrangement).
#
# Replaces the earlier placeholder that emitted SphereMesh body + CylinderMesh
# legs (the cone-legged stick critters). Same external API: apply(ctx).

extends Node3D

const CritterDNAClass = preload("res://algorithms/nature_system/dna/critter_dna.gd")
const CritterTraitMapperClass = preload("res://algorithms/nature_system/dna/critter_trait_mapper.gd")
const CritterSpawnerClass = preload("res://algorithms/nature_system/systems/spawner.gd")

var _trait_mapper: CritterTraitMapper = null
var _spawner: CritterSpawner = null


func _get_trait_mapper() -> CritterTraitMapper:
	if _trait_mapper == null:
		_trait_mapper = CritterTraitMapperClass.new()
	return _trait_mapper


func _get_spawner() -> CritterSpawner:
	if _spawner == null:
		_spawner = CritterSpawnerClass.new(self)
		_spawner.trait_mapper = _get_trait_mapper()
		_spawner.max_population = 80   # ring count caps below this
		_spawner.default_lod = 1       # ring critters are decorative; cheap
	return _spawner


func apply(ctx: Dictionary) -> void:
	var params: Dictionary = ctx.get("params", {})
	var count_range: Array = params.get("creature_count_range", [8, 20])
	var grid_center: Vector3 = ctx.get("grid_center", Vector3.ZERO)
	var grid_dims: Vector3i = ctx.get("grid_dims", Vector3i(10, 1, 10))
	var cube_size: float = ctx.get("cube_size", 1.0)

	var rng := RandomNumberGenerator.new()
	rng.seed = int(ctx.get("rng_seed", 0)) + 12
	var count: int = rng.randi_range(int(count_range[0]), int(count_range[1]))

	# Place around the floor footprint. Same ring math as the previous
	# placeholder so the spatial arrangement is unchanged — only the
	# rendered creature is upgraded.
	var radius: float = maxf(float(grid_dims.x), float(grid_dims.z)) * cube_size * 0.6 + 5.0
	var exclude: float = maxf(float(grid_dims.x), float(grid_dims.z)) * cube_size * 0.5 + 0.5

	for i in count:
		var angle: float = rng.randf() * TAU
		var r: float = rng.randf_range(exclude, radius)
		var pos: Vector3 = grid_center + Vector3(cos(angle) * r, 0.0, sin(angle) * r)
		var seed: int = (int(pos.x * 13.0) * 41 + int(pos.z * 13.0) * 23) & 0xFFFF

		# Walker-tuned DNA — same shape as biome_paint_dispatcher's
		# _spawn_creature, slightly smaller / less aggressive (decorative).
		var dna: CritterDNA = CritterDNAClass.new()
		dna.body_type = 1.0  # walker
		dna.segments = 4.0 + float(seed % 4)               # 4..7
		dna.symmetry = 2.0 + float(seed % 4)               # 2..5
		dna.scale = 0.4 + 0.20 * (float(seed >> 3 & 7) / 7.0)  # ~0.4..0.6
		dna.mobility = 0.4 + 0.10 * (float(seed >> 5 & 7) / 7.0)
		dna.aggression = 0.05 + 0.03 * float(seed & 7) / 7.0
		dna.sociality = 0.5 + 0.4 * (float(seed >> 4 & 7) / 7.0)
		dna.curiosity = 0.6
		# Bright per-creature colours — read against grass + tree biome.
		var hue_base: float = float(seed % 360) / 360.0
		dna.primary_color = Color.from_hsv(hue_base, 0.65, 0.85)
		dna.secondary_color = Color.from_hsv(fposmod(hue_base + 0.15, 1.0), 0.5, 0.7)
		dna.tertiary_color = Color.from_hsv(fposmod(hue_base + 0.45, 1.0), 0.7, 0.9)
		dna.iridescence = 0.10
		dna.roughness = 0.5
		dna.metallic = 0.05

		_get_spawner().spawn(dna, pos)
