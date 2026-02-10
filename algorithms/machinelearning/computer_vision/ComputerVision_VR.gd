extends Node3D

# VR-Reimagined Computer Vision
# Interactive image processing with spatial convolution filters
# Real-time edge detection, feature extraction, and object detection

@export_group("VR Scale")
@export var image_canvas_size: float = 4.0  # Size of image plane
@export var pixel_size: float = 0.2  # Individual pixel cube size
@export var filter_size: float = 0.3  # Convolution kernel display size
@export var feature_map_spacing: float = 1.5  # Space between feature maps

@export_group("Image Processing")
@export var image_resolution: int = 16  # 16x16 pixel grid (for performance)
@export var num_feature_maps: int = 4  # Number of detected features
@export var edge_threshold: float = 0.5  # Edge detection sensitivity

@export_group("Filters")
@export var show_sobel_filter: bool = true
@export var show_gaussian_blur: bool = true
@export var show_sharpen_filter: bool = true
@export var animate_convolution: bool = true

@export_group("Interactive Elements")
@export var enable_pixel_painting: bool = true
@export var enable_filter_grabbing: bool = true
@export var enable_object_detection: bool = true
@export var show_sliding_kernel: bool = true

# Image data
var input_image: Array = []  # 2D array of grayscale values
var edge_map: Array = []
var feature_maps: Array = []

# Visual elements
var pixel_meshes: Array = []  # MeshInstance3D for each pixel
var edge_pixels: Array = []
var feature_visualizations: Array = []
var bounding_boxes: Array = []

# Convolution kernels
var sobel_x: Array = [[-1, 0, 1], [-2, 0, 2], [-1, 0, 1]]
var sobel_y: Array = [[-1, -2, -1], [0, 0, 0], [1, 2, 1]]
var gaussian: Array = [[1, 2, 1], [2, 4, 2], [1, 2, 1]]  # Will be normalized
var sharpen: Array = [[0, -1, 0], [-1, 5, -1], [0, -1, 0]]

# Animation
var time: float = 0.0
var convolution_progress: float = 0.0
var current_filter_pos: Vector2i = Vector2i(0, 0)

# Kernel visualization
var kernel_window: Node3D

func _ready():
	print("[ComputerVision_VR] Initializing computer vision workspace")
	_initialize_image_data()
	_create_input_canvas()
	_create_filter_toolkit()
	_create_edge_detection_area()
	_create_feature_extraction_area()
	_create_object_detection_area()
	_create_convolution_visualizer()
	_create_control_panel()
	_create_info_panels()

func _process(delta):
	time += delta

	if animate_convolution:
		convolution_progress += delta * 0.5
		if convolution_progress >= 1.0:
			convolution_progress = 0.0
			_step_convolution()

	_update_pixel_display(delta)
	_animate_kernel_window(delta)
	_animate_features(delta)

func _initialize_image_data():
	"""Initialize input image with sample pattern"""
	for y in range(image_resolution):
		var row = []
		for x in range(image_resolution):
			# Create a simple test pattern (cross + circle)
			var center = image_resolution / 2.0
			var dist = sqrt(pow(x - center, 2) + pow(y - center, 2))

			var value = 0.0
			# Circle
			if dist < image_resolution / 3.0:
				value = 0.8
			# Cross
			if abs(x - center) < 2 or abs(y - center) < 2:
				value = 1.0

			row.append(value)
		input_image.append(row)

	# Initialize edge map
	edge_map = _apply_edge_detection(input_image)

	# Initialize feature maps
	for i in range(num_feature_maps):
		feature_maps.append([])

func _create_input_canvas():
	"""Create interactive input image canvas"""
	var canvas_container = Node3D.new()
	canvas_container.name = "InputCanvas"
	canvas_container.position = Vector3(-8.0, 0, 0)
	add_child(canvas_container)

	# Canvas label
	var label = Label3D.new()
	label.text = "INPUT IMAGE\nPaint pixels with hand"
	label.font_size = 48
	label.outline_size = 12
	label.modulate = Color(0.9, 0.9, 0.3)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0, image_canvas_size / 2.0 + 1.0, 0)
	canvas_container.add_child(label)

	# Create pixel grid
	for y in range(image_resolution):
		var row_meshes = []
		for x in range(image_resolution):
			var pixel = _create_pixel(x, y, input_image[y][x])
			canvas_container.add_child(pixel)
			row_meshes.append(pixel)
		pixel_meshes.append(row_meshes)

func _create_pixel(x: int, y: int, value: float) -> MeshInstance3D:
	"""Create a single pixel cube"""
	var mesh = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(pixel_size, pixel_size, pixel_size)
	mesh.mesh = box

	# Position in grid
	var grid_size = image_canvas_size
	var px = (float(x) / image_resolution - 0.5) * grid_size
	var py = (float(y) / image_resolution - 0.5) * grid_size
	mesh.position = Vector3(px, py, 0)

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(value, value, value)
	mat.emission_enabled = true
	mat.emission = Color(value, value, value)
	mat.emission_energy_multiplier = 0.5
	mat.metallic = 0.0
	mat.roughness = 1.0
	mesh.material_override = mat

	return mesh

func _create_filter_toolkit():
	"""Create grabbable filter objects"""
	var toolkit_container = Node3D.new()
	toolkit_container.name = "FilterToolkit"
	toolkit_container.position = Vector3(-8.0, -image_canvas_size / 2.0 - 2.0, 0)
	add_child(toolkit_container)

	# Toolkit label
	var label = Label3D.new()
	label.text = "FILTER TOOLKIT\nGrab to apply"
	label.font_size = 42
	label.outline_size = 10
	label.modulate = Color(0.3, 0.9, 0.9)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0, 1.0, 0)
	toolkit_container.add_child(label)

	# Create filter buttons
	var filters = [
		{"name": "Sobel X", "color": Color(0.9, 0.3, 0.3), "kernel": sobel_x},
		{"name": "Sobel Y", "color": Color(0.3, 0.9, 0.3), "kernel": sobel_y},
		{"name": "Gaussian", "color": Color(0.3, 0.3, 0.9), "kernel": gaussian},
		{"name": "Sharpen", "color": Color(0.9, 0.9, 0.3), "kernel": sharpen}
	]

	for i in range(filters.size()):
		var filter_data = filters[i]
		var filter_obj = _create_filter_object(filter_data, Vector3(i * 1.2 - 1.8, 0, 0))
		toolkit_container.add_child(filter_obj)

func _create_filter_object(filter_data: Dictionary, pos: Vector3) -> RigidBody3D:
	"""Create a grabbable filter tool"""
	var body = RigidBody3D.new()
	body.name = "Filter_" + filter_data.name.replace(" ", "_")
	body.position = pos
	body.gravity_scale = 0.0

	# Filter mesh (3x3 grid showing kernel)
	var grid_container = Node3D.new()
	body.add_child(grid_container)

	var kernel = filter_data.kernel
	for ky in range(3):
		for kx in range(3):
			var cell = MeshInstance3D.new()
			var box = BoxMesh.new()
			box.size = Vector3(filter_size / 3.5, filter_size / 3.5, 0.05)
			cell.mesh = box

			var value = kernel[ky][kx]
			var normalized_value = (value + 2) / 4.0  # Normalize to 0-1 range
			var mat = StandardMaterial3D.new()
			mat.albedo_color = filter_data.color * normalized_value
			mat.emission_enabled = true
			mat.emission = filter_data.color * normalized_value
			mat.emission_energy_multiplier = 0.8
			mat.metallic = 0.0
			mat.roughness = 1.0
			cell.material_override = mat

			cell.position = Vector3(
				(kx - 1) * filter_size / 3.0,
				(ky - 1) * filter_size / 3.0,
				0
			)
			grid_container.add_child(cell)

	# Collision
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(filter_size, filter_size, 0.1)
	collision.shape = shape
	body.add_child(collision)

	# Make grabbable
	if enable_filter_grabbing:
		body.collision_layer = 1 | (1 << 20)
		body.collision_mask = 1

	# Label
	var label = Label3D.new()
	label.text = filter_data.name
	label.font_size = 24
	label.outline_size = 8
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0, filter_size / 2.0 + 0.3, 0)
	body.add_child(label)

	return body

func _create_edge_detection_area():
	"""Create edge detection visualization area"""
	var edge_container = Node3D.new()
	edge_container.name = "EdgeDetection"
	edge_container.position = Vector3(-2.0, 0, 0)
	add_child(edge_container)

	# Label
	var label = Label3D.new()
	label.text = "EDGE DETECTION\nSobel Filter"
	label.font_size = 48
	label.outline_size = 12
	label.modulate = Color(0.9, 0.3, 0.3)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0, image_canvas_size / 2.0 + 1.0, 0)
	edge_container.add_child(label)

	# Create edge pixel grid
	for y in range(image_resolution):
		var row_meshes = []
		for x in range(image_resolution):
			var edge_value = edge_map[y][x]
			var pixel = _create_pixel(x, y, edge_value)
			edge_container.add_child(pixel)
			row_meshes.append(pixel)
		edge_pixels.append(row_meshes)

func _create_feature_extraction_area():
	"""Create feature map visualization"""
	var feature_container = Node3D.new()
	feature_container.name = "FeatureExtraction"
	feature_container.position = Vector3(4.0, 0, 0)
	add_child(feature_container)

	# Label
	var label = Label3D.new()
	label.text = "FEATURE MAPS\nLearned Patterns"
	label.font_size = 48
	label.outline_size = 12
	label.modulate = Color(0.3, 0.9, 0.5)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0, image_canvas_size / 2.0 + 1.5, 0)
	feature_container.add_child(label)

	# Create feature map columns
	for i in range(num_feature_maps):
		var feature_col = Node3D.new()
		feature_col.name = "FeatureMap_%d" % i
		feature_col.position = Vector3(i * feature_map_spacing - (num_feature_maps - 1) * feature_map_spacing / 2.0, 0, 0)
		feature_container.add_child(feature_col)

		# Feature spheres
		var num_features = 5 + i * 2
		var feature_spheres = []
		for f in range(num_features):
			var sphere = MeshInstance3D.new()
			var sphere_mesh = SphereMesh.new()
			sphere_mesh.radius = 0.15
			sphere.mesh = sphere_mesh

			var mat = StandardMaterial3D.new()
			var hue = float(i) / num_feature_maps
			var color = Color.from_hsv(hue, 0.8, 0.9)
			mat.albedo_color = color
			mat.emission_enabled = true
			mat.emission = color
			mat.emission_energy_multiplier = 1.0
			mat.metallic = 0.0
			mat.roughness = 1.0
			sphere.material_override = mat

			var angle = float(f) / num_features * TAU
			var radius = 0.8
			sphere.position = Vector3(
				cos(angle) * radius,
				sin(angle) * radius,
				0
			)

			feature_col.add_child(sphere)
			feature_spheres.append(sphere)

		feature_visualizations.append(feature_spheres)

func _create_object_detection_area():
	"""Create object detection bounding box visualization"""
	if not enable_object_detection:
		return

	var detection_container = Node3D.new()
	detection_container.name = "ObjectDetection"
	detection_container.position = Vector3(10.0, 0, 0)
	add_child(detection_container)

	# Label
	var label = Label3D.new()
	label.text = "OBJECT DETECTION\nBounding Boxes"
	label.font_size = 48
	label.outline_size = 12
	label.modulate = Color(0.9, 0.5, 0.3)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0, image_canvas_size / 2.0 + 1.0, 0)
	detection_container.add_child(label)

	# Create sample bounding boxes
	var bbox_data = [
		{"pos": Vector2(5, 5), "size": Vector2(6, 6), "label": "Circle", "confidence": 0.92},
		{"pos": Vector2(6, 6), "size": Vector2(4, 4), "label": "Cross", "confidence": 0.85}
	]

	for data in bbox_data:
		var bbox = _create_bounding_box(data)
		detection_container.add_child(bbox)
		bounding_boxes.append(bbox)

func _create_bounding_box(data: Dictionary) -> Node3D:
	"""Create a bounding box visualization"""
	var bbox_container = Node3D.new()

	# Box edges
	var edges = [
		[Vector3(0, 0, 0), Vector3(1, 0, 0)],
		[Vector3(1, 0, 0), Vector3(1, 1, 0)],
		[Vector3(1, 1, 0), Vector3(0, 1, 0)],
		[Vector3(0, 1, 0), Vector3(0, 0, 0)]
	]

	var grid_size = image_canvas_size
	var scale_x = float(data.size.x) / image_resolution * grid_size
	var scale_y = float(data.size.y) / image_resolution * grid_size
	var pos_x = (float(data.pos.x) / image_resolution - 0.5) * grid_size
	var pos_y = (float(data.pos.y) / image_resolution - 0.5) * grid_size

	for edge in edges:
		var line = MeshInstance3D.new()
		var cylinder = CylinderMesh.new()
		cylinder.top_radius = 0.02
		cylinder.bottom_radius = 0.02
		var length = (edge[1] - edge[0]).length() * max(scale_x, scale_y)
		cylinder.height = length
		line.mesh = cylinder

		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.9, 0.5, 0.3)
		mat.emission_enabled = true
		mat.emission = Color(0.9, 0.5, 0.3)
		mat.emission_energy_multiplier = 1.2
		mat.metallic = 0.0
		mat.roughness = 1.0
		line.material_override = mat

		var mid = (edge[0] + edge[1]) / 2.0
		line.position = Vector3(mid.x * scale_x + pos_x, mid.y * scale_y + pos_y, 0.1)

		var direction = (edge[1] - edge[0]).normalized()
		if direction.length() > 0.01:
			line.look_at(line.position + Vector3(direction.x, direction.y, 0), Vector3.UP)
			line.rotate_object_local(Vector3.RIGHT, PI / 2.0)

		bbox_container.add_child(line)

	# Label
	var label = Label3D.new()
	label.text = "%s: %.0f%%" % [data.label, data.confidence * 100]
	label.font_size = 20
	label.outline_size = 6
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(pos_x, pos_y + scale_y / 2.0 + 0.3, 0.1)
	bbox_container.add_child(label)

	return bbox_container

func _create_convolution_visualizer():
	"""Create sliding kernel window animation"""
	if not show_sliding_kernel:
		return

	kernel_window = Node3D.new()
	kernel_window.name = "KernelWindow"
	add_child(kernel_window)

	# 3x3 kernel outline
	var outline = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(pixel_size * 3.2, pixel_size * 3.2, 0.05)
	outline.mesh = box

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.9, 0.3, 0.0)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(0.9, 0.9, 0.3)
	mat.emission_energy_multiplier = 1.5
	mat.metallic = 0.0
	mat.roughness = 1.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	outline.material_override = mat

	kernel_window.add_child(outline)

	# Position at input canvas
	kernel_window.position = Vector3(-8.0, 0, 0.2)

func _create_control_panel():
	"""Create VR control panel"""
	var controls = Node3D.new()
	controls.name = "ControlPanel"
	controls.position = Vector3(13.0, 0, 0)
	add_child(controls)

	# Panel background
	var panel = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(3.0, 4.0, 0.1)
	panel.mesh = box

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.2, 0.3, 0.95)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.metallic = 0.0
	mat.roughness = 1.0
	panel.material_override = mat
	controls.add_child(panel)

	# Title
	var title = Label3D.new()
	title.text = "COMPUTER VISION\nPIPELINE"
	title.font_size = 56
	title.outline_size = 12
	title.position = Vector3(0, 1.6, 0.1)
	controls.add_child(title)

	# Info
	var info = Label3D.new()
	info.text = "Resolution: %dx%d\nFilters: 4\nFeatures: %d" % [image_resolution, image_resolution, num_feature_maps]
	info.font_size = 32
	info.outline_size = 8
	info.position = Vector3(0, 0.3, 0.1)
	controls.add_child(info)

func _create_info_panels():
	"""Create educational info panels"""
	# Convolution explanation
	_create_info_panel(
		Vector3(-8.0, image_canvas_size / 2.0 + 2.5, -2.0),
		"CONVOLUTION\nSliding window operation\nKernel Ã— Image = Feature\nLocal pattern detection",
		Color(0.9, 0.9, 0.3)
	)

	# Edge detection
	_create_info_panel(
		Vector3(-2.0, image_canvas_size / 2.0 + 2.5, -2.0),
		"SOBEL FILTER\nComputes gradients\nDetects edges and boundaries\nFoundation of CV",
		Color(0.9, 0.3, 0.3)
	)

	# Features
	_create_info_panel(
		Vector3(4.0, image_canvas_size / 2.0 + 3.0, -2.0),
		"FEATURE EXTRACTION\nHierarchical patterns\nLow to high level features\nLearn ed representations",
		Color(0.3, 0.9, 0.5)
	)

func _create_info_panel(pos: Vector3, text: String, color: Color):
	"""Create floating info panel"""
	var label = Label3D.new()
	label.text = text
	label.font_size = 28
	label.outline_size = 8
	label.outline_modulate = Color.BLACK
	label.modulate = color
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = pos
	add_child(label)

func _update_pixel_display(_delta):
	"""Update pixel visualization"""
	# Update input pixels
	for y in range(image_resolution):
		for x in range(image_resolution):
			var pixel = pixel_meshes[y][x]
			var value = input_image[y][x]

			# Pulse effect
			var pulse = 1.0 + sin(time * 2.0 + x * 0.1 + y * 0.1) * 0.1
			pixel.scale = Vector3.ONE * pulse

			# Update color
			pixel.material_override.albedo_color = Color(value, value, value)
			pixel.material_override.emission = Color(value, value, value)

	# Update edge pixels
	for y in range(image_resolution):
		for x in range(image_resolution):
			var pixel = edge_pixels[y][x]
			var value = edge_map[y][x]

			pixel.material_override.albedo_color = Color(value, value * 0.3, value * 0.3)
			pixel.material_override.emission = Color(value, value * 0.3, value * 0.3)

func _animate_kernel_window(_delta):
	"""Animate sliding convolution kernel"""
	if not show_sliding_kernel or not kernel_window:
		return

	# Move kernel across image
	var grid_size = image_canvas_size
	var px = (float(current_filter_pos.x) / image_resolution - 0.5) * grid_size
	var py = (float(current_filter_pos.y) / image_resolution - 0.5) * grid_size
	kernel_window.position = Vector3(-8.0 + px, py, 0.2)

func _animate_features(_delta):
	"""Animate feature visualizations"""
	for i in range(feature_visualizations.size()):
		var features = feature_visualizations[i]
		for f in range(features.size()):
			var sphere = features[f]
			var pulse = 1.0 + sin(time * 2.5 + i + f * 0.5) * 0.2
			sphere.scale = Vector3.ONE * pulse

func _step_convolution():
	"""Step convolution animation"""
	current_filter_pos.x += 1
	if current_filter_pos.x >= image_resolution - 2:
		current_filter_pos.x = 1
		current_filter_pos.y += 1
		if current_filter_pos.y >= image_resolution - 2:
			current_filter_pos.y = 1

func _apply_edge_detection(img: Array) -> Array:
	"""Apply Sobel edge detection"""
	var result = []
	for y in range(image_resolution):
		var row = []
		for x in range(image_resolution):
			if x <= 0 or x >= image_resolution - 1 or y <= 0 or y >= image_resolution - 1:
				row.append(0.0)
				continue

			# Apply Sobel kernels
			var gx = 0.0
			var gy = 0.0
			for ky in range(3):
				for kx in range(3):
					var pixel_val = img[y + ky - 1][x + kx - 1]
					gx += pixel_val * sobel_x[ky][kx]
					gy += pixel_val * sobel_y[ky][kx]

			var magnitude = sqrt(gx * gx + gy * gy)
			row.append(clamp(magnitude, 0.0, 1.0))
		result.append(row)
	return result

# Public API
func apply_filter(filter_name: String):
	"""Apply a filter to the input image"""
	print("[CV] Applying filter: ", filter_name)
	edge_map = _apply_edge_detection(input_image)

func set_pixel_value(x: int, y: int, value: float):
	"""Set a pixel value (for painting)"""
	if x >= 0 and x < image_resolution and y >= 0 and y < image_resolution:
		input_image[y][x] = clamp(value, 0.0, 1.0)
		edge_map = _apply_edge_detection(input_image)
