extends Node3D

# Sample sheet demonstrating k-means color quantization
# with Ada Lovelace image across three educational rows
# Converted from Control to Node3D for VR compatibility

const SWATCH_SIZE := 0.03
const ROW_SPACING := 0.15
const COL_SPACING := 0.04
const PANEL_SPACING := 0.18

# Row anchor nodes
var row1_node: Node3D
var row2_node: Node3D
var row3_node: Node3D

# Sample Ada Lovelace image data (simplified for demo)
var ada_image_data: Array = []
var original_colors: Array = []
var quantized_results: Dictionary = {}

func _ready() -> void:
	setup_layout()
	create_sample_image_data()
	populate_row1_quantization_comparison()
	populate_row2_pixel_resolution()
	populate_row3_color_palettes()

func setup_layout() -> void:
	# Title
	var title = Label3D.new()
	title.text = "K-Means Color Quantization Demo: Ada Lovelace Portrait"
	title.font_size = 48
	title.position = Vector3(0.3, 0.45, 0)
	title.modulate = Color.WHITE
	add_child(title)

	# Row anchors arranged vertically
	row1_node = Node3D.new()
	row1_node.position = Vector3(0, 0.3, 0)
	add_child(row1_node)

	row2_node = Node3D.new()
	row2_node.position = Vector3(0, 0.1, 0)
	add_child(row2_node)

	row3_node = Node3D.new()
	row3_node.position = Vector3(0, -0.1, 0)
	add_child(row3_node)

func create_sample_image_data() -> void:
	# Create simplified Ada Lovelace portrait data (32x32 for demo)
	var width := 32
	var height := 32

	ada_image_data.resize(width * height)
	original_colors.clear()

	# Generate sample portrait-like data with skin tones, dark hair, dress colors
	for y in range(height):
		for x in range(width):
			var idx := y * width + x
			var color := generate_portrait_pixel(x, y, width, height)
			ada_image_data[idx] = color
			if not original_colors.has(color):
				original_colors.append(color)

func generate_portrait_pixel(x: int, y: int, width: int, height: int) -> Color:
	# Generate realistic portrait colors based on position
	var center_x := width / 2.0
	var center_y := height / 2.0
	var dist_from_center := Vector2(x - center_x, y - center_y).length()

	# Face area (center region)
	if dist_from_center < width * 0.25:
		var skin_colors := [
			Color(0.956, 0.824, 0.706),
			Color(0.918, 0.780, 0.658),
			Color(0.875, 0.722, 0.592),
			Color(0.824, 0.667, 0.518)
		]
		return skin_colors[randi() % skin_colors.size()]

	# Hair region (upper portion)
	elif y < height * 0.4:
		var hair_colors := [
			Color(0.2, 0.15, 0.1),
			Color(0.15, 0.1, 0.05),
			Color(0.1, 0.08, 0.05),
			Color(0.05, 0.03, 0.02)
		]
		return hair_colors[randi() % hair_colors.size()]

	# Dress/clothing region
	else:
		var dress_colors := [
			Color(0.2, 0.3, 0.5),
			Color(0.15, 0.25, 0.45),
			Color(0.3, 0.2, 0.4),
			Color(0.1, 0.1, 0.2),
			Color(0.8, 0.8, 0.9),
			Color(0.6, 0.6, 0.7)
		]
		return dress_colors[randi() % dress_colors.size()]

func populate_row1_quantization_comparison() -> void:
	# Row 1: Original image vs different k-means quantization levels
	var row_label := Label3D.new()
	row_label.text = "Row 1: K-Means Color Quantization Levels"
	row_label.font_size = 32
	row_label.position = Vector3(0, 0.06, 0)
	row1_node.add_child(row_label)

	# Original image
	add_image_panel_3d(row1_node, "Original\n(~100+ colors)", ada_image_data, original_colors, 0)

	# Different quantization levels
	var k_values := [2, 5, 10, 15]
	for i in range(k_values.size()):
		var k: int = k_values[i]
		var quantized_data := apply_kmeans_quantization(ada_image_data, k)
		var palette := extract_color_palette(quantized_data, k)
		quantized_results[k] = {"data": quantized_data, "palette": palette}
		add_image_panel_3d(row1_node, str(k) + " colors", quantized_data, palette, i + 1)

func populate_row2_pixel_resolution() -> void:
	# Row 2: Pixel resolution effects with quantization
	var row_label := Label3D.new()
	row_label.text = "Row 2: Pixel Resolution & Color Quantization"
	row_label.font_size = 32
	row_label.position = Vector3(0, 0.06, 0)
	row2_node.add_child(row_label)

	# Different resolutions with 5-color quantization
	var resolutions := [8, 16, 32, 64]
	for i in range(resolutions.size()):
		var res: int = resolutions[i]
		var scaled_data := scale_image_data(ada_image_data, 32, res)
		var quantized_data := apply_kmeans_quantization(scaled_data, 5)
		var palette: Array = quantized_results[5].palette if quantized_results.has(5) else []
		add_image_panel_3d(row2_node, str(res) + "x" + str(res) + "\n5 colors", quantized_data, palette, i)

func populate_row3_color_palettes() -> void:
	# Row 3: Color palette extraction visualization
	var row_label := Label3D.new()
	row_label.text = "Row 3: Extracted Color Palettes (K-Means Centroids)"
	row_label.font_size = 32
	row_label.position = Vector3(0, 0.06, 0)
	row3_node.add_child(row_label)

	var idx := 0
	for k in [2, 5, 10, 15]:
		if quantized_results.has(k):
			add_palette_panel_3d(row3_node, str(k) + " Colors", quantized_results[k].palette, idx)
			idx += 1

func add_image_panel_3d(parent: Node3D, label_text: String, image_data: Array, palette: Array, panel_index: int) -> void:
	var panel := Node3D.new()
	panel.position = Vector3(panel_index * PANEL_SPACING, 0, 0)
	parent.add_child(panel)

	# Label
	var label := Label3D.new()
	label.text = label_text
	label.font_size = 20
	label.position = Vector3(0.05, 0.04, 0)
	panel.add_child(label)

	# Image grid using MultiMeshInstance3D for efficient rendering
	var grid_size := int(sqrt(image_data.size()))
	if grid_size <= 0:
		grid_size = 32

	var mm_instance := MultiMeshInstance3D.new()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var quad := QuadMesh.new()
	quad.size = Vector2(SWATCH_SIZE * 0.9, SWATCH_SIZE * 0.9)
	mm.mesh = quad

	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	quad.material = mat

	mm.instance_count = image_data.size()
	for i in range(image_data.size()):
		var px := i % grid_size
		var py := i / grid_size
		var t := Transform3D()
		t.origin = Vector3(px * SWATCH_SIZE, -py * SWATCH_SIZE, 0)
		mm.set_instance_transform(i, t)
		mm.set_instance_color(i, image_data[i])

	mm_instance.multimesh = mm
	panel.add_child(mm_instance)

	# Color count info
	var info_label := Label3D.new()
	info_label.text = "Colors: " + str(palette.size())
	info_label.font_size = 16
	info_label.position = Vector3(0.05, -grid_size * SWATCH_SIZE - 0.02, 0)
	panel.add_child(info_label)

func add_palette_panel_3d(parent: Node3D, label_text: String, palette: Array, panel_index: int) -> void:
	var panel := Node3D.new()
	panel.position = Vector3(panel_index * PANEL_SPACING, 0, 0)
	parent.add_child(panel)

	# Label
	var label := Label3D.new()
	label.text = label_text
	label.font_size = 20
	label.position = Vector3(0.03, 0.04, 0)
	panel.add_child(label)

	# Palette swatches as individual QuadMeshes
	for i in range(palette.size()):
		var swatch := MeshInstance3D.new()
		var quad := QuadMesh.new()
		quad.size = Vector2(0.03, 0.03)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = palette[i]
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		quad.material = mat
		swatch.mesh = quad
		swatch.position = Vector3(i * 0.035, 0, 0)
		panel.add_child(swatch)

	# RGB values (for first few colors)
	for i in range(min(3, palette.size())):
		var color: Color = palette[i]
		var rgb_label := Label3D.new()
		rgb_label.text = "RGB(%d,%d,%d)" % [color.r8, color.g8, color.b8]
		rgb_label.font_size = 12
		rgb_label.position = Vector3(0, -0.04 - i * 0.02, 0)
		panel.add_child(rgb_label)

# ─── K-Means Algorithm Logic (unchanged) ───

func apply_kmeans_quantization(image_data: Array, k: int) -> Array:
	if k >= original_colors.size():
		return image_data.duplicate()

	# Initialize centroids randomly from existing colors
	var centroids: Array = []
	var used_indices: Array = []

	for i in range(k):
		var rand_idx := randi() % original_colors.size()
		while used_indices.has(rand_idx) and used_indices.size() < original_colors.size():
			rand_idx = randi() % original_colors.size()
		used_indices.append(rand_idx)
		centroids.append(original_colors[rand_idx])

	# Perform k-means iterations (simplified)
	for iteration in range(5):
		var clusters: Array = []
		for i in range(k):
			clusters.append([])

		# Assign pixels to nearest centroid
		for color in image_data:
			var nearest_idx := 0
			var min_dist := color_distance(color, centroids[0])

			for i in range(1, k):
				var dist := color_distance(color, centroids[i])
				if dist < min_dist:
					min_dist = dist
					nearest_idx = i

			clusters[nearest_idx].append(color)

		# Update centroids
		for i in range(k):
			if clusters[i].size() > 0:
				centroids[i] = calculate_color_mean(clusters[i])

	# Replace all colors with nearest centroid
	var quantized_data: Array = []
	for color in image_data:
		var nearest_idx := 0
		var min_dist := color_distance(color, centroids[0])

		for i in range(1, k):
			var dist := color_distance(color, centroids[i])
			if dist < min_dist:
				min_dist = dist
				nearest_idx = i

		quantized_data.append(centroids[nearest_idx])

	return quantized_data

func color_distance(color1: Color, color2: Color) -> float:
	var dr := color1.r - color2.r
	var dg := color1.g - color2.g
	var db := color1.b - color2.b
	return sqrt(dr * dr + dg * dg + db * db)

func calculate_color_mean(colors: Array) -> Color:
	if colors.is_empty():
		return Color.BLACK

	var sum_r := 0.0
	var sum_g := 0.0
	var sum_b := 0.0

	for color in colors:
		sum_r += color.r
		sum_g += color.g
		sum_b += color.b

	var count := colors.size()
	return Color(sum_r / count, sum_g / count, sum_b / count)

func extract_color_palette(image_data: Array, max_colors: int) -> Array:
	var unique_colors: Array = []
	for color in image_data:
		if not unique_colors.has(color) and unique_colors.size() < max_colors:
			unique_colors.append(color)
	return unique_colors

func scale_image_data(original_data: Array, original_size: int, new_size: int) -> Array:
	var scaled_data: Array = []
	var scale_factor := float(original_size) / float(new_size)

	for y in range(new_size):
		for x in range(new_size):
			var src_x := int(x * scale_factor)
			var src_y := int(y * scale_factor)
			var src_idx := src_y * original_size + src_x

			if src_idx < original_data.size():
				scaled_data.append(original_data[src_idx])
			else:
				scaled_data.append(Color.BLACK)

	return scaled_data

func apply_grid_config(config: Dictionary) -> void:
	pass

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()
