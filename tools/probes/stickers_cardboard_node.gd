extends SceneTree
## THE CARDBOARD CONSTRUCTIONS IN THE NODE: what StickerData (commons/stickers/sticker_data.gd) does with them as a running
## node, where the parity (tools/probes/stickers_cardboard_parity.py) checks only its pure functions. On a COPY of the
## truth in <dir> (posting off, its outbox beside the copy), headless:
##   C1 constructions.json is read as the server reads it: the construction, its tables and walls, which board stands in
##      which (construction_of, wall_of), the revision
##   C2 board_sided: every wall has a back, no paper board does
##   C3 wall_threads(construction) is drawn_wall_threads over the view, and strokes_on(board, face) is drawn_strokes over
##      it, for every board and face
##   C4 stick() on a wall's back: stored on the back face (n = -Z, at.z = -CARDBOARD), pending in the outbox
##   C5 tie() between two walls of the construction draws a thread between walls at once; tie() to a paper board is
##      refused in the server's words
##   C6 scribble(): cleaned as cleanOp cleans it (a Vector2 point, a colour in capitals, a width past the pen), clamped
##      to the board by applyOps; on paper's back, with one point, with an unknown pen: refused in the server's words
##   C7 erase() keeps the stroke with who erased it and hides it; a second erase is skipped and posts nothing;
##      unerase() shows it again
##   C8 the watch: a changed constructions.json is read within 4 s (constructions_changed), and the tie whose wall
##      left the construction is no longer drawn
##   C9 the headset copy rule: a copy of constructions.json with a higher revision is read, one with a lower is not
##   C10 a constructions.json that does not clean keeps what was held and says why (constructions_error)
##   C11 a POST stays under the route's 512 KiB: 30 pending scribbles of 2000 points go in batches under MAX_BODY (the
##      30 in one body would be refused whole with 413); posted only to a port nothing listens on, with a sandbox
##   C12 the truth's files and the copy's documents are untouched (the node writes only its outbox)
##   C13 a thread never passes through cardboard: wall_threads carries `over`, over_walls of its pins over the
##      construction's wall_lines (read from the node's own board records); and over the truth's research walls - every
##      sticker on them that is on and its mirror on the other face, every pair tied - no piece of any thread between two
##      walls (thread_pieces) lies inside any wall's cardboard, nor any piece of a thread on one wall (over_board) inside
##      that wall's, sampled every 0.4 mm as cardboard.test.ts samples the U; while the plain curve between the same pins
##      does for many (the negative: without the rule they would pass through)
##   godot --headless --path . --xr-mode off --script res://tools/probes/stickers_cardboard_node.gd -- --dir=<scratch folder>
## Writes <dir>/node_result.json. Exit 0 when every check passes.

const StickerData := preload("res://commons/stickers/sticker_data.gd")
const REAL := "res://commons/data/stickers"
const DOCS := ["designs", "boards", "placements", "constructions"]

var dir := ""
var checks: Array = []

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--dir="):
			dir = a.substr(6).replace("\\", "/").trim_suffix("/")
	if dir == "":
		push_error("stickers_cardboard_node: give --dir=<a scratch folder>")
		quit(2)
		return
	_run.call_deferred()

func _check(name: String, ok: bool, detail: Variant) -> void:
	checks.append({"name": name, "ok": ok, "detail": detail})
	print("%s %s  %s" % ["PASS" if ok else "FAIL", name, JSON.stringify(detail).left(400)])

func _put(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()

func _md5s(folder: String) -> Dictionary:
	var out := {}
	for d in DOCS:
		var p := folder.path_join(d + ".json")
		out[d] = FileAccess.get_md5(p) if FileAccess.file_exists(p) else ""
	return out

func _ids(list: Array) -> Array:
	return list.map(func(s): return str(s.get("id", "")))

## A construction's walls as the sampler reads them: [{t, w, b}], each board as the server reads it.
func _slabs(c: Dictionary, data: Node) -> Array:
	var out: Array = []
	for w in c.get("walls", []):
		var b: Dictionary = data.board_spec(str(w.board))
		for t in c.get("tables", []):
			if str(t.id) == str(w.table) and b.has("w") and b.has("h"):
				out.append({"t": t, "w": w, "b": b})
	return out

## A point of the construction's frame in a wall's board frame (wall_point's inverse, as cardboard.test.ts inWall).
func _in_wall(sl: Dictionary, v: Array) -> Array:
	var t: Dictionary = sl.t
	var w: Dictionary = sl.w
	var txz: Array = StickerData.rot_y(-float(t.yaw), float(v[0]) - float(t.at[0]), float(v[2]) - float(t.at[1]))
	var xz: Array = StickerData.rot_y(-float(w.yaw), float(txz[0]) - float(w.at[0]), float(txz[1]) - float(w.at[1]))
	return [float(xz[0]), float(v[1]) - float(t.h) - float(sl.b.h) / 2.0, float(xz[1])]

## Whether any sample of thread_curve(p, q) - u = i / n, n = max(64, |q - p| / 0.4 mm), as cardboard.test.ts samples
## it - lies strictly inside a wall's cardboard (w x h x CARDBOARD behind its front face, 1e-7 in). The curve's plan line
## is linear in u (its control point is over the middle of the pins), so only the u where it comes within 1 cm of a wall
## are sampled; the rest cannot be inside it.
func _through(slabs: Array, p: Array, q: Array) -> bool:
	var cv: Dictionary = StickerData.thread_curve(p, q)
	var n := maxi(64, ceili(StickerData.hypot3(float(q[0]) - float(p[0]), float(q[1]) - float(p[1]), float(q[2]) - float(p[2])) / 0.0004))
	var e := 1e-7
	for sl in slabs:
		var a := _in_wall(sl, p)
		var b := _in_wall(sl, q)
		var hw := float(sl.b.w) / 2.0
		var hh := float(sl.b.h) / 2.0
		var lo := 0.0
		var hi := 1.0
		for ax in [[a[0], b[0], -hw - 0.01, hw + 0.01], [a[2], b[2], -StickerData.CARDBOARD - 0.01, 0.01]]:
			var v0: float = ax[0]
			var d: float = float(ax[1]) - v0
			if absf(d) < 1e-12:
				if v0 <= float(ax[2]) or v0 >= float(ax[3]):
					hi = -1.0
				continue
			var ta := (float(ax[2]) - v0) / d
			var tb := (float(ax[3]) - v0) / d
			lo = maxf(lo, minf(ta, tb))
			hi = minf(hi, maxf(ta, tb))
		if hi < lo:
			continue
		for i in range(maxi(0, floori(lo * n) - 1), mini(n, ceili(hi * n) + 1) + 1):
			var v := _in_wall(sl, StickerData.curve_at(cv, float(i) / float(n)))
			if absf(v[0]) < hw - e and absf(v[1]) < hh - e and v[2] < -e and v[2] > -StickerData.CARDBOARD + e:
				return true
	return false

func _run() -> void:
	var copy := dir.path_join("copy")
	DirAccess.make_dir_recursive_absolute(copy.path_join("headset"))
	for f in ["outbox.json", "outbox.json.tmp", "headset/constructions.json"]:
		if FileAccess.file_exists(copy.path_join(f)):
			DirAccess.remove_absolute(copy.path_join(f))
	for d in DOCS:
		_put(copy.path_join(d + ".json"), FileAccess.get_file_as_string(REAL.path_join(d + ".json")))
	var real_before := _md5s(REAL)
	var data: Node = StickerData.new()
	data.name = "StickerData"
	data.configure({"data_dir": copy, "outbox": copy.path_join("outbox.json"), "post": false, "copy_dir": copy.path_join("headset"), "by": "vr:probe"})
	root.add_child(data)
	await process_frame
	var copy_placements := FileAccess.get_md5(copy.path_join("placements.json"))

	# C1 - constructions.json as the server reads it
	var c: Dictionary = data.construction("research")
	var walls: Array = c.get("walls", [])
	var stands := walls.filter(func(w): return data.construction_of(str(w.board)) == "research").size()
	var edges: Dictionary = data.wall_of("cb_edges")
	_check("C1 constructions.json read: the construction, its tables and walls, which board stands where, the revision",
		c.get("tables", []).size() == 4 and walls.size() == 8 and stands == 8 and data.construction_of("visitors") == "" and int(data.revisions.constructions) >= 1
		and str(edges.get("table", {}).get("id", "")) == "sign" and float(edges.get("wall", {}).get("yaw", -1.0)) == 180.0 and data.constructions_error == "",
		{"tables": c.get("tables", []).size(), "walls": walls.size(), "standing": stands, "revision": data.revisions.constructions, "cb_edges": [edges.get("table", {}).get("id"), edges.get("wall", {}).get("yaw")]})

	# C2 - which boards have a back
	var sided := 0
	var paper_sided := 0
	for id in data.boards:
		var spec: Dictionary = data.board_spec(id)
		if data.board_sided(id):
			sided += 1
		if data.board_sided(id) and str(spec.get("stock", "")) != "cardboard":
			paper_sided += 1
	_check("C2 board_sided: every wall has a back, no paper board does", sided == 8 and paper_sided == 0 and not data.board_sided("visitors") and data.board_sided("cb_hand"),
		{"sided": sided, "boards": data.boards.size()})

	# C3 - the media's queries are the contract's functions over the view
	var view := {"stickers": data.stickers, "threads": data.threads, "strokes": data.strokes}
	var drawn: Array = data.wall_threads("research")
	var want: Array = StickerData.drawn_wall_threads(view, c, data.boards, data.designs)
	var mismatched := 0
	var faces := {"front": 0, "back": 0}
	for id in data.boards:
		for face in ["", "front", "back"]:
			if _ids(data.strokes_on(id, face)) != _ids(StickerData.drawn_strokes(view, id, face)):
				mismatched += 1
			if face != "":
				faces[face] += data.strokes_on(id, face).size()
	var t0 := Time.get_ticks_usec()
	for id in data.boards:
		data.strokes_on(id, "back")
	var strokes_us := Time.get_ticks_usec() - t0
	_check("C3 wall_threads is drawn_wall_threads and strokes_on is drawn_strokes over the view, every board and face",
		drawn.size() == want.size() and drawn.size() > 0 and _ids(drawn.map(func(e): return e.thread)) == _ids(want.map(func(e): return e.thread)) and mismatched == 0,
		{"threads_between_walls": drawn.size(), "strokes_front": faces.front, "strokes_back": faces.back, "mismatched_lists": mismatched, "strokes_on_all_boards_us": strokes_us})

	# C4 - a sticker stuck on a wall's back
	var pending0: int = data.pending.size()
	var back: Dictionary = data.stick("punctum_nails", {"kind": "board", "id": "cb_hand"}, [0.1, 0.1, -0.2], Vector3(0, 0.1, -1), [0.0, 1.0, 0.0], 0.12)
	_check("C4 stick() on a wall's back: stored on the back face, pending",
		not back.is_empty() and back.get("n") == [0.0, 0.0, -1.0] and float(back.at[2]) == -StickerData.CARDBOARD and data.pending.size() == pending0 + 1,
		{"n": back.get("n"), "at": back.get("at"), "up": back.get("up"), "pending": data.pending.size()})

	# C5 - ties between walls, and to paper
	var walls_before: int = data.wall_threads("research").size()
	var th: Dictionary = data.tie(str(back.get("id", "")), "cb-compass", "behind", "across the table")
	var after_tie: int = data.wall_threads("research").size()
	var refused: Dictionary = data.tie("cb-nails", "seed-board-triangle", "paper")
	var words: String = data.last_error
	_check("C5 tie() between two walls draws at once; tie() to a paper board is refused in the server's words",
		not th.is_empty() and after_tie == walls_before + 1 and refused.is_empty() and words.ends_with("a thread ties two stickers on one board, or on two walls of one construction"),
		{"thread": th.get("id"), "between_walls": [walls_before, after_tie], "refusal": words})

	# C13 - a thread never passes through cardboard: in the node's view, and over the research walls with every pair tied
	var t13 := Time.get_ticks_msec()
	var rc: Dictionary = data.construction("research")
	var lines: Dictionary = StickerData.wall_lines(rc, data.boards)
	var view_threads: Array = data.wall_threads("research")
	var unlike := view_threads.filter(func(e): return e.get("over") != StickerData.over_walls(e.p, e.q, lines)).size()
	var on_walls := {}
	for w in rc.get("walls", []):
		on_walls[str(w.board)] = true
	var pinned: Array = []
	for s in data.stickers:
		var h: Variant = s.get("host")
		if h is Dictionary and str(h.get("kind", "")) == "board" and on_walls.has(str(h.get("id", ""))) and str(s.get("state", "")) == "on":
			var m: Dictionary = s.duplicate(true)
			var on_back := float(s.n[2]) < 0.0
			m["id"] = str(s.id) + "-mirror"
			m["n"] = [0.0, 0.0, 1.0] if on_back else [0.0, 0.0, -1.0]
			m["at"] = [float(s.at[0]), float(s.at[1]), 0.0 if on_back else -StickerData.CARDBOARD]
			pinned.append_array([s, m])
	var ties: Array = []
	for i in pinned.size():
		for j in range(i + 1, pinned.size()):
			ties.append({"id": "c13-%d-%d" % [i, j], "a": pinned[i].id, "b": pinned[j].id, "word": "w", "state": "tied"})
	var slabs := _slabs(rc, data)
	var drawn13: Array = StickerData.drawn_wall_threads({"stickers": pinned, "threads": ties}, rc, data.boards, data.designs)
	var through := 0
	var crossing := 0
	var plain := 0
	var odd_count := 0
	for e in drawn13:
		var over: Array = e.over
		odd_count += over.size() % 2
		crossing += 1 if not over.is_empty() else 0
		plain += 1 if _through(slabs, e.p, e.q) else 0
		for piece in StickerData.thread_pieces(e.p, e.q, over).pieces:
			if _through(slabs, piece[0], piece[1]):
				through += 1
				break
	# on one wall: front to back over its top edge, in the board's own frame
	var board_over := 0
	var board_through := 0
	var board_plain := 0
	for bid in on_walls:
		var b: Dictionary = data.board_spec(bid)
		var own := [{"t": {"at": [0.0, 0.0], "yaw": 0.0, "h": -float(b.h) / 2.0}, "w": {"at": [0.0, 0.0], "yaw": 0.0}, "b": b}]
		var mine := pinned.filter(func(s): return str(s.host.id) == bid)
		for i in mine.size():
			for j in range(i + 1, mine.size()):
				var p: Array = StickerData.pin_of(mine[i], data.designs.get(str(mine[i].design)))
				var q: Array = StickerData.pin_of(mine[j], data.designs.get(str(mine[j].design)))
				var over: Array = StickerData.over_board(p, q, b)
				board_over += 1 if not over.is_empty() else 0
				board_plain += 1 if _through(own, p, q) else 0
				for piece in StickerData.thread_pieces(p, q, over).pieces:
					if _through(own, piece[0], piece[1]):
						board_through += 1
						break
	_check("C13 a thread never passes through cardboard: wall_threads carries over_walls over wall_lines; no piece of any thread on the research walls lies in cardboard",
		view_threads.size() > 0 and unlike == 0 and drawn13.size() > 0 and through == 0 and odd_count == 0 and crossing > 40 and plain > 40 and plain <= crossing
		and board_over > 0 and board_through == 0 and board_plain >= board_over,
		{"view_threads": view_threads.size(), "view_over_unlike": unlike, "stickers_and_mirrors": pinned.size(), "threads_between_walls": drawn13.size(),
		"over_a_wall": crossing, "pieces_through_cardboard": through, "plain_curves_through": plain, "odd_point_counts": odd_count,
		"one_wall_over_its_top": board_over, "one_wall_pieces_through": board_through, "one_wall_plain_through": board_plain, "ms": Time.get_ticks_msec() - t13})

	# C6 - scribbles
	var st: Dictionary = data.scribble("cb_hand", "front", "marker", [[0.0, 0.0], Vector2(0.5, 0.4), [0.123456, -0.2]], "#B3121B", 0.5)
	var last_front: Array = _ids(data.strokes_on("cb_hand", "front"))
	var bad_paper: Dictionary = data.scribble("visitors", "back", "marker", [[0.0, 0.0], [0.1, 0.1]])
	var e_paper: String = data.last_error
	var bad_one: Dictionary = data.scribble("cb_hand", "back", "fine", [[0.0, 0.0]])
	var e_one: String = data.last_error
	var bad_pen: Dictionary = data.scribble("cb_hand", "back", "crayon", [[0.0, 0.0], [0.1, 0.1]])
	var e_pen: String = data.last_error
	var back_st: Dictionary = data.scribble("cb_hand", "back", "fine", [[0.2, 0.1], [-0.2, -0.1]])
	_check("C6 scribble(): cleaned as cleanOp cleans it and clamped as applyOps clamps it; refused in the server's words",
		st.get("points") == [[0.0, 0.0], [0.4, 0.3], [0.1235, -0.2]] and str(st.get("colour", "")) == "#b3121b" and float(st.get("width", 0.0)) == 0.02
		and str(st.get("by", "")) == "vr:probe" and last_front.back() == str(st.get("id", "")) and bad_paper.is_empty() and e_paper.ends_with("has no back (it is not cardboard)")
		and bad_one.is_empty() and e_one.ends_with("2 to 2000 points") and bad_pen.is_empty() and e_pen.ends_with("pen must be fine, marker, chisel, spray")
		and str(back_st.get("face", "")) == "back",
		{"points": st.get("points"), "colour": st.get("colour"), "width": st.get("width"), "refusals": [e_paper, e_one, e_pen]})

	# C7 - erase and unerase
	var sid := str(st.get("id", ""))
	var n_pending: int = data.pending.size()
	var e1: bool = data.erase(sid)
	var hidden := not _ids(data.strokes_on("cb_hand", "front")).has(sid)
	var erased_by := str(data.stroke(sid).get("erased", {}).get("by", ""))
	var e2: bool = data.erase(sid)
	var posted_skip: int = data.pending.size() - (n_pending + 1)
	var u1: bool = data.unerase(sid)
	var shown := _ids(data.strokes_on("cb_hand", "front")).has(sid)
	_check("C7 erase() hides and keeps who erased; a second erase is skipped (nothing posted); unerase() shows it again",
		e1 and hidden and erased_by == "vr:probe" and e2 and posted_skip == 0 and u1 and shown and not data.stroke(sid).has("erased"),
		{"erased_by": erased_by, "second_erase_ops_added": posted_skip})

	# C8 - the watch
	var heard := [0]
	data.constructions_changed.connect(func(): heard[0] += 1)
	var tie_id := str(th.get("id", ""))
	var doc: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(copy.path_join("constructions.json")))
	doc.revision = int(doc.revision) + 1
	var research: Dictionary = doc.constructions[0]
	research.walls = (research.walls as Array).filter(func(w): return str(w.board) != "cb_gap")
	await create_timer(1.1).timeout   # mtime is in whole seconds: a write in the second the copy was made could be missed
	_put(copy.path_join("constructions.json"), JSON.stringify(doc))
	var t_write := Time.get_ticks_msec()
	var seen_ms := -1
	while Time.get_ticks_msec() - t_write < 4000:
		await process_frame
		if data.construction_of("cb_gap") == "":
			seen_ms = Time.get_ticks_msec() - t_write
			break
	var tie_gone: bool = data.thread(tie_id).is_empty() and not data.wall_threads("research").any(func(e): return str(e.thread.id) == tie_id)
	_check("C8 a changed constructions.json is read within 4 s; the tie whose wall left the construction is not drawn",
		seen_ms >= 0 and heard[0] >= 1 and tie_gone and data.pending.any(func(e): return str(e.op.get("op", "")) == "tie"),
		{"read_after_ms": seen_ms, "constructions_changed": heard[0], "tie_drawn": not tie_gone, "walls_now": data.construction("research").get("walls", []).size()})

	# C9 - the headset copy: a higher revision is read, a lower one is not
	var newer := doc.duplicate(true)
	newer.revision = int(doc.revision) + 5
	newer.constructions[0].title = "The research, on the headset"
	_put(copy.path_join("headset/constructions.json"), JSON.stringify(newer))
	data.reload()
	var title_newer := str(data.construction("research").get("title", ""))
	var older := doc.duplicate(true)
	older.revision = 0
	older.constructions[0].title = "an older copy"
	_put(copy.path_join("headset/constructions.json"), JSON.stringify(older))
	data.reload()
	var title_older := str(data.construction("research").get("title", ""))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(copy.path_join("headset/constructions.json")))
	data.reload()
	_check("C9 the headset's copy of constructions.json is read when its revision is higher, not when it is lower",
		title_newer == "The research, on the headset" and title_older == "The research, in cardboard",
		{"newer": title_newer, "older": title_older})

	# C10 - a constructions.json that does not clean
	var broken := doc.duplicate(true)
	broken.revision = int(doc.revision) + 9
	broken.constructions[0].walls[0].table = "nowhere"
	var held: int = data.construction("research").get("walls", []).size()
	_put(copy.path_join("constructions.json"), JSON.stringify(broken))
	data.reload()
	_check("C10 a constructions.json that does not clean keeps what was held and says why",
		data.construction("research").get("walls", []).size() == held and data.constructions_error.ends_with("stands on no table of it"),
		{"walls_held": held, "error": data.constructions_error})
	_put(copy.path_join("constructions.json"), JSON.stringify(doc))
	data.reload()

	# C11 - a POST under the route's 512 KiB
	var pts: Array = []
	for i in StickerData.STROKE_POINTS:
		pts.append([-0.3999 + 0.0004 * float(i % 2000), 0.2999 * sin(float(i) * 0.37)])
	for i in 30:
		data.scribble("cb_counted", "back", "spray", pts, "#eb0d85")
	var all_ops: Array = data.pending.map(func(e): return e.op)
	var whole := JSON.stringify({"by": "vr:probe", "ops": all_ops}).length()
	data.post_enabled = true
	data.sandbox = "probe-cap"
	data.post_url = "http://127.0.0.1:9"   # nothing listens there: the batch is made and the POST fails, kept in the outbox
	var started: bool = data.flush()
	var batch: Array = data.pending.filter(func(e): return data._batch_ids.has(str(e.op.op_id)))
	var body := JSON.stringify({"by": "vr:probe", "ops": batch.map(func(e): return e.op)}).length()
	data.post_enabled = false
	_check("C11 a POST stays under the route's 512 KiB: the pending scribbles go in batches under MAX_BODY",
		started and batch.size() > 0 and batch.size() < data.pending.size() and body <= StickerData.MAX_BODY + 64 and whole > 512 * 1024,
		{"pending": data.pending.size(), "batched": batch.size(), "body_chars": body, "all_in_one_chars": whole, "route_limit": 512 * 1024})
	for i in 60:
		await process_frame   # let the refused connection come back before the node goes

	# C12 - nothing but the outbox written
	var real_after := _md5s(REAL)
	_check("C12 the truth's files are untouched, and the copy's placements too (the node writes only its outbox)",
		real_after == real_before and FileAccess.get_md5(copy.path_join("placements.json")) == copy_placements and FileAccess.file_exists(copy.path_join("outbox.json")),
		{"truth": real_after == real_before, "copy_placements": FileAccess.get_md5(copy.path_join("placements.json")) == copy_placements})

	# the view's cost with the truth's 700 scribbles
	var t1 := Time.get_ticks_usec()
	data._recompute()
	var recompute_us := Time.get_ticks_usec() - t1
	var failed := checks.filter(func(x): return not x.ok).size()
	_put(dir.path_join("node_result.json"), JSON.stringify({"checks": checks, "failed": failed, "recompute_us": recompute_us,
		"strokes": data.strokes.size(), "pending": data.pending.size()}, "  "))
	print("stickers_cardboard_node: %d checks, %d failed; a recompute of the view with %d strokes and %d pending ops: %.2f ms" % [checks.size(), failed, data.strokes.size(), data.pending.size(), recompute_us / 1000.0])
	data.queue_free()
	await process_frame
	quit(0 if failed == 0 else 1)
