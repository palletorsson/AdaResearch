extends SceneTree
var gallery: Node3D
var checks: Array = []
var views: Array = []
var routes: Array = []
var states: Array = []

func _initialize() -> void:
	run.call_deferred()
	var watchdog := Timer.new()
	watchdog.wait_time = 90
	watchdog.one_shot = true
	watchdog.autostart = true
	watchdog.timeout.connect(func(): push_error("Native study exceeded 90 seconds"); quit(2))
	root.add_child(watchdog)

func check(label: String, passed: bool) -> void:
	checks.append({"name":label,"passed":passed})
	print("PASS " if passed else "FAIL ",label)

func settle() -> void:
	await physics_frame
	await physics_frame
	await process_frame

func capture(label: String) -> Image:
	for i in 5:
		await process_frame
	await RenderingServer.frame_post_draw
	var result := root.get_texture().get_image()
	result.save_png("res://captures/"+label+".png")
	views.append({"file":label+".png","arrangement":gallery.artifact.arrangement,"camera":str(gallery.camera.transform)})
	return result

func geometry_signature() -> String:
	var result := ""
	for piece in gallery.artifact.pieces:
		var mesh: Mesh = piece.get_child(0).mesh
		result += str(mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX])
	return result.sha256_text()

func click(button: Button) -> void:
	var position := button.get_global_rect().get_center()
	var move := InputEventMouseMotion.new()
	move.position = position
	Input.parse_input_event(move)
	await process_frame
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.position = position
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		Input.parse_input_event(event)
		await process_frame

func sampled_route(which: int, radius: float) -> Dictionary:
	# This is a bounded, finite-resolution route probe, not a universal proof.
	# Every graph edge is a swept physical capsule, not just a cell label.
	var capsule := CapsuleShape3D.new()
	capsule.radius = radius
	capsule.height = 1.75
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	query.collision_mask = 1
	query.exclude = [gallery.player.get_rid()]
	query.margin = 0.001
	var space: PhysicsDirectSpaceState3D = gallery.get_world_3d().direct_space_state
	var step := 0.14
	var extent := 2.94
	var side := 43
	var free: Array[bool] = []
	for z in side:
		for x in side:
			query.transform = Transform3D(Basis.IDENTITY,Vector3(-extent+x*step,0.895,-extent+z*step))
			free.append(space.intersect_shape(query,1).is_empty())
	var queue: Array[int] = []
	var parent: Dictionary = {}
	for x in side:
		var i := (side-1)*side+x
		if free[i]:
			queue.append(i)
			parent[i] = -1
	var cursor := 0
	var found := -1
	var directions := [Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1),Vector2i(0,-1),Vector2i(1,1),Vector2i(-1,1),Vector2i(1,-1),Vector2i(-1,-1)]
	while cursor < queue.size() and found < 0:
		var i := queue[cursor]
		cursor += 1
		var x := i % side
		var z := i / side
		if z == 0:
			found = i
			break
		for direction in directions:
			var nx: int = x + direction.x
			var nz: int = z + direction.y
			if nx < 0 or nz < 0 or nx >= side or nz >= side:
				continue
			var next := nz*side+nx
			if parent.has(next) or not free[next]:
				continue
			query.transform = Transform3D(Basis.IDENTITY,Vector3(-extent+x*step,0.895,-extent+z*step))
			query.motion = Vector3(direction.x*step,0,direction.y*step)
			var fractions := space.cast_motion(query)
			if fractions[0] < 0.9999:
				continue
			parent[next] = i
			queue.append(next)
	var points: Array = []
	var at := found
	while at >= 0:
		points.push_front([-extent+(at%side)*step,0.02,-extent+(at/side)*step])
		at = parent[at]
	var result := {"arrangement":which,"radius":radius,"height":1.75,"step":step,"bounds":[-extent,extent],"crossing_found":found>=0,"reachable_samples":parent.size(),"route":points}
	routes.append(result)
	return result

func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://captures")
	root.content_scale_size = Vector2i(1600,1000)
	root.size = Vector2i(1600,1000)
	gallery = load("res://gallery.tscn").instantiate()
	root.add_child(gallery)
	for i in 40:
		await process_frame
	gallery.panel.visible = false
	var initial_geometry := geometry_signature()
	var original_sites: Array = gallery.artifact.evidence.sites.duplicate()
	var original_heights: Array = gallery.artifact.evidence.heights.duplicate()
	states.append(gallery.artifact.evidence.duplicate(true))
	check("49 fragments and exactly seven raised",gallery.artifact.evidence.fragments==49 and gallery.artifact.evidence.raised==7)
	var unique_sites := {}
	for site in original_sites:
		unique_sites[site] = true
	check("49 unique horizontal sites",unique_sites.size()==49)
	var raised_in_rows: Array = []
	for z in 7:
		var count := 0
		for x in 7:
			count += 1 if gallery.artifact.lifted_cells[z*7+x] else 0
		raised_in_rows.append(count)
	check("passage raises one fragment in every row",raised_in_rows==[1,1,1,1,1,1,1])
	var hero := await capture("passage-room")
	check("native capture is 1600 by 1000",hero.get_size()==Vector2i(1600,1000))
	var camera_transform: Transform3D = gallery.camera.transform
	gallery.select_arrangement(1)
	gallery.panel.visible = false
	states.append(gallery.artifact.evidence.duplicate(true))
	await settle()
	var pockets := await capture("pockets-room")
	check("arrangement changes native pixels",hero.get_data()!=pockets.get_data())
	check("comparison camera is identical",gallery.camera.transform==camera_transform)
	check("horizontal sites and fragment meshes remain identical",gallery.artifact.evidence.sites==original_sites and geometry_signature()==initial_geometry)
	var sorted_before := original_heights.duplicate()
	var sorted_after: Array = gallery.artifact.evidence.heights.duplicate()
	sorted_before.sort()
	sorted_after.sort()
	check("the complete height inventory remains identical",sorted_before==sorted_after)
	check("pockets still raises exactly seven",gallery.artifact.evidence.raised==7)
	gallery.set_view(1)
	gallery.panel.visible = false
	await capture("pockets-entry")
	gallery.player.position = Vector3(0,0.03,3.4)
	await settle()
	var collision: KinematicCollision3D = gallery.player.move_and_collide(Vector3(0,0,-6.8))
	check("same straight crossing is physically blocked in pockets",collision!=null and gallery.player.position.z>2.0)
	var pockets_route := sampled_route(1,0.28)
	check("no sampled north-south crossing inside pockets field for 0.56 m body",not pockets_route.crossing_found)
	gallery.select_arrangement(0)
	gallery.panel.visible = false
	await settle()
	await capture("passage-entry")
	gallery.player.position = Vector3(0,0.03,3.4)
	await settle()
	collision = gallery.player.move_and_collide(Vector3(0,0,-6.8))
	check("the same capsule crosses the passage physically",collision==null and gallery.player.position.z < -3.3)
	var passage_route := sampled_route(0,0.28)
	check("sampled passage is connected for the same body",passage_route.crossing_found)
	# Keep the corridor fixed and disclose the body model as another variable.
	var wide_route := sampled_route(0,0.66)
	check("a 1.32 m wide capsule has no sampled crossing in the same passage",not wide_route.crossing_found)
	gallery.player.position = Vector3(0,0.03,0)
	await settle()
	collision = gallery.player.move_and_collide(Vector3(0,-0.25,0))
	check("the room floor supports the visitor",collision!=null and gallery.player.position.y>=-0.01)
	gallery.player.position = Vector3(3.55,0.03,3.4)
	await settle()
	collision = gallery.player.move_and_collide(Vector3(0,0,-6.8))
	check("walking around the installation remains possible",collision==null and gallery.player.position.z < -3.3)
	gallery.set_view(0)
	gallery.panel.visible = false
	var piece_before: Transform3D = gallery.artifact.pieces[3].transform
	var swapped: bool = gallery.artifact.swap_cells(3,0)
	check("swapping two unlike heights preserves seven lifted",swapped and gallery.artifact.evidence.raised==7)
	var changed: Array[int] = []
	for i in 49:
		if gallery.artifact.evidence.heights[i] != original_heights[i]:
			changed.append(i)
	check("swapping changes only the two height assignments",changed==[0,3] and gallery.artifact.pieces[3].position.y!=piece_before.origin.y and gallery.artifact.evidence.sites==original_sites)
	check("same-height and invalid swaps are rejected",not gallery.artifact.swap_cells(1,2) and not gallery.artifact.swap_cells(-1,0))
	gallery.select_arrangement(0)
	check("reset restores the exact original assignment and geometry",gallery.artifact.evidence.heights==original_heights and geometry_signature()==initial_geometry)
	gallery.panel.visible = true
	await settle()
	await click(gallery.rule_buttons[1])
	check("real GUI click changes the arrangement",gallery.artifact.arrangement==1)
	await click(gallery.rule_buttons[0])
	await click(gallery.cell_buttons[3])
	await click(gallery.cell_buttons[0])
	check("real grid clicks exchange two heights",gallery.artifact.arrangement==2 and gallery.artifact.lifted_cells[0] and not gallery.artifact.lifted_cells[3] and gallery.artifact.evidence.raised==7)
	gallery.select_arrangement(0)
	await click(gallery.body_button)
	check("real body control changes the actual capsule width",is_equal_approx(gallery.player.get_child(0).shape.radius,0.66) and gallery.body_width==1.32)
	gallery.player.position = Vector3(0,0.03,3.4)
	await settle()
	collision = gallery.player.move_and_collide(Vector3(0,0,-6.8))
	check("wider visitor physically stops in unchanged passage",collision!=null and gallery.player.position.z > -2.0)
	check("changing body preserves the artwork",gallery.artifact.evidence.heights==original_heights and geometry_signature()==initial_geometry)
	await click(gallery.body_button)
	await capture("controls")
	gallery.start_walk()
	check("walking uses the visitor camera and captures mouse",gallery.walking and gallery.eye.current and Input.mouse_mode==Input.MOUSE_MODE_CAPTURED)
	gallery.select_arrangement(1)
	check("changing arrangement exits walking before moving obstacles",not gallery.walking and gallery.camera.current and Input.mouse_mode==Input.MOUSE_MODE_VISIBLE)
	gallery.select_arrangement(0)
	gallery.panel.visible = false
	gallery.camera.look_at_from_position(Vector3(0,1.62,0.7),Vector3(0,1.62,-4))
	await capture("inside")
	var passed := true
	for result in checks:
		passed = passed and result.passed
	var report := {"passed":passed,"checks":checks,"views":views,"states":states,"routes":routes,"engine":Engine.get_version_info(),"scope":"Native desktop study. Sampled path tests have explicit body, boundary and 14 cm resolution. No installed hall, physical headset, weight or destruction simulation."}
	FileAccess.open("res://captures/results.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	quit(0 if passed else 1)
