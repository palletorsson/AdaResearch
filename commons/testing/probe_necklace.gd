extends SceneTree
## probe_necklace.gd — does the necklace scroll ten beads, add, drop, and write
## the hand layer the way the contract says?
##
## WHY A PROBE AND NOT A LOOK. The 4.6 exe on this machine is NON-CONSOLE: a
## headless run writes no stdout at all, so a print diagnoses nothing. Every
## finding here goes into a JSON report and is read back off disk.
##
## WHY A TRIAL OPS PATH. Palle plays the desktop museum while probes run
## (feedback_probe_isolation_live_session.md), and commons/data/spine_order_ops.json
## is the LIVE hand. The scene takes an injected path so this probe can exercise
## the real write path against a throwaway file, and then PROVE the live files
## were not touched by comparing their md5 before and after.
##
## Run:
##   python tools/godot_watchdog.py --expect=<report> -- \
##     "C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe" --headless --path . \
##     --xr-mode off --script res://commons/testing/probe_necklace.gd \
##     -- --report=<report>

const SCENE := "res://commons/scenes/desktop_necklace.tscn"
const GENERATED := "res://commons/data/spine_artifact_order.json"
const LIVE_OPS := "res://commons/data/spine_order_ops.json"
const EFFECTIVE := "res://commons/data/spine_order_effective.json"
const TRIAL_OPS := "user://_probe_necklace_ops.json"

var _checks: Array = []
var _notes: Array = []


func _initialize() -> void:
	_run()


func _fail_out(report: String, why: String) -> void:
	_check("probe ran", false, why)
	_write(report, false)
	quit(1)


func _run() -> void:
	var report: String = ProjectSettings.globalize_path("user://probe_necklace.json")
	for a in OS.get_cmdline_user_args():
		if str(a).begins_with("--report="):
			report = str(a).split("=", true, 1)[1]

	# baselines: the two files this scene must never write
	var gen_before := _md5(GENERATED)
	var live_ops_before := _md5(LIVE_OPS)
	var eff_before := _md5(EFFECTIVE)
	if FileAccess.file_exists(TRIAL_OPS):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TRIAL_OPS))
	_notes.append("trial ops: %s" % ProjectSettings.globalize_path(TRIAL_OPS))

	if not ResourceLoader.exists(SCENE):
		_fail_out(report, "%s does not exist" % SCENE)
		return
	var ps := load(SCENE) as PackedScene
	if ps == null:
		_fail_out(report, "%s did not load as a PackedScene" % SCENE)
		return
	var inst: Node = ps.instantiate()
	if not (inst is Node3D):
		_fail_out(report, "the scene root is not a Node3D")
		return
	# Set BEFORE add_child so _ready() resolves the injected path. A value
	# assigned after the node is in the tree is a default wearing a costume.
	inst.set("ops_path", TRIAL_OPS)
	root.add_child(inst)
	await process_frame
	await process_frame

	_check("opened without a fatal", str(inst.call("fatal_message")) == "",
		str(inst.call("fatal_message")))
	var n: int = int(inst.call("order_size"))
	_check("the order has beads", n > 0, "order_size = %d" % n)
	if n <= 0:
		_write(report, false)
		quit(1)
		return
	_notes.append("order_size = %d, candidates = %d" % [n, int(inst.call("candidate_count"))])

	# ── 1. ten beads across ────────────────────────────────────────────────
	var built: int = int(inst.call("bead_count"))
	_check("ten beads are built and visible", built == 10, "bead_count = %d" % built)
	var first0: int = int(inst.call("window_first"))
	var seen0: PackedStringArray = inst.call("visible_lookups")
	_check("the window starts at bead 0", first0 == 0, "window_first = %d" % first0)
	_notes.append("window at open: " + ", ".join(seen0))

	# ── 2. scrolling moves the window ──────────────────────────────────────
	inst.call("scroll_by", 120)
	inst.call("settle_scroll")
	await process_frame
	var first1: int = int(inst.call("window_first"))
	var focus1: int = int(inst.call("focus_index"))
	var seen1: PackedStringArray = inst.call("visible_lookups")
	# 116, not 120: the window start is the FOCUS minus its slot, and the focus
	# sits at slot 4 of the ten. Asserting 120 was the probe's own arithmetic
	# error on the first run — kept here as the arithmetic, not the number.
	_check("scrolling moved the window to focus-minus-slot", first1 == 120 - 4,
		"focus %d, window_first %d -> %d" % [focus1, first0, first1])
	_check("the focus followed the scroll", focus1 == 120, "focus_index = %d" % focus1)
	_check("ten beads after the scroll", inst.call("bead_count") == 10,
		"bead_count = %d" % int(inst.call("bead_count")))
	var overlap: int = 0
	for s in seen1:
		if seen0.has(s):
			overlap += 1
	_check("the ten on the string are different artifacts", overlap == 0,
		"%d of 10 shared with the opening window" % overlap)
	_notes.append("window after +120: " + ", ".join(seen1))

	# ── 2b. ten at BOTH ENDS ───────────────────────────────────────────────
	# The first run of this probe found six beads at bead 0: nothing exists to
	# the left of the first artifact, so a window anchored only on the focus is
	# short by four. The window start is now clamped into [0, n-10].
	inst.call("scroll_by", -10000)
	inst.call("settle_scroll")
	await process_frame
	_check("ten beads at the HEAD of the string", inst.call("bead_count") == 10,
		"focus %d, window_first %d, bead_count %d" % [
			int(inst.call("focus_index")), int(inst.call("window_first")),
			int(inst.call("bead_count"))])
	_check("the head window starts at 0", int(inst.call("window_first")) == 0,
		"window_first = %d" % int(inst.call("window_first")))
	inst.call("scroll_by", 10000)
	inst.call("settle_scroll")
	await process_frame
	_check("ten beads at the TAIL of the string", inst.call("bead_count") == 10,
		"focus %d, window_first %d, bead_count %d" % [
			int(inst.call("focus_index")), int(inst.call("window_first")),
			int(inst.call("bead_count"))])
	_check("the tail window ends on the last bead",
		int(inst.call("window_first")) == n - 10,
		"window_first %d, expected %d" % [int(inst.call("window_first")), n - 10])
	inst.call("scroll_by", -10000)
	inst.call("scroll_by", 120)
	inst.call("settle_scroll")
	await process_frame

	# scroll back part-way so the add lands somewhere legible in the report
	inst.call("scroll_by", -3)
	inst.call("settle_scroll")
	await process_frame

	# ── 3. ADD ─────────────────────────────────────────────────────────────
	var anchor_lookup: String = str(inst.call("focus_lookup"))
	var anchor_i: int = int(inst.call("focus_index"))
	var cand: String = str(inst.call("candidate_lookup_at", 0))
	_check("the add pool is not empty", cand != "", "first candidate = '%s'" % cand)
	var added_ok: bool = bool(inst.call("add_candidate", cand, "after"))
	await process_frame
	_check("add_candidate returned true", added_ok, "adding %s after %s" % [cand, anchor_lookup])
	var n_after_add: int = int(inst.call("order_size"))
	_check("the string grew by one", n_after_add == n + 1,
		"order_size %d -> %d" % [n, n_after_add])
	_check("the added bead sits immediately after its anchor",
		str(inst.call("lookup_at", anchor_i + 1)) == cand,
		"lookup_at(%d) = %s" % [anchor_i + 1, str(inst.call("lookup_at", anchor_i + 1))])
	_check("the added bead is marked as the hand's",
		str(inst.call("origin_at", anchor_i + 1)) == "hand",
		"origin = %s" % str(inst.call("origin_at", anchor_i + 1)))
	_check("ten beads after the add", inst.call("bead_count") == 10,
		"bead_count = %d" % int(inst.call("bead_count")))

	var doc1: Dictionary = _read(TRIAL_OPS)
	_check("the hand file was created", not doc1.is_empty(), TRIAL_OPS)
	var ops1: Array = doc1.get("ops", []) if doc1.get("ops") is Array else []
	_check("the hand file holds exactly one op", ops1.size() == 1, "ops = %d" % ops1.size())
	if ops1.size() == 1:
		var op: Dictionary = ops1[0]
		_check("op 0 is an add", str(op.get("op", "")) == "add", str(op.get("op", "")))
		_check("op 0 names the token", str(op.get("lookup", "")) == cand, str(op.get("lookup", "")))
		_check("op 0 is anchored to a LOOKUP, not an index",
			str(op.get("after", "")) == anchor_lookup and not op.has("index"),
			"after = '%s', index key present = %s" % [str(op.get("after", "")), str(op.has("index"))])
		_check("op 0 carries its chapter", str(op.get("sequence", "")) != "",
			"sequence = %s" % str(op.get("sequence", "")))
	var m1: Dictionary = doc1.get("_meta", {}) if doc1.get("_meta") is Dictionary else {}
	_check("ops_revision bumped to 1", int(m1.get("ops_revision", -1)) == 1,
		"ops_revision = %d" % int(m1.get("ops_revision", -1)))
	_check("_meta.ops matches the op count", int(m1.get("ops", -1)) == 1,
		"_meta.ops = %d" % int(m1.get("ops", -1)))
	_check("the schema is declared", str(doc1.get("schema", "")) == "spine_order_ops/1",
		str(doc1.get("schema", "")))
	_check("base_generated was carried over from the derived file",
		str(m1.get("base_generated", "")) == str(_meta_of(EFFECTIVE).get("base_generated", "x")),
		"base_generated = %s" % str(m1.get("base_generated", "")))
	var readme1 := str(doc1.get("_readme", ""))
	_check("a readme was written", readme1 != "", "%d chars" % readme1.length())

	# ── 4. REMOVE ──────────────────────────────────────────────────────────
	# drop the anchor itself: a spine-origin bead, so the op is a real removal
	# rather than the refusal an added bead gets.
	var drop_ok: bool = bool(inst.call("drop_bead", anchor_i))
	await process_frame
	_check("drop_bead returned true", drop_ok, "dropping %s" % anchor_lookup)
	var n_after_drop: int = int(inst.call("order_size"))
	_check("the string shrank by one", n_after_drop == n,
		"order_size %d -> %d" % [n_after_add, n_after_drop])
	var still_there: bool = false
	for i in range(maxi(0, anchor_i - 3), mini(n_after_drop, anchor_i + 4)):
		if str(inst.call("lookup_at", i)) == anchor_lookup:
			still_there = true
	_check("the dropped bead is off the string", not still_there, anchor_lookup)
	_check("ten beads after the drop", inst.call("bead_count") == 10,
		"bead_count = %d" % int(inst.call("bead_count")))

	var doc2: Dictionary = _read(TRIAL_OPS)
	var ops2: Array = doc2.get("ops", []) if doc2.get("ops") is Array else []
	_check("the hand file now holds two ops", ops2.size() == 2, "ops = %d" % ops2.size())
	if ops2.size() == 2:
		var op0: Dictionary = ops2[0]
		var op1: Dictionary = ops2[1]
		_check("op 0 was APPENDED to, not rewritten",
			str(op0.get("op", "")) == "add" and str(op0.get("lookup", "")) == cand,
			"op 0 = %s %s" % [str(op0.get("op", "")), str(op0.get("lookup", ""))])
		_check("op 1 is a remove", str(op1.get("op", "")) == "remove", str(op1.get("op", "")))
		_check("op 1 names the dropped token", str(op1.get("lookup", "")) == anchor_lookup,
			str(op1.get("lookup", "")))
		_check("op 1 carries no position clause",
			not (op1.has("after") or op1.has("before") or op1.has("first_in") or op1.has("last_in")),
			"keys = %s" % str(op1.keys()))
	var m2: Dictionary = doc2.get("_meta", {}) if doc2.get("_meta") is Dictionary else {}
	_check("ops_revision bumped to 2", int(m2.get("ops_revision", -1)) == 2,
		"ops_revision = %d" % int(m2.get("ops_revision", -1)))
	_check("the readme survived the second write", str(doc2.get("_readme", "")) == readme1, "")
	_check("base_generated survived the second write",
		str(m2.get("base_generated", "")) == str(m1.get("base_generated", "")), "")

	var any_index: bool = false
	for o in ops2:
		if (o as Dictionary).has("index"):
			any_index = true
	_check("NO op addresses a position by index", not any_index,
		"an index re-targets in silence when the order regenerates")

	# ── 5. the live-body guard ─────────────────────────────────────────────
	# Tested WITHOUT instantiating anything: boid_flocking is the documented
	# headless-hang artifact, so a test that had to build it to learn it must not
	# be built would hang on the very case it exists to cover.
	var i_boid: int = int(inst.call("index_of", "boid_flocking"))
	if i_boid >= 0:
		var r_boid := str(inst.call("live_refusal_at", i_boid))
		_check("boid_flocking is refused a live body", r_boid != "", r_boid)
	else:
		_notes.append("boid_flocking is not in this order — guard untested for it")
	var i_gpu: int = -1
	for tok in ["mc_cave", "marchingcubes_cave", "mc_flat_landscape", "gyroid_demo"]:
		var t: int = int(inst.call("index_of", str(tok)))
		if t >= 0:
			i_gpu = t
			break
	if i_gpu >= 0:
		var r_gpu := str(inst.call("live_refusal_at", i_gpu))
		_check("a marching-cubes token is refused a live body", r_gpu.contains("GPU"), r_gpu)
	var i_ok: int = int(inst.call("index_of", "origin"))
	if i_ok >= 0:
		_check("an ordinary Node3D artifact is allowed a live body",
			str(inst.call("live_refusal_at", i_ok)) == "",
			str(inst.call("live_refusal_at", i_ok)))

		# and BUILD one, because the recipe (stamp before add_child, chrome
		# suppressed, settle, normalise into the bead volume) is only proved by
		# a body that actually stood up.
		inst.call("scroll_by", -10000)
		inst.call("scroll_by", i_ok)
		inst.call("settle_scroll")
		inst.call("set_live", true)
		await create_timer(1.4).timeout
		_check("the focus bead built a live body", bool(inst.call("live_mounted")),
			str(inst.call("live_note")))
		var sc: float = float(inst.call("live_scale"))
		_check("the live body was normalised into the bead volume", sc > 0.0,
			"scale = %.4f  ·  %s" % [sc, str(inst.call("live_note"))])
		_notes.append("live: " + str(inst.call("live_note")))
		inst.call("set_live", false)
		await process_frame
		_check("turning the live body off frees it", not bool(inst.call("live_mounted")), "")

	# ── 6. the files that must not have moved ──────────────────────────────
	_check("commons/data/spine_artifact_order.json is byte-identical",
		_md5(GENERATED) == gen_before, "generated order: %s" % gen_before)
	_check("the LIVE ops file is byte-identical", _md5(LIVE_OPS) == live_ops_before,
		"live hand: %s" % live_ops_before)
	_check("the derived file is byte-identical", _md5(EFFECTIVE) == eff_before,
		"effective: %s" % eff_before)
	_check("the scene wrote the injected path, not the default",
		str(inst.call("resolved_ops_path")) == TRIAL_OPS,
		str(inst.call("resolved_ops_path")))

	var pass_all: bool = true
	for c in _checks:
		if not bool((c as Dictionary).get("ok", false)):
			pass_all = false
	_write(report, pass_all)
	quit(0 if pass_all else 1)


func _check(name: String, ok: bool, detail: String) -> void:
	_checks.append({"check": name, "ok": ok, "detail": detail})


func _write(report: String, pass_all: bool) -> void:
	var failed: Array = []
	for c in _checks:
		if not bool((c as Dictionary).get("ok", false)):
			failed.append(str((c as Dictionary).get("check", "")))
	var doc: Dictionary = {
		"probe": "commons/testing/probe_necklace.gd",
		"scene": SCENE,
		"when": Time.get_datetime_string_from_system(false, true),
		"pass": pass_all,
		"checks_total": _checks.size(),
		"checks_failed": failed.size(),
		"failed": failed,
		"checks": _checks,
		"notes": _notes,
	}
	var f := FileAccess.open(report, FileAccess.WRITE)
	if f == null:
		push_error("probe_necklace: cannot write %s (err %d)" % [report, FileAccess.get_open_error()])
		return
	f.store_string(JSON.stringify(doc, " ", false) + "\n")
	f.close()


func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return (parsed as Dictionary) if parsed is Dictionary else {}


func _meta_of(path: String) -> Dictionary:
	var d: Dictionary = _read(path)
	var m: Variant = d.get("_meta", {})
	return (m as Dictionary) if m is Dictionary else {}


func _md5(path: String) -> String:
	if not FileAccess.file_exists(path):
		return "<absent>"
	return FileAccess.get_md5(path)
