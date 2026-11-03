extends SceneTree
## THE UNIT'S LAB - Palle's Experiments 1 and 2 (2026-11-03), run on the artifact's own model (unit_sim.gd), headless,
## deterministic: the same command line writes the same numbers.
##
##   Experiment 1, TOPOLOGY: identical commands (the open-loop programme) and identical starts, three topologies -
##     none (two independent units; the tool is the point a rod's middle would be), rod (rigid, pin to pin) and tendon
##     (a cord that only pulls, the same stiffness when taut). Drawing, reachable workspace, forces, stability.
##   Experiment 2, SENSING: the same physics and starts, the open-loop programme against sensing controllers
##     (unit_sim.gd _command); added as arms of the same matrix, so every comparison is one switch.
##
## Each run records, every 0.5 s, both chassis (x, z, heading), both hub angles, both pins, the tool point, the link's
## length and tension and both units' rates - all together - and its metrics. Starts: the three hand-set arrangements
## (c, parallel, crossed) and random ones from fixed seeds (unit 2's pin one rod length from unit 1's).
## Writes ada_run/workstation/unit_lab/<experiment>/<topology>__<controller>__<start>.json and summary.json;
## tools/unit_lab_plots.py draws them.
## Run: godot --headless --path . --xr-mode off --script res://commons/testing/unit_lab.gd -- --exp=1 [--T=720] [--seeds=5]

const Sim = preload("res://commons/artifacts/the_unit/unit_sim.gd")
const SAMPLE := 60           ## ticks between samples (0.5 s)
const CELL := 0.02           ## m, the grid that measures covered area

var T := 720.0
var window := 120.0          ## the settled window is the last `window` seconds

func _initialize() -> void:
	var experiment := "1"
	var seeds := 5
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--exp="):experiment = a.trim_prefix("--exp=")
		if a.begins_with("--T="):T = float(a.trim_prefix("--T="))
		if a.begins_with("--seeds="):seeds = int(a.trim_prefix("--seeds="))
	var out_dir := ProjectSettings.globalize_path("res://ada_run/workstation/unit_lab/exp%s" % experiment)
	DirAccess.make_dir_recursive_absolute(out_dir)
	var starts := ["c", "parallel", "crossed"]
	for s in seeds:starts.append("seed%d" % (100 + s))
	var arms: Array = []
	if experiment == "1":
		for topo in ["none", "rod", "tendon"]:arms.append([topo, "programme"])
	else:
		for spec in experiment.split(",", false):pass
	var summary := {"experiment": experiment, "T": T, "window": window, "starts": starts, "runs": []}
	var t0 := Time.get_ticks_msec()
	for arm in arms:
		for st in starts:
			var r := _run(str(arm[0]), str(arm[1]), str(st))
			var name := "%s__%s__%s" % [arm[0], arm[1], st]
			var f := FileAccess.open(out_dir.path_join(name + ".json"), FileAccess.WRITE);f.store_string(JSON.stringify(r));f.close()
			var m: Dictionary = r.metrics
			summary.runs.append({"name": name, "topology": arm[0], "controller": arm[1], "start": st, "metrics": m})
			print("[unit_lab] %-40s tool %5.2f m2  |T| %6.1f N (peak %6.1f)  link %.3f+-%.3f  apart max %.2f  R_hub %.2f  corr_w %.2f  w %s" % [name, float(m.tool_area_m2), float(m.tension_mean_window), float(m.tension_peak), float(m.link_mean_window), float(m.link_std_window), float(m.units_apart_max), float(m.hub_order_window), float(m.turn_corr_window), str(m.w_mean_window)])
	summary["seconds"] = (Time.get_ticks_msec() - t0) / 1000.0
	var sf := FileAccess.open(out_dir.path_join("summary.json"), FileAccess.WRITE);sf.store_string(JSON.stringify(summary, "  "));sf.close()
	print("[unit_lab] done: %d runs in %.0f s -> %s" % [summary.runs.size(), summary.seconds, out_dir])
	quit(0)

## Two units at a start, linked by `topology`, each run by `controller`; the tool point between their pins.
func make_pair(topology: String, controller: String, start: String):
	var sim
	if start.begins_with("seed"):
		sim = Sim.new({})
		var rng := RandomNumberGenerator.new();rng.seed = int(start.trim_prefix("seed"))
		sim.add_unit(0.0, 0.0, rng.randf_range(-PI, PI), rng.randf_range(-PI, PI))
		var beta := rng.randf_range(-PI, PI);var th2 := rng.randf_range(-PI, PI);var ph2 := rng.randf_range(-PI, PI)
		var q2: Vector2 = sim.pin(0) + float(sim.P.L) * Vector2(cos(beta), sin(beta))
		var al2 := th2 + ph2
		sim.add_unit(q2.x - float(sim.P.r_pin) * cos(al2) - float(sim.P.a_hub) * cos(th2), q2.y - float(sim.P.r_pin) * sin(al2) - float(sim.P.a_hub) * sin(th2), th2, ph2)
	else:
		sim = Sim.make("apart", start, {}, .5, false)
		sim.pens.clear()
	if topology == "rod":sim.add_rod(0, 1)
	elif topology == "tendon":sim.add_rod(0, 1, -1.0, true)
	sim.add_pen_between(0, 1, .5)
	for u in sim.units:u.ctrl = controller
	return sim

func _run(topology: String, controller: String, start: String) -> Dictionary:
	var sim = make_pair(topology, controller, start)
	var trace := []
	var cells := {}
	var tool_len := 0.0;var last_tool: Vector2 = sim.pen_point(0)
	var t_sum := 0.0;var t_n := 0;var t_peak := 0.0;var t_peak_w := 0.0;var slack := 0
	var len_sum := 0.0;var len_sq := 0.0;var len_max := 0.0
	var w_sum := [0.0, 0.0];var h_sum := [0.0, 0.0];var wx := [];var wy := []
	var hub_c := 0.0;var hub_s := 0.0;var apart_max := 0.0;var stretch_max := 0.0
	var lo := Vector2(INF, INF);var hi := -lo
	var steps := int(round(T / Sim.DT))
	var w0 := T - window
	for k in steps:
		sim.tick()
		var tool: Vector2 = sim.pen_point(0)
		tool_len += tool.distance_to(last_tool);last_tool = tool
		cells[Vector2i(int(floor(tool.x / CELL)), int(floor(tool.y / CELL)))] = true
		lo = Vector2(minf(lo.x, tool.x), minf(lo.y, tool.y));hi = Vector2(maxf(hi.x, tool.x), maxf(hi.y, tool.y))
		var p0: Vector2 = sim.pin(0);var p1: Vector2 = sim.pin(1)
		var ln := p0.distance_to(p1)
		var tn := 0.0
		if sim.rods.size() > 0:
			tn = float(sim.P.k) * (ln - float(sim.rods[0].L))
			if bool(sim.rods[0].get("tendon", false)) and tn < 0.0:tn = 0.0
			if not bool(sim.rods[0].get("tendon", false)) or tn > 0.0:stretch_max = maxf(stretch_max, absf(ln - float(sim.rods[0].L)))
		t_peak = maxf(t_peak, absf(tn))
		var u0: Dictionary = sim.units[0];var u1: Dictionary = sim.units[1]
		apart_max = maxf(apart_max, Vector2(float(u0.x), float(u0.z)).distance_to(Vector2(float(u1.x), float(u1.z))))
		if sim.time >= w0:
			t_sum += absf(tn);t_n += 1;t_peak_w = maxf(t_peak_w, absf(tn))
			if sim.rods.size() > 0 and bool(sim.rods[0].get("tendon", false)) and tn <= 0.0:slack += 1
			len_sum += ln;len_sq += ln * ln;len_max = maxf(len_max, ln)
			for i in 2:
				w_sum[i] += float(sim.units[i].cmd.y);h_sum[i] += float(sim.units[i].cmd.z)
			wx.append(float(u0.cmd.y));wy.append(float(u1.cmd.y))
			var dphi := (float(u0.th) + float(u0.ph)) - (float(u1.th) + float(u1.ph))
			hub_c += cos(dphi);hub_s += sin(dphi)
		if k % SAMPLE == 0:
			trace.append([snappedf(sim.time, .01), float(u0.x), float(u0.z), float(u0.th), float(u0.ph), float(u1.x), float(u1.z), float(u1.th), float(u1.ph),
				p0.x, p0.y, p1.x, p1.y, tool.x, tool.y, ln, tn, float(u0.cmd.x), float(u0.cmd.y), float(u0.cmd.z), float(u1.cmd.x), float(u1.cmd.y), float(u1.cmd.z)])
	var n := maxi(t_n, 1)
	var lm := len_sum / n
	var skid := 0.0
	for u in sim.units:skid += float(u.skid)
	var metrics := {
		"tool_length_m": tool_len, "tool_area_m2": cells.size() * CELL * CELL, "tool_extent_m": [hi.x - lo.x, hi.y - lo.y],
		"tension_mean_window": t_sum / n, "tension_peak": t_peak, "tension_peak_window": t_peak_w, "slack_fraction_window": float(slack) / n,
		"link_mean_window": lm, "link_std_window": sqrt(maxf(len_sq / n - lm * lm, 0.0)), "link_max_window": len_max,
		"units_apart_max": apart_max, "stretch_max_m": stretch_max, "skid_m": skid,
		"w_mean_window": [snappedf(w_sum[0] / n, .001), snappedf(w_sum[1] / n, .001)], "h_mean_window": [snappedf(h_sum[0] / n, .001), snappedf(h_sum[1] / n, .001)],
		"hub_order_window": Vector2(hub_c, hub_s).length() / n, "turn_corr_window": _corr(wx, wy),
		"finite": is_finite(float(sim.units[0].x)) and is_finite(float(sim.units[1].x))}
	return {"topology": topology, "controller": controller, "start": start, "T": T, "fields": ["t", "x0", "z0", "th0", "ph0", "x1", "z1", "th1", "ph1", "pin0x", "pin0z", "pin1x", "pin1z", "toolx", "toolz", "link", "tension", "v0", "w0", "h0", "v1", "w1", "h1"], "trace": trace, "metrics": metrics}

func _corr(a: Array, b: Array) -> float:
	var n := a.size()
	if n < 2:return 0.0
	var ma := 0.0;var mb := 0.0
	for i in n:ma += a[i];mb += b[i]
	ma /= n;mb /= n
	var sab := 0.0;var saa := 0.0;var sbb := 0.0
	for i in n:
		sab += (a[i] - ma) * (b[i] - mb);saa += (a[i] - ma) * (a[i] - ma);sbb += (b[i] - mb) * (b[i] - mb)
	return 0.0 if saa < 1e-12 or sbb < 1e-12 else sab / sqrt(saa * sbb)
