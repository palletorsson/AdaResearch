extends SceneTree
const Model = preload("res://commons/artifacts/ant_scale_atlas/model.gd")
var checks: Array = []
var failures: Array = []
func _initialize() -> void: run.call_deferred()
func check(title: String, ok: bool) -> void:
	checks.append({"name": title, "passed": ok}); print("ANT SCALE ", "PASS " if ok else "FAIL ", title)
	if not ok: failures.append(title)
func run() -> void:
	var model = Model.new()
	var original = Model.Trail.new(); original._rng = RandomNumberGenerator.new(); original._rng.seed = hash("stigmergy")
	original._init_grid(); original._init_ants()
	for i in range(180):
		model.batch(); original._step_ants(); original._evaporate_and_diffuse()
	check("Trail rule and state match the existing engine after 180 steps", model.trail._pheromone == original._pheromone and model.trail._ant_x == original._ant_x and model.trail._ant_y == original._ant_y)
	var turmite = Model.Turmite.new(); turmite._rng.seed = Model.SEED; turmite._reset_state()
	for i in range(1000): turmite._step_swarm()
	model.select(1)
	for i in range(20): model.batch()
	check("Turmite matches original after warmup and twenty five-step batches", model.steps[1] == 1000 and model.turmite._state == turmite._state and model.turmite._ants == turmite._ants)
	var before: String = model.digest(); model.select(0); model.select(1)
	check("Switching views preserves both histories", before == model.digest())
	model.playing = false; model.advance(30)
	check("Pause leaves the complete state intact", before == model.digest())
	model.playing = true; model.advance(.2)
	check("Time adapter retains the original fifty turmite steps per second", model.steps[1] == 1010)
	model.reset(0); check("Trail reset is explicit and seeded", model.steps[0] == 0 and model.trail._pheromone.count(0.0) == 4096 and model.steps[1] == 1010)
	model.reset(1); check("Turmite reset declares its original 900-step warmup", model.steps[1] == 900)
	original.free(); turmite.free()
	var host := Node3D.new(); root.add_child(host); host.position = Vector3(30,4,-15); host.rotation.y = .7
	var atlas = load("res://commons/artifacts/ant_scale_atlas/ant_scale_atlas.tscn").instantiate(); host.add_child(atlas)
	atlas.set_physics_process(false)
	check("All three displays are present at real metric sizes", atlas.views.size() == 3 and atlas.views[0].span == 8 and atlas.views[1].span == 1.8 and atlas.views[2].span == .45)
	var shared := true
	for view in atlas.views: shared = shared and view.plane.material_override == atlas.field_material
	check("Three displays share one texture and one simulation", shared)
	var tops_up := true
	for b in atlas.buttons: tops_up = tops_up and b.global_basis.y.normalized().dot(Vector3.UP) > .99
	check("Control caps face upward and remain reachable from above", tops_up)
	for mode in [0,1,2]:
		atlas.select(mode)
		for i in range(10): atlas.model.batch()
		atlas.paint(); var kept: String = atlas.model.digest(); atlas.paint()
		check("Drawing mode %d does not alter its data" % mode, kept == atlas.model.digest())
		var aligned := true
		for view in atlas.views:
			for i in range(atlas.model.count()):
				var t: Transform3D = view.ants.multimesh.get_instance_transform(i)
				var p: Vector2 = atlas.model.position_of(i)
				aligned = aligned and Vector2(t.origin.x,t.origin.z).distance_to(p * view.span) < .00001
		check("Mode %d agents occupy the same relative position at every scale" % mode, aligned)
	atlas.select(0)
	var pointer := Node3D.new(); root.add_child(pointer); atlas.point.on_desktop_grab(pointer)
	atlas.point.global_position = atlas.to_global(atlas.HOME + Vector3(1,.4,-.2))
	var carried: Vector3 = atlas.point.global_position
	atlas._physics_process(.01)
	check("The original PointBody pickup retains a moved hand display", atlas.point.held() and atlas.point.global_position.distance_to(carried)<.001)
	var running: bool = atlas.model.playing; atlas.point.action()
	check("Held point trigger pauses the actual model", atlas.model.playing != running)
	var state: String = atlas.model.digest(); atlas._physics_process(1)
	check("Paused hand action freezes all three views", atlas.model.digest() == state)
	atlas.point.action(); atlas._physics_process(.1)
	check("Second trigger resumes from the same history", atlas.model.digest() != state)
	atlas.point.on_desktop_drop(pointer); atlas._physics_process(5.1)
	check("Released display returns to its original dock", atlas.point.position.distance_to(atlas.HOME)<.001)
	atlas.buttons[0].pressed.emit(); check("Trail button selects its existing model", atlas.model.mode == 0)
	atlas.buttons[1].pressed.emit(); check("Turmite button selects its existing model", atlas.model.mode == 1)
	atlas.buttons[3].pressed.emit(); var paused: bool = not atlas.model.playing
	atlas.buttons[4].pressed.emit(); check("Restart button resets only selected state and respects pause", paused and not atlas.model.playing and atlas.model.steps[1] == 900)
	atlas.buttons[2].pressed.emit()
	check("Third model button selects Ant Colony V2", atlas.model.mode == 2)
	var v2 = atlas.model.v2
	check("V2 uses its original scene, ant script, hundred ants and 256-square field", v2.colony.get_script().resource_path.ends_with("ants_v2/AntColonyV2.gd") and v2.ants.size() == 100 and v2.ants[0].get_script().resource_path.ends_with("ants_v2/SimpleAnt.gd") and v2.colony.grid.width == 256)
	check("V2 physics world is isolated from the room and its scale", v2.colony.get_world_3d() != atlas.get_world_3d() and v2.colony.global_transform == Transform3D.IDENTITY)
	var frozen: String = v2.digest()
	await create_timer(.2).timeout
	check("V2 remains frozen while paused", v2.digest() == frozen)
	atlas.toggle_play()
	await create_timer(.3).timeout
	check("V2 original physics moves ants and updates pheromone", v2.ticks > 0 and v2.ants[0].position.length() > .01 and v2.colony.grid.grid_home.count(0.0) < 65536)
	atlas.select(0); frozen = v2.digest()
	await create_timer(.2).timeout
	check("V2 retains its complete state while another model is selected", frozen == v2.digest())
	atlas.select(2); atlas.toggle_play()
	var untouched := var_to_str([atlas.model.trail._pheromone, atlas.model.turmite._state])
	atlas.restart()
	check("V2 restart resets original agents without affecting other models", v2.ticks == 0 and v2.ants[0].position == Vector3.ZERO and untouched == var_to_str([atlas.model.trail._pheromone, atlas.model.turmite._state]) and not v2.running)
	check("V2 displays share its original field texture and all hundred agents", atlas.v2_material.get_shader_parameter("trail_texture") == v2.colony.p_texture and atlas.views.all(func(v): return v.plane.material_override == atlas.v2_material and v.ants.multimesh.visible_instance_count == 100 and v.anchors.visible))
	# Exercise the real Area3D signals and ant state transitions in the private world.
	var subject: SimpleAnt = v2.ants[0]
	atlas.toggle_play()
	subject.set_physics_process(false)
	subject.position = v2.colony.PAIR_A
	for i in range(5): await physics_frame
	check("Original food detector changes foraging ant to returning", subject.current_state == SimpleAnt.State.RETURNING)
	subject.position = Vector3.ZERO
	for i in range(5): await physics_frame
	check("Original home detector completes the return trip", subject.current_state == SimpleAnt.State.FORAGING)
	FileAccess.open("res://ada_run/ant_scale_checks.json",FileAccess.WRITE).store_string(JSON.stringify({"passed": failures.is_empty(), "checks":checks,"failures":failures},"  "))
	host.queue_free(); pointer.queue_free(); await process_frame
	quit(0 if failures.is_empty() else 1)
