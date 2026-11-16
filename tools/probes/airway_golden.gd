extends SceneTree
## The GDScript airway voice (audio/airway/) against the reference numbers that came with the engine it
## was ported from: the head's geometry for 114 postures, and whole scenarios of sound, sample by sample.
## The references are not in this repo; point at the kit's folder.
##
##   godot --headless --path . --xr-mode off --script res://tools/probes/airway_golden.gd -- \
##       --golden=<kit>/vendor/chimera/tests/golden [--only=geometry|voice] [--scenario=sustain-male] \
##       [--samples=N] [--out=res://ada_run/airway_golden.json]

const Tract := preload("res://audio/airway/human_tract.gd")
const Voice := preload("res://audio/airway/airway_voice.gd")


func _arg(key: String, fallback: String) -> String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--" + key + "="): return a.substr(key.length() + 3)
	return fallback


static func _rel(a: float, b: float, floor_at: float) -> float:
	if a == b or (is_nan(a) and is_nan(b)): return 0.0
	return absf(a - b) / maxf(maxf(absf(a), absf(b)), floor_at)


func _initialize() -> void:
	var golden := _arg("golden", "")
	var only := _arg("only", "")
	var report := {}
	if only != "voice": report["geometry"] = _geometry(golden)
	if only != "geometry": report["voice"] = _voice(golden)
	var out := _arg("out", "")
	if out != "":
		var file := FileAccess.open(out, FileAccess.WRITE)
		file.store_string(JSON.stringify(report, "  "))
		file.close()
	print(JSON.stringify(report, "  "))
	quit(0)


func _geometry(golden: String) -> Dictionary:
	var cases: Variant = JSON.parse_string(FileAccess.get_file_as_string(golden + "/geometry.json"))
	if not cases is Array: return {"error": "no geometry.json at " + golden}
	var tracts := {}
	var worst := 0.0
	var worst_at := ""
	var wrong_sizes := 0
	var began := Time.get_ticks_usec()
	for ci in (cases as Array).size():
		var c: Dictionary = cases[ci]
		var body := str(c.body)
		if not tracts.has(body): tracts[body] = Tract.new(body)
		var tract: Tract = tracts[body]
		var a := PackedFloat64Array()
		for key in Tract.NAMES: a.append(float(c.artic[key]))
		tract.compute(a)
		var grid: Array = c.grid
		if grid.size() != tract.g_d.size():
			wrong_sizes += 1
			worst_at = "case %d grid size %d against %d" % [ci, tract.g_d.size(), grid.size()]
			continue
		var w := 0.0
		for i in grid.size():
			var e: Array = grid[i]
			if int(e[0]) != tract.g_region[i]: w = maxf(w, 1.0)
			w = maxf(w, maxf(_rel(float(e[1]), tract.g_d[i], 1e-6), maxf(_rel(float(e[2]), tract.g_area[i], 1e-6), _rel(float(e[3]), tract.g_s[i], 1e-6))))
		var s: Array = c.scalars
		var mine := [tract.length, tract.pharynx_length, tract.teeth_s, tract.lip_s, tract.velum_port, tract.lip_area, tract.tongue_radius * tract.scale,
			tract.tip_x, tract.tip_y, float(tract.split_index), tract.contact_tip, tract.contact_body, tract.contact_tip_nx, tract.contact_tip_ny,
			tract.contact_body_nx, tract.contact_body_ny]
		for i in mine.size(): w = maxf(w, _rel(float(s[i]), float(mine[i]), 1e-6))
		var ph := PackedFloat64Array()
		var orl := PackedFloat64Array()
		var ph_min := PackedFloat64Array()
		var or_min := PackedFloat64Array()
		for arr in [ph, orl, ph_min, or_min]: arr.resize(18)
		var lens := tract.resample(a, ph, orl, ph_min, or_min)
		var rs: Dictionary = c.resample
		w = maxf(w, maxf(_rel(float(rs.phLen), lens[0], 1e-6), _rel(float(rs.orLen), lens[1], 1e-6)))
		for pair in [["ph", ph], ["or", orl], ["phMin", ph_min], ["orMin", or_min]]:
			var want: Array = rs[pair[0]]
			var got: PackedFloat64Array = pair[1]
			for i in want.size(): w = maxf(w, _rel(float(want[i]), got[i], 1e-6))
		if w > worst:
			worst = w
			worst_at = "case %d (%s)" % [ci, body]
	return {"cases": (cases as Array).size(), "worst_relative_difference": worst, "worst_at": worst_at, "wrong_grid_sizes": wrong_sizes,
		"ms_a_posture": float(Time.get_ticks_usec() - began) / 1000.0 / float((cases as Array).size())}


func _voice(golden: String) -> Dictionary:
	var scenarios: Variant = JSON.parse_string(FileAccess.get_file_as_string(golden + "/voice.json"))
	if not scenarios is Array: return {"error": "no voice.json at " + golden}
	var which := _arg("scenario", "")
	var limit := int(_arg("samples", "0"))
	var result := {}
	for s in scenarios:
		var scenario_name := str(s.name)
		if which != "" and which != scenario_name: continue
		var reference := FileAccess.get_file_as_bytes("%s/voice-%s.f32" % [golden, scenario_name]).to_float32_array()
		var voice := Voice.new(float(s.fsOut), str(s.body), int(s.oversample))
		var n := int(s.samples)
		if limit > 0: n = mini(n, limit)
		var ops: Array = s.ops
		ops.sort_custom(func(p: Dictionary, q: Dictionary) -> bool: return int(p.at) < int(q.at))
		var got := PackedFloat32Array()
		got.resize(n)
		var i := 0
		var oi := 0
		var began := Time.get_ticks_usec()
		while i < n:
			while oi < ops.size() and int(ops[oi].at) <= i:
				var o: Dictionary = ops[oi]
				oi += 1
				match str(o.op):
					"gate": voice.set_gate(float(o.level))
					"artic": voice.set_articulation(o.values, -1 if not o.has("tipFree") or o.tipFree == null else (1 if bool(o.tipFree) else 0))
					"source": voice.set_source(o.values)
					"schedule": voice.schedule(o.gestures, float(o.offset))
					"release": voice.release(float(o.tag))
					"cancel": voice.cancel_score()
			var next_op := maxi(int(ops[oi].at), i + 1) if oi < ops.size() else n
			var upto := mini(n, mini(i + 128, next_op))
			voice.render(got, i, upto)
			i = upto
		var seconds := float(Time.get_ticks_usec() - began) / 1e6
		var peak := 0.0
		for k in n: peak = maxf(peak, absf(reference[k]))
		var max_err := 0.0
		var first := -1
		var sum_ref := 0.0
		var sum_err := 0.0
		for k in n:
			var e := absf(got[k] - reference[k])
			max_err = maxf(max_err, e)
			sum_ref += reference[k] * reference[k]
			sum_err += e * e
			if first < 0 and e > 1e-6 * peak: first = k
		result[scenario_name] = {"samples": n, "peak": peak, "max_error_of_peak": max_err / maxf(peak, 1e-30), "first_sample_off_by_1e-6": first,
			"error_db_below_signal": 10.0 * log(maxf(sum_err, 1e-300) / maxf(sum_ref, 1e-300)) / log(10.0), "render_seconds": seconds,
			"times_real_time": seconds / (float(n) / float(s.fsOut)), "nodes": voice.airway.net.n_nodes, "branches": voice.airway.net.n_branches,
			"courant": voice.airway.net.check_cfl()}
	return result
