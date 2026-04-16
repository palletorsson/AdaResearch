extends Node2D

# Pattern parameters
var P = {
	"tiles": 8,
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
	"add_new_row": false
}

var pattern_timer: Timer = null

# Directions for path generation
var directions = [
	Vector2(1, 0),
	Vector2(0, -1),
	Vector2(0, 1),
	Vector2(-1, 0),
]

var points_data = []
var mesh_instance: MeshInstance3D = null
var line_material: StandardMaterial3D = null

# Panel dimensions (wall-mounted, XY plane)
var panel_width: float = 0.7
var panel_height: float = 0.7

func _ready() -> void:
	randomize()

	# Create line material — unshaded with vertex colors and emission
	line_material = StandardMaterial3D.new()
	line_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	line_material.vertex_color_use_as_albedo = true
	line_material.emission_enabled = true
	line_material.emission = Color.WHITE
	line_material.emission_energy_multiplier = 0.6

	# Create mesh instance for ImmediateMesh line art
	mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "TileMateMesh"
	add_child(mesh_instance)

	# Label
	var label = Label3D.new()
	label.text = "Tile Mating Evolution"
	label.font_size = 48
	label.pixel_size = 0.001
	label.position = Vector3(0.0, panel_height * 0.5 + 0.04, 0.0)
	label.modulate = Color.WHITE
	add_child(label)

	generate_points_data()

	# Timer to shift patterns down and mate
	pattern_timer = Timer.new()
	add_child(pattern_timer)
	pattern_timer.wait_time = 0.1
	pattern_timer.connect("timeout", Callable(self, "shift_patterns_down"))
	pattern_timer.start()

func _rebuild_mesh() -> void:
	var im = ImmediateMesh.new()

	var block_step = panel_width / P.tiles
	var padding = block_step * P.padding
	var block_size = block_step - padding * 2.0

	var origin_offset = Vector2(-panel_width * 0.5, -panel_height * 0.5)

	im.surface_begin(Mesh.PRIMITIVE_LINES, line_material)

	for i in range(points_data.size()):
		var col = i % P.tiles
		var row = int(floor(float(i) / P.tiles))

		var pos = Vector2(
			origin_offset.x + col * block_step + padding,
			origin_offset.y + row * block_step + padding
		)

		_draw_mirrored_quadrants_im(im, points_data[i], block_size, pos)

	im.surface_end()
	mesh_instance.mesh = im

func _draw_mirrored_quadrants_im(im: ImmediateMesh, pd: Dictionary, size: float, offset: Vector2) -> void:
	var points = pd.points
	var colors = pd.colors
	var step = size / 2.0
	var center = Vector2(offset.x + step, offset.y + step)

	if P.symmetry == "reflect":
		var points_copy = points.duplicate()
		_quadrant_im(im, points_copy, colors, step, center)

		var points_reflect_v = []
		for p in points_copy:
			if p == null:
				points_reflect_v.append(null)
			else:
				points_reflect_v.append(Vector2(p.x, -p.y))
		_quadrant_im(im, points_reflect_v, colors, step, center)

		var points_reflect_h = []
		for p in points_copy:
			if p == null:
				points_reflect_h.append(null)
			else:
				points_reflect_h.append(Vector2(-p.x, p.y))
		_quadrant_im(im, points_reflect_h, colors, step, center)

		var points_reflect_both = []
		for p in points_copy:
			if p == null:
				points_reflect_both.append(null)
			else:
				points_reflect_both.append(Vector2(-p.x, -p.y))
		_quadrant_im(im, points_reflect_both, colors, step, center)

	elif P.symmetry == "rotate":
		_quadrant_im(im, points, colors, step, center)

		var rotated_points = []
		for p in points:
			if p == null:
				rotated_points.append(null)
			else:
				rotated_points.append(Vector2(-p.y, p.x))
		_quadrant_im(im, rotated_points, colors, step, center)

		rotated_points = []
		for p in points:
			if p == null:
				rotated_points.append(null)
			else:
				rotated_points.append(Vector2(-p.x, -p.y))
		_quadrant_im(im, rotated_points, colors, step, center)

		rotated_points = []
		for p in points:
			if p == null:
				rotated_points.append(null)
			else:
				rotated_points.append(Vector2(p.y, -p.x))
		_quadrant_im(im, rotated_points, colors, step, center)

func _quadrant_im(im: ImmediateMesh, points: Array, colors: Array, size: float, offset: Vector2) -> void:
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

		var line_color = Color.WHITE
		if i <= colors.size() and colors[i - 1] != null:
			line_color = colors[i - 1]

		im.surface_set_color(line_color)
		im.surface_add_vertex(Vector3(offset.x + x1, -(offset.y + y1), 0.0))
		im.surface_set_color(line_color)
		im.surface_add_vertex(Vector3(offset.x + x2, -(offset.y + y2), 0.0))

func get_points() -> Dictionary:
	var x = int(P.startPoint.x)
	var y = int(P.startPoint.y)
	var points = [Vector2(x, y)]
	var edges = {}
	var x_max = P.innerGrid
	var y_max = P.innerGrid
	var colors = []

	var get_edges = func(ex, ey):
		var key = str(ex) + "-" + str(ey)
		if not edges.has(key):
			edges[key] = []
		return edges[key]

	var i = 0
	var points_count = 0
	var need_to_push_point1 = false

	while i < P.edgesAttempts and points_count < P.edgesMax:
		var visited = get_edges.call(x, y)
		var options = []

		for dir in directions:
			var new_x = x + int(dir.x)
			var new_y = y + int(dir.y)

			if new_x < 0 or new_x > x_max:
				continue
			if new_y < 0 or new_y > y_max:
				continue

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
			points.append(null)
			points.append(Vector2(x, y))
			colors.append(null)
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
		colors.append(P.colors[randi() % P.colors.size()])
		points_count += 1
		i += 1

		if i % P.edgesBreak == 0:
			points.append(null)
			colors.append(null)
			x = randi() % (x_max + 1)
			y = randi() % (y_max + 1)
			need_to_push_point1 = true

	return {"points": points, "edges": edges, "colors": colors}

func generate_points_data() -> void:
	points_data = []
	for i in range(P.tiles * P.tiles):
		points_data.append(get_points())

	# Initial mating of patterns to create interesting starting patterns
	mate_patterns(points_data, P.tiles, P.tiles)
	_rebuild_mesh()

func shift_patterns_down() -> void:
	var grid_width = P.tiles
	var grid_height = P.tiles

	var new_points_data = []

	# Generate a new top row if add_new_row is true
	if P.add_new_row:
		for i in range(grid_width):
			new_points_data.append(get_points())

	var start_row = 0
	var end_row = grid_height

	if P.add_new_row:
		end_row -= 1

	for y in range(start_row, end_row):
		for x in range(grid_width):
			var index = y * grid_width + x
			if index < points_data.size():
				new_points_data.append(points_data[index])

	# Fill missing patterns to maintain grid size
	if not P.add_new_row and new_points_data.size() < grid_width * grid_height:
		var missing = (grid_width * grid_height) - new_points_data.size()
		for i in range(missing):
			new_points_data.append(get_points())

	# Mate patterns with random neighbors
	mate_patterns(new_points_data, grid_width, grid_height)

	points_data = new_points_data
	_rebuild_mesh()

	# Randomly toggle the add_new_row flag with 30% chance
	if randf() < 0.3:
		P.add_new_row = not P.add_new_row

func mate_patterns(data: Array, width: int, height: int) -> void:
	for y in range(height):
		for x in range(width):
			var index = y * width + x

			# Skip mating with 20% probability to maintain diversity
			if randf() < 0.2:
				continue

			var neighbors = []

			if x > 0:
				neighbors.append((y * width) + (x - 1))
			if x < width - 1:
				neighbors.append((y * width) + (x + 1))
			if y > 0:
				neighbors.append(((y - 1) * width) + x)
			if y < height - 1:
				neighbors.append(((y + 1) * width) + x)

			if neighbors.size() > 0:
				var neighbor_idx = neighbors[randi() % neighbors.size()]

				if neighbor_idx >= data.size():
					continue

				data[index] = mate_two_patterns(data[index], data[neighbor_idx])

func mate_two_patterns(pattern1: Dictionary, pattern2: Dictionary) -> Dictionary:
	var result = {}

	var inherit_points_from_first = randf() < 0.5

	if inherit_points_from_first:
		result.points = pattern1.points.duplicate()
		result.edges = pattern1.edges.duplicate()

		var colors = []
		var p2_colors = pattern2.colors

		for i in range(result.points.size()):
			if i < p2_colors.size():
				colors.append(p2_colors[i])
			else:
				colors.append(P.colors[randi() % P.colors.size()])

		result.colors = colors
	else:
		result.points = pattern2.points.duplicate()
		result.edges = pattern2.edges.duplicate()

		var colors = []
		var p1_colors = pattern1.colors

		for i in range(result.points.size()):
			if i < p1_colors.size():
				colors.append(p1_colors[i])
			else:
				colors.append(P.colors[randi() % P.colors.size()])

		result.colors = colors

	# Occasionally mutate by changing some random colors (10% chance)
	if randf() < 0.1:
		for i in range(result.colors.size()):
			if randf() < 0.2:
				result.colors[i] = P.colors[randi() % P.colors.size()]

	return result

func apply_grid_config(config: Dictionary) -> void:
	pass

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()
