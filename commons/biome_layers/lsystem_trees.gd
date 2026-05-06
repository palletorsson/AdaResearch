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
const TreeMorphologyClass = preload("res://algorithms/nature_system/morphology/tree_morphology.gd")

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

	# Place trees in a ring just outside the map footprint.
	var radius: float = maxf(float(grid_dims.x), float(grid_dims.z)) * cube_size * 0.9 + 3.0
	var tree_count: int = 8
	for i in tree_count:
		var theta: float = float(i) / float(tree_count) * TAU + 0.15
		var pos: Vector3 = grid_center + Vector3(
			cos(theta) * radius, 0.0, sin(theta) * radius
		)
		_spawn_tree(pos, i)


# Build one DNA-driven tree at `pos`. The seed (i) gives each tree in the ring
# a slightly different DNA without RNG — deterministic, curriculum-friendly.
func _spawn_tree(pos: Vector3, i: int) -> void:
	var seed: int = (i * 31 + 7) & 0xFFFF

	var dna: CritterDNA = CritterDNAClass.new()
	dna.body_type = 0.0  # 0 = tree in MorphologyRouter's encoding
	# Medium-tier tree (intensity 3 of 5). Mirrors dispatcher's tree-3 config.
	dna.segments = 5.0
	dna.scale = 1.0
	dna.branch_angle = 18.0 + float(seed % 16)         # 18..33 deg
	dna.branch_decay = 0.65 + 0.05 * (float(seed >> 4 & 7) / 7.0)
	dna.leaf_density = 0.55
	# Earth-bark trunk + leaf-green crown — matches the dispatcher palette
	# so painted t-cells and ring trees read as the same kingdom.
	dna.primary_color = Color(0.32 + 0.05 * float(seed & 3) * 0.1, 0.22, 0.12)
	dna.secondary_color = Color(0.14, 0.55, 0.12)
	dna.tertiary_color = Color(0.20, 0.55, 0.15)
	dna.symmetry = 3.0 + float(seed % 3)  # 3..5 branch fans
	dna.roughness = 0.85
	dna.metallic = 0.0

	var tree_root := Node3D.new()
	tree_root.name = "RingTree_%d" % i
	add_child(tree_root)
	tree_root.global_position = pos

	# LOD 1: 4-sided tubes, ~80 branch cap. Cheap enough to ring 8 maps with.
	TreeMorphologyClass.build(dna, tree_root, _get_trait_mapper(), 1)
