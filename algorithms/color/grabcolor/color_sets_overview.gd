extends Node3D

const GRAB_PAPER_SCENE = preload("res://commons/primitives/panels/DigitalPaper/grab_paper.tscn")
const DEFAULT_PALETTE_PATH := "res://algorithms/color/color_palettes.tres"

# grab_paper size: ~0.2 x 0.01 x 0.2
const PAPER_SIZE := Vector2(0.2, 0.2)  # X and Z dimensions
const PAPER_GAP := 0.02  # Gap between papers

# Web colors lookup table (name -> Color) for closest color matching
const WEB_COLORS := {
	"AliceBlue": Color(0.941, 0.973, 1.0),
	"Aqua": Color(0.0, 1.0, 1.0),
	"Aquamarine": Color(0.498, 1.0, 0.831),
	"Azure": Color(0.941, 1.0, 1.0),
	"Beige": Color(0.961, 0.961, 0.863),
	"Black": Color(0.0, 0.0, 0.0),
	"Blue": Color(0.0, 0.0, 1.0),
	"BlueViolet": Color(0.541, 0.169, 0.886),
	"Brown": Color(0.647, 0.165, 0.165),
	"Chartreuse": Color(0.498, 1.0, 0.0),
	"Chocolate": Color(0.824, 0.412, 0.118),
	"Coral": Color(1.0, 0.498, 0.314),
	"CornflowerBlue": Color(0.392, 0.584, 0.929),
	"Crimson": Color(0.863, 0.078, 0.235),
	"Cyan": Color(0.0, 1.0, 1.0),
	"DarkBlue": Color(0.0, 0.0, 0.545),
	"DarkCyan": Color(0.0, 0.545, 0.545),
	"DarkGray": Color(0.663, 0.663, 0.663),
	"DarkGreen": Color(0.0, 0.392, 0.0),
	"DarkMagenta": Color(0.545, 0.0, 0.545),
	"DarkOrange": Color(1.0, 0.549, 0.0),
	"DarkOrchid": Color(0.600, 0.196, 0.800),
	"DarkRed": Color(0.545, 0.0, 0.0),
	"DarkViolet": Color(0.580, 0.0, 0.827),
	"DeepPink": Color(1.0, 0.078, 0.576),
	"DeepSkyBlue": Color(0.0, 0.749, 1.0),
	"DodgerBlue": Color(0.118, 0.565, 1.0),
	"Firebrick": Color(0.698, 0.133, 0.133),
	"ForestGreen": Color(0.133, 0.545, 0.133),
	"Fuchsia": Color(1.0, 0.0, 1.0),
	"Gold": Color(1.0, 0.843, 0.0),
	"Goldenrod": Color(0.855, 0.647, 0.125),
	"Gray": Color(0.502, 0.502, 0.502),
	"Green": Color(0.0, 0.502, 0.0),
	"GreenYellow": Color(0.678, 1.0, 0.184),
	"HotPink": Color(1.0, 0.412, 0.706),
	"IndianRed": Color(0.804, 0.361, 0.361),
	"Indigo": Color(0.294, 0.0, 0.510),
	"Khaki": Color(0.941, 0.902, 0.549),
	"Lavender": Color(0.902, 0.902, 0.980),
	"LawnGreen": Color(0.486, 0.988, 0.0),
	"LightBlue": Color(0.678, 0.847, 0.902),
	"LightCoral": Color(0.941, 0.502, 0.502),
	"LightCyan": Color(0.878, 1.0, 1.0),
	"LightGray": Color(0.827, 0.827, 0.827),
	"LightGreen": Color(0.565, 0.933, 0.565),
	"LightPink": Color(1.0, 0.714, 0.757),
	"LightSkyBlue": Color(0.529, 0.808, 0.980),
	"LightYellow": Color(1.0, 1.0, 0.878),
	"Lime": Color(0.0, 1.0, 0.0),
	"LimeGreen": Color(0.196, 0.804, 0.196),
	"Magenta": Color(1.0, 0.0, 1.0),
	"Maroon": Color(0.502, 0.0, 0.0),
	"MediumBlue": Color(0.0, 0.0, 0.804),
	"MediumOrchid": Color(0.729, 0.333, 0.827),
	"MediumPurple": Color(0.576, 0.439, 0.859),
	"MediumSeaGreen": Color(0.235, 0.702, 0.443),
	"MediumSpringGreen": Color(0.0, 0.980, 0.604),
	"MidnightBlue": Color(0.098, 0.098, 0.439),
	"Navy": Color(0.0, 0.0, 0.502),
	"Olive": Color(0.502, 0.502, 0.0),
	"Orange": Color(1.0, 0.647, 0.0),
	"OrangeRed": Color(1.0, 0.271, 0.0),
	"Orchid": Color(0.855, 0.439, 0.839),
	"PaleGreen": Color(0.596, 0.984, 0.596),
	"PaleTurquoise": Color(0.686, 0.933, 0.933),
	"Peru": Color(0.804, 0.522, 0.247),
	"Pink": Color(1.0, 0.753, 0.796),
	"Plum": Color(0.867, 0.627, 0.867),
	"Purple": Color(0.502, 0.0, 0.502),
	"Red": Color(1.0, 0.0, 0.0),
	"RoyalBlue": Color(0.255, 0.412, 0.882),
	"Salmon": Color(0.980, 0.502, 0.447),
	"SeaGreen": Color(0.180, 0.545, 0.341),
	"Sienna": Color(0.627, 0.322, 0.176),
	"Silver": Color(0.753, 0.753, 0.753),
	"SkyBlue": Color(0.529, 0.808, 0.922),
	"SlateBlue": Color(0.416, 0.353, 0.804),
	"SlateGray": Color(0.439, 0.502, 0.565),
	"SpringGreen": Color(0.0, 1.0, 0.498),
	"SteelBlue": Color(0.275, 0.510, 0.706),
	"Tan": Color(0.824, 0.706, 0.549),
	"Teal": Color(0.0, 0.502, 0.502),
	"Tomato": Color(1.0, 0.388, 0.278),
	"Turquoise": Color(0.251, 0.878, 0.816),
	"Violet": Color(0.933, 0.510, 0.933),
	"Wheat": Color(0.961, 0.871, 0.702),
	"White": Color(1.0, 1.0, 1.0),
	"Yellow": Color(1.0, 1.0, 0.0),
	"YellowGreen": Color(0.604, 0.804, 0.196)
}

@export var palette_resource: Resource
@export var sets_to_show: int = 12
@export var colors_per_set: int = 12
@export var set_spacing_x: float = 1.0  # Spacing between palette sets (X)
@export var set_spacing_z: float = 0.8  # Spacing between palette sets (Z)
@export var columns: int = 4  # Palette sets per row
@export var colors_per_row: int = 4  # Colors per row within a set (3 rows of 4 = 12)

var palette_keys: Array = []

func _ready() -> void:
	_ensure_palette_resource()
	palette_keys = _collect_palette_keys()
	if palette_keys.is_empty():
		push_warning("ColorSetsOverview: No color palettes available")
		return
	create_overview()

func _ensure_palette_resource() -> void:
	if palette_resource != null:
		return
	if ResourceLoader.exists(DEFAULT_PALETTE_PATH):
		palette_resource = ResourceLoader.load(DEFAULT_PALETTE_PATH)
	else:
		push_warning("ColorSetsOverview: Palette resource not found at %s" % DEFAULT_PALETTE_PATH)

func _collect_palette_keys() -> Array:
	if palette_resource and "palettes" in palette_resource:
		var palettes = palette_resource.palettes
		if typeof(palettes) == TYPE_DICTIONARY:
			return Array(palettes.keys())
	return []

func _get_palette_entry(palette_name: String) -> Dictionary:
	if palette_resource and "palettes" in palette_resource:
		var palettes = palette_resource.palettes
		if palettes.has(palette_name):
			return palettes[palette_name]
	return {}

func _get_palette_colors(palette_name: String) -> Array:
	var entry = _get_palette_entry(palette_name)
	if entry.is_empty():
		return []
	var colors_source = entry.get("colors", [])
	var result: Array = []
	for value in colors_source:
		if value is Color:
			result.append(value)
	return result

func create_overview() -> void:
	# Clear existing children
	for child in get_children():
		if child.name.begins_with("PaletteSet_"):
			child.queue_free()
	
	var num_sets = min(sets_to_show, palette_keys.size())
	
	for set_index in range(num_sets):
		var palette_key = palette_keys[set_index]
		var colors = _get_palette_colors(palette_key)
		
		# Calculate set position in grid
		var row = set_index / columns
		var col = set_index % columns
		var set_position = Vector3(col * set_spacing_x, 0, row * set_spacing_z)
		
		# Create container for this palette set
		var set_container = Node3D.new()
		set_container.name = "PaletteSet_%d" % set_index
		set_container.position = set_position
		add_child(set_container)
		
		# Create color swatches - 3 rows stacked in Y (vertical)
		var num_colors = min(colors_per_set, colors.size())
		for color_index in range(num_colors):
			var color = colors[color_index]
			var swatch = _create_color_swatch(color)
			swatch.name = "Swatch_%d" % color_index
			
			# Arrange: colors_per_row columns (X), 3 rows stacked vertically (Y)
			var swatch_col = color_index % colors_per_row
			var swatch_row = color_index / colors_per_row
			var step_x = PAPER_SIZE.x + PAPER_GAP
			var step_y = PAPER_SIZE.y + PAPER_GAP
			
			swatch.position = Vector3(
				swatch_col * step_x,
				swatch_row * step_y,  # Stack rows in Y (vertical)
				0
			)
			set_container.add_child(swatch)

func _create_color_swatch(color: Color) -> Node3D:
	# Create grabbable paper with color
	if GRAB_PAPER_SCENE:
		var grab_swatch = GRAB_PAPER_SCENE.instantiate()
		if grab_swatch:
			# Remove the label from grab_paper
			var label = grab_swatch.get_node_or_null("Label")
			if label:
				label.queue_free()
			
			# Apply color to the mesh
			var mesh_node = grab_swatch.get_node_or_null("MeshInstance3D")
			if mesh_node and mesh_node is MeshInstance3D:
				var material = StandardMaterial3D.new()
				material.albedo_color = color
				material.emission_enabled = true
				material.emission = color * 0.4
				material.emission_energy_multiplier = 0.6
				mesh_node.material_override = material
			
			# Add color info label
			_add_color_info_label(grab_swatch, color)
			return grab_swatch
	
	# Fallback: static mesh matching grab_paper size
	var swatch_root = StaticBody3D.new()
	
	var mesh_instance = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(PAPER_SIZE.x, 0.01, PAPER_SIZE.y)
	mesh_instance.mesh = box_mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color * 0.4
	material.emission_energy_multiplier = 0.6
	mesh_instance.material_override = material
	swatch_root.add_child(mesh_instance)
	
	# Add collision for pointer interaction
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(PAPER_SIZE.x, 0.01, PAPER_SIZE.y)
	collision.shape = shape
	swatch_root.add_child(collision)
	
	# Set collision layer for pointer interaction (layer 21)
	swatch_root.collision_layer = 1 << 20
	swatch_root.collision_mask = 0
	
	# Add color info label to fallback swatch too
	_add_color_info_label(swatch_root, color)
	
	return swatch_root

# Add a Label3D with hex value and web color name
func _add_color_info_label(swatch: Node3D, color: Color) -> void:
	var hex_value = _color_to_hex(color)
	var web_name = _get_closest_web_color_name(color)
	
	var label = Label3D.new()
	label.name = "ColorInfoLabel"
	label.text = "%s\n%s" % [hex_value, web_name]
	label.font_size = 24
	label.pixel_size = 0.001
	label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	
	# Position label above the swatch, facing up (readable from above)
	label.position = Vector3(PAPER_SIZE.x * 0.5, 0.015, PAPER_SIZE.y * 0.5)
	label.rotation_degrees = Vector3(-90, 0, 0)  # Face upward
	
	# Use contrasting color for text (black or white based on luminance)
	var luminance = color.r * 0.299 + color.g * 0.587 + color.b * 0.114
	if luminance > 0.5:
		label.modulate = Color.BLACK
		label.outline_modulate = Color.WHITE
	else:
		label.modulate = Color.WHITE
		label.outline_modulate = Color.BLACK
	label.outline_size = 4
	
	# Ensure label renders on top
	label.no_depth_test = true
	
	swatch.add_child(label)

# Convert Color to hex string (#RRGGBB)
func _color_to_hex(color: Color) -> String:
	var r = int(color.r * 255)
	var g = int(color.g * 255)
	var b = int(color.b * 255)
	return "#%02X%02X%02X" % [r, g, b]

# Find the closest web color name for a given color
func _get_closest_web_color_name(target: Color) -> String:
	var closest_name := "Unknown"
	var min_distance := INF
	
	for color_name in WEB_COLORS:
		var web_color: Color = WEB_COLORS[color_name]
		var distance = _color_distance(target, web_color)
		if distance < min_distance:
			min_distance = distance
			closest_name = color_name
	
	return closest_name

# Euclidean distance in RGB space
func _color_distance(c1: Color, c2: Color) -> float:
	var dr = c1.r - c2.r
	var dg = c1.g - c2.g
	var db = c1.b - c2.b
	return dr * dr + dg * dg + db * db
