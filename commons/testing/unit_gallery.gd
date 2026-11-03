extends SceneTree
## THE UNIT'S GALLERY - specimens for the collection poster (Palle, 2026-11-03: "a collection poster of the
## experiment with overhead view"; "I like the timeline under each, and these examples - add more"). Each specimen is
## one run of the artifact's own model (unit_sim.gd), 900 s, headless and deterministic, recorded every 0.5 s in a
## generic layout: every unit (x, z, heading, hub, v, w, h), every pin, every tool point, every link (length,
## tension). tools/unit_gallery_poster.py draws them: overhead, with the timelines underneath.
## Rows: on its own and side by side; joined by a rod; pushed and mirrored; three in a triangle (Experiment 2's
## sensing rows are added here when its controllers land).
## Writes ada_run/workstation/unit_lab/gallery/<id>.json and index.json.
## Run: godot --headless --path . --xr-mode off --script res://commons/testing/unit_gallery.gd

const Sim = preload("res://commons/artifacts/the_unit/unit_sim.gd")
const T := 900.0
const SAMPLE := 60
const CELL := 0.02

const ROWS := [
	["On its own, and side by side", [
		{"id": "one", "label": "one unit, a pen on its hub", "make": "one"},
		{"id": "none_c", "label": "two units, no link (start c)", "make": "pair", "topology": "none", "start": "c"},
		{"id": "none_r2", "label": "two units, no link (random 2)", "make": "pair", "topology": "none", "start": "seed101"},
		{"id": "tendon_c", "label": "tendon (start c)", "make": "pair", "topology": "tendon", "start": "c"},
		{"id": "tendon_r4", "label": "tendon (random 4)", "make": "pair", "topology": "tendon", "start": "seed103"}]],
	["Joined by a rod", [
		{"id": "rod_c", "label": "rod, start c", "make": "pair", "topology": "rod", "start": "c"},
		{"id": "rod_parallel", "label": "rod, start parallel", "make": "pair", "topology": "rod", "start": "parallel"},
		{"id": "rod_crossed", "label": "rod, start crossed", "make": "pair", "topology": "rod", "start": "crossed"},
		{"id": "rod_r1", "label": "rod, random 1", "make": "pair", "topology": "rod", "start": "seed100"},
		{"id": "rod_r2", "label": "rod, random 2", "make": "pair", "topology": "rod", "start": "seed101"}]],
	["Pushed and mirrored", [
		{"id": "kick_plus", "label": "rod c, unit 2 turned +40 deg at 120 s", "make": "pair", "topology": "rod", "start": "c", "kick": [120.0, 1, 40.0]},
		{"id": "kick_minus", "label": "rod c, unit 2 turned -40 deg at 120 s", "make": "pair", "topology": "rod", "start": "c", "kick": [120.0, 1, -40.0]},
		{"id": "facing", "label": "rod, point-symmetric start", "make": "pair", "topology": "rod", "start": "facing"},
		{"id": "facing_nudged", "label": "the same, one unit turned 0.1 deg", "make": "pair", "topology": "rod", "start": "facing", "kick": [0.0, 1, 0.1]},
		{"id": "axle_hub", "label": "rod c, hub on the axle (a_hub 0)", "make": "axle"}]],
	["Sensing: the rod (experiment 2)", [
		{"id": "s_rod_open", "label": "rod c, no sensing", "make": "pair", "topology": "rod", "start": "c"},
		{"id": "s_ease_c", "label": "rod c + ease: the rod unloaded", "make": "pair", "topology": "rod", "start": "c", "ctrl": "ease"},
		{"id": "s_ease_r2", "label": "rod, random 2 + ease", "make": "pair", "topology": "rod", "start": "seed101", "ctrl": "ease"},
		{"id": "s_phase_c", "label": "rod c + phase: the bar never turns", "make": "pair", "topology": "rod", "start": "c", "ctrl": "phase"},
		{"id": "s_phase_r2", "label": "rod, random 2 + phase", "make": "pair", "topology": "rod", "start": "seed101", "ctrl": "phase"}]],
	["Sensing: the cord, and the ablations", [
		{"id": "s_tendon_open", "label": "tendon c, no sensing", "make": "pair", "topology": "tendon", "start": "c"},
		{"id": "s_keep_c", "label": "tendon c + keep: joined at a distance", "make": "pair", "topology": "tendon", "start": "c", "ctrl": "keep"},
		{"id": "s_keep_r4", "label": "tendon, random 4 + keep", "make": "pair", "topology": "tendon", "start": "seed103", "ctrl": "keep"},
		{"id": "s_ease_flip", "label": "rod c + ease, sign flipped (ablation)", "make": "pair", "topology": "rod", "start": "c", "ctrl": "ease_flip"},
		{"id": "s_phase_hub", "label": "rod crossed + hub reflex alone (ablation)", "make": "pair", "topology": "rod", "start": "crossed", "ctrl": "phase_hub"}]],
	["Three in a triangle", [
		{"id": "tri_c", "label": "triangle, start c", "make": "triangle", "start": "c"},
		{"id": "tri_scattered", "label": "triangle, scattered", "make": "triangle", "start": "scattered"},
		{"id": "tri_drifted", "label": "triangle, drifted", "make": "triangle", "start": "drifted"},
		{"id": "tri_tangent", "label": "triangle, threefold-symmetric start", "make": "triangle", "start": "tangent"},
		{"id": "tri_slow", "label": "triangle at the pair's programme (turn 0.25)", "make": "triangle", "start": "c", "params": {"w0": 0.25}}]],
]

func _initialize() -> void:
	var out_dir := ProjectSettings.globalize_path("res://ada_run/workstation/unit_lab/gallery")
	DirAccess.make_dir_recursive_absolute(out_dir)
	var index := {"T": T, "rows": []}
	var t0 := Time.get_ticks_msec()
	for row in ROWS:
		var entry := {"title": row[0], "specimens": []}
		for spec in row[1]:
			var r := _run(spec)
			var f := FileAccess.open(out_dir.path_join(str(spec.id) + ".json"), FileAccess.WRITE);f.store_string(JSON.stringify(r));f.close()
			entry.specimens.append({"id": spec.id, "label": spec.label, "metrics": r.metrics})
			print("[unit_gallery] %-14s reach %5.2f m2  |T| %5.1f N  turn %s" % [spec.id, float(r.metrics.reach_m2), float(r.metrics.tension_mean), str(r.metrics.w_mean)])
		index.rows.append(entry)
	index["seconds"] = (Time.get_ticks_msec() - t0) / 1000.0
	var fi := FileAccess.open(out_dir.path_join("index.json"), FileAccess.WRITE);fi.store_string(JSON.stringify(index, "  "));fi.close()
	print("[unit_gallery] done in %.0f s -> %s" % [index.seconds, out_dir])
	quit(0)

func _make(spec: Dictionary):
	var prm: Dictionary = spec.get("params", {})
	match str(spec.make):
		"one":
			return Sim.make("one", "c", prm)
		"triangle":
			return Sim.make("triangle", str(spec.start), prm)
		"axle":
			var sim = Sim.new({"a_hub": 0.0})
			sim.add_unit(-0.5, -0.3, 0.0, PI / 2.0)
			var q2: Vector2 = sim.pin(0) + float(sim.P.L) * Vector2(cos(0.3), sin(0.3))
			var th2 := 2.1;var al2 := th2 - 0.4
			sim.add_unit(q2.x - float(sim.P.r_pin) * cos(al2) - float(sim.P.a_hub) * cos(th2), q2.y - float(sim.P.r_pin) * sin(al2) - float(sim.P.a_hub) * sin(th2), th2, -0.4)
			sim.add_pen_between(0, 1, .5);sim.add_rod(0, 1)
			return sim
	var sim
	var start := str(spec.start)
	if start.begins_with("seed"):
		sim = Sim.new(prm)
		var rng := RandomNumberGenerator.new();rng.seed = int(start.trim_prefix("seed"))
		sim.add_unit(0.0, 0.0, rng.randf_range(-PI, PI), rng.randf_range(-PI, PI))
		var beta := rng.randf_range(-PI, PI);var th := rng.randf_range(-PI, PI);var ph := rng.randf_range(-PI, PI)
		var q: Vector2 = sim.pin(0) + float(sim.P.L) * Vector2(cos(beta), sin(beta))
		var al := th + ph
		sim.add_unit(q.x - float(sim.P.r_pin) * cos(al) - float(sim.P.a_hub) * cos(th), q.y - float(sim.P.r_pin) * sin(al) - float(sim.P.a_hub) * sin(th), th, ph)
	else:
		sim = Sim.make("apart", start, prm, .5, false)
		sim.pens.clear()
	var topo := str(spec.get("topology", "rod"))
	if topo == "rod":sim.add_rod(0, 1)
	elif topo == "tendon":sim.add_rod(0, 1, -1.0, true)
	sim.add_pen_between(0, 1, .5)
	for u in sim.units:u.ctrl = str(spec.get("ctrl", "programme"))
	return sim

func _kick(sim, unit: int, deg: float) -> void:
	var u: Dictionary = sim.units[unit]
	var pin: Vector2 = sim.pin(unit)
	var al: float = float(u.th) + float(u.ph)
	u.th = float(u.th) + deg_to_rad(deg);u.ph = al - float(u.th)
	u.x = pin.x - float(sim.P.a_hub) * cos(float(u.th)) - float(sim.P.r_pin) * cos(al)
	u.z = pin.y - float(sim.P.a_hub) * sin(float(u.th)) - float(sim.P.r_pin) * sin(al)

func _run(spec: Dictionary) -> Dictionary:
	var sim = _make(spec)
	var kick: Array = spec.get("kick", [])
	var kicked := false
	var nu: int = sim.units.size();var nt: int = sim.pens.size();var nl: int = sim.rods.size()
	var trace := []
	var cells := {}
	var t_sum := 0.0;var t_n := 0;var w_sum := 0.0
	for k in int(round(T / Sim.DT)):
		if kick.size() == 3 and not kicked and sim.time >= float(kick[0]):
			kicked = true;_kick(sim, int(kick[1]), float(kick[2]))
		sim.tick()
		var tool0: Vector2 = sim.pen_point(0)
		cells[Vector2i(int(floor(tool0.x / CELL)), int(floor(tool0.y / CELL)))] = true
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
				var ln: float = float(sim.stretch(j)) + float(sim.rods[j].L)
				var tn2: float = float(sim.P.k) * float(sim.stretch(j))
				if bool(sim.rods[j].get("tendon", false)) and tn2 < 0.0:tn2 = 0.0
				row.append_array([ln, tn2])
			trace.append(row)
	var n := maxi(t_n, 1)
	return {"id": spec.id, "label": spec.label, "T": T, "layout": {"units": nu, "tools": nt, "links": nl, "unit_fields": 7},
		"links": sim.rods.map(func(r): return [int(r.a), int(r.b), bool(r.get("tendon", false))]),
		"trace": trace, "metrics": {"reach_m2": cells.size() * CELL * CELL, "tension_mean": t_sum / n, "w_mean": snappedf(w_sum / n, .001)}}
