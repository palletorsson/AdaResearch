extends SceneTree
## probe_boids_tank_divergence.gd — book_swarmintelligence.022, 2026-09-25.
##
## Prediction: boids_aquarium's RESET deals the same scatter every time (seeded), but
## the tank advances in _process(delta) with each frame's own length, and a flock is
## nonlinear, so two runs from one scatter part within seconds when their frames differ
## in length. Control: two runs with IDENTICAL fixed steps must stay identical.
##
## First run (10:39): the CONTROL FAILED - two instances stepped identically ended in
## different places - so the probe now also asks WHEN they part: at build, after one
## step, after ten, after a hundred. The tank's own _process is switched off and
## _update_boids(delta) is driven by hand:
##   A  fixed  1/60 s x 1200 steps (20 s)
##   B  fixed  1/60 s x 1200 steps           -> expected to equal A to the byte
##   C  jittered steps around 1/60 s         -> predicted to diverge from A
##
## Run:
##   python tools/godot_watchdog.py --expect=ada_run/probes/boids_tank_divergence.json -- \
##     C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe --headless --path . --xr-mode off \
##     --no-window --script res://commons/testing/probe_boids_tank_divergence.gd

const OUT := "res://ada_run/probes/boids_tank_divergence.json"
const TANK := "res://commons/artifacts/boids_aquarium/boids_aquarium.tscn"
const STEPS: int = 1200
const DT: float = 1.0 / 60.0
const JITTER: float = 0.2  # +-20 % of a frame, the size of an ordinary vsync hiccup
const CHECKPOINTS: Array[int] = [0, 1, 10, 60, 300, 1200]


func _init() -> void:
	var root: Node = get_root()
	var a: Dictionary = await _run(root, "A_fixed", false, 1)
	var b: Dictionary = await _run(root, "B_fixed", false, 2)
	var c: Dictionary = await _run(root, "C_jitter", true, 3)
	var report: Dictionary = {
		"probe": "boids_tank_divergence", "date": "2026-09-25", "steps": STEPS, "dt": DT, "jitter": JITTER,
		"boids": a["final"].size(),
		"A_vs_B_by_checkpoint_max_sep_m": {}, "A_vs_C_by_checkpoint_max_sep_m": {},
		"A_vs_B_max_separation_m": _max_sep(a["final"], b["final"]),
		"A_vs_B_mean_separation_m": _mean_sep(a["final"], b["final"]),
		"A_vs_C_max_separation_m": _max_sep(a["final"], c["final"]),
		"A_vs_C_mean_separation_m": _mean_sep(a["final"], c["final"]),
		"A_vs_C_centroid_separation_m": _centroid(a["final"]).distance_to(_centroid(c["final"])),
	}
	for k in CHECKPOINTS:
		var key: String = str(k)
		report["A_vs_B_by_checkpoint_max_sep_m"][key] = _max_sep(a["at"][key], b["at"][key])
		report["A_vs_C_by_checkpoint_max_sep_m"][key] = _max_sep(a["at"][key], c["at"][key])
	report["A_moved_max_m"] = _max_sep(a["at"]["0"], a["final"])
	var same_start: bool = report["A_vs_B_by_checkpoint_max_sep_m"]["0"] < 1e-6
	var same_ab: bool = report["A_vs_B_max_separation_m"] < 1e-6
	var diverged_ac: bool = report["A_vs_C_mean_separation_m"] > 0.05
	var parts: Array = []
	parts.append("%d boids, A moved up to %.3f m over the run (a readback: zero here means nothing was simulated)" % [report["boids"], report["A_moved_max_m"]])
	parts.append("same scatter at build: %s (max %.6f m)" % ["yes" if same_start else "NO", report["A_vs_B_by_checkpoint_max_sep_m"]["0"]])
	parts.append("identical steps stay identical: %s (max %.4f m after %d steps; first parted at step %s)" % ["yes" if same_ab else "NO", report["A_vs_B_max_separation_m"], STEPS, _first_parting(report["A_vs_B_by_checkpoint_max_sep_m"])])
	parts.append("jittered steps diverge from A: %s (mean %.4f m, max %.4f m)" % ["yes" if diverged_ac else "no", report["A_vs_C_mean_separation_m"], report["A_vs_C_max_separation_m"]])
	report["verdict"] = "; ".join(parts)
	print("[boids_tank] VERDICT: ", report["verdict"])
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://ada_run/probes"))
	var f := FileAccess.open(OUT, FileAccess.WRITE)
	f.store_string(JSON.stringify(report, "  "))
	f.close()
	print("[boids_tank] wrote ", OUT)
	quit()


func _first_parting(by_cp: Dictionary) -> String:
	for k in CHECKPOINTS:
		if float(by_cp[str(k)]) > 1e-6:
			return str(k)
	return "never"


func _run(root: Node, label: String, jitter: bool, seed_for_jitter: int) -> Dictionary:
	var scene: PackedScene = load(TANK)
	var node: Node = scene.instantiate()
	root.add_child(node)
	# Switch the tank's own _process off BEFORE any frame passes, or two instances get
	# different real-time deltas for their first frames and part before the experiment
	# begins (the 10:39 control). If the build was deferred, run it by hand instead of
	# awaiting a frame (the 11:0x run compared three EMPTY arrays and called them equal).
	node.set_process(false)
	node.set_physics_process(false)
	if (node.get("_boids") as Array).is_empty() and node.has_method("_build_all"):
		node.call("_build_all")
		node.set_process(false)
		node.set_physics_process(false)
	var count: int = (node.get("_boids") as Array).size()
	if count == 0:
		push_error("[boids_tank] %s: no boids built - the probe cannot run" % label)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242 + seed_for_jitter
	var at: Dictionary = {}
	at["0"] = _positions(node)
	var t: float = 0.0
	for i in STEPS:
		var dt: float = DT
		if jitter:
			dt = DT * (1.0 + rng.randf_range(-JITTER, JITTER))
		node.call("_update_boids", dt)
		t += dt
		var n: int = i + 1
		if n in CHECKPOINTS:
			at[str(n)] = _positions(node)
	var out: Array = _positions(node)
	print("[boids_tank] %s: %d boids, simulated %.2f s, centroid %s" % [label, out.size(), t, str(_centroid(out))])
	node.queue_free()
	await process_frame
	return {"final": out, "at": at}


func _positions(node: Node) -> Array:
	var boids: Array = node.get("_boids")
	var out: Array = []
	for b in boids:
		out.append(Vector3(b.position))
	return out


func _centroid(p: Array) -> Vector3:
	var c := Vector3.ZERO
	for v in p:
		c += v
	return c / maxf(1.0, float(p.size()))


func _max_sep(p: Array, q: Array) -> float:
	var m: float = 0.0
	for i in mini(p.size(), q.size()):
		m = maxf(m, p[i].distance_to(q[i]))
	return m


func _mean_sep(p: Array, q: Array) -> float:
	var s: float = 0.0
	var n: int = mini(p.size(), q.size())
	for i in n:
		s += p[i].distance_to(q[i])
	return s / maxf(1.0, float(n))
