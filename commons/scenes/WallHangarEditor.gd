extends Node3D
## Isometric / front-elevation WALL HANGAR editor.
##
## You see the wall FACE-ON (orthographic), scroll only LEFT/RIGHT, and stamp ANY
## registered prop/artifact (filterable palette) that snaps with two gravities + depth:
##   · WALL pieces mount on the wall face at the cursor height.
##   · FLOOR pieces drop to the floor and STACK on whatever shares their cell footprint.
##   · NUMBER KEYS 0-9 set how far OUT FROM THE WALL a floor piece sits (depth layer).
## Select a piece to edit its DNA live in the inspector; G moves, Del removes; Save/Load.
##
## UI is four composable parts (commons/scenes/wall_hangar/): WHPalette (all props +
## filter), WHInspector (editable DNA), WHHud (toolbar + help + status), WHStyle (theme
## + ghost/selection visuals). This host owns placement + wires them together.

const GRID := 1.0
const WALL_FACE_Z := 0.0
const DEPTH_STEP := 0.7
const WALL_LEN := 48.0
const WALL_TOP := 3.4
const PAN_SPEED := 12.0
const PAN_LIMIT := 20.0
const SAVE_PATH := "user://wall_hangar_layout.json"
const REGISTRY_DIR := "res://commons/artifacts/registry"
const NEIGHBORS_PATH := "res://commons/data/artifact_neighbors.json"
const SPINE_WALLS_PATH := "res://commons/data/spine_walls.json"
const DNA_PROPS_PATH := "res://commons/data/dna_props.json"
# Lookup-names that mount on the wall (everything else falls to the floor + stacks).
const WALL_SET := ["station_panel", "station_frame", "framed_readout_screen"]
# Registries treated as staging PROPS (bottom bar); everything else = artifacts (left).
const PROP_REGISTRIES := ["station", "packaging", "furniture"]

const WHPalette := preload("res://commons/scenes/wall_hangar/WHPalette.gd")
const WHInspector := preload("res://commons/scenes/wall_hangar/WHInspector.gd")
const WHStyle := preload("res://commons/scenes/wall_hangar/WHStyle.gd")
const WHHud := preload("res://commons/scenes/wall_hangar/WHHud.gd")

const C_ACCENT := Color(0.86, 0.40, 0.16)

var _camera: Camera3D = null
var _pan_x := 0.0
var _placed: Array = []
var _held: Node3D = null
var _held_type := ""
var _held_is_wall := false
var _held_moving := false
var _depth_level := 1
var _selected: Node3D = null
var _sel_box: MeshInstance3D = null
var _scene_map: Dictionary = {}    # lookup_name -> scene path (all registries)
var _dna_props: Array = []         # canonical prop lookups (props-dna-gallery, no workbenches)
var _prop_lookups: Array = []      # _dna_props that have a scene here (the bottom bar)
var _props_filter: LineEdit = null
var _props_flow: HFlowContainer = null
var _palette: PanelContainer = null
var _insp: PanelContainer = null
var _hud: Control = null
var _neighbors: Dictionary = {}    # lookup -> [{id, name, sim}, ...]
var _spine_walls: Dictionary = {}  # MapName -> {sequence, small_count, pieces}
var _map_select: OptionButton = null
var _nearby_list: VBoxContainer = null
var _nearby_head: Label = null
var _artifact_seq: Dictionary = {}    # content lookup -> its spine sequence (nearby weighting)
var _current_seq: String = ""         # sequence of the currently loaded map


func _ready() -> void:
	_build_scene_map()
	_load_data()
	_build_world()
	_build_camera()
	_build_ui()


func _load_data() -> void:
	if FileAccess.file_exists(NEIGHBORS_PATH):
		var d = JSON.parse_string(FileAccess.get_file_as_string(NEIGHBORS_PATH))
		if d is Dictionary:
			_neighbors = d
	if FileAccess.file_exists(SPINE_WALLS_PATH):
		var d = JSON.parse_string(FileAccess.get_file_as_string(SPINE_WALLS_PATH))
		if d is Dictionary:
			_spine_walls = d
	# Map each spine small-item -> its sequence, for in-domain nearby weighting.
	for mapname in _spine_walls.keys():
		var entry: Variant = _spine_walls[mapname]
		if not (entry is Dictionary):
			continue
		var seq := str(entry.get("sequence", ""))
		var ps: Variant = entry.get("pieces", [])
		if ps is Array:
			for p in ps:
				if p is Dictionary:
					var tk := str(p.get("token", ""))
					if not tk.begins_with("station_") and not _artifact_seq.has(tk):
						_artifact_seq[tk] = seq
	# Canonical prop set (props-dna-gallery, workbenches excluded) -> the bottom bar.
	if FileAccess.file_exists(DNA_PROPS_PATH):
		var dp = JSON.parse_string(FileAccess.get_file_as_string(DNA_PROPS_PATH))
		if dp is Dictionary and dp.get("props") is Array:
			_dna_props = dp["props"]
	_prop_lookups = []
	for p in _dna_props:
		if _scene_map.has(str(p)):
			_prop_lookups.append(str(p))


func _build_scene_map() -> void:
	var dir := DirAccess.open(REGISTRY_DIR)
	if dir == null:
		return
	for f in dir.get_files():
		if not str(f).ends_with(".json"):
			continue
		var d = JSON.parse_string(FileAccess.get_file_as_string("%s/%s" % [REGISTRY_DIR, f]))
		var table = d
		if d is Dictionary and d.has("artifacts") and d["artifacts"] is Dictionary:
			table = d["artifacts"]
		if table is Dictionary:
			for k in table.keys():
				var e = table[k]
				if e is Dictionary and e.has("scene"):
					var lookup := str(e.get("lookup_name", k))
					_scene_map[lookup] = str(e["scene"])


# ── World (floor + long wall) ─────────────────────────────────────────
func _build_world() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.13, 0.14, 0.17)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.63, 0.68)
	env.ambient_light_energy = 1.5
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-46, -22, 0)
	sun.light_energy = 1.0
	sun.shadow_enabled = true
	add_child(sun)
	add_child(_box(Vector3(0, -0.05, 2.0), Vector3(WALL_LEN, 0.1, 6.0), Color(0.50, 0.51, 0.55)))
	add_child(_box(Vector3(0, 2.0, -0.3), Vector3(WALL_LEN, 4.0, 0.6), Color(0.80, 0.79, 0.75)))
	add_child(_box(Vector3(0, 3.0, 0.02), Vector3(WALL_LEN, 0.05, 0.02), C_ACCENT))
	for i in range(int(-WALL_LEN * 0.5), int(WALL_LEN * 0.5) + 1):
		add_child(_box(Vector3(float(i), 0.005, 2.0), Vector3(0.02, 0.01, 6.0), Color(0.42, 0.43, 0.47)))


func _box(center: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var m := BoxMesh.new()
	m.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = m
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	mi.material_override = mat
	mi.position = center
	return mi


func _build_camera() -> void:
	_camera = Camera3D.new()
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.size = 7.0
	_camera.position = Vector3(0.0, 2.1, 9.0)
	_camera.rotation_degrees = Vector3(-9, 0, 0)
	_camera.current = true
	add_child(_camera)


# ── UI — the four composed parts ──────────────────────────────────────
func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	_palette = WHPalette.new()
	_palette.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	_palette.offset_left = 8
	_palette.offset_right = 340
	_palette.offset_top = 86
	_palette.offset_bottom = -184
	layer.add_child(_palette)
	if _palette.has_method("set_wall_tokens"):
		_palette.set_wall_tokens(WALL_SET)
	if _palette.has_method("set_exclude_lookups"):
		_palette.set_exclude_lookups(_prop_lookups)   # artifacts only — the DNA props live in the bottom bar
	if _palette.has_method("set_title"):
		_palette.set_title("ARTIFACTS")
	_palette.picked.connect(_pick)
	_build_map_select(layer)
	_build_nearby(layer)

	_insp = WHInspector.new()
	_insp.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_insp.offset_left = -290
	_insp.offset_right = -8
	_insp.offset_top = 50
	_insp.offset_bottom = 470
	layer.add_child(_insp)
	if _insp.has_method("clear"):
		_insp.clear()
	if _insp.has_signal("rebuilt"):
		_insp.rebuilt.connect(_on_insp_rebuilt)

	_hud = WHHud.new()
	layer.add_child(_hud)
	if _hud.has_signal("save_requested"):
		_hud.save_requested.connect(_on_save)
	if _hud.has_signal("load_requested"):
		_hud.load_requested.connect(_on_load)
	if _hud.has_signal("clear_requested"):
		_hud.clear_requested.connect(_on_clear)
	_build_props_bar(layer)
	_hud_depth()
	_status("ARTIFACTS left · PROPS bottom — pick one, 0-9 depth, LMB to stamp")


func _build_props_bar(layer: CanvasLayer) -> void:
	var bar := PanelContainer.new()
	bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bar.offset_top = -178   # tall enough for ~4-5 wrapped rows + the filter
	bar.add_theme_stylebox_override("panel", WHStyle.toolbar_box())
	layer.add_child(bar)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 5)
	bar.add_child(vb)
	var headrow := HBoxContainer.new()
	headrow.add_theme_constant_override("separation", 10)
	vb.add_child(headrow)
	var head := Label.new()
	head.text = "PROPS"
	head.add_theme_color_override("font_color", C_ACCENT)
	head.add_theme_font_size_override("font_size", 12)
	headrow.add_child(head)
	_props_filter = LineEdit.new()
	_props_filter.placeholder_text = "filter props…"
	_props_filter.clear_button_enabled = true
	_props_filter.custom_minimum_size = Vector2(240, 0)
	_props_filter.text_changed.connect(func(_t): _refresh_props_bar())
	headrow.add_child(_props_filter)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(scroll)
	_props_flow = HFlowContainer.new()
	_props_flow.add_theme_constant_override("h_separation", 5)
	_props_flow.add_theme_constant_override("v_separation", 5)
	_props_flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_props_flow)
	_refresh_props_bar()


func _refresh_props_bar() -> void:
	if _props_flow == null:
		return
	for c in _props_flow.get_children():
		c.queue_free()
	var needle := ""
	if _props_filter != null:
		needle = _props_filter.text.strip_edges().to_lower()
	for lookup in _prop_lookups:
		if needle != "" and not str(lookup).to_lower().contains(needle):
			continue
		var b := Button.new()
		var is_wall: bool = lookup in WALL_SET
		b.text = ("◰ " if is_wall else "") + str(lookup).replace("station_", "").replace("hangar_", "")
		b.tooltip_text = str(lookup)
		b.custom_minimum_size = Vector2(120, 30)
		b.clip_text = true
		WHStyle.style_button(b)
		b.pressed.connect(_pick.bind(str(lookup)))
		_props_flow.add_child(b)


# ── Pick / stamp / select / grab ──────────────────────────────────────
func _pick(token: String) -> void:
	_clear_held()
	_deselect()
	_spawn_held(token, false)
	_status("holding %s — 0-9 depth, LMB to stamp" % token)


func _spawn_held(token: String, moving: bool) -> void:
	var path: String = _scene_map.get(token, "")
	if path == "" or not ResourceLoader.exists(path):
		_status("no scene for: %s" % token)
		return
	var packed = load(path)
	if packed == null:
		return
	_held_type = token
	_held_is_wall = token in WALL_SET
	_held_moving = moving
	_held = packed.instantiate()
	_held.set_meta("token", token)
	_held.set_meta("wall_piece", _held_is_wall)
	add_child(_held)
	call_deferred("_ghostify", _held)


func _ghostify(n: Node3D) -> void:
	if n != null and is_instance_valid(n) and n == _held:
		WHStyle.dim_for_ghost(n)


func _clear_held() -> void:
	if _held != null and is_instance_valid(_held):
		_held.queue_free()
	_held = null
	_held_moving = false


func _commit() -> void:
	if _held == null or not is_instance_valid(_held):
		return
	WHStyle.undim(_held)
	_held.set_meta("placed", true)
	_placed.append(_held)
	var t := _held_type
	var was_moving := _held_moving
	_held = null
	if was_moving:
		_held_moving = false
		_status("placed")
	else:
		_spawn_held(t, false)


func _select_at_mouse() -> void:
	var n := _piece_under_mouse()
	if n != null:
		_selected = n
		_update_selbox()
		if _insp != null and _insp.has_method("show_node"):
			_insp.show_node(n)
		_show_nearby(str(n.get_meta("token", "")))
		_status("selected %s — edit right · nearby below · G move · Del remove" % str(n.get_meta("token", n.name)))
	else:
		_deselect()


func _grab_selected() -> void:
	if _selected == null or not is_instance_valid(_selected):
		_status("select a piece first, then G")
		return
	var n := _selected
	_placed.erase(n)
	_deselect()
	_clear_held()
	_held = n
	_held_type = str(n.get_meta("token", ""))
	_held_is_wall = bool(n.get_meta("wall_piece", false))
	_held_moving = true
	WHStyle.dim_for_ghost(n)
	_status("moving %s — LMB to drop" % _held_type)


func _delete_selected() -> void:
	if _selected != null and is_instance_valid(_selected):
		_placed.erase(_selected)
		_selected.queue_free()
		_deselect()
		_status("deleted")


func _remove_at_mouse() -> void:
	var n := _piece_under_mouse()
	if n != null:
		if n == _selected:
			_deselect()
		_placed.erase(n)
		n.queue_free()
		_status("removed")


func _deselect() -> void:
	_selected = null
	if _sel_box != null:
		_sel_box.visible = false
	if _insp != null and _insp.has_method("clear"):
		_insp.clear()
	_show_nearby("")


func _on_insp_rebuilt(node: Node3D) -> void:
	# apply_grid_config freed+rebuilt the node's children — re-fit the highlight.
	if node == _selected and is_instance_valid(node):
		await get_tree().process_frame
		_update_selbox()


# ── Per-frame: pan + ghost follow with depth + two-gravity snap ────────
func _process(delta: float) -> void:
	_update_pan(delta)
	if _held != null and is_instance_valid(_held):
		var w := _mouse_on_wall_plane()
		var x := snappedf(w.x, GRID)
		if _held_is_wall:
			var y := clampf(snappedf(w.y, GRID * 0.5), 0.6, WALL_TOP)
			_held.global_position = Vector3(x, y, WALL_FACE_Z + 0.06)
		else:
			var z := _depth_z()
			_held.global_position = Vector3(x, _stack_top(x, z, _held), z)


func _depth_z() -> float:
	return WALL_FACE_Z + 0.1 + float(_depth_level) * DEPTH_STEP


func _update_pan(delta: float) -> void:
	var dx := 0.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		dx -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		dx += 1.0
	if dx != 0.0:
		_pan_x = clampf(_pan_x + dx * PAN_SPEED * delta, -PAN_LIMIT, PAN_LIMIT)
		_camera.position.x = _pan_x


func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed:
		match (ev as InputEventMouseButton).button_index:
			MOUSE_BUTTON_LEFT:
				if _held != null and is_instance_valid(_held):
					_commit()
				else:
					_select_at_mouse()
			MOUSE_BUTTON_RIGHT:
				_remove_at_mouse()
			MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_LEFT:
				_pan(-1.0)
			MOUSE_BUTTON_WHEEL_DOWN, MOUSE_BUTTON_WHEEL_RIGHT:
				_pan(1.0)
	elif ev is InputEventKey and ev.pressed and not ev.echo:
		var kc: int = (ev as InputEventKey).keycode
		if kc >= KEY_0 and kc <= KEY_9:
			_depth_level = kc - KEY_0
			_apply_depth_to_selected()
			_hud_depth()
		elif kc == KEY_G:
			_grab_selected()
		elif kc == KEY_H:
			if _hud != null and _hud.has_method("toggle_help"):
				_hud.toggle_help()
		elif kc == KEY_DELETE or kc == KEY_BACKSPACE:
			_delete_selected()
		elif kc == KEY_ESCAPE:
			if _held != null:
				_clear_held()
				_status("dropped")
			else:
				_deselect()


func _pan(dir: float) -> void:
	_pan_x = clampf(_pan_x + dir, -PAN_LIMIT, PAN_LIMIT)
	_camera.position.x = _pan_x


func _apply_depth_to_selected() -> void:
	if _selected == null or not is_instance_valid(_selected):
		return
	if bool(_selected.get_meta("wall_piece", false)):
		return
	var p := _selected.global_position
	var z := _depth_z()
	_selected.global_position = Vector3(p.x, _stack_top(p.x, z, _selected), z)
	_update_selbox()


# ── Save / load / clear ───────────────────────────────────────────────
func _on_save() -> void:
	var arr: Array = []
	for n in _placed:
		if not is_instance_valid(n):
			continue
		var cfg: Dictionary = {}
		for m in n.get_meta_list():
			var ms := str(m)
			if ms.begins_with("config_"):
				cfg[ms.substr(7)] = n.get_meta(m)   # DNA edits (apply_grid_config metas)
		arr.append({
			"token": str(n.get_meta("token", "")),
			"x": n.global_position.x, "y": n.global_position.y, "z": n.global_position.z,
			"wall": bool(n.get_meta("wall_piece", false)),
			"config": cfg,
		})
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({"pieces": arr}, "\t"))
		f.close()
		_status("saved %d pieces" % arr.size())


func _on_load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		_status("no saved layout")
		return
	var d = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if not (d is Dictionary):
		return
	var pieces: Array = d.get("pieces", [])
	_load_wall(pieces)
	_status("loaded %d pieces" % pieces.size())


func _on_clear() -> void:
	_deselect()
	for n in _placed:
		if is_instance_valid(n):
			n.queue_free()
	_placed.clear()
	_status("cleared")


# ── Geometry helpers ──────────────────────────────────────────────────
func _mouse_on_wall_plane() -> Vector3:
	var mouse := get_viewport().get_mouse_position()
	var from := _camera.project_ray_origin(mouse)
	var dir := _camera.project_ray_normal(mouse)
	if absf(dir.z) > 0.0001:
		var t := (WALL_FACE_Z - from.z) / dir.z
		if t > 0.0:
			return from + dir * t
	return Vector3(from.x, from.y, WALL_FACE_Z)


func _piece_under_mouse() -> Node3D:
	var mouse := get_viewport().get_mouse_position()
	var best: Node3D = null
	var best_d := 75.0
	for n in _placed:
		if not is_instance_valid(n) or n == _held:
			continue
		var box := _world_aabb(n)
		if box.size.y <= 0.001:
			continue
		var d := _camera.unproject_position(box.get_center()).distance_to(mouse)
		if d < best_d:
			best_d = d
			best = n
	return best


func _stack_top(x: float, z: float, exclude: Node3D) -> float:
	var top := 0.0
	for n in _placed:
		if n == exclude or not is_instance_valid(n):
			continue
		if bool(n.get_meta("wall_piece", false)):
			continue
		var box := _world_aabb(n)
		if box.size.y <= 0.001:
			continue
		var cx := box.position.x + box.size.x * 0.5
		var cz := box.position.z + box.size.z * 0.5
		if absf(x - cx) <= box.size.x * 0.5 + 0.05 and absf(z - cz) <= box.size.z * 0.5 + 0.05:
			top = maxf(top, box.position.y + box.size.y)
	return top


func _update_selbox() -> void:
	if _selected == null or not is_instance_valid(_selected):
		if _sel_box != null:
			_sel_box.visible = false
		return
	var box := _world_aabb(_selected)
	if box.size.y <= 0.001:
		if _sel_box != null:
			_sel_box.visible = false
		return
	if _sel_box == null:
		_sel_box = MeshInstance3D.new()
		_sel_box.mesh = BoxMesh.new()
		_sel_box.material_override = WHStyle.selection_material()
		add_child(_sel_box)
	(_sel_box.mesh as BoxMesh).size = box.size + Vector3(0.14, 0.14, 0.14)
	_sel_box.global_position = box.get_center()
	_sel_box.visible = true


func _world_aabb(n: Node3D) -> AABB:
	var box := AABB()
	var found := false
	var stack: Array = [n]
	while not stack.is_empty():
		var node = stack.pop_back()
		for ch in node.get_children():
			stack.append(ch)
		if node is VisualInstance3D and not (node is GPUParticles3D) and (node as VisualInstance3D).is_visible_in_tree():
			var gb: AABB = (node as VisualInstance3D).global_transform * (node as VisualInstance3D).get_aabb()
			if not found:
				box = gb
				found = true
			else:
				box = box.merge(gb)
	return box if found else AABB()


func _hud_depth() -> void:
	if _hud != null and _hud.has_method("set_depth"):
		_hud.set_depth(_depth_level)


func _status(msg: String) -> void:
	if _hud != null and _hud.has_method("set_status"):
		_hud.set_status(msg)


# ── Spine-wall loading + ontological neighbours ───────────────────────
func _build_map_select(layer: CanvasLayer) -> void:
	var row := HBoxContainer.new()
	row.position = Vector2(12, 48)
	row.add_theme_constant_override("separation", 6)
	layer.add_child(row)
	var lbl := Label.new()
	lbl.text = "MAP"
	lbl.add_theme_color_override("font_color", C_ACCENT)
	lbl.add_theme_font_size_override("font_size", 12)
	row.add_child(lbl)
	_map_select = OptionButton.new()
	_map_select.custom_minimum_size = Vector2(300, 28)
	WHStyle.style_button(_map_select)
	_map_select.add_item("— load a spine map's wall —", 0)
	# Natural key order = curriculum/spine order (the generator wrote maps sequence-by-
	# sequence, in lesson order, and Godot preserves JSON key order). Group by sequence
	# with separator headers, like the spine / slash editors.
	var last_seq := ""
	for k in _spine_walls.keys():
		var entry: Variant = _spine_walls[k]
		var seq := ""
		if entry is Dictionary:
			seq = str(entry.get("sequence", ""))
		if seq != last_seq:
			_map_select.add_separator(seq)
			last_seq = seq
		_map_select.add_item(str(k))
		_map_select.set_item_metadata(_map_select.item_count - 1, str(k))
	_map_select.item_selected.connect(_on_map_picked)
	row.add_child(_map_select)


func _build_nearby(layer: CanvasLayer) -> void:
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	panel.offset_left = -290
	panel.offset_right = -8
	panel.offset_top = 482
	panel.offset_bottom = -184
	panel.add_theme_stylebox_override("panel", WHStyle.panel_box())
	layer.add_child(panel)
	var vb := VBoxContainer.new()
	panel.add_child(vb)
	_nearby_head = Label.new()
	_nearby_head.text = "NEARBY"
	_nearby_head.add_theme_color_override("font_color", C_ACCENT)
	_nearby_head.add_theme_font_size_override("font_size", 13)
	vb.add_child(_nearby_head)
	var hint := Label.new()
	hint.text = "select an artifact to see kin to add"
	hint.add_theme_color_override("font_color", Color(0.58, 0.60, 0.64))
	hint.add_theme_font_size_override("font_size", 11)
	vb.add_child(hint)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(scroll)
	_nearby_list = VBoxContainer.new()
	_nearby_list.add_theme_constant_override("separation", 3)
	_nearby_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_nearby_list)


func _show_nearby(token: String) -> void:
	if _nearby_list == null:
		return
	for c in _nearby_list.get_children():
		c.queue_free()
	# Partition placeable kin by whether they share the loaded map's sequence —
	# in-domain (★, accent) first, then the rest, each group kept in similarity order.
	var same: Array = []
	var other: Array = []
	var list: Variant = _neighbors.get(token, [])
	if list is Array:
		for nb in list:
			if not (nb is Dictionary):
				continue
			var id := str(nb.get("id", ""))
			if not _scene_map.has(id):
				continue   # only kin we can actually place
			if _current_seq != "" and str(_artifact_seq.get(id, "")) == _current_seq:
				same.append(nb)
			else:
				other.append(nb)
	var ordered: Array = same + other
	for nb in ordered:
		var id := str(nb.get("id", ""))
		var in_seq: bool = _current_seq != "" and str(_artifact_seq.get(id, "")) == _current_seq
		var b := Button.new()
		b.text = ("★ " if in_seq else "+ ") + ("%s  ·  %.2f" % [str(nb.get("name", id)), float(nb.get("sim", 0.0))])
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.clip_text = true
		var tip := id
		if in_seq:
			tip += "   (in " + _current_seq + ")"
		b.tooltip_text = tip
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		WHStyle.style_button(b)
		if in_seq:
			b.add_theme_color_override("font_color", C_ACCENT)
		b.pressed.connect(_pick.bind(id))
		_nearby_list.add_child(b)
	if _nearby_head != null:
		if token == "":
			_nearby_head.text = "NEARBY"
		elif same.size() > 0:
			_nearby_head.text = "NEARBY (%d · ★%d in seq)" % [ordered.size(), same.size()]
		else:
			_nearby_head.text = "NEARBY (%d)" % ordered.size()


func _on_map_picked(idx: int) -> void:
	if idx <= 0 or _map_select == null:
		return
	var mapname := str(_map_select.get_item_metadata(idx))
	var entry: Variant = _spine_walls.get(mapname, {})
	if not (entry is Dictionary):
		return
	var pieces: Variant = entry.get("pieces", [])
	if not (pieces is Array):
		return
	_current_seq = str(entry.get("sequence", ""))
	_load_wall(pieces)
	_status("loaded %s — %d pieces (%d small)" % [mapname, pieces.size(), int(entry.get("small_count", 0))])


func _load_wall(pieces: Array) -> void:
	_on_clear()
	for item in pieces:
		if not (item is Dictionary):
			continue
		var token := str(item.get("token", ""))
		var path: String = _scene_map.get(token, "")
		if path == "" or not ResourceLoader.exists(path):
			continue
		var inst: Node = load(path).instantiate()
		inst.set_meta("token", token)
		inst.set_meta("wall_piece", bool(item.get("wall", false)))
		add_child(inst)
		if inst is Node3D:
			(inst as Node3D).global_position = Vector3(item.get("x", 0.0), item.get("y", 0.0), item.get("z", 0.0))
		var cfg: Variant = item.get("config", {})
		if cfg is Dictionary and not (cfg as Dictionary).is_empty() and inst.has_method("apply_grid_config"):
			inst.apply_grid_config(cfg)   # size plinths/stages to the artifact's footprint
		_placed.append(inst)
	call_deferred("_settle_loaded")


func _settle_loaded() -> void:
	# Let the deferred-built geometry settle, then re-seat each CONTENT artifact onto
	# the plinth beneath it at its REAL measured height (the generator used a fixed
	# 1.0 m plinth-top guess, so tall/short small items sat a touch off).
	for _i in range(40):
		await get_tree().process_frame
	for n in _placed:
		if not is_instance_valid(n):
			continue
		if bool(n.get_meta("wall_piece", false)):
			continue
		if str(n.get_meta("token", "")).begins_with("station_"):
			continue   # a staging prop, not the content artifact
		var box := _world_aabb(n)
		if box.size.y <= 0.001:
			continue
		var target := _stack_top(n.global_position.x, n.global_position.z, n)
		var shift := target - box.position.y
		if absf(shift) > 0.003 and absf(shift) < 6.0:
			var gp: Vector3 = n.global_position
			gp.y += shift
			n.global_position = gp
