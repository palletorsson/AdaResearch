extends SceneTree
## THE PAGE OF THE BOOK (2026-08-24, Palle: "I want the wall works of white frames
## with black canvas to be the page of the book. They should have one line or a
## visualization. When we double tap we get an editing window where we can change
## the current text, we can make field notes ... so we can write as we stand there
## looking at the museum").
##
## Proves the whole loop without a mouse, against a TRIAL COPY of the book — the
## probe-isolation rule: never write a file a live session reads.
##   1. the wall works are the page: white frame, black canvas, one line each
##   2. every hung line knows WHICH book line it is (em_speak_token) — the
##      distribution is by nearest anchor, so the binding cannot be recomputed
##   3. the page opens, edits, and WRITES BACK to the pearl's own line
##   4. field notes land in the book as `note` and survive a re-read
##   5. the canvas repaints in place, so the wall says what the book now says
## godot --headless --path . --xr-mode off --script res://commons/testing/probe_page_of_the_book.gd

const OUT := "res://ada_run/page_of_the_book_probe.txt"
const TRIAL := "res://ada_run/_trial_book"


func _initialize() -> void:
	call_deferred("_run")


func _copy_book() -> bool:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(TRIAL))
	var src := DirAccess.open("res://commons/data/book")
	if src == null:
		return false
	var n := 0
	for f in src.get_files():
		if not f.ends_with(".json"):
			continue
		var txt := FileAccess.get_file_as_string("res://commons/data/book/" + f)
		var w := FileAccess.open(TRIAL + "/" + f, FileAccess.WRITE)
		if w != null:
			w.store_string(txt)
			w.close()
			n += 1
	return n > 0


func _run() -> void:
	var fails: Array = []
	var notes: Array = []

	if not _copy_book():
		fails.append("could not copy the book to a trial dir")

	var inst: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	inst.set("EM_CONTROL", "res://ada_run/_trial_page_control.json")
	inst.set("_overrides_path", "res://ada_run/_trial_page_overrides.json")
	inst.set("_hand_path", "res://ada_run/_trial_page_hand.json")
	inst.set("start_chapter", "primitives")
	inst.set("start_map", "")
	var ctl := FileAccess.open("res://ada_run/_trial_page_control.json", FileAccess.WRITE)
	ctl.store_string(JSON.stringify({"first_chapter": "primitives", "dollhouse": 0, "grid_pack": 1}, " "))
	ctl.close()
	get_root().add_child(inst)
	inst.set("_book_dir", TRIAL)          # every write lands in the trial copy
	await create_timer(1.2).timeout
	inst.set("MIN_SEGMENTS", 99)
	inst.set("KEEP_BEHIND_M", 99999.0)
	inst.call("flush_stamps")
	await create_timer(2.0).timeout

	var segs: Array = inst.get("_segments")
	if segs.is_empty():
		fails.append("no segment built")
		_report(fails, notes)
		return

	# 1 + 2. the hung lines, and their binding back to the book
	var seg: Node3D = null
	var lbl: Label3D = null
	var si: int = -1
	for s_v in segs:
		var sd: Dictionary = s_v
		var sn: Node3D = sd.get("node")
		if sn == null or not is_instance_valid(sn):
			continue
		for n in sn.get_children():
			if n is Label3D and n.has_meta("em_speak") and n.has_meta("em_speak_token"):
				if String(n.get_meta("em_speak_token")) != "":
					seg = sn
					lbl = n as Label3D
					si = int(n.get_meta("em_speak"))
					break
		if lbl != null:
			break
	if lbl == null:
		fails.append("no hung line carries em_speak_token — the page does not know its line")
		_report(fails, notes)
		return
	notes.append("a wall work carries its line AND its token (%s)" % String(lbl.get_meta("em_speak_token")))

	# the canvas is black, the frame white — the page look
	var fields: Node = seg.find_child("WallFields", true, false)
	var frames: Node = seg.find_child("WallFrames", true, false)
	if fields == null or frames == null:
		fails.append("no WallFields/WallFrames — the wall works are not built as frame + canvas")
	else:
		notes.append("frame + canvas built (white frame, black field)")

	# 3 + 4. open the page, write a line and a field note
	var pearl := String(seg.get_meta("em_pearl")) if seg.has_meta("em_pearl") else ""
	var chapter := String(seg.get_meta("em_chapter")) if seg.has_meta("em_chapter") else ""
	inst.set("_page_ctx", {"chapter": chapter, "pearl": pearl,
		"token": String(lbl.get_meta("em_speak_token")), "si": si})
	inst.call("_page_build", lbl.text)
	if inst.get("_page_ui") == null:
		fails.append("the editing window did not open")
		_report(fails, notes)
		return
	notes.append("the editing window opens on %s - %s - page %02d" % [chapter, pearl, si + 1])

	var line_edit: TextEdit = inst.get("_page_line")
	var note_edit: TextEdit = inst.get("_page_note")
	if line_edit == null or note_edit == null:
		fails.append("the window has no line box or no field-notes box")
		_report(fails, notes)
		return
	var new_line := "a probe stood here and wrote this line"
	var new_note := "FIELD NOTE. Written standing in front of the canvas.\nThe detailed part goes here, and it is not what the wall says."
	line_edit.text = new_line
	note_edit.text = new_note
	inst.call("_page_save")

	# 5. the book on disk now says it
	var path := TRIAL + "/%s.json" % chapter
	var doc_v: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	var found_text := ""
	var found_note := ""
	if doc_v is Dictionary:
		for pv in ((doc_v as Dictionary).get("pearls", []) as Array):
			var pl: Dictionary = pv
			# the book names a pearl by its short name, the hall by its map —
			# read back the way the museum resolves it, or the instrument fails
			# a write that actually landed (it did, once, 2026-08-24)
			if String(pl.get("pearl", "")) != pearl 					and String(pl.get("map", "")).replace("_", " ").to_lower() != pearl:
				continue
			for lv in (pl.get("lines", []) as Array):
				var ln: Dictionary = lv
				if String(ln.get("token", "")) == String(lbl.get_meta("em_speak_token")):
					found_text = String(ln.get("text", ""))
					found_note = String(ln.get("note", ""))
	if found_text != new_line:
		fails.append("the book did not take the line (got %s)" % found_text.substr(0, 40))
	else:
		notes.append("the line is written into the pearl's own page")
	if found_note != new_note:
		fails.append("the field note did not land in the book")
	else:
		notes.append("the field note is written as `note`, %d characters" % found_note.length())

	# the canvas repainted in place
	if lbl.text != new_line:
		fails.append("the wall still says the old line (%s)" % lbl.text.substr(0, 30))
	else:
		notes.append("the canvas repaints in place - the wall says what the book says")

	# the real book is untouched
	var real_v: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://commons/data/book/%s.json" % chapter))
	var leaked := false
	if real_v is Dictionary:
		for pv2 in ((real_v as Dictionary).get("pearls", []) as Array):
			for lv2 in ((pv2 as Dictionary).get("lines", []) as Array):
				if String((lv2 as Dictionary).get("text", "")) == new_line:
					leaked = true
	if leaked:
		fails.append("THE PROBE WROTE THE REAL BOOK — isolation broken")
	else:
		notes.append("the real book is untouched (the trial copy took every write)")

	# 6. THE VISUALIZATION PAGE: turn this line into a plan of the hall, rebuild
	#    the pictures over the same labels, and check one actually hangs.
	var viz_ok := false
	if inst.get("_page_viz") != null:
		var ob: OptionButton = inst.get("_page_viz")
		ob.selected = 1                     # "a plan of this hall"
		inst.call("_page_save")
		var tile_now: Array = []
		var pk: Dictionary = inst.call("_plan_entry", "", chapter)
		if pk.get("tile") is Array:
			tile_now = pk["tile"]
		inst.call("_viz_pages", seg, chapter, pearl, tile_now)
		for n2 in seg.get_children():
			if n2 is MeshInstance3D and n2.has_meta("em_viz"):
				var mi := n2 as MeshInstance3D
				var mat: Material = mi.material_override
				if mat is StandardMaterial3D and (mat as StandardMaterial3D).albedo_texture != null:
					viz_ok = true
					notes.append("a visualization page hangs on the field (%.2f m, textured)" % (mi.mesh as QuadMesh).size.x)
					break
		if not viz_ok:
			fails.append("viz:plan was written but no picture hangs on the wall")
		# and the book kept the choice
		var re_v: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		var saw_viz := ""
		if re_v is Dictionary:
			for pv3 in ((re_v as Dictionary).get("pearls", []) as Array):
				var pl3: Dictionary = pv3
				if String(pl3.get("pearl", "")) != pearl 						and String(pl3.get("map", "")).replace("_", " ").to_lower() != pearl:
					continue
				for lv3 in (pl3.get("lines", []) as Array):
					if String((lv3 as Dictionary).get("token", "")) == String(lbl.get_meta("em_speak_token")):
						saw_viz = String((lv3 as Dictionary).get("viz", ""))
		if saw_viz != "plan":
			fails.append("the book did not keep viz:plan (got %s)" % saw_viz)
		else:
			notes.append("the book keeps the page kind as viz:plan")
	else:
		fails.append("the editing window has no visualization chooser")

	# 7. THE WALL READER, the same panel both lanes get: aim at the work from
	#    where it faces and the page opens IN THE WORLD, carrying the field
	#    notes the canvas has no room for.
	var aim_from: Vector3 = lbl.global_position + lbl.global_transform.basis.z * 1.6
	var aim_dir: Vector3 = -lbl.global_transform.basis.z
	var hit: Dictionary = inst.call("_wall_pick_aim", aim_from, aim_dir, 4.5, 0.45)
	if hit.is_empty():
		fails.append("aiming straight at a wall work found nothing to read")
	else:
		if not bool(inst.call("_wall_read_toggle", hit)):
			fails.append("the reader refused to open on a wall work")
		else:
			var rp: Node3D = inst.get("_wall_read")
			if rp == null or not is_instance_valid(rp):
				fails.append("the reader opened but built no panel")
			else:
				var rb := String(rp.get("body"))
				if not rb.contains(new_line):
					fails.append("the reader does not show the line (%s)" % rb.substr(0, 40))
				elif not rb.contains("FIELD NOTE"):
					fails.append("the reader does not show the field notes")
				else:
					notes.append("the reader opens in the WORLD (works in VR) with the line AND the field notes")
				# a second look puts it away
				inst.call("_wall_read_toggle", hit)
				if inst.get("_wall_read") != null:
					fails.append("a second look did not close the reader")
				else:
					notes.append("a second look closes it")

	# 8. THE INSPECTOR HOLDS THE PAGE (2026-08-24): selecting a wall work grows
	#    the text edit inside the inspector — one home, at the top — and writing
	#    from there reaches the same book line.
	var rec_i := -1
	var recs: Array = inst.get("_edit_records")
	for ri in range(recs.size()):
		var rr: Dictionary = recs[ri]
		if String(rr.get("kind", "")) == "showing" and int(rr.get("index", -1)) == si 				and rr.get("seg") == seg:
			rec_i = ri
			break
	if rec_i < 0:
		fails.append("no showing record for this wall work — the inspector cannot reach it")
	else:
		inst.call("_doll_select", rec_i)
		inst.call("_doll_insp_show")
		var insp: CanvasLayer = inst.get("_doll_insp")
		if insp == null or not is_instance_valid(insp):
			fails.append("the inspector did not open on a wall work")
		else:
			var panel: Node = insp.find_child("InspectorPanel", true, false)
			if panel == null:
				fails.append("the inspector has no styled panel")
			else:
				var pc := panel as PanelContainer
				# AT THE TOP: a negative top offset is the old bottom-right pane
				if pc.offset_top < 0.0:
					fails.append("the inspector still hangs from the bottom (offset_top %.0f)" % pc.offset_top)
				elif pc.anchor_bottom < 0.99:
					# a fixed-height box cropped the field notes and the write
					# button clean off the panel (measured 2026-08-24)
					fails.append("the inspector does not fill the height (anchor_bottom %.2f)" % pc.anchor_bottom)
				else:
					notes.append("the inspector stands at the TOP and FILLS the height")
			var sect: Node = insp.find_child("PageSection", true, false)
			if sect == null:
				fails.append("the inspector shows no page section for a wall work")
			else:
				notes.append("the inspector holds the page: line, field notes, what it shows")
			# THE FIXTURE STOOD ON THE HAPPY CELL (2026-08-27). This probe calls
			# _page_build at its top, which is the ONLY thing that ever assigns
			# _page_ui — and _page_save guarded on _page_ui. So this check has
			# always saved through a modal window the museum stopped opening on
			# 2026-08-26, and reported green while every write a person could
			# actually make returned on its first line. 842 lines in the book and
			# not one note in any commit, with a 17-check probe passing over it.
			#
			# Put the modal away and rebuild the page the way the inspector does,
			# so what is measured from here down is the path the hand walks.
			inst.call("_page_close")
			inst.call("_insp_page_clear")
			inst.call("_insp_page_section")
			if inst.get("_page_ui") != null:
				fails.append("the modal is still open - this is not the field's path")
			else:
				notes.append("the inspector page stands with NO modal window behind it")
			var il: TextEdit = inst.get("_page_line")
			var ino: TextEdit = inst.get("_page_note")
			if il == null or ino == null:
				fails.append("the inspector page has no line or no notes box")
			else:
				var from_insp := "written from the inspector at the top"
				il.text = from_insp
				ino.text = "a second note, from the inspector"
				inst.call("_page_save")
				var back_v: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
				var got := ""
				if back_v is Dictionary:
					for pv4 in ((back_v as Dictionary).get("pearls", []) as Array):
						var pl4: Dictionary = pv4
						if String(pl4.get("pearl", "")) != pearl 								and String(pl4.get("map", "")).replace("_", " ").to_lower() != pearl:
							continue
						for lv4 in (pl4.get("lines", []) as Array):
							if String((lv4 as Dictionary).get("token", "")) == String(lbl.get_meta("em_speak_token")):
								got = String((lv4 as Dictionary).get("text", ""))
				if got != from_insp:
					fails.append("writing from the inspector did not reach the book (got %s)" % got.substr(0, 30))
				else:
					notes.append("writing from the inspector reaches the same book line")
				# THE REFLECTION, which is the reason any of this exists: the field
				# note must survive the same round trip as the line. It is checked
				# separately because `text` and `note` are written by two different
				# branches of _page_save, and only one of them was ever asserted.
				var got_note := ""
				if back_v is Dictionary:
					for pv5 in ((back_v as Dictionary).get("pearls", []) as Array):
						var pl5: Dictionary = pv5
						if String(pl5.get("pearl", "")) != pearl \
								and String(pl5.get("map", "")).replace("_", " ").to_lower() != pearl:
							continue
						for lv5 in (pl5.get("lines", []) as Array):
							if String((lv5 as Dictionary).get("token", "")) == String(lbl.get_meta("em_speak_token")):
								got_note = String((lv5 as Dictionary).get("note", ""))
				if got_note != "a second note, from the inspector":
					fails.append("THE REFLECTION did not reach the book (note is %s)" % (
						"empty" if got_note == "" else got_note.substr(0, 30)))
				else:
					notes.append("the FIELD NOTE lands in the book beside its line")
			# selecting something else puts the page away
			inst.call("_doll_select", -1)
			inst.call("_insp_page_section")

	# 9. THE PICTURE MOVES (2026-08-24): a wall work is six batched boxes, and
	#    a drag used to move a magenta ghost standing in for them. The real
	#    instances must travel — and its sentence with them.
	var parts: Array = inst.call("_showing_parts", seg, si)
	if parts.is_empty():
		fails.append("showing %d owns no MultiMesh instances — the picture cannot move" % si)
	else:
		# READ THE STASH, NOT THE BUFFER: MultiMesh instance transforms come back
		# as identity under the dummy renderer, so this check used to measure
		# nothing and would have passed a mover that moved everything to the
		# origin (2026-08-24 — a headless probe measures another game).
		var nd0: MultiMeshInstance3D = (parts[0] as Array)[3]
		var i0: int = int((parts[0] as Array)[1])
		var xf_a: Array = nd0.get_meta("em_xforms")
		var was_o: Vector3 = (xf_a[i0] as Transform3D).origin
		var was_l: Vector3 = lbl.position
		inst.call("_showing_move", seg, si, Vector3(0.25, 0.1, 0.0))
		var now_o: Vector3 = ((nd0.get_meta("em_xforms") as Array)[i0] as Transform3D).origin
		if now_o.distance_to(was_o) < 0.2:
			fails.append("the picture did not move (%.2f m)" % now_o.distance_to(was_o))
		elif lbl.position.distance_to(was_l) < 0.2:
			fails.append("the picture moved but its sentence stayed behind")
		else:
			notes.append("the wall work itself moves, sentence with it (%d part group(s))" % parts.size())
		inst.call("_showing_move", seg, si, Vector3(-0.25, -0.1, 0.0))

	# 10. A WALL WORK NEEDS A WALL: nothing may hang over open floor
	var floating := 0
	for n3 in seg.get_children():
		if not n3.has_meta("em_showing") or n3.has_meta("em_hand_removed"):
			continue
		var pw: Vector3 = (n3 as Node3D).global_position
		var cx3: int = int(floor(pw.x))
		var cz3: int = int(floor(pw.z)) - int(float(segs[0]["z0"])) - 4
		var backed := false
		var tl: Array = inst.call("_plan_entry", "", chapter).get("tile", [])
		if tl.is_empty():
			break
		for d3 in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(0, 0)]:
			var tx3: int = cx3 + d3.x
			var tz3: int = cz3 + d3.y
			if tz3 < 0 or tz3 >= tl.size():
				continue
			var rw3: Array = tl[tz3]
			if tx3 >= 0 and tx3 < rw3.size() and String(rw3[tx3]).begins_with("4"):
				backed = true
				break
		if not backed:
			floating += 1
	if floating > 0:
		fails.append("%d wall work(s) still hang on nothing" % floating)
	else:
		notes.append("every standing wall work has a wall behind it")

	inst.call("_page_close")
	if inst.get("_page_ui") != null:
		fails.append("the window did not close")
	else:
		notes.append("the window closes")
	_report(fails, notes)


func _report(fails: Array, notes: Array) -> void:
	var report := "PAGE OF THE BOOK PROBE\n"
	for n in notes:
		report += "  ok   %s\n" % n
	for f in fails:
		report += "  FAIL %s\n" % f
	report += "%d fail(s)\n" % fails.size()
	var fh := FileAccess.open(OUT, FileAccess.WRITE)
	fh.store_string(report)
	fh.close()
	print(report)
	quit(1 if not fails.is_empty() else 0)
