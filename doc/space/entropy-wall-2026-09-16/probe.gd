extends SceneTree

const OUT := "res://doc/space/entropy-wall-2026-09-16/"
var failures: Array[String] = []
var checks: Array[Dictionary] = []
var details: Dictionary = {}
var em: Node3D
var wall: Node3D
var seg: Node3D


func _initialize() -> void:
	run.call_deferred()


func check(ok: bool, label: String) -> void:
	checks.append({"check": label, "passed": ok})
	print("WALL CHECK: ", label, " = ", ok)
	if not ok: failures.append(label)


func ray(from: Vector3, to: Vector3) -> Dictionary:
	return em.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from, to))


func through_wall(at: Vector3) -> Dictionary:
	return ray(wall.to_global(at + Vector3(0, 0, 3)), wall.to_global(at - Vector3(0, 0, 3)))


func check_floor_and_exit(label: String) -> void:
	# Map rows begin after the local vestibule. These cells are independent of
	# the wall apron, and include both end approaches and the rear bypass.
	for cell in [Vector2(8.5, 4.5), Vector2(8.5, 34.5), Vector2(3.5, 32.5), Vector2(15.5, 30.5)]:
		var from: Vector3 = seg.to_global(Vector3(cell.x, 0.4, cell.y))
		var hit: Dictionary = ray(from, from - Vector3(0, 2, 0))
		check(not hit.is_empty(), label + " floor support at " + str(cell))
	var doorway: Dictionary = ray(seg.to_global(Vector3(8.5, 1.5, 32.5)), seg.to_global(Vector3(8.5, 1.5, 36.5)))
	check(doorway.is_empty(), label + " rear exit remains open at body height")
	if not doorway.is_empty(): details[label + "_exit_hit"] = str(doorway.collider.get_path())


func capture(suffix: String) -> void:
	var camera := Camera3D.new()
	em.add_child(camera)
	camera.fov = 90
	# The existing ruin occupies the middle of this bay. Photograph from the
	# visitor aisle between its footprint and the wall's console, not inside it.
	camera.global_position = wall.to_global(Vector3(-0.1, 2.7, 3.85))
	camera.look_at(wall.to_global(Vector3(0, 2.0, 0)))
	for i in range(8):
		camera.make_current()
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT + suffix + ".png")
	camera.queue_free()


func finish() -> void:
	var file := FileAccess.open(OUT + "probe.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks": checks, "failures": failures, "details": details}, "  "))
	file.close()
	print("WEATHERING WALL FAILURES: ", failures)
	quit(0 if failures.is_empty() else 1)


func run() -> void:
	var control := OUT + "control.json"
	var file := FileAccess.open(control, FileAccess.WRITE)
	file.store_string(JSON.stringify({"first_chapter": "randomness", "dollhouse": 0, "grid_pack": 1}))
	file.close()
	em = load("res://commons/scenes/endless_museum.tscn").instantiate()
	em.set("EM_CONTROL", control)
	em.set("_overrides_path", control + ".unused")
	em.set("_hand_path", control + ".unused-hand")
	em.set("start_chapter", "randomness")
	em.set("start_map", "Random_Entropy")
	root.add_child(em)
	current_scene = em
	await create_timer(1.0).timeout
	em.set_process(false)
	em.set_physics_process(false)
	em.call("flush_stamps")
	for record: Dictionary in em.get("_segments"):
		if record.node.get_meta("em_map", "") == "Random_Entropy":
			seg = record.node
			break
	check(seg != null, "Actual Random_Entropy museum segment exists")
	if seg == null:
		finish()
		return
	wall = seg.find_child("WeatheringWall", true, false)
	check(wall != null, "Declared weathering wall is installed in museum architecture")
	if wall == null:
		finish()
		return
	var player: Node3D = em.get("_player")
	if player != null:
		player.set_process(false)
		player.set_physics_process(false)
		player.global_position = wall.to_global(Vector3(0, 1, 4.5))
	wall.running = false
	wall.restore()
	await process_frame
	await process_frame
	await physics_frame
	await physics_frame
	check(wall.is_visible_in_tree(), "Museum wall remains visible outside artifact culling")
	check(wall.pieces.size() == 144 and wall.stacks.size() == 12, "Wall comprises twelve columns of twelve real stones")
	check((seg.get_meta("em_weathering_cells", {}) as Dictionary).size() == 12, "Six native and six outer-skin cells are replaced")
	details["wall_position"] = str(wall.global_position)
	details["wall_rotation"] = str(wall.global_rotation_degrees)
	var top_positions: Array[Vector3] = []
	for stack in wall.stacks:
		var stone: Dictionary = wall.pieces[stack[-1]]
		top_positions.append(stone.home.origin)
		var hit := through_wall(stone.home.origin)
		check(not hit.is_empty() and hit.collider == stone.body, "Intact top stone blocks its original wall opening: " + str(stack[-1]))
	check_floor_and_exit("intact")
	await capture("wall-intact")
	var console: Node3D = wall.find_child("ReachConsole", true, false)
	check(console != null, "Compact console was installed after the two-frame staging delay")
	if console == null:
		finish()
		return
	var marker: Node3D = console.get_node("StandingPosition")
	var shoulder: Vector3 = marker.global_position + Vector3(0, 1.25, 0)
	var buttons: Array = console.find_children("Btn_*", "Node3D", true, false)
	check(buttons.size() == 3, "Console retains three original VR buttons")
	for button in buttons:
		check(shoulder.distance_to(button.global_position) <= 0.8, "Button reachable from standing mark: " + str(button.name))
		check(button.global_position.y - seg.global_position.y >= 0.8 and button.global_position.y - seg.global_position.y <= 1.5, "Button at hand height: " + str(button.name))
	var step_button: Node = console.find_child("Btn_1", true, false)
	var restore_button: Node = console.find_child("Btn_2", true, false)
	var run_button: Node = console.find_child("Btn_0", true, false)
	step_button.get_node("InteractableAreaButton").emit_signal("button_pressed", step_button)
	await physics_frame
	await physics_frame
	check(wall.history.size() == 1, "VR ONE STONE selects and lands exactly one stone")
	var first_id: int = wall.history[0]
	var first: Dictionary = wall.pieces[first_id]
	var first_gap: Dictionary = through_wall(first.home.origin)
	check(first_gap.is_empty(), "Removed stone opens a physical hole through native wall and outer skin")
	if not first_gap.is_empty(): details["single_gap_hit"] = str(first_gap.collider.get_path())
	check(first.node.position.distance_to(first.home.origin) > 0.5 and first.node.visible, "The actual stone moves into visible rubble instead of being hidden")
	check(first.body.collision_layer == 1, "The fallen stone retains its collider in the apron")
	restore_button.get_node("InteractableAreaButton").emit_signal("button_pressed", restore_button)
	await physics_frame
	await physics_frame
	check(wall.history.is_empty() and not wall.running, "VR RESTORE returns the wall to a paused intact state")
	var restored_hit := through_wall(first.home.origin)
	check(not restored_hit.is_empty() and restored_hit.collider == first.body, "RESTORE replaces the physical wall stone")
	step_button.get_node("InteractableAreaButton").emit_signal("button_pressed", step_button)
	check(wall.history[0] == first_id, "Seeded replay selects the same first stone")
	wall.restore()
	run_button.get_node("InteractableAreaButton").emit_signal("button_pressed", run_button)
	check(wall.running, "VR RUN starts automatic weathering")
	await create_timer(1.8).timeout
	run_button.get_node("InteractableAreaButton").emit_signal("button_pressed", run_button)
	check(not wall.running and wall.history.size() > 0, "VR PAUSE stops an active automatic run")
	wall.restore()
	for i in range(60): wall.weather_one()
	await physics_frame
	await physics_frame
	await capture("wall-partial")
	for i in range(60): wall.weather_one()
	await physics_frame
	await physics_frame
	var history: Array = wall.history.duplicate()
	var retained: int = 0
	for stack in wall.stacks: retained += stack.size()
	check(wall.history.size() == 120 and retained == 24, "Finite weathering moves 120 stones and retains 24 low-course stones")
	wall.weather_one()
	check(wall.history.size() == 120, "Exhausted weathering cannot remove the retained low courses")
	var high_hits: Array = []
	for at in top_positions:
		var hit := through_wall(at)
		if not hit.is_empty(): high_hits.append(str(hit.collider.get_path()))
	check(high_hits.is_empty(), "All twelve high openings clear both original wall planes after weathering")
	details["high_opening_hits_after"] = high_hits
	var low_hits: int = 0
	var finite_stones: int = 0
	for stack in wall.stacks:
		for id in stack:
			var stone: Dictionary = wall.pieces[id]
			# Approach from outdoors: the fallen rubble in front is itself solid,
			# and a visitor-side ray would correctly hit that before the low course.
			var at: Vector3 = stone.home.origin
			var hit := ray(wall.to_global(at - Vector3(0, 0, 2)), wall.to_global(at + Vector3(0, 0, 0.6)))
			if not hit.is_empty() and hit.collider == stone.body: low_hits += 1
	check(low_hits == 24, "All twenty-four retained low-course stones remain physically solid")
	for stone in wall.pieces:
		if stone.node.position.is_finite() and stone.node.rotation.is_finite(): finite_stones += 1
	check(finite_stones == 144, "Every retained and fallen stone has finite geometry")
	check_floor_and_exit("weathered")
	await capture("wall-weathered")
	wall.restore()
	await physics_frame
	await physics_frame
	var restored: int = 0
	for at in top_positions:
		if not through_wall(at).is_empty(): restored += 1
	check(restored == 12, "Full RESTORE closes all twelve high openings")
	check_floor_and_exit("restored")
	await capture("wall-restored")
	for i in range(120): wall.weather_one()
	check(wall.history == history, "Full 120-stone seeded replay preserves the exact selection order")
	details["first_stone"] = first_id
	details["history"] = history
	details["retained"] = retained
	wall.restore()
	finish()
