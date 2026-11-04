extends "res://tools/probes/void_game_probe.gd"
## THE FIRST ASSOCIATION IN THE TOWER (Palle, 2026-11-03): on floor 09 (Primitives_Columns), beside the first cylinder
## comparison, the fire extinguisher - fire_extinguisher = association(config(cylinder)), built from the cylinder term -
## stands as a body the hands can take, with the tape that writes its association on the floor before it.
## Run: python tools/test_association_floor.py
const FLOOR := 9

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out = arg.trim_prefix("--out=")
	Engine.physics_ticks_per_second = 90
	preload("res://commons/void/room_source.gd").use_main_tower = true
	load("res://commons/void/game.gd").requested_floor = FLOOR
	game = load("res://commons/void/void.tscn").instantiate(); game.force_xr = false
	root.add_child(game); current_scene = game; game.scene_loaded(); game.scene_visible(); game.set_process_unhandled_key_input(false)
	game.body.scripted_input = true; game.body.set_process_unhandled_input(false)
	await frames(120)
	var level: float = float(game.building.spec.levels[FLOOR])
	var ex: Dictionary = game.building.content.exhibits
	var mount: Node3D = ex.get("9/association-fire-extinguisher")
	var tape_mount: Node3D = ex.get("9/association-fire-extinguisher-tape")
	check("the fire extinguisher and its tape stand on floor 09 from rooms.json", mount != null and tape_mount != null)
	if mount == null or tape_mount == null: return finish()
	var bodies: Array = mount.find_children("*", "RigidBody3D", true, false)
	var body: RigidBody3D = bodies[0] if not bodies.is_empty() else null
	var cylinder := body != null and body.find_children("*", "CollisionShape3D", false, false).any(func(c): return c.shape is CylinderShape3D)
	check("built from the term: a body the hands can take, with a cylinder collider (%s)" % (body.get_script().resource_path.get_file() if body and body.get_script() else "no body"), body != null and body.get_script() != null and body.get_script().resource_path.ends_with("pickable.gd") and cylinder)
	var composite: Node = mount.find_children("*", "Node3D", true, false).filter(func(n): return n.get("term") != null).front() if mount.find_children("*", "Node3D", true, false).any(func(n): return n.get("term") != null) else null
	check("its term is fire_extinguisher = association(config(cylinder)) (%s)" % (str(composite.get("term")) if composite else "?"), composite != null and str(composite.get("term")) == "fire_extinguisher")
	await frames(90)
	var up := body.global_basis.y.normalized().dot(Vector3.UP); var foot := body.global_position.y - level
	# since 2026-11-04 it stands on its plinth (association_plinth), at the plinth's cap
	var plinth_m: Node3D = ex.get("9/association-fire-extinguisher-plinth")
	var cap: float = float(plinth_m.get_node("Artifact").get("top")) if plinth_m and plinth_m.has_node("Artifact") else 0.0
	check("it stands upright on its plinth (up %.3f, base %.3f m over the floor, the cap %.2f m)" % [up, foot, cap], up > .99 and cap > 0.0 and absf(foot - cap) < .05)
	var tapes: Array = tape_mount.find_children("*", "Label3D", true, false)
	var said: String = tapes[0].text if not tapes.is_empty() else ""
	check("the tape writes the association (\"%s\")" % said, said == "fire_extinguisher = association(config(cylinder))")
	if DisplayServer.get_name() != "headless":
		var at := Vector3(0.8, level + 1.55, -3.9); var look := Vector3(0, level + .3, -2.2)
		var camera := Camera3D.new(); game.add_child(camera); camera.fov = 60; camera.environment = game.atmosphere.environment
		camera.global_position = at; camera.look_at(look); camera.make_current()
		game.status.hide(); game.charge_display.hide(); game.notice_time = 0
		if game.desktop_help != null: game.desktop_help.hide()
		await frames(8); await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(out.path_join("extinguisher.png"))
	finish()

func finish() -> void:
	FileAccess.open(out.path_join("checks.json"), FileAccess.WRITE).store_string(JSON.stringify({"passed": failed.is_empty(), "checks": checks, "failed": failed}, "  "))
	print("[association_floor] %d/%d checks pass" % [checks.size() - failed.size(), checks.size()])
	quit(0 if failed.is_empty() else 1)
