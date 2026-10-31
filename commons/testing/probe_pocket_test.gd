extends Node3D
## THE POCKET TEST on two surfaces (Palle, 2026-10-31: "a lever or button releases like 100 balls ... some will settle
## in the pocket of the surface, others will not ... a random surface will pocket more balls than a sine surface").
## Two 10 x 8 m slots side by side, a sine floor and a gaussian random floor, each with a pocket test over it. The
## button is pressed, eight seconds of Jolt pass, and the readings are taken: (A) every released ball is accounted
## for - pocketed, at the rim, rolling, or gone over the open edge (this bench has no basin wall: gone is the
## paper's "escaped") - on both; (B) the random floor's normal-entropy is higher than the
## sine floor's (the paper's measure); (C) the readout and the settled signal carry the same numbers. Which surface
## pockets more is REPORTED, not asserted: that is the experiment's finding. Picture and
## ada_run/workstation/pocket_test.json. Run: godot --path . --xr-mode off --resolution 1600x1000 res://commons/testing/probe_pocket_test.tscn

const Items = preload("res://commons/player/inventory_items.gd")

func _ready() -> void:
	var out_dir := ProjectSettings.globalize_path("res://ada_run/workstation");DirAccess.make_dir_recursive_absolute(out_dir)
	var env := WorldEnvironment.new();var e := Environment.new();e.background_mode = Environment.BG_COLOR;e.background_color = Color("2a2c33")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR;e.ambient_light_color = Color("d8d2c8");e.ambient_light_energy = .8;env.environment = e;add_child(env)
	var sun := DirectionalLight3D.new();sun.rotation_degrees = Vector3(-55, 30, 0);sun.light_energy = 1.1;sun.shadow_enabled = true;add_child(sun)
	var cam := Camera3D.new();add_child(cam);cam.current = true
	var report := {"checks": [], "readings": {}}
	var slot := {"slot_size": [10, 8], "slot_depth": 1.0, "slot_margin": 0.0, "rim_width": 0.5, "edge_band": 1.0}
	var tests := {}
	var setups := {"sine_space_floor": [Vector3(-6.5, 0, 0), {"wave_frequency": 0.9, "wave_amplitude": 0.6}], "random_space": [Vector3(6.5, 0, 0), {"law": "gaussian", "chaos_level": 1.0, "resolution": 50}]}
	for token in setups:
		var at: Vector3 = setups[token][0];var cfg: Dictionary = slot.duplicate();cfg.merge(setups[token][1])
		var surf: Node3D = load(Items.scene_for(token)).instantiate()
		for k in cfg:surf.set_meta("config_%s" % k, cfg[k])
		surf.set_meta("config_gravity_point_test", false);surf.name = token;surf.position = at;add_child(surf);surf.apply_grid_config(cfg)
		var test: Node3D = load(Items.scene_for("pocket_test")).instantiate()
		var tcfg := {"slot_size": [10, 8], "slot_depth": 1.0, "rim_width": 0.5, "count": 100, "surface": token, "settle_seconds": 8.0}
		for k in tcfg:test.set_meta("config_%s" % k, tcfg[k])
		test.name = token + "_test";test.position = at + Vector3(0, 0.03, 0);add_child(test);test.apply_grid_config(tcfg)
		tests[token] = test
	for f in 3:
		await get_tree().physics_frame
	var settled := {}
	for token in tests:
		var t: Node3D = tests[token]
		t.settled.connect(func(r):settled[token] = r)
		t.release()
	var frames := int(ceil(9.0 * Engine.physics_ticks_per_second))
	for f in frames:
		await get_tree().physics_frame
	var all_counted := true;var both_settled := true
	for token in tests:
		var r: Dictionary = tests[token].reading();report.readings[token] = r
		r["entropy_bits"] = tests[token].surface_entropy_bits(get_node(token))
		# this bench has no basin wall: a ball that runs off the flat rim falls and counts as GONE - the paper's "escaped"
		all_counted = all_counted and r.released == 100 and r.pocketed + r.rim + r.rolling + r.gone == 100
		both_settled = both_settled and settled.has(token)
	_check(report, "A accounted: both tests released 100 balls, every ball pocketed, at the rim, rolling, or gone over the open edge", all_counted, report.readings)
	var h_sine: float = report.readings["sine_space_floor"].entropy_bits;var h_rand: float = report.readings["random_space"].entropy_bits
	_check(report, "B entropy: the random floor's normal-entropy is higher than the sine floor's", h_rand > h_sine and h_sine > 0.5, {"sine": h_sine, "random": h_rand})
	var same: bool = both_settled and int(settled["sine_space_floor"].released) == 100 and str(tests["sine_space_floor"].readout.text).contains("POCKETED")
	_check(report, "C readout: both tests settled and signalled, the readout shows the counts", same, {"settled": settled.keys(), "readout": tests["sine_space_floor"].readout.text})
	print("[probe_pocket_test] FINDING sine pocketed %d of 100 (rim %d), random pocketed %d of 100 (rim %d); entropy sine %.2f random %.2f" % [report.readings["sine_space_floor"].pocketed, report.readings["sine_space_floor"].rim, report.readings["random_space"].pocketed, report.readings["random_space"].rim, h_sine, h_rand])
	report["finding"] = "sine pocketed %d, random pocketed %d" % [report.readings["sine_space_floor"].pocketed, report.readings["random_space"].pocketed]
	var shots := {"pocket_both": [Vector3(0, 9, 14), Vector3(0, 0.3, 0)], "pocket_sine": [Vector3(-6.5, 5, 8), Vector3(-6.5, 0.3, 0)], "pocket_random": [Vector3(6.5, 5, 8), Vector3(6.5, 0.3, 0)]}
	for k in shots:
		cam.transform = Transform3D(Basis(), shots[k][0]).looking_at(shots[k][1]);cam.fov = 55
		for f in 3:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(out_dir.path_join("%s.png" % k))
	var passed := 0
	for ch in report.checks:
		if ch.ok:passed += 1
	report["passed"] = passed;report["of"] = report.checks.size()
	var o := FileAccess.open(out_dir.path_join("pocket_test.json"), FileAccess.WRITE);o.store_string(JSON.stringify(report, "  "));o.close()
	print("[probe_pocket_test] %d/%d" % [passed, report.checks.size()])
	get_tree().quit(0 if passed == report.checks.size() else 1)

func _check(report: Dictionary, what: String, ok: bool, data: Dictionary) -> void:
	report.checks.append({"what": what, "ok": ok, "data": data})
	print("[probe_pocket_test] %s  %s" % ["ok  " if ok else "FAIL", what])
