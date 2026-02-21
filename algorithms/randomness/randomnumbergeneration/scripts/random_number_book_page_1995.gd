extends Node3D

## Live-cascading random number page inspired by the RAND Corporation's
## "A Million Random Digits" (1955).  Numbers scroll top-to-bottom like a
## stock ticker.  Touch any number in VR (poke) to freeze it in place —
## frozen numbers glow amber while the rest keep flowing.

@export var font_file: FontFile
@export var grid_width: int = 10   ## columns of 5-digit numbers
@export var grid_height: int = 28  ## visible rows
@export var number_spacing_y: float = 0.15
@export var cascade_speed: float = 1.0  ## rows per second (adjustable)

@onready var label3D: Label3D = $Label3D_Title
@onready var label3D_side_number: Label3D = $Label3D_Side_Number

# ── Per-cell state ──────────────────────────────────────────────────────
# _cells[row][col] = Label3D node
var _cells: Array = []           # Array[Array[Label3D]]
var _frozen: Array = []          # Array[Array[bool]]
var _cell_areas: Array = []      # Array[Array[Area3D]]  (VR touch zones)

# Cascade timing
var _cascade_timer: float = 0.0

# Colors
const COLOR_NORMAL := Color(0, 0, 0)
const COLOR_FROZEN := Color(0.85, 0.55, 0.05)  # Amber glow
const COLOR_FROZEN_OUTLINE := Color(1.0, 0.75, 0.1, 0.6)

var side_number: int
var start_index: int

func _ready() -> void:
	if font_file == null:
		push_error("[RandomNumberBook] Font file not assigned!")
		return

	side_number = randi_range(100, 999)
	label3D_side_number.text = str(side_number)
	start_index = int(side_number * (17600.0 / 353.0))

	_create_cell_grid()
	print("[RandomNumberBook] Live cascade started — %dx%d grid, speed %.1f rows/s" % [
		grid_width, grid_height, cascade_speed])

func _process(delta: float) -> void:
	_cascade_timer += delta * cascade_speed
	if _cascade_timer >= 1.0:
		_cascade_timer -= 1.0
		_cascade_step()

# ═══════════════════════════════════════════════════════════════════════
# GRID CREATION
# ═══════════════════════════════════════════════════════════════════════

func _create_cell_grid() -> void:
	_cells.resize(grid_height)
	_frozen.resize(grid_height)
	_cell_areas.resize(grid_height)

	var y_offset := -2.3
	for row in range(grid_height):
		_cells[row] = []
		_frozen[row] = []
		_cell_areas[row] = []
		(_cells[row] as Array).resize(grid_width)
		(_frozen[row] as Array).resize(grid_width)
		(_cell_areas[row] as Array).resize(grid_width)

		for col in range(grid_width):
			_frozen[row][col] = false

			# Position: index column takes ~0.7, then numbers spaced with cluster gaps
			var x_pos := _col_x_position(col)
			var cell_label := Label3D.new()
			cell_label.name = "Cell_%d_%d" % [row, col]
			cell_label.text = NumberHelper.random_5_digit_number()
			cell_label.font = font_file
			cell_label.font_size = 16
			cell_label.outline_size = 3
			cell_label.modulate = COLOR_NORMAL
			cell_label.position = Vector3(x_pos, -y_offset, -0.001)
			cell_label.rotate(Vector3(0, 1, 0), PI)
			add_child(cell_label)
			_cells[row][col] = cell_label

			# Touch area for VR interaction
			var area := _create_touch_area(cell_label, row, col)
			_cell_areas[row][col] = area

		# Row index label (left margin)
		var idx_label := Label3D.new()
		idx_label.name = "RowIdx_%d" % row
		idx_label.text = str(start_index + row)
		idx_label.font = font_file
		idx_label.font_size = 16
		idx_label.outline_size = 3
		idx_label.modulate = Color(0.3, 0.3, 0.3)
		idx_label.position = Vector3(1.7, -y_offset, -0.001)
		idx_label.rotate(Vector3(0, 1, 0), PI)
		add_child(idx_label)

		y_offset += number_spacing_y
		if (row + 1) % 5 == 0:
			y_offset += number_spacing_y * 1.2

func _col_x_position(col: int) -> float:
	## Map column index to X position, with cluster gaps every 2 columns.
	var base := 1.35  # right of row-index column
	var cell_width := 0.25
	var cluster_gap := 0.12
	var x := base - col * cell_width
	# Add gap after every 2nd column
	x -= int(col / 2) * cluster_gap
	return x

# ═══════════════════════════════════════════════════════════════════════
# TOUCH AREAS
# ═══════════════════════════════════════════════════════════════════════

func _create_touch_area(cell_label: Label3D, row: int, col: int) -> Area3D:
	var area := Area3D.new()
	area.name = "Touch_%d_%d" % [row, col]
	area.collision_layer = 0
	area.collision_mask = 393216  # VR hand layers (18+19)

	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.22, 0.12, 0.04)
	shape.shape = box
	area.add_child(shape)

	cell_label.add_child(area)
	area.position = Vector3(0, 0, 0.02)

	# Connect touch signal
	area.body_entered.connect(_on_cell_touched.bind(row, col))
	return area

func _on_cell_touched(_body: Node3D, row: int, col: int) -> void:
	# Toggle freeze state
	var is_frozen: bool = _frozen[row][col]
	_frozen[row][col] = not is_frozen
	_update_cell_visual(row, col)

func _update_cell_visual(row: int, col: int) -> void:
	var label: Label3D = _cells[row][col]
	if _frozen[row][col]:
		label.modulate = COLOR_FROZEN
		label.outline_modulate = COLOR_FROZEN_OUTLINE
		label.outline_size = 5
	else:
		label.modulate = COLOR_NORMAL
		label.outline_modulate = Color(0, 0, 0, 0)
		label.outline_size = 3

# ═══════════════════════════════════════════════════════════════════════
# CASCADE LOGIC
# ═══════════════════════════════════════════════════════════════════════

func _cascade_step() -> void:
	## Shift numbers down one row per column. Frozen cells stay put.
	## New random number appears at top of each column.
	for col in range(grid_width):
		# Walk bottom-up: move non-frozen values down into non-frozen slots
		# First, collect the column values and frozen state
		var values: Array[String] = []
		var frozen_flags: Array[bool] = []
		for row in range(grid_height):
			values.append((_cells[row][col] as Label3D).text)
			frozen_flags.append(_frozen[row][col])

		# Build new column: frozen cells keep their value and position,
		# non-frozen cells shift down (bottom falls off, top gets new random)
		var flowing: Array[String] = []
		for row in range(grid_height):
			if not frozen_flags[row]:
				flowing.append(values[row])

		# New number enters at top, bottom value falls off
		flowing.insert(0, NumberHelper.random_5_digit_number())
		if flowing.size() > 1:
			flowing.pop_back()  # Drop the bottom-most flowing value

		# Re-distribute flowing values into non-frozen slots
		var flow_idx := 0
		for row in range(grid_height):
			if not frozen_flags[row]:
				if flow_idx < flowing.size():
					(_cells[row][col] as Label3D).text = flowing[flow_idx]
					flow_idx += 1
