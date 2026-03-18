extends Node3D

const GRAB_PAPER_SCENE = preload("res://commons/primitives/panels/DigitalPaper/grab_paper.tscn")
const DEFAULT_PALETTE_PATH := "res://algorithms/color/color_palettes.tres"

# Web colors lookup table (name -> Color)
const WEB_COLORS := {
	"AliceBlue": Color(0.941, 0.973, 1.0),
	"AntiqueWhite": Color(0.980, 0.922, 0.843),
	"Aqua": Color(0.0, 1.0, 1.0),
	"Aquamarine": Color(0.498, 1.0, 0.831),
	"Azure": Color(0.941, 1.0, 1.0),
	"Beige": Color(0.961, 0.961, 0.863),
	"Bisque": Color(1.0, 0.894, 0.769),
	"Black": Color(0.0, 0.0, 0.0),
	"BlanchedAlmond": Color(1.0, 0.922, 0.804),
	"Blue": Color(0.0, 0.0, 1.0),
	"BlueViolet": Color(0.541, 0.169, 0.886),
	"Brown": Color(0.647, 0.165, 0.165),
	"BurlyWood": Color(0.871, 0.722, 0.529),
	"CadetBlue": Color(0.373, 0.620, 0.627),
	"Chartreuse": Color(0.498, 1.0, 0.0),
	"Chocolate": Color(0.824, 0.412, 0.118),
	"Coral": Color(1.0, 0.498, 0.314),
	"CornflowerBlue": Color(0.392, 0.584, 0.929),
	"Cornsilk": Color(1.0, 0.973, 0.863),
	"Crimson": Color(0.863, 0.078, 0.235),
	"Cyan": Color(0.0, 1.0, 1.0),
	"DarkBlue": Color(0.0, 0.0, 0.545),
	"DarkCyan": Color(0.0, 0.545, 0.545),
	"DarkGoldenrod": Color(0.722, 0.525, 0.043),
	"DarkGray": Color(0.663, 0.663, 0.663),
	"DarkGreen": Color(0.0, 0.392, 0.0),
	"DarkKhaki": Color(0.741, 0.718, 0.420),
	"DarkMagenta": Color(0.545, 0.0, 0.545),
	"DarkOliveGreen": Color(0.333, 0.420, 0.184),
	"DarkOrange": Color(1.0, 0.549, 0.0),
	"DarkOrchid": Color(0.600, 0.196, 0.800),
	"DarkRed": Color(0.545, 0.0, 0.0),
	"DarkSalmon": Color(0.914, 0.588, 0.478),
	"DarkSeaGreen": Color(0.561, 0.737, 0.561),
	"DarkSlateBlue": Color(0.282, 0.239, 0.545),
	"DarkSlateGray": Color(0.184, 0.310, 0.310),
	"DarkTurquoise": Color(0.0, 0.808, 0.820),
	"DarkViolet": Color(0.580, 0.0, 0.827),
	"DeepPink": Color(1.0, 0.078, 0.576),
	"DeepSkyBlue": Color(0.0, 0.749, 1.0),
	"DimGray": Color(0.412, 0.412, 0.412),
	"DodgerBlue": Color(0.118, 0.565, 1.0),
	"Firebrick": Color(0.698, 0.133, 0.133),
	"FloralWhite": Color(1.0, 0.980, 0.941),
	"ForestGreen": Color(0.133, 0.545, 0.133),
	"Fuchsia": Color(1.0, 0.0, 1.0),
	"Gainsboro": Color(0.863, 0.863, 0.863),
	"GhostWhite": Color(0.973, 0.973, 1.0),
	"Gold": Color(1.0, 0.843, 0.0),
	"Goldenrod": Color(0.855, 0.647, 0.125),
	"Gray": Color(0.502, 0.502, 0.502),
	"Green": Color(0.0, 0.502, 0.0),
	"GreenYellow": Color(0.678, 1.0, 0.184),
	"Honeydew": Color(0.941, 1.0, 0.941),
	"HotPink": Color(1.0, 0.412, 0.706),
	"IndianRed": Color(0.804, 0.361, 0.361),
	"Indigo": Color(0.294, 0.0, 0.510),
	"Ivory": Color(1.0, 1.0, 0.941),
	"Khaki": Color(0.941, 0.902, 0.549),
	"Lavender": Color(0.902, 0.902, 0.980),
	"LavenderBlush": Color(1.0, 0.941, 0.961),
	"LawnGreen": Color(0.486, 0.988, 0.0),
	"LemonChiffon": Color(1.0, 0.980, 0.804),
	"LightBlue": Color(0.678, 0.847, 0.902),
	"LightCoral": Color(0.941, 0.502, 0.502),
	"LightCyan": Color(0.878, 1.0, 1.0),
	"LightGoldenrodYellow": Color(0.980, 0.980, 0.824),
	"LightGray": Color(0.827, 0.827, 0.827),
	"LightGreen": Color(0.565, 0.933, 0.565),
	"LightPink": Color(1.0, 0.714, 0.757),
	"LightSalmon": Color(1.0, 0.627, 0.478),
	"LightSeaGreen": Color(0.125, 0.698, 0.667),
	"LightSkyBlue": Color(0.529, 0.808, 0.980),
	"LightSlateGray": Color(0.467, 0.533, 0.600),
	"LightSteelBlue": Color(0.690, 0.769, 0.871),
	"LightYellow": Color(1.0, 1.0, 0.878),
	"Lime": Color(0.0, 1.0, 0.0),
	"LimeGreen": Color(0.196, 0.804, 0.196),
	"Linen": Color(0.980, 0.941, 0.902),
	"Magenta": Color(1.0, 0.0, 1.0),
	"Maroon": Color(0.502, 0.0, 0.0),
	"MediumAquamarine": Color(0.400, 0.804, 0.667),
	"MediumBlue": Color(0.0, 0.0, 0.804),
	"MediumOrchid": Color(0.729, 0.333, 0.827),
	"MediumPurple": Color(0.576, 0.439, 0.859),
	"MediumSeaGreen": Color(0.235, 0.702, 0.443),
	"MediumSlateBlue": Color(0.482, 0.408, 0.933),
	"MediumSpringGreen": Color(0.0, 0.980, 0.604),
	"MediumTurquoise": Color(0.282, 0.820, 0.800),
	"MediumVioletRed": Color(0.780, 0.082, 0.522),
	"MidnightBlue": Color(0.098, 0.098, 0.439),
	"MintCream": Color(0.961, 1.0, 0.980),
	"MistyRose": Color(1.0, 0.894, 0.882),
	"Moccasin": Color(1.0, 0.894, 0.710),
	"NavajoWhite": Color(1.0, 0.871, 0.678),
	"Navy": Color(0.0, 0.0, 0.502),
	"OldLace": Color(0.992, 0.961, 0.902),
	"Olive": Color(0.502, 0.502, 0.0),
	"OliveDrab": Color(0.420, 0.557, 0.137),
	"Orange": Color(1.0, 0.647, 0.0),
	"OrangeRed": Color(1.0, 0.271, 0.0),
	"Orchid": Color(0.855, 0.439, 0.839),
	"PaleGoldenrod": Color(0.933, 0.910, 0.667),
	"PaleGreen": Color(0.596, 0.984, 0.596),
	"PaleTurquoise": Color(0.686, 0.933, 0.933),
	"PaleVioletRed": Color(0.859, 0.439, 0.576),
	"PapayaWhip": Color(1.0, 0.937, 0.835),
	"PeachPuff": Color(1.0, 0.855, 0.725),
	"Peru": Color(0.804, 0.522, 0.247),
	"Pink": Color(1.0, 0.753, 0.796),
	"Plum": Color(0.867, 0.627, 0.867),
	"PowderBlue": Color(0.690, 0.878, 0.902),
	"Purple": Color(0.502, 0.0, 0.502),
	"RebeccaPurple": Color(0.400, 0.200, 0.600),
	"Red": Color(1.0, 0.0, 0.0),
	"RosyBrown": Color(0.737, 0.561, 0.561),
	"RoyalBlue": Color(0.255, 0.412, 0.882),
	"SaddleBrown": Color(0.545, 0.271, 0.075),
	"Salmon": Color(0.980, 0.502, 0.447),
	"SandyBrown": Color(0.957, 0.643, 0.376),
	"SeaGreen": Color(0.180, 0.545, 0.341),
	"Seashell": Color(1.0, 0.961, 0.933),
	"Sienna": Color(0.627, 0.322, 0.176),
	"Silver": Color(0.753, 0.753, 0.753),
	"SkyBlue": Color(0.529, 0.808, 0.922),
	"SlateBlue": Color(0.416, 0.353, 0.804),
	"SlateGray": Color(0.439, 0.502, 0.565),
	"Snow": Color(1.0, 0.980, 0.980),
	"SpringGreen": Color(0.0, 1.0, 0.498),
	"SteelBlue": Color(0.275, 0.510, 0.706),
	"Tan": Color(0.824, 0.706, 0.549),
	"Teal": Color(0.0, 0.502, 0.502),
	"Thistle": Color(0.847, 0.749, 0.847),
	"Tomato": Color(1.0, 0.388, 0.278),
	"Turquoise": Color(0.251, 0.878, 0.816),
	"Violet": Color(0.933, 0.510, 0.933),
	"Wheat": Color(0.961, 0.871, 0.702),
	"White": Color(1.0, 1.0, 1.0),
	"WhiteSmoke": Color(0.961, 0.961, 0.961),
	"Yellow": Color(1.0, 1.0, 0.0),
	"YellowGreen": Color(0.604, 0.804, 0.196)
}

func get_closest_web_color_name(target: Color) -> String:
	var closest_name := "Unknown"
	var min_distance := INF
	
	for color_name in WEB_COLORS:
		var web_color: Color = WEB_COLORS[color_name]
		var distance = _color_distance(target, web_color)
		if distance < min_distance:
			min_distance = distance
			closest_name = color_name
	
	return closest_name

func _color_distance(c1: Color, c2: Color) -> float:
	# Euclidean distance in RGB space
	var dr = c1.r - c2.r
	var dg = c1.g - c2.g
	var db = c1.b - c2.b
	return dr * dr + dg * dg + db * db

@export var paper_spacing: float = 0.02
@export var stack_height: float = 0.0
@export var paper_scale: Vector3 = Vector3(1.0, 1.0, 1.0)
@export var color_palette_resource: Resource

# Grid layout settings - horizontal XZ plane only
@export var grid_columns: int = 5  # Number of stickers horizontally (X axis)
@export var grid_rows: int = 2     # Number of stickers in depth (Z axis)
@export var sticker_width: float = 0.195  # From grab_paper mesh size
@export var grid_gutter: float = 0.03  # Small gutter between stickers
var palette_keys: Array = []
var current_palette_index: int = 0

func _ready() -> void:
	_ensure_palette_resource()
	palette_keys = _collect_palette_keys()
	if palette_keys.is_empty():
		push_warning("GrabColorCollection: No color palettes available")
		return

	var name_hash = name.hash()
	current_palette_index = abs(name_hash) % palette_keys.size()
	create_grab_paper_stack()

func _ensure_palette_resource() -> void:
	if color_palette_resource != null:
		return
	if ResourceLoader.exists(DEFAULT_PALETTE_PATH):
		color_palette_resource = ResourceLoader.load(DEFAULT_PALETTE_PATH)
	else:
		push_warning("GrabColorCollection: Palette resource not found at %s" % DEFAULT_PALETTE_PATH)

func _collect_palette_keys() -> Array:
	var palettes_dict = _get_palettes_dict()
	if palettes_dict.is_empty():
		return []
	return Array(palettes_dict.keys())

func _get_palettes_dict() -> Dictionary:
	if color_palette_resource and "palettes" in color_palette_resource:
		var palettes = color_palette_resource.palettes
		if typeof(palettes) == TYPE_DICTIONARY:
			return palettes
	return {}

func _get_palette_entry(palette_name: String) -> Dictionary:
	var palettes_dict = _get_palettes_dict()
	if palettes_dict.has(palette_name):
		return palettes_dict[palette_name]
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

func _get_palette_title(palette_name: String) -> String:
	var entry = _get_palette_entry(palette_name)
	return entry.get("title", palette_name)



func create_grab_paper_stack() -> void:
	for child in get_children():
		if child.name.begins_with("GrabPaper"):
			child.queue_free()

	# Calculate grid spacing
	var cell_spacing = sticker_width + grid_gutter

	# Create 10 papers in a simple XZ grid layout
	var total_papers = 10
	for i in range(total_papers):
		var paper_instance = GRAB_PAPER_SCENE.instantiate()
		paper_instance.name = "GrabPaper_%d" % i

		# Calculate position in XZ grid (single layer)
		var row = i / grid_columns
		var col = i % grid_columns

		var x_pos = col * cell_spacing
		var y_pos = stack_height
		var z_pos = row * cell_spacing
		paper_instance.position = Vector3(x_pos, y_pos, z_pos)
		paper_instance.scale = paper_scale

		var color = get_color_from_current_palette(i)
		set_paper_color(paper_instance, color)

		add_child(paper_instance)
		print("Created GrabPaper_%d at grid position (col:%d, row:%d) with color: %s" % [i, col, row, color])

func get_color_from_current_palette(paper_index: int) -> Color:
	if palette_keys.is_empty():
		return Color.WHITE

	var current_key = palette_keys[current_palette_index % palette_keys.size()]
	var colors = _get_palette_colors(current_key)
	if colors.is_empty():
		return Color.WHITE

	return colors[paper_index % colors.size()]

func update_paper_colors() -> void:
	if palette_keys.is_empty():
		return

	var current_key = palette_keys[current_palette_index % palette_keys.size()]
	var colors = _get_palette_colors(current_key)
	var palette_title = _get_palette_title(current_key)
	print("Using palette: %s" % palette_title)

	for i in range(10):
		var paper_name = "GrabPaper_%d" % i
		var paper_instance = get_node_or_null(paper_name)
		if paper_instance:
			var color = colors[i % colors.size()] if colors.size() > 0 else Color.WHITE
			set_paper_color(paper_instance, color)
			print("Updated %s with color: %s" % [paper_name, color])

func set_paper_color(paper_instance: Node3D, color: Color) -> void:
	var mesh_instance = paper_instance.get_node_or_null("MeshInstance3D")
	if mesh_instance and mesh_instance.material_override != null:
		var material = StandardMaterial3D.new()
		material.albedo_color = color
		material.metallic = 0.1
		material.roughness = 0.3
		material.emission_enabled = true
		material.emission = color * 0.2
		material.emission_energy_multiplier = 0.5
		mesh_instance.material_override = material

		var label = paper_instance.get_node_or_null("Label")
		if label:
			var hex_code = color.to_html(false)
			var web_name = get_closest_web_color_name(color)
			label.text = "#%s\n%s" % [hex_code, web_name]
	else:
		print("Warning: Could not find MeshInstance3D or material for paper")

func regenerate_stack() -> void:
	create_grab_paper_stack()

func add_paper_to_top() -> void:
	if palette_keys.is_empty():
		return

	var paper_instance = GRAB_PAPER_SCENE.instantiate()

	# Count existing papers to determine grid position
	var paper_count = 0
	for child in get_children():
		if child.name.begins_with("GrabPaper"):
			paper_count += 1

	paper_instance.name = "GrabPaper_%d" % paper_count

	# Calculate grid spacing
	var cell_spacing = sticker_width + grid_gutter

	# Calculate position in XZ grid
	var row = paper_count / grid_columns
	var col = paper_count % grid_columns

	var x_pos = col * cell_spacing
	var y_pos = stack_height
	var z_pos = row * cell_spacing
	paper_instance.position = Vector3(x_pos, y_pos, z_pos)
	paper_instance.scale = paper_scale

	var color = get_color_from_current_palette(paper_count)
	set_paper_color(paper_instance, color)

	add_child(paper_instance)
	print("Added paper at grid position (col:%d, row:%d) with color: %s" % [col, row, color])

func cycle_to_next_palette() -> void:
	if palette_keys.is_empty():
		return

	current_palette_index = (current_palette_index + 1) % palette_keys.size()
	update_paper_colors()

func get_current_palette_name() -> String:
	if palette_keys.is_empty():
		return "No Palette"
	var current_key = palette_keys[current_palette_index % palette_keys.size()]
	return _get_palette_title(current_key)

func remove_top_paper() -> void:
	var papers = []
	for child in get_children():
		if child.name.begins_with("GrabPaper"):
			papers.append(child)

	if papers.size() > 0:
		var top_paper = papers[-1]
		print("Removing paper: %s" % top_paper.name)
		top_paper.queue_free()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
