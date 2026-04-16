extends Control

@export var color_palette_resource: Resource = preload("res://algorithms/color/color_palettes.tres")

var SWATCH_SIZE := 0.03
var SWATCH_GAP := 0.005
var PALETTE_GAP_X := 0.2
var PALETTE_GAP_Y := 0.22
var COLUMNS := 2

func _ready() -> void:
	_build_wall()

func _build_wall() -> void:
	# Title
	var title := Label3D.new()
	title.text = "20 Cultural & Emotional Color Palette Sheets"
	title.font_size = 48
	title.position = Vector3(0.25, 0.1, 0)
	add_child(title)

	# Subtitle
	var subtitle := Label3D.new()
	subtitle.text = "4x4 Color Grids from Art, History, Culture & Human Experience"
	subtitle.font_size = 28
	subtitle.modulate = Color(0.7, 0.7, 0.7)
	subtitle.position = Vector3(0.25, 0.06, 0)
	add_child(subtitle)

	# Create palette sheets in 2-column grid
	var palette_keys = color_palette_resource.palettes.keys()
	for idx in range(palette_keys.size()):
		var palette_key = palette_keys[idx]
		var palette_data = color_palette_resource.palettes[palette_key]
		var col := idx % COLUMNS
		var row := idx / COLUMNS
		var origin := Vector3(col * PALETTE_GAP_X, -row * PALETTE_GAP_Y, 0)
		_create_palette_sheet(palette_data, origin)

func _create_palette_sheet(palette_data: Dictionary, origin: Vector3) -> void:
	var container := Node3D.new()
	container.position = origin
	add_child(container)

	# Palette title
	var title_lbl := Label3D.new()
	title_lbl.text = palette_data.title
	title_lbl.font_size = 24
	title_lbl.position = Vector3(0.06, 0.02, 0)
	container.add_child(title_lbl)

	# Description
	var desc_lbl := Label3D.new()
	desc_lbl.text = palette_data.description
	desc_lbl.font_size = 14
	desc_lbl.modulate = Color(0.8, 0.8, 0.8)
	desc_lbl.position = Vector3(0.06, 0.0, 0)
	desc_lbl.width = 0.15
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	container.add_child(desc_lbl)

	# 4x4 color grid
	var colors: Array = palette_data.colors
	var grid_start_y := -0.02
	for i in range(16):
		var col := i % 4
		var row_i := i / 4
		var swatch_color: Color
		if i < colors.size():
			swatch_color = colors[i]
		else:
			swatch_color = Color(0.5, 0.5, 0.5, 0.3)

		var mesh_inst := MeshInstance3D.new()
		var quad := QuadMesh.new()
		quad.size = Vector2(SWATCH_SIZE, SWATCH_SIZE)
		mesh_inst.mesh = quad

		var mat := StandardMaterial3D.new()
		mat.albedo_color = swatch_color
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mesh_inst.material_override = mat

		mesh_inst.position = Vector3(
			col * (SWATCH_SIZE + SWATCH_GAP),
			grid_start_y - row_i * (SWATCH_SIZE + SWATCH_GAP),
			0.001
		)
		container.add_child(mesh_inst)

	# Color count info
	var info_lbl := Label3D.new()
	info_lbl.text = str(colors.size()) + " colors"
	info_lbl.font_size = 12
	info_lbl.modulate = Color(0.6, 0.6, 0.6)
	info_lbl.position = Vector3(0.06, grid_start_y - 4 * (SWATCH_SIZE + SWATCH_GAP) - 0.01, 0)
	container.add_child(info_lbl)

func apply_grid_config(config: Dictionary) -> void:
	if config.is_empty():
		return
	if config.has("swatch_size"):
		SWATCH_SIZE = float(config["swatch_size"])
	if config.has("swatch_gap"):
		SWATCH_GAP = float(config["swatch_gap"])
	if config.has("columns"):
		COLUMNS = int(config["columns"])
	if config.has("palette_gap_x"):
		PALETTE_GAP_X = float(config["palette_gap_x"])
	if config.has("palette_gap_y"):
		PALETTE_GAP_Y = float(config["palette_gap_y"])
	for child in get_children():
		child.queue_free()
	await get_tree().process_frame
	_build_wall()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()
