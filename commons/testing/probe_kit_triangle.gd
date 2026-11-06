extends Node3D
## The Triangle stage of the playground kit on a bench (Palle, 2026-11-06), with numbers:
## (A) NEGATIVE: a ball without the stage keeps six sockets and makes no PlaygroundFaces node - a floor without the
##     stage is untouched; (B) with the stage a ball has eighteen sockets, and a brace (one diagonal) is sqrt(2) - 2 hubs
##     long and takes the diagonal mouths of two balls exactly; (C) a square standing on two floor balls - a floor
##     rod, two uprights and a top rod - has 3 free motions (the shear and each top ball sideways), both top balls flexible,
##     one face, drawn flexible; (D) a brace across it takes the shear: 2 free motions, a triangle face, still flexible
##     (it tips about its floor edge); (E) a brace from each top ball down to a floor ball behind holds it from the
##     side: 0 free motions, every ball fixed, the label says rigid; (F) the free motion is DRAWN, not done: while
##     flexible the top ball's foam moved off its rest and its body did not; once rigid the foam is back at rest;
##     (G) a point in space needs three rods: an apex on one upright has 2 free motions, on three rods none.
## Writes ada_run/kit_triangle/{flexible.png, rigid.png, report.json}.
## Run: godot --path . --xr-mode off --resolution 1280x800 res://commons/testing/probe_kit_triangle.tscn

const Ball = preload("res://commons/artifacts/playground_kit/playground_ball.tscn")
const Rod = preload("res://commons/artifacts/playground_kit/playground_rod.tscn")
const STAGE := {"diagonals": true, "rigidity": "bars"}

var report := {"checks": []}
var out_dir := ""

func _ready() -> void:
	out_dir = ProjectSettings.globalize_path("res://ada_run/kit_triangle");DirAccess.make_dir_recursive_absolute(out_dir)
	var env := WorldEnvironment.new();var e := Environment.new();e.background_mode = Environment.BG_COLOR;e.background_color = Color("2a2c33")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR;e.ambient_light_color = Color("d8d2c8");e.ambient_light_energy = .75;env.environment = e;add_child(env)
	var sun := DirectionalLight3D.new();sun.rotation_degrees = Vector3(-40, 30, 0);sun.light_energy = 1.1;add_child(sun)
	var floor_b := StaticBody3D.new();floor_b.collision_layer = 1;add_child(floor_b)
	var fs := CollisionShape3D.new();var fb := BoxShape3D.new();fb.size = Vector3(16, .1, 16);fs.shape = fb;fs.position.y = -.05;floor_b.add_child(fs)
	var fm := MeshInstance3D.new();var fbm := BoxMesh.new();fbm.size = Vector3(16, .1, 16);fm.mesh = fbm;fm.position.y = -.05
	var fmat := StandardMaterial3D.new();fmat.albedo_color = Color("8f8a84");fm.material_override = fmat;floor_b.add_child(fm)
	var cam := Camera3D.new();cam.transform = Transform3D(Basis(), Vector3(2.6, 2.1, 3.4)).looking_at(Vector3(1.3, .55, .3));cam.fov = 55;add_child(cam);cam.current = true
	await _run()
	var passed: int = report.checks.filter(func(c):return c.ok).size()
	report["passed"] = passed;report["total"] = report.checks.size()
	var f := FileAccess.open(out_dir.path_join("report.json"), FileAccess.WRITE);f.store_string(JSON.stringify(report, "  "));f.close()
	print("KIT_TRIANGLE %d/%d" % [passed, report.checks.size()])
	get_tree().quit(0 if passed == report.checks.size() else 1)

func _run() -> void:
	# A - negative: no stage, no faces node, six sockets
	var plain: RigidBody3D = await _ball(Vector3(-4, 0, -4), {})
	var plain_rod: RigidBody3D = await _rod_out(plain, 2, false)
	var top_plain: RigidBody3D = await _ball(Vector3(-4, 1, -4), {})
	_check("A negative: a ball without the stage has 6 sockets, the tower holds as before, and no PlaygroundFaces node is made", plain.sockets.size() == 6 and top_plain.supported and get_node_or_null("PlaygroundFaces") == null and plain_rod.joints.size() == 2, {"sockets": plain.sockets.size(), "faces_node": get_node_or_null("PlaygroundFaces") != null})
	# B + C - the square standing on two floor balls
	var a: RigidBody3D = await _ball(Vector3(0, 0, 0))
	var b: RigidBody3D = await _ball(Vector3(1, 0, 0))
	await _bridge(a, b, false)   # the floor rod: without it the loop is closed by the floor, not by rods - no face
	await _rod_out(a, 2, false)
	var c: RigidBody3D = await _ball(Vector3(0, 1, 0))
	await _rod_out(c, 0, false)
	var d: RigidBody3D = await _ball(Vector3(1, 1, 0))
	var n_bd: int = await _bridge(b, d, false)
	var faces: Node = get_node_or_null("PlaygroundFaces")
	var p: Dictionary = _piece_of(faces, c)
	_check("C square: two uprights and a top rod on two floor balls - 3 free motions, both top balls flexible, one face", n_bd == 2 and d.supported and p.get("free_motions", -1) == 3 and c.flexible and d.flexible and not a.flexible and p.get("faces", []).size() == 1, {"free_motions": p.get("free_motions"), "faces": p.get("faces", []).size(), "label": _label(faces)})
	for i in 20:await get_tree().physics_frame
	var foam_moved: float = (c.get_node("Foam") as Node3D).position.length()
	var body_still: bool = c.global_position.is_equal_approx(Vector3(0, 1 + c.hub(), 0))
	# D - a brace across the square
	var brace: RigidBody3D = await _bridge_rod(a, d, true)
	_check("B brace: 18 sockets with the stage; a brace is sqrt(2) - 2 hubs long and took both diagonal mouths", a.sockets.size() == 18 and absf(brace.length - (sqrt(2.0) - 2 * a.hub())) < .001 and brace.joints.size() == 2 and brace.joints.all(func(j):return j.socket >= 6), {"length": brace.length, "sockets": a.sockets.size()})
	p = _piece_of(faces, c)
	_check("D braced: the shear is gone - 2 free motions left (it tips about its floor edge), a triangle face", p.get("free_motions", -1) == 2 and c.flexible and p.get("faces", []).any(func(f):return f.size() == 3), {"free_motions": p.get("free_motions"), "faces": p.get("faces", []).map(func(f):return f.size()), "label": _label(faces)})
	for i in 20:await get_tree().physics_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir.path_join("flexible.png"))
	# E - held from the side: a brace from each top ball down to a floor ball behind
	var e0: RigidBody3D = await _ball(Vector3(0, 0, 1))
	var e1: RigidBody3D = await _ball(Vector3(1, 0, 1))
	await _bridge(c, e0, true)
	await _bridge(d, e1, true)
	p = _piece_of(faces, c)
	_check("E buttressed: 0 free motions, every ball fixed, the label says rigid", p.get("free_motions", -1) == 0 and not c.flexible and not d.flexible and _label(faces).contains("rigid"), {"free_motions": p.get("free_motions"), "label": _label(faces)})
	for i in 6:await get_tree().physics_frame
	var foam_rest: float = (c.get_node("Foam") as Node3D).position.length()
	_check("F drawn not done: while flexible the top ball's foam moved off rest and its body stayed on its grid point; once rigid the foam is back", foam_moved > .002 and body_still and foam_rest < 1e-5 and c.freeze, {"foam_moved_m": foam_moved, "foam_now_m": foam_rest, "body_on_grid": body_still})
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir.path_join("rigid.png"))
	# G - a point in space needs three rods
	var g0: RigidBody3D = await _ball(Vector3(4, 0, 0))
	var g1: RigidBody3D = await _ball(Vector3(5, 0, 0))
	var g2: RigidBody3D = await _ball(Vector3(4, 0, 1))
	await _rod_out(g0, 2, false)
	var apex: RigidBody3D = await _ball(Vector3(4, 1, 0))
	var one: int = _piece_of(faces, apex).get("free_motions", -1)
	await _bridge(g1, apex, true)
	var two: int = _piece_of(faces, apex).get("free_motions", -1)
	await _bridge(g2, apex, true)
	var three: int = _piece_of(faces, apex).get("free_motions", -1)
	_check("G three rods fix a point: on one upright 2 free motions, on two 1, on three none", one == 2 and two == 1 and three == 0 and not apex.flexible, {"one_rod": one, "two_rods": two, "three_rods": three})

func _ball(cell: Vector3, cfg: Dictionary = STAGE) -> RigidBody3D:
	var b: RigidBody3D = Ball.instantiate();b.apply_grid_config(cfg);add_child(b)
	b.global_position = cell + Vector3(.07, .1 + .085, -.06)   # a little off its point, as a hand lets go
	await get_tree().physics_frame
	b.settle()
	return b

## A rod (or brace) let go with end 0 at socket i's mouth, pointing out of it.
func _rod_out(ball: RigidBody3D, i: int, diag: bool) -> RigidBody3D:
	var r: RigidBody3D = Rod.instantiate();r.apply_grid_config({"diagonal": diag, "units": 1});add_child(r)
	var out: Vector3 = ball.socket_dir(i)
	r.global_transform = Transform3D(_basis_x(out), ball.socket_global(i) + out * (r.length / 2.0 + .02) + Vector3(.01, .01, 0))
	await get_tree().physics_frame
	r.settle()
	return r

func _bridge(x: RigidBody3D, y: RigidBody3D, diag: bool) -> int:
	var r: RigidBody3D = await _bridge_rod(x, y, diag)
	return r.joints.size()

## A rod (or brace) let go between the two mouths that face each other.
func _bridge_rod(x: RigidBody3D, y: RigidBody3D, diag: bool) -> RigidBody3D:
	var dir := (y.global_position - x.global_position).normalized()
	var ix := _facing(x, dir);var iy := _facing(y, -dir)
	var r: RigidBody3D = Rod.instantiate();r.apply_grid_config({"diagonal": diag, "units": 1});add_child(r)
	var ma: Vector3 = x.socket_global(ix);var mb: Vector3 = y.socket_global(iy)
	r.global_transform = Transform3D(_basis_x((mb - ma).normalized()), (ma + mb) / 2.0 + Vector3(.02, .02, -.01))
	await get_tree().physics_frame
	r.settle()
	return r

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

func _piece_of(faces: Node, ball: Node) -> Dictionary:
	if faces == null:return {}
	for p in faces.pieces:
		if ball in p.balls:return p
	return {}

func _label(faces: Node) -> String:
	if faces == null:return ""
	var texts: Array = []
	for c in faces.get_children():
		if c is Label3D and not c.is_queued_for_deletion():texts.append(c.text)
	return " | ".join(texts)

func _check(title: String, ok: bool, data: Dictionary) -> void:
	report.checks.append({"title": title, "ok": ok, "data": data})
	print(("PASS " if ok else "FAIL ") + title + " " + JSON.stringify(data))
