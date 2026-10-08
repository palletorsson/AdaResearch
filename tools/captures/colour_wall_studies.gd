extends SceneTree
var viewport: SubViewport
var scene: Node3D
var out: String
var checks: Array = []

func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks.append({"pass":ok,"check":message})
	print("PASS " if ok else "FAIL ",message)
func press(label: String) -> void: scene.buttons[label].pressed.emit()
func settle() -> void:
	for i in 8: await physics_frame
func shot(name: String) -> void:
	await settle()
	await RenderingServer.frame_post_draw
	check(viewport.get_texture().get_image().save_png(out.path_join(name+".png")) == OK,"saved "+name)
func ray(from: Vector3, to: Vector3) -> Dictionary:
	return scene.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from,to,1))
func ids() -> Array:
	var result: Array = []
	for group in scene.work.roots:
		for bar in group.get_children(): result.append(bar.get_instance_id())
	return result
func positions() -> Array:
	var result: Array = []
	for group in scene.work.roots:
		for bar in group.get_children(): result.append(bar.transform)
	return result
func colours() -> Array:
	var result: Array = []
	for mat in scene.work.materials: result.append(mat.albedo_color)
	return result
func run() -> void:
	out = OS.get_cmdline_user_args()[0]
	viewport = SubViewport.new()
	viewport.size = Vector2i(1800,1200)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.msaa_3d = Viewport.MSAA_4X
	root.add_child(viewport)
	scene = load("res://commons/artifacts/colour_wall_studies/study.tscn").instantiate()
	viewport.add_child(scene)
	scene.set_physics_process(false)
	scene.overlay.hide()
	await settle()
	var work: Node3D = scene.work
	var original := ids()
	check(original.size() == 48,"48 persistent bars across three studies")
	var initial_colours := colours()
	await shot("wall-overview")
	press("Intervals")
	press("Tight intervals")
	check(is_equal_approx(work.intervals[1].position.x-work.intervals[0].position.x,0.11),"tight control sets 0.11 m pitch")
	await shot("intervals-tight")
	press("Open intervals")
	check(is_equal_approx(work.intervals[23].position.x-work.intervals[0].position.x,23*0.21),"open control preserves 24 bars and spreads their centres")
	check(is_zero_approx(work.intervals[0].position.x+work.intervals[23].position.x),"spacing changes keep the collection centred")
	check(initial_colours == colours(),"spacing leaves colours fixed")
	await shot("intervals-open")
	press("Crossings")
	press("Shallow crossing")
	var before: Vector3 = work.uprights[0].position
	await shot("crossings-shallow")
	press("Deep crossing")
	check(is_equal_approx(work.uprights[0].position.z,0.52),"deep control moves vertical members forward")
	check(is_equal_approx(before.x,work.uprights[0].position.x) and is_equal_approx(before.y,work.uprights[0].position.y),"depth change retains the frontal XY arrangement")
	check(initial_colours == colours(),"depth leaves colour fixed")
	await shot("crossings-deep")
	press("Oblique")
	await shot("crossings-oblique")
	press("Open line")
	await shot("line-complete")
	var rail: Node3D = work.rails[5]
	var hit := ray(Vector3(5.575,3.55,0),Vector3(5.575,3.55,-4.0))
	check(hit.get("collider") == rail.get_node("Solid"),"selected top rail has physical depth")
	press("Omit one rail")
	await settle()
	check(not rail.visible and ray(Vector3(5.575,3.55,0),Vector3(5.575,3.55,-4.0)).is_empty(),"omission removes both visible rail and its collision")
	check(ids() == original,"omission retains the array identity for restoration")
	await shot("line-omitted")
	press("Restore rail")
	await settle()
	check(rail.visible and ray(Vector3(5.575,3.55,0),Vector3(5.575,3.55,-4.0)).get("collider") == rail.get_node("Solid"),"restore brings back the same rail and collider")
	press("Whole wall")
	await shot("wall-sequence")
	var fixed_positions := positions()
	press("All pink")
	check(positions() == fixed_positions,"all-pink comparison keeps every transform")
	var one_colour := true
	for colour in colours(): one_colour = one_colour and colour == work.PALETTE[0]
	check(one_colour,"all materials receive the same pink")
	press("Whole wall")
	await shot("wall-pink")
	press("Groups")
	check(positions() == fixed_positions,"group assignment keeps every transform")
	await shot("wall-groups")
	press("Walk")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	check(scene.walking and scene.eye.current,"Walk selects the visitor camera")
	scene.walker.position = Vector3(0,0,-3)
	press("Shallow crossing")
	check(is_equal_approx(work.projection,0.52) and scene.status.text.contains("back"),"structure change is refused beside the wall")
	press("Reset")
	check(not scene.walking and work.colour_rule == 0 and not work.omitted and is_equal_approx(work.spacing,0.16) and is_equal_approx(work.projection,0.18),"reset restores geometry, colour, rail and overview")
	check(ids() == original,"all study identities persist through controls and reset")
	scene.overlay.show()
	await shot("controls")
	var file := FileAccess.open(out.path_join("verification.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"scope":"Native companion; real button signals, stable identities, material/geometry independence, collision rays, view/guard/reset. No headset or physical-keyboard test."},"\t"))
	file.close()
	var failures := 0
	for c in checks:
		if not c["pass"]: failures += 1
	quit(0 if failures == 0 else 1)
