extends "res://tools/probes/void_game_probe.gd"
## THE VENDING MACHINES ON FLOOR 20 (Trans_Playground), beside the scaffold workstation (Palle, 2026-11-06): the
## prefabs machine and the tools machine from rooms.json, built in the actual tower - each with its slots, standing on
## the slab, cutting into no other work's box - and photographed. Run: python tools/test_vending_machine.py
var floors: Array = [20]
const IDS := ["vending-prefabs", "vending-tools"]

func world_bounds(host: Node3D) -> AABB:
	var result := AABB(); var first := true
	for node in host.find_children("*", "GeometryInstance3D", true, false):
		var bounds: AABB
		if node is MeshInstance3D and node.mesh != null: bounds = node.mesh.get_aabb()
		elif node is MultiMeshInstance3D and node.multimesh != null: bounds = node.multimesh.get_aabb()
		elif node is CSGShape3D: bounds = node.get_aabb()
		else: continue
		if bounds.size.length() < .001: continue
		bounds = node.global_transform * bounds
		result = bounds if first else result.merge(bounds); first = false
	return result

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out = arg.trim_prefix("--out=")
		if arg.begins_with("--floors="):
			floors = []
			for s in arg.trim_prefix("--floors=").split(","): floors.append(int(s))
	Engine.physics_ticks_per_second = 90
	preload("res://commons/void/room_source.gd").use_main_tower = true
	load("res://commons/void/game.gd").requested_floor = int(floors[0])
	game = load("res://commons/void/void.tscn").instantiate(); game.force_xr = false
	root.add_child(game); current_scene = game; game.scene_loaded(); game.scene_visible(); game.set_process_unhandled_key_input(false)
	game.body.scripted_input = true; game.body.set_process_unhandled_input(false)
	await frames(120)
	for f in floors:
		game.place_player(game.spawn_for(int(f))); await frames(200)
		await check_floor(int(f))
	FileAccess.open(out.path_join("checks.json"), FileAccess.WRITE).store_string(JSON.stringify({"passed": failed.is_empty(), "checks": checks, "failed": failed}, "  "))
	print("[vending_machine_floor] %d/%d checks pass" % [checks.size() - failed.size(), checks.size()])
	quit(0 if failed.is_empty() else 1)

func check_floor(f: int) -> void:
	var level: float = float(game.building.spec.levels[f])
	var ex: Dictionary = game.building.content.exhibits
	var boxes: Dictionary = {}
	for key in ex:
		if not str(key).begins_with("%d/" % f): continue
		var mount: Node3D = ex[key]; var art: Node = mount.get_node_or_null("Artifact") if mount else null
		if art == null: continue
		if str(art.get_meta("void_source", "")).contains("laser"): continue   # a laser's diagonal beam boxes most of the floor; the beam at z 7.9 passes 20 m east of the cabinets
		# a work area (a group with part_defaults) is tested part by part: its merged box covers the floor between its parts
		if art.get("part_defaults") is Dictionary:
			for part in art.get_children():
				if not part is Node3D or not (art.part_defaults as Dictionary).has(str(part.name)): continue
				var pb := world_bounds(part)
				if pb.size.length() < .05 or pb.size.y > 20.0: continue
				boxes["%s/%s" % [str(key), str(part.name)]] = pb
			continue
		var b := world_bounds(art)
		if b.size.length() < .05 or b.size.y > 20.0: continue   # a film's private stage is not a footprint
		if minf(b.size.x, b.size.z) < .12 and maxf(b.size.x, b.size.z) > 3.0: continue   # a laser's beam or a tape line crossing the floor is not furniture
		boxes[str(key)] = b
	for id in IDS:
		var key := "%d/%s" % [f, id]
		var mount: Node3D = ex.get(key); var art: Node = mount.get_node_or_null("Artifact") if mount else null
		check("floor %d: %s stands (rooms.json)" % [f, id], art != null)
		if art == null: continue
		var state: Dictionary = art.get_state() if art.has_method("get_state") else {}
		check("floor %d: %s is a %s machine with %d slots (%.2f x %.2f m)" % [f, id, state.get("kind", "?"), int(state.get("slots", 0)), float(state.get("width", 0)), float(state.get("height", 0))], int(state.get("stock", 0)) > 0)
		var under := ray(mount.global_position + Vector3(0, .5, 0), mount.global_position + Vector3(0, -.6, 0))
		check("floor %d: %s stands on the slab" % [f, id], not under.is_empty() and absf(under.position.y - level) < .1)
		var mine: AABB = boxes.get(key, AABB())
		var cuts: Array = []
		for other in boxes:
			if other == key or other.ends_with("vending-prefabs") or other.ends_with("vending-tools"): continue
			var o: AABB = boxes[other]
			if mine.intersects(o):
				var i: AABB = mine.intersection(o)
				if i.size.x > .05 and i.size.z > .05 and i.size.y > .05: cuts.append("%s by %.2f x %.2f m" % [other.substr(other.find("/") + 1), i.size.x, i.size.z])
		check("floor %d: %s cuts into no other work (box x %.1f..%.1f z %.1f..%.1f; %s)" % [f, id, mine.position.x, mine.end.x, mine.position.z, mine.end.z, "clear" if cuts.is_empty() else ", ".join(cuts)], cuts.is_empty())
		var hw: float = float(game.building.spec.width) / 2.0; var hd: float = float(game.building.spec.depth) / 2.0
		check("floor %d: %s is inside the slab's edges" % [f, id], mine.position.x > -hw and mine.end.x < hw and mine.position.z > -hd and mine.end.z < hd)
		var spec = game.building.spec; var over := []
		for shaft in spec.shafts:
			var sx := float(shaft.x); var hs := float(spec.shaft_width) / 2.0; var hz := float(spec.shaft_depth) / 2.0
			var ox := minf(mine.end.x, sx + hs) - maxf(mine.position.x, sx - hs); var oz := minf(mine.end.z, hz) - maxf(mine.position.z, -hz)
			if ox > .1 and oz > .1: over.append(str(shaft.name))
		check("floor %d: %s is clear of the shafts (%s)" % [f, id, "clear" if over.is_empty() else ", ".join(over)], over.is_empty())
	if DisplayServer.get_name() != "headless":
		var a: Node3D = ex.get("%d/vending-prefabs" % f); var b: Node3D = ex.get("%d/vending-tools" % f)
		if a and b:
			var mid: Vector3 = (a.global_position + b.global_position) * .5
			var front: Vector3 = a.global_basis.z   # the cabinet's front is its local +z
			var camera := Camera3D.new(); game.add_child(camera); camera.fov = 100; camera.environment = game.atmosphere.environment
			camera.global_position = mid + front * 2.6 + Vector3(0, 1.7, 0); camera.look_at(mid + Vector3(0, 1.0, 0)); camera.make_current()
			game.body.visible = false; game.status.hide(); game.charge_display.hide(); game.notice_time = 0
			if game.desktop_help != null: game.desktop_help.hide()
			await frames(8); await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(out.path_join("floor%02d_machines.png" % f))
			camera.queue_free()
