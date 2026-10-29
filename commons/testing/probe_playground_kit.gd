extends Node3D
## The playground kit on a bench, with numbers: (A) a ball let go off-grid snaps to the nearest grid point,
## squared and frozen; (B) a one-unit rod let go with an end near that ball's +X socket snaps in and HOLDS
## there, cantilevered off the frozen ball; (C) a second ball snaps to the next grid point and a rod let go
## between the two bridges both mouths exactly (one unit = grid minus two hubs); (D) a rod let go in the air
## with no ball near FALLS; (E) picked up again, the rod unsnaps and frees its sockets, and a picked-up ball
## is a body until it is let go on the next point; (F) a rod falling onto the floor at 4 m/s is a hit with
## the thwop; (G) the inventory makes a ball for 'point' and a two-unit rod for 'rod'; (H) a ball let go in
## the air with nothing under it falls; (I) a ball on a rod up from a grounded ball holds, and falls when the
## ground ball is taken away - the support graph. Writes
## ada_run/playground_kit/{kit.png, report.json}.
## Run: godot --path . --xr-mode off --resolution 1280x800 res://commons/testing/probe_playground_kit.tscn

const Ball = preload("res://commons/artifacts/playground_kit/playground_ball.tscn")
const Rod = preload("res://commons/artifacts/playground_kit/playground_rod.tscn")
const InventoryHandLib = preload("res://commons/player/inventory_hand.gd")

func _ready() -> void:
	var out_dir := ProjectSettings.globalize_path("res://ada_run/playground_kit");DirAccess.make_dir_recursive_absolute(out_dir)
	var env := WorldEnvironment.new();var e := Environment.new();e.background_mode = Environment.BG_COLOR;e.background_color = Color("2a2c33")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR;e.ambient_light_color = Color("d8d2c8");e.ambient_light_energy = .75;env.environment = e;add_child(env)
	var sun := DirectionalLight3D.new();sun.rotation_degrees = Vector3(-40, 30, 0);sun.light_energy = 1.1;add_child(sun)
	var floor_b := StaticBody3D.new();floor_b.collision_layer = 1;add_child(floor_b)
	var fs := CollisionShape3D.new();var fb := BoxShape3D.new();fb.size = Vector3(10, .1, 10);fs.shape = fb;fs.position.y = -.05;floor_b.add_child(fs)
	var fm := MeshInstance3D.new();var fbm := BoxMesh.new();fbm.size = Vector3(10, .1, 10);fm.mesh = fbm;fm.position.y = -.05
	var fmat := StandardMaterial3D.new();fmat.albedo_color = Color("8f8a84");fm.material_override = fmat;floor_b.add_child(fm)
	var cam := Camera3D.new();cam.transform = Transform3D(Basis(), Vector3(1.6, 1.4, 2.4)).looking_at(Vector3(.6, .3, -.4));cam.fov = 50;add_child(cam);cam.current = true
	var report := {"checks": []}
	# A — a ball let go off-grid snaps to the grid, squared and frozen
	var a: RigidBody3D = Ball.instantiate();add_child(a);a.global_transform = Transform3D(Basis(Vector3.UP, .4), Vector3(.3, .4, .2))
	await get_tree().physics_frame
	var at: Vector3 = a.settle();var hub: float = a.hub()
	_check(report, "A grid: a ball let go at (0.3, 0.4, 0.2) snapped to (0, hub, 0), squared, frozen", at.is_equal_approx(Vector3(0, hub, 0)) and a.global_position.is_equal_approx(at) and a.freeze and a.global_transform.basis.is_equal_approx(Basis()), {"at": _v(at), "hub": hub, "frozen": a.freeze})
	# B — a rod let go near the +X socket snaps in and holds there
	var r1: RigidBody3D = Rod.instantiate();add_child(r1)
	var mouth: Vector3 = a.socket_global(0)
	r1.global_transform = Transform3D(Basis(Vector3.UP, .08), mouth + Vector3(r1.length / 2.0 + .02, .03, .02))   # end 0 ~4 cm off the mouth, a little askew
	await get_tree().physics_frame
	var n1: int = r1.settle()
	var far0: Vector3 = r1.end_global(1)
	for i in 60:
		await get_tree().physics_frame
	_check(report, "B snap + hold: the rod snapped into the +X socket along +X (one unit = 0.83 m) and its far end held for 60 frames", n1 == 1 and r1.joints.size() == 1 and a.sockets[0] == r1 and is_equal_approx(r1.length, 1.0 - 2 * hub) and r1.end_global(1).distance_to(far0) < .01, {"ends": n1, "length": r1.length, "far_end_drift": r1.end_global(1).distance_to(far0)})
	# C — a second ball on the next grid point, a rod between them
	var b: RigidBody3D = Ball.instantiate();add_child(b);b.global_position = Vector3(.1, .5, -1.2)
	await get_tree().physics_frame
	var bt: Vector3 = b.settle()
	var r2: RigidBody3D = Rod.instantiate();add_child(r2)
	var ma: Vector3 = a.socket_global(5);var mb: Vector3 = b.socket_global(4)   # a's -Z mouth, b's +Z mouth
	r2.global_transform = Transform3D(Basis(Vector3.UP, PI / 2 + .25), (ma + mb) / 2.0 + Vector3(.03, .05, 0))
	await get_tree().physics_frame
	var n2: int = r2.settle()
	_check(report, "C bridge: the second ball snapped one grid on, and a rod let go between them took both mouths exactly", bt.is_equal_approx(Vector3(0, hub, -1)) and absf(ma.distance_to(mb) - .83) < .001 and n2 == 2 and r2.joints.size() == 2 and r2.end_global(0).distance_to(ma) < .005 and r2.end_global(1).distance_to(mb) < .005, {"b_at": _v(bt), "mouths_apart": ma.distance_to(mb), "ends": n2})
	# D — a rod with no ball near falls
	var r4: RigidBody3D = Rod.instantiate();add_child(r4);r4.global_position = Vector3(2.5, 1.0, 1.0)
	await get_tree().physics_frame
	var n4: int = r4.settle();var y4: float = r4.global_position.y
	for i in 30:
		await get_tree().physics_frame
	_check(report, "D falls: a rod let go in the air with no ball near snapped nothing and fell", n4 == 0 and r4.global_position.y < y4 - .1, {"ends": n4, "fell": y4 - r4.global_position.y})
	# E — picked up again: the rod unsnaps; the ball is a body until let go on the next point
	r2.unsnap()
	a.picked_up.emit(a)   # the hand's signal, as XR Tools sends it
	var loose: bool = not a.freeze
	a.global_position = Vector3(1.4, .5, .3);a.dropped.emit(a)   # let go off-grid again
	for i in 3:
		await get_tree().physics_frame
	_check(report, "E again: unsnap frees the sockets; a picked-up ball is a body, and let go it is on the next grid point", r2.joints.is_empty() and a.sockets[5] == null and b.sockets[4] == null and loose and a.freeze and a.global_position.is_equal_approx(Vector3(1, hub, 0)), {"loose_when_held": loose, "a_now": _v(a.global_position)})
	# H — SUPPORT: a ball let go in the air with nothing under it snaps to row 1, is unsupported, and falls
	var h: RigidBody3D = Ball.instantiate();add_child(h);h.global_position = Vector3(3, 1.0, 1)
	await get_tree().physics_frame
	var ht: Vector3 = h.settle()
	var h_held: bool = h.freeze
	for i in 40:
		await get_tree().physics_frame
	_check(report, "H support: a ball let go at 1 m with nothing under it snapped to row 1 then fell (unsupported)", ht.is_equal_approx(Vector3(3, 1 + hub, 1)) and not h_held and not h.supported and h.global_position.y < .5, {"snapped_to": _v(ht), "held": h_held, "y_now": h.global_position.y})
	# I — a tower: a rod up from the grounded ball, a ball on top is supported; take the ground ball away and it falls
	var g: RigidBody3D = Ball.instantiate();add_child(g);g.global_position = Vector3(-2, .2, -2)
	await get_tree().physics_frame
	g.settle()
	var up: RigidBody3D = Rod.instantiate();add_child(up)
	var top_mouth: Vector3 = g.socket_global(2)   # +Y
	up.global_transform = Transform3D(Basis(Vector3.BACK, PI / 2 - .05), top_mouth + Vector3(.02, up.length / 2.0 + .02, 0))   # standing, end 0 near the mouth
	await get_tree().physics_frame
	var nu: int = up.settle()
	var t: RigidBody3D = Ball.instantiate();add_child(t);t.global_position = Vector3(-2.1, 1.0 + hub + .1, -1.9)
	await get_tree().physics_frame
	var tt: Vector3 = t.settle()
	await get_tree().physics_frame
	var t_sup: bool = t.supported and t.freeze
	g.queue_free()   # the ground ball taken away
	for i in 30:
		await get_tree().physics_frame
	_check(report, "I tower: a ball on a rod up from a grounded ball is supported and holds at row 1; the ground ball taken away, it falls", nu == 1 and tt.is_equal_approx(Vector3(-2, 1 + hub, -2)) and t_sup and not t.supported and t.global_position.y < 1 + hub - .1, {"rod_ends": nu, "top_at": _v(tt), "top_supported_before": t_sup, "top_y_after": t.global_position.y})
	# F — the stick: a rod falling onto the floor is a hit with a thwop
	var r3: RigidBody3D = Rod.instantiate();add_child(r3);r3.global_position = Vector3(2.2, 1.2, -1.0)
	var hits: Array = []
	r3.hit.connect(func(what, speed): hits.append({"what": str(what.name), "speed": speed}))
	await get_tree().physics_frame
	r3.linear_velocity = Vector3(0, -4, 0)
	for i in 50:
		await get_tree().physics_frame
	var thwop: AudioStreamWAV = r3.get_node("Thwop").stream
	_check(report, "F hit: the falling rod hit the floor above hit_speed and the thwop (made in code) has its samples", hits.size() >= 1 and hits[0].speed > 1.2 and thwop.data.size() == int(22050 * .14) * 2, {"hits": hits, "samples": thwop.data.size() / 2})
	# G — the inventory makes them
	var hand: Node = InventoryHandLib.new();add_child(hand)
	hand.set_current("point");var pb: Node3D = hand.spawn_at(Transform3D(Basis(), Vector3(-1.5, .6, 1.0)))
	hand.set_current("rod");hand.set_knob("units", "2");var pr: Node3D = hand.spawn_at(Transform3D(Basis(), Vector3(-1.5, 1.0, 1.6)))
	_check(report, "G inventory: 'point' makes a ball and 'rod' a rod whose Length knob (two units) made it 1.83 m", pb != null and pb.has_method("socket_global") and pr != null and pr.has_method("end_global") and is_equal_approx(pr.length, 2.0 - 2 * hub), {"ball": pb.name if pb else null, "rod": pr.name if pr else null, "length": pr.length if pr else null})
	for i in 40:
		await get_tree().physics_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir.path_join("kit.png"))
	var passed := 0
	for ch in report.checks:
		if ch.ok:passed += 1
	report["passed"] = passed;report["of"] = report.checks.size()
	var o := FileAccess.open(out_dir.path_join("report.json"), FileAccess.WRITE);o.store_string(JSON.stringify(report, "  "));o.close()
	print("[probe_playground_kit] %d/%d" % [passed, report.checks.size()])
	get_tree().quit(0 if passed == report.checks.size() else 1)

func _check(report: Dictionary, what: String, ok: bool, data: Dictionary) -> void:
	report.checks.append({"what": what, "ok": ok, "data": data})
	print("[probe_playground_kit] %s  %s" % ["ok  " if ok else "FAIL", what])

func _v(v: Vector3) -> Array:return [snappedf(v.x, .001), snappedf(v.y, .001), snappedf(v.z, .001)]
