# MorphologyRouter.gd — Routes CritterDNA.body_type to the correct mesh generator
#
# The single entry point for "DNA → visible body". Reads body_type as a
# continuous float (0-4) and dispatches to the kingdom-specific morphology
# generator. Fractional body_type values produce hybrids by building the
# primary kingdom's mesh with gene-level blending from the secondary kingdom.
#
# Usage:
#   var root: Node3D = MorphologyRouter.build(dna, parent, trait_mapper, lod)
#
# Hybrid strategy (design decision):
#   body_type = 1.7 → primary kingdom = flower (2), secondary = creature (1)
#   We build the PRIMARY mesh only, but the DNA already carries blended genes
#   from both kingdoms (via crossover). The mesh naturally shows hybrid traits
#   because gene values sit between kingdom norms. No dual-mesh blending needed.
#   At high hybridity (>0.4), we add subtle visual markers from the secondary
#   kingdom as child decorations.

class_name MorphologyRouter
extends RefCounted

# ─────────────────────────────────────────────────────────────
#  Kingdom constants (matching CritterDNA.body_type ranges)
# ─────────────────────────────────────────────────────────────
const KINGDOM_TREE: int = 0
const KINGDOM_CREATURE: int = 1
const KINGDOM_FLOWER: int = 2
const KINGDOM_FUNGUS: int = 3
const KINGDOM_HYBRID: int = 4  # body_type = 4.0 — fully random, pick nearest

## Hybridity threshold above which we add secondary-kingdom decorations.
const HYBRID_DECORATION_THRESHOLD: float = 0.35

## LOD default for hybrid decorations (always one step lower than main).
const HYBRID_DECORATION_LOD_PENALTY: int = 1


# ═══════════════════════════════════════════════════════════════
# PUBLIC API
# ═══════════════════════════════════════════════════════════════

## Build a complete critter body from DNA.
##
## Returns a Node3D root containing all mesh children. The root is
## added as a child of [param parent] if provided.
##
## [param dna]          The genome to express.
## [param parent]       Optional parent node — mesh root will be added as child.
## [param trait_mapper] Shared CritterTraitMapper for material creation.
## [param lod]          Level of detail (0 = highest, 3 = lowest).
static func build(
	dna: CritterDNA,
	parent: Node3D = null,
	trait_mapper: CritterTraitMapper = null,
	lod: int = 2
) -> Node3D:
	if not dna:
		push_error("[MorphologyRouter] Cannot build: null DNA")
		return _fallback_mesh(parent)

	# Resolve the mapper — create one if not provided
	var mapper: CritterTraitMapper = trait_mapper
	if not mapper:
		mapper = CritterTraitMapper.new()

	# Determine primary kingdom
	var kingdom: int = dna.get_kingdom()
	var hybridity: float = dna.get_hybridity()

	# Check if this DNA uses the universal morphology pipeline
	# (body_type > 4.0 or form_process gene is non-default for the kingdom)
	var root: Node3D = null
	if _should_use_pipeline(dna, kingdom):
		root = MorphoPipeline.build_from_dna(dna, parent, mapper, lod)
		if root:
			root.set_meta("morphology_root", true)
			root.set_meta("pipeline_built", true)
			return root

	# Build the primary mesh via kingdom-specific builder
	root = _build_kingdom(kingdom, dna, parent, mapper, lod)
	if not root:
		root = _fallback_mesh(parent)

	# Tag for identification
	root.set_meta("kingdom", kingdom)
	root.set_meta("hybridity", hybridity)
	root.set_meta("body_type", dna.body_type)

	# Add hybrid decorations if significantly hybrid
	if hybridity > HYBRID_DECORATION_THRESHOLD:
		var secondary: int = _get_secondary_kingdom(dna.body_type, kingdom)
		if secondary != kingdom:
			var deco_lod: int = mini(lod + HYBRID_DECORATION_LOD_PENALTY, 3)
			_add_hybrid_decorations(root, dna, secondary, mapper, deco_lod, hybridity)

	return root


## Rebuild an existing critter's mesh in-place. Removes old mesh children
## and builds fresh from DNA. Useful for transmutation or runtime mutation.
static func rebuild(
	entity: Node3D,
	dna: CritterDNA,
	trait_mapper: CritterTraitMapper = null,
	lod: int = 2
) -> Node3D:
	# Remove existing mesh children (preserve non-mesh children like Area3D, etc.)
	var to_remove: Array[Node] = []
	for child in entity.get_children():
		if child is MeshInstance3D or child is MultiMeshInstance3D or child.has_meta("morphology_root"):
			to_remove.append(child)

	for child in to_remove:
		entity.remove_child(child)
		child.queue_free()

	return build(dna, entity, trait_mapper, lod)


## Get the kingdom name for a given body_type float.
static func kingdom_name(body_type: float) -> String:
	match clampi(roundi(body_type), 0, 4):
		0: return "tree"
		1: return "creature"
		2: return "flower"
		3: return "fungus"
		4: return "hybrid"
		_: return "unknown"


## Get both primary and secondary kingdoms for a body_type.
## Returns [primary: int, secondary: int, blend: float].
static func decompose_body_type(body_type: float) -> Dictionary:
	var clamped: float = clampf(body_type, 0.0, 4.0)
	var primary: int = clampi(roundi(clamped), 0, 4)
	var secondary: int = _get_secondary_kingdom(clamped, primary)
	var hybridity: float = absf(clamped - float(primary))
	return {
		"primary": primary,
		"secondary": secondary,
		"hybridity": hybridity,
	}


# ═══════════════════════════════════════════════════════════════
# INTERNAL — Pipeline routing
# ═══════════════════════════════════════════════════════════════

## Determine whether this DNA should use the universal MorphoPipeline
## instead of the kingdom-specific builder. Routes to pipeline when:
##   - body_type > 4.0 (explicit pipeline request)
##   - form_process gene is set to a value that doesn't match the kingdom default
static func _should_use_pipeline(dna: CritterDNA, kingdom: int) -> bool:
	# Explicit pipeline request: body_type beyond the 4 kingdoms
	if dna.body_type > 4.0:
		return true

	# Check if form_process gene exists and differs from kingdom default
	var fp: float = dna.get("form_process") as float if dna.get("form_process") != null else -1.0
	if fp < 0.0:
		return false  # Gene not set (old DNA format) — use kingdom builder

	# Kingdom defaults: tree=0.0-0.15, creature=0.2-0.4, flower=0.2-0.4, fungus=0.0-0.2
	# Only route to pipeline if form_process is clearly outside the kingdom's natural range
	match kingdom:
		KINGDOM_TREE:
			return fp > 0.45  # Trees are naturally "grown" (low form_process)
		KINGDOM_CREATURE:
			return fp > 0.6 or fp < 0.1  # Creatures are naturally "extruded"
		KINGDOM_FLOWER:
			return fp > 0.6 or fp < 0.1
		KINGDOM_FUNGUS:
			return fp > 0.45
		KINGDOM_HYBRID:
			return true  # Hybrids always try the pipeline

	return false


# ═══════════════════════════════════════════════════════════════
# INTERNAL — Kingdom dispatch
# ═══════════════════════════════════════════════════════════════

## Dispatch to the correct kingdom-specific morphology builder.
static func _build_kingdom(
	kingdom: int,
	dna: CritterDNA,
	parent: Node3D,
	mapper: CritterTraitMapper,
	lod: int
) -> Node3D:
	var root: Node3D = null

	match kingdom:
		KINGDOM_TREE:
			root = TreeMorphology.build(dna, parent, mapper, lod)
		KINGDOM_CREATURE:
			root = CreatureMorphology.build(dna, parent, mapper, lod)
		KINGDOM_FLOWER:
			root = FlowerMorphology.build(dna, parent, mapper, lod)
		KINGDOM_FUNGUS:
			root = FungusMorphology.build(dna, parent, mapper, lod)
		KINGDOM_HYBRID:
			# body_type=4 is "fully hybrid" — pick nearest non-4 kingdom
			# based on secondary gene indicators
			var best_kingdom: int = _infer_kingdom_from_genes(dna)
			root = _build_kingdom(best_kingdom, dna, parent, mapper, lod)
		_:
			push_warning("[MorphologyRouter] Unknown kingdom %d, using fallback" % kingdom)
			root = _fallback_mesh(parent)

	if root:
		root.set_meta("morphology_root", true)

	return root


## When body_type = 4 (true hybrid), infer which kingdom to use from gene patterns.
static func _infer_kingdom_from_genes(dna: CritterDNA) -> int:
	# Score each kingdom by how well the genes match its archetype
	var scores: Array[float] = [0.0, 0.0, 0.0, 0.0]

	# Tree indicators: low mobility, branching, deep roots
	scores[0] = (1.0 - dna.mobility) * 0.3 + dna.leaf_density * 0.3 + (1.0 - dna.aggression) * 0.2 + dna.root_type * 0.2

	# Creature indicators: high mobility, curiosity, aggression
	scores[1] = dna.mobility * 0.4 + dna.curiosity * 0.2 + dna.aggression * 0.3 + (1.0 - dna.leaf_density) * 0.1

	# Flower indicators: scent, low mobility, symmetry, nectar
	scores[2] = dna.scent_strength * 0.3 + dna.nectar_quality * 0.3 + (1.0 - dna.mobility) * 0.2 + (1.0 - dna.aggression) * 0.2

	# Fungus indicators: organic energy, sociality (colony), low mobility
	var organic_score: float = clampf(1.0 - absf(dna.energy_source - 1.5), 0.0, 1.0)
	scores[3] = organic_score * 0.3 + dna.sociality * 0.3 + (1.0 - dna.mobility) * 0.2 + dna.transparency * 0.2

	# Find highest scoring kingdom
	var best: int = 0
	var best_score: float = scores[0]
	for i in range(1, 4):
		if scores[i] > best_score:
			best_score = scores[i]
			best = i

	return best


## Get the secondary kingdom from a fractional body_type.
## E.g., body_type=1.7 → primary=2 (flower), secondary=1 (creature).
static func _get_secondary_kingdom(body_type: float, primary: int) -> int:
	var fractional: float = body_type - float(primary)
	if absf(fractional) < 0.01:
		return primary  # Pure, no secondary

	# Fractional part tells us direction
	if fractional > 0.0:
		return mini(primary + 1, 4)
	else:
		return maxi(primary - 1, 0)


# ═══════════════════════════════════════════════════════════════
# HYBRID DECORATIONS — Secondary kingdom visual markers
# ═══════════════════════════════════════════════════════════════

## Add subtle decorations from the secondary kingdom.
## These are small-scale mesh additions that hint at the critter's hybrid nature.
static func _add_hybrid_decorations(
	root: Node3D,
	dna: CritterDNA,
	secondary_kingdom: int,
	mapper: CritterTraitMapper,
	lod: int,
	hybridity: float
) -> void:
	# Scale decoration intensity by hybridity (0.35-0.5 = subtle, 0.5 = full)
	var intensity: float = clampf((hybridity - HYBRID_DECORATION_THRESHOLD) / (0.5 - HYBRID_DECORATION_THRESHOLD), 0.0, 1.0)

	# Collect existing mesh bounds for placement
	var aabb: AABB = _estimate_aabb(root)
	if aabb.size.length() < 0.01:
		return

	var deco_parent := Node3D.new()
	deco_parent.name = "HybridDecorations"
	deco_parent.set_meta("hybrid_secondary", secondary_kingdom)
	root.add_child(deco_parent)

	match secondary_kingdom:
		KINGDOM_TREE:
			_add_tree_decorations(deco_parent, dna, mapper, lod, intensity, aabb)
		KINGDOM_CREATURE:
			_add_creature_decorations(deco_parent, dna, mapper, lod, intensity, aabb)
		KINGDOM_FLOWER:
			_add_flower_decorations(deco_parent, dna, mapper, lod, intensity, aabb)
		KINGDOM_FUNGUS:
			_add_fungus_decorations(deco_parent, dna, mapper, lod, intensity, aabb)


## Tree decorations: small branch stubs or bark patches on a non-tree body.
static func _add_tree_decorations(
	parent: Node3D, dna: CritterDNA, mapper: CritterTraitMapper,
	lod: int, intensity: float, aabb: AABB
) -> void:
	var count: int = maxi(roundi(intensity * 3.0), 1)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(dna.primary_color.to_html()) + 100

	for i in count:
		var stub := MeshInstance3D.new()
		stub.name = "TreeStub_%d" % i
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.02 * dna.part_width * dna.scale
		cyl.bottom_radius = 0.04 * dna.part_width * dna.scale
		cyl.height = 0.15 * dna.part_length * dna.scale * intensity
		cyl.radial_segments = 4 if lod >= 2 else 6
		stub.mesh = cyl

		# Place on surface of the body
		var pos := Vector3(
			rng.randf_range(aabb.position.x, aabb.end.x) * 0.6,
			rng.randf_range(aabb.position.y + aabb.size.y * 0.3, aabb.end.y * 0.8),
			rng.randf_range(aabb.position.z, aabb.end.z) * 0.6
		)
		stub.position = pos
		stub.rotation.z = rng.randf_range(-0.5, 0.5)

		# Apply bark-like material
		var mat: ShaderMaterial = mapper.create_material_from_dna(dna, hash(pos))
		stub.material_override = mat

		parent.add_child(stub)


## Creature decorations: small bumps or eye-like spots on a non-creature body.
static func _add_creature_decorations(
	parent: Node3D, dna: CritterDNA, mapper: CritterTraitMapper,
	lod: int, intensity: float, aabb: AABB
) -> void:
	var count: int = maxi(roundi(intensity * 2.0), 1)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(dna.secondary_color.to_html()) + 200

	for i in count:
		# Small eye-like spheres
		var eye := MeshInstance3D.new()
		eye.name = "EyeSpot_%d" % i
		var sphere := SphereMesh.new()
		var eye_size: float = 0.03 * dna.scale * intensity
		sphere.radius = eye_size
		sphere.height = eye_size * 2.0
		sphere.radial_segments = 4 if lod >= 2 else 8
		sphere.rings = 2 if lod >= 2 else 4
		eye.mesh = sphere

		var pos := Vector3(
			rng.randf_range(aabb.position.x * 0.3, aabb.end.x * 0.3),
			rng.randf_range(aabb.position.y + aabb.size.y * 0.5, aabb.end.y),
			aabb.position.z + aabb.size.z * 0.5 + eye_size  # Front-ish
		)
		eye.position = pos

		var mat: ShaderMaterial = mapper.create_material_from_dna(dna, hash(pos) + 50)
		eye.material_override = mat

		parent.add_child(eye)


## Flower decorations: small petal buds or color patches on a non-flower body.
static func _add_flower_decorations(
	parent: Node3D, dna: CritterDNA, mapper: CritterTraitMapper,
	lod: int, intensity: float, aabb: AABB
) -> void:
	var count: int = maxi(roundi(intensity * 4.0), 1)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(dna.tertiary_color.to_html()) + 300

	for i in count:
		# Small petal-like quads
		var bud := MeshInstance3D.new()
		bud.name = "PetalBud_%d" % i
		var quad := QuadMesh.new()
		quad.size = Vector2(
			0.06 * dna.part_width * dna.scale * intensity,
			0.1 * dna.part_length * dna.scale * intensity
		)
		bud.mesh = quad

		var pos := Vector3(
			rng.randf_range(aabb.position.x, aabb.end.x) * 0.7,
			rng.randf_range(aabb.position.y, aabb.end.y),
			rng.randf_range(aabb.position.z, aabb.end.z) * 0.7
		)
		bud.position = pos
		bud.rotation = Vector3(
			rng.randf_range(-0.3, 0.3),
			rng.randf_range(0.0, TAU),
			rng.randf_range(-0.3, 0.3)
		)

		var mat: ShaderMaterial = mapper.create_material_from_dna(dna, hash(pos) + 70)
		bud.material_override = mat

		parent.add_child(bud)


## Fungus decorations: small cap bumps or spore-like spheres on a non-fungus body.
static func _add_fungus_decorations(
	parent: Node3D, dna: CritterDNA, mapper: CritterTraitMapper,
	lod: int, intensity: float, aabb: AABB
) -> void:
	var count: int = maxi(roundi(intensity * 3.0), 1)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(dna.primary_color.to_html()) + 400

	for i in count:
		var cap := MeshInstance3D.new()
		cap.name = "FungusSpot_%d" % i
		var sphere := SphereMesh.new()
		var cap_size: float = 0.04 * dna.scale * intensity
		sphere.radius = cap_size
		sphere.height = cap_size * 1.2  # Slightly flattened
		sphere.radial_segments = 4 if lod >= 2 else 6
		sphere.rings = 2 if lod >= 2 else 3
		cap.mesh = sphere

		var pos := Vector3(
			rng.randf_range(aabb.position.x, aabb.end.x) * 0.5,
			rng.randf_range(aabb.position.y, aabb.position.y + aabb.size.y * 0.5),
			rng.randf_range(aabb.position.z, aabb.end.z) * 0.5
		)
		cap.position = pos

		var mat: ShaderMaterial = mapper.create_material_from_dna(dna, hash(pos) + 90)
		cap.material_override = mat

		parent.add_child(cap)


# ═══════════════════════════════════════════════════════════════
# UTILITY
# ═══════════════════════════════════════════════════════════════

## Estimate the AABB of all mesh children (MeshInstance3D + MultiMeshInstance3D).
static func _estimate_aabb(root: Node3D) -> AABB:
	var combined := AABB()
	var found_any: bool = false

	for child in root.get_children():
		var child_aabb := AABB()
		var valid: bool = false

		if child is MeshInstance3D:
			var mi: MeshInstance3D = child as MeshInstance3D
			if mi.mesh:
				child_aabb = mi.mesh.get_aabb()
				child_aabb.position += mi.position
				valid = true
		elif child is MultiMeshInstance3D:
			var mmi: MultiMeshInstance3D = child as MultiMeshInstance3D
			if mmi.multimesh and mmi.multimesh.instance_count > 0:
				child_aabb = mmi.multimesh.get_aabb()
				child_aabb.position += mmi.position
				valid = true

		if valid:
			if found_any:
				combined = combined.merge(child_aabb)
			else:
				combined = child_aabb
				found_any = true

	if not found_any:
		# Default small AABB
		combined = AABB(Vector3(-0.2, 0.0, -0.2), Vector3(0.4, 0.5, 0.4))

	return combined


## Create a simple fallback mesh for error cases.
static func _fallback_mesh(parent: Node3D = null) -> Node3D:
	var root := Node3D.new()
	root.name = "FallbackCritter"
	root.set_meta("morphology_root", true)
	root.set_meta("is_fallback", true)

	var mi := MeshInstance3D.new()
	mi.name = "FallbackMesh"
	var box := BoxMesh.new()
	box.size = Vector3(0.2, 0.2, 0.2)
	mi.mesh = box

	# Bright magenta = something went wrong
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color.MAGENTA
	mi.material_override = mat

	root.add_child(mi)

	if parent:
		parent.add_child(root)

	return root


