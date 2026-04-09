@tool
extends VBoxContainer

## 2D top-down map_data.json editor
## Three layers: structure (heights), utilities (spawn/teleporter), interactables (artifacts)

const CELL_SIZE := 32
const HEIGHT_COLORS := {
	"0": Color(0.08, 0.08, 0.1),    # void — near black
	"1": Color(0.35, 0.35, 0.4),    # floor 1 — dark gray
	"2": Color(0.45, 0.45, 0.5),    # floor 2
	"3": Color(0.55, 0.55, 0.6),    # floor 3
	"4": Color(0.65, 0.65, 0.7),    # floor 4
	"5": Color(0.75, 0.75, 0.8),    # floor 5
	"6": Color(0.5, 0.15, 0.15),    # wall — dark red
}
const UTILITY_COLORS := {
	"sp": Color(0.2, 1.0, 0.3),     # spawn — green
	"t": Color(0.2, 0.5, 1.0),      # teleporter — blue
	"r": Color(1.0, 0.8, 0.2),      # ramp — yellow
	"tc": Color(0.8, 0.4, 1.0),     # transport cube — purple
	"m": Color(0.5, 0.5, 0.5),      # music — gray
	"ds": Color(1.0, 0.3, 0.3),     # danger — red
	"an": Color(0.3, 0.8, 0.8),     # annotation — teal
}

# State
var map_data: Dictionary = {}
var map_path: String = ""
var grid_width: int = 10
var grid_depth: int = 10
var structure_layer: Array = []
var utilities_layer: Array = []
var interactables_layer: Array = []
var active_layer: int = 0  # 0=structure, 1=utilities, 2=interactables
var paint_value: String = "1"
var is_painting: bool = false

# UI references
var grid_canvas: Control
var layer_buttons: Array[Button] = []
var palette_container: HBoxContainer
var map_selector: OptionButton
var save_button: Button
var info_label: Label

func _ready() -> void:
	_build_ui()
	_scan_maps()

func _build_ui() -> void:
	# Top toolbar
	var toolbar := HBoxContainer.new()
	toolbar.name = "Toolbar"
	add_child(toolbar)

	# Map selector
	var map_label := Label.new()
	map_label.text = "Map:"
	toolbar.add_child(map_label)

	map_selector = OptionButton.new()
	map_selector.custom_minimum_size = Vector2(250, 0)
	map_selector.item_selected.connect(_on_map_selected)
	toolbar.add_child(map_selector)

	# Layer buttons
	var layer_label := Label.new()
	layer_label.text = "  Layer:"
	toolbar.add_child(layer_label)

	for i in range(3):
		var btn := Button.new()
		btn.text = ["Structure", "Utilities", "Interactables"][i]
		btn.toggle_mode = true
		btn.button_pressed = (i == 0)
		btn.pressed.connect(_on_layer_selected.bind(i))
		toolbar.add_child(btn)
		layer_buttons.append(btn)

	# Save button
	save_button = Button.new()
	save_button.text = "Save"
	save_button.pressed.connect(_save_map)
	toolbar.add_child(save_button)

	# Info label
	info_label = Label.new()
	info_label.text = "No map loaded"
	toolbar.add_child(info_label)

	# Palette row
	palette_container = HBoxContainer.new()
	palette_container.name = "Palette"
	add_child(palette_container)
	_build_palette()

	# Grid canvas (draws the map)
	var scroll := ScrollContainer.new()
	scroll.name = "GridScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(scroll)

	grid_canvas = Control.new()
	grid_canvas.name = "GridCanvas"
	grid_canvas.gui_input.connect(_on_grid_input)
	grid_canvas.draw.connect(_on_grid_draw)
	scroll.add_child(grid_canvas)

	# Layout is handled by VBoxContainer root — children stack vertically

func _build_palette() -> void:
	for child in palette_container.get_children():
		child.queue_free()

	match active_layer:
		0:  # Structure — height buttons 0-6
			for h in range(7):
				var btn := Button.new()
				btn.text = str(h)
				btn.custom_minimum_size = Vector2(40, 30)
				btn.modulate = HEIGHT_COLORS.get(str(h), Color.WHITE)
				btn.pressed.connect(_set_paint_value.bind(str(h)))
				palette_container.add_child(btn)
			paint_value = "1"
		1:  # Utilities — utility codes
			for code in ["sp", "t", "r", "tc", "m", "ds", "an", " "]:
				var btn := Button.new()
				btn.text = code if code != " " else "clear"
				btn.custom_minimum_size = Vector2(50, 30)
				if code in UTILITY_COLORS:
					btn.modulate = UTILITY_COLORS[code]
				btn.pressed.connect(_set_paint_value.bind(code))
				palette_container.add_child(btn)
			paint_value = "sp"
		2:  # Interactables — text input for artifact name
			var lbl := Label.new()
			lbl.text = "Artifact:"
			palette_container.add_child(lbl)
			var input := LineEdit.new()
			input.placeholder_text = "lookup_name:rotation:y_offset"
			input.custom_minimum_size = Vector2(300, 0)
			input.text_changed.connect(func(t): paint_value = t)
			palette_container.add_child(input)
			var clear_btn := Button.new()
			clear_btn.text = "Clear cell"
			clear_btn.pressed.connect(func(): paint_value = " ")
			palette_container.add_child(clear_btn)
			paint_value = " "

func _set_paint_value(val: String) -> void:
	paint_value = val

func _scan_maps() -> void:
	map_selector.clear()
	var maps_dir := "res://commons/maps/"
	var dir := DirAccess.open(maps_dir)
	if not dir:
		return
	dir.list_dir_begin()
	var idx := 0
	while true:
		var folder := dir.get_next()
		if folder == "":
			break
		if dir.current_is_dir() and not folder.begins_with("."):
			var json_path := maps_dir + folder + "/map_data.json"
			if FileAccess.file_exists(json_path):
				map_selector.add_item(folder, idx)
				map_selector.set_item_metadata(idx, json_path)
				idx += 1
	dir.list_dir_end()

func _on_map_selected(idx: int) -> void:
	map_path = map_selector.get_item_metadata(idx)
	_load_map(map_path)

func _load_map(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		info_label.text = "Failed to open: " + path
		return

	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	if err != OK:
		info_label.text = "JSON error: " + json.get_error_message()
		return

	map_data = json.data
	var layers = map_data.get("layers", {})
	structure_layer = layers.get("structure", [])
	utilities_layer = layers.get("utilities", [])
	interactables_layer = layers.get("interactables", [])

	# Get dimensions
	grid_depth = structure_layer.size()
	grid_width = structure_layer[0].size() if grid_depth > 0 else 0

	# Ensure all layers have same dimensions
	_ensure_layer_size(utilities_layer)
	_ensure_layer_size(interactables_layer)

	# Resize canvas
	grid_canvas.custom_minimum_size = Vector2(grid_width * CELL_SIZE + 1, grid_depth * CELL_SIZE + 1)
	grid_canvas.queue_redraw()

	var map_name: String = map_data.get("map_info", {}).get("name", path.get_file())
	info_label.text = "%s  %dx%d" % [map_name, grid_width, grid_depth]

func _ensure_layer_size(layer: Array) -> void:
	while layer.size() < grid_depth:
		var row: Array = []
		row.resize(grid_width)
		row.fill(" ")
		layer.append(row)
	for row in layer:
		while row.size() < grid_width:
			row.append(" ")

func _on_layer_selected(idx: int) -> void:
	active_layer = idx
	for i in range(layer_buttons.size()):
		layer_buttons[i].button_pressed = (i == idx)
	_build_palette()
	grid_canvas.queue_redraw()

# === GRID DRAWING ===

func _on_grid_draw() -> void:
	if structure_layer.is_empty():
		return

	var canvas := grid_canvas
	var font := ThemeDB.fallback_font
	var font_size := 9

	for z in range(grid_depth):
		for x in range(grid_width):
			var rect := Rect2(x * CELL_SIZE, z * CELL_SIZE, CELL_SIZE, CELL_SIZE)

			# Structure layer (always drawn as background)
			var height_str: String = str(structure_layer[z][x]) if z < structure_layer.size() and x < structure_layer[z].size() else "0"
			var bg_color: Color = HEIGHT_COLORS.get(height_str, Color(0.2, 0.2, 0.2))
			if active_layer != 0:
				bg_color = bg_color.darkened(0.4)  # Dim when not active
			canvas.draw_rect(rect, bg_color)

			# Utilities overlay
			if active_layer == 1 or true:  # Always show utilities
				var util_str: String = str(utilities_layer[z][x]).strip_edges() if z < utilities_layer.size() and x < utilities_layer[z].size() else ""
				if util_str != "" and util_str != " ":
					var code := util_str.split(":")[0]
					var util_color: Color = UTILITY_COLORS.get(code, Color(0.8, 0.8, 0.8))
					if active_layer != 1:
						util_color.a = 0.4
					canvas.draw_rect(rect.grow(-2), util_color, false, 2.0)
					canvas.draw_string(font, rect.position + Vector2(3, font_size + 2), code, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, util_color)

			# Interactables overlay
			if active_layer == 2 or true:  # Always show interactables
				var inter_str: String = str(interactables_layer[z][x]).strip_edges() if z < interactables_layer.size() and x < interactables_layer[z].size() else ""
				if inter_str != "" and inter_str != " ":
					var name_part: String = inter_str.split(":")[0]
					var inter_color := Color(1.0, 0.7, 0.2)
					if active_layer != 2:
						inter_color.a = 0.3
					canvas.draw_circle(rect.get_center(), CELL_SIZE * 0.35, inter_color)
					canvas.draw_string(font, rect.position + Vector2(2, CELL_SIZE - 3), name_part.substr(0, 6), HORIZONTAL_ALIGNMENT_LEFT, -1, 7, inter_color)

			# Grid lines
			canvas.draw_rect(rect, Color(0.2, 0.2, 0.25), false, 1.0)

# === GRID INPUT (painting) ===

func _on_grid_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			is_painting = event.pressed
			if is_painting:
				_paint_at(event.position)
	elif event is InputEventMouseMotion and is_painting:
		_paint_at(event.position)

func _paint_at(pos: Vector2) -> void:
	var x := int(pos.x / CELL_SIZE)
	var z := int(pos.y / CELL_SIZE)
	if x < 0 or x >= grid_width or z < 0 or z >= grid_depth:
		return

	match active_layer:
		0:
			if z < structure_layer.size() and x < structure_layer[z].size():
				structure_layer[z][x] = paint_value
		1:
			if z < utilities_layer.size() and x < utilities_layer[z].size():
				utilities_layer[z][x] = paint_value
		2:
			if z < interactables_layer.size() and x < interactables_layer[z].size():
				interactables_layer[z][x] = paint_value

	grid_canvas.queue_redraw()

# === SAVE ===

func _save_map() -> void:
	if map_path == "":
		info_label.text = "No map loaded"
		return

	# Update layers in map_data
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
		info_label.text = "Saved: " + map_path.get_file()
	else:
		info_label.text = "Failed to save!"
