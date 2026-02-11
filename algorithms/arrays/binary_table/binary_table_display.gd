# binary_table_display.gd - Show array data as a grid of values (1s and 0s)
# Arrays made visible - see the data structure behind the visualization
extends Node3D
class_name BinaryTableDisplay

@export var rows: int = 4
@export var cols: int = 4
@export var cell_size: float = 0.08
@export var font_size: int = 24
@export var show_indices: bool = true
@export var title: String = ""

# Data to display
var data: Array = []

# Internal references
var _labels: Array = []  # Grid of Label3D nodes
var _panel: MeshInstance3D  # Background panel
var _title_label: Label3D
var _row_labels: Array = []  # Row index labels
var _col_labels: Array = []  # Column index labels

func _ready() -> void:
	if data.is_empty():
		# Default: create empty grid based on rows/cols
		data = []
		for r in range(rows):
			var row_data: Array = []
			for c in range(cols):
				row_data.append(0)
			data.append(row_data)
	_create_display()

func set_data(new_data: Array) -> void:
	data = new_data
	if data.size() > 0:
		rows = data.size()
		cols = data[0].size() if data[0] is Array else 1
	_rebuild_display()

func set_cell(row: int, col: int, value) -> void:
	if row >= 0 and row < data.size():
		if col >= 0 and col < data[row].size():
			data[row][col] = value
			_update_cell_label(row, col)

func _create_display() -> void:
	# Create background panel
	_panel = MeshInstance3D.new()
	_panel.name = "BackgroundPanel"
	var quad = QuadMesh.new()

	var panel_width = cols * cell_size + (0.15 if show_indices else 0.05)
	var panel_height = rows * cell_size + (0.15 if show_indices else 0.05)
	if title != "":
		panel_height += 0.08
	quad.size = Vector2(panel_width, panel_height)
	_panel.mesh = quad

	# Light semi-transparent background
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.25, 0.25, 0.30, 0.75)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_panel.material_override = mat
	add_child(_panel)

	# Title label
	if title != "":
		_title_label = Label3D.new()
		_title_label.name = "TitleLabel"
		_title_label.text = title
		_title_label.font_size = font_size + 8
		_title_label.pixel_size = 0.002
		_title_label.position = Vector3(0, panel_height / 2.0 - 0.04, 0.01)
		_title_label.modulate = Color(0.9, 0.95, 1.0)
		_title_label.outline_size = 0
		add_child(_title_label)

	# Offset for index labels
	var offset_x = -0.05 if show_indices else 0.0
	var offset_y = 0.05 if show_indices else 0.0
	if title != "":
		offset_y += 0.04

	# Create column index labels (top)
	if show_indices:
		for c in range(cols):
			var label = Label3D.new()
			label.name = "ColLabel_%d" % c
			label.text = str(c)
			label.font_size = font_size - 4
			label.pixel_size = 0.002
			label.position = Vector3(
				(c - cols / 2.0 + 0.5) * cell_size + offset_x,
				(rows / 2.0 + 0.3) * cell_size - offset_y,
				0.01
			)
			label.modulate = Color(0.6, 0.7, 0.8)
			label.outline_size = 0
			add_child(label)
			_col_labels.append(label)

	# Create row index labels (left) and data labels
	_labels = []
	for r in range(rows):
		# Row index label
		if show_indices:
			var row_label = Label3D.new()
			row_label.name = "RowLabel_%d" % r
			row_label.text = str(r)
			row_label.font_size = font_size - 4
			row_label.pixel_size = 0.002
			row_label.position = Vector3(
				(-cols / 2.0 - 0.3) * cell_size + offset_x,
				(rows / 2.0 - r - 0.5) * cell_size - offset_y,
				0.01
			)
			row_label.modulate = Color(0.6, 0.7, 0.8)
			row_label.outline_size = 0
			add_child(row_label)
			_row_labels.append(row_label)

		# Data labels for this row
		var row_labels: Array = []
		for c in range(cols):
			var label = Label3D.new()
			label.name = "Cell_%d_%d" % [r, c]
			label.font_size = font_size
			label.pixel_size = 0.002
			label.position = Vector3(
				(c - cols / 2.0 + 0.5) * cell_size + offset_x,
				(rows / 2.0 - r - 0.5) * cell_size - offset_y,
				0.01
			)
			label.outline_size = 0

			# Get value and set text/color
			var val = _get_value(r, c)
			label.text = _format_value(val)
			label.modulate = _get_color(val)

			add_child(label)
			row_labels.append(label)
		_labels.append(row_labels)

func _rebuild_display() -> void:
	# Remove old children
	for child in get_children():
		child.queue_free()
	_labels.clear()
	_row_labels.clear()
	_col_labels.clear()

	# Rebuild
	call_deferred("_create_display")

func _update_cell_label(row: int, col: int) -> void:
	if row < _labels.size() and col < _labels[row].size():
		var val = _get_value(row, col)
		_labels[row][col].text = _format_value(val)
		_labels[row][col].modulate = _get_color(val)

func _get_value(row: int, col: int):
	if row < data.size():
		var row_data = data[row]
		if row_data is Array and col < row_data.size():
			return row_data[col]
	return 0

func _format_value(val) -> String:
	if val is float:
		if val == int(val):
			return str(int(val))
		return "%.1f" % val
	return str(val)

func _get_color(val) -> Color:
	# Color coding for different values - high visibility
	if val is int or val is float:
		if val == 0:
			return Color(0.9, 0.5, 0.5)  # Light red for 0 - clearly visible
		elif val == 1:
			return Color(0.3, 1.0, 0.4)  # Green for 1
		elif val > 1:
			return Color(1.0, 0.9, 0.3)  # Yellow for > 1
		else:
			return Color(0.3, 0.7, 1.0)  # Blue for negative/fractional
	return Color(0.9, 0.9, 0.95)  # White for other

# =============================================================================
# GRID SYSTEM INTEGRATION
# =============================================================================

func apply_grid_config(config: Dictionary) -> void:
	if config.has("rows"):
		rows = config["rows"]
	if config.has("cols"):
		cols = config["cols"]
	if config.has("cell_size"):
		cell_size = config["cell_size"]
	if config.has("title"):
		title = config["title"]
	if config.has("show_indices"):
		show_indices = config["show_indices"]
	if config.has("data") and config["data"] is Array:
		data = config["data"]

	_rebuild_display()
