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
# Curated walls run along POSITIVE x (to ~92); the world backdrop + iso pan span this range so
# the iso view reaches every piece (not just the first ±20 m).
const WALL_X0 := -6.0
const WALL_X1 := 98.0
const WALL_TOP := 3.4
const PAN_SPEED := 12.0
const PAN_MIN := -4.0
const PAN_MAX := 96.0
const SAVE_PATH := "user://wall_hangar_layout.json"
const REGISTRY_DIR := "res://commons/artifacts/registry"
const MAPS_DIR := "res://commons/maps"
const NEIGHBORS_PATH := "res://commons/data/artifact_neighbors.json"
const SPINE_WALLS_PATH := "res://commons/data/spine_walls.json"
const DNA_PROPS_PATH := "res://commons/data/dna_props.json"
const CURATED_WALLS_DIR := "res://commons/data/curated_walls"
const CLUSTERS_DIR := "res://commons/data/curated_walls/clusters"
# Lookup-names that mount on the wall (everything else falls to the floor + stacks).
const WALL_SET := ["station_panel", "station_frame", "framed_readout_screen"]
# Registries treated as staging PROPS (bottom bar); everything else = artifacts (left).
const PROP_REGISTRIES := ["station", "packaging", "furniture"]

const WHPalette := preload("res://commons/scenes/wall_hangar/WHPalette.gd")
const WHInspector := preload("res://commons/scenes/wall_hangar/WHInspector.gd")
const WHStyle := preload("res://commons/scenes/wall_hangar/WHStyle.gd")
const WHHud := preload("res://commons/scenes/wall_hangar/WHHud.gd")

const C_ACCENT := Color(0.86, 0.40, 0.16)
const C_TEXT := Color(0.87, 0.88, 0.90)
const C_DIM := Color(0.60, 0.62, 0.66)

var _camera: Camera3D = null
var _pan_x := 0.0
var _free_cam := false             # false = iso front (ortho), true = free 3D orbit/fly
var _orbit_yaw := 0.6
var _orbit_pitch := 0.5
var _orbit_radius := 16.0
var _orbit_center := Vector3(0.0, 1.5, 1.0)
var _orbit_drag := false
var _lmb_press_pos := Vector2.ZERO    # click-vs-drag detection on placed pieces
var _lmb_press_piece: Node3D = null
var _lmb_dragging := false
var _placed: Array = []
var _current_map := ""           # the loaded map = the cluster name for Save-as-Cluster (K)
var _dais_h := 0.0               # dais/platform height (toggle P); recorded in the saved cluster def
var _dais_box: Node3D = null
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
var _map_filter: LineEdit = null
var _map_list: ItemList = null
var _map_index: Array = []         # [{name, seq, spine}] — spine maps (spine order) then others
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
	if _consume_cluster_handoff():   # MapToolEditor "Show in wall editor" → edit one cluster
		return
	var caps := _capture_targets()
	if not caps.is_empty():
		_run_capture(caps)   # headless batch render of curated walls -> user://wall_shots/
		return
	if OS.get_cmdline_user_args().has("--validate-props") or OS.get_cmdline_user_args().has("--validate-curated"):
		_run_validate_props()   # one plinth+artifact per held item -> user://prop_shots[_curated]/ + verdicts


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
	var wlen := WALL_X1 - WALL_X0
	var wcx := (WALL_X0 + WALL_X1) * 0.5
	add_child(_box(Vector3(wcx, -0.05, 2.0), Vector3(wlen, 0.1, 6.0), Color(0.50, 0.51, 0.55)))
	add_child(_box(Vector3(wcx, 2.0, -0.3), Vector3(wlen, 4.0, 0.6), Color(0.80, 0.79, 0.75)))
	add_child(_box(Vector3(wcx, 3.0, 0.02), Vector3(wlen, 0.05, 0.02), C_ACCENT))
	for i in range(int(WALL_X0), int(WALL_X1) + 1):
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
	_palette.offset_top = 222
	_palette.offset_bottom = -184
	layer.add_child(_palette)
	if _palette.has_method("set_wall_tokens"):
		_palette.set_wall_tokens(WALL_SET)
	if _palette.has_method("set_exclude_lookups"):
		_palette.set_exclude_lookups(_prop_lookups)   # artifacts only — the DNA props live in the bottom bar
	if _palette.has_method("set_title"):
		_palette.set_title("ARTIFACTS")
	_palette.picked.connect(_pick)
	_build_map_browser(layer)
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
	if _hud.has_signal("cam_toggle_requested"):
		_hud.cam_toggle_requested.connect(_toggle_cam)
	_build_props_bar(layer)
	_hud_depth()
	_status("ARTIFACTS left · PROPS bottom · pick one, 0-9 depth, LMB stamp · C = free 3D cam")


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
		_status("select a piece first, then G (or just drag it)")
		return
	_grab_piece(_selected)


func _grab_piece(n: Node3D) -> void:
	if n == null or not is_instance_valid(n):
		return
	_placed.erase(n)
	_deselect()
	_clear_held()
	_held = n
	_held_type = str(n.get_meta("token", ""))
	_held_is_wall = bool(n.get_meta("wall_piece", false))
	_held_moving = true
	WHStyle.dim_for_ghost(n)
	_status("moving %s — release to drop" % _held_type)


func _lmb_down() -> void:
	get_viewport().gui_release_focus()   # a click in the 3D view ends filter typing -> editor shortcuts work again
	if _held != null and is_instance_valid(_held):
		_commit()   # holding a palette piece or finishing a move -> stamp / drop
		_lmb_press_piece = null
		return
	# idle: record a potential click (select) or drag (move) on a placed piece
	_lmb_press_pos = get_viewport().get_mouse_position()
	_lmb_press_piece = _piece_under_mouse()
	_lmb_dragging = false


func _lmb_up() -> void:
	if _lmb_dragging:
		if _held != null and is_instance_valid(_held):
			_commit()   # drop the dragged piece where it rests
		_lmb_dragging = false
		_lmb_press_piece = null
		return
	# plain click (no drag): select what was under the press, else deselect
	if _lmb_press_piece != null and is_instance_valid(_lmb_press_piece):
		_selected = _lmb_press_piece
		_update_selbox()
		if _insp != null and _insp.has_method("show_node"):
			_insp.show_node(_selected)
		_show_nearby(str(_selected.get_meta("token", "")))
		_status("selected %s — edit right · nearby below · drag to move · Del remove" % str(_selected.get_meta("token", _selected.name)))
	elif _held == null:
		_deselect()
	_lmb_press_piece = null


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
	if _free_cam:
		_update_free_move(delta)
	else:
		_update_pan(delta)
	if _held != null and is_instance_valid(_held):
		var w := _mouse_on_wall_plane()
		var x := snappedf(w.x, GRID)
		if _held_is_wall:
			var y := clampf(snappedf(w.y, GRID * 0.5), 0.6, WALL_TOP)
			_held.global_position = Vector3(x, y + _dais_h, WALL_FACE_Z + 0.06)   # wall rides the dais too
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
		_pan_x = clampf(_pan_x + dx * PAN_SPEED * delta, PAN_MIN, PAN_MAX)
		_camera.position.x = _pan_x


func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton:
		var mb := ev as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_MIDDLE:
			if _free_cam:
				_orbit_drag = mb.pressed   # middle-drag orbits in free mode
			return
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_lmb_down()
			else:
				_lmb_up()
			return
		if not mb.pressed:
			return
		match mb.button_index:
			MOUSE_BUTTON_RIGHT:
				_remove_at_mouse()
			MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_LEFT:
				if _free_cam:
					_orbit_radius = maxf(2.0, _orbit_radius - 1.5)
					_update_free_cam()
				else:
					_pan(-1.0)
			MOUSE_BUTTON_WHEEL_DOWN, MOUSE_BUTTON_WHEEL_RIGHT:
				if _free_cam:
					_orbit_radius = minf(70.0, _orbit_radius + 1.5)
					_update_free_cam()
				else:
					_pan(1.0)
	elif ev is InputEventMouseMotion:
		var mm := ev as InputEventMouseMotion
		if _free_cam and _orbit_drag:
			_orbit_yaw -= mm.relative.x * 0.01
			_orbit_pitch = clampf(_orbit_pitch + mm.relative.y * 0.01, -1.45, 1.45)
			_update_free_cam()
		elif _held == null and _lmb_press_piece != null and not _lmb_dragging:
			if mm.position.distance_to(_lmb_press_pos) > 6.0:
				_grab_piece(_lmb_press_piece)   # drag past threshold -> pick it up
				_lmb_dragging = true
	elif ev is InputEventKey and ev.pressed and not ev.echo:
		if get_viewport().gui_get_focus_owner() is LineEdit:
			return   # typing in a filter — don't fire editor shortcuts (C/K/P/G/0-9…)
		var kc: int = (ev as InputEventKey).keycode
		if kc >= KEY_0 and kc <= KEY_9:
			_depth_level = kc - KEY_0
			_apply_depth_to_selected()
			_hud_depth()
		elif kc == KEY_C:
			_toggle_cam()
		elif kc == KEY_G:
			_grab_selected()
		elif kc == KEY_H:
			if _hud != null and _hud.has_method("toggle_help"):
				_hud.toggle_help()
		elif kc == KEY_P:
			_toggle_dais()
		elif kc == KEY_K:
			_save_as_cluster()
		elif kc == KEY_DELETE or kc == KEY_BACKSPACE:
			_delete_selected()
		elif kc == KEY_ESCAPE:
			if _held != null:
				_clear_held()
				_status("dropped")
			else:
				_deselect()


func _pan(dir: float) -> void:
	_pan_x = clampf(_pan_x + dir, PAN_MIN, PAN_MAX)
	_camera.position.x = _pan_x


func _toggle_cam() -> void:
	_free_cam = not _free_cam
	if _hud != null and _hud.has_method("set_cam_mode"):
		_hud.set_cam_mode(_free_cam)
	if _free_cam:
		_camera.projection = Camera3D.PROJECTION_PERSPECTIVE
		_camera.fov = 60.0
		_orbit_center = Vector3(_pan_x, 1.5, 1.0)
		_orbit_drag = false
		_update_free_cam()
		_status("FREE 3D camera — MIDDLE-drag orbit · wheel zoom · WASD/QE fly · C = iso")
	else:
		_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		_camera.size = 7.0
		_camera.rotation_degrees = Vector3(-9, 0, 0)
		_camera.position = Vector3(_pan_x, 2.1, 9.0)
		_status("ISO front camera — A/D · ←→ · wheel scroll · C = free 3D")


func _update_free_cam() -> void:
	var p := clampf(_orbit_pitch, -1.45, 1.45)
	var dir := Vector3(cos(p) * sin(_orbit_yaw), sin(p), cos(p) * cos(_orbit_yaw))
	_camera.position = _orbit_center + dir * _orbit_radius
	_camera.look_at(_orbit_center, Vector3.UP)


func _update_free_move(delta: float) -> void:
	var move := Vector3.ZERO
	if Input.is_key_pressed(KEY_W):
		move -= _flat(_camera.global_transform.basis.z)
	if Input.is_key_pressed(KEY_S):
		move += _flat(_camera.global_transform.basis.z)
	if Input.is_key_pressed(KEY_D):
		move += _flat(_camera.global_transform.basis.x)
	if Input.is_key_pressed(KEY_A):
		move -= _flat(_camera.global_transform.basis.x)
	if Input.is_key_pressed(KEY_E):
		move += Vector3.UP
	if Input.is_key_pressed(KEY_Q):
		move += Vector3.DOWN
	if move != Vector3.ZERO:
		_orbit_center += move.normalized() * 7.0 * delta
		_update_free_cam()


func _flat(v: Vector3) -> Vector3:
	v.y = 0.0
	return v.normalized() if v.length() > 0.01 else Vector3.ZERO


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
		# Transformless nodes (mutator artifacts like GridColorizer) have no global_position;
		# fall back to origin so saving a layout that contains one can't crash.
		var p: Vector3 = (n as Node3D).global_position if n is Node3D else Vector3.ZERO
		arr.append({
			"token": str(n.get_meta("token", "")),
			"x": p.x, "y": p.y, "z": p.z,
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
	_dais_h = 0.0
	if _dais_box != null and is_instance_valid(_dais_box):
		_dais_box.queue_free()
	_dais_box = null
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
	var top := _dais_h   # the dais is the floor: bare-cell pieces sit on it, stacks ride higher (no double-count)
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


func _world_aabb(n: Node) -> AABB:
	# Accept any Node, not just Node3D: mutator artifacts (e.g. GridColorizer) load as a
	# plain Node with no transform. The stack-walk below only measures VisualInstance3D
	# children, so a transformless node yields an empty AABB and every caller skips it
	# via its `box.size.y <= 0.001` guard.
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
func _build_map_browser(layer: CanvasLayer) -> void:
	_build_map_index()
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	panel.offset_left = 8
	panel.offset_top = 46
	panel.offset_right = 340
	panel.offset_bottom = 214
	panel.add_theme_stylebox_override("panel", WHStyle.panel_box())
	layer.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	panel.add_child(vb)
	var head := Label.new()
	head.text = "MAP"
	head.add_theme_color_override("font_color", C_ACCENT)
	head.add_theme_font_size_override("font_size", 12)
	vb.add_child(head)
	_map_filter = LineEdit.new()
	_map_filter.placeholder_text = "find a map…"
	_map_filter.clear_button_enabled = true
	_map_filter.add_theme_color_override("font_color", C_TEXT)
	_map_filter.text_changed.connect(func(_t): _refresh_map_list())
	vb.add_child(_map_filter)
	_map_list = ItemList.new()
	_map_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_map_list.add_theme_color_override("font_color", C_TEXT)
	_map_list.add_theme_font_size_override("font_size", 12)
	_map_list.item_selected.connect(_on_map_item)
	vb.add_child(_map_list)
	_refresh_map_list()


func _build_map_index() -> void:
	# Spine maps first (in spine_walls key order = curriculum order); every other map
	# on disk alphabetically last.
	_map_index = []
	var added: Dictionary = {}
	for k in _spine_walls.keys():
		var entry: Variant = _spine_walls[k]
		var seq := ""
		if entry is Dictionary:
			seq = str(entry.get("sequence", ""))
		_map_index.append({"name": str(k), "seq": seq, "spine": true})
		added[str(k)] = true
	var others: Array = []
	var dir := DirAccess.open(MAPS_DIR)
	if dir != null:
		for sub in dir.get_directories():
			var nm := str(sub).strip_edges()
			if nm == "" or nm.begins_with(".") or added.has(nm):
				continue
			if FileAccess.file_exists("%s/%s/map_data.json" % [MAPS_DIR, nm]):
				others.append(nm)
	others.sort()
	for nm in others:
		_map_index.append({"name": nm, "seq": "", "spine": false})


func _refresh_map_list() -> void:
	if _map_list == null:
		return
	_map_list.clear()
	var needle := ""
	if _map_filter != null:
		needle = _map_filter.text.strip_edges().to_lower()
	for m in _map_index:
		var nm := str(m["name"])
		var seq := str(m["seq"])
		if needle != "" and not (nm.to_lower().contains(needle) or seq.to_lower().contains(needle)):
			continue
		var label := ""
		if bool(m["spine"]):
			label = "%s   (%s)" % [nm, seq]
		else:
			label = "%s   · off-spine" % nm
		var idx := _map_list.add_item(label)
		_map_list.set_item_metadata(idx, nm)
		if not bool(m["spine"]):
			_map_list.set_item_custom_fg_color(idx, C_DIM)


func _on_map_item(idx: int) -> void:
	_load_map_by_name(str(_map_list.get_item_metadata(idx)))


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


func _load_map_by_name(mapname: String) -> void:
	if mapname == "":
		return
	if _spine_walls.has(mapname):
		var entry: Variant = _spine_walls[mapname]
		if entry is Dictionary:
			var pieces: Variant = entry.get("pieces", [])
			if pieces is Array:
				_current_seq = str(entry.get("sequence", ""))
				_load_wall(pieces)
				_current_map = mapname   # commit only after a load actually succeeds — K saves under this name
				_status("loaded %s — %d pieces" % [mapname, pieces.size()])
	else:
		_load_raw_map(mapname)


func _load_raw_map(mapname: String) -> void:
	# Off-spine map: no curated wall — stage its raw artifacts on plinths so you can see + curate.
	var path := "%s/%s/map_data.json" % [MAPS_DIR, mapname]
	if not FileAccess.file_exists(path):
		_status("no map_data for %s" % mapname)
		return
	var d = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (d is Dictionary):
		return
	var inter: Variant = []
	var layers: Variant = d.get("layers", {})
	if layers is Dictionary:
		inter = layers.get("interactables", [])
	var lookups: Array = []
	var seen: Dictionary = {}
	if inter is Array:
		for r in inter:
			if r is Array:
				for cell in r:
					var tk := str(cell).strip_edges()
					if tk == "" or tk == " ":
						continue
					tk = tk.split(":")[0].split("#")[0].strip_edges()
					if _scene_map.has(tk) and not seen.has(tk):
						seen[tk] = true
						lookups.append(tk)
	var pieces: Array = [{"token": "station_panel", "x": 0.0, "y": 1.8, "z": 0.06, "wall": true}]
	var i := 0
	for tk in lookups:
		var x := 1.0 + float(i) * 2.0
		pieces.append({"token": "station_plinth", "x": x, "y": 0.0, "z": 0.8, "wall": false})
		pieces.append({"token": str(tk), "x": x, "y": 1.0, "z": 0.8, "wall": false})
		i += 1
	_current_seq = ""
	_load_wall(pieces)
	_current_map = mapname   # commit only after a successful load
	_status("loaded %s (off-spine, %d raw artifacts — not curated)" % [mapname, lookups.size()])


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
		_clean_loaded(n)   # hide artifacts' floating Label3D + embedded UI/cameras
		if bool(n.get_meta("wall_piece", false)):
			continue
		if str(n.get_meta("token", "")).begins_with("station_"):
			continue   # a staging prop, not the content artifact
		var box := _world_aabb(n)
		if box.size.y <= 0.001:
			continue
		# R-019 body_on_cell: seat by the measured BODY, not the code origin — centre the
		# visible AABB on the requested cell before the vertical seat, so every artifact
		# lands centred on its cap. (The meet is between what you SEE and what holds it.)
		var gp: Vector3 = n.global_position
		var dx: float = gp.x - (box.position.x + box.size.x * 0.5)
		var dz: float = gp.z - (box.position.z + box.size.z * 0.5)
		if absf(dx) > 0.003 and absf(dx) < 3.0:
			gp.x += dx
		if absf(dz) > 0.003 and absf(dz) < 3.0:
			gp.z += dz
		n.global_position = gp
		box = _world_aabb(n)
		var target := _stack_top(n.global_position.x, n.global_position.z, n)
		var shift := target - box.position.y
		if absf(shift) > 0.003 and absf(shift) < 6.0:
			gp = n.global_position
			gp.y += shift
			n.global_position = gp


func _clean_loaded(n: Node) -> void:
	# Strip a loaded artifact's floating chrome so the only label is its station plate
	# (2D-in-3D): hide billboard Label3D, embedded screen-space CanvasLayer UI, and any
	# artifact-owned Camera3D that would steal the view.
	for c in n.get_children():
		if c is Label3D:
			(c as Label3D).visible = false
		elif c is CanvasLayer:
			(c as CanvasLayer).visible = false
		elif c is Camera3D:
			(c as Camera3D).current = false
		_clean_loaded(c)


# ── Headless wall capture ─────────────────────────────────────────────
# Run:  Godot --path . --no-window --xr-mode off res://commons/scenes/desktop_wall_hangar_editor.tscn -- --capture-all
#       (or --capture=<MapName> for one). Writes user://wall_shots/<Map>.png.
func _capture_targets() -> Array:
	var one := ""
	var all := false
	var clusters := false
	for a in OS.get_cmdline_user_args():
		if a == "--capture-all":
			all = true
		elif a == "--capture-clusters":
			clusters = true   # the auto-curated concept walls under curated_walls/clusters/
		elif a == "--capture-props":
			return ["_NewProps"]   # code-built showcase of the new station prop kinds
		elif a.begins_with("--capture="):
			one = a.substr(a.find("=") + 1)
	if one != "":
		return [one]
	if clusters:
		return _list_json_basenames(CLUSTERS_DIR)
	if all:
		return _list_json_basenames(CURATED_WALLS_DIR)
	return []


func _list_json_basenames(dir_path: String) -> Array:
	var out: Array = []
	var d := DirAccess.open(dir_path)
	if d:
		for f in d.get_files():
			if str(f).ends_with(".json"):
				out.append(str(f).get_basename())
	out.sort()
	return out


func _capture_extent(pieces: Array) -> Vector2:
	# X span of the FLOOR pieces (the wall itself spans the whole hall, so ignore it).
	var lo := INF
	var hi := -INF
	for p in pieces:
		if p is Dictionary and not bool(p.get("wall", false)):
			var x := float(p.get("x", 0.0))
			lo = minf(lo, x)
			hi = maxf(hi, x)
	if lo == INF:
		return Vector2(0.0, 10.0)
	return Vector2(lo, hi)


func _run_capture(targets: Array) -> void:
	# Hide the editor chrome so only the wall renders.
	for c in get_children():
		if c is CanvasLayer:
			(c as CanvasLayer).visible = false
	_camera.keep_aspect = Camera3D.KEEP_WIDTH   # fit the whole (wide) wall horizontally
	_camera.rotation_degrees = Vector3(-8, 0, 0)  # slight tilt so the staggered depth reads
	const W := 2400
	DirAccess.make_dir_recursive_absolute("user://wall_shots")
	var done := 0
	for mapname in targets:
		var pieces: Array
		var ext: Vector2
		if mapname == "_NewProps":
			pieces = _prop_showcase_pieces()       # the five new prop kinds, laid out in code
			ext = Vector2(2.0, 36.0)
		elif _spine_walls.has(mapname):
			pieces = (_spine_walls[mapname] as Dictionary).get("pieces", [])
			ext = Vector2.ZERO
		else:
			# Not a spine wall — maybe an auto-curated cluster (curated_walls/clusters/<name>.json).
			var cpath := "%s/%s.json" % [CLUSTERS_DIR, mapname]
			if not FileAccess.file_exists(cpath):
				print("CAPTURE skip (no wall): ", mapname)
				continue
			var cd: Variant = JSON.parse_string(FileAccess.get_file_as_string(cpath))
			if not (cd is Dictionary) or not (cd as Dictionary).has("pieces"):
				print("CAPTURE skip (bad cluster): ", mapname)
				continue
			pieces = (cd as Dictionary)["pieces"]
			ext = Vector2.ZERO
		_load_wall(pieces)
		for _i in range(72):   # deferred geometry + _settle_loaded (40f) + margin
			await get_tree().process_frame
		if mapname != "_NewProps":
			ext = _capture_extent(pieces)
		var cx: float = (ext.x + ext.y) * 0.5
		var ww: float = maxf(ext.y - ext.x + 3.0, 6.0)
		var h: int = clampi(int(round(float(W) * 5.0 / ww)), 320, 1000)  # ~5 m vertical, any wall length
		get_window().size = Vector2i(W, h)
		_camera.size = ww
		_camera.position = Vector3(cx, 2.3, 14.0)
		for _i in range(3):
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		var path := "user://wall_shots/%s.png" % mapname
		img.save_png(path)
		done += 1
		print("CAPTURE wrote ", path, "  ", W, "x", h)
	print("CAPTURE done: ", done, "/", targets.size())
	get_tree().quit()


func _run_validate_props() -> void:
	# One plinth + one artifact, isolated and front-on, so each ATOM can be checked for the
	# right form: is the artifact present at all, and does it sit ON the cap (not sunk in,
	# not floating)? Uses the SAME load+settle the walls use, then measures the result —
	# settle skips artifacts that measure ~0 at frame 40, which is exactly how they end up
	# missing or embedded. Writes a PNG + a verdict per held artifact.
	for c in get_children():
		if c is CanvasLayer:
			(c as CanvasLayer).visible = false
	_camera.keep_aspect = Camera3D.KEEP_HEIGHT
	_camera.rotation_degrees = Vector3(-6, 0, 0)
	_camera.size = 3.2
	const W := 900
	const H := 1100
	get_window().size = Vector2i(W, H)
	var curated := OS.get_cmdline_user_args().has("--validate-curated")
	var outdir := "user://prop_shots_curated" if curated else "user://prop_shots"
	DirAccess.make_dir_recursive_absolute(outdir)
	var pairs := (_gather_curated_pairs() if curated else _gather_validation_pairs())
	var report: Array = []
	for pair in pairs:
		var art: String = pair["art"]
		var top_h: float = float((pair["config"] as Dictionary).get("top_height", 1.2))
		var pieces: Array = [
			{"token": pair["plinth_token"], "x": 0.0, "y": 0.0, "z": 0.0, "wall": false, "config": pair["config"]},
			{"token": art, "x": 0.0, "y": top_h, "z": 0.0, "wall": false},
		]
		_load_wall(pieces)   # _settle re-seats at frame 40
		for _i in range(54):
			await get_tree().process_frame
		var art_node: Node3D = null
		for n in _placed:
			if is_instance_valid(n) and n is Node3D and not str(n.get_meta("token", "")).begins_with("station_"):
				art_node = n
		var box1: AABB = _world_aabb(art_node) if art_node != null else AABB()
		var present := box1.size.x > 0.001 or box1.size.y > 0.001 or box1.size.z > 0.001   # flat quads have ~0 height but still render
		var base_y: float = box1.position.y
		var cap_top: float = top_h
		var art_w := 0.0
		var cap_w: float = float((pair["config"] as Dictionary).get("cap_meters", 0.0))
		if present and art_node != null:
			art_w = maxf(box1.size.x, box1.size.z)   # footprint the cap must cover (early, post-settle)
			cap_top = _stack_top(0.0, 0.0, art_node)
		_camera.position = Vector3(0.0, cap_top + 0.4, 6.0)
		for _i in range(3):
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		img.save_png("%s/%s.png" % [outdir, art])
		for _i in range(40):   # measure AGAIN later: an animating artifact (grows over time) can't seat on a static cap
			await get_tree().process_frame
		var box2: AABB = _world_aabb(art_node) if art_node != null else AABB()
		var stable := absf(maxf(box2.size.x, box2.size.z) - maxf(box1.size.x, box1.size.z)) < 0.25 and absf(box2.size.y - box1.size.y) < 0.5
		var gap := base_y - cap_top
		var verdict := "missing"
		if present:
			if not stable:
				verdict = "animating"            # grows over time -> no stable form for a static plinth
			elif gap < -0.06:
				verdict = "embedded"
			elif gap > 0.08:
				verdict = "floating"
			else:
				verdict = "ok"
		var fit := true   # footprint fits the cap (horizontal), independent of seating
		if cap_w > 0.0 and art_w > 0.0:
			fit = art_w <= cap_w + 0.06
		report.append({
			"artifact": art, "plinth": pair["plinth_token"], "present": present, "stable": stable,
			"base_y": snappedf(base_y, 0.01), "cap_top": snappedf(cap_top, 0.01),
			"gap": snappedf(gap, 0.01), "verdict": verdict,
			"art_w": snappedf(art_w, 0.01), "cap_w": snappedf(cap_w, 0.01), "fit": fit,
		})
		var rf := FileAccess.open("%s/_report.json" % outdir, FileAccess.WRITE)   # incremental: crash-safe over a long run
		if rf:
			rf.store_string(JSON.stringify(report, "\t"))
			rf.close()
		print("VALIDATE ", art, " -> ", verdict, "  gap=", snappedf(gap, 0.01), "  stable=", stable, "  fit=", fit)
	print("VALIDATE done: ", report.size(), " props")
	get_tree().quit()


func _gather_validation_pairs() -> Array:
	# Each held artifact across the auto-curated clusters, paired with the plinth it rides
	# (first occurrence wins) — the faithful wall atom: same plinth token + cap config.
	var pairs: Array = []
	var seen := {}
	var dir := DirAccess.open(CLUSTERS_DIR)
	if dir == null:
		return pairs
	var files := dir.get_files()
	files.sort()
	for fn in files:
		if not str(fn).ends_with(".json"):
			continue
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string("%s/%s" % [CLUSTERS_DIR, fn]))
		if not (data is Dictionary):
			continue
		if not ("auto by lay_necklace" in str((data as Dictionary).get("source", ""))):
			continue
		var pieces: Array = (data as Dictionary).get("pieces", [])
		var plinth_at := {}   # "x_z" -> plinth piece
		for p in pieces:
			var tok := str((p as Dictionary).get("token", ""))
			if tok.begins_with("station_plinth") or tok == "station_micropod":
				plinth_at["%.1f_%.1f" % [float((p as Dictionary).get("x", 0.0)), float((p as Dictionary).get("z", 0.0))]] = p
		for p in pieces:
			var tok := str((p as Dictionary).get("token", ""))
			if tok.begins_with("station_"):
				continue
			if seen.has(tok):
				continue
			seen[tok] = true
			var key := "%.1f_%.1f" % [float((p as Dictionary).get("x", 0.0)), float((p as Dictionary).get("z", 0.0))]
			var plinth: Dictionary = plinth_at.get(key, {})
			pairs.append({
				"art": tok,
				"plinth_token": str(plinth.get("token", "station_plinth")),
				"config": plinth.get("config", {}),
			})
	return pairs


func _gather_curated_pairs() -> Array:
	# Each plinth/micropod-HELD artifact across the hand-curated forces+fractals spine walls
	# (first placement wins). Stage-mounted walk-in WORLDS are skipped — seating is a held question.
	var pairs: Array = []
	var seen := {}
	for mapname in _spine_walls.keys():
		var entry: Dictionary = _spine_walls[mapname]
		if not (str(entry.get("sequence", "")) in ["forces", "fractals"]):
			continue
		var pieces: Array = entry.get("pieces", [])
		var plinth_at := {}
		for p in pieces:
			var tok := str((p as Dictionary).get("token", ""))
			if tok.begins_with("station_plinth") or tok == "station_micropod":
				plinth_at["%.1f_%.1f" % [float((p as Dictionary).get("x", 0.0)), float((p as Dictionary).get("z", 0.0))]] = p
		for p in pieces:
			var tok := str((p as Dictionary).get("token", ""))
			if tok.begins_with("station_") or bool((p as Dictionary).get("wall", false)):
				continue
			if seen.has(tok):
				continue
			var key := "%.1f_%.1f" % [float((p as Dictionary).get("x", 0.0)), float((p as Dictionary).get("z", 0.0))]
			if not plinth_at.has(key):
				continue   # not on a plinth/micropod (a stage world, or unmounted) -> not a held seating question
			seen[tok] = true
			var plinth: Dictionary = plinth_at[key]
			pairs.append({
				"art": tok,
				"plinth_token": str(plinth.get("token", "station_plinth")),
				"config": plinth.get("config", {}),
			})
	return pairs


func _prop_showcase_pieces() -> Array:
	# The five NEW prop kinds laid out in a row with a header panel over each, for --capture-props.
	return [
		{"token": "station_luminaire", "x": 4.0, "y": 0.0, "z": 1.1, "wall": false,
			"config": {"mode": "task", "height": 2.3, "arm_reach": 0.9, "intensity": 7.0}},
		{"token": "station_panel", "x": 4.0, "y": 2.6, "z": 0.06, "wall": true,
			"config": {"width_cells": 2, "header": "LUMINAIRE", "lines": ["LIGHT"]}},
		{"token": "station_floorline", "x": 9.5, "y": 0.0, "z": 1.3, "wall": false,
			"config": {"style": "path", "direction": 1, "length_cells": 3, "width": 0.45}},
		{"token": "station_panel", "x": 9.5, "y": 2.6, "z": 0.06, "wall": true,
			"config": {"width_cells": 2, "header": "FLOORLINE", "lines": ["THE FLOOR, MADE TO POINT"]}},
		{"token": "station_skydome", "x": 15.0, "y": 0.0, "z": 0.6, "wall": false,
			"config": {"mode": "gradient", "width_cells": 3, "height": 2.7, "depth_offset": 0.3,
				"top_color": "0.10,0.13,0.27,1", "bottom_color": "0.46,0.52,0.66,1"}},
		{"token": "station_panel", "x": 15.0, "y": 2.6, "z": 0.06, "wall": true,
			"config": {"width_cells": 2, "header": "SKYDOME", "lines": ["ATMOSPHERE"]}},
		{"token": "station_ascent", "x": 20.5, "y": 0.0, "z": 1.0, "wall": false,
			"config": {"style": "stair", "rise": 1.4, "width": 1.2, "handrail": true}},
		{"token": "station_panel", "x": 20.5, "y": 2.6, "z": 0.06, "wall": true,
			"config": {"width_cells": 2, "header": "ASCENT", "lines": ["PASSAGE"]}},
		{"token": "station_multiscreen", "x": 26.0, "y": 1.45, "z": 0.06, "wall": true,
			"config": {"rows": 2, "cols": 2, "header": "MULTISCREEN",
				"cell_labels": ["QUANTUM", "FRACTAL", "EMERGENT", "EDGE"]}},
	]


# ── Cluster sandbox: dais toggle (P) + Save-as-Cluster (K) ─────────────
func _toggle_dais() -> void:
	# Raise/lower the whole curated cluster onto a 1 m platform so you author it on its dais (WYSIWYG).
	# The height is recorded in the saved cluster def; the map re-applies it as raised grid structure.
	var new_h := 0.0 if _dais_h > 0.0 else 1.0
	var delta := new_h - _dais_h
	_dais_h = new_h
	for n in _placed:
		if is_instance_valid(n) and n is Node3D:
			(n as Node3D).global_position.y += delta
	_rebuild_dais()
	_status("dais %s" % ("ON — 1 m preview; realised as raised map structure on placement" if _dais_h > 0.0 else "off"))


func _rebuild_dais() -> void:
	if _dais_box != null and is_instance_valid(_dais_box):
		_dais_box.queue_free()
	_dais_box = null
	if _dais_h <= 0.0:
		return
	var lo_x := INF
	var hi_x := -INF
	var lo_z := INF
	var hi_z := -INF
	for n in _placed:
		if not is_instance_valid(n):
			continue
		var p: Vector3 = (n as Node3D).global_position   # all pieces, incl. the wall, so the dais covers it
		lo_x = minf(lo_x, p.x)
		hi_x = maxf(hi_x, p.x)
		lo_z = minf(lo_z, p.z)
		hi_z = maxf(hi_z, p.z)
	if lo_x == INF:
		return
	var cx := (lo_x + hi_x) * 0.5
	var cz := (lo_z + hi_z) * 0.5 + 0.3
	var w := (hi_x - lo_x) + 3.0
	var d := (hi_z - lo_z) + 2.2
	_dais_box = _box(Vector3(cx, _dais_h * 0.5, cz), Vector3(w, _dais_h, d), Color(0.52, 0.53, 0.58))
	add_child(_dais_box)


func _save_as_cluster() -> void:
	# Export the curated pieces as a portable CLUSTER def to clusters/<map>.json — the unit a
	# cluster:<name> map token rebuilds. Pieces are stored floor-relative (dais-stripped); "dais" is
	# recorded as a HINT for the map: the platform is realised as raised grid structure under the
	# cluster cell (see Proto_Fractal_Recursion), which the cluster then auto-sits on via find_highest_y_at.
	if _placed.is_empty():
		_status("nothing to save as cluster")
		return
	var lo_x := INF
	for n in _placed:
		if is_instance_valid(n):
			lo_x = minf(lo_x, (n as Node3D).global_position.x)
	if lo_x == INF:
		lo_x = 0.0
	var shift_x := 1.5 - lo_x   # normalise so the cluster reads from ~x=1.5 out (anchor-relative)
	var arr: Array = []
	for n in _placed:
		if not is_instance_valid(n):
			continue
		var cfg: Dictionary = {}
		for m in n.get_meta_list():
			var ms := str(m)
			if ms.begins_with("config_"):
				cfg[ms.substr(7)] = n.get_meta(m)
		var gp: Vector3 = (n as Node3D).global_position
		arr.append({
			"token": str(n.get_meta("token", "")),
			"x": snappedf(gp.x + shift_x, 0.01),
			"y": snappedf(gp.y - _dais_h, 0.01),   # store dais-agnostic; the dais height is its own field
			"z": snappedf(gp.z, 0.01),
			"wall": bool(n.get_meta("wall_piece", false)),
			"config": cfg,
		})
	var cname := _current_map.to_lower() if _current_map != "" else "cluster"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CLUSTERS_DIR))
	var path := "%s/%s.json" % [CLUSTERS_DIR, cname]
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({"name": cname, "dais": _dais_h, "pieces": arr}, "\t"))
		f.close()
		_status("saved cluster '%s' — %d pieces, dais %.0f m  →  clusters/%s.json" % [cname, arr.size(), _dais_h, cname])
	else:
		_status("could not write clusters/%s.json" % cname)


# MapToolEditor "Show in wall editor" handoff: a one-shot cluster name in user://wall_editor_cluster.txt.
# Load that cluster (clusters/<name>.json — same pieces[] format K saves) for front-elevation editing,
# and set _current_map so a K save writes straight back to the same cluster file.
func _consume_cluster_handoff() -> bool:
	var path := "user://wall_editor_cluster.txt"
	if not FileAccess.file_exists(path):
		return false
	var cname := FileAccess.get_file_as_string(path).strip_edges()
	var f := FileAccess.open(path, FileAccess.WRITE)   # clear (one-shot)
	if f:
		f.store_string("")
		f.close()
	if cname == "":
		return false
	var cpath := "%s/%s.json" % [CLUSTERS_DIR, cname]
	if not FileAccess.file_exists(cpath):
		_status("cluster not found: clusters/%s.json" % cname)
		return false
	var d = JSON.parse_string(FileAccess.get_file_as_string(cpath))
	if not (d is Dictionary) or not (d.get("pieces") is Array):
		_status("bad cluster JSON: %s" % cname)
		return false
	_current_map = cname   # K (_save_as_cluster) writes back to clusters/<cname>.json
	_load_wall(d["pieces"])
	_status("editing cluster '%s' — %d pieces (K saves back)" % [cname, (d["pieces"] as Array).size()])
	return true
