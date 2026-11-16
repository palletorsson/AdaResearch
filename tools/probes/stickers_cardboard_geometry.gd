extends SceneTree
## THE CARDBOARD CONSTRUCTIONS' GEOMETRY (and cleaning) AGAINST THE CONTRACT'S: StickerData's ports
## (commons/stickers/sticker_data.gd) of stickers.ts wallPoint, wallYaw, drawnWallThreads (with pinOf and threadCurve),
## drawnStrokes, strokeZ, wallsOf, cleanBoard, cleanConstructionsDoc (with and without the boards) and cleanStroke, run on
## a placements document, its designs, its boards and its constructions, and written out for comparison with the same
## functions of ada_encyclopedia/src/lib/stickers.ts on the SAME files (tools/probes/stickers_cardboard_runner.ts
## geometry; tools/probes/stickers_cardboard_parity.py runs both and compares, to 1e-9). For every wall of every
## construction: its turn, eight points of its board frame in the construction's frame (the centre, the four corners,
## the back's centre, a point half a metre out, a point on the back's scribble plane) and every sticker's pin on it; every
## thread the construction draws between its walls, in order, with its pins, its curve's control point and seventeen
## points along it; every board's drawn strokes per face, in order, and where each one's ends stand in its construction;
## and the cleaning of every board, of the constructions document and of every stroke of the file, plus the CASES (a
## JSON file of raw boards, constructions documents and strokes, each named: every refusal and every clamp).
##   godot --headless --path . --xr-mode off --script res://tools/probes/stickers_cardboard_geometry.gd -- \
##       <placements.json> <designs.json> <boards.json> <constructions.json> <cases.json | -> <out.json> [--sd=<path>] [--mode=over]
## The constructions are read as the server reads them (cleanConstructionsDoc without the boards). Point it at COPIES of
## commons/data/stickers/*.json: it reads its inputs and writes only <out.json>. Doubles are written in full.
##
## --mode=over: A THREAD NEVER PASSES THROUGH CARDBOARD, and nothing else - the port's wallLines, overWalls, threadPieces,
## overBoard and drawnWallThreads' `over`, on the same inputs: for every construction its wall lines and every thread it
## draws between its walls (pins, the points over the walls, the pieces, the tag piece, each piece's control point and
## middle, the tag's point); for every board every thread drawn on it alone (drawnThreads; pins in the board frame, over
## its top edge by overBoard, pieces and tag likewise); the CASES' `over` key (named overWalls cases - pins given in the
## construction frame or on a wall's board frame, walls given as wall lines or by board id - named overBoard and
## threadPieces cases); and the constants every medium draws with (THREAD_OVER ... PENS, PEN_COLOUR_NAMES, STROKE_STEP).

const NOW := "2026-11-13T12:00:00Z"
const SAMPLES := 16
const OVER_FUNCS := ["wall_lines", "over_walls", "thread_pieces", "over_board", "drawn_wall_threads", "drawn_threads", "pin_of", "thread_curve",
	"curve_at", "wall_point", "clean_constructions_doc", "clean_board"]
const CONSTANTS := ["THREAD_OVER", "THREAD_CLEAR", "CARDBOARD", "MITER_LIMIT", "STROKE_STEP", "STROKE_DOT", "STROKE_LIFT", "STROKE_POINTS",
	"PEN_LIST", "PENS", "PEN_COLOURS", "PEN_COLOUR_NAMES"]

func _initialize() -> void:
	var a: Array = []
	var sd_path := "res://commons/stickers/sticker_data.gd"
	var mode := "geometry"
	for x in OS.get_cmdline_user_args():
		if x.begins_with("--sd="):
			sd_path = x.substr(5)
		elif x.begins_with("--mode="):
			mode = x.substr(7)
		else:
			a.append(x)
	if a.size() < 6:
		push_error("stickers_cardboard_geometry: give <placements.json> <designs.json> <boards.json> <constructions.json> <cases.json|-> <out.json> [--sd=<path>] [--mode=over]")
		quit(2)
		return
	var doc: Variant = JSON.parse_string(FileAccess.get_file_as_string(a[0]))
	var designs_doc: Variant = JSON.parse_string(FileAccess.get_file_as_string(a[1]))
	var boards_doc: Variant = JSON.parse_string(FileAccess.get_file_as_string(a[2]))
	var cons_raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(a[3]))
	var cases: Variant = {} if str(a[4]) == "-" else JSON.parse_string(FileAccess.get_file_as_string(a[4]))
	if not doc is Dictionary or not designs_doc is Dictionary or not boards_doc is Dictionary or not cases is Dictionary:
		push_error("stickers_cardboard_geometry: an input does not read as JSON of the right shape")
		quit(3)
		return
	var SD: Script = load(sd_path)
	if SD == null:
		push_error("stickers_cardboard_geometry: %s does not load" % sd_path)
		quit(4)
		return
	if mode == "over":
		_over_mode(SD, doc, designs_doc, boards_doc, cons_raw, cases, a[5], sd_path)
		return
	for fn in ["wall_point", "wall_yaw", "drawn_wall_threads", "drawn_strokes", "stroke_z", "walls_of", "clean_constructions_doc", "clean_stroke"]:
		if not (SD.get_script_method_list() as Array).any(func(m): return str(m.get("name", "")) == fn):
			push_error("stickers_cardboard_geometry: %s has no %s (a port from before the constructions)" % [sd_path, fn])
			quit(5)
			return
	var designs := {}
	for d in (designs_doc as Dictionary).get("designs", []):
		if d is Dictionary:
			designs[str(d.get("id", ""))] = d
	# the boards as the server holds them (cleanBoardsDoc: every record cleaned), in the file's order
	var boards := {}
	var board_ids: Array = []
	var clean_boards := {}
	for raw in (boards_doc as Dictionary).get("boards", []):
		var b: Dictionary = SD.clean_board(raw)
		clean_boards["file:%s" % str(raw.get("id", "")) if raw is Dictionary else "file:?"] = b if not b.is_empty() else null
		if not b.is_empty():
			boards[str(b.id)] = b
			board_ids.append(str(b.id))
	for e in (cases as Dictionary).get("boards", []):
		var b: Dictionary = SD.clean_board(e.get("raw"))
		clean_boards[str(e.name)] = b if not b.is_empty() else null
	var clean_cons := {"file": {"plain": SD.clean_constructions_doc(cons_raw), "boards": SD.clean_constructions_doc(cons_raw, boards)}}
	for e in (cases as Dictionary).get("constructions", []):
		clean_cons[str(e.name)] = {"plain": SD.clean_constructions_doc(e.get("raw")), "boards": SD.clean_constructions_doc(e.get("raw"), boards)}
	var clean_strokes := {}
	for s in (doc as Dictionary).get("strokes", []):
		clean_strokes["file:%s" % str(s.get("id", "")) if s is Dictionary else "file:?"] = SD.clean_stroke(s, NOW)
	for e in (cases as Dictionary).get("strokes", []):
		clean_strokes[str(e.name)] = SD.clean_stroke(e.get("raw"), NOW)
	var read: Dictionary = clean_cons.file.plain
	if not read.has("doc"):
		push_error("stickers_cardboard_geometry: <constructions.json> does not clean: %s" % str(read.get("error", "")))
		quit(3)
		return
	var cons: Dictionary = read.doc
	var walls: Dictionary = SD.walls_of(cons)
	var out_cons := {}
	var n_points := 0
	var n_threads := 0
	for c in cons.constructions:
		var tables := {}
		for t in c.tables:
			tables[str(t.id)] = t
		var wall_rows: Array = []
		for w in c.walls:
			var t: Dictionary = tables.get(str(w.table), {})
			var b: Variant = boards.get(str(w.board))
			var points: Array = []
			var pins: Array = []
			if b is Dictionary and not t.is_empty():
				var hw := float(b.w) / 2.0
				var hh := float(b.h) / 2.0
				for p in [[0.0, 0.0, 0.0], [-hw, -hh, 0.0], [hw, -hh, 0.0], [hw, hh, 0.0], [-hw, hh, 0.0], [0.0, 0.0, -SD.CARDBOARD],
						[0.1234, -0.2345, 0.5], [-0.3, 0.25, -SD.CARDBOARD - SD.STROKE_LIFT]]:
					points.append(SD.wall_point(t, w, b, p))
				for s in (doc as Dictionary).get("stickers", []):
					var h: Variant = s.get("host")
					if h is Dictionary and str(h.get("kind", "")) == "board" and str(h.get("id", "")) == str(w.board):
						pins.append({"id": str(s.get("id", "")), "at": SD.wall_point(t, w, b, SD.pin_of(s, designs.get(str(s.get("design", "")))))})
			n_points += points.size() + pins.size()
			wall_rows.append({"board": w.board, "table": w.table, "yaw": SD.wall_yaw(t, w) if not t.is_empty() else null, "points": points, "pins": pins})
		var thread_rows: Array = []
		for e in SD.drawn_wall_threads(doc, c, boards, designs):
			var cv: Dictionary = SD.thread_curve(e.p, e.q)
			var pts: Array = []
			for i in SAMPLES + 1:
				pts.append(SD.curve_at(cv, float(i) / float(SAMPLES)))
			thread_rows.append({"id": str(e.thread.get("id", "")), "a": str(e.a.get("id", "")), "b": str(e.b.get("id", "")), "p": e.p, "q": e.q, "c": cv.c, "at": pts})
		n_threads += thread_rows.size()
		out_cons[str(c.id)] = {"walls": wall_rows, "threads": thread_rows}
	var out_strokes := {}
	var n_strokes := 0
	for id in board_ids:
		var ids := func(list: Array) -> Array: return list.map(func(s): return str(s.get("id", "")))
		var all: Array = SD.drawn_strokes(doc, id)
		var ends: Array = []
		var cid := str(walls.get(id, ""))
		var place := {}
		for c in cons.constructions:
			if str(c.id) == cid:
				for w in c.walls:
					if str(w.board) == id:
						for t in c.tables:
							if str(t.id) == str(w.table):
								place = {"t": t, "w": w}
		if not place.is_empty():
			for s in all:
				var pts: Array = s.points
				var z: float = SD.stroke_z(str(s.face))
				ends.append({"id": str(s.id), "face": str(s.face),
					"first": SD.wall_point(place.t, place.w, boards[id], [float(pts[0][0]), float(pts[0][1]), z]),
					"last": SD.wall_point(place.t, place.w, boards[id], [float(pts[-1][0]), float(pts[-1][1]), z])})
		n_strokes += all.size()
		out_strokes[id] = {"front": ids.call(SD.drawn_strokes(doc, id, "front")), "back": ids.call(SD.drawn_strokes(doc, id, "back")), "all": ids.call(all), "ends": ends}
	var out := {"clean": {"boards": clean_boards, "constructions": clean_cons, "strokes": clean_strokes}, "walls_of": walls,
		"stroke_z": {"front": SD.stroke_z("front"), "back": SD.stroke_z("back")}, "constructions": out_cons, "strokes": out_strokes}
	var f := FileAccess.open(a[5], FileAccess.WRITE)
	f.store_string(JSON.stringify(out, "", false, true))
	f.close()
	print("stickers_cardboard_geometry: %d constructions, %d wall points and pins, %d threads between walls, %d strokes drawn; cleaned %d boards, %d constructions documents, %d strokes" % [
		out_cons.size(), n_points, n_threads, n_strokes, clean_boards.size(), clean_cons.size(), clean_strokes.size()])
	quit(0)

# ---- --mode=over: a thread never passes through cardboard ----

func _over_mode(SD: Script, doc: Variant, designs_doc: Variant, boards_doc: Variant, cons_raw: Variant, cases: Dictionary, out_path: String, sd_path: String) -> void:
	for fn in OVER_FUNCS:
		if not (SD.get_script_method_list() as Array).any(func(m): return str(m.get("name", "")) == fn):
			push_error("stickers_cardboard_geometry: %s has no %s (a port from before a thread went over the walls)" % [sd_path, fn])
			quit(5)
			return
	var designs := {}
	for d in (designs_doc as Dictionary).get("designs", []):
		if d is Dictionary:
			designs[str(d.get("id", ""))] = d
	# the boards as the server holds them (cleanBoardsDoc: every record cleaned), in the file's order
	var boards := {}
	var board_ids: Array = []
	for raw in (boards_doc as Dictionary).get("boards", []):
		var b: Dictionary = SD.clean_board(raw)
		if not b.is_empty():
			boards[str(b.id)] = b
			board_ids.append(str(b.id))
	var read: Dictionary = SD.clean_constructions_doc(cons_raw)
	if not read.has("doc"):
		push_error("stickers_cardboard_geometry: <constructions.json> does not clean: %s" % str(read.get("error", "")))
		quit(3)
		return
	var cons: Dictionary = read.doc
	var by_cons := {}
	var out_cons := {}
	var n_threads := 0
	var n_over := 0
	for c in cons.constructions:
		by_cons[str(c.id)] = c
		var rows: Array = []
		for e in SD.drawn_wall_threads(doc, c, boards, designs):
			rows.append(_row(SD, e.thread, e.a, e.b, e.p, e.q, e.over))
			n_over += 1 if not (e.over as Array).is_empty() else 0
		n_threads += rows.size()
		out_cons[str(c.id)] = {"lines": SD.wall_lines(c, boards), "threads": rows}
	var out_boards := {}
	var n_board := 0
	for id in board_ids:
		var rows: Array = []
		for e in SD.drawn_threads(doc, id):
			var p: Array = SD.pin_of(e.a, designs.get(str(e.a.get("design", ""))))
			var q: Array = SD.pin_of(e.b, designs.get(str(e.b.get("design", ""))))
			rows.append(_row(SD, e.thread, e.a, e.b, p, q, SD.over_board(p, q, boards[id])))
		if not rows.is_empty():
			out_boards[id] = rows
			n_board += rows.size()
	var oc: Dictionary = cases.get("over", {}) if cases.get("over") is Dictionary else {}
	var out_cases := {"walls": {}, "boards": {}, "pieces": {}}
	for e in oc.get("walls", []):
		var c: Dictionary = by_cons.get(str(e.get("construction", "")), {})
		var lines: Dictionary = SD.wall_lines(c, boards) if not c.is_empty() else {}
		var ws: Array = []
		if e.get("walls") is Array:
			for x in e.walls:
				if x is String:
					if lines.has(x):
						ws.append(lines[x])
				else:
					ws.append(x)
		else:
			ws = lines.values()
		var p: Variant = _point(SD, c, boards, e.get("p"))
		var q: Variant = _point(SD, c, boards, e.get("q"))
		if p == null or q == null:
			push_error("stickers_cardboard_geometry: case %s puts a point on a wall its construction does not have" % str(e.get("name", "")))
			quit(3)
			return
		out_cases.walls[str(e.name)] = SD.over_walls(p, q, ws)
	for e in oc.get("boards", []):
		var b: Variant = boards.get(e.board, {}) if e.get("board") is String else e.get("board")
		out_cases.boards[str(e.name)] = SD.over_board(e.p, e.q, b)
	for e in oc.get("pieces", []):
		out_cases.pieces[str(e.name)] = SD.thread_pieces(e.p, e.q, e.get("over", []))
	var k: Dictionary = SD.get_script_constant_map()
	var constants := {}
	for name in CONSTANTS:
		constants[name] = k.get(name)
	var out := {"constants": constants, "constructions": out_cons, "boards": out_boards, "cases": out_cases}
	var f := FileAccess.open(out_path, FileAccess.WRITE)
	f.store_string(JSON.stringify(out, "", false, true))
	f.close()
	print("stickers_cardboard_geometry over: %d constructions, %d threads between walls (%d over a wall), %d threads on one board; %d cases over walls, %d over a board, %d pieces" % [
		out_cons.size(), n_threads, n_over, n_board, out_cases.walls.size(), out_cases.boards.size(), out_cases.pieces.size()])
	quit(0)

## A thread as a medium draws it: its pins, the points it goes over the walls by, its pieces (thread_pieces), the tag
## piece, each piece's control point and middle (thread_curve, at u = 0.5), and the tag's point.
func _row(SD: Script, t: Dictionary, a: Dictionary, b: Dictionary, p: Array, q: Array, over: Array) -> Dictionary:
	var pc: Dictionary = SD.thread_pieces(p, q, over)
	var cs: Array = []
	var mids: Array = []
	for piece in pc.pieces:
		var cv: Dictionary = SD.thread_curve(piece[0], piece[1])
		cs.append(cv.c)
		mids.append(SD.curve_at(cv, 0.5))
	return {"id": str(t.get("id", "")), "a": str(a.get("id", "")), "b": str(b.get("id", "")), "p": p, "q": q, "over": over,
		"pieces": pc.pieces, "tag": pc.tag, "cs": cs, "mids": mids, "tag_at": mids[int(pc.tag)]}

## A case's point: [x, y, z] in the construction's frame, or {board, at} - a point of a wall's board frame, stood where
## that wall stands (wall_point). null when the construction has no such wall.
func _point(SD: Script, c: Dictionary, boards: Dictionary, v: Variant) -> Variant:
	if v is Array:
		return v
	if not v is Dictionary:
		return null
	for w in c.get("walls", []):
		if str(w.board) == str(v.get("board", "")):
			for t in c.get("tables", []):
				if str(t.id) == str(w.table) and boards.has(str(w.board)):
					return SD.wall_point(t, w, boards[str(w.board)], v.get("at"))
	return null
