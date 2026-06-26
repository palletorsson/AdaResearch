extends Node3D
## Isometric / front-elevation WALL HANGAR editor.
##
## You see the wall FACE-ON (orthographic), scroll only LEFT/RIGHT, and stamp station
## pieces that snap with two gravities + a depth dimension:
##   · WALL pieces (panels/signs) mount on the wall face at the cursor height.
##   · FLOOR pieces drop to the floor and STACK on whatever shares their cell footprint.
##   · NUMBER KEYS 0-9 set how far OUT FROM THE WALL a floor piece sits (depth layer).
##
## Controls
##   pick a palette piece (bottom)        a ghost follows the mouse
##   LMB                                  stamp it / (when not holding) SELECT a piece
##   0-9                                  depth out from the wall (held or selected piece)
##   G                                    grab the selected piece to move it
##   Del / Backspace                      delete the selected piece
##   RMB                                  delete the piece under the mouse
##   A/D · ←/→ · mouse-wheel              scroll the wall
##   Esc                                  drop / deselect
##
## No player, no mouse-capture — pure 2D-style editing.

const GRID := 1.0
const WALL_FACE_Z := 0.0        # wall pieces mount here (face toward +Z viewer)
const DEPTH_STEP := 0.7         # metres out from the wall per number-key level
const WALL_LEN := 48.0
const WALL_TOP := 3.4           # highest wall-mount height
const PAN_SPEED := 12.0
const PAN_LIMIT := 20.0

const STATION := {
	"station_panel": "res://commons/artifacts/station/station_panel.tscn",
	"station_plinth": "res://commons/artifacts/station/station_plinth.tscn",
	"station_pillar": "res://commons/artifacts/station/station_pillar.tscn",
	"station_stage": "res://commons/artifacts/station/station_stage.tscn",
	"station_cabinet": "res://commons/artifacts/station/station_cabinet.tscn",
	"station_barrier": "res://commons/artifacts/station/station_barrier.tscn",
	"station_bench": "res://commons/artifacts/station/station_bench.tscn",
	"station_crates": "res://commons/artifacts/station/station_crates.tscn",
}
const WALL_SET := ["station_panel"]

const C_PANEL := Color(0.11, 0.12, 0.15, 0.96)
const C_ACCENT := Color(0.86, 0.40, 0.16)
const C_TEXT := Color(0.87, 0.88, 0.90)
const C_DIM := Color(0.6, 0.62, 0.66)

var _camera: Camera3D = null
var _pan_x := 0.0
var _placed: Array = []
var _held: Node3D = null
var _held_type := ""
var _held_is_wall := false
var _held_moving := false       # held piece was picked up (not a fresh palette stamp)
var _depth_level := 1
var _selected: Node3D = null
var _sel_box: MeshInstance3D = null
var _status: Label = null
var _inspector: VBoxContainer = null


func _ready() -> void:
	_build_world()
	_build_camera()
	_build_ui()


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


# ── UI ────────────────────────────────────────────────────────────────
func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	var hint := Label.new()
	hint.position = Vector2(14, 10)
	hint.add_theme_color_override("font_color", C_TEXT)
	hint.add_theme_font_size_override("font_size", 13)
	hint.text = "WALL HANGAR (front)  ·  LMB stamp/select · 0-9 depth · G move · Del remove · RMB remove · A/D·wheel scroll"
	layer.add_child(hint)
	_status = Label.new()
	_status.position = Vector2(14, 32)
	_status.add_theme_color_override("font_color", C_ACCENT)
	_status.add_theme_font_size_override("font_size", 12)
	layer.add_child(_status)

	# Inspector (top-right).
	var insp := PanelContainer.new()
	insp.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	insp.offset_left = -246
	insp.offset_top = 54
	insp.offset_right = -12
	insp.offset_bottom = 230
	var isb := StyleBoxFlat.new()
	isb.bg_color = C_PANEL
	isb.set_corner_radius_all(6)
	isb.set_content_margin_all(12)
	insp.add_theme_stylebox_override("panel", isb)
	layer.add_child(insp)
	_inspector = VBoxContainer.new()
	insp.add_child(_inspector)
	_update_inspector()

	# Palette (bottom).
	var bar := PanelContainer.new()
	bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bar.offset_top = -60
	var sb := StyleBoxFlat.new()
	sb.bg_color = C_PANEL
	sb.set_content_margin_all(8)
	bar.add_theme_stylebox_override("panel", sb)
	layer.add_child(bar)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	bar.add_child(row)
	for token in STATION.keys():
		var b := Button.new()
		var is_wall: bool = token in WALL_SET
		b.text = ("◰ " if is_wall else "▣ ") + str(token).replace("station_", "")
		b.tooltip_text = "%s (%s)" % [token, "wall-mount" if is_wall else "floor + stack"]
		b.custom_minimum_size = Vector2(118, 40)
		b.pressed.connect(_pick.bind(str(token)))
		row.add_child(b)


func _heading(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", C_ACCENT)
	l.add_theme_font_size_override("font_size", 13)
	return l


func _row(k: String, v: String) -> HBoxContainer:
	var r := HBoxContainer.new()
	var kl := Label.new()
	kl.text = k
	kl.custom_minimum_size = Vector2(74, 0)
	kl.add_theme_color_override("font_color", C_DIM)
	kl.add_theme_font_size_override("font_size", 12)
	r.add_child(kl)
	var vl := Label.new()
	vl.text = v
	vl.add_theme_color_override("font_color", C_TEXT)
	vl.add_theme_font_size_override("font_size", 12)
	r.add_child(vl)
	return r


func _update_inspector() -> void:
	if _inspector == null:
		return
	for c in _inspector.get_children():
		c.queue_free()
	_inspector.add_child(_heading("INSPECTOR"))
	var focus: Node3D = _held if (_held != null and is_instance_valid(_held)) else _selected
	if focus == null or not is_instance_valid(focus):
		var l := Label.new()
		l.text = "nothing selected"
		l.add_theme_color_override("font_color", C_DIM)
		_inspector.add_child(l)
		_inspector.add_child(_row("depth", "%d  (%.1f m)" % [_depth_level, _depth_level * DEPTH_STEP]))
		return
	var token := str(focus.get_meta("token", focus.name))
	var is_wall := bool(focus.get_meta("wall_piece", false))
	var box := _world_aabb(focus)
	_inspector.add_child(_row("mode", "held" if focus == _held else "selected"))
	_inspector.add_child(_row("piece", token))
	_inspector.add_child(_row("gravity", "wall" if is_wall else "floor"))
	_inspector.add_child(_row("cell x", "%d" % roundi(focus.global_position.x)))
	if is_wall:
		_inspector.add_child(_row("height", "%.2f m" % focus.global_position.y))
	else:
		_inspector.add_child(_row("depth", "%d  (%.1f m)" % [_depth_level, focus.global_position.z]))
		_inspector.add_child(_row("base y", "%.2f m" % box.position.y))
	_inspector.add_child(_row("size", "%.1f×%.1f×%.1f" % [box.size.x, box.size.y, box.size.z]))


# ── Pick / stamp / select / grab ──────────────────────────────────────
func _pick(token: String) -> void:
	_clear_held()
	_deselect()
	_spawn_held(token, false)
	_set_status("holding %s — move to aim, 0-9 depth, LMB to stamp" % token)


func _spawn_held(token: String, moving: bool) -> void:
	var path: String = STATION.get(token, "")
	if path == "" or not ResourceLoader.exists(path):
		_set_status("missing: %s" % token)
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


func _clear_held() -> void:
	if _held != null and is_instance_valid(_held):
		_held.queue_free()
	_held = null
	_held_moving = false


func _commit() -> void:
	if _held == null or not is_instance_valid(_held):
		return
	_held.set_meta("placed", true)
	_placed.append(_held)
	var t := _held_type
	var was_moving := _held_moving
	_held = null
	if was_moving:
		_held_moving = false
		_set_status("placed")
	else:
		_spawn_held(t, false)   # keep stamping the same piece


func _select_at_mouse() -> void:
	var n := _piece_under_mouse()
	if n != null:
		_selected = n
		_update_selbox()
		_update_inspector()
		_set_status("selected %s — 0-9 depth · G move · Del remove" % str(n.get_meta("token", n.name)))
	else:
		_deselect()


func _grab_selected() -> void:
	if _selected == null or not is_instance_valid(_selected):
		_set_status("select a piece first, then G")
		return
	var n := _selected
	_placed.erase(n)
	_deselect()
	_clear_held()
	_held = n
	_held_type = str(n.get_meta("token", ""))
	_held_is_wall = bool(n.get_meta("wall_piece", false))
	_held_moving = true
	_set_status("moving %s — LMB to drop" % _held_type)


func _delete_selected() -> void:
	if _selected != null and is_instance_valid(_selected):
		_placed.erase(_selected)
		_selected.queue_free()
		_deselect()
		_set_status("deleted")


func _remove_at_mouse() -> void:
	var n := _piece_under_mouse()
	if n != null:
		if n == _selected:
			_deselect()
		_placed.erase(n)
		n.queue_free()
		_set_status("removed")


func _deselect() -> void:
	_selected = null
	if _sel_box != null:
		_sel_box.visible = false
	_update_inspector()


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
		_update_inspector()


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
			_update_inspector()
		elif kc == KEY_G:
			_grab_selected()
		elif kc == KEY_DELETE or kc == KEY_BACKSPACE:
			_delete_selected()
		elif kc == KEY_ESCAPE:
			if _held != null:
				_clear_held()
				_set_status("dropped")
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
	# Highest top among FLOOR pieces whose X+Z footprint covers (x,z); 0 = floor.
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
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 0.16)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		_sel_box.material_override = m
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


func _set_status(msg: String) -> void:
	if _status != null:
		_status.text = msg
