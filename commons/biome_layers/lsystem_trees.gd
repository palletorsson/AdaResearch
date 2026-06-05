# lsystem_trees.gd
# Seq 11: lsystems. L-system trees — string rewriting turned into geometry.
#
# Calls TreeMorphology.build() — the production 753-LOC DNA-driven L-system
# tree builder shared with the painted-cell dispatcher. Each ring tree gets a
# tree-tuned CritterDNA; per-position seed gives each tree a different look
# without random calls (deterministic from grid coords).
#
# Replaces the earlier placeholder that emitted CylinderMesh stems
# (the "default cones"). Same external API: apply(ctx).

extends Node3D

const CritterDNAClass = preload("res://algorithms/nature_system/dna/critter_dna.gd")
const CritterTraitMapperClass = preload("res://algorithms/nature_system/dna/critter_trait_mapper.gd")
# SpawnService preloaded (not referenced by global class_name) so it
# resolves on headless runs before the global class cache is rebuilt.
const SpawnService = preload("res://commons/biome_layers/spawn_service.gd")
const DistributionField = preload("res://commons/biome_layers/distribution_field.gd")

# Shared trait mapper — built lazily on first apply(), reused across all
# trees in this layer instance. Heavy (loads the critter DNA shader);
# avoid constructing if the layer never spawns anything.
var _trait_mapper: CritterTraitMapper = null


func _get_trait_mapper() -> CritterTraitMapper:
	if _trait_mapper == null:
		_trait_mapper = CritterTraitMapperClass.new()
	return _trait_mapper


func apply(ctx: Dictionary) -> void:
	var grid_center: Vector3 = ctx.get("grid_center", Vector3.ZERO)
	var grid_dims: Vector3i = ctx.get("grid_dims", Vector3i(10, 1, 10))
	var cube_size: float = ctx.get("cube_size", 1.0)

	# Paint layers (opt-in): if the map authored a "tree" distribution, place
	# trees by that field instead of the default perimeter ring. The accrual
	# stack stays the single populator — this is per-map authoring it consults.
	# See doc/PAINT_LAYERS.md.
	if DistributionField.has_layer_for(ctx, "tree"):
		var painted: Array = DistributionField.placements_for(ctx, "tree")
		var pi: int = 0
		for p in painted:
			_spawn_tree(p, pi)
			pi += 1
		return

	# Default: place trees in a ring just outside the map footprint.
	var radius: float = maxf(float(grid_dims.x), float(grid_dims.z)) * cube_size * 0.9 + 3.0
	# Phase 5: scale the target count by the population budget (1.0 = unchanged).
	var tree_count: int = maxi(0, int(round(8.0 * float(ctx.get("budget_scale", 1.0)))))
	for i in tree_count:
		var theta: float = float(i) / float(tree_count) * TAU + 0.15
		var pos: Vector3 = grid_center + Vector3(
			cos(theta) * radius, 0.0, sin(theta) * radius
		)
		_spawn_tree(pos, i)


# Build one DNA-driven tree at `pos`. The seed (i) gives each tree in the ring
# a slightly different DNA without RNG — deterministic, curriculum-friendly.
# DNA recipe + build now live in BiomeSpawnService (consolidation Phase 1);
# this layer uses the shared tree-3 defaults verbatim.
func _spawn_tree(pos: Vector3, i: int) -> void:
	var seed: int = (i * 31 + 7) & 0xFFFF
	var dna: CritterDNA = SpawnService.tree_dna_from_seed(seed)
	# LOD 1: 4-sided tubes, ~80 branch cap. Cheap enough to ring 8 maps with.
	SpawnService.build_tree(dna, self, _get_trait_mapper(), 1, "RingTree_%d" % i, pos)
