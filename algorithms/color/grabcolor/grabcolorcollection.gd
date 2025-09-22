extends Node3D

# Grab paper scene resource
const GRAB_PAPER_SCENE = preload("res://commons/primitives/panels/DigitalPaper/grab_paper.tscn")

# Stack configuration
@export var paper_spacing: float = 0.02  # Space between papers
@export var stack_height: float = 0.0   # Starting height for the stack
@export var paper_scale: Vector3 = Vector3(1.0, 1.0, 1.0)  # Scale for each paper

# Color palette data from colorsheets.gd
var color_palettes = {
	"starry_night": {
		"title": "Van Gogh's Starry Night",
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
			Color(0.235, 0.290, 0.431)  # Medium night blue
		]
	},
	"rothko_chapel": {
		"title": "Rothko Chapel Meditation",
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
			Color(0.243, 0.106, 0.129)  # Lighter maroon
		]
	},
	"mondrian_grid": {
		"title": "Mondrian's Primary Composition",
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
			Color(0.878, 0.757, 0.000)  # Deeper yellow
		]
	},
	"memphis_design": {
		"title": "Memphis Design Movement",
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
			Color(0.000, 0.392, 0.000)  # Forest green
		]
	},
	"bauhaus_palette": {
		"title": "Bauhaus School Colors",
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
			Color(0.251, 0.251, 0.251)  # Dark gray
		]
	},
	"pride_rainbow": {
		"title": "Pride Flag Evolution",
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
			Color(0.647, 0.325, 0.176)  # Brown (community)
		]
	},
	"neon_cyberpunk": {
		"title": "Cyberpunk Neon Dreams",
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
			Color(0.565, 0.933, 0.565)  # Neon green
		]
	},
	"tropical_paradise": {
		"title": "Tropical Paradise",
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
			Color(0.678, 0.847, 0.902)  # Sky blue
		]
	}
}

# Get palette keys for cycling
var palette_keys: Array = []
var current_palette_index: int = 0

func _ready() -> void:
	# Initialize palette keys
	palette_keys = color_palettes.keys()
	
	# Set initial palette based on instance name hash for different instances
	# This ensures each instance gets a different color palette that stays consistent
	# Hash the instance name to get a deterministic but unique value
	var name_hash = name.hash()
	current_palette_index = abs(name_hash) % 8
	
	create_grab_paper_stack()

func create_grab_paper_stack() -> void:
	"""Create a stack of ten grab papers with different colors"""
	
	# Clear any existing papers
	for child in get_children():
		if child.name.begins_with("GrabPaper"):
			child.queue_free()
	
	# Create ten papers
	for i in range(10):
		var paper_instance = GRAB_PAPER_SCENE.instantiate()
		paper_instance.name = "GrabPaper_%d" % i
		
		# Position the paper in the stack
		var y_position = stack_height + (i * paper_spacing)
		paper_instance.position = Vector3(0, y_position, 0)
		
		# Scale the paper
		paper_instance.scale = paper_scale
		
		# Set the color from current palette
		var color = get_color_from_current_palette(i)
		set_paper_color(paper_instance, color)
		
		# Add to scene
		add_child(paper_instance)
		
		print("Created GrabPaper_%d with color: %s" % [i, color])

func get_color_from_current_palette(paper_index: int) -> Color:
	"""Get a color from the current palette for a specific paper"""
	if palette_keys.is_empty():
		return Color.WHITE
	
	var current_palette_key = palette_keys[current_palette_index % palette_keys.size()]
	var current_palette = color_palettes[current_palette_key]
	var colors = current_palette.colors
	
	if colors.is_empty():
		return Color.WHITE
	
	# Cycle through colors in the palette
	return colors[paper_index % colors.size()]

func update_paper_colors() -> void:
	"""Update all paper colors based on current palette"""
	var current_palette_key = palette_keys[current_palette_index % palette_keys.size()]
	var current_palette = color_palettes[current_palette_key]
	print("Using palette: %s" % current_palette.title)
	
	for i in range(10):
		var paper_name = "GrabPaper_%d" % i
		var paper_instance = get_node_or_null(paper_name)
		if paper_instance:
			var color = get_color_from_current_palette(i)
			set_paper_color(paper_instance, color)
			print("Updated %s with color: %s" % [paper_name, color])

func set_paper_color(paper_instance: Node3D, color: Color) -> void:
	"""Set the color of a grab paper instance"""
	var mesh_instance = paper_instance.get_node("MeshInstance3D")
	if mesh_instance and mesh_instance.material_override:
		# Create a new material with the specified color
		var material = StandardMaterial3D.new()
		material.albedo_color = color
		material.metallic = 0.1
		material.roughness = 0.3
		material.emission_enabled = true
		material.emission = color * 0.2  # Subtle emission
		material.emission_energy_multiplier = 0.5
		
		mesh_instance.material_override = material
	else:
		print("Warning: Could not find MeshInstance3D or material for paper")

func regenerate_stack() -> void:
	"""Regenerate the entire stack (useful for testing)"""
	create_grab_paper_stack()

func add_paper_to_top() -> void:
	"""Add a new paper to the top of the stack using current palette"""
	var paper_instance = GRAB_PAPER_SCENE.instantiate()
	var current_count = get_child_count()
	paper_instance.name = "GrabPaper_%d" % current_count
	
	# Position at the top
	var y_position = stack_height + (current_count * paper_spacing)
	paper_instance.position = Vector3(0, y_position, 0)
	paper_instance.scale = paper_scale
	
	# Set color from current palette
	var color = get_color_from_current_palette(current_count)
	set_paper_color(paper_instance, color)
	
	add_child(paper_instance)
	print("Added paper to top with color: %s" % color)

func cycle_to_next_palette() -> void:
	"""Manually cycle to the next color palette"""
	current_palette_index = (current_palette_index + 1) % palette_keys.size()
	update_paper_colors()

func get_current_palette_name() -> String:
	"""Get the name of the current color palette"""
	if palette_keys.is_empty():
		return "No Palette"
	var current_palette_key = palette_keys[current_palette_index % palette_keys.size()]
	var current_palette = color_palettes[current_palette_key]
	return current_palette.title

func remove_top_paper() -> void:
	"""Remove the topmost paper from the stack"""
	var papers = []
	for child in get_children():
		if child.name.begins_with("GrabPaper"):
			papers.append(child)
	
	if papers.size() > 0:
		var top_paper = papers[-1]
		print("Removing paper: %s" % top_paper.name)
		top_paper.queue_free()
