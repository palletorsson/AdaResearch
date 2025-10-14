extends Node3D

const PILLAR_SCENE = preload("res://commons/primitives/pillar/pillar.tscn")
const DEFAULT_PALETTE_PATH := "res://algorithms/color/color_palettes.tres"

@export var color_palette_resource: Resource
@export var columns: int = 3
@export var rows: int = 8
@export var spacing: Vector3 = Vector3(2.0, 0.0, 2.0)
@export var origin_offset: Vector3 = Vector3.ZERO

var palette_keys: Array = []
var current_palette_index: int = 0

func _ready() -> void:
	_ensure_palette_resource()
	palette_keys = _collect_palette_keys()
	if palette_keys.is_empty():
		push_warning("PillarColorCollection: No color palettes available")
		return
	_spawn_pillars()

func _ensure_palette_resource() -> void:
	if color_palette_resource != null:
		return
	if ResourceLoader.exists(DEFAULT_PALETTE_PATH):
		color_palette_resource = ResourceLoader.load(DEFAULT_PALETTE_PATH)
	else:
		push_warning("PillarColorCollection: Palette resource not found at %s" % DEFAULT_PALETTE_PATH)

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
	var source = entry.get("colors", [])
	var result: Array = []
	for value in source:
		if value is Color:
			result.append(value)
	return result

func _get_palette_title(palette_name: String) -> String:
	var entry = _get_palette_entry(palette_name)
	return entry.get("title", palette_name)

func _spawn_pillars() -> void:
	_clear_existing_pillars()
	if palette_keys.is_empty():
		return

	var current_key = palette_keys[current_palette_index % palette_keys.size()]
	var colors = _get_palette_colors(current_key)
	if colors.is_empty():
		push_warning("PillarColorCollection: Palette '%s' has no colors" % current_key)
		return

	var color_index := 0
	for row in range(rows):
		for column in range(columns):
			var pillar_instance = PILLAR_SCENE.instantiate()
			pillar_instance.name = "Pillar_%d_%d" % [row, column]

			var position = origin_offset + Vector3(column * spacing.x, 0.0, row * spacing.z)
			pillar_instance.position = position

			var color = colors[color_index % colors.size()]
			_apply_color_to_pillar(pillar_instance, color)
			add_child(pillar_instance)
			color_index += 1

	print("PillarColorCollection: Spawned %d pillars using palette '%s'" % [rows * columns, _get_palette_title(current_key)])

func _clear_existing_pillars() -> void:
	for child in get_children():
		if child.name.begins_with("Pillar_"):
			child.queue_free()

func _apply_color_to_pillar(pillar_instance: Node3D, color: Color) -> void:
	# Keep the footer/base black and color only the column
	var footer: MeshInstance3D = _find_named_mesh_instance(pillar_instance, "Footer")
	var column: MeshInstance3D = _find_named_mesh_instance(pillar_instance, "Column")

	if footer:
		var foot_mat := footer.get_active_material(0)
		if not (foot_mat is StandardMaterial3D):
			foot_mat = StandardMaterial3D.new()
		var base_mat := foot_mat as StandardMaterial3D
		base_mat.albedo_color = Color(0.05, 0.05, 0.05)
		base_mat.metallic = 0.3
		base_mat.roughness = 0.6
		footer.material_override = base_mat

	if column:
		var col_mat := StandardMaterial3D.new()
		col_mat.albedo_color = color
		col_mat.metallic = 0.05
		col_mat.roughness = 0.35
		col_mat.emission_enabled = true
		col_mat.emission = color * 0.1
		column.material_override = col_mat
	elif not footer:
		# fallback: color first mesh found
		var any_mesh := _find_mesh_instance(pillar_instance)
		if any_mesh:
			var material = StandardMaterial3D.new()
			material.albedo_color = color
			material.metallic = 0.05
			material.roughness = 0.35
			material.emission_enabled = true
			material.emission = color * 0.1
			any_mesh.material_override = material

func _find_mesh_instance(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node
	for child in node.get_children():
		var found = _find_mesh_instance(child)
		if found:
			return found
	return null

func _find_named_mesh_instance(node: Node, target_name: String) -> MeshInstance3D:
	if node is MeshInstance3D and node.name == target_name:
		return node
	for child in node.get_children():
		var found = _find_named_mesh_instance(child, target_name)
		if found:
			return found
	return null

func regenerate_pillars() -> void:
	_spawn_pillars()

func cycle_to_next_palette() -> void:
	if palette_keys.is_empty():
		return
	current_palette_index = (current_palette_index + 1) % palette_keys.size()
	_spawn_pillars()

func get_current_palette_name() -> String:
	if palette_keys.is_empty():
		return "No Palette"
	var current_key = palette_keys[current_palette_index % palette_keys.size()]
	return _get_palette_title(current_key)
