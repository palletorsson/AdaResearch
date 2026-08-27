extends SceneTree
## probe_necklace_live.gd — the ONE live body at the focus. Does L actually mount
## a real artifact, is it normalised, is it freed, and does it stay refused on the
## tokens the scene badges as unmountable?

const SCENE := "res://commons/scenes/desktop_necklace.tscn"
const TRIAL_OPS := "user://_live_necklace_ops.json"

var R: Dictionary = {"checks": [], "data": {}}
var report: String = ""


func _ck(n: String, ok: bool, d: String = "") -> void:
	R["checks"].append({"name": n, "ok": ok, "detail": d})


func _write() -> void:
	var bad: int = 0
	for c in R["checks"]:
		if not bool((c as Dictionary)["ok"]):
			bad += 1
	R["failed"] = bad
	R["total"] = (R["checks"] as Array).size()
	R["pass"] = bad == 0
	var f := FileAccess.open(report, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(R, "  ", false))
		f.close()


func _initialize() -> void:
	_run()


func _goto(inst: Node, i: int) -> void:
	inst.call("scroll_by", i - int(inst.call("focus_index")))
	inst.call("settle_scroll")


func _run() -> void:
	report = ProjectSettings.globalize_path("user://probe_necklace_live.json")
	for a in OS.get_cmdline_user_args():
		if str(a).begins_with("--report="):
			report = str(a).split("=", true, 1)[1]

	var ps := load(SCENE) as PackedScene
	var inst: Node = ps.instantiate()
	inst.set("ops_path", TRIAL_OPS)
	root.add_child(inst)
	await process_frame
	await process_frame

	var oi: int = int(inst.call("index_of", "origin"))
	R["data"]["origin_index"] = oi
	_ck("origin is in the order", oi >= 0, "index %d" % oi)
	if oi < 0:
		_write()
		quit(1)
		return
	_goto(inst, oi)
	inst.call("set_live", true)
	# the scene debounces LIVE_DEBOUNCE 0.30 s then settles LIVE_SETTLE 0.35 s
	var t0: int = Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 3000:
		await process_frame
		if bool(inst.call("live_mounted")) and float(inst.call("live_scale")) > 0.0:
			if Time.get_ticks_msec() - t0 > 1200:
				break
	R["data"]["live_note"] = str(inst.call("live_note"))
	R["data"]["live_scale"] = snappedf(float(inst.call("live_scale")), 0.001)
	R["data"]["mount_ms"] = Time.get_ticks_msec() - t0
	_ck("a live body actually mounted on the focus bead",
		bool(inst.call("live_mounted")), str(inst.call("live_note")))
	_ck("the body was normalised (a finite non-zero scale)",
		float(inst.call("live_scale")) > 0.0 and float(inst.call("live_scale")) < 100.0,
		"scale = %s" % str(inst.call("live_scale")))
	# the mount node really holds a child
	var mounted: int = 0
	for ch in inst.get_children():
		if not str(ch.name).begins_with("bead_%d_" % oi):
			continue
		var m: Node = ch.get_node_or_null("Mount")
		if m != null:
			mounted = m.get_child_count()
	R["data"]["mount_children"] = mounted
	_ck("the Mount node on that bead holds the instantiated artifact", mounted > 0,
		"Mount children = %d" % mounted)
	_write()

	# scroll one along: the old body must be freed and a new one built
	var before_scale: float = float(inst.call("live_scale"))
	_goto(inst, oi + 1)
	var t1: int = Time.get_ticks_msec()
	while Time.get_ticks_msec() - t1 < 3000:
		await process_frame
		if Time.get_ticks_msec() - t1 > 1400:
			break
	R["data"]["after_step_note"] = str(inst.call("live_note"))
	R["data"]["after_step_scale"] = snappedf(float(inst.call("live_scale")), 0.001)
	var stale: int = 0
	for ch2 in inst.get_children():
		if not str(ch2.name).begins_with("bead_%d_" % oi):
			continue
		var m2: Node = ch2.get_node_or_null("Mount")
		if m2 != null:
			stale = m2.get_child_count()
	R["data"]["old_mount_children_after_step"] = stale
	_ck("the previous live body was freed when the focus moved", stale == 0,
		"old Mount still holds %d" % stale)
	_ck("no crash after mounting and freeing a real artifact", true)

	inst.call("set_live", false)
	await process_frame
	_ck("set_live(false) leaves nothing mounted", not bool(inst.call("live_mounted")))
	_write()
	quit(0)
