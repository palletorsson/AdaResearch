extends SceneTree
## THE UNIT'S ZOO - as many different drawings as the model can make (Palle, 2026-11-03: "there were other strange
## examples I liked ... we want as many different examples as possible, with different looks and entropy"). Every
## rule family (the compliant open loop; ease, phase, ease_flip and keep from Experiment 2; steer and rhythm from the
## Python study) across rod lengths, hub offsets, pin radii, programmes, starts and kicks, on rods, cords and no link.
## Config i is drawn from a generator seeded with i, so any specimen can be rebuilt alone. Each run records five pens -
## unit 1's hub pin (the hub rim), and points 0.25, 0.5, 0.75 and 1.4 of the way from pin 1 to pin 2 (the last beyond
## the rod's end, a pantograph) - so one run gives five drawings. tools/unit_zoo_poster.py measures each drawing's
## entropy and picks the most different ones. Same generic trace layout as unit_gallery.gd.
## Writes ada_run/workstation/unit_lab/zoo/<id>.json and index_<shard>.json.
## Run: godot --headless --path . --xr-mode off --script res://commons/testing/unit_zoo.gd -- [--n=264] [--shard=0 --of=1] [--T=600]

const Sim = preload("res://commons/artifacts/the_unit/unit_sim.gd")
const SAMPLE := 30           ## every 0.25 s: a pen on a fast hub moves under half a radian between samples
const PEN_FRACS := [0.25, 0.5, 0.75, 1.4]

## [name, controller, link, programme preset]
const FAMILIES := [
	["compliance", "programme", "rod", {}],
	["steer", "steer", "rod", {"v0": .25, "w0": .2, "h0": 1.6}],
	["steer_chiral", "steer_chiral", "rod", {"v0": .25, "w0": .2, "h0": 1.6}],
	["rhythm", "rhythm", "rod", {"v0": .10, "w0": .09, "h0": 1.2}],
	["rhythm_anti", "rhythm_anti", "rod", {"v0": .10, "w0": .09, "h0": 1.2}],
	["ease", "ease", "rod", {}],
	["phase", "phase", "rod", {}],
	["ease_flip", "ease_flip", "rod", {}],
	["keep", "keep", "tendon", {}],
	["cord", "programme", "tendon", {}],
	["free", "programme", "none", {}],
]
## Named starts: [bearing of unit 2's pin seen from unit 1, heading difference, hub difference], degrees.
const STARTS := {"side": [90.0, 0.0, 0.0], "inline": [0.0, 0.0, 0.0], "opposite": [90.0, 180.0, 0.0], "abreast_hubs90": [90.0, 180.0, 90.0],
	"ahead_crossed": [20.0, 120.0, 200.0], "behind_turned": [180.0, 60.0, 45.0], "head90": [90.0, 90.0, 0.0]}

var T := 600.0

func _initialize() -> void:
	var n := 264
	var shard := 0
	var of := 1
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--n="):n = int(a.trim_prefix("--n="))
		if a.begins_with("--shard="):shard = int(a.trim_prefix("--shard="))
		if a.begins_with("--of="):of = int(a.trim_prefix("--of="))
		if a.begins_with("--T="):T = float(a.trim_prefix("--T="))
	var out_dir := ProjectSettings.globalize_path("res://ada_run/workstation/unit_lab/zoo")
	DirAccess.make_dir_recursive_absolute(out_dir)
	var index := {"T": T, "pens": ["hub pin of unit 1"] + PEN_FRACS.map(func(f): return "%.2f of the way from pin 1 to pin 2" % f), "specimens": []}
	var t0 := Time.get_ticks_msec()
	for i in n:
		if i % of != shard:continue
		var cfg := config(i)
		var r := _run(cfg)
		var f := FileAccess.open(out_dir.path_join(str(cfg.id) + ".json"), FileAccess.WRITE);f.store_string(JSON.stringify(r));f.close()
		index.specimens.append({"id": cfg.id, "label": cfg.label, "config": cfg, "metrics": r.metrics})
		print("[unit_zoo] %s %-60s |T| %5.1f N  finite %s" % [cfg.id, cfg.label, float(r.metrics.tension_mean), str(r.metrics.finite)])
	index["seconds"] = (Time.get_ticks_msec() - t0) / 1000.0
	var fi := FileAccess.open(out_dir.path_join("index_%d.json" % shard), FileAccess.WRITE);fi.store_string(JSON.stringify(index, "  "));fi.close()
	print("[unit_zoo] shard %d/%d: %d runs in %.0f s -> %s" % [shard, of, index.specimens.size(), index.seconds, out_dir])
	quit(0)

## Config i, drawn from a generator seeded with i: a family in turn, then everything else at random.
static func config(i: int) -> Dictionary:
	var rng := RandomNumberGenerator.new();rng.seed = 1000 + i
	var fam: Array = FAMILIES[i % FAMILIES.size()]
	var prm: Dictionary = (fam[3] as Dictionary).duplicate()
	var pick := func(arr: Array): return arr[rng.randi() % arr.size()]
	prm["L"] = pick.call([0.6, 0.8, 1.0, 1.0, 1.2, 1.5])
	prm["a_hub"] = pick.call([0.0, 0.12, 0.12, 0.25])
	prm["r_pin"] = pick.call([0.15, 0.15, 0.3])
	var base := Sim.defaults()
	for k in ["v0", "w0", "h0"]:
		if not prm.has(k):prm[k] = base[k]
	if rng.randf() < 0.5:prm["w0"] = float(prm.w0) * float(pick.call([0.4, 2.0, -1.0]))
	if rng.randf() < 0.5:prm["h0"] = float(prm.h0) * float(pick.call([2.0, 0.5, -1.0, 0.0]))
	var start: String
	var geo: Array
	if rng.randf() < 0.6:
		start = pick.call(STARTS.keys())
		geo = STARTS[start]
	else:
		start = "random"
		geo = [rng.randf_range(-180.0, 180.0), rng.randf_range(-180.0, 180.0), rng.randf_range(-180.0, 180.0)]
	var kick := []
	if rng.randf() < 0.2:kick = [120.0, 1, 40.0 if rng.randf() < 0.5 else -40.0]
	var label := "%s, %s L %.1f, a %.2f r %.2f, v %.2f w %.2f h %.2f, %s%s" % [fam[0], fam[2], float(prm.L), float(prm.a_hub), float(prm.r_pin),
		float(prm.v0), float(prm.w0), float(prm.h0), start, (", kick %+d deg" % int(kick[2])) if kick.size() == 3 else ""]
	return {"id": "z%03d" % i, "family": fam[0], "ctrl": fam[1], "link": fam[2], "params": prm, "start": start, "geo": geo, "kick": kick, "label": label}

## Unit 1 at the origin; unit 2 placed so its pin is one rod length from unit 1's, at the start's bearing, heading
## difference and hub difference (for the free pair, the same placement with nothing between them).
func make(cfg: Dictionary):
	var sim = Sim.new(cfg.params)
	var th1 := PI / 2.0
	var ph1 := 0.3
	sim.add_unit(0.0, 0.0, th1, ph1)
	var g: Array = cfg.geo
	var q: Vector2 = sim.pin(0) + float(sim.P.L) * Vector2(cos(th1 + deg_to_rad(float(g[0]))), sin(th1 + deg_to_rad(float(g[0]))))
	var th2 := th1 + deg_to_rad(float(g[1]))
	var al2 := th1 + ph1 + deg_to_rad(float(g[2]))
	sim.add_unit(q.x - float(sim.P.r_pin) * cos(al2) - float(sim.P.a_hub) * cos(th2), q.y - float(sim.P.r_pin) * sin(al2) - float(sim.P.a_hub) * sin(th2), th2, al2 - th2)
	if str(cfg.link) == "rod":sim.add_rod(0, 1)
	elif str(cfg.link) == "tendon":sim.add_rod(0, 1, -1.0, true)
	sim.add_pen_on_unit(0)
	for fr in PEN_FRACS:sim.add_pen_between(0, 1, fr)
	for u in sim.units:u.ctrl = str(cfg.ctrl)
	return sim

## Unit `unit` turned about its own pin (the pin stays, the link's length does not jump).
func _kick(sim, unit: int, deg: float) -> void:
	var u: Dictionary = sim.units[unit]
	var q: Vector2 = sim.pin(unit)
	var r := (Vector2(float(u.x), float(u.z)) - q).rotated(deg_to_rad(deg))
	u.x = q.x + r.x;u.z = q.y + r.y;u.th = float(u.th) + deg_to_rad(deg)

func _run(cfg: Dictionary) -> Dictionary:
	var sim = make(cfg)
	var kick: Array = cfg.kick
	var nu: int = sim.units.size();var nt: int = sim.pens.size();var nl: int = sim.rods.size()
	var trace := []
	var t_sum := 0.0;var t_n := 0;var w_sum := 0.0
	var finite := true
	for k in int(round(T / Sim.DT)):
		if kick.size() == 3 and k == int(round(float(kick[0]) / Sim.DT)):_kick(sim, int(kick[1]), float(kick[2]))
		sim.tick()
		if not (is_finite(float(sim.units[0].x)) and is_finite(float(sim.units[1].x))):
			finite = false
			break
		if sim.time >= T - 120.0:
			for j in nl:
				var tn: float = float(sim.P.k) * float(sim.stretch(j))
				if bool(sim.rods[j].get("tendon", false)) and tn < 0.0:tn = 0.0
				t_sum += absf(tn) / nl
			for u in sim.units:w_sum += float(u.cmd.y) / nu
			t_n += 1
		if k % SAMPLE == 0:
			var row := [snappedf(sim.time, .01)]
			for u in sim.units:
				var c: Vector3 = u.cmd
				row.append_array([float(u.x), float(u.z), float(u.th), float(u.ph), c.x, c.y, c.z])
			for i in nu:
				var p: Vector2 = sim.pin(i);row.append_array([p.x, p.y])
			for j in nt:
				var q: Vector2 = sim.pen_point(j);row.append_array([q.x, q.y])
			for j in nl:
				var tn2: float = float(sim.P.k) * float(sim.stretch(j))
				if bool(sim.rods[j].get("tendon", false)) and tn2 < 0.0:tn2 = 0.0
				row.append_array([float(sim.stretch(j)) + float(sim.rods[j].L), tn2])
			for c2 in range(1, row.size()):row[c2] = snappedf(float(row[c2]), .0001)   # 0.1 mm, 0.1 mN: small files
			trace.append(row)
	var n := maxi(t_n, 1)
	var skid := 0.0
	for u in sim.units:skid += float(u.skid)
	return {"id": cfg.id, "label": cfg.label, "config": cfg, "T": T, "layout": {"units": nu, "tools": nt, "links": nl, "unit_fields": 7},
		"links": sim.rods.map(func(r): return [int(r.a), int(r.b), bool(r.get("tendon", false))]),
		"trace": trace, "metrics": {"tension_mean": t_sum / n, "w_mean": snappedf(w_sum / n, .001), "skid_m": skid, "finite": finite}}
