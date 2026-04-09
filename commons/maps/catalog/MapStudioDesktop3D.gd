extends HSplitContainer

const CELL := 38
const H_COLORS := {
	"0": Color(0.06, 0.06, 0.08), "1": Color(0.3, 0.3, 0.35),
	"2": Color(0.4, 0.4, 0.45), "3": Color(0.5, 0.5, 0.55),
	"4": Color(0.6, 0.6, 0.65), "5": Color(0.7, 0.7, 0.75),
	"6": Color(0.5, 0.12, 0.12),
}
const U_COLORS := {
	"sp": Color(0.2, 1.0, 0.3), "s": Color(0.2, 1.0, 0.3),
	"t": Color(0.2, 0.5, 1.0), "3t": Color(0.2, 0.5, 1.0),
	"r": Color(1.0, 0.8, 0.2), "wp": Color(1.0, 0.8, 0.2),
	"tc": Color(0.8, 0.4, 1.0), "m": Color(0.5, 0.5, 0.5),
	"ds": Color(1.0, 0.3, 0.3), "sub": Color(0.3, 0.8, 0.8),
}

var map_data: Dictionary
var map_path: String
var gw: int
var gd_val: int
var sl: Array  # structure
var ul: Array  # utilities
var il: Array  # interactables
var layer: int = 0
var paint: String = "1"
var painting: bool
var sel := Vector2i(-1, -1)
var paths: Array[String]

var orbit_yaw := 0.4
var orbit_pitch := 0.5
var orbit_dist := 15.0
var orbit_focus := Vector3(5, 0, 5)
var orbiting := false

@onready var list: ItemList = $MapList/List
@onready var filter: LineEdit = $MapList/Filter
@onready var tabs: TabBar = $CenterRight/Center/Grid2D/Toolbar/LayerTabs
@onready var palette: HBoxContainer = $CenterRight/Center/Grid2D/Palette
@onready var canvas: Control = $CenterRight/Center/Grid2D/GridScroll/GridCanvas
@onready var save_btn: Button = $CenterRight/Center/Grid2D/Toolbar/SaveBtn
@onready var cam: Camera3D = $CenterRight/Center/View3D/Viewport/Camera
@onready var map_root: Node3D = $CenterRight/Center/View3D/Viewport/MapContainer
@onready var viewport: SubViewport = $CenterRight/Center/View3D/Viewport
@onready var view3d: SubViewportContainer = $CenterRight/Center/View3D
@onready var cell_label: Label = $CenterRight/Inspector/CellLabel
@onready var art_input: LineEdit = $CenterRight/Inspector/ArtRow/Input
@onready var detail: RichTextLabel = $CenterRight/Inspector/Detail
@onready var status: Label = $CenterRight/Inspector/Status

func _ready() -> void:
	# Environment
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.1, 0.1, 0.14)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.4, 0.4, 0.45)
	env.ambient_light_energy = 0.5
	$CenterRight/Center/View3D/Viewport/Environment.environment = env

	cam.look_at(orbit_focus)

	list.item_selected.connect(_on_list)
	filter.text_changed.connect(_on_filter)
	tabs.tab_changed.connect(_on_tab)
	save_btn.pressed.connect(_save)
	canvas.gui_input.connect(_on_canvas_input)
	canvas.draw.connect(_on_canvas_draw)
	art_input.text_submitted.connect(_on_art_submit)
	view3d.gui_input.connect(_on_3d_input)

	_scan()
	_build_palette()

func _scan() -> void:
	list.clear()
	paths.clear()
	var dir := DirAccess.open("res://commons/maps/")
	if not dir: return
	dir.list_dir_begin()
	while true:
		var f := dir.get_next()
		if f == "": break
		if dir.current_is_dir() and not f.begins_with(".") and f != "catalog":
			var p := "res://commons/maps/" + f + "/map_data.json"
			if FileAccess.file_exists(p):
				list.add_item(f)
				paths.append(p)
	dir.list_dir_end()
	status.text = "%d maps" % paths.size()

func _on_filter(t: String) -> void:
	var q := t.to_lower()
	list.clear()
	for p in paths:
		var n := p.get_base_dir().get_file()
		if q == "" or q in n.to_lower():
			list.add_item(n)

func _on_list(idx: int) -> void:
	var n := list.get_item_text(idx)
	map_path = "res://commons/maps/" + n + "/map_data.json"
	_load(map_path)

func _load(p: String) -> void:
	var f := FileAccess.open(p, FileAccess.READ)
	if not f: return
	var j := JSON.new()
	if j.parse(f.get_as_text()) != OK:
		f.close()
		return
	f.close()
	map_data = j.data
	var ly: Dictionary = map_data.get("layers", {})
	sl = ly.get("structure", [])
	ul = ly.get("utilities", [])
	il = ly.get("interactables", [])
	gd_val = sl.size()
	gw = sl[0].size() if gd_val > 0 else 0
	_pad(ul)
	_pad(il)
	canvas.custom_minimum_size = Vector2(gw * CELL + 1, gd_val * CELL + 1)
	canvas.queue_redraw()
	_build_3d()
	orbit_focus = Vector3(gw * 0.5, 0, gd_val * 0.5)
	orbit_dist = maxf(gw, gd_val) * 1.2
	_update_cam()
	sel = Vector2i(-1, -1)
	status.text = "%s %dx%d" % [p.get_base_dir().get_file(), gw, gd_val]

func _pad(a: Array) -> void:
	while a.size() < gd_val:
		var r := []
		r.resize(gw)
		r.fill(" ")
		a.append(r)
	for r in a:
		while r.size() < gw:
			r.append(" ")

# 2D GRID
func _on_tab(i: int) -> void:
	layer = i
	_build_palette()
	canvas.queue_redraw()

var _art_search: LineEdit
var _art_list: ItemList
var _all_artifact_names: Array[String] = []

func _build_palette() -> void:
	for c in palette.get_children(): c.queue_free()
	match layer:
		0:
			var row := HFlowContainer.new()
			palette.add_child(row)
			for h in range(7):
				var b := Button.new()
				b.text = str(h)
				b.custom_minimum_size = Vector2(28, 24)
				var v: String = str(h)
				b.pressed.connect(func(): paint = v)
				row.add_child(b)
			paint = "1"
		1:
			var row := HFlowContainer.new()
			palette.add_child(row)
			for code in ["sp", "t", "r", "wp", "tc", "m", "ds", "sub", " "]:
				var b := Button.new()
				b.text = code if code != " " else "x"
				b.custom_minimum_size = Vector2(32, 24)
				var v: String = code
				b.pressed.connect(func(): paint = v)
				row.add_child(b)
			paint = "sp"
		2:
			_build_artifact_palette()

func _build_artifact_palette() -> void:
	# Load all artifact names once
	if _all_artifact_names.is_empty():
		var all := ArtifactCatalogDataProvider.get_all_artifacts()
		for a in all:
			var n: String = str(a.get("lookup_name", ""))
			if n != "":
				_all_artifact_names.append(n)
		_all_artifact_names.sort()

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = SIZE_EXPAND_FILL
	palette.add_child(vbox)

	var row := HBoxContainer.new()
	vbox.add_child(row)

	_art_search = LineEdit.new()
	_art_search.placeholder_text = "Search artifact..."
	_art_search.size_flags_horizontal = SIZE_EXPAND_FILL
	_art_search.text_changed.connect(_on_art_filter)
	row.add_child(_art_search)

	var clear_btn := Button.new()
	clear_btn.text = "x"
	clear_btn.custom_minimum_size = Vector2(28, 0)
	clear_btn.pressed.connect(func():
		if sel.x >= 0:
			il[sel.y][sel.x] = " "
			canvas.queue_redraw()
			_build_3d()
			_update_insp()
	)
	row.add_child(clear_btn)

	_art_list = ItemList.new()
	_art_list.custom_minimum_size = Vector2(0, 80)
	_art_list.max_columns = 3
	_art_list.item_selected.connect(_on_art_picked)
	vbox.add_child(_art_list)

	_filter_art_list("")

func _on_art_filter(t: String) -> void:
	_filter_art_list(t)

func _filter_art_list(t: String) -> void:
	if not _art_list: return
	_art_list.clear()
	var q := t.to_lower()
	for n in _all_artifact_names:
		if q == "" or q in n.to_lower():
			_art_list.add_item(n)

func _on_art_picked(idx: int) -> void:
	var name_str: String = _art_list.get_item_text(idx)
	paint = name_str
	# If a cell is selected, place immediately
	if sel.x >= 0:
		il[sel.y][sel.x] = name_str
		canvas.queue_redraw()
		_build_3d()
		_update_insp()
		art_input.text = name_str

func _on_canvas_draw() -> void:
	if sl.is_empty(): return
	var font: Font = ThemeDB.fallback_font
	for z in range(gd_val):
		for x in range(gw):
			var r := Rect2(x * CELL, z * CELL, CELL, CELL)
			var hs: String = str(sl[z][x])
			var bg: Color = H_COLORS.get(hs, Color(0.15, 0.15, 0.15))
			if layer != 0: bg = bg.darkened(0.3)
			canvas.draw_rect(r, bg)

			var us: String = str(ul[z][x]).strip_edges()
			if us != "" and us != " ":
				var uc: Color = U_COLORS.get(us.split(":")[0], Color(0.7, 0.7, 0.7))
				if layer != 1: uc.a = 0.35
				canvas.draw_rect(r.grow(-2), uc, false, 2.0)
				canvas.draw_string(font, r.position + Vector2(2, 9), us.split(":")[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 8, uc)

			var ia: String = str(il[z][x]).strip_edges()
			if ia != "" and ia != " ":
				var ic := Color(1.0, 0.7, 0.2, 0.8 if layer == 2 else 0.25)
				canvas.draw_circle(r.get_center(), CELL * 0.3, ic)
				canvas.draw_string(font, r.position + Vector2(1, CELL - 2), ia.split(":")[0].substr(0, 4), HORIZONTAL_ALIGNMENT_LEFT, -1, 7, ic)

			canvas.draw_rect(r, Color(0.18, 0.18, 0.22), false, 1.0)
			if Vector2i(x, z) == sel:
				canvas.draw_rect(r.grow(-1), Color(1, 1, 0.3, 0.7), false, 2.0)

func _on_canvas_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT:
		painting = ev.pressed
		if ev.pressed: _cell(ev.position)
	elif ev is InputEventMouseMotion and painting:
		_cell(ev.position)

func _cell(pos: Vector2) -> void:
	var x := int(pos.x / CELL)
	var z := int(pos.y / CELL)
	if x < 0 or x >= gw or z < 0 or z >= gd_val: return
	sel = Vector2i(x, z)
	match layer:
		0: sl[z][x] = paint
		1: ul[z][x] = paint
		2:
			if paint != "" and paint != " ":
				il[z][x] = paint
				art_input.text = paint
	canvas.queue_redraw()
	_update_insp()
	_build_3d()

func _on_art_submit(t: String) -> void:
	if sel.x < 0: return
	il[sel.y][sel.x] = t if t != "" else " "
	canvas.queue_redraw()
	_build_3d()
	_update_insp()

func _update_insp() -> void:
	if sel.x < 0:
		cell_label.text = "No cell"
		detail.text = ""
		art_input.text = ""
		return
	cell_label.text = "[%d, %d]" % [sel.x, sel.y]
	var h: String = str(sl[sel.y][sel.x])
	var u: String = str(ul[sel.y][sel.x]).strip_edges()
	var a: String = str(il[sel.y][sel.x]).strip_edges()
	art_input.text = a if a != " " else ""
	var t := "Height: %s" % h
	if u != "" and u != " ": t += "\nUtility: %s" % u
	if a != "" and a != " ": t += "\nArtifact: %s" % a
	detail.text = t

# 3D PREVIEW
func _build_3d() -> void:
	for c in map_root.get_children(): c.queue_free()
	if sl.is_empty(): return
	var cube := BoxMesh.new()
	cube.size = Vector3(0.95, 0.95, 0.95)
	for z in range(gd_val):
		for x in range(gw):
			var hs: String = str(sl[z][x])
			var h: int = int(hs) if hs.is_valid_int() else 0
			if h <= 0: continue
			if h == 6:
				for y in range(3):
					var m := MeshInstance3D.new()
					m.mesh = cube
					m.position = Vector3(x, y + 0.5, z)
					var mt := StandardMaterial3D.new()
					mt.albedo_color = Color(0.4, 0.15, 0.15)
					m.material_override = mt
					map_root.add_child(m)
			else:
				var m := MeshInstance3D.new()
				m.mesh = cube
				m.position = Vector3(x, (h - 1) * 0.5, z)
				var mt := StandardMaterial3D.new()
				mt.albedo_color = H_COLORS.get(hs, Color(0.3, 0.3, 0.3))
				m.material_override = mt
				map_root.add_child(m)

	# Real artifacts from registry
	for z in range(gd_val):
		for x in range(gw):
			var ia: String = str(il[z][x]).strip_edges()
			if ia == "" or ia == " ": continue
			var lookup: String = ia.split(":")[0]
			var rot: float = 0.0
			var y_off: float = 0.0
			var parts := ia.split(":")
			if parts.size() > 1 and parts[1].is_valid_float(): rot = float(parts[1])
			if parts.size() > 2 and parts[2].is_valid_float(): y_off = float(parts[2])

			var art_data: Dictionary = ArtifactCatalogDataProvider.get_artifact_by_lookup_name(lookup)
			var scene_path: String = str(art_data.get("scene", ""))
			if scene_path != "" and ResourceLoader.exists(scene_path):
				var packed: PackedScene = ResourceLoader.load(scene_path, "PackedScene", ResourceLoader.CACHE_MODE_REUSE) as PackedScene
				if packed:
					var inst: Node = packed.instantiate()
					if inst:
						map_root.add_child(inst)
						if inst is Node3D:
							(inst as Node3D).position = Vector3(x, y_off, z)
							(inst as Node3D).rotation_degrees.y = rot
						# Disable cameras
						_disable_cams(inst)
						continue

			# Fallback: amber box if artifact can't load
			var m := MeshInstance3D.new()
			var box := BoxMesh.new()
			box.size = Vector3(0.6, 1.2, 0.6)
			m.mesh = box
			m.position = Vector3(x, 0.6 + y_off, z)
			var mt := StandardMaterial3D.new()
			mt.albedo_color = Color(1.0, 0.7, 0.2)
			mt.emission_enabled = true
			mt.emission = Color(1.0, 0.7, 0.2) * 0.4
			m.material_override = mt
			map_root.add_child(m)

func _disable_cams(node: Node) -> void:
	if node is Camera3D:
		(node as Camera3D).current = false
	for c in node.get_children():
		_disable_cams(c)

func _on_3d_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton:
		if ev.button_index == MOUSE_BUTTON_RIGHT or ev.button_index == MOUSE_BUTTON_MIDDLE:
			orbiting = ev.pressed
		elif ev.button_index == MOUSE_BUTTON_WHEEL_UP:
			orbit_dist = maxf(3.0, orbit_dist - 1.5)
			_update_cam()
		elif ev.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			orbit_dist += 1.5
			_update_cam()
	elif ev is InputEventMouseMotion and orbiting:
		orbit_yaw -= ev.relative.x * 0.005
		orbit_pitch = clampf(orbit_pitch + ev.relative.y * 0.005, 0.1, 1.4)
		_update_cam()

func _update_cam() -> void:
	var o := Vector3(sin(orbit_yaw) * cos(orbit_pitch), sin(orbit_pitch), cos(orbit_yaw) * cos(orbit_pitch)) * orbit_dist
	cam.position = orbit_focus + o
	cam.look_at(orbit_focus, Vector3.UP)

# SAVE
func _save() -> void:
	if map_path == "": return
	if "layers" not in map_data: map_data["layers"] = {}
	map_data["layers"]["structure"] = sl
	map_data["layers"]["utilities"] = ul
	map_data["layers"]["interactables"] = il
	var f := FileAccess.open(map_path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(map_data, "  "))
		f.close()
		status.text = "Saved!"

func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and ev.ctrl_pressed and ev.keycode == KEY_S:
		_save()
		get_viewport().set_input_as_handled()
