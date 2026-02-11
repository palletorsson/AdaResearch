extends Node3D

const COLOR_STICKER_SCENE = preload("res://algorithms/color/grabcolor/color_sticker.tscn")
const DEFAULT_PALETTE_PATH := "res://algorithms/color/color_palettes.tres"

# Sticker size: ~0.2 x 0.01 x 0.2
const STICKER_SIZE := Vector2(0.2, 0.2)  # X and Z dimensions
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
	# Use the color_sticker scene
	if COLOR_STICKER_SCENE:
		var sticker = COLOR_STICKER_SCENE.instantiate()
		if sticker and sticker.has_method("set_sticker_color"):
			sticker.sticker_color = color
		elif sticker:
			# Fallback: set color directly if method not available yet
			sticker.set("sticker_color", color)
		return sticker
	
	# Fallback: create simple colored box
	var sticker_root = StaticBody3D.new()
	
	var mesh_instance = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(STICKER_SIZE.x, 0.01, STICKER_SIZE.y)
	mesh_instance.mesh = box_mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color * 0.4
	material.emission_energy_multiplier = 0.6
	mesh_instance.material_override = material
	sticker_root.add_child(mesh_instance)
	
	# Add collision for pointer interaction
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(STICKER_SIZE.x, 0.01, STICKER_SIZE.y)
	collision.shape = shape
	sticker_root.add_child(collision)
	
	sticker_root.collision_layer = 1 << 20
	sticker_root.collision_mask = 0
	
	return sticker_root
