extends RefCounted
class_name PaperAlgorithm

## Base class for all living paper algorithms.
## Override initialize() and step() to create a new paper cartridge.
## The paper manager calls step() each interval while the paper is grabbed.

## Called once when the paper is created. Set up initial state.
func initialize(img: Image, width: int, height: int) -> void:
	pass

## Called each tick while paper is held. Draw to img. Return false when done.
func step(img: Image, step_index: int) -> bool:
	return true

## Display name for the label
func get_name() -> String:
	return "Algorithm"

## Color scheme
func get_background_color() -> Color:
	return Color(0.05, 0.05, 0.08)

func get_primary_color() -> Color:
	return Color(1.0, 0.4, 0.7)  # Pink default

func get_secondary_color() -> Color:
	return Color(0.3, 0.8, 1.0)  # Cyan default

## How many initial steps to pre-draw (so paper isn't blank)
func get_initial_steps() -> int:
	return 30

## --- Drawing helpers (available to all cartridges) ---

static func set_pixel_safe(img: Image, x: int, y: int, color: Color) -> void:
	if x >= 0 and x < img.get_width() and y >= 0 and y < img.get_height():
		img.set_pixel(x, y, color)

static func draw_line(img: Image, from: Vector2i, to: Vector2i, color: Color) -> void:
	var x0 = from.x
	var y0 = from.y
	var x1 = to.x
	var y1 = to.y
	var dx = abs(x1 - x0)
	var sx = 1 if x0 < x1 else -1
	var dy = -abs(y1 - y0)
	var sy = 1 if y0 < y1 else -1
	var err = dx + dy
	while true:
		set_pixel_safe(img, x0, y0, color)
		if x0 == x1 and y0 == y1:
			break
		var e2 = 2 * err
		if e2 >= dy:
			err += dy
			x0 += sx
		if e2 <= dx:
			err += dx
			y0 += sy

static func fill_rect(img: Image, x: int, y: int, w: int, h: int, color: Color) -> void:
	for py in range(y, y + h):
		for px in range(x, x + w):
			set_pixel_safe(img, px, py, color)

static func draw_vertical_bar(img: Image, x: int, height_px: int, bar_width: int, img_height: int, color: Color) -> void:
	var y_start = img_height - height_px
	fill_rect(img, x, y_start, bar_width, height_px, color)

static func clear_column(img: Image, x: int, bar_width: int, bg_color: Color) -> void:
	fill_rect(img, x, 0, bar_width, img.get_height(), bg_color)
