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
#     meta) keep the pilot marker. ChunkManager routing is the biome-6 gate.
#   - Halo (biome-3): a halo cell on the grid boundary spills wilderness
#     OUTWARD — a ground strip + kingdom ground-cover thinning into the dark.
#     This is the old BiomeRingComponent reborn as a per-cell role; a map
#     that declares halo cells retires the ground_ring accrual layer (data-
#     gated in GridSystem). No collider — the halo is scenery, walkability
#     untouched, and the un-celled space beyond stays unclaimed (sieve Q3).
#
# Reactivity (pilot subset of the addendum):
#   react(col, row, trigger) applies the cell's matching responses to the
#   RUNTIME copy only: seed / step (generation counter) / claim (expand into
#   adjacent `field` cells) / mute / unmute. Play never rewrites the map file.

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


func initialize(grid_sys: Node3D, cube_size: float, gutter: float) -> void:
	_grid_system = grid_sys
	_cube_size = cube_size
	_gutter = gutter


func generate(biome_layer: Array, structure_layer: Array, stage_order: int = 0) -> void:
	_structure = structure_layer
	_stage_order = stage_order
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
			if parsed["role"] == "seed":
				_stage_cell(col, row, parsed)
			elif parsed["role"] == "halo":
				_spawn_halo(col, row, parsed)
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
	return applied


func _trigger_matches(declared: String, fired: String) -> bool:
	if declared == fired:
		return true
	# "catalyst" matches any typed "catalyst.<mode>"
	return declared == "catalyst" and fired.begins_with("catalyst.")


func _apply_response(key: String, col: int, row: int, cell: Dictionary, response: String) -> void:
	var state: Dictionary = _runtime[key]
	match response:
		"seed":
			state["active"] = true
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
			# mutate:<channel> routes into the mutator stack at biome-2.
			pass


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
	# ground strip — visual only, no collision: the void stays the void
	var ground: MeshInstance3D = MeshInstance3D.new()
	var plane: PlaneMesh = PlaneMesh.new()
	plane.size = Vector2(depth, step) if absf(dir.x) > 0.0 else Vector2(step, depth)
	ground.mesh = plane
	var gmat: StandardMaterial3D = StandardMaterial3D.new()
	var kcolor: Color = KINGDOM_COLORS.get(cell["kingdom"], KINGDOM_COLORS[""])
	gmat.albedo_color = Color(0.16, 0.15, 0.13).lerp(kcolor, 0.15)
	gmat.roughness = 0.9
	ground.material_override = gmat
	ground.position = Vector3(band_center.x, surf_y + 0.005, band_center.z)
	add_child(ground)
	# ground-cover: one MultiMesh per recipe entry
	var target: int = int(round(lerpf(10.0, 50.0, d)))
	for recipe in _halo_recipes(String(cell["kingdom"])):
		var count: int = maxi(1, int(round(float(target) * float(recipe["fraction"]))))
		var transforms: Array = []
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
			transforms.append(xf)
		if transforms.is_empty():
			continue
		_halo_instances += transforms.size()
		var mm: MultiMesh = MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = recipe["mesh"]
		mm.instance_count = transforms.size()
		for i in transforms.size():
			mm.set_instance_transform(i, transforms[i])
		var mmi: MultiMeshInstance3D = MultiMeshInstance3D.new()
		mmi.name = "HaloCover_%d_%d_%s" % [col, row, String(recipe["name"])]
		mmi.multimesh = mm
		var mat: StandardMaterial3D = StandardMaterial3D.new()
		mat.albedo_color = recipe["color"]
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		mat.emission_enabled = true
		mat.emission = (recipe["color"] as Color) * 0.25
		mmi.material_override = mat
		add_child(mmi)


# Ground-cover recipes per grammar kingdom — the halo's own look (grammar-
# native), sized to the ring's old VR budget (low-poly primitives).
func _halo_recipes(kingdom: String) -> Array:
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


# ── pilot rendering: one small kingdom-tinted marker per active cell ──

func _spawn_marker(col: int, row: int, cell: Dictionary) -> void:
	var marker: MeshInstance3D = MeshInstance3D.new()
	var mesh: BoxMesh = BoxMesh.new()
	var d: float = BiomeGridTokensScript.density_of(cell)
	var s: float = 0.12 + 0.18 * d
	mesh.size = Vector3(s, s, s)
	marker.mesh = mesh
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	var color: Color = KINGDOM_COLORS.get(cell["kingdom"], KINGDOM_COLORS[""])
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color * 0.4
	marker.material_override = mat
	var h: float = _cell_height(col, row)
	var step: float = _cube_size + _gutter
	marker.position = Vector3(col * step, h * _cube_size + s * 0.5 + 0.02, row * step)
	add_child(marker)


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
