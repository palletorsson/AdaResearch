# biome_paint_dispatcher.gd
# Step 3 of the build path in commons/biome_layers/DESIGN.md.
#
# Reads painted cells from the map's biome_paint layer and dispatches each
# deposit to a substrate, picked by (kingdom, current_sequence_order).
# This is the bridge between the biome_paint authoring surface (the
# /editor in encyclopedia, the painted Biome_Spine layer) and the
# rendering substrates (lsystem_trees, ca_surface, dna_creatures, etc.).
#
# The painted cell is a SEED, not a render unit. The dispatcher's job:
#   1. Walk the painted layer cell-by-cell (BiomePaintTokens parses it).
#   2. For each deposit, check the kingdom is curriculum-honest at the
#      current stage_order; if not, emit a primitive fallback.
#   3. Look up (kingdom, stage_order) in the dispatch table for the
#      crown-jewel substrate config; forward to that substrate's API.
#   4. If no dispatch entry exists, primitive fallback.
#
# Status 2026-05-05: Foundation alive — TODOs 3.a (unlock guard),
# 3.g (primitive fallback), 3.h (cell-to-world) filled. Painted cells
# now spawn cube primitives at the right positions, kingdom-color tinted.
# TODOs 3.b–3.f (substrate lookup + dispatch) are next session — they
# upgrade individual kingdoms from primitive to crown-jewel substrate.

extends Node3D
class_name BiomePaintDispatcher

const BiomePaintTokensClass = preload("res://algorithms/nature_system/systems/biome_paint_tokens.gd")
const BiomeConfigLoaderClass = preload("res://commons/biome_layers/biome_config_loader.gd")
const BotanicalFlowerScene = preload("res://commons/flora/botanical_flower.tscn")
# MoldNetwork.tscn is a pre-configured CellularAutomata3D_Flexible scene
# whose rule string ("4-6/5-7/10/M") produces mycelial-network growth.
# We instantiate it per painted u-cell and downsize the grid so each
# CA cluster fits a single biome cell (~0.5–1.0m).
const MoldNetworkScene = preload("res://algorithms/cellularautomata/cellular_automata_3d/MoldNetwork.tscn")
# TreeMorphology.build takes a CritterDNA + CritterTraitMapper and
# produces a real DNA-driven L-system tree. Both are RefCounteds we
# construct on demand. The mapper is shared (one per dispatcher),
# the DNA is per-cell (parameterised by intensity / position).
const CritterDNAClass = preload("res://algorithms/nature_system/dna/critter_dna.gd")
const CritterTraitMapperClass = preload("res://algorithms/nature_system/dna/critter_trait_mapper.gd")
const TreeMorphologyClass = preload("res://algorithms/nature_system/morphology/tree_morphology.gd")
# CritterSpawner takes a world_root + DNA and produces a full DNA-driven
# CritterEntity (mesh + shader + bond/age/breed lifecycle). Pokemon Studio
# uses this directly. We share one spawner across all creature deposits
# so its trait_mapper is loaded once.
const CritterSpawnerClass = preload("res://algorithms/nature_system/systems/spawner.gd")

# Per-kingdom substrate scenes / classes. The dispatcher matches on
# kingdom and forwards to one of these. Intensity influences the
# preset/config inside each substrate. Adding a new substrate = one
# preload, one branch in _spawn_for_kingdom.

# Flower preset map moved to biome_config.json's flower_presets_by_intensity.
# Read at spawn time via BiomeConfigLoaderClass.get_flower_preset(intensity).

# ── Cached refs ───────────────────────────────────────────────────────────

# CritterTraitMapper is shared across all DNA-driven spawns this layer
# does in one apply() pass. Constructed lazily because constructing it
# loads the shader, which we don't want on the first apply if the map
# has no DNA-routed cells.
var _trait_mapper: CritterTraitMapper = null
var _critter_spawner: CritterSpawner = null  # Shared across creature deposits.

func _get_trait_mapper() -> CritterTraitMapper:
	if _trait_mapper == null:
		_trait_mapper = CritterTraitMapperClass.new()
	return _trait_mapper

func _get_critter_spawner(parent: Node3D) -> CritterSpawner:
	# Spawner needs a Node3D world_root. We use the dispatch parent.
	# Reuse across deposits in this apply() pass — a fresh apply() on
	# a different map will rebuild because parent changes.
	if _critter_spawner == null or _critter_spawner.world_root != parent:
		_critter_spawner = CritterSpawnerClass.new(parent)
		_critter_spawner.trait_mapper = _get_trait_mapper()
		_critter_spawner.max_population = 500  # Biome_Spine has ~150 c-cells
		_critter_spawner.default_lod = 2
	return _critter_spawner

# ── Constants ─────────────────────────────────────────────────────────────

const KINGDOM_TREE := 0
const KINGDOM_CREATURE := 1
const KINGDOM_FLOWER := 2
const KINGDOM_FUNGUS := 3

# Per-kingdom values now live in commons/biome_layers/biome_config.json
# and load via BiomeConfigLoaderClass. The dispatcher used to hardcode
# unlock_order, primitive-fallback colors, and the flower preset map —
# all of which also lived in encyclopedia/folds.ts and DESIGN.md and
# silently drifted between sessions. One JSON, two readers, no drift.

# ── Public API ────────────────────────────────────────────────────────────

# Standard biome layer contract. ctx must contain:
#   biome_paint: Array[Array[String]]   — the painted layer
#   stage_order: int                    — current sequence order
#   parent: Node3D                      — where to add spawned content
#   grid_center: Vector3                — world centre of the floor grid
#   grid_dims: Vector3i                 — width × height × depth in cells
#   cube_size: float                    — metres per cell
func apply(ctx: Dictionary) -> void:
	var paint: Array = ctx.get("biome_paint", [])
	if paint.is_empty():
		return

	var stage_order: int = int(ctx.get("stage_order", 0))
	var parent: Node3D = ctx.get("parent", self)

	# Walk every painted cell. Each call produces 0+ deposits (painted
	# tokens like 'm5' or 'x4' fan out to multiple kingdom deposits).
	var deposits: Array = BiomePaintTokensClass.iter_painted_cells(paint)
	for deposit in deposits:
		_spawn_for_deposit(deposit, stage_order, ctx, parent)


# ── Internals ─────────────────────────────────────────────────────────────

# Resolve a single painted deposit to a substrate spawn.
# deposit shape (per BiomePaintTokens):
#   { x: int, z: int, kingdom: int, strength: float, sterile: bool, raw: String }
func _spawn_for_deposit(deposit: Dictionary, stage_order: int,
		ctx: Dictionary, parent: Node3D) -> void:
	# Sterile cells carve presence — for now just skip rendering.
	# (Future: emit a debug marker so authors can see sterile placement.)
	if bool(deposit.get("sterile", false)):
		return

	var kingdom: int = int(deposit.get("kingdom", -1))
	if kingdom < 0:
		return

	# 3.a — kingdom unlock guard: a flower painted on a sequence-1
	# (primitives) map shouldn't render as a flower yet because the
	# curriculum hasn't unlocked flowers. Fall back to a small kingdom-
	# coloured primitive so the painted intent is still visible without
	# breaking curriculum honesty. Unlock_order read from
	# biome_config.json — same value the encyclopedia's foldBiome reads.
	var unlock_at: int = BiomeConfigLoaderClass.get_unlock_order(kingdom)
	if stage_order < unlock_at:
		_spawn_primitive_fallback(deposit, ctx, parent)
		return

	# 3.b–3.e — substrate dispatch by kingdom. Each branch wraps a
	# production builder from elsewhere in the project: BotanicalFlower
	# (commons/flora) for flower, TreeMorphology + CritterSpawner for
	# tree/creature when DNA paths are wired (later session),
	# CellularAutomata3D_Flexible for fungus mycelium (later). Branches
	# without a wired substrate fall through to primitive_fallback.
	# This match is the dispatcher's seam — adding a per-kingdom
	# substrate = one new branch.
	match kingdom:
		KINGDOM_FLOWER:
			_spawn_flower(deposit, ctx, parent)
		KINGDOM_FUNGUS:
			_spawn_fungus(deposit, ctx, parent)
		KINGDOM_TREE:
			_spawn_tree(deposit, ctx, parent)
		KINGDOM_CREATURE:
			_spawn_creature(deposit, ctx, parent)
		_:
			_spawn_primitive_fallback(deposit, ctx, parent)


# Flower kingdom — wraps commons/flora/BotanicalFlower. Anatomically-
# correct Swedish-plant generator with stem, leaves, phyllotaxis,
# inflorescence, petals. Three presets (bluebell / orchid / daisy)
# selected by intensity so a painted f1 produces a small bluebell and
# a painted f5 produces a full daisy. The flower scales by intensity
# too, so even within a preset the higher-intensity cells feel bigger.
func _spawn_flower(deposit: Dictionary, ctx: Dictionary,
		parent: Node3D) -> void:
	var strength: float = float(deposit.get("strength", 1.0))
	# Recover the original painted intensity (1-5) from the strength
	# (which is intensity / 5.0 — see BiomePaintTokens.parse).
	var intensity: int = clampi(int(round(strength * 5.0)), 1, 5)
	# Preset read from biome_config.json:flower_presets_by_intensity.
	var preset_name: String = BiomeConfigLoaderClass.get_flower_preset(intensity)
	if preset_name.is_empty():
		preset_name = "bluebell"

	var flower := BotanicalFlowerScene.instantiate()
	flower.preset = preset_name
	# Slight extra scale via configure() — gives intensity a continuous
	# influence on top of the discrete preset choice. Strength 0.2 → 0.7×,
	# strength 1.0 → 1.4×.
	flower.configure({
		"overall_scale": 0.7 + 0.7 * strength,
		"seed": int(deposit.get("x", 0)) * 31 + int(deposit.get("z", 0)),
	})
	flower.global_position = _cell_to_world(deposit, ctx)
	parent.add_child(flower)


# Fungus kingdom — wraps MoldNetwork (a CellularAutomata3D_Flexible
# scene). The CA rule "4-6/5-7/10/M" produces mycelial-network growth:
# cells survive with 4-6 neighbours, are born with 5-7, decay through
# 10 states, Moore neighbourhood. Visually reads as a fungal hyphae
# spreading.
#
# We downsize the default 30×30×30 grid because that's a 6m cube, way
# too big for one biome cell. Intensity scales the grid: u1 → 4³
# cluster, u5 → 12³ cluster. cell_size shrunk to 0.05m so even u5
# stays sub-meter.
func _spawn_fungus(deposit: Dictionary, ctx: Dictionary,
		parent: Node3D) -> void:
	var strength: float = float(deposit.get("strength", 1.0))
	var intensity: int = clampi(int(round(strength * 5.0)), 1, 5)
	# Grid grows with intensity. Even at u5 it's a 12³ × 0.05m = 0.6m
	# cluster — one biome cell.
	var dim: int = 4 + intensity * 2  # 6, 8, 10, 12, 14
	var mold := MoldNetworkScene.instantiate()
	mold.grid_size = Vector3i(dim, dim, dim)
	mold.cell_size = 0.05
	# Let the CA grow then freeze — biomes shouldn't churn forever.
	mold.max_generations = 30
	mold.global_position = _cell_to_world(deposit, ctx)
	parent.add_child(mold)


# Tree kingdom — wraps TreeMorphology.build (production DNA-driven
# L-system tree builder, 753 LOC). Constructs a tree-tuned CritterDNA
# from intensity + cell position, calls TreeMorphology with the
# shared trait mapper. The build returns a Node3D containing trunk,
# branches, leaves (MultiMesh-batched).
#
# DNA defaults are already tree-friendly (body_type=0). We tune:
#   - segments: branch depth — scales with intensity (3..7)
#   - scale:    overall size — scales with intensity (0.4..1.0)
#   - branch_angle: L-system rotation — varies with cell position so
#                   neighbouring trees don't look identical
#   - primary_color: bark — earth tones (brown/grey)
#   - secondary_color / tertiary_color: leaves — sequence-tinted green
#
# LOD scales with intensity too: t1 → lod 0 (3-sided tubes, ≤30
# branches), t5 → lod 2 (6-sided, ≤200 branches). Keeps low-intensity
# trees cheap.
func _spawn_tree(deposit: Dictionary, ctx: Dictionary,
		parent: Node3D) -> void:
	var strength: float = float(deposit.get("strength", 1.0))
	var intensity: int = clampi(int(round(strength * 5.0)), 1, 5)
	var x: int = int(deposit.get("x", 0))
	var z: int = int(deposit.get("z", 0))
	var seed: int = (x * 31 + z * 17) & 0xFFFF

	var dna: CritterDNA = CritterDNAClass.new()
	dna.body_type = 0.0  # Tree
	dna.segments = 2.0 + float(intensity)  # 3..7 levels of branching
	dna.scale = 0.4 + 0.15 * float(intensity)  # 0.55..1.0
	# Vary branch angle by position so neighbours don't look identical.
	dna.branch_angle = 18.0 + float(seed % 16)  # 18..33 degrees
	dna.branch_decay = 0.65 + 0.05 * (float(seed >> 4 & 7) / 7.0)
	dna.leaf_density = 0.4 + 0.15 * float(intensity)  # denser at high intensity
	# Earth-bark trunk + leaf-green crown.
	dna.primary_color = Color(0.32 + 0.05 * (seed & 3) * 0.1, 0.22, 0.12)
	dna.secondary_color = Color(0.14, 0.45 + 0.1 * float(intensity) / 5.0, 0.12)
	dna.tertiary_color = Color(0.20, 0.55, 0.15)
	dna.symmetry = 3.0 + float(seed % 3)  # 3..5 branch fans
	dna.roughness = 0.85
	dna.metallic = 0.0

	# Build under a small wrapper Node3D so we can position it.
	var tree_root := Node3D.new()
	tree_root.name = "PaintedTree_%d_%d" % [x, z]
	parent.add_child(tree_root)
	tree_root.global_position = _cell_to_world(deposit, ctx)

	var lod: int = clampi(intensity - 2, 0, 3)  # 0,0,1,2,3 for i=1..5
	TreeMorphologyClass.build(dna, tree_root, _get_trait_mapper(), lod)


# Creature kingdom — wraps CritterSpawner.spawn (production
# DNA-driven critter pipeline used by Pokemon Studio). Constructs a
# walker-tuned CritterDNA per cell, hands off to the cached spawner
# which builds the CritterEntity (mesh + shader + bond/age/breed
# lifecycle).
#
# Per-cell DNA tuning:
#   - body_type   = 1.0 (walker)
#   - segments    = 3 + intensity   (4..8 body parts)
#   - scale       = 0.3 + 0.12*intensity  (0.42..0.9 — smaller than trees)
#   - mobility    = 0.4 + 0.1*intensity   (more active at high intensity)
#   - sociality   = 0.5..0.9 by position  (mix of solitary + flock)
#   - aggression  = 0.05..0.20  (passive, reads as friendly)
#   - colors      = bright per-cell variation (creatures should pop)
func _spawn_creature(deposit: Dictionary, ctx: Dictionary,
		parent: Node3D) -> void:
	var strength: float = float(deposit.get("strength", 1.0))
	var intensity: int = clampi(int(round(strength * 5.0)), 1, 5)
	var x: int = int(deposit.get("x", 0))
	var z: int = int(deposit.get("z", 0))
	var seed: int = (x * 41 + z * 23) & 0xFFFF

	var dna: CritterDNA = CritterDNAClass.new()
	dna.body_type = 1.0  # walker
	dna.segments = 3.0 + float(intensity)
	dna.symmetry = 2.0 + float(seed % 4)  # 2..5
	dna.scale = 0.3 + 0.12 * float(intensity)
	dna.mobility = 0.4 + 0.1 * float(intensity)
	dna.aggression = 0.05 + 0.03 * float(seed & 7) / 7.0
	dna.sociality = 0.5 + 0.4 * (float(seed >> 4 & 7) / 7.0)
	dna.curiosity = 0.6
	# Bright per-cell creature colours — read against grass/biome.
	var hue_base: float = float(seed % 360) / 360.0
	dna.primary_color = Color.from_hsv(hue_base, 0.65, 0.85)
	dna.secondary_color = Color.from_hsv(fposmod(hue_base + 0.15, 1.0), 0.5, 0.7)
	dna.tertiary_color = Color.from_hsv(fposmod(hue_base + 0.45, 1.0), 0.7, 0.9)
	dna.iridescence = 0.1 + 0.1 * float(intensity) / 5.0
	dna.roughness = 0.5
	dna.metallic = 0.05

	var spawner: CritterSpawner = _get_critter_spawner(parent)
	spawner.spawn(dna, _cell_to_world(deposit, ctx))


# When no substrate dispatch is available (kingdom locked, table miss,
# or path not yet implemented), spawn a small kingdom-coloured cube at
# the cell position. Keeps the painted intent visible — every painted
# cell becomes SOMETHING in VR, even before per-kingdom upgrades land.
func _spawn_primitive_fallback(deposit: Dictionary, ctx: Dictionary,
		parent: Node3D) -> void:
	var kingdom: int = int(deposit.get("kingdom", -1))
	var strength: float = float(deposit.get("strength", 0.5))

	# Mesh: a small cube, scaled by intensity. Intensity 5 = full cube,
	# intensity 1 = 30% cube. Matches the editor's 2D paint overlay.
	var mesh_inst := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	var cube_size: float = float(ctx.get("cube_size", 1.0))
	var s: float = cube_size * 0.20 * (0.4 + 0.6 * strength)
	mesh.size = Vector3(s, s, s)
	mesh_inst.mesh = mesh

	var mat := StandardMaterial3D.new()
	# Color read from biome_config.json:kingdoms.<name>.color_rgb —
	# same hex as the encyclopedia's biome-paint.ts palette.
	var color: Color = BiomeConfigLoaderClass.get_kingdom_color(kingdom)
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.4 + 0.4 * strength
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	mesh_inst.material_override = mat

	mesh_inst.global_position = _cell_to_world(deposit, ctx)
	parent.add_child(mesh_inst)


# Convert a painted cell's (x, z) grid address into a world Vector3.
# Same math as floating_primitives.gd:33-35 — origin is grid_center,
# cells are cube_size apart, y sits one cube above the floor so the
# primitive perches on the cube top instead of clipping into it.
func _cell_to_world(deposit: Dictionary, ctx: Dictionary) -> Vector3:
	var grid_center: Vector3 = ctx.get("grid_center", Vector3.ZERO)
	var grid_dims: Vector3i = ctx.get("grid_dims", Vector3i(10, 1, 10))
	var cube_size: float = float(ctx.get("cube_size", 1.0))
	var x_cell: int = int(deposit.get("x", 0))
	var z_cell: int = int(deposit.get("z", 0))
	# Offset so cell (0,0) is at the grid's bottom-left corner, matching
	# the layered grid's origin convention.
	var wx: float = grid_center.x + (float(x_cell) - float(grid_dims.x) * 0.5 + 0.5) * cube_size
	var wz: float = grid_center.z + (float(z_cell) - float(grid_dims.z) * 0.5 + 0.5) * cube_size
	# Sit on top of the floor cube (height 1 = cube_size in world units).
	var wy: float = grid_center.y + cube_size * 0.6
	return Vector3(wx, wy, wz)
