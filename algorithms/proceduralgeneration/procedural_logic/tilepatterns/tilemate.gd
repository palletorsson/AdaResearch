extends Node2D

# Pattern parameters
var P = {
	"tiles": 8,  # Changed to 4x4 grid
	"padding": 0.2,
	"edgesMax": 15,
	"edgesAttempts": 20,
	"edgesBreak": 4,
	"innerGrid": 3,
	"startPoint": Vector2(1, 1),
	"symmetry": "reflect",
	"colors": [
		Color(1.0, 0.3, 0.3),  # Red
		Color(0.3, 1.0, 0.3),  # Green
		Color(0.3, 0.3, 1.0),  # Blue
		Color(1.0, 1.0, 0.3),  # Yellow
		Color(1.0, 0.3, 1.0),  # Magenta
		Color(0.3, 1.0, 1.0),  # Cyan
		Color(1.0, 0.5, 0.0),  # Orange
		Color(0.5, 0.0, 1.0),  # Purple
		Color(0.0, 0.8, 0.5)   # Teal
	],
	"add_new_row": false  # Flag to control adding new rows
}

var pattern_timer = null

# Directions for path generation
var directions = [
	Vector2(1, 0),
	Vector2(0, -1),
	Vector2(0, 1),
	Vector2(-1, 0),
]

var points_data = []

func _ready():
	randomize()
	generate_points_data()
	
	# Set up a timer to shift patterns down
	pattern_timer = Timer.new()
	add_child(pattern_timer)
	pattern_timer.wait_time = 0.1  # Shift patterns every 3 seconds
	pattern_timer.connect("timeout", Callable(self, "shift_patterns_down"))
	pattern_timer.start()

func _draw():
	var window_size = get_viewport_rect().size
	var m = min(window_size.x, window_size.y) * 0.85
	var canvas_offset = Vector2((window_size.x - m) / 2, (window_size.y - m) / 2)
	
	# Draw background
	draw_rect(Rect2(0, 0, window_size.x, window_size.y), Color("#121212"))
	
	var block_step = m / P.tiles
	var padding = block_step * P.padding
	var block_size = block_step - padding * 2
	
	for i in range(points_data.size()):
		var x = i % P.tiles
		var y = floor(i / P.tiles)
		
		var pos = Vector2(
			canvas_offset.x + x * block_step + padding,
			canvas_offset.y + y * block_step + padding
		)
		
		draw_mirrored_quadrants(points_data[i], block_size, pos)

func get_points():
	var x = int(P.startPoint.x)
	var y = int(P.startPoint.y)
	var points = [Vector2(x, y)]
	var edges = {}
	var x_max = P.innerGrid
	var y_max = P.innerGrid
	var colors = []  # Array to store colors for each line segment
	
	# Helper function to get or initialize edges for a position
	var get_edges = func(x, y):
		var key = str(x) + "-" + str(y)
		if not edges.has(key):
			edges[key] = []
		return edges[key]
	
	var i = 0
	var points_count = 0
	var need_to_push_point1 = false
	
	while i < P.edgesAttempts and points_count < P.edgesMax:
		var visited = get_edges.call(x, y)
		var options = []
		
		# Filter valid directions
		for dir in directions:
			var new_x = x + int(dir.x)
			var new_y = y + int(dir.y)
			
			# Check boundaries
			if new_x < 0 or new_x > x_max:
				continue
			if new_y < 0 or new_y > y_max:
				continue
				
			# Check if already visited
			var already_visited = false
			for v_pos in visited:
				if v_pos.x == new_x and v_pos.y == new_y:
					already_visited = true
					break
					
			if not already_visited:
				options.append(dir)
		
		if options.size() == 0:
			x = randi() % (x_max + 1)
			y = randi() % (y_max + 1)
			i += 1
			points.append(null)  # Equivalent to false in the original code
			points.append(Vector2(x, y))
			colors.append(null)  # No color for breaks
			continue
		
		if need_to_push_point1:
			points.append(Vector2(x, y))
			need_to_push_point1 = false
			points_count += 1
		
		var prev_x = x
		var prev_y = y
		var dir = options[randi() % options.size()]
		x += int(dir.x)
		y += int(dir.y)
		
		visited.append(Vector2(x, y))
		get_edges.call(x, y).append(Vector2(prev_x, prev_y))
		
		points.append(Vector2(x, y))
		# Add a random color for this line segment
		colors.append(P.colors[randi() % P.colors.size()])
		points_count += 1
		i += 1
		
		if i % P.edgesBreak == 0:
			points.append(null)  # Equivalent to false in the original code
			colors.append(null)  # No color for breaks
			x = randi() % (x_max + 1)
			y = randi() % (y_max + 1)
			need_to_push_point1 = true
	
	return {"points": points, "edges": edges, "colors": colors}

func quadrant(points, colors, size, offset):
	var step = size / P.innerGrid
	
	for i in range(1, points.size()):
		var p1 = points[i - 1]
		var p2 = points[i]
		
		if p1 == null or p2 == null:
			continue
			
		var x1 = p1.x * step
		var y1 = p1.y * step
		var x2 = p2.x * step
		var y2 = p2.y * step
		
		# Use the color assigned to this line segment or default to white if none
		var line_color = Color.WHITE
		if i <= colors.size() and colors[i-1] != null:
			line_color = colors[i-1]
		
		draw_line(
			Vector2(offset.x + x1, offset.y + y1),
			Vector2(offset.x + x2, offset.y + y2),
			line_color,
			3.0
		)

func draw_mirrored_quadrants(points_data, size, offset):
	var points = points_data.points
	var colors = points_data.colors
	var step = size / 2
	var center = Vector2(offset.x + step, offset.y + step)
	
	if P.symmetry == "reflect":
		# Create copies of the points and colors arrays to avoid modifying the originals
		var points_copy = points.duplicate()
		
		# Original quadrant
		quadrant(points_copy, colors, step, center)
		
		# Reflect vertically
		var points_reflect_v = []
		for p in points_copy:
			if p == null:
				points_reflect_v.append(null)
			else:
				points_reflect_v.append(Vector2(p.x, -p.y))
		quadrant(points_reflect_v, colors, step, center)
		
		# Reflect horizontally
		var points_reflect_h = []
		for p in points_copy:
			if p == null:
				points_reflect_h.append(null)
			else:
				points_reflect_h.append(Vector2(-p.x, p.y))
		quadrant(points_reflect_h, colors, step, center)
		
		# Reflect both (diagonal)
		var points_reflect_both = []
		for p in points_copy:
			if p == null:
				points_reflect_both.append(null)
			else:
				points_reflect_both.append(Vector2(-p.x, -p.y))
		quadrant(points_reflect_both, colors, step, center)
				
	elif P.symmetry == "rotate":
		# Original quadrant
		quadrant(points, colors, step, center)
		
		# Rotate 90 degrees
		var rotated_points = []
		for p in points:
			if p == null:
				rotated_points.append(null)
			else:
				rotated_points.append(Vector2(-p.y, p.x))
		quadrant(rotated_points, colors, step, center)
		
		# Rotate 180 degrees
		rotated_points = []
		for p in points:
			if p == null:
				rotated_points.append(null)
			else:
				rotated_points.append(Vector2(-p.x, -p.y))
		quadrant(rotated_points, colors, step, center)
		
		# Rotate 270 degrees
		rotated_points = []
		for p in points:
			if p == null:
				rotated_points.append(null)
			else:
				rotated_points.append(Vector2(p.y, -p.x))
		quadrant(rotated_points, colors, step, center)

func generate_points_data():
	points_data = []
	for i in range(P.tiles * P.tiles):
		points_data.append(get_points())
	
	# Initial mating of patterns to create interesting starting patterns
	mate_patterns(points_data, P.tiles, P.tiles)
	queue_redraw()
	
func shift_patterns_down():
	# Save the current points data size
	var grid_width = P.tiles
	var grid_height = P.tiles
	
	# Shift existing rows down (removing the bottom row)
	var new_points_data = []
	
	# Generate a new top row if add_new_row is true
	if P.add_new_row:
		for i in range(grid_width):
			new_points_data.append(get_points())
	
	# Add the existing rows (except the bottom row if we're adding a new one)
	var start_row = 0
	var end_row = grid_height
	
	if P.add_new_row:
		# Skip the bottom row if we added a new row at the top
		end_row -= 1
	
	for y in range(start_row, end_row):
		for x in range(grid_width):
			var index = y * grid_width + x
			if index < points_data.size():
				new_points_data.append(points_data[index])
	
	# If not adding a new row, randomly generate missing patterns to maintain grid size
	if not P.add_new_row and new_points_data.size() < grid_width * grid_height:
		var missing = (grid_width * grid_height) - new_points_data.size()
		for i in range(missing):
			new_points_data.append(get_points())
	
	# Mate patterns with random neighbors
	mate_patterns(new_points_data, grid_width, grid_height)
	
	# Update points data
	points_data = new_points_data
	queue_redraw()
	
	# Randomly toggle the add_new_row flag with 30% chance
	if randf() < 0.3:
		P.add_new_row = not P.add_new_row


func mate_patterns(data, width, height):
	# For each pattern, find a random neighbor and mate with it
	for y in range(height):
		for x in range(width):
			var index = y * width + x
			
			# Skip mating with 20% probability to maintain some diversity
			if randf() < 0.2:
				continue
				
			# Get neighbors
			var neighbors = []
			
			# Add left neighbor if exists
			if x > 0:
				neighbors.append((y * width) + (x - 1))
			
			# Add right neighbor if exists
			if x < width - 1:
				neighbors.append((y * width) + (x + 1))
			
			# Add top neighbor if exists
			if y > 0:
				neighbors.append(((y - 1) * width) + x)
			
			# Add bottom neighbor if exists
			if y < height - 1:
				neighbors.append(((y + 1) * width) + x)
			
			# Choose a random neighbor
			if neighbors.size() > 0:
				var neighbor_idx = neighbors[randi() % neighbors.size()]
				
				# Skip if neighbor is out of bounds (for safety)
				if neighbor_idx >= data.size():
					continue
					
				# Perform mating (mix features)
				data[index] = mate_two_patterns(data[index], data[neighbor_idx])

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		generate_points_data()

func _notification(what):
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		queue_redraw()

func mate_two_patterns(pattern1, pattern2):
	# Create a new pattern by mixing features from two parent patterns
	var result = {}
	
	# Choose which properties to inherit from which parent
	# We'll inherit points structure from one parent and colors from another
	var inherit_points_from_first = randf() < 0.5
	
	if inherit_points_from_first:
		# Inherit points structure from pattern1
		result.points = pattern1.points.duplicate()
		result.edges = pattern1.edges.duplicate()
		
		# But inherit colors from pattern2, adjusting array size if needed
		var colors = []
		var p2_colors = pattern2.colors
		
		for i in range(result.points.size()):
			if i < p2_colors.size():
				colors.append(p2_colors[i])
			else:
				# If we run out of colors from pattern2, use a random color
				colors.append(P.colors[randi() % P.colors.size()])
		
		result.colors = colors
	else:
		# Inherit points structure from pattern2
		result.points = pattern2.points.duplicate()
		result.edges = pattern2.edges.duplicate()
		
		# But inherit colors from pattern1, adjusting array size if needed
		var colors = []
		var p1_colors = pattern1.colors
		
		for i in range(result.points.size()):
			if i < p1_colors.size():
				colors.append(p1_colors[i])
			else:
				# If we run out of colors from pattern1, use a random color
				colors.append(P.colors[randi() % P.colors.size()])
		
		result.colors = colors
	
	# Occasionally mutate by changing some random colors (10% chance)
	if randf() < 0.1:
		for i in range(result.colors.size()):
			if randf() < 0.2:  # 20% chance to change each color
				result.colors[i] = P.colors[randi() % P.colors.size()]
	
	return result
