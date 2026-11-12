extends RefCounted
## A WALK THAT LAYS THE KIT (Palle, 2026-11-12: "use this playground principal and style for the pipes").
## The law is pipe_dream's: keep going with a chance, else turn, never straight back. Every step lays a bar; where the
## four corners of a square have been reached on one level, a two-metre tile is laid; where a floor has room beside
## it, a wedge ramp. Horizontal steps are 2 m, vertical steps 1 m: a ramp is one cell long and rises one level.
## Everything goes through builder.bar / tile / assembly - the existing point, rod, quad and wedge. A walk is saved
## data: one seed gives one frame, compiled the same way every time. It has no live redraw.
##
##   "walks": [{"id":"pipes", "at":[0,0,0], "cells":[6,2], "levels":4, "steps":220, "seed":7,
##              "straight":0.32, "ramps":2, "out":["west","east"]}]
##
## `at` is the centre of the footprint on the host ground; `cells` are two-metre cells east-west by north-south;
## `levels` is how many metres the frame may rise. `ramps` is the most ramps laid up to each level. `out` names the
## sides by which a ramp from the ground may stand outside the footprint.
const SIDES := {"east": Vector2i(1, 0), "west": Vector2i(-1, 0), "south": Vector2i(0, 1), "north": Vector2i(0, -1)}
const TURN := {"west": 1, "east": 3, "north": 0, "south": 2}
const STEPS: Array[Vector3i] = [Vector3i(1, 0, 0), Vector3i(-1, 0, 0), Vector3i(0, 1, 0), Vector3i(0, -1, 0), Vector3i(0, 0, 1), Vector3i(0, 0, -1)]


static func whole(v: Variant, lo: int, hi: int) -> bool:
	return (v is int or v is float) and is_finite(float(v)) and v >= lo and v <= hi and is_equal_approx(float(v), roundf(v))


static func validate(raw: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	var walks: Variant = raw.get("walks", [])
	if not walks is Array:
		return PackedStringArray(["walks must be an array"])
	var ids := {}
	for w in walks:
		if not w is Dictionary:
			errors.append("Walk must be an object"); continue
		var id := str(w.get("id", ""))
		if not id.is_valid_identifier() or ids.has(id): errors.append("Walk needs a unique stable id: " + id)
		ids[id] = true
		for k in w:
			if k not in ["id", "at", "cells", "levels", "steps", "seed", "straight", "ramps", "out"]: errors.append(id + ": unknown walk field " + str(k))
		var at: Variant = w.get("at")
		var cells: Variant = w.get("cells")
		if not at is Array or at.size() != 3 or not whole(at[0], -48, 48) or not whole(at[1], 0, 6) or not whole(at[2], -48, 48): errors.append(id + ": at needs whole [x,y,z] metres, y=0..6")
		if not cells is Array or cells.size() != 2 or not whole(cells[0], 2, 12) or not whole(cells[1], 1, 8): errors.append(id + ": cells needs [east-west 2..12, north-south 1..8] two-metre cells")
		if not whole(w.get("levels", 4), 2, 6): errors.append(id + ": levels must be whole metres from 2 to 6")
		if not whole(w.get("steps", 200), 10, 800): errors.append(id + ": steps must be 10 to 800")
		if not whole(w.get("seed", 1), 0, 2147483647): errors.append(id + ": seed must be a whole number")
		var straight: Variant = w.get("straight", 0.32)
		if not (straight is int or straight is float) or straight < 0 or straight > 1: errors.append(id + ": straight is a chance from 0 to 1")
		if not whole(w.get("ramps", 2), 0, 6): errors.append(id + ": ramps must be 0 to 6")
		var out: Variant = w.get("out", [])
		if not out is Array or not out.all(func(s): return SIDES.has(s)): errors.append(id + ": out must name sides")
	return errors


static func build_all(builder: Object, raw: Dictionary) -> void:
	for w in raw.get("walks", []):
		build(builder, w)


## The walk and what follows from it, in lattice indices: points (i, level, k), cells (ci, ck).
## Pure: the same specification gives the same plan.
static func plan(w: Dictionary) -> Dictionary:
	var nx: int = int(w.cells[0])
	var nz: int = int(w.cells[1])
	var top: int = int(w.get("levels", 4))
	var rng := RandomNumberGenerator.new()
	rng.seed = int(w.get("seed", 1))
	var straight: float = float(w.get("straight", 0.32))
	var inside := func(p: Vector3i) -> bool: return p.x >= 0 and p.x <= nx and p.z >= 0 and p.z <= nz and p.y >= 0 and p.y <= top
	var choose := func(pos: Vector3i, current: Vector3i, force: bool) -> Vector3i:
		if not force and rng.randf() < straight and inside.call(pos + current):
			return current
		var candidates: Array[Vector3i] = []
		for d in STEPS:
			if d == -current or (force and d == current): continue
			candidates.append(d)
		for i in range(candidates.size() - 1, 0, -1):
			var j := rng.randi_range(0, i)
			var held := candidates[i]; candidates[i] = candidates[j]; candidates[j] = held
		for d in candidates:
			if inside.call(pos + d): return d
		return current
	var pos := Vector3i(nx / 2, 0, nz / 2)
	var heading := Vector3i(0, 0, -1)
	var reached := {pos: true}
	var edges := {}          # Vector4i(x, y, z, axis): the edge from that point one step along the axis
	for step in int(w.get("steps", 200)):
		if not inside.call(pos + heading):
			heading = choose.call(pos, heading, true)
		var end: Vector3i = pos + heading
		if not inside.call(end):
			continue
		var low := Vector3i(mini(pos.x, end.x), mini(pos.y, end.y), mini(pos.z, end.z))
		edges[Vector4i(low.x, low.y, low.z, 0 if heading.x != 0 else (1 if heading.y != 0 else 2))] = true
		reached[end] = true
		pos = end
		heading = choose.call(pos, heading, false)
	# a floor where four corners exist on one level above the ground; two floors in one column stand 2 m apart
	var floors := {}         # Vector3i(ci, level, ck)
	for ci in nx:
		for ck in nz:
			var last := -9
			for level in range(1, top):      # not on the top level: nothing stands above it to hold a rail, and a ceiling may be near
				var closed: bool = reached.has(Vector3i(ci, level, ck)) and reached.has(Vector3i(ci + 1, level, ck)) and reached.has(Vector3i(ci, level, ck + 1)) and reached.has(Vector3i(ci + 1, level, ck + 1))
				if closed and level - last >= 2:
					floors[Vector3i(ci, level, ck)] = true
					last = level
	# ramps: one cell long, one level up, where the cell beside a floor is free and something carries the foot
	var ramps := []
	var taken := {}
	var per_level := {}
	var most: int = int(w.get("ramps", 2))
	var out: Array = w.get("out", [])
	var keys: Array = floors.keys()
	keys.sort_custom(func(a: Vector3i, b: Vector3i) -> bool: return a.y < b.y or (a.y == b.y and (a.x < b.x or (a.x == b.x and a.z < b.z))))
	for q: Vector3i in keys:
		if int(per_level.get(q.y, 0)) >= most: continue
		for side: String in ["west", "east", "south", "north"]:
			var d: Vector2i = SIDES[side]
			var a := Vector3i(q.x + d.x, q.y, q.z + d.y)                 # the ramp's cell, named at the level it reaches
			var b := Vector3i(q.x + 2 * d.x, q.y - 1, q.z + 2 * d.y)     # where a body stands before it climbs
			var a_inside: bool = a.x >= 0 and a.x < nx and a.z >= 0 and a.z < nz
			var b_inside: bool = b.x >= 0 and b.x < nx and b.z >= 0 and b.z < nz
			if floors.has(a) or floors.has(a + Vector3i(0, 1, 0)) or taken.has(a): continue
			if floors.has(b + Vector3i(0, 1, 0)): continue                # no headroom at the foot
			if q.y - 1 == 0:
				if (not a_inside or not b_inside) and side not in out: continue
			elif not b_inside or not floors.has(b): continue             # nothing to stand on at the foot
			# a bar at chest height across the way in, or across the crest, is a closed gate
			var far_low: Vector3i
			var crest_low: Vector3i
			var axis := 2 if d.x != 0 else 0
			match side:
				"west": far_low = Vector3i(q.x - 1, q.y, q.z); crest_low = Vector3i(q.x, q.y + 1, q.z)
				"east": far_low = Vector3i(q.x + 2, q.y, q.z); crest_low = Vector3i(q.x + 1, q.y + 1, q.z)
				"north": far_low = Vector3i(q.x, q.y, q.z - 1); crest_low = Vector3i(q.x, q.y + 1, q.z)
				_: far_low = Vector3i(q.x, q.y, q.z + 2); crest_low = Vector3i(q.x, q.y + 1, q.z + 1)
			if edges.has(Vector4i(far_low.x, far_low.y, far_low.z, axis)) or edges.has(Vector4i(crest_low.x, crest_low.y, crest_low.z, axis)): continue
			ramps.append({"to": q, "side": side, "cell": a, "foot": b})
			taken[a] = true
			per_level[q.y] = int(per_level.get(q.y, 0)) + 1
			break
	return {"reached": reached, "edges": edges, "floors": floors, "ramps": ramps}


static func build(b: Object, w: Dictionary) -> void:
	var id: String = w.id
	var nx: int = int(w.cells[0])
	var nz: int = int(w.cells[1])
	var origin := Vector3(float(w.at[0]) - nx, float(w.at[1]), float(w.at[2]) - nz)      # the lattice's north-west foot
	var made: Dictionary = plan(w)
	var seat: float = .04 if b.design.appearance.get("workshop_profile", "") == "fitted" else 0.0
	for e: Vector4i in made.edges:
		# an edge of a floor is carried by the floor's own frame, seated flush: a second, loose rod there is a kerb
		if e.w == 0 and (made.floors.has(Vector3i(e.x, e.y, e.z)) or made.floors.has(Vector3i(e.x, e.y, e.z - 1))): continue
		if e.w == 2 and (made.floors.has(Vector3i(e.x, e.y, e.z)) or made.floors.has(Vector3i(e.x - 1, e.y, e.z))): continue
		var from := origin + Vector3(2 * e.x, e.y, 2 * e.z)
		var along: Vector3 = [Vector3(2, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, 2)][e.w]
		var to: Vector3 = from + along
		if e.y == 0:      # what stands or lies on the host ground is seated in it, whole, as a deck's legs are
			from.y -= seat
			to.y -= seat
		b.bar(id + "_bar_%d_%d_%d_%d" % [e.x, e.y, e.z, e.w], from, to)
	var floors := []
	for f: Vector3i in made.floors:
		var at := origin + Vector3(2 * f.x, f.y, 2 * f.z)
		b.tile(id + "_floor_%d_%d_%d" % [f.x, f.y, f.z], at, 2)
		floors.append(b.arr(at + Vector3(1, 0, 1)))
	var ramps := []
	for r in made.ramps:
		var cell: Vector3i = r.cell
		var q: Vector3i = r.to
		var at := origin + Vector3(2 * cell.x, q.y - 1, 2 * cell.z)
		var records: Array = b.square(2).filter(func(part): return part.kind != "quad")
		records.append({"kind": "wedge", "at": [.5, 0, .5], "turn": [0, TURN[r.side], 0]})
		b.assembly(id + "_ramp_%d_%d_%d" % [cell.x, q.y, cell.z], at, records)
		var foot: Vector3i = r.foot
		ramps.append({"side": r.side, "from_level": q.y - 1, "to_level": q.y,
			"foot": b.arr(origin + Vector3(2 * foot.x + 1, q.y - 1, 2 * foot.z + 1)), "top": b.arr(origin + Vector3(2 * q.x + 1, q.y, 2 * q.z + 1))})
	b.recipe.get_or_add("walks", []).append({"id": id, "at": w.at, "cells": w.cells, "floors": floors, "ramps": ramps,
		"bars": made.edges.size(), "points": made.reached.size()})
