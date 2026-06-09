class_name GridOps
extends RefCounted

## GDScript port of the web /editor mutators — the grid STRUCTURE (height) paint
## palette behind the VR Grid tab. Pure + deterministic over a height model:
##   heights := { Vector2i(row, col): int }   # 0..MAX_H
##
## Mirrors ada_encyclopedia/src/app/editor/mutators.ts so the headset Grid tab
## paints with the same ops as the web editor, plus randomize + ground_plane
## (= "make it a plane grid again" / normalize). Same applier shape as
## ModifierStack (commons/modifiers/modifier_stack.gd): apply(base, op) returns a
## NEW grid; base is never mutated; random ops are seeded → reproducible.

const MAX_H := 5
const MAX_BRUSH := 4   ## VR cap: a single stroke never exceeds 4x4 cells (local editing)


## The footprint of one VR stroke: a small square (1..4 per side, capped) of cells
## centred on the cell you point at. This is the ONLY way the Grid tab applies an op
## in VR — never "all" / large regions. Returns [[row,col],...] for op.target.cells.
static func brush_cells(center: Vector2i, size: int) -> Array:
	var s: int = clampi(size, 1, MAX_BRUSH)
	var start_r: int = center.x - (s - 1) / 2
	var start_c: int = center.y - (s - 1) / 2
	var cells: Array = []
	for dr in range(s):
		for dc in range(s):
			cells.append([start_r + dr, start_c + dc])
	return cells


## One VR stroke: apply `op` to the brush footprint at `center` (size capped 1..4).
static func stroke(base: Dictionary, op_name: String, center: Vector2i, size: int, params: Dictionary = {}, op_seed: int = 0) -> Dictionary:
	var op: Dictionary = {"op": op_name, "target": {"cells": brush_cells(center, size)}, "params": params, "seed": op_seed}
	return apply(base, op)


static func apply_stack(base: Dictionary, ops: Array) -> Dictionary:
	var out: Dictionary = _copy(base)
	for op in ops:
		if typeof(op) == TYPE_DICTIONARY:
			_apply(out, op)
	return out


static func apply(base: Dictionary, op: Dictionary) -> Dictionary:
	var out: Dictionary = _copy(base)
	_apply(out, op)
	return out


static func _copy(b: Dictionary) -> Dictionary:
	var o: Dictionary = {}
	for k in b:
		o[k] = int(b[k])
	return o


static func _clamp_h(v: int) -> int:
	return clampi(v, 0, MAX_H)


static func _apply(h: Dictionary, op: Dictionary) -> void:
	var op_name: String = str(op.get("op", ""))
	var params: Dictionary = op.get("params", {})
	var keys: Array = _targets(h, op.get("target", "all"))
	var value: int = int(params.get("value", 1))
	match op_name:
		"add":
			var amount: int = int(params.get("amount", 1))
			for k in keys:
				h[k] = _clamp_h(int(h[k]) + amount)
		"erase", "remove":
			for k in keys:
				h[k] = 0
		"fill", "level":
			for k in keys:
				h[k] = _clamp_h(value)
		"max", "lift":
			for k in keys:
				h[k] = maxi(int(h[k]), _clamp_h(value))
		"ground_plane", "flatten", "normalize":
			var base_h: int = int(params.get("value", 1))
			for k in keys:
				h[k] = _clamp_h(base_h)
		"randomize":
			var rng := RandomNumberGenerator.new()
			rng.seed = int(op.get("seed", 0))
			var lo: int = int(params.get("min", 0))
			var hi: int = int(params.get("max", MAX_H))
			for k in _sorted(keys):
				h[k] = _clamp_h(rng.randi_range(lo, hi))
		"raise", "pyramid":
			var b: Array = _bounds(keys)
			var cr: float = (float(b[0]) + float(b[2])) * 0.5
			var cc: float = (float(b[1]) + float(b[3])) * 0.5
			var maxr: float = maxf(1.0, maxf(float(b[2]) - cr, float(b[3]) - cc))
			for k in keys:
				var d: float = maxf(absf(float(k.x) - cr), absf(float(k.y) - cc))
				h[k] = _clamp_h(int(round(lerpf(float(value), 0.0, d / maxr))))
		"smooth":
			var src: Dictionary = _copy(h)
			for k in keys:
				var sum: int = int(src[k])
				var n: int = 1
				for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					var nk: Vector2i = k + d
					if src.has(nk):
						sum += int(src[nk]); n += 1
				h[k] = _clamp_h(int(round(float(sum) / float(n))))
		"rows":
			for k in keys:
				if k.x % 2 == 0:
					h[k] = _clamp_h(value)
		"cols":
			for k in keys:
				if k.y % 2 == 0:
					h[k] = _clamp_h(value)
		"checker":
			for k in keys:
				if (k.x + k.y) % 2 == 0:
					h[k] = _clamp_h(value)
		"frame":
			var b2: Array = _bounds(keys)
			for k in keys:
				if k.x == b2[0] or k.x == b2[2] or k.y == b2[1] or k.y == b2[3]:
					h[k] = _clamp_h(value)
		"ring":
			var b3: Array = _bounds(keys)
			var rc: float = (float(b3[0]) + float(b3[2])) * 0.5
			var rcc: float = (float(b3[1]) + float(b3[3])) * 0.5
			var rad: float = maxf(float(b3[2]) - rc, float(b3[3]) - rcc) * 0.5
			for k in keys:
				var dist: float = maxf(absf(float(k.x) - rc), absf(float(k.y) - rcc))
				if absf(dist - rad) < 0.6:
					h[k] = _clamp_h(value)
		_:
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
			var rg: Array = target["region"]
			if rg.size() >= 4:
				for k in cells.keys():
					if k.x >= int(rg[0]) and k.x <= int(rg[2]) and k.y >= int(rg[1]) and k.y <= int(rg[3]):
						keys.append(k)
	return keys


static func _sorted(keys: Array) -> Array:
	var s: Array = keys.duplicate()
	s.sort_custom(func(a, b): return (a.x * 100000 + a.y) < (b.x * 100000 + b.y))
	return s


static func _bounds(keys: Array) -> Array:
	if keys.is_empty():
		return [0, 0, 0, 0]
	var r0: int = 1 << 30
	var c0: int = 1 << 30
	var r1: int = -(1 << 30)
	var c1: int = -(1 << 30)
	for k in keys:
		r0 = mini(r0, k.x); c0 = mini(c0, k.y)
		r1 = maxi(r1, k.x); c1 = maxi(c1, k.y)
	return [r0, c0, r1, c1]
