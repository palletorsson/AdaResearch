extends Node3D

# @identity
# essence: palette_atlas — N palettes laid out as grabbable sticker grids, each sticker labeled with hex + nearest web color name
# desire: to pick up a color, read its name, and carry it across the room — making color portable and personal
# critical_parameter: sets_to_show — controls how many palettes are visible simultaneously, determining comparison density
# triggers: none at runtime — static grabbable display; XR pickup on each sticker via grab_paper.tscn
# emerges: the luminance-adaptive label contrast (dark text on light stickers, light on dark) makes every color readable without explicit design per palette
# needs: grab_paper.tscn XR pickup [has]; hex/name labels [has]; VR grab [has]; palette filtering [missing]
# relationships: depends on color_palettes.tres; follows pillarcolorcollection (viewing vs holding color); closest_web_color_name bridges digital hex to human language
# truth: naming a color does not capture it — but it makes the gap between name and experience visible

const GRAB_PAPER_SCENE = preload("res://commons/primitives/panels/DigitalPaper/grab_paper.tscn")
const DEFAULT_PALETTE_PATH := "res://algorithms/color/color_palettes.tres"

# Sticker size: ~0.2 x 0.01 x 0.2 (matches grab_paper mesh)
const STICKER_SIZE := Vector2(0.195, 0.205)  # X and Z dimensions from grab_paper
const STICKER_GAP := 0.02  # Gap between stickers

@export var palette_resource: Resource
@export var sets_to_show: int = 12
@export var colors_per_set: int = 12
@export var set_spacing_x: float = 0.9  # Spacing between palette sets (X) - rows
@export var set_spacing_z: float = 1.4  # Spacing between columns (Z) - room for ramp underneath
@export var columns: int = 2  # Two columns of sticker sets
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
		
		# Calculate set position in grid - columns go in Z direction
		var row = set_index / columns  # Row advances in X
		var col = set_index % columns  # Column is in Z
		var set_position = Vector3(row * set_spacing_x, 0, col * set_spacing_z)
		
		# Create container for this palette set
		var set_container = Node3D.new()
		set_container.name = "PaletteSet_%d" % set_index
		set_container.position = set_position
		# Flip second column (col=1) 180° so stickers face inward toward center
		if col == 1:
			set_container.rotation.y = PI
		add_child(set_container)
		
		# Create color stickers - 3 rows stacked in Y (vertical)
		var num_colors = min(colors_per_set, colors.size())
		for color_index in range(num_colors):
			var color = colors[color_index]
			var sticker = _create_color_sticker(color)
			sticker.name = "Sticker_%d" % color_index
			
			# Arrange: colors_per_row columns (X), 3 rows stacked vertically (Y)
			var sticker_col = color_index % colors_per_row
			var sticker_row = color_index / colors_per_row
			var step_x = STICKER_SIZE.x + STICKER_GAP
			var step_y = STICKER_SIZE.y + STICKER_GAP
			
			sticker.position = Vector3(
				sticker_col * step_x,
				sticker_row * step_y,  # Stack rows in Y (vertical)
				0
			)
			set_container.add_child(sticker)

func _create_color_sticker(color: Color) -> Node3D:
	# Use grab_paper scene (XR-pickable) instead of static color_sticker
	var paper = GRAB_PAPER_SCENE.instantiate()
	
	# Set color on the mesh material
	var mesh_instance = paper.get_node_or_null("MeshInstance3D")
	if mesh_instance:
		var material = StandardMaterial3D.new()
		material.albedo_color = color
		material.metallic = 0.1
		material.roughness = 0.3
		material.emission_enabled = true
		material.emission = color * 0.2
		material.emission_energy_multiplier = 0.5
		mesh_instance.material_override = material
	
	# Show compact color label on each sticker
	var label = paper.get_node_or_null("Label")
	if label and label is Label3D:
		var label3d := label as Label3D
		var hex_value = _color_to_hex(color)
		var web_name = _get_closest_web_color_name(color)
		label3d.visible = true
		label3d.text = "%s\n%s" % [hex_value, web_name]
		
		# Keep labels readable on both light and dark stickers.
		var luminance = color.r * 0.299 + color.g * 0.587 + color.b * 0.114
		if luminance > 0.5:
			label3d.modulate = Color.BLACK
			label3d.outline_modulate = Color.WHITE
		else:
			label3d.modulate = Color.WHITE
			label3d.outline_modulate = Color.BLACK
	
	return paper

func _color_to_hex(color: Color) -> String:
	var r = int(color.r * 255)
	var g = int(color.g * 255)
	var b = int(color.b * 255)
	return "#%02X%02X%02X" % [r, g, b]

func _get_closest_web_color_name(target: Color) -> String:
	var closest_name := "Unknown"
	var min_distance := INF
	var web_colors := {
		"Red": Color(1, 0, 0), "Green": Color(0, 0.502, 0), "Blue": Color(0, 0, 1),
		"Yellow": Color(1, 1, 0), "Cyan": Color(0, 1, 1), "Magenta": Color(1, 0, 1),
		"White": Color(1, 1, 1), "Black": Color(0, 0, 0), "Gray": Color(0.502, 0.502, 0.502),
		"Orange": Color(1, 0.647, 0), "Pink": Color(1, 0.753, 0.796),
		"Purple": Color(0.502, 0, 0.502), "Brown": Color(0.647, 0.165, 0.165),
		"Lime": Color(0, 1, 0), "Navy": Color(0, 0, 0.502), "Teal": Color(0, 0.502, 0.502),
		"Maroon": Color(0.502, 0, 0), "Olive": Color(0.502, 0.502, 0),
		"Coral": Color(1, 0.498, 0.314), "Salmon": Color(0.98, 0.502, 0.447),
		"Gold": Color(1, 0.843, 0), "Indigo": Color(0.294, 0, 0.51),
		"Violet": Color(0.933, 0.51, 0.933), "Crimson": Color(0.863, 0.078, 0.235),
		"Turquoise": Color(0.251, 0.878, 0.816), "Khaki": Color(0.941, 0.902, 0.549),
		"Lavender": Color(0.902, 0.902, 0.98), "Chocolate": Color(0.824, 0.412, 0.118),
		"Tomato": Color(1, 0.388, 0.278), "SkyBlue": Color(0.529, 0.808, 0.922),
		"SlateBlue": Color(0.416, 0.353, 0.804), "DarkGreen": Color(0, 0.392, 0),
		"ForestGreen": Color(0.133, 0.545, 0.133), "Silver": Color(0.753, 0.753, 0.753),
		"DodgerBlue": Color(0.118, 0.565, 1), "HotPink": Color(1, 0.412, 0.706),
		"DeepPink": Color(1, 0.078, 0.576), "Firebrick": Color(0.698, 0.133, 0.133),
		"DarkOrange": Color(1, 0.549, 0), "Sienna": Color(0.627, 0.322, 0.176),
		"Peru": Color(0.804, 0.522, 0.247), "Tan": Color(0.824, 0.706, 0.549),
	}
	for color_name in web_colors:
		var web_color: Color = web_colors[color_name]
		var dr = target.r - web_color.r
		var dg = target.g - web_color.g
		var db = target.b - web_color.b
		var distance = dr * dr + dg * dg + db * db
		if distance < min_distance:
			min_distance = distance
			closest_name = color_name
	return closest_name

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
