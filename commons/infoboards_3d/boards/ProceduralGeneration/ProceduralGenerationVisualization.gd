# ProceduralGenerationVisualization.gd
# Visualization component for procedural generation concepts
extends Control

var visualization_type = "intro"
var animation_playing = true
var time = 0.0

# Noise parameters
var noise_seed = 0
var noise_scale = 0.05
var noise_octaves = 4

# L-system parameters
var lsystem_angle = 25.0
var lsystem_iterations = 4

# BSP parameters
var bsp_rooms = []

# Cached noise for terrain
var noise_generator: FastNoiseLite = null

func _ready():
	setup_noise()
	setup_bsp()

func _process(delta):
	if animation_playing:
		time += delta
	queue_redraw()

func set_animation_playing(playing: bool):
	animation_playing = playing

func setup_noise():
	noise_generator = FastNoiseLite.new()
	noise_generator.seed = randi()
	noise_generator.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise_generator.fractal_octaves = noise_octaves
	noise_generator.frequency = noise_scale

func setup_bsp():
	# Generate a simple BSP dungeon
	bsp_rooms = []
	var root_rect = Rect2(50, 50, 400, 300)
	generate_bsp_rooms(root_rect, 0, 3)

func generate_bsp_rooms(rect: Rect2, depth: int, max_depth: int):
	if depth >= max_depth or rect.size.x < 80 or rect.size.y < 80:
		# Leaf node - create a room
		var margin = 10
		var room = Rect2(
			rect.position.x + margin,
			rect.position.y + margin,
			rect.size.x - margin * 2,
			rect.size.y - margin * 2
		)
		bsp_rooms.append(room)
		return

	# Split horizontally or vertically
	var horizontal = randf() > 0.5

	if horizontal:
		var split_y = rect.position.y + rect.size.y * (0.4 + randf() * 0.2)
		var rect1 = Rect2(rect.position.x, rect.position.y, rect.size.x, split_y - rect.position.y)
		var rect2 = Rect2(rect.position.x, split_y, rect.size.x, rect.position.y + rect.size.y - split_y)
		generate_bsp_rooms(rect1, depth + 1, max_depth)
		generate_bsp_rooms(rect2, depth + 1, max_depth)
	else:
		var split_x = rect.position.x + rect.size.x * (0.4 + randf() * 0.2)
		var rect1 = Rect2(rect.position.x, rect.position.y, split_x - rect.position.x, rect.size.y)
		var rect2 = Rect2(split_x, rect.position.y, rect.position.x + rect.size.x - split_x, rect.size.y)
		generate_bsp_rooms(rect1, depth + 1, max_depth)
		generate_bsp_rooms(rect2, depth + 1, max_depth)

func _draw():
	var center_x = size.x / 2
	var center_y = size.y / 2

	match visualization_type:
		"intro":
			draw_intro_visualization(center_x, center_y)
		"noise_terrain":
			draw_noise_terrain(center_x, center_y)
		"lsystem":
			draw_lsystem(center_x, center_y)
		"dungeon":
			draw_dungeon_visualization(center_x, center_y)
		"advanced":
			draw_advanced_visualization(center_x, center_y)

func draw_intro_visualization(center_x: float, center_y: float):
	# Draw a grid pattern that shifts procedurally
	var grid_size = 20
	var offset = int(time * 20) % grid_size

	for x in range(0, int(size.x) + grid_size, grid_size):
		for y in range(0, int(size.y) + grid_size, grid_size):
			var px = (x + offset) % int(size.x)
			var py = (y + offset) % int(size.y)

			var hash_val = (px * 73 + py * 37) % 255
			var brightness = hash_val / 255.0
			var color = Color(brightness * 0.3, brightness * 0.8, brightness * 0.5)

			draw_rect(Rect2(px, py, grid_size - 2, grid_size - 2), color)

	# Label
	draw_string(get_theme_default_font(), Vector2(20, 30), "Procedural Pattern Grid", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)

func draw_noise_terrain(center_x: float, center_y: float):
	if not noise_generator:
		setup_noise()

	# Update noise seed over time
	if animation_playing and int(time) % 3 == 0:
		noise_generator.seed = int(time / 3.0)

	# Draw heightmap
	var cell_size = 8
	for x in range(0, int(size.x), cell_size):
		for y in range(0, int(size.y), cell_size):
			var noise_val = noise_generator.get_noise_2d(x, y)
			var height = (noise_val + 1.0) / 2.0  # Normalize to 0-1

			# Color based on height
			var color: Color
			if height < 0.3:
				color = Color(0.1, 0.2, 0.6)  # Water
			elif height < 0.5:
				color = Color(0.2, 0.6, 0.2)  # Grass
			elif height < 0.7:
				color = Color(0.4, 0.5, 0.3)  # Hills
			else:
				color = Color(0.8, 0.8, 0.9)  # Mountains

			draw_rect(Rect2(x, y, cell_size, cell_size), color)

	# Label
	draw_string(get_theme_default_font(), Vector2(20, 30), "Noise-Based Terrain", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)

func draw_lsystem(center_x: float, center_y: float):
	# Generate L-system string
	var axiom = "F"
	var rules = {"F": "F[+F]F[-F]F"}
	var current = axiom

	var iterations = min(4, int(lsystem_iterations))
	for i in range(iterations):
		var next = ""
		for c in current:
			if c in rules:
				next += rules[c]
			else:
				next += c
		current = next

	# Draw using turtle graphics
	var pos = Vector2(center_x, size.y - 50)
	var angle = -90.0  # Start pointing up
	var length = 100.0 / pow(2, iterations)
	var stack = []

	for c in current:
		match c:
			"F":
				var new_pos = pos + Vector2(cos(deg_to_rad(angle)), sin(deg_to_rad(angle))) * length
				draw_line(pos, new_pos, Color(0.3, 0.8, 0.5), 2)
				pos = new_pos
			"+":
				angle -= lsystem_angle + sin(time) * 5
			"-":
				angle += lsystem_angle + sin(time) * 5
			"[":
				stack.append([pos, angle])
			"]":
				if stack.size() > 0:
					var state = stack.pop_back()
					pos = state[0]
					angle = state[1]

	# Label
	draw_string(get_theme_default_font(), Vector2(20, 30), "L-System Plant Growth", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)

func draw_dungeon_visualization(center_x: float, center_y: float):
	# Draw BSP rooms
	for room in bsp_rooms:
		# Room floor
		draw_rect(room, Color(0.3, 0.3, 0.4))
		# Room border
		draw_rect(room, Color(0.6, 0.8, 0.9), false, 2)

	# Highlight one room with animation
	if bsp_rooms.size() > 0:
		var highlight_index = int(time) % bsp_rooms.size()
		var highlight_room = bsp_rooms[highlight_index]
		var pulse = (sin(time * 3) + 1) / 2
		draw_rect(highlight_room, Color(0.3, 0.8, 0.5, 0.3 + pulse * 0.3))

	# Label
	draw_string(get_theme_default_font(), Vector2(20, 30), "BSP Dungeon Layout", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)

func draw_advanced_visualization(center_x: float, center_y: float):
	# Combine multiple techniques
	# Background: noise-based colors
	var cell_size = 16
	for x in range(0, int(size.x), cell_size):
		for y in range(0, int(size.y), cell_size):
			if noise_generator:
				var noise_val = noise_generator.get_noise_2d(x * 0.5, y * 0.5)
				var brightness = (noise_val + 1.0) / 2.0
				draw_rect(Rect2(x, y, cell_size, cell_size), Color(brightness * 0.2, brightness * 0.4, brightness * 0.6, 0.5))

	# Overlay: procedural circles (Voronoi-like)
	var num_points = 8
	for i in range(num_points):
		var px = center_x + cos(time * 0.5 + i * TAU / num_points) * 150
		var py = center_y + sin(time * 0.5 + i * TAU / num_points) * 100
		var radius = 30 + sin(time + i) * 10
		draw_circle(Vector2(px, py), radius, Color(0.3, 0.8, 0.5, 0.3))
		draw_arc(Vector2(px, py), radius, 0, TAU, 32, Color(0.3, 0.8, 0.5), 2)

	# Label
	draw_string(get_theme_default_font(), Vector2(20, 30), "Combined Techniques", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)
