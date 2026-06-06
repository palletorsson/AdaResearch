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

	# plant: leafy grass-tuft FOLIAGE — a batched fan of thin green blades per
	# cluster. One draw call for all plants; reads as ground foliage, distinct from
	# trees, blooms, and mushrooms.
	if DistributionField.has_layer_for(ctx, "plant"):
		_build_plant_tufts(DistributionField.placements_for(ctx, "plant"), int(ctx.get("rng_seed", 0)))


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


## Leafy grass-tuft foliage: one batched MultiMesh of thin green blades fanning up
## from each plant position. Cheap (1 draw call for all plants) and unmistakably
## foliage — no trunk, no bloom, no glossy sheen. Deterministic from the seed.
func _build_plant_tufts(positions: Array, base_seed: int) -> void:
	if positions.is_empty():
		return
	var blades_per := 9
	var blade := QuadMesh.new()
	blade.size = Vector2(0.07, 1.0)            # unit-tall blade; stretched per instance
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true                       # must precede instance_count
	mm.mesh = blade
	mm.instance_count = positions.size() * blades_per

	var rng := RandomNumberGenerator.new()
	rng.seed = base_seed + 137
	var i := 0
	for pos in positions:
		for b in blades_per:
			var yaw: float = rng.randf() * TAU
			var lean: float = deg_to_rad(rng.randf_range(6.0, 30.0))
			var h: float = 0.30 + rng.randf() * 0.45
			var rot := Basis.from_euler(Vector3(lean, yaw, 0.0))
			var origin: Vector3 = pos + (rot * Vector3.UP) * (h * 0.5)   # root the base at pos
			mm.set_instance_transform(i, Transform3D(rot.scaled(Vector3(1.0, h, 1.0)), origin))
			mm.set_instance_color(i, Color.from_hsv(0.26 + rng.randf() * 0.10, 0.5 + rng.randf() * 0.2, 0.38 + rng.randf() * 0.22))
			i += 1

	var mmi := MultiMeshInstance3D.new()
	mmi.name = "PlantFoliage"
	mmi.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED      # blades visible from both sides
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.9
	mmi.material_override = mat
	add_child(mmi)
	print("  [softbody_flora] %d plant tufts (%d blades) → 1 draw call" % [positions.size(), mm.instance_count])
