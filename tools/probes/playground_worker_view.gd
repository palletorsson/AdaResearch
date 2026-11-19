extends SceneTree
## Trans_Playground, floor 21 of the main tower as it is today: the playground maker "kit-playground-maker"
## (construction_robot, job playground), from where a visitor arrives and from in front of its console.
## The opera's line here says a worker on six legs carries a deck and another way across is being built.
## What does the floor give for that, and what does the visitor have to do?
##
## Arrives, looks at the worker; stands at the console; presses BUILD / HOLD (the method the button calls),
## presses again while a part is being carried, presses a third time and lets the build finish. Photographs
## each state, times the build, and reads the height of the finished surface along its length.
##
##   godot --path . --xr-mode off --resolution 1280x800 --script res://tools/probes/playground_worker_view.gd -- \
##       --void-start-floor=21 --no-opening --opera-quiet --out=<dir>
##
## <dir>/playground_worker.json, arrival.png, console_idle.png, carrying.png, held.png, deck_in_the_air.png, built.png

var game: Node
var folder := "res://ada_run/playground_worker"
var result := {}
var eye: Camera3D
var work: Node3D


func _initialize() -> void:
	run.call_deferred()


func _save() -> void:
	var file := FileAccess.open(folder.path_join("playground_worker.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "  "))
	file.close()


func _frame(label: String, at: Vector3, aim: Vector3) -> void:
	eye.global_position = at
	eye.look_at(aim, Vector3.UP)
	for i in 10: await process_frame
	await RenderingServer.frame_post_draw
	if label != "": root.get_texture().get_image().save_png(folder.path_join(label + ".png"))


# Along the build's long axis, on three lines: how high is the first surface under a foot, and whose is it?
func _underfoot(space: PhysicsDirectSpaceState3D, floor_y: float) -> Array:
	var rows := []
	for k in range(-10, 15):
		var z := float(k) * 0.5
		var row := {"z": z}
		for x in [-0.8, 0.0, 0.8]:
			var from: Vector3 = work.global_transform * Vector3(x, 1.7, z)
			var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * 3.0))
			row["x%+.1f" % x] = "none" if hit.is_empty() else "%.2f %s" % [hit.position.y - floor_y, str((hit.collider as Node).name)]
		rows.append(row)
	return rows


func _v(p: Vector3) -> Array:
	return [snappedf(p.x, 0.01), snappedf(p.y, 0.01), snappedf(p.z, 0.01)]


func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): folder = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(folder)
	load("res://commons/void/room_source.gd").use_main_tower = true
	game = load("res://commons/void/void.tscn").instantiate()
	root.add_child(game); current_scene = game
	game.body.scripted_input = true; game.body.set_process_unhandled_input(false)
	game.scene_loaded(); game.scene_visible()
	var checks := []
	result = {"floor": int(game.checkpoint), "map": "Trans_Playground", "window": str(root.size), "checks": checks, "passed": false}
	var key := "%d/kit-playground-maker" % int(game.checkpoint)
	for i in 2400:
		await physics_frame
		var mount: Variant = game.building.content.exhibits.get(key)
		if mount is Node and (mount as Node).get_node_or_null("Artifact") != null and i > 240:
			work = (mount as Node).get_node("Artifact")
			break
	if work == null or not work.has_method("toggle_build"):
		checks.append({"check": "the playground maker stands on this floor", "ok": false, "looked_for": key})
		_save(); quit(1); return
	var walker: Node3D = work.get("walker")
	var control: Node3D = work.get("control")
	var readout: Label3D = work.get("readout")
	eye = root.get_camera_3d()
	var arrived := eye.global_position
	var space := work.get_world_3d().direct_space_state
	var to_worker := walker.global_position + Vector3.UP * 0.8
	var blocked := space.intersect_ray(PhysicsRayQueryParameters3D.create(arrived, to_worker))
	result["arrival"] = {"eye": _v(arrived), "worker": _v(walker.global_position), "metres_to_the_worker": snappedf(arrived.distance_to(to_worker), 0.1),
		"metres_to_the_console": snappedf(arrived.distance_to(control.global_position), 0.1),
		"first_thing_on_the_line_of_sight": "nothing" if blocked.is_empty() else str((blocked.collider as Node).get_path()).right(70),
		"that_thing_is_metres_away": -1.0 if blocked.is_empty() else snappedf(arrived.distance_to(blocked.position), 0.1)}
	result["as_placed"] = {"building": bool(work.get("active")), "readout": str(readout.text), "kit": str((work.get("kit_label") as Label3D).text), "seated": int(work.get("placed"))}
	game.body.set_physics_process(false)
	game.body.set_process(false)
	await _frame("", arrived, to_worker)
	await _frame("arrival", arrived, to_worker)
	# in front of the console, at the eye height the game gave on arrival
	var out: Vector3 = (work.global_transform.basis * Vector3(0, 0, 1)).normalized()
	var floor_y: float = work.global_position.y
	var stand := Vector3(control.global_position.x, floor_y + (arrived.y - (game.body as Node3D).global_position.y), control.global_position.z) + out * 1.15
	var site: Vector3 = work.global_transform * Vector3(-0.4, 0.7, 0.6)
	await _frame("console_idle", stand, site)
	result["console"] = {"eye": _v(stand), "eye_above_floor_m": snappedf(stand.y - floor_y, 0.01), "console_centre_above_floor_m": snappedf(control.global_position.y - floor_y, 0.01)}

	# the way as a walker on the raised run meets it, before anything is built
	var along: Vector3 = work.global_transform * Vector3(0.0, 1.06 + 1.6, -4.5)
	result["underfoot_before"] = _underfoot(space, floor_y)
	await _frame("the_way_before", along, work.global_transform * Vector3(0.0, 1.3, 2.0))

	# press BUILD / HOLD
	var started := Time.get_ticks_msec()
	work.call("toggle_build")
	var at_press: Vector3 = walker.position
	var kinds := []
	for job in (work.get("jobs") as Array): kinds.append(str(job.part.kind) if job.has("part") else str(job.get("token", "?")))
	result["first_press"] = {"building": bool(work.get("active")), "readout": str(readout.text), "parts_in_the_plan": kinds.size(), "kinds": kinds}
	for i in 600:
		await process_frame
		if work.get("payload") != null: break
	var first_load_s := float(Time.get_ticks_msec() - started) / 1000.0
	for i in 12: await process_frame
	await _frame("carrying", stand, site)
	result["first_press"]["seconds_to_the_first_part_on_the_bed"] = snappedf(first_load_s, 0.01)
	result["first_press"]["worker_moved_m"] = snappedf(at_press.distance_to(walker.position), 0.01)

	# press again: HOLD
	work.call("toggle_build")
	var held_at: Vector3 = walker.position
	var cargo_at: Vector3 = (work.get("payload") as Node3D).position if work.get("payload") != null else Vector3.ZERO
	for i in 90: await process_frame
	await _frame("held", stand, site)
	result["second_press"] = {"building": bool(work.get("active")), "readout": str(readout.text), "worker_moved_in_90_frames_m": snappedf(held_at.distance_to(walker.position), 0.0001),
		"cargo_moved_in_90_frames_m": snappedf(cargo_at.distance_to((work.get("payload") as Node3D).position), 0.0001) if work.get("payload") != null else -1.0, "holding_a_part": work.get("payload") != null}

	# press a third time and let it finish
	work.call("toggle_build")
	var resumed := Time.get_ticks_msec()
	var deck_shot := false
	var finished_s := -1.0
	for i in 36000:
		await process_frame
		var cargo: Variant = work.get("payload")
		if not deck_shot and cargo != null and int(work.get("phase")) == 3:
			var job: Dictionary = (work.get("jobs") as Array)[int(work.get("placed"))]
			if job.has("part") and str(job.part.kind) in ["quad", "panel"]:
				deck_shot = true
				await _frame("deck_in_the_air", stand, site)
		if bool(work.get("complete")):
			finished_s = float(Time.get_ticks_msec() - resumed) / 1000.0
			break
	for i in 30: await process_frame
	await _frame("built", stand, site)
	result["third_press"] = {"complete": bool(work.get("complete")), "readout": str(readout.text), "seated": int(work.get("placed")), "seconds_from_resuming_to_complete": snappedf(finished_s, 0.1),
		"deck_photographed_in_the_air": deck_shot}

	# the finished surface: heights along the build's long axis, and what lies beside it
	var profile := []
	# what the visitor at the console has in front of the worker: the thing under the picture's left-centre
	var ray_from := eye.project_ray_origin(Vector2(300, 350))
	var in_front := space.intersect_ray(PhysicsRayQueryParameters3D.create(ray_from, ray_from + eye.project_ray_normal(Vector2(300, 350)) * 30.0))
	result["in_front_of_the_console"] = {"thing": "nothing with a collider" if in_front.is_empty() else str((in_front.collider as Node).get_path()).right(90),
		"metres_from_the_eye": -1.0 if in_front.is_empty() else snappedf(ray_from.distance_to(in_front.position), 0.01)}
	var overhead_names := {}
	var surface_names := {}
	for k in range(-8, 13):
		var z := float(k) * 0.5
		# the surface a foot meets (looked for from 1.7 m down) and the first thing above it (from 1.2 m up)
		var from_low: Vector3 = work.global_transform * Vector3(0.0, 1.7, z)
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(from_low, from_low + Vector3.DOWN * 3.0))
		var surface := -9.0 if hit.is_empty() else snappedf(hit.position.y - floor_y, 0.01)
		if not hit.is_empty(): surface_names[str((hit.collider as Node).get_path()).right(70)] = true
		var from_surface: Vector3 = work.global_transform * Vector3(0.0, maxf(surface, 0.0) + 0.15, z)
		var above := space.intersect_ray(PhysicsRayQueryParameters3D.create(from_surface, from_surface + Vector3.UP * 5.0))
		var ceiling := -9.0 if above.is_empty() else snappedf(above.position.y - floor_y, 0.01)
		if not above.is_empty(): overhead_names[str((above.collider as Node).get_path()).right(80)] = true
		profile.append({"z": z, "surface_m": surface, "first_thing_above_m": ceiling, "room_for_a_body_m": -9.0 if above.is_empty() else snappedf(ceiling - surface, 0.01)})
	result["above_the_build"] = overhead_names.keys()
	result["underfoot_along_the_build"] = surface_names.keys()
	result["floor_under_the_worker_origin_m"] = snappedf(work.global_position.y - (game.building as Node3D).global_position.y + 6.0 * float(game.checkpoint), 0.01)
	result["underfoot_after"] = _underfoot(space, floor_y)
	await _frame("the_way_after", along, work.global_transform * Vector3(0.0, 1.3, 2.0))
	# does the visitor's body fit, standing, on what was built? (the game's own capsule, set down along the middle)
	var fit := []
	var body_shape: CapsuleShape3D = null
	for shape: CollisionShape3D in (game.body as Node).find_children("*", "CollisionShape3D", true, false):
		if shape.shape is CapsuleShape3D: body_shape = shape.shape
	if body_shape != null:
		for k in range(-6, 12):
			var z := float(k) * 0.5
			var query := PhysicsShapeQueryParameters3D.new()
			query.shape = body_shape
			query.transform = Transform3D(Basis.IDENTITY, work.global_transform * Vector3(0.0, 1.06 + body_shape.height * 0.5 + 0.03, z))
			query.exclude = [(game.body as CollisionObject3D).get_rid()] if game.body is CollisionObject3D else []
			var touching := []
			for hit in space.intersect_shape(query, 6): touching.append(str((hit.collider as Node).name))
			fit.append({"z": z, "touches": touching})
	result["a_standing_body_on_the_built_surface"] = fit
	var parts: Node3D = work.get("finished")
	var low := Vector3(INF, INF, INF)
	var high := -low
	for mesh: MeshInstance3D in parts.find_children("*", "MeshInstance3D", true, false):
		var box: AABB = mesh.global_transform * mesh.get_aabb()
		var local_min: Vector3 = work.global_transform.affine_inverse() * box.position
		var local_max: Vector3 = work.global_transform.affine_inverse() * box.end
		low = low.min(local_min.min(local_max)); high = high.max(local_min.max(local_max))
	result["built"] = {"height_above_floor_along_its_length_m": profile, "extent_in_the_worker_s_frame_min": _v(low), "max": _v(high)}

	checks.append({"check": "on arrival the worker stands still and builds nothing until a visitor presses", "ok": not bool(result.as_placed.building) and int(result.as_placed.seated) == 0})
	checks.append({"check": "one press starts it: a part is on its bed and it has moved", "ok": bool(result.first_press.building) and float(result.first_press.worker_moved_m) > 0.05})
	checks.append({"check": "a second press holds it: worker and cargo do not move for 90 frames, the part stays on the bed", "ok": not bool(result.second_press.building)
		and float(result.second_press.worker_moved_in_90_frames_m) == 0.0 and bool(result.second_press.holding_a_part)})
	checks.append({"check": "a third press lets it finish", "ok": bool(result.third_press.complete)})
	checks.append({"check": "a deck was carried", "ok": deck_shot})
	result.passed = checks.all(func(c): return c.ok)
	_save()
	quit(0 if result.passed else 1)
