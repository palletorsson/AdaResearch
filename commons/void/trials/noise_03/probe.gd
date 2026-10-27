extends "res://tools/probes/void_transfer_probe.gd"
## Batch 25 (worker D): Noise_Box (1), Noise_Space_10 (2), Noise_Perlin_Simplex (3) and the
## optional Lab_Path (4). Visit, inspection, shaft descent, residency and retry come from the
## shared probe. Real input uses the shared input_* helpers and the press/pointer_drag
## variants from randomness_03; API, geometry and measurement checks say so in their names.

const SHELLS := ["f1_box_shell_space_17_19", "f1_box_atrium_space_51_19"]
const FIELD := "f2_noise_space_6_6"
const SIMPLEX := "f3_simplex_noise_3_13"
const PERLIN := "f3_perlin_noise_8_13"
const TERRAIN := "f3_perlin_noise_terrain_2_17"
const PORTAL := "f3_configurable_portal_9_19"
const SEED := 20260910

func debug_cases() -> Dictionary:
	return {"bounds-1": 1, "bounds-2": 2, "bounds-3": 3, "bounds-4": 4,
		"shells": 1, "field": 2, "scale": 2, "hand-lifecycle": 2, "pair": 3, "arch": 3, "portal": 3}

func run_debug_case(name: String, tag: String) -> void:
	match name:
		"bounds-1", "bounds-2", "bounds-3", "bounds-4":
			inspect_floor(tag)
			await frames(30)
			await fit_checks(tag)
			report_bounds(tag)
		"shells": await shell_checks(tag)
		"field": await field_checks(tag)
		"scale": await scale_checks(tag)
		"hand-lifecycle": await hand_lifecycle_checks(tag)
		"pair": await frames(20);await pair_checks(tag)
		"arch": await frames(20);await arch_checks(tag)
		"portal": await portal_checks(tag)

func hand_lifecycle_checks(tag: String) -> void:
	await scale_checks(tag)
	if xr: return
	var hand = game.body.desktop_pointer
	var parent: Node = hand.get_parent()
	var holder := Node3D.new()
	game.add_child(holder)
	var source = hand.ability
	check(tag+"catalyst source remains bound after actual scale round trip", is_instance_valid(source) and source.desktop_source == hand)
	hand.set_enabled(false)
	hand.reparent(holder)
	hand.reparent(parent)
	await frames(2)
	check(tag+"deliberately disabled hand stays disabled across reparent (API lifecycle)", not hand.enabled)
	hand.set_enabled(true)
	holder.queue_free()
	check(tag+"restored hand is active and catalyst ownership preserved", hand._active() and is_instance_valid(source) and source.desktop_source == hand)

func focused_checks(tag: String) -> void:
	check(tag+"standard floor "+str(level), game.building.spec.width == 42 and game.building.spec.depth == 32 and game.building.spec.storey_height == 6)
	await fit_checks(tag)
	match level:
		1:
			await shell_checks(tag)
		2:
			await field_checks(tag)
			await scale_checks(tag)
		3:
			await pair_checks(tag)
			await arch_checks(tag)
			await portal_checks(tag)
		4:
			check(tag+"Lab_Path keeps its one source work, the dark sphere (API)", station("f4_dark_sphere_2_2").get_script() != null)
	game.place_player(game.spawn_for(level));await frames(15)

# ── helpers (randomness_03 pattern) ─────────────────────────────────────────

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

## Stand 'distance' beyond a control, away from its artifact, on this floor.
func stand_near(control: Node3D, owner: Node3D, distance: float = 1.2) -> void:
	var away: Vector3 = control.global_position-owner.global_position
	away.y = 0
	if away.length() < .05: away = owner.global_basis.z
	var at: Vector3 = control.global_position+away.normalized()*distance
	at.y = game.building.spec.levels[level]+.06
	game.place_player(at);await frames(20)

## Real pointer press for rack buttons (InteractableAreaButton) and areas whose own
## CollisionShape3D is the target.
func press(button: Node3D) -> void:
	var rack: bool = button.has_node("InteractableAreaButton/CollisionShape3D")
	if rack and xr:
		await super.press(button);return
	var target: Vector3 = button.get_node("InteractableAreaButton/CollisionShape3D").global_position if rack \
		else button.get_children().filter(func(n): return n is CollisionShape3D)[0].global_position
	if not xr:
		# Same aim, frames and clicks as the shared press, with the hand traced
		# after the final aim and before the click.
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		await input_aim_camera(target, 25)
		trace_pointer(str(button.get_path()), target)
		var waits: Array = [6, 8] if rack else [8, 8]
		for k in 2:
			var e := InputEventMouseButton.new();e.button_index = MOUSE_BUTTON_LEFT;e.pressed = k == 0
			Input.parse_input_event(e);await frames(waits[k])
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
		trace_pointer("drag from "+str(from), from)
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

## Desktop hand state just before a click: what _active() reads, its press/lock/hover
## state, the scale of the view it sits in, its own RayCast3D hit and an independent
## pointer-mask ray (19/21/23, areas and bodies) toward the target. Measurement only.
func trace_pointer(label: String, at: Vector3) -> void:
	var hand = game.body.desktop_pointer
	var cast: RayCast3D = hand.get_node_or_null("PointerRay")
	var raw: Object = cast.get_collider() if cast != null and cast.is_colliding() else null
	var eye: Vector3 = game.camera.global_position
	var q := PhysicsRayQueryParameters3D.create(eye, eye+(at-eye)*1.5, (1 << 18) | (1 << 20) | (1 << 22))
	q.collide_with_areas = true
	q.exclude = [game.body.get_rid()]
	var direct: Dictionary = game.get_world_3d().direct_space_state.intersect_ray(q)
	var node_name := func(o): return str((o as Node).get_path()) if is_instance_valid(o) and o is Node else "none"
	print("PRESS_TRACE ", label,
		" hand_enabled=", hand.enabled, " active=", hand._active(), " hand_parent=", hand.get_parent().name,
		" mouse_captured=", Input.mouse_mode == Input.MOUSE_MODE_CAPTURED, " cam_current=", game.camera.current,
		" ready=", game.ready_for_play, " recovering=", game.recovering, " returning=", game.returning,
		" cam_scale=", game.camera.global_basis.get_scale(), " cam_parent=", game.camera.get_parent().name,
		" body_scale_meta=", game.body.get_meta("ada_body_scale", 1.0),
		" is_pressed=", hand._is_pressed, " locked=", node_name.call(hand._locked_target), " last=", node_name.call(hand._last_target),
		" raw=", node_name.call(raw), " direct=", node_name.call(direct.get("collider")),
		" reach=", eye.distance_to(at), " aim_error_deg=", rad_to_deg((-game.camera.global_basis.z).angle_to(at-eye)))

## Drive the real locomotion toward a horizontal target until done() or a bound.
## Unlike move_to it asserts nothing about height, for walks that climb or fall.
func drive_until(target: Vector3, done: Callable, limit: int = 240) -> bool:
	for step in limit:
		var at: Vector3 = game.body.global_position
		var offset := Vector2(target.x-at.x, target.z-at.z)
		axes(offset.normalized() if offset.length() > .06 else Vector2.ZERO)
		await frames(1)
		if done.call(): axes(Vector2.ZERO);await frames(6);return true
		if game.recovering: break
	axes(Vector2.ZERO);await frames(6)
	return false

# ── fit: whole shaft openings, columns, arrival and the default floor sign ──

func fit_checks(tag: String) -> void:
	var spec = game.building.spec
	var y: float = spec.levels[level]
	var keep_out: Array = []
	for shaft in spec.shafts:
		keep_out.append(["shaft "+str(shaft.name), AABB(Vector3(float(shaft.x)-float(spec.shaft_width)/2.0, y-.5, -float(spec.shaft_depth)/2.0), Vector3(float(spec.shaft_width), 6.5, float(spec.shaft_depth)))])
	keep_out.append(["arrival", AABB(Vector3(-1, y, 11), Vector3(2, 2.2, 2))])
	var sign_xz: Array = spec.get("floor_sign_positions", {}).get(str(level), [3.5, -7.8])
	keep_out.append(["floor sign", AABB(Vector3(float(sign_xz[0])-1.85, y+.525, float(sign_xz[1])-.06), Vector3(3.7, 1.65, .12))])
	for cx in spec.get("column_x", []):
		for cz in spec.get("column_z", []):
			keep_out.append(["column %d,%d" % [int(cx), int(cz)], AABB(Vector3(float(cx)-.45, y, float(cz)-.45), Vector3(.9, 5.6, .9))])
	var hits: Array = []
	for entry in game.building.content.data.floors[level].artifacts:
		var boxes: Array = [];geometry(station(entry.id), boxes)
		for item in keep_out:
			var zone: AABB = item[1]
			var inside: Array = boxes.filter(func(b): return shrink_mm(b).intersects(zone))
			if not inside.is_empty():
				hits.append(entry.id+" / "+str(item[0]))
				print("FIT_BOX ", tag, entry.id, " / ", item[0], " ", inside.slice(0, 3))
	print("FIT ", tag, "floor ", level, " ", hits)
	if not xr and not hits.is_empty(): fit_notes.append({"floor": level, "enters": hits})
	check(tag+"placement geometry stays out of shafts, columns, arrival and floor sign (measured)", hits.is_empty())

# ── floor 1: Noise_Box's two room-scale shells, exterior specimens ───────────

## The shells are ~24-27 x 29 x 10 m (mesh BOUNDS 27 x 11 x 29) and cannot share the
## 42 m floor or stand over a shaft without filling it. They stand beside the tower with
## their source config (floor:false). Geometry and measurement only: no floor = no walk-in.
func shell_checks(tag: String) -> void:
	var y: float = game.building.spec.levels[level]
	var tower := AABB(Vector3(-21, y-.5, -16), Vector3(42, 6.5, 32))
	for id in SHELLS:
		var shell: Node3D = station(id)
		var generated: Node3D = shell.get("generated")
		var surface: MeshInstance3D = generated.get_node_or_null("Membrane/Surface") if generated != null else null
		var membrane: StaticBody3D = generated.get_node_or_null("Membrane") if generated != null else null
		check(tag+id+" builds its box membrane with collision and no floor disc: floor:false consumed (API)",
			surface != null and surface.mesh != null and membrane != null and membrane.get_child_count() >= 2 and not shell.create_floor and not generated.has_node("Floor") and shell.box_cells)
		if generated == null: continue
		# The source's shared entrance: a 3.2 m tube along local +z, cut through collision.
		var hit := ray(shell.to_global(Vector3(0, 1.2, 15.0)), shell.to_global(Vector3(0, 1.2, .3)))
		check(tag+id+" entrance passage is open to the centre at 1.2 m (geometry ray)", hit.is_empty())
		var shut := ray(shell.to_global(Vector3(0, 1.2, -15.0)), shell.to_global(Vector3(0, 1.2, -.3)))
		check(tag+id+" opposite side is closed membrane (geometry ray hits)", not shut.is_empty())
		var b: AABB = bounds_of(shell)
		check(tag+id+" exterior specimen stays clear of the tower footprint (measured)", b.size != Vector3.ZERO and not shrink_mm(b).intersects(tower))
		var note := {"id": id, "layout": int(shell.layout), "seed": shell.seed_value, "build_msec_last": shell.build_msec,
			"world_x": [b.position.x, b.end.x], "world_z": [b.position.z, b.end.z], "y_above_floor": [b.position.y-y, b.end.y-y],
			"lights": generated.find_children("*", "OmniLight3D", true, false).size()}
		print("SHELL ", tag, note)
		if not xr: fit_notes.append(note)

# ── floor 2: Noise_Space_10, the stand:walk field ───────────────────────────

func field_checks(tag: String) -> void:
	var ground: Node3D = station(FIELD)
	var study: Node3D = ground.walk_study
	var y: float = game.building.spec.levels[level]
	check(tag+"noise space builds the stand:walk encounter: 8 x 8 m field at 1 m, walk study, trail and scale portals (API)",
		ground.stand == "walk" and study != null and study.walked_trail != null and study.scale_portals != null and ground.walk_heights.size() == 81*81 and is_equal_approx(ground.height_scale, .25))
	# Real walking: slab -> source wp wedge -> 1 m stone margin -> the field.
	game.place_player(ground.to_global(Vector3(0, .06, -7.4)));await frames(25)
	var on_margin: bool = await move_to(ground.to_global(Vector3(0, 1.0, -4.4)), false, 300)
	check(tag+"real walking climbs the wp wedge onto the 1 m margin at the entry gate", on_margin)
	var centre: Vector3 = ground.to_global(Vector3(0, ground.walk_height_at(Vector2.ZERO), 0))
	var on_field: bool = await move_to(centre, false, 300)
	await frames(20)
	var trail: int = study.walked_trail.points.size()
	print("FIELD ", tag, "margin=", on_margin, " field=", on_field, " at=", ground.to_local(game.body.global_position), " trail=", trail)
	check(tag+"real walking crosses onto the field and the trail records the supported walk", on_field and trail > 0)
	# HEIGHT refuses while the visitor stands on the field (source rule).
	var controls: Node3D = study.get_node("Controls")
	var height_button: Node3D = controls.find_child("Btn_0", true, false)
	await press(height_button);await frames(10)
	check(tag+"HEIGHT with real pointer is refused while standing on the field", study.blocked and is_equal_approx(ground.height_scale, .25))
	# From outside the field the same press regenerates the ground.
	await stand_near(height_button, ground, 1.6)
	await press(height_button);await frames(10)
	check(tag+"HEIGHT with real pointer from outside regenerates the field at 0.65 and clears the trail", not study.blocked and is_equal_approx(ground.height_scale, .65) and study.walked_trail.points.is_empty())
	await press(controls.find_child("Btn_1", true, false));await frames(8)
	var route_b: bool = study.route_index == 1
	check(tag+"ROUTE with real pointer proposes route B", route_b)
	await press(controls.find_child("Btn_3", true, false));await frames(10)
	check(tag+"RESET with real pointer restores height 0.25 and route A", route_b and is_equal_approx(ground.height_scale, .25) and study.route_index == 0)

## The SMALLER door on the north margin shrinks the visitor 1:8 (camera, collider and,
## in XR, XRServer.world_scale) and walking off the field restores it. Real walking both ways.
func scale_checks(tag: String) -> void:
	var ground: Node3D = station(FIELD)
	var portals: Node3D = ground.walk_study.scale_portals
	var start_scale: float = XRServer.world_scale
	var capsule: CollisionShape3D = null
	if not xr:
		for child in game.body.get_children():
			if child is CollisionShape3D: capsule = child
	var radius: float = capsule.shape.radius if capsule != null else 0.0
	var hand = null if xr else game.body.desktop_pointer
	var had_source: bool = hand != null and is_instance_valid(hand.ability) and hand.ability.desktop_source == hand
	# Inside the field, just south of the door; walk north through it.
	game.place_player(ground.to_global(Vector3(-2, ground.walk_height_at(Vector2(-2, -3.3))+.06, -3.3)));await frames(30)
	var entered: bool = await drive_until(ground.to_global(Vector3(-2, 1, -4.6)), func(): return portals.active, 200)
	await frames(15)
	var meta_scale: float = float(game.body.get_meta("ada_body_scale", 1.0))
	print("SCALE ", tag, "entered=", entered, " transitions=", portals.transitions, " meta=", meta_scale, " world_scale=", XRServer.world_scale, " at=", ground.to_local(game.body.global_position))
	if xr:
		check(tag+"walking through SMALLER shrinks the XR visitor 1:8 (world_scale)", entered and is_equal_approx(XRServer.world_scale, start_scale*.125) and is_equal_approx(meta_scale, .125))
	else:
		check(tag+"walking through SMALLER shrinks the desktop visitor 1:8 (camera in scaled view, collider)", entered and is_equal_approx(meta_scale, .125) and game.camera.get_parent() != game.body and capsule != null and capsule.shape.radius < radius*.2)
	# Walk off the field's edge (|local| > 4.12): the source restores and relocates.
	var restored: bool = await drive_until(ground.to_global(Vector3(-2, 1, -4.6)), func(): return not portals.active, 420)
	await frames(15)
	if not restored:
		print("SCALE ", tag, "walk-off did not restore; API restore to keep the floor usable")
		portals.restore();await frames(10)
	var back: bool = not game.body.has_meta("ada_body_scale") and is_equal_approx(XRServer.world_scale, start_scale)
	if not xr: back = back and game.camera.get_parent() == game.body and capsule != null and is_equal_approx(capsule.shape.radius, radius)
	check(tag+"walking off the field restores the visitor's size (real walking)", restored and back)
	if hand == null: return
	# Host seam (REQUESTS R4): the portal reparents the camera and the DesktopHand into
	# a scaled view and back. DesktopHand._exit_tree() calls set_enabled(false) and
	# nothing re-enables it, so after one SMALLER the mouse hand is dead until a retry
	# (first full acceptance: every floor-3 desktop press had no effect).
	trace_pointer("after SMALLER/restore", game.camera.global_position-game.camera.global_basis.z)
	var source_ok: bool = not had_source or (is_instance_valid(hand.ability) and hand.ability.desktop_source == hand)
	check(tag+"the mouse hand is still enabled after the scale portal round trip (host; needs R4)", hand.enabled and source_ok)
	if not (hand.enabled and source_ok):
		# Keep the later floors testing their own controls; this is not a pass.
		# desktop_hand.gd owns `enabled` (the base pointer declares none); set_enabled(true)
		# only assigns it, and _active() then also needs ready_for_play, no recovery or
		# return, the visitor camera current and the mouse captured.
		print("PROBE_RESTORE ", tag, "before: enabled=", hand.enabled, " active=", hand._active(), " catalyst_source=", source_ok)
		hand.set_enabled(true)
		if had_source and is_instance_valid(hand.ability): hand.ability.desktop_source = hand
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		await frames(4)
		var source_back: bool = not had_source or (is_instance_valid(hand.ability) and hand.ability.desktop_source == hand)
		print("PROBE_RESTORE ", tag, "after: enabled=", hand.enabled, " active=", hand._active(), " catalyst_source=", source_back)
		trace_pointer("after PROBE_RESTORE", game.camera.global_position-game.camera.global_basis.z)
		# Read back, labelled as the probe's own repair (API), never as the host fix.
		check(tag+"probe's API restore of the mouse hand took (read back; R4 still pending)", hand.enabled and hand._active() and source_back)

# ── floor 3: Noise_Perlin_Simplex, the controlled pair ──────────────────────

func pair_checks(tag: String) -> void:
	var s: Node3D = station(SIMPLEX)
	var p: Node3D = station(PERLIN)
	var y: float = game.building.spec.levels[level]
	check(tag+"pair keeps the comparison contract: seed 20260910, 8-cell fields, shared ramp, front panels (API)",
		s.current_seed() == SEED and p.current_seed() == SEED and s.noise_field.noise_field_size == 8 and p.noise_field.noise_field_size == 8
		and s.ramp == "shared" and p.ramp == "shared" and s._panel_node != null and p._panel_node != null)
	check(tag+"each display draws its own basis, read off the generator (API)", s.basis_name() == "simplex" and p.basis_name() == "perlin")
	check(tag+"front panels stand where the 8-cell field puts them, z -2.7 (needs R1 configure_before_ready)",
		s._panel_node != null and p._panel_node != null and absf(s._panel_node.position.z+2.7) < .01 and absf(p._panel_node.position.z+2.7) < .01)
	var study: Node3D = s.get_node_or_null("PairStudy")
	check(tag+"pair study binds the twin, the witness plate and two arches (needs R1)",
		study != null and study.pair.size() == 2 and study.pair[1] == p and s.has_node("Witness/Case") and study.arches.size() == 2)
	var anchor: Node3D = station(TERRAIN).get_node_or_null("PerlinNoiseTerrain")
	check(tag+"terrain carries the hall's stone plinth, collider and caption (needs R2 anchor)", anchor != null and anchor.get_child_count() >= 3)
	print("PAIR ", tag, "simplex=", s.contract(), " perlin=", p.contract(), " witness=", s.witness_state().get("differing", []))
	if s._panel_node == null or p._panel_node == null: return
	# Real pointer: REGEN draws a named new seed, REPLAY returns to the declared one.
	await stand_near(s._panel_node.find_child("Btn_0", true, false), s, 1.2)
	await press(s._panel_node.find_child("Btn_0", true, false));await frames(8)
	var drawn: int = s.current_seed()
	check(tag+"REGEN with real pointer draws a new recorded seed", drawn != SEED)
	await press(s._panel_node.find_child("Btn_1", true, false));await frames(8)
	# Not vacuous: only counts when REGEN had really moved the seed away.
	check(tag+"REPLAY with real pointer returns to seed 20260910 from the drawn one", drawn != SEED and s.current_seed() == SEED)
	# Real pointer drag on the perlin FREQ slider handle (layer 19).
	var slider: Node3D = p._panel_node.find_child("Param_0", true, false)
	var handle: Node3D = slider.get_node("SliderOrigin/InteractableSlider/HandleOrigin/InteractableHandle")
	await stand_near(handle, p, 1.2)
	var f0: float = float(p.contract().frequency)
	await pointer_drag(handle.global_position, handle.global_position+slider.global_basis.x.normalized()*.08)
	await frames(6)
	print("PAIR ", tag, "perlin FREQ ", f0, " -> ", p.contract().frequency)
	check(tag+"FREQ slider dragged with real pointer changes the perlin field's frequency", absf(float(p.contract().frequency)-f0) > .1)
	if study == null or study.pair.size() != 2: return
	# The hall's own comparison controls.
	var controls: Node3D = study.get_node("Controls")
	game.place_player(Vector3(controls.global_position.x+.25, y+.06, controls.global_position.z+1.4));await frames(20)
	var sample0: int = study.sample_index
	await press(controls.find_child("Btn_0", true, false));await frames(8)
	check(tag+"SAMPLE with real pointer moves the shared address", study.sample_index == (sample0+1)%5)
	await press(controls.find_child("Btn_1", true, false));await frames(10)
	var flat: bool = study.plate and s.readout == "plate" and p.readout == "plate"
	check(tag+"VIEW with real pointer lays both fields flat (plate)", flat)
	await press(controls.find_child("Btn_1", true, false));await frames(10)
	check(tag+"VIEW again restores relief on both", flat and not study.plate and s.readout == "relief" and p.readout == "relief")

## Real walking through the simplex's noise arch, the hall's walk-through surface.
func arch_checks(tag: String) -> void:
	var s: Node3D = station(SIMPLEX)
	var arch: Node3D = s.get_node_or_null("NoiseArch")
	check(tag+"simplex wears its walk-through noise arch (needs R1)", arch != null)
	if arch == null: return
	var y: float = game.building.spec.levels[level]
	var axis: Vector3 = arch.global_position
	game.place_player(Vector3(axis.x, y+.06, axis.z+2.2));await frames(25)
	var inside: bool = await move_to(Vector3(axis.x, y+.06, axis.z), false, 240)
	var occupied: bool = arch.occupied()
	var through: bool = await move_to(Vector3(axis.x, y+.06, axis.z-1.9), false, 240)
	print("ARCH ", tag, "axis=", axis, " inside=", inside, " occupied=", occupied, " through=", through)
	check(tag+"real walking passes through the arch, which knows it is occupied", inside and occupied and through)

## Source config: inactive, labelled "not connected"; nothing in the Void answers load_map.
func portal_checks(tag: String) -> void:
	var portal: Node3D = station(PORTAL)
	var y: float = game.building.spec.levels[level]
	# What a press of this door would reach is reported, not asserted: the label says
	# "not connected" and the token sets active:false, so no branch is ever taken.
	var route: Dictionary = portal.resolve_destination()
	check(tag+"portal keeps its source config: inactive, labelled \"not connected\", destination Lab_Path (API)",
		not portal.active and portal.destination_map == "Lab_Path" and portal.label_text == "Lab Path - not connected")
	print("PORTAL ", tag, "areas=", portal.find_children("*", "Area3D", true, false).size(), " surfaces=", portal.find_children("PortalSurface*", "MeshInstance3D", true, false).size(), " route=", route)
	var checkpoint: int = game.checkpoint
	game.place_player(portal.to_global(Vector3(0, .06, 1.3)));await frames(20)
	var through: bool = await move_to(portal.to_global(Vector3(0, .06, -1.3)), false, 200)
	await frames(30)
	check(tag+"real walking through the inactive portal changes nothing", through and game.checkpoint == checkpoint and not game.recovering and absf(game.body.global_position.y-y) < .2)

func capture_floor() -> void:
	var y: float = game.building.spec.levels[level]
	match level:
		1:
			await photo("01-noise-box-arrival-eye", Vector3(0, y+1.65, 12.5), Vector3(0, y+1.4, -4))
			await photo("02-shell-beside-east-edge", Vector3(18, y+2.2, 8), Vector3(35, y+3, -6))
			await photo("03-atrium-beside-west-edge", Vector3(-18, y+2.2, 8), Vector3(-35, y+3, -6))
		2:
			await photo("04-noise-space-arrival-eye", Vector3(-1.5, y+1.65, 15), Vector3(-6.5, y+1.2, 8.2))
			await photo("05-noise-space-entry-wedge", Vector3(-2.5, y+2.6, 15.3), Vector3(-6.5, y+1.0, 11.5))
		3:
			await photo("06-perlin-simplex-arrival-eye", Vector3(0, y+1.65, 12), Vector3(-0.5, y+1.4, 1))
			await photo("07-pair-panels-and-witness", Vector3(-0.5, y+1.7, 6.8), Vector3(-0.5, y+1.3, 1.5))
			await photo("08-terrain-sphere-portal", Vector3(-0.5, y+2.4, 1.5), Vector3(-1, y+0.9, -5))
		4:
			await photo("09-lab-path-arrival-eye", Vector3(0, y+1.65, 12.5), Vector3(-2, y+0.6, 9.5))
