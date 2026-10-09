class_name ModifierStack
extends RefCounted

## Pure, deterministic, NON-DESTRUCTIVE applier of a grid modifier op-stack
## (the `modifiers` section proposed in doc/BRACELET_GARDEN_MODIFIERS.md).
##
## Operates on a grid-agnostic cell model so it can be unit-tested in isolation
## and later pointed at the real grid (GridStructureComponent's per-instance
## colors + heights) without changing this logic:
##
##   cells := { Vector2i(row, col): { "height": int, "color": Color } }
##
## apply(base, ops) returns a NEW modified map; the base is never mutated.
## Same (base, ops) -> same result. random_colors carries a seed, so "random"
## is reproducible. undo = drop the last op and re-apply (it's a pure function).

const DEFAULT_COLOR := Color(0.55, 0.56, 0.62)


static func apply(base_cells: Dictionary, mods: Array) -> Dictionary:
	var out: Dictionary = {}
	for k in base_cells:
		var c: Dictionary = base_cells[k]
		out[k] = {
			"height": int(c.get("height", 1)),
			"color": c.get("color", DEFAULT_COLOR),
		}
	for op in mods:
		if typeof(op) == TYPE_DICTIONARY:
			_apply_op(out, op)
	return out


static func _apply_op(cells: Dictionary, op: Dictionary) -> void:
	var op_name: String = str(op.get("op", ""))
	var params: Dictionary = op.get("params", {})
	var keys: Array = _targets(cells, op.get("target", "all"))
	match op_name:
		"colorize":
			var col: Color = _parse_color(params.get("color", "#ffffff"))
			for k in keys:
				cells[k]["color"] = col
		"random_colors":
			var rng := RandomNumberGenerator.new()
			rng.seed = int(op.get("seed", 0))
			var pal: String = str(params.get("palette", "spectrum"))
			# Deterministic order so the seed is stable across runs.
			var sorted_keys: Array = keys.duplicate()
			sorted_keys.sort_custom(func(a, b): return (a.x * 100000 + a.y) < (b.x * 100000 + b.y))
			for k in sorted_keys:
				cells[k]["color"] = _palette_color(pal, rng.randf())
		"shift":
			var dy: int = int(params.get("dy", 0))
			for k in keys:
				cells[k]["height"] = maxi(0, int(cells[k]["height"]) + dy)
		"normalize":
			# "make it a plane grid again" — flatten heights + clear color overrides.
			var h: int = int(params.get("height", 1))
			for k in keys:
				cells[k]["height"] = h
				cells[k]["color"] = DEFAULT_COLOR
		_:
			# subdivide / transform / scale / rotate are region/mesh ops — deferred
			# (subdivide touches logical resolution + the pathfinder; see the doc).
			pass


static func _targets(cells: Dictionary, target) -> Array:
	var keys: Array = []
	if typeof(target) == TYPE_STRING and target == "all":
		keys = cells.keys()
	elif typeof(target) == TYPE_DICTIONARY:
		if target.has("cells"):
			for rc in target["cells"]:
				var k := Vector2i(int(rc[0]), int(rc[1]))
				if cells.has(k):
					keys.append(k)
		elif target.has("region"):
			var rg: Array = target["region"]  # [r0, c0, r1, c1]
			if rg.size() >= 4:
				for k in cells.keys():
					if k.x >= int(rg[0]) and k.x <= int(rg[2]) and k.y >= int(rg[1]) and k.y <= int(rg[3]):
						keys.append(k)
	return keys


static func _parse_color(v) -> Color:
	if typeof(v) == TYPE_COLOR:
		return v
	if typeof(v) == TYPE_STRING:
		var s: String = v
		if s.begins_with("#"):
			return Color.html(s)
		if Color.html_is_valid(s):
			return Color.html(s)
	return Color(0.9, 0.6, 0.2)


static func _palette_color(pal: String, t: float) -> Color:
	match pal:
		"warm":
			return Color.from_hsv(lerpf(0.02, 0.13, t), 0.72, 1.0)
		"cool":
			return Color.from_hsv(lerpf(0.5, 0.72, t), 0.6, 1.0)
		"mono":
			return Color(0.4 + 0.5 * t, 0.4 + 0.5 * t, 0.45 + 0.5 * t)
		_:
			return Color.from_hsv(t, 0.8, 1.0)
