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
	{"id": "artifacts", "label": "ARTIFACTS", "ready": true},
	{"id": "graph", "label": "ONTOLOGY GRAPH", "ready": true},
	{"id": "gameplay", "label": "GAMEPLAY", "ready": true},
	{"id": "grid", "label": "GRID", "ready": true},
]
var _active: String = "pathfind"
var _organized: Dictionary = {}   # artifacts auto-organize: old anchor (Vector2i) -> suggested anchor

var _overlay: MultiMeshInstance3D = null
var _score_lbl: Label = null
var _title_lbl: Label = null
var _layer_buttons: Dictionary = {}
var _toast_lbl: Label = null
var _toast_t: float = 0.0


func _ready() -> void:
	_editor = get_node_or_null("GridEditorDesktop3D")
	_build_overlay()
	_build_lines()
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
		elif event.keycode == KEY_G and _bound and _active == "artifacts":
			_auto_organize_artifacts()
			_toast("auto-organized (preview) — Enter to apply")
		elif (event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER) and _bound and _active == "artifacts" and not _organized.is_empty():
			_apply_artifacts()


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
	_clear_lines()
	match _active:
		"pathfind": _layer_pathfind()
		"artifacts": _layer_artifacts()
		"grid": _layer_grid()
		"gameplay": _layer_gameplay()
		"graph": _layer_graph()
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


# ── ONTOLOGY GRAPH layer: concept-distance edges in 3D + spatial↔conceptual fidelity ──
var _mindmaps: Array = []   # [{lk2co: Dictionary, dist: Array(NxN)}]
var _lines: MeshInstance3D = null

func _build_lines() -> void:
	_lines = MeshInstance3D.new()
	_lines.name = "ForemanLines"
	_lines.mesh = ImmediateMesh.new()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_lines.material_override = mat
	add_child(_lines)


func _paint_lines(segments: Array) -> void:
	var im := _lines.mesh as ImmediateMesh
	im.clear_surfaces()
	if segments.is_empty():
		return
	im.surface_begin(Mesh.PRIMITIVE_LINES)
	for s in segments:
		im.surface_set_color(s["color"])
		im.surface_add_vertex(s["a"])
		im.surface_set_color(s["color"])
		im.surface_add_vertex(s["b"])
	im.surface_end()


func _clear_lines() -> void:
	if _lines and _lines.mesh is ImmediateMesh:
		(_lines.mesh as ImmediateMesh).clear_surfaces()


func _load_mindmaps() -> void:
	var dir := DirAccess.open("res://doc")
	if dir == null:
		_mindmaps.append({"lk2co": {}, "dist": []})   # mark loaded
		return
	for fn in dir.get_files():
		if not fn.ends_with("_mindmap.json"):
			continue
		var f := FileAccess.open("res://doc/" + fn, FileAccess.READ)
		if f == null:
			continue
		var d = JSON.parse_string(f.get_as_text())
		if not (d is Dictionary):
			continue
		var lk2co: Dictionary = {}
		for art in d.get("artifacts", []):
			if art is Dictionary and art.has("lookup") and art.has("concept_order"):
				lk2co[str(art["lookup"])] = int(art["concept_order"])
		_mindmaps.append({"lk2co": lk2co, "dist": d.get("concept_distance", [])})


func _resolve_concept(name: String) -> Dictionary:
	for i in _mindmaps.size():
		if _mindmaps[i]["lk2co"].has(name):
			return {"mm": i, "co": int(_mindmaps[i]["lk2co"][name])}
	return {"mm": -1, "co": -1}


func _concept_dist(mm: int, a: int, b: int) -> float:
	var dist = _mindmaps[mm]["dist"]
	if not (dist is Array) or a < 0 or b < 0 or a >= dist.size():
		return -1.0
	var row = dist[a]
	if not (row is Array) or b >= row.size():
		return -1.0
	return float(row[b])


func _ranks(arr: Array) -> Array:
	var idx: Array = []
	for i in arr.size():
		idx.append(i)
	idx.sort_custom(func(i, j): return arr[i] < arr[j])
	var ranks: Array = []
	ranks.resize(arr.size())
	for r in arr.size():
		ranks[idx[r]] = float(r)
	return ranks


func _spearman(a: Array, b: Array) -> float:
	var n := a.size()
	if n < 3:
		return 0.0
	var ra := _ranks(a)
	var rb := _ranks(b)
	var ma := 0.0
	var mb := 0.0
	for i in n:
		ma += ra[i]
		mb += rb[i]
	ma /= float(n)
	mb /= float(n)
	var num := 0.0
	var da := 0.0
	var db := 0.0
	for i in n:
		var xa: float = ra[i] - ma
		var xb: float = rb[i] - mb
		num += xa * xb
		da += xa * xa
		db += xb * xb
	if da == 0.0 or db == 0.0:
		return 0.0
	return num / sqrt(da * db)


func _layer_graph() -> void:
	if _mindmaps.is_empty():
		_load_mindmaps()
	var arts := _artifact_list()
	var nodes: Array = []
	for a in arts:
		var res := _resolve_concept(a["name"])
		if int(res["mm"]) >= 0:
			var anc: Vector2i = a["anchor"]
			nodes.append({
				"anchor": anc, "mm": int(res["mm"]), "co": int(res["co"]),
				"pos": Vector3((float(anc.x) + 0.5) * _cube, float(_height_at(anc.x, anc.y)) * _cube + 0.4, (float(anc.y) + 0.5) * _cube),
			})
	var spatial: Array = []
	var concep: Array = []
	var segments: Array = []
	for i in nodes.size():
		for j in range(i + 1, nodes.size()):
			var na: Dictionary = nodes[i]
			var nb: Dictionary = nodes[j]
			if int(na["mm"]) != int(nb["mm"]):
				continue
			var cd := _concept_dist(int(na["mm"]), int(na["co"]), int(nb["co"]))
			if cd < 0.0:
				continue
			var sd := Vector2(na["anchor"]).distance_to(Vector2(nb["anchor"]))
			spatial.append(sd)
			concep.append(cd)
			if cd < 0.28:   # conceptually close → these "want" to be spatially near
				var close_spatial: bool = sd <= 5.0
				var col := Color(0.3, 0.9, 0.45, 0.7) if close_spatial else Color(0.95, 0.35, 0.3, 0.6)
				segments.append({"a": na["pos"], "b": nb["pos"], "color": col})
	var fid := _spearman(spatial, concep)
	var fid01 := clampf((fid + 1.0) * 0.5, 0.0, 1.0)
	var quads: Array = []
	for n in nodes:
		quads.append(_q(n["anchor"], Color(0.4, 0.7, 1.0, 0.7)))
	_paint_overlay(quads)
	_paint_lines(segments)
	_set_score("ONTOLOGY GRAPH    %d concept-nodes    %d affinity edges (green=near, red=split)    fidelity %d%%" % [
		nodes.size(), segments.size(), int(round(fid01 * 100.0))])


# ── shared helpers (reachability + quad-at-cell) ─────────────────────
func _q(c: Vector2i, col: Color) -> Dictionary:
	var ty := float(_height_at(c.x, c.y)) * _cube + 0.08
	return {"pos": Vector3((float(c.x) + 0.5) * _cube, ty, (float(c.y) + 0.5) * _cube), "color": col}


func _reachable_from(spawn: Vector2i) -> Dictionary:
	var reachable: Dictionary = {}
	if spawn == Vector2i(-1, -1):
		return reachable
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
			if nh < 1 or abs(nh - ch) > 1:
				continue
			reachable[nc] = true
			q.append(nc)
	return reachable


func _cell_reachable(c: Vector2i, reachable: Dictionary) -> bool:
	for nb in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		if reachable.has(c + nb):
			return true
	return false


# ── GAMEPLAY layer: spawn / teleporter / hazards + encounter-order path ──
func _layer_gameplay() -> void:
	var spawn := _find_spawn()
	var reachable := _reachable_from(spawn)
	var teles: Array = []
	var hazards: Array = []
	var g := _token_grid("_utilities")
	for z in range(min(g.size(), _d)):
		var row = g[z]
		if not (row is Array):
			continue
		for x in range(min(row.size(), _w)):
			var t := str(row[x]).strip_edges().to_lower()
			if t == "t" or t.begins_with("t:"):
				teles.append(Vector2i(x, z))
			elif t == "h" or t.begins_with("h:"):
				hazards.append(Vector2i(x, z))
	var arts := _artifact_cells()

	# Encounter order: greedy nearest reachable artifact from spawn.
	var order: Array = []
	var remaining := arts.duplicate()
	var cur := spawn
	while not remaining.is_empty():
		var best := -1
		var bestd := 1000000
		for i in remaining.size():
			if not _cell_reachable(remaining[i], reachable):
				continue
			var dd: int = abs(remaining[i].x - cur.x) + abs(remaining[i].y - cur.y)
			if dd < bestd:
				bestd = dd
				best = i
		if best < 0:
			break
		order.append(remaining[best])
		cur = remaining[best]
		remaining.remove_at(best)

	var walk_len := 0
	var p := spawn
	for c in order:
		walk_len += abs(c.x - p.x) + abs(c.y - p.y)
		p = c
	if not teles.is_empty():
		walk_len += abs(teles[0].x - p.x) + abs(teles[0].y - p.y)
	var tele_ok := 0
	for tl in teles:
		if _cell_reachable(tl, reachable):
			tele_ok += 1

	var ordered := {}
	for c in order:
		ordered[c] = true
	var quads: Array = []
	if spawn != Vector2i(-1, -1):
		quads.append(_q(spawn, Color(0.2, 0.55, 1.0, 0.92)))      # spawn = blue
	for tl in teles:
		quads.append(_q(tl, Color(0.72, 0.32, 0.96, 0.92) if _cell_reachable(tl, reachable) else Color(0.4, 0.15, 0.5, 0.85)))
	for hz in hazards:
		quads.append(_q(hz, Color(1.0, 0.25, 0.15, 0.88)))        # hazard = red
	for i in order.size():
		var tt := float(i) / float(maxi(order.size() - 1, 1))     # encounter order: green → amber
		quads.append(_q(order[i], Color(0.3, 0.9, 0.4).lerp(Color(0.96, 0.6, 0.12), tt)))
	for a in arts:
		if not ordered.has(a):
			quads.append(_q(a, Color(0.5, 0.5, 0.55, 0.7)))       # unreachable artifact = grey
	_paint_overlay(quads)
	_set_score("GAMEPLAY    spawn %s    teleporters %d/%d reachable    encounter %d/%d artifacts    walk ~%d cells" % [
		"OK" if spawn != Vector2i(-1, -1) else "MISSING", tele_ok, teles.size(), order.size(), arts.size(), walk_len])


# ── GRID layer: height heatmap lens + fill score ─────────────────────
func _layer_grid() -> void:
	var floor := 0
	var maxh := 1
	for z in _d:
		for x in _w:
			var h := _height_at(x, z)
			if h >= 1:
				floor += 1
				maxh = maxi(maxh, h)
	var total := _w * _d
	var quads: Array = []
	for z in _d:
		for x in _w:
			var h := _height_at(x, z)
			if h < 1:
				continue
			var t := float(h - 1) / float(maxi(maxh - 1, 1))   # 0..1 across the height range
			var col := Color(0.15, 0.4, 0.9).lerp(Color(0.96, 0.85, 0.2), t)   # low blue → high yellow
			col.a = 0.55
			var ty := float(h) * _cube + 0.06
			quads.append({"pos": Vector3((float(x) + 0.5) * _cube, ty, (float(z) + 0.5) * _cube), "color": col})
	_paint_overlay(quads)
	_set_score("GRID    fill %d%% (%d/%d cells floor)    heights 1..%d" % [
		int(round(100.0 * float(floor) / float(maxi(total, 1)))), floor, total, maxh])


# ── ARTIFACTS layer: footprint lens + fit/wall/isolate/cluster score + auto-organize ──
var _spatial_cache: Dictionary = {}

func _spatial_for(name: String) -> Dictionary:
	if _spatial_cache.is_empty():
		var dir := DirAccess.open("res://commons/artifacts/registry")
		if dir:
			for fn in dir.get_files():
				if not fn.ends_with(".json"):
					continue
				var f := FileAccess.open("res://commons/artifacts/registry/" + fn, FileAccess.READ)
				if f == null:
					continue
				var data = JSON.parse_string(f.get_as_text())
				if not (data is Dictionary):
					continue
				for k in (data.get("artifacts", {}) as Dictionary).keys():
					var v = data["artifacts"][k]
					if v is Dictionary:
						_spatial_cache[str(v.get("lookup_name", k))] = v.get("spatial_needs", {})
		if _spatial_cache.is_empty():
			_spatial_cache["__none__"] = {}   # mark loaded even if empty
	return _spatial_cache.get(name, {})


func _footprint_of(sn: Dictionary) -> Vector2i:
	var fc = sn.get("footprint_cells", 1)
	if fc is Array and (fc as Array).size() >= 2:
		return Vector2i(maxi(int(fc[0]), 1), maxi(int(fc[1]), 1))
	var n := int(fc) if (fc is int or fc is float) else 1
	var side := maxi(1, int(round(sqrt(float(maxi(n, 1))))))
	return Vector2i(side, side)


func _artifact_list() -> Array:
	# [{name, anchor:Vector2i, fw, fd, wall:bool, iso:bool, cluster:Array}]
	var out: Array = []
	var g := _token_grid("_interactables")
	for z in range(min(g.size(), _d)):
		var row = g[z]
		if not (row is Array):
			continue
		for x in range(min(row.size(), _w)):
			var t := str(row[x]).strip_edges()
			if t == "" or t == " " or t.begins_with("#"):
				continue
			# tokens are "lookup:rotation:y_offset" — strip to the lookup name.
			var name := t.split(":")[0].strip_edges()
			var sn := _spatial_for(name)
			var fp := _footprint_of(sn)
			out.append({
				"name": name, "anchor": Vector2i(x, z), "fw": fp.x, "fd": fp.y,
				"wall": bool(sn.get("wall_backing", false)),
				"iso": int(sn.get("isolation", 0)) >= 2,
				"cluster": sn.get("cluster_with", []),
			})
	return out


func _footprint_cells(a: Dictionary) -> Array:
	var cells: Array = []
	for dx in int(a["fw"]):
		for dz in int(a["fd"]):
			cells.append(Vector2i(a["anchor"].x + dx, a["anchor"].y + dz))
	return cells


func _wall_behind(a: Dictionary) -> bool:
	var z: int = a["anchor"].y - 1
	if z < 0:
		return true   # against the grid edge counts as backed
	return _height_at(a["anchor"].x, z) < 1   # non-floor (wall/void) behind = backed


func _iso_ok(a: Dictionary, arts: Array) -> bool:
	for b in arts:
		if b["anchor"] == a["anchor"]:
			continue
		var dist: int = abs(b["anchor"].x - a["anchor"].x) + abs(b["anchor"].y - a["anchor"].y)
		if dist <= 2:
			return false
	return true


func _cluster_ok(a: Dictionary, name_anchor: Dictionary) -> bool:
	var any_present := false
	for partner in a["cluster"]:
		var pn := str(partner)
		if name_anchor.has(pn):
			any_present = true
			var pa: Vector2i = name_anchor[pn]
			if abs(pa.x - a["anchor"].x) + abs(pa.y - a["anchor"].y) <= 4:
				return true
	return not any_present


func _layer_artifacts() -> void:
	var arts := _artifact_list()
	var occ: Dictionary = {}
	for a in arts:
		for cell in _footprint_cells(a):
			occ[cell] = int(occ.get(cell, 0)) + 1
	var name_anchor: Dictionary = {}
	for a in arts:
		name_anchor[a["name"]] = a["anchor"]

	var fit_ok := 0
	var wall_ok := 0
	var wall_total := 0
	var iso_ok := 0
	var iso_total := 0
	var clus_ok := 0
	var clus_total := 0
	var quads: Array = []
	for a in arts:
		var cells := _footprint_cells(a)
		var on_floor := true
		var overlap := false
		for cell in cells:
			if cell.x < 0 or cell.x >= _w or cell.y < 0 or cell.y >= _d or _height_at(cell.x, cell.y) < 1:
				on_floor = false
			if int(occ.get(cell, 0)) > 1:
				overlap = true
		var fit := on_floor and not overlap
		if fit:
			fit_ok += 1
		var wb_ok := true
		if a["wall"]:
			wall_total += 1
			wb_ok = _wall_behind(a)
			if wb_ok:
				wall_ok += 1
		var io_ok := true
		if a["iso"]:
			iso_total += 1
			io_ok = _iso_ok(a, arts)
			if io_ok:
				iso_ok += 1
		var cl_ok := true
		if a["cluster"] is Array and (a["cluster"] as Array).size() > 0:
			clus_total += 1
			cl_ok = _cluster_ok(a, name_anchor)
			if cl_ok:
				clus_ok += 1
		var col: Color
		if not fit:
			col = Color(0.9, 0.2, 0.2, 0.62)              # off-floor / overlap
		elif not (wb_ok and io_ok and cl_ok):
			col = Color(0.95, 0.6, 0.12, 0.6)             # soft-hook violation
		else:
			col = Color(0.25, 0.7, 0.92, 0.5)             # well placed
		for cell in cells:
			if cell.x < 0 or cell.x >= _w or cell.y < 0 or cell.y >= _d:
				continue
			var ty := float(_height_at(cell.x, cell.y)) * _cube + 0.07
			quads.append({"pos": Vector3((float(cell.x) + 0.5) * _cube, ty, (float(cell.y) + 0.5) * _cube), "color": col})
	_paint_overlay(quads)
	_set_score("ARTIFACTS    fit %d/%d    wall %d/%d    isolate %d/%d    cluster %d/%d        [G = auto-organize]" % [
		fit_ok, arts.size(), wall_ok, wall_total, iso_ok, iso_total, clus_ok, clus_total])


# Greedy auto-organize: pack every artifact onto floor cells, largest first, no overlap. Preview only.
func _auto_organize_artifacts() -> void:
	var arts := _artifact_list()
	var floor_cells: Array = []
	for z in _d:
		for x in _w:
			if _height_at(x, z) >= 1:
				floor_cells.append(Vector2i(x, z))
	arts.sort_custom(func(a, b): return int(a["fw"]) * int(a["fd"]) > int(b["fw"]) * int(b["fd"]))
	var taken: Dictionary = {}
	var placed: Dictionary = {}
	for a in arts:
		var best := Vector2i(-1, -1)
		for cell in floor_cells:
			var ok := true
			for dx in int(a["fw"]):
				for dz in int(a["fd"]):
					var c := Vector2i(cell.x + dx, cell.y + dz)
					if c.x >= _w or c.y >= _d or _height_at(c.x, c.y) < 1 or taken.has(c):
						ok = false
			if ok:
				best = cell
				break
		if best != Vector2i(-1, -1):
			for dx in int(a["fw"]):
				for dz in int(a["fd"]):
					taken[Vector2i(best.x + dx, best.y + dz)] = true
			placed[a["anchor"]] = best
	var quads: Array = []
	for a in arts:
		var anc: Vector2i = placed.get(a["anchor"], a["anchor"])
		for dx in int(a["fw"]):
			for dz in int(a["fd"]):
				var c := Vector2i(anc.x + dx, anc.y + dz)
				if c.x < 0 or c.x >= _w or c.y < 0 or c.y >= _d:
					continue
				var ty := float(_height_at(c.x, c.y)) * _cube + 0.08
				quads.append({"pos": Vector3((float(c.x) + 0.5) * _cube, ty, (float(c.y) + 0.5) * _cube), "color": Color(0.3, 0.9, 0.42, 0.62)})
	_organized = placed
	_paint_overlay(quads)
	_set_score("ARTIFACTS · auto-organized preview — %d/%d packed, no overlap    [Enter = apply to map · R = cancel]" % [placed.size(), arts.size()])


# Apply the previewed auto-organize to the real map: move each artifact to its suggested cell by
# driving the editor's own despawn/spawn + rewriting its _interactables data, so a Save (W) persists it.
func _apply_artifacts() -> void:
	if _organized.is_empty():
		_toast("press G to auto-organize first")
		return
	var inter = _editor.get("_interactables")
	if not (inter is Array):
		_toast("cannot reach the editor's interactables layer")
		return
	if _editor.has_method("_push_artifact_undo"):
		_editor._push_artifact_undo()   # so Ctrl+Z in the editor can undo the whole apply
	var moves: Array = []
	for old in _organized:
		var nw: Vector2i = _organized[old]
		if old == nw:
			continue
		if old.y < 0 or old.y >= inter.size() or old.x < 0 or old.x >= (inter[old.y] as Array).size():
			continue
		var token := str(inter[old.y][old.x])
		if token.strip_edges() in ["", " "]:
			continue
		moves.append({"token": token, "old": old, "new": nw})
	# Clear + despawn every source first, so moves into vacated cells don't collide.
	for m in moves:
		var o: Vector2i = m["old"]
		if _editor.has_method("_despawn_artifact_at"):
			_editor._despawn_artifact_at(o.x, o.y)
		inter[o.y][o.x] = " "
	# Write + spawn at the destinations (data keeps the full token; spawn uses the bare lookup).
	var done := 0
	for m in moves:
		var dst: Vector2i = m["new"]
		if dst.y < 0 or dst.y >= inter.size() or dst.x < 0 or dst.x >= (inter[dst.y] as Array).size():
			continue
		inter[dst.y][dst.x] = m["token"]
		if _editor.has_method("_spawn_artifact"):
			_editor._spawn_artifact(dst.x, dst.y, str(m["token"]).split(":")[0])
		done += 1
	_organized.clear()
	_refresh()
	_toast("applied — %d artifacts moved · press W in the editor to save" % done)
