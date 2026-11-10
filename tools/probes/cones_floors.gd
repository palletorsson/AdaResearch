extends "res://tools/probes/void_game_probe.gd"
## CONES AND POLES (Palle, 2026-11-04): floor 13 Trans_Pre without the black support poles under its three markers;
## the Array floor with a solid cone under every pick-up cube of its 1D and 2D arrays, each cube seated on its tip; floor
## 09 Primitives_Columns with 14 grove columns swapped for an assortment of cones and two posts. Photographs each.
## Run: python tools/test_cones_floors.py

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out = arg.trim_prefix("--out=")
	Engine.physics_ticks_per_second = 90
	preload("res://commons/void/room_source.gd").use_main_tower = true
	load("res://commons/void/game.gd").requested_floor = 13
	game = load("res://commons/void/void.tscn").instantiate(); game.force_xr = false
	root.add_child(game); current_scene = game; game.scene_loaded(); game.scene_visible(); game.set_process_unhandled_key_input(false)
	game.body.scripted_input = true; game.body.set_process_unhandled_input(false)
	await frames(150)
	var ex: Dictionary = game.building.content.exhibits

	# FLOOR 13: no pole under a marker (the floor's ArtifactSupport is a CylinderMesh pipe beside the work)
	var lv13: float = float(game.building.spec.levels[13])
	var markers := ["translation-marker", "rotation-marker", "scale-marker"]
	var poles := 0
	for id in markers:
		var m: Node3D = ex.get("13/%s" % id)
		if m == null: continue
		for mi in game.find_children("*", "MeshInstance3D", true, false):
			if (mi as MeshInstance3D).mesh is CylinderMesh and (mi as Node3D).is_visible_in_tree() and Vector2(mi.global_position.x - m.global_position.x, mi.global_position.z - m.global_position.z).length() < .45 and mi.global_position.y < m.global_position.y and mi.global_position.y > lv13 - .1:
				poles += 1
	var supports: int = game.building.content.find_children("ArtifactSupport*", "", true, false).filter(func(n): return str(n.get_path()).contains("/Content13/")).size()
	check("floor 13: no black pole under the three markers (%d pole meshes, %d supports)" % [poles, supports], poles == 0 and supports == 0 and markers.all(func(id): return ex.has("13/%s" % id)))
	if DisplayServer.get_name() != "headless": await _shot("trans_pre.png", Vector3(0, lv13 + 3.6, 7.5), Vector3(0, lv13 + 1.6, 0.5))

	# THE ARRAY FLOOR: a cone under every array cube, the cube seated on its tip
	var arr: int = preload("res://tools/probes/void_floor.gd").of("Array")
	game.place_player(game.spawn_for(arr)); await create_timer(2.5).timeout
	var lv25: float = float(game.building.spec.levels[arr])
	var stands_m: Node3D = game.building.content.exhibits.get("%d/cone-stands" % arr)
	var stands: Node = stands_m.get_node_or_null("Artifact") if stands_m else null
	var cubes: Array = stands._cubes() if stands else []
	var n_cones: int = (stands.cones as Array).size() if stands else 0
	var worst := 0.0; var solid := true
	for i in mini(n_cones, (stands.seated as Array).size() if stands else 0):
		var cone: Node3D = stands.cones[i]; var cube: Node3D = stands.seated[i]
		var mesh: MeshInstance3D = cube.find_child("CubeBaseMesh", true, false)
		var bottom: float = (mesh.global_transform * mesh.get_aabb()).position.y
		worst = maxf(worst, absf(bottom - (cone.global_position.y + float(cone.height))))
		var body: Node = cone.get_node_or_null("Body")
		solid = solid and body is StaticBody3D and (body as CollisionObject3D).collision_layer & 1 != 0 and body.find_children("*", "CollisionShape3D", false, false).size() == 2
	var y_then: float = stands.seated[0].global_position.y if stands and not (stands.seated as Array).is_empty() else 0.0
	await create_timer(1.0).timeout
	var still: bool = stands != null and not (stands.seated as Array).is_empty() and absf(stands.seated[0].global_position.y - y_then) < .002
	check("Array floor: %d cones under the %d cubes of the row, the grid and the column; every cube's body on its cone's tip (worst %.3f m), the bob stopped (%s), every cone solid (%s)" % [n_cones, cubes.size(), worst, still, solid], n_cones == 85 and cubes.size() == 85 and worst < .01 and still and solid)
	if DisplayServer.get_name() != "headless":
		await _shot("array_grid.png", Vector3(0.6, lv25 + 2.4, 9.0), Vector3(0.25, lv25 + .5, 3.0))
		await _shot("array_row.png", Vector3(-12.5, lv25 + 2.0, -1.0), Vector3(-8.5, lv25 + 1.3, -5.0))

	# FLOOR 09: 14 grove columns gone, the cones and posts in their places
	game.place_player(game.spawn_for(9)); await create_timer(2.5).timeout
	var lv9: float = float(game.building.spec.levels[9])
	var hall: Node = game.building.content.exhibits.get("9/hall").get_node("Artifact")
	var gone := []; var kept := []
	for i in range(1, 21):
		var n := "InteriorColumn_%02d" % i
		if hall.get_node_or_null(n) == null: gone.append(i)
		else: kept.append(i)
	var cones9 := []
	for k in game.building.content.exhibits.keys():
		if str(k).begins_with("9/grove-cone-") or str(k).begins_with("9/grove-post-"): cones9.append(game.building.content.exhibits[k].get_node("Artifact"))
	var pickable: bool = cones9.all(func(c): return c.get_node_or_null("Body") is RigidBody3D and (c.get_node("Body") as RigidBody3D).freeze)
	var posts: int = cones9.filter(func(c): return c.style == "post").size()
	var styles := {}
	for c in cones9: styles[c.style] = true
	check("floor 09: grove columns %s gone, %s kept; %d cones and %d posts stand in their places (%s), each a pickable frozen until taken (%s); the comparison columns all there (%d)" % [str(gone), str(kept), cones9.size() - posts, posts, ",".join(PackedStringArray(styles.keys())), pickable, hall.find_children("Sides_*", "", false, false).size()], gone == [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 19, 20] and kept == [13, 14, 15, 16, 17, 18] and cones9.size() == 14 and posts == 2 and styles.size() == 4 and pickable and hall.find_children("Sides_*", "", false, false).size() == 5)
	if DisplayServer.get_name() != "headless": await _shot("columns_cones.png", Vector3(-0.5, lv9 + 2.1, 7.0), Vector3(0, lv9 + .5, -0.5))
	finish()

func _shot(name: String, from: Vector3, at: Vector3) -> void:
	var camera := Camera3D.new(); game.add_child(camera); camera.fov = 62; camera.environment = game.atmosphere.environment
	camera.global_position = from; camera.look_at(at); camera.make_current()
	game.status.hide(); game.notice_time = 0
	if game.desktop_help != null: game.desktop_help.hide()
	await frames(8); await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(name))
	camera.queue_free(); game.camera.make_current()

func finish() -> void:
	FileAccess.open(out.path_join("checks.json"), FileAccess.WRITE).store_string(JSON.stringify({"passed": failed.is_empty(), "checks": checks, "failed": failed}, "  "))
	print("[cones_floors] %d/%d checks pass" % [checks.size() - failed.size(), checks.size()])
	quit(0 if failed.is_empty() else 1)
