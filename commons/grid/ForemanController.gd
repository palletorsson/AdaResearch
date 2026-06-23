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
	{"id": "graph", "label": "ONTOLOGY GRAPH", "ready": false},
	{"id": "gameplay", "label": "GAMEPLAY", "ready": false},
	{"id": "grid", "label": "GRID", "ready": true},
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
		elif event.keycode == KEY_G and _bound and _active == "artifacts":
			_auto_organize_artifacts()
			_toast("auto-organized (preview)")


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
		"artifacts": _layer_artifacts()
		"grid": _layer_grid()
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
			var sn := _spatial_for(t)
			var fp := _footprint_of(sn)
			out.append({
				"name": t, "anchor": Vector2i(x, z), "fw": fp.x, "fd": fp.y,
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
	_paint_overlay(quads)
	_set_score("ARTIFACTS · auto-organized preview — %d/%d packed onto floor, no overlap    [R = back to current]" % [placed.size(), arts.size()])
