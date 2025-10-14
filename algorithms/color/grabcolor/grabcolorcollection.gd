extends Node3D

const GRAB_PAPER_SCENE = preload("res://commons/primitives/panels/DigitalPaper/grab_paper.tscn")
const DEFAULT_PALETTE_PATH := "res://algorithms/color/color_palettes.tres"

@export var paper_spacing: float = 0.02
@export var stack_height: float = 0.0
@export var paper_scale: Vector3 = Vector3(1.0, 1.0, 1.0)
@export var color_palette_resource: Resource

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

	for i in range(10):
		var paper_instance = GRAB_PAPER_SCENE.instantiate()
		paper_instance.name = "GrabPaper_%d" % i

		var y_position = stack_height + (i * paper_spacing)
		paper_instance.position = Vector3(0, y_position, 0)
		paper_instance.scale = paper_scale

		var color = get_color_from_current_palette(i)
		set_paper_color(paper_instance, color)

		add_child(paper_instance)
		print("Created GrabPaper_%d with color: %s" % [i, color])

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
	var mesh_instance = paper_instance.get_node("MeshInstance3D")
	if mesh_instance and mesh_instance.material_override != null:
		var material = StandardMaterial3D.new()
		material.albedo_color = color
		material.metallic = 0.1
		material.roughness = 0.3
		material.emission_enabled = true
		material.emission = color * 0.2
		material.emission_energy_multiplier = 0.5
		mesh_instance.material_override = material
	else:
		print("Warning: Could not find MeshInstance3D or material for paper")

func regenerate_stack() -> void:
	create_grab_paper_stack()

func add_paper_to_top() -> void:
	if palette_keys.is_empty():
		return

	var paper_instance = GRAB_PAPER_SCENE.instantiate()
	var current_count = get_child_count()
	paper_instance.name = "GrabPaper_%d" % current_count

	var y_position = stack_height + (current_count * paper_spacing)
	paper_instance.position = Vector3(0, y_position, 0)
	paper_instance.scale = paper_scale

	var color = get_color_from_current_palette(current_count)
	set_paper_color(paper_instance, color)

	add_child(paper_instance)
	print("Added paper to top with color: %s" % color)

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
