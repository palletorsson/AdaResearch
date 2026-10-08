extends SceneTree
## probe_verify_addpos.gd — INDEPENDENT VERIFICATION (audit, 2026-08-27).
## Two questions probe_necklace_edits.gd does not ask:
##   1. does an add land WHERE it was asked to, next to the focus?
##   2. on the museum string, does a real KEY EVENT (X, comma, U, A) leave the
##      order and the hand file alone? The refusal was probed by CALL, not key.
const SCENE := "res://commons/scenes/desktop_necklace.tscn"
const TRIAL := "user://_verify_addpos_ops.json"
var _r: Array = []
var _f: int = 0

func _initialize() -> void: _run()

func _ok(n: String, p: bool, d: String = "") -> void:
	_r.append({"check": n, "pass": p, "detail": d})
	if not p: _f += 1

func _key(code: Key) -> void:
	var ev := InputEventKey.new()
	ev.keycode = code
	ev.physical_keycode = code
	ev.pressed = true
	Input.parse_input_event(ev)

func _run() -> void:
	var out := ProjectSettings.globalize_path("user://probe_verify_addpos.json")
	for a in OS.get_cmdline_user_args():
		if str(a).begins_with("--report="): out = str(a).split("=", true, 1)[1]
	for p in [TRIAL, TRIAL + ".bak", TRIAL + ".tmp"]:
		if FileAccess.file_exists(p): DirAccess.remove_absolute(p)

	var ps := load(SCENE) as PackedScene
	var n: Node = ps.instantiate()
	n.set("ops_path", TRIAL)
	root.add_child(n)
	for i in 20: await process_frame

	# ── SPINE: add AFTER a focus in the middle of a chapter
	n.call("scroll_to_index", 40)
	n.call("settle_scroll")
	for i in 4: await process_frame
	var focus: int = int(n.call("focus_index"))
	var before_at_focus := str(n.call("lookup_at", focus))
	var size0: int = int(n.call("order_size"))
	var tok := str(n.call("candidate_lookup_at", 0))
	var okadd: bool = bool(n.call("add_candidate", tok, "after"))
	_ok("spine add_candidate('%s','after') succeeded" % tok, okadd, str(n.call("notice")))
	_ok("order grew by one", int(n.call("order_size")) == size0 + 1,
		"%d -> %d" % [size0, int(n.call("order_size"))])
	var landed: int = int(n.call("index_of", tok))
	_ok("THE NEW BEAD LANDED IMMEDIATELY AFTER THE FOCUS", landed == focus + 1,
		"focus %d (%s), landed %d" % [focus, before_at_focus, landed])
	_ok("the bead before it is still the focus token",
		str(n.call("lookup_at", focus)) == before_at_focus,
		str(n.call("lookup_at", focus)))
	_ok("it is marked hand", str(n.call("origin_at", landed)) == "hand",
		str(n.call("origin_at", landed)))
	# and before
	var f2: int = int(n.call("focus_index"))
	var tok2 := str(n.call("candidate_lookup_at", 0))
	var s2: int = int(n.call("order_size"))
	var ok2: bool = bool(n.call("add_candidate", tok2, "before"))
	var l2: int = int(n.call("index_of", tok2))
	_ok("spine add 'before' succeeded", ok2, str(n.call("notice")))
	_ok("THE 'before' BEAD LANDED IMMEDIATELY BEFORE THE FOCUS", l2 == f2,
		"focus %d, landed %d, size %d -> %d" % [f2, l2, s2, int(n.call("order_size"))])
	# take both back
	n.call("undo_last"); n.call("undo_last")
	_ok("both undone, order restored", int(n.call("order_size")) == size0,
		"size %d" % int(n.call("order_size")))

	# ── MUSEUM: the KEYS, not the calls
	n.call("set_source", "museum")
	for i in 20: await process_frame
	var msize: int = int(n.call("order_size"))
	var ops_before := _ops_len()
	n.call("scroll_to_index", 25)
	n.call("settle_scroll")
	for i in 4: await process_frame
	var mfocus: int = int(n.call("focus_index"))
	for k in [KEY_X, KEY_DELETE, KEY_COMMA, KEY_PERIOD, KEY_U, KEY_A]:
		_key(k)
		for i in 3: await process_frame
	_ok("MUSEUM SIZE UNCHANGED AFTER X/DEL/,/./U/A KEYS",
		int(n.call("order_size")) == msize, "%d -> %d" % [msize, int(n.call("order_size"))])
	_ok("museum focus unchanged", int(n.call("focus_index")) == mfocus,
		"%d -> %d" % [mfocus, int(n.call("focus_index"))])
	_ok("NO HAND FILE WAS WRITTEN BY THE MUSEUM KEYS", _ops_len() == ops_before,
		"ops %d -> %d" % [ops_before, _ops_len()])
	_ok("the notice is a refusal sentence",
		str(n.call("notice")).begins_with("REFUSED"), str(n.call("notice")))
	_ok("bead count is still 10 on the museum", int(n.call("bead_count")) == 10,
		str(n.call("bead_count")))

	# ── museum ends
	n.call("scroll_to_index", 0); n.call("settle_scroll")
	for i in 4: await process_frame
	_ok("head: 10 beads, window_first 0", int(n.call("bead_count")) == 10
		and int(n.call("window_first")) == 0,
		"beads %d first %d at %s" % [int(n.call("bead_count")),
			int(n.call("window_first")), str(n.call("identity_at", 0))])
	n.call("scroll_to_index", msize - 1); n.call("settle_scroll")
	for i in 4: await process_frame
	_ok("tail: 10 beads, last identity is an orphan",
		int(n.call("bead_count")) == 10
		and str(n.call("identity_at", msize - 1)).begins_with("orphan@"),
		"beads %d last %s" % [int(n.call("bead_count")),
			str(n.call("identity_at", msize - 1))])
	# the last built placement, 1582
	n.call("scroll_to_index", 1578); n.call("settle_scroll")
	for i in 4: await process_frame
	_ok("the seam from placements into the orphan band holds 10 beads",
		int(n.call("bead_count")) == 10, str(n.call("bead_count")))

	var f := FileAccess.open(out, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({"failed": _f, "pass": _f == 0, "checks": _r}, "  ", false))
		f.close()
	quit(0)

func _ops_len() -> int:
	if not FileAccess.file_exists(TRIAL): return 0
	var t := FileAccess.get_file_as_string(TRIAL)
	var d = JSON.parse_string(t)
	if typeof(d) != TYPE_DICTIONARY: return -1
	var o = (d as Dictionary).get("ops", [])
	return (o as Array).size() if typeof(o) == TYPE_ARRAY else -1
