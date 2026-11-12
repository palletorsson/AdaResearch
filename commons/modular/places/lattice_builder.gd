extends RefCounted
## A LATTICE OF BARS OVER AN OPENING (Palle, 2026-11-12, with a picture of a floor of square pits between ribs:
## "start with a structure like this and add tiles instead"). The ribs only: one-metre rods with a joint at every
## crossing, laid through builder.bar. What fills the cells is not the kit's business - a game's tiles, or nothing.
##
##   "lattices": [{"id":"ribs", "at":[0,0,0], "cells":[6,6]}]
##
## `at` is the centre, with the elevation as its middle coordinate; `cells` are one-metre cells, even numbers,
## east-west by north-south. At elevation 0 the bars are seated in the host ground like any ground member.


static func whole(v: Variant, lo: int, hi: int) -> bool:
	return (v is int or v is float) and is_finite(float(v)) and v >= lo and v <= hi and is_equal_approx(float(v), roundf(v))


static func validate(raw: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	var lattices: Variant = raw.get("lattices", [])
	if not lattices is Array:
		return PackedStringArray(["lattices must be an array"])
	var ids := {}
	for l in lattices:
		if not l is Dictionary:
			errors.append("Lattice must be an object"); continue
		var id := str(l.get("id", ""))
		if not id.is_valid_identifier() or ids.has(id): errors.append("Lattice needs a unique stable id: " + id)
		ids[id] = true
		for k in l:
			if k not in ["id", "at", "cells"]: errors.append(id + ": unknown lattice field " + str(k))
		var at: Variant = l.get("at")
		var cells: Variant = l.get("cells")
		if not at is Array or at.size() != 3 or not whole(at[0], -48, 48) or not whole(at[1], 0, 6) or not whole(at[2], -48, 48): errors.append(id + ": at needs whole [x,y,z] metres, y=0..6")
		if not cells is Array or cells.size() != 2 or not cells.all(func(n): return whole(n, 2, 20) and int(n) % 2 == 0): errors.append(id + ": cells needs even [east-west, north-south] metres from 2..20")
	return errors


static func build_all(builder: Object, raw: Dictionary) -> void:
	for l in raw.get("lattices", []):
		build(builder, l)


static func build(b: Object, l: Dictionary) -> void:
	var id: String = l.id
	var nx: int = int(l.cells[0])
	var nz: int = int(l.cells[1])
	var seat: float = .04 if float(l.at[1]) == 0.0 and b.design.appearance.get("workshop_profile", "") == "fitted" else 0.0
	var origin := Vector3(float(l.at[0]) - nx / 2.0, float(l.at[1]) - seat, float(l.at[2]) - nz / 2.0)
	for k in nz + 1:
		for i in nx:
			b.bar(id + "_x_%d_%d" % [i, k], origin + Vector3(i, 0, k), origin + Vector3(i + 1, 0, k))
	for i in nx + 1:
		for k in nz:
			b.bar(id + "_z_%d_%d" % [i, k], origin + Vector3(i, 0, k), origin + Vector3(i, 0, k + 1))
	b.recipe.get_or_add("lattices", []).append({"id": id, "at": l.at, "cells": l.cells})
