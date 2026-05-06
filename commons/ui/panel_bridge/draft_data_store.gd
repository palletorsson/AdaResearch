## Reactive data store for weaving drafts.
##
## Holds threading, tie-up, and treadling binary matrices,
## computes the drawdown using bitmask operations (ported from
## draft-engine.ts), and emits change signals so widgets can
## repaint when data mutates.
##
## Supports up to 31 shafts via 32-bit integers.
class_name DraftDataStore
extends RefCounted

# ── Signals ──────────────────────────────────────────────────────

## Emitted when any cell in threading, tieup, or treadling changes.
## [param grid_id] is "threading", "tieup", or "treadling".
signal cell_changed(grid_id: String)

## Emitted after the drawdown has been recomputed.
signal drawdown_changed()

## Emitted when thread colors change.
signal colors_changed()

# ── Loom dimensions ─────────────────────────────────────────────

var warps: int = 24
var picks: int = 24
var shafts: int = 4
var treadles: int = 6

# ── Binary matrices ─────────────────────────────────────────────
# Each stored as a flat PackedByteArray for cache-friendly access.
# threading: warps × shafts   (row = warp, col = shaft)
# tieup:     shafts × treadles (row = shaft, col = treadle)
# treadling: picks × treadles  (row = pick,  col = treadle)

var _threading: PackedByteArray
var _tieup: PackedByteArray
var _treadling: PackedByteArray

# ── Drawdown cache ──────────────────────────────────────────────
# Flat bool array: picks × warps  (row = pick, col = warp)
# true = warp on top, false = weft on top

var _drawdown: PackedByteArray
var _drawdown_dirty: bool = true

# ── Pre-computed bitmasks (internal) ────────────────────────────

var _treadle_shaft_mask: PackedInt32Array   # [treadle] → shaft bitmask
var _warp_shaft: PackedInt32Array           # [warp]    → shaft index (-1 = unthreaded)
var _masks_dirty: bool = true

# ── Thread colors ───────────────────────────────────────────────
# Hex strings for palette, integer patterns for repeat sequences.

var color_palette: PackedStringArray = PackedStringArray([
	"#1e3a5f", "#c4a35a", "#8b2500", "#2d5a27",
	"#f5f0e6", "#4a2d6b", "#c67b30", "#1a1a2e",
])
var warp_pattern: PackedInt32Array = PackedInt32Array([0, 1])
var weft_pattern: PackedInt32Array = PackedInt32Array([0, 1])

# Pre-resolved per-thread Color arrays (rebuilt on color change)
var _warp_colors: PackedColorArray
var _weft_colors: PackedColorArray

# ── Initialisation ──────────────────────────────────────────────

func _init() -> void:
	_alloc_matrices()
	_resolve_colors()


## Resize the draft dimensions and reset all matrices to zero.
func resize(p_warps: int, p_picks: int, p_shafts: int, p_treadles: int) -> void:
	warps = p_warps
	picks = p_picks
	shafts = p_shafts
	treadles = p_treadles
	_alloc_matrices()
	_resolve_colors()
	_masks_dirty = true
	_drawdown_dirty = true
	cell_changed.emit("threading")
	cell_changed.emit("tieup")
	cell_changed.emit("treadling")
	drawdown_changed.emit()


func _alloc_matrices() -> void:
	_threading = PackedByteArray()
	_threading.resize(warps * shafts)
	_threading.fill(0)

	_tieup = PackedByteArray()
	_tieup.resize(shafts * treadles)
	_tieup.fill(0)

	_treadling = PackedByteArray()
	_treadling.resize(picks * treadles)
	_treadling.fill(0)

	_drawdown = PackedByteArray()
	_drawdown.resize(picks * warps)
	_drawdown.fill(0)

	_treadle_shaft_mask = PackedInt32Array()
	_treadle_shaft_mask.resize(treadles)
	_treadle_shaft_mask.fill(0)

	_warp_shaft = PackedInt32Array()
	_warp_shaft.resize(warps)
	_warp_shaft.fill(-1)


# ── Cell access ─────────────────────────────────────────────────

## Get a cell value (0 or 1) from the named grid.
## [param grid_id] "threading" | "tieup" | "treadling"
func get_cell(grid_id: String, row: int, col: int) -> int:
	match grid_id:
		"threading":
			if row < 0 or row >= warps or col < 0 or col >= shafts:
				return 0
			return _threading[row * shafts + col]
		"tieup":
			if row < 0 or row >= shafts or col < 0 or col >= treadles:
				return 0
			return _tieup[row * treadles + col]
		"treadling":
			if row < 0 or row >= picks or col < 0 or col >= treadles:
				return 0
			return _treadling[row * treadles + col]
	return 0


## Set a cell value directly.
func set_cell(grid_id: String, row: int, col: int, value: int) -> void:
	var idx := -1
	match grid_id:
		"threading":
			if row < 0 or row >= warps or col < 0 or col >= shafts:
				return
			idx = row * shafts + col
			_threading[idx] = value
		"tieup":
			if row < 0 or row >= shafts or col < 0 or col >= treadles:
				return
			idx = row * treadles + col
			_tieup[idx] = value
		"treadling":
			if row < 0 or row >= picks or col < 0 or col >= treadles:
				return
			idx = row * treadles + col
			_treadling[idx] = value
		_:
			return
	_masks_dirty = true
	_drawdown_dirty = true
	print("DraftDataStore: set_cell(%s, %d, %d) = %d → emitting signals" % [grid_id, row, col, value])
	cell_changed.emit(grid_id)
	drawdown_changed.emit()


## Toggle a cell between 0 and 1.
func toggle_cell(grid_id: String, row: int, col: int) -> void:
	var current := get_cell(grid_id, row, col)
	print("DraftDataStore: toggle_cell(%s, %d, %d) %d→%d" % [grid_id, row, col, current, 1 - current])
	set_cell(grid_id, row, col, 1 - current)


## Set a cell to 1 and clear all other cells in the same column.
## Used for threading (each warp on exactly one shaft) and
## treadling (each pick presses exactly one treadle).
func set_exclusive_col(grid_id: String, row: int, col: int) -> void:
	var rows := 0
	var cols := 0
	var arr: PackedByteArray
	match grid_id:
		"threading":
			rows = warps
			cols = shafts
			arr = _threading
		"treadling":
			rows = picks
			cols = treadles
			arr = _treadling
		_:
			# exclusive_col doesn't make sense for tieup
			toggle_cell(grid_id, row, col)
			return

	# If clicking the already-active cell, clear it (toggle off)
	var current_val := arr[row * cols + col]

	# Clear entire row (this warp/pick has only one shaft/treadle)
	for c in cols:
		arr[row * cols + c] = 0

	# Set the clicked cell (unless toggling off)
	if current_val == 0:
		arr[row * cols + col] = 1

	_masks_dirty = true
	_drawdown_dirty = true
	cell_changed.emit(grid_id)
	drawdown_changed.emit()


# ── Drawdown computation ────────────────────────────────────────

## Get the drawdown value at (pick, warp). 1 = warp on top.
## Lazily recomputes if dirty.
func get_drawdown(pick: int, warp: int) -> int:
	if _drawdown_dirty:
		_recompute_drawdown()
	if pick < 0 or pick >= picks or warp < 0 or warp >= warps:
		return 0
	return _drawdown[pick * warps + warp]


## Get the display color for a drawdown cell.
## Returns the warp color if warp is on top, else the weft color.
func get_drawdown_color(pick: int, warp: int) -> Color:
	if _drawdown_dirty:
		_recompute_drawdown()
	if pick < 0 or pick >= picks or warp < 0 or warp >= warps:
		return Color.BLACK
	var on_top := _drawdown[pick * warps + warp]
	if on_top:
		return _warp_colors[warp] if warp < _warp_colors.size() else Color.GRAY
	else:
		return _weft_colors[pick] if pick < _weft_colors.size() else Color.GRAY


## Force a full recomputation of the drawdown.
func _recompute_drawdown() -> void:
	if _masks_dirty:
		_rebuild_masks()

	# For each pick: compute active shaft mask, then check each warp
	for pick in picks:
		# Which treadles are pressed this pick?
		var treadle_mask := 0
		for t in treadles:
			if _treadling[pick * treadles + t]:
				treadle_mask |= (1 << t)

		# Which shafts are lifted?
		var active_shaft_mask := 0
		for t in treadles:
			if treadle_mask & (1 << t):
				active_shaft_mask |= _treadle_shaft_mask[t]

		# Check each warp
		var row_offset := pick * warps
		for warp in warps:
			var shaft := _warp_shaft[warp]
			if shaft >= 0 and (active_shaft_mask & (1 << shaft)):
				_drawdown[row_offset + warp] = 1
			else:
				_drawdown[row_offset + warp] = 0

	_drawdown_dirty = false


## Rebuild bitmask lookup tables from current matrix data.
func _rebuild_masks() -> void:
	# treadle_shaft_mask[t] = bitmask of shafts lifted when treadle t is pressed
	_treadle_shaft_mask.fill(0)
	for s in shafts:
		for t in treadles:
			if _tieup[s * treadles + t]:
				_treadle_shaft_mask[t] |= (1 << s)

	# warp_shaft[w] = which shaft each warp is threaded on
	_warp_shaft.fill(-1)
	for w in warps:
		for s in shafts:
			if _threading[w * shafts + s]:
				_warp_shaft[w] = s
				break  # each warp on exactly one shaft

	_masks_dirty = false


# ── Thread colors ───────────────────────────────────────────────

## Update the thread color configuration.
func set_colors(palette: PackedStringArray, warp_pat: PackedInt32Array, weft_pat: PackedInt32Array) -> void:
	color_palette = palette
	warp_pattern = warp_pat
	weft_pattern = weft_pat
	_resolve_colors()
	colors_changed.emit()


## Resolve color patterns into per-thread Color arrays.
func _resolve_colors() -> void:
	_warp_colors = _resolve_pattern(warp_pattern, warps)
	_weft_colors = _resolve_pattern(weft_pattern, picks)


func _resolve_pattern(pattern: PackedInt32Array, count: int) -> PackedColorArray:
	var result := PackedColorArray()
	result.resize(count)
	if pattern.is_empty() or color_palette.is_empty():
		result.fill(Color(0.2, 0.2, 0.2))
		return result
	for i in count:
		var color_idx: int = pattern[i % pattern.size()]
		var hex: String = color_palette[color_idx % color_palette.size()] if color_palette.size() > 0 else "#333333"
		result[i] = Color.from_string(hex, Color(0.2, 0.2, 0.2))
	return result


# ── Bulk loading (from JSON) ────────────────────────────────────

## Load draft data from a parsed JSON dictionary.
## Expected keys: warps, picks, shafts, treadles, threading, tieup, treadling, colors
func load_from_dict(data: Dictionary) -> void:
	warps = data.get("warps", 24) as int
	picks = data.get("picks", 24) as int
	shafts = data.get("shafts", 4) as int
	treadles = data.get("treadles", 6) as int

	_alloc_matrices()

	# Load binary matrices from 2D arrays
	_load_matrix("threading", data.get("threading", []), warps, shafts)
	_load_matrix("tieup", data.get("tieup", []), shafts, treadles)
	_load_matrix("treadling", data.get("treadling", []), picks, treadles)

	# Load colors
	var colors_dict: Dictionary = data.get("colors", {})
	if not colors_dict.is_empty():
		var palette := PackedStringArray()
		for c in colors_dict.get("colors", []):
			palette.append(str(c))
		var wp := PackedInt32Array()
		for v in colors_dict.get("warpPattern", []):
			wp.append(int(v))
		var wfp := PackedInt32Array()
		for v in colors_dict.get("weftPattern", []):
			wfp.append(int(v))
		color_palette = palette
		warp_pattern = wp
		weft_pattern = wfp

	_resolve_colors()
	_masks_dirty = true
	_drawdown_dirty = true

	cell_changed.emit("threading")
	cell_changed.emit("tieup")
	cell_changed.emit("treadling")
	drawdown_changed.emit()
	colors_changed.emit()


func _load_matrix(grid_id: String, matrix_2d: Array, rows: int, cols: int) -> void:
	var arr: PackedByteArray
	match grid_id:
		"threading":
			arr = _threading
		"tieup":
			arr = _tieup
		"treadling":
			arr = _treadling
		_:
			return

	for r in mini(matrix_2d.size(), rows):
		var row: Array = matrix_2d[r]
		for c in mini(row.size(), cols):
			arr[r * cols + c] = 1 if int(row[c]) else 0


# ── Draft operations (called from OperationsBarWidget) ──────────

## Dispatch a named operation on the draft.
func execute_operation(action_name: String) -> void:
	match action_name:
		"mirror_threading":   mirror_threading()
		"mirror_treadling":   mirror_treadling()
		"invert_tieup":       invert_tieup()
		"invert_threading":   invert_threading()
		"invert_treadling":   invert_treadling()
		"shift_threading_l":  shift_threading_left()
		"shift_threading_r":  shift_threading_right()
		"shift_treadling_u":  shift_treadling_up()
		"shift_treadling_d":  shift_treadling_down()
		"rotate_tieup_cw":    rotate_tieup_cw()
		"clear":              clear_all()
		_:
			push_warning("DraftDataStore: Unknown operation '%s'" % action_name)


## Reverse the threading order (warp 0 ↔ last warp).
func mirror_threading() -> void:
	var half := warps / 2
	for w in half:
		var other := warps - 1 - w
		for s in shafts:
			var tmp := _threading[w * shafts + s]
			_threading[w * shafts + s] = _threading[other * shafts + s]
			_threading[other * shafts + s] = tmp
	_masks_dirty = true
	_drawdown_dirty = true
	cell_changed.emit("threading")
	drawdown_changed.emit()


## Reverse the treadling order (pick 0 ↔ last pick).
func mirror_treadling() -> void:
	var half := picks / 2
	for p in half:
		var other := picks - 1 - p
		for t in treadles:
			var tmp := _treadling[p * treadles + t]
			_treadling[p * treadles + t] = _treadling[other * treadles + t]
			_treadling[other * treadles + t] = tmp
	_masks_dirty = true
	_drawdown_dirty = true
	cell_changed.emit("treadling")
	drawdown_changed.emit()


## Invert all tieup cells (0↔1).
func invert_tieup() -> void:
	for i in _tieup.size():
		_tieup[i] = 1 - _tieup[i]
	_masks_dirty = true
	_drawdown_dirty = true
	cell_changed.emit("tieup")
	drawdown_changed.emit()


## Invert all threading cells (0↔1).
func invert_threading() -> void:
	for i in _threading.size():
		_threading[i] = 1 - _threading[i]
	_masks_dirty = true
	_drawdown_dirty = true
	cell_changed.emit("threading")
	drawdown_changed.emit()


## Invert all treadling cells (0↔1).
func invert_treadling() -> void:
	for i in _treadling.size():
		_treadling[i] = 1 - _treadling[i]
	_masks_dirty = true
	_drawdown_dirty = true
	cell_changed.emit("treadling")
	drawdown_changed.emit()


## Shift threading left by one warp (wrapping).
func shift_threading_left() -> void:
	var new_arr := PackedByteArray()
	new_arr.resize(_threading.size())
	for w in warps:
		var src_w := (w + 1) % warps
		for s in shafts:
			new_arr[w * shafts + s] = _threading[src_w * shafts + s]
	_threading = new_arr
	_masks_dirty = true
	_drawdown_dirty = true
	cell_changed.emit("threading")
	drawdown_changed.emit()


## Shift threading right by one warp (wrapping).
func shift_threading_right() -> void:
	var new_arr := PackedByteArray()
	new_arr.resize(_threading.size())
	for w in warps:
		var src_w := (w - 1 + warps) % warps
		for s in shafts:
			new_arr[w * shafts + s] = _threading[src_w * shafts + s]
	_threading = new_arr
	_masks_dirty = true
	_drawdown_dirty = true
	cell_changed.emit("threading")
	drawdown_changed.emit()


## Shift treadling up by one pick (wrapping).
func shift_treadling_up() -> void:
	var new_arr := PackedByteArray()
	new_arr.resize(_treadling.size())
	for p in picks:
		var src_p := (p + 1) % picks
		for t in treadles:
			new_arr[p * treadles + t] = _treadling[src_p * treadles + t]
	_treadling = new_arr
	_masks_dirty = true
	_drawdown_dirty = true
	cell_changed.emit("treadling")
	drawdown_changed.emit()


## Shift treadling down by one pick (wrapping).
func shift_treadling_down() -> void:
	var new_arr := PackedByteArray()
	new_arr.resize(_treadling.size())
	for p in picks:
		var src_p := (p - 1 + picks) % picks
		for t in treadles:
			new_arr[p * treadles + t] = _treadling[src_p * treadles + t]
	_treadling = new_arr
	_masks_dirty = true
	_drawdown_dirty = true
	cell_changed.emit("treadling")
	drawdown_changed.emit()


## Rotate the tieup 90° clockwise (only if shafts == treadles).
func rotate_tieup_cw() -> void:
	if shafts != treadles:
		push_warning("DraftDataStore: rotate_tieup_cw only works when shafts == treadles")
		return
	var n := shafts
	var new_arr := PackedByteArray()
	new_arr.resize(n * n)
	for r in n:
		for c in n:
			new_arr[c * n + (n - 1 - r)] = _tieup[r * n + c]
	_tieup = new_arr
	_masks_dirty = true
	_drawdown_dirty = true
	cell_changed.emit("tieup")
	drawdown_changed.emit()


## Clear all matrices to zero.
func clear_all() -> void:
	_threading.fill(0)
	_tieup.fill(0)
	_treadling.fill(0)
	_masks_dirty = true
	_drawdown_dirty = true
	cell_changed.emit("threading")
	cell_changed.emit("tieup")
	cell_changed.emit("treadling")
	drawdown_changed.emit()


## Export the current state as a Dictionary suitable for JSON serialization.
func to_dict() -> Dictionary:
	var threading_2d := []
	for r in warps:
		var row := []
		for c in shafts:
			row.append(_threading[r * shafts + c])
		threading_2d.append(row)

	var tieup_2d := []
	for r in shafts:
		var row := []
		for c in treadles:
			row.append(_tieup[r * treadles + c])
		tieup_2d.append(row)

	var treadling_2d := []
	for r in picks:
		var row := []
		for c in treadles:
			row.append(_treadling[r * treadles + c])
		treadling_2d.append(row)

	return {
		"warps": warps,
		"picks": picks,
		"shafts": shafts,
		"treadles": treadles,
		"threading": threading_2d,
		"tieup": tieup_2d,
		"treadling": treadling_2d,
		"colors": {
			"colors": Array(color_palette),
			"warpPattern": Array(warp_pattern),
			"weftPattern": Array(weft_pattern),
		},
	}
