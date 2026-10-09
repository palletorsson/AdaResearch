extends "res://doc/book/iterations/2026-09-19-color-review/late/probes/base.gd"

func run() -> void:
	await museum("Color_Walls")
	var office: Node3D
	var gradient: Node3D
	var navigator: Node3D
	for n in current_scene.find_children("*", "Node3D", true, false):
		if not n.get_script(): continue
		var path: String = n.get_script().resource_path
		if path.ends_with("color_constellation_office.gd"): office = n
		if path.ends_with("gradient_interpolator.gd"): gradient = n
		if path.ends_with("color_space_navigator.gd"): navigator = n
	check(office != null and gradient != null and navigator != null, "all three primary encounters stand in the museum")
	if office == null or gradient == null or navigator == null: quit(1); return
	var player: CharacterBody3D = current_scene.get("_player")
	var head: Camera3D = current_scene.get("_cam")
	player.set_physics_process(false)
	current_scene.get("_feel").set_process(false)
	player.global_position += office.to_global(Vector3(0,1.7,-10)) - head.global_position
	for frame in range(30):
		current_scene.call("_cull_artifacts")
		await process_frame
	check(is_zero_approx(office.global_position.y), "office furniture starts on the floor")
	check(office.office_panes.size() == 40, "forty glass partitions")
	check(office.office_panes.all(func(p): return is_zero_approx(fposmod(p.rotation_degrees.y,90))), "all partitions remain orthogonal")
	var desks := 0
	for furniture in office.find_children("*", "MeshInstance3D", true, false):
		if furniture.mesh is BoxMesh and furniture.mesh.size.is_equal_approx(Vector3(1.7,0.065,0.7)): desks += 1
	check(desks == 8, "eight furnished cubicles")
	var pane_transforms: Array[Transform3D] = []
	var collisions: Array[RID] = []
	for pane in office.office_panes:
		pane_transforms.append(pane.global_transform)
		collisions.append(pane.get_child(0).get_rid())
	var query := PhysicsShapeQueryParameters3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.32
	capsule.height = 1.5
	query.shape = capsule
	query.collision_mask = 1
	query.exclude = [player.get_rid()]
	for mode in range(2):
		query.transform.origin = office.to_global(Vector3(0,0.85,-7))
		query.motion = office.global_basis * Vector3(0,0,14)
		check(current_scene.get_world_3d().direct_space_state.cast_motion(query)[0] > 0.99, "central aisle stays open in mode %d" % mode)
		for row in range(4):
			for side in [-1,1]:
				query.transform.origin = office.to_global(Vector3(0,0.85,-5.4+row*3.6))
				query.motion = office.global_basis * Vector3(side*2.5,0,0)
				check(current_scene.get_world_3d().direct_space_state.cast_motion(query)[0] > 0.99, "cubicle entrance %d/%d stays open in mode %d" % [row,side,mode])
		query.transform.origin = office.to_global(Vector3(0,0.85,-4.35))
		query.motion = office.global_basis * Vector3(2.5,0,0)
		check(current_scene.get_world_3d().direct_space_state.cast_motion(query)[0] < 0.9, "a pane blocks the body in mode %d" % mode)
		player.global_position += office.to_global(Vector3(0,1.7,-6.4)) - head.global_position
		head.look_at(office.to_global(Vector3(4,1.4,0)))
		await create_timer(0.6).timeout
		for frame in range(20):
			current_scene.call("_cull_artifacts")
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OUT+"walls_%s_museum.png" % ("glass" if mode == 0 else "opaque"))
		office.glass_button.pressed.emit()
		check(office.office_panes.all(func(p): return is_equal_approx(p.material_override.albedo_color.a, 1.0 if mode == 0 else 0.26)), "real button changes all pane opacity")
	var same := true
	for i in range(40): same = same and pane_transforms[i].is_equal_approx(office.office_panes[i].global_transform) and collisions[i] == office.office_panes[i].get_child(0).get_rid()
	check(same, "opacity changes preserve transforms and exact collision bodies")
	check(gradient.comparison_controls.size() == 3, "interpolator has three reachable comparison controls")
	print("WALLS_CONTROL_HEIGHT ", gradient.comparison_controls[0].global_position.y, " root ", gradient.global_position.y)
	check(gradient.comparison_controls[0].global_position.y >= 0.95, "interpolation controls stand above the floor")
	check(gradient._cubes[0].global_position.y > gradient.comparison_controls[0].global_position.y + 0.30, "gradient values stand above the controls")
	var mids: Color = gradient._cubes[7].material_override.albedo_color
	var first: Color = gradient._cubes[0].material_override.albedo_color
	var last: Color = gradient._cubes[15].material_override.albedo_color
	gradient.comparison_controls[2].pressed.emit()
	check(gradient._mode_hsv, "real mode button selects HSV")
	check(first.is_equal_approx(gradient._cubes[0].material_override.albedo_color) and last.is_equal_approx(gradient._cubes[15].material_override.albedo_color), "same endpoints survive mode change")
	check(not mids.is_equal_approx(gradient._cubes[7].material_override.albedo_color), "intermediate colour changes with the interpolation space")
	gradient.comparison_controls[0].pressed.emit()
	gradient.comparison_controls[1].pressed.emit()
	check(gradient._color_a_idx == 1 and gradient._color_b_idx == 6, "endpoint buttons choose the next presets")
	check(navigator.global_position.y - navigator.cube_size/2 >= 0.8, "whole RGB model stands above its plinth")
	check(navigator.get_node("RGBSamples").multimesh.instance_count == 500 and navigator.get_node("HSLSamples").multimesh.instance_count == 500, "two finite colour sample models")
	var rgb: MultiMesh = navigator.get_node("RGBSamples").multimesh
	var mapped := true
	for i in range(rgb.instance_count):
		var p: Vector3 = rgb.get_instance_transform(i).origin/navigator.cube_size + Vector3.ONE*0.5
		var c: Color = rgb.get_instance_color(i)
		mapped = mapped and absf(c.r-p.x) < 0.004 and absf(c.g-p.y) < 0.004 and absf(c.b-p.z) < 0.004
	check(mapped, "RGB positions correspond to stored channel values")
	for exhibit in [gradient, navigator]:
		player.global_position += exhibit.to_global(Vector3(0.3,0.8,2.4)) - head.global_position
		head.look_at(exhibit.to_global(Vector3(0.3,0.15,0)))
		for frame in range(25):
			current_scene.call("_cull_artifacts")
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OUT+"walls_%s_museum.png" % ("gradient" if exhibit == gradient else "coordinates"))
	var grid: Node3D=office.get_parent()
	while not grid.is_in_group("grid_system"): grid=grid.get_parent()
	if "after" in OUT:
		check(grid.to_local(navigator.global_position).z>grid.to_local(office.global_position).z+7.0 and grid.to_local(gradient.global_position).z>grid.to_local(office.global_position).z+7.0,"both colour models follow the full office footprint")
		query.exclude=[player.get_rid()]
		var routes: Array=[
			[Vector3(0,0.85,6.5),Vector3(0,0.85,9.0),"leave office aisle"],
			[Vector3(0,0.85,9.0),Vector3(-5,0.85,9.0),"reach RGB/HSV model approach"],
			[Vector3(0,0.85,9.0),Vector3(5,0.85,9.0),"reach interpolation approach"],
			[Vector3(0,0.85,9.0),Vector3(0,0.85,14.0),"continue between models"],
			[Vector3(0,0.85,14.0),Vector3(-5,0.85,14.0),"turn toward museum exit"],
			[Vector3(-5,0.85,14.0),Vector3(-5,0.85,19.2),"leave through museum exit"]]
		for route_check: Array in routes:
			query.transform.origin=office.to_global(route_check[0]);query.motion=office.global_basis*(route_check[1]-route_check[0])
			var result: PackedFloat32Array=current_scene.get_world_3d().direct_space_state.cast_motion(query)
			check(result[0]>0.99,"clear capsule route: "+route_check[2]+" "+str(result))
	var route: Dictionary={"office_grid_position":str(grid.to_local(office.global_position)),"navigator_grid_position":str(grid.to_local(navigator.global_position)),"gradient_grid_position":str(grid.to_local(gradient.global_position)),"segments":[]}
	for rec: Dictionary in current_scene.get("_segments"):
		if rec.node.get_meta("em_map","")=="Color_Walls":
			for key in rec:
				if not rec[key] is Object: route["segments"].append([key,str(rec[key])])
	var rf:=FileAccess.open(OUT+"walls-route.json",FileAccess.WRITE);rf.store_string(JSON.stringify(route,"  "))
	var cam:=Camera3D.new();current_scene.add_child(cam);cam.fov=67;root.size=Vector2i(1400,900)
	for view in [[Vector3(12,13,1),Vector3(23,0,22),"overview"],[Vector3(23,1.7,10),Vector3(23,1.3,27),"entrance"]]:
		cam.global_position=grid.to_global(view[0]);cam.look_at(grid.to_global(view[1]))
		player.global_position=grid.to_global(Vector3(23,0,20));current_scene.call("_cull_artifacts")
		for frame in range(40): cam.make_current();await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OUT+"Color_Walls-"+view[2]+".png")
	var report := {"checks":checks,"failures":failures,"headset_tested":false,"input":"Actual museum body sweeps in both opacity states; real button signals, collision identity, colour values and sample positions checked. Tracked hands untested."}
	var f := FileAccess.open(OUT+"probe_walls_encounter.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(report,"  "))
	print("WALLS_ENCOUNTER ",JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
