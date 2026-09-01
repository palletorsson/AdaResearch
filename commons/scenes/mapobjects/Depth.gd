extends RefCounted

## THE DEPENDENCY GRADIENT — what should become visible, here, now.
##
## 2026-09-01, Palle's ruling, which replaced a worse thing this file used to be.
## It was CodeDebt.gd: it measured every language construct a room's code used and
## printed the lot as "stands on … — not taught here". Accurate, and a dependency
## wall. Follow that logic and before Vector3 comes floats, before floats binary,
## before binary electricity, and the learner has learned nothing about points.
##
##     Explain a dependency when ignorance of it prevents the learner from
##     forming the intended mental model. Don't explain it merely because
##     it exists.
##
## So a thing is not present-or-absent, it has a rung; and the bottom rungs SHOW
## NOTHING:
##
##     background   in the building, never on the path (the basement)
##     used         the learner acts through it, need not know it exists  <- DEFAULT
##     named        one line, beside the thing, no theory
##     glimpsed     the line, plus a descent they may decline
##     understood   the room's subject — what it teaches
##     mastered     carried across rooms; not a property of any room
##
## THE DEFAULT IS SILENCE. An unruled room says nothing. That is the ruling, not a
## gap, and probe_depth.gd fails if this file ever invents a list for a room
## nobody has judged.
##
## Reads commons/data/depth.json (derived by tools/depth.py from the authored
## commons/data/depth_rulings.json). It names no autoload on purpose: every probe
## in this repo is `extends SceneTree`, which cannot see one, so a reader living
## inside info_board.gd — which names GameManager — could not be tested at all.

const FILE := "res://commons/data/depth.json"

## Rungs, low to high.
const LADDER := ["background", "used", "named", "glimpsed", "understood", "mastered"]

static var _doc: Dictionary = {}
static var _read := false


static func doc() -> Dictionary:
	if _read:
		return _doc
	_read = true                                    # a missing file is read ONCE
	if not FileAccess.file_exists(FILE):
		return _doc
	var f = FileAccess.open(FILE, FileAccess.READ)
	if not f:
		return _doc
	var j = JSON.new()
	if j.parse(f.get_as_text()) == OK and j.data is Dictionary:
		_doc = j.data
	f.close()
	return _doc


static func _room(map_name: String) -> Dictionary:
	var rooms = doc().get("rooms", {})
	if rooms is Dictionary and rooms.has(map_name):
		return rooms[map_name]
	return {}


## Everything this room says, high rung first. EMPTY for an unruled room.
static func says(map_name: String) -> Array:
	return _room(map_name).get("says", [])


## What the room TEACHES — its subject. This, and only this, belongs on the board
## at the entrance: a person arriving wants to know what they will be able to do,
## not an inventory of the machinery they will act through.
static func subject(map_name: String) -> Array:
	var out: Array = []
	for t in says(map_name):
		if str(t.get("status", "")) == "understood":
			out.append(t)
	return out


## The whole 'glimpsed' rung: things the room shows a plaque line for and MAY
## offer a descent from. Not every glimpsed thing has a descent written yet —
## `collision shapes` in Point_One has its line ("The ball knows when your hand
## is inside it") and no inscription under it — and filtering on the inscription
## dropped it off the sign entirely, which silently demoted it to 'used'. A rung
## is a ruling; a missing sentence is a to-do.
static func glimpsed(map_name: String) -> Array:
	var out: Array = []
	for t in says(map_name):
		if str(t.get("status", "")) == "glimpsed":
			out.append(t)
	return out


## Only those that actually carry the optional inscription. Use this to COUNT
## what is written, never to decide what is shown.
static func descents(map_name: String) -> Array:
	var out: Array = []
	for t in says(map_name):
		if str(t.get("descend", "")) != "":
			out.append(t)
	return out


## In the building, never on the path. Never rendered on a wall — the book lists
## it once, so the museum is honest about having a basement.
static func basement(map_name: String) -> Array:
	return _room(map_name).get("basement", [])


## The learner arrives late; there is no arriving early enough. Said once.
static func thrownness() -> String:
	return str(doc().get("_thrownness", ""))
