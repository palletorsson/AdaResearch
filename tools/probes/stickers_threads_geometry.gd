extends SceneTree
## THE THREADS' GEOMETRY AGAINST THE CONTRACT'S: StickerData's ports (commons/stickers/sticker_data.gd) of the four
## functions every medium draws a thread and a hanging board's cord with - stickers.ts drawnThreads, pinOf, threadCurve
## (its at(u) is curve_at here) and cordOf - run on a placements document, its designs and its boards, and written out
## for comparison with the same four functions of ada_encyclopedia/src/lib/stickers.ts run on the SAME files (the
## runner in commons/stickers/README.md, "Checks"). The two must agree number for number: which threads each board
## draws, in which order, each one's pins, its curve's control point and seventeen points along it (u = i / 16, the tag
## at u = 0.5), and on a hanging board every live sticker's cord.
##   godot --headless --path . --xr-mode off --script res://tools/probes/stickers_threads_geometry.gd -- \
##       <placements.json> <designs.json> <boards.json> <out.json>
## Every board of <boards.json> as cleanBoard reads it (clean_board); a board that does not clean is left out, as
## cleanBoardsDoc would refuse it. Point it at COPIES of commons/data/stickers/*.json: it reads its inputs and writes
## only <out.json>. Doubles are written in full (JSON.stringify full_precision).

const SAMPLES := 16

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() < 4:
		push_error("stickers_threads_geometry: give <placements.json> <designs.json> <boards.json> <out.json>")
		quit(2)
		return
	var doc: Variant = JSON.parse_string(FileAccess.get_file_as_string(a[0]))
	var designs_doc: Variant = JSON.parse_string(FileAccess.get_file_as_string(a[1]))
	var boards_doc: Variant = JSON.parse_string(FileAccess.get_file_as_string(a[2]))
	if not doc is Dictionary or not designs_doc is Dictionary or not boards_doc is Dictionary:
		push_error("stickers_threads_geometry: an input does not read as JSON of the right shape")
		quit(3)
		return
	var SD: Script = load("res://commons/stickers/sticker_data.gd")
	var designs := {}
	for d in (designs_doc as Dictionary).get("designs", []):
		if d is Dictionary:
			designs[str(d.get("id", ""))] = d
	var out := {}
	var n_threads := 0
	var n_cords := 0
	for raw in (boards_doc as Dictionary).get("boards", []):
		var b: Dictionary = SD.clean_board(raw)
		if b.is_empty():
			continue
		var id := str(b.id)
		var threads: Array = []
		for e in SD.drawn_threads(doc, id):
			var pa: Array = SD.pin_of(e.a, designs.get(str(e.a.get("design", ""))))
			var pb: Array = SD.pin_of(e.b, designs.get(str(e.b.get("design", ""))))
			var cv: Dictionary = SD.thread_curve(pa, pb)
			var pts: Array = []
			for i in SAMPLES + 1:
				pts.append(SD.curve_at(cv, float(i) / float(SAMPLES)))
			threads.append({"id": str(e.thread.get("id", "")), "a": str(e.a.get("id", "")), "b": str(e.b.get("id", "")),
				"p": cv.p, "c": cv.c, "q": cv.q, "at": pts})
		var cords: Array = []
		if bool(b.get("hang", false)):
			for s in (doc as Dictionary).get("stickers", []):
				var h: Variant = s.get("host")
				if not h is Dictionary or str(h.get("kind", "")) != "board" or str(h.get("id", "")) != id or str(s.get("state", "")) != "on":
					continue
				var pin: Array = SD.pin_of(s, designs.get(str(s.get("design", ""))))
				cords.append({"id": str(s.get("id", "")), "line": SD.cord_of(pin, b)})
		n_threads += threads.size()
		n_cords += cords.size()
		out[id] = {"board": b, "threads": threads, "cords": cords}
	var f := FileAccess.open(a[3], FileAccess.WRITE)
	f.store_string(JSON.stringify({"boards": out}, "", false, true))
	f.close()
	print("stickers_threads_geometry: %d boards, %d threads drawn, %d cords" % [out.size(), n_threads, n_cords])
	quit(0)
