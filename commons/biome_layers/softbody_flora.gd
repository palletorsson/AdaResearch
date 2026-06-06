# softbody_flora.gd
# Seq 13: softbodies. REAL DNA-driven flowers + mushrooms from the nature system —
# the Flower (kingdom 2) and Fungus (kingdom 3) morphologies, spawned through the
# production CritterSpawner pipeline (the same one dna_creatures uses for critters,
# and Pokemon Studio for breeding). Each organism's form varies by a deterministic
# per-position DNA seed, so reloads place the same garden.
#
# Replaces the earlier placeholder (cylinder stems + sphere caps + a wobble shader).
# flower → CritterDNA.random_kingdom(2); mushroom → kingdom 3. Same API: apply(ctx).

extends Node3D

const CritterDNAClass = preload("res://algorithms/nature_system/dna/critter_dna.gd")
const CritterTraitMapperClass = preload("res://algorithms/nature_system/dna/critter_trait_mapper.gd")
const CritterSpawnerClass = preload("res://algorithms/nature_system/systems/spawner.gd")
const DistributionField = preload("res://commons/biome_layers/distribution_field.gd")

const KINGDOM_TREE := 0
const KINGDOM_FLOWER := 2
const KINGDOM_FUNGUS := 3

var _trait_mapper: CritterTraitMapper = null
var _spawner: CritterSpawner = null


func _get_spawner() -> CritterSpawner:
	if _spawner == null:
		_trait_mapper = CritterTraitMapperClass.new()
		_spawner = CritterSpawnerClass.new(self)
		_spawner.trait_mapper = _trait_mapper
		_spawner.max_population = 240   # bounds flower + mushroom together
		_spawner.default_lod = 1        # decorative flora — cheap LOD
	return _spawner


func apply(ctx: Dictionary) -> void:
	var grid_center: Vector3 = ctx.get("grid_center", Vector3.ZERO)
	var grid_dims: Vector3i = ctx.get("grid_dims", Vector3i(10, 1, 10))
	var cube_size: float = float(ctx.get("cube_size", 1.0))

	var rng := RandomNumberGenerator.new()
	rng.seed = int(ctx.get("rng_seed", 0)) + 13

	# flower: a "flower" paint distribution, else the default ring footprint.
	var flower_pos: Array = []
	if DistributionField.has_layer_for(ctx, "flower"):
		flower_pos = DistributionField.placements_for(ctx, "flower")
	else:
		flower_pos = _ring_positions(grid_center, grid_dims, cube_size, rng, 14)
	for pos in flower_pos:
		_spawn(KINGDOM_FLOWER, pos)

	# mushroom: paint-only (no default ring), same engine, Fungus kingdom.
	if DistributionField.has_layer_for(ctx, "mushroom"):
		for pos in DistributionField.placements_for(ctx, "mushroom"):
			_spawn(KINGDOM_FUNGUS, pos)

	# plant: paint-only leafy foliage — a small, bushy Tree-kingdom form (the tree
	# morphology carries real batched leaves), distinct from a tall tree or a bloom.
	if DistributionField.has_layer_for(ctx, "plant"):
		for pos in DistributionField.placements_for(ctx, "plant"):
			_spawn_plant(pos)


## Scatter `n` points in the ring annulus around the grid (the default footprint
## when no paint layer authors a distribution).
func _ring_positions(center: Vector3, dims: Vector3i, cube: float, rng: RandomNumberGenerator, n: int) -> Array:
	var radius: float = maxf(float(dims.x), float(dims.z)) * cube * 0.75 + 4.0
	var exclude: float = maxf(float(dims.x), float(dims.z)) * cube * 0.5 + 1.0
	var out: Array = []
	for i in n:
		var angle: float = rng.randf() * TAU
		var r: float = rng.randf_range(exclude, radius)
		out.append(center + Vector3(cos(angle) * r, 0.0, sin(angle) * r))
	return out


## One DNA organism of `kingdom` (2 = flower, 3 = fungus) at `pos`. Deterministic
## form from the position seed.
func _spawn(kingdom: int, pos: Vector3) -> void:
	var seed: int = (int(pos.x * 13.0) * 41 + int(pos.z * 13.0) * 23) & 0xFFFF
	var dna: CritterDNA = CritterDNAClass.random_kingdom(kingdom, seed)
	_get_spawner().spawn(dna, pos)


## A "plant" — a small, bushy, leafy Tree-kingdom form. Reuses the tree morphology
## (real batched foliage) shrunk down and de-mobilised so it reads as greenery, not
## a tall tree or a flowering bloom.
func _spawn_plant(pos: Vector3) -> void:
	var seed: int = (int(pos.x * 13.0) * 41 + int(pos.z * 13.0) * 23) & 0xFFFF
	var dna: CritterDNA = CritterDNAClass.random_kingdom(KINGDOM_TREE, seed)
	dna.scale = 0.22 + 0.10 * (float(seed >> 3 & 7) / 7.0)   # small (shrub/plant sized)
	dna.segments = 3.0 + float(seed % 2)                      # low depth → bushy, not tall
	dna.leaf_density = 0.85                                   # lots of foliage
	dna.mobility = 0.0                                        # never a walking tree
	var h: float = 0.28 + 0.06 * (float(seed % 7) / 7.0)     # leafy green palette
	dna.primary_color = Color.from_hsv(h, 0.55, 0.48)
	dna.secondary_color = Color.from_hsv(h + 0.02, 0.50, 0.42)
	dna.tertiary_color = Color.from_hsv(h - 0.02, 0.60, 0.55)
	_get_spawner().spawn(dna, pos)
