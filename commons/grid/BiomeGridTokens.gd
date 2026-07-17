# BiomeGridTokens.gd — parser for the `biome` map layer (P-8 grammar).
#
# doc/plans/biome_grid_redesign.md is the law. Token language:
#
#   ""                                    → no biome on this cell
#   <kingdom>:<algo>:<role>[:<mod>=<val>...][:on=<trigger>:<response>[/<response>...]]
#   ::mute[...]                           → kingdom/algo may be empty for mute cells
#
#   kingdoms:  flora fungus fauna mineral water meta
#   roles:     seed field edge halo mute
#   mods:      d= density 0..1 · t= tier 1..5 · p= palette · clk= static|dwell|walk
#              rule= (algo param, e.g. CA rule) · any other k=v kept verbatim in mods
#   reactions: on=<trigger>:<response>[/<response>...]
#              triggers:  catalyst | catalyst.<mode> | touch | dwell | tick
#              responses: seed | step | claim | mute | unmute | mutate:<channel>
#
# Returned per token (always a Dictionary, never null):
#   { "empty": bool, "valid": bool, "kingdom": String, "algo": String,
#     "role": String, "mods": Dictionary, "reactions": Array[{trigger, responses}] }
#
# Maps without a biome layer never reach this parser (additive discipline).

class_name BiomeGridTokens

const KINGDOMS: Array = ["flora", "fungus", "fauna", "mineral", "water", "meta", ""]
const ROLES: Array = ["seed", "field", "edge", "halo", "mute"]
const RESPONSES: Array = ["seed", "step", "claim", "mute", "unmute"]


static func parse(raw: Variant) -> Dictionary:
	var out: Dictionary = {
		"empty": true, "valid": true,
		"kingdom": "", "algo": "", "role": "",
		"mods": {}, "reactions": [],
	}
	if raw == null:
		return out
	var s: String = String(raw).strip_edges()
	if s.is_empty():
		return out
	out["empty"] = false

	var parts: PackedStringArray = s.split(":")
	# positional head: kingdom : algo : role
	if parts.size() < 3:
		out["valid"] = false
		return out
	out["kingdom"] = parts[0].strip_edges()
	out["algo"] = parts[1].strip_edges()
	out["role"] = parts[2].strip_edges()
	if not KINGDOMS.has(out["kingdom"]) or not ROLES.has(out["role"]):
		out["valid"] = false
		return out
	# mute may omit kingdom/algo; every other role requires an algo unless field
	if out["role"] != "mute" and out["role"] != "field" and out["algo"].is_empty():
		out["valid"] = false
		return out

	# tail: k=v mods and on= reactions. on= consumes ITS OWN following segment
	# (trigger:response/response), so we walk with an index.
	var i: int = 3
	while i < parts.size():
		var seg: String = parts[i].strip_edges()
		if seg.begins_with("on="):
			var trigger: String = seg.substr(3)
			if i + 1 >= parts.size():
				out["valid"] = false
				return out
			var responses_raw: String = parts[i + 1].strip_edges()
			var responses: Array = []
			for r in responses_raw.split("/"):
				var rr: String = String(r).strip_edges()
				var ok: bool = RESPONSES.has(rr) or rr.begins_with("mutate")
				if not ok:
					out["valid"] = false
					return out
				responses.append(rr)
			var trig_ok: bool = trigger in ["catalyst", "touch", "dwell", "tick"] \
				or trigger.begins_with("catalyst.")
			if not trig_ok:
				out["valid"] = false
				return out
			out["reactions"].append({"trigger": trigger, "responses": responses})
			i += 2
			continue
		if seg.contains("="):
			var kv: PackedStringArray = seg.split("=", true, 1)
			out["mods"][kv[0].strip_edges()] = kv[1].strip_edges()
			i += 1
			continue
		if seg.is_empty():
			i += 1
			continue
		out["valid"] = false
		return out

	return out


# biome-2: grammar kingdom (+ algo, for flora) → BiomePaintDispatcher kingdom id
# (the painted-layer ints: tree 0, creature 1, flower 2, fungus 3). flora splits
# by algo — woody algos become trees, everything else flowers. mineral / water /
# meta have no substrate yet → -1, the caller keeps its pilot marker.
static func dispatch_kingdom_of(cell: Dictionary) -> int:
	match String(cell.get("kingdom", "")):
		"flora":
			var algo: String = String(cell.get("algo", ""))
			return 0 if algo in ["lsystem", "tree", "dna"] else 2
		"fungus":
			return 3
		"fauna":
			return 1
		_:
			return -1


# Convenience: density modifier as float (default 1.0), tier as int (default 2).
static func density_of(cell: Dictionary) -> float:
	var mods: Dictionary = cell.get("mods", {})
	if mods.has("d"):
		return clampf(String(mods["d"]).to_float(), 0.0, 1.0)
	return 1.0


static func tier_of(cell: Dictionary) -> int:
	var mods: Dictionary = cell.get("mods", {})
	if mods.has("t"):
		return clampi(String(mods["t"]).to_int(), 1, 5)
	return 2
