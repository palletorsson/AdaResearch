extends Node3D

## Map Studio Desktop — 3D scene with 2D overlay panels
## 3D viewport IS the map preview. 2D panels overlay: map list (left), grid editor (top-right), inspector (right).

const CELL_SIZE := 24
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
	"sp": Color(0.2, 1.0, 0.3), "s": Color(0.2, 1.0, 0.3),
	"t": Color(0.2, 0.5, 1.0), "3t": Color(0.2, 0.5, 1.0),
	"r": Color(1.0, 0.8, 0.2), "wp": Color(1.0, 0.8, 0.2),
	"tc": Color(0.8, 0.4, 1.0), "m": Color(0.5, 0.5, 0.5),
	"ds": Color(1.0, 0.3, 0.3), "an": Color(0.3, 0.8, 0.8),
	"sub": Color(0.3, 0.8, 0.8),
}

# Map data
var map_data: Dictionary = {}
var map_path: String = ""
var grid_width: int = 0
var grid_depth: int = 0
var structure_layer: Array = []
var utilities_layer: Array = []
var interactables_layer: Array = []

# State
var active_layer: int = 0
var paint_value: String = "1"
var is_painting: bool = false
var selected_cell: Vector2i = Vector2i(-1, -1)

# 3D scene
var _camera: Camera3D
var _map_container: Node3D  # holds generated 3D map preview
var _orbit_yaw: float = 0.4
var _orbit_pitch: float = 0.5
var _orbit_dist: float = 15.0
var _orbit_focus: Vector3 = Vector3(5, 0, 5)
var _is_orbiting: bool = false

# UI refs
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
	_build_3d_scene()
	_build_ui_overlays()
	_scan_maps()

# === 3D SCENE ===

func _build_3d_scene() -> void:
	# Environment
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.12, 0.13, 0.18)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.4, 0.4, 0.45)
	env.ambient_light_energy = 0.5
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

	# Camera
	_camera = Camera3D.new()
	_camera.name = "StudioCamera"
	_camera.fov = 50
	_camera.current = true
	add_child(_camera)
	_update_camera()

	# Lights
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-45, -30, 0)
	key.light_energy = 1.2
	key.shadow_enabled = true
	add_child(key)

	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-20, 150, 0)
	fill.light_energy = 0.4
	add_child(fill)

	# Container for map geometry
	_map_container = Node3D.new()
	_map_container.name = "MapPreview"
	add_child(_map_container)

func _update_camera() -> void:
	var offset := Vector3(
		sin(_orbit_yaw) * cos(_orbit_pitch),
		sin(_orbit_pitch),
		cos(_orbit_yaw) * cos(_orbit_pitch)
	) * _orbit_dist
	_camera.position = _orbit_focus + offset
	_camera.look_at(_orbit_focus, Vector3.UP)

# === 2D UI OVERLAYS ===

func _build_ui_overlays() -> void:
	# Layer 1: Left panel (map list)
	var left_layer := CanvasLayer.new()
	left_layer.layer = 10
	add_child(left_layer)

	var left_panel := PanelContainer.new()
	left_panel.anchor_left = 0.0
	left_panel.anchor_top = 0.0
	left_panel.anchor_right = 0.0
	left_panel.anchor_bottom = 1.0
	left_panel.offset_right = 185
	left_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	left_layer.add_child(left_panel)

	var left_vbox := VBoxContainer.new()
	left_panel.add_child(left_vbox)

	var title := Label.new()
	title.text = "Map Studio"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	left_vbox.add_child(title)

	var search := LineEdit.new()
	search.placeholder_text = "Filter maps..."
	search.text_changed.connect(_filter_maps)
	left_vbox.add_child(search)

	_map_list = ItemList.new()
	_map_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_map_list.item_selected.connect(_on_map_selected)
	left_vbox.add_child(_map_list)

	_status = Label.new()
	_status.text = "Ready"
	_status.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	_status.add_theme_font_size_override("font_size", 11)
	left_vbox.add_child(_status)

	# Layer 2: Top-right panel (2D grid editor)
	var grid_layer := CanvasLayer.new()
	grid_layer.layer = 10
	add_child(grid_layer)

	var grid_panel := PanelContainer.new()
	grid_panel.anchor_left = 0.55
	grid_panel.anchor_right = 1.0
	grid_panel.anchor_top = 0.0
	grid_panel.anchor_bottom = 0.55
	grid_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	grid_layer.add_child(grid_panel)

	var grid_vbox := VBoxContainer.new()
	grid_panel.add_child(grid_vbox)

	# Layer tabs + save
	var toolbar := HBoxContainer.new()
	grid_vbox.add_child(toolbar)

	_layer_tabs = TabBar.new()
	_layer_tabs.add_tab("Structure")
	_layer_tabs.add_tab("Utilities")
	_layer_tabs.add_tab("Interactables")
	_layer_tabs.tab_changed.connect(_on_layer_changed)
	toolbar.add_child(_layer_tabs)

	var save_btn := Button.new()
	save_btn.text = "Save"
	save_btn.pressed.connect(_save_map)
	toolbar.add_child(save_btn)

	_palette = HBoxContainer.new()
	grid_vbox.add_child(_palette)

	var grid_scroll := ScrollContainer.new()
	grid_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid_vbox.add_child(grid_scroll)

	_grid_canvas = Control.new()
	_grid_canvas.gui_input.connect(_on_grid_input)
	_grid_canvas.draw.connect(_on_grid_draw)
	grid_scroll.add_child(_grid_canvas)

	# Layer 3: Bottom-right panel (inspector)
	var insp_layer := CanvasLayer.new()
	insp_layer.layer = 10
	add_child(insp_layer)

	var insp_panel := PanelContainer.new()
	insp_panel.anchor_left = 0.55
	insp_panel.anchor_right = 1.0
	insp_panel.anchor_top = 0.55
	insp_panel.anchor_bottom = 1.0
	insp_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	insp_layer.add_child(insp_panel)

	var insp_vbox := VBoxContainer.new()
	insp_panel.add_child(insp_vbox)

	var insp_title := Label.new()
	insp_title.text = "Inspector"
	insp_title.add_theme_font_size_override("font_size", 14)
	insp_vbox.add_child(insp_title)

	_inspector_name = Label.new()
	_inspector_name.text = "No cell selected"
	insp_vbox.add_child(_inspector_name)

	var art_row := HBoxContainer.new()
	insp_vbox.add_child(art_row)
	var art_lbl := Label.new()
	art_lbl.text = "Artifact:"
	art_row.add_child(art_lbl)
	_artifact_input = LineEdit.new()
	_artifact_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_artifact_input.placeholder_text = "lookup_name:rot:y"
	_artifact_input.text_submitted.connect(_on_artifact_submitted)
	art_row.add_child(_artifact_input)

	_inspector_detail = RichTextLabel.new()
	_inspector_detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_inspector_detail.bbcode_enabled = true
	insp_vbox.add_child(_inspector_detail)

	_build_palette()

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
	var f := text.to_lower()
	for i in range(_map_list.item_count):
		_map_list.set_item_disabled(i, f != "" and not _map_list.get_item_text(i).to_lower().contains(f))

func _on_map_selected(idx: int) -> void:
	if idx < 0 or idx >= _map_paths.size(): return
	map_path = _map_paths[idx]
	_load_map(map_path)

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

	# Update 3D preview
	_rebuild_3d_preview()

	# Fit camera
	_orbit_focus = Vector3(grid_width * 0.5, 0, grid_depth * 0.5)
	_orbit_dist = maxf(grid_width, grid_depth) * 1.2
	_update_camera()

	var name_str: String = str(map_data.get("map_info", {}).get("name", path.get_file()))
	_status.text = "%s  %dx%d" % [name_str, grid_width, grid_depth]
	selected_cell = Vector2i(-1, -1)

func _ensure_layer(layer: Array) -> void:
	while layer.size() < grid_depth:
		var row: Array = []
		row.resize(grid_width)
		row.fill(" ")
		layer.append(row)
	for row in layer:
		while row.size() < grid_width:
			row.append(" ")

# === 3D MAP PREVIEW ===

func _rebuild_3d_preview() -> void:
	# Clear existing
	for child in _map_container.get_children():
		child.queue_free()

	if structure_layer.is_empty():
		return

	# Build simple cube geometry from structure layer
	var cube_mesh := BoxMesh.new()
	cube_mesh.size = Vector3(0.95, 0.95, 0.95)

	for z in range(grid_depth):
		for x in range(grid_width):
			var h_str: String = str(structure_layer[z][x])
			var h: int = int(h_str) if h_str.is_valid_int() else 0
			if h <= 0:
				continue  # void

			if h == 6:
				# Wall — tall column
				for y in range(3):
					var wall := MeshInstance3D.new()
					wall.mesh = cube_mesh
					wall.position = Vector3(x, y + 0.5, z)
					var mat := StandardMaterial3D.new()
					mat.albedo_color = Color(0.4, 0.15, 0.15)
					wall.material_override = mat
					_map_container.add_child(wall)
			else:
				# Floor at height h
				var floor_block := MeshInstance3D.new()
				floor_block.mesh = cube_mesh
				floor_block.position = Vector3(x, (h - 1) * 0.5, z)
				var mat := StandardMaterial3D.new()
				mat.albedo_color = HEIGHT_COLORS.get(h_str, Color(0.3, 0.3, 0.3))
				mat.emission_enabled = true
				mat.emission = mat.albedo_color * 0.15
				mat.emission_energy_multiplier = 0.3
				floor_block.material_override = mat
				_map_container.add_child(floor_block)

	# Utility markers
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

	# Interactable markers
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
			mat.emission_energy_multiplier = 1.5
			marker.material_override = mat
			_map_container.add_child(marker)

			var lbl := Label3D.new()
			lbl.text = a.split(":")[0].substr(0, 10)
			lbl.font_size = 12
			lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			lbl.position = Vector3(x, 2.0, z)
			lbl.modulate = Color(1.0, 0.8, 0.3, 0.8)
			_map_container.add_child(lbl)

# === CAMERA ORBIT (middle mouse or right-click drag in 3D area) ===

func _input(event: InputEvent) -> void:
	# Only orbit when mouse is in the 3D area (left 55% of screen)
	if event is InputEventMouseButton:
		var vp := get_viewport()
		if vp and event.position.x < vp.size.x * 0.55:
			if event.button_index == MOUSE_BUTTON_MIDDLE or event.button_index == MOUSE_BUTTON_RIGHT:
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

# === LAYER & PALETTE ===

func _on_layer_changed(idx: int) -> void:
	active_layer = idx
	_build_palette()
	_grid_canvas.queue_redraw()

func _build_palette() -> void:
	for c in _palette.get_children():
		c.queue_free()
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
			lbl.text = "Select cell → type in inspector"
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
		if event.pressed:
			_cell_action(event.position)
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
		# 2: interactables — use inspector input instead of painting

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
		_status.text = "No map loaded"
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
		_status.text = "Save failed"

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.ctrl_pressed and event.keycode == KEY_S:
		_save_map()
		get_viewport().set_input_as_handled()
