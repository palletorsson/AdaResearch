extends SceneTree
## THE BIOME BOX on one floor (the growth floors of the Void; Palle, 2026-11-12)
## A glass box with the biome's cell grid on it, closing shaft B, and inside it the biome object at the stage of the
## floor it stands on. Read in the running tower, with its own walker:
##   the box stands on the floor and its biome is built once a body has arrived there;
##   the stage is the floor's own sequence, read from the floor's map, and the phase is the row's;
##   everything the biome draws lies inside the glass;
##   the glass keeps a body out, and the box's floor closes the shaft (a body set on the roof stays on it);
##   what the build cost.
## A box in the slanted form (flare_height above 0: a larger ground carried up on a glass funnel) is read the same way,
## with the body walking in under the lean from the west, set down on the open top, and - when the floor has a
## `biome-lookout` row - walking up the ramp to the deck beside the rim. When the floor has a `biome-gate` row and the
## box a gate, the body walks IN: up the ramp to the deck, through the gate, down the board onto the ground, to the
## water, against the highest hill on the ground's edge (it must be held), and out again down to the floor.
##
##   godot --path <stage> --script res://tools/probes/biome_box_floor.gd -- --no-bridges
##       --void-start-floor=<floor> --out=<dir> [--stage=lsystems]
##
## box.json: checks with what was read. arrival.png, box.png, close.png; below.png for the slanted form; gate.png and
## inside.png when a body walks in.
const ID := "biome-box"
var game: Node3D
var level := 0.0


func _initialize() -> void:
	run.call_deferred()


func _shot(cam: Camera3D, at: Vector3, target: Vector3, path: String) -> void:
	cam.global_position = at
	cam.look_at(target, Vector3.UP)
	cam.current = true
	for i in 4: await process_frame
	root.get_viewport().get_texture().get_image().save_png(path)
	cam.current = false


func _go(body: CharacterBody3D, target: Vector3, ticks_max: int = 600, speed: float = 0.5) -> float:
	var best := INF
	for i in ticks_max:
		var d := Vector2(body.global_position.x, body.global_position.z).distance_to(Vector2(target.x, target.z))
		best = minf(best, d)
		if d < 0.15: break
		body.look_at(Vector3(target.x, body.global_position.y, target.z), Vector3.UP)
		body.drive = Vector2(0, -speed)
		await physics_frame
	body.drive = Vector2.ZERO
	for i in 20: await physics_frame
	return best


func run() -> void:
	var folder := ""
	var want_stage := "lsystems"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): folder = arg.trim_prefix("--out=")
		if arg.begins_with("--stage="): want_stage = arg.trim_prefix("--stage=")
	DirAccess.make_dir_recursive_absolute(folder)
	load("res://commons/void/room_source.gd").use_main_tower = true
	game = load("res://commons/void/void.tscn").instantiate()
	root.add_child(game); current_scene = game
	game.body.scripted_input = true; game.body.set_process_unhandled_input(false)
	game.scene_loaded(); game.scene_visible()
	var floor: int = game.checkpoint
	var record: Dictionary = game.building.content.data.floors[floor]
	var checks := []
	var result := {"floor": floor, "map": str(record.map), "checks": checks, "passed": false}
	var row = null
	for a in record.artifacts:
		if str(a.id) == ID: row = a
	for i in 1500:
		if game.building.content.exhibits.has(str(floor) + "/" + ID): break
		await physics_frame
	var mount: Node3D = game.building.content.exhibits.get(str(floor) + "/" + ID)
	var box: Node3D = mount.get_node_or_null("Artifact") if mount != null else null
	checks.append({"check": "the floor holds a biome box", "ok": box != null and box.has_method("grow") and row != null})
	if box != null and box.has_method("grow") and row != null:
		var built := false
		for i in 900:
			if bool(box.state().built): built = true; break
			await physics_frame
		for i in 240: await physics_frame
		level = float(game.building.spec.levels[floor]) + game.building.global_position.y
		var body: CharacterBody3D = game.body
		for layer in root.find_children("*", "CanvasLayer", true, false):
			if layer.get_viewport() == root: layer.hide()
		var cam := Camera3D.new()
		cam.fov = 80
		root.add_child(cam)
		var at: Vector3 = box.global_position
		var st: Dictionary = box.state()
		var want_phase: float = float((row.config as Dictionary).get("phase", 1.0))
		checks.append({"check": "a body has arrived on the floor and the biome is built in the box", "ok": built, "state": st})
		checks.append({"check": "the stage is the floor's own sequence and the phase is the row's", "ok": str(st.stage) == want_stage and is_equal_approx(float(st.phase), want_phase), "stage": str(st.stage), "phase": float(st.phase), "arriving": st.arriving})
		# everything the biome draws lies inside the glass
		var low := Vector3(INF, INF, INF)
		var high := Vector3(-INF, -INF, -INF)
		var drawn := 0
		for n in box.biome().find_children("*", "GeometryInstance3D", true, false):
			var g := n as GeometryInstance3D
			if not g.is_visible_in_tree() or g.get_aabb().size == Vector3.ZERO: continue
			var world: AABB = g.global_transform * g.get_aabb()
			low = low.min(world.position)
			high = high.max(world.end)
			drawn += 1
		var half: float = box.half_side()
		var rim: float = float(box.flare_height)
		var flared: bool = rim > 0.0
		var spec: Dictionary = game.building.spec
		var ceiling: float = float(spec.levels[floor - 1]) - float(spec.levels[floor]) - float(spec.slab_thickness) if flared else float(box.tall)      # an open top: the trees stay under the slab above
		var ground := {}
		if flared and box.biome().has_method("_h_at"):
			# the ground's own relief, read from the biome: the upright glass has to stand as high as the cut edge it holds
			var n: int = int(box.cells)
			var top_all := -INF
			var top_edge := -INF
			for i in n * 4 + 1:
				for j in n * 4 + 1:
					var h: float = float(box.biome().call("_h_at", -n * 0.5 + i * 0.25, -n * 0.5 + j * 0.25))
					top_all = maxf(top_all, h)
					if i == 0 or j == 0 or i == n * 4 or j == n * 4: top_edge = maxf(top_edge, h)
			var surface: float = box.biome().global_position.y - at.y
			ground = {"highest_m": snappedf(surface + top_all, .01), "highest_at_the_edge_m": snappedf(surface + top_edge, .01), "glass_top_m": float(box.glass_top())}
			checks.append({"check": "the upright glass stands higher than the ground's cut edge everywhere", "ok": surface + top_edge <= float(box.glass_top()) - 0.05, "ground": ground})
		var risers := []
		for n in root.find_children("*Riser*", "MeshInstance3D", true, false):
			var m := n as MeshInstance3D
			if m.is_visible_in_tree() and absf(m.global_position.y - (at.y + 3.0)) < 3.2 and absf(m.global_position.x - at.x) < half and absf(m.global_position.z - at.z) < half:
				risers.append([snappedf(m.global_position.x - at.x, .01), snappedf(m.global_position.z - at.z, .01)])
		var inside: bool = drawn > 0 and low.x >= at.x - half - 0.06 and high.x <= at.x + half + 0.06 and low.z >= at.z - half - 0.06 and high.z <= at.z + half + 0.06 and low.y >= at.y + rim - 0.02 and high.y <= at.y + ceiling + 0.02
		checks.append({"check": "everything the biome draws lies inside the glass" if not flared else "everything the biome draws lies inside the rim, on the tray and under the slab above", "ok": inside, "drawn": drawn, "ceiling_m": snappedf(ceiling, .01), "service_risers_inside_the_rim": risers,
			"from": [snappedf(low.x - at.x, .01), snappedf(low.y - at.y, .01), snappedf(low.z - at.z, .01)], "to": [snappedf(high.x - at.x, .01), snappedf(high.y - at.y, .01), snappedf(high.z - at.z, .01)]})
		game.place_player(Vector3(0, level + 0.3, 8.6))
		for i in 20: await physics_frame
		await _shot(cam, Vector3(0, level + 1.6, 7.8), at + Vector3(0, 1.4, 0), folder.path_join("arrival.png"))
		if not flared:
			await _shot(cam, at + Vector3(-4.6, 2.3, 6.2), at + Vector3(0, 1.3, 0), folder.path_join("box.png"))
			await _shot(cam, at + Vector3(0.4, 1.6, 4.3), at + Vector3(0, 1.2, 0), folder.path_join("close.png"))
			# the glass keeps a body out
			game.place_player(at + Vector3(0.9, 0.3, half + 1.6))
			for i in 40: await physics_frame
			await _go(body, at + Vector3(0.9, 0, 0), 300)
			var stopped: float = body.global_position.z - at.z
			checks.append({"check": "the glass keeps a body out", "ok": stopped >= half + 0.15, "stopped_m_from_the_middle": snappedf(stopped, .01)})
			# the box closes the shaft: a body set on its roof stays there
			game.place_player(at + Vector3(0, float(box.tall) + 0.4, 0))
			for i in 90: await physics_frame
			var on_roof: float = body.global_position.y - at.y
			checks.append({"check": "a body set on the roof stays on it: the box closes the shaft", "ok": absf(on_roof - float(box.tall)) < 0.25 and int(game.checkpoint) == floor, "feet_m": snappedf(on_roof, .01)})
		else:
			await _shot(cam, at + Vector3(-half - 2.4, rim + 3.3, half + 2.7), at + Vector3(0, rim + 0.5, 0), folder.path_join("box.png"))
			await _shot(cam, at + Vector3(2.0, rim + 1.6, half + 1.1), at + Vector3(-1.0, rim + 0.7, 0), folder.path_join("close.png"))
			await _shot(cam, at + Vector3(-half - 3.4, 1.6, 3.4), at + Vector3(0, 1.7, 0), folder.path_join("below.png"))
			# the lean keeps a body off the shaft: it walks in under the glass from the west and is stopped before the foot
			game.place_player(at + Vector3(-half - 1.6, 0.3, 2.6))
			for i in 40: await physics_frame
			await _go(body, at + Vector3(0, 0, 2.6), 400)
			var short: float = at.x - body.global_position.x
			checks.append({"check": "a body walking in under the lean is stopped before the foot, on the floor", "ok": short >= float(box.foot_half()) + 0.15 and absf(body.global_position.y - level) < 0.3,
				"stopped_m_from_the_middle": snappedf(short, .01), "foot_half_m": float(box.foot_half())})
			# the open top: a body set down over the middle comes to rest on the tray under the ground, on this floor
			game.place_player(at + Vector3(0, float(box.glass_top()) + 0.4, 0))
			for i in 120: await physics_frame
			var on_tray: float = body.global_position.y - at.y
			var under := ""
			var query := PhysicsRayQueryParameters3D.create(body.global_position + Vector3(0, 0.3, 0), body.global_position + Vector3(0, -0.6, 0))
			query.exclude = [body.get_rid()]
			var hit: Dictionary = root.get_world_3d().direct_space_state.intersect_ray(query)
			if not hit.is_empty(): under = str((hit.collider as Node).get_path()).get_slice("/Artifact/", 1).left(90)
			checks.append({"check": "a body set down on the open top stays on this floor, on the tray or on what the biome holds: the funnel closes the shaft", "ok": on_tray >= rim - 0.1 and on_tray < float(box.glass_top()) + 1.0 and int(game.checkpoint) == floor,
				"feet_m": snappedf(on_tray, .01), "stands_on": under})
			# the lookout, when the floor has one: up the ramp to a deck beside the rim
			var lookout = null
			for a in record.artifacts:
				if str(a.id) == "biome-lookout": lookout = a
			if lookout != null:
				var deck := Vector3(float(lookout.position[0]), level, float(lookout.position[1]))
				game.place_player(deck + Vector3(-6.2, 0.3, 0))
				for i in 40: await physics_frame
				await _go(body, deck, 700, 0.34)
				var up_m: float = body.global_position.y - level
				checks.append({"check": "a body walks up the ramp to the lookout and stands two metres up beside the rim", "ok": absf(up_m - 2.0) < 0.3 and Vector2(body.global_position.x - deck.x, body.global_position.z - deck.z).length() < 0.6,
					"feet_m": snappedf(up_m, .01), "at": [snappedf(body.global_position.x, .01), snappedf(body.global_position.z, .01)]})
				for layer in root.find_children("*", "CanvasLayer", true, false):
					if layer.get_viewport() == root: layer.hide()
				await _shot(cam, body.global_position + Vector3(0, 1.6, 0), at + Vector3(-1.5, rim + 0.6, -1.0), folder.path_join("lookout.png"))
			# the way in, when the floor has a gate deck and the box a gate
			var gate = null
			for a in record.artifacts:
				if str(a.id) == "biome-gate": gate = a
			if gate != null and str(box.gate_side) != "":
				var deck := Vector3(float(gate.position[0]), level, float(gate.position[1]))
				var inward := Vector3(signf(at.x - deck.x), 0, 0) if absf(at.x - deck.x) > absf(at.z - deck.z) else Vector3(0, 0, signf(at.z - deck.z))
				var foot: Vector3 = deck - inward * 8.2
				await _shot(cam, foot + Vector3(-1.5, 1.6, 4.6), deck + Vector3(1.5, float(box.gate_height), 0), folder.path_join("gate.png"))
				game.place_player(foot + Vector3(0, 0.3, 0))
				for i in 40: await physics_frame
				await _go(body, deck, 1100, 0.34)
				var on_deck: float = body.global_position.y - level
				var first: Vector3 = deck + inward * 4.2      # some three metres past the glass line
				await _go(body, first, 900, 0.34)
				var here: Vector3 = box.to_local(body.global_position)
				var ground_here: float = float(box.call("_ground_at", here))
				var query2 := PhysicsRayQueryParameters3D.create(body.global_position + Vector3(0, 0.3, 0), body.global_position + Vector3(0, -0.6, 0))
				query2.exclude = [body.get_rid()]
				var hit2: Dictionary = root.get_world_3d().direct_space_state.intersect_ray(query2)
				var on := str((hit2.collider as Node).get_path()).get_slice("/Artifact/", 1).left(60) if not hit2.is_empty() else ""
				checks.append({"check": "a body walks up the ramp to the deck, through the gate and down the board onto the ground", "ok": absf(on_deck - float(box.gate_height)) < 0.35 and absf(here.y - ground_here) < 0.2 and on.contains("Ground"),
					"deck_m": snappedf(on_deck, .01), "feet_m": snappedf(here.y, .01), "ground_there_m": snappedf(ground_here, .01), "stands_on": on, "at_in_the_box": [snappedf(here.x, .01), snappedf(here.z, .01)],
					"board_reach_m": float(box.state().way_in_reach_m), "board_clears_the_cut_edge": bool(box.state().way_in_clears_the_edge)})
				# to the water in the middle
				await _go(body, at + Vector3(-2.0, 0, 1.0), 900, 0.34)
				var water: Vector3 = box.to_local(body.global_position)
				await _shot(cam, body.global_position + Vector3(0, 1.6, 0), at + Vector3(4.0, rim + 1.6, -3.0), folder.path_join("inside.png"))
				# against the highest hill on the ground's edge: the edge holds
				await _go(body, at + Vector3(-1.5, 0, 4.6), 900, 0.34)
				await _go(body, at + Vector3(-1.5, 0, 9.5), 360, 0.5)
				var held: Vector3 = box.to_local(body.global_position)
				checks.append({"check": "inside, a body reaches the water and, walking out over the highest hill on the edge, is held on the ground", "ok": Vector2(water.x + 2.0, water.z - 1.0).length() < 0.4 and held.z < half - 0.4 and held.y > rim + 0.6 and int(game.checkpoint) == floor,
					"at_the_water": [snappedf(water.x, .01), snappedf(water.y, .01), snappedf(water.z, .01)], "held_at": [snappedf(held.x, .01), snappedf(held.y, .01), snappedf(held.z, .01)]})
				# and out again
				await _go(body, first, 1100, 0.34)
				await _go(body, deck, 900, 0.34)
				var back_on_deck: float = body.global_position.y - level
				await _go(body, foot, 1100, 0.34)
				var out_m: float = body.global_position.y - level
				checks.append({"check": "and walks out again: up the board to the deck, down the ramp to the floor", "ok": absf(back_on_deck - float(box.gate_height)) < 0.35 and absf(out_m) < 0.15, "deck_m": snappedf(back_on_deck, .01), "feet_m": snappedf(out_m, .01)})
		checks.append({"check": "the build is reported (the biome's own builders: about 1.3 s alone on this machine, more when several towers run at once)", "ok": int(st.build_ms) > 0, "build_ms": int(st.build_ms), "trees": int(st.trees), "creatures": int(st.creatures)})
		game.place_player(Vector3(0, level + 0.3, 8.6))
		result["passed"] = checks.all(func(c): return c.ok)
	var file := FileAccess.open(folder.path_join("box.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("[biome_box_floor] ", "PASSED" if result.passed else "FAILED")
	quit()
