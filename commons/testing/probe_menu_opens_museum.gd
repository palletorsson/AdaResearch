extends SceneTree

## Does the menu decide where the museum opens? (2026-09-06)
##
## Palle: "the new game means endless museum point one. Then all sequences are
## pointing to the endless museum version of the game."
##
## The hand-off is two static fields on endless_museum.gd, set by MainMenu3D one
## line before the staged scene is loaded. It has one job and one way to fail
## silently, and they are the same thing: BOTH museum scenes ship a chapter and a
## map in their own Inspector fields — endless_museum.tscn says transformation /
## Trans_Introduction, endless_museum_staged.tscn says primitives / Point_One —
## so a hand-off that is merely IGNORED does not look ignored. It looks like a
## museum that opened somewhere reasonable. Every sequence card would quietly
## land in the same lobby and the menu would appear to work.
##
## So the control is a run with NO menu voice, and it must open somewhere else.
## A test whose control lands in the same place proves nothing.
##
##   godot --path . --xr-mode off --headless --script res://commons/testing/probe_menu_opens_museum.gd

const MUSEUM_SCENE := "res://commons/scenes/endless_museum.tscn"
const MENU := preload("res://commons/scenes/main_menu/MainMenu3D.gd")
const EM := preload("res://commons/scenes/endless_museum.gd")
const REPORT := "res://ada_run/menu_opens_museum.txt"

var _lines: Array[String] = []
var _fails: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	# THE MENU'S OWN WORDS, read off the script rather than repeated here. If
	# FIRST_CHAPTER is ever changed to a chapter the plan has no rows for, this
	# probe must fail — and it can only do that if it asks the menu.
	var new_game_chapter: String = MENU.FIRST_CHAPTER
	var new_game_map: String = MENU.FIRST_MAP
	_lines.append("[probe] the menu's New Game is chapter '%s', map '%s'" % [new_game_chapter, new_game_map])

	# ── the control: no menu voice ───────────────────────────────────────
	var base: Dictionary = await _open({})
	_lines.append("[probe] with no menu voice the museum opens at chapter %s / map %s (pearl '%s') — its own Inspector fields" % [
		str(base.get("chapter", "?")), str(base.get("map", "?")), str(base.get("pearl", ""))])

	# ── New Game ─────────────────────────────────────────────────────────
	var ng: Dictionary = await _open({"chapter": new_game_chapter, "map": new_game_map})
	_check(String(ng.get("map", "")) == new_game_map,
		"New Game opens the museum at %s, in chapter %s (pearl '%s')" % [
			str(ng.get("map", "?")), str(ng.get("chapter", "?")), str(ng.get("pearl", ""))],
		"New Game asked for %s and the museum opened at %s (chapter %s)" % [
			new_game_map, str(ng.get("map", "?")), str(ng.get("chapter", "?"))])
	_check(String(ng.get("map", "")) != String(base.get("map", ""))
			or String(ng.get("chapter", "")) != String(base.get("chapter", "")),
		"  ...and that is NOT where it opens on its own (%s / %s) — the hand-off is doing the work" % [
			str(base.get("chapter", "?")), str(base.get("map", "?"))],
		"  ...but that is also where it opens with no menu voice at all, so this proves nothing")

	# ── a sequence card, which names a chapter and no map ────────────────
	# The map must be CLEARED, not merely unset: the staged scene ships
	# start_map "Point_One", and a card for another chapter that left it standing
	# would open in a hall belonging to somebody else's sequence.
	var other: String = await _a_chapter_other_than(new_game_chapter)
	if other == "":
		_lines.append("[probe] the plan has only one chapter — nothing to test a sequence card against")
	else:
		var sc: Dictionary = await _open({"chapter": other, "map": ""})
		_check(String(sc.get("chapter", "")) == other,
			"a sequence card for '%s' opens the museum in that chapter, at pearl '%s'" % [other, str(sc.get("pearl", ""))],
			"a sequence card for '%s' opened chapter '%s' instead" % [other, str(sc.get("chapter", "?"))])
		_check(String(sc.get("map", "")) != new_game_map,
			"  ...and not at %s — the shipped start_map was cleared, not inherited" % new_game_map,
			"  ...but at %s, which belongs to '%s': start_map was left standing from the scene file" % [
				new_game_map, new_game_chapter])

	# ── and the voice is SPENT ───────────────────────────────────────────
	# A view toggle inside the museum reloads the scene. If the menu's chapter
	# were still sitting in the static, that reload would be steered by a click
	# from ten minutes ago instead of by the resume the toggle just wrote.
	#
	# NOT through _open(), which clears the statics itself before every run — so
	# the first version of this check passed with the whole hand-off ripped out.
	# It was testing the probe's own housekeeping. The museum has to be the thing
	# that clears them, so nothing else is allowed to touch them here.
	EM.open_at("primitives", "Point_One")
	var before: String = EM.menu_chapter
	var n2: Node3D = (load(MUSEUM_SCENE) as PackedScene).instantiate() as Node3D
	root.add_child(n2)
	await process_frame
	n2.queue_free()
	await process_frame
	_check(before != "" and EM.menu_chapter == "" and EM.menu_map == "",
		"the menu's voice is cleared once the museum has heard it (was '%s', now '')" % before,
		"the static still holds '%s' after a launch — the next reload will be steered by it too" % EM.menu_chapter)

	_finish()


## Build a museum far enough to know where it decided to open, then drop it.
## `voice` empty means say nothing; otherwise it is passed exactly as the menu
## passes it, through the same static.
func _open(voice: Dictionary) -> Dictionary:
	EM.menu_chapter = ""
	EM.menu_map = ""
	if voice.has("chapter"):
		EM.open_at(String(voice["chapter"]), String(voice.get("map", "")))
	var n: Node3D = (load(MUSEUM_SCENE) as PackedScene).instantiate() as Node3D
	root.add_child(n)
	await process_frame
	# THE MAP IS start_map, NOT the pool row. The first version read
	# _pool[_pool_i].map and got "" every time — the pool's rows are chapters and
	# carry no map, so the probe reported "opened at ''" for every case and its
	# own control clause caught it as proving nothing. The pearl is a good thing
	# to print beside it, and a bad thing to assert on.
	var out := {"chapter": String(n.get("_first_chapter")), "map": String(n.get("start_map")), "pearl": ""}
	var pool: Variant = n.get("_pool")
	var pi: int = int(n.get("_pool_i"))
	if pool is Array and pi >= 0 and pi < (pool as Array).size():
		out["pearl"] = String(((pool as Array)[pi] as Dictionary).get("pearl", ""))
	n.queue_free()
	await process_frame
	return out


## A chapter that neither the menu nor the scene file would have chosen anyway.
##
## Excluding the SCENE'S OWN start_chapter matters as much as excluding the
## menu's: the first run of this picked "transformation", which is exactly what
## endless_museum.tscn ships in its Inspector — so the card's claim would have
## passed with the hand-off ripped out. The same shape as the control above, one
## level down, and it was already written into this file's own docstring.
func _a_chapter_other_than(chapter: String) -> String:
	var n: Node3D = (load(MUSEUM_SCENE) as PackedScene).instantiate() as Node3D
	root.add_child(n)
	await process_frame
	var pool: Variant = n.get("_pool")
	var shipped: String = String(n.get("start_chapter"))
	var out := ""
	if pool is Array:
		for row_v in (pool as Array):
			var s: String = String((row_v as Dictionary).get("sequence", ""))
			if s != "" and s != chapter and s != shipped:
				out = s
				break
	n.queue_free()
	await process_frame
	return out


func _check(ok: bool, line: String, why: String) -> void:
	_lines.append("[probe] %s  %s" % [line, "OK" if ok else "*** %s ***" % why])
	if not ok:
		_fails.append(why)


func _finish() -> void:
	var ok: bool = _fails.is_empty()
	_lines.append("[probe] %s%s" % ["PASS" if ok else "FAIL",
		"" if ok else " — " + String(";  ").join(PackedStringArray(_fails))])
	var f := FileAccess.open(REPORT, FileAccess.WRITE)
	if f != null:
		f.store_string(String.chr(10).join(PackedStringArray(_lines)) + String.chr(10))
		f.close()
	for l in _lines:
		print(l)
	quit(0 if ok else 1)
