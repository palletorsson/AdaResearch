extends "res://commons/testing/probe_physical_console_halls.gd"
## Actual two-builder hall: placement, native button input and comparison independence.
var pointer: Node3D

func press(button: Node3D) -> void:
	var area: Node3D = button.get_node("InteractableAreaButton")
	XRToolsPointerEvent.pressed(pointer, area, area.global_position)
	XRToolsPointerEvent.released(pointer, area, area.global_position)

func complete(cube: Node3D) -> void:
	for i in 45: cube.call("_process", .51)

func run() -> void:
	var spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OS.get_cmdline_user_args()[0]))
	folder = spec.run
	report.room = spec.room
	report.scope = "Actual museum hall, standing capsule, native pointer buttons, world control dimensions. Native corner grab and held-action guards; desktop evidence, headset comfort not tested."
	museum = load(folder+"museum_snapshot.tscn").instantiate()
	museum.set("EM_CONTROL", folder+"control.json")
	museum.set("_hand_path", folder+"necklace_hand.json")
	museum.set("_overrides_path", folder+"em_overrides.json")
	museum.set("start_chapter", spec.sequence)
	museum.set("start_map", spec.room)
	museum.set("plan_file", folder+"em_plan.json")
	root.add_child(museum)
	var started := Time.get_ticks_msec()
	while not museum.get("_museum_core_ready") and Time.get_ticks_msec()-started < 60000: await process_frame
	museum.set("_lazy_pending", 0)
	museum.set_process(false)
	museum.set_physics_process(false)
	museum.call("flush_stamps")
	await create_timer(1).timeout
	var hall: Node3D
	for child in museum.get_children():
		if child is Node3D and child.get_meta("em_map", "") == spec.room: hall = child; break
	check(hall != null, "Requested hall built")
	if hall == null: finish(); return
	origin = hall.global_position
	walker = museum.get("_player")
	if walker: walker.set_physics_process(false)
	pointer = Node3D.new()
	root.add_child(pointer)
	camera = Camera3D.new()
	root.add_child(camera)
	camera.current = true
	var cubes: Array[Node3D] = []
	for entry in museum.get("_edit_records"):
		if entry.get("seg") == hall and entry.get("token") == spec.token and entry.node.has_node("ExperimentPanel") and not cubes.has(entry.node): cubes.append(entry.node)
	check(cubes.size() == 2, "Both authored builders remain for comparison")
	report.builders = []
	report.approaches = []
	report.grab_poses = []
	for index in cubes.size():
		artifact = cubes[index]
		var panel: Node3D = artifact.get_node("ExperimentPanel")
		var front := artifact.global_basis.z.normalized()
		front.y = 0
		front = front.normalized()
		feet = panel.global_position + front*.48
		var floor_hit := floor_at(feet)
		check(not floor_hit.is_empty(), "Builder %d operating pose has floor" % index)
		if floor_hit.is_empty(): continue
		feet.y = floor_hit.position.y
		if walker: walker.global_position = feet
		museum.call("_cull_artifacts")
		artifact.set_process(false)
		complete(artifact)
		panel.update_readout()
		await process_frame
		await physics_frame
		report.builders.append({"index":index, "artifact":arr(artifact.global_position-origin), "panel":arr(panel.global_position-origin), "feet":arr(feet-origin)})
		var capsule := CapsuleShape3D.new()
		capsule.radius = .22
		capsule.height = 1.7
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = capsule
		query.collision_mask = 1
		query.transform.origin = feet+Vector3.UP*.87
		if walker: query.exclude = [walker.get_rid()]
		check(museum.get_world_3d().direct_space_state.intersect_shape(query).is_empty(), "Builder %d standing capsule clears geometry" % index)
		query.transform.origin = feet + front + Vector3.UP*.87
		query.motion = -front
		var motion := museum.get_world_3d().direct_space_state.cast_motion(query)
		var supported := true
		for i in 6:
			var hit := floor_at(feet + front*float(i)/5)
			supported = supported and not hit.is_empty() and absf(hit.get("position",Vector3(0,-999,0)).y-feet.y)<.05
		var clear_start := museum.get_world_3d().direct_space_state.intersect_shape(query).is_empty()
		report.approaches.append({"builder":index,"clear_fraction":motion[0],"level_floor":supported,"clear_start":clear_start})
		check(motion[0]>.99 and supported and clear_start, "Builder %d last metre is clear and supported" % index)
		if walker and motion[0]>.99 and supported and clear_start:
			walker.global_position = feet+front
			walker.velocity = Vector3.ZERO
			for frame in 80:
				var delta := feet-walker.global_position
				delta.y = 0
				var direction := delta.normalized() if delta.length()>.03 else Vector3.ZERO
				walker.velocity = Vector3(direction.x*1.5,0.0 if walker.is_on_floor() else walker.velocity.y-11.0/60,direction.z*1.5)
				walker.move_and_slide()
				await physics_frame
			check(walker.global_position.distance_to(feet)<.12,"Builder %d museum walker reaches console" % index)
		for name in ["ReplayButton","PauseButton","RestoreButton","DiagonalButton"]:
			var button: Node3D = panel.get_node(name)
			inspect_target(button, button.get_node("InteractableAreaButton/CollisionShape3D").global_position, "%d %s" % [index,name], button)
		for handle_index in artifact.handle_nodes.size():
			var corner: Node3D = artifact.handle_nodes[handle_index]
			check(corner.global_position.y-feet.y>=.55 and corner.global_position.y-feet.y<=1.70,"Builder %d v%d stays in tested grip height band" % [index,handle_index])
			var pose := {}
			for i in 16:
				var direction := front.rotated(Vector3.UP,TAU*float(i)/16)
				var candidate := artifact.global_position+direction*1.05
				candidate.y = feet.y
				var distance := Vector2(candidate.x-corner.global_position.x,candidate.z-corner.global_position.z).length()
				if distance>.70: continue
				query.motion = Vector3.ZERO
				query.transform.origin = candidate+Vector3.UP*.87
				if not museum.get_world_3d().direct_space_state.intersect_shape(query).is_empty(): continue
				var ground := floor_at(candidate)
				if ground.is_empty() or absf(ground.position.y-feet.y)>.05: continue
				var from := candidate+Vector3.UP*1.2
				var ray := PhysicsRayQueryParameters3D.create(from,corner.global_position+(corner.global_position-from).normalized()*.02,5)
				if walker: ray.exclude = [walker.get_rid()]
				var hit := museum.get_world_3d().direct_space_state.intersect_ray(ray)
				if not hit.is_empty() and hit.collider==corner:
					pose = {"builder":index,"corner":handle_index,"feet":arr(candidate-origin),"height":corner.global_position.y-feet.y,"horizontal_distance":distance}
					break
			check(not pose.is_empty(),"Builder %d v%d has a clear supported near-grab pose" % [index,handle_index])
			report.grab_poses.append(pose)
		camera.global_position = artifact.global_position+front*2.7+Vector3.UP*.7
		camera.look_at(artifact.global_position+Vector3.UP*.05)
		camera.fov = 70
		await capture("builder-%d-encounter" % index)
		camera.global_position = feet+Vector3.UP*1.65
		camera.look_at(panel.global_position)
		camera.fov = 72
		await capture("builder-%d-controls" % index)
		press(panel.get_node("ReplayButton"))
		artifact.call("_process", .51)
		press(panel.get_node("PauseButton"))
		if panel.has_node("ReadoutSurface"):
			check(panel.get_node("PauseButtonCaption").get_meta("text")=="RESUME" and panel.get_node("PauseButton").is_selected(),"Builder %d pause becomes a lit RESUME control" % index)
		var step: int = artifact.animation_step
		artifact.call("_process", 4.0)
		check(artifact.animation_step == step and artifact.discovery_paused, "Builder %d pause stops its assembly" % index)
		press(panel.get_node("PauseButton"))
		complete(artifact)
		check(artifact.get_current_phase() == "complete" and artifact.handle_nodes[6].enabled, "Builder %d resume reveals usable corners" % index)
		press(panel.get_node("DiagonalButton"))
		check(artifact._diagonal_lines.all(func(line): return line.visible), "Builder %d diagonal button reveals all six source diagonals" % index)
		var peer: Node3D = cubes[1-index]
		var peer_vertices: Array = peer.vertices.duplicate()
		var edges: Array = artifact.edges.duplicate(true)
		var triangles: Array = artifact.triangles.duplicate(true)
		var handle: Node3D = artifact.handle_nodes[6]
		var grabber := TestGrabber.new()
		root.add_child(grabber)
		grabber.global_transform = handle.global_transform
		grabber.held = handle
		handle.pick_up(grabber)
		grabber.global_position += artifact.global_basis*Vector3(.20,.15,.1)
		for i in 8: await process_frame; await physics_frame
		artifact.call("_process",.1)
		await process_frame # Mesh rebuilding is deferred by the builder.
		panel.update_readout()
		var held_vertices: Array = artifact.vertices.duplicate()
		check(handle.is_picked_up(), "Builder %d real XRTools grab holds v6" % index)
		check(not artifact.vertices[6].is_equal_approx(artifact._initial_vertices[6]), "Builder %d held corner moves in local geometry" % index)
		press(panel.get_node("ReplayButton"))
		check(artifact.get_current_phase()=="complete" and handle.is_picked_up(), "Builder %d replay cannot interrupt a held corner" % index)
		press(panel.get_node("RestoreButton"))
		check(artifact.vertices==held_vertices and handle.is_picked_up(), "Builder %d restore cannot reset a held corner" % index)
		if panel.has_node("ReadoutSurface"):
			check(not panel.get_node("ReplayButton").get_meta("action_ready") and not panel.get_node("RestoreButton").get_meta("action_ready"),"Builder %d held-state actions visibly dim" % index)
			check_readout(panel,index)
		camera.global_position = feet+Vector3.UP*1.65
		camera.look_at(artifact.global_position)
		camera.fov = 88
		await capture("builder-%d-held" % index)
		grabber.drop_object()
		grabber.queue_free()
		artifact.call("_process",.1)
		await process_frame # Mesh rebuilding is deferred by the builder.
		panel.update_readout()
		check(artifact.edges==edges and artifact.triangles==triangles, "Builder %d moving a corner preserves connectivity" % index)
		check(peer.vertices==peer_vertices, "Builder %d leaves its comparison partner unchanged" % index)
		if panel.has_node("ReadoutSurface"):
			check(panel.get_node("ReplayButton").get_meta("action_ready") and panel.get_node("RestoreButton").get_meta("action_ready"),"Builder %d releasing restores available actions" % index)
		press(panel.get_node("ReplayButton"))
		complete(artifact)
		check(artifact.vertices==held_vertices, "Builder %d replay retains deformation after release" % index)
		press(panel.get_node("RestoreButton"))
		check(artifact.vertices == artifact._initial_vertices, "Builder %d restore retains initial cube" % index)
	finish()

func check_readout(panel: Node3D, index: int) -> void:
	var surface: Node3D = panel.get_node("ReadoutSurface")
	var label: Label = surface.table
	var font := label.get_theme_font("font")
	var size := label.get_theme_font_size("font_size")
	var lines := label.text.split("\n")
	var width := 0.0
	for line in lines: width = maxf(width,font.get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x)
	var height := ceilf(font.get_height(size))*lines.size()+label.get_theme_constant("line_spacing")*maxi(0,lines.size()-1)
	check(width<=surface.viewport.size.x-64 and height<=surface.viewport.size.y-140,"Builder %d held-corner text fits its 2D screen" % index)
	check(size>=22,"Builder %d readout keeps at least 22 px per metre-scaled viewport" % index)
	check(panel.is_set_as_top_level(),"Builder %d console is excluded from specimen seating" % index)
	check(absf(panel.get_node("UprightSupport").global_position.y-feet.y)<.05,"Builder %d console support stands on hall floor" % index)
	# Compare slopes from the eye: top of readout stays below the cube's front bottom.
	var eye := feet+Vector3.UP*1.65
	var top: Vector3 = panel.to_global(Vector3(0,float(panel.surface.size_m.y)*.5+.02,0))
	var bottom: Vector3 = artifact.to_global(Vector3(0,-.5,.5))
	var top_angle := atan2(top.y-eye.y,Vector2(top.x-eye.x,top.z-eye.z).length())
	var bottom_angle := atan2(bottom.y-eye.y,Vector2(bottom.x-eye.x,bottom.z-eye.z).length())
	check(top_angle<bottom_angle,"Builder %d readout stays below the intact cube from operating eye" % index)
