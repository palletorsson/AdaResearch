extends Control

var visualization_type = "intro"
# Constants for visualization
const CIRCLE_RADIUS = 100
const GRAPH_WIDTH = 400
const GRAPH_HEIGHT = 200
const WAVE_SEGMENTS = 120
const WAVE_AMPLITUDE = 80
const TIME_SCALE = 3.0  # Controls how many wave cycles are shown

# Visual styling constants
const CELL_SIZE := Vector2(40, 40)
const CELL_MARGIN := Vector2(5, 5)
const GRID_OFFSET := Vector2(50, 50)
const COLOR_1D := Color(0.2, 0.6, 0.8, 0.8)
const COLOR_2D := Color(0.8, 0.4, 0.2, 0.8)
const COLOR_3D := Color(0.4, 0.8, 0.4, 0.8)
const COLOR_HIGHLIGHT := Color(1.0, 0.9, 0.2, 0.8)
const BG_COLOR := Color(0.15, 0.15, 0.2)

# Variables for interactive elements
var current_page := 0
var total_pages := 5
var unit_circle_point := Vector2(CIRCLE_RADIUS, 0)
var angle := 0.0
var animation_speed := 2.0
var animation_playing := true
var animation_step := 0
var animation_timer := 0.0
var step_duration := 0.8  # Time between animation steps

# Array data structures
var array_1d := [1, 2, 3, 4, 5, 6, 7, 8]
var array_2d := [
	[1, 2, 3, 4],
	[5, 6, 7, 8],
	[9, 10, 11, 12]
]
var array_3d := []  # Will be initialized in _ready


func _ready():
	# Initialize 3D array data
	_initialize_3d_array()
	
func _initialize_3d_array():
	# Create a 3x3x3 3D array
	array_3d = []
	for z in range(3):
		var plane = []
		for y in range(3):
			var row = []
			for x in range(3):
				row.append(x + y*3 + z*9 + 1)  # +1 to start from 1 instead of 0
			plane.append(row)
		array_3d.append(plane)

func _process(delta):
	if animation_playing:
		# Update the animation time and angle
		animation_timer += delta * animation_speed
		angle += delta * animation_speed
		if angle > 2 * PI:
			angle -= 2 * PI
			
		# Step-based animations
		if animation_timer >= step_duration:
			animation_timer = 0
			animation_step += 1
			
			# Reset step counters based on visualization type
			match visualization_type:
				"array_1d":
					if animation_step > array_1d.size():
						animation_step = 0
				"array_2d":
					var total_cells = array_2d.size() * array_2d[0].size()
					if animation_step > total_cells:
						animation_step = 0
				"array_3d":
					var total_cells = array_3d.size() * array_3d[0].size() * array_3d[0][0].size()
					if animation_step > total_cells:
						animation_step = 0
				"advanced":
					if animation_step >= 12:  # Arbitrary number for advanced visualization cycling
						animation_step = 0
		
		# Request redraw for visualization
		queue_redraw()

func _draw():

	var center_x = size.x / 2
	var center_y = size.y / 2
	
	# Draw the appropriate visualization based on current page
	match visualization_type:
		"intro":
			draw_intro_visualization(center_x, center_y)
		"array_1d":
			draw_1d_array_visualization(center_x, center_y)
		"array_2d":
			draw_2d_array_visualization(center_x, center_y)
		"array_3d":
			draw_3d_array_visualization(center_x, center_y)
		"advanced":
			draw_advanced_visualization(center_x, center_y)

func draw_intro_visualization(center_x, center_y):
	# Draw a simple array box with animated pointer
	var box_size = Vector2(50, 50)
	var margin = 10
	var array_size = 5
	var start_x = center_x - (array_size * (box_size.x + margin)) / 2
	var y_pos = center_y - 50
	
	# Draw the array boxes
	for i in range(array_size):
		var box_pos = Vector2(start_x + i * (box_size.x + margin), y_pos)
		var box_rect = Rect2(box_pos, box_size)
		
		# Determine which box to highlight based on animation
		var highlight = int(fmod(angle * 0.5, array_size)) == i
		
		# Draw box with value
		draw_rect(box_rect, COLOR_HIGHLIGHT if highlight else COLOR_1D, true)
		draw_rect(box_rect, Color.WHITE, false, 2)
		
		# Draw pointer under highlighted box
		if highlight:
			# Draw arrow pointing to current box
			var arrow_start = Vector2(box_pos.x + box_size.x/2, box_pos.y + box_size.y + 20)
			var arrow_end = Vector2(arrow_start.x, box_pos.y + box_size.y + 5)
			draw_line(arrow_start, arrow_end, Color.WHITE, 2)
			
			# Draw arrowhead
			var arrow_head_size = 8
			var arrow_left = Vector2(arrow_end.x - arrow_head_size, arrow_end.y + arrow_head_size)
			var arrow_right = Vector2(arrow_end.x + arrow_head_size, arrow_end.y + arrow_head_size)
			draw_colored_polygon(PackedVector2Array([arrow_end, arrow_left, arrow_right]), Color.WHITE)
	
	# Draw process visualization
	var process_y = y_pos + box_size.y + 80
	var process_height = 40
	var process_width = box_size.x * array_size + margin * (array_size - 1)
	var process_rect = Rect2(start_x, process_y, process_width, process_height)
	
	# Draw process box
	draw_rect(process_rect, Color(0.3, 0.3, 0.6, 0.8), true)
	draw_rect(process_rect, Color.WHITE, false, 2)
	
	# Draw processing animation (pulsing)
	var pulse_factor = (1 + sin(angle * 3)) * 0.5
	var inner_margin = 5
	var inner_rect = Rect2(
		process_rect.position.x + inner_margin,
		process_rect.position.y + inner_margin,
		process_rect.size.x * pulse_factor - inner_margin * 2,
		process_rect.size.y - inner_margin * 2
	)
	draw_rect(inner_rect, Color(0.5, 0.5, 1.0, 0.8), true)

func draw_1d_array_visualization(center_x, center_y):
	# Create an animated visualization of iterating through a 1D array
	var box_size = Vector2(60, 60)
	var spacing = 15
	var array = array_1d
	
	# Calculate positioning
	var total_width = array.size() * box_size.x + (array.size() - 1) * spacing
	var start_x = center_x - total_width / 2
	var start_y = center_y - 60
	
	# Draw array elements
	for i in range(array.size()):
		var position = Vector2(start_x + i * (box_size.x + spacing), start_y)
		var rect = Rect2(position, box_size)
		
		# Determine if this element should be highlighted (current step in the animation)
		var is_current = animation_step == i + 1
		var fill_color = COLOR_HIGHLIGHT if is_current else COLOR_1D
		
		# Draw the box
		draw_rect(rect, fill_color, true)
		draw_rect(rect, Color.WHITE, false, 2)
		
		# If this is the current element, draw an indicator
		if is_current:
			# Draw arrow pointing to current element
			var arrow_top = Vector2(position.x + box_size.x/2, position.y - 25)
			var arrow_bottom = Vector2(position.x + box_size.x/2, position.y - 5)
			draw_line(arrow_top, arrow_bottom, Color.WHITE, 2)
			
			# Draw arrowhead
			var arrowhead_size = 8
			var arrow_left = Vector2(arrow_bottom.x - arrowhead_size, arrow_bottom.y - arrowhead_size)
			var arrow_right = Vector2(arrow_bottom.x + arrowhead_size, arrow_bottom.y - arrowhead_size)
			draw_colored_polygon(PackedVector2Array([arrow_bottom, arrow_left, arrow_right]), Color.WHITE)
	
	# Draw for loop visualization below the array
	var loop_y = start_y + box_size.y + 40
	var loop_height = 50
	var loop_width = total_width
	
	# Progress indicator for loop
	var progress_width = 0
	if animation_step > 0 and animation_step <= array.size():
		var progress_percent = float(animation_step) / array.size()
		progress_width = loop_width * progress_percent
	
	# Draw loop container
	draw_rect(Rect2(start_x, loop_y, loop_width, loop_height), Color(0.2, 0.2, 0.3, 0.8), true)
	draw_rect(Rect2(start_x, loop_y, loop_width, loop_height), Color.WHITE, false, 2)
	
	# Draw progress
	if progress_width > 0:
		draw_rect(Rect2(start_x, loop_y, progress_width, loop_height), Color(0.3, 0.6, 0.3, 0.6), true)
	
	# Draw element creation visualization
	if animation_step > 0 and animation_step <= array.size():
		var i = animation_step - 1
		var element_y = loop_y + loop_height + 40
		var element_size = Vector2(box_size.x * 1.2, box_size.y * 1.2)
		var element_x = center_x - element_size.x / 2
		
		# Draw the highlighted element box
		var element_rect = Rect2(Vector2(element_x, element_y), element_size)
		draw_rect(element_rect, COLOR_HIGHLIGHT, true)
		draw_rect(element_rect, Color.WHITE, false, 2)
		
		# Draw animated connection line
		var source_pos = Vector2(start_x + i * (box_size.x + spacing) + box_size.x/2, start_y + box_size.y)
		var target_pos = Vector2(element_x + element_size.x/2, element_y)
		
		# Line with pulse effect
		var pulse_progression = fmod(animation_timer / step_duration, 1.0)
		var pulse_pos = source_pos.lerp(target_pos, pulse_progression)
		var pulse_radius = 5 * (1 - pulse_progression)
		
		draw_line(source_pos, target_pos, Color(0.8, 0.8, 1.0, 0.5), 2)
		draw_circle(pulse_pos, pulse_radius, Color(1.0, 1.0, 1.0, 0.8))

func draw_2d_array_visualization(center_x, center_y):
	# Visualize iteration through a 2D array with nested loops
	var grid = array_2d
	var rows = grid.size()
	var cols = grid[0].size()
	var total_cells = rows * cols
	
	# Calculate current position in animation
	var current_row = 0
	var current_col = 0
	if animation_step > 0 and animation_step <= total_cells:
		current_row = (animation_step - 1) / cols
		current_col = (animation_step - 1) % cols
	
	# Cell sizing and positioning
	var cell_size = Vector2(50, 50)
	var spacing = 10
	var grid_width = cols * (cell_size.x + spacing) - spacing
	var grid_height = rows * (cell_size.y + spacing) - spacing
	var start_x = center_x - grid_width / 2
	var start_y = center_y - grid_height / 2 - 40
	
	# Draw grid background for clarity
	var grid_rect = Rect2(
		start_x - spacing/2, 
		start_y - spacing/2, 
		grid_width + spacing, 
		grid_height + spacing
	)
	draw_rect(grid_rect, Color(0.2, 0.2, 0.25, 0.5), true)
	
	# Draw the grid cells
	for row in range(rows):
		for col in range(cols):
			var cell_pos = Vector2(
				start_x + col * (cell_size.x + spacing),
				start_y + row * (cell_size.y + spacing)
			)
			var cell_rect = Rect2(cell_pos, cell_size)
			
			# Determine if this is the current cell in the animation
			var is_current = (animation_step > 0 && 
							 animation_step <= total_cells && 
							 row == current_row && 
							 col == current_col)
			
			# Highlight the current row and column for better visual tracking
			var in_current_row = (animation_step > 0 && 
								 animation_step <= total_cells && 
								 row == current_row)
			var in_current_col = (animation_step > 0 && 
								 animation_step <= total_cells && 
								 col == current_col)
			
			var fill_color = COLOR_2D
			if is_current:
				fill_color = COLOR_HIGHLIGHT
			elif in_current_row || in_current_col:
				fill_color = Color(0.5, 0.3, 0.2, 0.8)
			
			# Draw the cell
			draw_rect(cell_rect, fill_color, true)
			draw_rect(cell_rect, Color.WHITE, false, 2)
	
	# Draw loop visualization
	var outer_loop_width = grid_width + spacing
	var outer_loop_height = 30
	var outer_loop_y = start_y + grid_height + 40
	var outer_loop_x = start_x - spacing/2
	
	var inner_loop_width = cell_size.x + spacing
	var inner_loop_height = 30
	var inner_loop_y = outer_loop_y + outer_loop_height + 20
	
	# Draw outer loop (row iteration)
	draw_rect(Rect2(outer_loop_x, outer_loop_y, outer_loop_width, outer_loop_height), 
			  Color(0.3, 0.3, 0.4, 0.8), true)
	draw_rect(Rect2(outer_loop_x, outer_loop_y, outer_loop_width, outer_loop_height), 
			  Color.WHITE, false, 2)
	
	# Draw outer loop progress
	if animation_step > 0:
		var outer_progress = min(float(current_row + 1) / rows, 1.0)
		draw_rect(Rect2(outer_loop_x, outer_loop_y, outer_loop_width * outer_progress, outer_loop_height), 
				  Color(0.4, 0.4, 0.6, 0.6), true)
	
	# Draw inner loop (column iteration)
	if animation_step > 0:
		var inner_loop_x = outer_loop_x + (outer_loop_width * (float(current_row) / rows))
		
		draw_rect(Rect2(inner_loop_x, inner_loop_y, inner_loop_width * cols, inner_loop_height), 
				  Color(0.3, 0.3, 0.4, 0.8), true)
		draw_rect(Rect2(inner_loop_x, inner_loop_y, inner_loop_width * cols, inner_loop_height), 
				  Color.WHITE, false, 2)
		
		# Draw inner loop progress
		var inner_progress = float(current_col + 1) / cols
		draw_rect(Rect2(inner_loop_x, inner_loop_y, inner_loop_width * cols * inner_progress, inner_loop_height), 
				  Color(0.6, 0.4, 0.4, 0.6), true)
		
		# Draw connection line from current position in loops to the highlighted cell
		var loop_pos = Vector2(inner_loop_x + inner_loop_width * current_col + inner_loop_width/2, inner_loop_y + inner_loop_height/2)
		var cell_pos = Vector2(
			start_x + current_col * (cell_size.x + spacing) + cell_size.x/2,
			start_y + current_row * (cell_size.y + spacing) + cell_size.y/2
		)
		
		# Animated pulse along the connection line
		var pulse_progression = fmod(animation_timer / step_duration, 1.0)
		var pulse_pos = loop_pos.lerp(cell_pos, pulse_progression)
		var pulse_radius = 4 * (1 - pulse_progression)
		
		draw_line(loop_pos, cell_pos, Color(0.8, 0.8, 1.0, 0.5), 2)
		draw_circle(pulse_pos, pulse_radius, Color(1.0, 1.0, 1.0, 0.8))

func draw_3d_array_visualization(center_x, center_y):
	# Visualize a 3D array with a perspective view
	var array_3d_size = array_3d.size()
	var layer_size = array_3d[0].size()
	var row_size = array_3d[0][0].size()
	var total_cells = array_3d_size * layer_size * row_size
	
	# Calculate current position in the 3D array based on animation step
	var current_z = 0
	var current_y = 0
	var current_x = 0
	if animation_step > 0 and animation_step <= total_cells:
		var cell_index = animation_step - 1
		current_z = cell_index / (layer_size * row_size)
		var remainder = cell_index % (layer_size * row_size)
		current_y = remainder / row_size
		current_x = remainder % row_size
	
	# Draw the 3D grid as stacked 2D grids
	var cube_size = Vector2(40, 40)
	var spacing = 10
	var z_offset = Vector2(15, 15)  # Visual offset for depth
	
	# Calculate the total dimensions
	var grid_width = row_size * (cube_size.x + spacing) - spacing
	var grid_height = layer_size * (cube_size.y + spacing) - spacing
	var start_x = center_x - grid_width/2 - (array_3d_size-1) * z_offset.x/2
	var start_y = center_y - grid_height/2 - (array_3d_size-1) * z_offset.y/2 - 30
	
	# Draw the 3D grid (back to front)
	for z in range(array_3d_size-1, -1, -1):
		var z_layer_offset = Vector2(z * z_offset.x, z * z_offset.y)
		
		for y in range(layer_size):
			for x in range(row_size):
				var cube_pos = Vector2(
					start_x + x * (cube_size.x + spacing) + z_layer_offset.x,
					start_y + y * (cube_size.y + spacing) + z_layer_offset.y
				)
				var cube_rect = Rect2(cube_pos, cube_size)
				
				# Determine highlight state
				var is_current = (animation_step > 0 && 
								 animation_step <= total_cells && 
								 z == current_z && 
								 y == current_y && 
								 x == current_x)
				
				# Determine if in current layer
				var in_current_layer = (animation_step > 0 && 
										animation_step <= total_cells && 
										z == current_z)
				
				# Adjust opacity based on depth
				var depth_factor = float(z) / (array_3d_size - 1)
				var opacity = 0.4 + 0.6 * depth_factor
				
				var fill_color
				if is_current:
					fill_color = COLOR_HIGHLIGHT
				elif in_current_layer:
					fill_color = Color(COLOR_3D.r, COLOR_3D.g, COLOR_3D.b, opacity + 0.2)
				else:
					fill_color = Color(COLOR_3D.r * 0.8, COLOR_3D.g * 0.8, COLOR_3D.b * 0.8, opacity)
				
				# Draw cube
				draw_rect(cube_rect, fill_color, true)
				draw_rect(cube_rect, Color(1, 1, 1, opacity), false, 1)
	
	# Draw the nested loops visualization
	var loop_height = 25
	var loop_spacing = 15
	var z_loop_width = grid_width + z_offset.x * (array_3d_size - 1) + spacing
	var y_loop_width = grid_width
	var x_loop_width = cube_size.x + spacing
	
	var z_loop_y = start_y + grid_height + z_offset.y * (array_3d_size - 1) + 50
	var y_loop_y = z_loop_y + loop_height + loop_spacing
	var x_loop_y = y_loop_y + loop_height + loop_spacing
	
	# Draw z-loop (outer)
	var z_loop_rect = Rect2(start_x, z_loop_y, z_loop_width, loop_height)
	draw_rect(z_loop_rect, Color(0.2, 0.4, 0.2, 0.8), true)
	draw_rect(z_loop_rect, Color.WHITE, false, 2)
	
	# Draw z-loop progress
	if animation_step > 0:
		var z_progress = min(float(current_z + 1) / array_3d_size, 1.0)
		draw_rect(Rect2(z_loop_rect.position, Vector2(z_loop_rect.size.x * z_progress, z_loop_rect.size.y)), 
				 Color(0.3, 0.6, 0.3, 0.6), true)
	
	# Draw y-loop (middle)
	if animation_step > 0:
		var y_loop_x = start_x + (z_loop_width * (float(current_z) / array_3d_size))
		var y_loop_rect = Rect2(y_loop_x, y_loop_y, y_loop_width, loop_height)
		draw_rect(y_loop_rect, Color(0.4, 0.2, 0.4, 0.8), true)
		draw_rect(y_loop_rect, Color.WHITE, false, 2)
		
		# Draw y-loop progress
		var y_progress = min(float(current_y + 1) / layer_size, 1.0)
		draw_rect(Rect2(y_loop_rect.position, Vector2(y_loop_rect.size.x * y_progress, y_loop_rect.size.y)), 
				 Color(0.6, 0.3, 0.6, 0.6), true)
		
		# Draw x-loop (inner)
		var x_loop_x = y_loop_x + (y_loop_width * (float(current_y) / layer_size))
		var x_loop_rect = Rect2(x_loop_x, x_loop_y, x_loop_width * row_size, loop_height)
		draw_rect(x_loop_rect, Color(0.2, 0.2, 0.4, 0.8), true)
		draw_rect(x_loop_rect, Color.WHITE, false, 2)
		
		# Draw x-loop progress
		var x_progress = min(float(current_x + 1) / row_size, 1.0) 
		draw_rect(Rect2(x_loop_rect.position, Vector2(x_loop_rect.size.x * x_progress, x_loop_rect.size.y)), 
				 Color(0.3, 0.3, 0.6, 0.6), true)
		
		# Draw connection line from current position in loops to the highlighted cube
		var loop_pos = Vector2(x_loop_x + x_loop_width * current_x + x_loop_width/2, x_loop_y + loop_height/2)
		var cube_pos = Vector2(
			start_x + current_x * (cube_size.x + spacing) + current_z * z_offset.x + cube_size.x/2,
			start_y + current_y * (cube_size.y + spacing) + current_z * z_offset.y + cube_size.y/2
		)
		
		# Animated pulse along the connection line
		var pulse_progression = fmod(animation_timer / step_duration, 1.0)
		var pulse_pos = loop_pos.lerp(cube_pos, pulse_progression)
		var pulse_radius = 4 * (1 - pulse_progression)
		
		draw_line(loop_pos, cube_pos, Color(0.8, 0.8, 1.0, 0.5), 2)
		draw_circle(pulse_pos, pulse_radius, Color(1.0, 1.0, 1.0, 0.8))

func draw_advanced_visualization(center_x, center_y):
	# Split the visualization area into two sections
	var section_height = size.y / 2
	
	# Determine which visualization to show based on animation step
	var show_filtering = animation_step < 6
	
	if show_filtering:
		# 1. Array filtering visualization (even numbers)
		var numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
		var even_numbers = []
		
		for n in numbers:
			if n % 2 == 0:
				even_numbers.append(n)
		
		# Draw the original array
		var box_size = Vector2(40, 40)
		var spacing = 10
		var array_width = numbers.size() * (box_size.x + spacing) - spacing
		var start_x = center_x - array_width / 2
		var start_y = position.y + 50
		
		# Determine which number is being processed
		var current_index = min(animation_step, numbers.size() - 1)
		var current_number = numbers[current_index]
		var is_current_even = current_number % 2 == 0
		
		# Draw the input array
		for i in range(numbers.size()):
			var position = Vector2(start_x + i * (box_size.x + spacing), start_y)
			var rect = Rect2(position, box_size)
			
			var is_even = numbers[i] % 2 == 0
			var is_processed = i <= current_index
			
			var fill_color
			if i == current_index:
				fill_color = COLOR_HIGHLIGHT
			elif is_processed:
				fill_color = Color(0.4, 0.4, 0.7, 0.7) if not is_even else Color(0.2, 0.7, 0.2, 0.7)
			else:
				fill_color = Color(0.4, 0.4, 0.7, 0.4)
			
			draw_rect(rect, fill_color, true)
			draw_rect(rect, Color.WHITE, false)
		
		# Draw the filter visualization
		var filter_y = start_y + box_size.y + 40
		var filter_height = 60
		var filter_rect = Rect2(start_x, filter_y, array_width, filter_height)
		
		# Filter box
		draw_rect(filter_rect, Color(0.2, 0.2, 0.4, 0.8), true)
		draw_rect(filter_rect, Color.WHITE, false, 2)
		
		# Filter mesh/screen visualization
		var mesh_spacing = 8
		for i in range(int(filter_rect.size.x / mesh_spacing)):
			var x = filter_rect.position.x + i * mesh_spacing
			draw_line(Vector2(x, filter_rect.position.y), 
					 Vector2(x, filter_rect.position.y + filter_rect.size.y),
					 Color(0.5, 0.5, 0.8, 0.3), 1)
		
		# Animate current number passing through filter
		if animation_step < numbers.size():
			var number_pos_y = 0
			var pulse_progression = fmod(animation_timer / step_duration, 1.0)
			
			if is_current_even:
				# Even numbers pass through
				number_pos_y = lerp(filter_y - box_size.y/2, filter_y + filter_height + box_size.y/2, pulse_progression)
			else:
				# Odd numbers bounce off
				var bounce_curve = sin(pulse_progression * PI)
				number_pos_y = lerp(filter_y - box_size.y/2, filter_y - box_size.y/2 - 20 * bounce_curve, pulse_progression)
			
			var current_box_pos = Vector2(
				start_x + current_index * (box_size.x + spacing) + box_size.x/2 - box_size.x/2,
				number_pos_y
			)
			
			var current_box_rect = Rect2(current_box_pos, box_size)
			draw_rect(current_box_rect, COLOR_HIGHLIGHT, true)
			draw_rect(current_box_rect, Color.WHITE, false, 2)
		
		# Draw the output array (filtered even numbers)
		var output_y = filter_y + filter_height + 60
		var output_width = even_numbers.size() * (box_size.x + spacing) - spacing
		var output_start_x = center_x - output_width / 2
		
		# Calculate how many even numbers have been processed so far
		var even_count = 0
		for i in range(current_index + 1):
			if numbers[i] % 2 == 0:
				even_count += 1
		
		for i in range(even_numbers.size()):
			var is_filled = i < even_count
			var position = Vector2(output_start_x + i * (box_size.x + spacing), output_y)
			var rect = Rect2(position, box_size)
			
			if is_filled:
				draw_rect(rect, Color(0.2, 0.7, 0.2, 0.7), true)
				draw_rect(rect, Color.WHITE, false)
			else:
				# Draw empty placeholder box
				draw_rect(rect, Color(0.2, 0.2, 0.3, 0.4), true)
				draw_rect(rect, Color(0.5, 0.5, 0.5, 0.5), false)
	else:
		# 2. Dictionary-based grid visualization
		var grid_size = Vector2(4, 3)
		var cell_size = Vector2(60, 60)
		var grid_spacing = 5
		
		var grid_width = grid_size.x * (cell_size.x + grid_spacing) - grid_spacing
		var grid_height = grid_size.y * (cell_size.y + grid_spacing) - grid_spacing
		
		var grid_start_x = center_x - grid_width / 2
		var grid_start_y = position.y + 50
		
		# Determine which cell to highlight based on animation cycle
		var highlight_idx = (animation_step - 6) % int(grid_size.x * grid_size.y)
		var highlight_x = highlight_idx % int(grid_size.x)
		var highlight_y = highlight_idx / int(grid_size.x)
		
		# Draw grid cells
		for y in range(int(grid_size.y)):
			for x in range(int(grid_size.x)):
				var cell_pos = Vector2(
					grid_start_x + x * (cell_size.x + grid_spacing),
					grid_start_y + y * (cell_size.y + grid_spacing)
				)
				var cell_rect = Rect2(cell_pos, cell_size)
				
				# Determine if this cell should be highlighted
				var is_highlighted = (x == highlight_x and y == highlight_y)
				
				# Calculate cell color based on distance from highlighted cell
				var dist_factor = 1.0
				if is_highlighted:
					dist_factor = 0.0
				else:
					var dx = abs(x - highlight_x)
					var dy = abs(y - highlight_y)
					dist_factor = min(1.0, sqrt(dx*dx + dy*dy) / 3.0)
				
				# Interpolate between highlight color and default color
				var cell_color = COLOR_HIGHLIGHT.lerp(Color(0.2, 0.2, 0.3, 0.7), dist_factor)
				
				# Draw cell with fill and border
				draw_rect(cell_rect, cell_color, true)
				draw_rect(cell_rect, Color.WHITE, false)
				
				# Draw item indicator for highlighted cells or nearby cells
				if dist_factor < 0.5:
					# Draw item icon (simplified)
					var icon_size = cell_size * 0.5
					var icon_pos = cell_pos + cell_size * 0.25
					var icon_rect = Rect2(icon_pos, icon_size)
					
					var opacity = 1.0 - dist_factor * 2
					var icon_color = Color(1.0, 0.9, 0.5, opacity)
					
					draw_rect(icon_rect, icon_color, true)
					draw_rect(icon_rect, Color(1, 1, 1, opacity), false)
		
		# Draw the property panel showing the dictionary for the highlighted cell
		var panel_width = 200
		var panel_height = 120
		var panel_x = center_x - panel_width / 2
		var panel_y = grid_start_y + grid_height + 40
		
		# Draw panel background
		var panel_rect = Rect2(panel_x, panel_y, panel_width, panel_height)
		draw_rect(panel_rect, Color(0.2, 0.2, 0.25, 0.8), true)
		draw_rect(panel_rect, Color.WHITE, false, 2)
		
		# Draw property indicators (no text, just visual markers)
		var prop_height = 25
		var prop_spacing = 10
		var prop_start_y = panel_y + 20
		
		for i in range(3):  # position, item_id, quantity
			var prop_bg_color = Color(0.3, 0.3, 0.4, 0.6)
			var prop_value_color = Color(0.8, 0.8, 0.3, 0.8)
			
			if i == 0:  # position property
				prop_value_color = Color(0.3, 0.7, 0.9, 0.8)
			
			# Property label indicator (left side)
			draw_rect(Rect2(panel_x + 10, prop_start_y + i * (prop_height + prop_spacing), 
						   60, prop_height), prop_bg_color, true)
			
			# Property value (right side)
			draw_rect(Rect2(panel_x + 80, prop_start_y + i * (prop_height + prop_spacing), 
						   panel_width - 90, prop_height), prop_value_color, true)
		
		# Draw connection line from highlighted cell to property panel
		var cell_center = Vector2(
			grid_start_x + highlight_x * (cell_size.x + grid_spacing) + cell_size.x/2,
			grid_start_y + highlight_y * (cell_size.y + grid_spacing) + cell_size.y/2
		)
		var panel_top = Vector2(panel_x + panel_width/2, panel_y)
		
		# Animated pulse along the connection line
		var pulse_progression = fmod(animation_timer / step_duration, 1.0)
		var pulse_pos = cell_center.lerp(panel_top, pulse_progression)
		var pulse_radius = 5 * (1 - pulse_progression)
		
		draw_line(cell_center, panel_top, Color(0.8, 0.8, 1.0, 0.5), 2)
		draw_circle(pulse_pos, pulse_radius, Color(1.0, 1.0, 1.0, 0.8))
