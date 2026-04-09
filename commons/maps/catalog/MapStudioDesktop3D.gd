@tool
extends Control

## Map Studio Desktop — split-view map editor
## Left: map list | Top center: 2D grid | Bottom center: 3D preview | Right: inspector

const CELL_SIZE := 28
const HEIGHT_COLORS := {
	"0": Color(0.06, 0.06, 0.08),
	"1": Color(0.3, 0.3, 0.35),
	"2": Color(0.4, 0.4, 0.45),
	"3": Color(0.5, 0.5, 0.55),
	"4": Color(0.6, 0.6, 0.65),
	"5": Color(0.7, 0.7, 0.75),
	"6": Color(0.5, 0.12, 0.12),
}
const UTILITY_COLORS := {
	"sp": Color(0.2, 1.0, 0.3),
	"s": Color(0.2, 1.0, 0.3),
	"t": Color(0.2, 0.5, 1.0),
	"r": Color(1.0, 0.8, 0.2),
	"wp": Color(1.0, 0.8, 0.2),
	"tc": Color(0.8, 0.4, 1.0),
	"m": Color(0.5, 0.5, 0.5),
	"ds": Color(1.0, 0.3, 0.3),
	"an": Color(0.3, 0.8, 0.8),
	"sub": Color(0.3, 0.8, 0.8),
	"3t": Color(0.2, 0.5, 1.0),
}

# Map data
var map_data: Dictionary = {}
var map_path: String = ""
var grid_width: int = 0
var grid_depth: int = 0
var structure_layer: Array = []
var utilities_layer: Array = []
var interactables_layer: Array = []

# Editor state
var active_layer: int = 0
var paint_value: String = "1"
var is_painting: bool = false
var selected_cell: Vector2i = Vector2i(-1, -1)

# UI references
var map_list: ItemList
var grid_canvas: Control
var layer_tabs: TabBar
var palette_container: HBoxContainer
var info_label: Label
var inspector_name: Label
var inspector_detail: RichTextLabel
var artifact_input: LineEdit
var preview_3d: SubViewportContainer
var preview_viewport: SubViewport
var status_bar: Label

# Map paths cache
var _map_paths: Array[String] = []

func _ready() -> void:
	_build_layout()
	_scan_maps()

func _build_layout() -> void:
	# Root: HSplitContainer
	var root_split := HSplitContainer.new()
	root_split.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	root_split.split_offset = 180
	add_child(root_split)

	# === LEFT: Map list ===
	var left_panel := VBoxContainer.new()
	left_panel.custom_minimum_size = Vector2(170, 0)
	root_split.add_child(left_panel)

	var list_label := Label.new()
	list_label.text = "Maps"
	list_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	left_panel.add_child(list_label)

	var search := LineEdit.new()
	search.placeholder_text = "Filter..."
	search.text_changed.connect(_filter_maps)
	left_panel.add_child(search)

	map_list = ItemList.new()
	map_list.size_flags_vertical = SIZE_EXPAND_FILL
	map_list.item_selected.connect(_on_map_item_selected)
	map_list.auto_height = false
	left_panel.add_child(map_list)

	# === CENTER + RIGHT split ===
	var center_right := HSplitContainer.new()
	center_right.split_offset = -280
	root_split.add_child(center_right)

	# === CENTER: 2D grid (top) + 3D preview (bottom) ===
	var center_split := VSplitContainer.new()
	center_split.split_offset = 300
	center_right.add_child(center_split)

	# Top: 2D grid editor
	var grid_panel := VBoxContainer.new()
	center_split.add_child(grid_panel)

	# Layer tabs + palette
	var grid_toolbar := HBoxContainer.new()
	grid_panel.add_child(grid_toolbar)

	layer_tabs = TabBar.new()
	layer_tabs.add_tab("Structure")
	layer_tabs.add_tab("Utilities")
	layer_tabs.add_tab("Interactables")
	layer_tabs.tab_changed.connect(_on_layer_changed)
	grid_toolbar.add_child(layer_tabs)

	var save_btn := Button.new()
	save_btn.text = "Save"
	save_btn.pressed.connect(_save_map)
	grid_toolbar.add_child(save_btn)

	palette_container = HBoxContainer.new()
	grid_panel.add_child(palette_container)

	# Scrollable grid canvas
	var grid_scroll := ScrollContainer.new()
	grid_scroll.size_flags_vertical = SIZE_EXPAND_FILL
	grid_scroll.size_flags_horizontal = SIZE_EXPAND_FILL
	grid_panel.add_child(grid_scroll)

	grid_canvas = Control.new()
	grid_canvas.gui_input.connect(_on_grid_input)
	grid_canvas.draw.connect(_on_grid_draw)
	grid_scroll.add_child(grid_canvas)

	# Bottom: 3D preview
	var preview_panel := VBoxContainer.new()
	center_split.add_child(preview_panel)

	var preview_label := Label.new()
	preview_label.text = "3D Preview"
	preview_panel.add_child(preview_label)

	preview_3d = SubViewportContainer.new()
	preview_3d.size_flags_vertical = SIZE_EXPAND_FILL
	preview_3d.size_flags_horizontal = SIZE_EXPAND_FILL
	preview_3d.stretch = true
	preview_panel.add_child(preview_3d)

	preview_viewport = SubViewport.new()
	preview_viewport.size = Vector2i(800, 400)
	preview_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	preview_3d.add_child(preview_viewport)

	# Add camera + light to preview
	var cam := Camera3D.new()
	cam.name = "PreviewCam"
	cam.position = Vector3(5, 8, 12)
	cam.look_at(Vector3(5, 0, 5))
	cam.fov = 50
	cam.current = true
	preview_viewport.add_child(cam)

	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, -30, 0)
	light.light_energy = 1.2
	preview_viewport.add_child(light)

	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.1, 0.1, 0.14)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.4, 0.4, 0.45)
	environment.ambient_light_energy = 0.5
	env.environment = environment
	preview_viewport.add_child(env)

	# === RIGHT: Inspector ===
	var right_panel := VBoxContainer.new()
	right_panel.custom_minimum_size = Vector2(260, 0)
	center_right.add_child(right_panel)

	var insp_title := Label.new()
	insp_title.text = "Inspector"
	insp_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	right_panel.add_child(insp_title)

	inspector_name = Label.new()
	inspector_name.text = "No cell selected"
	inspector_name.add_theme_font_size_override("font_size", 16)
	right_panel.add_child(inspector_name)

	var sep := HSeparator.new()
	right_panel.add_child(sep)

	# Artifact input for interactables layer
	var art_label := Label.new()
	art_label.text = "Artifact:"
	right_panel.add_child(art_label)

	artifact_input = LineEdit.new()
	artifact_input.placeholder_text = "lookup_name:rot:y_off"
	artifact_input.text_submitted.connect(_on_artifact_input_submitted)
	right_panel.add_child(artifact_input)

	inspector_detail = RichTextLabel.new()
	inspector_detail.size_flags_vertical = SIZE_EXPAND_FILL
	inspector_detail.bbcode_enabled = true
	right_panel.add_child(inspector_detail)

	# Status bar at bottom of right panel
	status_bar = Label.new()
	status_bar.text = "Map Studio"
	status_bar.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	right_panel.add_child(status_bar)

	_build_palette()

# === MAP LIST ===

func _scan_maps() -> void:
	map_list.clear()
	_map_paths.clear()
	var maps_dir := "res://commons/maps/"
	var dir := DirAccess.open(maps_dir)
	if not dir:
		return
	dir.list_dir_begin()
	while true:
		var folder := dir.get_next()
		if folder == "":
			break
		if dir.current_is_dir() and not folder.begins_with(".") and not folder.begins_with("catalog"):
			var json_path := maps_dir + folder + "/map_data.json"
			if FileAccess.file_exists(json_path):
				map_list.add_item(folder)
				_map_paths.append(json_path)
	dir.list_dir_end()
	status_bar.text = "%d maps found" % _map_paths.size()

func _filter_maps(text: String) -> void:
	var filter := text.to_lower()
	for i in range(map_list.item_count):
		var name_str: String = map_list.get_item_text(i)
		map_list.set_item_disabled(i, filter != "" and not name_str.to_lower().contains(filter))

func _on_map_item_selected(idx: int) -> void:
	if idx < 0 or idx >= _map_paths.size():
		return
	map_path = _map_paths[idx]
	_load_map(map_path)

func _load_map(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		status_bar.text = "Failed to open"
		return

	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		status_bar.text = "JSON error"
		file.close()
		return
	file.close()

	map_data = json.data
	var layers: Dictionary = map_data.get("layers", {})
	structure_layer = layers.get("structure", [])
	utilities_layer = layers.get("utilities", [])
	interactables_layer = layers.get("interactables", [])

	grid_depth = structure_layer.size()
	grid_width = structure_layer[0].size() if grid_depth > 0 else 0

	_ensure_layer_size(utilities_layer)
	_ensure_layer_size(interactables_layer)

	grid_canvas.custom_minimum_size = Vector2(grid_width * CELL_SIZE + 1, grid_depth * CELL_SIZE + 1)
	grid_canvas.queue_redraw()

	var map_name: String = str(map_data.get("map_info", {}).get("name", path.get_file()))
	status_bar.text = "%s  %dx%d" % [map_name, grid_width, grid_depth]
	selected_cell = Vector2i(-1, -1)
	_update_inspector()

func _ensure_layer_size(layer: Array) -> void:
	while layer.size() < grid_depth:
		var row: Array = []
		row.resize(grid_width)
		row.fill(" ")
		layer.append(row)
	for row in layer:
		while row.size() < grid_width:
			row.append(" ")

# === LAYER & PALETTE ===

func _on_layer_changed(idx: int) -> void:
	active_layer = idx
	_build_palette()
	grid_canvas.queue_redraw()

func _build_palette() -> void:
	for child in palette_container.get_children():
		child.queue_free()

	match active_layer:
		0:
			for h in range(7):
				var btn := Button.new()
				btn.text = str(h)
				btn.custom_minimum_size = Vector2(32, 26)
				var c: Color = HEIGHT_COLORS.get(str(h), Color.WHITE)
				var style := StyleBoxFlat.new()
				style.bg_color = c
				btn.add_theme_stylebox_override("normal", style)
				btn.pressed.connect(_set_paint.bind(str(h)))
				palette_container.add_child(btn)
			paint_value = "1"
		1:
			for code in ["sp", "t", "r", "wp", "tc", "m", "ds", "sub", " "]:
				var btn := Button.new()
				btn.text = code if code != " " else "x"
				btn.custom_minimum_size = Vector2(36, 26)
				btn.pressed.connect(_set_paint.bind(code))
				palette_container.add_child(btn)
			paint_value = "sp"
		2:
			var lbl := Label.new()
			lbl.text = "Click cell, type in inspector →"
			palette_container.add_child(lbl)
			paint_value = " "

func _set_paint(val: String) -> void:
	paint_value = val

# === 2D GRID DRAWING ===

func _on_grid_draw() -> void:
	if structure_layer.is_empty():
		return

	var font: Font = ThemeDB.fallback_font
	var fs := 8

	for z in range(grid_depth):
		for x in range(grid_width):
			var rect := Rect2(x * CELL_SIZE, z * CELL_SIZE, CELL_SIZE, CELL_SIZE)

			# Structure background
			var h_str: String = str(structure_layer[z][x]) if z < structure_layer.size() and x < structure_layer[z].size() else "0"
			var bg: Color = HEIGHT_COLORS.get(h_str, Color(0.15, 0.15, 0.15))
			if active_layer != 0:
				bg = bg.darkened(0.3)
			grid_canvas.draw_rect(rect, bg)

			# Utilities
			var util_str: String = str(utilities_layer[z][x]).strip_edges() if z < utilities_layer.size() and x < utilities_layer[z].size() else ""
			if util_str != "" and util_str != " ":
				var code := util_str.split(":")[0]
				var uc: Color = UTILITY_COLORS.get(code, Color(0.7, 0.7, 0.7))
				if active_layer != 1:
					uc.a = 0.35
				grid_canvas.draw_rect(rect.grow(-2), uc, false, 2.0)
				grid_canvas.draw_string(font, rect.position + Vector2(2, fs + 1), code, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, uc)

			# Interactables
			var inter_str: String = str(interactables_layer[z][x]).strip_edges() if z < interactables_layer.size() and x < interactables_layer[z].size() else ""
			if inter_str != "" and inter_str != " ":
				var name_part: String = inter_str.split(":")[0]
				var ic := Color(1.0, 0.7, 0.2)
				if active_layer != 2:
					ic.a = 0.25
				grid_canvas.draw_circle(rect.get_center(), CELL_SIZE * 0.3, ic)
				grid_canvas.draw_string(font, rect.position + Vector2(2, CELL_SIZE - 2), name_part.substr(0, 5), HORIZONTAL_ALIGNMENT_LEFT, -1, 7, ic)

			# Grid lines
			grid_canvas.draw_rect(rect, Color(0.18, 0.18, 0.22), false, 1.0)

			# Selected cell highlight
			if Vector2i(x, z) == selected_cell:
				grid_canvas.draw_rect(rect.grow(-1), Color(1.0, 1.0, 0.3, 0.6), false, 2.0)

# === GRID INPUT ===

func _on_grid_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var pos: Vector2 = event.position
		if event.button_index == MOUSE_BUTTON_LEFT:
			is_painting = event.pressed
			if event.pressed:
				_select_cell(pos)
				if active_layer != 2:
					_paint_at(pos)
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_select_cell(pos)
	elif event is InputEventMouseMotion and is_painting and active_layer != 2:
		_paint_at(event.position)

func _select_cell(pos: Vector2) -> void:
	var x := int(pos.x / CELL_SIZE)
	var z := int(pos.y / CELL_SIZE)
	if x >= 0 and x < grid_width and z >= 0 and z < grid_depth:
		selected_cell = Vector2i(x, z)
		_update_inspector()
		grid_canvas.queue_redraw()

func _paint_at(pos: Vector2) -> void:
	var x := int(pos.x / CELL_SIZE)
	var z := int(pos.y / CELL_SIZE)
	if x < 0 or x >= grid_width or z < 0 or z >= grid_depth:
		return
	match active_layer:
		0:
			structure_layer[z][x] = paint_value
		1:
			utilities_layer[z][x] = paint_value
	grid_canvas.queue_redraw()

func _on_artifact_input_submitted(text: String) -> void:
	if selected_cell.x >= 0 and selected_cell.y >= 0:
		if selected_cell.y < interactables_layer.size() and selected_cell.x < interactables_layer[selected_cell.y].size():
			interactables_layer[selected_cell.y][selected_cell.x] = text if text != "" else " "
			grid_canvas.queue_redraw()
			_update_inspector()

# === INSPECTOR ===

func _update_inspector() -> void:
	if selected_cell.x < 0:
		inspector_name.text = "No cell selected"
		inspector_detail.text = ""
		artifact_input.text = ""
		return

	var x := selected_cell.x
	var z := selected_cell.y
	inspector_name.text = "Cell [%d, %d]" % [x, z]

	var h: String = str(structure_layer[z][x]) if z < structure_layer.size() and x < structure_layer[z].size() else "?"
	var u: String = str(utilities_layer[z][x]).strip_edges() if z < utilities_layer.size() and x < utilities_layer[z].size() else ""
	var a: String = str(interactables_layer[z][x]).strip_edges() if z < interactables_layer.size() and x < interactables_layer[z].size() else ""

	var detail := "[b]Height:[/b] %s\n" % h
	if u != "" and u != " ":
		detail += "[b]Utility:[/b] %s\n" % u
	if a != "" and a != " ":
		detail += "[b]Artifact:[/b] %s\n" % a
		artifact_input.text = a
	else:
		artifact_input.text = ""

	detail += "\n[color=gray]Click to select. Paint structure/utilities.\nType artifact name in the field above.[/color]"
	inspector_detail.text = detail

# === SAVE ===

func _save_map() -> void:
	if map_path == "":
		status_bar.text = "No map loaded"
		return
	if "layers" not in map_data:
		map_data["layers"] = {}
	map_data["layers"]["structure"] = structure_layer
	map_data["layers"]["utilities"] = utilities_layer
	map_data["layers"]["interactables"] = interactables_layer

	var json_str := JSON.stringify(map_data, "  ")
	var file := FileAccess.open(map_path, FileAccess.WRITE)
	if file:
		file.store_string(json_str)
		file.close()
		status_bar.text = "Saved: " + map_path.get_file()
	else:
		status_bar.text = "Save failed!"

# === KEYBOARD SHORTCUTS ===

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.ctrl_pressed and event.keycode == KEY_S:
			_save_map()
			get_viewport().set_input_as_handled()
