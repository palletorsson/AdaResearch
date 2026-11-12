extends RefCounted
## A HILL A CELLULAR AUTOMATON LAYS WITH THE KIT (Palle, 2026-11-12: "can we build a playground with cellular
## automata?"). Two rules, on two-metre cells:
##   the GROUND PLAN  a seeded scatter of cells, smoothed: a cell stands if five of the nine cells round it stood
##                    (itself counted). Some cells are given: `alive` (a shaft to cover), `dead` (a column to leave).
##   the STOREYS      storey n+1 is storey n after one step of an erosion rule: a cell stands upstairs only if every
##                    neighbour stood downstairs (`rule`: moore = all eight, neumann = the four that share an edge).
## So every storey rests on the one below, a cell's height is how many steps of the rule it survived, and no number
## in the spec says how tall the hill is.
##
## THE KIT'S PARTS, NOTHING ELSE. A cell that has a higher neighbour across an edge is a WEDGE (the kit's ramp, 1 m up
## in 2 m) rising toward it; a cell with none is a flat TILE. A cell of level L lies one metre under its level, the
## wedge climbing the last metre, so rings of wedges make slopes a body walks straight up from the slab. Posts are
## the kit's rods, at the corners of whatever stands above the ground. A hill is saved data: one seed, one hill.
##
##   "automata": [{"id":"hill", "at":[9,0,1], "cells":[6,6], "seed":7, "fill":0.7, "smooth":2, "storeys":3,
##                 "rule":"moore", "alive":[[2,1],[3,1]], "dead":[[0,5]], "no_posts":[-2,-4,4,2]}]
##
## `at` is the centre of the footprint on the host ground; `cells` are two-metre cells east-west by north-south,
## counted from the north-west; `no_posts` is a rectangle [x0, z0, x1, z1] in metres from `at` with no ground under it.
const RISE := {Vector2i(1, 0): 1, Vector2i(0, 1): 0, Vector2i(-1, 0): 3, Vector2i(0, -1): 2}      # the wedge's turn for the way it climbs
const EDGE: Array[Vector2i] = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]
const ROUND: Array[Vector2i] = [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1)]


static func whole(v: Variant, lo: int, hi: int) -> bool:
	return (v is int or v is float) and is_finite(float(v)) and v >= lo and v <= hi and is_equal_approx(float(v), roundf(v))


static func _cells_ok(list: Variant, nx: int, nz: int) -> bool:
	if not list is Array: return false
	for c in list:
		if not c is Array or c.size() != 2 or not whole(c[0], 0, nx - 1) or not whole(c[1], 0, nz - 1): return false
	return true


static func validate(raw: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	var rows: Variant = raw.get("automata", [])
	if not rows is Array:
		return PackedStringArray(["automata must be an array"])
	var ids := {}
	for a in rows:
		if not a is Dictionary:
			errors.append("Automaton must be an object"); continue
		var id := str(a.get("id", ""))
		if not id.is_valid_identifier() or ids.has(id): errors.append("Automaton needs a unique stable id: " + id)
		ids[id] = true
		for k in a:
			if k not in ["id", "at", "cells", "seed", "fill", "smooth", "storeys", "rule", "alive", "dead", "no_posts"]: errors.append(id + ": unknown automaton field " + str(k))
		var at: Variant = a.get("at")
		var cells: Variant = a.get("cells")
		if not at is Array or at.size() != 3 or not whole(at[0], -48, 48) or not whole(at[1], 0, 6) or not whole(at[2], -48, 48): errors.append(id + ": at needs whole [x,y,z] metres, y=0..6")
		if not cells is Array or cells.size() != 2 or not whole(cells[0], 3, 12) or not whole(cells[1], 3, 12):
			errors.append(id + ": cells needs [east-west, north-south] two-metre cells, 3 to 12 each"); continue
		if not whole(a.get("seed", 1), 0, 2147483647): errors.append(id + ": seed must be a whole number")
		var fill: Variant = a.get("fill", 0.6)
		if not (fill is int or fill is float) or fill < 0 or fill > 1: errors.append(id + ": fill is a chance from 0 to 1")
		if not whole(a.get("smooth", 2), 0, 8): errors.append(id + ": smooth is 0 to 8 steps")
		if not whole(a.get("storeys", 3), 1, 5): errors.append(id + ": storeys must be 1 to 5")
		if str(a.get("rule", "moore")) not in ["moore", "neumann"]: errors.append(id + ": rule is moore or neumann")
		for key in ["alive", "dead"]:
			if a.has(key) and not _cells_ok(a[key], int(cells[0]), int(cells[1])): errors.append(id + ": " + key + " lists cells [east-west, north-south] inside the footprint")
		if a.has("no_posts") and (not a.no_posts is Array or a.no_posts.size() != 4): errors.append(id + ": no_posts is [x0, z0, x1, z1] in metres from at")
	return errors


static func build_all(builder: Object, raw: Dictionary) -> void:
	for a in raw.get("automata", []):
		build(builder, a)


## Both rules, in cells. Pure: the same specification gives the same plan.
## Returns {level: {cell: storeys it stands in}, surface: {cell: {kind, base, climbs}}, top: highest level}.
static func plan(a: Dictionary) -> Dictionary:
	var nx: int = int(a.cells[0])
	var nz: int = int(a.cells[1])
	var given_alive := {}
	var given_dead := {}
	for c in a.get("alive", []): given_alive[Vector2i(int(c[0]), int(c[1]))] = true
	for c in a.get("dead", []): given_dead[Vector2i(int(c[0]), int(c[1]))] = true
	var rng := RandomNumberGenerator.new()
	rng.seed = int(a.get("seed", 1))
	var fill: float = float(a.get("fill", 0.6))
	var stands := {}
	for z in nz:
		for x in nx:
			var c := Vector2i(x, z)
			var drawn: bool = rng.randf() < fill          # drawn for every cell, so a given cell does not shift the rest
			if (drawn or given_alive.has(c)) and not given_dead.has(c): stands[c] = true
	for step in int(a.get("smooth", 2)):
		var next := {}
		for z in nz:
			for x in nx:
				var c := Vector2i(x, z)
				var count: int = 1 if stands.has(c) else 0
				for d in ROUND:
					if stands.has(c + d): count += 1
				if (count >= 5 or given_alive.has(c)) and not given_dead.has(c): next[c] = true
		stands = next
	var around: Array[Vector2i] = ROUND if str(a.get("rule", "moore")) == "moore" else EDGE
	var level := {}
	var storey: Dictionary = stands
	var top := 0
	for n in range(1, int(a.get("storeys", 3)) + 1):
		if storey.is_empty(): break
		top = n
		for c in storey: level[c] = n
		var upstairs := {}
		for c: Vector2i in storey:
			var held := true
			for d in around:
				if not storey.has(c + d): held = false; break
			if held: upstairs[c] = true
		storey = upstairs
	var surface := {}
	for c: Vector2i in level:
		var here: int = level[c]
		var climbs := Vector2i.ZERO
		for d in EDGE:
			if int(level.get(c + d, 0)) > here: climbs = d; break
		if climbs != Vector2i.ZERO:
			surface[c] = {"kind": "wedge", "base": here - 1, "climbs": climbs}
		elif here > 1:
			surface[c] = {"kind": "tile", "base": here - 1, "climbs": Vector2i.ZERO}
		elif _bare(a, Vector2(2 * c.x + 1 - nx, 2 * c.y + 1 - nz)):
			surface[c] = {"kind": "tile", "base": 0, "climbs": Vector2i.ZERO}      # no ground under it: the hill's foot is laid
		# any other cell of the first storey with no higher neighbour is the ground itself: nothing is laid
	return {"level": level, "surface": surface, "top": top}


## Is a point (metres from `at`) over the rectangle that has no ground under it?
static func _bare(a: Dictionary, local: Vector2) -> bool:
	var bare: Array = a.get("no_posts", [])
	return bare.size() == 4 and local.x > float(bare[0]) and local.x < float(bare[2]) and local.y > float(bare[1]) and local.y < float(bare[3])


static func build(b: Object, a: Dictionary) -> void:
	var id: String = a.id
	var nx: int = int(a.cells[0])
	var nz: int = int(a.cells[1])
	var origin := Vector3(float(a.at[0]) - nx, float(a.at[1]), float(a.at[2]) - nz)      # the footprint's north-west foot
	var made: Dictionary = plan(a)
	var seat: float = .04 if b.design.appearance.get("workshop_profile", "") == "fitted" else 0.0
	var posts := {}                      # corner (in cells) -> the height it carries
	var cells := []
	for c: Vector2i in made.surface:
		var s: Dictionary = made.surface[c]
		var base: int = int(s.base)
		var at := origin + Vector3(2 * c.x, base, 2 * c.y)
		if s.kind == "wedge":
			var records: Array = b.square(2).filter(func(part): return part.kind != "quad")
			records.append({"kind": "wedge", "at": [.5, 0, .5], "turn": [0, RISE[s.climbs], 0]})
			b.assembly(id + "_ramp_%d_%d" % [c.x, c.y], at, records)
		else:
			b.tile(id + "_floor_%d_%d" % [c.x, c.y], at, 2)
		if base >= 1:
			for corner in [c, c + Vector2i(1, 0), c + Vector2i(0, 1), c + Vector2i(1, 1)]:
				posts[corner] = maxi(int(posts.get(corner, 0)), base)
		cells.append({"cell": [c.x, c.y], "level": int(made.level[c]), "kind": s.kind, "base": base,
			"climbs": [s.climbs.x, s.climbs.y], "centre": b.arr(at + Vector3(1, 0, 1))})
	var stood := 0
	for corner: Vector2i in posts:
		var foot := origin + Vector3(2 * corner.x, 0, 2 * corner.y)
		if _bare(a, Vector2(foot.x - float(a.at[0]), foot.z - float(a.at[2]))): continue
		b.bar(id + "_post_%d_%d" % [corner.x, corner.y], foot - Vector3(0, seat, 0), foot + Vector3(0, int(posts[corner]) - seat, 0))
		stood += 1
	# ways straight up: from a first-storey wedge, cell after cell the same way - a wedge that climbs that way from the
	# height reached, or a flat cell at that height - to a flat cell of the top storey
	var ways := []
	for c: Vector2i in made.surface:
		var s: Dictionary = made.surface[c]
		if s.kind != "wedge" or int(s.base) != 0: continue
		var d: Vector2i = s.climbs
		var at_cell: Vector2i = c + d
		var height := 1
		var good := false
		while made.surface.has(at_cell):
			var next: Dictionary = made.surface[at_cell]
			if next.kind == "wedge":
				if next.climbs != d or int(next.base) != height: break
				height += 1
			else:
				if int(next.base) != height: break
				if int(made.level[at_cell]) == int(made.top): good = true; break
			at_cell += d
		if not good: continue
		var foot := origin + Vector3(2 * c.x + 1, 0, 2 * c.y + 1) - Vector3(d.x, 0, d.y) * 1.6
		var summit := origin + Vector3(2 * at_cell.x + 1, int(made.surface[at_cell].base), 2 * at_cell.y + 1)
		ways.append({"foot": b.arr(foot), "top": b.arr(summit), "climbs": [d.x, d.y]})
	var counts := []
	for n in range(1, int(made.top) + 1):
		var count := 0
		for c in made.level:
			if int(made.level[c]) >= n: count += 1
		counts.append(count)
	var levels := []
	for c: Vector2i in made.level: levels.append([c.x, c.y, int(made.level[c])])
	b.recipe.get_or_add("automata", []).append({"id": id, "at": a.at, "cells": a.cells, "rule": str(a.get("rule", "moore")),
		"storeys": counts, "top": int(made.top), "levels": levels, "laid": cells, "posts": stood, "ways": ways})
