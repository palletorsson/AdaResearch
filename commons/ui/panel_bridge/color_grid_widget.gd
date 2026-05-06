## Paintable color-index grid Control for the Pattern Maker domain editor.
##
## Each cell stores a color index (0–7) mapped to a palette of Colors.
## Click to paint cells with the active color; right-click to pick a color.
##
## Supports two layouts:
##   "domain"  — editable fundamental domain (small, square, 2–16 cells)
##   "preview" — read-only tiled preview (applies wallpaper group symmetry)
##
## Set up via [method setup] before adding to tree.
class_name ColorGridWidget
extends Control

const P = preload("res://commons/ui/ada_palette.gd")

# ── Signals ──────────────────────────────────────────────────────

## Emitted when any cell is painted.
## [param row] data row, [param col] data column, [param color_index] new value.
signal cell_painted(row: int, col: int, color_index: int)

## Emitted after the entire grid data changes (bulk load / clear / symmetry op).
signal grid_changed()

# ── Configuration ───────────────────────────────────────────────

## Grid dimensions (always square for domains, may be rectangular for preview).
var grid_rows: int = 8
var grid_cols: int = 8

## Color palette — up to 8 entries.  Index 0 is typically background/lightest.
var palette: PackedColorArray = PackedColorArray([
	Color(0.94, 0.90, 0.82),  # 0  cream / background
	Color(0.12, 0.14, 0.18),  # 1  near-black
	Color(0.12, 0.23, 0.37),  # 2  dark navy
	Color(0.77, 0.64, 0.35),  # 3  gold
	Color(0.55, 0.15, 0.00),  # 4  rust
	Color(0.18, 0.35, 0.15),  # 5  forest
	Color(0.29, 0.18, 0.42),  # 6  plum
	Color(0.78, 0.48, 0.19),  # 7  copper
])

## Currently selected color index for painting.
var active_color_index: int = 1

## Click mode: "paint" sets cell to active color, "pick" reads color from cell.
var click_mode: String = "paint"

## If true, this widget is read-only (tiled preview).
var read_only: bool = false

# ── Grid data ───────────────────────────────────────────────────
## Flat PackedByteArray, row-major: data[row * grid_cols + col] = color index.
var _grid_data: PackedByteArray

# ── Visual styling ──────────────────────────────────────────────

var grid_line_color: Color = Color(0.65, 0.62, 0.56, 0.7)  # Warm grid lines
var hover_color: Color = Color(0.75, 0.38, 0.13, 0.35)  # Copper hover
var selected_outline_color: Color = Color(0.75, 0.38, 0.13)  # Copper

# ── Internal state ──────────────────────────────────────────────

var _hover_cell := Vector2i(-1, -1)
var _painting: bool = false   # true while dragging to paint


# ── Lifecycle ───────────────────────────────────────────────────

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP if not read_only else Control.MOUSE_FILTER_IGNORE
	if _grid_data.is_empty():
		_alloc_grid()


## Full setup — call before or after adding to tree.
func setup(rows: int, cols: int, p_palette: PackedColorArray = PackedColorArray(),
		p_read_only: bool = false, p_click_mode: String = "paint") -> void:
	grid_rows = rows
	grid_cols = cols
	if p_palette.size() > 0:
		palette = p_palette
	read_only = p_read_only
	click_mode = p_click_mode
	mouse_filter = Control.MOUSE_FILTER_STOP if not read_only else Control.MOUSE_FILTER_IGNORE
	_alloc_grid()
	queue_redraw()


func _alloc_grid() -> void:
	_grid_data = PackedByteArray()
	_grid_data.resize(grid_rows * grid_cols)
	_grid_data.fill(0)


# ── Data access ─────────────────────────────────────────────────

## Get the color index at (row, col). Returns 0 if out of bounds.
func get_cell(row: int, col: int) -> int:
	if row < 0 or row >= grid_rows or col < 0 or col >= grid_cols:
		return 0
	return _grid_data[row * grid_cols + col]


## Set the color index at (row, col). Emits cell_painted.
func set_cell(row: int, col: int, color_index: int) -> void:
	if row < 0 or row >= grid_rows or col < 0 or col >= grid_cols:
		return
	var idx := row * grid_cols + col
	if _grid_data[idx] == color_index:
		return  # no change
	_grid_data[idx] = clampi(color_index, 0, maxi(palette.size() - 1, 0))
	cell_painted.emit(row, col, color_index)
	queue_redraw()


## Bulk-load grid data from a 2D array of color indices.
func load_from_2d(data: Array) -> void:
	for r in mini(data.size(), grid_rows):
		var row_data: Array = data[r]
		for c in mini(row_data.size(), grid_cols):
			_grid_data[r * grid_cols + c] = clampi(int(row_data[c]), 0, maxi(palette.size() - 1, 0))
	grid_changed.emit()
	queue_redraw()


## Export grid data as a 2D array of color indices.
func to_2d() -> Array:
	var result := []
	for r in grid_rows:
		var row := []
		for c in grid_cols:
			row.append(_grid_data[r * grid_cols + c])
		result.append(row)
	return result


## Clear all cells to color index 0.
func clear_grid() -> void:
	_grid_data.fill(0)
	grid_changed.emit()
	queue_redraw()


## Fill all cells with a specific color index.
func fill_grid(color_index: int) -> void:
	_grid_data.fill(clampi(color_index, 0, maxi(palette.size() - 1, 0)))
	grid_changed.emit()
	queue_redraw()


# ── Palette management ──────────────────────────────────────────

## Update the palette. Clamps existing cell values to new palette size.
func set_palette(new_palette: PackedColorArray) -> void:
	palette = new_palette
	var max_idx := maxi(palette.size() - 1, 0)
	for i in _grid_data.size():
		if _grid_data[i] > max_idx:
			_grid_data[i] = max_idx
	queue_redraw()


## Update the palette from an array of hex strings.
func set_palette_from_hex(hex_colors: Array) -> void:
	var pal := PackedColorArray()
	for hex in hex_colors:
		pal.append(Color.from_string(str(hex), Color(0.2, 0.2, 0.2)))
	set_palette(pal)


# ── Grid operations (symmetry helpers) ──────────────────────────

## Mirror the grid horizontally (flip left ↔ right).
func mirror_x() -> void:
	for r in grid_rows:
		for c in grid_cols / 2:
			var left_idx := r * grid_cols + c
			var right_idx := r * grid_cols + (grid_cols - 1 - c)
			var tmp := _grid_data[left_idx]
			_grid_data[left_idx] = _grid_data[right_idx]
			_grid_data[right_idx] = tmp
	grid_changed.emit()
	queue_redraw()


## Mirror the grid vertically (flip top ↔ bottom).
func mirror_y() -> void:
	for r in grid_rows / 2:
		for c in grid_cols:
			var top_idx := r * grid_cols + c
			var bot_idx := (grid_rows - 1 - r) * grid_cols + c
			var tmp := _grid_data[top_idx]
			_grid_data[top_idx] = _grid_data[bot_idx]
			_grid_data[bot_idx] = tmp
	grid_changed.emit()
	queue_redraw()


## Rotate the grid 90 degrees clockwise. Only works on square grids.
func rotate_cw() -> void:
	if grid_rows != grid_cols:
		push_warning("ColorGridWidget: rotate_cw only supports square grids")
		return
	var n := grid_rows
	var new_data := PackedByteArray()
	new_data.resize(n * n)
	for r in n:
		for c in n:
			new_data[c * n + (n - 1 - r)] = _grid_data[r * n + c]
	_grid_data = new_data
	grid_changed.emit()
	queue_redraw()


## Rotate the grid 90 degrees counter-clockwise. Only works on square grids.
func rotate_ccw() -> void:
	if grid_rows != grid_cols:
		push_warning("ColorGridWidget: rotate_ccw only supports square grids")
		return
	var n := grid_rows
	var new_data := PackedByteArray()
	new_data.resize(n * n)
	for r in n:
		for c in n:
			new_data[(n - 1 - c) * n + r] = _grid_data[r * n + c]
	_grid_data = new_data
	grid_changed.emit()
	queue_redraw()


## Invert: swap color 0 ↔ max, 1 ↔ max-1, etc.
func invert_colors() -> void:
	var max_idx := maxi(palette.size() - 1, 0)
	for i in _grid_data.size():
		_grid_data[i] = max_idx - _grid_data[i]
	grid_changed.emit()
	queue_redraw()


## Shift the entire grid left by one cell (wrapping).
func shift_left() -> void:
	var new_data := PackedByteArray()
	new_data.resize(_grid_data.size())
	for r in grid_rows:
		for c in grid_cols:
			var src_c := (c + 1) % grid_cols
			new_data[r * grid_cols + c] = _grid_data[r * grid_cols + src_c]
	_grid_data = new_data
	grid_changed.emit()
	queue_redraw()


## Shift the entire grid right by one cell (wrapping).
func shift_right() -> void:
	var new_data := PackedByteArray()
	new_data.resize(_grid_data.size())
	for r in grid_rows:
		for c in grid_cols:
			var src_c := (c - 1 + grid_cols) % grid_cols
			new_data[r * grid_cols + c] = _grid_data[r * grid_cols + src_c]
	_grid_data = new_data
	grid_changed.emit()
	queue_redraw()


## Shift the entire grid up by one cell (wrapping).
func shift_up() -> void:
	var new_data := PackedByteArray()
	new_data.resize(_grid_data.size())
	for r in grid_rows:
		var src_r := (r + 1) % grid_rows
		for c in grid_cols:
			new_data[r * grid_cols + c] = _grid_data[src_r * grid_cols + c]
	_grid_data = new_data
	grid_changed.emit()
	queue_redraw()


## Shift the entire grid down by one cell (wrapping).
func shift_down() -> void:
	var new_data := PackedByteArray()
	new_data.resize(_grid_data.size())
	for r in grid_rows:
		var src_r := (r - 1 + grid_rows) % grid_rows
		for c in grid_cols:
			new_data[r * grid_cols + c] = _grid_data[src_r * grid_cols + c]
	_grid_data = new_data
	grid_changed.emit()
	queue_redraw()


## Dispatch a named operation (called by OperationsBarWidget).
func execute_operation(action_name: String) -> void:
	match action_name:
		"mirror_x":    mirror_x()
		"mirror_y":    mirror_y()
		"rotate_cw":   rotate_cw()
		"rotate_ccw":  rotate_ccw()
		"invert":      invert_colors()
		"shift_l":     shift_left()
		"shift_r":     shift_right()
		"shift_u":     shift_up()
		"shift_d":     shift_down()
		"clear":       clear_grid()
		_:
			push_warning("ColorGridWidget: Unknown operation '%s'" % action_name)


# ── Drawing ─────────────────────────────────────────────────────

func _draw() -> void:
	if grid_rows <= 0 or grid_cols <= 0:
		return

	var cell_w := size.x / grid_cols
	var cell_h := size.y / grid_rows

	for r in grid_rows:
		for c in grid_cols:
			var color_idx: int = _grid_data[r * grid_cols + c]
			var color: Color = palette[color_idx] if color_idx < palette.size() else Color(0.2, 0.2, 0.2)
			var rect := Rect2(c * cell_w, r * cell_h, cell_w, cell_h)

			# Cell fill
			draw_rect(rect, color)

			# Grid lines
			draw_rect(rect, grid_line_color, false, 1.0)

	# Hover highlight (only on editable grids)
	if not read_only and _hover_cell.x >= 0 and _hover_cell.y >= 0:
		var hover_rect := Rect2(
			_hover_cell.x * cell_w, _hover_cell.y * cell_h, cell_w, cell_h
		)
		draw_rect(hover_rect, hover_color)

		# Show active color as small indicator in the hovered cell
		var indicator_size := minf(cell_w, cell_h) * 0.3
		var indicator_rect := Rect2(
			hover_rect.position.x + (cell_w - indicator_size) * 0.5,
			hover_rect.position.y + (cell_h - indicator_size) * 0.5,
			indicator_size, indicator_size
		)
		var active_col: Color = palette[active_color_index] if active_color_index < palette.size() else Color.WHITE
		draw_rect(indicator_rect, active_col)
		draw_rect(indicator_rect, selected_outline_color, false, 1.0)


# ── Input ───────────────────────────────────────────────────────

func _gui_input(event: InputEvent) -> void:
	if read_only:
		return

	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_painting = true
				var cell := _pixel_to_cell(mb.position)
				if cell.x >= 0:
					_apply_paint(cell)
				accept_event()
			else:
				_painting = false

		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			# Right-click: pick color from cell
			var cell := _pixel_to_cell(mb.position)
			if cell.x >= 0:
				active_color_index = get_cell(cell.y, cell.x)
				queue_redraw()
			accept_event()

	elif event is InputEventMouseMotion:
		var new_hover := _pixel_to_cell(event.position)
		if new_hover != _hover_cell:
			_hover_cell = new_hover
			queue_redraw()

		# Paint while dragging
		if _painting and new_hover.x >= 0:
			_apply_paint(new_hover)


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT:
		_hover_cell = Vector2i(-1, -1)
		_painting = false
		queue_redraw()


## Convert pixel position to (col, row). Returns (-1,-1) if out of bounds.
func _pixel_to_cell(pos: Vector2) -> Vector2i:
	if grid_rows <= 0 or grid_cols <= 0:
		return Vector2i(-1, -1)
	var cell_w := size.x / grid_cols
	var cell_h := size.y / grid_rows
	var col := int(pos.x / cell_w)
	var row := int(pos.y / cell_h)
	if col < 0 or col >= grid_cols or row < 0 or row >= grid_rows:
		return Vector2i(-1, -1)
	return Vector2i(col, row)  # (col, row) — x=col, y=row


func _apply_paint(cell: Vector2i) -> void:
	# cell.x = col, cell.y = row
	match click_mode:
		"paint":
			set_cell(cell.y, cell.x, active_color_index)
		"pick":
			active_color_index = get_cell(cell.y, cell.x)
			queue_redraw()
