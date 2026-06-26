extends Node3D
## Godot-main-editor-style map / hangar editor.
##
## Layout (docks frame a full-viewport 3D scene, like the Godot editor):
##   ┌─ toolbar (top): map name + Save ─────────────────────────────┐
##   │ MAP LIST │            3D VIEWPORT            │  INSPECTOR     │
##   │ (left)   │   (centre, orbit cam, picking)    │  (right)       │
##   ├──────────┴───────────────────────────────────┴───────────────┤
##   │ PROPS / ARTIFACTS PALETTE — drag a thumbnail up into the view │
##   └──────────────────────────────────────────────────────────────┘
##
## Reuses the real GridSystem (WYSIWYG with the game): the centre is the live
## map renderer. Drag a palette item onto the viewport → raycast → place on the
## grid via GridInteractablesComponent. Save merges back into map_data.json.

const MAPS_DIR := "res://commons/maps"
const REGISTRY_DIR := "res://commons/artifacts/registry"
const GRID_SCENE := "res://commons/grid/grid_system.tscn"

const C_PANEL := Color(0.12, 0.13, 0.16, 0.97)
const C_PANEL2 := Color(0.16, 0.17, 0.21, 0.98)
const C_ACCENT := Color(0.86, 0.40, 0.16)
const C_TEXT := Color(0.86, 0.87, 0.90)
const DOCK_L := 230.0
const DOCK_R := 290.0
const DOCK_B := 150.0
const BAR_H := 34.0

@export var start_map: String = "Tutorial_Start"

var _grid: Node3D = null
var _camera: Camera3D = null
var _orbit_yaw := 0.7
var _orbit_pitch := 0.85
var _orbit_radius := 26.0
var _orbit_center := Vector3.ZERO
var _dragging_cam := false

var _registry: Dictionary = {}          # lookup_name -> artifact dict
var _current_map := ""
var _selected_lookup := ""
var _inter_grid: Array = []             # local interactables layer [z][x] -> token
var _dims := Vector3i.ZERO

var _map_list: ItemList
var _palette_row: HBoxContainer
var _inspector: VBoxContainer
var _title: Label
var _viewport_ctl: Control


func _ready() -> void:
	_build_world()
	_build_camera()
	_load_registry()
	_build_ui()
	_populate_maps()
	_populate_palette()
	_load_map(start_map)


# ── 3D world ──────────────────────────────────────────────────────────
func _build_world() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.09, 0.10, 0.13)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.56, 0.60)
	env.ambient_light_energy = 1.6
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -38, 0)
	sun.shadow_enabled = true
	sun.light_energy = 1.1
	add_child(sun)


func _build_camera() -> void:
	_camera = Camera3D.new()
	_camera.current = true
	add_child(_camera)
	_update_camera()


func _update_camera() -> void:
	var p := clampf(_orbit_pitch, 0.08, 1.5)
	var dir := Vector3(cos(p) * sin(_orbit_yaw), sin(p), cos(p) * cos(_orbit_yaw))
	_camera.position = _orbit_center + dir * _orbit_radius
	_camera.look_at(_orbit_center, Vector3.UP)


# ── Map load ──────────────────────────────────────────────────────────
func _load_map(map_name: String) -> void:
	if map_name == "":
		return
	if _grid and is_instance_valid(_grid):
		_grid.queue_free()
		_grid = null
	var packed := load(GRID_SCENE)
	if packed == null:
		push_error("HangarEditor: grid_system.tscn not found")
		return
	_grid = packed.instantiate()
	if "map_name" in _grid:
		_grid.map_name = map_name
	if "auto_load_map_on_ready" in _grid:
		_grid.auto_load_map_on_ready = true
	add_child(_grid)
	_current_map = map_name
	if _title:
		_title.text = "  %s" % map_name
	await get_tree().process_frame
	await get_tree().process_frame
	var dims := Vector3i(12, 1, 12)
	if _grid.has_method("get_grid_dimensions"):
		dims = _grid.get_grid_dimensions()
	var cs := 1.0
	if "cube_size" in _grid:
		cs = float(_grid.cube_size)
	_dims = dims
	_load_inter_grid()
	_orbit_center = Vector3(dims.x * 0.5 * cs, 0.0, dims.z * 0.5 * cs)
	_orbit_radius = maxf(float(dims.x), float(dims.z)) * cs * 1.15 + 9.0
	_update_camera()


func _load_inter_grid() -> void:
	# Seed the local interactables grid from the map's existing layer so Save
	# merges (rather than erases) hand-authored placements.
	_inter_grid = []
	var existing: Array = []
	var path := "%s/%s/map_data.json" % [MAPS_DIR, _current_map]
	if FileAccess.file_exists(path):
		var d = JSON.parse_string(FileAccess.get_file_as_string(path))
		if d is Dictionary and d.has("layers") and d["layers"] is Dictionary:
			var il = d["layers"].get("interactables", [])
			if il is Array:
				existing = il
	for z in range(max(_dims.z, 1)):
		var row: Array = []
		for x in range(max(_dims.x, 1)):
			var tok := " "
			if z < existing.size() and existing[z] is Array and x < existing[z].size():
				tok = str(existing[z][x])
			row.append(tok)
		_inter_grid.append(row)


# ── Registry / palette data ───────────────────────────────────────────
func _load_registry() -> void:
	var dir := DirAccess.open(REGISTRY_DIR)
	if dir == null:
		return
	for f in dir.get_files():
		if not str(f).ends_with(".json"):
			continue
		var raw := FileAccess.get_file_as_string("%s/%s" % [REGISTRY_DIR, f])
		var parsed = JSON.parse_string(raw)
		if parsed is Dictionary and parsed.has("artifacts") and parsed["artifacts"] is Dictionary:
			for k in parsed["artifacts"].keys():
				_registry[str(k)] = parsed["artifacts"][k]


func _scan_maps() -> Array:
	var out: Array = []
	var dir := DirAccess.open(MAPS_DIR)
	if dir == null:
		return out
	for sub in dir.get_directories():
		var nm := str(sub).strip_edges()
		if nm == "" or nm.begins_with("."):
			continue
		if FileAccess.file_exists("%s/%s/map_data.json" % [MAPS_DIR, nm]):
			out.append(nm)
	out.sort()
	return out


# ── UI (docks) ────────────────────────────────────────────────────────
func _panel(bg: Color) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = Color(0, 0, 0, 0.5)
	sb.set_border_width_all(1)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	p.add_theme_stylebox_override("panel", sb)
	return p


func _heading(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", C_ACCENT)
	l.add_theme_font_size_override("font_size", 12)
	return l


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	# Centre interaction surface (under the docks): camera + drops + picking.
	_viewport_ctl = Control.new()
	_viewport_ctl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_viewport_ctl.mouse_filter = Control.MOUSE_FILTER_STOP
	_viewport_ctl.gui_input.connect(_on_viewport_gui)
	_viewport_ctl.set_drag_forwarding(Callable(), _center_can_drop, _center_drop)
	layer.add_child(_viewport_ctl)

	# Top toolbar.
	var bar := _panel(C_PANEL2)
	bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	bar.offset_bottom = BAR_H
	layer.add_child(bar)
	var barbox := HBoxContainer.new()
	bar.add_child(barbox)
	var brand := Label.new()
	brand.text = "WALL HANGAR EDITOR"
	brand.add_theme_color_override("font_color", C_ACCENT)
	brand.add_theme_font_size_override("font_size", 12)
	barbox.add_child(brand)
	_title = Label.new()
	_title.add_theme_color_override("font_color", C_TEXT)
	barbox.add_child(_title)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	barbox.add_child(spacer)
	var save := Button.new()
	save.text = "Save"
	save.pressed.connect(_on_save)
	barbox.add_child(save)

	# Left dock — map selector.
	var left := _panel(C_PANEL)
	left.anchor_top = 0.0
	left.anchor_bottom = 1.0
	left.anchor_left = 0.0
	left.anchor_right = 0.0
	left.offset_top = BAR_H
	left.offset_bottom = -DOCK_B
	left.offset_left = 0.0
	left.offset_right = DOCK_L
	layer.add_child(left)
	var lv := VBoxContainer.new()
	left.add_child(lv)
	lv.add_child(_heading("MAPS"))
	_map_list = ItemList.new()
	_map_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_map_list.add_theme_color_override("font_color", C_TEXT)
	_map_list.item_selected.connect(_on_map_selected)
	lv.add_child(_map_list)

	# Right dock — inspector.
	var right := _panel(C_PANEL)
	right.anchor_top = 0.0
	right.anchor_bottom = 1.0
	right.anchor_left = 1.0
	right.anchor_right = 1.0
	right.offset_top = BAR_H
	right.offset_bottom = -DOCK_B
	right.offset_left = -DOCK_R
	right.offset_right = 0.0
	layer.add_child(right)
	_inspector = VBoxContainer.new()
	right.add_child(_inspector)
	_inspector.add_child(_heading("INSPECTOR"))
	var hint := Label.new()
	hint.text = "Select a prop in the view."
	hint.add_theme_color_override("font_color", Color(0.6, 0.62, 0.66))
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_inspector.add_child(hint)

	# Bottom dock — palette.
	var bottom := _panel(C_PANEL2)
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_top = -DOCK_B
	layer.add_child(bottom)
	var bv := VBoxContainer.new()
	bottom.add_child(bv)
	bv.add_child(_heading("PROPS & ARTIFACTS — drag up into the view"))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	bv.add_child(scroll)
	_palette_row = HBoxContainer.new()
	_palette_row.add_theme_constant_override("separation", 6)
	scroll.add_child(_palette_row)


func _populate_maps() -> void:
	_map_list.clear()
	for nm in _scan_maps():
		_map_list.add_item(nm)


func _populate_palette() -> void:
	# Station kit first (the hangar props), then the rest.
	var names := _registry.keys()
	names.sort_custom(func(a, b):
		var sa := 0 if str(a).begins_with("station") or str(a) == "curation_station" else 1
		var sb := 0 if str(b).begins_with("station") or str(b) == "curation_station" else 1
		if sa != sb:
			return sa < sb
		return str(a) < str(b))
	for lookup in names:
		_palette_row.add_child(_palette_item(str(lookup)))


func _palette_item(lookup: String) -> Control:
	var b := Button.new()
	b.custom_minimum_size = Vector2(96, 96)
	b.clip_text = true
	b.text = lookup
	b.tooltip_text = lookup
	b.add_theme_font_size_override("font_size", 10)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.20, 0.21, 0.25)
	sb.set_corner_radius_all(4)
	b.add_theme_stylebox_override("normal", sb)
	b.set_drag_forwarding(_palette_get_drag.bind(lookup), Callable(), Callable())
	b.pressed.connect(func(): _selected_lookup = lookup)
	return b


func _palette_get_drag(_at: Vector2, lookup: String) -> Variant:
	var prev := Label.new()
	prev.text = lookup
	prev.add_theme_color_override("font_color", C_ACCENT)
	set_drag_preview_safe(prev)
	return {"hangar_artifact": lookup}


func set_drag_preview_safe(ctrl: Control) -> void:
	# set_drag_preview must be called from a Control during a drag; route it
	# through the viewport control which is always present.
	if _viewport_ctl:
		_viewport_ctl.set_drag_preview(ctrl)


# ── Drag-drop placement ───────────────────────────────────────────────
func _center_can_drop(_pos: Vector2, data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY and data.has("hangar_artifact")


func _center_drop(pos: Vector2, data: Variant) -> void:
	var lookup := str(data.get("hangar_artifact", ""))
	if lookup == "":
		return
	var hit := _raycast(pos)
	if hit.is_empty():
		return
	_place(lookup, hit.position)


func _raycast(screen_pos: Vector2) -> Dictionary:
	if _camera == null:
		return {}
	var from := _camera.project_ray_origin(screen_pos)
	var dir := _camera.project_ray_normal(screen_pos)
	var space := get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(from, from + dir * 400.0)
	var hit := space.intersect_ray(q)
	if hit.is_empty():
		# Fall back to the ground plane (y=0) so empty cells still accept drops.
		if absf(dir.y) > 0.0001:
			var t := -from.y / dir.y
			if t > 0.0:
				return {"position": from + dir * t}
		return {}
	return hit


func _place(lookup: String, world_pos: Vector3) -> void:
	if _grid == null:
		return
	var cs := 1.0
	if "cube_size" in _grid:
		cs = float(_grid.cube_size)
	var gx := int(round(world_pos.x / cs))
	var gz := int(round(world_pos.z / cs))
	var inter = null
	if _grid.has_method("get_interactables_component"):
		inter = _grid.get_interactables_component()
	if inter and inter.has_method("_place_artifact"):
		inter._place_artifact(gx, 0, gz, lookup, cs)
		if gz >= 0 and gz < _inter_grid.size() and gx >= 0 and gx < _inter_grid[gz].size():
			_inter_grid[gz][gx] = lookup
		_selected_lookup = lookup
		_show_inspector(lookup, Vector3i(gx, 0, gz))
	else:
		push_warning("HangarEditor: interactables component / _place_artifact unavailable")


func _show_inspector(lookup: String, cell: Vector3i) -> void:
	for c in _inspector.get_children():
		c.queue_free()
	_inspector.add_child(_heading("INSPECTOR"))
	var meta: Dictionary = _registry.get(lookup, {})
	_insp_row("artifact", lookup)
	_insp_row("name", str(meta.get("name", lookup)))
	_insp_row("cell", "%d, %d, %d" % [cell.x, cell.y, cell.z])
	if meta.has("category"):
		_insp_row("category", str(meta["category"]))


func _insp_row(k: String, v: String) -> void:
	var row := HBoxContainer.new()
	var kl := Label.new()
	kl.text = k
	kl.custom_minimum_size = Vector2(70, 0)
	kl.add_theme_color_override("font_color", Color(0.6, 0.62, 0.66))
	kl.add_theme_font_size_override("font_size", 11)
	row.add_child(kl)
	var vl := Label.new()
	vl.text = v
	vl.add_theme_color_override("font_color", C_TEXT)
	vl.add_theme_font_size_override("font_size", 11)
	vl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(vl)
	_inspector.add_child(row)


# ── Viewport interaction (camera orbit + zoom + pick) ─────────────────
func _on_viewport_gui(ev: InputEvent) -> void:
	if ev is InputEventMouseButton:
		if ev.button_index == MOUSE_BUTTON_RIGHT:
			_dragging_cam = ev.pressed
		elif ev.button_index == MOUSE_BUTTON_WHEEL_UP:
			_orbit_radius = maxf(4.0, _orbit_radius - 2.0)
			_update_camera()
		elif ev.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_orbit_radius = minf(120.0, _orbit_radius + 2.0)
			_update_camera()
	elif ev is InputEventMouseMotion and _dragging_cam:
		_orbit_yaw -= ev.relative.x * 0.01
		_orbit_pitch = clampf(_orbit_pitch + ev.relative.y * 0.01, 0.08, 1.5)
		_update_camera()


func _on_map_selected(idx: int) -> void:
	_load_map(_map_list.get_item_text(idx))


# ── Save (non-destructive merge of the interactables layer) ───────────
func _on_save() -> void:
	if _current_map == "" or _inter_grid.is_empty():
		return
	var path := "%s/%s/map_data.json" % [MAPS_DIR, _current_map]
	if not FileAccess.file_exists(path):
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (data is Dictionary):
		return
	# Serialize the local interactables grid (non-destructive: other layers kept).
	var rows: Array = []
	var count := 0
	for z in range(_inter_grid.size()):
		var row: Array = []
		for x in range(_inter_grid[z].size()):
			var tok := str(_inter_grid[z][x]).strip_edges()
			if tok != "" and tok != " ":
				count += 1
				row.append(tok)
			else:
				row.append(" ")
		rows.append(row)
	if not (data.get("layers") is Dictionary):
		data["layers"] = {}
	data["layers"]["interactables"] = rows
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(data, "\t"))
	f.close()
	if _title:
		_title.text = "  %s  (saved %d artifacts)" % [_current_map, count]
