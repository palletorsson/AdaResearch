class_name EmEditor
extends RefCounted
## The in-museum placement editor — SPIKE 08's curator layer, v1.
##
## WHAT THIS IS NOT: a gizmo that writes node transforms. Every fault this week
## was two authors holding one number (the 4 m offset, symmetry's cast in
## change's room, capuchin vs the Uffizi), and a free-hand editor would be a
## THIRD author of placement — invisible to the plan, clobbered on regeneration,
## unexplainable by any trace.
##
## WHAT THIS IS: a hand that writes ada_run/em_overrides.json, keyed
## (chapter, token, from-cell), provenance "hand". The negotiator keeps its
## plan; the override rides on top at _deal_from_plan time; the live node moves
## immediately as a PREVIEW of what the next build will do. Hand authorship is
## doctrine — crowns are rulings, preferred_venue overrides derivation — as long
## as the overrule is a RECORDED decision. This file records it.
##
## Keys (desktop walker, --em-edit):
##   E            select the artifact nearest the crosshair
##   arrows       nudge the selection one cell (world x / z)
##   Q / R        rotate 90° CCW / CW (the GRID's sign: rotation_degrees.y)
##   DELETE       remove (soft-hides the node; the override records it)
##   F5           save overrides · F6 discard selection
##
## The museum owns the state (records, selection, overrides); this module is
## arithmetic and IO, stateless, like every other em/ module.

const OVERRIDES_PATH := "res://ada_run/em_overrides.json"


## Nearest editable record to the camera's crosshair. Scored by angle off the
## view axis with a distance tiebreak — no physics ray, so artifacts without
## colliders (plenty of the diagram class) are still selectable.
static func pick(cam: Camera3D, records: Array, max_dist: float = 24.0) -> int:
	if cam == null:
		return -1
	var origin: Vector3 = cam.global_position
	var fwd: Vector3 = -cam.global_transform.basis.z
	var best: int = -1
	var best_score: float = 0.25          # ~14° cone; outside it, nothing selects
	for i in range(records.size()):
		var r: Dictionary = records[i]
		var node: Node3D = r.get("node") as Node3D
		if node == null or not is_instance_valid(node):
			continue
		var to: Vector3 = node.global_position - origin
		var d: float = to.length()
		if d < 0.3 or d > max_dist:
			continue
		var ang: float = fwd.angle_to(to.normalized())
		var score: float = ang + d * 0.004    # angle rules; distance breaks ties
		if score < best_score:
			best_score = score
			best = i
	return best


## One override row per touched placement, keyed by where the PLAN put it —
## `from` is the plan's tile_cell, so the override survives regeneration and
## reports itself idle if the negotiator stops placing that row.
static func override_for(records: Array, idx: int, overrides: Array) -> Dictionary:
	var r: Dictionary = records[idx]
	var key_tok := String(r.get("token", ""))
	var key_from: Array = r.get("from", r.get("tile_cell", []))
	for ov in overrides:
		if String((ov as Dictionary).get("token", "")) == key_tok \
				and (ov as Dictionary).get("from", []) == key_from:
			return ov
	var ov: Dictionary = {
		"chapter": String(r.get("chapter", "")),
		"token": key_tok,
		"from": key_from.duplicate(),
		"to": key_from.duplicate(),
		"rotation": float(r.get("rotation", 0.0)),
		"remove": false,
		"provenance": "hand",
	}
	overrides.append(ov)
	return ov


static func save(overrides: Array, path: String = OVERRIDES_PATH) -> bool:
	var doc: Dictionary = {
		"schema": "adaresearch.em_overrides.v1",
		"_readme": ("Hand placement rulings over em_plan.json, written by the "
			+ "in-museum editor (--em-edit). Applied by _deal_from_plan on top "
			+ "of the negotiated plan; keyed (chapter, token, from-cell) so "
			+ "they survive plan regeneration. An override whose row the "
			+ "negotiator no longer places is reported idle, never guessed."),
		"overrides": overrides,
	}
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_warning("[em-edit] cannot write %s" % path)
		return false
	f.store_string(JSON.stringify(doc, "\t"))
	f.close()
	return true


static func load_file(path: String = OVERRIDES_PATH) -> Array:
	if not FileAccess.file_exists(path):
		return []
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (parsed is Dictionary):
		return []
	var rows: Variant = (parsed as Dictionary).get("overrides", [])
	return (rows as Array) if rows is Array else []


## The add-palette: what the current chapter's pool offers, in spine order.
## Chapter-scoped on purpose — 2,700 living tokens is a search problem, not a
## palette; the chapter's own cast is a handful and is what belongs here.
static func palette(pool: Array, chapter: String) -> Array:
	var out: Array = []
	for e in pool:
		if String((e as Dictionary).get("sequence", "")) == chapter:
			out.append({"token": String((e as Dictionary).get("lookup", "")),
				"scene": String((e as Dictionary).get("scene", ""))})
	return out


## An added row's DELETE should erase the ADD ruling, not mint a removal of a
## row the plan never held. True = an add was erased; false = not an add.
static func remove_add(records: Array, idx: int, overrides: Array) -> bool:
	var r: Dictionary = records[idx]
	var tok := String(r.get("token", ""))
	var at: Array = r.get("from", [])
	for i in range(overrides.size()):
		var ov: Dictionary = overrides[i]
		if bool(ov.get("add", false)) and String(ov.get("token", "")) == tok 				and ov.get("to", []) == at:
			overrides.remove_at(i)
			return true
	return false


static func hud(root: Node) -> Label:
	var layer := CanvasLayer.new()
	layer.name = "EmEditHud"
	layer.layer = 90
	var lbl := Label.new()
	lbl.name = "Text"
	lbl.position = Vector2(14, 14)
	lbl.add_theme_font_size_override("font_size", 15)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	lbl.add_theme_constant_override("shadow_offset_y", 1)
	layer.add_child(lbl)
	root.add_child(layer)
	return lbl


static func hud_text(records: Array, sel: int, overrides: Array, dirty: bool,
		pal: Array = [], pal_i: int = -1) -> String:
	var head := "[EDIT]  E select · arrows move · Q/R rotate · DEL remove · [ ] palette · ENTER add · F5 save"
	if pal_i >= 0 and pal_i < pal.size():
		head += "
add: %s  (%d/%d) — ENTER places it 2.5 m ahead" % [
			String((pal[pal_i] as Dictionary).get("token", "?")), pal_i + 1, pal.size()]
	var line2 := ""
	if sel >= 0 and sel < records.size():
		var r: Dictionary = records[sel]
		line2 = "\nselected: %s  cell %s  rot %.0f  (%s)" % [
			String(r.get("token", "?")), str(r.get("tile_cell", [])),
			float(r.get("rotation", 0.0)), String(r.get("chapter", "?"))]
	var pend := overrides.size()
	return head + line2 + ("\noverrides: %d%s" % [pend, "  *unsaved*" if dirty else ""]
		if pend > 0 or dirty else "")
