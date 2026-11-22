extends SceneTree
## ISO_ImplicitModeling, floor 156: CONTACT (commons/artifacts/contact_study).
##   row "contact"        two bodies that come together as the visitor comes near, made five ways
##   row "contact-field"  a version at every place the floor has room for; reach across, distance along
##   row "contact-within" the two heads where they meet, at nine times the size, as a room with a door in each body:
##                        it stands under the ceiling, a body the size of a visitor walks in through one body and
##                        out through the other, and the same body sent at the wall is stopped by it
##   row "contact-church" five hollow bodies of different sizes joined into one tall room on the north side slab
##                        (row "side-slab-north"): the game keeps a visitor there, the sky is open over it, and a
##                        body walks in at the portal, down the nave under the canopy, and out at the door
## Walks the visitor's camera towards each station of the row and reads what it does: far away the two stand apart,
## near they are as close as they come; the frame follows the distance; SKIN goes from two bodies to one body to
## one body with an opening, as its baked frames say; THROUGH slides one mesh into the other; INSIDE keeps the join
## inside its diamond. For the field: every version has floor in front of it, has its mesh, and says on its plaque what
## the bake counted; reach grows to the east and the gap shrinks to the north; all three states are there; the two
## lines are on the ground; and the bake's map of the floor says of every version's place what the version is.
##
##   python tools/run_floor_probe.py ISO_ImplicitModeling contact_study.gd contact_study.json <folder> --no-opening --opera-quiet [--xr]

var game: Node
var folder := "res://ada_run/contact_study"
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


## A point of the floor, in the floor's own metres, at a height above it.
func _at(x: float, z: float, above: float) -> Vector3:
	var p := content.to_global(Vector3(x, 0, z))
	return Vector3(p.x, floor_y + above, p.z)


func _picture(file: String) -> void:
	for i in 8: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(folder.path_join(file))


func _triangles(node: Node) -> int:
	var total := 0
	for part in node.find_children("*", "MeshInstance3D", true, false):
		var mesh := (part as MeshInstance3D).mesh
		if mesh == null or part.name == "Wire" or mesh.get_surface_count() == 0: continue
		var arrays := mesh.surface_get_arrays(0)
		if arrays[Mesh.ARRAY_INDEX] != null: total += (arrays[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3
	return total


func _done() -> void:
	result.passed = (result.checks as Array).all(func(c): return c.ok)
	var file := FileAccess.open(folder.path_join("contact_study.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "  "))
	file.close()
	quit()


func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): folder = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(folder)
	load("res://commons/void/room_source.gd").use_main_tower = true
	game = load("res://commons/void/void.tscn").instantiate()
	# --xr: the game's VR branch on synthetic trackers, before a headset build
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
	# the floor's height from the ground itself: a headset's eye is not at a fixed 1.6 m
	var ground := eye.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(arrival, arrival + Vector3.DOWN * 4.0, 1))
	floor_y = float(ground.position.y) if not ground.is_empty() else arrival.y - 1.6
	var row_mount := game.building.content.exhibits.get("%d/contact" % index) as Node3D
	var field_mount := game.building.content.exhibits.get("%d/contact-field" % index) as Node3D
	var study := row_mount.get_node_or_null("Artifact") as Node3D if is_instance_valid(row_mount) else null
	var field := field_mount.get_node_or_null("Artifact") as Node3D if is_instance_valid(field_mount) else null
	if not _check("both rows stand on the floor", study != null and field != null):
		_done(); return
	game.body.set_physics_process(false)
	game.body.set_process(false)
	var size: float = study.get("size")
	result["sizes"] = {"row": size, "field": field.get("size"), "a_body_in_the_row_m": snappedf(1.78 * size, 0.01), "a_body_in_the_field_m": snappedf(1.78 * float(field.get("size")), 0.01)}
	# ------------------------------------------------------------------ the row of five ways
	var stations: Array = study.get("stations")
	_check("five stations, each with its frames", stations.size() == 5 and stations.all(func(s): return s.kind == "through" or ((s.meshes as Array).size() >= 8 and not (s.meshes as Array).has(null))),
		{"stations": stations.map(func(s): return [s.kind, (s.meshes as Array).size()])})
	var front := study.global_basis.z
	var far: float = study.get("far")
	var near: float = study.get("near")
	await _stand(arrival, arrival + Vector3(0, -0.2, -6.0), 1.0)
	await _picture("1_from_the_arrival.png")
	var report := []
	for station: Dictionary in stations:
		var at: Vector3 = (station.root as Node3D).global_position
		var entry := {"kind": station.kind}
		await _stand(at + front * (far + 1.5) + Vector3.UP * 1.65, at + Vector3.UP * 1.4, 3.5)
		entry["t_far"] = snappedf(float(station.t), 0.01)
		entry["frame_far"] = int(station.frame)
		await _stand(at + front * (near - 0.1) + Vector3.UP * 1.65, at + Vector3.UP * 1.4, 3.5)
		entry["t_near"] = snappedf(float(station.t), 0.01)
		entry["frame_near"] = int(station.frame)
		entry["plaque"] = (station.plaque as Label3D).text if station.has("plaque") else ""
		if station.has("slides"): entry["slid_m"] = snappedf((station.slides as Node3D).position.x, 0.01)
		await _stand(at + front * 3.9 + study.global_basis.x * 0.8 + Vector3.UP * 1.65, at + Vector3.UP * 1.6, 0.1)
		await _picture("2_%s_near.png" % station.kind)
		report.append(entry)
	result["stations"] = report
	_check("far away every pair stands apart; near, each is as close as it comes", report.all(func(r): return float(r.t_far) <= 0.02 and float(r.t_near) >= 0.98), {"t": report.map(func(r): return [r.kind, r.t_far, r.t_near])})
	_check("the frames follow: first frame far, last frame near", report.all(func(r): return r.kind == "through" or (int(r.frame_far) == 0 and int(r.frame_near) >= 7)), {"frames": report.map(func(r): return [r.kind, r.frame_far, r.frame_near])})
	var through: Dictionary = report.filter(func(r): return r.kind == "through")[0]
	_check("THROUGH slides one mesh into the other", float(through.slid_m) < -0.05, {"slid_m": through.slid_m})
	var skin: Dictionary = stations.filter(func(s): return s.kind == "skin")[0]
	var story := (skin.rows as Array).map(func(r): return [float(r.gap), int(r.get("pieces", 0)), int(r.get("handles", 0))])
	result["skin_story_gap_pieces_openings"] = story
	_check("SKIN: two bodies, then one body before they touch, then one body with an opening",
		story.front()[1] == 2 and story.any(func(s): return s[0] > 0.0 and s[1] == 1) and story.any(func(s): return s[1] == 1 and s[2] >= 1), {"story": story})
	var inside: Dictionary = stations.filter(func(s): return s.kind == "inside")[0]
	var container := inside.get("container") as Node3D
	var reach_out := 0.0
	var form_mesh := (inside.form as MeshInstance3D).mesh
	if form_mesh != null and container != null:
		var radius: float = float((study.get("index") as Dictionary).inside.radius)
		for vertex: Vector3 in form_mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
			var q := (vertex - container.position).abs()
			reach_out = maxf(reach_out, q.x + q.y + q.z - radius)
	_check("INSIDE: nothing of the join lies outside its diamond", container != null and form_mesh != null and reach_out < 0.03, {"furthest_outside_m": snappedf(reach_out, 0.001)})
	# ------------------------------------------------------------------ the field of versions
	for i in 240: await physics_frame
	var versions: Array = field.get("versions")
	var space := eye.get_world_3d().direct_space_state
	var without_floor := []
	var without_mesh := []
	var wrong_words := []
	for version: Dictionary in versions:
		# where a visitor stands to read it: in front of the plaque
		var here := _at(float(version.row.x), float(version.row.z) + 1.5, 2.0)
		var under := space.intersect_ray(PhysicsRayQueryParameters3D.create(here, here + Vector3.DOWN * 3.0, 1))
		if under.is_empty() or absf(under.position.y - floor_y) > 0.06: without_floor.append(version.row.file)
		if (version.form as MeshInstance3D).mesh == null: without_mesh.append(version.row.file)
		var said := (version.plaque as Label3D).text if version.has("plaque") else ""
		var want := "two bodies" if int(version.row.pieces) >= 2 else "one body"
		if not said.contains(want) or not said.contains("REACH %.2f" % float(version.row.reach)): wrong_words.append(version.row.file)
	_check("the field: twenty versions, each with floor in front of it, its mesh and its count on the plaque", versions.size() == 20 and without_floor.is_empty() and without_mesh.is_empty() and wrong_words.is_empty(),
		{"versions": versions.size(), "no_floor_in_front": without_floor, "no_mesh": without_mesh, "wrong_plaque": wrong_words})
	var ordered := true
	for a: Dictionary in versions:
		for b: Dictionary in versions:
			if float(a.row.x) < float(b.row.x) - 0.1 and float(a.row.reach) >= float(b.row.reach): ordered = false
			if float(a.row.z) > float(b.row.z) + 0.1 and float(a.row.gap) <= float(b.row.gap): ordered = false
	_check("the place gives the version: more reach to the east, a smaller gap to the north", ordered)
	var states := {}
	for version: Dictionary in versions:
		var key := "two bodies" if int(version.row.pieces) >= 2 else ("one body" if int(version.row.handles) == 0 else "one body with openings")
		states[key] = int(states.get(key, 0)) + 1
	result["field_states"] = states
	_check("the field holds all three: two bodies, one body, one body with openings", states.size() == 3, {"states": states})
	var line := field.get_node_or_null("OneBody") as MeshInstance3D
	var opening := field.get_node_or_null("AnOpening") as MeshInstance3D
	_check("the two lines are on the ground", line != null and opening != null and line.mesh != null and opening.mesh != null)
	# the bake's map of the floor, read at every version's own place: is it two bodies there or one?
	var map: Dictionary = (field.get("index") as Dictionary).get("states", {})
	var agree := 0
	var differ := []
	if not map.is_empty():
		var xs: Array = map.x
		var zs: Array = map.z
		for version: Dictionary in versions:
			var i := 0
			var j := 0
			for n in xs.size():
				if absf(float(xs[n]) - float(version.row.x)) < absf(float(xs[i]) - float(version.row.x)): i = n
			for n in zs.size():
				if absf(float(zs[n]) - float(version.row.z)) < absf(float(zs[j]) - float(version.row.z)): j = n
			var mark := str(map.rows[j]).substr(i, 1)
			if (mark == "2") == (int(version.row.pieces) >= 2): agree += 1
			else: differ.append([version.row.file, mark, int(version.row.pieces)])
	_check("the map on the ground and the versions agree on two bodies or one", not map.is_empty() and differ.size() <= 2, {"agree": agree, "differ": differ})
	var drawn := _triangles(study) + _triangles(field)
	_check("the whole floor of bodies draws a number of triangles a headset can carry", drawn < 160000, {"triangles": drawn, "row": _triangles(study), "field": _triangles(field)})
	# pictures of the field
	await _stand(arrival + Vector3(0, 0.2, 0), _at(-17.0, 0.0, 1.6), 0.3)
	await _picture("3_west_wing_from_the_arrival.png")
	await _stand(_at(-17.3, 7.8, 1.65), _at(-17.3, -3.0, 1.5), 0.3)
	await _picture("4_west_wing_walking_north.png")
	await _stand(_at(17.3, 7.8, 1.65), _at(17.3, -3.0, 1.5), 0.3)
	await _picture("5_east_wing_walking_north.png")
	await _stand(_at(-13.4, 4.0, 1.9), _at(-17.5, -0.6, 0.3), 0.3)
	await _picture("6_the_line_on_the_ground.png")
	await _stand(_at(-4.6, -3.6, 1.65), _at(-9.5, -5.4, 1.4), 0.3)
	await _picture("7_north_versions.png")
	# from above the south-east wing, clear of the corner column, over the east versions to the row and the north band
	await _stand(_at(17.4, 7.0, 4.1), _at(-2.0, -2.2, 0.6), 3.0)
	await _picture("8_the_floor_from_a_corner.png")
	# ------------------------------------------------------------------ within: the two heads as a room
	var room_mount := game.building.content.exhibits.get("%d/contact-within" % index) as Node3D
	var room := room_mount.get_node_or_null("Artifact") as Node3D if is_instance_valid(room_mount) else null
	if not _check("the room stands on the floor", room != null):
		_done(); return
	for i in 180: await physics_frame
	var made: Dictionary = room.get("within")
	var row: Dictionary = made.get("row", {})
	var form := made.get("form") as MeshInstance3D
	if not _check("the room has its form and its walls", form != null and form.mesh != null and made.get("walls") != null):
		_done(); return
	var times: float = room.get("size")
	var west := float(row.west_door_x)
	var east := float(row.east_door_x)
	var axis_a := float(row.axis_a_x)
	var axis_b := float(row.axis_b_x)
	var tall := form.mesh.get_aabb().end.y * times
	var beside := _in(room, west - 2.0, 0.0, 0.5)
	var above := space.intersect_ray(PhysicsRayQueryParameters3D.create(beside, beside + Vector3.UP * 9.0, 1))
	var clear_height := (float(above.position.y) - floor_y) if not above.is_empty() else 0.0
	result["room"] = {"size": times, "tall_m": snappedf(tall, 0.01), "ceiling_m": snappedf(clear_height, 0.01), "long_m": row.get("long_m"), "deep_m": row.get("deep_m"),
		"doorway_headroom_m": row.get("narrowest_headroom_m"), "doorway_width_m": row.get("narrowest_width_m"), "triangles": _triangles(room)}
	_check("the room stands under the ceiling", clear_height > 0.0 and tall < clear_height - 0.1, {"tall_m": snappedf(tall, 0.01), "ceiling_m": snappedf(clear_height, 0.01)})
	_check("from the middle of one body the middle of the other is seen through the doorway",
		space.intersect_ray(PhysicsRayQueryParameters3D.create(_in(room, axis_a, 0.0, 1.5), _in(room, axis_b, 0.0, 1.5), 1)).is_empty())
	# a body the size of a visitor walks it: in at A's door, through the doorway, out at B's door
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
	var legs := []
	walker.global_position = _in(room, west - 1.4, 0.0, 0.93)
	for stop: Array in [["into A", axis_a], ["the doorway", 0.5 * (axis_a + axis_b)], ["into B", axis_b], ["out of B's door", east + 1.4]]:
		var reached := await _walk(walker, _in(room, float(stop[1]), 0.0, 0.93))
		legs.append([stop[0], reached, snappedf(room.to_local(walker.global_position).x, 0.01)])
	_check("a body 0.6 m wide and 1.8 m tall walks in through one body and out through the other", legs.all(func(l): return l[1]), {"legs": legs})
	# and the wall is a wall: the same body, sent at the long side, stays outside
	walker.global_position = _in(room, axis_a, 3.2, 0.93)
	var through_wall := await _walk(walker, _in(room, axis_a, 0.0, 0.93))
	var stopped_at := room.to_local(walker.global_position).z
	_check("the same body sent at the wall is stopped by it", not through_wall and stopped_at > 1.2, {"stopped_at_z_m": snappedf(stopped_at, 0.01)})
	walker.queue_free()
	_check("with the room, the floor still draws a number of triangles a headset can carry", drawn + _triangles(room) < 160000, {"triangles": drawn + _triangles(room), "room": _triangles(room)})
	await _stand(_in(room, west - 3.2, 3.6, 2.3), _in(room, 0.4, 0.0, 2.0), 0.3)
	await _picture("9_the_room_from_outside.png")
	await _stand(_in(room, west - 2.4, 0.0, 1.65), _in(room, east, 0.0, 1.3), 0.3)
	await _picture("10_at_the_first_door.png")
	await _stand(_in(room, axis_a - 0.6, 0.5, 1.65), _in(room, axis_b, 0.0, 1.35), 0.3)
	await _picture("11_inside_the_first_body.png")
	await _stand(_in(room, axis_a, 0.0, 1.5), _in(room, axis_a + 0.25, 0.0, 4.4), 0.3)
	await _picture("12_looking_up_inside.png")
	await _stand(_in(room, axis_b + 0.5, -0.4, 1.65), _in(room, axis_a, 0.0, 1.5), 0.3)
	await _picture("13_from_the_second_body_back.png")
	# ------------------------------------------------------------------ the church: five bodies as one tall room
	var church_mount := game.building.content.exhibits.get("%d/contact-church" % index) as Node3D
	var church := church_mount.get_node_or_null("Artifact") as Node3D if is_instance_valid(church_mount) else null
	if not _check("the church stands beyond the north edge", church != null):
		_done(); return
	for i in 240: await physics_frame
	var built: Dictionary = church.get("church")
	var plan: Dictionary = built.get("row", {})
	var nave := built.get("form") as MeshInstance3D
	if not _check("the church has its form, its walls and its canopy", nave != null and nave.mesh != null and built.get("walls") != null and built.get("canopy_solid") != null and built.get("pair") != null):
		_done(); return
	var bays: Array = plan.bays
	var portal_x := float(plan.portal_x)
	var door_x := float(plan.door_x)
	var door_z := float(plan.door_z)
	var heights := bays.map(func(b): return float(b[2]))
	result["church"] = {"long_m": plan.get("long_m"), "deep_m": plan.get("deep_m"), "tall_m": plan.get("tall_m"), "bays_x_radius_height": bays.map(func(b): return [b[0], b[1], b[2]]),
		"rooms_x_height_width": plan.get("rooms_x_height_width"), "arches_x_height_width": plan.get("arches_x_height_width"), "triangles": _triangles(church)}
	_check("five bodies of different sizes, the tallest over 15 m", bays.size() == 5 and float(heights.max()) > 15.0 and float(heights.min()) < float(heights.max()) - 3.0, {"heights_m": heights})
	# the ground under it is a side slab the game accepts: a visitor in the nave is not sent back, and is on this floor
	var in_nave := _in(church, 0.0, 2.6, 0.0)
	var under_nave := space.intersect_ray(PhysicsRayQueryParameters3D.create(in_nave + Vector3.UP * 0.5, in_nave + Vector3.DOWN * 2.0, 1))
	_check("the nave has a floor at the tower's own level", not under_nave.is_empty() and absf(float(under_nave.position.y) - floor_y) < 0.06, {"floor_under_m": snappedf(float(under_nave.position.y) - floor_y, 0.01) if not under_nave.is_empty() else -99.0})
	var kept_there := bool(game.call("_exterior_walk_support", in_nave))
	var on_floor := int(game.floor_stream.floor_at_position(in_nave + Vector3.UP)) if game.floor_stream != null else index
	_check("a visitor in the nave is kept there and belongs to this floor", kept_there and on_floor == index, {"kept": kept_there, "floor": on_floor})
	# the sky is open over it: nothing between the tallest tip and the air
	var tip := _in(church, 0.0, 0.0, float(heights.max()) + 0.5)
	_check("the sky is open over the tallest bay", space.intersect_ray(PhysicsRayQueryParameters3D.create(tip, tip + Vector3.UP * 30.0, 1)).is_empty())
	# a body the size of a visitor: in at the portal, down the axis through every bay and under the canopy, out at the door
	var pilgrim := CharacterBody3D.new()
	var pilgrim_shape := CollisionShape3D.new()
	var pilgrim_capsule := CapsuleShape3D.new()
	pilgrim_capsule.radius = 0.3
	pilgrim_capsule.height = 1.8
	pilgrim_shape.shape = pilgrim_capsule
	pilgrim.add_child(pilgrim_shape)
	pilgrim.collision_layer = 0
	pilgrim.collision_mask = 1
	pilgrim.motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	root.add_child(pilgrim)
	pilgrim.global_position = _in(church, portal_x - 1.6, 0.0, 0.93)
	var way := []
	for bay: Array in bays:
		var arrived := await _walk(pilgrim, _in(church, float(bay[0]), 0.0, 0.93), 14.0)
		way.append(["bay at %.1f" % float(bay[0]), arrived])
	way.append(["out at the door", await _walk(pilgrim, _in(church, door_x, door_z + 1.4, 0.93), 14.0)])
	_check("a body 0.6 m wide and 1.8 m tall walks the nave: in at the portal, under the canopy, out at the door", way.all(func(l): return l[1]), {"way": way})
	pilgrim.global_position = _in(church, 0.0, -7.5, 0.93)
	var through_church_wall := await _walk(pilgrim, _in(church, 0.0, -2.5, 0.93), 8.0)
	_check("the same body sent at the church's wall from outside is stopped by it", not through_church_wall, {"stopped_at_z_m": snappedf(church.to_local(pilgrim.global_position).z, 0.01)})
	pilgrim.queue_free()
	_check("with the church, the floor draws a number of triangles a headset can carry", drawn + _triangles(room) + _triangles(church) < 180000, {"triangles": drawn + _triangles(room) + _triangles(church), "church": _triangles(church)})
	await _stand(_in(church, portal_x - 3.3, 3.6, 1.65), _in(church, portal_x + 2.0, 0.0, 3.2), 0.3)
	await _picture("14_the_portal_from_the_slab.png")
	await _stand(_in(church, portal_x - 0.6, 0.0, 1.65), _in(church, 13.0, 0.0, 2.2), 0.3)
	await _picture("15_down_the_nave.png")
	await _stand(_in(church, -9.0, 1.2, 1.65), _in(church, 0.0, 0.0, 3.4), 0.3)
	await _picture("16_towards_the_canopy.png")
	await _stand(_in(church, 0.0, 0.0, 1.6), _in(church, 0.35, 0.0, 16.0), 0.3)
	await _picture("17_up_through_the_canopy.png")
	await _stand(_in(church, -6.8, 0.0, 1.6), _in(church, -6.5, 0.0, 12.0), 0.3)
	await _picture("18_up_inside_a_body.png")
	await _stand(_in(church, 4.2, -1.6, 1.65), _in(church, 14.6, 0.0, 1.9), 0.3)
	await _picture("19_the_pair_in_the_last_bay.png")
	await _stand(_in(church, 11.2, 0.6, 1.65), _in(church, -13.0, 0.0, 3.0), 0.3)
	await _picture("20_back_down_the_nave.png")
	# from the air beyond the slab's north-west corner, near enough that the tower's haze does not take it
	await _stand(_in(church, -25.0, -13.0, 8.0), _in(church, -2.0, 0.0, 7.5), 0.3)
	await _picture("21_the_church_from_the_air.png")
	_done()


## A point of the room, in the room's own metres (x from A's door to B's, z south), at a height above the floor.
func _in(room: Node3D, x: float, z: float, above: float) -> Vector3:
	var p := room.to_global(Vector3(x, 0, z))
	return Vector3(p.x, floor_y + above, p.z)


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
