extends SceneTree
## Primitives_Prefab_Test: a floor to try the prefab system on (commons/artifacts/prefab_test).
##   rows test-area-west / test-area-east  a taped ground with a pile of twenty prefabs that clears when the visitor
##                                         steps over the tape (and only the one stepped into)
##   rows prefab-belt-west / -east         the prefab belt beside each area
##   row  white-block                      wall slabs with no colliders: a body walks in under the pagoda, through the
##                                         block and out of its far side; prefabs hidden in the slabs (its `hidden`),
##                                         none solid, none reaching out (tools/probes/white_block_glitch.gd measures
##                                         the ways against each other)
##   row  menu-board                       six sticker notes and four badge notes on the in-game menu
##   rows example-* / example-*-plinth     fourteen prefabs on plinths round the grounds: picked up, the item is in the
##                                         hand, and the black can stays black, the text tape keeps its text
##   rows police-line-* / edge-wall-*      blue barricades and short white walls at the edges round the block: each
##                                         stops a body, and a body gets through the gaps between them
## The floor is found by its map name, so it may stand anywhere in the tower.
##
##   python tools/run_floor_probe.py Primitives_Prefab_Test prefab_test_floor.gd prefab_test.json <folder> --no-opening --opera-quiet [--xr]

var game: Node
var folder := "res://ada_run/prefab_test"
var result := {}
var eye: Camera3D
var content: Node3D
var floor_y := 0.0


func _initialize() -> void:
	run.call_deferred()


func _check(what: String, ok: bool, more := {}) -> bool:
	var entry := {"check": what, "ok": ok}
	entry.merge(more)
	(result.checks as Array).append(entry)
	return ok


func _stand(from: Vector3, at: Vector3, seconds: float) -> void:
	eye.global_position = from
	eye.look_at(at, Vector3.UP)
	for i in int(seconds * 60.0): await physics_frame


## A point of the floor, in the floor's own metres (x east, z south), at a height above it.
func _at(x: float, z: float, above: float) -> Vector3:
	var p := content.to_global(Vector3(x, 0, z))
	return Vector3(p.x, floor_y + above, p.z)


func _picture(file: String) -> void:
	for i in 8: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(folder.path_join(file))


func _work(index: int, id: String) -> Node3D:
	var mount := game.building.content.exhibits.get("%d/%s" % [index, id]) as Node3D
	return mount.get_node_or_null("Artifact") as Node3D if is_instance_valid(mount) else null


## Walk a body straight at a place, sliding along what it meets: true when it arrives.
func _walk(walker: CharacterBody3D, to: Vector3, seconds := 8.0) -> bool:
	for i in int(60.0 * seconds):
		var left := to - walker.global_position
		left.y = 0.0
		if left.length() < 0.12: return true
		walker.velocity = left.normalized() * 1.4
		walker.move_and_slide()
		await physics_frame
	return false


func _done() -> void:
	result.passed = (result.checks as Array).all(func(c): return c.ok)
	var file := FileAccess.open(folder.path_join("prefab_test.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "  "))
	file.close()
	quit()


func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): folder = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(folder)
	load("res://commons/void/room_source.gd").use_main_tower = true
	game = load("res://commons/void/void.tscn").instantiate()
	if OS.get_cmdline_user_args().has("--xr"): game.force_xr = true
	root.add_child(game); current_scene = game
	if game.body.get("scripted_input") != null:
		game.body.scripted_input = true; game.body.set_process_unhandled_input(false)
	game.scene_loaded(); game.scene_visible()
	var index := int(game.checkpoint)
	result = {"floor": index, "checks": [], "passed": false}
	for i in 900: await physics_frame
	eye = root.get_camera_3d()
	var arrival := eye.global_position
	content = game.building.content.roots[index] as Node3D
	var space := eye.get_world_3d().direct_space_state
	var ground := space.intersect_ray(PhysicsRayQueryParameters3D.create(arrival, arrival + Vector3.DOWN * 4.0, 1))
	floor_y = float(ground.position.y) if not ground.is_empty() else arrival.y - 1.6
	var west := _work(index, "test-area-west")
	var east := _work(index, "test-area-east")
	var block := _work(index, "white-block")
	var board := _work(index, "menu-board")
	var belts := [_work(index, "prefab-belt-west"), _work(index, "prefab-belt-east")]
	if not _check("the six rows stand on the floor", west != null and east != null and block != null and board != null and belts[0] != null and belts[1] != null):
		_done(); return
	game.body.set_physics_process(false)
	game.body.set_process(false)
	result["arrival_on_floor_m"] = [snappedf(content.to_local(arrival).x, 0.01), snappedf(content.to_local(arrival).z, 0.01)]
	await _stand(arrival, arrival + Vector3(0, -0.15, -6.0), 1.0)
	await _picture("1_from_the_arrival.png")
	# ------------------------------------------------------------------ the two test areas
	for i in 360: await physics_frame
	var piles := {}
	for area: Node3D in [west, east]:
		piles[area.name] = {"things": (area.get("pile") as Array).size(), "built": area.get("built"), "cleared": area.get("cleared"), "chosen": (area.get("chosen") as Array).slice(0, 6)}
	result["piles"] = piles
	_check("each area holds a pile of twenty prefabs, standing, while nobody is in it",
		[west, east].all(func(a): return (a.get("pile") as Array).size() == int(a.get("count")) and bool(a.get("built")) and not bool(a.get("cleared"))), {"piles": piles})
	var kinds := {}
	for id in west.get("chosen"): kinds[id] = true
	_check("a pile is drawn from more than a few kinds of prefab", kinds.size() >= 8, {"kinds": kinds.size()})
	# a pile stops nobody: a ray through its middle at knee height meets no body
	var mid := west.global_position
	var through := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(mid.x - 2.4, floor_y + 0.5, mid.z), Vector3(mid.x + 2.4, floor_y + 0.5, mid.z), 1))
	_check("a pile has no colliders", through.is_empty(), {"met": str(through.collider.name) if not through.is_empty() else ""})
	var pile_box := AABB()
	var first := true
	for thing: Node3D in west.get("pile"):
		for part in thing.find_children("*", "MeshInstance3D", true, false):
			var mesh := part as MeshInstance3D
			if mesh.mesh == null or not mesh.is_visible_in_tree(): continue
			var b: AABB = mesh.global_transform * mesh.get_aabb()
			pile_box = b if first else pile_box.merge(b)
			first = false
	result["pile_size_m"] = [snappedf(pile_box.size.x, 0.01), snappedf(pile_box.size.y, 0.01), snappedf(pile_box.size.z, 0.01)]
	_check("the pile stands on the floor and is a pile, not a spread", absf(pile_box.position.y - floor_y) < 0.25 and pile_box.size.x < 6.0 and pile_box.size.y > 0.8, {"size_m": result.pile_size_m, "bottom_over_floor_m": snappedf(pile_box.position.y - floor_y, 0.01)})
	await _stand(_at(-12.6, 5.4, 1.7), _at(-17.2, -0.6, 0.7), 0.3)
	await _picture("2_area_a_with_its_pile.png")
	# step over the tape of area A: its pile clears, B's stays
	await _stand(_at(-17.2, 4.6, 1.65), _at(-17.2, -0.6, 0.8), 1.2)
	var cleared_a := bool(west.get("cleared"))
	var pile_node := west.get_node_or_null("Pile")
	_check("stepping over the tape clears that area's pile", cleared_a and (pile_node == null or not (pile_node as Node3D).visible or (pile_node as Node3D).scale.x < 0.1), {"cleared": cleared_a})
	_check("the other area keeps its pile", not bool(east.get("cleared")) and (east.get("pile") as Array).size() == int(east.get("count")))
	await _picture("3_area_a_cleared.png")
	# leaving does not bring it back, this visit
	await _stand(_at(-12.6, 5.4, 1.7), _at(-17.2, -0.6, 0.7), 1.0)
	_check("the pile stays cleared after the visitor leaves", bool(west.get("cleared")))
	# the belts
	var trays := belts.map(func(b): return (b.get("timeline") as Array).size() if b.get("timeline") != null else -1)
	_check("a belt stands beside each area with the prefab timeline on it", trays.all(func(n): return n > 10), {"timeline": trays})
	await _stand(_at(-15.2, 4.9, 1.6), _at(-17.2, 7.7, 1.0), 0.3)
	await _picture("4_the_belt_of_area_a.png")
	# ------------------------------------------------------------------ the white block
	var side: float = block.get("side")
	for i in 600:
		if bool(block.get("built")): break
		await process_frame
	var way := str(block.get("hidden"))
	if way == "primitives":
		_check("the block holds its crowd of primitives", int(block.get("shape_count")) >= 60 and (block.get("shapes") as Array).size() == 7, {"primitives": block.get("shape_count"), "kinds": (block.get("shapes") as Array).size()})
	else:
		var hid := {}
		for row: Dictionary in block.get("plan"): hid[str(row.id)] = true
		result["hidden"] = {"way": way, "prefabs": (block.get("things") as Array).size(), "lattice_meshes": (block.get("grids") as Array).size(), "kinds": hid.keys()}
		_check("the block hides the catalogue's prefabs in its slabs, all of them made", bool(block.get("built")) and (block.get("things") as Array).size() >= 12 and hid.size() >= 8, result.hidden)
	_check("the block's middle is inside it and the arrival is not", bool(block.call("holds", block.global_position + Vector3.UP)) and not bool(block.call("holds", arrival)))
	var walker := CharacterBody3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.3
	capsule.height = 1.8
	var walker_shape := CollisionShape3D.new()
	walker_shape.shape = capsule
	walker.add_child(walker_shape)
	walker.collision_layer = 0
	walker.collision_mask = 1
	walker.motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	root.add_child(walker)
	var here := block.global_position
	walker.global_position = Vector3(here.x, floor_y + 0.93, here.z) + block.global_basis.z * (side * 0.5 + 2.6)
	var legs := []
	for stop: Array in [["under the pagoda, into the wall", side * 0.5 - 0.6], ["the middle of the block", 0.0], ["out of the far wall", -side * 0.5 - 1.2]]:
		var to := Vector3(here.x, floor_y + 0.93, here.z) + block.global_basis.z * float(stop[1])
		legs.append([stop[0], await _walk(walker, to, 12.0)])
	_check("a body 0.6 m wide and 1.8 m tall walks in under the pagoda, through the block and out of its far side", legs.all(func(l): return l[1]), {"legs": legs})
	# and from the side, through a wall with no pagoda
	walker.global_position = Vector3(here.x, floor_y + 0.93, here.z) + block.global_basis.x * (side * 0.5 + 1.2)
	_check("the same body walks in through a side wall as well", await _walk(walker, Vector3(here.x, floor_y + 0.93, here.z) + block.global_basis.x * (side * 0.5 - 2.0), 8.0))
	walker.queue_free()
	# everything inside stays inside: a primitive's place plus half its diagonal, a prefab's meshes, the lattice's cells
	var furthest := -99.0
	var tall := float(block.get("height"))
	for many: MultiMeshInstance3D in (block.get("shapes") as Array) + (block.get("grids") as Array):
		var to_block := block.global_transform.affine_inverse() * many.global_transform
		var reach_mesh := many.multimesh.mesh.get_aabb() if many.multimesh.mesh != null else AABB()
		for i in many.multimesh.instance_count:
			var t := to_block * many.multimesh.get_instance_transform(i)
			var box: AABB = t * reach_mesh
			furthest = maxf(furthest, maxf(maxf(maxf(-box.position.x, box.end.x), maxf(-box.position.z, box.end.z)) - side * 0.5, maxf(box.end.y - tall, -box.position.y)))
	for thing: Node3D in block.get("things"):
		var box: AABB = block.call("_local_box", thing)
		furthest = maxf(furthest, maxf(maxf(maxf(-box.position.x, box.end.x), maxf(-box.position.z, box.end.z)) - side * 0.5, maxf(box.end.y - tall, -box.position.y)))
	_check("nothing hidden in the block reaches out of it", furthest <= 0.02, {"furthest_outside_m": snappedf(furthest, 0.01)})
	# the block is full: along the walk from the south face to the north face, at eye height, nearly every point
	# is inside a slab, and the eye crosses a slab's face every few centimetres
	var slabs := (block.get("walls") as MultiMeshInstance3D).multimesh
	var boxes: Array[Transform3D] = []
	for i in slabs.instance_count: boxes.append(slabs.get_instance_transform(i).affine_inverse())
	var in_slab := 0
	var crossings := 0
	var was := false
	var samples := 1000
	for n in samples:
		var p := Vector3(0.3, 1.6, side * 0.5 - (n + 0.5) * side / samples)
		var held := false
		for box in boxes:
			var q := box * p
			if absf(q.x) <= 0.5 and absf(q.y) <= 0.5 and absf(q.z) <= 0.5:
				held = true
				break
		if held: in_slab += 1
		if held != was: crossings += 1
		was = held
	result["block"] = {"slabs": int(block.get("slab_count")), "segments": slabs.instance_count, "share_of_the_walk_inside_a_slab": snappedf(float(in_slab) / samples, 0.001), "faces_crossed": crossings}
	_check("the block is full of slabs: no open room on the way through", int(block.get("slab_count")) >= 40 and float(in_slab) / samples > 0.9 and crossings >= 80, result.block)
	# a hidden prefab may carry a body of its own: it is made inert (no layer, no mask, every shape off)
	var bodies := block.find_children("*", "CollisionObject3D", true, false)
	var solid := bodies.filter(func(b): return (b as CollisionObject3D).collision_layer != 0 or (b as CollisionObject3D).collision_mask != 0 \
		or b.find_children("*", "CollisionShape3D", true, false).any(func(c): return not (c as CollisionShape3D).disabled))
	_check("the block has no collider of any kind", solid.is_empty(), {"collision_objects": bodies.size(), "solid": solid.map(func(b): return str(b.get_path()).get_slice("Artifact/", 1))})
	var top := floor_y + float(block.get("height"))
	var over := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(here.x + 6.5, floor_y + 0.5, here.z), Vector3(here.x + 6.5, floor_y + 9.0, here.z), 1))
	_check("the block and its pagoda stand under the ceiling", not over.is_empty() and top < float(over.position.y) - 0.05, {"block_top_m": snappedf(top - floor_y, 0.01), "ceiling_m": snappedf(float(over.position.y) - floor_y, 0.01) if not over.is_empty() else -1.0})
	var gate := here + block.global_basis.z * (side * 0.5)
	await _stand(Vector3(gate.x + 2.9, floor_y + 1.65, gate.z) + block.global_basis.z * 3.9, Vector3(gate.x, floor_y + 2.4, gate.z), 0.3)
	await _picture("5_the_pagoda_at_the_wall.png")
	await _stand(Vector3(here.x, floor_y + 1.65, here.z) + block.global_basis.z * (side * 0.5 - 0.7), Vector3(here.x, floor_y + 2.0, here.z) - block.global_basis.z * 2.0, 0.3)
	await _picture("6_one_step_inside.png")
	await _stand(Vector3(here.x - 3.2, floor_y + 1.65, here.z) - block.global_basis.z * 3.0, Vector3(here.x + 2.5, floor_y + 2.2, here.z) + block.global_basis.z * 2.0, 0.3)
	await _picture("7_inside_the_block.png")
	await _stand(Vector3(here.x + 9.4, floor_y + 3.2, here.z) + block.global_basis.z * 9.0, Vector3(here.x, floor_y + 2.2, here.z), 0.3)
	await _picture("8_the_block_from_outside.png")
	# ------------------------------------------------------------------ the menu board
	var notes: Array = board.get("notes")
	var badges: Array = board.get("badges")
	var states := badges.map(func(b): return [b.verb, (b.state as Label3D).text])
	result["badge_notes"] = states
	_check("the board holds six sticker notes and four badge notes", notes.size() == 6 and badges.size() == 4, {"notes": notes.size(), "badges": badges.size()})
	_check("every badge note says whether the verb is the visitor's", states.all(func(s): return s[1] in ["LOCKED", "YOURS"]), {"states": states})
	var said := ""
	for label in board.find_children("*", "Label3D", true, false): said += (label as Label3D).text + "\n"
	_check("the board names the button that opens the menu, on the headset and on the desktop", said.contains("right A") and said.contains("Desktop: I"), {})
	var face := board.global_position + Vector3.UP * 1.5
	await _stand(face + board.global_basis.z * 3.1 + Vector3.UP * 0.1, face, 0.3)
	await _picture("9_the_menu_board.png")
	await _stand(face + board.global_basis.z * 1.25 - board.global_basis.x * 0.75 + Vector3.UP * 0.1, face - board.global_basis.x * 0.75, 0.3)
	await _picture("10_the_board_near_its_notes.png")
	await _stand(face + board.global_basis.z * 1.1 + board.global_basis.x * 1.05 + Vector3.UP * 0.05, face + board.global_basis.x * 1.05, 0.3)
	await _picture("11_the_board_near_its_badges.png")
	var drawn := 0
	for work: Node3D in [west, east, block, board]:
		for part in work.find_children("*", "MeshInstance3D", true, false):
			var mesh := (part as MeshInstance3D).mesh
			if mesh == null or mesh.get_surface_count() == 0: continue
			var arrays := mesh.surface_get_arrays(0)
			drawn += (arrays[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3 if arrays[Mesh.ARRAY_INDEX] != null else (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3
	result["triangles_outside_multimeshes"] = drawn
	await _stand(_at(20.0, 8.6, 3.4), _at(4.0, 0.0, 1.0), 0.3)
	await _picture("12_the_floor_from_a_corner.png")
	# ------------------------------------------------------------------ the examples on their plinths
	var items = load("res://commons/player/inventory_items.gd")
	items.collected_path = folder.path_join("collected.json")       # never the visitor's own collection
	var plinths := []
	var empty := []
	for row: Dictionary in game.building.content.data.floors[index].artifacts:
		if str(row.artifact) != "association_plinth": continue
		var plinth := _work(index, str(row.id))
		plinths.append(plinth)
		if plinth == null or not is_instance_valid(plinth.get("example")): empty.append(str(row.id))
	_check("fourteen prefabs stand on plinths round the grounds, each plinth holding its example", plinths.size() == 14 and empty.is_empty(), {"plinths": plinths.size(), "without_an_example": empty})
	# the picture first: once something is collected the hand shows its own preview where the eye aims
	await _stand(_at(-17.2, -4.6, 1.7), _at(-17.2, -8.3, 1.0), 0.3)
	await _picture("15_the_examples_north_of_area_a.png")
	var hands: Array = get_nodes_in_group("inventory_hands")
	var taken := {}
	for id in ["example-spray-paint-plinth", "example-tape-plinth", "example-tyre-plinth"]:
		var plinth := _work(index, id)
		if plinth == null: continue
		plinth.call("_on_picked_up")
		for i in 6: await physics_frame
		var item := str(plinth.get("item"))
		taken[item] = {"collected": (items.collected() as Array).has(item), "settings": (hands[0].get("values") as Dictionary).get(item, {}) if not hands.is_empty() else {}}
	result["taken_from_plinths"] = taken
	_check("picking an example up collects its item", taken.size() == 3 and taken.values().all(func(t): return t.collected), {"taken": taken})
	_check("the black can stays black and the text tape keeps its text", not hands.is_empty() and str((taken.get("spray_paint", {}).get("settings", {}) as Dictionary).get("pigment", "")) == "16191e"
		and str((taken.get("tape", {}).get("settings", {}) as Dictionary).get("note", "")) == "PREFAB TEST", {"hands": hands.size()})
	# ------------------------------------------------------------------ the edges round the block
	var lines := 0
	var short_walls := 0
	for row: Dictionary in game.building.content.data.floors[index].artifacts:
		if str(row.artifact) == "do_not_cross_barrier" and _work(index, str(row.id)) != null: lines += 1
		if str(row.artifact) == "edge_wall" and _work(index, str(row.id)) != null: short_walls += 1
	_check("seven blue police barricades and six short walls stand at the edges round the block", lines == 7 and short_walls == 6, {"barricades": lines, "walls": short_walls})
	var guard := CharacterBody3D.new()
	var guard_shape := CollisionShape3D.new()
	var guard_capsule := CapsuleShape3D.new()
	guard_capsule.radius = 0.3
	guard_capsule.height = 1.8
	guard_shape.shape = guard_capsule
	guard.add_child(guard_shape)
	guard.collision_layer = 0
	guard.collision_mask = 1
	guard.motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	root.add_child(guard)
	var tries := {}
	for run: Array in [["the north barricade", 0.0, -7.4, 0.0, -9.8], ["the gap beside it", -2.25, -7.4, -2.25, -9.8], ["the north-west wall", -7.3, -7.4, -7.3, -9.8],
			["the barricade behind the arrival", -0.4, 7.9, -0.4, 9.9], ["the barricade at shaft A", -5.6, 0.0, -7.6, 0.0], ["the open end of shaft A", -5.6, 2.4, -7.6, 2.4]]:
		guard.global_position = _at(float(run[1]), float(run[2]), 0.93)
		tries[run[0]] = await _walk(guard, _at(float(run[3]), float(run[4]), 0.93), 5.0)
	guard.queue_free()
	# the gap on the other side of the middle barricade is where the tower's own floor sign stands (found by a ray
	# when a body would not pass there): the west gap is the open one
	result["at_the_edges"] = tries
	_check("a barricade or a wall stops a body", not tries["the north barricade"] and not tries["the north-west wall"] and not tries["the barricade behind the arrival"] and not tries["the barricade at shaft A"], tries)
	_check("and a body still gets through the gaps: safer, not safe", tries["the gap beside it"] and tries["the open end of shaft A"], tries)
	await _stand(_at(6.4, -7.3, 1.9), _at(-2.0, -8.6, 0.7), 0.3)
	await _picture("16_the_police_line_at_the_north_edge.png")
	await _stand(_at(-3.2, 5.9, 2.0), _at(-0.2, 8.8, 0.7), 0.3)
	await _picture("17_behind_the_arrival.png")
	# ------------------------------------------------------------------ the doors: Portals -> here -> Melencolia
	var source = load("res://commons/void/room_source.gd")
	var portals := int(source.spine_floor("Primitives_Portals"))
	var melencolia := int(source.spine_floor("Primitives_Melencolia"))
	var onward := _work(index, "on-to-melencolia")
	var back := _work(index, "back-to-portals")
	_check("two doors stand by the arrival: on to Melencolia, back to Portals", onward != null and back != null and onward.get_node_or_null("TransferKey") != null and back.get_node_or_null("TransferKey") != null
		and int(source.spine_floor(str(onward.get("destination")))) == melencolia and int(source.spine_floor(str(back.get("destination")))) == portals,
		{"portals_floor": portals, "melencolia_floor": melencolia, "this_floor": index})
	await _stand(_at(1.2, 5.6, 1.65), _at(4.5, 7.7, 1.4), 0.3)
	await _picture("13_the_two_doors.png")
	if onward == null or back == null:
		_done(); return
	# back to Portals; there the door that leads here; through it; then on to Melencolia
	back.call("_transfer")
	for i in 420: await physics_frame
	_check("the door BACK TO PORTALS puts the visitor on the Portals floor", int(game.checkpoint) == portals, {"checkpoint": int(game.checkpoint)})
	var here_door: Node3D = null
	for i in 900:
		here_door = _work(portals, "to-prefab-test")
		if here_door != null: break
		await physics_frame
	var free := false
	if here_door != null:
		for i in 60: await physics_frame
		var probe_shape := SphereShape3D.new()
		probe_shape.radius = 0.4
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = probe_shape
		query.collision_mask = 1
		query.transform = Transform3D(Basis.IDENTITY, here_door.global_position + here_door.global_basis.z * 1.0 + Vector3.UP * 1.0)
		free = eye.get_world_3d().direct_space_state.intersect_shape(query, 4).is_empty()
		var face_at := here_door.global_position + Vector3.UP * 1.3
		await _stand(face_at + here_door.global_basis.z * 3.4 + here_door.global_basis.x * 1.2, face_at, 0.3)
		await _picture("14_the_door_on_the_portals_floor.png")
	_check("on the Portals floor a door PREFAB TEST stands with room in front of it", here_door != null and free and str(here_door.get("destination")) == "Primitives_Prefab_Test", {"found": here_door != null, "free_in_front": free})
	if here_door != null:
		here_door.call("_transfer")
		for i in 420: await physics_frame
	_check("that door puts the visitor on the Prefab Test floor", int(game.checkpoint) == index, {"checkpoint": int(game.checkpoint)})
	var again: Node3D = null
	for i in 900:
		again = _work(index, "on-to-melencolia")
		if again != null: break
		await physics_frame
	if again != null:
		again.call("_transfer")
		for i in 420: await physics_frame
	_check("the door ON TO MELENCOLIA puts the visitor on the Melencolia floor", again != null and int(game.checkpoint) == melencolia, {"checkpoint": int(game.checkpoint)})
	_done()
