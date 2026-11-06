extends Node3D
## The built look switched on by the bench (Palle, 2026-11-06: "yes turn it on"): workbench.json carries `fold` on the
## default and every floor stage. The path the game uses - the hand reads the stage of the Void's checkpoint floor,
## lays it over the item's config, and the piece is made with that config - proven on a bench with a stand-in Void:
## (A) on floors 0, 3 and 5 the hand's config for the ball says fold; floor 5 also diagonals and bars; (B) a ball made
## with the floor-3 config and let go on its grid point is drawn BUILT (folded, its own meshes hidden), and so is a rod
## set into it; (C) NEGATIVE: a ball made without the hand's config (as a map places one) stays in the detailed look.
## Writes ada_run/kit_bench_fold/{fold.png, report.json}.
## Run: godot --path <abs> --xr-mode off --resolution 1280x800 res://commons/testing/probe_kit_bench_fold.tscn

const Ball = preload("res://commons/artifacts/playground_kit/playground_ball.tscn")
const Rod = preload("res://commons/artifacts/playground_kit/playground_rod.tscn")
const InventoryHandLib = preload("res://commons/player/inventory_hand.gd")
const Structure = preload("res://commons/artifacts/playground_kit/kit_structure.gd")

var report := {"checks": []}

func _ready() -> void:
	var out_dir := ProjectSettings.globalize_path("res://ada_run/kit_bench_fold");DirAccess.make_dir_recursive_absolute(out_dir)
	var env := WorldEnvironment.new();var e := Environment.new();e.background_mode = Environment.BG_COLOR;e.background_color = Color("2a2c33")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR;e.ambient_light_color = Color("d8d2c8");e.ambient_light_energy = .75;env.environment = e;add_child(env)
	var sun := DirectionalLight3D.new();sun.rotation_degrees = Vector3(-40, 30, 0);add_child(sun)
	var floor_b := StaticBody3D.new();add_child(floor_b)
	var fs := CollisionShape3D.new();var fb := BoxShape3D.new();fb.size = Vector3(10, .1, 10);fs.shape = fb;fs.position.y = -.05;floor_b.add_child(fs)
	var cam := Camera3D.new();cam.transform = Transform3D(Basis(), Vector3(2.2, 1.8, 2.6)).looking_at(Vector3(.5, .5, 0));add_child(cam);cam.current = true
	# a stand-in Void: the hand finds it in group void_game and reads its checkpoint floor
	var src := GDScript.new();src.source_code = "extends Node\nvar checkpoint := 0\n";src.reload()
	var fake := Node.new();fake.set_script(src);fake.add_to_group("void_game");add_child(fake)
	var hand: Node = InventoryHandLib.new();hand.name = "InventoryHand";add_child(hand)
	await get_tree().process_frame
	var by_floor := {}
	for f in [0, 3, 5]:
		fake.checkpoint = f
		var cfg: Dictionary = hand.config_for("point")
		by_floor[f] = {"fold": cfg.get("fold"), "diagonals": cfg.get("diagonals"), "rigidity": cfg.get("rigidity"), "snap_to": cfg.get("snap_to")}
	_check("A the hand's ball config says fold on floors 0, 3 and 5; floor 5 also diagonals and bars",
		by_floor[0].fold == true and by_floor[3].fold == true and by_floor[5].fold == true and by_floor[5].diagonals == true and by_floor[5].rigidity == "bars", by_floor)
	# B - a ball and a rod made with the floor-3 config
	fake.checkpoint = 3
	var a: RigidBody3D = Ball.instantiate();a.apply_grid_config(hand.config_for("point"));add_child(a)
	a.global_position = Vector3(.07, .15, -.05);a.settle()
	var r: RigidBody3D = Rod.instantiate();r.apply_grid_config(hand.config_for("rod"));add_child(r)
	r.global_transform = Transform3D(Basis(Vector3.FORWARD, PI / 2), a.socket_global(2) + Vector3(0, r.length / 2.0 + .02, 0))
	r.settle()
	# C - a ball as a map places it: no hand config
	var m: RigidBody3D = Ball.instantiate();add_child(m)
	m.global_position = Vector3(2, .15, 0);m.settle()
	for i in 4:await get_tree().process_frame
	var st := Structure.current(get_tree())
	var hidden := func(p):return p.get_children().all(func(c):return not (c is MeshInstance3D) or not c.visible)
	_check("B made with the floor-3 config, the settled ball and the rod set into it are drawn built",
		a.fold and a in st.folded_balls and r in st.folded_rods and hidden.call(a) and hidden.call(r) and r.joints.size() == 1,
		{"ball_fold": a.fold, "built_balls": st.folded_balls.size(), "built_rods": st.folded_rods.size(), "rod_ends": r.joints.size()})
	var foam: MultiMesh = st.get_node("Foam").multimesh
	_check("C negative: a ball placed without the hand's config stays detailed (one foam instance, not built)",
		not m.fold and m not in st.folded_balls and foam.instance_count == 1, {"foam_instances": foam.instance_count})
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir.path_join("fold.png"))
	var passed: int = report.checks.filter(func(c):return c.ok).size()
	report["passed"] = passed;report["total"] = report.checks.size()
	var f := FileAccess.open(out_dir.path_join("report.json"), FileAccess.WRITE);f.store_string(JSON.stringify(report, "  "));f.close()
	get_tree().quit(0 if passed == report.checks.size() else 1)

func _check(title: String, ok: bool, data: Dictionary) -> void:
	report.checks.append({"title": title, "ok": ok, "data": data})
	print(("PASS " if ok else "FAIL ") + title + " " + JSON.stringify(data))
