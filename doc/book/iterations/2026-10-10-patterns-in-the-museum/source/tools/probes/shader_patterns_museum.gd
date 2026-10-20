extends SceneTree
var checks: Array = []
var museum: Node3D
var hall: Node3D
var stage: Node3D
var camera: Camera3D
var origin: Vector3
var output: String

func _initialize() -> void: call_deferred("run")
func check(ok: bool, title: String) -> void:
	checks.append({"passed": ok, "test": title}); print("PASS " if ok else "FAIL ", title)
func tick() -> void:
	for i in range(5): await process_frame
func photo(title: String, at: Vector3, target: Vector3, fov: float = 75) -> void:
	camera.global_position = stage.to_global(at); camera.look_at(stage.to_global(target)); camera.fov = fov
	for i in range(8): camera.make_current(); await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output + title + ".png")

func shader_pixels() -> void:
	var view := SubViewport.new(); view.size = Vector2i(128,128); view.own_world_3d = true; view.render_target_update_mode = SubViewport.UPDATE_ALWAYS; root.add_child(view)
	var env := WorldEnvironment.new(); env.environment = Environment.new(); env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color.WHITE; env.environment.ambient_light_energy = 1.0; view.add_child(env)
	var mat: ShaderMaterial = stage.square_material.duplicate(); mat.set_shader_parameter("density", 1.0); mat.set_shader_parameter("phase", 0.0)
	var q := MeshInstance3D.new(); var mesh := QuadMesh.new(); mesh.size = Vector2(2,2); q.mesh = mesh; q.material_override = mat; view.add_child(q)
	var cam := Camera3D.new(); cam.projection = Camera3D.PROJECTION_ORTHOGONAL; cam.size = 2; cam.position = Vector3(0,0,2); view.add_child(cam); cam.make_current()
	await tick(); await RenderingServer.frame_post_draw
	var image := view.get_texture().get_image()
	var ink: Color = image.get_pixel(64,64); var ground: Color = image.get_pixel(1,1)
	print("PIXELS ", ink, " / ", ground)
	check(ground.g - ink.g > .15, "GPU: repeated circle has distinct ink and ground")
	check(absf(image.get_pixel(21,64).g - ink.g) < .05 and absf(image.get_pixel(106,64).g - ink.g) < .05, "GPU: the same mask repeats at three UV addresses")
	mat.set_shader_parameter("phase", .5); await tick(); await RenderingServer.frame_post_draw
	check(view.get_texture().get_image().get_pixel(64,64).g - ink.g > .15, "GPU: half-tile shift changes the fixed sample")
	mat.set_shader_parameter("phase", 1.0); await tick(); await RenderingServer.frame_post_draw
	check(absf(view.get_texture().get_image().get_pixel(64,64).g - ink.g) < .05, "GPU: one complete tile shift returns the sample")
	# Follow a translated receiver with the camera. World phase changes; attached phase is retained.
	mat.set_shader_parameter("phase", 0.0); mat.set_shader_parameter("use_uv", false); mat.set_shader_parameter("field_origin", Vector3.ZERO)
	q.position = Vector3(.5,.5,0); cam.position = Vector3(.5,.5,2); await tick(); await RenderingServer.frame_post_draw
	var world_before: Color = view.get_texture().get_image().get_pixel(64,64)
	q.position.x += .5; cam.position.x += .5; await tick(); await RenderingServer.frame_post_draw
	check(view.get_texture().get_image().get_pixel(64,64).g - world_before.g > .15, "GPU: a moving receiver crosses a room-anchored pattern")
	mat.set_shader_parameter("attached", true); mat.set_shader_parameter("receiver_inverse", q.global_transform.affine_inverse()); await tick(); await RenderingServer.frame_post_draw
	var attached_before := view.get_texture().get_image().duplicate()
	q.position.x += .37; cam.position.x += .37; mat.set_shader_parameter("receiver_inverse", q.global_transform.affine_inverse()); await tick(); await RenderingServer.frame_post_draw
	var attached_after := view.get_texture().get_image()
	var max_error := 0.0
	for p in [Vector2i(21,31),Vector2i(64,64),Vector2i(95,75)]: max_error = maxf(max_error, absf(attached_before.get_pixelv(p).g - attached_after.get_pixelv(p).g))
	check(max_error < .02, "GPU: an attached pattern stays at the same receiver samples after translation")
	view.queue_free()

func run() -> void:
	root.size = Vector2i(1800,1200); root.msaa_3d = Viewport.MSAA_4X; create_timer(125).timeout.connect(func(): quit(98))
	var spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OS.get_cmdline_user_args()[0])); output = spec.run
	museum = load(output + "museum_snapshot.tscn").instantiate()
	museum.set("EM_CONTROL", output + "control.json"); museum.set("_hand_path", output + "necklace_hand.json"); museum.set("_overrides_path", output + "em_overrides.json")
	museum.set("start_chapter", "shaders"); museum.set("start_map", "Shader_05_Patterns"); museum.set("plan_file", output + "plan.json")
	root.add_child(museum); current_scene = museum
	var begin := Time.get_ticks_msec()
	while not bool(museum.get("_museum_core_ready")) and Time.get_ticks_msec() - begin < 65000: await process_frame
	museum.set("_lazy_pending", 0); museum.set_process(false); museum.set_physics_process(false); museum.call("flush_stamps"); await create_timer(1).timeout
	var old: Camera3D = museum.get("_cam")
	if old:
		for timer in old.find_children("*", "Timer", true, false): timer.stop()
	for child in museum.get_children():
		if child is Node3D and str(child.get_meta("em_map", "")) == "Shader_05_Patterns": hall = child
	check(hall != null, "Actual Patterns museum hall loads")
	if hall == null: quit(1); return
	var graphs: Node3D
	for node in hall.find_children("*", "Node3D", true, false):
		if node.scene_file_path.ends_with("/shader_pattern_passage.tscn"): stage = node
		if node.scene_file_path.ends_with("/shader_05_patterns.tscn"): graphs = node
	check(stage != null, "Pattern passage resolved through registry and authored map")
	if stage == null: quit(1); return
	origin = stage.global_position - hall.global_basis * Vector3(27.5,0,7.5)
	camera = Camera3D.new(); root.add_child(camera)
	var inventory: Array = []
	for rec in museum.get("_edit_records"):
		var node = rec.get("node")
		if is_instance_valid(node) and hall.is_ancestor_of(node): inventory.append(str(rec.get("token", "")))
	for token in ["shader_05_patterns", "dark_sphere", "film_shader_repeat", "camera_glitch_study", "reference_pattern_garden", "fuzzy_body", "model_disagreement", "fuzzy_doorway"]:
		check(inventory.any(func(t): return t.begins_with(token)), "Existing artifact retained: " + token)
	check(stage.chair.scene_file_path.ends_with("chair_modern.tscn"), "Chair is the existing project prefab")
	check(museum.call("_peek_next_authored_map") == "Shader_11_QueerRubber", "Onward sequence remains Queer Materials")
	check(stage.square.mesh is QuadMesh, "Teaching receiver has a complete square UV domain")
	var cube_mesh: Mesh = stage.get_node("CarriedCube").mesh; var initial_chair: Vector3 = stage.chair.position
	stage.sliders.DENSITY._track.move_slider(stage.sliders.DENSITY.TRAVEL); await tick()
	check(is_equal_approx(stage.density, 2.0), "Density slider reaches two repeats per metre")
	stage.sliders.SHIFT._track.move_slider(stage.sliders.SHIFT.TRAVEL * .5); await tick()
	check(is_equal_approx(stage.phase, .5), "Shift slider reaches half a tile")
	check(stage.chair.position.is_equal_approx(initial_chair), "Moving the pattern retains the chair placement")
	check(stage.get_node("CarriedCube").mesh == cube_mesh, "Changing repetition retains the cube mesh")
	stage.sliders.CHAIR._track.move_slider(stage.sliders.CHAIR.TRAVEL); await tick()
	check(is_equal_approx(stage.chair.position.x - initial_chair.x, 2.0), "Chair control moves the existing prefab two metres")
	stage.buttons.ATTACH.get_node("InteractableAreaButton").button_pressed.emit(null)
	check(stage.attached and stage.chair_material.get_shader_parameter("attached"), "ATTACH button selects the chair reference frame")
	var inverse: Transform3D = stage.chair_material.get_shader_parameter("receiver_inverse")
	check(inverse.basis.get_scale().is_equal_approx(Vector3.ONE), "Attached projection retains metre units on the enlarged chair")
	check(not stage.room_material.get_shader_parameter("attached"), "The room stays room-anchored while the chair changes mode")
	stage.buttons.RESET.get_node("InteractableAreaButton").button_pressed.emit(null)
	check(is_equal_approx(stage.density,1) and is_zero_approx(stage.phase) and not stage.attached and stage.chair.position.is_equal_approx(initial_chair), "RESET restores the whole comparison")
	await shader_pixels()
	if graphs:
		for mode in range(3):
			check(graphs.wall_setting and graphs._displays.all(func(d): return d.mesh is QuadMesh), "Supporting mode %d uses full square receivers" % mode)
			check(graphs._panels.all(func(p): return p.position.y >= 1.0), "Supporting mode %d has standing-height controls" % mode)
			graphs._on_mode_pressed(); await tick()
	await physics_frame
	for p in [Vector3(10.5,0,1.25),Vector3(14,0,1.25),Vector3(19,0,1.25),Vector3(27.5,0,1.25),Vector3(27.5,0,4),Vector3(27.5,0,8),Vector3(27.5,0,13),Vector3(24.4,0,3.0),Vector3(10.5,0,8.5)]:
		var at: Vector3 = origin + hall.global_basis * p
		var query := PhysicsRayQueryParameters3D.create(at + Vector3.UP*.3, at - Vector3.UP*.7, 1)
		check(not hall.get_world_3d().direct_space_state.intersect_ray(query).is_empty(), "Floor supports approach " + str(p))
		var capsule := CapsuleShape3D.new(); capsule.radius = .24; capsule.height = 1.6
		var q := PhysicsShapeQueryParameters3D.new(); q.shape = capsule; q.transform.origin = at + Vector3.UP*.86; q.collision_mask = 1
		var hits := hall.get_world_3d().direct_space_state.intersect_shape(q)
		check(hits.is_empty(), "Standing route clear " + str(p))
		for hit in hits: print("BLOCKER ", hit.collider.get_path())
	# Step out of the existing entrance landing before turning into the new bay.
	var route: Array[Vector3] = [Vector3(10.5,0,1.25), Vector3(10.5,0,1.85), Vector3(19,0,1.85), Vector3(19,0,1.25), Vector3(27.5,0,1.25), Vector3(27.5,0,13.5), Vector3(34.6,0,13.5), Vector3(34.6,0,1.25), Vector3(27.5,0,1.25)]
	var route_ok := true
	for i in range(1,route.size()):
		var steps := ceili(route[i-1].distance_to(route[i]) / .25)
		for j in range(steps+1):
			var at: Vector3 = origin + hall.global_basis * route[i-1].lerp(route[i],float(j)/steps)
			var ray := PhysicsRayQueryParameters3D.create(at+Vector3.UP*.3,at-Vector3.UP*.7,1)
			var capsule := CapsuleShape3D.new(); capsule.radius=.24; capsule.height=1.6
			var q := PhysicsShapeQueryParameters3D.new(); q.shape=capsule; q.collision_mask=1; q.transform.origin=at+Vector3.UP*.86
			var hits := hall.get_world_3d().direct_space_state.intersect_shape(q)
			var clear := hits.is_empty() and not hall.get_world_3d().direct_space_state.intersect_ray(ray).is_empty()
			if not clear: print("ROUTE BLOCK ",at-origin)
			for hit in hits: print("ROUTE COLLIDER ",hit.collider.get_path())
			route_ok = route_ok and clear
	check(route_ok,"Entrance, passage and return loop supported and clear at quarter-metre intervals")
	await photo("passage", Vector3(0,1.7,6.1), Vector3(0,1.8,-2), 86)
	await photo("across", Vector3(-1.1,1.7,5.5), Vector3(3,1.5,-1), 80)
	await photo("console", Vector3(2.2,1.65,5.5), Vector3(3.2,1.2,3.6), 64)
	await photo("chair-room", Vector3(1.0,1.6,1.3), Vector3(3.3,.9,-1.65), 62)
	stage.set_control("CHAIR",.35)
	await photo("chair-room-moved", Vector3(1.0,1.6,1.3), Vector3(3.3,.9,-1.65), 62)
	stage.act("RESET"); stage.act("ATTACH"); stage.set_control("CHAIR",.35)
	await photo("chair-attached", Vector3(1.0,1.6,1.3), Vector3(3.3,.9,-1.65), 62)
	stage.act("RESET")
	await photo("overview", Vector3(0,3.5,6.3), Vector3(0,1.4,-1), 92)
	var passed: bool = checks.all(func(c): return c.passed)
	var f := FileAccess.open(output + "report.json", FileAccess.WRITE); f.store_string(JSON.stringify({"passed":passed,"checks":checks,"scope":"Native museum, control receivers and shader pixel readback. No physical headset or ghost-student reconstruction claim."}, "\t")); f.close()
	quit(0 if passed else 1)
