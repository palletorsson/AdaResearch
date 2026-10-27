extends "res://tools/probes/void_transfer_probe.gd"
## Batch 25 (worker D): CA_GameOfLife, the single content floor of cellularautomata_02.
## The shared visit() runs floor 1 only (floors.size()-2 == 1): inspection, focused checks,
## then return and retry on floor 1. Real input uses the shared input_* helpers and the
## press variant from randomness_03; API, geometry and measurement checks say so.

const BRIDGE := "f1_ca_bridge_6_5"
const FILM := "f1_film_cellular_history_1_15"
const LAB := "f1_lab_room_6_22"
const COLUMNS := "f1_ca_columns_8_28"
const MIRRORED := "f1_mirrored_cellular_automata_6_32"
## The floor-1 basin (rooms.json), floor-local x/z: the source hole plus 0.1 m per side.
const BASIN_RECT := Rect2(-3.6, -2.6, 7.2, 10.2)
const BASIN_DEPTH := 0.72

func debug_cases() -> Dictionary:
	return {"bounds-1": 1, "record": 1, "desk": 1, "film": 1, "lab": 1, "growth": 1}

func run_debug_case(name: String, tag: String) -> void:
	match name:
		"bounds-1":
			inspect_floor(tag)
			await frames(30)
			await fit_checks(tag)
			report_bounds(tag)
		"record": await record_checks(tag)
		"desk": await desk_checks(tag)
		"film": await film_checks(tag)
		"lab": await lab_checks(tag)
		"growth": await growth_checks(tag)

func focused_checks(tag: String) -> void:
	check(tag+"standard floor "+str(level), game.building.spec.width == 42 and game.building.spec.depth == 32 and game.building.spec.storey_height == 6)
	await fit_checks(tag)
	await growth_checks(tag)
	await record_checks(tag)
	await desk_checks(tag)
	await film_checks(tag)
	await lab_checks(tag)
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
## CollisionShape3D is the target (the film monitor's buttons).
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

func basin_box() -> AABB:
	var y: float = game.building.spec.levels[level]
	return AABB(Vector3(BASIN_RECT.position.x, y-BASIN_DEPTH-.2, BASIN_RECT.position.y), Vector3(BASIN_RECT.size.x, BASIN_DEPTH+.2, BASIN_RECT.size.y))

# ── fit: whole shaft openings, columns, arrival, floor sign and the basin ────

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
		var zones: Array = keep_out.duplicate()
		# Only the bridge's own collecting floor and ramps belong below the slab here.
		if entry.id != BRIDGE: zones.append(["floor-1 basin", basin_box()])
		for item in zones:
			var zone: AABB = item[1]
			var inside: Array = boxes.filter(func(b): return shrink_mm(b).intersects(zone))
			if not inside.is_empty():
				hits.append(entry.id+" / "+str(item[0]))
				print("FIT_BOX ", tag, entry.id, " / ", item[0], " ", inside.slice(0, 3))
	print("FIT ", tag, "floor ", level, " ", hits)
	if not xr and not hits.is_empty(): fit_notes.append({"floor": level, "enters": hits})
	check(tag+"placement geometry stays out of shafts, columns, arrival, floor sign and (except the bridge) the basin (measured)", hits.is_empty())

# ── the bridge: one Rule 30 history as desk, support and lattice ────────────

func study_node() -> Node3D:
	return station(BRIDGE).get_node_or_null("HistoryStudy")

## Lowest-row empty 2 x 2 block (rows g, g+1; cells i, i+1) whose row g-1 holds both
## cells. Returns (i, g), or (-1, -1).
func find_hole(history: Array) -> Vector2i:
	for g in range(1, history.size()-1):
		for i in range(history[g].size()-1):
			if int(history[g-1][i]) == 1 and int(history[g-1][i+1]) == 1 \
					and int(history[g][i])+int(history[g][i+1])+int(history[g+1][i])+int(history[g+1][i+1]) == 0:
				return Vector2i(i, g)
	return Vector2i(-1, -1)

## A record cell in world space (the study's own cell_position, through its frame).
func cell_world(i: int, g: int) -> Vector3:
	var study: Node3D = study_node()
	return study.to_global(study.cell_position(i, g))

func record_checks(tag: String) -> void:
	var bridge: Node3D = station(BRIDGE)
	var study: Node3D = study_node()
	check(tag+"bridge mounts its history study: rule 30, 15 x 24 record, twelve rows held, walk-follow on (API)",
		study != null and study.walk_follow and bridge.rule == 30 and int(study.readback().generation) == 11)
	if study == null: return
	var y: float = game.building.spec.levels[level]
	var history: Array = study.history
	# The first row whose centre cell (x index 7) is empty after a supported row.
	var gap: int = -1
	for g in range(1, history.size()):
		if int(history[g][7]) == 0 and int(history[g-1][7]) == 1 and int(history[g][8]) == 0:
			gap = g;break
	check(tag+"the record holds a gap in its centre column after a supported row (API, rule 30 history)", gap > 0)
	if gap <= 0: return
	var solid := ray(cell_world(7, gap-1)+Vector3.UP*.5, cell_world(7, gap-1)+Vector3.DOWN*1.5)
	var open := ray(cell_world(7, gap)+Vector3.UP*.5, cell_world(7, gap)+Vector3.DOWN*1.5)
	print("RECORD ", tag, "gap row ", gap, " solid=", solid.get("position"), " open=", open.get("position"))
	check(tag+"occupied cells carry support at the slab; the gap opens onto the collecting floor 0.6 m down (geometry; needs the basin)",
		not solid.is_empty() and absf(solid.position.y-y) < .03 and not open.is_empty() and absf(open.position.y-(y-.6)) < .05)
	var gen0: int = int(study.readback().generation)
	# Measurement only: a one-cell gap is 0.4 m along the walk, the body's capsule is
	# 0.4 m across, so it bridges the two supported rows (first native run: walked to
	# row 4 at slab height). Printed, not asserted.
	game.place_player(study.to_global(study.cell_position(7, gap-1)+Vector3(.1, .17, 0)));await frames(30)
	var bridged_to: Vector3 = study.to_global(study.cell_position(7, gap+2)+Vector3(.1, 0, 0))
	var dropped: bool = await drive_until(bridged_to, func(): return game.body.global_position.y < y-.4, 120)
	print("RECORD ", tag, "one-cell gap row ", gap, ": dropped=", dropped, " feet=", game.body.global_position)
	# A hole wider than the body: the first empty 2 x 2 block behind an occupied pair,
	# read from the live history (rule 30, single seed: rows 6-7, cells 7-8). The walk
	# line runs on the boundary between the two cells, so every tile edge stays 0.4 m
	# from the hole's centre.
	var hole: Vector2i = find_hole(history)
	check(tag+"the held record has a 2 x 2 hole behind an occupied pair (API, live history)", hole.x >= 0)
	if hole.x < 0: return
	var seam := Vector3(.2, 0, 0)
	game.place_player(study.to_global(study.cell_position(hole.x, hole.y-1)+seam+Vector3(0, .17, 0)));await frames(40)
	var feet: Vector3 = game.body.global_position
	check(tag+"a body standing on the occupied pair is carried at slab height and gold follows its row (physics + walk-follow)",
		game.body.is_on_floor() and absf(feet.y-y) < .08 and study.walking_row and study.selected == hole.y-1)
	# Real walking into the hole: rows advance along the study's +z. Re-read each frame.
	var fell: bool = await drive_until(study.to_global(study.cell_position(hole.x, hole.y+2)+seam),
		func(): return game.body.global_position.y < y-.4 and game.body.is_on_floor(), 180)
	await frames(20)
	var p: Vector3 = study.to_local(game.body.global_position)
	var row_under: int = clampi(floori(p.z/.4+.5), 0, history.size()-1)
	print("RECORD ", tag, "hole ", hole, " fell=", fell, " feet=", game.body.global_position, " row_under=", row_under, " selected=", study.selected, " generation=", study.readback().generation, " running=", study.running)
	check(tag+"walking into a hole wider than the body drops it to the collecting floor; gold follows the fallen body's row (real walking)",
		fell and absf(game.body.global_position.y-(y-.6)) < .08 and study.walking_row and study.selected == row_under)
	check(tag+"walking never advances or edits the held record (API: generation and run state unchanged)",
		int(study.readback().generation) == gen0 and not study.running and study.history.size() == gen0+1)
	# The open end of the basin, beyond the held rows: walk out up the exit ramp.
	var held: int = int(study.readback().generation)
	game.place_player(study.to_global(Vector3(0, -.54, (held+3)*.4)));await frames(30)
	var exit_to: Vector3 = study.to_global(Vector3(0, 0, 10.3))
	var out: bool = await drive_until(exit_to, func(): return study.to_local(game.body.global_position).z > 9.7 and absf(game.body.global_position.y-y) < .08 and game.body.is_on_floor(), 260)
	print("RECORD ", tag, "exit=", out, " feet=", game.body.global_position)
	check(tag+"the collecting floor is left up its exit ramp onto the slab (real walking)", out)

## The desk's six buttons on the tilted console (RackTemplates, real pointer).
func desk_checks(tag: String) -> void:
	var bridge: Node3D = station(BRIDGE)
	var study: Node3D = study_node()
	if study == null:
		check(tag+"history desk present", false);return
	var controls: Node3D = study.console.get_node("HistoryControls")
	var step_button: Node3D = controls.find_child("Btn_0", true, false)
	await stand_near(step_button, bridge, 1.2)
	var g0: int = int(study.readback().generation)
	await press(step_button);await frames(6)
	check(tag+"STEP with real pointer adds one generation", int(study.readback().generation) == g0+1)
	await press(controls.find_child("Btn_1", true, false));await frames(45)
	var was_running: bool = study.running
	var g1: int = int(study.readback().generation)
	await press(controls.find_child("Btn_1", true, false));await frames(6)
	check(tag+"RUN with real pointer advances the record at 0.5 s per row; RUN again holds it", was_running and g1 > g0+1 and not study.running)
	await press(controls.find_child("Btn_3", true, false));await frames(6)
	check(tag+"SEED with real pointer replays from the PAIR seed", study.seed_mode == 1 and int(study.readback().generation) == 0)
	await press(controls.find_child("Btn_4", true, false));await frames(6)
	check(tag+"FLIP X9 with real pointer flips one starting cell", study.flipped and int(study.history[0][9]) == 0)
	# Not vacuous: step away from generation 0 first, then REPLAY must come back.
	await press(step_button);await frames(6)
	var stepped: bool = int(study.readback().generation) == 1
	await press(controls.find_child("Btn_2", true, false));await frames(6)
	check(tag+"REPLAY with real pointer returns a stepped record to generation 0, keeping the chosen beginning",
		stepped and int(study.readback().generation) == 0 and study.seed_mode == 1 and study.flipped)

func film_checks(tag: String) -> void:
	var film: Node3D = station(FILM)
	# 1.1 m in front of the buttons keeps the visitor on the slab beside the basin edge.
	game.place_player(film.to_global(Vector3(0, .06, 1.1)));await frames(20)
	var before: bool = film.stage.running
	await press(film.buttons.pause)
	check(tag+"cellular-history film PAUSE with real pointer toggles the stage", film.stage.running != before)
	await press(film.buttons.pause)

func lab_checks(tag: String) -> void:
	var lab: Node3D = station(LAB)
	var door: Node = lab.find_child("DoorHandler", true, false)
	var mounted: Array = lab.mount_point.get_children().map(func(n): return str(n.name)) if lab.mount_point != null else []
	check(tag+"lab room builds 8 x 7 x 3.8 m with its sliding door and the Turing apparatus on the plinth (API)",
		is_equal_approx(lab.room_width, 8.0) and is_equal_approx(lab.room_depth, 7.0) and is_equal_approx(lab.room_height, 3.8) and door != null and not mounted.is_empty())
	if door == null: return
	# Real walking to the door (local +x, west after the turn).
	game.place_player(lab.to_global(Vector3(6.2, .06, 0)));await frames(20)
	var reached: bool = await move_to(lab.to_global(Vector3(4.7, .06, 0)), false, 200)
	await frames(40)
	print("LAB ", tag, "reached=", reached, " door_open=", door.get("_open"), " auto=", door.get("auto_open_on_proximity"), " mounted=", mounted)
	check(tag+"door stays shut at its sensor: the source waits for a palm scanner this hall does not place (measured)",
		reached and not bool(door.get("_open")) and not bool(door.get("auto_open_on_proximity")))

func growth_checks(tag: String) -> void:
	var cols: Node3D = station(COLUMNS)
	var last: Array = cols.history_3d.back() if not cols.history_3d.is_empty() else []
	var grew := false
	for i in 200:
		await frames(1)
		if not cols.history_3d.is_empty() and not is_same(cols.history_3d.back(), last):
			grew = true;break
	print("GROWTH ", tag, "layers=", cols.history_3d.size(), " instances=", cols.multi_mesh_instance.multimesh.instance_count, " scale=", cols.global_basis.get_scale())
	check(tag+"ca_columns stacks a new Life generation as instanced cubes within 3.3 s (API)", grew and cols.multi_mesh_instance.multimesh.instance_count > 0)
	var mir: Node3D = station(MIRRORED).get_node("MirroredCellularAutomata")
	check(tag+"mirrored automaton lays its 31 x 31 motif-stencil field on its floor plate (API)",
		mir.grid_size == 31 and mir.symmetry_type == 2 and mir.mesh_instance != null and mir.mesh_instance.mesh != null)

func capture_floor() -> void:
	var y: float = game.building.spec.levels[level]
	await photo("01-game-of-life-arrival-eye", Vector3(0, y+1.65, 12.5), Vector3(0, y+0.6, 4))
	await photo("02-record-and-lattice", Vector3(2.6, y+2.4, 10.5), Vector3(0, y-0.3, 4.5))
	await photo("03-lab-and-rear-gallery", Vector3(3.5, y+2.2, -4.5), Vector3(-3, y+1.2, -12))
	await photo("04-film-monitor", Vector3(2.2, y+1.6, -3), Vector3(5, y+1.7, -3))
