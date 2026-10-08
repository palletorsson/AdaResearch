extends SceneTree
## Measured operating poses in the actual halls. No headset comfort claim.
var report := {"checks": [], "failures": [], "controls": [], "shots": []}
var museum: Node3D
var artifact: Node3D
var camera: Camera3D
var walker: CharacterBody3D
var folder: String
var origin: Vector3
var feet: Vector3
class TestGrabber extends Node3D:
	var picked_up_ranged := false
	var held: Node3D
	func drop_object() -> void:
		held.let_go(self, Vector3.ZERO, Vector3.ZERO)
		held = null

func _initialize() -> void: run.call_deferred()
func arr(v: Vector3) -> Array: return [v.x, v.y, v.z]
func check(ok: bool, message: String) -> void:
	report.checks.append({"passed": ok, "message": message})
	if not ok: report.failures.append(message)
	print("HALL_UI ", "PASS " if ok else "FAIL ", message)

func run() -> void:
	var spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OS.get_cmdline_user_args()[0]))
	folder = spec.run
	report.room = spec.room
	report.scope = "Actual museum geometry. Static standing capsule, short approach, control rays and world dimensions; desktop capture, no headset or learner validation."
	museum = load(folder + "museum_snapshot.tscn").instantiate()
	museum.set("EM_CONTROL", folder + "control.json")
	museum.set("_hand_path", folder + "necklace_hand.json")
	museum.set("_overrides_path", folder + "em_overrides.json")
	museum.set("start_chapter", spec.sequence)
	museum.set("start_map", spec.room)
	museum.set("plan_file", folder + "em_plan.json")
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
	origin = hall.global_position + Vector3(0, 0, 4)
	for entry in museum.get("_edit_records"):
		if entry.get("seg") == hall and entry.get("token") == spec.token:
			artifact = entry.node; break
	check(is_instance_valid(artifact), "Live hall contains the actual console artifact")
	if not is_instance_valid(artifact): finish(); return
	artifact.set_process(false)
	# Keep the original player collision out of the measurement; the hall stays intact.
	walker = museum.get("_player")
	if walker: walker.set_physics_process(false)
	var console: Node3D = artifact.get("_controls")
	check(console != null, "Physical console exists after museum loading")
	if console == null: finish(); return
	var front := artifact.global_basis.z.normalized()
	front.y = 0
	front = front.normalized()
	# Half a metre from the station centre leaves room for the case and body.
	feet = console.global_position + front * .50
	var floor_hit := floor_at(feet)
	check(not floor_hit.is_empty(), "Operating position has supporting floor")
	if floor_hit.is_empty(): finish(); return
	feet.y = floor_hit.position.y
	report.artifact = {"position": arr(artifact.global_position-origin), "scale": arr(artifact.global_basis.get_scale()), "rotation": arr(artifact.global_rotation_degrees)}
	report.console = {"position": arr(console.global_position-origin), "scale": arr(console.global_basis.get_scale()), "height_above_floor": console.global_position.y-feet.y}
	report.feet = arr(feet-origin)
	report.floor_collider = str(floor_hit.collider.get_path())
	check(artifact.global_basis.get_scale().is_equal_approx(Vector3.ONE), "Artifact retains metre scale")
	var capsule := CapsuleShape3D.new()
	capsule.radius = .22
	capsule.height = 1.7
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	query.collision_mask = 1
	query.transform.origin = feet + Vector3.UP * .87
	if walker: query.exclude = [walker.get_rid()]
	var obstacles := museum.get_world_3d().direct_space_state.intersect_shape(query)
	report.standing_obstacles = obstacles.map(func(hit): return str(hit.collider.get_path()))
	check(obstacles.is_empty(), "Standing capsule fits in front of console")
	# A terrace may require a side approach. Test it explicitly instead of
	# declaring an inaccessible straight line to be the only valid route.
	report.approaches = []
	var approach := Vector3.ZERO
	for direction in [front, front.rotated(Vector3.UP, PI/2), front.rotated(Vector3.UP, -PI/2)]:
		query.transform.origin = feet + direction + Vector3.UP * .87
		query.motion = -direction
		var motion := museum.get_world_3d().direct_space_state.cast_motion(query)
		var support := true
		for i in 6:
			var hit := floor_at(feet + direction * float(i) / 5)
			support = support and not hit.is_empty() and absf(hit.get("position", Vector3(0,-999,0)).y-feet.y)<.05
		var clear_start := museum.get_world_3d().direct_space_state.intersect_shape(query).is_empty()
		var valid: bool = motion[0] > .99 and support and clear_start
		report.approaches.append({"direction":arr(direction), "clear_fraction":motion[0], "level_support":support, "clear_start":clear_start, "passed":valid})
		if valid and approach.is_zero_approx(): approach = direction
	check(not approach.is_zero_approx(), "A supported, unobstructed final metre reaches the operating pose")
	# Discover the shared components, not artifact-specific control names.
	for node in console.find_children("*", "Node3D", true, false):
		if node.get_script() == load("res://commons/interactables/physical_stepped_slider.gd"):
			for value in [0.0, 1.0]:
				inspect_target(node, node.to_global(Vector3(0, lerpf(-.09,.09,value), 0)), str(node.param_name)+" endpoint "+str(value), node)
		elif node.get_script() == load("res://commons/interactables/push_button.gd"):
			var shape: CollisionShape3D = node.get_node("InteractableAreaButton/CollisionShape3D")
			if shape: inspect_target(node, shape.global_position, str(node.name), node)
	check(not report.controls.is_empty(), "Live controls were measured")
	# Readable plaques are also part of the interface. Catch buried text.
	report.plaques = []
	for panel in artifact.find_children("Provenance_*", "Node3D", true, false):
		var box: AABB = museum.call("_seat_extent", panel)
		report.plaques.append({"node":str(panel.name), "bottom":box.position.y-feet.y, "top":box.end.y-feet.y})
		check(box.position.y >= feet.y+.05, str(panel.name)+" lettering and casing stand above the floor")
		var plaque_query := PhysicsShapeQueryParameters3D.new()
		plaque_query.shape = BoxShape3D.new()
		plaque_query.shape.size = Vector3(.95,.47,.035)
		plaque_query.transform = panel.global_transform
		plaque_query.collision_mask = 1
		if walker: plaque_query.exclude = [walker.get_rid()]
		check(museum.get_world_3d().direct_space_state.intersect_shape(plaque_query).is_empty(), str(panel.name)+" casing clears the hall structure")
	if walker and not approach.is_zero_approx():
		walker.global_position = feet + approach
		walker.velocity = Vector3.ZERO
		for frame in 100:
			var delta := feet-walker.global_position
			delta.y = 0
			var direction := delta.normalized() if delta.length()>.03 else Vector3.ZERO
			walker.velocity = Vector3(direction.x*1.5, 0.0 if walker.is_on_floor() else walker.velocity.y-11.0/60, direction.z*1.5)
			walker.move_and_slide()
			await physics_frame
		report.walk_end = arr(walker.global_position-origin)
		check(walker.global_position.distance_to(feet)<.12, "Museum CharacterBody reaches the operating pose along the measured approach")
	# Use the real grab driver under the hall's authored rotation and placement.
	for node in console.find_children("*", "Node3D", true, false):
		if node.get_script() != load("res://commons/interactables/physical_stepped_slider.gd"): continue
		if not node.input_enabled: continue
		var original: float = node.get_normalized_value()
		# Depth six is an expensive million-segment comparison; input can be
		# proven at generation two without using the audit to stress the GPU.
		var target_value := .2 if spec.case == "grammar" else 1.0
		var grabber := TestGrabber.new()
		root.add_child(grabber)
		grabber.global_transform = node._handle.global_transform
		grabber.held = node._handle
		node._handle.pick_up(grabber)
		grabber.global_position = node._track.get_parent().to_global(Vector3(.18*target_value,0,0))
		for i in 5: await process_frame; await physics_frame
		check(is_equal_approx(node.get_normalized_value(),target_value), str(node.param_name)+" real grab reaches chosen value in the rotated hall")
		grabber.global_position = node._track.get_parent().to_global(Vector3(.18*original,0,0))
		for i in 5: await process_frame; await physics_frame
		grabber.drop_object()
		check(is_equal_approx(node.get_normalized_value(),original), str(node.param_name)+" release retains restored value in the hall")
		grabber.queue_free()
	camera = Camera3D.new()
	root.add_child(camera)
	camera.current = true
	if walker: walker.global_position = feet
	museum.call("_cull_artifacts")
	# Culling can unpause the specimen; freeze state for repeatable images.
	artifact.set_process(false)
	camera.global_position = feet + Vector3.UP*1.65
	camera.fov = 98
	camera.look_at(artifact.to_global(Vector3(0, 1.1, .1)))
	await capture("operating")
	camera.look_at(console.global_position)
	camera.fov = 55
	await capture("controls")
	camera.global_position = feet + (approach if not approach.is_zero_approx() else front) + Vector3.UP*1.65
	camera.look_at(artifact.to_global(Vector3(0,.8,0)))
	camera.fov = 78
	await capture("approach")
	if not report.plaques.is_empty():
		camera.global_position = feet + Vector3.UP*1.65
		camera.look_at(artifact.to_global(Vector3(0,.38,.7)))
		camera.fov = 48
		await capture("plaques-detail")
	finish()

func floor_at(at: Vector3) -> Dictionary:
	var ray := PhysicsRayQueryParameters3D.create(Vector3(at.x, artifact.global_position.y+.35, at.z), Vector3(at.x, artifact.global_position.y-4, at.z), 1)
	if walker: ray.exclude = [walker.get_rid()]
	return museum.get_world_3d().direct_space_state.intersect_ray(ray)

func inspect_target(node: Node3D, target: Vector3, label: String, host: Node3D) -> void:
	var height := target.y-feet.y
	var distance := Vector2(target.x-feet.x,target.z-feet.z).length()
	var ray := PhysicsRayQueryParameters3D.create(feet + Vector3.UP*1.2, target+(target-(feet+Vector3.UP*1.2)).normalized()*.02, 1 | (1<<20) | (1<<22))
	ray.collide_with_areas = true
	if walker: ray.exclude = [walker.get_rid()]
	var hit := museum.get_world_3d().direct_space_state.intersect_ray(ray)
	var visible: bool = not hit.is_empty() and (hit.collider == host or host.is_ancestor_of(hit.collider))
	report.controls.append({"label": label,"height": height,"horizontal_distance": distance,"position": arr(target-origin),"clear_ray":visible,"hit":str(hit.collider.get_path()) if not hit.is_empty() else "none"})
	check(node.global_basis.get_scale().is_equal_approx(Vector3.ONE), label+" retains unit physics scale")
	check(height >= .65 and height <= 1.25, label+" inside working height band 0.65–1.25 m")
	check(distance <= .70, label+" within 0.70 m horizontal layout budget")
	check(visible, label+" has unobstructed interaction ray from operating pose")

func capture(tag: String) -> void:
	for i in 12: await process_frame
	camera.make_current()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(folder+tag+".png")
	report.shots.append(tag+".png")

func finish() -> void:
	report.passed = report.failures.is_empty()
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("HALL_UI_RESULT ", report.room, " ", report.failures)
	quit(0 if report.passed else 1)
