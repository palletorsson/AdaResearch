extends Node3D
## The node editor on a bench (Palle, 2026-11-06: "the editor should work as a selector ... hitting the nodes with the
## fire button"). The bench's floor stands at -30 m, where the Void's floor 5 is, and a stand-in Void says floor 5, so
## the Triangle stage applies. Everything goes through the wand, as the prism and the desktop drive it.
## (A) a kit element in the hand gives the node editor the trigger; a plank does not; (B) the first shot on the floor
## sets the edit space down, centred; (C) a ball fired at a floor node stands there GROUNDED at -30 m (the floor under
## it, not world height 0), frozen and supported; (D) a ball fired at a node two up with nothing under it is HELD there
## (edit mode), unsupported and drawn amber; (E) a rod: first node, second node - the missing ball is made, both ends
## join; a second rod up to the held ball supports it (no longer amber); (F) a rod across a diagonal is refused with a
## reason; (G) a brace on a face diagonal joins diagonal sockets; a two-step rod is two units long; (H) the grip lets a
## half-made rod go, and pointing at no node clears the edit space; (I) the budget pays the kit's six draws once.
## Writes ada_run/kit_node_editor/{editor.png, report.json}.
## Run: godot --path <abs> --xr-mode off --resolution 1280x800 res://commons/testing/probe_kit_node_editor.tscn

const InventoryHandLib = preload("res://commons/player/inventory_hand.gd")
const WandLib = preload("res://commons/player/inventory_wand.gd")
const Structure = preload("res://commons/artifacts/playground_kit/kit_structure.gd")
const FLOOR_Y := -30.0

var report := {"checks": []}
var hand: Node
var wand: Node3D
var aim: Camera3D
var ed: Node3D

func _ready() -> void:
	var out_dir := ProjectSettings.globalize_path("res://ada_run/kit_node_editor");DirAccess.make_dir_recursive_absolute(out_dir)
	var env := WorldEnvironment.new();var e := Environment.new();e.background_mode = Environment.BG_COLOR;e.background_color = Color("2a2c33")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR;e.ambient_light_color = Color("d8d2c8");e.ambient_light_energy = .75;env.environment = e;add_child(env)
	var sun := DirectionalLight3D.new();sun.rotation_degrees = Vector3(-40, 30, 0);add_child(sun)
	var floor_b := StaticBody3D.new();floor_b.position.y = FLOOR_Y;add_child(floor_b)
	var fs := CollisionShape3D.new();var fb := BoxShape3D.new();fb.size = Vector3(20, .2, 20);fs.shape = fb;fs.position.y = -.1;floor_b.add_child(fs)
	var fm := MeshInstance3D.new();var fbm := BoxMesh.new();fbm.size = Vector3(20, .2, 20);fm.mesh = fbm;fm.position.y = -.1
	var fmat := StandardMaterial3D.new();fmat.albedo_color = Color("8f8a84");fm.material_override = fmat;floor_b.add_child(fm)
	var src := GDScript.new();src.source_code = "extends Node\nvar checkpoint := 5\n";src.reload()
	var fake := Node.new();fake.set_script(src);fake.add_to_group("void_game");add_child(fake)
	hand = InventoryHandLib.new();hand.name = "InventoryHand";add_child(hand)
	aim = Camera3D.new();aim.fov = 60;add_child(aim);aim.current = true
	wand = WandLib.new();wand.name = "Wand";add_child(wand);wand.setup(hand, aim)
	ed = wand.editor
	await get_tree().process_frame
	await _run()
	_point(Vector3(0, FLOOR_Y + .6, 0))
	aim.global_position = Vector3(4.2, FLOOR_Y + 3.2, 5.4);aim.look_at(Vector3(0, FLOOR_Y + .7, 0))
	for i in 4:await get_tree().process_frame
	wand.update(true, .016)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir.path_join("editor.png"))
	var passed: int = report.checks.filter(func(c):return c.ok).size()
	report["passed"] = passed;report["total"] = report.checks.size()
	var f := FileAccess.open(out_dir.path_join("report.json"), FileAccess.WRITE);f.store_string(JSON.stringify(report, "  "));f.close()
	get_tree().quit(0 if passed == report.checks.size() else 1)

## Aim from a fixed eye at a world point.
func _point(p: Vector3) -> void:
	aim.global_position = Vector3(2.5, FLOOR_Y + 2.6, 4.5);aim.look_at(p)

func _fire(p: Vector3) -> String:
	_point(p);wand.update(true, .016)
	var said: String = wand.press()
	wand.release()
	for i in 2:await get_tree().physics_frame
	return said

func _run() -> void:
	hand.set_current("plank")
	var plank_off: bool = not ed.active()
	hand.set_current("point")
	_check("A a kit element gives the node editor the trigger, a plank does not", plank_off and ed.active() and ed.kind() == "ball", {})
	# B - the edit space
	var said := await _fire(Vector3(0, FLOOR_Y, 0))
	_check("B the first shot on the floor sets the edit space down, centred (corner node at -3, -30, -3)",
		said == "box" and ed.has_box and ed.origin.is_equal_approx(Vector3(-3, FLOOR_Y, -3)), {"said": said, "origin": [ed.origin.x, ed.origin.y, ed.origin.z]})
	var N := func(x, y, z): return ed.world(Vector3i(x, y, z))
	# C - a ball on a floor node, at -30 m
	said = await _fire(N.call(3, 0, 3))
	var c: Node3D = ed.ball_at(Vector3i(3, 0, 3))
	_check("C a ball fired at a floor node stands there grounded on the floor at -30 m, frozen and supported",
		said == "placed" and c != null and c.grounded() and c.supported and c.freeze, {"said": said, "y": c.global_position.y if c else null, "floor_y": c.floor_y if c else null})
	# D - a ball two up, nothing under it
	said = await _fire(N.call(3, 2, 3))
	var d: Node3D = ed.ball_at(Vector3i(3, 2, 3))
	for i in 30:await get_tree().physics_frame
	for i in 2:await get_tree().process_frame
	var amber := _foam_colour_at(N.call(3, 2, 3)).is_equal_approx(Structure.UNSUPPORTED)
	_check("D a ball fired two up with nothing under it is held there (edit mode), unsupported, drawn amber",
		said == "placed" and d != null and d.global_position.is_equal_approx(N.call(3, 2, 3)) and not d.supported and d.editing and amber, {"said": said, "amber": amber})
	# E - rods up the column
	hand.set_current("rod")
	var s1 := await _fire(N.call(3, 0, 3));var s2 := await _fire(N.call(3, 1, 3))
	var mid: Node3D = ed.ball_at(Vector3i(3, 1, 3))
	var s3 := await _fire(N.call(3, 1, 3));var s4 := await _fire(N.call(3, 2, 3))
	for i in 2:await get_tree().process_frame
	var rods := get_tree().get_nodes_in_group("playground_rods")
	var amber_after := _foam_colour_at(N.call(3, 2, 3)).is_equal_approx(Structure.UNSUPPORTED)
	_check("E two hits make a rod (the missing middle ball is made, both ends join); a second rod supports the held ball",
		[s1, s2, s3, s4] == ["first", "placed", "first", "placed"] and mid != null and rods.size() == 2 and rods.all(func(r):return r.joints.size() == 2) and d.supported and not amber_after,
		{"said": [s1, s2, s3, s4], "rods": rods.size(), "top_supported": d.supported})
	# F - a rod across a diagonal is refused
	var f1 := await _fire(N.call(3, 0, 3));var f2 := await _fire(N.call(4, 1, 3))
	_check("F a rod across a diagonal is refused, with a reason", f1 == "first" and f2 == "refused" and hand.notice.contains("one axis"), {"said": [f1, f2], "notice": hand.notice})
	# G - a brace on a face diagonal; a two-step rod
	hand.set_current("brace")
	var g1 := await _fire(N.call(4, 0, 3));var g2 := await _fire(N.call(3, 1, 3))
	var braces: Array = get_tree().get_nodes_in_group("playground_rods").filter(func(r):return r.diagonal)
	hand.set_current("rod")
	var g3 := await _fire(N.call(0, 0, 1));var g4 := await _fire(N.call(2, 0, 1))
	var long: Array = get_tree().get_nodes_in_group("playground_rods").filter(func(r):return not r.diagonal and absf(r.length - (2.0 - 2 * .085)) < .001)
	_check("G a brace on a face diagonal joins diagonal sockets; a rod over two nodes is two units long",
		g2 == "placed" and braces.size() == 1 and braces[0].joints.size() == 2 and braces[0].joints.all(func(j):return j.socket >= 6) and g4 == "placed" and long.size() == 1 and long[0].joints.size() == 2,
		{"said": [g1, g2, g3, g4], "braces": braces.size(), "two_unit_rods": long.size()})
	# H - the grip
	await _fire(N.call(0, 0, 0))
	var had_first: bool = ed.first != null
	var gripped: bool = wand.grip()
	var cleared_first: bool = ed.first == null
	aim.global_position = Vector3(2.5, FLOOR_Y + 2.6, 4.5);aim.look_at(aim.global_position + Vector3(0, 1, -.2));wand.update(true, .016)
	var gripped2: bool = wand.grip()
	_check("H grip lets a half-made rod go; pointing at no node, the edit space is cleared",
		had_first and gripped and cleared_first and gripped2 and not ed.has_box, {"first_then": had_first, "box": ed.has_box})
	# I - the budget
	var spent: Dictionary = hand.spent()
	var balls := get_tree().get_nodes_in_group("playground_balls").size();var all_rods := get_tree().get_nodes_in_group("playground_rods").size()
	_check("I the budget pays the kit's six draws once for %d balls and %d rods" % [balls, all_rods], spent.draws == Structure.KIT_DRAWS, {"spent": spent})
	ed.has_box = true   # for the picture

## The colour the kit renderer gives the foam drawn at `p`.
func _foam_colour_at(p: Vector3) -> Color:
	var st := Structure.current(get_tree())
	var mm: MultiMesh = st.get_node("Foam").multimesh
	for i in mm.instance_count:
		if mm.get_instance_transform(i).origin.distance_to(p) < .005:return mm.get_instance_color(i)
	return Color.BLACK

func _check(title: String, ok: bool, data: Dictionary) -> void:
	report.checks.append({"title": title, "ok": ok, "data": data})
	print(("PASS " if ok else "FAIL ") + title + " " + JSON.stringify(data))
