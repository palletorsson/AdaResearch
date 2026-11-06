extends Node3D
## The load test on a bench (Palle, 2026-11-06: build in edit mode, then "a separate test lets physics loose"). The floor
## stands at -30 m like the Void's floor 5, a stand-in Void says floor 5 (the Triangle stage), and everything goes through
## the wand: the node editor builds, the hand's TEST tool tests.
## (A) an unbraced square (floor rod, two uprights, a top rod) tested: its top balls are loose and SAG - each drops more
## than 20 cm; (B) the test fired again undoes it: every ball and rod back exactly on its node, frozen, every joint fixed,
## nothing `testing`; (C) a square braced in its own plane tested: it TIPS out of its plane (a top ball moves more than
## 15 cm sideways); (D) a corner tetrahedron (an upright and two braces to a point) tested: "holds", nothing moves;
## (E) NEGATIVE: the test fired at the floor is refused and changes nothing.
## Writes ada_run/kit_load_test/{sagged.png, report.json}.
## Run: godot --path <abs> --xr-mode off --resolution 1280x800 res://commons/testing/probe_kit_load_test.tscn

const InventoryHandLib = preload("res://commons/player/inventory_hand.gd")
const WandLib = preload("res://commons/player/inventory_wand.gd")
const FLOOR_Y := -30.0

var report := {"checks": []}
var hand: Node
var wand: Node3D
var aim: Camera3D
var ed: Node3D
var out_dir := ""

func _ready() -> void:
	out_dir = ProjectSettings.globalize_path("res://ada_run/kit_load_test");DirAccess.make_dir_recursive_absolute(out_dir)
	var env := WorldEnvironment.new();var e := Environment.new();e.background_mode = Environment.BG_COLOR;e.background_color = Color("2a2c33")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR;e.ambient_light_color = Color("d8d2c8");e.ambient_light_energy = .75;env.environment = e;add_child(env)
	var sun := DirectionalLight3D.new();sun.rotation_degrees = Vector3(-40, 30, 0);add_child(sun)
	var floor_b := StaticBody3D.new();floor_b.position.y = FLOOR_Y;add_child(floor_b)
	var fs := CollisionShape3D.new();var fb := BoxShape3D.new();fb.size = Vector3(30, .2, 30);fs.shape = fb;fs.position.y = -.1;floor_b.add_child(fs)
	var fm := MeshInstance3D.new();var fbm := BoxMesh.new();fbm.size = Vector3(30, .2, 30);fm.mesh = fbm;fm.position.y = -.1
	var fmat := StandardMaterial3D.new();fmat.albedo_color = Color("8f8a84");fm.material_override = fmat;floor_b.add_child(fm)
	var src := GDScript.new();src.source_code = "extends Node\nvar checkpoint := 5\n";src.reload()
	var fake := Node.new();fake.set_script(src);fake.add_to_group("void_game");add_child(fake)
	hand = InventoryHandLib.new();hand.name = "InventoryHand";add_child(hand)
	aim = Camera3D.new();aim.fov = 60;add_child(aim);aim.current = true
	wand = WandLib.new();wand.name = "Wand";add_child(wand);wand.setup(hand, aim)
	ed = wand.editor
	await get_tree().process_frame
	await _run()
	var passed: int = report.checks.filter(func(c):return c.ok).size()
	report["passed"] = passed;report["total"] = report.checks.size()
	var f := FileAccess.open(out_dir.path_join("report.json"), FileAccess.WRITE);f.store_string(JSON.stringify(report, "  "));f.close()
	get_tree().quit(0 if passed == report.checks.size() else 1)

func N(x: int, y: int, z: int) -> Vector3:
	return ed.world(Vector3i(x, y, z))

## Fire the trigger at a world point, from an eye placed `from` relative to it (default: a few metres off, above).
func _fire(p: Vector3, from := Vector3(1.6, 2.2, 3.0)) -> String:
	aim.global_position = p + from;aim.look_at(p);wand.update(true, .016)
	var said: String = wand.press();wand.release()
	for i in 2:await get_tree().physics_frame
	return said

func _rod(a: Vector3i, b: Vector3i, item := "rod") -> void:
	hand.set_current(item)
	await _fire(N(a.x, a.y, a.z));await _fire(N(b.x, b.y, b.z))

func _run() -> void:
	hand.set_current("point")
	await _fire(Vector3(0, FLOOR_Y, 0))   # the edit space: corner node at (-3, -30, -3)
	# the three structures
	await _rod(Vector3i(0, 0, 1), Vector3i(1, 0, 1));await _rod(Vector3i(0, 0, 1), Vector3i(0, 1, 1))
	await _rod(Vector3i(1, 0, 1), Vector3i(1, 1, 1));await _rod(Vector3i(0, 1, 1), Vector3i(1, 1, 1))
	await _rod(Vector3i(0, 0, 4), Vector3i(1, 0, 4));await _rod(Vector3i(0, 0, 4), Vector3i(0, 1, 4))
	await _rod(Vector3i(1, 0, 4), Vector3i(1, 1, 4));await _rod(Vector3i(0, 1, 4), Vector3i(1, 1, 4))
	await _rod(Vector3i(0, 0, 4), Vector3i(1, 1, 4), "brace")
	await _rod(Vector3i(4, 0, 1), Vector3i(4, 1, 1));await _rod(Vector3i(5, 0, 1), Vector3i(4, 1, 1), "brace")
	await _rod(Vector3i(4, 0, 2), Vector3i(4, 1, 1), "brace")
	for i in 10:await get_tree().physics_frame
	var top: Node3D = ed.ball_at(Vector3i(0, 1, 1));var top2: Node3D = ed.ball_at(Vector3i(1, 1, 1))
	var built_ok: bool = top != null and top2 != null and top.supported and top2.supported
	hand.set_current("test")
	# E - negative first: the floor
	var bodies_before := _snapshot()
	var e_said := await _fire(Vector3(-2.5, FLOOR_Y, 2.5), Vector3(0, 2.0, .02))   # straight down onto clear floor
	_check("E negative: the test fired at the floor is refused and changes nothing", e_said == "refused" and _snapshot() == bodies_before, {"said": e_said})
	# A - the unbraced square sags
	var home1: Vector3 = top.global_position;var home2: Vector3 = top2.global_position
	var a_said := await _fire(home1, Vector3(0, 2.0, .02))
	for i in 150:await get_tree().physics_frame
	var drop1: float = home1.y - top.global_position.y;var drop2: float = home2.y - top2.global_position.y
	_check("A the unbraced square tested: its top balls are loose and sag, each more than 20 cm", built_ok and a_said == "test_started" and drop1 > .2 and drop2 > .2 and top.testing,
		{"said": a_said, "drop_m": [snappedf(drop1, .001), snappedf(drop2, .001)], "built": built_ok})
	await RenderingServer.frame_post_draw
	aim.global_position = Vector3(2.5, FLOOR_Y + 2.4, 4.5);aim.look_at(Vector3(-1.5, FLOOR_Y + .6, -1));wand.update(true, .016)
	for i in 2:await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir.path_join("sagged.png"))
	# B - fired again: undone (aim at where the top ball is now)
	var b_said := await _fire(top.global_position, Vector3(0, 2.0, .02))
	if b_said != "test_reset":b_said += "|" + await _fire(top2.global_position, Vector3(0, 2.0, .02))
	for i in 4:await get_tree().physics_frame
	var rods1: Array = get_tree().get_nodes_in_group("playground_rods").filter(func(r):return r.joints.any(func(j):return j.ball == top or j.ball == top2))
	var fixed := rods1.all(func(r):return r.joints.all(func(j):return bool(j.joint.get("angular_limit_x/enabled")) and bool(j.joint.get("angular_limit_y/enabled")) and bool(j.joint.get("angular_limit_z/enabled"))))
	_check("B fired again: undone - the balls back exactly on their nodes, frozen, every joint of its rods fixed, nothing testing",
		b_said.contains("test_reset") and top.global_position.is_equal_approx(home1) and top2.global_position.is_equal_approx(home2) and top.freeze and top2.freeze and fixed and not top.testing and not top2.testing,
		{"said": b_said, "top_at": top.global_position, "home": home1, "fixed": fixed, "rods": rods1.size()})
	# C - the square braced in its own plane tips over sideways
	var t3: Node3D = ed.ball_at(Vector3i(0, 1, 4));var h3: Vector3 = t3.global_position
	var c_said := await _fire(h3, Vector3(0, 2.0, .02))
	for i in 180:await get_tree().physics_frame
	var side: float = Vector2(t3.global_position.x - h3.x, t3.global_position.z - h3.z).length()
	_check("C the square braced in its own plane tested: it tips out of its plane, a top ball moves more than 15 cm sideways", c_said == "test_started" and side > .15,
		{"said": c_said, "sideways_m": snappedf(side, .001), "now": t3.global_position})
	# D - the corner tetrahedron holds
	var apex: Node3D = ed.ball_at(Vector3i(4, 1, 1));var ha: Vector3 = apex.global_position
	var d_said := await _fire(ha, Vector3(0, 2.0, .02))
	for i in 60:await get_tree().physics_frame
	_check("D the corner tetrahedron (an upright and two braces to one point) tested: it holds, nothing moves",
		d_said == "test_holds" and apex.global_position.is_equal_approx(ha) and apex.freeze and not apex.testing, {"said": d_said, "notice": hand.notice})

## Every kit body's position, rounded, to tell whether anything moved.
func _snapshot() -> Array:
	var out: Array = []
	for n in get_tree().get_nodes_in_group("playground_balls") + get_tree().get_nodes_in_group("playground_rods"):
		out.append([snappedf(n.global_position.x, .001), snappedf(n.global_position.y, .001), snappedf(n.global_position.z, .001)])
	return out

func _check(title: String, ok: bool, data: Dictionary) -> void:
	report.checks.append({"title": title, "ok": ok, "data": data})
	print(("PASS " if ok else "FAIL ") + title + " " + JSON.stringify(data))
