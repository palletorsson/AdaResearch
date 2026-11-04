extends "res://tools/probes/void_game_probe.gd"
## THE ASSOCIATIONS IN THE TOWER (Palle, 2026-11-03): on every Primitives floor where a form is first met, its
## associated object - built from its term, association(config(form)) - and the tape that writes the association.
## Visits each floor of ada_run/associations/plan.json; for every object: built from its term, a body, resting on the
## floor; for every tape: the words. Photographs each pair. Run: python tools/test_associations_tower.py

func run() -> void:
	var plan_path := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out = arg.trim_prefix("--out=")
		if arg.begins_with("--plan="): plan_path = arg.trim_prefix("--plan=")
	Engine.physics_ticks_per_second = 90
	var plan: Array = JSON.parse_string(FileAccess.get_file_as_string(plan_path))
	var Items = load("res://commons/player/inventory_items.gd")
	Items.collected_path = out.path_join("collected.json")   # a shell's collect goes here, not into the person's belt
	if FileAccess.file_exists(Items.collected_path): DirAccess.remove_absolute(Items.collected_path)
	var floors := []
	for row in plan:
		if not (int(row.floor) in floors): floors.append(int(row.floor))
	preload("res://commons/void/room_source.gd").use_main_tower = true
	load("res://commons/void/game.gd").requested_floor = floors[0]
	game = load("res://commons/void/void.tscn").instantiate(); game.force_xr = false
	root.add_child(game); current_scene = game; game.scene_loaded(); game.scene_visible(); game.set_process_unhandled_key_input(false)
	game.body.scripted_input = true; game.body.set_process_unhandled_input(false)
	await frames(90)
	for f in floors:
		game.place_player(game.spawn_for(f)); await frames(150)
		var level: float = float(game.building.spec.levels[f])
		var ex: Dictionary = game.building.content.exhibits
		for row in plan:
			if int(row.floor) != f: continue
			var ident := "association-%s%s" % [str(row.term).replace("_", "-"), "-tape" if row.get("tape", false) else ""]
			var m: Node3D = ex.get("%d/%s" % [f, ident])
			if m == null:
				check("floor %d: %s stands" % [f, ident], false); continue
			if row.get("tape", false):
				var labels: Array = m.find_children("*", "Label3D", true, false)
				var said: String = labels[0].text if not labels.is_empty() else ""
				check("floor %d: the tape writes \"%s\"" % [f, said], said == str(row.text))
				continue
			var comp: Array = m.find_children("*", "Node3D", true, false).filter(func(n): return n.get("term") != null)
			var term: String = str(comp[0].get("term")) if not comp.is_empty() else "?"
			var bodies: Array = m.find_children("*", "CollisionObject3D", true, false)
			var body: Node3D = bodies[0] if not bodies.is_empty() else null
			var grab: bool = body != null and body.get_script() != null and body.get_script().resource_path.ends_with("pickable.gd")
			var meshes: Array = m.find_children("*", "MeshInstance3D", true, false)
			var low := INF
			for mi in meshes:
				var bb: AABB = (mi as MeshInstance3D).global_transform * (mi as MeshInstance3D).get_aabb()
				low = minf(low, bb.position.y - level)
			# since 2026-11-04 an example stands on its association_plinth (`<id>-plinth`): it rests on the cap, not the floor
			var plinth_m: Node3D = ex.get("%d/%s-plinth" % [f, ident])
			var plinth_a: Node = plinth_m.get_node_or_null("Artifact") if plinth_m else null
			var rest: float = float(plinth_a.get("top")) if plinth_a != null else 0.0
			# a term made without a grabbable part is taken through its plinth's invisible shell (2026-11-04)
			var shell: Node = plinth_a.get_node_or_null("PickShell") if plinth_a else null
			var takeable: bool = grab or shell != null
			check("floor %d: %s - built from its term (%s), %s, resting on %s (lowest %.3f m, the cap %.2f m)" % [f, row.text, term, "a body the hands take" if grab else ("taken through its plinth's shell" if shell else "a fixed body"), "its plinth" if plinth_a else "the floor", low, rest],
				term == str(row.term) and body != null and takeable and absf(low - rest) < .03 and meshes.size() > 0)
			if shell != null:
				# the shell is what a hand takes: picked up, the item is collected and the shell goes back home
				var home: Vector3 = (shell as Node3D).global_position
				var dp: Node = game.body.desktop_pointer
				shell.pick_up(dp.grip)
				await frames(20)
				var item_id: String = str(plinth_a.get("item"))
				check("floor %d: %s - picked up through the shell it is collected (%s), the shell back home (%.3f m)" % [f, item_id, Items.is_collected(item_id), (shell as Node3D).global_position.distance_to(home)], Items.is_collected(item_id) and (shell as Node3D).global_position.distance_to(home) < .02 and not shell.is_picked_up())
			if DisplayServer.get_name() != "headless":
				var at: Vector3 = m.global_position
				var camera := Camera3D.new(); game.add_child(camera); camera.fov = 55; camera.environment = game.atmosphere.environment
				camera.global_position = at + Vector3(1.3, 1.25, 1.6); camera.look_at(at + Vector3(-.3, .15, -.3)); camera.make_current()
				game.status.hide(); game.charge_display.hide(); game.notice_time = 0
				if game.desktop_help != null: game.desktop_help.hide()
				await frames(8); await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(out.path_join("%02d_%s.png" % [f, row.term]))
				camera.free(); game.camera.make_current()
	FileAccess.open(out.path_join("checks.json"), FileAccess.WRITE).store_string(JSON.stringify({"passed": failed.is_empty(), "checks": checks, "failed": failed}, "  "))
	print("[associations] %d/%d checks pass" % [checks.size() - failed.size(), checks.size()])
	quit(0 if failed.is_empty() else 1)
