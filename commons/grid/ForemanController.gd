extends Node3D
## FOREMAN (Godot) — a layer game built ON TOP of GridEditorDesktop3D, non-invasively.
##
## The editor renders the map (structure / artifacts / utilities). This controller adds a
## LAYER system over it: each layer is a LENS (a 3D highlight on the grid) + an AUTO-ORGANISE
## pass + a SCORE/verdict. You select the layer you want to work, it organises + scores that
## aspect, and you stack the layers that help — "select the right layer, it auto-organises".
##
## Layer 1 (working): PATHFIND — flood-fill the walkable floor from spawn, highlight reachable
## (green) vs stranded (red) cells, mark spawn (blue) + artifacts (orange), score walk% + reach.
## Other layers are scaffolded and come next.
##
## Non-invasive: instances GridEditorDesktop3D.tscn as a child and reads its live grid data
## (heights via _structure.get_height_at, the interactables/utilities token arrays). It never
## edits GridEditorDesktop3D.gd.

const BakedText := preload("res://commons/utils/baked_text_albedo.gd")

# Cell→world (matches GridEditorDesktop3D): cell (x=col, z=row) → ((x+0.5)*cube, h*cube, (z+0.5)*cube).
var _editor: Node = null
var _structure: Node = null
var _cube: float = 1.0
var _w: int = 0
var _d: int = 0
var _bound: bool = false

# Layers — each: id, label, enabled (built), and whether it's implemented yet.
const LAYERS := [
	{"id": "pathfind", "label": "PATHFIND", "ready": true},
	{"id": "artifacts", "label": "ARTIFACTS", "ready": false},
	{"id": "graph", "label": "ONTOLOGY GRAPH", "ready": false},
	{"id": "gameplay", "label": "GAMEPLAY", "ready": false},
	{"id": "grid", "label": "GRID", "ready": false},
]
var _active: String = "pathfind"

var _overlay: MultiMeshInstance3D = null
var _score_lbl: Label = null
var _title_lbl: Label = null
var _layer_buttons: Dictionary = {}
var _toast_lbl: Label = null
var _toast_t: float = 0.0


func _ready() -> void:
	_editor = get_node_or_null("GridEditorDesktop3D")
	_build_overlay()
	_build_hud()
	set_process(true)


func _process(delta: float) -> void:
	if not _bound:
		_try_bind()
	if _toast_t > 0.0:
		_toast_t -= delta
		if _toast_t <= 0.0 and _toast_lbl:
			_toast_lbl.text = ""


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R and _bound:
			_refresh()
			_toast("layer refreshed")


# ── Bind to the editor once its grid is built ─────────────────────────
func _try_bind() -> void:
	if _editor == null:
		return
	var st = _editor.get("_structure")
	var w := int(_editor.get("_grid_w")) if _editor.get("_grid_w") != null else 0
	var d := int(_editor.get("_grid_d")) if _editor.get("_grid_d") != null else 0
	if st == null or w <= 0 or d <= 0:
		return
	_structure = st
	_w = w
	_d = d
	var cs = _editor.get("cube_size")
	if cs != null:
		_cube = float(cs)
	_bound = true
	_refresh()
	var mp = _editor.get("_loaded_map")
	_toast("foreman bound · %s · %d×%d" % [str(mp) if mp else "grid", _w, _d])


# ── Grid reads (live, from the editor) ────────────────────────────────
func _height_at(x: int, z: int) -> int:
	if _structure and _structure.has_method("get_height_at"):
		return int(_structure.get_height_at(x, z))
	return 0


func _token_grid(member: String) -> Array:
	# editor._interactables / _utilities are Array[Array[String]] indexed [z][x].
	var g = _editor.get(member)
	return g if g is Array else []


func _artifact_cells() -> Array:
	var out: Array = []
	var g := _token_grid("_interactables")
	for z in range(min(g.size(), _d)):
		var row = g[z]
		if not (row is Array):
			continue
		for x in range(min(row.size(), _w)):
			var t := str(row[x]).strip_edges()
			if t != "" and t != " " and not t.begins_with("#"):
				out.append(Vector2i(x, z))
	return out


func _find_spawn() -> Vector2i:
	var g := _token_grid("_utilities")
	for z in range(min(g.size(), _d)):
		var row = g[z]
		if not (row is Array):
			continue
		for x in range(min(row.size(), _w)):
			var t := str(row[x]).strip_edges().to_lower()
			if t == "sp" or t == "s" or t.begins_with("sp:") or t.begins_with("s:"):
				return Vector2i(x, z)
	# fallback: first floor cell
	for z in _d:
		for x in _w:
			if _height_at(x, z) >= 1:
				return Vector2i(x, z)
	return Vector2i(-1, -1)


# ── Layer dispatch ────────────────────────────────────────────────────
func _refresh() -> void:
	if not _bound:
		return
	match _active:
		"pathfind": _layer_pathfind()
		_:
			_clear_overlay()
			_set_score("%s — coming soon" % _active.to_upper())


func _set_layer(id: String) -> void:
	var entry: Dictionary = {}
	for l in LAYERS:
		if l["id"] == id:
			entry = l
	if entry.is_empty():
		return
	if not entry["ready"]:
		_toast("%s layer — coming next" % entry["label"])
		return
	_active = id
	for lid in _layer_buttons:
		_layer_buttons[lid].button_pressed = (lid == id)
	_refresh()


# ── PATHFIND layer: lens + auto-organise (flood-fill) + score ─────────
func _layer_pathfind() -> void:
	var spawn := _find_spawn()
	var floor_cells: Array = []
	for z in _d:
		for x in _w:
			if _height_at(x, z) >= 1:
				floor_cells.append(Vector2i(x, z))

	# Flood-fill reachable floor from spawn (4-connected, step ≤ 1 height).
	var reachable: Dictionary = {}
	if spawn != Vector2i(-1, -1):
		var q: Array = [spawn]
		reachable[spawn] = true
		while not q.is_empty():
			var c: Vector2i = q.pop_front()
			var ch := _height_at(c.x, c.y)
			for nb in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var nc: Vector2i = c + nb
				if nc.x < 0 or nc.x >= _w or nc.y < 0 or nc.y >= _d:
					continue
				if reachable.has(nc):
					continue
				var nh := _height_at(nc.x, nc.y)
				if nh < 1:
					continue
				if abs(nh - ch) > 1:
					continue
				reachable[nc] = true
				q.append(nc)

	# Reach verdict: each artifact has a reachable walkable cell at/adjacent to it.
	var arts := _artifact_cells()
	var reached := 0
	for a in arts:
		for nb in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			if reachable.has(a + nb):
				reached += 1
				break

	var walk_pct := 100.0 * float(reachable.size()) / float(maxi(floor_cells.size(), 1))

	# Lens — colour every floor cell on its walkable surface.
	var art_set := {}
	for a in arts:
		art_set[a] = true
	var quads: Array = []
	for c in floor_cells:
		var top_y := float(_height_at(c.x, c.y)) * _cube + 0.06
		var col: Color
		if c == spawn:
			col = Color(0.2, 0.55, 1.0, 0.85)        # spawn = blue
		elif art_set.has(c):
			col = Color(0.95, 0.55, 0.12, 0.8) if reachable.has(c) else Color(0.95, 0.2, 0.5, 0.85)
		elif reachable.has(c):
			col = Color(0.25, 0.85, 0.35, 0.5)        # reachable = green
		else:
			col = Color(0.85, 0.2, 0.2, 0.6)          # stranded = red
		quads.append({"pos": Vector3((float(c.x) + 0.5) * _cube, top_y, (float(c.y) + 0.5) * _cube), "color": col})
	_paint_overlay(quads)

	_set_score("PATHFIND    walk %d%%  (%d/%d cells)    reach %d/%d artifacts%s" % [
		int(round(walk_pct)), reachable.size(), floor_cells.size(), reached, arts.size(),
		"" if spawn != Vector2i(-1, -1) else "    [no spawn!]",
	])


# ── Overlay (the 3D lens) ─────────────────────────────────────────────
func _build_overlay() -> void:
	_overlay = MultiMeshInstance3D.new()
	_overlay.name = "ForemanOverlay"
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var quad := PlaneMesh.new()
	quad.size = Vector2(0.9, 0.9)   # lies in XZ, faces +Y
	mm.mesh = quad
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.vertex_color_use_as_albedo = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.no_depth_test = false
	quad.material = mat
	_overlay.multimesh = mm
	add_child(_overlay)


func _paint_overlay(quads: Array) -> void:
	var mm := _overlay.multimesh
	mm.instance_count = quads.size()
	for i in range(quads.size()):
		var q: Dictionary = quads[i]
		mm.set_instance_transform(i, Transform3D(Basis(), q["pos"]))
		mm.set_instance_color(i, q["color"])
	_overlay.visible = true


func _clear_overlay() -> void:
	if _overlay and _overlay.multimesh:
		_overlay.multimesh.instance_count = 0


# ── HUD (layer selector + score) ──────────────────────────────────────
func _build_hud() -> void:
	var cl := CanvasLayer.new()
	cl.name = "ForemanHUD"
	cl.layer = 5
	add_child(cl)

	# Layer selector — left column.
	var panel := PanelContainer.new()
	panel.position = Vector2(12, 90)
	cl.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	panel.add_child(vb)
	_title_lbl = Label.new()
	_title_lbl.text = "◆ FOREMAN · LAYERS"
	_title_lbl.add_theme_color_override("font_color", Color(0.95, 0.6, 0.15))
	vb.add_child(_title_lbl)
	for l in LAYERS:
		var b := Button.new()
		b.toggle_mode = true
		b.text = ("● " if l["ready"] else "○ ") + str(l["label"]) + ("" if l["ready"] else "  (soon)")
		b.button_pressed = (l["id"] == _active)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var lid: String = l["id"]
		b.pressed.connect(func(): _set_layer(lid))
		vb.add_child(b)
		_layer_buttons[lid] = b
	var hint := Label.new()
	hint.text = "R = refresh layer"
	hint.add_theme_color_override("font_color", Color(0.6, 0.62, 0.68))
	hint.add_theme_font_size_override("font_size", 11)
	vb.add_child(hint)

	# Score readout — bottom-centre band.
	var sp := PanelContainer.new()
	sp.anchor_left = 0.5
	sp.anchor_right = 0.5
	sp.anchor_top = 1.0
	sp.anchor_bottom = 1.0
	sp.offset_left = -360
	sp.offset_right = 360
	sp.offset_top = -52
	sp.offset_bottom = -16
	cl.add_child(sp)
	_score_lbl = Label.new()
	_score_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_score_lbl.text = "binding to grid…"
	_score_lbl.add_theme_color_override("font_color", Color(0.9, 0.92, 0.96))
	sp.add_child(_score_lbl)

	# Toast — just above the score.
	_toast_lbl = Label.new()
	_toast_lbl.anchor_left = 0.5
	_toast_lbl.anchor_right = 0.5
	_toast_lbl.anchor_top = 1.0
	_toast_lbl.anchor_bottom = 1.0
	_toast_lbl.offset_left = -300
	_toast_lbl.offset_right = 300
	_toast_lbl.offset_top = -78
	_toast_lbl.offset_bottom = -56
	_toast_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_lbl.add_theme_color_override("font_color", Color(0.95, 0.8, 0.3))
	cl.add_child(_toast_lbl)


func _set_score(t: String) -> void:
	if _score_lbl:
		_score_lbl.text = t


func _toast(t: String) -> void:
	if _toast_lbl:
		_toast_lbl.text = t
		_toast_t = 2.5
