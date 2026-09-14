## Colored read-only drawdown grid Control.
##
## Renders the computed drawdown from a DraftDataStore using per-cell
## warp/weft colors.  Read-only — no click interaction.
## Listens to [signal DraftDataStore.drawdown_changed] to auto-repaint.
class_name DrawdownWidget
extends Control

const P = preload("res://commons/ui/ada_palette.gd")

# ── Configuration ───────────────────────────────────────────────

## The DraftDataStore this widget reads.
var data_store: DraftDataStore

## Grid dimensions (picks × warps).
var grid_rows: int = 24   # picks
var grid_cols: int = 24   # warps

## If true, pick 0 is drawn at the bottom.
var flip_y: bool = true

# ── Visual styling ──────────────────────────────────────────────

var grid_line_color: Color = Color(0.22, 0.24, 0.30, 0.6)

# ── Lifecycle ───────────────────────────────────────────────────

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if data_store:
		_connect_signals()


func setup(store: DraftDataStore, rows: int, cols: int, p_flip_y: bool = true) -> void:
	data_store = store
	grid_rows = rows
	grid_cols = cols
	flip_y = p_flip_y
	_connect_signals()
	queue_redraw()


func _connect_signals() -> void:
	if not data_store:
		return
	if not data_store.drawdown_changed.is_connected(_on_drawdown_changed):
		data_store.drawdown_changed.connect(_on_drawdown_changed)
	if not data_store.colors_changed.is_connected(_on_drawdown_changed):
		data_store.colors_changed.connect(_on_drawdown_changed)


# ── Drawing ─────────────────────────────────────────────────────

func _draw() -> void:
	if not data_store or grid_rows <= 0 or grid_cols <= 0:
		return

	var cell_w := size.x / grid_cols
	var cell_h := size.y / grid_rows

	for pick in grid_rows:
		var vis_r: int = (grid_rows - 1 - pick) if flip_y else pick

		for warp in grid_cols:
			var color := data_store.get_drawdown_color(pick, warp)
			var rect := Rect2(warp * cell_w, vis_r * cell_h, cell_w, cell_h)

			# Cell fill with resolved warp/weft color
			draw_rect(rect, color)

			# Subtle grid lines
			draw_rect(rect, grid_line_color, false, 0.5)


# ── Signal handler ──────────────────────────────────────────────

func _on_drawdown_changed() -> void:
	queue_redraw()
