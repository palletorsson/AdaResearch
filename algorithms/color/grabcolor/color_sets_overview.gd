extends Node3D

const GRAB_PAPER_SCENE = preload("res://commons/primitives/panels/DigitalPaper/grab_paper.tscn")
const DEFAULT_PALETTE_PATH := "res://algorithms/color/color_palettes.tres"

@export var palette_resource: Resource
@export var sets_to_show: int = 12
@export var colors_per_set: int = 12
@export var color_swatch_size: float = 0.08
@export var set_spacing_x: float = 1.2
@export var set_spacing_z: float = 0.6
@export var columns: int = 4

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

func _get_palette_title(palette_name: String) -> String:
	var entry = _get_palette_entry(palette_name)
	return entry.get("title", palette_name)

func create_overview() -> void:
	# Clear existing children
	for child in get_children():
		if child.name.begins_with("PaletteSet_") or child.name.begins_with("PaletteLabel_"):
			child.queue_free()
	
	var num_sets = min(sets_to_show, palette_keys.size())
	
	for set_index in range(num_sets):
		var palette_key = palette_keys[set_index]
		var colors = _get_palette_colors(palette_key)
		var title = _get_palette_title(palette_key)
		
		# Calculate set position in grid
		var row = set_index / columns
		var col = set_index % columns
		var set_position = Vector3(col * set_spacing_x, 0, row * set_spacing_z)
		
		# Create container for this palette set
		var set_container = Node3D.new()
		set_container.name = "PaletteSet_%d" % set_index
		set_container.position = set_position
		add_child(set_container)
		
		# Add title label
		var title_label = Label3D.new()
		title_label.name = "PaletteLabel_%d" % set_index
		title_label.text = title
		title_label.font_size = 24
		title_label.position = Vector3(0.4, 0.15, -0.05)
		title_label.modulate = Color.WHITE
		set_container.add_child(title_label)
		
		# Create color swatches in a row
		var num_colors = min(colors_per_set, colors.size())
		for color_index in range(num_colors):
			var color = colors[color_index]
			var swatch = _create_color_swatch(color)
			swatch.name = "Swatch_%d" % color_index
			swatch.position = Vector3(color_index * (color_swatch_size + 0.005), 0, 0)
			swatch.scale = Vector3(color_swatch_size, color_swatch_size, 0.01)
			set_container.add_child(swatch)

func _create_color_swatch(color: Color) -> MeshInstance3D:
	var mesh_instance = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(1, 1, 1)
	mesh_instance.mesh = box_mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = 0.1
	material.roughness = 0.3
	material.emission_enabled = true
	material.emission = color * 0.3
	material.emission_energy_multiplier = 0.5
	mesh_instance.material_override = material
	
	return mesh_instance
