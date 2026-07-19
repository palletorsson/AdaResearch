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
	_stage_order = stage_order
	_budget_instances = int(meta.get("budget_instances", DEFAULT_BUDGET_INSTANCES))
	_visibility_range = float(meta.get("visibility_range", DEFAULT_VISIBILITY_RANGE))
	_tick_seconds = maxf(0.1, float(meta.get("tick_seconds", DEFAULT_TICK_SECONDS)))
	_dwell_seconds = maxf(0.1, float(meta.get("dwell_seconds", DEFAULT_DWELL_SECONDS)))
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
				"active": parsed["role"] == "seed",
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
		_spawn_marker(col, row, cell)
		return
	_routed += 1
	var step: float = _cube_size + _gutter
	var local: Vector3 = Vector3(
		col * step, _cell_height(col, row) * _cube_size + 0.02, row * step)
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
	}
	_get_dispatcher().spawn_cell(deposit, _stage_order, {"cube_size": _cube_size}, self)


func _get_dispatcher() -> Node3D:
	if _dispatcher == null:
		# load (not preload / class_name): the dispatcher preloads heavy
		# substrate scenes — only maps that actually route pay for them.
		var DispatcherScript = load("res://commons/biome_layers/biome_paint_dispatcher.gd")
		_dispatcher = DispatcherScript.new()
		_dispatcher.name = "BiomeGridDispatcher"
		add_child(_dispatcher)
	return _dispatcher


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
	var surf_y: float = _cell_height(col, row) * _cube_size
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
			var sc: float = rng.randf_range(0.6, 1.2)
			xf = xf.scaled(Vector3(sc, sc, sc))
			xf.origin = pos
			_batch_add("cover:%s:%s" % [kingdom, String(recipe["name"])], recipe["mesh"], {
				"albedo": recipe["color"], "cull_off": true,
				"emission": (recipe["color"] as Color) * 0.25,
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
	match kingdom:
		"flora":
			var grass: QuadMesh = QuadMesh.new()
			grass.size = Vector2(0.12, 0.4)
			grass.center_offset = Vector3(0, 0.2, 0)
			var bloom: SphereMesh = SphereMesh.new()
			bloom.radius = 0.06
			bloom.height = 0.12
			bloom.radial_segments = 6
			bloom.rings = 3
			return [
				{"name": "grass", "mesh": grass, "color": Color(0.25, 0.45, 0.15), "fraction": 0.8},
				{"name": "bloom", "mesh": bloom, "color": Color(0.85, 0.5, 0.4), "fraction": 0.2},
			]
		"fungus":
			var cap: CylinderMesh = CylinderMesh.new()
			cap.top_radius = 0.15
			cap.bottom_radius = 0.03
			cap.height = 0.18
			cap.radial_segments = 6
			return [{"name": "mushroom", "mesh": cap, "color": Color(0.5, 0.35, 0.55), "fraction": 1.0}]
		"fauna":
			var body: CapsuleMesh = CapsuleMesh.new()
			body.radius = 0.12
			body.height = 0.35
			return [{"name": "silhouette", "mesh": body, "color": Color(0.6, 0.4, 0.2), "fraction": 1.0}]
		"mineral":
			var stone: BoxMesh = BoxMesh.new()
			stone.size = Vector3(0.18, 0.12, 0.15)
			return [{"name": "stone", "mesh": stone, "color": Color(0.5, 0.5, 0.55), "fraction": 1.0}]
		"water":
			var reed: CylinderMesh = CylinderMesh.new()
			reed.top_radius = 0.008
			reed.bottom_radius = 0.015
			reed.height = 0.7
			reed.radial_segments = 3
			return [{"name": "reed", "mesh": reed, "color": Color(0.3, 0.45, 0.4), "fraction": 1.0}]
		"meta":
			var glyph: QuadMesh = QuadMesh.new()
			glyph.size = Vector2(0.1, 0.1)
			glyph.center_offset = Vector3(0, 0.15, 0)
			return [{"name": "glyph", "mesh": glyph, "color": Color(0.9, 0.9, 0.95), "fraction": 1.0}]
		_:
			var tuft: QuadMesh = QuadMesh.new()
			tuft.size = Vector2(0.12, 0.3)
			tuft.center_offset = Vector3(0, 0.15, 0)
			return [{"name": "tuft", "mesh": tuft, "color": Color(0.35, 0.35, 0.3), "fraction": 1.0}]


# ── pilot rendering: one small kingdom-tinted marker per active cell.
#    Batched map-wide per kingdom (biome-6); a runtime claim arriving after
#    the flush (react → claim) spawns direct — few, and honestly counted. ──

func _spawn_marker(col: int, row: int, cell: Dictionary) -> void:
	var d: float = BiomeGridTokensScript.density_of(cell)
	var s: float = 0.12 + 0.18 * d
	var kingdom: String = String(cell["kingdom"])
	var color: Color = KINGDOM_COLORS.get(kingdom, KINGDOM_COLORS[""])
	var h: float = _cell_height(col, row)
	var step: float = _cube_size + _gutter
	var pos: Vector3 = Vector3(col * step, h * _cube_size + s * 0.5 + 0.02, row * step)
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
