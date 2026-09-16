extends SceneTree
## PROBE: wall_drawing_291 (Sol LeWitt, Wall Drawing 291, 1976; the visitor is the draftsman).
##
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_wall_drawing_291.gd
##
## WHICH PRESS PATH THIS EXERCISES, said before any result, because a green run
## means nothing until you know what it pressed with:
##
##   DESKTOP LANE: the project's own DesktopInteractionPointer script, under a Head
##   with a Camera3D, stood 0.9 m in front of the wall at eye height 1.6 m and
##   turned to look at the square. The pointer's OWN RayCast3D (mask 19 + 21)
##   finds the collider, its OWN _resolve_pointer_target names the area, and its
##   OWN _input handler turns a left-button InputEventMouseButton into
##   XRToolsPointerEvent.pressed / released, which reaches the square's
##   InteractableAreaButton and fires button_pressed. What is NOT exercised: the
##   OS -> viewport event dispatch (this probe calls the pointer's _input
##   directly) and a person's hand on a mouse.
##
##   HAND LANE: an AnimatableBody3D on the XR Tools poke layer (18, 131072, a
##   5 mm sphere, as addons/godot-xr-tools/player/poke/poke.tscn builds it) moved
##   into a square's area, so the press arrives as the physics server's
##   body_entered. It is NOT a tracked hand and not a headset. It also pushes
##   10 and 20 cm THROUGH the collider-less wall and back, because nothing stops a
##   real hand at the face, and a press box that ended there would fire twice.
##   Its counts are deltas: the pointer lane already pressed the same square.
##
##   THIS PROBE NEVER EMITS button_pressed ITSELF. Emitting a control's signal
##   tests the handler, not the reach: it would pass on a square nobody can hit.
##   Every press here fired because a ray or a body reached the area. The
##   emissions are COUNTED (a connection per area), so "fired once" is a number,
##   not an inference from state.
##
## What it asserts: the four directions cycle on one square and it never goes
## blank; the counter moves once per square and only once; all 40 reads "all 40
## squares drawn"; START AGAIN (pressed through the pointer) clears; a ray at the
## bare wall presses nothing; a fingertip pushed through the wall and back is one
## press, not two; the hidden button caps are not live bodies; start = drawn
## builds the authored 40 lines and the same state twice; config before _ready
## builds once; no randomness in source.
## Exit code 1 on any failed check.

const SCENE := "res://commons/artifacts/wall_drawing_291/wall_drawing_291.tscn"
const SCRIPT_PATH := "res://commons/artifacts/wall_drawing_291/wall_drawing_291.gd"
const POINTER := "res://commons/scenes/DesktopInteractionPointer.gd"
const GRID_COMPONENT := "res://commons/grid/GridInteractablesComponent.gd"
const TAG := "[wall-291] "

const AREA_LAYER := 1048576      # push_button.tscn InteractableAreaButton: layer 21
const AREA_MASK := 393216        # layers 18 + 19
const POKE_LAYER := 131072       # XR Tools PokeBody: layer 18, "Player Hands"
const STAND_M := 0.9
const EYE_Y := 1.6

## The probe's OWN copy of the authored sheet, top row first. It is compared
## against what the artifact built, so a readback is checked against something
## the artifact did not compute.
const SHEET: PackedStringArray = ["VRRHHLLV", "RVHRLHVL", "HRVLRVLH", "LHRVVLVR", "VLHRLHRV"]
const LETTER_TO_STATE := {"V": 1, "H": 2, "R": 3, "L": 4}
const STATE_ROTATION := {1: PI * 0.5, 2: 0.0, 3: PI * 0.25, 4: -PI * 0.25}

var checks := 0
var failures: Array[String] = []
var emits: Dictionary = {}       # area instance id -> button_pressed count


func _initialize() -> void:
	run.call_deferred()


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
	print(TAG, "PASS " if ok else "FAIL ", message)


func _count_emit(key: int) -> void:
	emits[key] = int(emits.get(key, 0)) + 1


func _emits_of(area: Object) -> int:
	if area == null:
		return 0
	return int(emits.get(area.get_instance_id(), 0))


func _total_emits() -> int:
	var t: int = 0
	for k in emits.keys():
		t += int(emits[k])
	return t


func _centre(w: Node, index: int) -> Vector3:
	var v: Vector3 = w.call("square_global_centre", index)
	return v


func _settle(frames: int) -> void:
	for i in range(frames):
		await process_frame
	for i in range(2):
		await physics_frame


func run() -> void:
	print(TAG, "PRESS PATH (desktop): DesktopInteractionPointer's own RayCast3D + _resolve_pointer_target + _input -> XRToolsPointerEvent.pressed/released -> InteractableAreaButton.button_pressed. OS->viewport dispatch NOT exercised (_input called directly).")
	print(TAG, "PRESS PATH (hand): AnimatableBody3D on the XR Tools poke layer 18 moved into the area, through the wall face and back -> physics body_entered/body_exited. NOT a tracked hand.")
	print(TAG, "This probe never emits button_pressed: emitting a signal tests the handler, not the reach.")

	# ── 0. the source and the config keys ─────────────────────────────────────
	var src: String = FileAccess.get_file_as_string(SCRIPT_PATH)
	check(src.length() > 0, "the artifact's source is readable")
	var rng_hits: Array[String] = []
	for raw_line in src.split("\n"):
		var code: String = String(raw_line).split("#")[0]     # comments may SAY randf; code may not CALL it
		for word in ["randf", "randi", "RandomNumberGenerator", "randomize", "rand_range"]:
			if code.find(word) != -1:
				rng_hits.append(word)
	check(rng_hits.is_empty(), "no randomness in the artifact's code (found: %s)" % str(rng_hits))

	var gic: String = FileAccess.get_file_as_string(GRID_COMPONENT)
	var list_at: int = gic.find("const CONFIG_PARAM_NAMES")
	var list_end: int = gic.find("\n]", list_at) if list_at != -1 else -1
	var names_block: String = gic.substr(list_at, list_end - list_at) if list_at != -1 and list_end != -1 else ""
	check(names_block.find("\"columns\"") != -1 and names_block.find("\"rows\"") != -1,
		"`columns` and `rows` are listed in CONFIG_PARAM_NAMES, so #columns:10#rows:6 arrive as values, not rotation shorthand")

	# ── 1. the default build ──────────────────────────────────────────────────
	var packed: PackedScene = load(SCENE)
	check(packed != null, "the scene loads")
	if packed == null:
		_finish()
		return
	var wall: Node3D = packed.instantiate() as Node3D
	check(wall != null and wall.get_script() != null, "the .tscn ROOT carries the script (map tokens can reach apply_grid_config)")
	if wall == null:
		_finish()
		return
	check(wall.has_method("apply_grid_config"), "the root has apply_grid_config(config_data)")
	root.add_child(wall)
	await _settle(8)

	var n: int = int(wall.call("square_count"))
	check(n == 40, "default grid is 8 x 5 = 40 squares with no config (got %d)" % n)
	check(int(wall.call("drawn_count")) == 0, "start = empty: nothing drawn")
	var visible_lines: int = 0
	for i in range(n):
		var ln: MeshInstance3D = wall.call("square_line", i) as MeshInstance3D
		if ln != null and ln.visible:
			visible_lines += 1
	check(visible_lines == 0, "start = empty: no line is visible (%d are)" % visible_lines)
	var plate: Node = wall.find_child("Plate", false, false)
	check(plate != null and str(plate.get("title")) == "WALL DRAWING 291", "the plate is a TextScreen titled WALL DRAWING 291")
	check(str(wall.call("plate_body")).find("0 of 40 squares drawn") != -1, "the plate reads \"0 of 40 squares drawn\"")

	# geometry: base at y = 0, nothing below the floor, text faces +Z
	var min_y: float = INF
	for node in wall.find_children("*", "MeshInstance3D", true, false):
		var mi: MeshInstance3D = node as MeshInstance3D
		if mi.mesh == null or mi.is_queued_for_deletion():
			continue
		var box: AABB = mi.global_transform * mi.get_aabb()
		min_y = minf(min_y, box.position.y)
	check(min_y > -0.002 and min_y < 0.01, "the base is at y = 0 and nothing is below the floor (min y %.4f)" % min_y)
	for text_name in ["Plate", "StartAgainCaption"]:
		var t: Node3D = wall.find_child(text_name, false, false) as Node3D
		check(t != null and t.global_transform.basis.z.normalized().dot(Vector3(0, 0, 1)) > 0.999,
			"%s faces +Z, the side the wall presents" % text_name)
	var bottom_edge: float = _centre(wall, 32).y - 0.15
	var top_edge: float = _centre(wall, 0).y + 0.15
	check(absf(bottom_edge - 0.50) < 0.001 and absf(top_edge - 2.00) < 0.001,
		"the grid runs from 0.50 m to 2.00 m, every square within a standing reach (%.3f .. %.3f)" % [bottom_edge, top_edge])

	# the wall-work contract: no body collider outside the marked hand targets
	var unmarked: Array[String] = []
	for node in wall.find_children("*", "CollisionShape3D", true, false):
		var up: Node = node
		var marked: bool = false
		while up != null and up != wall:
			if bool(up.get_meta("em_local_instrument", false)):
				marked = true
				break
			up = up.get_parent()
		if not marked:
			unmarked.append(str(wall.get_path_to(node)))
	check(unmarked.is_empty(), "every CollisionShape3D is inside an em_local_instrument subtree; the wall itself seals nothing (%s)" % str(unmarked))

	# the hidden button caps must not be live bodies: an invisible collider at every
	# square's centre would stop a hand and snag a walking body on a collider-less wall
	var squares_holder: Node = wall.find_child("Squares", false, false)
	var bodies_seen: int = 0
	var live_bodies: Array[String] = []
	if squares_holder != null:
		for node in squares_holder.find_children("*", "PhysicsBody3D", true, false):
			var pb: PhysicsBody3D = node as PhysicsBody3D
			bodies_seen += 1
			if pb.collision_layer != 0 or pb.collision_mask != 0:
				live_bodies.append("%s (layer %d mask %d)" % [str(wall.get_path_to(pb)), pb.collision_layer, pb.collision_mask])
	check(bodies_seen >= 40 and live_bodies.is_empty(),
		"no body under Squares collides with anything (%d bodies read back, live: %s)" % [bodies_seen, str(live_bodies.slice(0, 4))])

	# every square is its own press target, the whole square wide
	var bad_areas: Array[String] = []
	var first_shape: Shape3D = null
	var second_shape: Shape3D = null
	for i in range(n):
		var area: Area3D = wall.call("square_press_area", i) as Area3D
		if area == null:
			bad_areas.append("%d: no area" % i)
			continue
		if area.collision_layer != AREA_LAYER or area.collision_mask != AREA_MASK:
			bad_areas.append("%d: layer %d mask %d" % [i, area.collision_layer, area.collision_mask])
		var cs: CollisionShape3D = area.get_node_or_null("CollisionShape3D") as CollisionShape3D
		var bs: BoxShape3D = cs.shape as BoxShape3D if cs != null else null
		if bs == null or not bs.size.is_equal_approx(Vector3(0.27, 0.30, 0.27)):
			bad_areas.append("%d: shape %s" % [i, str(cs.shape) if cs != null else "none"])
		elif cs != null:
			# the box's depth runs along the button's local Y, which faces +Z: read the
			# span back in the wall's frame rather than trusting the constants
			var cz: float = wall.to_local(cs.global_position).z
			var front_z: float = cz + bs.size.y * 0.5
			var back_z: float = cz - bs.size.y * 0.5
			if absf(front_z - 0.05) > 0.002 or absf(back_z + 0.25) > 0.002:
				bad_areas.append("%d: depth span z %.3f .. %.3f" % [i, back_z, front_z])
		if i == 0 and cs != null:
			first_shape = cs.shape
		if i == 1 and cs != null:
			second_shape = cs.shape
		area.connect("button_pressed", func(_b): _count_emit(area.get_instance_id()))
	check(bad_areas.is_empty(), "40 press areas on layer 21 / mask 18+19, each a 27 x 27 cm box from 5 cm in front of the face to 25 cm behind it (%s)" % str(bad_areas))
	check(first_shape != null and first_shape != second_shape, "each square got its OWN shape (the push button's AreaShape is shared project-wide)")
	var again: Area3D = wall.call("start_again_area") as Area3D
	check(again != null, "START AGAIN has an InteractableAreaButton")
	if again != null:
		var again_cs: CollisionShape3D = again.get_node_or_null("CollisionShape3D") as CollisionShape3D
		check(again_cs != null and again_cs.shape is CylinderShape3D, "the shared push-button AreaShape was not mutated (START AGAIN's area is still its cylinder)")
		again.connect("button_pressed", func(_b): _count_emit(again.get_instance_id()))

	# ── 2. the desktop pointer: one square through all four directions ────────
	var head := Node3D.new()
	head.name = "Head"
	root.add_child(head)
	var cam := Camera3D.new()
	cam.name = "Camera3D"
	head.add_child(cam)
	var pointer_script: GDScript = load(POINTER)
	var ptr: Node3D = pointer_script.new() as Node3D
	ptr.name = "DesktopInteractionPointer"
	head.add_child(ptr)
	await _settle(2)
	check(ptr.get("_raycast") != null, "the desktop pointer built its RayCast3D")

	var target: int = 12
	var target_area: Area3D = wall.call("square_press_area", target) as Area3D
	var line12: MeshInstance3D = wall.call("square_line", target) as MeshInstance3D
	if line12 == null or target_area == null:
		check(false, "square 12 has a line and a press area")
		_finish()
		return
	check(int(wall.call("square_state", target)) == 0 and not line12.visible, "premise: square 12 is blank before any press")
	var expected_cycle: Array[int] = [1, 2, 3, 4, 1]
	var never_blank: bool = true
	for step in range(expected_cycle.size()):
		var rec: Dictionary = await _pointer_press(ptr, head, _centre(wall, target), target_area)
		var st: int = int(wall.call("square_state", target))
		var rot: float = line12.rotation.z
		var want: int = expected_cycle[step]
		if st == 0 or not line12.visible:
			never_blank = false
		check(bool(rec["hover_is_expected"]) and int(rec["emits"]) == 1,
			"press %d on square 12: the pointer's ray named THAT square's area and it fired exactly once (hover %s, collider %s, emits %d)" % [step + 1, rec["hover"], rec["collider"], rec["emits"]])
		check(st == want and line12.visible and absf(rot - float(STATE_ROTATION[want])) < 0.001,
			"press %d on square 12 draws %s (state %d, visible %s, rotation.z %.4f)" % [step + 1, ["blank", "vertical", "horizontal", "diagonal_right", "diagonal_left"][want], st, line12.visible, rot])
		check(int(wall.call("drawn_count")) == 1, "press %d on square 12: the counter stays at 1 (%d)" % [step + 1, int(wall.call("drawn_count"))])
	check(never_blank, "square 12 was never blank again once drawn")
	var diag_mesh: BoxMesh = line12.mesh as BoxMesh
	check(diag_mesh != null and diag_mesh.size.x > 0.29 and diag_mesh.size.y >= 0.015,
		"the drawn line is a light bar at least 1.5 cm thick, edge to edge (%s)" % (str(diag_mesh.size) if diag_mesh != null else "no mesh"))
	check(int(wall.call("square_state", 11)) == 0 and int(wall.call("square_state", 13)) == 0
		and _emits_of(wall.call("square_press_area", 11)) == 0 and _emits_of(wall.call("square_press_area", 13)) == 0,
		"the neighbours of square 12 were never pressed and are still blank")
	check(str(wall.call("plate_body")).find("1 of 40 squares drawn") != -1, "the plate reads \"1 of 40 squares drawn\"")

	# ── 3. the counter moves once per square ──────────────────────────────────
	var misses: Array[String] = []
	var body_before_last: String = ""
	for i in range(n):
		if i == target:
			continue
		var before: int = int(wall.call("drawn_count"))
		if before == n - 1:
			body_before_last = str(wall.call("plate_body"))
		var area_i: Area3D = wall.call("square_press_area", i) as Area3D
		var rec_i: Dictionary = await _pointer_press(ptr, head, _centre(wall, i), area_i)
		var after: int = int(wall.call("drawn_count"))
		if not bool(rec_i["hover_is_expected"]) or int(rec_i["emits"]) != 1 or after != before + 1 or int(wall.call("square_state", i)) != 1:
			misses.append("%d (hover %s, emits %d, count %d -> %d)" % [i, rec_i["hover"], rec_i["emits"], before, after])
	check(misses.is_empty(), "each of the other 39 squares: the ray named it, it fired once, the counter rose by exactly one (misses: %s)" % str(misses))
	check(body_before_last.find("39 of 40 squares drawn") != -1, "before the last square the plate read \"39 of 40 squares drawn\"")
	check(int(wall.call("drawn_count")) == 40 and bool(wall.call("is_complete")), "all 40 squares are drawn")
	check(str(wall.call("plate_body")).find("all 40 squares drawn") != -1, "the plate reads \"all 40 squares drawn\"")
	check(_total_emits() == 44, "44 presses, 44 emissions in all (5 on square 12, 39 elsewhere; got %d)" % _total_emits())

	# ── 4. a ray at the bare wall presses nothing (the negative) ──────────────
	var emits_before_bare: int = _total_emits()
	var bare_point: Vector3 = _centre(wall, 8) + Vector3(-0.27, 0.0, 0.0)   # the black margin left of row 1
	var bare: Dictionary = await _pointer_press(ptr, head, bare_point, null)
	check(str(bare["hover"]) == "nothing" and _total_emits() == emits_before_bare and int(wall.call("drawn_count")) == 40,
		"a click on the black margin presses nothing (hover %s, emissions %d -> %d)" % [bare["hover"], emits_before_bare, _total_emits()])

	# ── 5. START AGAIN, through the pointer ───────────────────────────────────
	if again != null:
		var again_cs2: CollisionShape3D = again.get_node_or_null("CollisionShape3D") as CollisionShape3D
		var again_point: Vector3 = again_cs2.global_position if again_cs2 != null else again.global_position
		var rec_again: Dictionary = await _pointer_press(ptr, head, again_point, again)
		var lit: int = 0
		for i in range(n):
			var ln2: MeshInstance3D = wall.call("square_line", i) as MeshInstance3D
			if ln2 != null and ln2.visible:
				lit += 1
		check(bool(rec_again["hover_is_expected"]) and int(rec_again["emits"]) == 1,
			"START AGAIN: the pointer's ray named its area and it fired once (hover %s)" % rec_again["hover"])
		check(int(wall.call("drawn_count")) == 0 and lit == 0, "START AGAIN cleared all 40 (count %d, lines still visible %d)" % [int(wall.call("drawn_count")), lit])
		check(str(wall.call("plate_body")).find("0 of 40 squares drawn") != -1, "after START AGAIN the plate reads \"0 of 40 squares drawn\"")

	# ── 6. the hand lane: a poke-layer body enters a square ───────────────────
	# Square 33 was already pressed once through the pointer in section 3, and the
	# emission counts are never reset: every hand check below is a DELTA from here.
	var hand_square: int = 33
	var hand_area: Area3D = wall.call("square_press_area", hand_square) as Area3D
	var hand_centre: Vector3 = _centre(wall, hand_square)
	var hand_base: int = _emits_of(hand_area)
	var neighbour_ids: Array[int] = [25, 32, 34]
	var neighbour_base: Array[int] = []
	for nb in neighbour_ids:
		neighbour_base.append(_emits_of(wall.call("square_press_area", nb)))
	print(TAG, "hand lane baseline: square 33 has fired %d time(s) already (the pointer lane pressed it); the hand checks are deltas from that" % hand_base)
	var fingertip := AnimatableBody3D.new()
	fingertip.name = "ProbeFingertip"
	fingertip.sync_to_physics = false
	fingertip.collision_layer = POKE_LAYER
	fingertip.collision_mask = 0
	var tip_shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.005
	tip_shape.shape = sphere
	fingertip.add_child(tip_shape)
	root.add_child(fingertip)
	fingertip.global_position = hand_centre + Vector3(0.0, 0.0, 0.30)
	await _settle(4)
	var hand_delta: int = _emits_of(hand_area) - hand_base
	check(hand_delta == 0 and int(wall.call("square_state", hand_square)) == 0,
		"premise: a fingertip 30 cm in front of square 33 presses nothing (delta %d, state %d)" % [hand_delta, int(wall.call("square_state", hand_square))])
	fingertip.global_position = hand_centre + Vector3(0.0, 0.0, 0.02)
	await _settle(4)
	await _settle(2)
	hand_delta = _emits_of(hand_area) - hand_base
	check(hand_delta == 1 and int(wall.call("square_state", hand_square)) == 1,
		"a fingertip 2 cm from square 33 presses it once and draws a vertical line (delta %d, state %d)" % [hand_delta, int(wall.call("square_state", hand_square))])

	# THROUGH the wall and back. The wall has no collider and nothing stops a hand,
	# so a real push keeps going past the face. With a press box that ended at the
	# face the finger would leave out of the back (released) and come back in on
	# the way out (pressed again): one touch, two turns. The fingertip goes 10 cm,
	# then 20 cm through, then back to 2 cm in front, and must still be ONE press.
	var through_depths: Array[float] = [-0.10, -0.20, 0.02]
	for depth in through_depths:
		fingertip.global_position = hand_centre + Vector3(0.0, 0.0, depth)
		await _settle(4)
		await _settle(2)
	hand_delta = _emits_of(hand_area) - hand_base
	check(hand_delta == 1 and int(wall.call("square_state", hand_square)) == 1,
		"a fingertip pushed 10 then 20 cm THROUGH the collider-less wall and drawn back to 2 cm is still one press: one emission, still vertical (delta %d, state %d)" % [hand_delta, int(wall.call("square_state", hand_square))])
	fingertip.global_position = hand_centre + Vector3(0.0, 0.0, 0.30)
	await _settle(4)
	hand_delta = _emits_of(hand_area) - hand_base
	check(hand_delta == 1 and int(wall.call("square_state", hand_square)) == 1,
		"taking the fingertip away presses nothing (delta %d, state %d)" % [hand_delta, int(wall.call("square_state", hand_square))])

	fingertip.global_position = hand_centre + Vector3(0.0, 0.0, 0.02)
	await _settle(4)
	await _settle(2)
	hand_delta = _emits_of(hand_area) - hand_base
	check(hand_delta == 2 and int(wall.call("square_state", hand_square)) == 2 and int(wall.call("drawn_count")) == 1,
		"out and back in turns square 33 to horizontal and the counter stays at 1 (delta %d, state %d, count %d)" % [hand_delta, int(wall.call("square_state", hand_square)), int(wall.call("drawn_count"))])
	var neighbour_moved: Array[String] = []
	for k in range(neighbour_ids.size()):
		var nb_delta: int = _emits_of(wall.call("square_press_area", neighbour_ids[k])) - neighbour_base[k]
		if nb_delta != 0 or int(wall.call("square_state", neighbour_ids[k])) != 0:
			neighbour_moved.append("%d (delta %d, state %d)" % [neighbour_ids[k], nb_delta, int(wall.call("square_state", neighbour_ids[k]))])
	check(neighbour_moved.is_empty(), "the hand lane pressed only square 33: its neighbours 25, 32 and 34 did not fire (%s)" % str(neighbour_moved))
	fingertip.queue_free()

	# ── 7. start = drawn: the authored 40 lines, deterministically ────────────
	var drawn_a: Node3D = packed.instantiate() as Node3D
	drawn_a.set("start", "drawn")
	drawn_a.position = Vector3(0.0, 0.0, -8.0)
	root.add_child(drawn_a)
	await _settle(4)
	var sheet_miss: Array[String] = []
	var lines_on: int = 0
	for i in range(40):
		var c: int = i % 8
		var r: int = floori(float(i) / 8.0)
		var want_state: int = int(LETTER_TO_STATE[SHEET[r][c]])
		var got_state: int = int(drawn_a.call("square_state", i))
		var ln3: MeshInstance3D = drawn_a.call("square_line", i) as MeshInstance3D
		if ln3 != null and ln3.visible:
			lines_on += 1
		if got_state != want_state or ln3 == null or absf(ln3.rotation.z - float(STATE_ROTATION[want_state])) > 0.001:
			sheet_miss.append("%d: want %d got %d" % [i, want_state, got_state])
	check(int(drawn_a.call("square_count")) == 40 and lines_on == 40, "start = drawn builds 40 visible lines (%d)" % lines_on)
	check(sheet_miss.is_empty(), "start = drawn is the AUTHORED sheet, square for square, line for line (%s)" % str(sheet_miss))
	check(str(drawn_a.call("plate_body")).find("all 40 squares drawn") != -1, "start = drawn: the plate reads \"all 40 squares drawn\"")

	# the museum's path: configured after _ready, deferred; must rebuild once, to the same state
	var drawn_b: Node3D = packed.instantiate() as Node3D
	drawn_b.position = Vector3(0.0, 0.0, -16.0)
	root.add_child(drawn_b)
	await _settle(2)
	drawn_b.call("apply_grid_config", {"start": "drawn"})
	await _settle(4)
	var snap_a: PackedInt32Array = drawn_a.call("state_snapshot")
	var snap_b: PackedInt32Array = drawn_b.call("state_snapshot")
	check(snap_a == snap_b and snap_a.size() == 40, "start = drawn twice (export, then #start:drawn after _ready) gives the identical 40-square state")
	var holders_b: int = 0
	var squares_b: int = 0
	for ch in drawn_b.get_children():
		if str(ch.name) == "Squares" and not ch.is_queued_for_deletion():
			holders_b += 1
			squares_b += ch.get_child_count()
	check(holders_b == 1 and squares_b == 40, "#start:drawn after _ready re-drafts in place: ONE set of squares (%d holders, %d squares)" % [holders_b, squares_b])
	# a size change after _ready is a real rebuild; it must not leave the old squares behind
	drawn_b.call("apply_grid_config", {"columns": "6", "rows": "5"})
	await _settle(4)
	var holders_c: int = 0
	var squares_c: int = 0
	for ch in drawn_b.get_children():
		if str(ch.name) == "Squares" and not ch.is_queued_for_deletion():
			holders_c += 1
			squares_c += ch.get_child_count()
	var rebuilt_miss: int = 0
	for i in range(30):
		if int(drawn_b.call("square_state", i)) != int(LETTER_TO_STATE[SHEET[floori(float(i) / 6.0)][i % 6]]):
			rebuilt_miss += 1
	check(int(drawn_b.call("square_count")) == 30 and holders_c == 1 and squares_c == 30,
		"#columns:6 after _ready rebuilds ONCE at 6 x 5 (%d squares, %d holders, %d square nodes)" % [int(drawn_b.call("square_count")), holders_c, squares_c])
	check(rebuilt_miss == 0 and str(drawn_b.call("plate_body")).find("all 30 squares drawn") != -1,
		"the rebuilt 6 x 5 wall keeps start = drawn, follows the authored sheet, and the plate counts 30")

	# configured BEFORE _ready, as the museum can: built once, at the configured size
	var small: Node3D = packed.instantiate() as Node3D
	small.call("apply_grid_config", {"start": "drawn", "columns": "4", "rows": "3"})
	small.position = Vector3(0.0, 0.0, -24.0)
	root.add_child(small)
	await _settle(4)
	var small_holders: int = 0
	var small_squares: int = 0
	for ch in small.get_children():
		if str(ch.name) == "Squares":
			small_holders += 1
			small_squares += ch.get_child_count()
	var small_miss: int = 0
	for i in range(12):
		var c2: int = i % 4
		var r2: int = floori(float(i) / 4.0)
		if int(small.call("square_state", i)) != int(LETTER_TO_STATE[SHEET[r2][c2]]):
			small_miss += 1
	check(int(small.call("square_count")) == 12 and small_holders == 1 and small_squares == 12,
		"config before _ready (#columns:4#rows:3) builds ONCE at 4 x 3 (%d squares, %d holders)" % [int(small.call("square_count")), small_holders])
	check(small_miss == 0 and str(small.call("plate_body")).find("all 12 squares drawn") != -1, "4 x 3 drawn follows the authored sheet and the plate counts 12")
	small.call("apply_grid_config", {"columns": true})
	await _settle(2)
	check(int(small.get("columns")) == 4, "a bool columns (the shorthand misparse of an unlisted key) is refused, not read as 1")

	_finish()


## Stand an eye STAND_M in front of `aim`, look at it, and click through the
## desktop pointer's own ray and input handler. Returns what the pointer named
## and how many times `expected` fired. `expected` null = expect nothing.
func _pointer_press(ptr: Node3D, head: Node3D, aim: Vector3, expected: Area3D) -> Dictionary:
	head.global_position = Vector3(aim.x, EYE_Y, aim.z + STAND_M)
	head.look_at(aim, Vector3.UP)
	await physics_frame
	await physics_frame
	var ray: RayCast3D = ptr.get("_raycast") as RayCast3D
	if ray != null:
		ray.force_raycast_update()
	ptr.call("_process", 0.0)
	var collider: String = "none"
	if ray != null and ray.is_colliding() and ray.get_collider() != null:
		collider = str((ray.get_collider() as Node).name)
	var hover: Variant = ptr.get("_last_target")
	var hover_node: Node = hover as Node if hover is Node else null
	var before: int = _emits_of(expected)
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	ptr.call("_input", down)
	await process_frame
	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.pressed = false
	ptr.call("_input", up)
	await process_frame
	return {
		"hover_is_expected": expected != null and hover_node == expected,
		"hover": (str(hover_node.get_parent().get_parent().name) + "/" + str(hover_node.name)) if hover_node != null and hover_node.get_parent() != null and hover_node.get_parent().get_parent() != null else "nothing",
		"collider": collider,
		"emits": _emits_of(expected) - before,
	}


func _finish() -> void:
	print(TAG, "%d checks, %d failed" % [checks, failures.size()])
	for f in failures:
		print(TAG, "  FAILED: ", f)
	print(TAG, "lanes: desktop pointer (own ray + own _input, OS dispatch not exercised); poke-layer body (physics overlap, not a tracked hand); no signal emitted by the probe")
	print(TAG, "RESULT: ", "PASS" if failures.is_empty() else "FAIL")
	quit(0 if failures.is_empty() else 1)
