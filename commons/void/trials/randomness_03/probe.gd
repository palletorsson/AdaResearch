extends "res://tools/probes/void_transfer_probe.gd"
## Batch 24: Random_Remove (floor 1) and Randomness_10_PRINT_Algorithm (floor 2).
## Visit, inspection, shaft descent, residency and retry come from the shared probe.
## Real input uses the shared input_* helpers; API, geometry and measurement checks
## say so in their names.

const ARENA := "f1_random_removal_arena_8_17"
const NATURE := "f2_nature_system_demo_13_19"
## Floor 1's 3 m basin (rooms.json), as a world box hanging below floor 1.
const BASIN_RECT := Rect2(-7.5, -10.5, 15, 11)

func debug_cases() -> Dictionary:
	return {"bounds-1": 1, "bounds-2": 2, "nature": 2, "remover": 1, "hoppers": 1, "arena": 1,
		"film": 2, "composition": 2, "textile": 2, "clipboard": 2, "crossfloor": 1}

func run_debug_case(name: String, tag: String) -> void:
	match name:
		"bounds-1", "bounds-2":
			inspect_floor(tag)
			await frames(30)
			await fit_checks(tag)
			report_bounds(tag)
		"nature": await frames(60);await nature_checks(tag)
		"remover": await remover_checks(tag)
		"hoppers": await hopper_checks(tag)
		"arena": await arena_checks(tag)
		"film": await film_checks(tag)
		"composition": await composition_checks(tag)
		"textile": await textile_checks(tag)
		"clipboard": await clipboard_checks(tag)
		"crossfloor": await crossfloor_report(tag)

## Floor-2 maze planes rise 3-13 m, through floor 1. Seen from floor 1: are they
## visible, do they collide at body height, and can a visitor walk across their line
## to the arena's north bank? Measurement only.
func crossfloor_report(tag: String) -> void:
	var y1: float = game.building.spec.levels[1]
	for id in ["f2_ten_print_maze_3d_2_5", "f2_ten_print_maze_3d_12_5", "f2_ten_print_maze_3d_2_15"]:
		var maze: Node3D = game.building.content.exhibits["2/"+id].get_node("Artifact")
		var b: AABB = bounds_of(maze)
		var mid: Vector3 = b.get_center();mid.y = y1+1.2
		var across: Vector3 = Vector3(2.0, 0, 0) if b.size.x < b.size.z else Vector3(0, 0, 2.0)
		var hit := ray(mid-across, mid+across)
		print("CROSSFLOOR ", tag, id, " visible=", maze.is_visible_in_tree(), " processing=", maze.can_process(), " body_height_hit=", str(hit.collider.get_path()) if not hit.is_empty() else "none")
	game.place_player(Vector3(-2, y1+.06, 5.5));await frames(25)
	var reached: bool = await move_to(Vector3(-2, y1+.06, 1.2), false, 240)
	print("CROSSFLOOR ", tag, "walk from z 5.5 to the arena north bank z 1.2 at x -2: reached=", reached, " at=", game.body.global_position)

## Measured empty sources: remove_random without local_grid binds no board, and
## pickup_cube_placer needs a GridSystem, which neither the museum nor the Void has.
func expected_empty_source(node: Node3D) -> bool:
	var key: String = str(node.get_meta("artifact_lookup_name", ""))
	return key == "pickup_cube_placer" or (key == "remove_random" and not bool(node.get("local_grid")))

func focused_checks(tag: String) -> void:
	check(tag+"standard floor "+str(level), game.building.spec.width == 42 and game.building.spec.depth == 32 and game.building.spec.storey_height == 6)
	await fit_checks(tag)
	match level:
		1:
			await remover_checks(tag)
			await hopper_checks(tag)
			await arena_checks(tag)
		2:
			await film_checks(tag)
			await composition_checks(tag)
			await textile_checks(tag)
			await clipboard_checks(tag)
			tenprint_checks(tag)
			await nature_checks(tag)
	game.place_player(game.spawn_for(level));await frames(15)

# ── helpers ─────────────────────────────────────────────────────────────────

func bounds_of(node: Node3D) -> AABB:
	var boxes: Array = [];geometry(node, boxes)
	if boxes.is_empty(): return AABB()
	var b: AABB = boxes[0]
	for box in boxes: b = b.merge(box)
	return b

## Shrink by up to 1 mm per side without ever producing a negative size
## (zero-thickness planes and labels stay zero-thick).
func shrink_mm(b: AABB) -> AABB:
	var g := Vector3(minf(.001, b.size.x/2.0), minf(.001, b.size.y/2.0), minf(.001, b.size.z/2.0))
	return AABB(b.position+g, b.size-g*2.0)

func basin_box() -> AABB:
	var y1: float = game.building.spec.levels[1]
	return AABB(Vector3(BASIN_RECT.position.x, y1-3.2, BASIN_RECT.position.y), Vector3(BASIN_RECT.size.x, 3.2, BASIN_RECT.size.y))

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

## Stand 1.2 m beyond a control, away from its artifact, on this floor.
func stand_near(control: Node3D, owner: Node3D, distance: float = 1.2) -> void:
	var away: Vector3 = control.global_position-owner.global_position
	away.y = 0
	if away.length() < .05: away = owner.global_basis.z
	var at: Vector3 = control.global_position+away.normalized()*distance
	at.y = game.building.spec.levels[level]+.06
	game.place_player(at);await frames(20)

## Real pointer press for rack buttons (InteractableAreaButton) and areas whose
## own CollisionShape3D is the target.
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

## Real pointer drag: mouse button or trigger held while the ray sweeps.
func pointer_drag(from: Vector3, to: Vector3, steps: int = 16) -> void:
	if not xr:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		await input_aim_camera(from, 20)
		var e := InputEventMouseButton.new();e.button_index = MOUSE_BUTTON_LEFT;e.pressed = true
		Input.parse_input_event(e);await frames(4)
		for i in steps:
			await input_aim_camera(from.lerp(to, (i+1)/float(steps)), 2)
		e = InputEventMouseButton.new();e.button_index = MOUSE_BUTTON_LEFT;e.pressed = false
		Input.parse_input_event(e);await frames(8)
		return
	for i in 20:
		aim_pointer(from);await frames(1)
	right.set_input("trigger_click", true);await frames(4)
	for i in steps:
		aim_pointer(from.lerp(to, (i+1)/float(steps)));await frames(2)
	right.set_input("trigger_click", false);await frames(8)

func release_grip() -> void:
	if xr: right.set_input("grip", 0.0);await frames(12)
	else:
		for down in [true, false]:
			var e := InputEventMouseButton.new();e.button_index = MOUSE_BUTTON_RIGHT;e.pressed = down
			Input.parse_input_event(e);await frames(8)

# ── floor 1 ─────────────────────────────────────────────────────────────────

func remover_checks(tag: String) -> void:
	var rig: Node3D = station("f1_remove_random_8_5")
	check(tag+"remover owns its 8x8 board (local_grid)", rig.local_grid and rig.multimesh != null and rig.multimesh.instance_count == 64)
	var range_button: Node3D = rig.find_child("Btn_0", true, false)
	var remove_button: Node3D = rig.find_child("Btn_4", true, false)
	var reset_button: Node3D = rig.find_child("Btn_5", true, false)
	await stand_near(range_button, rig)
	await press(range_button);await frames(10)
	check(tag+"RANGE with real pointer selects the source range", rig.selection_mode == "Range")
	var before: int = rig.active_instances.size()
	await press(remove_button)
	for i in 120:
		await frames(1)
		if rig.removal_log.size() == 1: break
	check(tag+"REMOVE ONE with real pointer deletes one eligible cube", rig.removal_log.size() == 1 and rig.active_instances.size() == before-1)
	await press(reset_button);await frames(20)
	check(tag+"RESET with real pointer restores the board", rig.removal_log.is_empty() and rig.active_instances.size() == before)

func hopper_checks(tag: String) -> void:
	var hoppers: Node3D = station("f1_sampling_hoppers_3_6")
	check(tag+"two hoppers of eight with two levers", hoppers.levers.size() == 2 and hoppers.pools[0].size() == 8 and hoppers.pools[1].size() == 8)
	var lever: Node3D = hoppers.levers[1]
	var hinge: Node3D = lever.get_node("LeverOrigin/InteractableLever")
	# The handle (layer 19) is the pointable part; the bar sits on layer 1, which
	# neither the desktop pointer (19/21/23) nor the XR grab sees.
	var handle: Node3D = lever.get_node("LeverOrigin/InteractableLever/HandleOrigin/InteractableHandle")
	var shape: CollisionShape3D = handle.get_node("CollisionShape3D")
	await stand_near(shape, hoppers, 1.0)
	var before: int = hoppers.totals[1]
	if xr:
		var origin: Node3D = lever.get_node("LeverOrigin")
		var rest: Vector3 = origin.to_local(handle.global_position)
		if await input_grab(tag+"lever handle: ", handle, shape, .3, .05):
			for degrees in [4.0, 12.0, 20.0, 28.0, 36.0, 40.0]:
				await input_tip_to(handle, origin.to_global(Basis(Vector3.RIGHT, deg_to_rad(degrees))*rest))
				await frames(4)
			await release_grip()
	else:
		# The lever reads local-y pointer travel (x450 degrees per metre); the hopper
		# scales it by 1.35, so 0.12 m in the world is about 40 degrees.
		var from: Vector3 = shape.global_position
		await pointer_drag(from, from-lever.global_basis.y.normalized()*.12)
	print("HOPPER ", tag, "angle=", hinge.hinge_position, " totals=", hoppers.totals)
	for i in 120:
		await frames(1)
		if hoppers.totals[1] > before and not hoppers.busy[1]: break
	check(tag+"real "+("grip" if xr else "pointer")+" lever pull draws from the withdrawal hopper", hoppers.totals[1] == before+1 and hoppers.pools[1].size() == 7)
	await stand_near(hoppers.find_child("Btn_0", true, false), hoppers)
	await press(hoppers.find_child("Btn_0", true, false));await frames(60)
	check(tag+"REPLAY BOTH with real pointer refills the withdrawn member", hoppers.pools[1].size() == 8)

func arena_checks(tag: String) -> void:
	var arena: Node3D = station(ARENA)
	var y: float = game.building.spec.levels[level]
	check(tag+"arena builds the source 15 x 11 = 165 tiles with full crossing and Tesla canopy (needs R1)", arena.colliders.size() == 165 and arena.full_crossing and arena.coils != null)
	print("ARENA ", tag, "tiles=", arena.colliders.size(), " coils=", arena.coils != null, " script=", arena.get_script().resource_path)
	# Under a tile: the floor-1 basin, 3 m down, not the slab.
	var tile: Vector3 = arena.colliders[0].global_position
	var under := ray(tile+Vector3.DOWN*.35, tile+Vector3.DOWN*4.0)
	check(tag+"basin lies 3 m under the arena tiles (geometry)", not under.is_empty() and absf(under.position.y-(y-3.0)) < .15)
	# Real walking onto the crossing from its north bank.
	var bank: Vector3 = arena.to_global(Vector3(0, .06, -arena.rows/2.0-.5))
	bank.y = y+.06
	game.place_player(bank);await frames(25)
	var removed_before: int = arena.get_state().removed
	await move_to(arena.to_global(Vector3(0, 0, -arena.rows/2.0+2.5)), false, 150)
	for i in 120:
		await frames(1)
		if arena.get_state().removed > removed_before: break
	var state: Dictionary = arena.get_state()
	print("ARENA ", tag, "state=", state)
	check(tag+"walking onto the arena withdraws a tile (needs R2)", state.removed > removed_before and state.disabled_colliders >= 1)
	if state.removed > removed_before:
		var gone: Vector3 = arena.colliders[arena.remover.last_removed_index].global_position
		var hole := ray(gone+Vector3.UP*.5, gone+Vector3.DOWN*4.0)
		check(tag+"withdrawn tile leaves a drop into the basin (geometry)", not hole.is_empty() and hole.position.y < y-2.5)
	game.place_player(arena.to_global(Vector3(0, .06, -arena.rows/2.0-.5)));await frames(15)
	var replay: Node3D = arena.find_child("Btn_2", true, false)
	await stand_near(replay, arena)
	await press(replay);await frames(30)
	var after: Dictionary = arena.get_state()
	check(tag+"REPLAY with real pointer restores every tile and collider", after.remaining == arena.colliders.size() and after.disabled_colliders == 0)

# ── floor 2 ─────────────────────────────────────────────────────────────────

func film_checks(tag: String) -> void:
	var film: Node3D = station("f2_film_chance_passage_13_7")
	await stand_local(film, Vector3(0, .06, 1.7))
	await press(film.buttons.pause)
	check(tag+"chance-passage film pauses with real pointer", not film.stage.running)
	await press(film.buttons.pause)

func composition_checks(tag: String) -> void:
	var comp: Node3D = station("f2_composition_stochastique_1_8")
	var reseed: Node3D = comp.find_child("Btn_0", true, false)
	var before: int = comp.draw_index()
	await stand_near(reseed, comp)
	await press(reseed);await frames(10)
	check(tag+"RESEED with real pointer deals a new composition", comp.draw_index() == before+1)

func textile_checks(tag: String) -> void:
	var studio: Node3D = station("f2_textile_comparison_7_15")
	var seed_before: int = int(studio.record.seed)
	await stand_near(studio.buttons["SEED +"], studio)
	await press(studio.buttons["SEED +"]);await frames(10)
	check(tag+"SEED + with real pointer changes the retained draws", int(studio.record.seed) == seed_before+1)
	await press(studio.buttons["STITCH"]);await frames(10)
	check(tag+"STITCH with real pointer selects the stitched print", int(studio.record.mark) == 1)

func clipboard_checks(tag: String) -> void:
	var board: Node3D = station("f2_clipboard_7_5")
	var plane: Node3D = board.get_node_or_null("GrabPlane")
	var shape: CollisionShape3D = plane.get_node_or_null("CollisionShape3D") if plane != null else null
	check(tag+"clipboard keeps its grab plane (geometry)", plane != null and shape != null)
	if plane == null or shape == null: return
	print("CLIPBOARD ", tag, "plane=", plane.global_position, " class=", plane.get_class(), " layer=", plane.get("collision_layer"))
	await stand_local(board, Vector3(0, .06, 1.0))
	if await input_grab(tag+"clipboard: ", plane, shape, .4, .1):
		await frames(20)
		await release_grip()

func tenprint_checks(tag: String) -> void:
	var wall: Node3D = station("f2_ten_print_structure_11_3")
	check(tag+"10 PRINT structure keeps its wall form, 4 x 3 cells and seed 1982 (API)", wall.form == "wall" and wall.cols == 4 and wall.rows == 3 and wall.seed == 1982)
	for entry in game.building.content.data.floors[level].artifacts:
		if entry.artifact != "ten_print_maze_3d": continue
		var maze: Node3D = station(entry.id)
		check(tag+entry.id+" draws the character impression (API)", maze.impression == "character")

## R4 adapter: the original 48 critters in the demo's own frame, its standalone UI
## and keys off, and the original key actions on real pointer buttons.
func nature_checks(tag: String) -> void:
	var demo: Node3D = station(NATURE)
	check(tag+"nature demo runs the trial adapter (needs R4)", demo.get_script().resource_path.ends_with("randomness_03/nature_demo_local.gd"))
	if not "buttons" in demo:
		nature_report(tag);return
	var active: Array = demo._spawner.get_active_critters()
	var local_ok := func(list: Array) -> bool:
		return list.all(func(c): return is_instance_valid(c) and absf(demo.to_local(c.global_position).y) < .01)
	check(tag+"48 original critters stand in the demo's own frame (3 x 4 x 4 at 3.5 m)", active.size() == 48 and demo.spawned_by_demo == 48 and demo.grid_rows == 3 and is_equal_approx(demo.grid_spacing, 3.5) and local_ok.call(active))
	check(tag+"standalone screen UI hidden and key handler off", not demo.get_node("UI").visible and not demo.is_processing_unhandled_input())
	await stand_near(demo.buttons["CLEAR"], demo, 1.2)
	await press(demo.buttons["CLEAR"]);await frames(15)
	check(tag+"CLEAR with real pointer removes the population", demo._spawner.get_active_critters().filter(func(c): return is_instance_valid(c) and not c.is_queued_for_deletion()).is_empty())
	await press(demo.buttons["REPOPULATE"]);await frames(30)
	var again: Array = demo._spawner.get_active_critters().filter(func(c): return is_instance_valid(c) and not c.is_queued_for_deletion())
	check(tag+"REPOPULATE with real pointer rebuilds 48 critters in the demo frame", again.size() == 48 and local_ok.call(again))
	nature_report(tag)

## What the immersive demo actually builds here. Measurement only: its DNA is
## randomised every boot, so body-chain extents vary between runs.
func nature_report(tag: String) -> void:
	var demo: Node3D = station(NATURE)
	var y: float = game.building.spec.levels[level]
	var root: Node3D = demo.get_node_or_null("CritterRoot")
	var critters: Array = root.get_children() if root != null else []
	var lo := Vector3.INF
	var hi := -Vector3.INF
	for c in critters:
		if c is Node3D:
			lo = lo.min(c.global_position);hi = hi.max(c.global_position)
	var layers: Array = demo.find_children("*", "CanvasLayer", true, false).map(func(l): return str(demo.get_path_to(l))+(" visible" if l.visible else " hidden"))
	var b: AABB = bounds_of(demo)
	var note := {"id": NATURE, "critters": critters.size(), "origin_world_y": [lo.y, hi.y], "origin_world_x": [lo.x, hi.x], "origin_world_z": [lo.z, hi.z],
		"floor_y": y, "canvas_layers": layers, "unhandled_input": demo.is_processing_unhandled_input(),
		"geometry_world_x": [b.position.x, b.end.x], "geometry_world_z": [b.position.z, b.end.z], "geometry_y_above_floor": [b.position.y-y, b.end.y-y]}
	print("NATURE ", tag, note)
	if not xr: fit_notes.append(note)

## Whole shaft openings, the arrival, the default floor sign and (on floor 2) the
## floor-1 basin that hangs into this storey.
func fit_checks(tag: String) -> void:
	var spec = game.building.spec
	var y: float = spec.levels[level]
	var keep_out: Array = []
	for shaft in spec.shafts:
		keep_out.append(["shaft "+str(shaft.name), AABB(Vector3(float(shaft.x)-float(spec.shaft_width)/2.0, y-.5, -float(spec.shaft_depth)/2.0), Vector3(float(spec.shaft_width), 6.5, float(spec.shaft_depth)))])
	keep_out.append(["arrival", AABB(Vector3(-1, y, 11), Vector3(2, 2.2, 2))])
	var sign_xz: Array = spec.get("floor_sign_positions", {}).get(str(level), [3.5, -7.8])
	keep_out.append(["floor sign", AABB(Vector3(float(sign_xz[0])-1.85, y+.525, float(sign_xz[1])-.06), Vector3(3.7, 1.65, .12))])
	if level == 2: keep_out.append(["floor-1 basin", basin_box()])
	var hits: Array = []
	for entry in game.building.content.data.floors[level].artifacts:
		if entry.id == NATURE: continue # spawns in world space; measured separately
		var boxes: Array = [];geometry(station(entry.id), boxes)
		if entry.id == ARENA:
			# The source Tesla canopy is 15.1 m wide; the gap between the shafts is
			# 15.0 m. Its side rails are measured on their own below; everything
			# else in the arena stays under the strict test.
			var canopy: Array = [];geometry(station(ARENA).coils, canopy)
			boxes = boxes.filter(func(b): return not canopy.has(b))
			var reach := 0.0
			for b in canopy:
				for shaft in spec.shafts:
					var inner: float = float(shaft.x)-signf(float(shaft.x))*float(spec.shaft_width)/2.0
					reach = maxf(reach, (b.end.x-inner) if float(shaft.x) > 0 else (inner-b.position.x))
			print("CANOPY ", tag, "rail reach into shaft openings %.3f m" % reach)
			if not xr: fit_notes.append({"id": ARENA, "canopy_rail_into_each_shaft_m": reach, "canopy_width_m": 15.1, "gap_between_shafts_m": 15.0})
			check(tag+"arena canopy side rails overhang each shaft opening by at most 0.06 m (measured; source 15.1 m vs 15.0 m gap)", reach <= .06)
		for item in keep_out:
			var zone: AABB = item[1]
			# Contact is not entry: the arena's 15.0 m end bank meets the shaft
			# edges exactly, and float rounding made that touch read as overlap.
			var inside: Array = boxes.filter(func(b): return shrink_mm(b).intersects(zone))
			if not inside.is_empty():
				hits.append(entry.id+" / "+str(item[0]))
				print("FIT_BOX ", tag, entry.id, " / ", item[0], " ", inside.slice(0, 3))
	print("FIT ", tag, "floor ", level, " ", hits)
	if not xr and not hits.is_empty(): fit_notes.append({"floor": level, "enters": hits})
	check(tag+"placement geometry stays out of shafts, arrival, floor sign"+(" and floor-1 basin" if level == 2 else ""), hits.is_empty())

func capture_floor() -> void:
	var y: float = game.building.spec.levels[level]
	match level:
		1:
			await photo("01-random-remove-arrival-eye", Vector3(0, y+1.65, 12.5), Vector3(0, y+1.0, 2))
			await photo("02-remover-and-hoppers", Vector3(2.5, y+2.4, 11), Vector3(2.5, y+1.0, 6.5))
			await photo("03-arena-from-north-bank", Vector3(0, y+3.2, 4), Vector3(0, y-.5, -6))
		2:
			await photo("04-tenprint-arrival-eye", Vector3(0, y+1.65, 12.5), Vector3(-2, y+3, 2))
			await photo("05-mazes-into-slab", Vector3(-3, y+2.0, -6), Vector3(-1, y+4.5, 6))
			await photo("06-film-and-clipboard", Vector3(-5, y+1.8, 9), Vector3(-8, y+1.0, 6))
			await photo("07-textile-under-basin", Vector3(-3, y+1.8, -6), Vector3(-3, y+1.4, -11.5))
