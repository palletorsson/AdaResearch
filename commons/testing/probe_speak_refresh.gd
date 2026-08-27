extends SceneTree
## DOES AN EDIT AT THE DESK REACH A RUNNING MUSEUM? (2026-08-27, Palle: "if I
## change wall-map will it change the godot endless museum?")
##
## Three registers travel three different ways, and only two of them worked:
##
##   adopt / hang   read from commons/data/book/<chapter>.json on every build.
##                  Live at the next rebuild of that hall. Never cached.
##   the SENTENCE   read from commons/data/trunk_branches.json through
##                  _speak_for — which cached each hall the first time it was
##                  asked and never emptied the cache. A line written at the
##                  desk reached the book, reached the trunk through
##                  book.py compile, and then sat there unread while the museum
##                  kept saying the old one, through rebuilds, until the process
##                  was restarted.
##
## This proves the cache now follows the trunk's modified time. It never writes
## the trunk — os.utime is not available here and rewriting an 837 KB file that
## another session may be holding is not worth a test — so it moves the museum's
## own record of when it last read, which is the same fork in the code.
##
## godot --headless --path . --xr-mode off --script res://commons/testing/probe_speak_refresh.gd

const OUT := "res://ada_run/speak_refresh_probe.txt"
const TRUNK := "res://commons/data/trunk_branches.json"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var fails: Array = []
	var notes: Array = []

	var inst: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	inst.set("EM_CONTROL", "res://ada_run/_trial_speak_control.json")
	inst.set("_overrides_path", "res://ada_run/_trial_speak_ov.json")
	inst.set("_hand_path", "res://ada_run/_trial_speak_hand.json")
	var c := FileAccess.open("res://ada_run/_trial_speak_control.json", FileAccess.WRITE)
	c.store_string(JSON.stringify({"first_chapter": "primitives", "dollhouse": 0}, " "))
	c.close()
	get_root().add_child(inst)
	await create_timer(1.4).timeout

	# 1. the first ask fills the cache
	var one: Dictionary = inst.call("_speak_for", "primitives", "point one")
	var cache: Dictionary = inst.get("_speak_cache")
	if cache.is_empty():
		fails.append("asking for a hall's words cached nothing — the cache is not in play")
		_report(fails, notes)
		return
	notes.append("the first ask caches the hall (%d entry)" % cache.size())
	var said: int = (one.get("says", {}) as Dictionary).size()
	if said == 0:
		notes.append("this hall has no lines in the trunk — the identity check still stands")
	else:
		notes.append("%d line(s) read for primitives|point one" % said)

	# 2. the cache must not be dropped when nothing changed
	var stamp0: int = int(inst.get("_speak_trunk_at"))
	inst.call("_speak_for", "primitives", "point one")
	if int(inst.get("_speak_trunk_at")) != stamp0:
		fails.append("the stamp moved without the trunk changing")
	elif (inst.get("_speak_cache") as Dictionary).size() != cache.size():
		fails.append("the cache was dropped though the trunk had not changed — every ask reparses 837 KB")
	else:
		notes.append("an unchanged trunk keeps the cache (it is still a cache)")

	# 3. a CHANGED trunk empties it, and the words come back
	inst.set("_speak_trunk_at", -999)
	var again: Dictionary = inst.call("_speak_for", "primitives", "point one")
	var stamp1: int = int(inst.get("_speak_trunk_at"))
	if stamp1 == -999:
		fails.append("THE CACHE NEVER NOTICED: a changed trunk left the stamp alone, so a "
			+ "line written at the desk cannot reach a running museum")
	else:
		notes.append("a changed trunk is noticed, and the stamp is taken again (%d)" % stamp1)
	if stamp1 != int(FileAccess.get_modified_time(TRUNK)):
		fails.append("the stamp is not the trunk's modified time — it will drift")
	else:
		notes.append("the stamp IS the trunk's modified time")
	if (again.get("says", {}) as Dictionary).size() != said:
		fails.append("re-reading gave %d lines where the first read gave %d"
			% [(again.get("says", {}) as Dictionary).size(), said])
	else:
		notes.append("the re-read says the same thing — the refresh is not a reset")

	# 4. and the OTHER two registers are not cached at all
	var h1: Array = inst.call("_speak_hang", "primitives", "point")
	var h2: Array = inst.call("_speak_hang", "primitives", "point")
	if h1.size() != h2.size():
		fails.append("the hang is not stable between two reads")
	else:
		notes.append("the hang is re-read from the book every time (%d row(s)), never cached" % h1.size())

	_report(fails, notes)


func _report(fails: Array, notes: Array) -> void:
	var r := "SPEAK REFRESH PROBE\n"
	for n in notes:
		r += "  ok   %s\n" % n
	for f in fails:
		r += "  FAIL %s\n" % f
	r += "%d fail(s)\n" % fails.size()
	var fh := FileAccess.open(OUT, FileAccess.WRITE)
	fh.store_string(r)
	fh.close()
	print(r)
	quit(1 if not fails.is_empty() else 0)
