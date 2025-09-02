extends Control

# Sample sheet demonstrating k-means color quantization
# with Ada Lovelace image across three educational rows

@onready var main_container = VBoxContainer.new()
@onready var title_label = Label.new()

# Row containers
@onready var row1_container = HBoxContainer.new()  # Original vs quantized comparison
@onready var row2_container = HBoxContainer.new()  # Pixel resolution demonstration
@onready var row3_container = HBoxContainer.new()  # Color palette extraction

# Sample Ada Lovelace image data (simplified for demo)
var ada_image_data = []
var original_colors = []
var quantized_results = {}

func _ready():
	setup_ui()
	create_sample_image_data()
	populate_row1_quantization_comparison()
	populate_row2_pixel_resolution()
	populate_row3_color_palettes()

func setup_ui():
	# Main container setup
	add_child(main_container)
	main_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_container.add_theme_constant_override("separation", 20)
	
	# Title
	title_label.text = "K-Means Color Quantization Demo: Ada Lovelace Portrait"
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_container.add_child(title_label)
	
	# Row containers setup
	for container in [row1_container, row2_container, row3_container]:
		container.add_theme_constant_override("separation", 15)
		main_container.add_child(container)

func create_sample_image_data():
	# Create simplified Ada Lovelace portrait data (32x32 for demo)
	# In a real implementation, you'd load an actual image
	var width = 32
	var height = 32
	
	ada_image_data.resize(width * height)
	original_colors.clear()
	
	# Generate sample portrait-like data with skin tones, dark hair, dress colors
	for y in range(height):
		for x in range(width):
			var idx = y * width + x
			var color = generate_portrait_pixel(x, y, width, height)
			ada_image_data[idx] = color
			if not original_colors.has(color):
				original_colors.append(color)

func generate_portrait_pixel(x: int, y: int, width: int, height: int) -> Color:
	# Generate realistic portrait colors based on position
	var center_x = width / 2.0
	var center_y = height / 2.0
	var dist_from_center = Vector2(x - center_x, y - center_y).length()
	
	# Face area (center region)
	if dist_from_center < width * 0.25:
		# Skin tones
		var skin_colors = [
			Color(0.956, 0.824, 0.706), # Light peach
			Color(0.918, 0.780, 0.658), # Medium peach  
			Color(0.875, 0.722, 0.592), # Tan
			Color(0.824, 0.667, 0.518)  # Deeper tan
		]
		return skin_colors[randi() % skin_colors.size()]
	
	# Hair region (upper portion)
	elif y < height * 0.4:
		var hair_colors = [
			Color(0.2, 0.15, 0.1),   # Dark brown
			Color(0.15, 0.1, 0.05),  # Very dark brown
			Color(0.1, 0.08, 0.05),  # Almost black
			Color(0.05, 0.03, 0.02)  # Black
		]
		return hair_colors[randi() % hair_colors.size()]
	
	# Dress/clothing region
	else:
		var dress_colors = [
			Color(0.2, 0.3, 0.5),    # Deep blue
			Color(0.15, 0.25, 0.45), # Navy blue
			Color(0.3, 0.2, 0.4),    # Purple
			Color(0.1, 0.1, 0.2),    # Dark purple
			Color(0.8, 0.8, 0.9),    # Light fabric highlight
			Color(0.6, 0.6, 0.7)     # Medium fabric
		]
		return dress_colors[randi() % dress_colors.size()]

func populate_row1_quantization_comparison():
	# Row 1: Original image vs different k-means quantization levels
	var row_label = Label.new()
	row_label.text = "Row 1: K-Means Color Quantization Levels"
	row_label.add_theme_font_size_override("font_size", 16)
	row1_container.add_child(row_label)
	
	# Original image
	add_image_panel(row1_container, "Original\n(~100+ colors)", ada_image_data, original_colors)
	
	# Different quantization levels
	var k_values = [2, 5, 10, 15]
	for k in k_values:
		var quantized_data = apply_kmeans_quantization(ada_image_data, k)
		var palette = extract_color_palette(quantized_data, k)
		quantized_results[k] = {"data": quantized_data, "palette": palette}
		add_image_panel(row1_container, str(k) + " colors", quantized_data, palette)

func populate_row2_pixel_resolution():
	# Row 2: Pixel resolution effects with quantization
	var row_label = Label.new()
	row_label.text = "Row 2: Pixel Resolution & Color Quantization"
	row_label.add_theme_font_size_override("font_size", 16)
	row2_container.add_child(row_label)
	
	# Different resolutions with 5-color quantization
	var resolutions = [8, 16, 32, 64]
	for res in resolutions:
		var scaled_data = scale_image_data(ada_image_data, 32, res)
		var quantized_data = apply_kmeans_quantization(scaled_data, 5)
		add_image_panel(row2_container, str(res) + "x" + str(res) + "\n5 colors", quantized_data, quantized_results[5].palette)

func populate_row3_color_palettes():
	# Row 3: Color palette extraction visualization
	var row_label = Label.new()
	row_label.text = "Row 3: Extracted Color Palettes (K-Means Centroids)"
	row_label.add_theme_font_size_override("font_size", 16)
	row3_container.add_child(row_label)
	
	# Show palettes for different k values
	for k in [2, 5, 10, 15]:
		if quantized_results.has(k):
			add_palette_panel(row3_container, str(k) + " Colors", quantized_results[k].palette)

func add_image_panel(parent: Control, label_text: String, image_data: Array, palette: Array):
	var panel = VBoxContainer.new()
	
	# Label
	var label = Label.new()
	label.text = label_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(label)
	
	# Image representation (simplified as colored squares)
	var image_grid = GridContainer.new()
	image_grid.columns = 32  # Assuming 32x32 image
	image_grid.custom_minimum_size = Vector2(128, 128)
	
	for color in image_data:
		var pixel = ColorRect.new()
		pixel.color = color
		pixel.custom_minimum_size = Vector2(4, 4)
		image_grid.add_child(pixel)
	
	panel.add_child(image_grid)
	
	# Color count info
	var info_label = Label.new()
	info_label.text = "Colors: " + str(palette.size())
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.add_theme_font_size_override("font_size", 10)
	panel.add_child(info_label)
	
	parent.add_child(panel)

func add_palette_panel(parent: Control, label_text: String, palette: Array):
	var panel = VBoxContainer.new()
	
	# Label
	var label = Label.new()
	label.text = label_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(label)
	
	# Palette colors
	var palette_container = HBoxContainer.new()
	for color in palette:
		var color_swatch = ColorRect.new()
		color_swatch.color = color
		color_swatch.custom_minimum_size = Vector2(40, 40)
		palette_container.add_child(color_swatch)
	
	panel.add_child(palette_container)
	
	# RGB values (for first few colors)
	var rgb_info = VBoxContainer.new()
	for i in range(min(3, palette.size())):
		var color = palette[i]
		var rgb_label = Label.new()
		rgb_label.text = "RGB(%d,%d,%d)" % [color.r8, color.g8, color.b8]
		rgb_label.add_theme_font_size_override("font_size", 8)
		rgb_info.add_child(rgb_label)
	
	panel.add_child(rgb_info)
	parent.add_child(panel)

func apply_kmeans_quantization(image_data: Array, k: int) -> Array:
	# Simplified k-means color quantization algorithm
	if k >= original_colors.size():
		return image_data.duplicate()
	
	# Initialize centroids randomly from existing colors
	var centroids = []
	var used_indices = []
	
	for i in range(k):
		var rand_idx = randi() % original_colors.size()
		while used_indices.has(rand_idx) and used_indices.size() < original_colors.size():
			rand_idx = randi() % original_colors.size()
		used_indices.append(rand_idx)
		centroids.append(original_colors[rand_idx])
	
	# Perform k-means iterations (simplified)
	for iteration in range(5):  # Limited iterations for demo
		var clusters = []
		for i in range(k):
			clusters.append([])
		
		# Assign pixels to nearest centroid
		for color in image_data:
			var nearest_idx = 0
			var min_dist = color_distance(color, centroids[0])
			
			for i in range(1, k):
				var dist = color_distance(color, centroids[i])
				if dist < min_dist:
					min_dist = dist
					nearest_idx = i
			
			clusters[nearest_idx].append(color)
		
		# Update centroids
		for i in range(k):
			if clusters[i].size() > 0:
				centroids[i] = calculate_color_mean(clusters[i])
	
	# Replace all colors with nearest centroid
	var quantized_data = []
	for color in image_data:
		var nearest_idx = 0
		var min_dist = color_distance(color, centroids[0])
		
		for i in range(1, k):
			var dist = color_distance(color, centroids[i])
			if dist < min_dist:
				min_dist = dist
				nearest_idx = i
		
		quantized_data.append(centroids[nearest_idx])
	
	return quantized_data

func color_distance(color1: Color, color2: Color) -> float:
	# Euclidean distance in RGB space
	var dr = color1.r - color2.r
	var dg = color1.g - color2.g  
	var db = color1.b - color2.b
	return sqrt(dr*dr + dg*dg + db*db)

func calculate_color_mean(colors: Array) -> Color:
	if colors.is_empty():
		return Color.BLACK
	
	var sum_r = 0.0
	var sum_g = 0.0
	var sum_b = 0.0
	
	for color in colors:
		sum_r += color.r
		sum_g += color.g
		sum_b += color.b
	
	var count = colors.size()
	return Color(sum_r/count, sum_g/count, sum_b/count)

func extract_color_palette(image_data: Array, max_colors: int) -> Array:
	# Extract unique colors from quantized data
	var unique_colors = []
	for color in image_data:
		if not unique_colors.has(color) and unique_colors.size() < max_colors:
			unique_colors.append(color)
	
	return unique_colors

func scale_image_data(original_data: Array, original_size: int, new_size: int) -> Array:
	# Simple nearest-neighbor scaling
	var scaled_data = []
	var scale_factor = float(original_size) / float(new_size)
	
	for y in range(new_size):
		for x in range(new_size):
			var src_x = int(x * scale_factor)
			var src_y = int(y * scale_factor)
			var src_idx = src_y * original_size + src_x
			
			if src_idx < original_data.size():
				scaled_data.append(original_data[src_idx])
			else:
				scaled_data.append(Color.BLACK)
	
	return scaled_data