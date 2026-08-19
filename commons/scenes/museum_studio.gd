extends Node3D
## MUSEUM STUDIO — edit one pearl of the endless museum from above, fast.
##
## Palle, 2026-08-19: "Tweaking the position of artifacts in endless_museum
## works fine but we need a more fast and powerful tool … like
## MapStudioDesktop3D but for the endless corridor." So: the museum's OWN
## assembler builds one pearl exactly as the walk builds it (studio mode: no
## walker, no streaming, no gate), a top-down orthographic camera shows the
## whole hall as a floor plan, and every edit is a PLAN ROW — written by
## tools/em_plan_write.py (the one writer, ints stay ints), then the hall is
## rebuilt from the plan so what you see is what the plan says. Bake one
## pearl in ~15 s, walk it from here.
##
##   click            select (nearest body)      drag           move (cell snap; Ctrl = 0.2 m)
##   R / Shift+R      rotate +90 / -90           Alt+R          rotate +15
##   + / -            scale                      P              plinth on/off (support 0.95)
##   C                cycle the token's first DNA axis            Delete   remove
##   palette click, then click a cell → place    Z / Y          undo / redo
##   G                walk-map overlay           O              orbit view / top view
##   wheel            zoom                        MMB drag / arrows   pan
##   B                bake this pearl             W              walk it (endless_museum.tscn)
##   F                frame the hall
##
## KINDS (slice 2): bodies (plan rows) · plinths, benches, props, showings
## (the plan row's DRESSING rules: offset / rotation / remove / text) · DNA
## wall variants (wall_runs: nudge along the wall, drop / restore a value).
## Left-drag on empty ground rotates the iso view; middle-drag pans.

const MUSEUM_SCENE := "res://commons/scenes/endless_museum.tscn"
const PLAN := "res://ada_run/em_plan.json"
const EM_CONTROL := "res://ada_run/em_control.json"
const VESTIBULE_H := 4
const PICK_PX := 26.0

var _museum: Node3D = null
var _cam: Camera3D
var _hud: CanvasLayer
var _chapter_opt: OptionButton
var _pearl_opt: OptionButton
var _status: Label
var _sel_label: Label
var _refused_label: Label
var _palette: ItemList
var _search: LineEdit
var _hint: Label
var _overlay: MeshInstance3D = null
var _marks: Node3D = null            # one label + ring per body, so the plan reads at any zoom

var _plan: Dictionary = {}
var _chapters: Array = []          # [{chapter, pearls:[{pearl, map, index}]}]
var _chapter: String = "primitives"
var _pearl: String = ""
var _map: String = ""

var _sel: Dictionary = {}          # the selected record (from the museum's _edit_records)
var _sel_key: String = ""          # "token|x|y" to reselect after a rebuild
var _drag: bool = false
var _drag_moved: bool = false
var _drag_start_pos: Vector3 = Vector3.ZERO
var _placing: String = ""          # a palette token waiting for a cell
var _orbit: bool = false
var _iso: bool = false               # I: orthographic isometric — heights visible, grid still exact
var _iso_yaw: float = -2.356           # from the south-west, the walk going up-right
var _iso_pitch: float = 0.85           # radians above the horizon
var _config_edit: LineEdit
var _orbit_yaw: float = 0.6
var _orbit_pitch: float = -0.9
var _pan_drag: bool = false
var _orbit_drag: bool = false          # left-drag on empty ground: turn the iso view
var _busy: bool = false
var _undo: Array = []              # snapshots of the pearl's artifacts list
var _redo: Array = []
var _show_overlay: bool = true
var _cam_target: Vector3 = Vector3(7.5, 0, 15)
var _cam_size: float = 40.0
var _all_tokens: Array = []


func _ready() -> void:
	_cam = Camera3D.new()
	_cam.name = "StudioCamera"
	_cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	_cam.size = _cam_size
	_cam.far = 400.0
	add_child(_cam)
	_cam.current = true
	# the studio's own light: no fog, no DOF, no glow — a drawing, not a photograph
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.16, 0.16, 0.18)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.9, 0.9, 0.92)
	env.ambient_light_energy = 0.45
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 0.9
	_cam.environment = env
	# the museum's WorldEnvironment carries CameraAttributes with a far DOF at 26 m
	# and auto exposure — from 60 m up that is a blur and a bloom. The studio's own:
	var ca := CameraAttributesPractical.new()
	ca.dof_blur_far_enabled = false
	ca.dof_blur_near_enabled = false
	ca.auto_exposure_enabled = false
	ca.exposure_multiplier = 0.55
	_cam.attributes = ca
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-70, 30, 0)
	sun.light_energy = 0.35
	sun.shadow_enabled = false
	add_child(sun)
	_build_hud()
	_load_plan()
	_fill_chapters()
	var args: PackedStringArray = OS.get_cmdline_user_args()
	for a in args:
		if String(a).begins_with("--em-chapter="):
			_chapter = String(a).substr(13)
		elif String(a).begins_with("--em-pearl="):
			_pearl = String(a).substr(11)
	_select_chapter(_chapter)
	if _pearl == "" and not _pearls_of(_chapter).is_empty():
		_pearl = String((_pearls_of(_chapter)[0] as Dictionary).get("pearl", ""))
	_open_pearl(_chapter, _pearl)


# ── plan ────────────────────────────────────────────────────────────────────
func _load_plan() -> void:
	var path: String = PLAN if FileAccess.file_exists(PLAN) else "res://commons/data/museum/em_plan.json"
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	_plan = parsed if parsed is Dictionary else {}
	_chapters = []
	var by: Dictionary = {}
	for p in _plan.get("plans", []):
		var pd: Dictionary = p
		var ch: String = String(pd.get("sequence", ""))
		if not by.has(ch):
			by[ch] = {"chapter": ch, "pearls": []}
			_chapters.append(by[ch])
		if pd.has("pearl"):
			(by[ch]["pearls"] as Array).append({"pearl": String(pd.get("pearl", "")), "map": String(pd.get("map", "")),
				"index": int(pd.get("pearl_index", 0)), "rooms": int(pd.get("rooms", 0)),
				"bodies": (pd.get("artifacts", []) as Array).size()})
	for c in _chapters:
		(c["pearls"] as Array).sort_custom(func(a, b): return int(a["index"]) < int(b["index"]))
	# every token the plan knows, for the palette's search
	var seen: Dictionary = {}
	for p in _plan.get("plans", []):
		for a in (p as Dictionary).get("artifacts", []):
			seen[String((a as Dictionary).get("token", ""))] = true
	_all_tokens = seen.keys()
	_all_tokens.sort()

func _pearls_of(ch: String) -> Array:
	for c in _chapters:
		if String(c["chapter"]) == ch:
			return c["pearls"]
	return []

func _row() -> Dictionary:
	for p in _plan.get("plans", []):
		var pd: Dictionary = p
		if String(pd.get("sequence", "")) == _chapter and String(pd.get("pearl", "")) == _pearl:
			return pd
	return {}


# ── HUD ─────────────────────────────────────────────────────────────────────
func _build_hud() -> void:
	_hud = CanvasLayer.new()
	add_child(_hud)
	var top := HBoxContainer.new()
	top.position = Vector2(8, 6)
	top.add_theme_constant_override("separation", 8)
	_hud.add_child(top)
	var title := Label.new(); title.text = "MUSEUM STUDIO"; title.add_theme_color_override("font_color", Color(1, 0.85, 0.4))
	top.add_child(title)
	_chapter_opt = OptionButton.new(); _chapter_opt.item_selected.connect(_on_chapter_pick); top.add_child(_chapter_opt)
	_pearl_opt = OptionButton.new(); _pearl_opt.item_selected.connect(_on_pearl_pick); top.add_child(_pearl_opt)
	var bake := Button.new(); bake.text = "Bake pearl (B)"; bake.pressed.connect(_bake_pearl); top.add_child(bake)
	var walk := Button.new(); walk.text = "Walk it (W)"; walk.pressed.connect(_walk_it); top.add_child(walk)
	var undo := Button.new(); undo.text = "Undo (Z)"; undo.pressed.connect(_do_undo); top.add_child(undo)
	_status = Label.new(); _status.text = ""; top.add_child(_status)

	var left := VBoxContainer.new()
	left.position = Vector2(8, 40)
	left.custom_minimum_size = Vector2(240, 0)
	_hud.add_child(left)
	var pl := Label.new(); pl.text = "PALETTE — click, then click a cell"; pl.add_theme_font_size_override("font_size", 12); left.add_child(pl)
	_search = LineEdit.new(); _search.placeholder_text = "search every token…"; _search.text_changed.connect(_fill_palette); left.add_child(_search)
	_palette = ItemList.new(); _palette.custom_minimum_size = Vector2(240, 360); _palette.item_selected.connect(_on_palette_pick); left.add_child(_palette)

	_sel_label = Label.new(); _sel_label.position = Vector2(260, 40); _sel_label.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0)); _hud.add_child(_sel_label)
	_config_edit = LineEdit.new(); _config_edit.position = Vector2(260, 64); _config_edit.custom_minimum_size = Vector2(520, 0)
	_config_edit.placeholder_text = "K: config for the selected body — key=value key=value (Enter writes, empty clears)"
	_config_edit.text_submitted.connect(_on_config_submit)
	_hud.add_child(_config_edit)
	_refused_label = Label.new(); _refused_label.position = Vector2(260, 100); _refused_label.add_theme_color_override("font_color", Color(1.0, 0.55, 0.5)); _hud.add_child(_refused_label)
	_hint = Label.new()
	_hint.text = "click select · drag move (Ctrl fine) · left-drag on ground: turn iso · R rotate · +/- scale · P/[ ] plinth · C axis · K config/text · PgUp/PgDn height · Del remove · Home clear rule · Z/Y undo · G overlay · I iso · F frame · B bake · W walk"
	_hint.add_theme_font_size_override("font_size", 12)
	_hint.add_theme_color_override("font_color", Color(0.75, 0.75, 0.8))
	_hud.add_child(_hint)
	get_viewport().size_changed.connect(_place_hint)
	_place_hint()

func _place_hint() -> void:
	_hint.position = Vector2(8, get_viewport().get_visible_rect().size.y - 24)

func _fill_chapters() -> void:
	_chapter_opt.clear()
	for c in _chapters:
		_chapter_opt.add_item(String(c["chapter"]))

func _select_chapter(ch: String) -> void:
	for i in range(_chapter_opt.item_count):
		if _chapter_opt.get_item_text(i) == ch:
			_chapter_opt.select(i)
	_pearl_opt.clear()
	for p in _pearls_of(ch):
		var pd: Dictionary = p
		_pearl_opt.add_item("%d · %s (%d)%s" % [int(pd["index"]) + 1, String(pd["pearl"]), int(pd["bodies"]), (" · %d rooms" % int(pd["rooms"])) if int(pd["rooms"]) > 0 else ""])

func _on_chapter_pick(i: int) -> void:
	_chapter = _chapter_opt.get_item_text(i)
	_select_chapter(_chapter)
	var ps: Array = _pearls_of(_chapter)
	if not ps.is_empty():
		_open_pearl(_chapter, String((ps[0] as Dictionary)["pearl"]))

func _on_pearl_pick(i: int) -> void:
	var ps: Array = _pearls_of(_chapter)
	if i >= 0 and i < ps.size():
		_open_pearl(_chapter, String((ps[i] as Dictionary)["pearl"]))

func _fill_palette(_q: String = "") -> void:
	_palette.clear()
	var q: String = _search.text.to_lower().strip_edges()
	var row: Dictionary = _row()
	var mine: Array = []
	for a in row.get("artifacts", []):
		var t: String = String((a as Dictionary).get("token", ""))
		if not mine.has(t):
			mine.append(t)
	mine.sort()
	if q == "":
		for t in mine:
			_palette.add_item("· " + t)
	else:
		var n: int = 0
		for t in _all_tokens:
			if String(t).to_lower().contains(q):
				_palette.add_item(("· " if mine.has(t) else "  ") + String(t))
				n += 1
				if n >= 200:
					break

func _on_palette_pick(i: int) -> void:
	_placing = _palette.get_item_text(i).substr(2)
	_status.text = "placing %s — click a cell (Esc cancels)" % _placing


# ── open / rebuild ──────────────────────────────────────────────────────────
func _open_pearl(ch: String, pearl: String) -> void:
	_chapter = ch
	_pearl = pearl
	for p in _pearls_of(ch):
		if String((p as Dictionary)["pearl"]) == pearl:
			_map = String((p as Dictionary)["map"])
			for i in range(_pearl_opt.item_count):
				if _pearl_opt.get_item_text(i).contains("· " + pearl + " ("):
					_pearl_opt.select(i)
	_undo.clear(); _redo.clear()
	_rebuild()

func _rebuild() -> void:
	if _busy:
		return
	_busy = true
	_status.text = "building %s · %s…" % [_chapter, _pearl]
	if _museum != null:
		_museum.queue_free()
		_museum = null
	await get_tree().process_frame
	var ps: PackedScene = load(MUSEUM_SCENE)
	var m: Node3D = ps.instantiate() as Node3D
	m.set("_studio", true)
	m.set("start_chapter", _chapter)
	m.set("start_map", _map)
	add_child(m)
	_museum = m
	# the assembler builds segment 0 in _ready; give deferred builders a beat
	await get_tree().create_timer(0.35).timeout
	_busy = false
	_frame_hall()
	_fill_palette()
	_refresh_overlay()
	_reselect()
	_refresh_marks()
	_report()

func _records() -> Array:
	if _museum == null:
		return []
	var out: Array = []
	for r in (_museum.get("_edit_records") as Array):
		var rd: Dictionary = r
		var nv: Variant = rd.get("node")
		if not is_instance_valid(nv):          # a freed node cannot even be assigned to a typed var
			continue
		if (nv as Node).is_queued_for_deletion():
			continue
		out.append(rd)
	return out

func _kind(r: Dictionary) -> String:
	return String(r.get("kind", "")) if r.has("kind") else "body"

const KIND_COLOR := {"body": Color(0.2, 0.9, 1.0), "plinth": Color(0.85, 0.65, 0.35), "furniture": Color(0.55, 0.9, 0.45),
	"prop": Color(0.9, 0.55, 0.9), "showing": Color(0.95, 0.9, 0.5), "variant": Color(1.0, 0.5, 0.35)}

func _report() -> void:
	var recs: Array = _records()
	var refused: Array = _museum.get("_seg_refused") if _museum != null else []
	var row: Dictionary = _row()
	var counts: Dictionary = {}
	for r in recs:
		counts[_kind(r)] = int(counts.get(_kind(r), 0)) + 1
	_status.text = "%s · %s · %s · %d bodies · %d plinths · %d furniture · %d props · %d showings · %d variants · %d plan rows · %d rooms" % [
		_chapter, _pearl, _map, int(counts.get("body", 0)), int(counts.get("plinth", 0)), int(counts.get("furniture", 0)),
		int(counts.get("prop", 0)), int(counts.get("showing", 0)), int(counts.get("variant", 0)),
		(row.get("artifacts", []) as Array).size(), int(row.get("rooms", 0))]
	var lines: Array = []
	for r in refused:
		var rd: Dictionary = r
		lines.append("refused %s @%s — %s" % [rd.get("token"), rd.get("tile_cell"), String(rd.get("why", "")).substr(0, 60)])
	_refused_label.text = "\n".join(lines)
	_show_selection()


# ── camera ──────────────────────────────────────────────────────────────────
func _frame_hall() -> void:
	if _museum == null:
		return
	var segs: Array = _museum.get("_segments")
	var z1: float = 34.0
	if not segs.is_empty():
		z1 = float((segs[0] as Dictionary).get("z1", 34.0))
	_cam_target = Vector3(7.5, 0.0, z1 * 0.5)
	_cam_size = maxf(z1 + 6.0, 20.0)
	_apply_cam()

func _apply_cam() -> void:
	if _orbit:
		_cam.projection = Camera3D.PROJECTION_PERSPECTIVE
		_cam.fov = 60.0
		var d: float = _cam_size * 0.9
		var off := Vector3(cos(_orbit_pitch) * sin(_orbit_yaw), -sin(_orbit_pitch), cos(_orbit_pitch) * cos(_orbit_yaw)) * d
		_cam.global_position = _cam_target + off
		_cam.look_at(_cam_target, Vector3.UP)
	elif _iso:
		# isometric, still ORTHOGRAPHIC: cell snapping stays exact, heights show —
		# the plinth under the body, what hangs on the wall. Seen from the
		# entrance side (south-west), the walk going up-right.
		_cam.projection = Camera3D.PROJECTION_ORTHOGONAL
		_cam.size = _cam_size
		var dir := Vector3(sin(_iso_yaw) * cos(_iso_pitch), sin(_iso_pitch), cos(_iso_yaw) * cos(_iso_pitch)).normalized()
		_cam.global_position = _cam_target + dir * 80.0
		_cam.look_at(_cam_target, Vector3.UP)
	else:
		_cam.projection = Camera3D.PROJECTION_ORTHOGONAL
		_cam.size = _cam_size
		_cam.global_position = _cam_target + Vector3(0, 60, 0)
		_cam.look_at(_cam_target, Vector3(0, 0, 1))    # +z (the walk) points UP the screen

func _mouse_plane(mp: Vector2, y: float) -> Vector3:
	var o: Vector3 = _cam.project_ray_origin(mp)
	var d: Vector3 = _cam.project_ray_normal(mp)
	if absf(d.y) < 1e-4:
		return o
	var t: float = (y - o.y) / d.y
	return o + d * t

func _wall_normal_of(r: Dictionary) -> Vector3:
	var na: Array = r.get("normal", [])
	if na.size() >= 3:
		return Vector3(float(na[0]), 0.0, float(na[2])).normalized()
	# a showing/prop record: face from the node's yaw (it faces out of the wall)
	var n: Node3D = r.get("node") as Node3D
	var f: Vector3 = -n.global_transform.basis.z
	if absf(f.x) > absf(f.z):
		return Vector3(signf(f.x), 0, 0)
	return Vector3(0, 0, signf(f.z) if absf(f.z) > 0.01 else 1.0)

func _mouse_floor(mp: Vector2) -> Vector3:
	var o: Vector3 = _cam.project_ray_origin(mp)
	var d: Vector3 = _cam.project_ray_normal(mp)
	if absf(d.y) < 1e-4:
		return o
	var t: float = -o.y / d.y
	return o + d * t


# ── selection / edit ────────────────────────────────────────────────────────
func _record_at(mp: Vector2) -> Dictionary:
	var best: Dictionary = {}
	var best_d: float = PICK_PX
	for r in _records():
		var n: Node3D = r.get("node") as Node3D
		var sp: Vector2 = _cam.unproject_position(n.global_position + Vector3(0, 0.3, 0))
		if _kind(r) != "body" and _kind(r) != "plinth" and _kind(r) != "furniture":
			sp = _cam.unproject_position(n.global_position)
		var d: float = sp.distance_to(mp)
		if d < best_d:
			best_d = d
			best = r
	return best

func _key_of(r: Dictionary) -> String:
	var kind: String = _kind(r)
	if kind == "variant":
		return "variant|%d|%d" % [int(r.get("run", -1)), int(r.get("vi", -1))]
	if kind != "body" and kind != "plinth":
		return "%s|%s|%d" % [kind, String(r.get("token", "")), int(r.get("index", -1))]
	var tc: Array = r.get("tile_cell", r.get("from", []))
	if tc.size() < 2:
		return String(r.get("token", ""))
	return "%s|%s|%d|%d" % [kind, String(r.get("token", "")), int(tc[0]), int(tc[1])]

func _reselect() -> void:
	_sel = {}
	if _sel_key == "":
		return
	for r in _records():
		if _key_of(r) == _sel_key:
			_sel = r
			break

func _refresh_marks() -> void:
	if _marks != null:
		_marks.queue_free()
	_marks = Node3D.new()
	_marks.name = "Marks"
	add_child(_marks)
	for r in _records():
		var n: Node3D = r.get("node") as Node3D
		var sel: bool = not _sel.is_empty() and _sel.get("node") == n
		var kind: String = _kind(r)
		var kc: Color = KIND_COLOR.get(kind, Color(0.8, 0.8, 0.8))
		var lbl := Label3D.new()
		lbl.text = String(r.get("token", "")) if kind == "body" else ("%s·%s" % [kind[0], String(r.get("token", ""))] if kind != "showing" else "s·%d" % int(r.get("index", 0)))
		lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lbl.fixed_size = true
		lbl.pixel_size = 0.0007
		lbl.font_size = 30
		lbl.outline_size = 7
		lbl.no_depth_test = true
		lbl.modulate = Color(1, 0.85, 0.3) if sel else (Color(0.95, 0.97, 1.0) if kind == "body" else kc)
		if kind != "body":
			lbl.font_size = 22
		lbl.outline_modulate = Color(0, 0, 0, 0.9)
		lbl.position = n.global_position + Vector3(0, 2.4, 0.55)   # a little north of the ring, so ring and name both read
		_marks.add_child(lbl)
		var ring := MeshInstance3D.new()
		var tm := TorusMesh.new(); tm.inner_radius = 0.34 if kind == "body" else 0.16; tm.outer_radius = 0.46 if kind == "body" else 0.24; tm.rings = 24; tm.ring_segments = 8
		ring.mesh = tm
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = Color(1, 0.8, 0.2) if sel else kc
		mat.no_depth_test = true
		ring.material_override = mat
		ring.position = Vector3(n.global_position.x, 0.06 if kind in ["body", "plinth", "furniture"] else n.global_position.y, n.global_position.z)
		_marks.add_child(ring)

func _show_selection() -> void:
	if _sel.is_empty() or not is_instance_valid(_sel.get("node")):
		_sel_label.text = "" if _placing == "" else ("placing %s — click a cell" % _placing)
		return
	var nv0: Variant = _sel.get("node")
	var n: Node3D = nv0 as Node3D
	var kind: String = _kind(_sel)
	if kind != "body":
		var rule: Dictionary = _dressing_rule_for(_sel)
		match kind:
			"variant":
				_sel_label.text = "DNA variant %s · %s = %s · run %d value %d · %s wall\n  drag: nudge along the wall (Ctrl free) · PgUp/PgDn: height · Delete: drop this value · Insert: restore" % [
					String(_sel.get("token", "")), String(_sel.get("axis", "")), String(_sel.get("value", "")), int(_sel.get("run", -1)), int(_sel.get("vi", -1)), String(_sel.get("wall_side", ""))]
			"showing":
				_sel_label.text = "showing #%d (a wall frame)  world (%.1f, %.1f, %.1f)%s\n  drag: offset · K: card text · Delete: remove · Home: clear the rule" % [
					int(_sel.get("index", 0)), n.global_position.x, n.global_position.y, n.global_position.z, ("  rule %s" % str(rule)) if not rule.is_empty() else ""]
			"plinth":
				_sel_label.text = "plinth under %s at %s  (%.1f, %.1f, %.1f)%s\n  drag: offset the plinth alone · Home: clear the rule · P on the body removes it" % [
					String(_sel.get("token", "")), str(_sel.get("from", [])), n.global_position.x, n.global_position.y, n.global_position.z, ("  rule %s" % str(rule)) if not rule.is_empty() else ""]
			_:
				_sel_label.text = "%s %s #%d  (%.1f, %.1f, %.1f)%s\n  drag: offset · R: rotate · PgUp/PgDn: height · Delete: remove · Home: clear the rule" % [
					kind, String(_sel.get("token", "")), int(_sel.get("index", 0)), n.global_position.x, n.global_position.y, n.global_position.z, ("  rule %s" % str(rule)) if not rule.is_empty() else ""]
		return
	var tc: Array = _sel.get("tile_cell", [])
	var prow: Dictionary = _plan_row_for(_sel)
	_sel_label.text = "%s  cell %s  rot %.0f°  world (%.1f, %.1f, %.1f)%s%s%s" % [
		String(_sel.get("token", "")), str(tc), n.rotation_degrees.y, n.global_position.x, n.global_position.y, n.global_position.z,
		("  scale %.2f" % float(prow.get("scale", 1.0))) if prow.has("scale") else "",
		("  plinth %.2f" % float(prow.get("support_height_m", 0.0))) if float(prow.get("support_height_m", 0.0)) > 0.05 else "",
		("  config %s" % str(prow.get("config"))) if prow.has("config") else ""]
	if _is_court_resident(_sel):
		_sel_label.text += "
  COURT resident — placed by the court builder (court %s); not movable here yet" % str(_plan_row_for_token(String(_sel.get("token", ""))).get("court", []))
	var pw: String = String(_sel.get("plinth_why", ""))
	if String(_sel.get("plinth", "")) != "":
		_sel_label.text += "
  plinth: %s %.2f m" % [String(_sel.get("plinth", "")), float(_sel.get("plinth_h", 0.0))]
	elif pw != "":
		_sel_label.text += "
  no plinth: %s" % pw.substr(0, 90)

func _dressing_rule_for(r: Dictionary) -> Dictionary:
	var kind: String = _kind(r)
	for d in _row().get("dressing", []):
		var dd: Dictionary = d
		if String(dd.get("kind", "")) != kind or String(dd.get("token", "")) != String(r.get("token", "")):
			continue
		if kind == "plinth":
			var f1: Array = dd.get("from", []); var f2: Array = r.get("from", [])
			if f1.size() >= 2 and f2.size() >= 2 and int(f1[0]) == int(f2[0]) and int(f1[1]) == int(f2[1]):
				return dd
		elif int(dd.get("index", -2)) == int(r.get("index", -3)):
			return dd
	return {}

func _rule_offset(r: Dictionary) -> Vector3:
	var o: Array = _dressing_rule_for(r).get("offset", [])
	return Vector3(float(o[0]), float(o[1]), float(o[2])) if o.size() >= 3 else Vector3.ZERO

func _variant_offset(r: Dictionary) -> Vector3:
	var runs: Array = _row().get("wall_runs", [])
	var ri: int = int(r.get("run", -1))
	if ri < 0 or ri >= runs.size():
		return Vector3.ZERO
	var offs: Array = (runs[ri] as Dictionary).get("offsets", [])
	var vi: int = int(r.get("vi", -1))
	if vi >= 0 and vi < offs.size() and offs[vi] is Array and (offs[vi] as Array).size() >= 3:
		var o: Array = offs[vi]
		return Vector3(float(o[0]), float(o[1]), float(o[2]))
	return Vector3.ZERO

func _plan_row_for(r: Dictionary) -> Dictionary:
	var tc: Array = r.get("tile_cell", [])
	for a in _row().get("artifacts", []):
		var ad: Dictionary = a
		var atc: Array = ad.get("tile_cell", [])
		if String(ad.get("token", "")) == String(r.get("token", "")) and atc.size() >= 2 and tc.size() >= 2 \
				and int(atc[0]) == int(tc[0]) and int(atc[1]) == int(tc[1]):
			return ad
	return {}

## world position -> tile cell (segment 0 stands at z 0, its tile after the vestibule)
func _cell_of(pos: Vector3) -> Array:
	return [int(floor(pos.x)), int(floor(pos.z)) - VESTIBULE_H]

func _unhandled_input(event: InputEvent) -> void:
	if _busy or _museum == null:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			_cam_size = maxf(_cam_size * 0.9, 6.0); _apply_cam()
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_cam_size = minf(_cam_size * 1.1, 200.0); _apply_cam()
		elif mb.button_index == MOUSE_BUTTON_MIDDLE:
			_pan_drag = mb.pressed
		elif mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				if _placing != "":
					_place_at(_mouse_floor(mb.position))
					return
				var r: Dictionary = _record_at(mb.position)
				if r.is_empty():
					# empty ground: left-drag turns the isometric view (Palle: "left click rotate iso")
					_orbit_drag = true
					return
				_sel = r
				_sel_key = _key_of(r)
				_show_selection()
				_refresh_marks()
				_drag = true
				_drag_moved = false
				_drag_start_pos = (r.get("node") as Node3D).global_position
			else:
				_orbit_drag = false
				if _drag:
					_drag = false
					if _drag_moved:
						_commit_move()
	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if _orbit_drag:
			if not _iso and not _orbit:
				_iso = true
			_iso_yaw -= mm.relative.x * 0.008
			_iso_pitch = clampf(_iso_pitch - mm.relative.y * 0.005, 0.25, 1.45)
			_apply_cam()
			return
		if _pan_drag:
			var k: float = _cam_size / get_viewport().get_visible_rect().size.y
			if _orbit and mm.button_mask & MOUSE_BUTTON_MASK_RIGHT:
				_orbit_yaw -= mm.relative.x * 0.01; _orbit_pitch = clampf(_orbit_pitch - mm.relative.y * 0.01, -1.5, -0.1)
			else:
				_cam_target += Vector3(-mm.relative.x * k, 0, mm.relative.y * k)
			_apply_cam()
		elif _drag and not _sel.is_empty() and is_instance_valid(_sel.get("node")):
			var n: Node3D = _sel.get("node") as Node3D
			var fine: bool = Input.is_key_pressed(KEY_CTRL)
			var kind: String = _kind(_sel)
			var np: Vector3
			if kind == "variant" or kind == "showing" or kind == "prop":
				# a wall piece slides ALONG its wall (a plane at its own height)
				var ph: Vector3 = _mouse_plane(mm.position, n.global_position.y)
				var nrm: Vector3 = _wall_normal_of(_sel)
				var tang := Vector3(-nrm.z, 0, nrm.x)
				var along: float = (ph - _drag_start_pos).dot(tang)
				if not fine:
					along = snappedf(along, 0.25)
				np = _drag_start_pos + tang * along
			else:
				var p: Vector3 = _mouse_floor(mm.position)
				if fine or kind != "body":
					np = Vector3(snappedf(p.x, 0.2), n.global_position.y, snappedf(p.z, 0.2))
				else:
					np = Vector3(floor(p.x) + 0.5, n.global_position.y, floor(p.z) + 0.5)
			if np.distance_to(n.global_position) > 0.001:
				n.global_position = np
				_drag_moved = true
				_show_selection()
				_refresh_marks()
	elif event is InputEventKey and (event as InputEventKey).pressed and not (event as InputEventKey).echo:
		_key((event as InputEventKey).keycode, (event as InputEventKey).shift_pressed, (event as InputEventKey).alt_pressed)

func _key(k: int, shift: bool, alt: bool) -> void:
	if _search.has_focus() or _config_edit.has_focus():
		return
	match k:
		KEY_ESCAPE:
			_placing = ""; _show_selection()
		KEY_F:
			_frame_hall()
		KEY_O:
			_orbit = not _orbit; _apply_cam()
		KEY_I:
			_iso = not _iso; _orbit = false; _apply_cam()
		KEY_BRACKETLEFT:
			_edit_row({"support_height_m": _step_support(-1)})
		KEY_BRACKETRIGHT:
			_edit_row({"support_height_m": _step_support(1)})
		KEY_K:
			_config_edit.text = String(_dressing_rule_for(_sel).get("text", "")) if _kind(_sel) == "showing" else _config_text()
			_config_edit.grab_focus()
		KEY_G:
			_show_overlay = not _show_overlay; _refresh_overlay()
		KEY_B:
			_bake_pearl()
		KEY_W:
			_walk_it()
		KEY_Z:
			_do_undo()
		KEY_Y:
			_do_redo()
		KEY_LEFT:  _cam_target.x -= 1.0; _apply_cam()
		KEY_RIGHT: _cam_target.x += 1.0; _apply_cam()
		KEY_UP:    _cam_target.z += 1.0; _apply_cam()
		KEY_DOWN:  _cam_target.z -= 1.0; _apply_cam()
		KEY_R:
			if _kind(_sel) == "furniture" or _kind(_sel) == "prop":
				var n_r: Node3D = _sel.get("node") as Node3D
				_write_dressing([_rule_key(_sel).merged({"rotation": fmod(n_r.rotation_degrees.y + (15.0 if alt else (-90.0 if shift else 90.0)) + 360.0, 360.0)})])
			elif _kind(_sel) == "body":
				_edit_row({"rotation": _cur_rot() + (15.0 if alt else (-90.0 if shift else 90.0))})
		KEY_PAGEUP, KEY_PAGEDOWN:
			var dy: float = 0.2 if k == KEY_PAGEUP else -0.2
			if _kind(_sel) == "variant":
				var o: Vector3 = _variant_offset(_sel) + Vector3(0, dy, 0)
				_write_variants([{"run": int(_sel.get("run", -1)), "vi": int(_sel.get("vi", -1)), "offset": [o.x, o.y, o.z]}])
			elif not _sel.is_empty() and _kind(_sel) != "body":
				var o2: Vector3 = _rule_offset(_sel) + Vector3(0, dy, 0)
				_write_dressing([_rule_key(_sel).merged({"offset": [o2.x, o2.y, o2.z]})])
		KEY_HOME:
			if not _sel.is_empty() and _kind(_sel) != "body" and _kind(_sel) != "variant":
				_write_dressing([_rule_key(_sel).merged({"clear": true})])
		KEY_INSERT:
			if _kind(_sel) == "variant":
				_write_variants([{"run": int(_sel.get("run", -1)), "vi": int(_sel.get("vi", -1)), "restore": true}])
		KEY_EQUAL, KEY_KP_ADD:
			_edit_row({"scale": _cur_scale() * 1.1})
		KEY_MINUS, KEY_KP_SUBTRACT:
			_edit_row({"scale": _cur_scale() / 1.1})
		KEY_P:
			_edit_row({"support_height_m": 0.0 if _cur_support() > 0.05 else 0.95})
		KEY_C:
			_cycle_config()
		KEY_DELETE, KEY_BACKSPACE:
			if _sel.is_empty():
				return
			match _kind(_sel):
				"body":
					_write_rows([{"token": _sel.get("token"), "cell": _sel.get("tile_cell"), "removed": true}])
					_sel_key = ""
				"variant":
					_write_variants([{"run": int(_sel.get("run", -1)), "vi": int(_sel.get("vi", -1)), "drop": true}])
					_sel_key = ""
				"plinth":
					_status.text = "a plinth is the body's request — select the body and press P"
				_:
					_write_dressing([_rule_key(_sel).merged({"remove": true})])
					_sel_key = ""

const SUPPORTS := [0.0, 0.4, 0.64, 0.95, 1.2]
func _step_support(dir: int) -> float:
	var cur: float = _cur_support()
	var i: int = 0
	for j in range(SUPPORTS.size()):
		if absf(float(SUPPORTS[j]) - cur) < 0.05:
			i = j
	return float(SUPPORTS[clampi(i + dir, 0, SUPPORTS.size() - 1)])

func _config_text() -> String:
	var cfg: Dictionary = _plan_row_for(_sel).get("config", {})
	var parts: Array = []
	for k in cfg:
		parts.append("%s=%s" % [String(k), String(cfg[k])])
	return " ".join(parts)

func _rule_key(r: Dictionary) -> Dictionary:
	var d: Dictionary = {"kind": _kind(r), "token": r.get("token"), "index": int(r.get("index", -1))}
	if _kind(r) == "plinth":
		d["from"] = r.get("from")
	return d

func _on_config_submit(text: String) -> void:
	if _sel.is_empty():
		return
	if _kind(_sel) == "showing":
		_config_edit.release_focus()
		_write_dressing([_rule_key(_sel).merged({"text": text.strip_edges()})])
		return
	var cfg: Dictionary = {}
	for part in text.split(" ", false):
		var kv: PackedStringArray = String(part).split("=", true, 1)
		if kv.size() == 2 and kv[0].strip_edges() != "":
			cfg[kv[0].strip_edges()] = kv[1].strip_edges()
	_config_edit.release_focus()
	_edit_row({"config": cfg})

func _cur_rot() -> float:
	var pr: Dictionary = _plan_row_for(_sel)
	return float(pr.get("rotation", 0.0))
func _cur_scale() -> float:
	return float(_plan_row_for(_sel).get("scale", 1.0))
func _cur_support() -> float:
	return float(_plan_row_for(_sel).get("support_height_m", 0.0))

func _edit_row(fields: Dictionary) -> void:
	if _sel.is_empty():
		return
	var row: Dictionary = {"token": _sel.get("token"), "cell": _sel.get("tile_cell")}
	for k in fields:
		row[k] = fields[k]
	_write_rows([row])

func _cycle_config() -> void:
	if _sel.is_empty() or _museum == null:
		return
	var tok: String = String(_sel.get("token", ""))
	var axes: Dictionary = _museum.call("_axes_for", tok)
	if axes.is_empty():
		_status.text = "%s has no DNA axis" % tok
		return
	var axis: String = String(axes.keys()[0])
	var vals: Array = axes[axis]
	var pr: Dictionary = _plan_row_for(_sel)
	var cfg: Dictionary = (pr.get("config", {}) as Dictionary).duplicate()
	var cur: String = String(cfg.get(axis, ""))
	var i: int = vals.find(cur)
	var nxt: String = String(vals[(i + 1) % vals.size()])
	cfg[axis] = nxt
	_edit_row({"config": cfg})

func _tile_wh() -> Array:
	var row: Dictionary = _row()
	if row.get("tile") is Array and not (row["tile"] as Array).is_empty():
		return [(row["tile"][0] as Array).size(), (row["tile"] as Array).size()]
	var rm: Dictionary = row.get("room", {})
	var apron: int = int(row.get("apron", 14))
	return [int(rm.get("w", 43)) - 2 * apron, int(rm.get("h", 58)) - 2 * apron]

func _is_court_resident(r: Dictionary) -> bool:
	var pr: Dictionary = _plan_row_for_token(String(r.get("token", "")))
	return String(pr.get("venue", "")) in ["courtyard", "balcony", "hall"] and (pr.get("court", []) as Array).size() >= 2

func _plan_row_for_token(tok: String) -> Dictionary:
	var hits: Array = []
	for a in _row().get("artifacts", []):
		if String((a as Dictionary).get("token", "")) == tok:
			hits.append(a)
	return hits[0] if hits.size() == 1 else _plan_row_for(_sel)

func _commit_move() -> void:
	if _sel.is_empty() or not is_instance_valid(_sel.get("node")):
		return
	var n: Node3D = _sel.get("node") as Node3D
	var p: Vector3 = n.global_position
	var kind: String = _kind(_sel)
	if kind == "variant":
		var base_v: Vector3 = _drag_start_pos - _variant_offset(_sel)
		var dv: Vector3 = p - base_v
		_write_variants([{"run": int(_sel.get("run", -1)), "vi": int(_sel.get("vi", -1)), "offset": [snappedf(dv.x, 0.01), snappedf(dv.y, 0.01), snappedf(dv.z, 0.01)]}])
		return
	if kind != "body":
		var base_d: Vector3 = _drag_start_pos - _rule_offset(_sel)
		var dd: Vector3 = p - base_d
		var rule: Dictionary = {"kind": kind, "token": _sel.get("token"), "index": int(_sel.get("index", -1)),
			"offset": [snappedf(dd.x, 0.01), snappedf(dd.y, 0.01), snappedf(dd.z, 0.01)]}
		if kind == "plinth":
			rule["from"] = _sel.get("from")
		_write_dressing([rule])
		return
	var cell: Array = _cell_of(p)
	# what the plan cannot say: a court resident is placed by the court builder
	# (its row has `court`, not a cell), and a cell outside the tile is nowhere
	if _is_court_resident(_sel):
		n.global_position = _drag_start_pos
		_status.text = "%s is a COURT resident — the court builder places it; the studio cannot move it yet" % String(_sel.get("token", ""))
		_refresh_marks()
		return
	var wh: Array = _tile_wh()
	if int(cell[0]) < 0 or int(cell[0]) >= int(wh[0]) or int(cell[1]) < 0 or int(cell[1]) >= int(wh[1]):
		n.global_position = _drag_start_pos
		_status.text = "cell %s is outside the tile (%d x %d) — the plan cannot place a body there" % [str(cell), int(wh[0]), int(wh[1])]
		_refresh_marks()
		return
	var centre := Vector3(cell[0] + 0.5, p.y, cell[1] + VESTIBULE_H + 0.5)
	var off: Vector3 = p - centre
	var row: Dictionary = {"token": _sel.get("token"), "token_before": _sel.get("token"),
		"cell_before": _sel.get("tile_cell"), "cell": cell,
		"offset": [snappedf(off.x, 0.01), 0.0, snappedf(off.z, 0.01)]}
	_sel_key = "%s|%d|%d" % [String(_sel.get("token", "")), int(cell[0]), int(cell[1])]
	_write_rows([row])

func _place_at(p: Vector3) -> void:
	var cell: Array = _cell_of(p)
	var wh: Array = _tile_wh()
	if int(cell[0]) < 0 or int(cell[0]) >= int(wh[0]) or int(cell[1]) < 0 or int(cell[1]) >= int(wh[1]):
		_status.text = "cell %s is outside the tile (%d x %d) — place inside the hall" % [str(cell), int(wh[0]), int(wh[1])]
		return
	var tok: String = _placing
	_placing = ""
	_sel_key = "%s|%d|%d" % [tok, int(cell[0]), int(cell[1])]
	_write_rows([{"token": tok, "cell": cell, "add": true, "rotation": 0}])


# ── the writer: tools/em_plan_write.py, then rebuild ────────────────────────
func _write_rows(rows: Array, replace: bool = false) -> void:
	_write_op(rows, "--replace" if replace else "--rows-op")

func _snapshot() -> Dictionary:
	var row: Dictionary = _row()
	return {"artifacts": (row.get("artifacts", []) as Array).duplicate(true),
		"dressing": (row.get("dressing", []) as Array).duplicate(true),
		"wall_runs": (row.get("wall_runs", []) as Array).duplicate(true)}

func _write_op(rows: Variant, flag: String) -> void:
	if _busy:
		return
	if flag != "--replace-all":
		_undo.append(_snapshot())
		if _undo.size() > 40:
			_undo.pop_front()
		_redo.clear()
	var tmp: String = OS.get_user_data_dir() + "/em_studio_rows.json"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	f.store_string(JSON.stringify(rows))
	f.close()
	var repo: String = ProjectSettings.globalize_path("res://")
	var args: PackedStringArray = [repo + "tools/em_plan_write.py", "--chapter", _chapter, "--pearl", _pearl, "--rows", tmp, "--by", "studio", flag]
	var out: Array = []
	var code: int = OS.execute("python", args, out, true)
	if code != 0:
		_status.text = "WRITE FAILED (%d): %s" % [code, "".join(out).substr(0, 200)]
		return
	_load_plan()
	_rebuild()

func _write_dressing(rules: Array) -> void:
	_write_op(rules, "--dressing")

func _write_variants(edits: Array) -> void:
	_write_op(edits, "--variants")

func _do_undo() -> void:
	if _undo.is_empty():
		_status.text = "nothing to undo"; return
	_redo.append(_snapshot())
	var snap: Dictionary = _undo.pop_back()
	_write_op(snap, "--replace-all")

func _do_redo() -> void:
	if _redo.is_empty():
		return
	_undo.append(_snapshot())
	var snap: Dictionary = _redo.pop_back()
	_write_op(snap, "--replace-all")


# ── bake / walk ─────────────────────────────────────────────────────────────
func _bake_pearl() -> void:
	if _busy:
		return
	_busy = true
	_status.text = "baking %s/%s (~15 s)…" % [_chapter, _pearl]
	await get_tree().process_frame
	var repo: String = ProjectSettings.globalize_path("res://")
	var out: Array = []
	var code: int = OS.execute("python", [repo + "tools/em_bake.py", "--pearl", _chapter + "/" + _pearl], out, true)
	_busy = false
	_status.text = ("baked %s/%s — the walk replays it" % [_chapter, _pearl]) if code == 0 else ("BAKE FAILED: " + "".join(out).substr(0, 200))

func _walk_it() -> void:
	# the museum opens at this pearl: em_control speaks for a flagless launch
	var f := FileAccess.open(EM_CONTROL, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({"_readme": "written by museum_studio: the walk opens at the pearl being edited",
			"first_chapter": _chapter, "first_map": _map}, "\t"))
		f.close()
	get_tree().change_scene_to_file(MUSEUM_SCENE)


# ── overlay: the walk map ───────────────────────────────────────────────────
func _refresh_overlay() -> void:
	if _overlay != null:
		_overlay.queue_free()
		_overlay = null
	if not _show_overlay or _museum == null:
		return
	var walk: Dictionary = _museum.get("_walk_cells")
	var erased: Dictionary = _museum.get("_walk_erased")
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var quad := func(x: int, z: int, col: Color) -> void:
		var y: float = 0.02
		var a := Vector3(x + 0.08, y, z + 0.08); var b := Vector3(x + 0.92, y, z + 0.08)
		var c := Vector3(x + 0.92, y, z + 0.92); var d := Vector3(x + 0.08, y, z + 0.92)
		st.set_color(col); st.add_vertex(a); st.set_color(col); st.add_vertex(b); st.set_color(col); st.add_vertex(c)
		st.set_color(col); st.add_vertex(a); st.set_color(col); st.add_vertex(c); st.set_color(col); st.add_vertex(d)
	for k in walk.keys():
		var v: Vector2i = k
		quad.call(v.x, v.y, Color(0.3, 0.8, 1.0, 0.18))
	for k in erased.keys():
		var v: Vector2i = k
		var why: String = String(erased[k])
		quad.call(v.x, v.y, Color(1.0, 0.35, 0.3, 0.35) if why.begins_with("seal") else Color(1.0, 0.8, 0.3, 0.3))
	var mesh: ArrayMesh = st.commit()
	_overlay = MeshInstance3D.new()
	_overlay.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_overlay.material_override = mat
	add_child(_overlay)
