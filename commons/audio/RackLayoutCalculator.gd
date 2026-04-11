# RackLayoutCalculator.gd
# Uses 2D Control layout logic as a blueprint for 3D rack positioning
# Converts pixel-based 2D layouts to meter-based 3D positions

class_name RackLayoutCalculator
extends RefCounted

## Scale factor: how many pixels = 1 meter
## Default: 500px = 0.5m (so rack fits comfortably)
const PIXELS_PER_METER: float = 1000.0

## 2D control sizes in PIXELS (easy to visualize)
## These match common UI element sizes
const CONTROL_SIZES_PX := {
	# Sliders
	"slider": Vector2(60, 180),      # Vertical fader
	"slv": Vector2(60, 180),         # Vertical fader
	"slh": Vector2(180, 50),         # Horizontal fader
	"sls": Vector2(60, 180),         # Snap slider
	"slz": Vector2(60, 180),         # Zero-centered slider

	# Rotary
	"knob": Vector2(80, 100),        # Knob with label below
	"wheel": Vector2(100, 100),      # Scroll wheel

	# 2D Controls
	"xy": Vector2(140, 140),         # XY pad
	"joystick": Vector2(120, 120),   # Joystick
	"js": Vector2(120, 120),         # Joystick alias

	# Buttons
	"btn": Vector2(70, 50),          # Push button
	"button": Vector2(70, 50),
	"lever": Vector2(60, 120),       # Lever/switch
	"lv": Vector2(60, 120),

	# Displays
	"monitor": Vector2(280, 180),    # Waveform monitor
	"spectrum": Vector2(280, 200),   # Spectrum analyzer
	"waveform": Vector2(280, 200),   # Waveform display
	"simple_waveform": Vector2(200, 100),
	"lissajous": Vector2(200, 200),  # XY scope

	# Meters
	"meter": Vector2(30, 120),       # VU meter
	"mtr": Vector2(30, 120),

	# Labels
	"label": Vector2(120, 30),       # Text label
	"lbl": Vector2(120, 30),

	# Containers
	"group": Vector2(200, 150),
	"grp": Vector2(200, 150),

	# Dividers
	"divider": Vector2(4, 120),
	"div": Vector2(4, 120),

	# Default
	"default": Vector2(80, 80)
}

## Layout result structure
class LayoutResult:
	var positions: Dictionary = {}  # control_id -> Vector3
	var sizes: Dictionary = {}      # control_id -> Vector2 (width, height in meters)
	var total_width: float = 0.0    # Total rack width in meters
	var total_height: float = 0.0   # Total rack height in meters
	var cell_positions: Array = []  # For debug: [row][col] -> Rect2

## Calculate 3D positions from rack config
static func calculate_layout(rack_config: Dictionary) -> LayoutResult:
	var result = LayoutResult.new()

	if not rack_config.has("grid") or not rack_config.has("control_definitions"):
		return result

	var grid: Array = rack_config["grid"]
	var control_defs: Dictionary = rack_config["control_definitions"]
	var layout_settings: Dictionary = rack_config.get("layout", {})

	# Get layout parameters
	var padding_px: float = layout_settings.get("padding_px", 12.0)
	var gap_px: float = layout_settings.get("gap_px", 10.0)
	var vr_scale: float = layout_settings.get("vr_scale", 1.0)

	# Legacy support: convert meter-based values to pixels
	if layout_settings.has("padding"):
		padding_px = layout_settings["padding"] * PIXELS_PER_METER
	if layout_settings.has("gap"):
		gap_px = layout_settings["gap"] * PIXELS_PER_METER

	# First pass: calculate row heights and column widths in pixels
	var row_heights_px: Array[float] = []
	var col_widths_px: Array[float] = []
	var num_cols: int = 0

	for row_idx in range(grid.size()):
		var row: Array = grid[row_idx]
		num_cols = max(num_cols, row.size())
		var max_height_px: float = 40.0 * vr_scale  # Minimum row height

		for col_idx in range(row.size()):
			var control_id: String = str(row[col_idx])
			if control_id.is_empty() or control_id == " ":
				continue

			if control_defs.has(control_id):
				var control_type: String = control_defs[control_id].get("type", "default")
				var size_px: Vector2 = _get_control_size_px(control_type, control_defs[control_id]) * vr_scale
				max_height_px = max(max_height_px, size_px.y)

				# Expand col_widths array if needed (size_px already scaled by vr_scale)
				while col_widths_px.size() <= col_idx:
					col_widths_px.append(40.0 * vr_scale)
				col_widths_px[col_idx] = max(col_widths_px[col_idx], size_px.x)

		row_heights_px.append(max_height_px)

	# Ensure col_widths covers all columns
	while col_widths_px.size() < num_cols:
		col_widths_px.append(40.0)

	# Calculate total dimensions in pixels
	var total_width_px: float = padding_px * 2.0
	for w in col_widths_px:
		total_width_px += w
	total_width_px += gap_px * max(0, col_widths_px.size() - 1)

	var total_height_px: float = padding_px * 2.0
	for h in row_heights_px:
		total_height_px += h
	total_height_px += gap_px * max(0, row_heights_px.size() - 1)

	# Convert to meters
	result.total_width = total_width_px / PIXELS_PER_METER
	result.total_height = total_height_px / PIXELS_PER_METER

	# Second pass: calculate positions
	var y_px: float = padding_px

	for row_idx in range(grid.size()):
		var row: Array = grid[row_idx]
		var x_px: float = padding_px
		var row_height_px: float = row_heights_px[row_idx] if row_idx < row_heights_px.size() else 40.0
		var row_positions: Array = []

		for col_idx in range(row.size()):
			var control_id: String = str(row[col_idx])
			var col_width_px: float = col_widths_px[col_idx] if col_idx < col_widths_px.size() else 40.0

			# Store cell rect for debug
			row_positions.append(Rect2(x_px, y_px, col_width_px, row_height_px))

			if not control_id.is_empty() and control_id != " " and control_defs.has(control_id):
				var control_type: String = control_defs[control_id].get("type", "default")
				var size_px: Vector2 = _get_control_size_px(control_type, control_defs[control_id]) * vr_scale

				# Center control within cell
				var center_x_px: float = x_px + (col_width_px - size_px.x) / 2.0 + size_px.x / 2.0
				var center_y_px: float = y_px + (row_height_px - size_px.y) / 2.0 + size_px.y / 2.0

				# Convert to 3D coordinates (meters)
				# X: left to right
				# Y: top to bottom (inverted, so negative)
				# Z: forward from rack face
				var pos_3d = Vector3(
					center_x_px / PIXELS_PER_METER,
					-center_y_px / PIXELS_PER_METER,
					0.03  # Slight forward offset
				)

				result.positions[control_id] = pos_3d
				result.sizes[control_id] = size_px / PIXELS_PER_METER

			x_px += col_width_px + gap_px

		result.cell_positions.append(row_positions)
		y_px += row_height_px + gap_px

	# Center the layout (so origin is at rack center)
	var offset_x: float = result.total_width / 2.0
	var offset_y: float = result.total_height / 2.0

	for control_id in result.positions.keys():
		var pos: Vector3 = result.positions[control_id]
		result.positions[control_id] = Vector3(
			pos.x - offset_x,
			pos.y + offset_y,  # Already negative, so add to center
			pos.z
		)

	return result

## Get control size in pixels, with override support
static func _get_control_size_px(control_type: String, config: Dictionary) -> Vector2:
	# Check for explicit size override in config
	if config.has("width_px") and config.has("height_px"):
		return Vector2(config["width_px"], config["height_px"])

	# Check for size multiplier
	var size: Vector2 = CONTROL_SIZES_PX.get(control_type, CONTROL_SIZES_PX["default"])

	if config.has("size_scale"):
		var scale: float = config["size_scale"]
		size *= scale

	# Legacy: convert meter-based size to pixels
	if config.has("width"):
		size.x = config["width"] * PIXELS_PER_METER
	if config.has("height"):
		size.y = config["height"] * PIXELS_PER_METER
	if config.has("size"):
		var s: float = config["size"] * PIXELS_PER_METER
		size = Vector2(s, s)

	return size

## Generate a debug 2D preview Control (for testing layouts)
static func create_debug_preview(rack_config: Dictionary) -> Control:
	var result = calculate_layout(rack_config)

	var container = Control.new()
	container.custom_minimum_size = Vector2(
		result.total_width * PIXELS_PER_METER,
		result.total_height * PIXELS_PER_METER
	)

	# Background
	var bg = ColorRect.new()
	bg.color = Color(0.1, 0.1, 0.12)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.add_child(bg)

	# Draw cells
	var control_defs: Dictionary = rack_config.get("control_definitions", {})
	var grid: Array = rack_config.get("grid", [])

	for row_idx in range(result.cell_positions.size()):
		for col_idx in range(result.cell_positions[row_idx].size()):
			var cell_rect: Rect2 = result.cell_positions[row_idx][col_idx]

			# Cell background
			var cell_bg = ColorRect.new()
			cell_bg.position = cell_rect.position
			cell_bg.size = cell_rect.size
			cell_bg.color = Color(0.15, 0.15, 0.18, 0.5)
			container.add_child(cell_bg)

			# Control placeholder
			if row_idx < grid.size() and col_idx < grid[row_idx].size():
				var control_id: String = str(grid[row_idx][col_idx])
				if not control_id.is_empty() and control_id != " " and control_defs.has(control_id):
					var config: Dictionary = control_defs[control_id]
					var control_type: String = config.get("type", "default")
					var size_px: Vector2 = _get_control_size_px(control_type, config)

					var ctrl_rect = ColorRect.new()
					ctrl_rect.size = size_px
					ctrl_rect.position = cell_rect.position + (cell_rect.size - size_px) / 2.0
					ctrl_rect.color = _get_type_color(control_type)
					container.add_child(ctrl_rect)

					# Label
					var label = Label.new()
					label.text = control_id
					label.position = ctrl_rect.position + Vector2(2, 2)
					label.add_theme_font_size_override("font_size", 10)
					container.add_child(label)

	return container

## Get debug color for control type
static func _get_type_color(control_type: String) -> Color:
	match control_type:
		"slider", "slv", "slh", "sls", "slz":
			return Color(0.3, 0.6, 0.9, 0.8)  # Blue for sliders
		"knob", "wheel":
			return Color(0.9, 0.6, 0.3, 0.8)  # Orange for rotary
		"xy", "joystick", "js":
			return Color(0.6, 0.3, 0.9, 0.8)  # Purple for 2D
		"btn", "button", "lever", "lv":
			return Color(0.9, 0.3, 0.3, 0.8)  # Red for buttons
		"monitor", "spectrum", "waveform", "lissajous", "simple_waveform":
			return Color(0.3, 0.8, 0.5, 0.8)  # Green for displays
		"meter", "mtr":
			return Color(0.8, 0.8, 0.3, 0.8)  # Yellow for meters
		"label", "lbl":
			return Color(0.5, 0.5, 0.5, 0.6)  # Gray for labels
		"divider", "div":
			return Color(0.4, 0.4, 0.5, 0.4)  # Dim for dividers
		_:
			return Color(0.4, 0.4, 0.4, 0.7)
