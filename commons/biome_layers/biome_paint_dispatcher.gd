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
# 3.g (primitive fallback), 3.h (cell-to-world) filled.
# Status 2026-07-17 (biome-2): 3.b–3.e substrate branches are LIVE
# (flower→BotanicalFlower, fungus→MoldNetwork CA, tree→TreeMorphology DNA,
# creature→CritterSpawner) and the dispatcher is now also the render path
# for the grid-native `layers.biome` (GridBiomeComponent → spawn_cell):
# one dispatch law, two authoring surfaces (painted + grid-declared).

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
# Shared tree/creature DNA recipe + tree build (consolidation Phase 1).
const SpawnService = preload("res://commons/biome_layers/spawn_service.gd")

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


# biome-2 (layers.biome): dispatch ONE grid-declared cell. GridBiomeComponent
# builds the deposit (kingdom already mapped to the painted ids, world_pos
# computed against real structure heights) and the honesty guard + substrate
# match run exactly as for painted cells.
func spawn_cell(deposit: Dictionary, stage_order: int, ctx: Dictionary,
		parent: Node3D) -> void:
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

	# Scale params from biome_config.json:intensity_scaling.flower —
	# tunable from /biome-control. Defaults Alice-scale.
	var s := BiomeConfigLoaderClass.get_intensity_scaling("flower")
	var scale_base: float = float(s.get("overall_scale_base", 1.5))
	var scale_per: float = float(s.get("overall_scale_per_intensity", 0.20))
	var overall_scale: float = scale_base + scale_per * float(intensity)

	var flower := BotanicalFlowerScene.instantiate()
	flower.preset = preset_name
	flower.configure({
		"overall_scale": overall_scale,
		"seed": int(deposit.get("x", 0)) * 31 + int(deposit.get("z", 0)),
	})
	# add_child BEFORE setting global_position — global_position on a node
	# not yet in the tree fails ("!is_inside_tree()") and silently places
	# it at origin. (Pre-existing bug, found during the consolidation.)
	parent.add_child(flower)
	flower.global_position = _cell_to_world(deposit, ctx)


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
	# Scale params from biome_config.json:intensity_scaling.fungus —
	# Alice-scale defaults: u5 ≈ 2m mycelium cluster.
	var s := BiomeConfigLoaderClass.get_intensity_scaling("fungus")
	var dim_base: int = int(s.get("grid_dim_base", 6))
	var dim_per: int = int(s.get("grid_dim_per_intensity", 3))
	var cell_size: float = float(s.get("cell_size", 0.10))
	var dim: int = dim_base + intensity * dim_per
	var cx: int = int(deposit.get("x", 0))
	var cz: int = int(deposit.get("z", 0))
	# Mycelial read: mould spreads FLAT and wide along the ground, not as a
	# ball. A low grid (thin Y, full X/Z) + centre seed grows a network mat
	# outward from a point. Thin enough to read as filaments, deep enough that
	# the survive(4-6)/born(5-7) rule still sustains — floor the height at 4.
	var flat_y: int = maxi(4, int(round(float(dim) / 3.0)))
	# Generation FREEZE (rule-search finding, Biome_GenSearch): the default rule
	# reads most mycelial at the SPREADING-FRONT phase (~gen 12-20 — a network
	# ring with a hollow centre), not the filled (gen 26+) or collapsed (gen 34+)
	# state the config's 30 left to capture timing. Freeze in that band, scaled
	# by intensity, with a per-cell jitter so neighbouring colonies differ (the
	# centre seed is deterministic — same gen would clone them).
	var net_gen: int = 13 + intensity + ((cx * 7 + cz * 13) % 5)   # ~14..22

	var mold := MoldNetworkScene.instantiate()
	mold.grid_size = Vector3i(dim, flat_y, dim)
	mold.cell_size = cell_size
	mold.max_generations = net_gen
	mold.center_seed_on_start = true  # a colony that spreads from one point
	# per-cell CA rule override (mods `rule=`); else the scene's mould default.
	var rule: String = String(deposit.get("rule", ""))
	if not rule.is_empty():
		mold.rule_string = rule
	# per-cell generation freeze (mods `gen=`): fewer generations = the thin
	# spreading front, more = the filled colony. Overrides the config default.
	var gen: String = String(deposit.get("gen", ""))
	if gen.is_valid_int():
		mold.max_generations = maxi(1, int(gen))
	# Tint to the fungus kingdom's color so CA clusters read as fungus,
	# not generic white. Pulled from biome_config.json:kingdoms.fungus.
	mold.color_alive = BiomeConfigLoaderClass.get_kingdom_color(KINGDOM_FUNGUS)
	mold.use_gradient = false  # solid kingdom-color is more legible at biome scale
	# add_child before global_position (see _spawn_flower note).
	parent.add_child(mold)
	mold.global_position = _cell_to_world(deposit, ctx)


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

	# Scale params from biome_config.json:intensity_scaling.tree.
	var s := BiomeConfigLoaderClass.get_intensity_scaling("tree")
	var seg_base: float = float(s.get("segments_base", 2.0))
	var seg_per: float = float(s.get("segments_per_intensity", 1.0))
	var scale_base: float = float(s.get("scale_base", 0.8))
	var scale_per: float = float(s.get("scale_per_intensity", 0.30))
	var leaf_base: float = float(s.get("leaf_density_base", 0.4))
	var leaf_per: float = float(s.get("leaf_density_per_intensity", 0.03))
	var ang_base: float = float(s.get("branch_angle_base", 18.0))
	var ang_jit: float = float(s.get("branch_angle_jitter", 16.0))

	# Shared tree-3 recipe (constants: branch_decay, primary/tertiary
	# colour, symmetry, roughness, metallic); override the intensity-
	# scaled fields from biome_config:intensity_scaling.tree.
	var dna: CritterDNA = SpawnService.tree_dna_from_seed(seed)
	dna.segments = seg_base + seg_per * float(intensity)
	dna.scale = scale_base + scale_per * float(intensity)
	dna.branch_angle = ang_base + float(seed % int(max(ang_jit, 1.0)))
	dna.leaf_density = leaf_base + leaf_per * float(intensity)
	dna.secondary_color = Color(0.14, 0.45 + 0.1 * float(intensity) / 5.0, 0.12)

	var lod: int = clampi(intensity - 2, 0, 3)  # 0,0,1,2,3 for i=1..5
	SpawnService.build_tree(dna, parent, _get_trait_mapper(), lod,
		"PaintedTree_%d_%d" % [x, z], _cell_to_world(deposit, ctx))


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

	# Mobility from biome_config.json:intensity_scaling.creature.
	var s := BiomeConfigLoaderClass.get_intensity_scaling("creature")
	var mob_base: float = float(s.get("mobility_base", 0.4))
	var mob_per: float = float(s.get("mobility_per_intensity", 0.1))

	# Shared walker recipe (symmetry, temperament, HSV colours, finish). We take
	# control of the four GEOMETRY genes so a cell's creature reads as a small
	# compact grub, not the multi-metre thread the raw seed DNA produces:
	#   body_length = part_length * scale * 0.5 * segments  (was ~15 m, off-cell)
	#   max_radius  = part_width  * scale * 0.12            (was thread-thin)
	# Temperament / colour / mobility stay from the shared recipe + config. This
	# is the biome dispatch only — Pokemon Studio spawns from its own DNA.
	var dna: CritterDNA = SpawnService.creature_dna_from_seed(seed)
	dna.segments = 3.0 + 0.5 * float(intensity)      # 3.5..5.5 body rings
	dna.scale = 0.55 + 0.07 * float(intensity)        # 0.62..0.9
	dna.part_length = 0.30 + 0.03 * float(intensity)  # short — stays in its cell
	dna.part_width = 0.85 + 0.03 * float(intensity)   # chunky, not thread-thin
	dna.mobility = mob_base + mob_per * float(intensity)
	dna.iridescence = 0.1 + 0.1 * float(intensity) / 5.0

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

	# add_child BEFORE global_position (same fix as _spawn_flower — setting
	# global_position off-tree fails and lands the cube at origin).
	parent.add_child(mesh_inst)
	mesh_inst.global_position = _cell_to_world(deposit, ctx)


# Convert a painted cell's (x, z) grid address into a world Vector3.
# Same math as floating_primitives.gd:33-35 — origin is grid_center,
# cells are cube_size apart, y sits one cube above the floor so the
# primitive perches on the cube top instead of clipping into it.
func _cell_to_world(deposit: Dictionary, ctx: Dictionary) -> Vector3:
	# Grid-native deposits (layers.biome) carry their exact world position,
	# computed against real per-cell structure heights — which the painted
	# path's flat-floor math below cannot know.
	if deposit.has("world_pos"):
		return deposit["world_pos"]
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
