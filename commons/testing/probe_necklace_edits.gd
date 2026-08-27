extends SceneTree
## probe_necklace_edits.gd — CAN THE TOOL TAKE AN EDIT BACK, AND DOES IT REFUSE
## TO WRITE OVER A HAND FILE IT CANNOT READ?
##
## The floor and frame defects were geometric, so a probe and a PNG could both
## see them. These two cannot be photographed:
##
##   · _candidates was only ever REMOVED from, so a dropped bead vanished from
##     the add list and the one thing you could not do after a drop was put back
##     what you had just dropped. And drop_bead refused a hand-added bead
##     outright. Both verbs sent you to the CLI.
##   · _read_json_dict returned {} for absent AND for unparseable, so the scene
##     said "no hand file yet … untouched" over a file that exists and will not
##     parse — and the next keystroke wrote a FRESH document over it.
##
## Everything here drives the scene's own public verbs (the keys call the same
## functions) and then reads the FILE back, because "the file agrees with the
## screen" is the whole claim.
##
##   godot --path . --xr-mode off --headless \
##     --script res://commons/testing/probe_necklace_edits.gd -- --report=<file>

const SCENE := "res://commons/scenes/desktop_necklace.tscn"
const TRIAL_OPS := "user://_probe_edits_necklace_ops.json"

var _checks: Array = []
var _failed: int = 0


func _initialize() -> void:
	_run()


func _ok(name: String, pass_: bool, detail: String = "") -> void:
	_checks.append({"check": name, "pass": pass_, "detail": detail})
	if not pass_:
		_failed += 1


func _run() -> void:
	var report := ProjectSettings.globalize_path("user://probe_necklace_edits.json")
	for a in OS.get_cmdline_user_args():
		if str(a).begins_with("--report="):
			report = str(a).split("=", true, 1)[1]

	# a clean bench: no hand file, no leftovers from a previous run
	for p in [TRIAL_OPS, TRIAL_OPS + ".bak", TRIAL_OPS + ".tmp"]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)

	var n: Node = await _fresh()

	_ok("opens with no hand file and is not 'broken'", not bool(n.call("ops_broken")),
		str(n.call("ops_broken_why")))
	_ok("no fatal", str(n.call("fatal_message")) == "", str(n.call("fatal_message")))

	# ── 1. DROP, then put it back from the add list ──────────────────────────
	var size0: int = int(n.call("order_size"))
	var pool0: int = int(n.call("candidate_count"))
	# a spine bead near the head; the focus rides at index 0 on open
	var victim_i: int = -1
	for i in range(0, 12):
		if str(n.call("origin_at", i)) == "spine":
			victim_i = i
			break
	var victim: String = str(n.call("lookup_at", victim_i))

	var dropped: bool = bool(n.call("drop_bead", victim_i))
	_ok("drop_bead succeeded", dropped, victim)
	_ok("the order lost exactly one bead", int(n.call("order_size")) == size0 - 1,
		"%d -> %d" % [size0, int(n.call("order_size"))])
	_ok("THE DROPPED TOKEN IS BACK IN THE ADD LIST",
		int(n.call("candidate_count")) == pool0 + 1 and _in_pool(n, victim),
		"pool %d -> %d, %s present: %s" % [pool0, int(n.call("candidate_count")),
			victim, str(_in_pool(n, victim))])
	_ok("one op on disk", _ops_count() == 1, "ops=%d" % _ops_count())
	_ok("the op is a remove of that token", _op_at(0).get("op") == "remove"
		and str(_op_at(0).get("lookup", "")) == victim, JSON.stringify(_op_at(0)))

	# ── 2. UNDO takes it back, and the FILE agrees ───────────────────────────
	_ok("one edit is undoable", int(n.call("undo_depth")) == 1)
	var undone: bool = bool(n.call("undo_last"))
	_ok("undo_last succeeded", undone, str(n.call("live_note")))
	_ok("the bead is back on the string", int(n.call("order_size")) == size0
		and str(n.call("lookup_at", victim_i)) == victim,
		"size %d, at %d: %s" % [int(n.call("order_size")), victim_i,
			str(n.call("lookup_at", victim_i))])
	_ok("the pool is back where it was", int(n.call("candidate_count")) == pool0
		and not _in_pool(n, victim), "pool=%d" % int(n.call("candidate_count")))
	_ok("THE TRAILING OP WAS POPPED FROM THE FILE", _ops_count() == 0,
		"ops=%d" % _ops_count())
	_ok("nothing left to undo", int(n.call("undo_depth")) == 0)
	_ok("the previous file was kept as .bak", FileAccess.file_exists(TRIAL_OPS + ".bak"))
	_ok("no .tmp was left behind", not FileAccess.file_exists(TRIAL_OPS + ".tmp"))

	# ── 3. ADD, then X on the bead you just placed ───────────────────────────
	var cand: String = str(n.call("candidate_lookup_at", 0))
	var added: bool = bool(n.call("add_candidate", cand, "after"))
	_ok("add_candidate succeeded", added, cand)
	_ok("the order gained one", int(n.call("order_size")) == size0 + 1)
	_ok("the token left the add list", not _in_pool(n, cand))
	_ok("one op on disk again", _ops_count() == 1, "ops=%d" % _ops_count())
	var hand_i: int = int(n.call("index_of", cand))
	_ok("the new bead is marked hand", str(n.call("origin_at", hand_i)) == "hand")
	# X on a hand bead used to REFUSE and cite the CLI. It is the trailing op,
	# so it is undoable, so it must simply come off.
	var x_hand: bool = bool(n.call("drop_bead", hand_i))
	_ok("X ON A HAND-ADDED BEAD IS NO LONGER REFUSED", x_hand)
	_ok("the order is back to its size", int(n.call("order_size")) == size0)
	_ok("the token is back in the add list", _in_pool(n, cand))
	_ok("and the file is empty of ops again", _ops_count() == 0, "ops=%d" % _ops_count())

	# ── 4. A CORRUPT HAND FILE ───────────────────────────────────────────────
	# Truncated JSON: the shape a killed writer leaves behind.
	var corrupt := "{\"schema\": \"spine_order_ops/1\", \"ops\": [{\"op\": \"remo"
	var cf := FileAccess.open(TRIAL_OPS, FileAccess.WRITE)
	cf.store_string(corrupt)
	cf.close()
	n.queue_free()
	await process_frame
	var m: Node = await _fresh()

	_ok("A CORRUPT HAND FILE IS SEEN AS CORRUPT", bool(m.call("ops_broken")),
		str(m.call("ops_broken_why")))
	var before := FileAccess.get_file_as_string(TRIAL_OPS)
	var v0: int = int(m.call("order_size"))
	var refused_drop: bool = not bool(m.call("drop_bead", 3))
	var refused_add: bool = not bool(m.call("add_candidate",
		str(m.call("candidate_lookup_at", 0)), "after"))
	var refused_move: bool = not bool(m.call("move_focus", 1))
	_ok("drop is REFUSED", refused_drop)
	_ok("add is REFUSED", refused_add)
	_ok("move is REFUSED", refused_move)
	_ok("the order on screen did not move", int(m.call("order_size")) == v0)
	_ok("THE CORRUPT FILE WAS NOT OVERWRITTEN",
		FileAccess.get_file_as_string(TRIAL_OPS) == before,
		"%d bytes" % FileAccess.get_file_as_string(TRIAL_OPS).length())

	# a file that parses but is not an object — the other half of "unreadable"
	var af := FileAccess.open(TRIAL_OPS, FileAccess.WRITE)
	af.store_string("[1, 2, 3]\n")
	af.close()
	m.queue_free()
	await process_frame
	var k: Node = await _fresh()
	_ok("a JSON ARRAY is also refused, not treated as absent", bool(k.call("ops_broken")),
		str(k.call("ops_broken_why")))
	_ok("its edits are refused too", not bool(k.call("drop_bead", 3)))

	var doc := {
		"failed": _failed,
		"pass": _failed == 0,
		"checks": _checks,
	}
	var f := FileAccess.open(report, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(doc, "  ", false))
		f.close()
	quit(1 if _failed > 0 else 0)


func _fresh() -> Node:
	var ps := load(SCENE) as PackedScene
	var n: Node = ps.instantiate()
	n.set("ops_path", TRIAL_OPS)
	root.add_child(n)
	await process_frame
	await process_frame
	return n


func _in_pool(n: Node, lookup: String) -> bool:
	for i in int(n.call("candidate_count")):
		if str(n.call("candidate_lookup_at", i)) == lookup:
			return true
	return false


func _ops_doc() -> Dictionary:
	if not FileAccess.file_exists(TRIAL_OPS):
		return {}
	var t := FileAccess.get_file_as_string(TRIAL_OPS)
	var p: Variant = JSON.parse_string(t)
	return (p as Dictionary) if p is Dictionary else {}


func _ops_count() -> int:
	var d := _ops_doc()
	var raw: Variant = d.get("ops", [])
	return (raw as Array).size() if raw is Array else -1


func _op_at(i: int) -> Dictionary:
	var d := _ops_doc()
	var raw: Variant = d.get("ops", [])
	if not (raw is Array):
		return {}
	var a: Array = raw
	if i < 0 or i >= a.size():
		return {}
	return (a[i] as Dictionary) if a[i] is Dictionary else {}
