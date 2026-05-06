extends StaticBody3D
class_name ColorSticker

## A single color sticker with corner label

@export var sticker_color: Color = Color.WHITE : set = set_sticker_color

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var color_label: Label3D = $ColorLabel

# Web colors lookup for closest name matching
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

func _ready() -> void:
	_apply_color()

func set_sticker_color(value: Color) -> void:
	sticker_color = value
	if is_inside_tree():
		_apply_color()

func _apply_color() -> void:
	# Apply material to mesh
	if mesh_instance:
		var material = StandardMaterial3D.new()
		material.albedo_color = sticker_color
		material.emission_enabled = true
		material.emission = sticker_color * 0.4
		material.emission_energy_multiplier = 0.6
		mesh_instance.material_override = material
	
	# Update label
	if color_label:
		var hex_value = _color_to_hex(sticker_color)
		var web_name = _get_closest_web_color_name(sticker_color)
		color_label.text = "%s\n%s" % [hex_value, web_name]
		
		# Contrast text color
		var luminance = sticker_color.r * 0.299 + sticker_color.g * 0.587 + sticker_color.b * 0.114
		if luminance > 0.5:
			color_label.modulate = Color.BLACK
			color_label.outline_modulate = Color.WHITE
		else:
			color_label.modulate = Color.WHITE
			color_label.outline_modulate = Color.BLACK

func _color_to_hex(color: Color) -> String:
	var r = int(color.r * 255)
	var g = int(color.g * 255)
	var b = int(color.b * 255)
	return "#%02X%02X%02X" % [r, g, b]

func _get_closest_web_color_name(target: Color) -> String:
	var closest_name := "Unknown"
	var min_distance := INF
	
	for color_name in WEB_COLORS:
		var web_color: Color = WEB_COLORS[color_name]
		var dr = target.r - web_color.r
		var dg = target.g - web_color.g
		var db = target.b - web_color.b
		var distance = dr * dr + dg * dg + db * db
		if distance < min_distance:
			min_distance = distance
			closest_name = color_name
	
	return closest_name

func apply_grid_config(config: Dictionary) -> void:
	pass
