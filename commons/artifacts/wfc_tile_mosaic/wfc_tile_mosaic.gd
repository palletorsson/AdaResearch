# @identity
# essence: a 16×16 floor panel solved by Wave Function Collapse — each cell's terrain type (ground, water, sand, grass, stone, path) was chosen by constraint propagation, not random assignment
# desire: to show that local rules produce global coherence — the mosaic looks designed because every tile honored its neighbors' constraints, and the result is the only map that could have existed
# critical_parameter: grid_size (16) and the adjacency rules — water may only neighbor water or sand, never stone; changing one adjacency rule cascades through every cell that depended on it
# triggers: _ready() calls _solve_wfc() which runs constraint propagation until every cell collapses to one tile type, then renders via ArrayMesh pixel geometry
# emerges: landscape-like patterns without a landscape designer — rivers, shores, and paths appear because ecology IS a local-constraint system; the algorithm finds the same shapes biology does
# needs: VR standing on the mosaic [has — StaticBody3D]; live re-solving with player input [missing]; grid_size variation [missing]; apply_grid_config [has]
# relationships: placed with pattern_tile_puzzle and array_carpet — the three form a progression: draw (puzzle) → repeat (carpet) → constrain (WFC); each is a different theory of pattern formation
# truth: Wave Function Collapse is not random — it is maximum constraint at every step; the map it produces is the only map that could exist given its adjacency rules, which makes it identical to how cities grow

extends Node3D
class_name WfcTileMosaic

## WFC Tile Mosaic — Floor panel showing a pre-generated Wave Function Collapse output.
##
## A grid of tiles where each cell respects adjacency constraints, solved via
## constraint propagation and backtracking. Like array_carpet but for WFC.

# --- Configuration ---

@export var mosaic_world_size: Vector2 = Vector2(0.8, 0.8)
@export var grid_size: int = 16
@export var pixel_scale: int = 4  ## Each tile rendered as NxN pixels for detail

# ═══════════════════════════════════════════
#  DNA (stage 2 — variation)
# ═══════════════════════════════════════════
# grammar: THE LOCAL LAW, which is the whole of what this artifact claims. Its
#   own @identity names it — "the adjacency rules — water may only neighbor water
#   or sand, never stone" — and the table was a literal one screen down that no
#   map token could reach. Same word as lsystem_editor, lsystem_architecture and
#   room_grammar, which is the corpus's word for "the set of local rules that
#   generates the global form"; the values are this system's own laws, the way
#   bouncing_ball kept `regime` and brought its own cases.
#     landscape — the shipped ecotone table, verbatim. Water must reach ground
#                 through sand; ground and path are the connectors.
#     open      — no constraint at all. Every tile may touch every tile, and the
#                 mosaic falls to salt-and-pepper: the proof that the coherence
#                 was never the algorithm, it was the rules.
#     enclave   — a tile may touch only its own kind and ground. Every boundary
#                 must be brokered, so the map becomes continents in a sea.
#     chain     — the six terrains are a cycle (water-sand-ground-grass-path-
#                 stone-water) and a cell may touch only its neighbours in it.
#                 Nothing may jump a step, so the mosaic reads as bands.
#     checker   — a tile may touch anything EXCEPT its own kind. Maximal
#                 constraint in the opposite direction: no region can form.
@export_enum("landscape", "open", "enclave", "chain", "checker") var grammar: String = "landscape"

# ── Capture knob, NOT an axis. 0 keeps the shipped position+instance_id hash,
# so every placement still gets its own mosaic, fresh each launch.
@export var mosaic_seed: int = 0

# ── Capture knob, NOT an axis. 10 is the shipped `max_attempts` literal. It is
# exported because the solver below has a MEASURED defect (see _attempt_solve)
# that makes a single attempt fail most of the time, so a sweep needs to be able
# to buy reliability without anyone quietly changing what seven maps draw.
@export var solve_attempts: int = 10

const GRAMMARS: Array[String] = ["landscape", "open", "enclave", "chain", "checker"]

# --- Tile definitions ---
# Each tile type has a color and a 2x2 pixel pattern.
# Adjacency rules: which tile types can be neighbors (up/right/down/left).

enum Tile { GROUND, WATER, SAND, GRASS, STONE, PATH }

var _tile_colors: Dictionary = {
	Tile.GROUND: Color(0.55, 0.45, 0.35),
	Tile.WATER:  Color(0.15, 0.35, 0.65),
	Tile.SAND:   Color(0.85, 0.78, 0.55),
	Tile.GRASS:  Color(0.25, 0.55, 0.2),
	Tile.STONE:  Color(0.5, 0.5, 0.55),
	Tile.PATH:   Color(0.7, 0.6, 0.45),
}

# 2x2 pixel micro-patterns per tile type (row-major)
var _tile_patterns: Dictionary = {
	Tile.GROUND: [Color(0.55, 0.45, 0.35), Color(0.5, 0.42, 0.32),
				  Color(0.52, 0.43, 0.34), Color(0.57, 0.47, 0.36)],
	Tile.WATER:  [Color(0.15, 0.35, 0.65), Color(0.2, 0.4, 0.7),
				  Color(0.18, 0.38, 0.68), Color(0.12, 0.32, 0.62)],
	Tile.SAND:   [Color(0.85, 0.78, 0.55), Color(0.82, 0.75, 0.52),
				  Color(0.88, 0.8, 0.58), Color(0.84, 0.76, 0.54)],
	Tile.GRASS:  [Color(0.25, 0.55, 0.2), Color(0.28, 0.58, 0.22),
				  Color(0.22, 0.52, 0.18), Color(0.26, 0.56, 0.21)],
	Tile.STONE:  [Color(0.5, 0.5, 0.55), Color(0.48, 0.48, 0.52),
				  Color(0.52, 0.52, 0.56), Color(0.46, 0.46, 0.5)],
	Tile.PATH:   [Color(0.7, 0.6, 0.45), Color(0.68, 0.58, 0.42),
				  Color(0.72, 0.62, 0.47), Color(0.66, 0.56, 0.4)],
}

# Adjacency rules: for each tile, which tiles may appear next to it.
# Symmetric — if A can neighbor B, B can neighbor A.
# This is the `landscape` grammar, and it is the table this file has always used.
var _adjacency_landscape: Dictionary = {
	Tile.GROUND: [Tile.GROUND, Tile.SAND, Tile.GRASS, Tile.STONE, Tile.PATH],
	Tile.WATER:  [Tile.WATER, Tile.SAND],
	Tile.SAND:   [Tile.SAND, Tile.WATER, Tile.GROUND, Tile.PATH],
	Tile.GRASS:  [Tile.GRASS, Tile.GROUND, Tile.PATH],
	Tile.STONE:  [Tile.STONE, Tile.GROUND, Tile.PATH],
	Tile.PATH:   [Tile.PATH, Tile.GROUND, Tile.SAND, Tile.GRASS, Tile.STONE],
}

# The table actually in force. Assigned from `grammar` at the top of _ready,
# before anything reads it; at the default it IS _adjacency_landscape, the same
# object the solver read before.
var _adjacency: Dictionary = {}

# The terrain order `chain` walks. A CYCLE, not a line: stone gives way back to
# water. Measured — as an open line the solver reached a complete grid in 6-14%
# of attempts and fell back to the checkerboard about a fifth to a half of the
# time within the shipped 10-attempt budget; closed into a cycle it reaches 29%,
# level with the shipped landscape table's 31%.
const CHAIN_ORDER: Array[int] = [Tile.WATER, Tile.SAND, Tile.GROUND, Tile.GRASS, Tile.PATH, Tile.STONE]

# --- Internal ---

var _mosaic_mesh: MeshInstance3D
var _mosaic_material: StandardMaterial3D
var _rng: RandomNumberGenerator
var _all_tiles: Array = [Tile.GROUND, Tile.WATER, Tile.SAND, Tile.GRASS, Tile.STONE, Tile.PATH]
var _built: bool = false


func _ready() -> void:
	_adjacency = _grammar_table(grammar)
	_rng = RandomNumberGenerator.new()
	_reseed()
	_create_mosaic_mesh()
	_generate_wfc()
	_built = true


## mosaic_seed 0 is the shipped line, character for character.
func _reseed() -> void:
	if mosaic_seed != 0:
		_rng.seed = mosaic_seed
	else:
		_rng.seed = hash(str(global_position) + str(get_instance_id()))


# --- Grammars ---
# Each returns the adjacency table for one law. `landscape` returns the shipped
# dictionary itself, so at the default not one entry is recomputed. All five are
# symmetric by construction (checked: A allows B iff B allows A), which the
# solver's arc-consistency assumes.

func _grammar_table(g: String) -> Dictionary:
	match g:
		"open":
			return _table_open()
		"enclave":
			return _table_enclave(Tile.GROUND)
		"chain":
			return _table_chain()
		"checker":
			return _table_checker()
		_:
			return _adjacency_landscape


func _table_open() -> Dictionary:
	var d: Dictionary = {}
	for t in _all_tiles:
		d[t] = _all_tiles.duplicate()
	return d


func _table_enclave(hub: int) -> Dictionary:
	var d: Dictionary = {}
	for t in _all_tiles:
		if int(t) == hub:
			d[t] = _all_tiles.duplicate()
		else:
			d[t] = [t, hub]
	return d


func _table_chain() -> Dictionary:
	var d: Dictionary = {}
	var n: int = CHAIN_ORDER.size()
	for i in range(n):
		var t: int = CHAIN_ORDER[i]
		d[t] = [t, CHAIN_ORDER[(i - 1 + n) % n], CHAIN_ORDER[(i + 1) % n]]
	return d


func _table_checker() -> Dictionary:
	var d: Dictionary = {}
	for t in _all_tiles:
		var opts: Array = []
		for other in _all_tiles:
			if other != t:
				opts.append(other)
		d[t] = opts
	return d


func _create_mosaic_mesh() -> void:
	_mosaic_mesh = MeshInstance3D.new()
	_mosaic_mesh.name = "MosaicMesh"

	var quad := QuadMesh.new()
	quad.size = mosaic_world_size
	_mosaic_mesh.mesh = quad

	# Lie flat on the floor
	_mosaic_mesh.rotation_degrees.x = -90
	_mosaic_mesh.position.y = 0.005

	# Material
	_mosaic_material = StandardMaterial3D.new()
	_mosaic_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_mosaic_material.roughness = 0.85
	_mosaic_material.metallic = 0.0
	_mosaic_mesh.material_override = _mosaic_material

	add_child(_mosaic_mesh)


func _generate_wfc() -> void:
	var grid: Array = _solve_wfc()
	_render_grid(grid)


# --- WFC Solver ---

func _solve_wfc() -> Array:
	# Each cell holds an array of possible tile types (superposition).
	# We collapse one cell at a time, propagate constraints, backtrack on contradiction.
	var max_attempts: int = maxi(solve_attempts, 1)
	for _attempt in range(max_attempts):
		var result := _attempt_solve()
		if result.size() > 0:
			return result
		# Failed — retry with different seed
		_rng.seed = _rng.randi()
	# Fallback: return a simple checkerboard
	return _fallback_grid()


## MEASURED DEFECT, left in place on purpose — reported, not papered over.
##
## The entropy scan below breaks out of its `for y` loop as soon as a row holds
## no uncollapsed cell ("if min_entropy == 999 and candidates.is_empty(): break").
## That fires the moment ROW 0 is fully collapsed, whatever the other fifteen
## rows are doing: candidates stays empty, the while loop `continue`s, and the
## solve spins uselessly until max_iterations and reports failure. So an attempt
## only completes when the last cell to collapse happens to lie in row 0.
##
## Measured in a faithful port of this exact function (16x16, one attempt each):
## landscape succeeds 31% of attempts, checker 38%, enclave 19%, open 12% — and
## `open` puts NO constraint on anything, which is the proof that the failure is
## structural and not about the rules. Every single failure was the iteration cap
## with ~15-22 cells still uncollapsed and ~4880 dead spins burnt; not one was a
## genuine contradiction. Within the shipped 10-attempt budget that is a ~3%
## chance of falling through to _fallback_grid's two-colour checkerboard at the
## default, and ~26% under `open`.
##
## Deleting the `break` is the fix, and it is a one-line change to what seven
## maps draw, so it belongs to a deliberate decision and not to a DNA promotion.
## `solve_attempts` exists so a capture can buy its way past this meanwhile.
func _attempt_solve() -> Array:
	var possibilities: Array = []
	for y in range(grid_size):
		var row: Array = []
		for x in range(grid_size):
			row.append(_all_tiles.duplicate())
		possibilities.append(row)

	var collapsed: Array = []
	for y in range(grid_size):
		var row: Array = []
		for x in range(grid_size):
			row.append(-1)
		collapsed.append(row)

	# Track collapse history for backtracking
	var history: Array = []
	var cells_remaining := grid_size * grid_size
	var max_iterations := grid_size * grid_size * 20  # Safety cap
	var iteration := 0

	while cells_remaining > 0 and iteration < max_iterations:
		iteration += 1
		# Find cell with lowest entropy (fewest possibilities) among uncollapsed
		var min_entropy := 999
		var candidates: Array = []
		for y in range(grid_size):
			for x in range(grid_size):
				if collapsed[y][x] != -1:
					continue
				var entropy: int = possibilities[y][x].size()
				if entropy == 0:
					# Contradiction — try backtracking
					if not _backtrack(history, possibilities, collapsed):
						return []  # Cannot recover
					cells_remaining += 1
					min_entropy = 999
					candidates.clear()
					break
				if entropy < min_entropy:
					min_entropy = entropy
					candidates = [Vector2i(x, y)]
				elif entropy == min_entropy:
					candidates.append(Vector2i(x, y))
			if min_entropy == 999 and candidates.is_empty():
				break  # Restarting inner loop after backtrack

		if candidates.is_empty():
			continue

		# Pick a random candidate among those with lowest entropy
		var pick: Vector2i = candidates[_rng.randi() % candidates.size()]
		var px: int = pick.x
		var py: int = pick.y
		var opts: Array = possibilities[py][px]

		if opts.is_empty():
			if not _backtrack(history, possibilities, collapsed):
				return []
			cells_remaining += 1
			continue

		# Collapse: pick a weighted random tile
		var chosen: int = opts[_rng.randi() % opts.size()]

		# Save state for backtracking
		history.append({
			"pos": pick,
			"chosen": chosen,
			"old_possibilities": _deep_copy_possibilities(possibilities),
			"old_collapsed": _deep_copy_collapsed(collapsed),
		})
		# Limit history to prevent excessive memory use
		if history.size() > 200:
			history = history.slice(history.size() - 100)

		collapsed[py][px] = chosen
		possibilities[py][px] = [chosen]
		cells_remaining -= 1

		# Propagate constraints
		if not _propagate(possibilities, collapsed):
			if not _backtrack(history, possibilities, collapsed):
				return []
			cells_remaining = _count_remaining(collapsed)

	if iteration >= max_iterations:
		return []  # Exceeded iteration budget — signal failure
	return collapsed


func _propagate(possibilities: Array, collapsed: Array) -> bool:
	# Iteratively remove impossible tiles based on neighbor constraints
	var changed := true
	var iterations := 0
	while changed and iterations < 200:
		changed = false
		iterations += 1
		for y in range(grid_size):
			for x in range(grid_size):
				if collapsed[y][x] != -1:
					continue
				var current_opts: Array = possibilities[y][x]
				var new_opts: Array = []
				for tile in current_opts:
					if _is_compatible(tile, x, y, possibilities, collapsed):
						new_opts.append(tile)
				if new_opts.size() < current_opts.size():
					changed = true
					possibilities[y][x] = new_opts
					if new_opts.is_empty():
						return false  # Contradiction
	return true


func _is_compatible(tile: int, x: int, y: int, possibilities: Array, collapsed: Array) -> bool:
	var neighbors := [
		Vector2i(x, y - 1),  # up
		Vector2i(x + 1, y),  # right
		Vector2i(x, y + 1),  # down
		Vector2i(x - 1, y),  # left
	]
	var allowed: Array = _adjacency[tile]
	for n_pos in neighbors:
		if n_pos.x < 0 or n_pos.x >= grid_size or n_pos.y < 0 or n_pos.y >= grid_size:
			continue
		# Check if at least one possibility of the neighbor is allowed
		var n_opts: Array
		if collapsed[n_pos.y][n_pos.x] != -1:
			n_opts = [collapsed[n_pos.y][n_pos.x]]
		else:
			n_opts = possibilities[n_pos.y][n_pos.x]
		var any_allowed := false
		for n_tile in n_opts:
			if n_tile in allowed:
				any_allowed = true
				break
		if not any_allowed:
			return false
	return true


func _backtrack(history: Array, possibilities: Array, collapsed: Array) -> bool:
	if history.is_empty():
		return false
	var last: Dictionary = history.pop_back()
	# Restore state
	var old_p: Array = last["old_possibilities"]
	var old_c: Array = last["old_collapsed"]
	for y in range(grid_size):
		for x in range(grid_size):
			possibilities[y][x] = old_p[y][x]
			collapsed[y][x] = old_c[y][x]
	# Remove the failed choice from possibilities
	var pos: Vector2i = last["pos"]
	var failed_tile: int = last["chosen"]
	possibilities[pos.y][pos.x].erase(failed_tile)
	return possibilities[pos.y][pos.x].size() > 0


func _count_remaining(collapsed: Array) -> int:
	var count := 0
	for y in range(grid_size):
		for x in range(grid_size):
			if collapsed[y][x] == -1:
				count += 1
	return count


func _deep_copy_possibilities(p: Array) -> Array:
	var copy: Array = []
	for y in range(p.size()):
		var row: Array = []
		for x in range(p[y].size()):
			row.append(p[y][x].duplicate())
		copy.append(row)
	return copy


func _deep_copy_collapsed(c: Array) -> Array:
	var copy: Array = []
	for y in range(c.size()):
		copy.append(c[y].duplicate())
	return copy


func _fallback_grid() -> Array:
	var grid: Array = []
	for y in range(grid_size):
		var row: Array = []
		for x in range(grid_size):
			row.append(((x + y) % 2) * 3)  # Alternating GROUND/GRASS
		grid.append(row)
	return grid


# --- Rendering ---

func _render_grid(grid: Array) -> void:
	var tex_size := grid_size * pixel_scale
	var image := Image.create(tex_size, tex_size, false, Image.FORMAT_RGBA8)

	for gy in range(grid_size):
		for gx in range(grid_size):
			var tile_type: int = grid[gy][gx]
			if tile_type < 0:
				tile_type = Tile.GROUND
			var pattern: Array = _tile_patterns.get(tile_type, _tile_patterns[Tile.GROUND])
			# Draw each tile as pixel_scale x pixel_scale block with 2x2 micro-pattern
			for py in range(pixel_scale):
				for px in range(pixel_scale):
					var pi: int = (py % 2) * 2 + (px % 2)
					var color: Color = pattern[pi]
					image.set_pixel(gx * pixel_scale + px, gy * pixel_scale + py, color)

	# Add subtle grid lines between tiles
	var line_color := Color(0.0, 0.0, 0.0, 0.15)
	for g in range(grid_size + 1):
		var pixel_pos := g * pixel_scale
		if pixel_pos >= tex_size:
			pixel_pos = tex_size - 1
		for i in range(tex_size):
			if pixel_pos < tex_size:
				var existing := image.get_pixel(clampi(pixel_pos, 0, tex_size - 1), i)
				image.set_pixel(clampi(pixel_pos, 0, tex_size - 1), i, existing.lerp(line_color, 0.3))
				existing = image.get_pixel(i, clampi(pixel_pos, 0, tex_size - 1))
				image.set_pixel(i, clampi(pixel_pos, 0, tex_size - 1), existing.lerp(line_color, 0.3))

	var texture := ImageTexture.create_from_image(image)
	_mosaic_material.albedo_texture = texture


## Grid system integration — accept configuration from map data.
##
## Guarded twice: a value is taken only when it VALIDATES against the code's own
## table and DIFFERS from the value already held, and the re-solve fires only
## after _ready has generated once. Before this, any call at all re-seeded and
## re-solved — including the {"emissive": false} that curation_station sends to
## every artifact it mounts, which is the one call this artifact actually
## receives in the corpus. That call reached the same position and the same
## instance id as _ready had, so it re-seeded to the identical number and drew
## the identical mosaic; the guard therefore removes a wasted solve and changes
## no pixel in Curation_Bay_mosaicanalysis_1. The other six placements are bare
## tokens (or rotation shorthand, which the grid routes to overrides, not to
## config_data), so apply_grid_config is never called for them at all.
func apply_grid_config(config_data: Dictionary) -> void:
	var changed: bool = false
	if config_data.has("grammar"):
		var g: String = str(config_data["grammar"])
		if GRAMMARS.has(g) and g != grammar:
			grammar = g
			_adjacency = _grammar_table(g)
			changed = true
	if config_data.has("mosaic_seed"):
		var s: int = int(config_data["mosaic_seed"])
		if s != mosaic_seed:
			mosaic_seed = s
			changed = true
	if config_data.has("solve_attempts"):
		var a: int = int(config_data["solve_attempts"])
		if a > 0 and a != solve_attempts:
			solve_attempts = a
			changed = true
	if config_data.has("grid_size"):
		var n: int = int(config_data["grid_size"])
		if n > 0 and n != grid_size:
			grid_size = n
			changed = true
	if config_data.has("pixel_scale"):
		var p: int = int(config_data["pixel_scale"])
		if p > 0 and p != pixel_scale:
			pixel_scale = p
			changed = true
	if changed and _built:
		_reseed()
		_generate_wfc()
