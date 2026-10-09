extends SceneTree
## Noise_Perlin_Simplex pilot (doc/research/waves-chance-noise, 2026-09-10):
## are the two fields drawn from the bases they are named for, and is everything
## else the same?
##
## Stands up the ACTUAL museum hall with its artifacts, finds both roots by
## script, reads the noise_type back from each FastNoiseLite (not from the scene
## name), compares the full contract, samples the same coordinates on both,
## replays per basis, and moves one panel slider through its own slider_moved
## signal — emitted programmatically, no tracked hand.
##
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_wcn_noise_pair.gd -- --capture
##
## Writes res://ada_run/waves_chance_noise/Noise_Perlin_Simplex/probe_noise_pair.json.
var checks := 0
var failures: Array[String] = []
var measurements: Dictionary = {}
const MAP := "Noise_Perlin_Simplex"
const OUT := "res://ada_run/waves_chance_noise/Noise_Perlin_Simplex/"

func _initialize() -> void: run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)
	print("[wcn-noise] ", "PASS " if ok else "FAIL ", message)

func run() -> void:
	var em: Node3D = load("res://commons/scenes/endless_museum.tscn").instantiate()
	var ctl := "res://ada_run/waves_chance_noise/wcn-probe-control.json"
	em.set("EM_CONTROL", ctl); em.set("_overrides_path", ctl + ".unused"); em.set("_hand_path", ctl + ".unused-hand")
	em.set("start_chapter", "noise"); em.set("start_map", MAP)
	var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://commons/data/em_layout.json"))
	layout.get_or_add("stream", {})["bodies"] = 1
	em.set("_layout", layout)
	var f := FileAccess.open(ctl, FileAccess.WRITE)
	f.store_string(JSON.stringify({"first_chapter": "noise", "dollhouse": 0, "grid_pack": 1})); f.close()
	root.add_child(em); current_scene = em
	await create_timer(1.0).timeout
	em.set_process(false); em.set_physics_process(false); em.call("flush_stamps")
	var player: Node = em.get("_player")
	if player != null: player.set_process(false); player.set_physics_process(false)
	var seg: Node3D
	for rec: Dictionary in em.get("_segments"):
		if rec.node.get_meta("em_map", "") == MAP: seg = rec.node; break
	check(seg != null, "the hall exists in the active museum")
	if seg == null:
		_finish(); return
	for i in range(30): await process_frame

	var simplex: Node3D; var perlin: Node3D
	for n in seg.find_children("*", "Node3D", true, false):
		if n.get_script() == null: continue
		var p := str(n.get_script().resource_path)
		if p.ends_with("SimplexNoise.gd"): simplex = n
		elif p.ends_with("PerlinNoise.gd"): perlin = n
	check(simplex != null, "the simplex display is built")
	check(perlin != null, "the perlin display is built")
	if simplex == null or perlin == null:
		_finish(); return

	# ── 1. the bases, read back from the generators ───────────────────────────
	check(int(perlin.call("noise_type")) == FastNoiseLite.TYPE_PERLIN, "the display named Perlin draws TYPE_PERLIN (%d)" % int(perlin.call("noise_type")))
	check(int(simplex.call("noise_type")) == FastNoiseLite.TYPE_SIMPLEX, "the display named Simplex draws TYPE_SIMPLEX (%d)" % int(simplex.call("noise_type")))
	check(str(perlin.call("basis_name")) == "perlin", "the perlin readout reports its basis from the generator")

	# ── 2. the contract ───────────────────────────────────────────────────────
	var cs: Dictionary = simplex.call("contract"); var cp: Dictionary = perlin.call("contract")
	measurements["contract_simplex"] = cs; measurements["contract_perlin"] = cp
	for key in ["seed", "octaves", "frequency", "gain", "amplitude", "size", "resolution", "ramp", "readout"]:
		check(cs.get(key) == cp.get(key), "shared %s: %s == %s" % [key, str(cs.get(key)), str(cp.get(key))])
	check(int(cs.get("seed", -1)) == 20260910, "the declared seed reached both fields (%d)" % int(cs.get("seed", -1)))
	check(str(cs.get("ramp")) == "shared", "both fields use the shared ramp")
	check(int(cs.get("size", 0)) == 8, "both fields are 8 cells on a side")

	# ── 3. the same coordinates, two bases; replay per basis ──────────────────
	var sa: float = simplex.call("sample_at", 0.0, 0.0); var sb: float = simplex.call("sample_at", 2.5, 2.5)
	var pa: float = perlin.call("sample_at", 0.0, 0.0); var pb: float = perlin.call("sample_at", 2.5, 2.5)
	measurements["values"] = {"simplex": [sa, sb], "perlin": [pa, pb]}
	check(not (is_equal_approx(sa, pa) and is_equal_approx(sb, pb)), "the same seed in two bases gives different values at the same coordinates")
	simplex.call("regenerate"); await process_frame
	var s_regen: int = int(simplex.call("current_seed"))
	check(s_regen != 20260910, "REGEN moved the simplex field to another, recorded seed (%d)" % s_regen)
	check(not is_equal_approx(float(simplex.call("sample_at", 0.0, 0.0)), sa), "and its value at (0,0) changed")
	simplex.call("replay"); await process_frame
	check(int(simplex.call("current_seed")) == 20260910, "REPLAY restored the declared seed")
	check(is_equal_approx(float(simplex.call("sample_at", 0.0, 0.0)), sa) and is_equal_approx(float(simplex.call("sample_at", 2.5, 2.5)), sb), "and the two values came back exactly")
	perlin.call("regenerate"); await process_frame; perlin.call("replay"); await process_frame
	check(is_equal_approx(float(perlin.call("sample_at", 0.0, 0.0)), pa), "the perlin field replays per basis too")

	# ── 4. one shared dial, moved on one side, through the slider's own signal ─
	var fs: Node = simplex.find_child("Param_0", true, false)
	check(fs != null and fs.has_method("set_normalized_value"), "the simplex FREQ slider exists on a reachable panel")
	if fs != null:
		fs.set_normalized_value(0.6)
		fs.emit_signal("slider_moved", 0.6)
		await process_frame
		var f_after: float = float((simplex.call("contract") as Dictionary).get("frequency"))
		measurements["frequency_after_slider"] = f_after
		check(not is_equal_approx(f_after, float(cs.get("frequency"))), "moving FREQ changed the simplex field's frequency (%.2f -> %.2f)" % [float(cs.get("frequency")), f_after])
		check(is_equal_approx(float((perlin.call("contract") as Dictionary).get("frequency")), float(cp.get("frequency"))), "and left the perlin field alone — one variable, one side")
		simplex.call("set_frequency", float(cs.get("frequency"))); await process_frame
		check(is_equal_approx(float((simplex.call("contract") as Dictionary).get("frequency")), float(cs.get("frequency"))), "restored")
	var readout: Label3D = simplex.get_node_or_null("Readout")
	check(readout != null and readout.text.begins_with("simplex · seed 20260910"), "the readout names the basis and the seed")
	var pr: Label3D = perlin.get_node_or_null("Readout")
	check(pr != null and pr.text.begins_with("perlin · seed 20260910"), "the perlin readout does too")

	# ── 5. reach, the aisle, the walk, the door ───────────────────────────────
	for pair in [["simplex", simplex], ["perlin", perlin]]:
		var pn: Node3D = (pair[1] as Node3D).find_child("Param_0", true, false)
		if pn != null:
			var h: float = seg.to_local(pn.global_position).y
			measurements[str(pair[0]) + "_panel_height"] = h
			check(h > 0.6 and h < 1.7, "%s panel at hand height (%.2f m)" % [pair[0], h])
	var vest: int = int(em.get("VESTIBULE_H"))
	var space := seg.get_world_3d().direct_space_state
	var cap := CapsuleShape3D.new(); cap.radius = 0.22; cap.height = 1.6
	var q := PhysicsShapeQueryParameters3D.new(); q.shape = cap
	# the east corridor, the front row, and the aisle between the fields
	for route in [["east corridor", Vector3(11.5, 0.81, 1.5), Vector3(0, 0, 11.5)],
			["front row", Vector3(1.5, 0.81, 2.5), Vector3(10.0, 0, 0)],
			["aisle between the fields", Vector3(6.0, 0.81, 4.5), Vector3(0, 0, 6.0)]]:
		q.transform = Transform3D(Basis.IDENTITY, seg.to_global(Vector3(route[1].x, route[1].y, route[1].z + vest)))
		q.motion = route[2]
		var frac: float = space.cast_motion(q)[0]
		measurements["walk_" + str(route[0]).replace(" ", "_")] = frac
		check(frac > 0.99, "a body walks the %s (%.2f of the way)" % [route[0], frac])
	var portal: Node = null; var terrain100: Node = null
	for record: Dictionary in em.get("_edit_records"):
		var child: Node3D = record.get("node")
		if child == null or not is_instance_valid(child) or not seg.is_ancestor_of(child): continue
		if str(record.get("token", "")) == "configurable_portal": portal = child
		if str(record.get("token", "")) == "noise_terrain": terrain100 = child
	check(portal != null, "the optional Lab Path portal still stands")
	check(terrain100 == null, "the 100 m noise_terrain is no longer the floor of this hall")

	if "--capture" in OS.get_cmdline_user_args():
		var cam := Camera3D.new(); em.add_child(cam); cam.fov = 62
		cam.global_position = seg.to_global(Vector3(6.0, 2.4, 1.0 + vest)); cam.look_at(seg.to_global(Vector3(6.0, 0.9, 7.5 + vest)))
		for i in range(30): cam.make_current(); await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OUT + "probe_noise_pair.png")
	_finish()

func _finish() -> void:
	var report := {"map": MAP, "checks": checks, "failures": failures, "measurements": measurements,
		"control_path": "slider_moved emitted programmatically on the simplex FREQ slider; buttons called by method; no tracked hand",
		"headset_verified": false, "engine": Engine.get_version_info().string}
	var f := FileAccess.open(OUT + "probe_noise_pair.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(report, "  ")); f.close()
	print("[wcn-noise] ", checks, " checks; ", failures.size(), " failures")
	quit(0 if failures.is_empty() else 1)
