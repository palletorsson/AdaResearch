extends Node3D
## The kit drawn as multimeshes, measured (Palle, 2026-11-06: "if we create a really large playground we want the
## geometry as simple as possible", then "these should all be multimesh"). A 10 x 10 x 4 field of kit balls and rods
## is built by the kit's own rules (rods up, balls on their ends, rods across), then measured over 120 frames in three
## states: OWN MESHES (kit_structure.gd disabled - every piece draws itself, as before), MULTIMESH DETAILED (every
## piece copied into the kit's shared foam / socket / core / sleeve multimeshes) and MULTIMESH BUILT (balls with
## `fold` on, settled pieces in the simple look). Checks:
## (A) the field stands: every ball supported, every rod in two sockets; (B) NEGATIVE: disabled, no renderer exists and
## every piece's own meshes are visible; (C) multimesh detailed: every piece's own meshes hidden, one foam per ball,
## its six sockets, one core and one sleeve per rod, and at most 12 draws; (D) built: every ball and rod folded,
## triangles down again, draws still at most 12, built rods frozen with their script off; (E) a ball picked up leaves
## the built look (399 built) and its detailed foam instance FOLLOWS it when it moves; set down, 400 again.
## Writes ada_run/kit_built/{own_meshes.png, multimesh_detailed.png, multimesh_built.png, report.json}.
## Run: godot --path <abs> --xr-mode off --resolution 1280x800 --rendering-method mobile res://commons/testing/probe_kit_built.tscn

const Ball = preload("res://commons/artifacts/playground_kit/playground_ball.tscn")
const Rod = preload("res://commons/artifacts/playground_kit/playground_rod.tscn")
const BallLib = preload("res://commons/artifacts/playground_kit/playground_ball.gd")
const Structure = preload("res://commons/artifacts/playground_kit/kit_structure.gd")
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
	Structure.enabled = false   # the BEFORE: every piece draws its own meshes
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
	var own := await _measure("own_meshes")
	_check("B negative: with the renderer disabled no PlaygroundStructure exists and every piece shows its own meshes",
		get_node_or_null("PlaygroundStructure") == null and balls.all(func(x):return x.get_node("Foam").visible), {})
	# the kit as multimeshes: every piece registers, as it does from its own _build in the game
	Structure.enabled = true
	for p in balls + rods:Structure.track(p)
	for i in 3:await get_tree().process_frame
	var st: Node = get_node_or_null("PlaygroundStructure")
	var detailed := await _measure("multimesh_detailed")
	var counts := {}
	if st:
		for c in st.get_children():counts[str(c.name)] = (c as MultiMeshInstance3D).multimesh.instance_count
	var hidden: bool = (balls + rods).all(func(x):return x.get_children().all(func(c):return not (c is MeshInstance3D) or not c.visible))
	_check("C multimesh detailed: own meshes hidden; 400 foam, 2400 sockets, 1020 cores and sleeves; at most 12 draws",
		st != null and hidden and counts.get("Foam", -1) == balls.size() and counts.get("Socket", -1) == 6 * balls.size() and counts.get("Core", -1) == rods.size() and counts.get("Sleeve", -1) == rods.size() and detailed.draws <= 12,
		{"instances": counts, "own_meshes_hidden": hidden, "draws": [own.draws, detailed.draws], "triangles": [own.triangles, detailed.triangles]})
	# the built look: fold every ball and read the graph again
	for x in balls:x.fold = true
	BallLib.reevaluate(get_tree())
	for i in 3:await get_tree().process_frame
	var built := await _measure("multimesh_built")
	var nb: int = st.folded_balls.size() if st else -1;var nr: int = st.folded_rods.size() if st else -1
	_check("D built: every ball and rod folded, triangles down again, draws at most 12, built rods frozen with their script off",
		nb == balls.size() and nr == rods.size() and built.triangles < detailed.triangles and built.draws <= 12 and rods.all(func(r):return r.freeze and not r.is_physics_processing()),
		{"folded_balls": nb, "folded_rods": nr, "draws": [own.draws, detailed.draws, built.draws], "triangles": [own.triangles, detailed.triangles, built.triangles],
		"physics_ms": [own.physics_ms, detailed.physics_ms, built.physics_ms]})
	# E - a top corner ball picked up and carried, then set down
	var top: RigidBody3D = grid[Vector3i(NX - 1, NY - 1, NZ - 1)]
	top.picked_up.emit(top)
	for i in 3:await get_tree().process_frame
	var lifted: int = st.folded_balls.size()
	top.global_position += Vector3(0, .5, 0)   # carried
	for i in 2:await get_tree().process_frame
	var foam_mm: MultiMesh = st.get_node("Foam").multimesh;var follows := false
	for i in foam_mm.instance_count:
		if foam_mm.get_instance_transform(i).origin.distance_to(top.global_position) < .001:follows = true
	top.global_position = Vector3(NX - 1, NY - 1, NZ - 1) + Vector3(.05, .085 + .04, -.03);top.dropped.emit(top)
	for i in 4:await get_tree().physics_frame
	for i in 3:await get_tree().process_frame
	_check("E picked up it leaves the built look (%d built) and its detailed foam follows it 0.5 m up; set down, %d again" % [balls.size() - 1, balls.size()],
		lifted == balls.size() - 1 and follows and st.folded_balls.size() == balls.size(),
		{"while_held": lifted, "foam_follows": follows, "after": st.folded_balls.size()})

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
