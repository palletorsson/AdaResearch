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
const BotanicalFlowerScene = preload("res://commons/flora/botanical_flower.tscn")

# Per-kingdom substrate scenes / classes. The dispatcher matches on
# kingdom and forwards to one of these. Intensity influences the
# preset/config inside each substrate. Adding a new substrate = one
# preload, one branch in _spawn_for_kingdom.

# Intensity → BotanicalFlower preset. Maps the painted token's 1..5
# intensity to a flower variant: low intensity = small/delicate, high
# intensity = larger/showier. The presets are defined in
# commons/flora/botanical_flower.gd PRESETS const.
const FLOWER_PRESET_BY_INTENSITY := {
	1: "bluebell",
	2: "bluebell",
	3: "orchid",
	4: "daisy",
	5: "daisy",
}

# ── Constants ─────────────────────────────────────────────────────────────

const KINGDOM_TREE := 0
const KINGDOM_CREATURE := 1
const KINGDOM_FLOWER := 2
const KINGDOM_FUNGUS := 3

# Lowest spine sequence order at which each kingdom is allowed to render.
# Mirrors KINGDOM_UNLOCK_ORDER in the encyclopedia's foldBiome strategy.
# Painted cells for a locked kingdom fall back to primitive rendering.
const KINGDOM_UNLOCK_ORDER := {
	KINGDOM_FLOWER: 4,    # color sequence
	KINGDOM_TREE: 5,      # forces — first vertical primitives
	KINGDOM_FUNGUS: 7,    # randomness — RD requires randf()
	KINGDOM_CREATURE: 11, # lsystems — recognisable forms first appear
}

# Primitive fallback colors, one per kingdom. Picked to match the
# encyclopedia's KINGDOM_COLORS palette (rose / emerald / violet / amber).
# Used when a substrate dispatch is unavailable — preserves painted
# intent visually so the cell still reads as "flower here, tree there"
# even before the proper substrate lands.
const KINGDOM_COLOR := {
	KINGDOM_FLOWER:   Color(0.957, 0.247, 0.369),  # rose-500
	KINGDOM_TREE:     Color(0.063, 0.725, 0.506),  # emerald-500
	KINGDOM_FUNGUS:   Color(0.545, 0.361, 0.965),  # violet-500
	KINGDOM_CREATURE: Color(0.961, 0.620, 0.043),  # amber-500
}

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
	# breaking curriculum honesty.
	var unlock_at: int = int(KINGDOM_UNLOCK_ORDER.get(kingdom, 0))
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
	var preset_name: String = String(FLOWER_PRESET_BY_INTENSITY.get(intensity, "bluebell"))

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
	var color: Color = KINGDOM_COLOR.get(kingdom, Color.WHITE)
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
