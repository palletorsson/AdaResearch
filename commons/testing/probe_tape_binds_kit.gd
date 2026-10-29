extends Node3D
## The tape binds the playground kit: (A) a strip from a ball to a rod lying beside it (not in a socket) makes
## a binding, and lifting the ball lifts the rod; (B) a strip from a ball to the floor holds the ball up off
## the floor; (C) freeing the strip frees the rod again; (D) the tape item's bind knob reaches the roll the hand
## makes. Strips are laid as the roll lays them (Strip.anchor on a hit, draw_between, bind_surfaces), since a
## probe has no hand to press the roll's trigger. Writes ada_run/tape_binds/{bind.png, report.json}.
## Run: godot --path . --xr-mode off --resolution 1280x800 res://commons/testing/probe_tape_binds_kit.tscn

const Ball = preload("res://commons/artifacts/playground_kit/playground_ball.tscn")
const Rod = preload("res://commons/artifacts/playground_kit/playground_rod.tscn")
const Strip = preload("res://commons/artifacts/tape_roll/strip.gd")
const Design = preload("res://commons/artifacts/tape_roll/tape_design.gd")
const InventoryHandLib = preload("res://commons/player/inventory_hand.gd")

func _ready() -> void:
	var out_dir := ProjectSettings.globalize_path("res://ada_run/tape_binds");DirAccess.make_dir_recursive_absolute(out_dir)
	var env := WorldEnvironment.new();var e := Environment.new();e.background_mode = Environment.BG_COLOR;e.background_color = Color("2a2c33")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR;e.ambient_light_color = Color("d8d2c8");e.ambient_light_energy = .75;env.environment = e;add_child(env)
	var sun := DirectionalLight3D.new();sun.rotation_degrees = Vector3(-40, 30, 0);sun.light_energy = 1.1;add_child(sun)
	var floor_b := StaticBody3D.new();floor_b.name = "Floor";floor_b.collision_layer = 1;add_child(floor_b)
	var fs := CollisionShape3D.new();var fb := BoxShape3D.new();fb.size = Vector3(10, .1, 10);fs.shape = fb;fs.position.y = -.05;floor_b.add_child(fs)
	var fm := MeshInstance3D.new();var fbm := BoxMesh.new();fbm.size = Vector3(10, .1, 10);fm.mesh = fbm;fm.position.y = -.05
	var fmat := StandardMaterial3D.new();fmat.albedo_color = Color("8f8a84");fm.material_override = fmat;floor_b.add_child(fm)
	var cam := Camera3D.new();cam.transform = Transform3D(Basis(), Vector3(1.0, 1.2, 2.4)).looking_at(Vector3(.4, .35, 0));cam.fov = 50;add_child(cam);cam.current = true
	var tape := StandardMaterial3D.new();tape.albedo_color = Color("ea72ab");tape.roughness = .9
	var report := {"checks": []}
	# A — ball and rod on the floor, a strip across them
	var a: RigidBody3D = Ball.instantiate();add_child(a);a.global_position = Vector3(0, .09, 0)
	var r: RigidBody3D = Rod.instantiate();add_child(r);r.global_position = Vector3(.3, .03, -.5);r.global_basis = Basis(Vector3.UP, PI / 2)   # lying along z, 30 cm off
	for i in 60:
		await get_tree().physics_frame
	var s1 := _lay(a, a.global_position + Vector3(0, a.radius, 0), Vector3.UP, r, r.global_position + Vector3(0, .03, 0), Vector3.UP, tape)
	await get_tree().physics_frame
	var bound1: int = s1.get_children().filter(func(c):return c.has_method("connect_bodies")).size()
	var ry0: float = r.global_position.y
	a.apply_central_impulse(Vector3(0, 3.0, 0))
	for i in 14:
		await get_tree().physics_frame
	_check(report, "A ball to rod: the strip made a binding, and lifting the ball lifted the rod", bound1 == 1 and r.global_position.y > ry0 + .02, {"bindings": bound1, "rod_rise": r.global_position.y - ry0})
	for i in 60:
		await get_tree().physics_frame
	# B — a ball taped to the floor, held up by the tape
	var b: RigidBody3D = Ball.instantiate();add_child(b);b.global_position = Vector3(-1.0, .6, 0);b.freeze = true
	await get_tree().physics_frame
	var s2 := _lay(b, b.global_position + Vector3(0, -b.radius, 0), Vector3.DOWN, floor_b, Vector3(-1.0, 0, 0), Vector3.UP, tape)
	await get_tree().physics_frame
	b.freeze = false
	for i in 60:
		await get_tree().physics_frame
	_check(report, "B ball to floor: taped to the floor from 0.6 m up, the ball hangs there", absf(b.global_position.y - .6) < .03, {"y": b.global_position.y, "bindings": s2.get_children().filter(func(c):return c.has_method("connect_bodies")).size()})
	# C — the strip gone, the rod is free again
	s1.queue_free()
	await get_tree().physics_frame
	await get_tree().physics_frame
	var ry1: float = r.global_position.y
	a.apply_central_impulse(Vector3(0, 3.0, 0))
	for i in 14:
		await get_tree().physics_frame
	_check(report, "C strip freed: lifting the ball no longer lifts the rod", r.global_position.y < ry1 + .01, {"rod_rise": r.global_position.y - ry1})
	for i in 40:
		await get_tree().physics_frame
	# D — the tape item's bind knob reaches the roll
	var hand: Node = InventoryHandLib.new();add_child(hand)
	hand.set_current("tape");hand.set_knob("bind_objects", "false")
	var roll: Node3D = hand.spawn_at(Transform3D(Basis(), Vector3(1.4, .5, .6)))
	var off: bool = roll != null and not bool(roll.get("bind_objects"))
	hand.set_knob("bind_objects", "true");var roll2: Node3D = hand.spawn_at(Transform3D(Basis(), Vector3(1.6, .5, .6)))
	_check(report, "D knob: the tape item's Binds knob sets the roll's bind_objects (false, then true)", off and roll2 != null and bool(roll2.get("bind_objects")), {"first": roll.get("bind_objects") if roll else null, "second": roll2.get("bind_objects") if roll2 else null})
	for i in 10:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir.path_join("bind.png"))
	var passed := 0
	for ch in report.checks:
		if ch.ok:passed += 1
	report["passed"] = passed;report["of"] = report.checks.size()
	var o := FileAccess.open(out_dir.path_join("report.json"), FileAccess.WRITE);o.store_string(JSON.stringify(report, "  "));o.close()
	print("[probe_tape_binds_kit] %d/%d" % [passed, report.checks.size()])
	get_tree().quit(0 if passed == report.checks.size() else 1)

## A strip as the roll lays one between two surface hits, bound.
func _lay(body_a: Node3D, pa: Vector3, na: Vector3, body_b: Node3D, pb: Vector3, nb: Vector3, mat: Material) -> Node3D:
	var strip := Strip.new();strip.name = "TapeStrip";add_child(strip)
	strip.tape_width = .075;strip.material_override = mat
	strip.anchors = [Strip.anchor({"collider": body_a, "position": pa, "normal": na}), Strip.anchor({"collider": body_b, "position": pb, "normal": nb})]
	strip.paid_length = pa.distance_to(pb)
	strip.draw_between(pa, na, pb, nb)
	strip.bind_surfaces()
	return strip

func _check(report: Dictionary, what: String, ok: bool, data: Dictionary) -> void:
	report.checks.append({"what": what, "ok": ok, "data": data})
	print("[probe_tape_binds_kit] %s  %s" % ["ok  " if ok else "FAIL", what])
