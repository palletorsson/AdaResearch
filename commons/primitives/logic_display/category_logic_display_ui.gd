extends Control

# Colors - Black & White Scheme
const BG_COLOR = Color(0.0, 0.0, 0.0, 1.0)
const FG_COLOR = Color(1.0, 1.0, 1.0, 1.0) # White

# Drawing Config
const ITEM_SPACING = 80.0
const SYMBOL_SIZE = 40.0
const STROKE_WIDTH = 4.0

# Current equation to display
var equation_items: Array = []

func _ready() -> void:
	# Default size matches standard InfoBoard viewport
	custom_minimum_size = Vector2(1024, 256)

func set_equation(items: Array) -> void:
	equation_items = items
	queue_redraw()

func _draw() -> void:
	if equation_items.is_empty():
		return
		
	# Calculate total width to center the equation
	var total_width = (equation_items.size() * SYMBOL_SIZE) + ((equation_items.size() - 1) * ITEM_SPACING)
	var start_x = (size.x - total_width) / 2.0
	var center_y = size.y / 2.0
	
	for i in range(equation_items.size()):
		var item_type = equation_items[i]
		var center_pos = Vector2(start_x + (i * (SYMBOL_SIZE + ITEM_SPACING)) + (SYMBOL_SIZE / 2.0), center_y)
		
		# Draw based on type
		match item_type:
			"point":
				draw_point(center_pos)
			"line":
				draw_logic_line(center_pos)
			"plus":
				draw_plus(center_pos)
			"arrow":
				draw_arrow(center_pos)
			"triangle":
				draw_triangle(center_pos)
			"cross":
				draw_cross(center_pos)
			"parallel":
				draw_parallel(center_pos)
			"quad":
				draw_quad(center_pos)
			"equals":
				draw_equals(center_pos)
			"times":
				draw_times(center_pos)
			"tetrahedron":
				draw_tetrahedron(center_pos)
			"pyramid":
				draw_pyramid(center_pos)
			"octahedron":
				draw_octahedron(center_pos)
			"wedge":
				draw_wedge(center_pos)
			_:
				# Fallback text
				draw_string(get_theme_default_font(), center_pos, str(item_type), HORIZONTAL_ALIGNMENT_CENTER, -1, 16, FG_COLOR)

func draw_quad(center: Vector2) -> void:
	var half = SYMBOL_SIZE * 0.4
	# Square
	var p1 = center + Vector2(-half, -half)
	var p2 = center + Vector2(half, -half)
	var p3 = center + Vector2(half, half)
	var p4 = center + Vector2(-half, half)
	
	var points = PackedVector2Array([p1, p2, p3, p4, p1]) # Closed loop
	draw_polyline(points, FG_COLOR, STROKE_WIDTH)

func draw_cross(center: Vector2) -> void:
	var radius = SYMBOL_SIZE * 0.4
	# Draw X shape
	var p1 = center + Vector2(-radius, -radius)
	var p2 = center + Vector2(radius, radius)
	var p3 = center + Vector2(-radius, radius)
	var p4 = center + Vector2(radius, -radius)
	
	draw_line(p1, p2, FG_COLOR, STROKE_WIDTH)
	draw_line(p3, p4, FG_COLOR, STROKE_WIDTH)

func draw_parallel(center: Vector2) -> void:
	var half_h = SYMBOL_SIZE * 0.4
	var half_w = SYMBOL_SIZE * 0.3
	
	# Two vertical-ish lines (slanted slightly)
	var p1 = center + Vector2(-half_w, -half_h)
	var p2 = center + Vector2(-half_w, half_h)
	var p3 = center + Vector2(half_w, -half_h)
	var p4 = center + Vector2(half_w, half_h)
	
	draw_line(p1, p2, FG_COLOR, STROKE_WIDTH)
	draw_line(p3, p4, FG_COLOR, STROKE_WIDTH)

func draw_point(center: Vector2) -> void:
	# Draw filled circle
	draw_circle(center, SYMBOL_SIZE * 0.4, FG_COLOR)

func draw_logic_line(center: Vector2) -> void:
	# Draw horizontal line segment
	var half_len = SYMBOL_SIZE * 0.8
	var start = center - Vector2(half_len, 0)
	var end = center + Vector2(half_len, 0)
	
	draw_line(start, end, FG_COLOR, STROKE_WIDTH * 1.5)
	
	# Optional: draw small dots at ends to emphasize "from point to point"
	draw_circle(start, STROKE_WIDTH * 1.2, FG_COLOR)
	draw_circle(end, STROKE_WIDTH * 1.2, FG_COLOR)

func draw_plus(center: Vector2) -> void:
	var half_size = SYMBOL_SIZE * 0.3
	
	# Horizontal
	draw_line(center - Vector2(half_size, 0), center + Vector2(half_size, 0), FG_COLOR, STROKE_WIDTH)
	# Vertical
	draw_line(center - Vector2(0, half_size), center + Vector2(0, half_size), FG_COLOR, STROKE_WIDTH)

func draw_arrow(center: Vector2) -> void:
	var half_len = SYMBOL_SIZE * 0.6
	var start = center - Vector2(half_len, 0)
	var end = center + Vector2(half_len, 0)
	
	# Main shaft
	draw_line(start, end, FG_COLOR, STROKE_WIDTH)
	
	# Arrowhead
	var head_size = SYMBOL_SIZE * 0.25
	var angle = PI / 6 # 30 degrees
	var p1 = end - Vector2(head_size * cos(angle), head_size * sin(angle))
	var p2 = end - Vector2(head_size * cos(angle), -head_size * sin(angle))
	
	var points = PackedVector2Array([end, p1, p2])
	draw_colored_polygon(points, FG_COLOR)

func draw_triangle(center: Vector2) -> void:
	var radius = SYMBOL_SIZE * 0.5
	# Equilateral triangle pointing up
	var p1 = center + Vector2(0, -radius)
	var p2 = center + Vector2(radius * 0.866, radius * 0.5)
	var p3 = center + Vector2(-radius * 0.866, radius * 0.5)
	
	var points = PackedVector2Array([p1, p2, p3])
	# Draw outline with thickness
	draw_polyline(points, FG_COLOR, STROKE_WIDTH, true) # true = closed

func draw_equals(center: Vector2) -> void:
	var half_w = SYMBOL_SIZE * 0.3
	var half_h = SYMBOL_SIZE * 0.15
	
	# Top line
	draw_line(center + Vector2(-half_w, -half_h), center + Vector2(half_w, -half_h), FG_COLOR, STROKE_WIDTH)
	# Bottom line
	draw_line(center + Vector2(-half_w, half_h), center + Vector2(half_w, half_h), FG_COLOR, STROKE_WIDTH)

func draw_times(center: Vector2) -> void:
	var radius = SYMBOL_SIZE * 0.25
	# Small x for multiplication
	var p1 = center + Vector2(-radius, -radius)
	var p2 = center + Vector2(radius, radius)
	var p3 = center + Vector2(-radius, radius)
	var p4 = center + Vector2(radius, -radius)
	
	draw_line(p1, p2, FG_COLOR, STROKE_WIDTH)
	draw_line(p3, p4, FG_COLOR, STROKE_WIDTH)

func draw_tetrahedron(center: Vector2) -> void:
	var radius = SYMBOL_SIZE * 0.5
	var top = center + Vector2(0, -radius)
	var left = center + Vector2(-radius * 0.8, radius * 0.5)
	var right = center + Vector2(radius * 0.8, radius * 0.5)
	var mid = center + Vector2(0, radius * 0.1) # Internal vertex
	
	# Outline
	var points = PackedVector2Array([top, left, right, top])
	draw_polyline(points, FG_COLOR, STROKE_WIDTH)
	
	# Internal edges
	draw_line(top, mid, FG_COLOR, STROKE_WIDTH)
	draw_line(left, mid, FG_COLOR, STROKE_WIDTH)
	draw_line(right, mid, FG_COLOR, STROKE_WIDTH)

func draw_pyramid(center: Vector2) -> void:
	var radius = SYMBOL_SIZE * 0.5
	var top = center + Vector2(0, -radius)
	var bl = center + Vector2(-radius * 0.8, radius * 0.6) # Bottom left
	var br = center + Vector2(radius * 0.8, radius * 0.6) # Bottom right
	var bm = center + Vector2(radius * 0.3, radius * 0.3) # Back/mid corner hint
	
	# Outline triangle
	draw_line(top, bl, FG_COLOR, STROKE_WIDTH)
	draw_line(top, br, FG_COLOR, STROKE_WIDTH)
	draw_line(bl, br, FG_COLOR, STROKE_WIDTH)
	
	# Side face edge
	draw_line(top, bm, FG_COLOR, STROKE_WIDTH)
	draw_line(br, bm, FG_COLOR, STROKE_WIDTH)

func draw_octahedron(center: Vector2) -> void:
	var h = SYMBOL_SIZE * 0.5
	var w = SYMBOL_SIZE * 0.4
	var top = center + Vector2(0, -h)
	var bottom = center + Vector2(0, h)
	var left = center + Vector2(-w, 0)
	var right = center + Vector2(w, 0)
	var front = center + Vector2(0, h * 0.2)
	
	# Outline diamond
	var points = PackedVector2Array([top, right, bottom, left, top])
	draw_polyline(points, FG_COLOR, STROKE_WIDTH)
	
	# Cross lines
	draw_line(left, right, FG_COLOR, STROKE_WIDTH)
	draw_line(top, front, FG_COLOR, STROKE_WIDTH)
	draw_line(bottom, front, FG_COLOR, STROKE_WIDTH)
	draw_line(right, front, FG_COLOR, STROKE_WIDTH)
	draw_line(left, front, FG_COLOR, STROKE_WIDTH)

func draw_wedge(center: Vector2) -> void:
	var w = SYMBOL_SIZE * 0.4
	var h = SYMBOL_SIZE * 0.3
	
	# Wedge shape (triangular prism on side)
	var dl = center + Vector2(-w, h) # Down Left
	var dr = center + Vector2(w, h) # Down Right
	var ul = center + Vector2(-w, -h) # Up Left
	var ur = center + Vector2(w * 0.5, -h * 0.5) # Up Right (back)
	
	# Front face
	var front_points = PackedVector2Array([ul, dl, dr, ul])
	draw_polyline(front_points, FG_COLOR, STROKE_WIDTH)
	
	# Top/Side lines
	draw_line(ul, ur, FG_COLOR, STROKE_WIDTH)
	draw_line(dr, ur, FG_COLOR, STROKE_WIDTH)
	draw_line(ur, dl, FG_COLOR, STROKE_WIDTH) # Diagonal cross
