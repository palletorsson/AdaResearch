extends SceneTree
## Walk-order probe for em_sets._slot_before, across the whole museum corpus.
##
## Throwaway. Lives ONLY in the detached worktree tools/spine_run.py creates, so
## the repository's working tree is never touched by the measurement.
##
## It calls the REAL `EmSets.build_set()` — the function d1adfb394 changed — on
## the REAL slot arrays of all 30 museum-tagged templates, with the REAL
## relations database and the REAL spine lead order. The only thing that differs
## between arms is which version of `_slot_before` is on disk when it boots.
##
## Slots are collected exactly as endless_museum.gd::_build_segment collects
## them (lines 1131-1152): tile char `1s` -> rank 2, `2s` -> rank 1, `3s` ->
## rank 0, and z = tile row + VESTIBULE_H.
##
## WHAT IT DOES NOT MODEL: `_deal_segment`'s guest phase, `em_multiples`,
## `em_plinths`, and `_seal_cells`'s silent footprint refusal. Those are the
## museum's, not em_sets', and they are what the live segment boots measure.

const VESTIBULE_H := 2
const BUDGET := 8


func _init() -> void:
	var out_path := "res://ada_sort_probe.json"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_path = a.substr(6)

	var pats: Dictionary = _json("res://commons/data/template_patterns.json").get("patterns", {})
	var rel: Dictionary = _json("res://commons/data/artifact_relations.json")
	var order: Array = _json("res://commons/data/spine_artifact_order.json").get("order", [])

	var rel_arts: Dictionary = rel.get("artifacts", {})
	var leads: Array = []
	var seen: Dictionary = {}
	for row0 in order:
		var row: Dictionary = row0
		var tok := String(row.get("lookup", ""))
		if tok != "" and rel_arts.has(tok) and not seen.has(tok):
			seen[tok] = true
			leads.append(tok)

	var keys: Array = []
	for k in pats:
		if String(pats[k].get("museum", "")) != "":
			keys.append(k)
	keys.sort_custom(func(a, b):
		var oa := int(pats[a].get("em_order", 9999))
		var ob := int(pats[b].get("em_order", 9999))
		if oa != ob:
			return oa < ob
		return String(a) < String(b))

	var out: Dictionary = {"budget": BUDGET, "leads_available": leads.size(),
		"museums": {}}
	for k0 in keys:
		var key := String(k0)
		var tile: Array = pats[key].get("tile", [])
		var slots: Array = []
		for y in range(tile.size()):
			var row: Array = tile[y]
			var z: int = y + VESTIBULE_H
			for x in range(row.size()):
				var c := String(row[x])
				if c == "1s":
					slots.append({"x": x, "y": z, "top": 0.0, "rank": 2})
				elif c == "2s":
					slots.append({"x": x, "y": z, "top": 0.4, "rank": 1})
				elif c == "3s":
					slots.append({"x": x, "y": z, "top": 0.8, "rank": 0})
		# the input order build_set receives. It re-sorts internally, so this is
		# not what is under test — it is fixed here precisely so that the ONLY
		# variable across arms is _slot_before.
		slots.sort_custom(func(a, b):
			if int(a["y"]) != int(b["y"]):
				return int(a["y"]) < int(b["y"])
			if int(a["rank"]) != int(b["rank"]):
				return int(a["rank"]) < int(b["rank"])
			return int(a["x"]) < int(b["x"]))

		var free: Array = slots.duplicate()
		var depths: Array = []
		var lead_depths: Array = []
		var ranks: Array = []
		var roles: Array = []
		var tokens: Array = []
		var li := 0
		while free.size() > 0 and depths.size() < BUDGET and li < leads.size():
			var lead := String(leads[li])
			li += 1
			var room: int = BUDGET - depths.size()
			var set_pl: Array = EmSets.build_set(lead, free, rel, room)
			if set_pl.is_empty():
				continue
			for p0 in set_pl:
				var p: Dictionary = p0
				var cell: Dictionary = p.get("cell", {})
				if cell.is_empty():
					continue
				depths.append(int(cell.get("y", 0)))
				ranks.append(int(cell.get("rank", 2)))
				roles.append(String(p.get("role", "")))
				tokens.append(String(p.get("token", "")))
				if String(p.get("role", "")) == "lead":
					lead_depths.append(int(cell.get("y", 0)))
				for i in range(free.size() - 1, -1, -1):
					var f: Dictionary = free[i]
					if int(f["x"]) == int(cell.get("x", -1)) \
							and int(f["y"]) == int(cell.get("y", -1)):
						free.remove_at(i)
		out["museums"][key] = {
			"slots": slots.size(), "placed": depths.size(),
			"depths": depths, "lead_depths": lead_depths,
			"ranks": ranks, "roles": roles, "tokens": tokens,
			"deepest_slot": _max(slots), "leads_used": li,
		}
		print("[sort_probe] %s slots=%d placed=%d depths=%s" % [
			key, slots.size(), depths.size(), str(depths)])

	var f := FileAccess.open(out_path, FileAccess.WRITE)
	f.store_string(JSON.stringify(out))
	f.close()
	print("[sort_probe] wrote %s" % out_path)
	quit()


func _max(slots: Array) -> int:
	var m := 0
	for s in slots:
		m = maxi(m, int((s as Dictionary)["y"]))
	return m


func _json(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var v: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	return v if v is Dictionary else {}
