extends SceneTree
## THE TIER A/B, proven headless: the museum installs a tier, _env_swap flips
## it live (WorldEnvironment replaced, vignette appears only on high), and the
## ab_seconds clock flips it unattended. Negative half: with ab_seconds 0 the
## tier holds still.
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_em_env_ab.gd

const OUT := "res://ada_run/em_env_ab_probe.json"

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var fails: Array = []
	var ps: PackedScene = load("res://commons/scenes/endless_museum.tscn")
	var inst: Node3D = ps.instantiate() as Node3D
	inst.set("_plan_path", "res://ada_run/em_plan.json")
	get_root().add_child(inst)
	await create_timer(1.0).timeout
	var t0 := String(inst.get("_env_tier"))
	var we0: Node = inst.get("_env_we")
	if t0 == "":
		fails.append("no environment tier installed (v1 fallback?)")
	# ── the manual swap, both directions ─────────────────────────────────────
	inst.call("_env_swap")
	await create_timer(0.2).timeout
	var t1 := String(inst.get("_env_tier"))
	var we1: Node = inst.get("_env_we")
	if t1 == t0:
		fails.append("swap 1 did not change the tier (%s)" % t1)
	if we1 == we0:
		fails.append("swap 1 kept the same WorldEnvironment instance")
	var vg1 := inst.get_node_or_null("EmVignette")
	inst.call("_env_swap")
	await create_timer(0.2).timeout
	var t2 := String(inst.get("_env_tier"))
	if t2 != t0:
		fails.append("swap 2 did not return to %s (got %s)" % [t0, t2])
	var vg2 := inst.get_node_or_null("EmVignette")
	# the vignette exists on exactly one side of the flip (the high tier)
	var vg_high := vg2 if t2 == "high" else vg1
	var vg_perf := vg1 if t2 == "high" else vg2
	if vg_high == null:
		fails.append("high tier has no vignette")
	if vg_perf != null:
		fails.append("perf tier kept a vignette")
	# ── negative half: ab_seconds 0 holds still ──────────────────────────────
	for i in range(30):
		await process_frame
	if String(inst.get("_env_tier")) != t2:
		fails.append("tier moved with ab_seconds=0")
	# ── the clock: 0.4 s alternation flips unattended ────────────────────────
	inst.set("_env_ab_s", 0.4)
	# museum-process time lags wall time under headless boot load, so wait on
	# the FLIP, not on a wall clock (up to 8 s)
	var t3 := t2
	for i in range(80):
		await create_timer(0.1).timeout
		t3 = String(inst.get("_env_tier"))
		if t3 != t2:
			break
	if t3 == t2:
		fails.append("ab clock at 0.4 s never flipped the tier in 8 s (accumulator %.3f)" % float(inst.get("_env_ab_t")))
	var f := FileAccess.open(OUT, FileAccess.WRITE)
	f.store_string(JSON.stringify({"start": t0, "after1": t1, "after2": t2,
		"clock": t3, "ab_t": float(inst.get("_env_ab_t")), "ab_s": float(inst.get("_env_ab_s")),
		"fails": fails}, " "))
	f.close()
	if fails.is_empty():
		print("EM ENV AB: PASS — %s -> %s -> %s, vignette follows high, clock flips, 0 holds" % [t0, t1, t2])
	else:
		print("EM ENV AB: FAIL %d" % fails.size())
		for x in fails:
			print("  - " + str(x))
	quit(0 if fails.is_empty() else 1)
