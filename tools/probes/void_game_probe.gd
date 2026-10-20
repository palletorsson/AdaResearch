extends SceneTree
var checks: Array[Dictionary] = []
var failed: Array[String] = []
var game: Node3D
var left: XRControllerTracker
var right: XRControllerTracker
var head: XRPositionalTracker
var out := "user://"
var xr := false

func _initialize() -> void:
	run.call_deferred()

func check(label: String, passed: bool) -> void:
	checks.append({"name": label, "passed": passed})
	if not passed: failed.append(label)
	print("[void] ", "PASS " if passed else "FAIL ", label)

func frames(count: int) -> void:
	for i in range(count): await physics_frame
	await process_frame

func wait_for_recovery(deaths_before: int) -> void:
	# The tower grows: completion is a state, not a three-floor flight duration.
	for i in range(900):
		await frames(1)
		if game.deaths>deaths_before and not game.recovering and game.body.is_on_floor(): return

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out = arg.trim_prefix("--out=")
	if "--editor-roundtrip" in OS.get_cmdline_user_args():
		await start(false)
		var room: Node3D = game.building.content.exhibits["3/setting_out"].get_node("Artifact/MeasurementRoom")
		var okay: bool = room.global_position.is_equal_approx(Vector3(1,-18,3.5)) and game.checkpoint==3
		FileAccess.open(out.path_join("editor-runtime-checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":okay,"check":"Native editor draft moves the original two-point room in the real game and starts on floor 03", "actual_position":[room.global_position.x,room.global_position.y,room.global_position.z]},"  "))
		game.queue_free();await frames(3);quit(0 if okay else 1);return
	if "--capture" in OS.get_cmdline_user_args():
		await capture()
		quit()
		return
	if "--package" in OS.get_cmdline_user_args():
		check("documentation is absent from exported package", not FileAccess.file_exists("res://doc/sentinel.txt"))
	await exercise(false)
	await exercise(true)
	await content_checks()
	await coordinate_checks()
	await lines_checks(false)
	await lines_checks(true)
	var destination := "package-checks.json" if "--package" in OS.get_cmdline_user_args() else "checks.json"
	var file := FileAccess.open(out.path_join(destination), FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed": failed.is_empty(), "checks": checks, "failed": failed}, "\t"))
	file.close()
	print("[void] %d/%d checks pass" % [checks.size() - failed.size(), checks.size()])
	quit(0 if failed.is_empty() else 1)

func content_checks() -> void:
	await start(false)
	var content: Node3D = game.building.content
	check("roof references Point Zero", content.data.floors[0].map == "Point_Zero")
	check("four sockets on every floor", game.building.mounts.size() == game.building.spec.levels.size()*4)
	check("origin remains exactly at world zero", content.get_node("Content0/WorldZero").global_position.is_equal_approx(Vector3.ZERO))
	check("one existing counter, no replacement", content.exhibits["0/clock"].get_node("Artifact").get_script().resource_path == "res://commons/visualaid/frame_counter/frame_counter_display.gd")
	var counter: Node3D = content.exhibits["0/clock"].get_node("Artifact")
	var placement: Dictionary = content.data.floors[0].artifacts[0]
	check("editor artifact scale reaches the runtime", counter.scale.is_equal_approx(Vector3.ONE * float(placement.scale)))
	check("editor facing reaches the runtime", is_equal_approx(content.exhibits["0/clock"].rotation_degrees.y, float(placement.facing)))
	var before: String = counter.label.text
	await frames(10)
	check("the rooftop counter actually advances", counter.label.text != before)
	check("artifact records remain connected to supply stations", content.exhibits["0/clock"].get_meta("supply") == "ceiling_bus" and content.exhibits["0/clock"].get_meta("station") == "NW")
	check("first floor references Point One", content.data.floors[1].map == "Point_One")
	check("Point One retains its container and two entrance crates", content.props["1/store-01"].get_meta("kind") == "container" and content.props.has("1/entry-left") and content.props.has("1/entry-right"))
	for item in content.data.floors[1].props:
		var prop: StaticBody3D = content.props["1/" + str(item.id)]
		check("prop placement matches editor: " + str(item.id), prop.position.is_equal_approx(Vector3(item.position[0],0,item.position[1])) and is_equal_approx(prop.rotation_degrees.y,float(item.facing)))
		if content.catalog.props[item.kind].get("collision", "bounds") == "parts":
			check("open prop retains part collision: " + str(item.id), not prop.find_children("*","CollisionShape3D",true,false).is_empty())
		else:
			var shape: CollisionShape3D = prop.get_child(0)
			check("prop has solid full-height collision: " + str(item.id), is_equal_approx(shape.shape.size.y,content.catalog.props[item.kind].size[1]))
	var container: StaticBody3D = content.props["1/store-01"]
	var container_shape: CollisionShape3D = container.get_child(0)
	check("40 ft container has real external dimensions and unit scale", container_shape.shape.size.is_equal_approx(Vector3(2.438,2.591,12.192)) and container.scale.is_equal_approx(Vector3.ONE))
	var visual := mesh_bounds(container)
	check("container visible shell is 2.438 wide, 2.591 high, 12.192 long", visual.size.is_equal_approx(Vector3(2.438,2.591,12.192)) and is_zero_approx(visual.position.y))
	check("Floor 02 carries Point Coordinates", content.data.floors[2].map == "Point_Coordinates")
	# Streaming only prepares the current floor and its neighbour.
	game.place_player(game.spawn_for(2)); await frames(30)
	var frame: Node3D = content.exhibits["2/frame"].get_node("Artifact")
	var held: Node3D = content.exhibits["2/held"].get_node("Artifact")
	check("existing held-point scene has no podium in the tower", held.get_script().resource_path == "res://commons/primitives/point/point_held.gd" and not held.has_node("HeldPointPlinth"))
	check("frame adopts the existing point without making a duplicate", frame._find_point() == held.point and get_nodes_in_group("ada_coordinate_point").size() == 1)
	check("solid frame keeps the museum palette", frame.axis_palette == "pink_grey_black" and is_equal_approx(frame.axis_opacity,1.0) and not frame.axis_unshaded)
	var scale_host := Node3D.new()
	game.add_child(scale_host)
	var scale_item: Dictionary = content.data.floors[2].artifacts[1].duplicate(true)
	scale_item.id = "scale-fixture"
	scale_item.scale = 0.8
	content._build_artifact(scale_host,2,scale_item)
	var scale_frame: Node3D = content.exhibits["2/scale-fixture"].get_node("Artifact")
	check("editor placement scale composes with coordinate display scale", scale_frame.scale.is_equal_approx(Vector3.ONE*1.35*0.8))
	scale_host.queue_free()
	content.exhibits.erase("2/scale-fixture")
	var y_tip: float = frame.to_global(frame.get_node("AxisLabelY").position).y
	check("upper axis and label fit below the concrete ceiling", y_tip + 0.25 < -6.36)
	check("point's own guide ends at this frame", held.point.origin_point.is_equal_approx(frame.global_position))
	for xz in [Vector2(-3,0),Vector2(0,3)]:
		var top := ray(Vector3(xz.x,-11.5,xz.y),Vector3(xz.x,-12.15,xz.y))
		check("solid Coordinates slab at " + str(xz), not top.is_empty() and top.collider.get_meta("void_floor_index",-1)==2 and is_equal_approx(top.position.y,-12.0))
	check("Coordinates has no recessed basin",not game.building.floors[2].has_node("Basin"))
	for axis in ["AxisX","AxisZ"]:
		var line: Node3D = frame.get_node(axis)
		var tip: Vector3 = line.to_global(Vector3(line.length+line.arrow_size,0,0))
		var hit := ray(Vector3(tip.x,-11.5,tip.z),Vector3(tip.x,-12.15,tip.z))
		check("solid floor under the actual " + axis + " arm", not hit.is_empty() and hit.collider.get_meta("void_floor_index",-1)==2)
	var podiums := 0
	for id in ["absence", "surface", "solid"]:
		var mount: Node3D = content.exhibits["1/" + id]
		var artifact: Node3D = mount.get_node("Artifact")
		check("Point One reuses the existing scene: " + id, artifact.get_script().resource_path == "res://commons/primitives/point/point_condition.gd")
		check("Point One is on the supplied first floor: " + id, is_equal_approx(artifact.global_position.y, -6.0) and mount.get_meta("supply") == "ceiling_bus")
		check("small study joins the comparison row: " + id, is_equal_approx(mount.position.z,2.5) and is_zero_approx(mount.rotation_degrees.y))
		if artifact.has_node("PointPlinth/PlinthCollision"): podiums += 1
		var ray := PhysicsRayQueryParameters3D.create(artifact.to_global(Vector3(0, 1.12, 0.6)), artifact.to_global(Vector3(0, 1.12, -0.6)), 1)
		var hit := game.get_world_3d().direct_space_state.intersect_ray(ray)
		check("point collision matches its condition: " + id, (not hit.is_empty()) == (id == "solid"))
	check("all three study podiums stand on the floor", podiums == 3)
	check("first podium remains empty", not content.exhibits["1/absence"].get_node("Artifact").has_node("VisiblePoint"))
	var future: Node3D = content.exhibits["1/future"].get_node("Artifact")
	var sphere: MeshInstance3D = future.get_node("VisiblePoint")
	var finish: StandardMaterial3D = sphere.material_override
	check("future is the existing 1.3 m black glossy sphere", is_equal_approx(sphere.mesh.radius, 0.65) and finish.albedo_color.v < 0.02 and finish.roughness < 0.1 and finish.clearcoat_enabled)
	check("future sphere rests on its original plinth", is_equal_approx(sphere.position.y - sphere.mesh.radius, future.get_node("Pedestal").mesh.size.y))
	check("future sphere sits beyond the row", content.exhibits["1/future"].position.is_equal_approx(Vector3(0,0,-4.3)))
	for item in content.data.floors[1].artifacts:
		var lead: Node3D = content.get_node("Content1/Lead_" + str(item.id))
		check("relocated exhibit retains its electrical lead: " + str(item.id), lead.get_meta("station") == item.station and lead.has_node("ArtifactFeed") and lead.get_node("ArtifactFeed").position.y > 1.9)
	var sight_origin := Vector3(0,-4.35,6.0)
	for id in ["absence","surface","solid"]:
		var view_target: Node3D = content.exhibits["1/"+id]
		var sight := PhysicsRayQueryParameters3D.create(sight_origin,view_target.global_position+Vector3(0,0.72,0),1)
		var seen := game.get_world_3d().direct_space_state.intersect_ray(sight)
		check("entry sightline reaches study: " + id, not seen.is_empty() and view_target.is_ancestor_of(seen.collider))
	var east_ray := PhysicsRayQueryParameters3D.create(Vector3(3,-4.7,3.35),Vector3(8,-4.7,3.35),1)
	var east_hit := game.get_world_3d().direct_space_state.intersect_ray(east_ray)
	check("container physically screens the east shaft", not east_hit.is_empty() and east_hit.collider == content.props["1/store-01"])
	var original: Node3D = load("res://commons/primitives/point/point_visible.tscn").instantiate()
	game.add_child(original)
	check("source museum visible point remains unsupported by default", not original.has_node("PointPlinth"))
	original.apply_grid_config({"study_plinth": true})
	original.apply_grid_config({"study_plinth": true})
	check("applying podium config twice does not duplicate supports", original.find_children("PointPlinth", "MeshInstance3D", false, false).size() == 1)
	original.apply_grid_config({"study_plinth": false})
	check("podium config can restore the original unsupported study", not original.has_node("PointPlinth") and is_equal_approx(original.get_node("PointOneLabel").position.y, 0.012))
	original.queue_free()
	var cell: Dictionary = content.cells["1:-2:-2"]
	var untouched: Dictionary = content.cells["1:-1:-2"]
	check("only authored cells exist", content.cells.size() == 8)
	check("time alone leaves the grid unchanged", is_equal_approx(cell.height, 0.03))
	check("ordinary touch is not a catalyst impact", not content.react_at_world(Vector3(-1.5,-5.97,-1.5), "touch"))
	check("shaft and frame reject catalyst edits", not content.react_at_world(Vector3(-10,-6,0), "catalyst.transformation") and not content.react_at_world(Vector3(-6,-6,4.5), "catalyst.transformation"))
	var shot: RigidBody3D = load("res://commons/hazards/becoming_catalyst/catalyst_projectile.gd").new()
	shot.direction = Vector3.DOWN
	shot.position = Vector3(-1.5, -4.5, -1.5)
	shot.projectile_scale = 0.5
	game.add_child(shot)
	await frames(40)
	check("real catalyst collision raises one panel", content.impact_count == 1 and is_equal_approx(cell.height, 0.33))
	check("neighbouring panel does not change", is_equal_approx(untouched.height, 0.03))
	var tile: StaticBody3D = cell.node
	check("panel visible height equals its collision height", is_equal_approx(tile.get_child(0).mesh.size.y, tile.get_child(1).shape.size.y) and is_equal_approx(tile.position.y*2, cell.height))
	var wall: Node3D = content.get_node("Content1/Wall_partition")
	check("JSON wall creates a physical wall", wall is StaticBody3D and wall.get_child(1) is CollisionShape3D)
	check("editor wall height reaches the runtime", is_equal_approx(wall.get_child(0).mesh.size.y, content.data.floors[1].walls[0].height))
	game.queue_free()
	await frames(10)

func tracker(id: String, type: int, pose: String, at: Vector3) -> XRPositionalTracker:
	var item: XRPositionalTracker = XRControllerTracker.new() if type == XRServer.TRACKER_CONTROLLER else XRPositionalTracker.new()
	item.name = id
	item.type = type
	item.set_pose(pose, Transform3D(Basis.IDENTITY, at), Vector3.ZERO, Vector3.ZERO, XRPose.XR_TRACKING_CONFIDENCE_HIGH)
	XRServer.add_tracker(item)
	return item

func ray(from: Vector3, to: Vector3) -> Dictionary:
	return game.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from,to,1))

func mesh_bounds(host: Node3D) -> AABB:
	var result := AABB()
	var first := true
	for node in host.find_children("*", "GeometryInstance3D", true, false):
		var bounds: AABB
		if node is MeshInstance3D: bounds = node.mesh.get_aabb()
		elif node is MultiMeshInstance3D: bounds = node.multimesh.get_aabb()
		else: continue # Text stencil does not change the shell dimensions.
		bounds = (host.global_transform.affine_inverse() * node.global_transform) * bounds
		result = bounds if first else result.merge(bounds)
		first = false
	return result

func hand_at(controller: XRControllerTracker, world: Vector3) -> void:
	var local: Vector3 = game.get_node("XROrigin3D").to_local(world)
	controller.set_pose("aim",Transform3D(Basis.IDENTITY,local),Vector3.ZERO,Vector3.ZERO,XRPose.XR_TRACKING_CONFIDENCE_HIGH)

func coordinates_text(p: Vector3) -> String:
	return "x = %.2f\ny = %.2f\nz = %.2f" % [p.x,p.y,p.z]

func coordinate_checks() -> void:
	await start(true)
	game.checkpoint = 2
	game.place_player(Vector3(0,-11.94,-5.4))
	await frames(20)
	var point: RigidBody3D = game.coordinate_point
	var frame: Node3D = game.building.content.exhibits["2/frame"].get_node("Artifact")
	var world: Node3D = game.building.content.exhibits["2/world"].get_node("Artifact")
	var local: Node3D = game.building.content.exhibits["2/local"].get_node("Artifact")
	check("two hands have real XRTools grip pickup providers", game.pickups.size() == 2)
	hand_at(right,point.global_position)
	await frames(15)
	check("right hand detects the original black point", game.pickups[1].closest_object == point)
	right.set_input("grip",1.0)
	await frames(15)
	check("grip picks up the point using XRTools", game.pickups[1].picked_up_object == point and point._is_held)
	var target := Vector3(-4,-10.6,2)
	hand_at(right,target)
	await frames(20)
	check("held point follows the tracked controller", point.global_position.distance_to(target) < 0.05)
	check("WORLD reports the held point in tower coordinates", world.get_node("Value").text == coordinates_text(point.global_position) and world.get_node("SpaceCaption").text == "WORLD")
	check("LOCAL reports the same point in the frame", local.get_node("Value").text == coordinates_text(frame.to_local(point.global_position)) and local.get_node("SpaceCaption").text == "LOCAL")
	check("markers follow beyond the drawn axis without confining the point", not frame.confine_point and frame._axis_markers[0].position.x < 0.0)
	right.set_input("grip",0.0)
	await frames(15)
	check("releasing grip leaves the point and updates drop feedback", game.pickups[1].picked_up_object == null and not point._is_held)
	hand_at(left,point.global_position)
	await frames(15)
	left.set_input("grip",1.0)
	await frames(15)
	check("left hand can pick up the released point", game.pickups[0].picked_up_object == point and point._is_held)
	right.set_input("by_button",true)
	await frames(100)
	right.set_input("by_button",false)
	left.set_input("grip",0.0)
	await frames(5)
	check("retry releases the point and restores its authored position", game.pickups[0].picked_up_object == null and not point._is_held and point.global_transform.is_equal_approx(game.point_home))
	check("retry remains on the last landed floor", game.checkpoint == 2 and not game.recovering and game.body.is_on_floor())
	game.queue_free()
	await frames(3)
	for item in [head,left,right]: XRServer.remove_tracker(item)

func start(use_xr: bool) -> void:
	xr = use_xr
	if xr:
		head = tracker("head", XRServer.TRACKER_HEAD, "default", Vector3(0, 1.65, 0))
		left = tracker("left_hand", XRServer.TRACKER_CONTROLLER, "aim", Vector3(-0.3, 1.2, -0.4))
		right = tracker("right_hand", XRServer.TRACKER_CONTROLLER, "aim", Vector3(0.3, 1.2, -0.4))
		left.set_input("primary", Vector2.ZERO)
		right.set_input("primary", Vector2.ZERO)
		right.set_input("ax_button", false)
		right.set_input("trigger_click", false)
	var packed := load("res://commons/void/void.tscn") as PackedScene
	var instance := packed.instantiate()
	var type_probe: GDScript = load("res://staging_type_probe.gd")
	game = type_probe.assign_scene(instance)
	game.force_xr = xr
	root.add_child(game)
	current_scene = game
	if not xr: game.body.scripted_input = true
	await frames(45)
	game.scene_loaded()
	game.scene_visible()
	await frames(30)

func axes(value: Vector2) -> void:
	if xr: left.set_input("primary", Vector2(value.x, -value.y))
	else: game.body.drive = value

func press_jump() -> void:
	if xr: right.set_input("ax_button", true)
	else: game.body.jump_queued = true

func release_jump() -> void:
	if xr: right.set_input("ax_button", false)

func move_to(target: Vector3, jump_now := false, limit := 360) -> bool:
	if jump_now: press_jump()
	var departed := false
	for step in range(limit):
		var at: Vector3 = game.body.global_position
		var offset := Vector2(target.x - at.x, target.z - at.z)
		axes(offset.normalized() if offset.length() > 0.08 else Vector2.ZERO)
		await frames(1)
		if step == 1: release_jump()
		if not game.body.is_on_floor(): departed = true
		if game.recovering:
			axes(Vector2.ZERO)
			return false
		if game.body.is_on_floor() and absf(game.body.global_position.y - target.y) < 0.16 and offset.length() < 0.25 and (not jump_now or departed):
			axes(Vector2.ZERO)
			await frames(20)
			return true
	axes(Vector2.ZERO)
	print("[void] route missed target ", target, " at ", game.body.global_position)
	return false

func exercise(use_xr: bool) -> void:
	await start(use_xr)
	var tag := "XRTools" if xr else "Desktop"
	check(tag + ": scene initializes and player stands on roof", game.ready_for_play and game.body.is_on_floor() and absf(game.body.global_position.y) < 0.1)
	check(tag + ": roof checkpoint active", game.checkpoint == 0)
	check(tag + ": active camera uses the Void fog environment", game.camera.environment == game.atmosphere.environment and game.camera.environment.fog_enabled)
	check(tag + ": fog leaves nearby landings clear", game.camera.environment.fog_mode == Environment.FOG_MODE_DEPTH and is_equal_approx(game.camera.environment.fog_depth_begin, 6.0))
	game.place_player(Vector3(4, 0.06, 8))
	axes(Vector2(0, 1))
	await frames(60)
	axes(Vector2.ZERO)
	check(tag + ": visible roof rail blocks walking through it", not game.recovering and game.body.is_on_floor() and game.body.global_position.z < 8.85)
	game.place_player(game.spawn_for(0))
	await frames(20)
	if xr:
		check("XR controllers receive synthetic tracking", game.get_node("XROrigin3D/LeftHand").get_is_active() and game.get_node("XROrigin3D/RightHand").get_is_active())
		left.set_input("trigger_click", true)
		await frames(3)
		check("XR left trigger alone cannot bypass the two-hand catalyst", get_nodes_in_group("void_shots").is_empty())
		await frames(15)
		check("held left trigger creates no shortcut shots", get_nodes_in_group("void_shots").is_empty())
		left.set_input("trigger_click", false)
		check("XRTools uses only this scene's providers", game.body._movement_providers.size() == 4)
		var basis_before: Basis = game.get_node("XROrigin3D").basis
		right.set_input("primary", Vector2(1, 0))
		await frames(1)
		var basis_after: Basis = game.get_node("XROrigin3D").basis
		await frames(30)
		check("XR right stick turns once while held", not basis_before.is_equal_approx(basis_after) and game.get_node("XROrigin3D").basis.is_equal_approx(basis_after))
		right.set_input("primary", Vector2.ZERO)
		game.place_player(game.spawn_for(0))
		await frames(20)
		right.set_input("trigger_click", true)
		await frames(12)
		check("XR trigger does not jump", game.body.is_on_floor())
		right.set_input("trigger_click", false)
		right.set_input("ax_button", true)
		await frames(12)
		check("XR A launches a real jump", game.body.global_position.y > 0.3 and not game.body.is_on_floor())
		await frames(100)
		check("XR held jump does not bounce on landing", game.body.is_on_floor() and absf(game.body.global_position.y) < 0.12)
		right.set_input("ax_button", false)
	# Continuous traversal: no repositioning between roof and second floor.
	check(tag + ": walk to south launch opening", await move_to(Vector3(0, 0, 8.15)))
	check(tag + ": jump six metres to first balcony", await move_to(Vector3(0, -6, 10.2), true))
	check(tag + ": cushion absorbs first impact and saves floor 01", game.cushioned_landings == 1 and game.checkpoint == 1 and game.last_impact > game.HARD_LANDING_SPEED and game.health.get_health()==100)
	check(tag + ": enter Point One between the crates", await move_to(Vector3(0, -6, 4.2)))
	for x in [-3,0,3]:
		check(tag + ": approach comparison study at x=%d" % x, await move_to(Vector3(x,-6,4.0)))
	check(tag + ": pass between the small podiums", await move_to(Vector3(1.6,-6,4.0)) and await move_to(Vector3(1.6,-6,-3.3)))
	check(tag + ": walk beside the future sphere", await move_to(Vector3(1.6,-6,-5.5)))
	check(tag + ": reach the opening between the pillars", await move_to(Vector3(0,-6,-6.0)))
	check(tag + ": reach opposite balcony approach", await move_to(Vector3(0, -6, -8.5)))
	check(tag + ": jump six metres to second balcony", await move_to(Vector3(0, -12, -10.2), true))
	check(tag + ": second cushion saves floor 02", game.cushioned_landings == 2 and game.checkpoint == 2)
	check(tag + ": full alternating balcony route survives", game.deaths == 0)
	check(tag + ": enter Coordinates from the north balcony", await move_to(Vector3(0,-12,-6.2)))
	check(tag + ": reach the point on its podium", await move_to(Vector3(0,-12,-5.4)))
	check(tag + ": walk around the pickup podium", await move_to(Vector3(1.2,-12,-5.4)) and await move_to(Vector3(1.2,-12,0)))
	check(tag + ": glass basin remains walkable", await move_to(Vector3(-3,-12,0)))
	check(tag + ": reach Coordinates south doorway", await move_to(Vector3(0,-12,5.5)) and await move_to(Vector3(0,-12,8.4)))
	check(tag + ": jump six metres to Point Lines balcony", await move_to(Vector3(0,-18,10.2),true))
	check(tag + ": third cushion saves Point Lines", game.cushioned_landings==3 and game.checkpoint==3 and game.deaths==0)
	check(tag + ": enter Lines around its service wall", await move_to(Vector3(-3,-18,8.0)) and await move_to(Vector3(-3,-18,4.5)))
	# Resume older floor fixtures below; the new descent above had no relocation.
	game.checkpoint = 2
	# Both new side bays are solid and inside the playable bounds.
	for side in [-1, 1]:
		game.place_player(Vector3(side * 16, -11.94, 0))
		await frames(20)
		check(tag + ": expanded wing is walkable: %d" % side, await move_to(Vector3(side * 19, -12, 0)))
	# Bottom checkpoint survives a fatal fall outside the structure.
	var count: int = game.deaths
	game.place_player(Vector3(float(game.building.spec.width) / 2.0 + 1.0, -12.0, 0))
	await wait_for_recovery(count)
	check(tag + ": fatal bottom-floor fall returns to floor 02", game.deaths == count + 1 and game.checkpoint == 2 and not game.recovering and game.body.is_on_floor() and absf(game.body.global_position.y + 12) < 0.12)
	# A direct six-metre landing costs health and can save the lower checkpoint.
	game.checkpoint = 1
	# Start entirely below the upper slab (including the head/capsule),
	# with the speed gained by falling 2.2 m. The remaining 3.8 m makes
	# a six-metre impact fixture; this is not a traversal claim.
	game.place_player(Vector3(-6, -8.2, 4.5))
	await frames(2) # Clear move_and_slide's contact cache after fixture relocation.
	game.body.velocity.y = -sqrt(2.0 * 9.8 * 2.2)
	count = game.deaths
	await frames(150)
	check(tag + ": one-floor hard landing costs 25 health and saves floor 02", game.deaths == count and game.checkpoint == 2 and game.health.get_health()==75 and absf(game.body.global_position.y + 12) < 0.12)
	check(tag + ": landing clears falling velocity", absf(game.body.velocity.y) < 0.1 and game.airborne_speed == 0.0)
	# A pad only absorbs one floor: excessive speed remains lethal.
	game.checkpoint = 1
	game.place_player(Vector3(0, -2.2, 10.2))
	await frames(2)
	game.body.velocity.y = -13.0
	count = game.deaths
	var cushions_before: int = game.cushioned_landings
	await frames(150)
	check(tag + ": pad rejects an excessive fall", game.deaths == count + 1 and game.last_death == "Hard landing" and game.checkpoint == 1 and game.cushioned_landings == cushions_before)
	# Shaft centre is open: merely passing floor 01 does not save it.
	game.checkpoint = 0
	count = game.deaths
	game.place_player(Vector3(-10, 0.06, 0))
	await wait_for_recovery(count)
	check(tag + ": falling past floors cannot claim their checkpoints", game.checkpoint == 0 and not game.recovering and absf(game.body.global_position.y) < 0.12)
	# Restore the already-tested second-floor state for retry-button checks.
	game.checkpoint = 2
	game.place_player(game.spawn_for(2))
	await frames(25)
	if xr:
		# Keep a nonzero local head offset through recovery: centre the origin,
		# never reset the physical head's tracked pose.
		head.set_pose("default", Transform3D(Basis.IDENTITY, Vector3(0.25, 1.65, 0.15)), Vector3.ZERO, Vector3.ZERO, XRPose.XR_TRACKING_CONFIDENCE_HIGH)
		right.set_input("by_button", true)
		await frames(100)
		right.set_input("by_button", false)
		check("XR retry button restores floor 02", game.checkpoint == 2 and absf(game.body.global_position.y + 12) < 0.12)
		check("XR respawn retains real headset tracking offset", game.camera.position.distance_to(Vector3(0.25, 1.65, 0.15)) < 0.02)
		check("XR respawn centres tracked head over checkpoint", Vector2(game.camera.global_position.x + 6, game.camera.global_position.z - 4.5).length() < 0.1)
		check("XR movement works after respawn", await move_to(Vector3(-4, -12, 4.5)))
		left.set_input("by_button", true)
		await frames(100)
		left.set_input("by_button", false)
		check("XR left Y restarts on roof", game.checkpoint == 0 and absf(game.body.global_position.y) < 0.12)
	game.queue_free()
	await frames(3)
	if xr:
		for item in [head, left, right]: XRServer.remove_tracker(item)

func capture() -> void:
	await start(false)
	game._set_enabled(false)
	game.status.hide()
	game.notice_time = -1.0
	# Photograph the actual scene at eye height; hide desktop help, not artifacts.
	for layer in game.find_children("*", "CanvasLayer", true, false): layer.hide()
	root.msaa_3d = Viewport.MSAA_4X
	var views := [
		["lines-arrival",Vector3(0.5,-16.35,7.6),Vector3(0.5,-16.6,3.2)],
		["lines-overview",Vector3(0,-16.35,-7.7),Vector3(1,-16.8,3)],
		["lines-setting-out",Vector3(-13.2,-16.35,5.2),Vector3(-16.5,-17.0,-1.0)],
		["lines-measure",Vector3(0.5,-16.35,4.8),Vector3(0,-16.7,3.1)],
		["lines-directions",Vector3(-5.7,-16.35,-4.2),Vector3(-1,-17,-2)],
		["lines-follow",Vector3(1.5,-16.35,0.2),Vector3(7.0,-16.8,-1.4)],
		["lines-timber",Vector3(13.3,-16.35,4.7),Vector3(17.0,-16.7,-3.0)],
		["lines-bridge",Vector3(6,-16.35,2.8),Vector3(12,-17.3,1.3)],
		["lines-health",Vector3(16.5,-16.35,4.7),Vector3(16.5,-16.8,6.4)],
		["coordinates-entry",Vector3(0,-10.35,-6.2),Vector3(-0.5,-10.9,2)],
		["coordinates-basin",Vector3(3.4,-10.35,-0.8),Vector3(-2,-11.3,2)],
		["coordinates-point",Vector3(0.8,-10.35,-5.6),Vector3(0,-10.95,-4.5)],
		["coordinates-readouts",Vector3(0,-10.35,4.6),Vector3(0,-10.35,6.65)],
		["point-one-gallery", Vector3(0, -4.35, 6.0), Vector3(0, -4.7, -1.5)],
		["point-one-comparison", Vector3(-0.8,-4.35,4.7), Vector3(0,-4.95,2.5)],
		["point-one-containers", Vector3(-3.5,-4.35,4), Vector3(5,-4.6,-1)],
		["point-one-door", Vector3(1.8,-4.35,-2.3), Vector3(0,-4.5,-7)],
		["balcony-approach", Vector3(0, 1.65, 7.0), Vector3(0, 0, 8.2)],
		["balcony-below", Vector3(0, 1.65, 8.95), Vector3(0, -6, 10.2)],
		["balcony-arrival", Vector3(0, -4.35, 10.2), Vector3(0, -4.7, 0)],
		["balcony-next", Vector3(0, -4.35, -8.95), Vector3(0, -12, -10.2)],
		["side-bay", Vector3(19, -4.35, 5.5), Vector3(11, -4.6, -3)],
		["point-one-fog", Vector3(-12, -4.35, 6.5), Vector3(8, -4.7, -5)],
		["point-one-floor", Vector3(-4, -4.35, 3.7), Vector3(1, -4.8, -4.8)],
		["point-one-studies", Vector3(-1.5, -4.35, 0.5), Vector3(0, -5.0, -5.5)],
		["point-one-absence", Vector3(-3.3, -4.35, 2.9), Vector3(-5, -5.25, 5.5)],
		["point-one-future", Vector3(1.8, -4.35, -1.9), Vector3(0, -4.6, -4.3)],
		["sky-tower", Vector3(34, 15, 37), Vector3(0, -5, 0)],
		["sky-roof", Vector3(3, 1.65, -2), Vector3(-11, 1.4, 9)],
		["point-zero", Vector3(-2.5, 1.65, 3.7), Vector3(-3, 1.1, -4.4)],
		["counter", Vector3(-4.4, 1.65, -2), Vector3(-5, 1.65, -5.5)],
		["origin", Vector3(2.8, 1.65, 3), Vector3(0, 0.65, 0)],
		["roof", Vector3(-6, 1.65, 4.5), Vector3(-9.5, -1, -0.8)],
		["descent", Vector3(-8.35, -0.35, -1.65), Vector3(-11.3, -4.3, 1.25)],
		["floor-one", Vector3(-7, -4.35, 4.5), Vector3(4, -5.5, -3)],
		["floor-two", Vector3(-5, -10.35, 3.5), Vector3(-3, -10.6, -4.9)]
	]
	for item in views:
		if ("void-point-lines" in out or "void-curated-route" in out) and not str(item[0]).begins_with("lines-"): continue
		if (out.get_file() == "2026-10-18-void-coordinates" or (out.get_file() == "mobile" and out.get_base_dir().get_file() == "2026-10-18-void-coordinates")) and item[0] not in ["coordinates-entry", "coordinates-basin", "coordinates-point", "coordinates-readouts", "point-one-containers"]: continue
		game.camera.global_position = item[1]
		game.camera.look_at(item[2])
		await frames(8)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(out.path_join(item[0] + ".png"))
		if item[0] == "point-one-fog":
			game.camera.environment.fog_enabled = false
			await frames(5)
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(out.path_join("point-one-clear.png"))
			game.camera.environment.fog_enabled = true
	game.camera.global_position = Vector3(-3.5, -4.35, 1.5)
	game.camera.look_at(Vector3(-1.5, -5.95, -1.5))
	await frames(5)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join("impact-before.png"))
	game.fire_catalyst()
	await frames(45)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join("impact-after.png"))
	game.queue_free()
	await frames(3)

func lines_checks(use_xr: bool) -> void:
	await start(use_xr)
	var tag := "Lines XR" if use_xr else "Lines desktop"
	game.place_player(game.spawn_for(3))
	await frames(30)
	check(tag+": fourth floor saves its own checkpoint",game.checkpoint==3)
	var content: Node3D = game.building.content
	var setting: Node3D = content.exhibits["3/setting_out"].get_node("Artifact")
	var directions: Node3D = content.exhibits["3/directions"].get_node("Artifact")
	var assembly: Node3D = content.exhibits["3/assembly"].get_node("Artifact")
	var consequences: Node3D = content.exhibits["3/consequences"].get_node("Artifact")
	var defaults := {}
	for root in [setting,directions,assembly,consequences]: defaults[root.area]=root.part_defaults
	FileAccess.open(out.path_join("line-parts.json"),FileAccess.WRITE).store_string(JSON.stringify(defaults,"  "))

	check(tag+": four work areas are built on floor 03",[setting,directions,assembly,consequences].all(func(area): return area.is_in_group("void_lines_area") and is_equal_approx(area.global_position.y,-18)))
	check(tag+": original pairing and measurement implementations",setting.get_node("PairingPoints").get_script().resource_path.ends_with("primitive_encounters/pairing_field.gd") and setting.get_node("MeasurementRoom").get_script().resource_path.ends_with("line_black_box/line_black_box.gd"))
	var field: Node3D = setting.get_node("PairingPoints")
	check(tag+": all twelve points remain available",field.points.size()==12)
	var a: Node3D = field.points[0]
	var b: Node3D = field.points[1]
	a.global_position = b.global_position + Vector3(0.1,0,0)
	a.dropped.emit(a)
	await frames(8)
	check(tag+": release near another point creates a real connection",field.manager._connections.size()>0)
	var room: Node3D = setting.get_node("MeasurementRoom")
	game.place_player(Vector3(0.5,-17.94,7.5))
	await frames(12)
	check(tag+": enter first encounter from the landing",await move_to(Vector3(0.5,-18,4.5)))
	check(tag+": leave through the side opening",await move_to(Vector3(-3.7,-18,4.1)))
	check(tag+": walk round shaft A to the point network",await move_to(Vector3(-16.5,-18,4.2)))
	check(tag+": reach north passage around shaft A",await move_to(Vector3(-19,-18,4.2)) and await move_to(Vector3(-18,-18,-4.3)) and await move_to(Vector3(-6,-18,-4.3)))
	check(tag+": overhead power leaves the arrival slab free",content.get_node("Content3/Socket_NW").position.y>4.5 and content.get_node("Content3/Socket_SE").position.y>4.5)
	room.point_b.position.x += 1.0
	await frames(5)
	check(tag+": existing measurement follows endpoints",room.readout.text=="2.60 m")
	room.reset_line()
	check(tag+": measurement reset restores its two endpoints",room.readout.text=="1.60 m")
	check(tag+": drawn continuation has no collision body",directions.get_node("FollowIntoAir") is Node3D and not directions.get_node("FollowIntoAir") is CollisionObject3D)
	var over_air := ray(Vector3(9.3,-16.0,-1.4),Vector3(9.3,-20,-1.4))
	check(tag+": suspended instruction does not cap the shaft",over_air.is_empty())
	var box := ray(Vector3(4.5,-15,-1.4),Vector3(4.5,-18,-1.4))
	check(tag+": white crate has the promised physical top",not box.is_empty() and is_equal_approx(box.position.y,-16.6))
	game.place_player(Vector3(6.5,-17.94,1.3))
	check(tag+": relocating sets body as well as tracked origin",game.body.global_position.distance_to(Vector3(6.5,-17.94,1.3))<0.01)
	await frames(15)
	check(tag+": fixed timber carries a real player across shaft B",await move_to(Vector3(13.4,-18,1.3)))
	var middle := ray(Vector3(10,-17,1.3),Vector3(10,-19,1.3))
	check(tag+": crossing collision is the reused plank itself",not middle.is_empty() and middle.collider.get_meta("fixed_construction",false) and middle.collider.get_script().resource_path.ends_with("line_body.gd"))
	var loose: Node3D = assembly.get_node("Hand_plank")
	check(tag+": movable specimens remain pickable",loose.enabled and not loose.has_meta("fixed_construction"))
	if use_xr:
		hand_at(right,loose.global_position)
		await frames(12)
		right.set_input("grip",1.0)
		await frames(10)
		check("Lines XR: grip carries original gallery plank",loose.is_picked_up())
		right.set_input("grip",0.0)
		await frames(8)
		check("Lines XR: release leaves plank available",not loose.is_picked_up())
	check(tag+": X and + use the same tower health provider",consequences.hazard.health_provider==game.health and consequences.recovery.health_provider==game.health)
	var danger_at: Vector3 = consequences.hazard.global_position
	var recovery_at: Vector3 = consequences.recovery.global_position
	game.place_player(danger_at+Vector3(0,0.06,-1.3))
	await frames(12)
	check(tag+": walk into existing X",await move_to(danger_at))
	await frames(40)
	var damaged: float = game.health.get_health()
	check(tag+": occupying X reduces health without teleporting",damaged<100 and damaged>0 and not game.recovering)
	check(tag+": leave hazard",await move_to(danger_at+Vector3(0,0,-1.5)))
	var after_exit: float = game.health.get_health()
	await frames(45)
	check(tag+": damage stops on leaving",is_equal_approx(after_exit,game.health.get_health()))
	check(tag+": reach recovery by the optional route",await move_to(recovery_at+Vector3(0,0,-1.5)) and await move_to(recovery_at))
	await frames(8)
	check(tag+": existing plus restores bounded health and is consumed",game.health.get_health()>after_exit and game.health.get_health()<=100 and consequences.recovery.is_spent())
	var deaths: int = game.deaths
	game.health.apply_bite_damage(200)
	await wait_for_recovery(deaths)
	check(tag+": health depletion uses tower recovery on floor 03",game.deaths==deaths+1 and game.checkpoint==3 and not game.recovering and absf(game.body.global_position.y+18)<0.15 and game.health.get_health()==100)
	check(tag+": trace clears on recovery instead of drawing a teleport",directions.trace._trail_points.size()<=2)
	deaths=game.deaths
	game.place_player(Vector3(23,-18,0))
	await frames(150)
	check(tag+": fatal fall returns to Lines with full health",game.deaths==deaths+1 and game.checkpoint==3 and absf(game.body.global_position.y+18)<0.15 and game.health.get_health()==100)
	game.queue_free()
	await frames(3)
	if xr:
		for item in [head,left,right]: XRServer.remove_tracker(item)
