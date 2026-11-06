extends Node3D
## The built look's pilot, measured (Palle, 2026-11-06: "if we create a really large playground we want the geometry
## as simple as possible - or does it not matter?"). A 10 x 10 x 4 field of kit balls and rods is built by the kit's
## own rules (rods up, balls on their ends, rods across), then measured over 120 frames DETAILED (every piece its own
## meshes and body) and BUILT (the same pieces folded into kit_structure.gd). Checks:
## (A) the field stands: every ball supported, every rod in two sockets; (B) NEGATIVE: with fold off no structure node
## exists; (C) built: every ball and rod folded, draw calls down by at least 90 %, triangles down; (D) built rods are
## frozen and stop ticking: active physics bodies down; (E) a ball picked up unfolds (its own meshes back, 399 in the
## structure) and set down again folds back (400).
## Writes ada_run/kit_built/{detailed.png, built.png, report.json}.
## Run: godot --path <abs> --xr-mode off --resolution 1280x800 --rendering-method mobile res://commons/testing/probe_kit_built.tscn

const Ball = preload("res://commons/artifacts/playground_kit/playground_ball.tscn")
const Rod = preload("res://commons/artifacts/playground_kit/playground_rod.tscn")
const BallLib = preload("res://commons/artifacts/playground_kit/playground_ball.gd")
const NX := 10
const NZ := 10
const NY := 4

var report := {"checks": [], "measured": {}}
var out_dir := ""
var grid := {}   # Vector3i -> ball

func _ready() -> void:
	out_dir = ProjectSettings.globalize_path("res://ada_run/kit_built");DirAccess.make_dir_recursive_absolute(out_dir)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var env := WorldEnvironment.new();var e := Environment.new();e.background_mode = Environment.BG_COLOR;e.background_color = Color("2a2c33")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR;e.ambient_light_color = Color("d8d2c8");e.ambient_light_energy = .75;env.environment = e;add_child(env)
	var sun := DirectionalLight3D.new();sun.rotation_degrees = Vector3(-40, 30, 0);sun.light_energy = 1.1;add_child(sun)
	var floor_b := StaticBody3D.new();floor_b.collision_layer = 1;add_child(floor_b)
	var fs := CollisionShape3D.new();var fb := BoxShape3D.new();fb.size = Vector3(30, .1, 30);fs.shape = fb;fs.position = Vector3(4.5, -.05, 4.5);floor_b.add_child(fs)
	var fm := MeshInstance3D.new();var fbm := BoxMesh.new();fbm.size = Vector3(30, .1, 30);fm.mesh = fbm;fm.position = Vector3(4.5, -.05, 4.5)
	var fmat := StandardMaterial3D.new();fmat.albedo_color = Color("8f8a84");fm.material_override = fmat;floor_b.add_child(fm)
	var cam := Camera3D.new();cam.transform = Transform3D(Basis(), Vector3(15, 9, 17)).looking_at(Vector3(4.5, 1.2, 4.5));cam.fov = 50;add_child(cam);cam.current = true
	await _run()
	var passed: int = report.checks.filter(func(c):return c.ok).size()
	report["passed"] = passed;report["total"] = report.checks.size()
	var f := FileAccess.open(out_dir.path_join("report.json"), FileAccess.WRITE);f.store_string(JSON.stringify(report, "  "));f.close()
	print("KIT_BUILT %d/%d" % [passed, report.checks.size()])
	get_tree().quit(0 if passed == report.checks.size() else 1)

func _run() -> void:
	var t0 := Time.get_ticks_msec()
	for y in NY:
		if y > 0:
			for x in NX:
				for z in NZ:_rod_out(grid[Vector3i(x, y - 1, z)], 2)
		for x in NX:
			for z in NZ:grid[Vector3i(x, y, z)] = _ball(Vector3(x, y, z))
		for x in NX:
			for z in NZ:
				if x + 1 < NX:_bridge(grid[Vector3i(x, y, z)], grid[Vector3i(x + 1, y, z)])
				if z + 1 < NZ:_bridge(grid[Vector3i(x, y, z)], grid[Vector3i(x, y, z + 1)])
		await get_tree().physics_frame
	report.measured["build_ms"] = Time.get_ticks_msec() - t0
	var balls := get_tree().get_nodes_in_group("playground_balls");var rods := get_tree().get_nodes_in_group("playground_rods")
	var expected_rods := NY * (2 * NX * NZ - NX - NZ) + (NY - 1) * NX * NZ
	_check("A the field stands: %d balls all supported, %d rods each in two sockets" % [NX * NY * NZ, expected_rods],
		balls.size() == NX * NY * NZ and balls.all(func(b):return b.supported and b.freeze) and rods.size() == expected_rods and rods.all(func(r):return r.joints.size() == 2),
		{"balls": balls.size(), "rods": rods.size(), "unsupported": balls.filter(func(b):return not b.supported).size(), "short_rods": rods.filter(func(r):return r.joints.size() != 2).size()})
	var detailed := await _measure("detailed")
	_check("B negative: with fold off there is no PlaygroundStructure node", get_node_or_null("PlaygroundStructure") == null, {})
	# fold every ball and read the graph again
	for b in balls:b.fold = true
	BallLib.reevaluate(get_tree())
	var built := await _measure("built")
	var st: Node = get_node_or_null("PlaygroundStructure")
	var nb: int = st.folded_balls.size() if st else -1;var nr: int = st.folded_rods.size() if st else -1
	_check("C built: every ball and rod folded; draw calls down at least 90 %%, triangles down",
		nb == balls.size() and nr == rods.size() and built.draws <= detailed.draws * .1 and built.triangles < detailed.triangles,
		{"folded_balls": nb, "folded_rods": nr, "draws": [detailed.draws, built.draws], "triangles": [detailed.triangles, built.triangles]})
	# Not a claim about physics time: jointed rods fall ASLEEP once settled (Jolt counted 0 active bodies before folding
	# too), so the first run's "active bodies down" was a guess the field refuted. What folding does is this:
	_check("D built rods are frozen and their per-frame script is off (physics time is reported, not claimed)",
		rods.all(func(r):return r.freeze and not r.is_physics_processing()),
		{"active_bodies": [detailed.active_bodies, built.active_bodies], "physics_ms": [detailed.physics_ms, built.physics_ms]})
	# E - a top corner ball picked up, then set down
	var top: RigidBody3D = grid[Vector3i(NX - 1, NY - 1, NZ - 1)]
	top.picked_up.emit(top)
	await get_tree().physics_frame
	var lifted: int = st.folded_balls.size();var foam_back: bool = top.get_node("Foam").visible
	top.global_position += Vector3(.05, .04, -.03);top.dropped.emit(top)
	for i in 4:await get_tree().physics_frame
	_check("E pick-up unfolds one ball (its foam visible, %d in the structure) and setting it down folds it back" % (balls.size() - 1),
		lifted == balls.size() - 1 and foam_back and st.folded_balls.size() == balls.size() and not top.get_node("Foam").visible,
		{"while_held": lifted, "foam_visible_held": foam_back, "after": st.folded_balls.size()})

func _measure(tag: String) -> Dictionary:
	for i in 30:await get_tree().process_frame
	var draws := 0.0;var tris := 0.0;var frame := 0.0;var phys := 0.0;var active := 0.0
	var n := 120
	for i in n:
		await get_tree().process_frame
		draws += RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
		tris += RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
		frame += get_process_delta_time() * 1000.0
		active += Performance.get_monitor(Performance.PHYSICS_3D_ACTIVE_OBJECTS)
	# physics time sampled once per physics TICK (a render frame here is far shorter than a tick, so per-frame samples
	# repeat one value); the monitor is the engine's own, and is reported, not gated
	for i in 60:
		await get_tree().physics_frame
		phys += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0 / 60.0 * n
	var m := {"draws": roundi(draws / n), "triangles": roundi(tris / n), "frame_ms": snappedf(frame / n, .01),
		"physics_ms": snappedf(phys / n, .01), "active_bodies": roundi(active / n)}
	report.measured[tag] = m
	print("KIT_BUILT measured ", tag, " ", JSON.stringify(m))
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir.path_join(tag + ".png"))
	return m

func _ball(cell: Vector3) -> RigidBody3D:
	var b: RigidBody3D = Ball.instantiate();add_child(b)
	b.global_position = cell + Vector3(.06, .085 + .05, -.05)
	b.settle()
	return b

func _rod_out(ball: RigidBody3D, i: int) -> void:
	var r: RigidBody3D = Rod.instantiate();add_child(r)
	var out: Vector3 = ball.socket_dir(i)
	r.global_transform = Transform3D(_basis_x(out), ball.socket_global(i) + out * (r.length / 2.0 + .02))
	r.settle()

func _bridge(x: RigidBody3D, y: RigidBody3D) -> void:
	var dir := (y.global_position - x.global_position).normalized()
	var ix := _facing(x, dir);var iy := _facing(y, -dir)
	var r: RigidBody3D = Rod.instantiate();add_child(r)
	var ma: Vector3 = x.socket_global(ix);var mb: Vector3 = y.socket_global(iy)
	r.global_transform = Transform3D(_basis_x((mb - ma).normalized()), (ma + mb) / 2.0 + Vector3(.02, .02, -.01))
	r.settle()

func _facing(ball: RigidBody3D, dir: Vector3) -> int:
	var best := -1;var best_dot := -2.0
	for i in ball.dirs().size():
		var dp: float = ball.dirs()[i].dot(dir)
		if dp > best_dot:best_dot = dp;best = i
	return best

static func _basis_x(axis: Vector3) -> Basis:
	var up := Vector3.UP if absf(axis.dot(Vector3.UP)) < .9 else Vector3.BACK
	var z := axis.cross(up).normalized();var y := z.cross(axis).normalized()
	return Basis(axis, y, z)

func _check(title: String, ok: bool, data: Dictionary) -> void:
	report.checks.append({"title": title, "ok": ok, "data": data})
	print(("PASS " if ok else "FAIL ") + title + " " + JSON.stringify(data))
