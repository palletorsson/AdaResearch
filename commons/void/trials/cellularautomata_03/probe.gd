extends "res://tools/probes/void_transfer_probe.gd"
## Batch 26: real source studies, five independent floors. Diagnostic measurements
## distinguish original fit issues from pointer/input and host integration failures.

func debug_cases() -> Dictionary:
	return {"bounds-1":1, "bounds-2":2, "bounds-3":3, "bounds-4":4, "bounds-5":5,
		"life":1, "proximity":2, "exchange":3, "neighbours":4, "difference":5}

func run_debug_case(name: String, tag: String) -> void:
	await frames(40)
	if name.begins_with("bounds"):
		inspect_floor(tag)
		fit_checks(tag)
		report_bounds(tag)
	else:
		await focused_checks(tag)

func report_bounds(tag: String) -> void:
	var y: float = game.building.spec.levels[level]
	for entry in game.building.content.data.floors[level].artifacts:
		var node: Node3D = station(entry.id)
		var boxes: Array = []
		geometry(node, boxes)
		if boxes.is_empty(): print("BOUNDS ", tag, entry.id, " NONE"); continue
		var bound: AABB = boxes[0]
		for box in boxes: bound = bound.merge(box)
		print("BOUNDS ", tag, entry.id, " x ", snappedf(bound.position.x,.01), "..", snappedf(bound.end.x,.01), " y ", snappedf(bound.position.y-y,.01), "..", snappedf(bound.end.y-y,.01), " z ", snappedf(bound.position.z,.01), "..", snappedf(bound.end.z,.01))

func focused_checks(tag: String) -> void:
	check(tag+"standard floor", game.building.spec.width == 42 and game.building.spec.depth == 32 and game.building.spec.storey_height == 6)
	report_bounds(tag)
	fit_checks(tag)
	match level:
		1: await life_checks(tag)
		2: await proximity_checks(tag)
		3: await exchange_checks(tag)
		4: await neighbour_checks(tag)
		5: await difference_checks(tag)
	game.place_player(game.spawn_for(level)); await frames(15)

func geometry(node: Node, boxes: Array) -> void:
	if node is SubViewport: return
	if node is CSGShape3D:
		if node.is_root_shape() and node.is_visible_in_tree(): boxes.append(node.global_transform * node.get_aabb())
	elif node is MeshInstance3D:
		if node.mesh != null and node.mesh.get_surface_count() > 0 and node.is_visible_in_tree() and node.layers != 0: boxes.append(node.global_transform * node.get_aabb())
	elif node is MultiMeshInstance3D:
		if node.multimesh != null and node.multimesh.instance_count > 0 and node.multimesh.visible_instance_count != 0 and node.is_visible_in_tree(): boxes.append(node.global_transform * node.get_aabb())
	elif node is Label3D:
		# A zero-infection display can consist of its original explanatory label.
		if not node.text.is_empty() and node.is_visible_in_tree(): boxes.append(node.global_transform * node.get_aabb())
	for child in node.get_children(): geometry(child, boxes)

func fit_checks(tag: String) -> void:
	var y: float = game.building.spec.levels[level]
	var zones: Array = []
	for shaft in game.building.spec.shafts:
		zones.append(["shaft " + str(shaft.name), AABB(Vector3(shaft.x-2.5,y-.4,-3),Vector3(5,6,6))])
	zones.append(["arrival", AABB(Vector3(-.65,y,11.35),Vector3(1.3,2.2,1.3))])
	var hits: Array = []
	for entry in game.building.content.data.floors[level].artifacts:
		var boxes: Array = []
		geometry(station(entry.id), boxes)
		for box: AABB in boxes:
			if not box.has_volume(): continue
			for zone in zones:
				if box.intersection(zone[1]).has_volume(): hits.append(entry.id + ": " + zone[0])
	print("FIT ",tag," floor ",level," ",hits)
	check(tag+"full drawn parts clear shaft volumes and arrival", hits.is_empty())

func button(owner: Node, index: int) -> Node3D:
	return owner.find_child("Btn_%d" % index, true, false)

func control_press(owner: Node3D, console: Node3D, index: int) -> void:
	var key: Node3D = button(console, index)
	var away: Vector3 = key.global_position - owner.global_position
	away.y = 0
	if away.length() < .1: away = owner.global_basis.z
	var at: Vector3 = key.global_position + away.normalized() * 1.05
	at.y = game.building.spec.levels[level] + .06
	game.place_player(at); await frames(20)
	await press(key)

func trigger_held() -> void:
	for down in [true, false]:
		if xr: right.set_input("trigger_click", down)
		else:
			var event := InputEventMouseButton.new()
			event.button_index = MOUSE_BUTTON_LEFT; event.pressed = down
			Input.parse_input_event(event)
		await frames(8)

func release_point() -> void:
	if xr: right.set_input("grip", 0.0); await frames(10)
	else:
		for down in [true, false]:
			var event := InputEventMouseButton.new()
			event.button_index = MOUSE_BUTTON_RIGHT; event.pressed = down
			Input.parse_input_event(event); await frames(8)

func held_step(tag: String, owner: Node3D, point: Node3D, read_generation: Callable) -> void:
	var at: Vector3 = point.global_position + owner.global_basis.z * 1.05
	at.y = game.building.spec.levels[level] + .06
	game.place_player(at); await frames(20)
	var shape: CollisionShape3D
	for child in point.get_children():
		if child is CollisionShape3D: shape = child; break
	if await input_grab(tag, point, shape, .5, .12):
		var before: int = int(read_generation.call())
		await trigger_held()
		check(tag+"held point trigger advances original simulation", int(read_generation.call()) == before + 1)
		await release_point()
		check(tag+"point releases through native input", not point.is_picked_up())
		await frames(35) # XRTools removes hand collision exceptions after 0.5 s

func life_checks(tag: String) -> void:
	var work: Node3D = artifact("game_of_life_petri")
	var study: Node3D = work.get_node("AddressStudy")
	check(tag+"address study keeps 24x24 original state, walk floor and three receivers (API)", work.grid_size == 24 and study.walk_floor and study.floor_view.multimesh.instance_count == 576 and study.receivers.size() == 3)
	var before: int = work._generation
	await control_press(work, study.console, 0)
	check(tag+"STEP with real pointer advances Life once", work._generation == before + 1)
	var trace_before: bool = study.trace
	await control_press(work, study.console, 7)
	check(tag+"TRACE with real pointer shows births and deaths", study.trace != trace_before)
	await control_press(work, study.console, 2)
	check(tag+"REPLAY with real pointer returns to generation zero", work._generation == 0)
	await held_step(tag+"Life point: ", work, study.get_node("LifeHand").point, func(): return work._generation)
	var model: Node3D = artifact("mold_network")
	var grew: int = model.generation
	await frames(18)
	check(tag+"mold retains 30 cubed and its original rule (API)", model.grid_size == Vector3i(30,30,30) and not str(model.rule_string).is_empty())
	check(tag+"mold simulation advances or reaches source limit", model.generation > grew or model.generation >= model.max_generations)
	var hex: Node3D = artifact("hexagon_ca_vr")
	check(tag+"hexagon study uses original table presentation", hex.has_node("MuseumTable") and is_equal_approx(hex._sim_root.scale.x, .12))
	var growth: Node3D = artifact("ca_growth_network")
	check(tag+"growth network retains source seeds and live geometry (API)", not growth.grid.is_empty() and growth.multi_mesh_instance.multimesh.instance_count > 0)

func proximity_checks(tag: String) -> void:
	var work: Node3D = artifact("decaying_bridge")
	var study: Node3D = work.get_node("ProximityStudy")
	check(tag+"proximity bridge keeps 16x5 cells and original collecting basin", work.length == 16 and work.width == 5 and study.has_node("CollectingBasin"))
	study.source_mode = 1; study.probe_near = true; study.reset()
	var before: float = work.grid[Vector2i(2,6)]
	await control_press(work, study.console, 0)
	check(tag+"STEP with real pointer decays the nominated near cell", study.ticks == 1 and work.grid[Vector2i(2,6)] < before)
	var order: bool = work.synchronous_updates
	await control_press(work, study.console, 6)
	check(tag+"ORDER with real pointer switches snapshot/scan update", work.synchronous_updates != order)
	study.source_mode = 1; study.probe_near = true; study.full_reset()
	for i in range(23): study.step_once()
	await frames(3) # source collision withdrawal is deferred to the physics step
	var site: Vector3 = work.to_global(Vector3(0,0,3.6))
	var hit: Dictionary = ray(site + Vector3.UP*.5, site - Vector3.UP*.9)
	print("PROXIMITY_BASIN ", tag, "health=", work.grid[Vector2i(2,6)], " hit=", hit)
	check(tag+"withdrawn support opens to original shallow basin (API decay; geometry)", not hit.is_empty() and hit.position.y < game.building.spec.levels[level] - .45)
	game.place_player(site + Vector3.UP*.06); await frames(40)
	check(tag+"real player falls into the withdrawn cell's collecting basin", game.body.global_position.y < game.building.spec.levels[level] - .4 and game.body.is_on_floor())
	game.place_player(game.spawn_for(level)); await frames(5)
	study.full_reset()
	var vent: Node3D = artifact("catalyst_vent")
	var box: Node3D = artifact("catalyst_prompter_box")
	check(tag+"catalyst keeps source lease and resolved cellular context (API)", box._crystal != null and vent.bind_sequence == "cellularautomata" and vent.wave_size >= 3 and is_equal_approx(vent.emit_interval_s,2.5))
	var chair: Node3D = artifact("ca_chair_test")
	check(tag+"chair simulation retained and standalone UI hidden", chair.ca_grid != null and not chair.ui.visible and not chair.camera.current)
	check(tag+"chair seed cells are actually drawn after reset", chair.ca_grid.multimesh_instance.multimesh.visible_instance_count != 0 and chair.ca_grid.get_occupied_count() == 4)
	await control_press(chair, chair.get_node("VoidChairControls"), 0)
	check(tag+"chair STEP with real pointer runs original strategy", chair.ca_grid.generation == 1)
	var strategy: int = chair.strategy_type
	await control_press(chair, chair.get_node("VoidChairControls"), 3)
	check(tag+"chair STRATEGY with real pointer switches original algorithm", chair.strategy_type != strategy and chair.ca_grid.generation == 0)
	var tree: Node3D = artifact("cellular_automata_3d_tree")
	check(tag+"tree keeps its original generation geometry", tree.get_child_count() > 3)

func exchange_checks(tag: String) -> void:
	var work: Node3D = artifact("rd_artifact")
	var study: Node3D = work.get_node("ExchangeStudy")
	check(tag+"exchange keeps matched fields and walk-seed study (API)", study.walk_seed and study.has_node("WalkSeed") and study.left.ticks == study.right.ticks)
	var before: int = study.left.ticks
	await control_press(work, study.console, 0)
	check(tag+"STEP with real pointer advances both fields", study.left.ticks == before + 1 and study.right.ticks == study.left.ticks)
	var exchange: bool = study.right.exchange
	await control_press(work, study.console, 4)
	check(tag+"EXCHANGE B with real pointer changes relation and resets both", study.right.exchange != exchange and study.left.ticks == 0 and study.right.ticks == 0)
	await control_press(work, study.console, 5)
	check(tag+"INJECT with real pointer perturbs original fields", study.injections == 1)
	check(tag+"clockmaker is the original ornamental construction (API)", artifact("the_clockmaker_of_rules").rule == 30 and artifact("the_clockmaker_of_rules").get_child_count() > 20)
	var gas: Node3D = artifact("lattice_gas_pump")
	var state: PackedByteArray = gas._state.duplicate()
	await frames(15)
	check(tag+"lattice gas retains 44x22 field and live bookkeeping", gas.cols == 44 and gas.rows == 22 and gas._state.size() == state.size() and gas._state != state)
	var sphere: Node3D = artifact("ca_sphere")
	check(tag+"sphere preserves topology and source mesh", sphere.vertices.size() > 0 and sphere.mesh_instance.mesh != null)

func neighbour_checks(tag: String) -> void:
	var work: Node3D = artifact("ca_rule_explorer")
	var study: Node3D = work.get_node("NeighbourStudy")
	check(tag+"rule-90 comparison keeps 32 addresses and original shared history", work.cells_x == 32 and work.rule == 90 and study.floor_history != null)
	var generation: int = work.generation
	await control_press(work, study.get_node("StudyControls"), 0)
	check(tag+"STEP with real pointer advances the rule-90 history", work.generation == generation + 1)
	var sample: int = work.sample_cell
	await control_press(work, study.get_node("StudyControls"), 3)
	check(tag+"CELL with real pointer selects the next address", work.sample_cell != sample)
	await held_step(tag+"Neighbour point: ", work, study.get_node("HandPoint").point, func(): return work.generation)
	var film: Node3D = artifact("film_ca_triplet")
	check(tag+"film keeps original stage", film.get("stage") != null)
	var pyramid: Node3D = artifact("sierpinski_pyramid")
	check(tag+"pyramid keeps inherited six-call recipe", pyramid.leaf_count > 0 and pyramid.extra_crown)
	check(tag+"original pyramid is seated above its authored 25 cm plinth", pyramid.has_node("OriginalMuseumPlinth") and pyramid.position.y > 1.7)

func difference_checks(tag: String) -> void:
	var work: Node3D = artifact("self_organization_ca")
	var study: Node3D = work.get_node("DifferenceStudy")
	check(tag+"paired difference study keeps both 11 cubed volumes and walking slice", study.volumes.size() == 2 and study.volumes[0].multimesh.instance_count == 1331 and study.slice_walker != null)
	var tick: int = study.model.tick
	await control_press(work, study.console, 0)
	check(tag+"STEP with real pointer advances paired volumes", study.model.tick == tick + 1)
	var integer: bool = study.model.integer_storage
	await control_press(work, study.console, 9)
	check(tag+"STORE with real pointer changes storage and resets", study.model.integer_storage != integer and study.model.tick == 0)
	var slice: int = study.slice_z
	await control_press(work, study.console, 10)
	check(tag+"Z SLICE with real pointer changes spatial receiver", study.slice_z != slice)
	var disease: Node3D = artifact("disease_spread_ca")
	var counts: Dictionary = disease.get_disease_counts()
	check(tag+"SIR retains 64 cubed state with budget configured before ready", disease.museum_budget and disease.budget_next.size() == 64 and int(counts.susceptible) + int(counts.infected) + int(counts.recovered) == 262144)
	print("SIR_DISPLAY ",tag,counts," visible stride samples=",disease.multi_mesh_instance.multimesh.visible_instance_count)
	var fog: Node3D = artifact("volumetric_fog_ca")
	check(tag+"fog keeps authored 12 cubed preview with honest central-slice rendering", fog.grid_size == Vector3i(12,12,12) and fog.slice_preview != null and fog.current_state.size() == 1728)
	var screen: Node3D = artifact("ca_screen")
	check(tag+"CA screen keeps source scale ten", screen.scale.is_equal_approx(Vector3.ONE*10))

func capture_floor() -> void:
	var y: float = game.building.spec.levels[level]
	await photo("f%d-arrival" % level, Vector3(0,y+1.65,12.5), Vector3(0,y+1.2,4))
	await photo("f%d-study" % level, Vector3(6,y+3.2,11), Vector3(0,y+1.1,2))
