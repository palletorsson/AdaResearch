extends "res://tools/probes/void_game_probe.gd"
## PALLE'S FOUR PRIMITIVES ASKS IN THE TOWER (2026-11-05). In the actual Void:
##   floor 3   point-room: the black lining stands in the workstation's bay (or on its own floor), eight lettered points
##             hang; point B let go beside A JOINS it (the snap system) and the wall writes "A - B" with the length;
##             moved apart the length follows; the two-points line stands inside the room
##   floor 4   primitives-standing-grid: a net 8 x 4 m in a solid frame (a ray meets a post; a ray through the net does not)
##   floor 9   primitives-form-table: 21 parts; the example column stands as a stack; a drum let go over the column's
##             top SNAPS onto it, centred and upright; lifting the column's base lifts the four parts on it; a part let
##             go off the table FALLS
##   floor 12  durer-box: the sculpture is inside the three walls; the grid fills the open front; the sight stands
##             across the shaft at eye height; the floor's route and the moved museum works keep out of the walls
## Windowed, it photographs each: the room from inside, the grid, the table, and the engraving THROUGH the grid from
## the sight's eye-piece. Run: python tools/test_primitives_rooms.py

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out = arg.trim_prefix("--out=")
	Engine.physics_ticks_per_second = 90
	preload("res://commons/void/room_source.gd").use_main_tower = true
	load("res://commons/void/game.gd").requested_floor = 3
	game = load("res://commons/void/void.tscn").instantiate(); game.force_xr = false
	root.add_child(game); current_scene = game; game.scene_loaded(); game.scene_visible(); game.set_process_unhandled_key_input(false)
	game.body.scripted_input = true; game.body.set_process_unhandled_input(false)
	await frames(90)
	await _floor3()
	await _floor4()
	await _floor9()
	await _floor12()
	finish()

func _art(f: int, id: String) -> Node3D:
	var mount: Node3D = game.building.content.exhibits.get("%d/%s" % [f, id])
	return mount.get_node_or_null("Artifact") if mount else null

func _go(f: int) -> void:
	game.place_player(game.spawn_for(f)); await frames(150)

func _floor3() -> void:
	await _go(3)
	var room: Node3D = _art(3, "point-room")
	check("floor 3: the point room is mounted", room != null)
	if room == null: return
	await frames(120)   # the gate search and the own-floor wait
	var lining: Node3D = room.get_node_or_null("Lining")
	var bay_floor := room.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(room.global_position + Vector3(0, .5, 0), room.global_position + Vector3(0, -.4, 0), 1))
	check("floor 3: black lining (%d panels), a solid floor under the room (%s), the gate %s" % [lining.get_child_count() if lining else 0, "the bay's" if not room.own_floor else "its own", "opened" if room.gate_opened else "absent / not opened"],
		lining != null and lining.get_child_count() == 5 and not bay_floor.is_empty())
	var balls: Array = room.balls
	check("floor 3: %d lettered points hang in the dark, none in the bay's middle" % balls.size(), balls.size() == 8 and balls.all(func(b): var l: Vector3 = room.to_local(b.global_position); return Vector2(l.x, l.z).length() > 1.2))
	# B let go beside A: they join; the wall says so and measures
	var a: Node3D = balls[0]; var b: Node3D = balls[1]
	b.picked_up.emit(b)
	b.global_position = a.global_position + Vector3(.25, 0, 0)
	b.dropped.emit(b)
	await frames(6)
	var joined: bool = room.manager.are_points_connected(a, b)
	var text0: String = room.measure.text
	b.global_position = a.global_position + Vector3(1.5, 0, .4)
	await frames(6)
	var text1: String = room.measure.text
	var l1: Array = room.lines()
	check("floor 3: B let go beside A joins it (%s); the wall reads \"%s\"; moved 1.55 m apart it reads \"%s\" (%s)" % [str(joined), text0.replace("\n", " / "), text1.replace("\n", " / "), str(l1)],
		joined and text0.begins_with("A - B") and "0.25 m" in text0 and "1.55 m" in text1 and l1.size() == 1)
	var tpl: Node3D = null
	for key in game.building.content.exhibits:
		if str(key).begins_with("3/museum-point_lines-60-24"): tpl = game.building.content.exhibits[key]
	var inside: bool = tpl != null and absf(room.to_local(tpl.global_position).x) < 3.2 and absf(room.to_local(tpl.global_position).z) < 3.2
	check("floor 3: the two-points line stands inside the room (%s)" % (str(room.to_local(tpl.global_position).snapped(Vector3.ONE * .1)) if tpl else "missing"), inside)
	await _photo(3, room, Vector3(0, 1.6, 2.6), Vector3(0, 1.8, -3.3), "03_point_room")

func _floor4() -> void:
	await _go(4)
	var grid: Node3D = _art(4, "primitives-standing-grid")
	check("floor 4: the standing grid is mounted", grid != null)
	if grid == null: return
	var net: MeshInstance3D = grid.get_node_or_null("NetBounds")
	var box: AABB = net.get_aabb() if net else AABB()
	var space := grid.get_world_3d().direct_space_state
	var post := space.intersect_ray(PhysicsRayQueryParameters3D.create(grid.to_global(Vector3(-4.08, 2.0, 1.0)), grid.to_global(Vector3(-4.08, 2.0, -1.0)), 1))
	var through := space.intersect_ray(PhysicsRayQueryParameters3D.create(grid.to_global(Vector3(0, 2.3, 1.0)), grid.to_global(Vector3(0, 2.3, -1.0)), 1))
	check("floor 4: a net %.1f x %.1f m (%d strings) in a frame - a ray meets a post (%s), a ray through the net meets nothing (%s)" % [box.size.x, box.size.y, grid.get_node("Net").multimesh.instance_count, str(not post.is_empty()), str(through.is_empty())],
		absf(box.size.x - 8.0) < .01 and absf(box.size.y - 4.0) < .01 and not post.is_empty() and through.is_empty())
	await _photo(4, grid, Vector3(-3.0, 1.7, 7.5), Vector3(0, 2.0, 0), "04_standing_grid")

func _floor9() -> void:
	await _go(9)
	var table: Node3D = _art(9, "primitives-form-table")
	check("floor 9: the form table is mounted", table != null)
	if table == null: return
	await frames(10)
	var parts: Array = table.parts
	var column: Array = parts.slice(parts.size() - 5)
	var stacked := true
	for i in range(1, column.size()):
		stacked = stacked and table.support.get(column[i].body) == column[i - 1].body
	check("floor 9: %d parts on the table; the example column of five stands as a stack (%s)" % [parts.size(), str(stacked)], parts.size() == 21 and stacked)
	# a drum let go over the column's top snaps onto it
	var drum: RigidBody3D = parts[1].body
	var top_body: RigidBody3D = column[4].body
	var top: Vector3 = table.top_of(top_body)
	drum.picked_up.emit(drum)
	drum.global_transform = Transform3D(Basis(Vector3(0, 0, 1), .3) * Basis(Vector3.UP, 1.1), top + Vector3(.05, .06, -.03))
	drum.dropped.emit(drum)
	await frames(4)
	var snapped_on: bool = table.support.get(drum) == top_body and drum.global_position.distance_to(top) < .002 and drum.global_basis.y.dot(Vector3.UP) > .999
	check("floor 9: a drum let go 6 cm over the column's top, tilted, snaps onto it: centred (%.1f mm off), upright (%s), frozen (%s)" % [drum.global_position.distance_to(top) * 1000.0, str(drum.global_basis.y.dot(Vector3.UP) > .999), str(drum.freeze)], snapped_on and drum.freeze)
	# lifting the column's base lifts the five parts on it (the four, and the drum)
	var base: RigidBody3D = column[0].body
	base.picked_up.emit(base)
	var before: Vector3 = drum.global_position
	base.global_position += Vector3(0, .3, .2)
	await frames(2)
	var rides: bool = table.carried.size() == 5 and drum.global_position.distance_to(before + Vector3(0, .3, .2)) < .002
	base.dropped.emit(base)   # let go over the table: it stands where it is, the stack with it
	await frames(4)
	var restood: bool = base.freeze and table.support.get(drum) == top_body and absf(table.to_local(base.global_position).y - table.top) < .002
	check("floor 9: lifting the base lifts the stack of %d with it (%s); let go over the table they stand again (%s)" % [table.carried.size() if table.holding else 5, str(rides), str(restood)], rides and restood)
	# a part let go off the table falls
	var cone: RigidBody3D = parts[5].body
	cone.picked_up.emit(cone)
	cone.global_position = table.to_global(Vector3(0, 1.2, table.width * .5 + .8))
	cone.dropped.emit(cone)
	await frames(60)
	var fell: bool = not cone.freeze and table.to_local(cone.global_position).y < .3
	check("floor 9: a cone let go beside the table falls (y %.2f after 60 frames, free %s)" % [table.to_local(cone.global_position).y, str(not cone.freeze)], fell)
	await _photo(10, table, Vector3(1.6, 1.5, 1.6), Vector3(0.3, .9, 0), "09_form_table")

func _floor12() -> void:
	await _go(12)
	var box: Node3D = _art(12, "durer-box")
	check("floor 12: the box round the sculpture is mounted", box != null)
	if box == null: return
	var hall: Node3D = game.building.content.exhibits.get("12/hall")
	var eng: Node3D = hall.find_child("MelencoliaEngraving", true, false) if hall else null
	var inner: AABB = box.inner()
	var eb: AABB = (eng.global_transform * mesh_bounds(eng)) if eng else AABB()   # mesh_bounds is in the host's frame
	var lo: Vector3 = box.to_local(eb.position); var hi: Vector3 = box.to_local(eb.end)
	var lb := AABB(lo.min(hi), (hi - lo).abs())
	# in plan: the box has three walls and no roof, and the sculpture's hanging polyhedra reach the ceiling
	var inside: bool = eng != null and lb.position.x >= inner.position.x and lb.end.x <= inner.end.x and lb.position.z >= inner.position.z and lb.end.z <= inner.end.z
	check("floor 12: the sculpture (%s in the box's frame, %.2f m tall) stands inside the three walls in plan (inner %s): %s" % [str(lb.position.snapped(Vector3.ONE * .01)) + ".." + str(lb.end.snapped(Vector3.ONE * .01)), lb.size.y, str(inner.size), str(inside)], inside)
	var grid: Node3D = box.get_node_or_null("Grid")
	var sight: Node3D = box.get_node_or_null("Sight")
	var gl: Vector3 = grid.position if grid else Vector3.ZERO
	check("floor 12: the grid stands in the open front (local z %.2f = depth/2 + wall/2, %.1f m long, %.1f m high) and the sight %.1f m across the shaft at %.1f m" % [gl.z, grid.length if grid else 0.0, grid.height if grid else 0.0, box.sight_distance, box.sight_height],
		grid != null and absf(gl.z - (box.depth * .5 + box.wall * .5)) < .01 and absf(grid.length - box.width) < .01 and sight != null)
	# the sight stands on floor, not over the shaft: a ray under it meets slab
	var under := box.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(sight.global_position + Vector3(0, .3, 0), sight.global_position + Vector3(0, -.6, 0), 1))
	check("floor 12: the sight stands on solid floor at %s (%s)" % [str(sight.global_position.snapped(Vector3.ONE * .1)), str(not under.is_empty())], not under.is_empty())
	# the route and the other works keep out of the walls
	var walls: Array = []
	for n in ["BackWall", "SideWall", "SideWall2"]:
		var m: MeshInstance3D = box.get_node_or_null(n)
		if m: walls.append(m.global_transform * m.get_aabb())
	var level: float = float(game.building.spec.levels[12])
	var route_in := []
	for p in game.building.content.data.floors[12].get("route", []):
		var w := Vector3(float(p.position[0]), level + .9, float(p.position[1]))
		for wb in walls:
			if (wb as AABB).grow(.3).has_point(w): route_in.append([p.position[0], p.position[1]])
	var clashes := []
	for key in game.building.content.exhibits:
		if not str(key).begins_with("12/") or str(key) in ["12/hall", "12/durer-box"]: continue
		var m: Node3D = game.building.content.exhibits[key]
		var mb: AABB = m.global_transform * mesh_bounds(m)   # into the world, as the walls are
		if mb.size.length() < .01: continue
		for wb in walls:
			if (wb as AABB).intersects(mb): clashes.append(str(key)); break
	check("floor 12: the route keeps 0.3 m off the walls (%s) and no other work stands in them (%s)" % [str(route_in) if route_in else "clear", ", ".join(PackedStringArray(clashes)) if clashes else "clear"], route_in.is_empty() and clashes.is_empty())
	# the picture Palle asked for: the work through the grid, from the sight's eye-piece
	await _photo(12, box, Vector3(0, box.sight_height, box.depth * .5 + box.sight_distance - .05), Vector3(0, 2.2, 0), "12_through_the_grid", 50.0)
	await _photo(12, box, Vector3(5.5, 3.0, box.depth * .5 + 4.0), Vector3(0, 2.0, 0), "12_box_and_sight")

func _photo(f: int, at: Node3D, eye: Vector3, look: Vector3, n: String, fov := 65.0) -> void:
	if DisplayServer.get_name() == "headless": return
	var camera := Camera3D.new(); game.add_child(camera); camera.fov = fov; camera.environment = game.atmosphere.environment
	camera.global_position = at.to_global(eye); camera.look_at(at.to_global(look)); camera.make_current()
	var seen: bool = game.body.visible; game.body.visible = false
	game.status.hide(); game.charge_display.hide(); game.notice_time = 0
	if game.desktop_help != null: game.desktop_help.hide()
	await frames(8); await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join("%s.png" % n))
	game.body.visible = seen; camera.queue_free()
	FileAccess.open(out.path_join("progress.json"), FileAccess.WRITE).store_string(JSON.stringify({"floor": f, "checks": checks.size()}))

func finish() -> void:
	FileAccess.open(out.path_join("checks.json"), FileAccess.WRITE).store_string(JSON.stringify({"passed": failed.is_empty(), "checks": checks, "failed": failed}, "  "))
	print("[primitives_rooms_tower] %d/%d checks pass" % [checks.size() - failed.size(), checks.size()])
	quit(0 if failed.is_empty() else 1)
