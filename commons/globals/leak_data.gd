extends Node

## THE LEAK BUS — what a rule REFUSED, kept.
##
## [[trace_data]] carries what a visitor MEANT: a released drawing, a saved tile
## pattern. This carries the opposite, and it exists because of a claim the book
## makes in every chapter and had no way to act on.
##
## A world is held together by restraint. Every restraint has an edge, and at that
## edge something escapes: the pause a movement gate drops, the flourish a grid
## rounds away, the triangle a fan lays across a notch you deliberately left open,
## the cubes a lattice deletes because your body was allowed to reach a little past
## where it was stopped. Primitives_Ignorance already says it of the five-sided
## capsule — "its surprise is made within the restriction."
##
## The rooms compute these remainders, name them out loud, and then drop them.
## This keeps them, so a later room can be built out of what your passage could not
## be contained by.
##
## A LEAK IS DATA, NEVER A SCORE. There is deliberately no total, no ordering by
## size and no per-room tally exposed here. The moment a remainder carries a number
## somebody optimises it, and the book would have built the scoreboard it spends
## twenty-four chapters arguing against. Name what was dropped; do not count it.

## One entry per refusal event:
##   room    the map it happened in
##   rule    which restraint refused, as "<artifact>.<parameter>" — the edge, named
##   kind    what the points are: "cells", "positions", "corners", "faces"
##   points  the refused material, in the ARTIFACT's local space
##   tint    a colour the material carried, for a consumer that wants to keep it
##   span    the artifact's own scale, so a consumer can resize without guessing
var leaks: Array = []

signal leak_added(leak: Dictionary)

## Bounds, not budgets. A visitor who stands in a lattice for ten minutes should
## not be able to exhaust memory, and nothing here should feel like a limit the
## visitor is being measured against.
const MAX_LEAKS: int = 64
const MAX_POINTS: int = 2048


## Record a refusal. Silent and harmless when there is nothing to record: a rule
## that refused nothing has no edge to report, which is a normal state and not a
## failure of the room.
func spill(room: String, rule: String, kind: String, points: Array,
		tint: Color = Color(1.0, 1.0, 1.0, 1.0), span: float = 1.0) -> void:
	if points.is_empty():
		return
	var kept: Array = points.duplicate()
	if kept.size() > MAX_POINTS:
		kept = kept.slice(kept.size() - MAX_POINTS)
	var leak: Dictionary = {
		"room": room,
		"rule": rule,
		"kind": kind,
		"points": kept,
		"tint": tint,
		"span": span,
	}
	leaks.append(leak)
	while leaks.size() > MAX_LEAKS:
		leaks.pop_front()
	print("LeakData: %s refused %d %s in %s" % [rule, kept.size(), kind, room])
	leak_added.emit(leak)


func all_leaks() -> Array:
	return leaks


## Every leak a given room produced, oldest first.
func leaks_from(room: String) -> Array:
	var out: Array = []
	for l: Dictionary in leaks:
		if str(l.get("room", "")) == room:
			out.append(l)
	return out


## Every leak a given rule produced. The rule string is the edge's name, so this
## is how a room asks "what has this restraint refused before?"
func leaks_by_rule(rule: String) -> Array:
	var out: Array = []
	for l: Dictionary in leaks:
		if str(l.get("rule", "")) == rule:
			out.append(l)
	return out


## The union of every point a rule has refused, across visits. A room restoring
## its own edge wants this rather than the most recent leak: two passes through
## the same lattice cut different cells, and the second visitor should meet both.
func points_by_rule(rule: String) -> Array:
	var out: Array = []
	for l: Dictionary in leaks_by_rule(rule):
		out.append_array(l.get("points", []))
	return out


func has_leaks() -> bool:
	return not leaks.is_empty()


func clear_leaks() -> void:
	leaks.clear()
