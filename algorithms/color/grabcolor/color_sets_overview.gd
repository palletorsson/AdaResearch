extends Node3D

const GRAB_PAPER_SCENE = preload("res://commons/primitives/panels/DigitalPaper/grab_paper.tscn")
const DEFAULT_PALETTE_PATH := "res://algorithms/color/color_palettes.tres"

# grab_paper size: ~0.2 x 0.01 x 0.2
const PAPER_SIZE := Vector2(0.2, 0.2)  # X and Z dimensions
const PAPER_GAP := 0.02  # Gap between papers

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
	
	return swatch_root
