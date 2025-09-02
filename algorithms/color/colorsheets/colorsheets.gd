extends Control

# 20 Color Palette Sheets - Cultural, Historical, and Emotional Themes
# Each sheet contains 4x4 color grids representing different concepts

@onready var main_container = VBoxContainer.new()
@onready var scroll_container = ScrollContainer.new()
@onready var sheets_container = VBoxContainer.new()

# Color palette data for 20 different themes
var color_palettes = {
	"starry_night": {
		"title": "Van Gogh's Starry Night",
		"description": "Swirling blues and golden yellows of the night sky",
		"colors": [
			Color(0.063, 0.125, 0.314), # Deep blue night
			Color(0.188, 0.267, 0.471), # Medium blue
			Color(0.376, 0.463, 0.651), # Lighter blue
			Color(0.961, 0.871, 0.443), # Golden yellow stars
			Color(0.153, 0.227, 0.369), # Dark blue swirls
			Color(0.294, 0.357, 0.522), # Blue-gray
			Color(0.867, 0.788, 0.357), # Warm yellow
			Color(0.992, 0.918, 0.565), # Bright yellow
			Color(0.071, 0.090, 0.184), # Almost black blue
			Color(0.235, 0.290, 0.431), # Medium night blue
			Color(0.706, 0.643, 0.302), # Darker yellow
			Color(0.824, 0.749, 0.333)  # Golden highlights
		]
	},
	
	"rothko_chapel": {
		"title": "Rothko Chapel Meditation",
		"description": "Deep purples and maroons for spiritual contemplation",
		"colors": [
			Color(0.184, 0.090, 0.106), # Deep maroon
			Color(0.227, 0.098, 0.125), # Dark red-brown
			Color(0.106, 0.063, 0.082), # Almost black purple
			Color(0.157, 0.078, 0.098), # Dark wine
			Color(0.263, 0.118, 0.141), # Medium maroon
			Color(0.200, 0.086, 0.110), # Deep burgundy
			Color(0.141, 0.071, 0.090), # Dark plum
			Color(0.176, 0.082, 0.102), # Dark red
			Color(0.118, 0.055, 0.071), # Very dark purple
			Color(0.243, 0.106, 0.129), # Lighter maroon
			Color(0.133, 0.067, 0.086), # Deep purple-brown
			Color(0.208, 0.094, 0.114)  # Medium burgundy
		]
	},
	
	"mondrian_grid": {
		"title": "Mondrian's Primary Composition",
		"description": "Bold primary colors with black and white grid",
		"colors": [
			Color(1.000, 1.000, 1.000), # Pure white
			Color(0.000, 0.000, 0.000), # Pure black
			Color(0.902, 0.098, 0.157), # Mondrian red
			Color(0.000, 0.408, 0.780), # Mondrian blue
			Color(1.000, 0.863, 0.000), # Mondrian yellow
			Color(0.941, 0.941, 0.941), # Light gray
			Color(0.157, 0.157, 0.157), # Dark gray
			Color(0.784, 0.086, 0.137), # Deeper red
			Color(0.000, 0.357, 0.682), # Deeper blue
			Color(0.878, 0.757, 0.000), # Deeper yellow
			Color(0.627, 0.627, 0.627), # Medium gray
			Color(0.314, 0.314, 0.314)  # Charcoal gray
		]
	},
	
	"memphis_design": {
		"title": "Memphis Design Movement",
		"description": "80s postmodern bright geometric colors",
		"colors": [
			Color(1.000, 0.078, 0.576), # Hot pink
			Color(0.000, 0.980, 0.604), # Electric green
			Color(0.000, 0.749, 0.992), # Cyan blue
			Color(1.000, 0.647, 0.000), # Electric orange
			Color(0.627, 0.125, 0.941), # Electric purple
			Color(1.000, 0.271, 0.000), # Red-orange
			Color(0.196, 0.804, 0.196), # Lime green
			Color(1.000, 0.412, 0.706), # Bubblegum pink
			Color(0.294, 0.000, 0.510), # Deep purple
			Color(0.000, 0.392, 0.000), # Forest green
			Color(0.000, 0.000, 0.804), # Royal blue
			Color(0.804, 0.522, 0.247)  # Tan/beige accent
		]
	},
	
	"bauhaus_palette": {
		"title": "Bauhaus School Colors",
		"description": "Functional primary colors and industrial grays",
		"colors": [
			Color(0.863, 0.078, 0.235), # Bauhaus red
			Color(0.000, 0.447, 0.698), # Bauhaus blue
			Color(1.000, 0.835, 0.000), # Bauhaus yellow
			Color(0.000, 0.000, 0.000), # Pure black
			Color(1.000, 1.000, 1.000), # Pure white
			Color(0.502, 0.502, 0.502), # Medium gray
			Color(0.745, 0.069, 0.208), # Deeper red
			Color(0.000, 0.392, 0.612), # Deeper blue
			Color(0.878, 0.733, 0.000), # Deeper yellow
			Color(0.251, 0.251, 0.251), # Dark gray
			Color(0.749, 0.749, 0.749), # Light gray
			Color(0.125, 0.125, 0.125)  # Charcoal
		]
	},
	
	"stonewall_freedom": {
		"title": "Stonewall Uprising 1969",
		"description": "Colors of rebellion, pride, and liberation",
		"colors": [
			Color(0.906, 0.298, 0.235), # Brick red (Stonewall Inn)
			Color(0.502, 0.000, 0.502), # Deep purple (resistance)
			Color(1.000, 0.647, 0.000), # Orange (courage)
			Color(0.196, 0.804, 0.196), # Green (hope)
			Color(0.000, 0.749, 0.992), # Cyan (freedom)
			Color(1.000, 0.078, 0.576), # Hot pink (defiance)
			Color(0.627, 0.125, 0.941), # Violet (spirit)
			Color(0.863, 0.078, 0.235), # Revolutionary red
			Color(0.294, 0.000, 0.510), # Royal purple
			Color(0.000, 0.392, 0.000), # Forest green
			Color(0.804, 0.522, 0.247), # Earth brown (grounding)
			Color(1.000, 0.843, 0.000)  # Golden yellow (triumph)
		]
	},
	
	"pride_rainbow": {
		"title": "Pride Flag Evolution",
		"description": "LGBTQ+ pride colors across different flag designs",
		"colors": [
			Color(0.902, 0.098, 0.294), # Red (life)
			Color(1.000, 0.647, 0.000), # Orange (healing)
			Color(1.000, 0.843, 0.000), # Yellow (sunlight)
			Color(0.000, 0.502, 0.251), # Green (nature)
			Color(0.000, 0.318, 0.729), # Blue (harmony)
			Color(0.627, 0.125, 0.941), # Purple (spirit)
			Color(1.000, 0.753, 0.796), # Light pink (trans)
			Color(0.357, 0.808, 0.898), # Light blue (trans)
			Color(0.000, 0.000, 0.000), # Black (community)
			Color(0.647, 0.325, 0.176), # Brown (community)
			Color(1.000, 1.000, 1.000), # White (trans)
			Color(1.000, 0.941, 0.000)  # Bright yellow
		]
	},
	
	"harlem_renaissance": {
		"title": "Harlem Renaissance Jazz",
		"description": "Rich golds, deep blues, and warm browns of the era",
		"colors": [
			Color(0.718, 0.525, 0.043), # Jazz gold
			Color(0.098, 0.098, 0.439), # Midnight blue
			Color(0.545, 0.271, 0.075), # Rich brown
			Color(0.863, 0.078, 0.235), # Vibrant red
			Color(0.000, 0.000, 0.000), # Deep black
			Color(0.941, 0.902, 0.549), # Cream
			Color(0.502, 0.000, 0.000), # Deep burgundy
			Color(0.184, 0.310, 0.310), # Dark teal
			Color(0.722, 0.451, 0.200), # Copper
			Color(0.412, 0.412, 0.412), # Smoky gray
			Color(0.800, 0.498, 0.196), # Warm orange
			Color(0.235, 0.000, 0.392)  # Deep purple
		]
	},
	
	"pinkness_spectrum": {
		"title": "Spectrum of Pinkness",
		"description": "From blush to fuchsia - all shades of pink",
		"colors": [
			Color(1.000, 0.753, 0.796), # Baby pink
			Color(1.000, 0.627, 0.478), # Peach pink
			Color(1.000, 0.412, 0.706), # Bubblegum pink
			Color(0.906, 0.298, 0.235), # Coral pink
			Color(1.000, 0.078, 0.576), # Hot pink
			Color(0.780, 0.082, 0.522), # Deep pink
			Color(1.000, 0.271, 0.000), # Pink-orange
			Color(0.863, 0.627, 0.863), # Plum pink
			Color(1.000, 0.894, 0.882), # Powder pink
			Color(0.941, 0.502, 0.502), # Indian pink
			Color(0.722, 0.333, 0.827), # Orchid
			Color(1.000, 0.000, 1.000)  # Magenta
		]
	},
	
	"dance_energy": {
		"title": "Dance Floor Energy",
		"description": "Electric colors of movement and rhythm",
		"colors": [
			Color(1.000, 0.000, 1.000), # Electric magenta
			Color(0.000, 1.000, 1.000), # Cyan
			Color(1.000, 1.000, 0.000), # Electric yellow
			Color(1.000, 0.271, 0.000), # Electric orange
			Color(0.627, 0.125, 0.941), # Electric purple
			Color(0.000, 0.980, 0.604), # Neon green
			Color(1.000, 0.078, 0.576), # Hot pink
			Color(0.000, 0.749, 0.992), # Electric blue
			Color(0.565, 0.933, 0.565), # Light green
			Color(1.000, 0.647, 0.000), # Vibrant orange
			Color(0.294, 0.000, 0.510), # Deep purple
			Color(1.000, 0.412, 0.706)  # Bright pink
		]
	},
	
	"joy_celebration": {
		"title": "Pure Joy & Celebration",
		"description": "Bright, uplifting colors of happiness",
		"colors": [
			Color(1.000, 0.843, 0.000), # Golden yellow
			Color(1.000, 0.647, 0.000), # Bright orange
			Color(0.196, 0.804, 0.196), # Lime green
			Color(0.000, 0.749, 0.992), # Sky blue
			Color(1.000, 0.412, 0.706), # Cheerful pink
			Color(0.565, 0.933, 0.565), # Light green
			Color(1.000, 1.000, 0.000), # Bright yellow
			Color(1.000, 0.753, 0.796), # Soft pink
			Color(0.678, 0.847, 0.902), # Light blue
			Color(1.000, 0.894, 0.710), # Cream yellow
			Color(0.855, 0.647, 0.125), # Gold
			Color(1.000, 0.500, 0.000)  # Pure orange
		]
	},
	
	"pain_depth": {
		"title": "Depths of Pain",
		"description": "Dark colors expressing sorrow and struggle",
		"colors": [
			Color(0.184, 0.090, 0.106), # Deep maroon
			Color(0.098, 0.098, 0.439), # Midnight blue
			Color(0.106, 0.063, 0.082), # Dark purple
			Color(0.000, 0.000, 0.000), # Pure black
			Color(0.502, 0.000, 0.000), # Dark red
			Color(0.251, 0.251, 0.251), # Dark gray
			Color(0.294, 0.000, 0.510), # Deep purple
			Color(0.122, 0.122, 0.122), # Very dark gray
			Color(0.157, 0.078, 0.098), # Dark wine
			Color(0.176, 0.082, 0.102), # Dark crimson
			Color(0.412, 0.412, 0.412), # Medium gray
			Color(0.071, 0.090, 0.184)  # Deep blue-black
		]
	},
	
	"love_warmth": {
		"title": "Love & Warmth",
		"description": "Tender colors of love and affection",
		"colors": [
			Color(0.863, 0.078, 0.235), # Love red
			Color(1.000, 0.753, 0.796), # Soft pink
			Color(0.941, 0.502, 0.502), # Rose
			Color(1.000, 0.627, 0.478), # Peach
			Color(0.722, 0.333, 0.827), # Orchid
			Color(1.000, 0.894, 0.882), # Blush
			Color(0.863, 0.627, 0.863), # Lavender
			Color(1.000, 0.271, 0.000), # Warm orange
			Color(0.800, 0.498, 0.196), # Golden brown
			Color(1.000, 0.412, 0.706), # Bright pink
			Color(0.941, 0.902, 0.549), # Cream
			Color(0.780, 0.082, 0.522)  # Deep rose
		]
	},
	
	"frida_kahlo": {
		"title": "Frida Kahlo's Palette",
		"description": "Bold Mexican colors of passion and pain",
		"colors": [
			Color(0.863, 0.078, 0.235), # Passionate red
			Color(0.000, 0.392, 0.000), # Cactus green
			Color(1.000, 0.647, 0.000), # Marigold orange
			Color(0.627, 0.125, 0.941), # Purple passion
			Color(0.941, 0.902, 0.549), # Bone white
			Color(0.545, 0.271, 0.075), # Earth brown
			Color(0.000, 0.749, 0.992), # Azure blue
			Color(1.000, 0.843, 0.000), # Golden yellow
			Color(0.502, 0.000, 0.000), # Blood red
			Color(0.294, 0.000, 0.510), # Royal purple
			Color(1.000, 0.078, 0.576), # Magenta
			Color(0.000, 0.000, 0.000)  # Deep black
		]
	},
	
	"hokusai_wave": {
		"title": "Hokusai's Great Wave",
		"description": "Blues and whites of the iconic Japanese wave",
		"colors": [
			Color(0.063, 0.125, 0.314), # Deep ocean blue
			Color(0.188, 0.267, 0.471), # Wave blue
			Color(0.376, 0.463, 0.651), # Lighter blue
			Color(0.565, 0.678, 0.847), # Sky blue
			Color(1.000, 1.000, 1.000), # Foam white
			Color(0.941, 0.941, 0.941), # Light gray
			Color(0.784, 0.863, 0.933), # Pale blue
			Color(0.153, 0.227, 0.369), # Dark water
			Color(0.627, 0.627, 0.627), # Gray
			Color(0.235, 0.290, 0.431), # Medium blue
			Color(0.678, 0.847, 0.902), # Light blue
			Color(0.294, 0.357, 0.522)  # Blue-gray
		]
	},
	
	"desert_sunset": {
		"title": "Desert Sunset Meditation",
		"description": "Warm earth tones and sky colors",
		"colors": [
			Color(1.000, 0.271, 0.000), # Sunset orange
			Color(0.863, 0.078, 0.235), # Deep red
			Color(1.000, 0.647, 0.000), # Golden orange
			Color(0.722, 0.451, 0.200), # Desert sand
			Color(0.545, 0.271, 0.075), # Canyon brown
			Color(1.000, 0.843, 0.000), # Golden yellow
			Color(0.627, 0.125, 0.941), # Purple sky
			Color(0.941, 0.502, 0.502), # Pink clouds
			Color(0.800, 0.498, 0.196), # Copper
			Color(0.294, 0.000, 0.510), # Deep purple
			Color(1.000, 0.894, 0.710), # Pale yellow
			Color(0.502, 0.000, 0.000)  # Deep burgundy
		]
	},
	
	"neon_cyberpunk": {
		"title": "Cyberpunk Neon Dreams",
		"description": "Electric colors of the digital future",
		"colors": [
			Color(1.000, 0.000, 1.000), # Electric magenta
			Color(0.000, 1.000, 1.000), # Neon cyan
			Color(0.000, 0.980, 0.604), # Electric green
			Color(1.000, 0.078, 0.576), # Hot pink
			Color(0.627, 0.125, 0.941), # Electric purple
			Color(1.000, 1.000, 0.000), # Electric yellow
			Color(0.000, 0.749, 0.992), # Bright blue
			Color(1.000, 0.271, 0.000), # Electric orange
			Color(0.000, 0.000, 0.000), # Void black
			Color(0.565, 0.933, 0.565), # Neon green
			Color(0.294, 0.000, 0.510), # Deep purple
			Color(1.000, 0.412, 0.706)  # Bright pink
		]
	},
	
	"autumn_melancholy": {
		"title": "Autumn Melancholy",
		"description": "Fading colors of fall and reflection",
		"colors": [
			Color(0.722, 0.451, 0.200), # Autumn orange
			Color(0.545, 0.271, 0.075), # Brown leaves
			Color(0.800, 0.498, 0.196), # Rust
			Color(0.863, 0.078, 0.235), # Deep red leaves
			Color(0.941, 0.902, 0.549), # Pale yellow
			Color(0.502, 0.000, 0.000), # Dark red
			Color(0.184, 0.310, 0.310), # Gray-green
			Color(0.412, 0.412, 0.412), # Gray sky
			Color(0.718, 0.525, 0.043), # Golden brown
			Color(0.235, 0.000, 0.392), # Deep purple
			Color(0.627, 0.627, 0.627), # Light gray
			Color(0.294, 0.000, 0.510)  # Twilight purple
		]
	},
	
	"tropical_paradise": {
		"title": "Tropical Paradise",
		"description": "Vibrant colors of tropical beaches and forests",
		"colors": [
			Color(0.000, 0.749, 0.992), # Tropical blue
			Color(0.196, 0.804, 0.196), # Palm green
			Color(1.000, 0.647, 0.000), # Sunset orange
			Color(1.000, 0.843, 0.000), # Golden sand
			Color(1.000, 0.412, 0.706), # Hibiscus pink
			Color(0.000, 0.502, 0.251), # Deep green
			Color(1.000, 1.000, 1.000), # White sand
			Color(0.565, 0.933, 0.565), # Light green
			Color(1.000, 0.753, 0.796), # Coral pink
			Color(0.678, 0.847, 0.902), # Sky blue
			Color(1.000, 0.500, 0.000), # Bright orange
			Color(0.000, 0.392, 0.000)  # Forest green
		]
	},
	
	"industrial_brutalism": {
		"title": "Industrial Brutalism",
		"description": "Concrete grays and industrial colors",
		"colors": [
			Color(0.412, 0.412, 0.412), # Concrete gray
			Color(0.251, 0.251, 0.251), # Dark gray
			Color(0.627, 0.627, 0.627), # Light gray
			Color(0.000, 0.000, 0.000), # Deep black
			Color(0.502, 0.502, 0.502), # Medium gray
			Color(0.122, 0.122, 0.122), # Charcoal
			Color(0.718, 0.525, 0.043), # Rust brown
			Color(0.800, 0.498, 0.196), # Oxidized metal
			Color(0.749, 0.749, 0.749), # Pale gray
			Color(0.184, 0.310, 0.310), # Steel blue
			Color(0.314, 0.314, 0.314), # Dark concrete
			Color(0.545, 0.271, 0.075)  # Rust red
		]
	}
}

func _ready():
	setup_ui()
	create_all_palette_sheets()

func setup_ui():
	# Main setup
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Scroll container
	scroll_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(scroll_container)
	
	# Main container
	main_container.add_theme_constant_override("separation", 30)
	scroll_container.add_child(main_container)
	
	# Add margin
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	scroll_container.add_child(margin)
	margin.add_child(main_container)
	
	# Title
	var title = Label.new()
	title.text = "20 Cultural & Emotional Color Palette Sheets"
	title.add_theme_font_size_override("font_size", 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_container.add_child(title)
	
	# Subtitle
	var subtitle = Label.new()
	subtitle.text = "4x4 Color Grids from Art, History, Culture & Human Experience"
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.modulate = Color(0.7, 0.7, 0.7)
	main_container.add_child(subtitle)

func create_all_palette_sheets():
	# Create sheets in a grid layout (2 columns)
	var grid_container = GridContainer.new()
	grid_container.columns = 2
	grid_container.add_theme_constant_override("h_separation", 30)
	grid_container.add_theme_constant_override("v_separation", 30)
	main_container.add_child(grid_container)
	
	# Create each palette sheet
	var palette_keys = color_palettes.keys()
	for palette_key in palette_keys:
		var palette_data = color_palettes[palette_key]
		var sheet = create_palette_sheet(palette_data)
		grid_container.add_child(sheet)

func create_palette_sheet(palette_data: Dictionary) -> Control:
	var sheet_container = VBoxContainer.new()
	sheet_container.add_theme_constant_override("separation", 10)
	
	# Title
	var title_label = Label.new()
	title_label.text = palette_data.title
	title_label.add_theme_font_size_override("font_size", 16)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sheet_container.add_child(title_label)
	
	# Description
	var desc_label = Label.new()
	desc_label.text = palette_data.description
	desc_label.add_theme_font_size_override("font_size", 10)
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.modulate = Color(0.8, 0.8, 0.8)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.custom_minimum_size = Vector2(300, 0)
	sheet_container.add_child(desc_label)
	
	# 4x4 Color grid
	var color_grid = GridContainer.new()
	color_grid.columns = 4
	color_grid.add_theme_constant_override("h_separation", 2)
	color_grid.add_theme_constant_override("v_separation", 2)
	
	var colors = palette_data.colors
	
	# Create 16 color rectangles (4x4 grid)
	for i in range(16):
		var color_rect = ColorRect.new()
		color_rect.custom_minimum_size = Vector2(50, 50)
		
		if i < colors.size():
			color_rect.color = colors[i]
		else:
			# Fill remaining slots with a neutral color
			color_rect.color = Color(0.5, 0.5, 0.5, 0.3)
		
		# Add subtle border
		var border_style = StyleBoxFlat.new()
		border_style.border_width_left = 1
		border_style.border_width_right = 1
		border_style.border_width_top = 1
		border_style.border_width_bottom = 1
		border_style.border_color = Color(0.3, 0.3, 0.3)
		color_rect.add_theme_stylebox_override("panel", border_style)
		
		color_grid.add_child(color_rect)
	
	sheet_container.add_child(color_grid)
	
	# Color count info
	var info_label = Label.new()
	info_label.text = str(colors.size()) + " colors"
	info_label.add_theme_font_size_override("font_size", 8)
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.modulate = Color(0.6, 0.6, 0.6)
	sheet_container.add_child(info_label)
	
	return sheet_container