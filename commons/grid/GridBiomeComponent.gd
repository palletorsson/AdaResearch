# GridBiomeComponent.gd — the living layer as part of the grid (additive).
#
# doc/plans/biome_grid_redesign.md. Reads the optional `layers.biome` grid
# (BiomeGridTokens grammar: kingdom:algo:role:mods:on=trigger:response),
# holds DECLARED state (from the map file, never mutated) and RUNTIME state
# (what play does — catalyst reactions, CA claims), and stages the cells.
#
# Discipline (walls-layer precedent):
#   - Maps WITHOUT layers.biome never construct any of this (GridSystem gates).
#   - Never touches structure or walkability; the pathfinder is unaffected.
#   - Rendering (biome-2): seed/halo cells whose kingdom maps to a painted-
#     layer kingdom route through BiomePaintDispatcher.spawn_cell — the SAME
#     honesty guard + substrate ladder as painted cells (one dispatch law,
#     two authoring surfaces). Kingdoms without a substrate (mineral/water/
#     meta) keep the pilot marker.
#   - Perf gate (biome-6): halo strips, ground-cover and pilot markers BATCH
#     into one MultiMesh per (kind, kingdom, recipe) across the whole map —
#     node count is O(kingdoms), not O(cells). Per-cell RNG streams are
#     unchanged, so the geometry is identical to the per-cell path. A map
#     may bound the layer via `layers.biome._meta` (dict form {_meta, rows}):
#     budget_instances caps total batched instances (deterministic stride
#     thinning, honestly printed), visibility_range sets GPU-side culling
#     distance (the ChunkManager discipline; its organism LOD machinery
#     cannot apply here — halo cover is identical geometry, the MultiMesh
#     case ChunkManager explicitly is not). Runtime claims after the flush
#     fall back to single spawns (few, honest).
#   - Halo (biome-3): a halo cell on the grid boundary spills wilderness
#     OUTWARD — a ground strip + kingdom ground-cover thinning into the dark.
#     This is the old BiomeRingComponent reborn as a per-cell role; a map
#     that declares halo cells retires the ground_ring accrual layer (data-
#     gated in GridSystem). No collider — the halo is scenery, walkability
#     untouched, and the un-celled space beyond stays unclaimed (sieve Q3).
#
# Reactivity (biome-7 — the addendum wired into play):
#   react(col, row, trigger) applies the cell's matching responses to the
#   RUNTIME copy only: seed / step (generation counter) / claim (expand into
#   adjacent `field` cells) / mute / unmute / mutate:<channel>. Play never
#   rewrites the map file. Sources now CALL it:
#     - catalyst: every CatalystProjectile impact and every biome-brush stamp
#       fires react_at_world(pos, "catalyst.<mode id>") — mode ids are the
#       real ones from becoming_catalyst.MODES (chromatic, fractal,
#       branching, ...), found via the "biome_grid" group (joined only by
#       maps that declared the layer — the additive gate).
#     - touch / dwell / tick: a clock in _process, enabled ONLY when some
#       declared cell asks for one of these triggers. touch = the camera
#       (the body's honest proxy, ProximityLOD's pattern) entering a cell;
#       dwell = staying DWELL_SECONDS on it (fires once per visit); tick =
#       every TICK_SECONDS on every tick-reactive cell. Headless runs have
#       no camera: touch/dwell never fire; tick still does.
#     - friend.<power>: a settled FRIEND creature (catalyst_foe) fires its
#       lineage power slug (CatalystCapabilityManager FRIEND_POWERS:
#       neutralizer, bridger, shield, ...) once per cell it enters — the
#       catalyst thread's "friend powers need in-world effects" landing as
#       grid reactions (neutralizer quiets biome = mute; bridger's tendril
#       = a claimed row). Declared "friend" matches any typed power.
# Presence (2026-07-21 — "make the shader responsive to non-moving life"):
#   every ACTIVE, UNMUTED cell (seed / halo / claimed field / reaction-opened
#   vacuum) stamps a kingdom-tinted influence into a small presence texture
#   (one texel per cell, radial falloff — the dormant PresenceGrid's idea,
#   grid-native). biome_presence.gdshader draws it as a breathing ground
#   stain on ONE batched MultiMesh of per-cell quads seated on real heights.
#   Rebuilt on every state-changing reaction, so a CA claim visibly spreads
#   its ground. Muted cells contribute NOTHING — the vacuum stays dry.
#   Opt-out: layers.biome._meta.presence = false.
#
#   Responses with teeth: `seed` now STAGES a newly-active unmuted cell
#   (through the same dispatcher honesty guard — the vacuum that can be
#   opened renders when opened); `mutate:<channel>` routes into the mutator
#   stack (GridMutatorBase family: color / visibility|hide / transform|
#   rotate|lift / glyph / part) as one advance_to_next_pattern() call —
#   unrouted channels are counted and said out loud, never silent.
#   _meta knobs: tick_seconds (default 5), dwell_seconds (default 2.5).

extends Node3D

const BiomeGridTokensScript = preload("res://commons/grid/BiomeGridTokens.gd")

const KINGDOM_COLORS: Dictionary = {
	"flora": Color(0.35, 0.75, 0.35),
	"fungus": Color(0.65, 0.45, 0.8),
	"fauna": Color(0.9, 0.6, 0.3),
	"mineral": Color(0.6, 0.6, 0.65),
	"water": Color(0.35, 0.55, 0.85),
	"meta": Color(0.9, 0.9, 0.9),
	"": Color(0.2, 0.2, 0.2),
}

var _grid_system: Node3D = null
var _cube_size: float = 1.0
var _gutter: float = 0.0
var _stage_order: int = 0        # feeds the dispatcher's curriculum-honesty guard
var _dispatcher: Node3D = null   # lazy — maps whose kingdoms never map stay dispatcher-free
var _declared: Dictionary = {}   # "col,row" -> parsed cell (immutable after generate)
var _runtime: Dictionary = {}    # "col,row" -> {active, muted, generation, claimed_by}
var _structure: Array = []
var _stats: Dictionary = {"cells": 0, "seeds": 0, "fields": 0, "mutes": 0, "halos": 0, "invalid": 0, "reactive": 0}
var _routed: int = 0             # cells sent through the dispatcher
var _marker_only: int = 0        # cells kept on the pilot marker (no substrate kingdom)
var _halo_cells: int = 0         # boundary halo cells that spilled wilderness
var _halo_instances: int = 0     # total halo ground-cover instances
var _grid_rows: int = 0
var _grid_cols: int = 0

# ── biome-6: batched rendering + per-map budget ──
const DEFAULT_BUDGET_INSTANCES: int = 4000
const DEFAULT_VISIBILITY_RANGE: float = 60.0
var _budget_instances: int = DEFAULT_BUDGET_INSTANCES
var _visibility_range: float = DEFAULT_VISIBILITY_RANGE
# chunk_lod (opt-in via layers.biome._meta.chunk_lod): route the SEED organisms
# (dispatcher-built trees/mushrooms/creatures — the individual, unbatched nodes)
# into a ChunkManager in adoption mode, so they get the ecosystem's LOD machinery
# (mesh-merge draw-call reduction + camera-distance visibility ranges + a far
# process-freeze). Off by default → seeds spawn exactly as before, untouched.
var _chunk_lod: bool = false
var _chunk_mgr = null  # lazy adopt-only ChunkManager (loaded, not class_name)
# living_ground (opt-in via layers.biome._meta.living_ground): the declared layer
# feeds the project's REAL ecology loop instead of only a static stamp —
# PresenceGrid (a pheromone field with decay + diffusion) seeded from the
# declared cells, and GroundSpawner (presence accumulates → fertile ground grows
# NEW organisms). The loop existed but was switched off wholesale in
# NatureRenderer ("should_be_active = false") because its living-ground PLANE
# rendered black in VR — a visual-overlay bug, not a simulation bug. Here the
# simulation is revived WITHOUT that plane: the biome already draws its own
# presence stain, which works.
var _living_ground: bool = false
var _presence_sim = null      # PresenceGrid — the live diffusing field
var _ground_spawner = null    # GroundSpawner — spontaneous growth from fertility
var _ground_holder: Node3D = null
var _ground_pop: int = 12     # _meta.living_ground_population
var _ground_marks: Array = [] # standing life re-marks the ground each tick
var _ground_mark_accum: float = 0.0
# build_budget (opt-in via layers.biome._meta.build_budget): organisms per frame.
# 0 = build everything synchronously in generate() (the default — unchanged).
var _build_budget: int = 0
var _build_queue: Array = []
var _batches: Dictionary = {}    # key -> {mesh, mat, transforms: Array}
var _recipe_cache: Dictionary = {}  # kingdom -> cached recipe array (shared meshes)
var _flushed: bool = false       # after flush, late (runtime) spawns go direct

# ── biome-7: the clock (touch / dwell / tick) + mutate routing ──
const DEFAULT_TICK_SECONDS: float = 5.0
const DEFAULT_DWELL_SECONDS: float = 2.5
var _tick_seconds: float = DEFAULT_TICK_SECONDS
var _dwell_seconds: float = DEFAULT_DWELL_SECONDS
var _tick_accum: float = 0.0
var _tick_keys: Array = []           # "col,row" of cells with a tick trigger
var _occupied: Vector2i = Vector2i(-9999, -9999)
var _dwell_accum: float = 0.0
var _dwell_fired: bool = false
var _mutators: Array = []            # cached GridMutatorBase nodes (lazy)
var _mutators_scanned: bool = false

# ── presence: the ground answers the standing life ──
const PRESENCE_RADIUS: float = 2.4   # influence radius in cells
const PRESENCE_MIN_A: float = 0.03   # below this, no quad
var _presence_enabled: bool = true
var _presence_img: Image = null
var _presence_tex: ImageTexture = null
var _presence_mmi: MultiMeshInstance3D = null


func initialize(grid_sys: Node3D, cube_size: float, gutter: float) -> void:
	_grid_system = grid_sys
	_cube_size = cube_size
	_gutter = gutter
	# biome-7: only maps that reach initialize (declared layer) join the group,
	# so catalyst wiring finds the component exactly when there is one to find.
	add_to_group("biome_grid")
	set_process(false)  # the clock switches on in generate() only if asked for


func generate(biome_layer: Array, structure_layer: Array, stage_order: int = 0, meta: Dictionary = {}) -> void:
	_structure = structure_layer
	# stage_order normally comes from the live EcosystemManager (the running
	# sequence). A gate/test map has no sequence context, so it defaults to 0 and
	# every kingdom would fall back to a primitive cube — a probe map for the
	# fungus/creature substrates could never SHOW them. A map may pin the stage it
	# wants to be read at via `_meta.stage_order`; absent the key nothing changes,
	# so real sequence maps are untouched (additive, gated by new data).
	_stage_order = int(meta.get("stage_order", stage_order))
	_budget_instances = int(meta.get("budget_instances", DEFAULT_BUDGET_INSTANCES))
	_visibility_range = float(meta.get("visibility_range", DEFAULT_VISIBILITY_RANGE))
	_tick_seconds = maxf(0.1, float(meta.get("tick_seconds", DEFAULT_TICK_SECONDS)))
	_dwell_seconds = maxf(0.1, float(meta.get("dwell_seconds", DEFAULT_DWELL_SECONDS)))
	_presence_enabled = bool(meta.get("presence", true))
	_chunk_lod = bool(meta.get("chunk_lod", false))
	_living_ground = bool(meta.get("living_ground", false))
	_ground_pop = int(meta.get("living_ground_population", 12))
	_build_budget = maxi(0, int(meta.get("build_budget", 0)))
	_build_queue.clear()
	var needs_clock: bool = false
	_grid_rows = _structure.size()
	_grid_cols = 0
	for r in _structure:
		if r is Array:
			_grid_cols = maxi(_grid_cols, (r as Array).size())
	for row in range(biome_layer.size()):
		var cells: Variant = biome_layer[row]
		if not (cells is Array):
			continue
		for col in range(cells.size()):
			var parsed: Dictionary = BiomeGridTokensScript.parse(cells[col])
			if parsed["empty"]:
				continue
			var key: String = "%d,%d" % [col, row]
			_stats["cells"] += 1
			if not parsed["valid"]:
				_stats["invalid"] += 1
				continue
			_declared[key] = parsed
			_runtime[key] = {
				# seeds AND halos live from load (both render); fields wake on claim
				"active": parsed["role"] == "seed" or parsed["role"] == "halo",
				"muted": parsed["role"] == "mute",
				"generation": 0,
				"claimed_by": "",
			}
			match parsed["role"]:
				"seed": _stats["seeds"] += 1
				"field": _stats["fields"] += 1
				"mute": _stats["mutes"] += 1
				"halo": _stats["halos"] += 1
			if not (parsed["reactions"] as Array).is_empty():
				_stats["reactive"] += 1
				for reaction in parsed["reactions"]:
					var trig: String = String(reaction["trigger"])
					if trig == "tick":
						_tick_keys.append(key)
						needs_clock = true
					elif trig == "touch" or trig == "dwell":
						needs_clock = true
			if parsed["role"] == "seed":
				_stage_cell(col, row, parsed)
			elif parsed["role"] == "halo":
				_spawn_halo(col, row, parsed)
	_flush_batches()
	_refresh_presence()
	if _living_ground:
		_start_living_ground()
		needs_clock = true  # the loop needs the per-frame tick
	if not _build_queue.is_empty():
		needs_clock = true  # the queue drains on the same clock
		print("GridBiomeComponent: %d organisms queued, %d/frame (deferred build)" % [
			_build_queue.size(), _build_budget])
	if needs_clock:
		set_process(true)
		print("GridBiomeComponent: clock ON (tick %.1fs, dwell %.1fs, %d tick cells)" % [
			_tick_seconds, _dwell_seconds, _tick_keys.size()])
	print("GridBiomeComponent: %d biome cells (%d seeds, %d fields, %d mutes, %d halos, %d reactive, %d invalid)" % [
		_stats["cells"], _stats["seeds"], _stats["fields"], _stats["mutes"],
		_stats["halos"], _stats["reactive"], _stats["invalid"]])
	if _routed > 0 or _marker_only > 0:
		print("GridBiomeComponent: routed %d cells -> BiomePaintDispatcher (stage_order %d), %d marker-only" % [
			_routed, _stage_order, _marker_only])
	if _halo_cells > 0:
		print("GridBiomeComponent: halo spill from %d cells -> %d ground-cover instances (grid-native ring)" % [
			_halo_cells, _halo_instances])


# ── living_ground: the declared layer feeds the real ecology loop ──
#
# PresenceGrid is a pheromone field (R=tree, G=creature, B=flower, A=fungus)
# that decays and diffuses every tick; GroundSpawner watches it and grows NEW
# organisms where presence crosses `spawn_threshold`. Seeding it from the
# declared cells makes the biome's own vocabulary the ecology's input: a mat of
# `fungus:mycelium:seed` cells becomes fertile fungus ground, and the ground
# answers by growing more — the `field`/`claim` grammar, but emergent.
#
# NOTE the kingdom ints line up already: BiomeGridTokens.dispatch_kingdom_of
# returns the painted-layer ids (tree 0, creature 1, flower 2, fungus 3), which
# is exactly PresenceGrid's channel order. No remap.
#
# CURRICULUM HONESTY is enforced through the DATA: only kingdoms unlocked at
# this map's stage_order are ever deposited, so GroundSpawner — which can only
# grow what the field carries — can never grow a creature on a sequence-2 map.
func _start_living_ground() -> void:
	var PresenceGridScript = load("res://algorithms/nature_system/systems/presence_grid.gd")
	var GroundSpawnerScript = load("res://algorithms/nature_system/systems/ground_spawner.gd")
	var ConfigLoader = load("res://commons/biome_layers/biome_config_loader.gd")
	if PresenceGridScript == null or GroundSpawnerScript == null:
		push_warning("GridBiomeComponent: living_ground requested but the ecology scripts are missing")
		return
	var step: float = _cube_size + _gutter
	var span_x: float = maxf(float(_grid_cols) * step, 1.0)
	var span_z: float = maxf(float(_grid_rows) * step, 1.0)
	var span: float = maxf(span_x, span_z)
	# Resolution follows PresenceGrid's OWN tuned spatial scale (its defaults are
	# 128 texels over 50m ≈ 2.6 texels/metre). Sizing a small grid map at a fixed
	# 96 gave 6cm texels — 6x finer — and diffusion, which spreads one texel per
	# tick, then crawls and never reaches the next cell. Keep the metres-per-texel
	# constant instead, so the field diffuses at cell scale on any map size.
	var res: int = clampi(roundi(span * 2.6), 16, 128)
	_presence_sim = PresenceGridScript.new(res, Vector2(span, span))
	# PresenceGrid centres its field on world_offset; the grid's own centre is
	# ((cols-1)/2*step, (rows-1)/2*step) in local space, mapped to world.
	var centre_local := Vector3((float(_grid_cols) - 1.0) * step * 0.5, 0.0,
		(float(_grid_rows) - 1.0) * step * 0.5)
	var centre: Vector3 = to_global(centre_local) if is_inside_tree() else centre_local
	_presence_sim.world_offset = Vector2(centre.x, centre.z)

	# seed the field from the declared cells (unlocked kingdoms only). The list is
	# KEPT: PresenceGrid decays (0.98/tick), so a one-shot seed would fade below
	# GroundSpawner's fertility threshold in seconds and nothing could ever grow.
	# Standing organisms keep marking the ground — so the cells re-deposit a
	# maintenance dose every tick, and decay erases only where nothing stands.
	_ground_marks.clear()
	var seeded: int = 0
	for key in _runtime.keys():
		var state: Dictionary = _runtime[key]
		if bool(state.get("muted", false)) or not bool(state.get("active", true)):
			continue
		# state carries live/muted; the DECLARED cell carries kingdom/algo/mods
		if not _declared.has(key):
			continue
		var cell: Dictionary = _declared[key]
		var kid: int = BiomeGridTokensScript.dispatch_kingdom_of(cell)
		if kid < 0:
			continue  # mineral / water / meta carry no ecology channel
		if ConfigLoader != null and _stage_order < int(ConfigLoader.get_unlock_order(kid)):
			continue  # curriculum guard — an unwalked kingdom never becomes fertile
		var parts: PackedStringArray = String(key).split(",")
		if parts.size() < 2:
			continue
		var col: int = int(parts[0])
		var row: int = int(parts[1])
		var local := Vector3(col * step, _surface_y(col, row), row * step)
		var wpos: Vector3 = to_global(local) if is_inside_tree() else local
		var tier: int = BiomeGridTokensScript.tier_of(cell)
		var strength: float = clampf(BiomeGridTokensScript.density_of(cell) * (0.35 + 0.13 * float(tier)), 0.05, 1.0)
		_presence_sim.deposit(wpos, kid, strength, step * 1.2)
		_ground_marks.append({"pos": wpos, "kid": kid, "strength": strength, "radius": step * 1.2})
		seeded += 1

	# the grower: fertile ground raises new organisms, bounded and parented here
	_ground_holder = Node3D.new()
	_ground_holder.name = "BiomeGroundGrown"
	add_child(_ground_holder)
	_ground_spawner = GroundSpawnerScript.new()
	_ground_spawner.presence = _presence_sim
	_ground_spawner.terrain_size = span
	_ground_spawner.max_ground_population = _ground_pop
	_ground_spawner.spawner = CritterSpawner.new(_ground_holder)
	_ground_spawner.spawner.max_population = _ground_pop
	print("GridBiomeComponent: living_ground ON — PresenceGrid seeded from %d cells (span %.1fm), GroundSpawner cap %d" % [
		seeded, span, _ground_pop])


# Tick the ecology. The FIELD always diffuses (deterministic, allocates nothing
# new). GROWTH additionally requires a camera — the body's honest proxy, the
# same rule ProximityLOD and chunk_lod use — so headless captures stay stable
# and the ground only answers a witness.
func _tick_living_ground(delta: float) -> void:
	if _presence_sim == null:
		return
	# standing life keeps marking its ground (the maintenance dose above)
	_ground_mark_accum += delta
	if _ground_mark_accum >= 0.5:
		_ground_mark_accum = 0.0
		for m in _ground_marks:
			_presence_sim.deposit(m["pos"], int(m["kid"]), float(m["strength"]) * 0.5, float(m["radius"]))
	_presence_sim.process(delta)
	if _ground_spawner == null:
		return
	if get_viewport() == null or get_viewport().get_camera_3d() == null:
		return
	_ground_spawner.process(delta)


## Live pheromone reading at a world position (test / telemetry).
func living_ground_presence(world_pos: Vector3) -> float:
	if _presence_sim == null:
		return 0.0
	return float(_presence_sim.get_total_presence(world_pos))


## Count of organisms the ground has grown on its own (test / telemetry).
func living_ground_grown() -> int:
	if _ground_spawner == null:
		return 0
	return int(_ground_spawner.get_ground_spawned_count())


# ── reactivity (runtime only; the map file is never rewritten) ──

func react(col: int, row: int, trigger: String) -> Array:
	var key: String = "%d,%d" % [col, row]
	if not _declared.has(key):
		return []
	var applied: Array = []
	var cell: Dictionary = _declared[key]
	for reaction in cell["reactions"]:
		if not _trigger_matches(reaction["trigger"], trigger):
			continue
		for response in reaction["responses"]:
			_apply_response(key, col, row, cell, String(response))
			applied.append(response)
	if not applied.is_empty():
		_stats["reactions_fired"] = int(_stats.get("reactions_fired", 0)) + 1
		# the ground answers: any state-changing response reshapes the stain,
		# so a claim visibly SPREADS its territory underfoot
		for r in applied:
			if String(r) in ["seed", "claim", "mute", "unmute"]:
				_refresh_presence()
				break
	return applied


# biome-7: the one entry point every play source shares — a world position
# (projectile impact, brush stamp, the walking body) mapped to its cell.
func react_at_world(world_pos: Vector3, trigger: String) -> Array:
	var cell: Vector2i = _world_to_cell(world_pos)
	return react(cell.x, cell.y, trigger)


# Public cell query for once-per-cell sources (friends, future walkers):
# lets a mover ask "which cell am I on" so it can gate its own re-fires.
func cell_at_world(world_pos: Vector3) -> Vector2i:
	return _world_to_cell(world_pos)


func _world_to_cell(world_pos: Vector3) -> Vector2i:
	var local: Vector3 = to_local(world_pos) if is_inside_tree() else world_pos
	var step: float = _cube_size + _gutter
	return Vector2i(roundi(local.x / step), roundi(local.z / step))


# ── biome-7: the clock. Runs ONLY on maps whose declared cells ask for
#    touch / dwell / tick (set_process gated in generate). The camera stands
#    in for the body (ProximityLOD's pattern); headless has none, so only
#    tick fires there. ──

func _process(delta: float) -> void:
	if not _build_queue.is_empty():
		_drain_build_queue()
	if _living_ground:
		_tick_living_ground(delta)
	_tick_accum += delta
	if _tick_accum >= _tick_seconds and not _tick_keys.is_empty():
		_tick_accum = 0.0
		for key in _tick_keys:
			var parts: PackedStringArray = String(key).split(",")
			react(int(parts[0]), int(parts[1]), "tick")
	var cam: Camera3D = get_viewport().get_camera_3d() if is_inside_tree() else null
	if cam == null:
		return
	var cell: Vector2i = _world_to_cell(cam.global_position)
	if cell != _occupied:
		_occupied = cell
		_dwell_accum = 0.0
		_dwell_fired = false
		react(cell.x, cell.y, "touch")
	else:
		_dwell_accum += delta
		if not _dwell_fired and _dwell_accum >= _dwell_seconds:
			_dwell_fired = true
			react(cell.x, cell.y, "dwell")


func _trigger_matches(declared: String, fired: String) -> bool:
	if declared == fired:
		return true
	# "catalyst" matches any typed "catalyst.<mode>"; "friend" any "friend.<power>"
	if declared == "catalyst" and fired.begins_with("catalyst."):
		return true
	return declared == "friend" and fired.begins_with("friend.")


func _apply_response(key: String, col: int, row: int, cell: Dictionary, response: String) -> void:
	var state: Dictionary = _runtime[key]
	match response:
		"seed":
			# biome-7: seeding a not-yet-active, unmuted cell now RENDERS it —
			# through the same dispatcher honesty guard as declared seeds.
			# Responses apply in declared order, so "unmute/seed" opens the
			# vacuum and then grows in it.
			var was_active: bool = bool(state["active"])
			state["active"] = true
			if not was_active and not bool(state["muted"]):
				_stage_cell(col, row, cell)
		"step":
			state["generation"] = int(state["generation"]) + 1
		"mute":
			state["muted"] = true
		"unmute":
			state["muted"] = false
		"claim":
			for offset in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var nkey: String = "%d,%d" % [col + offset.x, row + offset.y]
				if _declared.has(nkey) and _declared[nkey]["role"] == "field":
					var nstate: Dictionary = _runtime[nkey]
					if not bool(nstate["muted"]) and String(nstate["claimed_by"]).is_empty():
						nstate["claimed_by"] = key
						nstate["active"] = true
						# claimed growth renders as the CLAIMING seed's substrate —
						# and the honesty guard applies to triggered growth too.
						_stage_cell(col + offset.x, row + offset.y, cell)
		_:
			# biome-7: mutate.<channel> routes into the mutator stack. Dot is
			# the canonical token form (":" is the layer's token separator and
			# would shear the channel off in parse); direct react() callers
			# may still pass "mutate:<channel>".
			if response.begins_with("mutate"):
				var channel: String = response.substr(6)
				if channel.begins_with(".") or channel.begins_with(":"):
					channel = channel.substr(1)
				_route_mutate(channel.strip_edges())


# ── biome-7: mutate:<channel> → the mutator stack (GridMutatorBase family).
#    One reaction = one advance_to_next_pattern() on every mutator whose class
#    carries the channel. Unrouted channels are counted and printed once —
#    "routes nowhere" is now a fact the map states, not a silence. ──

const MUTATE_ALIASES: Dictionary = {
	"hide": "visibility", "show": "visibility",
	"rotate": "transform", "lift": "transform",
}
var _unrouted_warned: Dictionary = {}


func _route_mutate(channel: String) -> void:
	if not _mutators_scanned:
		_mutators_scanned = true
		# climb to the outermost ancestor rather than get_tree().root:
		# equivalent in play, and honest in probe contexts where nodes are
		# parented but not yet "inside the tree" (SceneTree _init).
		var scan_root: Node = self
		while scan_root.get_parent() != null:
			scan_root = scan_root.get_parent()
		_collect_mutators(scan_root)
		_stats["mutators_found"] = _mutators.size()
	var wanted: String = String(MUTATE_ALIASES.get(channel, channel)).to_lower()
	var routed: bool = false
	for m in _mutators:
		if not is_instance_valid(m):
			continue
		var s: Script = m.get_script()
		var cls: String = ""
		if s != null:
			cls = String(s.get_global_name()).to_lower()
			if cls.is_empty():
				cls = s.resource_path.get_file().get_basename().to_lower()
		if cls.contains(wanted) and m.has_method("advance_to_next_pattern"):
			m.advance_to_next_pattern()
			routed = true
	if routed:
		_stats["mutations_routed"] = int(_stats.get("mutations_routed", 0)) + 1
	else:
		_stats["mutations_unrouted"] = int(_stats.get("mutations_unrouted", 0)) + 1
		if not _unrouted_warned.has(channel):
			_unrouted_warned[channel] = true
			print("GridBiomeComponent: mutate:%s has no %s mutator in this scene (counted, not silent)" % [
				channel, wanted])


func _collect_mutators(node: Node) -> void:
	if node is GridMutatorBase:
		_mutators.append(node)
	for child in node.get_children():
		_collect_mutators(child)


# ── staging (biome-2): substrate via the dispatcher when the kingdom maps,
#    pilot marker otherwise ──

func _stage_cell(col: int, row: int, cell: Dictionary) -> void:
	var kid: int = BiomeGridTokensScript.dispatch_kingdom_of(cell)
	if kid < 0:
		_marker_only += 1
		# mineral / water / meta have no dispatcher substrate — but they are
		# not nothing. Give them a real procedural specimen (crystal / pool /
		# glyph) instead of a solid pilot cube. Few per map (seeds), so direct
		# spawn is fine; unknown kingdoms keep the box.
		var kingdom: String = String(cell["kingdom"])
		if kingdom in ["mineral", "water", "meta"]:
			_spawn_specimen(col, row, cell, kingdom)
		else:
			_spawn_marker(col, row, cell)
		return
	_routed += 1
	var step: float = _cube_size + _gutter
	var local: Vector3 = Vector3(
		col * step, _surface_y(col, row) + 0.02, row * step)
	var deposit: Dictionary = {
		"x": col, "z": row, "kingdom": kid,
		# tier (1..5) IS the painted intensity ladder; strength = intensity/5
		# per BiomePaintTokens. Density stays a per-cell field-fill knob.
		"strength": float(BiomeGridTokensScript.tier_of(cell)) / 5.0,
		"sterile": false,
		"raw": "%s:%s" % [cell["kingdom"], cell["algo"]],
		# exact world position against real structure heights — the painted
		# path's flat-floor _cell_to_world cannot know these.
		"world_pos": to_global(local) if is_inside_tree() else local,
		# the declared algo — the dispatcher branches on it within a kingdom
		# (fungus: `ca` = the voxel CA network, `mycelium` = filaments).
		"algo": String(cell["algo"]),
		# per-cell density (`d=`) — web fill for the mycelium substrate.
		"density": BiomeGridTokensScript.density_of(cell),
		# optional per-cell CA controls (fungus): `rule=` overrides the rule,
		# `gen=` the generation the CA freezes at (its thin spreading front).
		"rule": String((cell["mods"] as Dictionary).get("rule", "")),
		"gen": String((cell["mods"] as Dictionary).get("gen", "")),
		# fungus:dna — fd=<family> picks the curated mushroom family
		# (alien_lumen / button_dome / fairy_ring / parasol_tall / shelf_bracket)
		"fd": String((cell["mods"] as Dictionary).get("fd", "")),
		# fungus:softbody — sf=<pose family> (gravity_droop / inflate_bloat /
		# squash_settle / wilt_collapse / wind_lean)
		"sf": String((cell["mods"] as Dictionary).get("sf", "")),
	}
	# build_budget: a dense seed field builds SYNCHRONOUSLY inside generate() —
	# measured at ~210ms per organism, so 70 seeds froze the load for ~15s. With a
	# budget the deposits queue and drain N per frame, turning one long hang into
	# a world that grows in around the player. The deposit is fully resolved here,
	# so queueing changes nothing about WHAT gets built — only when.
	if _build_budget > 0:
		_build_queue.append(deposit)
		return
	_get_dispatcher().spawn_cell(deposit, _stage_order, {"cube_size": _cube_size}, self)


## Build every queued organism NOW (captures, probes, tools that need the whole
## map present before they measure or shoot). No-op when the queue is empty.
func flush_build_queue() -> int:
	var n: int = _build_queue.size()
	while not _build_queue.is_empty():
		_get_dispatcher().spawn_cell(_build_queue.pop_front(), _stage_order,
			{"cube_size": _cube_size}, self)
	return n


## Organisms still waiting to be built (test / telemetry).
func pending_builds() -> int:
	return _build_queue.size()


func _drain_build_queue() -> void:
	var n: int = 0
	while not _build_queue.is_empty() and n < _build_budget:
		_get_dispatcher().spawn_cell(_build_queue.pop_front(), _stage_order,
			{"cube_size": _cube_size}, self)
		n += 1
	if _build_queue.is_empty() and n > 0:
		print("GridBiomeComponent: build queue drained (budget %d/frame)" % _build_budget)


func _get_dispatcher() -> Node3D:
	if _dispatcher == null:
		# load (not preload / class_name): the dispatcher preloads heavy
		# substrate scenes — only maps that actually route pay for them.
		var DispatcherScript = load("res://commons/biome_layers/biome_paint_dispatcher.gd")
		_dispatcher = DispatcherScript.new()
		_dispatcher.name = "BiomeGridDispatcher"
		add_child(_dispatcher)
	return _dispatcher


# chunk_lod: adopt a dispatcher-built SEED organism into an adopt-only
# ChunkManager (mesh-merge + camera-distance visibility ranges + a far process-
# freeze). Gated on _meta.chunk_lod — a no-op, and no manager is ever created,
# otherwise, so maps without the flag are byte-identical. The dispatcher offers
# every newly-built organism; the gate lives HERE (one source of truth).
func adopt_biome_organism(node: Node3D) -> void:
	if not _chunk_lod or node == null or not is_instance_valid(node):
		return
	if _chunk_mgr == null or not is_instance_valid(_chunk_mgr):
		# load (not class_name): keep the ecosystem subsystem off the grid's
		# static dependency graph — only chunk_lod maps pay for it.
		var ChunkManagerScript = load("res://commons/managers/ChunkManager.gd")
		_chunk_mgr = ChunkManagerScript.new()
		_chunk_mgr.name = "BiomeChunkLOD"
		_chunk_mgr.adopt_only = true
		add_child(_chunk_mgr)
		print("GridBiomeComponent: chunk_lod ON — seed organisms adopt into BiomeChunkLOD (ChunkManager, adopt_only)")
	_chunk_mgr.adopt(node)


# ── halo (biome-3): the cell spills wilderness OUTWARD — the old ring,
#    reborn as a per-cell role. A ground strip plus kingdom ground-cover in
#    the band adjacent to this boundary cell, quadratically thinning into
#    the dark. Deterministic per cell (seeded RNG). No collider. Interior
#    halo cells keep the pilot marker so the declaration stays visible. ──

func _spawn_halo(col: int, row: int, cell: Dictionary) -> void:
	var dirs: Array = []
	if col == 0:
		dirs.append(Vector3(-1, 0, 0))
	if col == _grid_cols - 1:
		dirs.append(Vector3(1, 0, 0))
	if row == 0:
		dirs.append(Vector3(0, 0, -1))
	if row == _grid_rows - 1:
		dirs.append(Vector3(0, 0, 1))
	if dirs.is_empty():
		_marker_only += 1
		_spawn_marker(col, row, cell)
		return
	_halo_cells += 1
	var d: float = BiomeGridTokensScript.density_of(cell)
	var depth: float = lerpf(2.0, 6.0, d)  # like the ring: thin when sparse, wide when dense
	var surf_y: float = _surface_y(col, row)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = hash("halo:%d,%d" % [col, row])
	for dir in dirs:
		_spawn_halo_band(col, row, cell, dir, depth, surf_y, d, rng)


func _spawn_halo_band(col: int, row: int, cell: Dictionary, dir: Vector3,
		depth: float, surf_y: float, d: float, rng: RandomNumberGenerator) -> void:
	var step: float = _cube_size + _gutter
	var center: Vector3 = Vector3(col * step, 0.0, row * step)
	var band_center: Vector3 = center + dir * (step * 0.5 + depth * 0.5)
	var kingdom: String = String(cell["kingdom"])
	# ground strip — visual only, no collision: the void stays the void.
	# Batched (biome-6): a unit plane scaled per band, one node per kingdom.
	var strip_xf: Transform3D = Transform3D.IDENTITY
	var strip_scale: Vector3 = Vector3(depth, 1.0, step) if absf(dir.x) > 0.0 else Vector3(step, 1.0, depth)
	strip_xf = strip_xf.scaled(strip_scale)
	strip_xf.origin = Vector3(band_center.x, surf_y + 0.005, band_center.z)
	var kcolor: Color = KINGDOM_COLORS.get(kingdom, KINGDOM_COLORS[""])
	_batch_add("strip:" + kingdom, _unit_plane(), {
		"albedo": Color(0.16, 0.15, 0.13).lerp(kcolor, 0.15), "roughness": 0.9,
	}, strip_xf)
	# ground-cover: transforms per recipe, batched map-wide per (kingdom, recipe)
	var target: int = int(round(lerpf(10.0, 50.0, d)))
	for recipe in _halo_recipes(kingdom):
		var count: int = maxi(1, int(round(float(target) * float(recipe["fraction"]))))
		var added: int = 0
		for _i in count:
			var t_out: float = rng.randf()   # 0 = grid edge, 1 = outer rim
			if rng.randf() < t_out * t_out:  # quadratic thinning into the dark
				continue
			var along: float = (rng.randf() - 0.5) * step
			var outward: float = step * 0.5 + t_out * depth
			var pos: Vector3
			if absf(dir.x) > 0.0:
				pos = Vector3(center.x + dir.x * outward, surf_y, center.z + along)
			else:
				pos = Vector3(center.x + along, surf_y, center.z + dir.z * outward)
			var xf: Transform3D = Transform3D.IDENTITY
			xf = xf.rotated(Vector3.UP, rng.randf_range(0.0, TAU))
			var sc: float = rng.randf_range(0.7, 1.4)  # wider spread = varied heights
			xf = xf.scaled(Vector3(sc, sc, sc))
			# base sits ON the ground: lift by the recipe's own half-height
			xf.origin = pos + Vector3(0.0, float(recipe.get("y_off", 0.0)) * sc, 0.0)
			_batch_add("cover:%s:%s" % [kingdom, String(recipe["name"])], recipe["mesh"], {
				"albedo": recipe["color"], "cull_off": true,
				"emission": (recipe["color"] as Color) * float(recipe.get("emission_mul", 0.25)),
			}, xf)
			added += 1
		_halo_instances += added


# Ground-cover recipes per grammar kingdom — the halo's own look (grammar-
# native), sized to the ring's old VR budget (low-poly primitives).
# Cached per kingdom (biome-6): every cell of a kingdom shares ONE mesh per
# recipe, so the map-wide batches carry a single mesh each.
func _halo_recipes(kingdom: String) -> Array:
	if _recipe_cache.has(kingdom):
		return _recipe_cache[kingdom]
	var recipes: Array = _build_halo_recipes(kingdom)
	_recipe_cache[kingdom] = recipes
	return recipes


func _build_halo_recipes(kingdom: String) -> Array:
	# Each recipe is ONE self-contained mesh (batched scatter can't assemble
	# multi-part objects); y_off lifts its base onto the ground; emission_mul
	# overrides glow. Meshes stand at varied heights, not a uniform carpet.
	match kingdom:
		"flora":
			# a tapered blade (tall triangle) + a bright bloom on a point
			var blade: PrismMesh = PrismMesh.new()
			blade.size = Vector3(0.07, 0.45, 0.02)
			var bloom: SphereMesh = SphereMesh.new()
			bloom.radius = 0.055
			bloom.height = 0.11
			bloom.radial_segments = 6
			bloom.rings = 3
			return [
				{"name": "blade", "mesh": blade, "color": Color(0.3, 0.55, 0.2), "fraction": 0.75, "y_off": 0.225},
				{"name": "bloom", "mesh": bloom, "color": Color(0.95, 0.6, 0.5), "fraction": 0.25, "y_off": 0.16, "emission_mul": 0.45},
			]
		"fungus":
			# a low dome cap + a taller toadstool cone, both grounded
			var dome: SphereMesh = SphereMesh.new()
			dome.radius = 0.11
			dome.height = 0.14
			dome.radial_segments = 8
			dome.rings = 4
			var stalk: CylinderMesh = CylinderMesh.new()
			stalk.top_radius = 0.13
			stalk.bottom_radius = 0.02
			stalk.height = 0.24
			stalk.radial_segments = 7
			return [
				{"name": "cap", "mesh": dome, "color": Color(0.55, 0.38, 0.62), "fraction": 0.6, "y_off": 0.03, "emission_mul": 0.35},
				{"name": "toadstool", "mesh": stalk, "color": Color(0.7, 0.32, 0.42), "fraction": 0.4, "y_off": 0.12, "emission_mul": 0.3},
			]
		"fauna":
			# earthy burrow mounds + track-pebbles + a pale creature-sign (an egg).
			# Was dark-brown-on-dark and vanished into the strip; now warmer, lighter
			# earth for tonal contrast plus a pale emissive egg so the rim reads as
			# "a creature passed here" instead of a flat brown smear.
			var mound: SphereMesh = SphereMesh.new()
			mound.radius = 0.11
			mound.height = 0.1
			mound.radial_segments = 8
			mound.rings = 3
			var pebble: BoxMesh = BoxMesh.new()
			pebble.size = Vector3(0.06, 0.03, 0.09)
			var egg: SphereMesh = SphereMesh.new()
			egg.radius = 0.05
			egg.height = 0.13
			egg.radial_segments = 8
			egg.rings = 4
			return [
				{"name": "mound", "mesh": mound, "color": Color(0.47, 0.35, 0.23), "fraction": 0.45, "y_off": 0.0},
				{"name": "track", "mesh": pebble, "color": Color(0.4, 0.35, 0.29), "fraction": 0.35, "y_off": 0.015},
				{"name": "egg", "mesh": egg, "color": Color(0.79, 0.72, 0.55), "fraction": 0.2, "y_off": 0.06, "emission_mul": 0.25},
			]
		"mineral":
			# angular shards fanning up — faceted, not a rounded box
			var shard: PrismMesh = PrismMesh.new()
			shard.size = Vector3(0.1, 0.26, 0.1)
			return [{"name": "shard", "mesh": shard, "color": Color(0.6, 0.66, 0.82), "fraction": 1.0, "y_off": 0.13, "emission_mul": 0.4}]
		"water":
			# slender reeds + flat lily discs on the surface
			var reed: CylinderMesh = CylinderMesh.new()
			reed.top_radius = 0.007
			reed.bottom_radius = 0.014
			reed.height = 0.6
			reed.radial_segments = 4
			var lily: CylinderMesh = CylinderMesh.new()
			lily.top_radius = 0.09
			lily.bottom_radius = 0.09
			lily.height = 0.015
			return [
				{"name": "reed", "mesh": reed, "color": Color(0.32, 0.5, 0.42), "fraction": 0.6, "y_off": 0.3},
				{"name": "lily", "mesh": lily, "color": Color(0.24, 0.42, 0.32), "fraction": 0.4, "y_off": 0.01},
			]
		"meta":
			# floating emissive motes — small glowing points hovering in the ring
			var mote: SphereMesh = SphereMesh.new()
			mote.radius = 0.05
			mote.height = 0.1
			mote.radial_segments = 8
			mote.rings = 4
			return [{"name": "mote", "mesh": mote, "color": Color(0.7, 0.9, 1.0), "fraction": 1.0, "y_off": 0.3, "emission_mul": 2.2}]
		_:
			var tuft: QuadMesh = QuadMesh.new()
			tuft.size = Vector2(0.12, 0.3)
			tuft.center_offset = Vector3(0, 0.15, 0)
			return [{"name": "tuft", "mesh": tuft, "color": Color(0.35, 0.35, 0.3), "fraction": 1.0}]


# ── pilot rendering: one small kingdom-tinted marker per active cell.
#    Batched map-wide per kingdom (biome-6); a runtime claim arriving after
#    the flush (react → claim) spawns direct — few, and honestly counted. ──

# ── biome-visual (2026-07-19): real specimens for the substrate-less kingdoms.
#    mineral = a faceted crystal cluster; water = a still reflective pool with
#    ripple rings and reeds; meta = a hovering emissive glyph. Tier scales size.
#    Deterministic RNG per cell so the look is stable across runs. ──

func _spawn_specimen(col: int, row: int, cell: Dictionary, kingdom: String) -> void:
	var step: float = _cube_size + _gutter
	var surf_y: float = _surface_y(col, row)
	var base: Vector3 = Vector3(col * step, surf_y, row * step)
	var tier: int = BiomeGridTokensScript.tier_of(cell)
	var scale: float = 0.5 + 0.12 * float(tier)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = hash("specimen:%s:%d,%d" % [kingdom, col, row])
	var holder: Node3D = Node3D.new()
	holder.name = "BiomeSpecimen_%s_%d_%d" % [kingdom, col, row]
	holder.position = base
	add_child(holder)
	match kingdom:
		"mineral":
			_build_crystal(holder, scale, rng)
		"water":
			_build_pool(holder, scale, rng)
		"meta":
			_build_glyph(holder, scale, rng)


func _build_crystal(holder: Node3D, scale: float, rng: RandomNumberGenerator) -> void:
	# a cluster of elongated faceted prisms fanning up from a common base.
	# Bigger, more numerous and more spread than before (was 4-6 shards 0.09 wide
	# packed within +/-0.09 — they merged into one chip); now reads as a CLUSTER.
	scale *= 1.4
	var shards: int = rng.randi_range(6, 9)
	for _i in range(shards):
		var mi := MeshInstance3D.new()
		var pm := PrismMesh.new()
		var hgt: float = rng.randf_range(0.24, 0.62) * scale
		pm.size = Vector3(0.11 * scale, hgt, 0.11 * scale)
		mi.mesh = pm
		var tint: float = rng.randf_range(-0.04, 0.14)
		var col := Color(0.58 + tint, 0.66 + tint, 0.86 + tint * 0.4)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = col
		mat.metallic = 0.4
		mat.roughness = 0.22
		mat.emission_enabled = true
		mat.emission = col * 0.5
		mi.material_override = mat
		var off: Vector2 = Vector2(rng.randf_range(-0.17, 0.17), rng.randf_range(-0.17, 0.17)) * scale
		mi.position = Vector3(off.x, hgt * 0.5, off.y)
		mi.rotation = Vector3(rng.randf_range(-0.42, 0.42), rng.randf_range(0.0, TAU), rng.randf_range(-0.42, 0.42))
		holder.add_child(mi)


func _build_pool(holder: Node3D, scale: float, rng: RandomNumberGenerator) -> void:
	# a still reflective disc + two ripple rings, a few reeds at the rim
	var disc := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	var r: float = 0.34 * scale
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = 0.02
	disc.mesh = cm
	var wmat := StandardMaterial3D.new()
	wmat.albedo_color = Color(0.16, 0.34, 0.62, 0.8)
	wmat.metallic = 0.7
	wmat.roughness = 0.08
	wmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	wmat.emission_enabled = true
	wmat.emission = Color(0.1, 0.3, 0.5) * 0.25
	disc.material_override = wmat
	disc.position = Vector3(0.0, 0.02, 0.0)
	holder.add_child(disc)
	for k in range(2):
		var ring := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = r * (0.4 + 0.28 * float(k))
		tm.outer_radius = r * (0.46 + 0.28 * float(k))
		ring.mesh = tm
		var rmat := StandardMaterial3D.new()
		rmat.albedo_color = Color(0.5, 0.75, 0.9, 0.5)
		rmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		rmat.emission_enabled = true
		rmat.emission = Color(0.4, 0.7, 0.95) * 0.4
		ring.material_override = rmat
		ring.position = Vector3(0.0, 0.03, 0.0)
		holder.add_child(ring)
	var reeds: int = rng.randi_range(2, 4)
	for _i in range(reeds):
		var reed := MeshInstance3D.new()
		var rc := CylinderMesh.new()
		rc.top_radius = 0.008 * scale
		rc.bottom_radius = 0.014 * scale
		var rh: float = rng.randf_range(0.25, 0.5) * scale
		rc.height = rh
		reed.mesh = rc
		var remat := StandardMaterial3D.new()
		remat.albedo_color = Color(0.3, 0.5, 0.42)
		reed.material_override = remat
		var a: float = rng.randf_range(0.0, TAU)
		reed.position = Vector3(cos(a) * r * 0.85, rh * 0.5, sin(a) * r * 0.85)
		holder.add_child(reed)


func _build_glyph(holder: Node3D, scale: float, rng: RandomNumberGenerator) -> void:
	# a hovering emissive rune: a ring with two crossing strokes, unshaded glow
	var hover: float = 0.4 * scale
	var glow := Color(0.7, 0.92, 1.0)
	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.12 * scale
	tm.outer_radius = 0.16 * scale
	ring.mesh = tm
	var gmat := StandardMaterial3D.new()
	gmat.albedo_color = glow
	gmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	gmat.emission_enabled = true
	gmat.emission = glow
	gmat.emission_energy_multiplier = 2.0
	ring.material_override = gmat
	ring.rotation = Vector3(PI * 0.5, 0.0, 0.0)
	ring.position = Vector3(0.0, hover, 0.0)
	holder.add_child(ring)
	for j in range(2):
		var stroke := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.025 * scale, 0.26 * scale, 0.025 * scale)
		stroke.mesh = bm
		stroke.material_override = gmat
		stroke.position = Vector3(0.0, hover, 0.0)
		stroke.rotation = Vector3(0.0, 0.0, PI * (0.25 + 0.5 * float(j)))
		holder.add_child(stroke)


func _spawn_marker(col: int, row: int, cell: Dictionary) -> void:
	var d: float = BiomeGridTokensScript.density_of(cell)
	var s: float = 0.12 + 0.18 * d
	var kingdom: String = String(cell["kingdom"])
	var color: Color = KINGDOM_COLORS.get(kingdom, KINGDOM_COLORS[""])
	var step: float = _cube_size + _gutter
	var pos: Vector3 = Vector3(col * step, _surface_y(col, row) + s * 0.5 + 0.02, row * step)
	if _flushed:
		var marker: MeshInstance3D = MeshInstance3D.new()
		var mesh: BoxMesh = BoxMesh.new()
		mesh.size = Vector3(s, s, s)
		marker.mesh = mesh
		var mat: StandardMaterial3D = StandardMaterial3D.new()
		mat.albedo_color = color
		mat.emission_enabled = true
		mat.emission = color * 0.4
		marker.material_override = mat
		marker.position = pos
		add_child(marker)
		_stats["late_spawns"] = int(_stats.get("late_spawns", 0)) + 1
		return
	var xf: Transform3D = Transform3D.IDENTITY
	xf = xf.scaled(Vector3(s, s, s))
	xf.origin = pos
	_batch_add("marker:" + kingdom, _unit_box(), {
		"albedo": color, "emission": color * 0.4,
	}, xf)


# ── presence: bake the standing life into a texture, stain the ground.
#    One texel per cell; sources = every ACTIVE unmuted cell, radial falloff
#    over PRESENCE_RADIUS. Rebuilt whole on any state change — cols×rows
#    texels, trivially cheap at reaction frequency. ──

func _refresh_presence() -> void:
	if not _presence_enabled or _grid_cols == 0 or _grid_rows == 0:
		return
	# gather sources from runtime truth (declared file never consulted alone —
	# what stains is what LIVES, including reaction-opened vacuums and claims)
	var sources: Array = []
	for key in _runtime:
		var state: Dictionary = _runtime[key]
		if bool(state["muted"]) or not bool(state["active"]):
			continue
		var cell: Dictionary = _declared[key]
		var parts: PackedStringArray = String(key).split(",")
		var strength: float = BiomeGridTokensScript.density_of(cell) \
			* (0.4 + 0.12 * float(BiomeGridTokensScript.tier_of(cell)))
		if cell["role"] == "halo":
			strength *= 0.7  # the rim stains inward more faintly — it spills outward
		# claimed-by color: claimed fields stain as the CLAIMING seed's kingdom
		var kingdom: String = String(cell["kingdom"])
		var claimer: String = String(state["claimed_by"])
		if kingdom.is_empty() and not claimer.is_empty() and _declared.has(claimer):
			kingdom = String(_declared[claimer]["kingdom"])
		sources.append({
			"col": int(parts[0]), "row": int(parts[1]),
			"color": KINGDOM_COLORS.get(kingdom, KINGDOM_COLORS[""]),
			"strength": strength,
		})
	if sources.is_empty():
		if _presence_mmi != null:
			_presence_mmi.visible = false
		return
	# accumulate weighted kingdom color per cell
	var acc_rgb: Array = []
	var acc_w: Array = []
	acc_rgb.resize(_grid_cols * _grid_rows)
	acc_w.resize(_grid_cols * _grid_rows)
	for i in acc_rgb.size():
		acc_rgb[i] = Vector3.ZERO
		acc_w[i] = 0.0
	var r_cells: int = int(ceil(PRESENCE_RADIUS))
	for src in sources:
		for dr in range(-r_cells, r_cells + 1):
			for dc in range(-r_cells, r_cells + 1):
				var c: int = int(src["col"]) + dc
				var r: int = int(src["row"]) + dr
				if c < 0 or r < 0 or c >= _grid_cols or r >= _grid_rows:
					continue
				var dist: float = Vector2(dc, dr).length()
				if dist > PRESENCE_RADIUS:
					continue
				var w: float = pow(1.0 - dist / PRESENCE_RADIUS, 2.0) * float(src["strength"])
				var idx: int = r * _grid_cols + c
				var col3: Color = src["color"]
				acc_rgb[idx] += Vector3(col3.r, col3.g, col3.b) * w
				acc_w[idx] += w
	if _presence_img == null:
		_presence_img = Image.create(_grid_cols, _grid_rows, false, Image.FORMAT_RGBA8)
	for r in _grid_rows:
		for c in _grid_cols:
			var idx: int = r * _grid_cols + c
			var w: float = acc_w[idx]
			# the void is never stained — no ground, no moisture
			if w <= 0.0 or _cell_height(c, r) <= 0.0:
				_presence_img.set_pixel(c, r, Color(0, 0, 0, 0))
				continue
			var rgb: Vector3 = (acc_rgb[idx] as Vector3) / w
			_presence_img.set_pixel(c, r, Color(rgb.x, rgb.y, rgb.z, clampf(w, 0.0, 1.0)))
	if _presence_tex == null:
		_presence_tex = ImageTexture.create_from_image(_presence_img)
	else:
		_presence_tex.update(_presence_img)
	_rebuild_presence_overlay()


func _rebuild_presence_overlay() -> void:
	if _presence_mmi != null:
		_presence_mmi.queue_free()
		_presence_mmi = null
	var step: float = _cube_size + _gutter
	var cells: Array = []
	for r in _grid_rows:
		for c in _grid_cols:
			if _presence_img.get_pixel(c, r).a >= PRESENCE_MIN_A and _cell_height(c, r) > 0.0:
				cells.append(Vector2i(c, r))
	if cells.is_empty():
		return
	var mm: MultiMesh = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.mesh = _unit_plane()
	mm.instance_count = cells.size()
	for i in cells.size():
		var cell: Vector2i = cells[i]
		var xf: Transform3D = Transform3D.IDENTITY
		xf = xf.scaled(Vector3(step, 1.0, step))
		xf.origin = Vector3(cell.x * step,
			_surface_y(cell.x, cell.y) + 0.012, cell.y * step)
		mm.set_instance_transform(i, xf)
		mm.set_instance_custom_data(i, Color(float(cell.x), float(cell.y), 0.0, 0.0))
	_presence_mmi = MultiMeshInstance3D.new()
	_presence_mmi.name = "BiomePresenceOverlay"
	_presence_mmi.multimesh = mm
	# a stain must never cast shadows: alpha-blended geometry still renders
	# OPAQUE into the shadow map, and the resulting slab reads as a dark
	# rectangle in the volumetric fog past the grid edge (found on the wide
	# ladder stage — the bisect capture without presence was clean)
	_presence_mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var shader: Shader = load("res://commons/resourses/shaders/biome_presence.gdshader")
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("presence_tex", _presence_tex)
	mat.set_shader_parameter("grid_cols", float(_grid_cols))
	mat.set_shader_parameter("grid_rows", float(_grid_rows))
	_presence_mmi.material_override = mat
	if _visibility_range > 0.0:
		_presence_mmi.visibility_range_end = _visibility_range
	add_child(_presence_mmi)
	if int(_stats.get("presence_cells", 0)) != cells.size():
		_stats["presence_cells"] = cells.size()
		print("GridBiomeComponent: presence stain over %d cells (the ground answers the standing life)" % cells.size())


# ── biome-6: the batch machinery. One MultiMesh per (kind, kingdom, recipe)
#    across the whole map; budget thins by even stride, honestly printed. ──

var _unit_plane_mesh: PlaneMesh = null
var _unit_box_mesh: BoxMesh = null


func _unit_plane() -> PlaneMesh:
	if _unit_plane_mesh == null:
		_unit_plane_mesh = PlaneMesh.new()
		_unit_plane_mesh.size = Vector2(1.0, 1.0)
	return _unit_plane_mesh


func _unit_box() -> BoxMesh:
	if _unit_box_mesh == null:
		_unit_box_mesh = BoxMesh.new()
		_unit_box_mesh.size = Vector3.ONE
	return _unit_box_mesh


func _batch_add(key: String, mesh: Mesh, mat_spec: Dictionary, xf: Transform3D) -> void:
	if not _batches.has(key):
		_batches[key] = {"mesh": mesh, "mat": mat_spec, "transforms": []}
	(_batches[key]["transforms"] as Array).append(xf)


func _flush_batches() -> void:
	_flushed = true
	if _batches.is_empty():
		return
	var total: int = 0
	for key in _batches:
		total += (_batches[key]["transforms"] as Array).size()
	var keep_ratio: float = 1.0
	if _budget_instances > 0 and total > _budget_instances:
		keep_ratio = float(_budget_instances) / float(total)
	var kept_total: int = 0
	var nodes: int = 0
	for key in _batches:
		var batch: Dictionary = _batches[key]
		var transforms: Array = batch["transforms"]
		var keep_n: int = transforms.size()
		if keep_ratio < 1.0:
			keep_n = maxi(1, int(floor(float(transforms.size()) * keep_ratio)))
		var mm: MultiMesh = MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = batch["mesh"]
		mm.instance_count = keep_n
		if keep_n == transforms.size():
			for i in keep_n:
				mm.set_instance_transform(i, transforms[i])
		else:
			# even-stride decimation — spatially uniform, deterministic
			var stride: float = float(transforms.size()) / float(keep_n)
			for i in keep_n:
				mm.set_instance_transform(i, transforms[int(floor(float(i) * stride))])
		kept_total += keep_n
		var mmi: MultiMeshInstance3D = MultiMeshInstance3D.new()
		mmi.name = "BiomeBatch_" + key.replace(":", "_")
		mmi.multimesh = mm
		var spec: Dictionary = batch["mat"]
		var mat: StandardMaterial3D = StandardMaterial3D.new()
		mat.albedo_color = spec["albedo"]
		if spec.has("roughness"):
			mat.roughness = float(spec["roughness"])
		if spec.get("cull_off", false):
			mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		if spec.has("emission"):
			mat.emission_enabled = true
			mat.emission = spec["emission"]
		mmi.material_override = mat
		if _visibility_range > 0.0:
			mmi.visibility_range_end = _visibility_range
		add_child(mmi)
		nodes += 1
	_stats["instances"] = kept_total
	_stats["nodes"] = nodes
	_stats["budget_dropped"] = total - kept_total
	if kept_total < total:
		print("GridBiomeComponent: BUDGET CLAMP — %d instances wanted, budget %d, kept %d (dropped %d, even stride)" % [
			total, _budget_instances, kept_total, total - kept_total])
	print("GridBiomeComponent: batched %d instances into %d nodes (visibility range %.0fm)" % [
		kept_total, nodes, _visibility_range])
	_batches.clear()


# The walkable surface of a cell, per GridCommon.surface_world_y: cubes are
# CENTER-origin, so a height-h stack's top sits at (h-1)*step + half a cube —
# NOT h*cube. The component's original h*cube math floated every spawn half a
# cube above the floor; iso captures hid it until the presence stain's
# elevated quads poked past the floor silhouette on the wide ladder stage
# (the "dark rectangle"). One helper, every y computation goes through it.
func _surface_y(col: int, row: int) -> float:
	var h: float = _cell_height(col, row)
	if h <= 0.0:
		return 0.0
	return (h - 1.0) * (_cube_size + _gutter) + _cube_size * 0.5


func _cell_height(col: int, row: int) -> float:
	if row < _structure.size():
		var cells: Variant = _structure[row]
		if cells is Array and col < (cells as Array).size():
			var v: String = String((cells as Array)[col]).strip_edges()
			if v.is_valid_float():
				return v.to_float()
	return 1.0


# ── introspection (tests + editors) ──

func get_stats() -> Dictionary:
	return _stats.duplicate()


func get_runtime(col: int, row: int) -> Dictionary:
	return _runtime.get("%d,%d" % [col, row], {})
