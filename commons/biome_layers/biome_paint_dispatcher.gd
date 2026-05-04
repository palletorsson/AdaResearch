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
#   1. Walk the painted layer cell-by-cell.
#   2. For each deposit, look up (kingdom, stage_order) in the dispatch
#      table. The table answers: which substrate, with which gallery
#      config, at which tier?
#   3. Forward the deposit to that substrate's apply(ctx) — same
#      contract every other biome_layers/*.gd file uses.
#
# When fully populated, this replaces the placeholder primitive output of
# BiomeRingComponent with kingdom-correct, sequence-correct, gallery-
# rated rendering.
#
# Status 2026-05-04: SKELETON. Public surface stable, internals TODO.
# Tracks the audit's "Q5 Dispatch Table" (~50 explicit cells). Each cell
# resolved by:
#   - encyclopedia gallery manifest (config payload)
#   - per-substrate apply() implementation (already exist as siblings)
#   - kingdom unlock guard (curriculum honesty)

extends Node3D
class_name BiomePaintDispatcher

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

# ── Public API ────────────────────────────────────────────────────────────

# Standard biome layer contract. ctx must contain:
#   biome_paint: string[][]      — the painted layer
#   stage_order: int             — current sequence order
#   parent: Node3D               — where to add spawned content
#   grid_center, grid_dims, cube_size — spatial info (same as siblings)
func apply(ctx: Dictionary) -> void:
	var paint: Array = ctx.get("biome_paint", [])
	if paint.is_empty():
		return  # No paint, nothing to dispatch.

	var stage_order: int = int(ctx.get("stage_order", 0))
	var parent: Node3D = ctx.get("parent", self)

	# Iterate painted cells. The token parser exists at
	# algorithms/nature_system/systems/biome_paint_tokens.gd — reuse it.
	# TODO: var deposits := BiomePaintTokens.iter_painted_cells(paint)
	#       for deposit in deposits:
	#           _spawn_for_deposit(deposit, stage_order, ctx, parent)
	pass


# ── Internals (TODO) ──────────────────────────────────────────────────────

# Resolve a single painted deposit to a substrate spawn.
# deposit shape (per BiomePaintTokens):
#   { row: int, col: int, kingdom: int, intensity: int, sterile: bool }
func _spawn_for_deposit(_deposit: Dictionary, _stage_order: int,
		_ctx: Dictionary, _parent: Node3D) -> void:
	# TODO Step 3.a — kingdom unlock guard:
	#   if stage_order < KINGDOM_UNLOCK_ORDER[deposit.kingdom]:
	#       return _spawn_primitive_fallback(deposit, ctx, parent)
	#
	# TODO Step 3.b — substrate lookup:
	#   var entry := _lookup_dispatch(deposit.kingdom, stage_order)
	#   # entry := { gallery, entry_id, api, config_url }
	#
	# TODO Step 3.c — config fetch:
	#   var cfg := _fetch_config(entry.gallery, entry.entry_id)
	#
	# TODO Step 3.d — substrate dispatch:
	#   match entry.api:
	#       "PrimitiveStack.build":   PrimitiveStack.build(cfg)
	#       "LSystemSim":             LSystemSim.new().run(cfg)
	#       "MorphologySim.simulate": MorphologySim.simulate(cfg)
	#       "SoftBodySim.simulate":   SoftBodySim.new().simulate(cfg)
	#       "CritterSpawner.spawn":   CritterSpawner.spawn(cfg)
	#       "ReactionDiffusionSim":   ReactionDiffusionSim.simulate(cfg)
	#       _: _spawn_primitive_fallback(deposit, ctx, parent)
	#
	# TODO Step 3.e — place at cell position:
	#   var node := <result>
	#   node.global_position = _cell_to_world(deposit, ctx)
	#   parent.add_child(node)
	pass


# Lookup the (substrate, config, api) triple for a (kingdom, stage_order)
# pair. Cascade-back inheritance: if the exact cell isn't populated, walk
# backwards in stage_order until we find a populated one for that kingdom.
# TODO Step 3.f — read from biome_dispatch_table.json (sibling file).
func _lookup_dispatch(_kingdom: int, _stage_order: int) -> Dictionary:
	# Returns Dictionary with keys: gallery, entry_id, api, config_url
	# Empty dict means "no dispatch — use primitive fallback".
	return {}


# When no substrate is available (kingdom locked, or table miss), emit
# the same primitive output that floating_primitives.gd uses. Keeps the
# painted intent visible even at sterile-curriculum stages.
# TODO Step 3.g — call into floating_primitives directly with a small cfg.
func _spawn_primitive_fallback(_deposit: Dictionary, _ctx: Dictionary,
		_parent: Node3D) -> void:
	pass


# Convert a (row, col) cell address into a world Vector3 for placement.
# TODO Step 3.h — same math as the other biome_layers, factored out.
func _cell_to_world(_deposit: Dictionary, _ctx: Dictionary) -> Vector3:
	return Vector3.ZERO
