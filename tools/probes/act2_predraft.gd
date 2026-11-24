extends SceneTree
## Before the Void Book's Act II is written: what five floors really do when a body uses them.
##   Logic_Event       the marble run's door stop, the plate STAND HERE TO RESET under the game's own body, the hand lever
##   Color_Nails       what NAILS and SKIN change, and whether a colour can be put back
##   Color_Walls       which controls a body can reach (heights over the slab)
##   Pattern_Machines  the same question for the ceiling machines' consoles
##   Pattern_Temple    what AGE does to a surface and whether it turns back
##   PatternFullSpace  the body the first mirror shows, and its height against the bulbs
##
##   python tools/run_floor_probe.py <Map> act2_predraft.gd predraft.json <folder> --no-opening --opera-quiet

var folder := "res://ada_run/act2_predraft"
var eye: Camera3D
var content: Node3D
var floor_y := 0.0
var game: Node
var index := 0
var result := {}


func _initialize() -> void:
	run.call_deferred()


func _picture(file: String) -> void:
	for i in 8: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(folder.path_join(file))


func _look(from: Vector3, at: Vector3) -> void:
	eye.global_position = from
	eye.look_at(at, Vector3.UP)


func _wait(seconds: float) -> void:
	for i in int(seconds * 60.0): await physics_frame


func _work(id: String) -> Node3D:
	var mount := game.building.content.exhibits.get("%d/%s" % [index, id]) as Node3D
	if not is_instance_valid(mount): return null
	var inner := mount.get_node_or_null("Artifact") as Node3D
	return inner if inner != null else mount


func _at(n: Node3D) -> Array:
	var p := content.to_local(n.global_position)
	return [snappedf(p.x, 0.01), snappedf(n.global_position.y - floor_y, 0.01), snappedf(p.z, 0.01)]


func _note(check: String, ok: bool, detail = null) -> void:
	(result.checks as Array).append({"check": check, "ok": ok, "detail": detail})


func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): folder = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(folder)
	load("res://commons/void/room_source.gd").use_main_tower = true
	game = load("res://commons/void/void.tscn").instantiate()
	root.add_child(game); current_scene = game
	if game.body.get("scripted_input") != null:
		game.body.scripted_input = true; game.body.set_process_unhandled_input(false)
	game.scene_loaded(); game.scene_visible()
	index = int(game.checkpoint)
	result = {"floor": index, "map": str(game.building.content.data.floors[index].map), "checks": [], "passed": false}
	for i in 900: await physics_frame
	eye = root.get_camera_3d()
	var arrival := eye.global_position
	content = game.building.content.roots[index] as Node3D
	var ground := eye.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(arrival, arrival + Vector3.DOWN * 4.0, 1))
	floor_y = float(ground.position.y) if not ground.is_empty() else arrival.y - 1.6
	result["charge_at_start"] = float(game.health.get_charge())
	match str(result.map):
		"Logic_Event": await _logic()
		"Color_Nails": await _nails()
		"Pattern_Temple": await _temple()
		"PatternFullSpace": await _mirror()
		_: await _reach()
	var ok := true
	for c in result.checks:
		if not c.ok: ok = false
	result.passed = ok
	var file := FileAccess.open(folder.path_join("predraft.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "  "))
	file.close()
	print("ACT2_PREDRAFT ", JSON.stringify(result))
	quit(0 if ok else 1)


func _stand_body(at_global: Vector3) -> void:
	var body := game.body as CharacterBody3D
	body.velocity = Vector3.ZERO
	body.global_position = at_global
	await _wait(1.2)


func _logic() -> void:
	var run_node := _work("physics-play-marble-run")
	var ramp := _work("physics-play-extinguisher-ramp")
	if run_node == null or ramp == null:
		_note("marble run and extinguisher ramp stand on the floor", false); return
	await _wait(2.0)
	var before: Dictionary = run_node.call("get_state")
	result["marble_bodies"] = (before.bodies as Dictionary).keys()
	var stop_home: Vector3 = before.bodies["DoorStop"].at
	var marble_home: Vector3 = before.bodies["Marble0"].at
	result["plate_word"] = "STAND HERE TO RESET"
	var here := run_node.global_position
	game.body.set_physics_process(false); game.body.set_process(false)
	_look(here + run_node.global_basis * Vector3(-0.2, 1.1, 1.5), here + run_node.global_basis * Vector3(-0.6, 0.25, 0))
	await _picture("1_marble_run_held.png")
	run_node.call("release")
	await _wait(4.0)
	var after: Dictionary = run_node.call("get_state")
	var moved := 0
	for i in 5:
		if (after.bodies["Marble%d" % i].at as Vector3).distance_to(before.bodies["Marble%d" % i].at) > 0.3: moved += 1
	result["marbles_run"] = moved
	result["stop_after_release"] = after.bodies["DoorStop"].at
	_note("lifting the door stop lets five marbles run", moved == 5, moved)
	await _picture("2_marble_run_released.png")
	# the plate, under the game's own body
	var plate := run_node.get("plate") as Node3D
	result["plate_on_floor"] = _at(plate)
	game.body.set_physics_process(true); game.body.set_process(true)
	await _stand_body(plate.global_position + Vector3(0, 0.25, 0))
	await _wait(1.5)
	var back: Dictionary = run_node.call("get_state")
	result["body_on_floor_on_plate"] = (game.body as CharacterBody3D).is_on_floor()
	result["body_groups"] = (game.body as Node).get_groups()
	var stop_back := (back.bodies["DoorStop"].at as Vector3).distance_to(stop_home) < 0.05
	var marble_back := (back.bodies["Marble0"].at as Vector3).distance_to(marble_home) < 0.08
	_note("standing on the plate puts the door stop back", stop_back, back.bodies["DoorStop"].at)
	_note("standing on the plate puts the marbles back", marble_back, back.bodies["Marble0"].at)
	game.body.set_physics_process(false); game.body.set_process(false)
	eye = root.get_camera_3d()
	_look(here + run_node.global_basis * Vector3(-0.2, 1.1, 1.5), here + run_node.global_basis * Vector3(-0.6, 0.25, 0))
	await _picture("3_marble_run_reset.png")
	# the hand lever on the extinguisher ramp
	var rb: Dictionary = ramp.call("get_state")
	result["ramp_bodies"] = (rb.bodies as Dictionary).keys()
	result["ramp_has_lever"] = is_instance_valid(ramp.get("ramp_lever"))
	var there := ramp.global_position
	_look(there + ramp.global_basis * Vector3(0.2, 1.3, 2.6), there + ramp.global_basis * Vector3(-0.4, 0.4, 0))
	await _picture("4_ramp_held.png")
	ramp.call("release")
	await _wait(5.0)
	var ra: Dictionary = ramp.call("get_state")
	var rolled := (ra.bodies["Extinguisher"].at as Vector3).distance_to(rb.bodies["Extinguisher"].at)
	var boxes := 0
	for k in (ra.bodies as Dictionary).keys():
		if str(k).begins_with("Cardboard") and (ra.bodies[k].at as Vector3).distance_to(rb.bodies[k].at) > 0.1: boxes += 1
	result["extinguisher_rolled_m"] = snappedf(rolled, 0.01)
	result["boxes_moved"] = boxes
	_note("the lever lets the extinguisher go", rolled > 0.5, rolled)
	await _picture("5_ramp_released.png")


func _nails() -> void:
	var nails := _with_method(_work("f1_nail_color_controller_9_4"), "_on_color_values_changed")
	var skin := _with_method(_work("f1_hand_color_controller_5_4"), "_on_color_values_changed")
	var salon := _work("f1_nail_salon_7_9")
	if nails == null or skin == null or salon == null:
		_note("the salon and both controls stand on the floor", false); return
	var gm := root.get_node("GameManager")
	var nail0: Color = gm.call("get_nail_color")
	var skin0: Color = gm.call("get_hand_color")
	result["nail_at_arrival"] = nail0.to_html(false)
	result["skin_at_arrival"] = skin0.to_html(false)
	result["visitor_nail_material_found"] = nails.get("nail_material_left") != null
	result["nails_control_on_floor"] = _at(nails)
	result["skin_control_on_floor"] = _at(skin)
	game.body.set_physics_process(false); game.body.set_process(false)
	var s := salon.global_position
	_look(s + salon.global_basis * Vector3(0, 1.6, 7.0), s + salon.global_basis * Vector3(0, 2.4, 0))
	await _picture("1_salon_before.png")
	_set_colour(nails, Color(0.1, 0.75, 0.35))
	await _wait(0.5)
	var giant_nails: Array = salon.get("nail_materials")
	result["nail_after"] = (gm.call("get_nail_color") as Color).to_html(false)
	result["giant_nail_after"] = (giant_nails[0] as StandardMaterial3D).albedo_color.to_html(false) if not giant_nails.is_empty() else ""
	result["giant_nail_materials"] = giant_nails.size()
	_note("NAILS changes the big hand and its copy", result.giant_nail_after == result.nail_after and result.nail_after != result.nail_at_arrival, result.giant_nail_after)
	await _picture("2_salon_green_nails.png")
	_set_colour(skin, Color(0.35, 0.45, 0.8))
	await _wait(0.5)
	result["skin_after"] = (gm.call("get_hand_color") as Color).to_html(false)
	var giant_skin: Array = salon.get("skin_materials")
	result["giant_skin_after"] = (giant_skin[0] as StandardMaterial3D).albedo_color.to_html(false) if not giant_skin.is_empty() else ""
	await _picture("3_salon_blue_skin.png")
	_set_colour(nails, nail0)
	_set_colour(skin, skin0)
	await _wait(0.5)
	result["nail_restored"] = (gm.call("get_nail_color") as Color).to_html(false)
	_note("a colour comes back only by setting the same three values again", result.nail_restored == result.nail_at_arrival, "no reset control in either script")
	await _picture("4_salon_restored.png")


## The node under a work that carries the method (a scene's script is not always on its root).
func _with_method(start: Node3D, method: String) -> Node3D:
	if start == null: return null
	if start.has_method(method): return start
	for n in start.find_children("*", "", true, false):
		if n.has_method(method) and n is Node3D: return n as Node3D
	return null


## What a hand does at the control: the handle moves in the cage and the control hears its three values.
func _set_colour(control: Node, c: Color) -> void:
	var mapper = control.get("value_mapper")
	if mapper != null: mapper.call("set_values", c.r, c.g, c.b)
	control.call("_on_color_values_changed", c.r, c.g, c.b)


func _temple() -> void:
	var temple := _work("f3_pattern_temple_12_12")
	if temple == null:
		_note("the temple stands on the floor", false); return
	var console := temple.get("alien_console") as Node3D
	result["console"] = is_instance_valid(console)
	result["console_on_floor"] = _at(console) if is_instance_valid(console) else []
	result["surfaces"] = temple.get("SURFACES")
	game.body.set_physics_process(false); game.body.set_process(false)
	# three paces from the far wall, which is the surface the desk targets first
	var from := content.to_global(Vector3(5.0, 0, -5.6)); from.y = floor_y + 1.65
	var to := content.to_global(Vector3(5.0, 0, -9.0)); to.y = floor_y + 1.7
	var log: Array = []
	var materials: Array = temple.get("materials")
	for step in 6:
		var target := int(temple.get("target"))
		var mat := materials[target] as ShaderMaterial
		log.append({"press": step, "target": (temple.get("SURFACES") as Array)[target], "age_index": int((temple.get("dressing") as Array)[target]["age"]), "stain": mat.get_shader_parameter("stain_amount"), "cracks": mat.get_shader_parameter("crack_density")})
		_look(from, to)
		if step in [0, 2, 4, 5]: await _picture("age_%d.png" % step)
		if is_instance_valid(console): console.call("activate_key", "AGE")
		else: temple.call("_step", "age", 5)
		await _wait(0.4)
	result["age_log"] = log
	_note("AGE climbs in four steps", float(log[4].stain) > float(log[0].stain), log[4].stain)
	_note("the fifth press of AGE returns the surface to new", is_equal_approx(float(log[5].stain), float(log[0].stain)), log[5].stain)
	# where the keys hang
	if is_instance_valid(console):
		var keys: Array = []
		for n in console.find_children("*", "Label3D", true, false):
			var t := str((n as Label3D).text)
			if t.begins_with("◈ "): keys.append({"key": t, "at": _at(n as Node3D)})
		result["keys"] = keys
		var c := console.global_position
		_look(Vector3(c.x, floor_y + 1.65, c.z + 3.2), Vector3(c.x, floor_y + 1.6, c.z))
		await _picture("console.png")


func _mirror() -> void:
	var mirror := _work("pattern-fullspace-wear-mirror")
	if mirror == null:
		_note("the mirror stands on the floor", false); return
	var body := game.body as CharacterBody3D
	var m := mirror.global_position
	var stand := m + mirror.global_basis.z.normalized() * 2.0
	stand.y = floor_y + 0.2
	await _stand_body(stand)
	body.look_at(Vector3(m.x, body.global_position.y, m.z), Vector3.UP)
	await _wait(0.6)
	# what the body is, and how tall
	var care := game.find_child("CareBody", true, false)
	var meshes: Array = care.find_children("*", "MeshInstance3D", true, false) if care != null else []
	var low := INF; var high := -INF; var names := {}
	for mi in meshes:
		var inst := mi as MeshInstance3D
		if not inst.is_visible_in_tree() or inst.mesh == null: continue
		var box := inst.global_transform * inst.get_aabb()
		low = minf(low, box.position.y); high = maxf(high, box.end.y)
		var owner_name := str(inst.get_parent().name)
		names[owner_name] = int(names.get(owner_name, 0)) + 1
	result["body_mesh_parents"] = names
	result["body_feet_y"] = snappedf(low - floor_y, 0.01)
	result["body_top_y"] = snappedf(high - floor_y, 0.01)
	var wardrobe := game.get_node_or_null("StudioWardrobe")
	result["outfit_id"] = str(wardrobe.get("costume").get("outfit_id")) if wardrobe != null and wardrobe.get("costume") != null else "none"
	result["console_readout"] = str((mirror.get("readout") as Label).text) if mirror.get("readout") != null else ""
	result["mirror_scale"] = mirror.global_basis.y.length()
	result["bulbs_over_floor"] = []
	for i in 9: (result.bulbs_over_floor as Array).append(snappedf(m.y - floor_y + (0.20 + i * 0.30) * mirror.global_basis.y.length(), 0.01))
	game.body.set_physics_process(false); game.body.set_process(false)
	eye = root.get_camera_3d()
	_look(Vector3(stand.x, floor_y + 1.6, stand.z), Vector3(m.x, floor_y + 1.4, m.z))
	await _wait(0.5)
	await _picture("1_mirror_from_the_head.png")
	var side := stand + mirror.global_basis.x.normalized() * 2.4 + mirror.global_basis.z.normalized() * 1.2
	_look(Vector3(side.x, floor_y + 1.5, side.z), Vector3(stand.x, floor_y + 1.0, stand.z))
	await _picture("2_body_from_the_side.png")
	result["readout_after"] = str((mirror.get("readout") as Label).text) if mirror.get("readout") != null else ""
	_note("the body before the mirror wears no outfit", str(result.outfit_id) in ["", "none"], result.outfit_id)


func _reach() -> void:
	# every control on the floor a body could use, with its height over the slab
	var rows: Array = []
	var seen := {}
	var root_node := content
	for n in root_node.find_children("*", "", true, false):
		if not (n is Node3D): continue
		var kind := ""
		if n.has_signal("button_pressed"): kind = "button"
		elif n.has_signal("pressed") and not (n is Control): kind = "pressed"
		elif n.has_method("pick_up") and n is RigidBody3D: kind = "pickable"
		elif n is Area3D and (n as Area3D).monitoring and str(n.name).to_lower().contains("plate"): kind = "plate"
		if kind == "": continue
		var p := _at(n as Node3D)
		var owner_row := ""
		var walk: Node = n
		while walk != null and walk != root_node:
			if walk.get_parent() == root_node: owner_row = str(walk.name)
			walk = walk.get_parent()
		var key := "%s|%s|%.1f|%.1f|%.1f" % [owner_row, kind, p[0], p[1], p[2]]
		if seen.has(key): continue
		seen[key] = true
		rows.append({"row": owner_row, "kind": kind, "name": str(n.name), "at": p})
	result["controls"] = rows
	var reachable := 0
	for r in rows:
		if float(r.at[1]) >= 0.4 and float(r.at[1]) <= 1.9: reachable += 1
	result["controls_between_0.4_and_1.9_m"] = reachable
	result["controls_total"] = rows.size()
	_note("at least one control hangs where a standing body can reach it", reachable > 0, reachable)
