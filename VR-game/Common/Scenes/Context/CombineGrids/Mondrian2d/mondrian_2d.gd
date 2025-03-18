extends Node2D

# Mondrian color palette
const COLOR_WHITE = Color(0.95, 0.95, 0.95)
const COLOR_BLACK = Color(0.1, 0.1, 0.1)
const COLOR_RED = Color(0.9, 0.1, 0.1)
const COLOR_BLUE = Color(0.1, 0.1, 0.9)
const COLOR_YELLOW = Color(0.9, 0.9, 0.1)

# Canvas proportions - using the actual 60x55 ratio but filling the viewport
const LINE_THICKNESS = 8

# Lists to store grid lines and colored sections
var horizontal_lines = []
var vertical_lines = []
var colored_sections = []

# Viewport size (will be set in _ready)
var viewport_size = Vector2(600, 600)
var canvas_width = 0
var canvas_height = 0

func _ready():
	# Get the actual viewport size
	viewport_size = get_viewport_rect().size
	
	# Calculate canvas dimensions to maintain 60:55 aspect ratio
	# But fill the viewport completely (no empty space)
	if viewport_size.x / viewport_size.y > 60.0 / 55.0:
		# Viewport is wider than painting aspect ratio
		canvas_height = viewport_size.y
		canvas_width = canvas_height * (60.0 / 55.0)
	else:
		# Viewport is taller than painting aspect ratio
		canvas_width = viewport_size.x
		canvas_height = canvas_width * (55.0 / 60.0)
	
	# Center the canvas in the viewport
	position = (viewport_size - Vector2(canvas_width, canvas_height)) / 2
	
	# Create the Mondrian composition data
	define_grid_lines()
	define_colored_sections()
	
	# Call to draw will happen automatically through _draw

func define_grid_lines():
	# Define the horizontal grid lines based on the image
	# Format: {y_position, start_x, end_x}
	
	# Calculate positions based on canvas height
	var top_border = 0      # Top edge
	var first_horizontal = canvas_height * 0.33 # ~33% from top
	var second_horizontal = canvas_height * 0.66 # ~66% from top
	var bottom_border = canvas_height    # Bottom edge
	
	horizontal_lines = [
		# Horizontal lines from top to bottom
		{"y": top_border, "start_x": 0, "end_x": canvas_width},             # Top border
		{"y": first_horizontal, "start_x": 0, "end_x": canvas_width},       # First internal horizontal
		{"y": second_horizontal, "start_x": 0, "end_x": canvas_width},      # Second internal horizontal
		{"y": bottom_border, "start_x": 0, "end_x": canvas_width}           # Bottom border
	]
	
	# Define vertical grid lines
	# Calculate positions based on canvas width
	var left_border = 0       # Left edge
	var first_vertical = canvas_width * 0.16    # ~16% from left
	var second_vertical = canvas_width * 0.33    # ~33% from left
	var third_vertical = canvas_width * 0.5    # Middle (50%)
	var fourth_vertical = canvas_width * 0.66    # ~66% from left
	
	# Fibonacci-like sequence for right vertical lines
	var right_v1 = canvas_width * 0.75         # ~75% from left
	var right_v2 = canvas_width * 0.81         # ~81% from left
	var right_v3 = canvas_width * 0.87         # ~87% from left
	var right_v4 = canvas_width * 0.93         # ~93% from left
	var right_border = canvas_width            # Right edge
	
	vertical_lines = [
		# Main vertical lines from left to right
		{"x": left_border, "start_y": top_border, "end_y": bottom_border},      # Left border
		{"x": first_vertical, "start_y": top_border, "end_y": bottom_border},    # First internal vertical
		{"x": second_vertical, "start_y": top_border, "end_y": bottom_border},   # Second internal vertical
		{"x": third_vertical, "start_y": top_border, "end_y": bottom_border},    # Third internal vertical (middle)
		{"x": fourth_vertical, "start_y": top_border, "end_y": bottom_border},   # Fourth internal vertical
		
		# The closely spaced Fibonacci-like vertical lines on the right side
		{"x": right_v1, "start_y": top_border, "end_y": bottom_border},         # First narrow vertical
		{"x": right_v2, "start_y": top_border, "end_y": bottom_border},         # Second narrow vertical
		{"x": right_v3, "start_y": top_border, "end_y": bottom_border},         # Third narrow vertical
		{"x": right_v4, "start_y": top_border, "end_y": bottom_border},         # Fourth narrow vertical
		{"x": right_border, "start_y": top_border, "end_y": bottom_border}      # Right border
	]

func define_colored_sections():
	# Get grid positions for easy reference
	var top = horizontal_lines[0]["y"]
	var middle_top = horizontal_lines[1]["y"] 
	var middle_bottom = horizontal_lines[2]["y"]
	var bottom = horizontal_lines[3]["y"]
	
	var left = vertical_lines[0]["x"]
	var first_v = vertical_lines[1]["x"]
	var second_v = vertical_lines[2]["x"] 
	var middle = vertical_lines[3]["x"]
	var fourth_v = vertical_lines[4]["x"]
	var right_area = vertical_lines[5]["x"]  # Start of narrow streets
	
	# Define colored sections
	# Red sections - top right and bottom left
	colored_sections.append({
		"rect": Rect2(fourth_v, top, right_area - fourth_v, middle_top - top),  # Top-right red rectangle
		"color": COLOR_RED
	})
	
	colored_sections.append({
		"rect": Rect2(left, middle_top, first_v - left, middle_bottom - middle_top),  # Bottom-left red rectangle
		"color": COLOR_RED
	})
	
	# Blue section - top middle
	colored_sections.append({
		"rect": Rect2(second_v, top, middle - second_v, middle_top - top),  # Top-middle blue rectangle
		"color": COLOR_BLUE
	})
	
	# Yellow section - middle bottom
	colored_sections.append({
		"rect": Rect2(second_v, middle_bottom, middle - second_v, bottom - middle_bottom),  # Middle-bottom yellow rectangle
		"color": COLOR_YELLOW
	})

func _draw():
	# Draw white background for the entire canvas
	draw_rect(Rect2(0, 0, canvas_width, canvas_height), COLOR_WHITE, true)
	
	# Draw colored sections
	for section in colored_sections:
		draw_rect(section["rect"], section["color"], true)
	
	# Draw horizontal grid lines
	for line in horizontal_lines:
		draw_line(
			Vector2(line["start_x"], line["y"]), 
			Vector2(line["end_x"], line["y"]), 
			COLOR_BLACK, 
			LINE_THICKNESS
		)
	
	# Draw vertical grid lines
	for line in vertical_lines:
		draw_line(
			Vector2(line["x"], line["start_y"]), 
			Vector2(line["x"], line["end_y"]), 
			COLOR_BLACK, 
			LINE_THICKNESS
		)

# For animation/interaction
func animate_construction():
	# Temporarily store original data
	var original_horizontals = horizontal_lines.duplicate(true)
	var original_verticals = vertical_lines.duplicate(true)
	var original_colors = colored_sections.duplicate(true)
	
	# Clear everything
	horizontal_lines.clear()
	vertical_lines.clear()
	colored_sections.clear()
	queue_redraw()
	
	# Sequence with delays
	await get_tree().create_timer(0.5).timeout
	
	# Step 1: Draw horizontal lines
	horizontal_lines = original_horizontals.duplicate(true)
	queue_redraw()
	await get_tree().create_timer(0.5).timeout
	
	# Step 2: Draw vertical lines
	vertical_lines = original_verticals.duplicate(true)
	queue_redraw()
	await get_tree().create_timer(0.5).timeout
	
	# Step 3: Add red sections
	for section in original_colors:
		if section["color"] == COLOR_RED:
			colored_sections.append(section)
	queue_redraw()
	await get_tree().create_timer(0.5).timeout
	
	# Step 4: Add blue sections
	for section in original_colors:
		if section["color"] == COLOR_BLUE:
			colored_sections.append(section)
	queue_redraw()
	await get_tree().create_timer(0.5).timeout
	
	# Step 5: Add yellow section
	for section in original_colors:
		if section["color"] == COLOR_YELLOW:
			colored_sections.append(section)
	queue_redraw()
