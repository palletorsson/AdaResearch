extends SceneTree
var viewport: SubViewport
var scene: Node3D
var out: String
var checks: Array = []

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks.append({"pass":ok,"check":message})
	print("PASS " if ok else "FAIL ", message)

func settle() -> void:
	for i in 12: await physics_frame

func ray(from: Vector3, to: Vector3) -> Dictionary:
	return scene.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from,to,1))

func shot(name: String) -> void:
	for i in 8: await process_frame
	await RenderingServer.frame_post_draw
	check(viewport.get_texture().get_image().save_png(out.path_join(name+".png")) == OK, "saved "+name)

func colours() -> Array:
	var result: Array = []
	for material in scene.work.materials: result.append(material.albedo_color)
	return result

func transforms() -> Array:
	var result: Array = []
	for panel in scene.work.panels: result.append(panel.transform)
	return result

func identities() -> Array:
	var result: Array = []
	for panel in scene.work.panels: result.append(panel.get_instance_id())
	return result

func walk_forward() -> float:
	scene.walker.position = Vector3(0,0.04,7.3)
	scene.walker.velocity = Vector3.ZERO
	await settle()
	for i in 230:
		await physics_frame
		scene.walker.velocity = Vector3(0,-0.5,-2.8)
		scene.walker.move_and_slide()
	return scene.walker.position.z

func run() -> void:
	out = OS.get_cmdline_user_args()[0]
	viewport = SubViewport.new()
	viewport.size = Vector2i(1800,1200)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.msaa_3d = Viewport.MSAA_4X
	root.add_child(viewport)
	scene = load("res://commons/artifacts/colour_assembly/study.tscn").instantiate()
	viewport.add_child(scene)
	scene.set_physics_process(false)
	scene.overlay.hide()
	await settle()
	var work: Node3D = scene.work
	var original_ids := identities()
	check(original_ids.size() == 12, "twelve persistent panels")
	var names := ["canopy","screens","gathering"]
	var rules := ["alternating","bands","one-colour"]
	for arrangement in 3:
		var before_colours := colours()
		scene.buttons[work.ARRANGEMENTS[arrangement]].pressed.emit()
		check(work.arrangement == arrangement and before_colours == colours(), "arrangement button %d preserves colours" % arrangement)
		var before_transforms := transforms()
		for rule in 3:
			scene.buttons[work.COLOUR_RULES[rule]].pressed.emit()
			check(work.colour_rule == rule and before_transforms == transforms(), "colour button %d preserves arrangement %d" % [rule,arrangement])
			check(identities() == original_ids, "panel identities preserved in state %d/%d" % [arrangement,rule])
			await shot(names[arrangement]+"-"+rules[rule])
		work.set_colour_rule(0)
		scene.set_view(1)
		await shot(names[arrangement]+"-eye")
		scene.set_view(0)
	check(work.materials[0].albedo_color.a < 1.0, "pane is visibly transparent")
	work.set_arrangement(0)
	await settle()
	check(ray(Vector3(0,1.5,7.3),Vector3(0,1.5,-3)).is_empty(), "canopy leaves central body-height path open")
	check(not ray(Vector3(1.25,1.7,0),Vector3(1.25,4,0)).is_empty(), "canopy is solid overhead")
	var canopy_z := await walk_forward()
	check(canopy_z < -2.0 and scene.walker.position.y > -0.1, "standing capsule walks under canopy and stays on floor")
	work.set_arrangement(1)
	await settle()
	check(not ray(Vector3(0,1.5,7.3),Vector3(0,1.5,-3)).is_empty(), "screens block the former straight path")
	var screens_z := await walk_forward()
	check(screens_z > 2.0, "transparent screen stops the standing capsule")
	work.set_arrangement(2)
	await settle()
	var gathering_z := await walk_forward()
	check(gathering_z < -2.0 and scene.walker.position.y > -0.1, "standing capsule enters the open gathering centre")
	scene.buttons["Walk"].pressed.emit()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	check(scene.walking and scene.eye.current, "Walk button activates the visitor camera")
	scene.walker.position = Vector3(0,0,0)
	scene.buttons["Screens"].pressed.emit()
	check(work.arrangement == 2 and scene.status.text.contains("edge"), "layout change is refused while visitor occupies the panel area")
	scene.walker.position = Vector3(0,0,7.3)
	scene.buttons["Screens"].pressed.emit()
	check(work.arrangement == 1, "layout change works after returning to the edge")
	scene.buttons["One colour"].pressed.emit()
	scene.buttons["Reset"].pressed.emit()
	check(work.arrangement == 0 and work.colour_rule == 0 and not scene.walking, "Reset restores canopy, alternating colour and overview")
	scene.overlay.show()
	await shot("controls")
	var report := FileAccess.open(out.path_join("verification.json"),FileAccess.WRITE)
	report.store_string(JSON.stringify({"checks":checks,
		"walk_final_z":{"canopy":canopy_z,"screens":screens_z,"gathering":gathering_z},
		"scope":"Native desktop gallery. Button signals, state invariants, collision rays and scripted CharacterBody3D traversal. No physical-keyboard, tracked-hand or headset test."},"\t"))
	report.close()
	var failures := 0
	for c in checks:
		if not c["pass"]: failures += 1
	quit(0 if failures == 0 else 1)
