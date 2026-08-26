extends SceneTree
## THE ADOPTION (2026-08-26, Palle: "what is a good connection between the pearl
## text and 3d space and the text and the book?").
## Closeness is the DEFAULT; the written binding is the hand. Proves:
##   1. a hall writes a LEDGER of which page speaks for which work
##   2. a hand `adopt` on the pearl OUTRANKS closeness — that page carries that
##      work's line even though the nearest body is someone else
##   3. an empty token pins a wall SILENT
##   4. everything unadopted still falls to closeness
## Runs against a TRIAL COPY of the book: the real one is never written.
const OUT := "res://ada_run/adoption_probe.txt"
const TRIAL := "res://ada_run/_trial_adopt_book"

func _initialize() -> void: call_deferred("_run")

func _copy_book(adopt_into: String, adopt_rows: Array) -> Dictionary:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(TRIAL))
	var src := DirAccess.open("res://commons/data/book")
	var pearl_used := ""
	var doc_out: Dictionary = {}
	for f in src.get_files():
		if not f.ends_with(".json"):
			continue
		var txt := FileAccess.get_file_as_string("res://commons/data/book/" + f)
		if f == adopt_into + ".json":
			var d: Variant = JSON.parse_string(txt)
			if d is Dictionary:
				var doc: Dictionary = d
				for pv in (doc.get("pearls", []) as Array):
					var pl: Dictionary = pv
					if String(pl.get("map", "")) == "Point_One":
						pl["adopt"] = adopt_rows
						pl["hang"] = [{"page": 0, "cell": [1, 5], "dir": [1, 0]}]
						pearl_used = String(pl.get("pearl", ""))
						doc_out = doc
						break
				txt = JSON.stringify(doc, " ")
		var w := FileAccess.open(TRIAL + "/" + f, FileAccess.WRITE)
		w.store_string(txt); w.close()
	return {"pearl": pearl_used, "doc": doc_out}

func _run() -> void:
	var fails: Array = []
	var notes: Array = []
	# page 0 adopts a work that is NOT the nearest to it; page 1 is pinned silent
	# page 2 adopts a FOYER token: closeness skips those (their lines stand on
	# the foyer wall), so before 2026-08-26 this ruling was written, saved,
	# compiled and silently ignored. The hand outranks the heuristic now.
	var setup: Dictionary = _copy_book("primitives", [
		{"page": 0, "token": "you_are_here"}, {"page": 1, "token": ""},
		{"page": 2, "token": "origin"}])
	# and MOVE page 0 to a named wall face — the hang ruling, read from the same
	# pearl as the adoption, so one editor writes one file
	var moved_to := Vector2i(0, 0)
	if String(setup.get("pearl", "")) == "":
		fails.append("could not find the Point_One pearl to adopt into")

	var inst: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	inst.set("EM_CONTROL", "res://ada_run/_trial_adopt_control.json")
	inst.set("_overrides_path", "res://ada_run/_trial_adopt_ov.json")
	inst.set("_hand_path", "res://ada_run/_trial_adopt_hand.json")
	inst.set("start_chapter", "primitives")
	inst.set("start_map", "")
	var c := FileAccess.open("res://ada_run/_trial_adopt_control.json", FileAccess.WRITE)
	c.store_string(JSON.stringify({"first_chapter": "primitives", "dollhouse": 0, "grid_pack": 1}, " ")); c.close()
	get_root().add_child(inst)
	inst.set("_book_dir", TRIAL)
	await create_timer(1.2).timeout
	inst.call("flush_stamps")
	await create_timer(2.2).timeout

	var seg: Node3D = null
	for sv in (inst.get("_segments") as Array):
		var sn: Node3D = (sv as Dictionary).get("node")
		if sn != null and is_instance_valid(sn) and sn.has_meta("em_pearl"):
			seg = sn
			break
	if seg == null:
		fails.append("no hall built")
		_report(fails, notes); return
	var pearl := String(seg.get_meta("em_pearl"))

	# 2 + 3. the hand's pages
	var at0 := ""
	var page1_spoke := false
	for n in seg.get_children():
		if not (n is Label3D) or not n.has_meta("em_speak"):
			continue
		var pg: int = int(n.get_meta("em_speak"))
		if pg == 0:
			at0 = String(n.get_meta("em_speak_token")) if n.has_meta("em_speak_token") else ""
		elif pg == 1:
			page1_spoke = true
	if at0 != "you_are_here":
		fails.append("page 0 adopted '%s' — the hand said you_are_here" % at0)
	else:
		notes.append("the hand's adoption OUTRANKS closeness (page 0 speaks for you_are_here)")
	if page1_spoke:
		fails.append("page 1 was pinned silent and still spoke")
	else:
		notes.append("an empty token pins a wall SILENT")

	# THE HANG: page 0 was given a wall face, and its boxes must be there
	if _hang_check(seg):
		notes.append("a hand `hang` moves the wall work to the named face")
	else:
		fails.append("the hang ruling did not move page 0's boxes")

	# the foyer token the hand adopted
	var at2 := ""
	for n3 in seg.get_children():
		if n3 is Label3D and n3.has_meta("em_speak") and int(n3.get_meta("em_speak")) == 2:
			at2 = String(n3.get_meta("em_speak_token")) if n3.has_meta("em_speak_token") else ""
	if at2 != "origin":
		fails.append("page 2 adopted a FOYER token and got '%s' — the ruling was ignored" % at2)
	else:
		notes.append("an adopted FOYER token is honoured (closeness would have skipped it)")

	# 4. the rest still fell to closeness
	var spoke := 0
	for n2 in seg.get_children():
		if n2 is Label3D and n2.has_meta("em_speak"):
			spoke += 1
	if spoke < 2:
		fails.append("only %d wall(s) speak — closeness stopped working" % spoke)
	else:
		notes.append("%d walls speak in all; the unadopted still fall to closeness" % spoke)

	# 1. the ledger
	var lp := "res://ada_run/em_adoptions.json"
	if not FileAccess.file_exists(lp):
		fails.append("no ledger written at " + lp)
	else:
		var lv: Variant = JSON.parse_string(FileAccess.get_file_as_string(lp))
		var halls: Dictionary = (lv as Dictionary).get("halls", {}) if lv is Dictionary else {}
		var key := "primitives|" + pearl
		if not halls.has(key):
			fails.append("the ledger has no row for %s (has %s)" % [key, str(halls.keys()).substr(0, 90)])
		else:
			var rows: Array = halls[key]
			var first := String((rows[0] as Dictionary).get("token", "")) if rows.size() > 0 else ""
			if first != "you_are_here":
				fails.append("the ledger says page 0 speaks for '%s'" % first)
			else:
				notes.append("the ledger records what was ACTUALLY hung (%d pages)" % rows.size())

	# the real book is untouched
	var real := FileAccess.get_file_as_string("res://commons/data/book/primitives.json")
	if real.contains("\"adopt\""):
		fails.append("THE PROBE WROTE THE REAL BOOK — isolation broken")
	else:
		notes.append("the real book is untouched")
	_report(fails, notes)

## page 0 was ruled onto the face of TILE cell (1,5) looking +x; its boxes must
## sit on that plane. Read from the stash em_detail keeps, never from the
## MultiMesh buffer — headless returns identity for every instance transform.
##
## THE Z IS THE POINT OF THIS CHECK (2026-08-26). The first cut tested x alone,
## and x is the one axis the two candidate frames AGREE on — so a hang written
## four rows out would have passed green. The book speaks TILE z; the segment
## puts tile row y at z = y + VESTIBULE_H, and _speak_hang adds it. So tile row
## 5 must land at 5 + 4 + 0.5 = 9.5, and 5.5 means the vestibule was dropped.
func _hang_check(seg: Node3D) -> bool:
	var nd: Node = seg.find_child("WallMounts", true, false)
	if nd == null or not nd.has_meta("em_xforms"):
		return false
	var xf: Array = nd.get_meta("em_xforms")
	if xf.is_empty():
		return false
	var o: Vector3 = (xf[0] as Transform3D).origin
	var want_z: float = 5.0 + 4.0 + 0.5
	if absf(o.z - want_z) > 0.2:
		push_error("hang landed at z=%.2f, the tile frame says %.2f (out by %.1f rows)" % [
			o.z, want_z, (want_z - o.z)])
		return false
	return absf(o.x - 2.0) < 0.2


func _report(fails: Array, notes: Array) -> void:
	var r := "ADOPTION PROBE\n"
	for n in notes: r += "  ok   %s\n" % n
	for f in fails: r += "  FAIL %s\n" % f
	r += "%d fail(s)\n" % fails.size()
	var fh := FileAccess.open(OUT, FileAccess.WRITE); fh.store_string(r); fh.close()
	print(r)
	quit(1 if not fails.is_empty() else 0)
