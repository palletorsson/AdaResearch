extends SceneTree
var gallery
var checks: Array = []
var images: Array = []

func _initialize() -> void:
	run.call_deferred()
	var watchdog := Timer.new()
	watchdog.wait_time = 50
	watchdog.one_shot = true
	watchdog.autostart = true
	watchdog.timeout.connect(func(): push_error("Hinge study timeout"); quit(2))
	root.add_child(watchdog)

func check(title: String, success: bool) -> void:
	checks.append({"name":title,"passed":success})
	print("PASS " if success else "FAIL ",title)

func frames() -> Array:
	var result := []
	for i in 6:
		result.append(gallery.specimen.find_child("Plate_%d" % i,true,false).global_transform)
	return result

func same_frames(a: Array, b: Array) -> bool:
	for i in a.size():
		if not a[i].is_equal_approx(b[i]):
			return false
	return true

func shot(name: String) -> String:
	for i in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	var picture := root.get_texture().get_image()
	picture.save_png("res://captures/"+name+".png")
	images.append({"name":name,"angles":gallery.specimen.hinge_angles(),"policy":"return" if gallery.score.return_on_release else "keep","path_samples":gallery.trace_points.size()})
	return picture.get_data().hex_encode().sha256_text()

func click(at: Vector2) -> void:
	var move := InputEventMouseMotion.new()
	move.position = at
	Input.parse_input_event(move)
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = at
		event.pressed = pressed
		Input.parse_input_event(event)
		await process_frame
		await process_frame

func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://captures")
	root.size = Vector2i(1600,1000)
	root.content_scale_size = Vector2i(1600,1000)
	gallery = load("res://gallery.tscn").instantiate()
	root.add_child(gallery)
	for i in 12:
		await process_frame
	gallery.panel.visible = false
	check("six visible plates and five retained hinge angles",gallery.sheets.size()==6 and gallery.specimen.hinge_angles().size()==5)
	check("portable fallback is explicitly without the XR addon",not ResourceLoader.exists(gallery.specimen.HINGE_SCRIPT))
	var original: Array = gallery.specimen.hinge_angles()
	var initial_frames: Array = frames()
	var original_image := await shot("arrival")
	var solver: Array = gallery.specimen._solve(gallery.specimen._root_frame(gallery.specimen.plinth_height),original,6,gallery.specimen.plate_w,gallery.specimen.plate_w*gallery.specimen.DEPTH_RATIO)
	check("production scene graph agrees with its forward kinematics",same_frames(initial_frames,solver))
	gallery.select_joint(0)
	gallery.turn_selected(50)
	var changed: Array = frames()
	check("moving joint one keeps the supported root fixed",changed[0].is_equal_approx(initial_frames[0]))
	check("moving joint one carries its descendant plates",not changed[1].is_equal_approx(initial_frames[1]) and not changed[5].is_equal_approx(initial_frames[5]))
	check("moving joint one leaves the root's other branch fixed",changed[4].is_equal_approx(initial_frames[4]))
	check("all other local joint angles are retained",gallery.specimen.hinge_angles().slice(1)==original.slice(1))
	gallery.score.release()
	for i in 20:
		await process_frame
	check("leave policy preserves released angles over native frames",is_equal_approx(float(gallery.specimen.hinge_angles()[0]),50.0))
	var left_image := await shot("left")
	check("moving a hinge changes actual native pixels",left_image!=original_image)
	gallery.set_policy(true)
	gallery.score.release()
	for i in 5:
		await process_frame
	check("return begins only after release and makes progress",float(gallery.specimen.hinge_angles()[0])<50.0)
	gallery.set_process(false)
	gallery.score.advance(10)
	check("return reaches the exact chosen starting angles",gallery.specimen.hinge_angles()==original and not gallery.score.returning)
	check("restored angle vector restores all actual plate frames",same_frames(frames(),initial_frames))
	await shot("returned")
	gallery.set_policy(false)
	gallery.set_trace(true)
	gallery.clear_trace()
	# Two paths through joint-angle space. Same final values, different journeys.
	for step in 41:
		gallery.turn_selected(lerpf(float(original[0]),50.0,float(step)/40))
	var first_path_tip: Vector3 = gallery.tip()
	gallery.select_joint(1)
	for step in 41:
		gallery.turn_selected(lerpf(float(original[1]),30.0,float(step)/40))
	var a_frames := frames()
	var a_path: PackedVector3Array = gallery.trace_points.duplicate()
	gallery.select_joint(0)
	await shot("parent-then-child")
	gallery.reset()
	gallery.select_joint(1)
	for step in 41:
		gallery.turn_selected(lerpf(float(original[1]),30.0,float(step)/40))
	var second_path_tip: Vector3 = gallery.tip()
	gallery.select_joint(0)
	for step in 41:
		gallery.turn_selected(lerpf(float(original[0]),50.0,float(step)/40))
	check("opposite assignment order gives the same final plate transforms",same_frames(frames(),a_frames))
	check("the intermediate corner positions differ",first_path_tip.distance_to(second_path_tip)>0.01)
	check("the retained corner traces differ",gallery.trace_points!=a_path and gallery.trace_points.size()>30)
	await shot("child-then-parent")
	gallery.turn_selected(999)
	check("requests beyond a hinge stop clamp to its authored maximum",is_equal_approx(float(gallery.specimen.hinge_angles()[0]),165.0))
	gallery.turn_selected(-999)
	check("negative requests clamp to the minimum",is_equal_approx(float(gallery.specimen.hinge_angles()[0]),-15.0))
	gallery.reset()
	gallery.set_trace(false)
	check("reset clears the retained trace",gallery.trace_points.size()<=1)
	# Pick an actually visible moving plate through the physics ray, then send
	# real mouse events through the gallery's routing and production pointer API.
	await physics_frame
	var picked := false
	for index in range(1,6):
		var plate: Node3D = gallery.specimen.find_child("Plate_%d"%index,true,false)
		var centre_world := plate.to_global(Vector3(0,0,gallery.specimen.plate_w*gallery.specimen.DEPTH_RATIO*0.5))
		var screen: Vector2 = gallery.camera.unproject_position(centre_world)
		var hit: Dictionary = gallery.mouse_ray(screen)
		if hit.is_empty() or not gallery.specimen.is_ancestor_of(hit.collider) or not str(hit.collider.get_parent().name).begins_with("Plate_"):
			continue
		var down := InputEventMouseButton.new()
		down.button_index = MOUSE_BUTTON_LEFT
		down.position = screen
		down.pressed = true
		Input.parse_input_event(down)
		await process_frame
		await process_frame
		if not gallery.dragging:
			continue
		picked = true
		var selected: int = gallery.selected
		var old_value := float(gallery.specimen.hinge_angles()[selected])
		var mount_node: Node3D = gallery.specimen.get("_mounts")[selected]
		var band: Vector2 = gallery.specimen.get("_limits")[selected]
		var step_degrees := 8.0 if old_value < band.x+9.0 else -8.0
		var moved_world := mount_node.to_global(Basis(Vector3.RIGHT,deg_to_rad(step_degrees))*mount_node.to_local(hit.position))
		var motion := InputEventMouseMotion.new()
		motion.position = gallery.camera.unproject_position(moved_world)
		motion.relative = motion.position-screen
		motion.button_mask = MOUSE_BUTTON_MASK_LEFT
		Input.parse_input_event(motion)
		await process_frame
		await process_frame
		check("real mouse motion drives a ray-picked plate",absf(float(gallery.specimen.hinge_angles()[selected])-old_value)>1.0)
		var up := InputEventMouseButton.new()
		up.button_index = MOUSE_BUTTON_LEFT
		up.position = motion.position
		up.pressed = false
		Input.parse_input_event(up)
		await process_frame
		check("real mouse release ends the plate drag",not gallery.dragging and int(gallery.specimen.get("_drag"))==-1)
		break
	check("at least one moving plate can be picked through the actual scene collider",picked)
	gallery.reset()
	# Exercise the production pointer path in its own mount coordinate frame.
	var hinge: Node3D = gallery.specimen.get("_hinges")[1]
	var mount: Node3D = gallery.specimen.get("_mounts")[1]
	var centre := hinge.to_global(Vector3(0,0,gallery.specimen.plate_w*gallery.specimen.DEPTH_RATIO*0.5))
	gallery.sample(2,centre)
	check("production pointer press identifies the intended child hinge",int(gallery.specimen.get("_drag"))==1)
	var before := float(gallery.specimen.hinge_angles()[1])
	var local := mount.to_local(centre)
	var moved := mount.to_global(Basis(Vector3.RIGHT,deg_to_rad(12))*local)
	gallery.sample(4,moved)
	check("production pointer move rotates one selected hinge",absf(float(gallery.specimen.hinge_angles()[1])-before)>5.0)
	check("positive pointer rotation follows the hand's direction",is_equal_approx(float(gallery.specimen.hinge_angles()[1]),before+12.0))
	gallery.sample(3,moved)
	var released: Array = gallery.specimen.hinge_angles()
	check("production pointer release closes the drag",int(gallery.specimen.get("_drag"))==-1)
	for i in 4:
		await process_frame
	check("production pointer release retains its last pose",released==gallery.specimen.hinge_angles())
	gallery.reset()
	gallery.select_joint(0)
	gallery.panel.visible = true
	await process_frame
	await click(gallery.return_button.get_global_rect().get_center())
	check("real GUI mouse click selects return policy",gallery.score.return_on_release)
	await click(gallery.keep_button.get_global_rect().get_center())
	check("real GUI mouse click selects keep policy",not gallery.score.return_on_release)
	gallery.slider.value = 35.0
	check("GUI slider changes the production hinge angle",is_equal_approx(float(gallery.specimen.hinge_angles()[gallery.selected]),35.0))
	await shot("controls")
	gallery.panel.visible = false
	gallery.reset()
	gallery.yaw = -0.70
	gallery.update_camera()
	await shot("other-side")
	var passed := checks.all(func(c): return c.passed)
	var report = {"engine":Engine.get_version_info(),"checks":checks,"passed":passed,"captures":images,
		"scope":"Production specimen copied byte-for-byte, desktop fallback without XR addon. GPU, joint state, scene transforms, pointer protocol and GUI events. No gravity/contact solver, installed hall, headset or learner trial."}
	var file := FileAccess.open("res://captures/results.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	file.close()
	print("RESULT: ",checks.size()," checks; ","PASS" if passed else "FAIL")
	quit(0 if passed else 1)
