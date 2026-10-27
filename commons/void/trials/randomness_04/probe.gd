extends "res://tools/probes/void_transfer_probe.gd"
## Batch 25 / randomness_04 (Claude worker A): Random_Cubes (1), Random_Rotate_Random_XYZ (2),
## Random_Walk (3), Random_Gaussian (4), Random_Mushrooms (5). 75 placements.
## Visit, inspection (identity, geometry, config meta for all 75), shaft descent, residency
## and retry come from the shared probe. Real input uses the shared input_* helpers,
## press() and pointer_drag(); API, geometry and measurement checks say so in their names.
## "(needs Rn)" names the shared request in REQUESTS.md the check depends on.

const MOAT := "f3_random_walk_128_9_17"
const SPAWNERS := ["f1_random_object_spawner_5_6", "f1_random_object_spawner_6_6"]

func debug_cases() -> Dictionary:
	return {"bounds-1": 1, "bounds-2": 2, "bounds-3": 3, "bounds-4": 4, "bounds-5": 5,
		"dice": 1, "dice-transform": 1, "paired": 1, "spawner": 1, "decay": 2, "hardware": 2, "walk": 3, "rails": 3,
		"moat": 3, "leash-transform": 3, "gaussian": 4, "galton": 4, "galton-spread": 4, "comparator": 4, "mushrooms": 5, "arrivals": 5}

func run_debug_case(name: String, tag: String) -> void:
	match name:
		"bounds-1", "bounds-2", "bounds-3", "bounds-4", "bounds-5":
			inspect_floor(tag)
			await frames(30)
			await fit_checks(tag)
			report_bounds(tag)
		"dice": identity_checks_1(tag);await dice_checks(tag);await coin_checks(tag);await continuing_checks(tag)
		"dice-transform": await dice_transform_check(tag)
		"paired": await paired_checks(tag);await paired_throw(tag)
		"spawner": await spawner_checks(tag)
		"decay": await decay_checks(tag);rotate_checks(tag);await key_checks(tag)
		"hardware": await hardware_checks(tag);await key_checks(tag)
		"walk": sheet_checks(tag);await terrarium_checks(tag);await leash_checks(tag);await dot_checks(tag);await key_checks(tag)
		"rails": await rails_checks(tag)
		"leash-transform": await leash_transform_check(tag)
		"moat": await walk128_checks(tag)
		"gaussian": await key_checks(tag);await sampler_checks(tag);splatter_checks(tag)
		"galton": await galton_checks(tag)
		"galton-spread": await galton_spread(tag)
		"comparator": await comparator_checks(tag);await comparator_slider_report(tag)
		"mushrooms": bubbles_checks(tag);await mushroom_checks(tag)
		"arrivals": await arrivals_checks(tag);await couture_checks(tag)

## Spawners are hidden templates until their first cube arrives (a 0.3-1.3 s clock).
## Bounded readiness after start, so inspection sees original geometry, not a race.
func leash_transform_check(tag: String) -> void:
	var artifact: Node3D = station("f3_random_walk_leash_15_5")
	var mount: Node3D = artifact.get_parent()
	var saved := mount.transform
	mount.position += Vector3(1, -6, 2)
	mount.rotation.y += PI * .5
	mount.scale *= 1.25
	var orb: RigidBody3D = artifact.get("_orb_body")
	var mode: int = orb.freeze_mode
	orb.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
	orb.freeze = true
	var local_end: Vector3 = artifact.get("_orb_spawn_pos") + Vector3(.2, .1, -.15)
	orb.global_position = artifact.to_global(local_end)
	artifact.call("_update_leash_visual")
	artifact.call("_update_trail")
	var line: MeshInstance3D = artifact.get("_leash_line")
	var vertices: PackedVector3Array = line.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	check(tag+"rotated scaled moved leash ends at orb (geometry)", (line.global_transform * vertices[1]).distance_to(orb.global_position) < .001)
	var points: Array = artifact.get("_trail_points")
	check(tag+"rotated trail records orb in artifact coordinates (API)", artifact.to_global(points.back()).distance_to(orb.global_position) < .001)
	artifact.call("_reset")
	check(tag+"rotated negative-floor leash reset returns to gantry (API)", orb.global_position.distance_to(artifact.to_global(artifact.get("_orb_spawn_pos"))) < .001)
	await frames(2)
	mount.transform = saved
	orb.freeze_mode = mode
	artifact.call("_reset")

func dice_transform_check(tag: String) -> void:
	var artifact: Node3D = station("f1_dice_throw_3_2")
	var mount: Node3D = artifact.get_parent()
	var saved := mount.transform
	mount.position += Vector3(2, -6, 1)
	mount.rotation.y += PI * 0.5
	mount.scale *= 1.25
	var body: RigidBody3D = artifact.get("_dice_body")
	artifact.call("_reset_dice")
	var expected: Vector3 = artifact.to_global(artifact.get("_dice_spawn_pos"))
	check(tag+"moved rotated scaled negative-floor dice reset uses local spawn (API)", body.global_position.distance_to(expected) < .001)
	await frames(2)
	check(tag+"dice reset survives physics unfreeze", body.global_position.distance_to(expected) < .1 and not body.freeze)
	mount.transform = saved
	artifact.call("_reset_dice")

func start(use_xr: bool) -> void:
	await super.start(use_xr)
	await spawners_ready()

func spawners_ready() -> void:
	for i in 150:
		var all_ready := true
		for id in SPAWNERS:
			var mount: Node3D = game.building.content.exhibits.get("1/"+id)
			if mount == null or not mount.has_node("Artifact"):
				all_ready = false
			elif not has_visible_cube(mount.get_node("Artifact")):
				all_ready = false
		if all_ready: return
		await frames(1)

func has_visible_cube(spawner: Node3D) -> bool:
	for cube in spawner.spawned_cubes:
		if is_instance_valid(cube) and cube.is_visible_in_tree(): return true
	return false

## Measured-empty source: Random_Rotate_Random_XYZ finds no grid floor and turns nothing.
func expected_empty_source(node: Node3D) -> bool:
	return str(node.get_meta("artifact_lookup_name", "")) == "Random_Rotate_Random_XYZ"

func focused_checks(tag: String) -> void:
	check(tag+"standard floor "+str(level), game.building.spec.width == 42 and game.building.spec.depth == 32 and game.building.spec.storey_height == 6)
	await fit_checks(tag)
	match level:
		1:
			identity_checks_1(tag)
			await dice_checks(tag)
			await coin_checks(tag)
			await paired_checks(tag)
			await continuing_checks(tag)
			await spawner_checks(tag)
		2:
			await hardware_checks(tag)
			await decay_checks(tag)
			await key_checks(tag)
			rotate_checks(tag)
		3:
			sheet_checks(tag)
			await terrarium_checks(tag)
			await leash_checks(tag)
			await dot_checks(tag)
			await rails_checks(tag)
			await key_checks(tag)
			await walk128_checks(tag)
		4:
			await key_checks(tag)
			await sampler_checks(tag)
			splatter_checks(tag)
			await galton_checks(tag)
			await comparator_checks(tag)
		5:
			bubbles_checks(tag)
			await mushroom_checks(tag)
			await arrivals_checks(tag)
			await couture_checks(tag)
	game.place_player(game.spawn_for(level));await frames(15)

# ── helpers (randomness_03 pattern) ─────────────────────────────────────────

## The shared walker, except that a mesh with no surfaces contributes no box. Measured on
## bounds-3: random_draw_dot's DrawTrail is a top-level MeshInstance3D at the world origin
## whose ImmediateMesh stays empty until the dot is held and drawn with (draw_dot.gd:135,
## points appended in world space, :499). Its zero-size box at world (0, 0, 0) stretched
## the dot's bounds to x 0..3.25, y 0..18 above floor 3. It renders nothing.
func geometry(node: Node, boxes: Array) -> void:
	if node is MeshInstance3D and node.mesh != null and node.mesh.get_surface_count() == 0:
		for child in node.get_children(): geometry(child, boxes)
		return
	super.geometry(node, boxes)

func bounds_of(node: Node3D) -> AABB:
	var boxes: Array = [];geometry(node, boxes)
	if boxes.is_empty(): return AABB()
	var b: AABB = boxes[0]
	for box in boxes: b = b.merge(box)
	return b

## Shrink by up to 1 mm per side, never to a negative size (zero-thickness planes stay zero).
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

## Stand at an artifact-local floor point (artifact frame, so it follows any move/turn).
func stand_local(node: Node3D, at: Vector3) -> void:
	var p: Vector3 = node.to_global(at)
	p.y = game.building.spec.levels[level]+.06
	game.place_player(p);await frames(20)

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

## Desktop: the shared press (aim at the area's collider, LMB down 6 frames, up 8), but
## re-aimed every frame up to the click and traced at the moment of the click. XR: shared.
func press(button: Node3D) -> void:
	var shape: Node3D = button.get_node_or_null("InteractableAreaButton/CollisionShape3D")
	if xr or shape == null:
		await super.press(button);return
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	await input_aim_camera(shape.global_position, 25)
	trace_pointer(button, shape)
	var e := InputEventMouseButton.new();e.button_index = MOUSE_BUTTON_LEFT;e.pressed = true
	Input.parse_input_event(e);await frames(6)
	e = InputEventMouseButton.new();e.button_index = MOUSE_BUTTON_LEFT;e.pressed = false
	Input.parse_input_event(e);await frames(8)
	var area: Node = button.get_node_or_null("InteractableAreaButton")
	print("PRESS_AFTER ", button.get_path(), " area_pressed=", area.get("pressed") if area != null else "?")

## What the desktop hand will click: its resolved target and raw RayCast3D hit, an
## independent physics ray on the pointer mask (19/21/23, areas and bodies) through the
## collider, the area's own pressed state and trigger items, and the reach.
func trace_pointer(button: Node3D, shape: Node3D) -> void:
	var hand = game.body.desktop_pointer
	var cast: RayCast3D = hand.get_node_or_null("PointerRay")
	var raw: Object = cast.get_collider() if cast != null and cast.is_colliding() else null
	var target: Object = hand._last_target if is_instance_valid(hand._last_target) else null
	var eye: Vector3 = game.camera.global_position
	var q := PhysicsRayQueryParameters3D.create(eye, eye+(shape.global_position-eye)*1.5, (1 << 18) | (1 << 20) | (1 << 22))
	q.collide_with_areas = true
	q.exclude = [game.body.get_rid()]
	var direct: Dictionary = game.get_world_3d().direct_space_state.intersect_ray(q)
	var area: Node = button.get_node_or_null("InteractableAreaButton")
	var items = area.get("_trigger_items") if area != null else null
	print("PRESS_TRACE ", button.get_path(),
		" target=", (target as Node).get_path() if target is Node else "none",
		" raw=", (raw as Node).get_path() if raw is Node else "none",
		" direct=", (direct.collider as Node).get_path() if not direct.is_empty() and direct.collider is Node else "none",
		" area_pressed=", area.get("pressed") if area != null else "?",
		" area_items=", (items as Dictionary).keys().map(func(k): return str(k)) if items is Dictionary else "?",
		" holding=", hand.is_holding(), " reach=", eye.distance_to(shape.global_position),
		" aim_error_deg=", rad_to_deg((-game.camera.global_basis.z).angle_to(shape.global_position-eye)))

## A real key event through the viewport, as a desktop visitor's keyboard sends it.
func key(code: Key) -> void:
	for down in [true, false]:
		var e := InputEventKey.new();e.keycode = code;e.physical_keycode = code;e.pressed = down
		Input.parse_input_event(e);await frames(3)

func btn(host: Node, index: int) -> Node3D:
	return host.find_child("Btn_%d" % index, true, false)

func shape_of(body: Node) -> CollisionShape3D:
	var direct: Node = body.get_node_or_null("CollisionShape3D")
	if direct is CollisionShape3D: return direct as CollisionShape3D
	for child in body.get_children():
		if child is CollisionShape3D: return child as CollisionShape3D
	return null

func profile_built(entry: Dictionary) -> bool:
	var p: Node3D = station(entry.id)
	return p.readout == "relief" and p.point_count == 5 and p.profile_points.size() == 5

# ── floor 1: Random_Cubes ───────────────────────────────────────────────────

func identity_checks_1(tag: String) -> void:
	var profiles: Array = game.building.content.data.floors[1].artifacts.filter(func(e): return e.artifact == "random_edge_profile")
	var built: Array = profiles.filter(func(e): return profile_built(e))
	check(tag+"48 edge profiles keep their own relief, five points each (API)", profiles.size() == 48 and built.size() == 48)
	var coin: Node3D = station("f1_coin_toss_8_2")
	check(tag+"coin keeps disclosure:origin with its launch gauges (API)", coin.disclosure == "origin" and coin._gauge_holder != null)
	var orb: Node3D = station("f1_dark_sphere_9_5")
	check(tag+"dark sphere derives no gestation rung in a randomness hall, as in the museum (API)", orb._gest_stage() == "")

func dice_checks(tag: String) -> void:
	var dice: Node3D = station("f1_dice_throw_3_2")
	var body: Node3D = dice._dice_body
	var home: Vector3 = dice.global_position+dice._dice_spawn_pos
	var rolls: int = dice._total_rolls
	await stand_local(dice, Vector3(0, 0, 1.3))
	if await input_grab(tag+"die: ", body, shape_of(body), .3, .08):
		await input_tip_to(body, home+Vector3.UP*.35)
		await release_grip()
		for i in 240:
			await frames(1)
			if dice._total_rolls > rolls: break
		print("DICE ", tag, "rolls=", dice._total_rolls, " result=", dice._result_label.text, " at=", body.global_position)
		check(tag+"released die settles and its upward face is read (real pickup and drop)", dice._total_rolls == rolls+1 and dice._result_label.text in ["1","2","3","4","5","6"])
	await stand_local(dice, Vector3(-.22, 0, 1.4))
	var before_reset: Vector3 = body.global_position
	var area: Node = btn(dice, 0).get_node("InteractableAreaButton")
	area.button_pressed.connect(func(_b): sample_body(tag+"die after RESET", body, 12), CONNECT_ONE_SHOT)
	await press(btn(dice, 0));await frames(6)
	print("DICE_RESET ", tag, "before=", before_reset, " die=", body.global_position, " home=", home, " off=", body.global_position.distance_to(home), " result=", dice._result_label.text, " rain=", dice._reward_balls.size(), " freeze=", body.freeze, " freeze_mode=", body.freeze_mode, " held=", body.is_picked_up(), " script=", dice.get_script().resource_path)
	check(tag+"dice RESET with real pointer blanks the result and clears the reward rain", dice._result_label.text == "?" and dice._reward_balls.is_empty())
	check(tag+"dice RESET returns the die to its spawn on the felt from wherever it settled (needs R7)", body.global_position.distance_to(home) < .12)

## REFILL frees every coin and stacks a new tray. Compare by instance ID: Array.has() on a
## freed coin raises an engine error.
func coin_checks(tag: String) -> void:
	var coin: Node3D = station("f1_coin_toss_8_2")
	var old_ids: Array = []
	for c in coin._coins:
		if is_instance_valid(c): old_ids.append(c.get_instance_id())
	await stand_local(coin, Vector3(-.2, 0, 1.1))
	await press(btn(coin, 0));await frames(6)
	var new_ids: Array = []
	for c in coin._coins:
		if is_instance_valid(c): new_ids.append(c.get_instance_id())
	var kept: Array = new_ids.filter(func(i): return old_ids.has(i))
	print("COIN_REFILL ", tag, "before=", old_ids.size(), " after=", new_ids.size(), " kept=", kept.size())
	check(tag+"coin REFILL with real pointer restacks a fresh tray of coins", old_ids.size() > 0 and new_ids.size() == old_ids.size() and kept.is_empty())

## Positions of a body over the next frames (diagnostic print, not a check).
func sample_body(label: String, body: Node3D, count: int) -> void:
	var path: Array = []
	for i in count:
		if not is_instance_valid(body): break
		path.append(body.global_position)
		await frames(1)
	print("BODY_SAMPLE ", label, " ", path)

func paired_checks(tag: String) -> void:
	var column: Node3D = station("f1_paired_dice_column_5_4")
	check(tag+"paired column holds two tray dice (API)", column.trays.size() == 2)
	var returned := [0]
	for tray in column.trays: tray.returned.connect(func(): returned[0] += 1)
	await stand_local(column, Vector3(0, 0, 1.6))
	await press(btn(column, 0));await frames(6)
	var state: Dictionary = column.get_state()
	check(tag+"RETURN DICE with real pointer returns both dice to their trays", returned[0] == 2 and not state.committed)

## Diagnostic only: the tray-gated throw (pickup over tray A, release, face recorded).
func paired_throw(tag: String) -> void:
	var column: Node3D = station("f1_paired_dice_column_5_4")
	var tray: Node3D = column.trays[0]
	var die: Node3D = tray._dice_body
	await stand_local(column, Vector3(-.7, 0, 1.4))
	if not await input_grab(tag+"tray die A: ", die, shape_of(die), .3, .08): return
	await input_tip_to(die, tray.to_global(Vector3(0, tray.table_height+.3, 0)))
	await release_grip()
	for i in 240:
		await frames(1)
		if int(column.get_state().pending[0]) > 0: break
	print("PAIRED ", tag, column.get_state())
	check(tag+"die A released over its tray lands and is recorded as the pair's first face (real pickup and drop)", int(column.get_state().pending[0]) in [1,2,3,4,5,6])

func continuing_checks(tag: String) -> void:
	var rule: Node3D = station("f1_continuing_die_2_5")
	var changed := [0]
	rule.chain_changed.connect(func(_s): changed[0] += 1)
	await stand_local(rule, Vector3(-.7, 0, 1.7))
	await press(btn(rule, 1));await frames(6)
	var state: Dictionary = rule.get_state()
	check(tag+"NEW CHAIN with real pointer starts an empty six-again chain", changed[0] == 1 and state.chain.is_empty() and not state.closed)

func spawner_checks(tag: String) -> void:
	var y: float = game.building.spec.levels[1]
	for id in SPAWNERS:
		var s: Node3D = station(id)
		for i in 120:
			if s.spawned_cubes.size() >= 2: break
			await frames(1)
		check(tag+id+" keeps the source spigot and capacity 20, and cubes keep arriving (API)", s.dispersal == "spigot" and s.capacity == 20 and s.spawned_cubes.size() >= 2)
		var top := ray(s.global_position+Vector3.UP*.6, s.global_position+Vector3.DOWN*1.5)
		check(tag+id+" stands on its restored 1 m structure block (geometry)", not top.is_empty() and absf(top.position.y-(y+1.0)) < .08)
		var sound: Vector3 = s.wood_sound.global_position
		var spigot: Vector3 = s.to_global(s.spawn_position)
		print("SPAWNER ", tag, id, " cubes=", s.spawned_cubes.size(), " sound_ready=", s.sound_ready, " sound=", sound, " spigot=", spigot, " script=", s.get_script().resource_path)
		check(tag+id+" wood knock sounds at its own spigot, not near world zero (needs R4)", s.sound_ready and sound.distance_to(spigot) < .3)

# ── floor 2: Random_Rotate_Random_XYZ ───────────────────────────────────────

func hardware_checks(tag: String) -> void:
	var rig: Node3D = station("f2_hardware_entropy_decay_1_6")
	var paused: bool = rig._paused
	await stand_local(rig, Vector3(-2.6, 0, 1.1))
	await press(btn(rig, 1));await frames(6)
	check(tag+"entropy rig PAUSE with real pointer freezes the decay", rig._paused != paused)
	await press(btn(rig, 1));await frames(6)

func decay_checks(tag: String) -> void:
	var wall: Node3D = station("f2_random_decay_multimesh_6_10")
	var layers: Array = wall.get_children().filter(func(n): return n is MultiMeshInstance3D)
	check(tag+"decay study keeps the rotation comparison: two stacks fitted to 10 m, no drift or sink (API)", layers.size() == 2 and is_equal_approx(wall._stack_fit, 10.0) and is_zero_approx(wall.drift_strength) and is_zero_approx(wall.sink_distance))
	var panel: Node3D = wall.get_node("DecayControls")
	var active: bool = wall.decay_active
	await stand_local(wall, Vector3(0, 0, -2.2))
	await press(btn(panel, 0));await frames(6)
	check(tag+"decay TOGGLE with real pointer pauses the stacks", wall.decay_active != active)
	await press(btn(panel, 0));await frames(6)

func rotate_checks(tag: String) -> void:
	var cubes: Node3D = station("f2_RotateGridCubes_6_11")
	check(tag+"RotateGridCubes builds the compact 5 x 5 study at 0.75 m (API)", cubes._cubes.size() == 25 and is_equal_approx(cubes.spacing, .75) and not cubes.animate_slope)
	var turner: Node3D = station("f2_Random_Rotate_Random_XYZ_3_10")
	check(tag+"Random_Rotate_Random_XYZ finds no grid floor and turns nothing, as in the museum (API)", turner.multimesh_instance == null)

## Desktop only: a real Space press (the Void's jump) must not reach the source keyboard
## fallbacks on this floor that read ui_accept / KEY_SPACE.
func key_checks(tag: String) -> void:
	if xr: return
	var watched: Dictionary = {}
	for entry in game.building.content.data.floors[level].artifacts:
		match str(entry.artifact):
			"hardware_entropy_decay": watched[entry.id] = "_paused"
			"random_decay_multimesh": watched[entry.id] = "decay_active"
			"distribution_sampler": watched[entry.id] = "auto_sample"
			"galton_board": watched[entry.id] = "auto_drop"
	var before: Dictionary = {}
	for id in watched: before[id] = station(id).get(watched[id])
	var cloud: Node3D = station("f3_pixel_cloud_3_9") if level == 3 else null
	var first: Node = null
	if cloud != null and not cloud._generated.is_empty(): first = cloud._generated[0]
	game.place_player(game.spawn_for(level));await frames(10)
	await key(KEY_SPACE);await frames(40)
	for id in watched:
		check(tag+id+" ignores the Void's Space key (real key event; needs R2)", station(id).get(watched[id]) == before[id])
	if cloud != null:
		check(tag+"pixel cloud is not rebuilt by the Void's Space key (real key event; needs R2)", is_instance_valid(first) and not first.is_queued_for_deletion())

# ── floor 3: Random_Walk ────────────────────────────────────────────────────

func sheet_checks(tag: String) -> void:
	var rack: Node3D = station("f3_random_walk_collection_3_5")
	var y: float = game.building.spec.levels[3]
	var lows: Array = []
	for p in rack._papers: lows.append(bounds_of(p).position.y-y)
	print("SHEETS ", tag, "papers=", rack._papers.size(), " bottoms_above_floor=", lows)
	if not xr: fit_notes.append({"id": "f3_random_walk_collection_3_5", "root_height_m": rack.global_position.y-y, "sheet_bottoms_above_floor_m": lows, "museum_plinth_m": 0.75, "void_plinth": "not built"})
	check(tag+"rack keeps six law sheets above the slab at the plinth-deck height (API, geometry)", rack._papers.size() == 6 and lows.all(func(v): return v > .2))

func terrarium_checks(tag: String) -> void:
	var tank: Node3D = station("f3_random_walk_terrarium_9_5")
	check(tag+"terrarium builds its logbook stand with a named seed (API)", tank.stand == "logbook" and tank._logbook_root != null and tank.walk_seed >= 10000)
	check(tag+"terrarium keypad sits on the compact console 1.25 m out (needs R1)", tank.has_node("ExhibitStage/ReachConsole"))
	var two_d: Node3D = btn(tank._control_panel, 0)
	await stand_local(tank, Vector3(0, 0, 2.0))
	await press(two_d);await frames(6)
	check(tag+"terrarium 2D with real pointer switches the walk mode", int(tank.walk_mode) == 0)

func leash_checks(tag: String) -> void:
	var leash: Node3D = station("f3_random_walk_leash_15_5")
	var slider: Node3D = leash.find_child("Param_0", true, false)
	var handle: Node3D = slider.get_node("SliderOrigin/InteractableSlider/HandleOrigin/InteractableHandle")
	var before: float = leash.impulse_strength
	await stand_local(leash, Vector3(0, 0, 1.1))
	await pointer_drag(handle.global_position, handle.global_position+slider.global_basis.x.normalized()*.05)
	print("LEASH ", tag, before, " -> ", leash.impulse_strength)
	check(tag+"leash IMPULSE with real pointer drag changes the tug strength", absf(leash.impulse_strength-before) > .002)

func dot_checks(tag: String) -> void:
	var dot: Node3D = station("f3_random_draw_dot_6_8")
	var wandering: bool = dot.wandering
	await stand_local(dot, Vector3(0, 0, -1.5))
	await press(btn(dot, 0));await frames(6)
	check(tag+"HAND / RANDOM with real pointer switches the dot's walk", dot.wandering != wandering)
	await press(btn(dot, 0));await frames(6)

func rails_checks(tag: String) -> void:
	var rails: Node3D = station("f3_random_position_rails_13_8")
	var lever: Node3D = rails.lever
	var hinge: Node3D = lever.get_node("LeverOrigin/InteractableLever")
	var handle: Node3D = lever.get_node("LeverOrigin/InteractableLever/HandleOrigin/InteractableHandle")
	var shape: CollisionShape3D = handle.get_node("CollisionShape3D")
	var tick: int = rails.tick
	await stand_local(rails, Vector3(-2.7, 0, 1.6))
	if xr:
		var origin: Node3D = lever.get_node("LeverOrigin")
		var rest: Vector3 = origin.to_local(handle.global_position)
		if await input_grab(tag+"NEXT lever handle: ", handle, shape, .3, .05):
			for degrees in [4.0, 12.0, 20.0, 28.0, 36.0, 40.0]:
				await input_tip_to(handle, origin.to_global(Basis(Vector3.RIGHT, deg_to_rad(degrees))*rest))
				await frames(4)
			await release_grip()
	else:
		# The lever reads local-y pointer travel; the rails scale it 1.5x, so 0.12 m in
		# the world is about 36 degrees, past the 28-degree trigger (hopper pattern).
		var from: Vector3 = shape.global_position
		await pointer_drag(from, from-lever.global_basis.y.normalized()*.12)
	for i in 140:
		await frames(1)
		if rails.tick > tick: break
	print("RAILS ", tag, "angle=", hinge.hinge_position, " tick=", rails.tick, " committed=", rails.committed)
	check(tag+"NEXT lever by real "+("grip" if xr else "pointer drag")+" moves both carriages one draw", rails.tick == tick+1)
	var replay: Node3D = rails.get_node("RunReplay").find_child("Btn_1", true, false)
	await stand_local(rails, Vector3(2.73, 0, 1.6))
	await press(replay);await frames(10)
	check(tag+"REPLAY with real pointer restores the seeded start", rails.tick == 0 and rails.history.is_empty())

func walk128_checks(tag: String) -> void:
	var walk: Node3D = station(MOAT)
	var y: float = game.building.spec.levels[3]
	var count: int = walk._count_created_cubes()
	await frames(20)
	check(tag+"128 walk keeps its raised lattice (API)", walk._count_created_cubes() >= count and count > 0 and walk.current_step > 0)
	check(tag+"128 walk stands in its WALK / RETAIN glass with moat rails (needs R1)", walk.has_node("ExhibitStage/GlassSimulation"))
	# Under the moat ring: the source's 2.5 m basin, not the slab.
	var east := ray(Vector3(7.0, y+.5, -5), Vector3(7.0, y-3.2, -5))
	check(tag+"moat cell opens 2.5 m down to the basin floor (geometry)", not east.is_empty() and absf(east.position.y-(y-2.5)) < .15)
	# Real walking: from the works, over the north bridge, to the glass doorway.
	game.place_player(Vector3(0, y+.06, 5.0));await frames(20)
	var reached: bool = await move_to(Vector3(0, y+.06, .4), false, 240)
	print("MOAT ", tag, "reached=", reached, " at=", game.body.global_position)
	check(tag+"walking from the works over the moat bridge reaches the glass doorway (real walking)", reached)

# ── floor 4: Random_Gaussian ────────────────────────────────────────────────

func sampler_checks(tag: String) -> void:
	var s: Node3D = station("f4_distribution_sampler_5_6")
	check(tag+"sampler builds its cabinet with the wing readout and a named seed (API)", s._stand_root != null and s._readout_wing and s.sample_seed >= 10000)
	check(tag+"sampler keypads sit on the compact console 1.05 m out (needs R1)", s.has_node("ExhibitStage/ReachConsole"))
	var uniform: Node3D = btn(s._control_panel, 0)
	await stand_local(s, Vector3(-.3, 0, 1.9))
	await press(uniform);await frames(6)
	check(tag+"UNIFORM with real pointer switches the sampled law", int(s.distribution) == 0)

func splatter_checks(tag: String) -> void:
	var root: Node3D = station("f4_GaussianPaintSplatter_2_7")
	var canvas: Node = root.get_node("PaintSplatter")
	check(tag+"Gaussian splatter paints its own 640 px canvas at 0.65 scale (API)", canvas.img != null and canvas.img.get_width() == 640 and is_equal_approx(root.scale.x, .65))

func galton_checks(tag: String) -> void:
	var board: Node3D = station("f4_galton_board_2_10")
	var auto: bool = board.auto_drop
	var toggle: Node3D = btn(board._control_panel, 1)
	await stand_local(board, Vector3(.43, 0, 1.0))
	await press(toggle);await frames(6)
	check(tag+"galton AUTO with real pointer stops the automatic drop", board.auto_drop != auto)
	# Before our ball: did any auto-dropped ball reach a bin, and where are the ones in flight?
	print("GALTON_BEFORE ", tag, "dropped=", board._total_dropped, " bins=", board._bin_counts, " active=", board._active_balls.size(), " available=", board._available_balls.size())
	for old in board._active_balls:
		print("GALTON_ACTIVE ", tag, "local=", board.to_local(old.global_position), " v=", old.linear_velocity, " sleeping=", old.sleeping, " freeze=", old.freeze)
	# Source counting reads only the nine bin sensors (Area3D, mask 2; balls on layer 2).
	# The pool is built at the board origin, inside the centre sensor, so every pool ball
	# is counted once in bin 4 at build: measured 50 = max_active_balls, recorded below.
	var bins_before: Array = board._bin_counts.duplicate()
	var dropped_before: int = board._total_dropped
	# (a) The source path: five balls through the funnel and all eight peg rows. Where they
	# come to rest is the board's own physics; it is measured and recorded, not asserted.
	var landed: Array = await galton_batch(tag+"funnel", board, 5, -1.0)
	var span: float = absf(float(board._bin_divider_positions[0]))
	var inside: int = landed.filter(func(r): return absf(float(r.x)) < span).size()
	print("GALTON_COUNTS ", tag, "before=", bins_before, " (", dropped_before, ") after=", board._bin_counts, " (", board._total_dropped, ") inside_bins=", inside, "/", landed.size())
	if not xr: fit_notes.append({"id": "f4_galton_board_2_10", "pool_counted_at_build": bins_before, "funnel_rest": landed, "inside_bins": inside, "bin_span_m": span, "uncounted_side_gap_m": [span, board.board_width/2.0], "scale": board.scale.x})
	check(tag+"five funnel balls run the pegs down into the bin row within 5 s (physics outcome)", landed.size() == 5 and landed.all(func(r): return float(r.y) < board.bin_height))
	# (b) Counting, deterministic: one ball released inside the centre bin, below the last
	# peg row (0.199) and between its dividers (+-0.024), must enter bin 4's sensor.
	board._spawn_ball()
	var probe_ball: RigidBody3D = board._active_balls.back()
	probe_ball.global_position = board.to_global(Vector3(0, .16, 0)) # still statically frozen: moves at once
	var pid: int = probe_ball.get_instance_id()
	for i in 90:
		await frames(1)
		if board._ball_bin_assigned.has(pid): break
	print("GALTON_SENSOR ", tag, "bin=", board._ball_bin_assigned.get(pid, -1), " at=", board.to_local(probe_ball.global_position), " counts=", board._bin_counts)
	check(tag+"a ball released inside the centre bin is counted by bin 4's sensor (API placement, physics outcome)", int(board._ball_bin_assigned.get(pid, -1)) == 4)
	board.auto_drop = auto # restore the source state for the photos (not a check)

## Spawn `count` balls (the source's own _spawn_ball, 10 frames apart) and wait until each
## is counted or at rest. `from_y` >= 0 re-releases each at that board-local height (the
## museum-equivalent comparison); -1 keeps the source spawn. Returns one record per ball.
func galton_batch(label: String, board: Node3D, count: int, from_y: float) -> Array:
	var balls: Array = []
	for k in count:
		board._spawn_ball()
		var b: RigidBody3D = board._active_balls.back()
		if from_y >= 0.0:
			var p0: Vector3 = board.to_local(b.global_position)
			b.global_position = board.to_global(Vector3(p0.x, from_y, p0.z))
		elif k == 0:
			var local_y: float = board.to_local(b.global_position).y
			print("GALTON ", label, " spawn local y=", local_y, " funnel top=", board._funnel_top_y, " script=", board.get_script().resource_path)
			check(label+": galton ball enters at the funnel of the 1.5x board (API spawn; needs R5)", absf(local_y-(board._funnel_top_y+.02)) < .03)
		balls.append(b)
		await frames(10)
	var rest: Dictionary = {}
	for i in 300:
		await frames(1)
		var waiting := false
		for b in balls:
			var bid: int = b.get_instance_id()
			if rest.has(bid): continue
			var p: Vector3 = board.to_local(b.global_position)
			if board._ball_bin_assigned.has(bid) or (p.y < board.bin_height and (b.sleeping or b.linear_velocity.length() < .01)):
				rest[bid] = {"x": snappedf(p.x, .001), "y": snappedf(p.y, .001), "bin": int(board._ball_bin_assigned.get(bid, -1))}
			else: waiting = true
		if not waiting: break
	print("GALTON_REST ", label, " ", rest.values(), " bin_span=+-", absf(float(board._bin_divider_positions[0])), " board_half_width=", board.board_width/2.0)
	return rest.values()

## Diagnostic for the R5 decision: ten balls on the source's funnel path against ten
## re-released at board-local 0.38, where the museum's unscaled offset puts them on the
## 1.5x board (below the first three peg rows). Measurement only.
func galton_spread(tag: String) -> void:
	var board: Node3D = station("f4_galton_board_2_10")
	board.auto_drop = false
	var span: float = absf(float(board._bin_divider_positions[0]))
	for pair in [["funnel (R5)", -1.0], ["museum-equivalent 0.38", .38]]:
		var rows: Array = await galton_batch(tag+str(pair[0]), board, 10, float(pair[1]))
		var inside: int = rows.filter(func(r): return absf(float(r.x)) < span).size()
		print("GALTON_SPREAD ", tag, pair[0], " inside_bins=", inside, "/", rows.size(), " bins=", rows.map(func(r): return int(r.bin)))
		if not xr: fit_notes.append({"id": "f4_galton_board_2_10", "spread": pair[0], "inside_bins": inside, "of": rows.size(), "rest": rows})
		await frames(100) # let counted balls recycle back into the pool
	board.auto_drop = true

func comparator_checks(tag: String) -> void:
	var c: Node3D = station("f4_distribution_comparator_8_10")
	var before: Array = bar_heights(c)
	await stand_local(c, Vector3(0, 0, 1.2))
	await press(btn(c, 0));await frames(6)
	check(tag+"comparator RESAMPLE with real pointer redraws the three histograms", bar_heights(c) != before)

func bar_heights(c: Node3D) -> Array:
	var out: Array = []
	for column in c._bars:
		for bar in column: out.append(bar.mesh.size.y)
	return out

## Diagnostic: the SAMPLES slider looks for "DISTRIBUTIONS/Param_0", but its panel is named
## RackPanel (static reading). Measurement only, not a check.
func comparator_slider_report(tag: String) -> void:
	var c: Node3D = station("f4_distribution_comparator_8_10")
	var slider: Node3D = c.find_child("Param_0", true, false)
	var handle: Node3D = slider.get_node("SliderOrigin/InteractableSlider/HandleOrigin/InteractableHandle")
	var before: int = c._sample_count
	await pointer_drag(handle.global_position, handle.global_position+slider.global_basis.x.normalized()*.05)
	print("COMPARATOR_SLIDER ", tag, "sample_count ", before, " -> ", c._sample_count, " slider=", slider.get_normalized_value())

# ── floor 5: Random_Mushrooms ───────────────────────────────────────────────

func bubbles_checks(tag: String) -> void:
	var b: Node3D = station("f5_bubbles_random_3_5")
	check(tag+"bubble dish runs at 0.25 scale with rising bubbles (API)", is_equal_approx(b.scale.x, .25) and b.active_bubbles.size() > 0)

func mushroom_checks(tag: String) -> void:
	var m: Node3D = station("f5_mushrooms_8_11")
	check(tag+"mushrooms build the 6 m specimen bed, table and three edibles (API)", m.stand == "specimen" and is_equal_approx(m.meadow_size, 6.0) and m._stand_root != null and m.edible_count() == 3)
	check(tag+"mushrooms stand in the POPULATION / DIFFERENCE glass with a console 5.1 m out (needs R1)", m.has_node("ExhibitStage/GlassSimulation") and m.has_node("ExhibitStage/ReachConsole"))
	var seed_before: int = m.population_seed
	await stand_local(m, Vector3(.3, 0, 5.8))
	await press(btn(m._panel, 4));await frames(10)
	check(tag+"NEW SEED with real pointer regrows a different population", m.population_seed != seed_before)
	var edible: Array = m._edibles.filter(func(x): return is_instance_valid(x))
	if edible.is_empty():
		check(tag+"mushroom bed has an edible to pick", false);return
	var food: Node3D = edible[0]
	var outward: Vector3 = food.global_position-m.global_position
	outward.y = 0
	var at: Vector3 = food.global_position+outward.normalized()*.8
	at.y = game.building.spec.levels[level]+.06
	game.place_player(at);await frames(20)
	if await input_grab(tag+"edible mushroom: ", food, shape_of(food), .3, .08):
		await frames(10)
		await release_grip()

func arrivals_checks(tag: String) -> void:
	var a: Node3D = station("f5_silhouette_arrivals_13_17")
	await stand_local(a, Vector3(0, 0, -2.4))
	await press(btn(a, 2));await frames(4)
	check(tag+"REPLAY with real pointer empties the arrivals", a.people.is_empty() and a.history.is_empty())
	await press(btn(a, 0));await frames(4)
	check(tag+"ARRIVE with real pointer brings a silhouette to a free slot", a.people.size() >= 1 and a.history.size() == a.people.size())

func couture_checks(tag: String) -> void:
	var c: Node3D = station("f5_couture_comparison_8_20")
	await stand_local(c, Vector3(0, 0, -2.5))
	await press(btn(c, 0));await frames(6)
	check(tag+"couture NEXT SEED with real pointer deals three new seeds", c.base_seed == 44)
	await press(btn(c, 2));await frames(6)
	check(tag+"couture RESET with real pointer returns to seeds 41-43", c.base_seed == 41 and c.variant == 0)

# ── fit ──────────────────────────────────────────────────────────────────────

## Floor-3 moat basin as world boxes hanging below floor 3's slab into floor 4's storey.
func moat_boxes() -> Array:
	var spec = game.building.spec
	var basin: Dictionary = game.building.content.data.floors[3].get("basin", {})
	var y3: float = spec.levels[3]
	var boxes: Array = []
	for r in basin.get("rects", []):
		var depth: float = float(basin.depth)
		boxes.append(AABB(Vector3(float(r[0]), y3-depth-.2, float(r[1])), Vector3(float(r[2]), depth+.2-float(spec.slab_thickness), float(r[3]))))
	return boxes

## Whole shaft openings, the arrival, the floor sign (at this trial's position) and, on
## floor 4, the floor-3 moat basin that hangs into this storey.
func fit_checks(tag: String) -> void:
	var spec = game.building.spec
	var y: float = spec.levels[level]
	var keep_out: Array = []
	for shaft in spec.shafts:
		keep_out.append(["shaft "+str(shaft.name), AABB(Vector3(float(shaft.x)-float(spec.shaft_width)/2.0, y-.5, -float(spec.shaft_depth)/2.0), Vector3(float(spec.shaft_width), 6.5, float(spec.shaft_depth)))])
	keep_out.append(["arrival", AABB(Vector3(-1, y, 11), Vector3(2, 2.2, 2))])
	var sign_xz: Array = spec.get("floor_sign_positions", {}).get(str(level), [3.5, -7.8])
	keep_out.append(["floor sign", AABB(Vector3(float(sign_xz[0])-1.85, y+.525, float(sign_xz[1])-.06), Vector3(3.7, 1.65, .12))])
	if level == 4:
		for box in moat_boxes(): keep_out.append(["floor-3 moat basin", box])
	var hits: Array = []
	for entry in game.building.content.data.floors[level].artifacts:
		var boxes: Array = [];geometry(station(entry.id), boxes)
		if entry.id == MOAT:
			# The source ring is 15 m across (12 m glass + 3 m); the gap between the shafts
			# is 15.0 m. Its side rails are measured on their own below; everything else
			# in the exhibit stays under the strict test.
			var stage: Node = station(MOAT).get_node_or_null("ExhibitStage")
			var rails: Array = []
			if stage != null:
				for child in stage.get_children():
					if child is MeshInstance3D: rails.append(child.global_transform*child.get_aabb())
			boxes = boxes.filter(func(b): return not rails.has(b))
			var reach := 0.0
			for b in rails:
				if b.end.z < -3.0 or b.position.z > 3.0: continue
				for shaft in spec.shafts:
					var inner: float = float(shaft.x)-signf(float(shaft.x))*float(spec.shaft_width)/2.0
					reach = maxf(reach, (b.end.x-inner) if float(shaft.x) > 0 else (inner-b.position.x))
			print("MOAT_RAILS ", tag, "rails=", rails.size(), " reach into shaft openings %.3f m" % reach)
			if not xr: fit_notes.append({"id": MOAT, "moat_rails": rails.size(), "rail_reach_into_each_shaft_m": reach, "ring_width_m": 15.0, "gap_between_shafts_m": 15.0})
			check(tag+"moat rails overhang each shaft opening by at most 0.03 m (measured; source 15 m ring vs 15 m gap)", reach <= .03)
		for item in keep_out:
			var zone: AABB = item[1]
			var inside: Array = boxes.filter(func(b): return shrink_mm(b).intersects(zone))
			if not inside.is_empty():
				hits.append(entry.id+" / "+str(item[0]))
				print("FIT_BOX ", tag, entry.id, " / ", item[0], " ", inside.slice(0, 3))
	print("FIT ", tag, "floor ", level, " ", hits)
	if not xr and not hits.is_empty(): fit_notes.append({"floor": level, "enters": hits})
	check(tag+"placement geometry stays out of shafts, arrival, floor sign"+(" and floor-3 moat basin" if level == 4 else ""), hits.is_empty())

# ── photos (desktop, inside the tower) ──────────────────────────────────────

func capture_floor() -> void:
	var y: float = game.building.spec.levels[level]
	match level:
		1:
			await photo("01-random-cubes-arrival-eye", Vector3(0, y+1.65, 12.5), Vector3(-4, y+1.0, 6))
			await photo("02-dice-coin-column", Vector3(-4, y+2.2, 12), Vector3(-5, y+1.0, 8))
			await photo("03-spawners-and-profile-field", Vector3(1, y+2.6, 7), Vector3(-4, y+.8, 1))
		2:
			await photo("04-rotate-hall-arrival-eye", Vector3(0, y+1.65, 12.5), Vector3(1, y+2.0, 2))
			await photo("05-decay-wall-and-rig", Vector3(1, y+2.0, 9), Vector3(-1, y+2.4, 2))
			await photo("06-rotate-grid-behind-wall", Vector3(-1, y+1.8, -5), Vector3(-1, y+.5, 0))
		3:
			await photo("07-random-walk-arrival-eye", Vector3(0, y+1.65, 12.5), Vector3(0, y+1.2, 3))
			await photo("08-terrarium-leash-collection", Vector3(0, y+2.0, 10.5), Vector3(0, y+1.0, 6.5))
			await photo("09-moat-and-glass", Vector3(5, y+3.2, 6), Vector3(0, y+.2, -4))
		4:
			await photo("10-gaussian-arrival-eye", Vector3(0, y+1.65, 12.5), Vector3(0, y+1.2, 4))
			await photo("11-galton-splatter-comparator", Vector3(0, y+1.8, 8.5), Vector3(0, y+1.2, 2))
		5:
			await photo("12-mushrooms-arrival-eye", Vector3(0, y+1.65, 12.5), Vector3(0, y+1.0, 2))
			await photo("13-glass-bed-and-console", Vector3(4, y+2.6, 9), Vector3(0, y+.4, 1))
			await photo("14-arrivals-and-couture", Vector3(-1, y+1.8, -1.5), Vector3(-2, y+1.0, -7))
