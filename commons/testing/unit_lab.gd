extends SceneTree
## THE UNIT'S LAB - Palle's Experiments 1 and 2 (2026-11-03), run on the artifact's own model (unit_sim.gd), headless,
## deterministic: the same command line writes the same numbers.
##
##   Experiment 1, TOPOLOGY: identical commands (the open-loop programme) and identical starts, three topologies -
##     none (two independent units; the tool is the point a rod's middle would be), rod (rigid, pin to pin) and tendon
##     (a cord that only pulls, the same stiffness when taut). Drawing, reachable workspace, forces, stability.
##   Experiment 2, SENSING: the same physics and starts, the open-loop programme against sensing controllers
##     (unit_sim.gd _command); added as arms of the same matrix, so every comparison is one switch.
##   Experiment f, FAMILIES (the controlled comparison asked for 2026-11-03): the steer and rhythm rules, each on its
##     own programme - the bare programme with no link, and on a rod and on a cord the bare programme against the
##     family's two rules, so CONSTRAINED by the link can be told from RESPONDING to it. Every run has a twin with unit 2
##     moved 1 micrometre: how far apart the two tool points end, and when they first part by 1 cm, says whether the
##     drawing depends on its start that finely (sensitivity to initial conditions - what "chaotic" would mean).
##   Experiment 2h, HOLD: does the sensing HOLD the state it reaches, or only reach it? At KICK_AT every sensing pair
##     gets the same kick - unit 1 turned KICK_DEG about its own pin, so the link's length does not jump but the two
##     units stop being translates of each other - with the sensing left on (`~kick`), switched off at the same moment
##     (`~cut~kick`), or switched off with no kick (`~cut`: is the state an open-loop equilibrium that nothing disturbs?).
##     Scored on the same last 120 s.
##
## Each run records, every 0.5 s, both chassis (x, z, heading), both hub angles, both pins, the tool point, the link's
## length and tension and both units' rates - all together - and its metrics. Starts: the three hand-set arrangements
## (c, parallel, crossed) and random ones from fixed seeds (unit 2's pin one rod length from unit 1's).
## Writes ada_run/workstation/unit_lab/<experiment>/<topology>__<controller>__<start>.json and summary.json;
## tools/unit_lab_plots.py draws them.
## Run: godot --headless --path . --xr-mode off --script res://commons/testing/unit_lab.gd -- --exp=1|2|2h|f [--T=720] [--seeds=5]

const Sim = preload("res://commons/artifacts/the_unit/unit_sim.gd")
const SAMPLE := 60           ## ticks between samples (0.5 s)
const CELL := 0.02           ## m, the grid that measures covered area
const KICK_AT := 480.0       ## s, Experiment 2h's kick and switch-off
const KICK_DEG := 2.0        ## unit 1 turned about its own pin
## Experiment f: each family on its own programme (the Python study's), and the twin's nudge
const PRESETS := {"steer": {"v0": .25, "w0": .2, "h0": 1.6}, "rhythm": {"v0": .10, "w0": .09, "h0": 1.2}}
const TWIN_NUDGE := 1e-6     ## m, unit 2 moved along x in the twin

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
	elif experiment == "2":
		# the same physics and starts; only the controller differs - open loop, the sensing controller, an ablation
		for arm in [["rod", "programme"], ["rod", "ease"], ["rod", "ease_flip"], ["rod", "phase"], ["rod", "phase_hub"],
				["tendon", "programme"], ["tendon", "keep"], ["tendon", "keep_pull"], ["none", "keep"]]:arms.append(arm)
	elif experiment == "2h":
		for arm in [["rod", "ease"], ["rod", "phase"], ["tendon", "keep"]]:
			for ev in ["kick", "cut~kick", "cut"]:arms.append([arm[0], arm[1], ev])
	elif experiment == "f":
		# the steer and rhythm families, each on its own programme: the bare programme with no link, and on a rod and a
		# cord the bare programme against the family's two rules - constrained by the link, or responding to it
		for fam in [["steer", ["steer", "steer_chiral"]], ["rhythm", ["rhythm", "rhythm_anti"]]]:
			arms.append(["none", "programme", "", fam[0]])
			for topo in ["rod", "tendon"]:
				arms.append([topo, "programme", "", fam[0]])
				for c in fam[1]:arms.append([topo, c, "", fam[0]])
	var summary := {"experiment": experiment, "T": T, "window": window, "starts": starts, "runs": []}
	var t0 := Time.get_ticks_msec()
	for arm in arms:
		for st in starts:
			var ev: String = str(arm[2]) if arm.size() > 2 else ""
			var r := _run(str(arm[0]), str(arm[1]), str(st), ev, str(arm[3]) if arm.size() > 3 else "")
			var ctrl: String = str(r.controller)
			var name := "%s__%s__%s" % [arm[0], ctrl, st]
			var f := FileAccess.open(out_dir.path_join(name + ".json"), FileAccess.WRITE);f.store_string(JSON.stringify(r));f.close()
			var m: Dictionary = r.metrics
			summary.runs.append({"name": name, "topology": arm[0], "controller": ctrl, "start": st, "event_at": r.event_at, "kick_deg": r.kick_deg, "metrics": m})
			print("[unit_lab] %-36s |T| %5.2f N (win peak %5.1f)  rod turns %6.1f deg  band %3.0f%%  contact %d  v %s w %s h %s  carry %s bar %s joined %s" % [name, float(m.tension_mean_window), float(m.tension_peak_window), float(m.rod_pp_window_deg), 100.0 * float(m.band_fraction_window), int(m.contact_ticks), str(m.v_mean_window), str(m.w_mean_window), str(m.h_mean_window), m.test_carry, m.test_bar, m.test_joined])
	summary["seconds"] = (Time.get_ticks_msec() - t0) / 1000.0
	var sf := FileAccess.open(out_dir.path_join("summary.json"), FileAccess.WRITE);sf.store_string(JSON.stringify(summary, "  "));sf.close()
	print("[unit_lab] done: %d runs in %.0f s -> %s" % [summary.runs.size(), summary.seconds, out_dir])
	quit(0)

## Two units at a start, linked by `topology`, each run by `controller`; the tool point between their pins.
func make_pair(topology: String, controller: String, start: String, params := {}):
	var sim
	if start.begins_with("seed"):
		sim = Sim.new(params)
		var rng := RandomNumberGenerator.new();rng.seed = int(start.trim_prefix("seed"))
		sim.add_unit(0.0, 0.0, rng.randf_range(-PI, PI), rng.randf_range(-PI, PI))
		var beta := rng.randf_range(-PI, PI);var th2 := rng.randf_range(-PI, PI);var ph2 := rng.randf_range(-PI, PI)
		var q2: Vector2 = sim.pin(0) + float(sim.P.L) * Vector2(cos(beta), sin(beta))
		var al2 := th2 + ph2
		sim.add_unit(q2.x - float(sim.P.r_pin) * cos(al2) - float(sim.P.a_hub) * cos(th2), q2.y - float(sim.P.r_pin) * sin(al2) - float(sim.P.a_hub) * sin(th2), th2, ph2)
	else:
		sim = Sim.make("apart", start, params, .5, false)
		sim.pens.clear()
	if topology == "rod":sim.add_rod(0, 1)
	elif topology == "tendon":sim.add_rod(0, 1, -1.0, true)
	sim.add_pen_between(0, 1, .5)
	for u in sim.units:u.ctrl = controller
	return sim

## Experiment 2h's kick: unit 1 turned about its own pin, so the pin (and the link's length) stays where it was.
func _kick(sim, deg: float) -> void:
	var u: Dictionary = sim.units[1]
	var q: Vector2 = sim.pin(1)
	var r := (Vector2(float(u.x), float(u.z)) - q).rotated(deg_to_rad(deg))
	u.x = q.x + r.x;u.z = q.y + r.y;u.th = float(u.th) + deg_to_rad(deg)

func _run(topology: String, controller: String, start: String, event := "", preset := "") -> Dictionary:
	var params: Dictionary = PRESETS.get(preset, {})
	var sim = make_pair(topology, controller, start, params)
	# Experiment f's twin: the same run with unit 2 moved 1 micrometre - does the drawing depend on the start that finely?
	var twin = make_pair(topology, controller, start, params) if preset != "" else null
	if twin != null:twin.units[1].x = float(twin.units[1].x) + TWIN_NUDGE
	var div_max := 0.0;var div_t_1cm := -1.0;var div_end := 0.0
	var k_event := int(round(KICK_AT / Sim.DT)) if event != "" else -1
	var trace := []
	var cells := {}
	var tool_len := 0.0;var last_tool: Vector2 = sim.pen_point(0)
	var t_sum := 0.0;var t_n := 0;var t_peak := 0.0;var t_peak_w := 0.0;var slack := 0
	var len_sum := 0.0;var len_sq := 0.0;var len_max := 0.0
	var w_sum := [0.0, 0.0];var h_sum := [0.0, 0.0];var wx := [];var wy := []
	var hub_c := 0.0;var hub_s := 0.0;var apart_max := 0.0;var stretch_max := 0.0
	var lo := Vector2(INF, INF);var hi := -lo
	var v_sum := [0.0, 0.0];var rod_prev := 0.0;var rod_acc := 0.0;var rod_lo := INF;var rod_hi := -INF;var rod_started := false
	var band := 0;var contact := 0;var contact_w := 0;var tool_w := 0.0;var wlo := Vector2(INF, INF);var whi := -wlo;var dev_max := 0.0
	var last_tool_w := Vector2.ZERO;var have_w := false
	var steps := int(round(T / Sim.DT))
	var w0 := T - window
	for k in steps:
		if k == k_event:
			if event.begins_with("cut"):
				for u in sim.units:u.ctrl = "programme"
			if event.ends_with("kick"):_kick(sim, KICK_DEG)
		sim.tick()
		var tool: Vector2 = sim.pen_point(0)
		if twin != null:
			twin.tick()
			div_end = tool.distance_to(twin.pen_point(0))
			div_max = maxf(div_max, div_end)
			if div_t_1cm < 0.0 and div_end > 0.01:div_t_1cm = sim.time
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
		var touching := _overlap(u0, u1)
		if touching:contact += 1
		var ang := atan2(p1.y - p0.y, p1.x - p0.x)
		if sim.time >= w0:
			if touching:contact_w += 1
			if not rod_started:rod_started = true;rod_prev = ang
			rod_acc += wrapf(ang - rod_prev, -PI, PI);rod_prev = ang;rod_lo = minf(rod_lo, rod_acc);rod_hi = maxf(rod_hi, rod_acc)
			if ln >= .85 and ln <= 1.008:band += 1
			if sim.rods.size() > 0:dev_max = maxf(dev_max, absf(ln - float(sim.rods[0].L)))
			if have_w:tool_w += tool.distance_to(last_tool_w)
			last_tool_w = tool;have_w = true
			wlo = Vector2(minf(wlo.x, tool.x), minf(wlo.y, tool.y));whi = Vector2(maxf(whi.x, tool.x), maxf(whi.y, tool.y))
			for i in 2:v_sum[i] += float(sim.units[i].cmd.x)
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
		"finite": is_finite(float(sim.units[0].x)) and is_finite(float(sim.units[1].x)),
		"v_mean_window": [snappedf(v_sum[0] / n, .001), snappedf(v_sum[1] / n, .001)],
		"rod_pp_window_deg": rad_to_deg(rod_hi - rod_lo), "band_fraction_window": float(band) / n, "contact_ticks": contact, "contact_ticks_window": contact_w,
		"tool_path_window_m": tool_w, "tool_span_window_m": maxf(whi.x - wlo.x, whi.y - wlo.y), "link_dev_max_window_m": dev_max,
		"twin_div_max_m": div_max, "twin_div_end_m": div_end, "twin_div_1cm_s": div_t_1cm}
	# Experiment 2's three capability tests (the designers' operational tests), on the settled window
	var P: Dictionary = sim.P
	var rates_within := func(tol: float) -> bool:
		for i in 2:
			if absf(float(v_sum[i]) / n / float(P.v0) - 1.0) > tol or absf(float(w_sum[i]) / n / float(P.w0) - 1.0) > tol or absf(float(h_sum[i]) / n / float(P.h0) - 1.0) > tol:return false
		return true
	metrics["test_carry"] = sim.rods.size() > 0 and not bool(sim.rods[0].get("tendon", false)) and float(metrics.tension_mean_window) < .5 and float(metrics.tension_peak_window) < 2.0 and rates_within.call(.02)
	metrics["test_bar"] = sim.rods.size() > 0 and float(metrics.rod_pp_window_deg) < 2.0 and tool_w >= 10.0 and float(metrics.tool_span_window_m) >= .5 and rates_within.call(.10) and dev_max < .005
	metrics["test_joined"] = sim.rods.size() > 0 and float(metrics.band_fraction_window) >= .95 and float(metrics.tension_peak_window) <= 25.0 and contact_w == 0 and float(v_sum[0]) / n >= .5 * float(P.v0) and float(v_sum[1]) / n >= .5 * float(P.v0)
	return {"topology": topology, "controller": controller + ("@" + preset if preset != "" else "") + ("~" + event if event != "" else ""), "start": start, "T": T, "event_at": KICK_AT if event != "" else -1.0, "kick_deg": KICK_DEG if event.ends_with("kick") else 0.0, "fields": ["t", "x0", "z0", "th0", "ph0", "x1", "z1", "th1", "ph1", "pin0x", "pin0z", "pin1x", "pin1z", "toolx", "toolz", "link", "tension", "v0", "w0", "h0", "v1", "w1", "h1"], "trace": trace, "metrics": metrics}

## Do the two chassis footprints overlap (separating-axis test on the frames with their wheels: x -0.09..0.33, z +-0.25)?
func _overlap(a: Dictionary, b: Dictionary) -> bool:
	var ca := _corners(a);var cb := _corners(b)
	for th in [float(a.th), float(b.th)]:
		for axis in [Vector2(cos(th), sin(th)), Vector2(-sin(th), cos(th))]:
			var amin := INF;var amax := -INF;var bmin := INF;var bmax := -INF
			for q in ca:
				var d: float = axis.dot(q)
				amin = minf(amin, d);amax = maxf(amax, d)
			for q in cb:
				var d2: float = axis.dot(q)
				bmin = minf(bmin, d2);bmax = maxf(bmax, d2)
			if amax < bmin or bmax < amin:return false
	return true

func _corners(u: Dictionary) -> Array:
	var c := cos(float(u.th));var s := sin(float(u.th));var out := []
	for q in [Vector2(-.09, -.25), Vector2(.33, -.25), Vector2(.33, .25), Vector2(-.09, .25)]:
		out.append(Vector2(float(u.x) + q.x * c - q.y * s, float(u.z) + q.x * s + q.y * c))
	return out

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
