# RockScanner.gd - Reveals 2D cross-sections of 3D irregular forms
extends Node3D

@export var scan_height: float = 1.0
@export var scan_speed: float = 0.5
@export var scan_range: Vector2 = Vector2(0.0, 3.0)  # Min/max Y
@export var auto_scan: bool = true
@export var display_size: Vector2 = Vector2(2.0, 2.0)

var scan_plane: MeshInstance3D
var display_canvas: Node3D
var current_height: float = 0.0
var scan_direction: float = 1.0

func _ready():
	create_scan_plane()
	# create_display_canvas()  # Disabled - only show scanning plane
	current_height = scan_range.x

func _process(delta):
	if auto_scan:
		# Move scan plane up and down
		current_height += scan_speed * scan_direction * delta

		# Reverse at boundaries
		if current_height >= scan_range.y:
			current_height = scan_range.y
			scan_direction = -1.0
		elif current_height <= scan_range.x:
			current_height = scan_range.x
			scan_direction = 1.0

		scan_height = current_height
		update_scan_plane()
		# update_cross_section_display()  # Disabled

func create_scan_plane():
	"""Create visual plane that shows scan position"""
	# Create a StaticBody3D so player can walk on it
	var static_body = StaticBody3D.new()
	static_body.name = "ScanPlaneBody"
	add_child(static_body)

	# Create the visual mesh
	scan_plane = MeshInstance3D.new()
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(3.5, 3.5)
	scan_plane.mesh = plane_mesh

	# Semi-transparent cyan material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.0, 0.9, 1.0, 0.4)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED  # Make it glow
	scan_plane.material_override = material

	static_body.add_child(scan_plane)

	# Add collision shape so player can walk on it
	var collision = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(3.5, 0.05, 3.5)  # Thin collision box
	collision.shape = box_shape
	static_body.add_child(collision)

func create_display_canvas():
	"""Create 2D display showing cross-section"""
	display_canvas = MeshInstance3D.new()
	display_canvas.name = "CrossSectionDisplay"

	var quad_mesh = QuadMesh.new()
	quad_mesh.size = display_size
	display_canvas.mesh = quad_mesh

	# Initial material so it's visible from the start
	var initial_material = StandardMaterial3D.new()
	initial_material.albedo_color = Color(0.1, 0.1, 0.2, 1.0)
	initial_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	display_canvas.material_override = initial_material

	# Position display above the crate, facing down slightly so you can see it
	display_canvas.position = Vector3(0, 3.5, 0)
	display_canvas.rotation_degrees = Vector3(-15, 0, 0)

	add_child(display_canvas)

	# Create a visible frame around the display
	create_display_frame()

func create_display_frame():
	"""Create visible frame around the display panel"""
	var frame_thickness = 0.1
	var frame_color = Color(0.2, 0.8, 1.0, 1.0)  # Bright cyan

	# Create 4 bars forming a rectangle frame
	var positions = [
		Vector3(0, display_size.y / 2 + frame_thickness / 2, 0),  # Top
		Vector3(0, -(display_size.y / 2 + frame_thickness / 2), 0),  # Bottom
		Vector3(-(display_size.x / 2 + frame_thickness / 2), 0, 0),  # Left
		Vector3(display_size.x / 2 + frame_thickness / 2, 0, 0)  # Right
	]

	var sizes = [
		Vector3(display_size.x + frame_thickness * 2, frame_thickness, 0.05),  # Top/Bottom
		Vector3(display_size.x + frame_thickness * 2, frame_thickness, 0.05),
		Vector3(frame_thickness, display_size.y, 0.05),  # Left/Right
		Vector3(frame_thickness, display_size.y, 0.05)
	]

	for i in range(4):
		var frame_bar = MeshInstance3D.new()
		var box_mesh = BoxMesh.new()
		box_mesh.size = sizes[i]
		frame_bar.mesh = box_mesh

		var material = StandardMaterial3D.new()
		material.albedo_color = frame_color
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.emission_enabled = true
		material.emission = frame_color
		material.emission_energy_multiplier = 2.0
		frame_bar.material_override = material

		frame_bar.position = positions[i]
		display_canvas.add_child(frame_bar)

func update_scan_plane():
	"""Update scan plane visual position"""
	if scan_plane:
		# Update the parent StaticBody3D position
		var static_body = scan_plane.get_parent()
		if static_body:
			static_body.position.y = scan_height

func update_cross_section_display():
	"""Calculate and display 2D cross-section at current height"""
	# Find all rocks in scene
	var rocks = find_rocks_in_scene()

	# Create image for cross-section
	var img_size = 512
	var img = Image.create(img_size, img_size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.1, 0.1, 0.2, 1.0))  # Dark background

	# Draw each rock's cross-section
	for rock in rocks:
		draw_rock_cross_section(img, rock, img_size)

	# Update display texture
	var texture = ImageTexture.create_from_image(img)
	var material = StandardMaterial3D.new()
	material.albedo_texture = texture
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	display_canvas.material_override = material

func find_rocks_in_scene() -> Array:
	"""Find all RigidBody3D rocks"""
	var rocks = []
	var root = get_tree().root
	find_rocks_recursive(root, rocks)
	return rocks

func find_rocks_recursive(node: Node, rocks: Array):
	if node.name.contains("Rock") and node is RigidBody3D:
		rocks.append(node)
	for child in node.get_children():
		find_rocks_recursive(child, rocks)

func draw_rock_cross_section(img: Image, rock: RigidBody3D, img_size: int):
	"""Draw irregular cross-section where convex shape intersects scan plane"""
	# Get rock's collision shape
	var collision_shape = rock.get_node_or_null("CollisionShape3D")
	if not collision_shape:
		return

	var shape = collision_shape.shape
	var rock_pos = rock.global_position
	var rock_rotation = rock.global_transform.basis

	# Handle ConvexPolygonShape3D (irregular rocks)
	if shape is ConvexPolygonShape3D:
		var convex: ConvexPolygonShape3D = shape
		var points = convex.points

		# Calculate approximate radius for fallback circle rendering
		var max_radius = 0.0
		for point in points:
			max_radius = max(max_radius, point.length())

		# Check if scan plane intersects the rock's bounding sphere
		var distance_to_plane = abs(rock_pos.y - scan_height)

		if distance_to_plane < max_radius:
			# For now, draw a circle approximation based on the cross-section
			# This is simpler and more reliable than polygon intersection
			var cross_section_radius = sqrt(max_radius * max_radius - distance_to_plane * distance_to_plane)

			var world_to_img_scale = img_size / 8.0  # 8 units = image width
			var center_x = int((rock_pos.x + 4.0) * world_to_img_scale)
			var center_z = int((rock_pos.z + 4.0) * world_to_img_scale)
			var pixel_radius = int(cross_section_radius * world_to_img_scale)

			var color = Color(0.8, 0.8, 0.9, 1.0)
			draw_filled_circle(img, center_x, center_z, pixel_radius, color)

	# Fallback for SphereShape3D (if any old rocks exist)
	elif shape is SphereShape3D:
		var sphere: SphereShape3D = shape
		var radius = sphere.radius
		var distance_to_plane = abs(rock_pos.y - scan_height)

		if distance_to_plane < radius:
			var cross_section_radius = sqrt(radius * radius - distance_to_plane * distance_to_plane)
			var world_to_img_scale = img_size / 4.0
			var center_x = int((rock_pos.x + 2.0) * world_to_img_scale)
			var center_z = int((rock_pos.z + 2.0) * world_to_img_scale)
			var pixel_radius = int(cross_section_radius * world_to_img_scale)
			var color = Color(0.8, 0.8, 0.9, 1.0)
			draw_filled_circle(img, center_x, center_z, pixel_radius, color)

func draw_filled_circle(img: Image, cx: int, cy: int, radius: int, color: Color):
	"""Draw a filled circle on the image"""
	for y in range(-radius, radius + 1):
		for x in range(-radius, radius + 1):
			if x * x + y * y <= radius * radius:
				var px = cx + x
				var py = cy + y
				if px >= 0 and px < img.get_width() and py >= 0 and py < img.get_height():
					img.set_pixel(px, py, color)

func draw_irregular_shape(img: Image, points_2d: Array, img_size: int, color: Color):
	"""Draw irregular polygon from 2D intersection points"""
	if points_2d.size() == 0:
		return

	# Find center point of all intersection points
	var center = Vector2.ZERO
	for p in points_2d:
		center += p
	center /= points_2d.size()

	# Sort points by angle from center (creates convex hull-like ordering)
	var sorted_points = points_2d.duplicate()
	sorted_points.sort_custom(func(a, b):
		var angle_a = (a - center).angle()
		var angle_b = (b - center).angle()
		return angle_a < angle_b
	)

	# Convert to pixel coordinates
	var world_to_img_scale = img_size / 4.0
	var pixel_points = []
	for p in sorted_points:
		var px = int((p.x + 2.0) * world_to_img_scale)
		var py = int((p.y + 2.0) * world_to_img_scale)
		pixel_points.append(Vector2i(px, py))

	# Draw filled polygon using scanline algorithm
	if pixel_points.size() >= 3:
		# Simple approach: fill based on center point
		var pixel_center = Vector2i(
			int((center.x + 2.0) * world_to_img_scale),
			int((center.y + 2.0) * world_to_img_scale)
		)

		# Find bounding box
		var min_x = pixel_points[0].x
		var max_x = pixel_points[0].x
		var min_y = pixel_points[0].y
		var max_y = pixel_points[0].y

		for p in pixel_points:
			min_x = mini(min_x, p.x)
			max_x = maxi(max_x, p.x)
			min_y = mini(min_y, p.y)
			max_y = maxi(max_y, p.y)

		# Flood fill approach - check if point is inside polygon
		for py in range(max(0, min_y - 5), min(img.get_height(), max_y + 5)):
			for px in range(max(0, min_x - 5), min(img.get_width(), max_x + 5)):
				if is_point_in_polygon(Vector2i(px, py), pixel_points):
					img.set_pixel(px, py, color)

func is_point_in_polygon(point: Vector2i, polygon: Array) -> bool:
	"""Check if point is inside polygon using ray casting"""
	var inside = false
	var j = polygon.size() - 1

	for i in range(polygon.size()):
		var vi = polygon[i]
		var vj = polygon[j]

		if ((vi.y > point.y) != (vj.y > point.y)) and \
		   (point.x < (vj.x - vi.x) * (point.y - vi.y) / (vj.y - vi.y) + vi.x):
			inside = !inside

		j = i

	return inside
