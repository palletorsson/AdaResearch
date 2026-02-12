extends PaperAlgorithm
class_name PaperCA1D

## 1D Cellular Automata — Wolfram rules scrolling down the page.
## Each row is one generation. The paper fills top to bottom like a receipt printer.

var rule_number: int = 30
var _row: Array[int] = []
var _current_y: int = 0
var _w: int
var _h: int
var _color: Color
var _bg: Color

func _init(rule: int = 30) -> void:
	rule_number = rule

func get_name() -> String:
	return "Rule %d" % rule_number

func get_background_color() -> Color:
	match rule_number:
		30: return Color(0.02, 0.02, 0.06)
		110: return Color(0.04, 0.02, 0.06)
		90: return Color(0.02, 0.04, 0.06)
		_: return Color(0.03, 0.03, 0.06)

func get_primary_color() -> Color:
	match rule_number:
		30: return Color(1.0, 0.6, 0.1)   # Orange — chaos
		110: return Color(0.2, 1.0, 0.5)   # Green — computation
		90: return Color(0.6, 0.4, 1.0)    # Purple — Sierpinski
		_: return Color(1.0, 1.0, 1.0)

func get_initial_steps() -> int:
	return 40

func initialize(img: Image, width: int, height: int) -> void:
	_w = width
	_h = height
	_color = get_primary_color()
	_bg = get_background_color()
	_current_y = 0

	# Start with single cell in center
	_row.resize(width)
	_row.fill(0)
	_row[width / 2] = 1

	# Draw first row
	_draw_current_row(img)
	_current_y += 1

func step(img: Image, _step_index: int) -> bool:
	if _current_y >= _h:
		# Scroll up: shift image up by 1 pixel
		_scroll_up(img)
		_current_y = _h - 1

	# Compute next generation
	var new_row: Array[int] = []
	new_row.resize(_w)
	for x in range(_w):
		var left = _row[(x - 1 + _w) % _w]
		var center = _row[x]
		var right = _row[(x + 1) % _w]
		var pattern = (left << 2) | (center << 1) | right
		new_row[x] = 1 if (rule_number >> pattern) & 1 else 0
	_row = new_row

	_draw_current_row(img)
	_current_y += 1
	return true

func _draw_current_row(img: Image) -> void:
	for x in range(_w):
		if _row[x] == 1:
			set_pixel_safe(img, x, _current_y, _color)
		else:
			set_pixel_safe(img, x, _current_y, _bg)

func _scroll_up(img: Image) -> void:
	for y in range(1, _h):
		for x in range(_w):
			var pixel = img.get_pixel(x, y)
			img.set_pixel(x, y - 1, pixel)
	# Clear last row
	for x in range(_w):
		set_pixel_safe(img, x, _h - 1, _bg)
