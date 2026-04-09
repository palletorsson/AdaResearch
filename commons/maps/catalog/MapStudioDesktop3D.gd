extends Control

## Map Studio Desktop — Control root with 3D SubViewport + 2D panels
## Left: map list | Center-left: 3D preview (SubViewport) | Top-right: 2D grid | Bottom-right: inspector

const CELL_SIZE := 24
const HEIGHT_COLORS := {
	"0": Color(0.06, 0.06, 0.08), "1": Color(0.3, 0.3, 0.35),
	"2": Color(0.4, 0.4, 0.45), "3": Color(0.5, 0.5, 0.55),
	"4": Color(0.6, 0.6, 0.65), "5": Color(0.7, 0.7, 0.75),
	"6": Color(0.5, 0.12, 0.12),
}
const UTILITY_COLORS := {
	"sp": Color(0.2, 1.0, 0.3), "s": Color(0.2, 1.0, 0.3),
	"t": Color(0.2, 0.5, 1.0), "3t": Color(0.2, 0.5, 1.0),
	"r": Color(1.0, 0.8, 0.2), "wp": Color(1.0, 0.8, 0.2),
	"tc": Color(0.8, 0.4, 1.0), "m": Color(0.5, 0.5, 0.5),
	"ds": Color(1.0, 0.3, 0.3), "sub": Color(0.3, 0.8, 0.8),
}

var map_data: Dictionary = {}
var map_path: String = ""
var grid_width: int = 0
var grid_depth: int = 0
var structure_layer: Array = []
var utilities_layer: Array = []
var interactables_layer: Array = []

var active_layer: int = 0
var paint_value: String = "1"
var is_painting: bool = false
var selected_cell: Vector2i = Vector2i(-1, -1)

# 3D
var _viewport: SubViewport
var _camera: Camera3D
var _map_container: Node3D
var _orbit_yaw := 0.4
var _orbit_pitch := 0.5
var _orbit_dist := 15.0
var _orbit_focus := Vector3(5, 0, 5)
var _is_orbiting := false
var _viewport_container: SubViewportContainer

# UI
var _map_list: ItemList
var _grid_canvas: Control
var _layer_tabs: TabBar
var _palette: HBoxContainer
var _inspector_name: Label
var _inspector_detail: RichTextLabel
var _artifact_input: LineEdit
var _status: Label
var _map_paths: Array[String] = []

func _ready() -> void:
	_build_layout()
	_scan_maps()

func _build_layout() -> void:
	# Main horizontal split: [map list] [3D viewport] [grid + inspector]
	var hsplit := HSplitContainer.new()
	hsplit.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	hsplit.split_offset = 170
	add_child(hsplit)

	# === LEFT: Map list ===
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(160, 0)
	hsplit.add_child(left)

	var title := Label.new()
	title.text = "Map Studio"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	left.add_child(title)

	var search := LineEdit.new()
	search.placeholder_text = "Filter..."
	search.text_changed.connect(_filter_maps)
	left.add_child(search)

	_map_list = ItemList.new()
	_map_list.size_flags_vertical = SIZE_EXPAND_FILL
	_map_list.item_selected.connect(_on_map_selected)
	left.add_child(_map_list)

	_status = Label.new()
	_status.text = "Ready"
	_status.add_theme_font_size_override("font_size", 10)
	_status.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	left.add_child(_status)

	# === CENTER + RIGHT ===
	var center_right := HSplitContainer.new()
	center_right.split_offset = -350
	hsplit.add_child(center_right)

	# === CENTER: 3D SubViewport ===
	_viewport_container = SubViewportContainer.new()
	_viewport_container.size_flags_horizontal = SIZE_EXPAND_FILL
	_viewport_container.size_flags_vertical = SIZE_EXPAND_FILL
	_viewport_container.stretch = true
	_viewport_container.gui_input.connect(_on_viewport_input)
	center_right.add_child(_viewport_container)

	_viewport = SubViewport.new()
	_viewport.size = Vector2i(800, 600)
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport.handle_input_locally = true
	_viewport_container.add_child(_viewport)

	# 3D scene inside viewport
	_camera = Camera3D.new()
	_camera.fov = 50
	_camera.current = true
	_viewport.add_child(_camera)
	_update_camera()

	var key_light := DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-45, -30, 0)
	key_light.light_energy = 1.2
	key_light.shadow_enabled = true
	_viewport.add_child(key_light)

	var fill_light := DirectionalLight3D.new()
	fill_light.rotation_degrees = Vector3(-20, 150, 0)
	fill_light.light_energy = 0.4
	_viewport.add_child(fill_light)

	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.1, 0.1, 0.14)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.4, 0.4, 0.45)
	environment.ambient_light_energy = 0.5
	env.environment = environment
	_viewport.add_child(env)

	_map_container = Node3D.new()
	_map_container.name = "MapPreview"
	_viewport.add_child(_map_container)

	# === RIGHT: grid + inspector stacked ===
	var right := VSplitContainer.new()
	right.custom_minimum_size = Vector2(320, 0)
	right.split_offset = 300
	center_right.add_child(right)

	# Top-right: 2D grid editor
	var grid_box := VBoxContainer.new()
	right.add_child(grid_box)

	var grid_toolbar := HBoxContainer.new()
	grid_box.add_child(grid_toolbar)

	_layer_tabs = TabBar.new()
	_layer_tabs.add_tab("Structure")
	_layer_tabs.add_tab("Utilities")
	_layer_tabs.add_tab("Artifacts")
	_layer_tabs.tab_changed.connect(_on_layer_changed)
	grid_toolbar.add_child(_layer_tabs)

	var save_btn := Button.new()
	save_btn.text = "Save"
	save_btn.pressed.connect(_save_map)
	grid_toolbar.add_child(save_btn)

	_palette = HBoxContainer.new()
	grid_box.add_child(_palette)

	var grid_scroll := ScrollContainer.new()
	grid_scroll.size_flags_vertical = SIZE_EXPAND_FILL
	grid_box.add_child(grid_scroll)

	_grid_canvas = Control.new()
	_grid_canvas.gui_input.connect(_on_grid_input)
	_grid_canvas.draw.connect(_on_grid_draw)
	grid_scroll.add_child(_grid_canvas)

	# Bottom-right: inspector
	var insp_box := VBoxContainer.new()
	right.add_child(insp_box)

	_inspector_name = Label.new()
	_inspector_name.text = "No cell selected"
	_inspector_name.add_theme_font_size_override("font_size", 14)
	insp_box.add_child(_inspector_name)

	var art_row := HBoxContainer.new()
	insp_box.add_child(art_row)
	var art_lbl := Label.new()
	art_lbl.text = "Artifact:"
	art_row.add_child(art_lbl)
	_artifact_input = LineEdit.new()
	_artifact_input.size_flags_horizontal = SIZE_EXPAND_FILL
	_artifact_input.placeholder_text = "lookup_name:rot:y"
	_artifact_input.text_submitted.connect(_on_artifact_submitted)
	art_row.add_child(_artifact_input)

	_inspector_detail = RichTextLabel.new()
	_inspector_detail.size_flags_vertical = SIZE_EXPAND_FILL
	_inspector_detail.bbcode_enabled = true
	insp_box.add_child(_inspector_detail)

	_build_palette()

# === 3D CAMERA ===

func _update_camera() -> void:
	if not _camera: return
	var offset := Vector3(
		sin(_orbit_yaw) * cos(_orbit_pitch),
		sin(_orbit_pitch),
		cos(_orbit_yaw) * cos(_orbit_pitch)
	) * _orbit_dist
	_camera.position = _orbit_focus + offset
	_camera.look_at(_orbit_focus, Vector3.UP)

func _on_viewport_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT or event.button_index == MOUSE_BUTTON_MIDDLE:
			_is_orbiting = event.pressed
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_orbit_dist = maxf(3.0, _orbit_dist - 1.5)
			_update_camera()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_orbit_dist += 1.5
			_update_camera()
	elif event is InputEventMouseMotion and _is_orbiting:
		_orbit_yaw -= event.relative.x * 0.005
		_orbit_pitch = clampf(_orbit_pitch + event.relative.y * 0.005, 0.1, 1.4)
		_update_camera()

# === MAP LIST ===

func _scan_maps() -> void:
	_map_list.clear()
	_map_paths.clear()
	var dir := DirAccess.open("res://commons/maps/")
	if not dir: return
	dir.list_dir_begin()
	while true:
		var folder := dir.get_next()
		if folder == "": break
		if dir.current_is_dir() and not folder.begins_with(".") and not folder.begins_with("catalog"):
			var p := "res://commons/maps/" + folder + "/map_data.json"
			if FileAccess.file_exists(p):
				_map_list.add_item(folder)
				_map_paths.append(p)
	dir.list_dir_end()
	_status.text = "%d maps" % _map_paths.size()

func _filter_maps(text: String) -> void:
	# Rebuild list filtered
	_map_list.clear()
	var f := text.to_lower()
	for i in range(_map_paths.size()):
		var name_str := _map_paths[i].get_base_dir().get_file()
		if f == "" or name_str.to_lower().contains(f):
			_map_list.add_item(name_str)
			_map_list.set_item_metadata(_map_list.item_count - 1, _map_paths[i])

func _on_map_selected(idx: int) -> void:
	var path: String
	if _map_list.get_item_metadata(idx):
		path = str(_map_list.get_item_metadata(idx))
	elif idx < _map_paths.size():
		path = _map_paths[idx]
	else:
		return
	map_path = path
	_load_map(path)

func _load_map(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if not file: return
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
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
	_ensure_layer(utilities_layer)
	_ensure_layer(interactables_layer)

	_grid_canvas.custom_minimum_size = Vector2(grid_width * CELL_SIZE + 1, grid_depth * CELL_SIZE + 1)
	_grid_canvas.queue_redraw()
	_rebuild_3d_preview()

	_orbit_focus = Vector3(grid_width * 0.5, 0, grid_depth * 0.5)
	_orbit_dist = maxf(grid_width, grid_depth) * 1.2
	_update_camera()

	var map_name: String = str(map_data.get("map_info", {}).get("name", path.get_file()))
	_status.text = "%s  %dx%d" % [map_name, grid_width, grid_depth]
	selected_cell = Vector2i(-1, -1)

func _ensure_layer(layer: Array) -> void:
	while layer.size() < grid_depth:
		var row := []
		row.resize(grid_width)
		row.fill(" ")
		layer.append(row)
	for row in layer:
		while row.size() < grid_width:
			row.append(" ")

# === 3D PREVIEW ===

func _rebuild_3d_preview() -> void:
	for child in _map_container.get_children():
		child.queue_free()
	if structure_layer.is_empty(): return

	var cube_mesh := BoxMesh.new()
	cube_mesh.size = Vector3(0.95, 0.95, 0.95)

	for z in range(grid_depth):
		for x in range(grid_width):
			var h_str: String = str(structure_layer[z][x])
			var h: int = int(h_str) if h_str.is_valid_int() else 0
			if h <= 0: continue
			if h == 6:
				for y in range(3):
					var wall := MeshInstance3D.new()
					wall.mesh = cube_mesh
					wall.position = Vector3(x, y + 0.5, z)
					var mat := StandardMaterial3D.new()
					mat.albedo_color = Color(0.4, 0.15, 0.15)
					wall.material_override = mat
					_map_container.add_child(wall)
			else:
				var block := MeshInstance3D.new()
				block.mesh = cube_mesh
				block.position = Vector3(x, (h - 1) * 0.5, z)
				var mat := StandardMaterial3D.new()
				mat.albedo_color = HEIGHT_COLORS.get(h_str, Color(0.3, 0.3, 0.3))
				mat.emission_enabled = true
				mat.emission = mat.albedo_color * 0.15
				block.material_override = mat
				_map_container.add_child(block)

	for z in range(grid_depth):
		for x in range(grid_width):
			var u: String = str(utilities_layer[z][x]).strip_edges()
			if u == "" or u == " ": continue
			var code := u.split(":")[0]
			var marker := MeshInstance3D.new()
			var sphere := SphereMesh.new()
			sphere.radius = 0.3
			sphere.height = 0.6
			marker.mesh = sphere
			marker.position = Vector3(x, 1.5, z)
			var mat := StandardMaterial3D.new()
			mat.albedo_color = UTILITY_COLORS.get(code, Color(0.8, 0.8, 0.8))
			mat.emission_enabled = true
			mat.emission = mat.albedo_color * 0.5
			mat.emission_energy_multiplier = 2.0
			marker.material_override = mat
			_map_container.add_child(marker)

	for z in range(grid_depth):
		for x in range(grid_width):
			var a: String = str(interactables_layer[z][x]).strip_edges()
			if a == "" or a == " ": continue
			var marker := MeshInstance3D.new()
			var box := BoxMesh.new()
			box.size = Vector3(0.6, 1.2, 0.6)
			marker.mesh = box
			marker.position = Vector3(x, 0.6, z)
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(1.0, 0.7, 0.2)
			mat.emission_enabled = true
			mat.emission = Color(1.0, 0.7, 0.2) * 0.4
			marker.material_override = mat
			_map_container.add_child(marker)
			var lbl := Label3D.new()
			lbl.text = a.split(":")[0].substr(0, 10)
			lbl.font_size = 12
			lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			lbl.position = Vector3(x, 2.0, z)
			lbl.modulate = Color(1.0, 0.8, 0.3, 0.8)
			_map_container.add_child(lbl)

# === LAYER & PALETTE ===

func _on_layer_changed(idx: int) -> void:
	active_layer = idx
	_build_palette()
	_grid_canvas.queue_redraw()

func _build_palette() -> void:
	for c in _palette.get_children(): c.queue_free()
	match active_layer:
		0:
			for h in range(7):
				var btn := Button.new()
				btn.text = str(h)
				btn.custom_minimum_size = Vector2(28, 24)
				btn.pressed.connect(func(): paint_value = str(h))
				_palette.add_child(btn)
			paint_value = "1"
		1:
			for code in ["sp", "t", "r", "wp", "tc", "m", "ds", "sub", " "]:
				var btn := Button.new()
				btn.text = code if code != " " else "x"
				btn.custom_minimum_size = Vector2(32, 24)
				btn.pressed.connect(func(): paint_value = code)
				_palette.add_child(btn)
			paint_value = "sp"
		2:
			var lbl := Label.new()
			lbl.text = "Select cell, type in inspector"
			_palette.add_child(lbl)
			paint_value = " "

# === 2D GRID ===

func _on_grid_draw() -> void:
	if structure_layer.is_empty(): return
	var font: Font = ThemeDB.fallback_font
	for z in range(grid_depth):
		for x in range(grid_width):
			var rect := Rect2(x * CELL_SIZE, z * CELL_SIZE, CELL_SIZE, CELL_SIZE)
			var h_str: String = str(structure_layer[z][x]) if z < structure_layer.size() and x < structure_layer[z].size() else "0"
			var bg: Color = HEIGHT_COLORS.get(h_str, Color(0.15, 0.15, 0.15))
			if active_layer != 0: bg = bg.darkened(0.3)
			_grid_canvas.draw_rect(rect, bg)

			var u: String = str(utilities_layer[z][x]).strip_edges() if z < utilities_layer.size() and x < utilities_layer[z].size() else ""
			if u != "" and u != " ":
				var code := u.split(":")[0]
				var uc: Color = UTILITY_COLORS.get(code, Color(0.7, 0.7, 0.7))
				if active_layer != 1: uc.a = 0.35
				_grid_canvas.draw_rect(rect.grow(-2), uc, false, 2.0)
				_grid_canvas.draw_string(font, rect.position + Vector2(2, 9), code, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, uc)

			var a: String = str(interactables_layer[z][x]).strip_edges() if z < interactables_layer.size() and x < interactables_layer[z].size() else ""
			if a != "" and a != " ":
				var ic := Color(1.0, 0.7, 0.2, 0.8 if active_layer == 2 else 0.25)
				_grid_canvas.draw_circle(rect.get_center(), CELL_SIZE * 0.3, ic)
				_grid_canvas.draw_string(font, rect.position + Vector2(2, CELL_SIZE - 2), a.split(":")[0].substr(0, 4), HORIZONTAL_ALIGNMENT_LEFT, -1, 7, ic)

			_grid_canvas.draw_rect(rect, Color(0.18, 0.18, 0.22), false, 1.0)
			if Vector2i(x, z) == selected_cell:
				_grid_canvas.draw_rect(rect.grow(-1), Color(1.0, 1.0, 0.3, 0.7), false, 2.0)

func _on_grid_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		is_painting = event.pressed
		if event.pressed: _cell_action(event.position)
	elif event is InputEventMouseMotion and is_painting:
		_cell_action(event.position)

func _cell_action(pos: Vector2) -> void:
	var x := int(pos.x / CELL_SIZE)
	var z := int(pos.y / CELL_SIZE)
	if x < 0 or x >= grid_width or z < 0 or z >= grid_depth: return
	selected_cell = Vector2i(x, z)
	match active_layer:
		0: structure_layer[z][x] = paint_value
		1: utilities_layer[z][x] = paint_value
	_grid_canvas.queue_redraw()
	_update_inspector()

func _on_artifact_submitted(text: String) -> void:
	if selected_cell.x >= 0 and selected_cell.y >= 0:
		interactables_layer[selected_cell.y][selected_cell.x] = text if text != "" else " "
		_grid_canvas.queue_redraw()
		_rebuild_3d_preview()
		_update_inspector()

func _update_inspector() -> void:
	if selected_cell.x < 0:
		_inspector_name.text = "No cell"
		_inspector_detail.text = ""
		_artifact_input.text = ""
		return
	var x := selected_cell.x
	var z := selected_cell.y
	_inspector_name.text = "Cell [%d, %d]" % [x, z]
	var h: String = str(structure_layer[z][x])
	var u: String = str(utilities_layer[z][x]).strip_edges()
	var a: String = str(interactables_layer[z][x]).strip_edges()
	_artifact_input.text = a if a != " " else ""
	var txt := "[b]Height:[/b] %s\n" % h
	if u != "" and u != " ": txt += "[b]Utility:[/b] %s\n" % u
	if a != "" and a != " ": txt += "[b]Artifact:[/b] %s\n" % a
	_inspector_detail.text = txt

# === SAVE ===

func _save_map() -> void:
	if map_path == "":
		_status.text = "No map"
		return
	if "layers" not in map_data: map_data["layers"] = {}
	map_data["layers"]["structure"] = structure_layer
	map_data["layers"]["utilities"] = utilities_layer
	map_data["layers"]["interactables"] = interactables_layer
	var file := FileAccess.open(map_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(map_data, "  "))
		file.close()
		_status.text = "Saved!"
	else:
		_status.text = "Failed"

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.ctrl_pressed and event.keycode == KEY_S:
		_save_map()
		get_viewport().set_input_as_handled()
