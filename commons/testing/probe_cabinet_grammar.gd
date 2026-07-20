## probe_cabinet_grammar.gd
##
## Measures every element of every cabinet-family artifact against the canon
## in commons/data/cabinet_grammar.json, and writes a report.
##
## The point (Palle 2026-07-20: "make sure every element in each artifact is
## aligned in the right way, it must look consistent"): consistency cannot
## live in my head as remembered magic numbers. It has to be MEASURED — the
## artifact is instantiated, its whole tree walked, and each rule evaluated
## against the actual node transforms and materials.
##
## Run:
##   godot --path . --xr-mode off --no-window \
##     --script res://commons/testing/probe_cabinet_grammar.gd
##
## Writes: doc/reports/cabinet_grammar_report.json  (repo-relative)
## Gate:   python tools/check_cabinet_grammar.py

extends SceneTree

const CANON_PATH := "res://commons/data/cabinet_grammar.json"
const REPORT_PATH := "res://doc/reports/cabinet_grammar_report.json"


func _initialize() -> void:
	_run()


func _run() -> void:
	var canon: Dictionary = _load_json(CANON_PATH)
	if canon.is_empty():
		push_error("cabinet_grammar.json unreadable")
		quit(2)
		return

	var palette: Dictionary = canon.get("palette", {})
	var members: Array = canon.get("members", [])
	var results: Array = []

	for m in members:
		var entry: Dictionary = m
		results.append(await _probe(entry, palette))

	var violations := 0
	for r in results:
		violations += int(r.get("violations", 0))

	var report := {
		"canon_version": canon.get("version", 0),
		"artifacts": results,
		"total_violations": violations,
	}
	_write_json(REPORT_PATH, report)
	print("cabinet grammar probe: %d artifacts, %d violations" % [results.size(), violations])
	quit(0)


func _probe(entry: Dictionary, palette: Dictionary) -> Dictionary:
	var name: String = str(entry.get("artifact", "?"))
	var dialect: String = str(entry.get("dialect", "vertical"))
	var scene_path: String = str(entry.get("scene", ""))
	var out := {
		"artifact": name, "dialect": dialect, "body": entry.get("body", ""),
		"findings": [], "violations": 0,
	}

	if not ResourceLoader.exists(scene_path):
		out["findings"] = [{"rule": "-", "ok": false, "detail": "scene missing: " + scene_path}]
		out["violations"] = 1
		return out

	var packed: PackedScene = load(scene_path)
	var inst: Node = packed.instantiate()
	root.add_child(inst)

	# _ready builds the procedural body — it has NOT run yet at add_child
	# time. Two frames is the project's settled convention.
	await process_frame
	await process_frame

	if inst.get_script() == null:
		out["findings"] = [{"rule": "-", "ok": false,
			"detail": "scene instantiated SCRIPTLESS — the .gd failed to compile"}]
		out["violations"] = 1
		inst.queue_free()
		return out

	# let _ready build the procedural body
	var meshes: Array = []
	var texts: Array = []
	var mats: Array = []          # housing materials only — see _walk
	var housing_meshes: Array = []
	_walk(inst, meshes, texts, mats, housing_meshes, false)
	# if no housing node exists yet the whole artifact is the subject
	if housing_meshes.is_empty():
		housing_meshes = meshes

	var findings: Array = []

	# ── G2 grounded ──────────────────────────────────────────────────────
	var min_y := INF
	var max_y := -INF
	var tallest: Node = null
	var housing_aabb := AABB()
	var have_aabb := false
	for mi in meshes:
		var m: MeshInstance3D = mi
		var wab: AABB = m.global_transform * m.get_aabb()
		var lo: float = wab.position.y
		var hi: float = wab.position.y + wab.size.y
		min_y = minf(min_y, lo)
		if hi > max_y:
			max_y = hi
			tallest = m
		if have_aabb:
			housing_aabb = housing_aabb.merge(wab)
		else:
			housing_aabb = wab
			have_aabb = true
	findings.append({
		"rule": "G2-grounded", "ok": min_y < 0.06 and min_y > -0.20,
		"detail": "lowest element y = %.3f" % min_y,
	})

	# ── G1 no orphan text ────────────────────────────────────────────────
	var inflated := housing_aabb.grow(0.12)
	var orphans: Array = []
	for t in texts:
		var n: Node3D = t
		if not inflated.has_point(n.global_position):
			orphans.append("%s @ %.2f,%.2f,%.2f" % [n.name,
				n.global_position.x, n.global_position.y, n.global_position.z])
	findings.append({
		"rule": "G1-no-orphan-text", "ok": orphans.is_empty(),
		"detail": ("all %d text nodes inside the body" % texts.size()) if orphans.is_empty()
			else ("floating: " + ", ".join(orphans)),
	})

	# ── G3 silhouette (horizontal only) ──────────────────────────────────
	if dialect == "horizontal":
		var h_max := -INF
		var h_tall: Node = null
		for hm in housing_meshes:
			var hab: AABB = (hm as MeshInstance3D).global_transform * (hm as MeshInstance3D).get_aabb()
			if hab.position.y + hab.size.y > h_max:
				h_max = hab.position.y + hab.size.y
				h_tall = hm
		max_y = h_max
		tallest = h_tall
		# deck = the artifact's table/board height; read the tallest STATIC
		# surface that is not console furniture, else fall back to a probe.
		var deck_y: float = _guess_deck_y(inst)
		var over: float = max_y - (deck_y + 0.10)
		findings.append({
			"rule": "G3-silhouette", "ok": over <= 0.0,
			"detail": "deck %.3f, tallest %.3f = %s (%+.3f vs the 0.10 allowance)" % [
				deck_y, max_y, _path(inst, tallest), over],
		})

	# ── G4 palette ───────────────────────────────────────────────────────
	var canon_cols: Array = []
	for k in palette.keys():
		if str(k).begins_with("_"):
			continue
		var arr: Array = palette[k]
		canon_cols.append([str(k), Color(arr[0], arr[1], arr[2])])
	var drift: Array = []
	var matched := 0
	for mm in mats:
		var c: Color = mm[1]
		var best := 9.0
		for cc in canon_cols:
			var d: float = absf(c.r - cc[1].r) + absf(c.g - cc[1].g) + absf(c.b - cc[1].b)
			if _is_kin(c, cc[1]):
				d = 0.0          # a derived tint of canon IS canon
			best = minf(best, d)
		if best <= 0.06:
			matched += 1
		elif best <= 0.20:
			# near-miss: close enough to LOOK like canon but not canon — the
			# drift that quietly breaks a family
			drift.append("%s rgb(%.2f,%.2f,%.2f) off by %.3f" % [mm[0], c.r, c.g, c.b, best])
	findings.append({
		"rule": "G4-palette", "ok": drift.is_empty(),
		"detail": ("%d canon materials, no near-miss drift" % matched) if drift.is_empty()
			else ("near-miss: " + ", ".join(drift)),
	})

	# ── G5 reach ─────────────────────────────────────────────────────────
	var pad: Node = _find_pad(inst)
	if pad != null:
		var py: float = (pad as Node3D).global_position.y
		findings.append({
			"rule": "G5-reach", "ok": py >= 0.75 and py <= 1.35,
			"detail": "keypad centre y = %.3f" % py,
		})

	# ── G6 screens seated ────────────────────────────────────────────────
	var glass_nodes: Array = []
	var pockets: Array = []
	for mi2 in housing_meshes:
		var m2: MeshInstance3D = mi2
		var mat: Material = m2.material_override
		if mat is StandardMaterial3D:
			var sc: Color = (mat as StandardMaterial3D).albedo_color
			if absf(sc.r - 0.04) < 0.03 and absf(sc.g - 0.05) < 0.03 and absf(sc.b - 0.08) < 0.04:
				glass_nodes.append(m2)
			elif absf(sc.r - 0.07) < 0.02 and absf(sc.g - 0.075) < 0.02 and absf(sc.b - 0.09) < 0.02:
				pockets.append(m2)
	var unseated: Array = []
	for g in glass_nodes:
		var gp: Vector3 = (g as MeshInstance3D).global_position
		var seated := false
		for pk in pockets:
			if gp.distance_to((pk as MeshInstance3D).global_position) <= 0.06:
				seated = true
				break
		if not seated:
			unseated.append(_path(inst, g))
	findings.append({
		"rule": "G6-screen-seated", "ok": unseated.is_empty(),
		"detail": ("%d glass panels, all pocketed" % glass_nodes.size()) if unseated.is_empty()
			else ("unpocketed: " + ", ".join(unseated)),
	})

	# ── G7 ember present ─────────────────────────────────────────────────
	var emissive := 0
	for mm2 in mats:
		var c2: Color = mm2[1]
		if absf(c2.r - 0.86) < 0.06 and absf(c2.g - 0.30) < 0.06 and absf(c2.b - 0.10) < 0.06:
			emissive += 1
	findings.append({
		"rule": "G7-accent-present", "ok": emissive > 0,
		"detail": "%d ember elements" % emissive,
	})

	var v := 0
	for f in findings:
		if not bool(f.get("ok", false)):
			v += 1
	out["findings"] = findings
	out["violations"] = v
	out["element_count"] = meshes.size()
	inst.queue_free()
	return out


## Is `c` a lightened/darkened tint of canon colour `base`? BakedText bezels
## use bg.lightened(0.22); a rail adopts its table's wood lightened(0.18).
## Those are the family speaking, not drift — so kinship counts as canon.
## (Found by the checker flagging its own shared infrastructure, 2026-07-20.)
func _is_kin(c: Color, base: Color) -> bool:
	for toward_white in [true, false]:
		var ts: Array = []
		var ok := true
		for ch in 3:
			var cv: float = [c.r, c.g, c.b][ch]
			var bv: float = [base.r, base.g, base.b][ch]
			var t: float
			if toward_white:
				if 1.0 - bv < 0.02:
					continue
				t = (cv - bv) / (1.0 - bv)
			else:
				if bv < 0.02:
					continue
				t = 1.0 - cv / bv
			if t < -0.02 or t > 1.02:
				ok = false
				break
			ts.append(t)
		if ok and ts.size() >= 2:
			var lo: float = ts.min()
			var hi: float = ts.max()
			if hi - lo <= 0.10:
				return true
	return false


## Node path relative to the artifact root — auto-names like
## "@MeshInstance3D@678" tell you nothing; the parent chain does.
func _path(root_node: Node, n: Node) -> String:
	if n == null:
		return "?"
	var parts: PackedStringArray = []
	var cur: Node = n
	var guard := 0
	while cur != null and cur != root_node and guard < 8:
		parts.insert(0, str(cur.name))
		cur = cur.get_parent()
		guard += 1
	return "/".join(parts)


func _short(n: Node) -> String:
	var nm: String = str(n.name)
	if nm.begins_with("@") and n.get_parent() != null:
		return "%s/%s" % [str(n.get_parent().name), nm]
	return nm


## `in_housing` tracks whether we are inside the Cabinet / TableConsole
## subtree — the part the grammar governs. Baked text tags are skipped for
## material purposes: their backing plates are typography, not housing.
func _walk(n: Node, meshes: Array, texts: Array, mats: Array,
		housing: Array, in_housing: bool, in_tag: bool = false) -> void:
	var nm: String = str(n.name)
	var is_tag: bool = in_tag or nm.ends_with("Tag") or nm.begins_with("BakedText")
	if nm == "Cabinet" or nm == "TableConsole":
		in_housing = true

	if n is MeshInstance3D:
		meshes.append(n)
		if in_housing and not is_tag:
			housing.append(n)
			var mat: Material = (n as MeshInstance3D).material_override
			if mat is StandardMaterial3D:
				var sm := mat as StandardMaterial3D
				if sm.albedo_texture == null:   # textured = baked text, not paint
					mats.append([_short(n), sm.albedo_color])
	if n is Label3D:
		texts.append(n)
	elif n is Node3D and is_tag:
		texts.append(n)

	for c in n.get_children():
		_walk(c, meshes, texts, mats, housing, in_housing, is_tag)


## The deck plane of a horizontal artifact: its table/board surface.
func _guess_deck_y(inst: Node) -> float:
	for prop in ["table_height", "board_height", "deck_height", "pedestal_height"]:
		if prop in inst:
			return float(inst.get(prop))
	return 0.85


func _find_pad(n: Node) -> Node:
	if n.get_node_or_null("InteractableAreaButton") != null:
		return n.get_parent()
	for c in n.get_children():
		var r: Node = _find_pad(c)
		if r != null:
			return r
	return null


func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	return parsed if parsed is Dictionary else {}


func _write_json(path: String, data: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(data, "\t"))
	f.close()
