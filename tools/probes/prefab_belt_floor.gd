extends "res://tools/probes/void_game_probe.gd"
const Items := preload("res://commons/player/inventory_items.gd")
## THE PREFAB BELT ON FLOOR 7 (Point_Animatedcube) in the built tower (2026-11-21): the row from rooms.json stands on
## the slab between the two vending machines, cuts into no other work, knows its floor, starts on one earlier tray and
## then the things floor 7 gives; a key steps it; a later tray is a closed box. Photographed.
## Run: python tools/test_prefab_belt.py
var floors: Array = []
const IDS := ["prefab-belt"]

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
	if floors.is_empty(): floors = [preload("res://tools/probes/void_floor.gd").of("Point_Animatedcube")]
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
	print("[prefab_belt_floor] %d/%d checks pass" % [checks.size() - failed.size(), checks.size()])
	quit(0 if failed.is_empty() else 1)

func check_floor(f: int) -> void:
	var level: float = float(game.building.spec.levels[f])
	var ex: Dictionary = game.building.content.exhibits
	var boxes: Dictionary = {}
	for key in ex:
		if not str(key).begins_with("%d/" % f): continue
		var m: Node3D = ex[key]; var a: Node = m.get_node_or_null("Artifact") if m else null
		if a == null: continue
		if str(a.get_meta("void_source", "")).contains("laser"): continue
		if a.get("part_defaults") is Dictionary:
			for part in a.get_children():
				if not part is Node3D or not (a.part_defaults as Dictionary).has(str(part.name)): continue
				var pb := world_bounds(part)
				if pb.size.length() < .05 or pb.size.y > 20.0: continue
				boxes["%s/%s" % [str(key), str(part.name)]] = pb
			continue
		var b := world_bounds(a)
		if b.size.length() < .05 or b.size.y > 20.0: continue
		if minf(b.size.x, b.size.z) < .12 and maxf(b.size.x, b.size.z) > 3.0: continue
		boxes[str(key)] = b
	var key := "%d/prefab-belt" % f
	var mount: Node3D = ex.get(key); var art: Node = mount.get_node_or_null("Artifact") if mount else null
	check("floor %d: the prefab belt stands (rooms.json)" % f, art != null)
	if art == null: return
	for i in 600:
		var w0: Array = art.window()
		if w0.size() == 4 and w0.all(func(x): return bool(x.made)): break
		await frames(1)
	await frames(40)
	var state: Dictionary = art.get_state()
	var w: Array = state.window
	check("floor %d: the belt knows its floor (%d), %d on the timeline, trays [%s] states [%s]" % [f, int(state.given_floor), int(state.timeline), ", ".join(w.map(func(x): return str(x.id))), ", ".join(w.map(func(x): return str(x.state)))],
		int(state.given_floor) == f and w.size() == 4 and w[0].state == "earlier" and w[1].state == "here")
	check("floor %d: the earlier tray prints its line: %s" % [f, str(w[0].words).replace("
", " | ")], str(w[0].words).contains("association("))
	var under := ray(mount.global_position + Vector3(0, .5, 0), mount.global_position + Vector3(0, -.6, 0))
	check("floor %d: the belt stands on the slab" % f, not under.is_empty() and absf(under.position.y - level) < .1)
	var mine: AABB = boxes.get(key, AABB())
	var cuts: Array = []
	for other in boxes:
		if other == key: continue
		var o: AABB = boxes[other]
		if mine.intersects(o):
			var i: AABB = mine.intersection(o)
			if i.size.x > .05 and i.size.z > .05 and i.size.y > .05: cuts.append("%s by %.2f x %.2f m" % [other.substr(other.find("/") + 1), i.size.x, i.size.z])
	check("floor %d: the belt cuts into no other work (box x %.2f..%.2f z %.2f..%.2f; %s)" % [f, mine.position.x, mine.end.x, mine.position.z, mine.end.z, "clear" if cuts.is_empty() else ", ".join(cuts)], cuts.is_empty())
	var hw: float = float(game.building.spec.width) / 2.0; var hd: float = float(game.building.spec.depth) / 2.0
	check("floor %d: the belt is inside the slab's edges" % f, mine.position.x > -hw and mine.end.x < hw and mine.position.z > -hd and mine.end.z < hd)
	# room to stand: from the belt's front face outward at knee, hip and chest, at the lever, the middle and the keys
	var front: Vector3 = mount.global_basis.z; var side: Vector3 = mount.global_basis.x
	var nearest := 99.0; var what := ""
	for dx in [-1.3, 0.0, 1.3]:
		for dy in [.4, 1.0, 1.5]:
			var from: Vector3 = mount.global_position + side * dx + front * .48 + Vector3(0, dy, 0)
			var hit := ray(from, from + front * 4.0)
			if not hit.is_empty() and from.distance_to(hit.position) < nearest:
				nearest = from.distance_to(hit.position); what = str(hit.collider.get_path()).right(70)
	check("floor %d: %.2f m of free floor in front of the belt (nearest: %s)" % [f, nearest, what], nearest >= .9)
	# DIAGNOSTIC: do the things on the trays stay put? Bodies under each tray: frozen?, and drift over 5 s and a step.
	var before := {}
	for index in art.trays:
		var tr: Dictionary = art.trays[index]
		for rb in (tr.node as Node3D).find_children("*", "RigidBody3D", true, false):
			before[rb] = [(rb as Node3D).global_position - (tr.node as Node3D).global_position, tr.node]
			print("[prefab diag] %s %s freeze=%s mode=%d grav=%.1f top=%s sleeping=%s layer=%d" % [tr.id, rb.name, rb.freeze, rb.freeze_mode, rb.gravity_scale, rb.top_level, rb.sleeping, rb.collision_layer])
		var turn: Node3D = tr.get("turn")
		if turn != null:
			var bb: AABB = art.Vending._bounds(turn)
			print("[prefab diag] %s mesh bottom %.3f above the tray top, centre off %.3f, %.3f" % [tr.id, bb.position.y - (tr.node as Node3D).global_position.y, bb.get_center().x - turn.global_position.x, bb.get_center().z - turn.global_position.z])
	await frames(450)
	for rb in before:
		if not is_instance_valid(rb): continue
		var now: Vector3 = (rb as Node3D).global_position - (before[rb][1] as Node3D).global_position
		print("[prefab diag] %s moved %.3f m against its tray in 5 s" % [rb.name, now.distance_to(before[rb][0])])
	for index in art.trays:
		var tr2: Dictionary = art.trays[index]
		var turn2: Node3D = tr2.get("turn")
		if turn2 != null:
			var bb2: AABB = art.Vending._bounds(turn2)
			print("[prefab diag] after 5 s: %s mesh bottom %.3f above the tray top" % [tr2.id, bb2.position.y - (tr2.node as Node3D).global_position.y])
	await shot(mount, f, "start")
	var p0: float = art.pos
	art.get_node("Machine/StepLater").pressed.emit()
	await frames(90)
	check("floor %d: the LATER key steps one tray (%.2f -> %.2f)" % [f, p0, art.pos], is_equal_approx(art.pos, p0 + 1.0))
	var later := -1
	for i in state.ids.size():
		if art.state_of(art.timeline[i]) == "later": later = i; break
	if later >= 0:
		art.jump(maxi(later - 2, 0))
		for i in 600:
			var w1: Array = art.window()
			if w1.all(func(x): return bool(x.made)): break
			await frames(1)
		await frames(40)
		var t: Dictionary = art.trays[later]
		check("floor %d: the first later thing '%s' is a closed box printed '%s', no pick" % [f, str(t.id), str(t.words)], t.node.get_node_or_null("ClosedBox") != null and not t.has("shell") and str(t.words).begins_with("FLOOR "))
		await shot(mount, f, "edge")

func shot(mount: Node3D, f: int, name: String) -> void:
	if DisplayServer.get_name() == "headless": return
	var front: Vector3 = mount.global_basis.z
	var camera := Camera3D.new(); game.add_child(camera); camera.fov = 95; camera.environment = game.atmosphere.environment
	camera.global_position = mount.global_position + front * 1.25 + Vector3(0, 1.65, 0); camera.look_at(mount.global_position + Vector3(0, .95, 0)); camera.make_current()
	game.body.visible = false; game.status.hide(); game.charge_display.hide(); game.notice_time = 0
	if game.desktop_help != null: game.desktop_help.hide()
	await frames(8); await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join("floor%02d_belt_%s.png" % [f, name]))
	camera.queue_free()
