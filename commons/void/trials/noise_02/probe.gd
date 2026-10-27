extends "res://tools/probes/void_transfer_probe.gd"
## Batch 25, worker C: Noise_One (1), Noise_Voxel (2), Noise_6_Wall (3),
## Noise_Inside_Noise (4) and Noise_Cellular (5). Visit, inspection, shaft descent,
## residency and retry come from the shared probe. Real input uses the shared
## input helpers and press(); API, geometry and measurement checks say so.
## Several works here are architecture-sized; fit_checks refines curved shells by
## their actual triangle vertices and also tests the floor below's geometry
## against this floor's shafts, arrival and sign (neighbour-floor intrusion).

const FILM1 := "f1_film_noise_layers_1_2"
const TORUS := "f1_noisetorus_5_4"
const BASIN := "f1_noiselayers_5_7"
const VOXEL := "f2_voxelnoise_16_24"
const SCREEN := "f2_science_screen_18_4"
const BENCH := "f2_perlin_terrain_sculptor_13_7"
const PANEL := "f3_shader_noise_space_6_4"
const ROOM := "f3_shader_noise_space_6_6"
const SPHERE := "f4_noisesphere_6_5"
const FILM4 := "f4_film_noise_relief_11_9"
const WOMB := "f5_cellular_womb_space_17_19"
const ATRIUM := "f5_cellular_atrium_space_51_19"
const STRANDS := "f5_voronoi_strands_34_40"
const FLIGHT_SCRIPT := "res://commons/movement/museum_flight_box.gd"

func debug_cases() -> Dictionary:
	return {"bounds-1": 1, "bounds-2": 2, "bounds-3": 3, "bounds-4": 4, "bounds-5": 5,
		"torus": 1, "basin": 1, "film": 1, "flightseam": 1, "lattice": 2, "flight": 2,
		"panel": 3, "room": 3, "warp": 4, "relief": 4, "crossfloor": 4, "rooms": 5, "strands": 5, "strands-photo": 5}

func run_debug_case(name: String, tag: String) -> void:
	await ready_floor(tag)
	match name:
		"bounds-1", "bounds-2", "bounds-3", "bounds-4", "bounds-5":
			inspect_floor(tag)
			await frames(30)
			await fit_checks(tag)
			report_bounds(tag)
		"torus": await torus_checks(tag)
		"basin": await basin_checks(tag)
		"film": await film_checks(tag, FILM1)
		"flightseam": await flight_seam_report(tag)
		"lattice": await lattice_checks(tag)
		"flight": await flight_checks(tag)
		"panel": await panel_checks(tag)
		"room": await room_walk(tag)
		"warp":
			await warp_checks(tag)
			await sphere_walk(tag)
		"relief": await film_checks(tag, FILM4)
		"crossfloor": await crossfloor_report(tag)
		"rooms": await rooms_checks(tag)
		"strands":
			await strands_checks(tag)
			await strands_release(tag)
		"strands-photo":
			take_photos = true
			# Bounded review capture of the finished weave, not elapsed gameplay.
			var weaver: Node = station(STRANDS).get("weaver")
			if is_instance_valid(weaver): weaver.call("finish")
			await frames(2)
			var y: float = game.building.spec.levels[level]
			await photo("16-strands", Vector3(13.5, y+1.65, -3.5), Vector3(17, y+3.5, -10.5))

func focused_checks(tag: String) -> void:
	check(tag+"standard floor "+str(level), game.building.spec.width == 42 and game.building.spec.depth == 32 and game.building.spec.storey_height == 6)
	await ready_floor(tag)
	await fit_checks(tag)
	match level:
		1:
			await torus_checks(tag)
			await basin_checks(tag)
			await film_checks(tag, FILM1)
		2:
			await lattice_checks(tag)
			await flight_checks(tag)
		3:
			await panel_checks(tag)
			await room_walk(tag)
		4:
			await warp_checks(tag)
			await sphere_walk(tag)
			await film_checks(tag, FILM4)
		5:
			await rooms_checks(tag)
			await strands_checks(tag)
	dark_checks(tag)
	game.place_player(game.spawn_for(level));await frames(15)

# ── helpers ─────────────────────────────────────────────────────────────────

func has_exhibit(index: int, id: String) -> bool:
	return game.building.content.exhibits.has(str(index)+"/"+id)

func exhibit(index: int, id: String) -> Node3D:
	var mount: Node3D = game.building.content.exhibits.get(str(index)+"/"+id)
	return mount.get_node_or_null("Artifact") if mount != null else null

## Frames until the test holds, or -1 when the bound runs out.
func wait_until(test: Callable, limit: int) -> int:
	for i in limit:
		if bool(test.call()): return i
		await frames(1)
	return limit if bool(test.call()) else -1

func floor_built(index: int) -> bool:
	for entry in game.building.content.data.floors[index].artifacts:
		if exhibit(index, str(entry.id)) == null: return false
	return true

## Bounded readiness: every placement built, then the asynchronous parts finished
## (deferred cell rebuild and bench broadcast, membrane meshing, strand network).
func ready_floor(tag: String) -> void:
	var built: int = await wait_until(func(): return floor_built(level), 900)
	check(tag+"floor %d placements built (bounded wait)" % level, built >= 0)
	if built < 0: return
	var test: Callable = func(): return true
	match level:
		1:
			test = func(): return bool(station(TORUS).get("_built")) and station(TORUS).get("_pair_root") != null and station(BASIN).get("terrain") != null and station(FILM1).get("stage") != null
		2:
			test = func(): return bool(station(VOXEL).get("_contract")) and not bool(station(VOXEL).get("_rebuild_queued")) and station(BENCH).get("_lattice_root") != null and is_instance_valid(station(SCREEN).get("_screen_mesh"))
		3:
			test = func(): return station(PANEL).get("_panel_root") != null and station(ROOM).has_node("MuseumRoom")
		4:
			test = func(): return station(SPHERE).has_node("WarpStudy") and station(SPHERE).get_node("WarpStudy").get("enclosure") != null
		5:
			test = func(): return int(station(WOMB).get("build_msec")) > 0 and int(station(ATRIUM).get("build_msec")) > 0 and int(station(STRANDS).get("generation_count")) > 0
	var after: int = await wait_until(test, 600)
	print("READY ", tag, "floor ", level, " placements after ", built, " frames, construction after ", after)
	check(tag+"floor %d construction complete (bounded readiness; floor 2/3 need R1)" % level, after >= 0)

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

## [node, world AABB] for every visible drawn part, as geometry() counts them.
func parts(node: Node, out: Array) -> void:
	if node is SubViewport: return
	if node is CSGShape3D:
		if node.is_root_shape() and node.is_visible_in_tree(): out.append([node, node.global_transform*node.get_aabb()])
	elif node is MeshInstance3D and node.mesh != null and node.is_visible_in_tree() and node.layers != 0:
		out.append([node, node.global_transform*node.get_aabb()])
	elif node is MultiMeshInstance3D and node.multimesh != null and node.is_visible_in_tree():
		out.append([node, node.global_transform*node.get_aabb()])
	for child in node.get_children(): parts(child, out)

## A large curved shell's AABB overstates its corners: test its actual vertices.
## The enclosing sphere is displaced in its shader; its collider's vertices are
## the displaced ones, so those stand in for the drawn surface.
func part_enters(part: Array, zone: AABB) -> bool:
	var node: Node3D = part[0]
	var box: AABB = part[1]
	if not shrink_mm(box).intersects(zone): return false
	# MultiMeshes (strand nets, knots, fixing plates) are tested per instance.
	if node is MultiMeshInstance3D: return int(multimesh_inside(node as MultiMeshInstance3D, zone).count) > 0
	if box.size.x < 3.0 and box.size.y < 3.0 and box.size.z < 3.0: return true
	var points := PackedVector3Array()
	var xf: Transform3D = node.global_transform
	var host: Node = node.get_parent()
	if str(node.name) == "InnerSurface" and host != null and "displaced_vertices" in host:
		points = host.get("displaced_vertices");xf = (host as Node3D).global_transform
	elif node is MeshInstance3D:
		points = (node as MeshInstance3D).mesh.get_faces()
	else:
		return true
	var inner := shrink_mm(zone)
	for p in points:
		if inner.has_point(xf*p): return true
	return false

## Liang-Barsky: does segment a-b pass through the box?
func segment_hits(a: Vector3, b: Vector3, box: AABB) -> bool:
	var t0 := 0.0
	var t1 := 1.0
	var d: Vector3 = b-a
	for axis in 3:
		var lo: float = box.position[axis]
		var hi: float = box.end[axis]
		if absf(d[axis]) < 0.000000001:
			if a[axis] < lo or a[axis] > hi: return false
			continue
		var u: float = (lo-a[axis])/d[axis]
		var v: float = (hi-a[axis])/d[axis]
		if u > v:
			var w: float = u;u = v;v = w
		t0 = maxf(t0, u);t1 = minf(t1, v)
		if t0 > t1: return false
	return true

## Every instance, built or still to be woven: unit cylinders (strands) as their
## segments, anything else (knots, fixing plates, legs) by its origin, with 5 cm grace.
func multimesh_inside(node: MultiMeshInstance3D, zone: AABB) -> Dictionary:
	var mm: MultiMesh = node.multimesh
	var xf: Transform3D = node.global_transform
	var strand: bool = mm.mesh is CylinderMesh
	var grace: AABB = zone.grow(.05)
	var count := 0
	var lowest := INF
	for i in mm.instance_count:
		var t: Transform3D = xf*mm.get_instance_transform(i)
		var inside := false
		if strand:
			var a: Vector3 = t.origin-t.basis.y*0.5
			var b: Vector3 = t.origin+t.basis.y*0.5
			inside = segment_hits(a, b, zone)
			if inside: lowest = minf(lowest, minf(a.y, b.y))
		else:
			inside = grace.has_point(t.origin)
			if inside: lowest = minf(lowest, t.origin.y)
		if inside: count += 1
	return {"count": count, "lowest": lowest}

## Whole shaft openings (full storey), the arrival and the floor sign at this level.
func zones(index: int) -> Array:
	var spec = game.building.spec
	var y: float = spec.levels[index]
	var out: Array = []
	for shaft in spec.shafts:
		out.append(["shaft "+str(shaft.name), AABB(Vector3(float(shaft.x)-float(spec.shaft_width)/2.0, y-.5, -float(spec.shaft_depth)/2.0), Vector3(float(spec.shaft_width), 6.5, float(spec.shaft_depth)))])
	out.append(["arrival", AABB(Vector3(-1, y, 11), Vector3(2, 2.2, 2))])
	var sign_xz: Array = spec.get("floor_sign_positions", {}).get(str(index), [3.5, -7.8])
	out.append(["floor sign", AABB(Vector3(float(sign_xz[0])-1.85, y+.525, float(sign_xz[1])-.06), Vector3(3.7, 1.65, .12))])
	return out

func enters(index: int, id: String, keep_out: Array) -> Array:
	var hits: Array = []
	var node: Node3D = exhibit(index, id)
	if node == null: return hits
	var list: Array = [];parts(node, list)
	for item in keep_out:
		for part in list:
			# The strands' cords run to whatever solid surface their rays meet, as they ran
			# to the museum hall's walls. A cord crossing a keep-out is recorded, not
			# failed (no collision); an ANCHOR inside one fails, through the Knots and
			# SurfaceFixings parts.
			if str(part[0].name) == "AnchorCords":
				var cross: Dictionary = multimesh_inside(part[0] as MultiMeshInstance3D, item[1])
				if int(cross.count) > 0:
					var base: float = game.building.spec.levels[index]
					var note := {"id": id, "cords_crossing": str(item[0]), "floor": index, "count": cross.count, "lowest_above_floor": float(cross.lowest)-base}
					print("CORDS ", note)
					if not xr: fit_notes.append(note)
				continue
			if part_enters(part, item[1]):
				hits.append(id+" / "+str(item[0]))
				print("FIT_PART ", id, " ", (part[0] as Node).get_path(), " / ", item[0], " ", part[1])
				break
	return hits

func fit_checks(tag: String) -> void:
	var here: Array = zones(level)
	var hits: Array = []
	for entry in game.building.content.data.floors[level].artifacts:
		hits.append_array(enters(level, entry.id, here))
	print("FIT ", tag, "floor ", level, " ", hits)
	if not xr and not hits.is_empty(): fit_notes.append({"floor": level, "enters": hits})
	check(tag+"placement geometry stays out of whole shaft openings, arrival and floor sign (vertex-refined)", hits.is_empty())
	# Neighbour-floor intrusion: what the floor below raises into this storey.
	var below: int = level+1
	if below >= game.building.content.data.floors.size()-1: return
	var loaded: Array = game.building.content.data.floors[below].artifacts.filter(func(e): return has_exhibit(below, str(e.id)))
	var up: Array = []
	for entry in loaded:
		up.append_array(enters(below, entry.id, here))
	print("FIT_BELOW ", tag, "floor ", below, " into floor ", level, " loaded ", loaded.size(), " ", up)
	if not xr and not up.is_empty(): fit_notes.append({"floor": level, "entered_from_floor_below": up})
	check(tag+"floor %d geometry stays out of floor %d's shaft openings, arrival and sign (vertex-refined)" % [below, level], up.is_empty())

func report_bounds(tag: String) -> void:
	var y: float = game.building.spec.levels[level]
	for entry in game.building.content.data.floors[level].artifacts:
		var node: Node3D = station(entry.id)
		var b: AABB = bounds_of(node)
		if b.size == Vector3.ZERO:
			print("BOUNDS ", tag, entry.id, " none");continue
		print("BOUNDS ", tag, entry.id, " x %.2f..%.2f y %.2f..%.2f z %.2f..%.2f" % [b.position.x, b.end.x, b.position.y-y, b.end.y-y, b.position.z, b.end.z])
		if not xr and (b.position.x < -21.0 or b.end.x > 21.0 or b.position.z < -16.0 or b.end.z > 16.0):
			fit_notes.append({"id": entry.id, "beyond_floor_edge": true, "x": [b.position.x, b.end.x], "z": [b.position.z, b.end.z], "y_above_floor": [b.position.y-y, b.end.y-y]})
		var list: Array = [];parts(node, list)
		for part in list:
			var p: AABB = part[1]
			if maxf(p.size.x, maxf(p.size.y, p.size.z)) < 4.0: continue
			print("  PART ", entry.id, " ", node.get_path_to(part[0]), " x %.2f..%.2f y %.2f..%.2f z %.2f..%.2f" % [p.position.x, p.end.x, p.position.y-y, p.end.y-y, p.position.z, p.end.z])
			# The enclosing sphere's relief is applied in its shader; its mesh AABB is the
			# undisplaced r = 5 m shell. Its collider's displaced vertices give the extent.
			var host: Node = (part[0] as Node).get_parent()
			if str((part[0] as Node).name) == "InnerSurface" and host != null and "displaced_vertices" in host:
				var d: AABB = displaced_bounds(host)
				print("  RELIEF ", entry.id, " x %.2f..%.2f y %.2f..%.2f z %.2f..%.2f" % [d.position.x, d.end.x, d.position.y-y, d.end.y-y, d.position.z, d.end.z])
				if not xr: fit_notes.append({"id": entry.id, "displaced_shell_y_above_floor": [d.position.y-y, d.end.y-y], "x": [d.position.x, d.end.x], "z": [d.position.z, d.end.z]})

func displaced_bounds(host: Node) -> AABB:
	var xf: Transform3D = (host as Node3D).global_transform
	var points: PackedVector3Array = host.get("displaced_vertices")
	if points.is_empty(): return AABB()
	var b := AABB(xf*points[0], Vector3.ZERO)
	for p in points: b = b.expand(xf*p)
	return b

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

## Real pointer press: rack buttons (InteractableAreaButton) via the shared press,
## film keys (an Area3D whose own CollisionShape3D is the target) here.
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

## Real stick/drive walking toward a point until a test holds (bounded).
func walk_until(target: Vector3, test: Callable, limit: int) -> bool:
	for i in limit:
		var at: Vector3 = game.body.global_position
		var offset := Vector2(target.x-at.x, target.z-at.z)
		axes(offset.normalized() if offset.length() > .1 else Vector2.ZERO)
		await frames(1)
		if bool(test.call()):
			axes(Vector2.ZERO);await frames(6);return true
		if game.recovering: break
	axes(Vector2.ZERO);await frames(6)
	return false

func dark_checks(tag: String) -> void:
	for entry in game.building.content.data.floors[level].artifacts:
		if entry.artifact != "dark_sphere": continue
		var orb: Node3D = station(entry.id)
		check(tag+entry.id+" orb builds its body and stays inert in this hall (API)", orb.get("_sphere_mesh") != null and str(orb.call("_gest_stage")) == "")

# ── floor 1: Noise_One ──────────────────────────────────────────────────────

func torus_checks(tag: String) -> void:
	var torus: Node3D = station(TORUS)
	var state: Dictionary = torus.call("pair_state")
	check(tag+"noisetorus builds the source pair: two rings on one bench (API)", str(state.get("stand", "")) == "pair" and (state.get("rings", []) as Array).size() == 2 and torus.get_node_or_null("Pair/Bench") != null)
	var panel: Node3D = torus.get_node_or_null("Pair/Panel")
	var freeze: Node3D = panel.find_child("Btn_0", true, false) if panel != null else null
	if freeze == null:
		check(tag+"noisetorus FREEZE control exists", false);return
	await stand_near(freeze, torus)
	await press(freeze);await frames(6)
	var held: Dictionary = torus.call("pair_state")
	await frames(30)
	var later: Dictionary = torus.call("pair_state")
	check(tag+"FREEZE with real pointer holds the shared ring clock", bool(held.frozen) and is_equal_approx(float(later.time), float(held.time)))
	await press(freeze);await frames(6)
	check(tag+"FREEZE again with real pointer resumes the clock", not bool(torus.call("pair_state").frozen))

func basin_checks(tag: String) -> void:
	var basin: Node3D = station(BASIN)
	var terrain: Node3D = basin.get("terrain")
	var model: Node3D = basin.get_node_or_null("Model")
	check(tag+"noiselayers stands as the source basin: 1:50 model of the three-resource terrain (API)", bool(basin.get("basin")) and terrain != null and model != null and is_equal_approx(model.scale.x, 0.02))
	var panel: Node3D = basin.get_node_or_null("LayerPanel")
	var low: Node3D = panel.find_child("Btn_1", true, false) if panel != null else null
	if low == null or terrain == null:
		check(tag+"noiselayers LOW control exists", false);return
	await stand_near(low, basin)
	await press(low);await frames(10)
	check(tag+"LOW with real pointer isolates the low-frequency resource", int(basin.get("layer_index")) == 1 and float(terrain.get("low_freq_amplitude")) > 0.0 and is_zero_approx(float(terrain.get("med_freq_amplitude"))) and is_zero_approx(float(terrain.get("high_freq_amplitude"))))
	await press(panel.find_child("Btn_0", true, false));await frames(10)
	check(tag+"SUM with real pointer restores all three weights", int(basin.get("layer_index")) == 0 and float(terrain.get("med_freq_amplitude")) > 0.0 and float(terrain.get("high_freq_amplitude")) > 0.0)

func film_checks(tag: String, id: String) -> void:
	var film: Node3D = station(id)
	var stage: Node = film.get("stage")
	var buttons: Dictionary = film.get("buttons")
	if stage == null or not buttons.has("pause"):
		check(tag+id+" film builds its stage and keys", false);return
	# Floor 4's monitor faces the enclosure wall; stand to its side, outside the shell.
	await stand_local(film, Vector3(0, .06, 1.7) if id == FILM1 else Vector3(1.2, .06, 1.0))
	var before: bool = bool(stage.get("running"))
	await press(buttons.pause)
	check(tag+id+" PAUSE with real pointer toggles the filmed stage", bool(stage.get("running")) != before)
	await press(buttons.pause)

## Verify flight lookup excludes a paused floor before and after visiting it,
## and is restored while live. Glass collision remains diagnostic only.
func flight_seam_report(tag: String) -> void:
	await flight_seam_once(tag, "from floor 1")
	game.place_player(game.spawn_for(2));await frames(60)
	var zone: Node3D = exhibit(2, VOXEL).get_node_or_null("FlightBox")
	var flight = load(FLIGHT_SCRIPT)
	check(tag+"live floor restores flight lookup", zone != null and flight.at_point(root.get_tree(), zone.to_global(Vector3(0, 1, 0))) == zone)
	game.place_player(game.spawn_for(1));await frames(60)
	await flight_seam_once(tag, "after visiting floor 2")

func flight_seam_once(tag: String, when: String) -> void:
	var waited: int = await wait_until(func(): return has_exhibit(2, VOXEL), 900)
	if waited < 0:
		check(tag+"flight seam volume loaded: "+when, false);return
	var volume: Node3D = exhibit(2, VOXEL)
	var zone: Node3D = volume.get_node_or_null("FlightBox")
	var flight = load(FLIGHT_SCRIPT)
	var y: float = game.building.spec.levels[1]
	var beyond := Vector3(-6, y+1.0, -17.0)
	var in_zone: bool = flight.at_point(root.get_tree(), beyond) != null
	var wall := ray(Vector3(-6, y+1.0, -15.5), Vector3(-6, y+1.0, -17.0))
	var note := {"floor": 1, "when": when, "point_beyond_north_edge": [beyond.x, beyond.z], "flight_zone_active": in_zone,
		"glass_wall_collision": "none" if wall.is_empty() else str((wall.collider as Node).get_path()),
		"zone_visible": zone.is_visible_in_tree() if zone != null else false, "zone_processing": zone.can_process() if zone != null else false,
		"visitor_checkpoint": game.checkpoint}
	print("FLIGHTSEAM ", tag, note)
	check(tag+"inactive floor excludes flight lookup: "+when, not in_zone and zone != null and flight.at_point(root.get_tree(), zone.to_global(Vector3(0, 1, 0))) == null)
	if not xr: fit_notes.append(note)

# ── floor 2: Noise_Voxel ────────────────────────────────────────────────────

func lattice_checks(tag: String) -> void:
	var bench: Node3D = station(BENCH)
	var volume: Node3D = station(VOXEL)
	var screen: Node3D = station(SCREEN)
	var lattice: Dictionary = bench.call("lattice_state") if bench.has_method("lattice_state") else {}
	check(tag+"bench builds the source lattice: seed 31415, keyboard off (needs R1)", str(bench.get("stand")) == "lattice" and int(lattice.get("seed", -1)) == 31415 and not bool(bench.get("keyboard_shortcuts")) and bench.get("_lattice_root") != null)
	check(tag+"volume keeps 24^3 one-metre cells and its 28 m flight enclosure (API)", str(volume.get("stand")) == "volume" and int(volume.get("chunk_size")) == 24 and int(volume.get("world_height")) == 24 and is_equal_approx(float(volume.get("voxel_scale")), 1.0) and volume.has_node("FlightBox") and is_equal_approx(float(volume.get_node("FlightBox").get("edge_length")), 28.0))
	check(tag+"volume received this floor's bench contract (API)", bool(volume.get("_contract")) and int(volume.get("noise_seed")) == 31415 and not (volume.get("_occupied_cells") as Dictionary).is_empty())
	var slice: Dictionary = screen.call("voxel_slice_data")
	check(tag+"screen draws the live slice from this floor's bench (API)", str(screen.get("_generic_mode_name")) == "voxel_slice" and int(slice.get("seed", -1)) == 31415 and str(slice.get("source", "")) == str(bench.get_path()))
	print("LATTICE ", tag, lattice.get("occupancy", {}), " volume cells=", (volume.get("_occupied_cells") as Dictionary).size(), " rebuild_ms=", volume.get("_rebuild_ms"))
	var panel: Node3D = bench.get_node_or_null("LatticeStand/Panel")
	var cell_button: Node3D = panel.find_child("Btn_1", true, false) if panel != null else null
	if cell_button == null: return
	var before: Vector3i = bench.get("_cell")
	await stand_near(cell_button, bench)
	await press(cell_button);await frames(10)
	var after: Vector3i = bench.get("_cell")
	var marked: Vector3i = volume.get("_selected_cell")
	check(tag+"CELL with real pointer moves the selection, the volume's marker and the screen's section", after != before and marked == after and int(screen.call("voxel_slice_data").get("y", -1)) == after.y)

## The enclosure stands beyond the north edge; its south door meets the slab.
func flight_checks(tag: String) -> void:
	var volume: Node3D = station(VOXEL)
	var zone: Node3D = volume.get_node_or_null("FlightBox")
	if zone == null:
		check(tag+"flight enclosure exists", false);return
	var flight = load(FLIGHT_SCRIPT)
	var y: float = game.building.spec.levels[level]
	var door: Vector3 = zone.to_global(Vector3(0, 0, float(zone.get("edge_length"))*0.5))
	# Start 0.5 m west of the door's axis: the column at (-5, -14) stands beside the route.
	game.place_player(Vector3(door.x-.5, y+.06, -13.0));await frames(25)
	check(tag+"slab approach to the enclosure door is ordinary floor, not flight", flight.at_point(root.get_tree(), game.body.global_position) == null and game.body.is_on_floor())
	var entered: bool = await walk_until(Vector3(door.x-.3, y, door.z-2.5), func(): return flight.at_point(root.get_tree(), game.body.global_position) != null, 300)
	print("FLIGHT ", tag, "door=", door, " entered=", entered, " feet=", game.body.global_position, " recovering=", game.recovering)
	check(tag+"real walking through the south door enters the flight volume", entered and not game.recovering)
	game.place_player(game.spawn_for(level));await frames(20)

# ── floor 3: Noise_6_Wall ───────────────────────────────────────────────────

func panel_checks(tag: String) -> void:
	var panel: Node3D = station(PANEL)
	var room: Node3D = station(ROOM)
	check(tag+"board and five-metre room staged as in the source, no 27 m enclosure (needs R1)", str(panel.get("stand")) == "panel" and str(room.get("stand")) == "room" and panel.get("_panel_root") != null and room.has_node("MuseumRoom") and not panel.has_node("WallsContainer") and not room.has_node("WallsContainer"))
	var controls: Node3D = panel.get_node_or_null("SamplePanel/Panel")
	if controls == null or room.get("room_material") == null: return
	await stand_local(panel, Vector3(0.6, .06, 1.6))
	var before: int = int(panel.get("layers"))
	await press(controls.find_child("Btn_0", true, false));await frames(8)
	var after: int = int(panel.get("layers"))
	var room_mat: ShaderMaterial = room.get("room_material")
	var wall_mat: ShaderMaterial = room.get("wall_material")
	check(tag+"LAYERS with real pointer changes the room's cloud sum on this floor", after != before and int(room_mat.get_shader_parameter("layers")) == after and int(wall_mat.get_shader_parameter("layers")) == after)
	await press(controls.find_child("Btn_2", true, false));await frames(8)
	var held: float = float(room_mat.get_shader_parameter("time"))
	await frames(30)
	check(tag+"FREEZE with real pointer holds the room's clock", bool(panel.call("is_frozen")) and is_equal_approx(float(room_mat.get_shader_parameter("time")), held))
	await press(controls.find_child("Btn_2", true, false));await frames(4)
	for i in 3:
		if int(panel.get("layers")) == before: break
		await press(controls.find_child("Btn_0", true, false));await frames(4)

func room_walk(tag: String) -> void:
	var room: Node3D = station(ROOM)
	if not room.has_node("MuseumRoom"):
		check(tag+"shader room exists for the doorway walk", false);return
	var y: float = game.building.spec.levels[level]
	var outside: Vector3 = room.to_global(Vector3(-4.0, 0, 0));outside.y = y+.06
	var inside: Vector3 = room.to_global(Vector3(0, 0, 0));inside.y = y+.06
	game.place_player(outside);await frames(20)
	var reached: bool = await move_to(inside, false, 300)
	check(tag+"real walking enters the shader room through its side door", reached)

# ── floor 4: Noise_Inside_Noise ─────────────────────────────────────────────

func warp_checks(tag: String) -> void:
	var sphere: Node3D = station(SPHERE)
	var study: Node3D = sphere.get_node_or_null("WarpStudy")
	if study == null:
		check(tag+"noisesphere builds the warp study", false);return
	var enclosure: Node3D = study.get("enclosure")
	check(tag+"warp study keeps both small spheres and the 10 m enclosure with collision (API)", (study.get("spheres") as Array).size() == 2 and enclosure != null and enclosure.has_node("ShellCollision") and (enclosure.get("displaced_vertices") as PackedVector3Array).size() > 0)
	var controls: Node3D = study.get_node_or_null("Controls")
	if controls == null: return
	await stand_local(study, Vector3(2.0, .06, 2.8))
	var strength: int = int(study.get("strength_index"))
	var revision: int = int(study.get("revision"))
	await press(controls.find_child("Btn_0", true, false));await frames(10)
	check(tag+"WARP with real pointer changes the warp and rebuilds the field and shell", int(study.get("strength_index")) != strength and int(study.get("revision")) > revision)
	for i in 4:
		if int(study.get("strength_index")) == strength: break
		await press(controls.find_child("Btn_0", true, false));await frames(6)

func sphere_walk(tag: String) -> void:
	var study: Node3D = station(SPHERE).get_node_or_null("WarpStudy")
	if study == null: return
	var y: float = game.building.spec.levels[level]
	var outside: Vector3 = study.to_global(Vector3(-6.4, 0, 0.2));outside.y = y+.06
	var inside: Vector3 = study.to_global(Vector3(-3.2, 0, 0.6));inside.y = y+.06
	game.place_player(outside);await frames(20)
	var reached: bool = await move_to(inside, false, 300)
	check(tag+"real walking enters the enclosure through its west opening", reached)

## Neighbour-floor heights, measured: floor 5's rooms and strands rise into this
## storey; this floor's enclosure rises into floor 3.
func crossfloor_report(tag: String) -> void:
	for pair in [[5, WOMB], [5, ATRIUM], [5, STRANDS], [4, SPHERE]]:
		var index: int = pair[0]
		var id: String = pair[1]
		var waited: int = await wait_until(func(): return has_exhibit(index, id), 600)
		if waited < 0:
			print("CROSSFLOOR ", tag, id, " not loaded");continue
		var node: Node3D = exhibit(index, id)
		var b: AABB = bounds_of(node)
		var upper: float = game.building.spec.levels[index-1]
		var note := {"id": id, "top_above_upper_floor": b.end.y-upper, "x": [b.position.x, b.end.x], "z": [b.position.z, b.end.z], "visible": node.is_visible_in_tree()}
		print("CROSSFLOOR ", tag, note)
		if not xr: fit_notes.append(note)
	var y3: float = game.building.spec.levels[3]
	var y4: float = game.building.spec.levels[4]
	for probe_at in [Vector3(1, y3+3.0, 0.2), Vector3(-12, y4+4.0, 12.0), Vector3(12, y4+4.0, 12.0)]:
		var hit := ray(probe_at, probe_at+Vector3.DOWN*4.5)
		print("CROSSFLOOR ", tag, "ray down at ", probe_at, " -> ", "none" if hit.is_empty() else "%s at %.2f" % [str((hit.collider as Node).get_path()), hit.position.y])

# ── floor 5: Noise_Cellular ─────────────────────────────────────────────────

func rooms_checks(tag: String) -> void:
	var y: float = game.building.spec.levels[level]
	for id in [WOMB, ATRIUM]:
		var room: Node3D = station(id)
		var generated: Node3D = room.get("generated")
		var membrane: Node = generated.get_node_or_null("Membrane") if generated != null else null
		check(tag+id+" builds its membrane with collision and no floor of its own (API, floor:false)", membrane != null and membrane.get_child_count() >= 2 and not generated.has_node("Floor") and not bool(room.get("create_floor")))
		var front: Vector3 = room.to_global(Vector3(0, 0, 6.0));front.y = y+1.0
		var back: Vector3 = room.to_global(Vector3(0, 0, -6.0));back.y = y+1.0
		var under_front := ray(front, front+Vector3.DOWN*2.0)
		var under_back := ray(back, back+Vector3.DOWN*8.0)
		var note := {"id": id, "layout": room.get("layout"), "build_msec": room.get("build_msec"), "front": [front.x, front.z], "front_support": not under_front.is_empty(), "back": [back.x, back.z], "back_support": not under_back.is_empty()}
		print("ROOM ", tag, note)
		if not xr: fit_notes.append(note)
		check(tag+id+" entrance half stands on the slab (geometry)", not under_front.is_empty())
	var womb: Node3D = station(WOMB)
	var outside: Vector3 = womb.to_global(Vector3(0, 0, 16.0));outside.y = y+.06
	var inside: Vector3 = womb.to_global(Vector3(0, 0, 8.0));inside.y = y+.06
	game.place_player(outside);await frames(20)
	var reached: bool = await move_to(inside, false, 420)
	check(tag+"real walking enters the womb through its entrance", reached)

func strands_checks(tag: String) -> void:
	var net: Node3D = station(STRANDS)
	var kinds: Dictionary = net.get("anchor_kinds")
	var generated: Node3D = net.get("generated")
	check(tag+"strands build the source Voronoi net and anchor it to real surfaces (API)", int(net.get("generation_count")) >= 1 and generated != null and generated.visible and not kinds.is_empty() and (net.get("edges") as Array).size() > 0)
	var y: float = game.building.spec.levels[level]
	var vertices: PackedVector3Array = net.get("vertices")
	var top := -INF
	var low := INF
	var above := 0
	for v in vertices:
		var h: float = net.to_global(v).y-y
		top = maxf(top, h);low = minf(low, h)
		if h > 5.64: above += 1
	var where := {"this slab": 0, "this ceiling": 0, "upper storey": 0, "side surface": 0}
	for id in kinds:
		var h: float = net.to_global(vertices[int(id)]).y-y
		if h < .3: where["this slab"] += 1
		elif absf(h-5.64) < .3: where["this ceiling"] += 1
		elif h > 6.0: where["upper storey"] += 1
		else: where["side surface"] += 1
	# Every anchor in floor coordinates, and whether one lies in a keep-out.
	var listed: Array = []
	var bad: Array = []
	for id in kinds:
		var w: Vector3 = net.to_global(vertices[int(id)])
		listed.append([snappedf(w.x, .01), snappedf(w.y-y, .01), snappedf(w.z, .01), str(kinds[id])])
		for item in zones(level):
			var zone: AABB = item[1]
			if zone.grow(.05).has_point(w): bad.append(str(item[0])+" at "+str(listed.back()))
	print("ANCHORS ", tag, listed)
	if not bad.is_empty(): print("ANCHOR_IN_KEEP_OUT ", tag, bad)
	check(tag+"no strand anchor lies in a shaft opening, the arrival or the floor sign (geometry)", bad.is_empty())
	var weaver: Node = net.get("weaver")
	var note := {"id": STRANDS, "anchors": where, "kinds": kinds.values().size(), "tethers": (net.get("tethers") as Array).size(), "edges": (net.get("edges") as Array).size(),
		"vertex_y_above_floor": [low, top], "vertices_above_ceiling": above, "woven": weaver.get("finished") if is_instance_valid(weaver) else "no weaver", "tension": net.get("tension_active")}
	print("STRANDS ", tag, note)
	if not xr: fit_notes.append(note)

## Diagnostic only: finish the weave by API (the spider takes minutes at 2 m/s)
## and measure whether the released net moves under gravity and tension.
func strands_release(tag: String) -> void:
	var net: Node3D = station(STRANDS)
	var weaver: Node = net.get("weaver")
	if is_instance_valid(weaver) and not bool(weaver.get("finished")): weaver.call("finish")
	await frames(2)
	var start: PackedVector3Array = (net.get("vertices") as PackedVector3Array).duplicate()
	await frames(90)
	var now: PackedVector3Array = net.get("vertices")
	var moved := 0.0
	for i in mini(start.size(), now.size()): moved = maxf(moved, start[i].distance_to(now[i]))
	print("STRANDS_RELEASE ", tag, "tension=", net.get("tension_active"), " max knot travel 90 frames=", moved)
	check(tag+"API-finished net releases into the tension simulation (diagnostic)", bool(net.get("tension_active")))

# ── photographs ─────────────────────────────────────────────────────────────

func capture_floor() -> void:
	var y: float = game.building.spec.levels[level]
	match level:
		1:
			await photo("01-noise-one-arrival-eye", Vector3(0, y+1.65, 12.5), Vector3(-4, y+1.2, 6))
			await photo("02-torus-and-basin", Vector3(-1.2, y+2.6, 11.5), Vector3(-5, y+0.9, 5.5))
		2:
			await photo("03-voxel-arrival-eye", Vector3(0, y+1.65, 12.5), Vector3(-4, y+1.4, 2))
			await photo("04-bench-and-screen", Vector3(-0.5, y+1.9, 10.5), Vector3(-5, y+1.3, 6.5))
			await photo("05-flight-door-eye", Vector3(-6, y+1.65, -11), Vector3(-6, y+2.5, -24))
			await photo("06-voxel-volume-from-slab", Vector3(4, y+5.2, -14.5), Vector3(-6, y+8, -30))
		3:
			await photo("07-wall-arrival-eye", Vector3(0, y+1.65, 12.5), Vector3(-5, y+1.4, 7))
			await photo("08-inside-shader-room", Vector3(-4.2, y+1.6, 6.0), Vector3(-5.2, y+1.3, 9.0))
			await photo("09-floor-4-dome-cap", Vector3(5.5, y+1.7, 6.5), Vector3(1, y+0.5, 0.2))
		4:
			await photo("10-inside-noise-arrival-eye", Vector3(0, y+1.65, 12.5), Vector3(1, y+1.6, 0))
			await photo("11-inside-the-enclosure", Vector3(-2.6, y+1.6, 0.4), Vector3(3.5, y+1.4, 1.6))
			await photo("12-floor-5-room-caps", Vector3(0, y+1.65, 9.5), Vector3(-12, y+0.6, 13))
		5:
			await photo("13-cellular-arrival-eye", Vector3(0, y+1.65, 12.5), Vector3(0, y+2, 2))
			await photo("14-womb-entrance-eye", Vector3(14.5, y+1.65, -0.5), Vector3(14.5, y+2.2, 10))
			await photo("15-atrium-inside-eye", Vector3(-14, y+1.65, 7), Vector3(-14, y+3, 16))
			await photo("16-strands", Vector3(13.5, y+1.65, -3.5), Vector3(17, y+3.5, -10.5)) # aimed at (17, -10.5) after acceptance; not yet re-taken
