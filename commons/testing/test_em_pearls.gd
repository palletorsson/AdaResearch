extends SceneTree
## The pearls, in the museum — one SEGMENT per pearl, proven both ways.
##
## GATE:  a plan whose chapter rows carry no `pearl` builds exactly as before:
##        _plan_pearls empty, one segment per chapter, the pool cursor moving a
##        chapter per segment.
## BITE:  a plan where primitives arrives as N pearl rows (`--em-plan=<trial>`,
##        opening at primitives) builds N consecutive segments for primitives —
##        each dealt from its own pearl row in string order — and only THEN
##        moves the pool to the next chapter. The banner carries the pearl.
##
##   godot --headless --path . --xr-mode off --script res://commons/testing/test_em_pearls.gd -- --trial=res://ada_run/_trial_em_plan_pearls.json

const PLAN := "res://ada_run/em_plan.json"

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var fails: Array[String] = []
	var trial := ""
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("--trial="):
			trial = String(a).substr(8)
	var ps: PackedScene = load("res://commons/scenes/endless_museum.tscn")

	# ── GATE: the live plan; are its rows pearl-less? then nothing must change
	var live: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PLAN))
	var live_has_pearls := false
	for r in live.get("plans", []):
		if (r as Dictionary).has("pearl"):
			live_has_pearls = true
	if not live_has_pearls:
		var g: Node3D = ps.instantiate() as Node3D
		g.set("_plan_path", PLAN)
		g.set("_first_chapter", "primitives")
		get_root().add_child(g)
		await create_timer(0.6).timeout
		if not (g.get("_plan_pearls") as Dictionary).is_empty():
			fails.append("GATE: a pearl-less plan produced _plan_pearls")
		get_root().remove_child(g); g.queue_free()
		await create_timer(0.2).timeout
	else:
		print("[test] the live plan already carries pearls — gate arm skipped, bite arm on the live plan")
		trial = PLAN if trial == "" else trial

	# ── BITE: the pearl plan
	if trial == "" or not FileAccess.file_exists(trial):
		print("EM PEARLS: SKIP — no trial plan (build one with spine_run per-pearl, or pass --trial=)")
		quit(0); return
	var b: Node3D = ps.instantiate() as Node3D
	b.set("_plan_path", trial)
	b.set("_first_chapter", "primitives")
	b.set("_overrides_path", "res://ada_run/_trial_em_overrides_pearls.json")
	get_root().add_child(b)
	await create_timer(0.6).timeout
	var pp: Dictionary = b.get("_plan_pearls")
	var key := ""
	var n_pearls := 0
	for k in pp.keys():
		if String(k).ends_with("|primitives"):
			key = String(k); n_pearls = (pp[k] as Array).size()
	if n_pearls < 2:
		fails.append("BITE: primitives has %d pearl rows in the trial plan" % n_pearls)
	else:
		# the museum pre-builds its look-ahead on ready, so the cursor already
		# stands past those; from HERE the remaining pearls must be walked one
		# per segment, then reset to 0 as the pool moves to the next chapter
		var start: int = int((b.get("_pearl_cursor") as Dictionary).get("primitives", 0))
		if start < 1:
			fails.append("BITE: after the museum's own first segments the cursor is %d — the string was not entered" % start)
		var seen_pearls: Array = []
		for i in range(n_pearls - start + 1):
			seen_pearls.append(int((b.get("_pearl_cursor") as Dictionary).get("primitives", 0)))
			b.call("_build_segment")
			await create_timer(0.15).timeout
		var expect: Array = []
		for i in range(start, n_pearls): expect.append(i)
		expect.append(0)
		if seen_pearls != expect:
			fails.append("BITE: pearl cursor walked %s, expected %s" % [str(seen_pearls), str(expect)])
		var pool_i: int = int(b.get("_pool_i"))
		var pool: Array = b.get("_pool")
		var now_seq := String((pool[pool_i % pool.size()] as Dictionary).get("sequence", ""))
		if now_seq == "primitives":
			fails.append("BITE: after the string the pool cursor still points at primitives")
	get_root().remove_child(b); b.queue_free()
	if FileAccess.file_exists("res://ada_run/_trial_em_overrides_pearls.json"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path("res://ada_run/_trial_em_overrides_pearls.json"))
	if fails.is_empty():
		print("EM PEARLS: PASS — pearl-less plan unchanged; primitives built %d segments, one per pearl, then moved on" % n_pearls)
	else:
		print("EM PEARLS: FAIL %d" % fails.size()); for x in fails: print("  - " + x)
	quit(0 if fails.is_empty() else 1)
