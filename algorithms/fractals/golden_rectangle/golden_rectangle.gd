extends Node3D

## Golden Rectangle Subdivider
## Recursively subdivides a rectangle using the golden ratio (φ ≈ 1.618)
## Each subdivision creates a square and a smaller golden rectangle
## Visualizes the classic Fibonacci spiral construction

@export_group("Rectangle")
@export var initial_width := 5.0
@export var max_subdivisions := 10
@export var extrusion_height := 0.1  # 3D depth of rectangles

@export_group("Animation")
@export var animate := true
@export var subdivision_delay := 0.6  # Seconds between subdivisions
@export var spiral_draw_speed := 2.0  # How fast spiral draws

@export_group("Appearance")
@export var use_fibonacci_colors := true  # Color by Fibonacci number
@export var base_hue := 0.0  # Starting hue (0 = red)
@export var hue_shift_per_level := 0.08
@export var show_spiral := true
@export var show_numbers := true
@export var spiral_color := Color(1.0, 0.84, 0.0)  # Gold
@export var outline_color := Color(0.1, 0.1, 0.1)

# Constants
var PHI := (1.0 + sqrt(5.0)) / 2.0  # Golden ratio ≈ 1.618
var fibonacci := [1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144]

# State
var rectangles: Array[Dictionary] = []  # {corners, level, fib_number, center}
var current_subdivision := 0
var subdivision_timer := 0.0
var is_animating := false
var spiral_progress := 0.0

# Visual nodes
var rectangles_parent: Node3D
var spiral_mesh: MeshInstance3D
var labels_parent: Node3D

signal subdivision_complete(level: int, fib_number: int)
signal all_subdivisions_complete()

func _ready() -> void:
	_setup_containers()
	_initialize_rectangle()

	if animate:
		is_animating = true
	else:
		_generate_all_subdivisions()

func _setup_containers() -> void:
	rectangles_parent = Node3D.new()
	rectangles_parent.name = "Rectangles"
	add_child(rectangles_parent)

	labels_parent = Node3D.new()
	labels_parent.name = "Labels"
	add_child(labels_parent)

func _process(delta: float) -> void:
	if is_animating:
		subdivision_timer += delta
		if subdivision_timer >= subdivision_delay:
			subdivision_timer = 0.0
			_perform_subdivision()

	# Animate spiral drawing
	if show_spiral and spiral_progress < 1.0:
		spiral_progress += delta * spiral_draw_speed / max_subdivisions
		spiral_progress = min(spiral_progress, 1.0)
		_update_spiral()

func _initialize_rectangle() -> void:
	"""Create the initial golden rectangle"""
	rectangles.clear()

	# Golden rectangle: width = φ * height
	var height = initial_width / PHI
	var half_w = initial_width / 2.0
	var half_h = height / 2.0

	var rect = {
		"x": -half_w,
		"y": -half_h,
		"width": initial_width,
		"height": height,
		"level": 0,
		"fib_index": 0,
		"direction": 0  # 0=right, 1=up, 2=left, 3=down (which way to cut square)
	}

	rectangles.append(rect)
	_create_rectangle_visual(rect, true)  # true = it's the current golden rectangle

	print("GoldenRectangle: Initialized %.2f x %.2f (ratio: %.4f)" % [initial_width, height, initial_width / height])

func _perform_subdivision() -> void:
	"""Subdivide the current golden rectangle"""
	if current_subdivision >= max_subdivisions:
		is_animating = false
		all_subdivisions_complete.emit()
		print("GoldenRectangle: All %d subdivisions complete" % current_subdivision)
		return

	# Find the current golden rectangle (last one added that isn't a square)
	var golden_rect = rectangles.back()

	# Calculate the square and new golden rectangle
	var square: Dictionary
	var new_golden: Dictionary

	var w = golden_rect.width
	var h = golden_rect.height
	var x = golden_rect.x
	var y = golden_rect.y
	var dir = golden_rect.direction

	# The square's side length is the shorter dimension
	var square_size = min(w, h)

	# Determine orientation and create square + new golden rectangle
	if w > h:
		# Horizontal rectangle - cut square from left or right
		if dir == 0:  # Cut from left
			square = {
				"x": x,
				"y": y,
				"width": square_size,
				"height": square_size,
				"level": current_subdivision + 1,
				"fib_index": current_subdivision,
				"is_square": true,
				"direction": dir
			}
			new_golden = {
				"x": x + square_size,
				"y": y,
				"width": w - square_size,
				"height": h,
				"level": current_subdivision + 1,
				"fib_index": current_subdivision + 1,
				"direction": 1  # Next cut goes up
			}
		else:  # Cut from right (dir == 2)
			square = {
				"x": x + w - square_size,
				"y": y,
				"width": square_size,
				"height": square_size,
				"level": current_subdivision + 1,
				"fib_index": current_subdivision,
				"is_square": true,
				"direction": dir
			}
			new_golden = {
				"x": x,
				"y": y,
				"width": w - square_size,
				"height": h,
				"level": current_subdivision + 1,
				"fib_index": current_subdivision + 1,
				"direction": 3  # Next cut goes down
			}
	else:
		# Vertical rectangle - cut square from top or bottom
		if dir == 1:  # Cut from bottom
			square = {
				"x": x,
				"y": y,
				"width": square_size,
				"height": square_size,
				"level": current_subdivision + 1,
				"fib_index": current_subdivision,
				"is_square": true,
				"direction": dir
			}
			new_golden = {
				"x": x,
				"y": y + square_size,
				"width": w,
				"height": h - square_size,
				"level": current_subdivision + 1,
				"fib_index": current_subdivision + 1,
				"direction": 2  # Next cut goes left
			}
		else:  # Cut from top (dir == 3)
			square = {
				"x": x,
				"y": y + h - square_size,
				"width": square_size,
				"height": square_size,
				"level": current_subdivision + 1,
				"fib_index": current_subdivision,
				"is_square": true,
				"direction": dir
			}
			new_golden = {
				"x": x,
				"y": y,
				"width": w,
				"height": h - square_size,
				"level": current_subdivision + 1,
				"fib_index": current_subdivision + 1,
				"direction": 0  # Next cut goes right
			}

	# Remove old golden rectangle visual and add new ones
	rectangles.append(square)
	rectangles.append(new_golden)

	_create_rectangle_visual(square, false)
	_create_rectangle_visual(new_golden, true)

	# Get Fibonacci number for this level
	var fib_num = fibonacci[min(current_subdivision, fibonacci.size() - 1)]

	current_subdivision += 1
	subdivision_complete.emit(current_subdivision, fib_num)

	print("GoldenRectangle: Subdivision %d - Square %.2f, Fib: %d" % [current_subdivision, square_size, fib_num])

func _create_rectangle_visual(rect: Dictionary, is_golden: bool) -> void:
	"""Create 3D visual for a rectangle"""
	var mesh_instance = MeshInstance3D.new()

	# Create box mesh
	var box = BoxMesh.new()
	box.size = Vector3(rect.width, extrusion_height, rect.height)
	mesh_instance.mesh = box

	# Position at center of rectangle
	var center_x = rect.x + rect.width / 2.0
	var center_y = rect.y + rect.height / 2.0
	var height_offset = rect.level * extrusion_height * 0.5  # Stack slightly
	mesh_instance.position = Vector3(center_x, height_offset, center_y)

	# Material with color based on level
	var material = StandardMaterial3D.new()

	if use_fibonacci_colors:
		var hue = fmod(base_hue + rect.level * hue_shift_per_level, 1.0)
		var saturation = 0.7 if rect.get("is_square", false) else 0.5
		var value = 0.9 if is_golden else 0.8
		material.albedo_color = Color.from_hsv(hue, saturation, value)
	else:
		material.albedo_color = Color(0.8, 0.8, 0.8) if rect.get("is_square", false) else Color(0.6, 0.6, 0.6)

	if is_golden:
		material.emission_enabled = true
		material.emission = material.albedo_color * 0.2

	mesh_instance.material_override = material
	mesh_instance.name = "Rect_L%d" % rect.level

	rectangles_parent.add_child(mesh_instance)

	# Add outline
	_add_rectangle_outline(rect, height_offset)

	# Add Fibonacci number label
	if show_numbers and rect.get("is_square", false):
		_add_number_label(rect, height_offset)

func _add_rectangle_outline(rect: Dictionary, height: float) -> void:
	"""Add outline edges to rectangle"""
	var line_mesh = ImmediateMesh.new()
	var mesh_instance = MeshInstance3D.new()

	var x0 = rect.x
	var x1 = rect.x + rect.width
	var y0 = rect.y
	var y1 = rect.y + rect.height
	var h = height + extrusion_height * 0.51

	# Create line strip for outline
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_LINE_STRIP)
	surface_tool.set_color(outline_color)

	surface_tool.add_vertex(Vector3(x0, h, y0))
	surface_tool.add_vertex(Vector3(x1, h, y0))
	surface_tool.add_vertex(Vector3(x1, h, y1))
	surface_tool.add_vertex(Vector3(x0, h, y1))
	surface_tool.add_vertex(Vector3(x0, h, y0))  # Close the loop

	mesh_instance.mesh = surface_tool.commit()

	var material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = outline_color
	mesh_instance.material_override = material

	rectangles_parent.add_child(mesh_instance)

func _add_number_label(rect: Dictionary, height: float) -> void:
	"""Add Fibonacci number label to square"""
	var fib_index = rect.fib_index
	if fib_index >= fibonacci.size():
		return

	var number = fibonacci[fib_index]

	var label = Label3D.new()
	label.text = str(number)
	label.font_size = max(32, int(rect.width * 20))
	label.position = Vector3(
		rect.x + rect.width / 2.0,
		height + extrusion_height + 0.1,
		rect.y + rect.height / 2.0
	)
	label.rotation_degrees = Vector3(-90, 0, 0)  # Face up
	label.pixel_size = 0.01
	label.modulate = Color(0.1, 0.1, 0.1)
	label.outline_size = 8
	label.outline_modulate = Color(1, 1, 1, 0.5)

	labels_parent.add_child(label)

func _update_spiral() -> void:
	"""Update the golden spiral visualization"""
	if spiral_mesh:
		spiral_mesh.queue_free()

	if rectangles.size() < 2:
		return

	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_LINE_STRIP)
	surface_tool.set_color(spiral_color)

	# Calculate spiral points through each square
	var total_points = int(current_subdivision * 20 * spiral_progress)
	var points_per_square = 20

	for i in range(rectangles.size()):
		var rect = rectangles[i]
		if not rect.get("is_square", false):
			continue

		var square_index = rect.fib_index
		if square_index * points_per_square > total_points:
			break

		# Calculate arc for this square
		var cx: float  # Arc center x
		var cy: float  # Arc center y
		var radius = rect.width
		var start_angle: float
		var dir = rect.direction

		# Determine arc center and start angle based on direction
		match dir:
			0:  # Square on left, arc from bottom-right
				cx = rect.x + rect.width
				cy = rect.y + rect.height
				start_angle = PI
			1:  # Square on bottom, arc from top-right
				cx = rect.x + rect.width
				cy = rect.y
				start_angle = PI * 0.5
			2:  # Square on right, arc from top-left
				cx = rect.x
				cy = rect.y
				start_angle = 0
			3:  # Square on top, arc from bottom-left
				cx = rect.x
				cy = rect.y + rect.height
				start_angle = PI * 1.5

		# Generate arc points
		var points_for_this_square = min(points_per_square, total_points - square_index * points_per_square)
		for j in range(points_for_this_square):
			var t = float(j) / points_per_square
			var angle = start_angle + t * PI * 0.5  # Quarter circle
			var x = cx + cos(angle) * radius
			var y = cy + sin(angle) * radius
			var h = rect.level * extrusion_height * 0.5 + extrusion_height + 0.05

			surface_tool.add_vertex(Vector3(x, h, y))

	spiral_mesh = MeshInstance3D.new()
	spiral_mesh.mesh = surface_tool.commit()
	spiral_mesh.name = "GoldenSpiral"

	var material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = spiral_color
	material.emission_enabled = true
	material.emission = spiral_color * 0.5
	spiral_mesh.material_override = material

	add_child(spiral_mesh)

func _generate_all_subdivisions() -> void:
	"""Generate all subdivisions immediately (no animation)"""
	for i in range(max_subdivisions):
		_perform_subdivision()
	spiral_progress = 1.0
	_update_spiral()

# Public API
func regenerate() -> void:
	"""Clear and regenerate"""
	# Clear visuals
	for child in rectangles_parent.get_children():
		child.queue_free()
	for child in labels_parent.get_children():
		child.queue_free()
	if spiral_mesh:
		spiral_mesh.queue_free()
		spiral_mesh = null

	rectangles.clear()
	current_subdivision = 0
	subdivision_timer = 0.0
	spiral_progress = 0.0

	_initialize_rectangle()

	if animate:
		is_animating = true
	else:
		_generate_all_subdivisions()

func set_subdivisions(count: int) -> void:
	"""Set to specific subdivision count"""
	max_subdivisions = count
	regenerate()

func toggle_spiral() -> void:
	"""Toggle spiral visibility"""
	show_spiral = not show_spiral
	if show_spiral:
		spiral_progress = 0.0
	elif spiral_mesh:
		spiral_mesh.queue_free()
		spiral_mesh = null

func toggle_numbers() -> void:
	"""Toggle number visibility"""
	show_numbers = not show_numbers
	regenerate()

# Grid system integration
func configure(data: Dictionary) -> void:
	"""Configure from grid spawn parameters (e.g., golden_rectangle#preset:rainbow)"""
	print("GoldenRectangle: Configuring from Grid JSON: ", data)

	if data.has("preset"):
		apply_preset(str(data["preset"]).to_lower())

	if data.has("subdivisions"):
		max_subdivisions = int(data["subdivisions"])

	if data.has("animate"):
		animate = str(data["animate"]).to_lower() == "true"

	if data.has("spiral"):
		show_spiral = str(data["spiral"]).to_lower() == "true"

	if data.has("numbers"):
		show_numbers = str(data["numbers"]).to_lower() == "true"

	if data.has("delay"):
		subdivision_delay = float(data["delay"])

	regenerate()

# Presets
func apply_preset(preset_name: String) -> void:
	"""Apply visualization preset"""
	match preset_name:
		"classic":
			max_subdivisions = 8
			use_fibonacci_colors = true
			base_hue = 0.0
			show_spiral = true
			show_numbers = true
		"minimal":
			max_subdivisions = 6
			use_fibonacci_colors = false
			show_spiral = true
			show_numbers = false
		"rainbow":
			max_subdivisions = 10
			use_fibonacci_colors = true
			base_hue = 0.0
			hue_shift_per_level = 0.1
			show_spiral = true
			show_numbers = true
		"deep":
			max_subdivisions = 12
			use_fibonacci_colors = true
			hue_shift_per_level = 0.05
			show_spiral = true
			show_numbers = false
		"fast":
			max_subdivisions = 8
			animate = true
			subdivision_delay = 0.2
			spiral_draw_speed = 5.0

	regenerate()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

