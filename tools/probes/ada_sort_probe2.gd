extends SceneTree
## Walk-order probe, second pass — MANY leads per building instead of one.
##
## ada_sort_probe.gd handed `build_set` the whole segment budget (8), so one
## lead's set swallowed it and every building placed exactly one lead. That
## makes a leads-only tau undefined: you cannot invert a sequence of one.
##
## The museum does not do that. `endless_museum.gd:1499` calls
##
##     set_budget = mini(1 + rel_per_lead, max_objects - placed)
##
## inside a `while placed < max_objects` loop, so a segment is MANY small sets,
## one per lead. That is the loop reproduced here: a per-lead budget of
## 1 + REL_PER_LEAD, spent until the segment budget or the slots run out.
##
## Everything else is identical to probe 1 — real EmSets.build_set, real slot
## arrays, real relations db, real spine lead order. Throwaway; lives only in
## the detached worktree.

const VESTIBULE_H := 2
const REL_PER_LEAD := 2
const SEG_BUDGET := 14


func _init() -> void:
	var out_path := "res://ada_sort_probe2.json"
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

	var out: Dictionary = {"seg_budget": SEG_BUDGET, "rel_per_lead": REL_PER_LEAD,
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
		slots.sort_custom(func(a, b):
			if int(a["y"]) != int(b["y"]):
				return int(a["y"]) < int(b["y"])
			if int(a["rank"]) != int(b["rank"]):
				return int(a["rank"]) < int(b["rank"])
			return int(a["x"]) < int(b["x"]))

		var free: Array = slots.duplicate()
		var depths: Array = []
		var lead_depths: Array = []
		var lead_ranks: Array = []
		var roles: Array = []
		var li := 0
		while free.size() > 0 and depths.size() < SEG_BUDGET and li < leads.size():
			var lead := String(leads[li])
			li += 1
			var set_budget: int = mini(1 + REL_PER_LEAD, SEG_BUDGET - depths.size())
			if set_budget <= 0:
				break
			var set_pl: Array = EmSets.build_set(lead, free, rel, set_budget)
			if set_pl.is_empty():
				continue
			for p0 in set_pl:
				var p: Dictionary = p0
				var cell: Dictionary = p.get("cell", {})
				if cell.is_empty():
					continue
				var role := String(p.get("role", ""))
				depths.append(int(cell.get("y", 0)))
				roles.append(role)
				if role == "lead":
					lead_depths.append(int(cell.get("y", 0)))
					lead_ranks.append(int(cell.get("rank", 2)))
				for i in range(free.size() - 1, -1, -1):
					var f: Dictionary = free[i]
					if int(f["x"]) == int(cell.get("x", -1)) \
							and int(f["y"]) == int(cell.get("y", -1)):
						free.remove_at(i)
		out["museums"][key] = {
			"slots": slots.size(), "placed": depths.size(),
			"depths": depths, "lead_depths": lead_depths,
			"ranks": lead_ranks, "roles": roles,
			"deepest_slot": _max(slots), "leads_used": lead_depths.size(),
		}
		print("[probe2] %s slots=%d placed=%d leads=%d depths=%s" % [
			key, slots.size(), depths.size(), lead_depths.size(), str(depths)])

	var f := FileAccess.open(out_path, FileAccess.WRITE)
	f.store_string(JSON.stringify(out))
	f.close()
	print("[probe2] wrote %s" % out_path)
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
