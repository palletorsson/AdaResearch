extends RefCounted
class_name BiomeSpawnService

## Single home for building DNA-driven biome organisms.
##
## Phase 1 of the biome consolidation (commons/biome_layers/CONSOLIDATION_PLAN.md):
## DRY the duplicate tree/creature build code that lived in THREE places —
## lsystem_trees.gd, BiomeRingComponent.gd (_spawn_dna_trees), and
## biome_paint_dispatcher.gd (_spawn_tree). All three built a tree-tuned
## CritterDNA from a seed (the same ~12 lines) then called the identical
## `TreeMorphology.build(dna, root, mapper, 1)`.
##
## This is a PURE refactor — zero behaviour change. Each caller keeps the
## few DNA fields that genuinely vary (segments, scale, secondary green);
## the shared recipe + build boilerplate move here.
##
## Phase 2 will add ChunkManager enrolment + VisibilityRangeHelper
## .merge_mesh_children HERE, in build_tree() — so all callers get LOD +
## draw-call batching for free, in one place. (Today lsystem_trees spawns
## loose, bypassing the merge path; that's the perf cliff Phase 2 closes.)

const CritterDNAClass = preload("res://algorithms/nature_system/dna/critter_dna.gd")
const TreeMorphologyClass = preload("res://algorithms/nature_system/morphology/tree_morphology.gd")


## The shared tree DNA recipe — earth-bark trunk + leaf-green crown,
## fully deterministic from `seed` (no RNG; curriculum-honest). This is
## the medium-tier ("tree-3") config that the painted dispatcher, the
## L-system ring layer, and the biome ring all converged on, so painted
## t-cells and ring trees read as the same kingdom.
##
## Callers override only the fields that vary between sites:
##   - lsystem_trees: uses these defaults as-is (segments 5, scale 1).
##   - BiomeRingComponent: overrides segments (4..6), scale (~.85..1.15),
##     and the green of secondary_color.
static func tree_dna_from_seed(seed: int) -> CritterDNA:
	var dna: CritterDNA = CritterDNAClass.new()
	dna.body_type = 0.0  # 0 = tree in MorphologyRouter's encoding
	dna.segments = 5.0
	dna.scale = 1.0
	dna.branch_angle = 18.0 + float(seed % 16)              # 18..33 deg
	dna.branch_decay = 0.65 + 0.05 * (float(seed >> 4 & 7) / 7.0)
	dna.leaf_density = 0.55
	dna.primary_color = Color(0.32 + 0.05 * float(seed & 3) * 0.1, 0.22, 0.12)
	dna.secondary_color = Color(0.14, 0.55, 0.12)
	dna.tertiary_color = Color(0.20, 0.55, 0.15)
	dna.symmetry = 3.0 + float(seed % 3)                    # 3..5 branch fans
	dna.roughness = 0.85
	dna.metallic = 0.0
	return dna


## The shared WALKER creature DNA recipe — bright per-seed HSV colours,
## passive/social temperament, deterministic from `seed`. This is the
## core shared verbatim by biome_paint_dispatcher._spawn_creature and
## BiomeRingComponent._spawn_dna_creatures. Callers override only the
## fields that vary by site: segments, scale, mobility, iridescence.
static func creature_dna_from_seed(seed: int) -> CritterDNA:
	var dna: CritterDNA = CritterDNAClass.new()
	dna.body_type = 1.0  # walker
	dna.symmetry = 2.0 + float(seed % 4)                    # 2..5
	dna.aggression = 0.05 + 0.03 * float(seed & 7) / 7.0    # passive
	dna.sociality = 0.5 + 0.4 * (float(seed >> 4 & 7) / 7.0)
	dna.curiosity = 0.6
	var hue_base: float = float(seed % 360) / 360.0
	dna.primary_color = Color.from_hsv(hue_base, 0.65, 0.85)
	dna.secondary_color = Color.from_hsv(fposmod(hue_base + 0.15, 1.0), 0.5, 0.7)
	dna.tertiary_color = Color.from_hsv(fposmod(hue_base + 0.45, 1.0), 0.7, 0.9)
	dna.roughness = 0.5
	dna.metallic = 0.05
	return dna


## Build one DNA tree as a child of `parent`, positioned at `pos`.
## `mapper` is a CritterTraitMapper (callers own/cache it — it's heavy).
## `lod` 1 = 4-sided tubes, ~80-branch cap (the ring/accrual default).
## Returns the tree root Node3D.
##
## PHASE 2: when `merge` is true (default), the tree's per-branch
## MeshInstance3D nodes are collapsed into ONE merged mesh after build.
## TreeMorphology emits each branch as its own MeshInstance — measured at
## ~200 draw calls for a single LOD-1 tree (8 trees = 1624). Merging
## drops that to ~1 mesh + 1 leaf MultiMesh per tree. The per-branch
## depth-darkening is dropped in favour of one representative bark
## material — invisible at ring/biome distance, and this is the single
## point where ALL three tree callers (accrual, ring, painted) get the
## win for free.
static func build_tree(dna: CritterDNA, parent: Node3D, mapper,
		lod: int, node_name: String, pos: Vector3,
		y_rotation: float = 0.0, merge: bool = true) -> Node3D:
	var root := Node3D.new()
	root.name = node_name
	parent.add_child(root)
	root.global_position = pos
	if y_rotation != 0.0:
		root.rotate_y(y_rotation)
	TreeMorphologyClass.build(dna, root, mapper, lod)
	if merge:
		_merge_branch_meshes(root)
	return root


## Collapse all MeshInstance3D descendants of `root` (the tree's branch
## tubes) into a single merged ArrayMesh with one representative material.
## MultiMeshInstance3D children (leaves — already one draw call) are left
## untouched. Geometry is preserved exactly via SurfaceTool.append_from
## with each branch's transform relative to root.
static func _merge_branch_meshes(root: Node3D) -> void:
	# Gather branch MeshInstances (depth-first), and a representative
	# material from the first one.
	var branches: Array = []
	var rep_material: Material = null
	var stack: Array = [root]
	while not stack.is_empty():
		var n = stack.pop_back()
		for c in n.get_children():
			if c is MeshInstance3D and c.mesh != null:
				branches.append(c)
				if rep_material == null:
					rep_material = c.material_override
			stack.append(c)
	if branches.size() < 2:
		return  # nothing meaningful to merge

	var root_inv: Transform3D = root.global_transform.affine_inverse()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var any := false
	for mi in branches:
		var m: Mesh = mi.mesh
		var rel: Transform3D = root_inv * mi.global_transform
		for si in range(m.get_surface_count()):
			st.append_from(m, si, rel)
			any = true
	if not any:
		return
	var merged_mesh: ArrayMesh = st.commit()
	if merged_mesh == null:
		return

	var merged := MeshInstance3D.new()
	merged.name = "MergedBranches"
	merged.mesh = merged_mesh
	if rep_material != null:
		merged.material_override = rep_material
	root.add_child(merged)
	# Free the now-redundant per-branch instances.
	for mi in branches:
		mi.queue_free()
