extends Control

# Visualization type and parameters
var visualization_type = "intro"
var animation_playing = true
var animation_speed = 1.0
var time_elapsed = 0.0

# Noise terrain parameters
var noise_seed = 42
var noise_scale = 25.0
var noise_octaves = 4
var terrain_grid = []
var terrain_colors = [
	Color(0.0, 0.2, 0.8, 1.0),  # Deep water
	Color(0.0, 0.4, 0.9, 1.0),  # Shallow water
	Color(0.9, 0.9, 0.2, 1.0),  # Beach
	Color(0.0, 0.7, 0.0, 1.0),  # Grassland
	Color(0.0, 0.5, 0.0, 1.0),  # Forest
	Color(0.5, 0.4, 0.2, 1.0),  # Hills
	Color(0.7, 0.7, 0.7, 1.0),  # Mountains
	Color(1.0, 1.0, 1.0, 1.0)   # Snow
]

# L-System parameters
var lsystem_angle = 25.0
var lsystem_string = ""
var lsystem_commands = []
var turtle_states = []
var current_lsystem = ""

# Dungeon generation parameters
var dungeon_room_count = 12
var dungeon_connectivity = 0.5
var dungeon_grid = []
var dungeon_rooms = []
var dungeon_corridors = []
var CELL_WALL = 0
var CELL_FLOOR = 1
var CELL_CORRIDOR = 2
var CELL_DOOR = 3

# Constants for visualizations
const TERRAIN_GRID_SIZE = 64
const CELL_SIZE = 8
const LSYSTEM_ITERATIONS = 4
const LSYSTEM_SEGMENT_LENGTH = 10.0
const MAX_DUNGEON_WIDTH = 40
const MAX_DUNGEON_HEIGHT = 30
const MIN_ROOM_SIZE = 3
const MAX_ROOM_SIZE = 8

# Colors for visualization
var COLOR_TEXT = Color(0.85, 0.85, 0.95, 1.0)
var COLOR_GRID = Color(0.3, 0.3, 0.4, 0.3)
var COLOR_BRANCH = Color(0.5, 0.3, 0.0, 1.0)
var COLOR_LEAF = Color(0.0, 0.8, 0.2, 1.0)
var COLOR_FRACTAL = Color(0.3, 0.7, 0.9, 1.0)
var COLOR_WALL = Color(0.2, 0.2, 0.3, 1.0)
var COLOR_FLOOR = Color(0.7, 0.7, 0.8, 0.7)
var COLOR_CORRIDOR = Color(0.5, 0.5, 0.6, 0.8)
var COLOR_DOOR = Color(0.8, 0.4, 0.2, 1.0)

# Random number generator
var rng = RandomNumberGenerator.new()

# Initialization
func _ready():
	rng.randomize()
	
	# Initialize based on visualization type
	match visualization_type:
		"intro":
			initialize_intro()
		"noise_terrain":
			initialize_noise_terrain()
		"lsystem":
			initialize_lsystem()
		"dungeon":
			initialize_dungeon()
		"advanced":
			initialize_advanced()

func _process(delta):
	if animation_playing:
		time_elapsed += delta * animation_speed
		
		# Update visualization based on current type
		match visualization_type:
			"intro":
				process_intro_animation(delta)
			"noise_terrain":
				process_noise_animation(delta)
			"lsystem":
				process_lsystem_animation(delta)
			"dungeon":
				process_dungeon_animation(delta)
			"advanced":
				process_advanced_animation(delta)
		
		# Request redraw
		queue_redraw()

func _draw():
	var center_x = size.x / 2
	var center_y = size.y / 2
	
	# Draw appropriate visualization
	match visualization_type:
		"intro":
			draw_intro_visualization(center_x, center_y)
		"noise_terrain":
			draw_noise_terrain(center_x, center_y)
		"lsystem":
			draw_lsystem(center_x, center_y)
		"dungeon":
			draw_dungeon(center_x, center_y)
		"advanced":
			draw_advanced(center_x, center_y)

# Initialize different visualizations
func initialize_intro():
	# Sample initialization for intro visualization
	# This could show a combination of procedural techniques
	initialize_noise_terrain()
	initialize_lsystem()
	initialize_dungeon()

func initialize_noise_terrain():
	# Create a noise generator
	var noise = FastNoiseLite.new()
	noise.seed = noise_seed
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = noise_octaves
	noise.frequency = 1.0 / noise_scale
	
	# Generate terrain grid
	terrain_grid = []
	for y in range(TERRAIN_GRID_SIZE):
		var row = []
		for x in range(TERRAIN_GRID_SIZE):
			# Get noise value in range [-1,1]
			var elevation = noise.get_noise_2d(x, y)
			# Scale to desired range (0-7 for terrain types)
			elevation = (elevation + 1.0) * 3.5
			row.append(elevation)
		terrain_grid.append(row)

func initialize_lsystem():
	# Define various L-systems
	var lsystems = {
		"plant": {
			"axiom": "F",
			"rules": {"F": "F[+F]F[-F][F]"},
			"angle": lsystem_angle,
			"iterations": LSYSTEM_ITERATIONS
		},
		"tree": {
			"axiom": "F",
			"rules": {"F": "FF-[-F+F+F]+[+F-F-F]"},
			"angle": lsystem_angle,
			"iterations": LSYSTEM_ITERATIONS
		},
		"sierpinski": {
			"axiom": "F-G-G",
			"rules": {"F": "F-G+F+G-F", "G": "GG"},
			"angle": 120,
			"iterations": LSYSTEM_ITERATIONS
		},
		"dragon": {
			"axiom": "FX",
			"rules": {"X": "X+YF+", "Y": "-FX-Y"},
			"angle": 90,
			"iterations": LSYSTEM_ITERATIONS
		}
	}
	
	# Choose which L-system to show
	current_lsystem = "plant"
	generate_lsystem(lsystems[current_lsystem])

func initialize_dungeon():
	# Initialize dungeon grid
	dungeon_grid = []
	for y in range(MAX_DUNGEON_HEIGHT):
		var row = []
		for x in range(MAX_DUNGEON_WIDTH):
			row.append(CELL_WALL)
		dungeon_grid.append(row)
	
	# Generate dungeon using BSP algorithm
	generate_dungeon()

func initialize_advanced():
	# Combine multiple procedural techniques
	initialize_noise_terrain()
	initialize_lsystem()
	initialize_dungeon()

# Animation processing
func process_intro_animation(delta):
	# Cycle through the different visualization techniques
	var cycle_duration = 5.0
	var phase = fmod(time_elapsed, cycle_duration * 3) / cycle_duration
	
	if phase < 1.0:
		# Show terrain generation
		process_noise_animation(delta)
	elif phase < 2.0:
		# Show L-system growth
		process_lsystem_animation(delta)
	else:
		# Show dungeon generation
		process_dungeon_animation(delta)

func process_noise_animation(delta):
	# For noise-based terrain, we might animate water or cloud movements
	# This is optional since the terrain itself is static
	pass

func process_lsystem_animation(delta):
	# Animate the L-system growth
	var growth_progress = fmod(time_elapsed, 10.0) / 10.0
	
	# Calculate which commands to show based on growth progress
	var visible_commands = int(growth_progress * lsystem_commands.size())
	
	# Limit to actual available commands
	turtle_states = []
	for i in range(min(visible_commands, lsystem_commands.size())):
		var cmd = lsystem_commands[i]
		
		if cmd == "F":  # Forward
			# Draw line segment
			pass
		elif cmd == "+":  # Turn right
			# Turn turtle
			pass
		elif cmd == "-":  # Turn left
			# Turn turtle
			pass
		elif cmd == "[":  # Push state
			# Save turtle state
			pass
		elif cmd == "]":  # Pop state
			# Restore turtle state
			pass

func process_dungeon_animation(delta):
	# For dungeon visualization, we might animate exploration or generation
	# This is optional since the dungeon layout itself is static once generated
	pass

func process_advanced_animation(delta):
	# Cycle through the different visualization techniques
	var cycle_duration = 6.0
	var phase = fmod(time_elapsed, cycle_duration * 3) / cycle_duration
	
	if phase < 1.0:
		# Show terrain generation
		process_noise_animation(delta)
	elif phase < 2.0:
		# Show L-system growth
		process_lsystem_animation(delta)
	else:
		# Show dungeon generation
		process_dungeon_animation(delta)

# Drawing functions
func draw_intro_visualization(center_x, center_y):
	# Draw a split screen showing all three techniques
	var third_height = size.y / 3
	
	# Draw terrain in top section
	var terrain_section_y = third_height / 2
	draw_section_label(center_x, 20, "Procedural Terrain")
	draw_noise_terrain(center_x, terrain_section_y, 0.4)
	
	# Draw L-system in middle section
	var lsystem_section_y = third_height + third_height / 2
	draw_section_label(center_x, third_height + 20, "L-System (Plants & Fractals)")
	draw_lsystem(center_x, lsystem_section_y, 0.4)
	
	# Draw dungeon in bottom section
	var dungeon_section_y = 2 * third_height + third_height / 2
	draw_section_label(center_x, 2 * third_height + 20, "Procedural Dungeons")
	draw_dungeon(center_x, dungeon_section_y, 0.4)

func draw_noise_terrain(center_x, center_y, scale_factor = 1.0):
	if terrain_grid.size() == 0:
		return
	
	# Calculate grid dimensions
	var grid_width = TERRAIN_GRID_SIZE * CELL_SIZE * scale_factor
	var grid_height = TERRAIN_GRID_SIZE * CELL_SIZE * scale_factor
	var start_x = center_x - grid_width / 2
	var start_y = center_y - grid_height / 2
	
	# Draw terrain cells
	for y in range(TERRAIN_GRID_SIZE):
		for x in range(TERRAIN_GRID_SIZE):
			var elevation = terrain_grid[y][x]
			var terrain_type = clamp(int(elevation), 0, terrain_colors.size() - 1)
			var cell_color = terrain_colors[terrain_type]
			
			var cell_x = start_x + x * CELL_SIZE * scale_factor
			var cell_y = start_y + y * CELL_SIZE * scale_factor
			var cell_rect = Rect2(cell_x, cell_y, CELL_SIZE * scale_factor, CELL_SIZE * scale_factor)
			
			draw_rect(cell_rect, cell_color)
	
	# Draw a simple legend
	if scale_factor > 0.9:  # Only show legend at full scale
		var legend_x = start_x + grid_width + 20
		var legend_y = start_y
		
		draw_string(ThemeDB.fallback_font, Vector2(legend_x, legend_y), "Elevation Types:", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, COLOR_TEXT)
		
		for i in range(terrain_colors.size()):
			var label = ""
			match i:
				0: label = "Deep Water"
				1: label = "Shallow Water" 
				2: label = "Beach"
				3: label = "Grassland"
				4: label = "Forest"
				5: label = "Hills"
				6: label = "Mountains"
				7: label = "Snow"
			
			var box_size = 15
			var box_rect = Rect2(legend_x, legend_y + 20 + i * 25, box_size, box_size)
			
			draw_rect(box_rect, terrain_colors[i])
			draw_rect(box_rect, Color.WHITE, false)
			draw_string(ThemeDB.fallback_font, Vector2(legend_x + box_size + 10, legend_y + 20 + i * 25 + box_size/2 + 5), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, COLOR_TEXT)

func draw_lsystem(center_x, center_y, scale_factor = 1.0):
	if lsystem_commands.size() == 0:
		return
	
	# Calculate starting position and orientation
	var turtle_x = center_x
	var turtle_y = center_y + 100 * scale_factor  # Start at bottom
	var turtle_angle = -90  # Start pointing up
	var segment_length = LSYSTEM_SEGMENT_LENGTH * scale_factor
	
	# Determine how much of the L-system to show (for animation)
	var visible_commands = lsystem_commands.size()
	if visualization_type == "lsystem" or visualization_type == "advanced":
		var growth_progress = fmod(time_elapsed, 10.0) / 10.0
		visible_commands = int(growth_progress * lsystem_commands.size())
	
	# Storage for turtle state
	var state_stack = []
	
	# Process the L-system commands
	for i in range(min(visible_commands, lsystem_commands.size())):
		var cmd = lsystem_commands[i]
		
		match cmd:
			"F", "G":  # Draw forward
				# Calculate endpoint
				var angle_rad = deg_to_rad(turtle_angle)
				var end_x = turtle_x + cos(angle_rad) * segment_length
				var end_y = turtle_y + sin(angle_rad) * segment_length
				
				# Draw the line segment
				var line_color = COLOR_BRANCH
				var line_width = 2.0 * scale_factor
				
				# Adjust color and thickness based on nesting level
				if state_stack.size() > 0:
					line_color = COLOR_BRANCH.lerp(COLOR_LEAF, float(state_stack.size()) / 4.0)
					line_width = max(1.0, 2.0 - state_stack.size() * 0.3) * scale_factor
				
				draw_line(Vector2(turtle_x, turtle_y), Vector2(end_x, end_y), line_color, line_width)
				
				# Update turtle position
				turtle_x = end_x
				turtle_y = end_y
			"+":  # Turn right
				turtle_angle += lsystem_angle
			"-":  # Turn left
				turtle_angle -= lsystem_angle
			"[":  # Save state
				state_stack.push_back([turtle_x, turtle_y, turtle_angle])
			"]":  # Restore state
				if state_stack.size() > 0:
					var state = state_stack.pop_back()
					turtle_x = state[0]
					turtle_y = state[1]
					turtle_angle = state[2]
	
	# Draw L-system information
	if scale_factor > 0.9:  # Only show info at full scale
		var info_x = center_x - 200
		var info_y = center_y - 150
		
		draw_string(ThemeDB.fallback_font, Vector2(info_x, info_y), "Current L-System: " + current_lsystem.capitalize(), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, COLOR_TEXT)
		draw_string(ThemeDB.fallback_font, Vector2(info_x, info_y + 25), "Angle: " + str(lsystem_angle) + "°", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, COLOR_TEXT)
		draw_string(ThemeDB.fallback_font, Vector2(info_x, info_y + 50), "Iterations: " + str(LSYSTEM_ITERATIONS), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, COLOR_TEXT)

func draw_dungeon(center_x, center_y, scale_factor = 1.0):
	if dungeon_grid.size() == 0:
		return
	
	# Calculate grid dimensions
	var grid_width = MAX_DUNGEON_WIDTH * CELL_SIZE * scale_factor
	var grid_height = MAX_DUNGEON_HEIGHT * CELL_SIZE * scale_factor
	var start_x = center_x - grid_width / 2
	var start_y = center_y - grid_height / 2
	
	# Draw dungeon cells
	for y in range(MAX_DUNGEON_HEIGHT):
		for x in range(MAX_DUNGEON_WIDTH):
			var cell_type = dungeon_grid[y][x]
			var cell_color
			
			match cell_type:
				CELL_WALL:
					cell_color = COLOR_WALL
				CELL_FLOOR:
					cell_color = COLOR_FLOOR
				CELL_CORRIDOR:
					cell_color = COLOR_CORRIDOR
				CELL_DOOR:
					cell_color = COLOR_DOOR
			
			var cell_x = start_x + x * CELL_SIZE * scale_factor
			var cell_y = start_y + y * CELL_SIZE * scale_factor
			var cell_rect = Rect2(cell_x, cell_y, CELL_SIZE * scale_factor, CELL_SIZE * scale_factor)
			
			draw_rect(cell_rect, cell_color)
	
	# Draw dungeon information
	if scale_factor > 0.9:  # Only show info at full scale
		var info_x = start_x + grid_width + 20
		var info_y = start_y
		
		draw_string(ThemeDB.fallback_font, Vector2(info_x, info_y), "Dungeon Generation", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, COLOR_TEXT)
		draw_string(ThemeDB.fallback_font, Vector2(info_x, info_y + 25), "Algorithm: BSP Tree", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, COLOR_TEXT)
		draw_string(ThemeDB.fallback_font, Vector2(info_x, info_y + 50), "Rooms: " + str(dungeon_rooms.size()), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, COLOR_TEXT)
		draw_string(ThemeDB.fallback_font, Vector2(info_x, info_y + 75), "Connectivity: " + str(dungeon_connectivity), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, COLOR_TEXT)
		
		# Draw color legend
		var legend_y = info_y + 120
		
		var box_size = 15
		var box_rect = Rect2(info_x, legend_y, box_size, box_size)
		draw_rect(box_rect, COLOR_WALL)
		draw_rect(box_rect, Color.WHITE, false)
		draw_string(ThemeDB.fallback_font, Vector2(info_x + box_size + 10, legend_y + box_size/2 + 5), "Wall", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, COLOR_TEXT)
		
		box_rect = Rect2(info_x, legend_y + 25, box_size, box_size)
		draw_rect(box_rect, COLOR_FLOOR)
		draw_rect(box_rect, Color.WHITE, false)
		draw_string(ThemeDB.fallback_font, Vector2(info_x + box_size + 10, legend_y + 25 + box_size/2 + 5), "Room", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, COLOR_TEXT)
		
		box_rect = Rect2(info_x, legend_y + 50, box_size, box_size)
		draw_rect(box_rect, COLOR_CORRIDOR)
		draw_rect(box_rect, Color.WHITE, false)
		draw_string(ThemeDB.fallback_font, Vector2(info_x + box_size + 10, legend_y + 50 + box_size/2 + 5), "Corridor", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, COLOR_TEXT)
		
		box_rect = Rect2(info_x, legend_y + 75, box_size, box_size)
		draw_rect(box_rect, COLOR_DOOR)
		draw_rect(box_rect, Color.WHITE, false)
		draw_string(ThemeDB.fallback_font, Vector2(info_x + box_size + 10, legend_y + 75 + box_size/2 + 5), "Door", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, COLOR_TEXT)

func draw_advanced(center_x, center_y):
	# This visualization combines multiple procedural techniques
	# For now, we'll just cycle between the three main visualizations
	var cycle_duration = 6.0
	var phase = fmod(time_elapsed, cycle_duration * 3) / cycle_duration
	
	if phase < 1.0:
		draw_string(ThemeDB.fallback_font, Vector2(center_x, 20), "Combined Procedural Generation: Terrain", HORIZONTAL_ALIGNMENT_CENTER, -1, 16, COLOR_TEXT)
		draw_noise_terrain(center_x, center_y)
	elif phase < 2.0:
		draw_string(ThemeDB.fallback_font, Vector2(center_x, 20), "Combined Procedural Generation: L-System", HORIZONTAL_ALIGNMENT_CENTER, -1, 16, COLOR_TEXT)
		draw_lsystem(center_x, center_y)
	else:
		draw_string(ThemeDB.fallback_font, Vector2(center_x, 20), "Combined Procedural Generation: Dungeon", HORIZONTAL_ALIGNMENT_CENTER, -1, 16, COLOR_TEXT)
		draw_dungeon(center_x, center_y)

# Helper function to draw section labels
func draw_section_label(x, y, text):
	draw_string(ThemeDB.fallback_font, Vector2(x, y), text, HORIZONTAL_ALIGNMENT_CENTER, -1, 14, COLOR_TEXT)

# Generation functions
func generate_lsystem(lsystem_data):
	var axiom = lsystem_data.axiom
	var rules = lsystem_data.rules
	var iterations = lsystem_data.iterations
	lsystem_angle = lsystem_data.angle
	
	# Generate L-system string
	lsystem_string = axiom
	
	for i in range(iterations):
		var next_string = ""
		
		for c in lsystem_string:
			if rules.has(c):
				next_string += rules[c]
			else:
				next_string += c
		
		lsystem_string = next_string
	
	# Create command list for drawing
	lsystem_commands = []
	for c in lsystem_string:
		lsystem_commands.append(c)

func generate_dungeon():
	# Clear previous dungeon
	dungeon_rooms = []
	dungeon_corridors = []
	
	# Reset dungeon grid
	for y in range(MAX_DUNGEON_HEIGHT):
		for x in range(MAX_DUNGEON_WIDTH):
			dungeon_grid[y][x] = CELL_WALL
	
	# Create a BSP tree for room placement
	var root = {
		"x": 0,
		"y": 0,
		"width": MAX_DUNGEON_WIDTH,
		"height": MAX_DUNGEON_HEIGHT,
		"room": null,
		"left_child": null,
		"right_child": null
	}
	
	# Split the space recursively
	split_bsp_node(root, 0)
	
	# Create rooms in leaf nodes
	create_rooms_in_bsp(root)
	
	# Connect rooms with corridors
	connect_rooms_in_bsp(root)

func split_bsp_node(node, depth):
	# Define max depth for splitting
	var max_depth = 4
	
	if depth >= max_depth:
		return
	
	# Decide whether to split horizontally or vertically
	var split_horizontal = rng.randf() > 0.5
	
	# If one dimension is much larger, prefer to split along that dimension
	if node.width > node.height && node.width / node.height >= 1.5:
		split_horizontal = false
	elif node.height > node.width && node.height / node.width >= 1.5:
		split_horizontal = true
	
	# Calculate minimum size for child nodes
	var min_size = MIN_ROOM_SIZE + 2  # Extra space for walls
	
	# Calculate maximum possible split position
	var max_split = 0
	if split_horizontal:
		max_split = node.height - min_size
	else:
		max_split = node.width - min_size
	
	# If we can't split further, stop here
	if max_split < min_size:
		return
	
	# Determine split position (not too close to edges)
	var split = min_size + rng.randi() % (max_split - min_size + 1)
	
	# Create child nodes based on split
	if split_horizontal:
		node.left_child = {
			"x": node.x,
			"y": node.y,
			"width": node.width,
			"height": split,
			"room": null,
			"left_child": null,
			"right_child": null
		}
		
		node.right_child = {
			"x": node.x,
			"y": node.y + split,
			"width": node.width,
			"height": node.height - split,
			"room": null,
			"left_child": null,
			"right_child": null
		}
	else:
		node.left_child = {
			"x": node.x,
			"y": node.y,
			"width": split,
			"height": node.height,
			"room": null,
			"left_child": null,
			"right_child": null
		}
		
		node.right_child = {
			"x": node.x + split,
			"y": node.y,
			"width": node.width - split,
			"height": node.height,
			"room": null,
			"left_child": null,
			"right_child": null
		}
	
	# Recursively split children
	split_bsp_node(node.left_child, depth + 1)
	split_bsp_node(node.right_child, depth + 1)

# Continuation of create_rooms_in_bsp function
func create_rooms_in_bsp(node):
	# If this is a leaf node, create a room
	if node.left_child == null && node.right_child == null:
		# Determine room size and position within the node
		var room_width = MIN_ROOM_SIZE + rng.randi() % (min(MAX_ROOM_SIZE, node.width - 2) - MIN_ROOM_SIZE + 1)
		var room_height = MIN_ROOM_SIZE + rng.randi() % (min(MAX_ROOM_SIZE, node.height - 2) - MIN_ROOM_SIZE + 1)
		
		var room_x = node.x + rng.randi() % (node.width - room_width - 1) + 1
		var room_y = node.y + rng.randi() % (node.height - room_height - 1) + 1
		
		node.room = {
			"x": room_x,
			"y": room_y,
			"width": room_width,
			"height": room_height
		}
		
		# Add the room to our list
		dungeon_rooms.append(node.room)
		
		# Fill the room in the grid
		for y in range(room_y, room_y + room_height):
			for x in range(room_x, room_x + room_width):
				if y >= 0 && y < MAX_DUNGEON_HEIGHT && x >= 0 && x < MAX_DUNGEON_WIDTH:
					dungeon_grid[y][x] = CELL_FLOOR
	else:
		# Recursively create rooms in children
		if node.left_child:
			create_rooms_in_bsp(node.left_child)
		if node.right_child:
			create_rooms_in_bsp(node.right_child)

func connect_rooms_in_bsp(node):
	# If this node has two children with rooms, connect them
	if node.left_child != null && node.right_child != null:
		# First, recursively connect rooms in the children
		connect_rooms_in_bsp(node.left_child)
		connect_rooms_in_bsp(node.right_child)
		
		# Then connect one room from the left child to one room from the right child
		var left_room = find_room(node.left_child)
		var right_room = find_room(node.right_child)
		
		if left_room != null && right_room != null:
			# Create corridor between the rooms
			create_corridor(left_room, right_room)
	
	# Randomly create additional corridors based on connectivity parameter
	if dungeon_rooms.size() > 1 && rng.randf() < dungeon_connectivity:
		var room1 = dungeon_rooms[rng.randi() % dungeon_rooms.size()]
		var room2 = dungeon_rooms[rng.randi() % dungeon_rooms.size()]
		
		# Make sure we don't connect a room to itself
		if room1 != room2:
			create_corridor(room1, room2)

func find_room(node):
	# If this node has a room, return it
	if node.room != null:
		return node.room
	
	# Otherwise, look in the children
	var room = null
	if node.left_child != null:
		room = find_room(node.left_child)
	
	if room == null && node.right_child != null:
		room = find_room(node.right_child)
	
	return room

func create_corridor(room1, room2):
	# Find center points of rooms
	var center1_x = room1.x + room1.width / 2
	var center1_y = room1.y + room1.height / 2
	var center2_x = room2.x + room2.width / 2
	var center2_y = room2.y + room2.height / 2
	
	# Choose a random point on the perimeter of each room
	var point1_x = room1.x
	var point1_y = room1.y
	var point2_x = room2.x
	var point2_y = room2.y
	
	# Select which side to use based on relative room positions
	if center1_x <= center2_x:
		# Room 1 is left of Room 2
		point1_x = room1.x + room1.width - 1
		point2_x = room2.x
	else:
		# Room 1 is right of Room 2
		point1_x = room1.x
		point2_x = room2.x + room2.width - 1
	
	if center1_y <= center2_y:
		# Room 1 is above Room 2
		point1_y = room1.y + room1.height - 1
		point2_y = room2.y
	else:
		# Room 1 is below Room 2
		point1_y = room1.y
		point2_y = room2.y + room2.height - 1
	
	# Adjust points to be within room boundaries
	point1_x = clamp(point1_x, room1.x, room1.x + room1.width - 1)
	point1_y = clamp(point1_y, room1.y, room1.y + room1.height - 1)
	point2_x = clamp(point2_x, room2.x, room2.x + room2.width - 1)
	point2_y = clamp(point2_y, room2.y, room2.y + room2.height - 1)
	
	# Create L-shaped corridor
	var corridor = {
		"start_x": point1_x,
		"start_y": point1_y,
		"mid_x": point1_x,
		"mid_y": point2_y,
		"end_x": point2_x,
		"end_y": point2_y
	}
	
	# Randomly choose horizontal-first or vertical-first corridor
	if rng.randf() > 0.5:
		corridor.mid_x = point2_x
		corridor.mid_y = point1_y
	
	dungeon_corridors.append(corridor)
	
	# Create corridor in grid
	# First segment
	var x1 = min(corridor.start_x, corridor.mid_x)
	var x2 = max(corridor.start_x, corridor.mid_x)
	var y1 = min(corridor.start_y, corridor.mid_y)
	var y2 = max(corridor.start_y, corridor.mid_y)
	
	for x in range(x1, x2 + 1):
		for y in range(y1, y2 + 1):
			if y >= 0 && y < MAX_DUNGEON_HEIGHT && x >= 0 && x < MAX_DUNGEON_WIDTH:
				if dungeon_grid[y][x] == CELL_WALL:
					dungeon_grid[y][x] = CELL_CORRIDOR
	
	# Second segment
	x1 = min(corridor.mid_x, corridor.end_x)
	x2 = max(corridor.mid_x, corridor.end_x)
	y1 = min(corridor.mid_y, corridor.end_y)
	y2 = max(corridor.mid_y, corridor.end_y)
	
	for x in range(x1, x2 + 1):
		for y in range(y1, y2 + 1):
			if y >= 0 && y < MAX_DUNGEON_HEIGHT && x >= 0 && x < MAX_DUNGEON_WIDTH:
				if dungeon_grid[y][x] == CELL_WALL:
					dungeon_grid[y][x] = CELL_CORRIDOR
	
	# Add doors where corridors meet rooms
	place_doors()

func place_doors():
	# Scan grid for potential door locations (corridor cells adjacent to room cells)
	for y in range(1, MAX_DUNGEON_HEIGHT - 1):
		for x in range(1, MAX_DUNGEON_WIDTH - 1):
			if dungeon_grid[y][x] == CELL_CORRIDOR:
				var has_room_neighbor = false
				var has_wall_neighbor = false
				
				# Check adjacent cells
				if dungeon_grid[y-1][x] == CELL_FLOOR || dungeon_grid[y+1][x] == CELL_FLOOR || \
				   dungeon_grid[y][x-1] == CELL_FLOOR || dungeon_grid[y][x+1] == CELL_FLOOR:
					has_room_neighbor = true
				
				if dungeon_grid[y-1][x] == CELL_WALL || dungeon_grid[y+1][x] == CELL_WALL || \
				   dungeon_grid[y][x-1] == CELL_WALL || dungeon_grid[y][x+1] == CELL_WALL:
					has_wall_neighbor = true
				
				# If this corridor cell connects a room to a corridor
				if has_room_neighbor && has_wall_neighbor:
					# Make it a door with a 30% chance
					if rng.randf() < 0.3:
						dungeon_grid[y][x] = CELL_DOOR

# Regeneration functions for parameter changes
func regenerate_terrain():
	initialize_noise_terrain()
	queue_redraw()

func regenerate_lsystem():
	# Re-initialize with current angle
	var lsystems = {
		"plant": {
			"axiom": "F",
			"rules": {"F": "F[+F]F[-F][F]"},
			"angle": lsystem_angle,
			"iterations": LSYSTEM_ITERATIONS
		},
		"tree": {
			"axiom": "F",
			"rules": {"F": "FF-[-F+F+F]+[+F-F-F]"},
			"angle": lsystem_angle,
			"iterations": LSYSTEM_ITERATIONS
		},
		"sierpinski": {
			"axiom": "F-G-G",
			"rules": {"F": "F-G+F+G-F", "G": "GG"},
			"angle": 120,
			"iterations": LSYSTEM_ITERATIONS
		},
		"dragon": {
			"axiom": "FX",
			"rules": {"X": "X+YF+", "Y": "-FX-Y"},
			"angle": 90,
			"iterations": LSYSTEM_ITERATIONS
		}
	}
	
	generate_lsystem(lsystems[current_lsystem])
	queue_redraw()

func regenerate_dungeon():
	generate_dungeon()
	queue_redraw()

# Cycle between different L-systems on click
func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if visualization_type == "lsystem" or (visualization_type == "advanced" and time_elapsed % 18.0 > 6.0 and time_elapsed % 18.0 < 12.0):
				# Cycle through L-systems
				var lsystems = ["plant", "tree", "sierpinski", "dragon"]
				var current_index = lsystems.find(current_lsystem)
				current_index = (current_index + 1) % lsystems.size()
				current_lsystem = lsystems[current_index]
				
				# Update L-system
				var lsystem_data = {
					"plant": {
						"axiom": "F",
						"rules": {"F": "F[+F]F[-F][F]"},
						"angle": lsystem_angle,
						"iterations": LSYSTEM_ITERATIONS
					},
					"tree": {
						"axiom": "F",
						"rules": {"F": "FF-[-F+F+F]+[+F-F-F]"},
						"angle": lsystem_angle,
						"iterations": LSYSTEM_ITERATIONS
					},
					"sierpinski": {
						"axiom": "F-G-G",
						"rules": {"F": "F-G+F+G-F", "G": "GG"},
						"angle": 120,
						"iterations": LSYSTEM_ITERATIONS
					},
					"dragon": {
						"axiom": "FX",
						"rules": {"X": "X+YF+", "Y": "-FX-Y"},
						"angle": 90,
						"iterations": LSYSTEM_ITERATIONS
					}
				}
				
				generate_lsystem(lsystem_data[current_lsystem])
				queue_redraw()
