## Interactive binary (0/1) grid Control.
##
## Renders a grid of cells via _draw(), handles pointer input for
## toggle or exclusive_col click modes.  Used for threading, tieup,
## and treadling grids in the VR panel bridge.
##
## Set [member data_store] and [member data_path] before adding to tree.
## Connects to DraftDataStore.cell_changed to auto-repaint.
class_name BinaryGridWidget
extends Control

const P = preload("res://commons/ui/ada_palette.gd")

# ── Configuration (set by PanelContentBuilder from JSON metadata) ─

## The DraftDataStore this widget reads/writes.
var data_store: DraftDataStore

## Which matrix to access: "threading", "tieup", or "treadling"
var data_path: String = "threading"

## Grid dimensions (rows × cols of this widget's view).
var grid_rows: int = 4
var grid_cols: int = 24

## If true, row 0 of the data is drawn at the bottom (threading convention).
var flip_y: bool = false

## If true, data indices are transposed: get_cell(col, row) instead of (row, col).
var transposed: bool = false

## Click mode: "toggle" flips cells, "exclusive_col" sets one-per-row.
var click_mode: String = "toggle"

# ── Visual styling ──────────────────────────────────────────────

var cell_color_on: Color = P.ACCENT_CYAN
var cell_color_off: Color = Color(0.16, 0.18, 0.24)
var grid_line_color: Color = Color(0.30, 0.33, 0.40)
var hover_color: Color = Color(1.0, 1.0, 1.0, 0.25)

# ── Internal state ──────────────────────────────────────────────

var _hover_cell := Vector2i(-1, -1)

# ── Lifecycle ───────────────────────────────────────────────────

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	if data_store:
		data_store.cell_changed.connect(_on_cell_changed)


func setup(store: DraftDataStore, path: String, rows: int, cols: int,
		p_flip_y: bool = false, p_transposed: bool = false,
		p_click_mode: String = "toggle") -> void:
	data_store = store
	data_path = path
	grid_rows = rows
	grid_cols = cols
	flip_y = p_flip_y
	transposed = p_transposed
	click_mode = p_click_mode
	if data_store and not data_store.cell_changed.is_connected(_on_cell_changed):
		data_store.cell_changed.connect(_on_cell_changed)
	queue_redraw()


# ── Drawing ─────────────────────────────────────────────────────

func _draw() -> void:
	if not data_store or grid_rows <= 0 or grid_cols <= 0:
		return

	var cell_w := size.x / grid_cols
	var cell_h := size.y / grid_rows

	for r in grid_rows:
		# Visual row (flip_y draws data row 0 at bottom)
		var vis_r: int = (grid_rows - 1 - r) if flip_y else r

		for c in grid_cols:
			# Data access — optionally transposed
			var val: int
			if transposed:
				val = data_store.get_cell(data_path, c, r)
			else:
				val = data_store.get_cell(data_path, r, c)

			var rect := Rect2(c * cell_w, vis_r * cell_h, cell_w, cell_h)

			# Fill
			draw_rect(rect, cell_color_on if val else cell_color_off)

			# Grid lines
			draw_rect(rect, grid_line_color, false, 1.0)

	# Hover highlight
	if _hover_cell.x >= 0 and _hover_cell.y >= 0:
		var vis_r: int = (grid_rows - 1 - _hover_cell.y) if flip_y else _hover_cell.y
		var hover_rect := Rect2(
			_hover_cell.x * cell_w, vis_r * cell_h, cell_w, cell_h
		)
		draw_rect(hover_rect, hover_color)


# ── Input ───────────────────────────────────────────────────────

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			var cell := _pixel_to_cell(mb.position)
			if cell.x >= 0:
				_handle_click(cell)
				accept_event()

	elif event is InputEventMouseMotion:
		var new_hover := _pixel_to_cell(event.position)
		if new_hover != _hover_cell:
			_hover_cell = new_hover
			queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT:
		_hover_cell = Vector2i(-1, -1)
		queue_redraw()


## Convert pixel position to (col, data_row). Returns (-1,-1) if out of bounds.
func _pixel_to_cell(pos: Vector2) -> Vector2i:
	if grid_rows <= 0 or grid_cols <= 0:
		return Vector2i(-1, -1)
	var cell_w := size.x / grid_cols
	var cell_h := size.y / grid_rows
	var col := int(pos.x / cell_w)
	var vis_row := int(pos.y / cell_h)
	var data_row: int = (grid_rows - 1 - vis_row) if flip_y else vis_row

	if col < 0 or col >= grid_cols or data_row < 0 or data_row >= grid_rows:
		return Vector2i(-1, -1)
	return Vector2i(col, data_row)


func _handle_click(cell: Vector2i) -> void:
	if not data_store:
		return

	# Map widget (col, data_row) to store (row, col)
	var store_row: int
	var store_col: int
	if transposed:
		store_row = cell.x  # widget col → store row
		store_col = cell.y  # widget data_row → store col
	else:
		store_row = cell.y  # widget data_row → store row
		store_col = cell.x  # widget col → store col

	match click_mode:
		"toggle":
			data_store.toggle_cell(data_path, store_row, store_col)
		"exclusive_col":
			data_store.set_exclusive_col(data_path, store_row, store_col)


# ── Signal handler ──────────────────────────────────────────────

func _on_cell_changed(grid_id: String) -> void:
	if grid_id == data_path:
		queue_redraw()
