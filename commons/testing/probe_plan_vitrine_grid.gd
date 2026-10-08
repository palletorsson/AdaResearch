extends "res://commons/testing/probe_plan_vitrine_hands.gd"

## Supplied controller motion, real occupancy and production drawing scripts.
## No headset or learner-experience claim. The inherited probe checks the
## unchanged default pair separately.
var assertions: int = 0

func _check(tag: String, ok: bool, detail: String) -> void:
	assertions += 1
	super._check(tag, ok, detail)

func _sample(v: Node3D, controllers: Array, pens: Array, local_tip: Vector3) -> void:
	for i in controllers.size():
		var ctrl: Node3D = controllers[i]
		var pen: Node3D = pens[i]
		ctrl.global_position = v.to_global(local_tip) - ctrl.global_basis * v.nib_offset
		pen.call("_process", 1.0 / 60.0)

func _last_local(v: Node3D, pen: Node) -> Vector3:
	var points: Array = pen.get("_trail_points")
	return v.to_local(points.back()) if not points.is_empty() else Vector3.INF

func _run() -> void:
	for i in 12: await process_frame
	var rig := _mk_rig(root)
	var left: Node3D = rig[1]
	var right: Node3D = rig[2]
	var v: Node3D = (load(VITRINE) as PackedScene).instantiate()
	v.position = Vector3(7.2, 0.0, -3.1)
	v.rotation.y = 0.47
	v.call("apply_grid_config", {"pen_pair":"space_grid"})
	v.set_meta("force_arm", true)
	root.add_child(v)
	var body := _mk_visitor("SpatialVisitor")
	body.position = Vector3(0,0,20)
	root.add_child(body)
	await _step(4)
	body.global_position = v.global_position
	await _step(20)
	var pl: Node3D = left.get_node_or_null("PlanPen_L")
	var pr: Node3D = right.get_node_or_null("PlanPen_R")
	_check("mount", pl != null and pr != null and v.is_armed(), "real area entry mounts the configured pair")
	if pl == null or pr == null: return
	_check("space", not pl.has_method("_set_time_origin") and not pr.has_method("_set_time_origin"), "neither hand uses time as a coordinate")
	_check("floor", v.get_node_or_null("Plan/PlanFloor") != null, "numbered plan retains its actual floor")
	_check("glass", _stray_colliders(v).is_empty(), "glass adds no collision")
	for pen in [pl,pr]:
		pen.set_process(false)
		pen.call("clear_trail")
		_check("nib", not pen.get_node("GrabPoint").has_signal("dropped") and not pen.get_node("GrabPoint") is CollisionObject3D, "mounted nib has no drop publisher or hand collider")
	_sample(v,[left,right],[pl,pr],Vector3(0.21,1.27,0.31))
	_check("cyan", _last_local(v,pl).is_equal_approx(Vector3(0.21,1.27,0.31)), "cyan retains supplied position in a translated/rotated exhibit")
	_check("amber", _last_local(v,pr).is_equal_approx(Vector3(0,1.27,0)), "amber uses local cell centre and retains height")
	var count_l: int = pl.get("_trail_points").size()
	var count_r: int = pr.get("_trail_points").size()
	_sample(v,[left,right],[pl,pr],Vector3(0.42,1.27,0.44))
	_check("same_address", pr.get("_trail_points").size() == count_r and pl.get("_trail_points").size() == count_l + 1, "horizontal motion within one address only extends cyan")
	_sample(v,[left,right],[pl,pr],Vector3(0.62,1.27,0.44))
	_check("cross", _last_local(v,pr).is_equal_approx(Vector3(1,1.27,0)), "crossing the local midpoint selects the next floor column")
	_sample(v,[left,right],[pl,pr],Vector3(0.62,1.63,0.44))
	_check("height", _last_local(v,pr).is_equal_approx(Vector3(1,1.63,0)), "height can vary within the same horizontal address")
	_sample(v,[left,right],[pl,pr],Vector3(-1.62,0.93,-0.64))
	_check("negative", _last_local(v,pr).is_equal_approx(Vector3(-2,0.93,-1)), "negative local addresses round over the numbered floor")
	count_r = pr.get("_trail_points").size()
	for i in 30: pr.call("_process",0.1)
	_check("still", pr.get("_trail_points").size() == count_r, "elapsed time without movement adds no positions")
	# Disable automatic polling while drawing a matched input for the image.
	v.set_process(false)
	for pen in [pl,pr]: pen.call("clear_trail")
	for i in 145:
		var angle := TAU * float(i) / 144.0
		_sample(v,[left,right],[pl,pr],Vector3(cos(angle)*1.65,1.15,sin(angle)*1.65))
	_check("circle", pl.get("_trail_points").size() > pr.get("_trail_points").size() and pr.get("_trail_points").size() > 8, "the same circle produces fine and addressed records")
	if "--capture" in OS.get_cmdline_user_args():
		await _capture(v,pl,pr)
	v.set_process(true)
	body.position = Vector3(0,0,20)
	await _step(20)
	_check("exit", not v.is_armed() and left.get_node_or_null("PlanPen_L") == null and right.get_node_or_null("PlanPen_R") == null, "exit returns both pens")
	_check("linger", pr.get("_trail_points").size() > 0, "record remains during exit linger")
	v.call("_process",6.1)
	_check("clear", pl.get("_trail_points").is_empty() and pr.get("_trail_points").is_empty(), "records clear after linger")
	body.global_position = v.global_position
	await _step(20)
	_check("return", left.get_node_or_null("PlanPen_L") == pl and right.get_node_or_null("PlanPen_R") == pr, "reentry reuses the same pair")
	v.call("apply_grid_config",{"pen_pair":"space_time"})
	await _step(20)
	var legacy: Node = right.get_node_or_null("PlanPen_R")
	_check("reconfigure", legacy != null and legacy.has_method("_set_time_origin"), "changing to the legacy pair replaces mounted pens cleanly")
	v.queue_free()
	await _step(4)
	_check("cleanup", left.get_node_or_null("PlanPen_L") == null and right.get_node_or_null("PlanPen_R") == null, "freeing the exhibit leaves controllers clean")
	body.queue_free()
	rig[0].queue_free()
	await process_frame
	print("[grid-probe] %d assertions, %d failures" % [assertions,_fails.size()])

func _capture(v: Node3D, pl: Node3D, pr: Node3D) -> void:
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.055,0.065,0.09)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.8,0.85,1)
	env.environment.ambient_light_energy = 0.9
	root.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55,25,0)
	root.add_child(sun)
	var camera := Camera3D.new()
	camera.current = true
	root.add_child(camera)
	camera.global_position = v.to_global(Vector3(7,7,8))
	camera.look_at(v.to_global(Vector3(0,0.8,0)))
	camera.fov = 44
	for i in 8: await process_frame
	await RenderingServer.frame_post_draw
	var output := "res://doc/book/iterations/2026-09-21-primitives-finish/grid-spatial-pair.png"
	var err := root.get_texture().get_image().save_png(output)
	_check("capture", err == OK, "actual production vitrine and matched circle records captured")
	camera.queue_free()
	env.queue_free()
	sun.queue_free()
