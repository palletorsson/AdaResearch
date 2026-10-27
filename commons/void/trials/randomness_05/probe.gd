extends "res://tools/probes/void_transfer_probe.gd"
## Batch 25 (Claude worker B): Random_Space_Geometry (1), Randomness_Examples_of_Randomness
## (2), Random_Pheromone (3), Random_Space (4), Random_Game (5).
## Visit, inspection, shaft descent, residency and retry come from the shared probe.
## Real input uses the shared input_* helpers and press(); API, geometry and measurement
## checks say so in their names. "(needs R#)" names the REQUESTS.md hook a check depends on.

const SEEDED := "f1_seeded_room_5_7"
const ENV := "f1_env_one_5_17"
const SCULPT := "f1_sculpt_one_2_19"
const DARTS := "f2_monte_carlo_dartboard_4_12"
const PHEROMONE := "f3_pheromone_terrain_6_3"
const CLIPBOARD := "f3_clipboard_2_6"
const SPACE := "f4_random_space_6_6"
const MIXER := "f4_noise_mixer_4_3"
const CROSSING := "f5_r_c_9_6"
const ARENA := "f5_random_removal_arena_9_17"
const DOORS := "f5_random_doors_9_29"
const TIMING := "f5_door_timing_trials_9_38"
const FIELD := "f5_cube_projectile_spawner_9_51"
const WAITING := "f5_waiting_profile_9_61"

func debug_cases() -> Dictionary:
	return {"bounds-1": 1, "bounds-2": 2, "bounds-3": 3, "bounds-4": 4, "bounds-5": 5,
		"orphans": 1, "seeded": 1, "seedlight": 1, "envone": 1, "darts": 2, "pheromone": 3, "clipboard": 3,
		"space": 4, "mixer": 4, "crossing": 5, "arena": 5, "doors": 5, "timing": 5, "field": 5,
		"fieldmove": 5, "fieldsleep": 5, "waiting": 5}

func run_debug_case(name: String, tag: String) -> void:
	match name:
		"bounds-1", "bounds-2", "bounds-3", "bounds-4", "bounds-5":
			inspect_floor(tag)
			await frames(30)
			await fit_checks(tag)
			report_bounds(tag)
		"orphans": await orphan_report(tag)
		"seeded": await seeded_checks(tag)
		"seedlight":
			await sculpt_seed_checks(tag)
			await env_seed_checks(tag)
		"envone":
			env_report(tag)
			await env_seed_checks(tag)
		"darts": await darts_checks(tag)
		"pheromone": await pheromone_checks(tag)
		"clipboard": await clipboard_checks(tag)
		"space": await space_checks(tag)
		"mixer": await mixer_checks(tag)
		"crossing": await crossing_checks(tag)
		"arena": await arena_checks(tag)
		"doors": await doors_checks(tag)
		"timing": await timing_checks(tag)
		"field": await frames(30);await field_checks(tag)
		"fieldmove": await frames(30);await field_move_checks(tag)
		"fieldsleep": await frames(30);await field_residency_report(tag)
		"waiting": await frames(90);await waiting_checks(tag)

func focused_checks(tag: String) -> void:
	check(tag+"standard floor "+str(level), game.building.spec.width == 42 and game.building.spec.depth == 32 and game.building.spec.storey_height == 6)
	await fit_checks(tag)
	match level:
		1:
			await seeded_checks(tag)
			await sculpt_seed_checks(tag)
			await env_seed_checks(tag)
		2:
			await darts_checks(tag)
		3:
			await pheromone_checks(tag)
		4:
			await space_checks(tag)
		5:
			await crossing_checks(tag)
			await arena_checks(tag)
			await doors_checks(tag)
			await timing_checks(tag)
			await field_checks(tag)
			await waiting_checks(tag)
	game.place_player(game.spawn_for(level));await frames(15)

# ── helpers ─────────────────────────────────────────────────────────────────

func bounds_of(node: Node3D) -> AABB:
	var boxes: Array = [];geometry(node, boxes)
	if boxes.is_empty(): return AABB()
	var b: AABB = boxes[0]
	for box in boxes: b = b.merge(box)
	return b

## Shrink by up to 1 mm per side without ever producing a negative size.
func shrink_mm(b: AABB) -> AABB:
	var g := Vector3(minf(.001, b.size.x/2.0), minf(.001, b.size.y/2.0), minf(.001, b.size.z/2.0))
	return AABB(b.position+g, b.size-g*2.0)

func report_bounds(tag: String) -> void:
	var y: float = game.building.spec.levels[level]
	for entry in game.building.content.data.floors[level].artifacts:
		var b: AABB = bounds_of(station(entry.id))
		if b.size == Vector3.ZERO:
			print("BOUNDS ", tag, entry.id, " none");continue
		print("BOUNDS ", tag, entry.id, " x %.2f..%.2f y %.2f..%.2f z %.2f..%.2f" % [b.position.x, b.end.x, b.position.y-y, b.end.y-y, b.position.z, b.end.z])

## Stand at an artifact-local point; y is taken from the artifact's frame.
func stand_local(node: Node3D, at: Vector3) -> void:
	game.place_player(node.to_global(at));await frames(20)

## Stand beyond a control, away from its artifact, on this floor.
func stand_near(control: Node3D, owner: Node3D, distance: float = 1.2) -> void:
	var away: Vector3 = control.global_position-owner.global_position
	away.y = 0
	if away.length() < .05: away = owner.global_basis.z
	var at: Vector3 = control.global_position+away.normalized()*distance
	at.y = game.building.spec.levels[level]+.06
	game.place_player(at);await frames(20)

## Drive the body (desktop walker or XR stick) toward a point; stops within 0.3 m.
func walk_to(goal: Vector3, limit: int = 300) -> void:
	for i in limit:
		var at: Vector3 = game.body.global_position
		var offset := Vector2(goal.x-at.x, goal.z-at.z)
		if offset.length() < .3: break
		axes(offset.normalized())
		await frames(1)
	axes(Vector2.ZERO);await frames(10)

## Real pointer press for rack buttons (InteractableAreaButton) and areas whose own
## CollisionShape3D is the target.
func press(button: Node3D) -> void:
	if button.has_node("InteractableAreaButton/CollisionShape3D"):
		await super.press(button);return
	var target: Vector3 = button.get_children().filter(func(n): return n is CollisionShape3D)[0].global_position
	if not xr:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		await input_aim_camera(target, 25)
		for down in [true, false]:
			var e := InputEventMouseButton.new();e.button_index = MOUSE_BUTTON_LEFT;e.pressed = down
			Input.parse_input_event(e);await frames(8)
		return
	for i in 20:
		aim_pointer(target);await frames(1)
	right.set_input("trigger_click", true);await frames(6)
	right.set_input("trigger_click", false);await frames(8)

func aim_pointer(target: Vector3) -> void:
	var origin: Node3D = game.get_node("XROrigin3D")
	var pointer: Node3D = game.pointers[1]
	var at: Vector3 = game.camera.global_position+Vector3(.1, -.2, 0)
	var aim := Basis.looking_at(target-at)
	at -= aim*Vector3(0, pointer.y_offset*XRServer.world_scale, 0)
	right.set_pose("aim", Transform3D(origin.global_basis.inverse()*aim, origin.to_local(at)), Vector3.ZERO, Vector3.ZERO, XRPose.XR_TRACKING_CONFIDENCE_HIGH)

func release_grip() -> void:
	if xr: right.set_input("grip", 0.0);await frames(12)
	else:
		for down in [true, false]:
			var e := InputEventMouseButton.new();e.button_index = MOUSE_BUTTON_RIGHT;e.pressed = down
			Input.parse_input_event(e);await frames(8)

## No visible DirectionalLight3D and no live WorldEnvironment under a node (floor_content's
## import rule, which a seed rebuild undoes without R4).
func host_lights_quiet(node: Node3D) -> bool:
	for sun in node.find_children("*", "DirectionalLight3D", true, false):
		if (sun as DirectionalLight3D).is_visible_in_tree(): return false
	for environment in node.find_children("*", "WorldEnvironment", true, false):
		if (environment as WorldEnvironment).environment != null: return false
	return true

# ── fit ─────────────────────────────────────────────────────────────────────

## Whole shaft openings, the arrival and the floor sign (this trial moves floor 5's sign
## to (8.5, -12.5)). env_one is a world-scale kitbash cloud with no colliders: measured in
## env_report. random_space is 15.4 m wide against 15.0 m between the shafts: offset east,
## its entry into shaft B is measured and capped, shaft A stays strict.
func fit_checks(tag: String) -> void:
	var spec = game.building.spec
	var y: float = spec.levels[level]
	var keep_out: Array = []
	for shaft in spec.shafts:
		keep_out.append(["shaft "+str(shaft.name), AABB(Vector3(float(shaft.x)-float(spec.shaft_width)/2.0, y-.5, -float(spec.shaft_depth)/2.0), Vector3(float(spec.shaft_width), 6.5, float(spec.shaft_depth)))])
	keep_out.append(["arrival", AABB(Vector3(-1, y, 11), Vector3(2, 2.2, 2))])
	var sign_xz: Array = spec.get("floor_sign_positions", {}).get(str(level), [3.5, -7.8])
	keep_out.append(["floor sign", AABB(Vector3(float(sign_xz[0])-1.85, y+.525, float(sign_xz[1])-.06), Vector3(3.7, 1.65, .12))])
	var hits: Array = []
	for entry in game.building.content.data.floors[level].artifacts:
		if entry.id == ENV:
			env_report(tag);continue
		var boxes: Array = [];geometry(station(entry.id), boxes)
		for item in keep_out:
			var zone: AABB = item[1]
			if entry.id == SPACE and str(item[0]) == "shaft B":
				var reach := 0.0
				for b in boxes:
					if shrink_mm(b).intersects(zone): reach = maxf(reach, b.end.x-zone.position.x)
				print("SPACE_SHAFT ", tag, "walk surface reach into shaft B %.3f m" % reach)
				if not xr: fit_notes.append({"id": SPACE, "into_shaft_B_m": reach, "width_m": 15.4, "gap_between_shafts_m": 15.0})
				check(tag+"random_space walk surface enters shaft B by at most 0.47 m, shaft A kept clear (measured; 15.4 m vs 15.0 m gap)", reach <= .47)
				continue
			var inside: Array = boxes.filter(func(b): return shrink_mm(b).intersects(zone))
			if not inside.is_empty():
				hits.append(entry.id+" / "+str(item[0]))
				print("FIT_BOX ", tag, entry.id, " / ", item[0], " ", inside.slice(0, 3))
	print("FIT ", tag, "floor ", level, " ", hits)
	if not xr and not hits.is_empty(): fit_notes.append({"floor": level, "enters": hits})
	check(tag+"placement geometry stays out of shafts, arrival and floor sign"+(" (env_one measured separately)" if level == 1 else ""), hits.is_empty())

## env_one at height 4, scale 0.5: modules +-7.5 m, ambient and atmosphere MultiMeshes
## +-15 m around (-5, 4, -5). Visual only; measured, not shrunk.
func env_report(tag: String) -> void:
	var env: Node3D = station(ENV)
	var y: float = game.building.spec.levels[level]
	var controls: Node3D = env.get_node_or_null("ArtSeedControls")
	var bodies: Array = env.find_children("*", "CollisionObject3D", true, false).filter(func(body): return controls == null or not controls.is_ancestor_of(body))
	check(tag+"env_one kitbash has no colliders outside its seed console, so it cannot block a shaft (geometry)", bodies.is_empty())
	var b: AABB = bounds_of(env)
	var console_y: float = controls.global_position.y-y if controls != null else -1.0
	var note := {"id": ENV, "geometry_x": [b.position.x, b.end.x], "geometry_z": [b.position.z, b.end.z],
		"geometry_y_above_floor": [b.position.y-y, b.end.y-y], "seed_console_base_above_floor": console_y}
	print("ENVONE ", tag, note)
	if not xr: fit_notes.append(note)

# ── floor 1 ─────────────────────────────────────────────────────────────────

func seeded_checks(tag: String) -> void:
	var room: Node3D = station(SEEDED)
	check(tag+"seeded room builds 64 cells from seed 42 (API)", room.blocks.size() == 64 and room.seed_value == 42)
	var next_button: Node3D = room.panel.find_child("Btn_1", true, false)
	await stand_local(room, Vector3(-2.4, .06, -6.9))
	await press(next_button);await frames(10)
	check(tag+"NEXT SEED with real pointer draws seed 43 and keeps the blue passage open", room.seed_value == 43 and room.passage.all(func(i): return room.heights[i] < .05))

## Visible suns anywhere in the game, and the environments the visitor actually sees.
func lighting_state() -> Dictionary:
	var suns: Array = game.find_children("*", "DirectionalLight3D", true, false).filter(func(s): return (s as DirectionalLight3D).is_visible_in_tree())
	return {"suns": suns.size(), "camera_env": game.camera.environment, "world_env": game.get_world_3d().environment}

## The drawn sculpture: positions of every mesh in its composition.
func sculpt_print(sculpt: Node3D) -> Array:
	var comp: Node = sculpt.get_node_or_null("LiquidComposition")
	if comp == null: return []
	return comp.find_children("*", "MeshInstance3D", true, false).map(func(m): return (m as Node3D).position.snapped(Vector3(.001, .001, .001)))

## R4, rebuild path 1: sculpt_one (_rebuild_now -> setup_environment). Real pointer NEXT.
func sculpt_seed_checks(tag: String) -> void:
	var sculpt: Node3D = station(SCULPT)
	var controls: Node3D = sculpt.get_node_or_null("ArtSeedControls")
	check(tag+"sculpture seed console built (API)", controls != null and controls.panel != null)
	if controls == null or controls.panel == null: return
	check(tag+"sculpture runs the trial adapter (needs R4)", sculpt.get_script().resource_path.ends_with("randomness_05/sculpt_one_local.gd"))
	var next_button: Node3D = controls.panel.find_child("Btn_2", true, false)
	await stand_local(controls, Vector3(0, .06, 1.1))
	var before: int = sculpt.sculpt_seed
	var shape_before: Array = sculpt_print(sculpt)
	var light_before: Dictionary = lighting_state()
	await press(next_button);await frames(12)
	var light_after: Dictionary = lighting_state()
	print("SEEDLIGHT ", tag, "sculpt seed ", before, " -> ", sculpt.sculpt_seed, " suns ", light_before.suns, " -> ", light_after.suns)
	check(tag+"NEXT on the sculpture's seed console with real pointer draws seed "+str(before+1)+" and a different sculpture", sculpt.sculpt_seed == before+1 and not sculpt_print(sculpt).is_empty() and str(sculpt_print(sculpt)) != str(shape_before))
	check(tag+"rebuilt sculpture leaves no visible sun or live environment under it (needs R4)", host_lights_quiet(sculpt))
	check(tag+"after the sculpture rebuild the tower has the same visible suns and visitor environment (needs R4)", light_after.suns == light_before.suns and light_after.camera_env == light_before.camera_env and light_after.world_env == light_before.world_env)

## R4, rebuild path 2: env_one (set_generation_seed -> apply_lighting). Its console rides the
## kitbash origin 4 m up; the real pointer press is made from the floor, 2 m in front.
func env_seed_checks(tag: String) -> void:
	var env: Node3D = station(ENV)
	var y: float = game.building.spec.levels[level]
	var controls: Node3D = env.get_node_or_null("ArtSeedControls")
	check(tag+"env_one seed console built (API)", controls != null and controls.panel != null)
	if controls == null or controls.panel == null: return
	check(tag+"env_one runs the trial adapter (needs R4)", env.get_script().resource_path.ends_with("randomness_05/env_one_local.gd"))
	var next_button: Node3D = controls.panel.find_child("Btn_2", true, false)
	var under: Vector3 = controls.to_global(Vector3(0, 0, 2.0));under.y = y+.06
	game.place_player(under);await frames(20)
	var before: int = env.kitbash_seed
	var placed_before: String = str(env._placed_pos)
	var light_before: Dictionary = lighting_state()
	await press(next_button);await frames(15)
	var light_after: Dictionary = lighting_state()
	print("SEEDLIGHT ", tag, "env console base %.2f m above floor, seed %d -> %d, suns %d -> %d" % [controls.global_position.y-y, before, env.kitbash_seed, light_before.suns, light_after.suns])
	check(tag+"NEXT on env_one's console (4 m up) with real pointer from the floor draws seed "+str(before+1)+" and a different kitbash", env.kitbash_seed == before+1 and not env._placed_pos.is_empty() and str(env._placed_pos) != placed_before)
	check(tag+"rebuilt kitbash leaves no visible sun or live environment under it (needs R4)", host_lights_quiet(env))
	check(tag+"after the kitbash rebuild the tower has the same visible suns and visitor environment (needs R4)", light_after.suns == light_before.suns and light_after.camera_env == light_before.camera_env and light_after.world_env == light_before.world_env)

## Diagnostic for the exit leak: list nodes outside the tree, before and after a sculpture
## rebuild. env_one's ten module templates are orphans by design (freed in _exit_tree).
func orphan_report(tag: String) -> void:
	await frames(60)
	print("ORPHANS_BEGIN ", tag)
	Node.print_orphan_nodes()
	print("ORPHANS_END ", tag)
	await sculpt_seed_checks(tag)
	await frames(30)
	print("ORPHANS_AFTER_REBUILD_BEGIN ", tag)
	Node.print_orphan_nodes()
	print("ORPHANS_AFTER_REBUILD_END ", tag)

# ── floor 2 ─────────────────────────────────────────────────────────────────

func darts_checks(tag: String) -> void:
	var board: Node3D = station(DARTS)
	var console: Node3D = board.get("sample_console")
	check(tag+"Monte Carlo keeps the sample-budget lesson with its keys off (API)", board.sample_budget and not board.keyboard_shortcuts and console != null)
	if console == null: return
	var before: int = board.sample_run.points.size()
	await stand_local(console, Vector3(0, .06, 1.0))
	await press(console.buttons["THROW"]);await frames(10)
	check(tag+"THROW with real pointer adds one generated sample", board.sample_run.points.size() == before+1)

# ── floor 3 ─────────────────────────────────────────────────────────────────

func pheromone_checks(tag: String) -> void:
	var terrain: Node3D = station(PHEROMONE)
	for i in 120:
		if terrain._comparison_panel != null: break
		await frames(1)
	check(tag+"pheromone comparison fitted to its 4.8 m display with seed 190919 (API)", terrain.comparison and terrain._comparison_panel != null and terrain.walk_seed == 190919 and is_equal_approx(terrain.get_node("Plane").scale.x, .24))
	if terrain._comparison_panel == null: return
	await stand_local(terrain, Vector3(0, .06, 4.1))
	await press(terrain._comparison_panel.find_child("Btn_3", true, false));await frames(8)
	check(tag+"+20 STEPS with real pointer advances the comparison by 20", terrain._comparison_steps == 20)
	await press(terrain._comparison_panel.find_child("Btn_4", true, false));await frames(8)
	check(tag+"REPLAY with real pointer rewinds to step 0 on the same seed", terrain._comparison_steps == 0 and terrain.walk_seed == 190919)

func clipboard_checks(tag: String) -> void:
	var board: Node3D = station(CLIPBOARD)
	var plane: Node3D = board.get_node_or_null("GrabPlane")
	var shape: CollisionShape3D = plane.get_node_or_null("CollisionShape3D") if plane != null else null
	check(tag+"clipboard keeps its grab plane (geometry)", plane != null and shape != null)
	if plane == null or shape == null: return
	print("CLIPBOARD ", tag, "plane=", plane.global_position, " class=", plane.get_class(), " layer=", plane.get("collision_layer"))
	await stand_local(board, Vector3(0, .06, 1.0))
	if await input_grab(tag+"clipboard: ", plane, shape, .4, .1):
		await frames(20)
		await release_grip()

# ── floor 4 ─────────────────────────────────────────────────────────────────

## Random_Space: a 15.4 x 28 m walk surface (+-0.17 m relief) under the other four.
func space_checks(tag: String) -> void:
	var space: Node3D = station(SPACE)
	var y: float = game.building.spec.levels[level]
	var b: AABB = bounds_of(space)
	print("SPACE ", tag, "x %.2f..%.2f z %.2f..%.2f y %.2f..%.2f" % [b.position.x, b.end.x, b.position.z, b.end.z, b.position.y-y, b.end.y-y])
	var raised := Vector3.ZERO
	var found := false
	for i in 7:
		for j in 6:
			var p := Vector3(-6.0+i, y+1.0, 4.0+j)
			var hit := ray(p, p+Vector3.DOWN*2.0)
			if not hit.is_empty() and space.is_ancestor_of(hit.collider) and hit.position.y > y+.06:
				raised = hit.position;found = true;break
		if found: break
	check(tag+"random_space walk surface carries collision above the slab (geometry)", found)
	if not found: return
	game.place_player(game.spawn_for(level));await frames(20)
	await walk_to(raised, 420)
	var feet: Vector3 = game.body.global_position
	print("SPACE ", tag, "walked to ", feet, " raised point ", raised)
	check(tag+"real walking from the arrival reaches a raised point of the walk surface and stands on it", Vector2(feet.x-raised.x, feet.z-raised.z).length() < .45 and absf(feet.y-raised.y) < .15 and game.body.is_on_floor())

## The museum stands noise_mixer on a 0.9 m plinth; the Void builds none (R6).
func mixer_checks(tag: String) -> void:
	var mixer: Node3D = station(MIXER)
	var y: float = game.building.spec.levels[level]
	var b: AABB = bounds_of(mixer)
	print("MIXER ", tag, "y %.2f..%.2f above floor 4, no plinth under it" % [b.position.y-y, b.end.y-y])
	var button: Node3D = mixer.find_child("Btn_0", true, false)
	await stand_near(button, mixer, 1.0)
	var before: int = mixer.seed_value
	await press(button);await frames(10)
	check(tag+"noise mixer SEED with real pointer draws a new seed", mixer.seed_value != before)

# ── floor 5 ─────────────────────────────────────────────────────────────────

func crossing_checks(tag: String) -> void:
	var cube: Node3D = station(CROSSING)
	var y: float = game.building.spec.levels[level]
	check(tag+"r_c stages its chasm crossing: 3 stones, bed and advance cue (API)", cube.stand == "chasm" and cube._stones.size() == 3 and cube._crossing != null and cube.advance_seconds > 0.0)
	# Beside the stone row (west of it, clear of the WayOut ramp), the floor-5 basin
	# opens the slab and a ray falls to the crossing's own bed, 1.02 m down.
	var side: Vector3 = cube.global_position+Vector3(-1.6, 0, 0)
	side.y = y+1.0
	var hit := ray(side, side+Vector3.DOWN*4.0)
	print("CROSSING ", tag, "beside the row: ", str(hit.collider.get_path()) if not hit.is_empty() else "none", " at ", hit.get("position", Vector3.ZERO))
	check(tag+"pit beside the stones opens onto the crossing's bed 1.02 m down (geometry; floor-5 basin)", not hit.is_empty() and cube.is_ancestor_of(hit.collider) and absf(hit.position.y-(y-1.02)) < .1)
	var cue: Node3D = cube.find_child("Controls", true, false)
	cue = cue.find_child("Btn_2", true, false) if cue != null else null
	check(tag+"crossing controls present (API)", cue != null)
	if cue == null: return
	print("CROSSING ", tag, "console=", cube.find_child("ReachConsole", true, false) != null)
	await stand_near(cue, cube, 1.2)
	var before: float = cube.advance_seconds
	await press(cue);await frames(8)
	check(tag+"CUE with real pointer switches the advance notice off", before > 0.0 and is_zero_approx(cube.advance_seconds))
	await press(cue);await frames(8)

func arena_checks(tag: String) -> void:
	var arena: Node3D = station(ARENA)
	var y: float = game.building.spec.levels[level]
	check(tag+"arena builds the source 9 x 9 = 81 tiles (needs R2: configure before ready)", arena.colliders.size() == 81 and arena.rows == 9 and arena.columns == 9)
	check(tag+"arena stands in its 11 x 11 m glass box with the compact console (needs R1)", arena.find_child("GlassSimulation", true, false) != null and arena.find_child("ReachConsole", true, false) != null)
	print("ARENA ", tag, "tiles=", arena.colliders.size(), " script=", arena.get_script().resource_path)
	var tile: Vector3 = arena.colliders[0].global_position
	var under := ray(tile+Vector3.DOWN*.35, tile+Vector3.DOWN*4.0)
	check(tag+"basin lies 3 m under the arena tiles (geometry)", not under.is_empty() and absf(under.position.y-(y-3.0)) < .15)
	var bank: Vector3 = arena.to_global(Vector3(0, 0, -arena.rows/2.0-.5))
	bank.y = y+.06
	game.place_player(bank);await frames(25)
	var removed_before: int = arena.get_state().removed
	await walk_to(arena.to_global(Vector3(0, 0, -arena.rows/2.0+2.5)), 180)
	for i in 120:
		await frames(1)
		if arena.get_state().removed > removed_before: break
	var state: Dictionary = arena.get_state()
	print("ARENA ", tag, "state=", state)
	check(tag+"walking onto the arena withdraws a tile (needs R2: Void body)", state.removed > removed_before and state.disabled_colliders >= 1)
	game.place_player(bank);await frames(15)
	var replay: Node3D = arena.find_child("Btn_2", true, false)
	await stand_near(replay, arena)
	await press(replay);await frames(30)
	var after: Dictionary = arena.get_state()
	check(tag+"REPLAY with real pointer restores every tile and collider", after.remaining == arena.colliders.size() and after.disabled_colliders == 0)

## Press the drawn passage only: a fire door is harmless here (R5) and is not run.
func doors_checks(tag: String) -> void:
	var doors: Node3D = station(DOORS)
	var safe: int = doors.safe_door
	var button: Node3D = doors.find_child("Btn_"+str(safe), true, false)
	await stand_near(button, doors, 1.2)
	await press(button)
	for i in 150:
		await frames(1)
		if doors.state[safe] == "passage": break
	await frames(3)
	check(tag+"DOOR "+str(safe+1)+" (the drawn passage) with real pointer opens and unlocks", doors.state[safe] == "passage" and doors.locks[safe].disabled)
	await press(doors.find_child("Btn_3", true, false));await frames(20)
	check(tag+"REPLAY with real pointer closes every door", doors.state.all(func(s): return s == "closed"))

func timing_checks(tag: String) -> void:
	var group: Node3D = station(TIMING)
	var trial: Node3D = group.trials[0]
	var y: float = game.building.spec.levels[level]
	var start: Vector3 = trial.to_global(Vector3(trial.lane_x(0), 0, -4.7))
	start.y = y+.06
	game.place_player(start);await frames(20)
	await walk_to(trial.get_node("ChoicePlate0").global_position, 180)
	for i in 30:
		if trial.chosen != -1: break
		await frames(1)
	print("TIMING ", tag, trial.get_state())
	check(tag+"real walking onto plate A of SHOWN FIRST chooses A (Void body)", trial.chosen == 0 and trial.get_state().events.size() == 3)
	var controls: Node3D = trial.get_node("RoundControls")
	await stand_local(trial, Vector3(2.0, .06, -4.75))
	await press(controls.find_child("Btn_0", true, false));await frames(10)
	check(tag+"REPLAY with real pointer starts a new round with no choice", trial.chosen == -1)

var field_launches: Array = []

func _on_field_launch(projectile: Node3D) -> void:
	field_launches.append({"node": projectile, "at": projectile.global_position})

## Launch points of the next `count` cubes the source timer spawns (projectile_spawned is
## emitted after the source has positioned the cube). The window covers the source's FIRST
## interval: the scene authors spawn_interval = 6.0 and activate_spawner() starts the timer
## in _ready, before the token's spawn_interval:0.5 arrives, so the first cube comes about
## 6 s after the floor builds and 0.5 s apart after that (source behaviour, unchanged).
func field_launch_sample(field: Node3D, count: int, limit: int = 480) -> Array:
	field_launches.clear()
	var timer: Timer = field.get("spawn_timer")
	print("FIELD_TIMER active=", field.get("is_active"), " wait=", timer.wait_time if timer != null else -1.0, " left=", timer.time_left if timer != null else -1.0, " processing=", field.can_process())
	field.projectile_spawned.connect(_on_field_launch)
	var waited := 0
	for i in limit:
		await frames(1)
		waited += 1
		if field_launches.size() >= count or not is_instance_valid(field): break
	if is_instance_valid(field) and field.projectile_spawned.is_connected(_on_field_launch):
		field.projectile_spawned.disconnect(_on_field_launch)
	print("FIELD_SAMPLE ", field_launches.size(), " of ", count, " launches in ", waited, " frames")
	return field_launches.duplicate()

func field_ceiling() -> float:
	return float(game.building.spec.levels[level])+float(game.building.spec.storey_height)-float(game.building.spec.slab_thickness)

## R3 at the token's own placement: an effective launch height under the slab above, and a
## launched cube coming to rest on floor 5 (not on floor 4).
func field_checks(tag: String) -> void:
	var field: Node3D = station(FIELD)
	var y: float = game.building.spec.levels[level]
	var ceiling: float = field_ceiling()
	check(tag+"falling field keeps the source values: field mode, 8 x 8 m, 24 cubes, 0.5 s, configured launch 8 m (API)", field.spawn_mode == 1 and is_equal_approx(field.field_size_meters.x, 8.0) and field.max_projectiles == 24 and is_equal_approx(field.spawn_interval, .5) and is_equal_approx(float(field.get("source_field_height") if field.get("source_field_height") != null else -1.0), 8.0))
	check(tag+"falling field runs the trial adapter (needs R3)", field.get_script().resource_path.ends_with("randomness_05/cube_field_local.gd"))
	var launches: Array = await field_launch_sample(field, 2)
	var heights: Array = launches.map(func(l): return snappedf(l.at.y-y, .01))
	print("FIELD ", tag, "effective launch ", field.field_spawn_height, " (source ", field.get("source_field_height"), ") offset ", field.field_center_offset, " launch heights above floor 5 ", heights)
	check(tag+"real source spawns launch under the slab above floor 5 (needs R3: effective-height adaptation, source 8 m)", launches.size() >= 2 and launches.all(func(l): return l.at.y < ceiling-.2 and l.at.y > y+1.0))
	var cube: Node3D = launches[0].node if not launches.is_empty() else null
	var lowest := INF
	var low_frames := 0
	for i in 300:
		if cube == null or not is_instance_valid(cube): break
		lowest = minf(lowest, cube.global_position.y)
		low_frames = low_frames+1 if cube.global_position.y < y+.5 else 0
		if low_frames >= 15: break
		await frames(1)
	print("FIELD ", tag, "first cube lowest centre %.2f m above floor 5" % (lowest-y))
	# 0.25 m = resting on the slab; up to 0.75 m = on another resting cube. Floor 4 is 6 m up.
	check(tag+"a launched cube comes to rest on floor 5, the intended floor, not floor 4 (geometry)", lowest > y+.1 and lowest < y+.85)
	if not xr: fit_notes.append({"id": FIELD, "effective_launch_m": field.field_spawn_height, "source_launch_m": field.get("source_field_height"), "launch_heights_m": heights, "rest_height_m": lowest-y})

## R3 after a changed placement height, a move with a 90 degree turn, and a nonzero
## field_center_offset.y (the token has none): launches stay under the slab and centre on
## the moved emitter. Mount transforms are set as the editor would; restored afterwards.
func field_move_checks(tag: String) -> void:
	var field: Node3D = station(FIELD)
	var mount: Node3D = field.get_parent()
	var y: float = game.building.spec.levels[level]
	var ceiling: float = field_ceiling()
	var home: Transform3D = mount.transform
	var home_offset: Vector3 = field.field_center_offset
	mount.position.y = home.origin.y+1.0
	var raised: Array = await field_launch_sample(field, 2)
	print("FIELDMOVE ", tag, "raised 1 m: launch ", field.field_spawn_height, " at ", raised.map(func(l): return l.at))
	check(tag+"placement raised 1 m: launches stay under the slab above (needs R3)", raised.size() >= 2 and raised.all(func(l): return l.at.y < ceiling-.2 and l.at.y > y+1.0))
	mount.position = home.origin+Vector3(-1.5, 0, -2.0)
	mount.rotation_degrees.y += 90.0
	var moved: Array = await field_launch_sample(field, 2)
	var origin: Vector3 = field.global_position+field.field_center_offset
	print("FIELDMOVE ", tag, "moved and turned: origin ", origin, " at ", moved.map(func(l): return l.at))
	# The source samples x/z in WORLD axes around the emitter (field half-size 4 m), so a
	# turned mount does not turn the field; only the move and the cap are tested here.
	check(tag+"placement moved 2.5 m and turned 90 degrees: launches lie within the 8 x 8 m field around the moved emitter, under the slab (needs R3)", moved.size() >= 2 and moved.all(func(l): return absf(l.at.x-origin.x) <= 4.05 and absf(l.at.z-origin.z) <= 4.05 and l.at.y < ceiling-.2))
	field.field_center_offset = home_offset+Vector3(0, .6, 0)
	var lifted: Array = await field_launch_sample(field, 2)
	print("FIELDMOVE ", tag, "offset y +0.6: launch ", field.field_spawn_height, " at ", lifted.map(func(l): return l.at))
	check(tag+"field_center_offset.y +0.6 is included in the cap (needs R3)", lifted.size() >= 2 and lifted.all(func(l): return l.at.y < ceiling-.2))
	field.field_center_offset = home_offset
	mount.transform = home
	await frames(5)

## Residency of the source's scene-root projectiles: they are children of the current
## scene, not of floor 5. Measured: emitter asleep and no launches while the visitor is on
## floor 4; cubes already in flight keep processing and free themselves after their 10 s
## lifetime (or when the emitter leaves the tree).
func field_residency_report(tag: String) -> void:
	var field: Node3D = station(FIELD)
	await field_launch_sample(field, 3)
	var flying: Array = field.active_projectiles.filter(func(p): return is_instance_valid(p))
	game.place_player(game.spawn_for(level-1));await frames(90)
	var emitter_alive: bool = is_instance_valid(field)
	var asleep: bool = not emitter_alive or not field.can_process()
	var away: Array = []
	if emitter_alive: away = await field_launch_sample(field, 1, 120)
	var still_live: Array = flying.filter(func(p): return is_instance_valid(p))
	var processing: int = still_live.filter(func(p): return p.can_process()).size()
	print("FIELDSLEEP ", tag, "emitter alive=", emitter_alive, " asleep=", asleep, " launches away=", away.size(), " in flight before=", flying.size(), " live=", still_live.size(), " processing=", processing)
	check(tag+"while the visitor is on floor 4 the field emitter sleeps and launches nothing (residency)", asleep and away.is_empty())
	await frames(660)
	var after: int = flying.filter(func(p): return is_instance_valid(p)).size()
	print("FIELDSLEEP ", tag, "after 11 s live=", after)
	check(tag+"cubes in flight when the visitor left free themselves within their 10 s lifetime (measurement)", after == 0)

func waiting_checks(tag: String) -> void:
	var waiting: Node3D = station(WAITING)
	var run_button: Node3D = waiting.find_child("Btn_0", true, false)
	await stand_near(run_button, waiting, 1.2)
	var before: bool = waiting.running
	await press(run_button);await frames(8)
	check(tag+"RUN / STOP with real pointer toggles the arrivals", waiting.running != before)
	await press(run_button);await frames(8)
	var cube: Node3D = null
	for item in waiting.cubes:
		if is_instance_valid(item): cube = item
	if cube == null:
		print("WAITING ", tag, "no wooden cube has arrived yet");return
	var shapes: Array = cube.find_children("*", "CollisionShape3D", false, false)
	var preflight: Dictionary = input_grab_preflight(cube, shapes[0] if not shapes.is_empty() else null)
	print("WAITING ", tag, cube.get_path(), " ", preflight)
	check(tag+"arriving wooden cube is in the active grab mask (preflight)", preflight.passed)

func capture_floor() -> void:
	var y: float = game.building.spec.levels[level]
	match level:
		1:
			await photo("01-geometry-arrival-eye", Vector3(0, y+1.65, 12.5), Vector3(-1.5, y+1.4, 3))
			await photo("02-geometry-bench", Vector3(1.5, y+2.2, -2), Vector3(-5, y+1.2, -6.5))
		2:
			await photo("03-examples-arrival-eye", Vector3(0, y+1.65, 12.5), Vector3(1, y+.4, 3))
			await photo("04-examples-pipe-particles", Vector3(3, y+1.9, 2), Vector3(-.5, y+1.3, -7))
		3:
			await photo("05-pheromone-console-eye", Vector3(-6, y+1.65, 3.6), Vector3(-6, y+.4, 9))
		4:
			await photo("06-space-arrival-eye", Vector3(0, y+1.65, 12.5), Vector3(.25, y+.4, -2))
			await photo("07-space-instruments", Vector3(5.5, y+2.2, 3), Vector3(1, y+.9, -3.5))
		5:
			await photo("08-game-crossing-eye", Vector3(0, y+1.65, 11.4), Vector3(0, y-.3, 5))
			await photo("09-game-arena-glass", Vector3(0, y+2.6, 3.2), Vector3(0, y, -5))
			await photo("10-game-doors-west", Vector3(-16.5, y+1.65, -13.8), Vector3(-16.5, y+1.6, -6.5))
			await photo("11-game-door-timing", Vector3(-13.4, y+1.9, 3.4), Vector3(-13.4, y+1.2, 8.5))
			await photo("12-game-field-waiting", Vector3(15, y+1.9, 14.2), Vector3(15.5, y+1.4, -1))
