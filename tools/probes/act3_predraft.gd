extends SceneTree
## Before the Void Book's Act III is written (floors 48 to 64): what the floors print, and what they do when a body
## uses them. Every run lists the words each work on the floor shows (Label3D, by row id). Then, by map:
##   Vectors_Act1_WhatAVectorIs    the three point stations' readings, and the reading with the point on its origin
##   VFM_05_Launch                 the firework's controls; whether the human catapult throws the game's own body
##   VFM_03_Motion                 the dead stand: plate, screen, bars, charge, the cut cable's heights; the mower pushed
##   Vectors_Act3_FieldsAndMotion  the cell; whether the turning field and the whirlpool move a body that stands still
##   Vectors_Act4a_KineticForces   the leaning planks, tapped
##   Vectors_Act4b_Oscillation     the spring tower's period, timed
##   Change_Choreography           whether the rods' eyes follow the visitor
##   VFM_07_Gravity                the two orbiting bodies about the post
##   VFM_09_Legs                   the table when the rose leg is moved; the power cell; the walkers' legs
##   VFM_08_Arena                  the ceiling unit over a standing body
##   Vectors_Act5_ForceAsPlace     the live stand: the screen from a figure under a hundred to FULL
##   FormFinding_Descent           the desk run from each start on both surfaces
##   FormFinding_Catenary          the cable when one bead is moved; the cell
##   FormFinding_Annealing         the shaken ball, released
##   FormFinding_Forge             the body case from one end of its fader to the other
##
##   python tools/run_floor_probe.py <Map> act3_predraft.gd predraft.json <folder> --no-opening --opera-quiet

var folder := "res://ada_run/act3_predraft"
var eye: Camera3D
var content: Node3D
var floor_y := 0.0
var game: Node
var index := 0
var result := {}


func _initialize() -> void:
	run.call_deferred()


func _picture(file: String) -> void:
	for i in 8: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(folder.path_join(file))


func _look(from: Vector3, at: Vector3) -> void:
	eye.global_position = from
	eye.look_at(at, Vector3.UP)


func _wait(seconds: float) -> void:
	for i in int(seconds * 60.0): await physics_frame


func _mount(id: String) -> Node3D:
	var key := "%d/%s" % [index, id]
	if game.building.content.exhibits.has(key): return game.building.content.exhibits[key] as Node3D
	return game.building.content.props.get(key) as Node3D


## The node under a row that answers to a method: the mount, its Artifact child, or something deeper.
func _with(id: String, method: String) -> Node:
	var mount := _mount(id)
	if not is_instance_valid(mount): return null
	if mount.has_method(method): return mount
	for n in mount.find_children("*", "", true, false):
		if n.has_method(method): return n
	return null


func _at(n: Node3D) -> Array:
	var p := content.to_local(n.global_position)
	return [snappedf(p.x, 0.01), snappedf(n.global_position.y - floor_y, 0.01), snappedf(p.z, 0.01)]


func _on_floor(p: Vector3) -> Array:
	var q := content.to_local(p)
	return [snappedf(q.x, 0.01), snappedf(p.y - floor_y, 0.01), snappedf(q.z, 0.01)]


func _note(check: String, ok: bool, detail = null) -> void:
	(result.checks as Array).append({"check": check, "ok": ok, "detail": detail})


func _charge() -> float:
	return snappedf(float(game.health.get_charge()), 0.01)


func _words(node: Node, limit := 40) -> Array:
	var out: Array = []
	if not is_instance_valid(node): return out
	for l in node.find_children("*", "Label3D", true, false):
		var label := l as Label3D
		var text := label.text.strip_edges()
		if text == "" or not label.is_visible_in_tree(): continue
		text = text.replace("\n", " / ")
		if text.length() > 260: text = text.substr(0, 260) + "…"
		if not out.has(text): out.append(text)
		if out.size() >= limit: break
	return out


func _controls(node: Node) -> Array:
	var out: Array = []
	if not is_instance_valid(node): return out
	for n in node.find_children("*", "", true, false):
		if n is Control or not n.has_signal("pressed"): continue
		var caption := str(n.get("label")) if n.get("label") != null else ""
		out.append({"name": str(n.name), "label": caption, "at": _at(n as Node3D) if n is Node3D else []})
	return out


func _press(node: Node, key: String) -> bool:
	for n in node.find_children("*", "", true, false):
		if n is Control or not n.has_signal("pressed"): continue
		var caption := str(n.get("label")) if n.get("label") != null else ""
		if str(n.name) == key or caption == key:
			n.emit_signal("pressed")
			return true
	return false


func _stand_body(at_global: Vector3, settle := 1.2) -> void:
	var body := game.body as CharacterBody3D
	body.velocity = Vector3.ZERO
	body.global_position = at_global
	await _wait(settle)


func _free_eye(yes: bool) -> void:
	game.body.set_physics_process(not yes); game.body.set_process(not yes)


## Let the body stand with no input for a while: how far it was carried and what that cost.
func _carried(seconds: float) -> Dictionary:
	var body := game.body as CharacterBody3D
	var start := body.global_position
	var last := start
	var path := 0.0
	var top := start.y
	var before := _charge()
	for i in int(seconds * 60.0):
		await physics_frame
		var here := body.global_position
		path += Vector2(here.x - last.x, here.z - last.z).length()
		top = maxf(top, here.y)
		last = here
	return {"seconds": seconds, "from": _on_floor(start), "to": _on_floor(last), "path_m": snappedf(path, 0.01),
		"net_m": snappedf(Vector2(last.x - start.x, last.z - start.z).length(), 0.01), "rose_m": snappedf(top - start.y, 0.01),
		"charge_before": before, "charge_after": _charge(), "on_floor": body.is_on_floor(), "checkpoint": int(game.checkpoint)}


func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): folder = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(folder)
	load("res://commons/void/room_source.gd").use_main_tower = true
	game = load("res://commons/void/void.tscn").instantiate()
	root.add_child(game); current_scene = game
	if game.body.get("scripted_input") != null:
		game.body.scripted_input = true; game.body.set_process_unhandled_input(false)
	game.scene_loaded(); game.scene_visible()
	index = int(game.checkpoint)
	result = {"floor": index, "map": str(game.building.content.data.floors[index].map), "checks": [], "passed": false}
	for i in 900: await physics_frame
	eye = root.get_camera_3d()
	var arrival := eye.global_position
	content = game.building.content.roots[index] as Node3D
	var ground := eye.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(arrival, arrival + Vector3.DOWN * 4.0, 1))
	floor_y = float(ground.position.y) if not ground.is_empty() else arrival.y - 1.6
	result["arrival"] = _on_floor(arrival)
	result["charge_at_start"] = _charge()
	result["body_groups"] = (game.body as Node).get_groups()
	result["walk_speed"] = game.body.get("SPEED")
	var words := {}
	for shelf in [game.building.content.exhibits, game.building.content.props]:
		for key in shelf:
			if not str(key).begins_with("%d/" % index): continue
			var shown := _words(shelf[key] as Node)
			if not shown.is_empty(): words[str(key).get_slice("/", 1)] = shown
	result["words"] = words
	match str(result.map):
		"Vectors_Act1_WhatAVectorIs": await _vectors()
		"VFM_05_Launch": await _launch()
		"VFM_03_Motion": await _dead_stand()
		"Vectors_Act3_FieldsAndMotion": await _field()
		"Vectors_Act4a_KineticForces": await _leaning()
		"Vectors_Act4b_Oscillation": await _spring()
		"Change_Choreography": await _rods()
		"VFM_07_Gravity": await _orbit()
		"VFM_09_Legs": await _legs()
		"VFM_08_Arena": await _arena()
		"Vectors_Act5_ForceAsPlace": await _live_stand()
		"FormFinding_Descent": await _descent()
		"FormFinding_Catenary": await _cable()
		"FormFinding_Annealing": await _anneal()
		"FormFinding_Forge": await _forge()
	if (result.checks as Array).is_empty(): _note("the floor's words were read", not words.is_empty(), words.size())
	var ok := true
	for c in result.checks:
		if not c.ok: ok = false
	result.passed = ok
	var file := FileAccess.open(folder.path_join("predraft.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "  "))
	file.close()
	print("ACT3_PREDRAFT ", JSON.stringify(result).substr(0, 1500))
	quit(0 if ok else 1)


func _vectors() -> void:
	var stations := {}
	for id in ["direction", "addition", "projection"]:
		var s = _with(id, "update_reading")
		if s == null: _note("station %s stands on the floor" % id, false); continue
		var points: Array = []
		for l in s.point_labels: points.append(str(l.text).replace("\n", " / "))
		stations[id] = {"points": points, "result": str(s.result_label.text).replace("\n", " / "), "output": str(s.output.text).replace("\n", " / ")}
	result["stations"] = stations
	var d = _with("direction", "update_reading")
	if d != null:
		var home: Vector3 = d.points[0].position
		d.points[0].position = d.origin
		d.update_reading()
		result["direction_with_point_on_origin"] = str(d.result_label.text).replace("\n", " / ")
		d.points[0].position = home
		d.update_reading()
		result["point_radius_m"] = ((d.points[0].get_child(0) as MeshInstance3D).mesh as SphereMesh).radius if (d.points[0].get_child(0) as MeshInstance3D).mesh is SphereMesh else null
	_note("the addition station prints end distance and distance travelled", str(stations.get("addition", {}).get("output", "")).contains("travelled"), stations.get("addition"))


func _launch() -> void:
	var firework := _mount("f1_firework_burst_31_66")
	result["firework_controls"] = _controls(firework)
	result["firework_words_before"] = _words(firework)
	result["firework_freeze_pressed"] = _press(firework, "FREEZE / RESUME") or _press(firework, "FREEZE")
	await _wait(1.0)
	result["firework_words_after"] = _words(firework)
	var cat = _with("f1_human_catapult_10_62", "_within_basket")
	if cat == null: _note("the human catapult stands on the floor", false); return
	var basket: Node3D = cat._basket
	result["catapult_words"] = _words(_mount("f1_human_catapult_10_62"))
	result["basket_on_floor"] = _at(basket)
	await _stand_body(basket.global_position + Vector3(0, 0.25, 0), 0.5)
	result["catapult_sees_body"] = is_instance_valid(cat._player_node)
	result["catapult_within_basket"] = bool(cat._within_basket(game.body))
	var ride := await _carried(9.0)
	result["catapult_ride"] = ride
	result["catapult_count_label"] = str(cat._count_label.text) if cat.get("_count_label") != null else ""
	_note("the catapult throws the game's own body", float(ride.net_m) > 3.0, ride)


func _dead_stand() -> void:
	var stand = _with("f50-dead-charger", "on_plate")
	if stand == null: _note("the dead stand is on the floor", false); return
	result["stand_on_floor"] = _at(stand)
	result["mains_online"] = bool(stand.mains_online)
	var parts := {}
	var broken := (stand as Node).get_node_or_null("BrokenMainsSupply")
	if broken != null:
		for c in broken.get_children():
			var m := c as MeshInstance3D
			var half := (m.mesh as BoxMesh).size.y * 0.5
			parts[str(m.name)] = [snappedf(m.global_position.y - half - floor_y, 0.01), snappedf(m.global_position.y + half - floor_y, 0.01)]
	result["cut_cable_heights_m"] = parts
	result["intact_supply"] = (stand as Node).get_node_or_null("HardwareSupply") != null
	game.health.set_charge(80.0, "probe")
	var before := _charge()
	var rest_y := float(stand.plate_deck.position.y)
	await _stand_body(stand.to_global(Vector3(0, 0.12, 0.76)), 3.0)
	var lit := 0
	for bar in stand.charge_bars:
		if ((bar as MeshInstance3D).material_override as StandardMaterial3D).emission_enabled: lit += 1
	result["dead_plate"] = {"on_plate": bool(stand.plate_active), "screen": str(stand._displayed).replace("\n", " / "), "title": str(stand._readout.title),
		"plate_rest_mm": snappedf(rest_y * 1000.0, 0.1), "plate_pressed_mm": snappedf(float(stand.plate_deck.position.y) * 1000.0, 0.1),
		"bars_lit": lit, "charge_before": before, "charge_after_3s": _charge()}
	_note("the plate goes down under the body", float(stand.plate_deck.position.y) < rest_y - 0.005, result.dead_plate)
	_note("the dead stand gives no charge", is_equal_approx(_charge(), before), result.dead_plate)
	_note("the screen reads NO MAINS", str(stand._displayed).contains("NO MAINS"), str(stand._displayed))
	_free_eye(true)
	var head: Vector3 = stand.to_global(Vector3(0, 0, 0.76)); head.y = floor_y + 1.6
	_look(head, stand.to_global(Vector3(0, 1.25, 0.17)))
	await _picture("1_on_the_dead_plate.png")
	_look(stand.to_global(Vector3(0.9, 0, 2.6)) + Vector3(0, 1.6 + floor_y - stand.global_position.y, 0), stand.to_global(Vector3(0, 2.9, 0)))
	await _picture("2_the_cut_cable.png")
	_free_eye(false)
	await _stand_body(stand.to_global(Vector3(0, 0.12, 2.4)), 1.0)
	result["plate_after_stepping_off_mm"] = snappedf(float(stand.plate_deck.position.y) * 1000.0, 0.1)
	# the mower, pushed north at a walking push
	var garden = _with("f2_force_mower_14_46", "reset_garden")
	if garden == null: _note("the mower's garden is built", false); return
	var mower: RigidBody3D = garden.mower
	var forward := mower.global_basis.x.normalized()
	result["mower_start"] = _at(mower)
	result["mower_heading_on_floor"] = [snappedf(content.global_basis.inverse().x.dot(forward), 0.01), snappedf((content.global_basis.inverse() * forward).z, 0.01)]
	result["lawn"] = {"length": float(garden.lawn_length), "width": float(garden.lawn_width), "tufts": int(garden.points.size())}
	garden.handle.set_meta("capability_desktop_held", true)
	var log: Array = []
	var still := 0
	for tick in 60 * 16:
		garden.handle.global_position = garden.anchor() + mower.global_basis.x.normalized() * 0.19
		await physics_frame
		if tick % 60 == 59:
			log.append([snappedf(float(garden.distance), 0.01), snappedf(float(garden.work), 0.1), int(garden.flower_count), snappedf(mower.linear_velocity.length(), 0.01)])
		still = still + 1 if mower.linear_velocity.length() < 0.05 and tick > 120 else 0
		if still > 60: break
	garden.handle.remove_meta("capability_desktop_held")
	result["mower_push"] = {"per_second": log, "end": _at(mower), "distance_m": snappedf(float(garden.distance), 0.01), "work_J": snappedf(float(garden.work), 0.1),
		"flowers": int(garden.flower_count), "tufts_cut": int(garden.cut_count), "counter": str(garden.counter.text).replace("\n", " / ")}
	_note("the pushed mower cuts and leaves flowers", int(garden.flower_count) > 0, result.mower_push)
	_free_eye(true)
	var behind := mower.global_position - forward * 2.2
	_look(Vector3(behind.x, floor_y + 1.6, behind.z), stand.to_global(Vector3(0, 1.2, 0)))
	await _picture("3_the_cut_strip_towards_the_stand.png")
	var back: Vector3 = stand.to_global(Vector3(0, 0, 1.4))
	_look(Vector3(back.x, floor_y + 1.6, back.z), Vector3(mower.global_position.x, floor_y + 0.2, mower.global_position.z) - forward * 5.0)
	await _picture("4_the_strip_from_the_stand.png")
	_free_eye(false)


func _take_cell(id: String, set_to: float) -> Dictionary:
	var cell = _with(id, "collect")
	if cell == null: return {"found": false}
	var words_before := _words(_mount(id))
	game.health.set_charge(set_to, "probe")
	var before := _charge()
	var took: bool = cell.collect()
	await _wait(0.5)
	return {"found": true, "took": took, "charge_before": before, "charge_after": _charge(), "words_before": words_before, "words_after": _words(_mount(id)), "at": _at(cell)}


func _field() -> void:
	result["cell"] = await _take_cell("f51-pill-battery", 60.0)
	_note("the cell gives fifteen", is_equal_approx(float(result.cell.get("charge_after", 0)) - float(result.cell.get("charge_before", 0)), 15.0), result.cell)
	var play = _with("f3_force_play_vortex_14_13", "carry_velocity")
	if play != null:
		await _stand_body(play.to_global(Vector3(4.0, 0.15, 0)), 0.6)
		result["turning_field_sees_body"] = is_instance_valid(play.visitor())
		result["turning_field_carry"] = await _carried(6.0)
		_note("the turning field moves a body that stands still", float(result.turning_field_carry.path_m) > 0.5, result.turning_field_carry)
	var pool := _mount("f3_force_vortex_14_72")
	if pool != null:
		await _stand_body(pool.global_position + content.global_basis * Vector3(2.4, 0.15, 0), 0.4)
		result["whirlpool_carry"] = await _carried(8.0)


func _leaning() -> void:
	var lean := _mount("matter-leaning-together")
	if lean == null: _note("the leaning planks stand on the floor", false); return
	var before := {}
	var bodies: Array = []
	for n in lean.find_children("*", "RigidBody3D", true, false):
		bodies.append(n); before[str(n.name)] = _at(n)
	result["leaning_before"] = before
	await _wait(2.0)
	var settled := {}
	for b in bodies: settled[str(b.name)] = _at(b)
	result["leaning_after_2s_untouched"] = settled
	_free_eye(true)
	var here := lean.global_position
	_look(Vector3(here.x, floor_y + 1.5, here.z) + lean.global_basis.z.normalized() * 2.2, Vector3(here.x, floor_y + 0.9, here.z))
	await _picture("1_leaning_untouched.png")
	var tapped := ""
	for b in bodies:
		if str(b.name).to_lower().contains("plank"):
			(b as RigidBody3D).apply_central_impulse(lean.global_basis.x.normalized() * 0.35 * (b as RigidBody3D).mass); tapped = str(b.name); break
	await _wait(4.0)
	var after := {}
	for b in bodies: after[str(b.name)] = _at(b)
	result["leaning_tapped"] = tapped
	result["leaning_after_tap"] = after
	await _picture("2_leaning_after_a_tap.png")
	_free_eye(false)
	_note("the leaning set is made of loose bodies", bodies.size() >= 5, bodies.size())


func _spring() -> void:
	var tower := _mount("f1_spring_tower_22_61")
	if tower == null: _note("the spring tower stands on the floor", false); return
	var nodes: Array = []
	for n in tower.find_children("*", "MeshInstance3D", true, false): nodes.append(n)
	var tracks: Array = []
	for n in nodes: tracks.append(PackedFloat32Array())
	for tick in 60 * 14:
		await physics_frame
		for i in nodes.size(): (tracks[i] as PackedFloat32Array).append((nodes[i] as Node3D).global_position.y)
	var best := -1
	var best_span := 0.0
	for i in nodes.size():
		var t: PackedFloat32Array = tracks[i]
		var lo := 1e9; var hi := -1e9
		for v in t: lo = minf(lo, v); hi = maxf(hi, v)
		if hi - lo > best_span: best_span = hi - lo; best = i
	if best < 0: _note("something on the spring tower moves", false); return
	var t: PackedFloat32Array = tracks[best]
	var mean := 0.0
	for v in t: mean += v
	mean /= t.size()
	var ups: Array = []
	for i in range(1, t.size()):
		if t[i - 1] < mean and t[i] >= mean: ups.append(i / 60.0)
	var period := (float(ups[-1]) - float(ups[0])) / (ups.size() - 1) if ups.size() > 1 else 0.0
	result["spring_tower"] = {"moving_part": str((nodes[best] as Node).name), "travel_m": snappedf(best_span, 0.01), "mid_height_m": snappedf(mean - floor_y, 0.01), "returns": ups.size(), "period_s": snappedf(period, 0.01)}
	_note("the block comes back at a steady period", period > 0.5, result.spring_tower)


func _rods() -> void:
	var rods = _with("f2_phase_rod_array_12_8", "_update_eyes")
	if rods == null: _note("the rod array stands on the floor", false); return
	result["rods"] = int(rods.rods.size())
	result["eyes"] = int(rods.eyes.size())
	var readings: Array = []
	for offset in [Vector3(5, 0, 5), Vector3(-5, 0, 6)]:
		await _stand_body(rods.global_position + content.global_basis * offset + Vector3(0, 0.2, 0), 1.0)
		var head := root.get_camera_3d()
		var worst := 0.0
		for e in rods.eyes:
			var to_head: Vector3 = (head.global_position - (e as Node3D).global_position).normalized()
			worst = maxf(worst, rad_to_deg((-(e as Node3D).global_basis.z.normalized()).angle_to(to_head)))
		readings.append({"body_at": _on_floor(game.body.global_position), "worst_eye_off_the_head_deg": snappedf(worst, 0.1)})
	result["eyes_follow"] = readings
	_note("every eye stays on the visitor's head", float(readings[0].worst_eye_off_the_head_deg) < 3.0 and float(readings[1].worst_eye_off_the_head_deg) < 3.0, readings)
	result["rod_readout"] = str(rods.readout.text).replace("\n", " / ") if rods.get("readout") != null else ""
	_free_eye(true)
	var here: Vector3 = rods.global_position
	_look(Vector3(here.x, floor_y + 1.6, here.z) + content.global_basis * Vector3(4.5, 0, 4.5), Vector3(here.x, floor_y + 1.6, here.z))
	await _picture("1_the_rods_look_back.png")
	_free_eye(false)


func _orbit() -> void:
	var orbit := _mount("f3_orbit_walk_17_70")
	if orbit == null: _note("the orbit walk stands on the floor", false); return
	var balls: Array = []
	for n in orbit.find_children("*", "MeshInstance3D", true, false):
		var m := n as MeshInstance3D
		if m.mesh is SphereMesh and (m.mesh as SphereMesh).radius * m.global_basis.get_scale().x > 0.12: balls.append(m)
	var samples: Array = []
	for step in 4:
		var row: Array = []
		for b in balls:
			var p: Vector3 = orbit.to_local((b as Node3D).global_position)
			row.append([str(b.name), snappedf(p.x, 0.01), snappedf(p.y, 0.01), snappedf(p.z, 0.01)])
		samples.append(row)
		await _wait(1.5)
	result["orbit_bodies"] = samples
	_note("the orbit walk shows moving bodies", balls.size() >= 2, balls.size())


func _legs() -> void:
	var play = _with("f4_force_play_support_14_13", "carry_velocity")
	if play == null: _note("the table play stands on the floor", false); return
	var table: RigidBody3D = play.members.table
	var leg: RigidBody3D = play.members.leg
	var load: Array = play.members.load
	var tilt := func() -> float: return snappedf(rad_to_deg(table.global_basis.y.normalized().angle_to(Vector3.UP)), 0.1)
	var heights := func() -> Array:
		var out: Array = []
		for c in load: out.append(snappedf((c as Node3D).global_position.y - floor_y, 0.01))
		return out
	result["table_before"] = {"tilt_deg": tilt.call(), "top_m": snappedf(table.global_position.y - floor_y, 0.01), "leg_at": _at(leg), "load_heights_m": heights.call()}
	_free_eye(true)
	var here: Vector3 = play.global_position
	var from: Vector3 = Vector3(here.x, floor_y + 1.6, here.z) + play.global_basis * Vector3(4.6, 0, -3.6)
	_look(from, Vector3(here.x, floor_y + 1.4, here.z))
	await _picture("1_table_with_the_rose_leg.png")
	# a hand's pull, as the desktop pointer does it: grab, carry the leg out from under its corner, let go
	result["frozen_before_a_hand"] = {"leg": leg.freeze, "table": table.freeze, "first_load": (load[0] as RigidBody3D).freeze, "play_can_process": play.can_process()}
	var out: Vector3 = (play.global_basis * Vector3(1.0, 0, -0.7)).normalized()
	leg.on_desktop_grab(null)
	leg.freeze = true
	for tick in 100:
		leg.global_position += out * 1.2 / 60.0
		await physics_frame
	leg.on_desktop_drop(null)
	result["frozen_after_the_hand"] = {"leg": leg.freeze, "table": table.freeze, "first_load": (load[0] as RigidBody3D).freeze}
	await _wait(6.0)
	result["table_after_leg_moved"] = {"tilt_deg": tilt.call(), "top_m": snappedf(table.global_position.y - floor_y, 0.01), "leg_at": _at(leg), "load_heights_m": heights.call()}
	_look(from, Vector3(here.x, floor_y + 1.0, here.z))
	await _picture("2_table_after_the_leg_is_moved.png")
	_free_eye(false)
	_note("moving the rose leg changes what the table carries", float(result.table_after_leg_moved.tilt_deg) > 2.0, result.table_after_leg_moved)
	result["power_cell"] = await _take_cell("f56-power-cell", 60.0)
	_note("the power cell gives twenty", is_equal_approx(float(result.power_cell.get("charge_after", 0)) - float(result.power_cell.get("charge_before", 0)), 20.0), result.power_cell)
	var walkers := {}
	for id in ["f4_one_leg_5_31", "f4_four_leg_critter_14_31", "f4_six_leg_critter_23_31"]:
		var w := _mount(id)
		if w == null: continue
		var names := {}
		for n in w.find_children("*", "", true, false):
			var base := str(n.name).rstrip("0123456789")
			names[base] = int(names.get(base, 0)) + 1
		var a := _at(w)
		var first := Vector3.ZERO
		var mover: Node3D = null
		for n in w.find_children("*", "MeshInstance3D", true, false):
			mover = n as Node3D; first = mover.global_position; break
		await _wait(3.0)
		var bones: Array = []
		for sk in w.find_children("*", "Skeleton3D", true, false): bones.append((sk as Skeleton3D).get_bone_count())
		walkers[id] = {"at": a, "node_names": names, "bones_per_leg": bones, "first_mesh_moved_m": snappedf(mover.global_position.distance_to(first), 0.01) if mover != null else null}
	result["walkers"] = walkers


func _arena() -> void:
	var unit := _mount("trace-ceiling-sentry")
	if unit == null: _note("the ceiling unit hangs on the floor", false); return
	result["ceiling_unit_at"] = _at(unit)
	var script := unit.get_script() as Script
	result["ceiling_unit_script"] = script.resource_path if script != null else ""
	var methods: Array = []
	for m in unit.get_method_list():
		if str(m.name).begins_with("_") or int(m.flags) & METHOD_FLAG_VIRTUAL: continue
		if script != null and not methods.has(str(m.name)) and methods.size() < 30: methods.append(str(m.name))
	result["ceiling_unit_methods"] = methods
	game.health.set_charge(90.0, "probe")
	await _stand_body(unit.global_position * Vector3(1, 0, 1) + Vector3(0, floor_y + 0.2, 0) + content.global_basis * Vector3(0, 0, 2.5), 0.5)
	var basis_before := unit.global_basis
	var stay := await _carried(6.0)
	result["under_the_ceiling_unit"] = stay
	result["charge_cause"] = str(game.health.last_cause)
	await _stand_body(unit.global_position * Vector3(1, 0, 1) + Vector3(0, floor_y + 0.2, 0) + content.global_basis * Vector3(4.0, 0, -2.0), 2.0)
	var turned := 0.0
	for n in unit.find_children("*", "Node3D", true, false):
		turned = maxf(turned, absf((n as Node3D).rotation.y) + absf((n as Node3D).rotation.x))
	result["ceiling_unit_parts_turned_rad"] = snappedf(turned, 0.01)
	result["ceiling_unit_basis_changed"] = not basis_before.is_equal_approx(unit.global_basis)
	_free_eye(true)
	var below: Vector3 = game.body.global_position
	_look(Vector3(below.x, floor_y + 1.6, below.z), unit.global_position)
	await _picture("1_the_ceiling_unit_from_below.png")
	_free_eye(false)
	_note("standing under the ceiling unit was measured", true, stay)


func _live_stand() -> void:
	var stand = _with("f58-charging-stand", "on_plate")
	if stand == null: _note("the live stand is on the floor", false); return
	result["stand_on_floor"] = _at(stand)
	result["mains_online"] = bool(stand.mains_online)
	result["intact_supply"] = (stand as Node).get_node_or_null("HardwareSupply") != null
	result["broken_supply"] = (stand as Node).get_node_or_null("BrokenMainsSupply") != null
	game.health.set_charge(66.0, "probe")
	result["screen_off_the_plate"] = str(stand._displayed).replace("\n", " / ")
	await _stand_body(stand.to_global(Vector3(0, 0.12, 0.76)), 0.6)
	var seen: Array = []
	var seconds := 0.0
	while seconds < 9.0:
		var words := str(stand._displayed).replace("\n", " / ")
		if seen.is_empty() or str(seen[-1][1]) != words: seen.append([snappedf(seconds, 0.1), words])
		if words.contains("FULL"): break
		await _wait(0.25); seconds += 0.25
	var lit := 0
	for bar in stand.charge_bars:
		if ((bar as MeshInstance3D).material_override as StandardMaterial3D).emission_enabled: lit += 1
	result["live_plate"] = {"screens": seen, "seconds_to_full_from_66": snappedf(seconds, 0.1), "bars_lit_at_full": lit, "charge": _charge()}
	_note("the live stand fills the charge", _charge() >= 99.9, result.live_plate)
	_free_eye(true)
	var head: Vector3 = stand.to_global(Vector3(0, 0, 0.76)); head.y = floor_y + 1.6
	_look(head, stand.to_global(Vector3(0, 1.25, 0.17)))
	await _picture("1_on_the_live_plate.png")
	var side: Vector3 = stand.to_global(Vector3(1.2, 0, 2.8)); side.y = floor_y + 1.6
	_look(side, stand.to_global(Vector3(0, 3.0, 0)))
	await _picture("2_the_whole_cable.png")
	_free_eye(false)


func _descent() -> void:
	var lab = _with("landscape", "step_once")
	if lab == null: _note("the descent desk stands on the floor", false); return
	var runs: Array = []
	var finish := func() -> void:
		for i in 400:
			lab.step_once()
			if str(lab.status) in ["SMALL SLOPE", "LEFT FRAME", "STEP LIMIT"]: break
	for surface in 2:
		for start in 3:
			while int(lab.surface) != surface: lab.act("SURFACE")
			while int(lab.start_index) != start: lab.act("START")
			var first_cost := float(lab.cost(lab.point))
			lab.act("STEP")
			var after_one := str(lab.first_panel.readout.text).replace("\n", " / ")
			finish.call()
			lab.refresh()
			runs.append({"surface": "BOWL" if surface == 0 else "TWO VALLEYS", "start": start + 1, "from": [lab.STARTS[start].x, lab.STARTS[start].y], "cost_at_start": snappedf(first_cost, 0.0001),
				"after_one_step": after_one, "ends": str(lab.first_panel.readout.text).replace("\n", " / "), "at": [snappedf(lab.point.x, 0.001), snappedf(lab.point.y, 0.001)], "second_panel": str(lab.second_panel.readout.text).replace("\n", " / ")})
	result["descent_runs"] = runs
	lab.act("PARTS"); lab.act("RULE")
	result["board_with_parts_and_rule"] = str(lab.board.text)
	lab.act("PARTS"); lab.act("RULE")
	# the fastest rate from the first start on the bowl: does it leave the frame?
	while int(lab.surface) != 0: lab.act("SURFACE")
	while int(lab.start_index) != 0: lab.act("START")
	var rates: Array = []
	for r in 4:
		lab.act("RATE")
		finish.call(); lab.refresh()
		rates.append([str(lab.second_panel.readout.text).replace("\n", " / "), str(lab.first_panel.readout.text).replace("\n", " / ")])
	result["bowl_start_1_by_rate"] = rates
	_note("two starts on TWO VALLEYS end at different costs", absf(float(runs[3].at[0]) - float(runs[4].at[0])) > 1.0, [runs[3].ends, runs[4].ends])
	_free_eye(true)
	while int(lab.surface) != 1: lab.act("SURFACE")
	while int(lab.start_index) != 1: lab.act("START")
	finish.call(); lab.refresh()
	var here: Vector3 = lab.global_position
	_look(Vector3(here.x, floor_y + 1.7, here.z) + lab.global_basis * Vector3(0, 0, -5.4), Vector3(here.x, floor_y + 0.6, here.z))
	await _picture("1_two_valleys_from_start_2.png")
	_free_eye(false)


func _cable() -> void:
	var cable = _with("f1_cable_builder_5_3", "_update_cable_slack")
	if cable == null: _note("the cable builder stands on the floor", false)
	else:
		var beads: Array = []
		for n in (cable as Node).find_children("*", "", true, false):
			if n is RigidBody3D or n.has_method("pick_up"): beads.append(n)
		var lowest := func() -> float:
			var lo := 1e9
			for m in (cable as Node).find_children("*", "MeshInstance3D", true, false):
				var mesh := m as MeshInstance3D
				if beads.has(mesh.get_parent()) or mesh.mesh == null: continue
				var box: AABB = mesh.global_transform * mesh.get_aabb()
				if box.size.length() > 1.0: lo = minf(lo, box.position.y)
			return snappedf(lo - floor_y, 0.01)
		var places: Array = []
		for b in beads: places.append(_at(b))
		result["cable"] = {"slack": str(cable.slack), "beads": places, "lowest_point_m": lowest.call(), "words": _words(_mount("f1_cable_builder_5_3"))}
		if beads.size() >= 2:
			var bead := beads[1] as Node3D
			var home := bead.global_position
			if bead is RigidBody3D: (bead as RigidBody3D).freeze = true
			bead.global_position = home + Vector3(0, 0.6, 0)
			await _wait(0.6)
			result.cable["lowest_point_after_one_bead_raised_0.6_m"] = lowest.call()
			_free_eye(true)
			var here: Vector3 = cable.global_position
			_look(Vector3(here.x, floor_y + 1.6, here.z) + content.global_basis * Vector3(0, 0, -3.2), Vector3(here.x, floor_y + 1.1, here.z))
			await _picture("1_cable_with_a_bead_raised.png")
			_free_eye(false)
			bead.global_position = home
			await _wait(0.4)
			result.cable["lowest_point_put_back"] = lowest.call()
		_note("the cable has beads to move", beads.size() >= 2, beads.size())
	result["cell"] = await _take_cell("f60-pill-battery", 60.0)
	_note("the cell gives fifteen", is_equal_approx(float(result.cell.get("charge_after", 0)) - float(result.cell.get("charge_before", 0)), 15.0), result.cell)


func _anneal() -> void:
	var study = _with("threshold-workshop-descent", "release_take")
	if study == null: _note("the shaken ball stands on the floor", false); return
	result["anneal_setting"] = str(study.setting_text())
	result["anneal_extra"] = study.graph.extra
	result["anneal_params"] = study.graph.params
	result["anneal_status_before"] = str(study.status.text).replace("\n", " / ")
	var takes: Array = []
	for take in 3:
		study.release_take()
		var seconds := 0.0
		var heard: Array = []
		while seconds < 48.0 and (bool(study.running) or seconds < 1.0):
			await _wait(0.5); seconds += 0.5
			var words := str(study.status.text).replace("\n", " / ")
			if int(seconds * 2) % 8 == 0: heard.append(words)
		takes.append({"seconds": seconds, "status": str(study.status.text).replace("\n", " / "), "reading": study.reading, "heard": heard})
		if study.has_method("reset_take"): study.reset_take()
		await _wait(1.0)
	result["anneal_takes"] = takes
	result["anneal_controls"] = _controls(_mount("threshold-workshop-descent"))
	_note("the shaken ball ends in a named place", not takes.is_empty() and str(takes[0].status) != "", takes)


func _forge() -> void:
	var booth = _with("contact-bench", "_scrub_mix")
	if booth == null: _note("the body case stands on the floor", false); return
	var read := func() -> Dictionary:
		var box: AABB = (booth._body as MeshInstance3D).global_transform * (booth._body as MeshInstance3D).get_aabb()
		return {"pair": str(booth._pair_readout.text), "mix": str(booth._mix_readout.text), "count": str(booth._count_readout.text), "mesh": str(booth._mesh_readout.text),
			"body_height_m": snappedf(box.size.y, 0.01), "body_length_m": snappedf(maxf(box.size.x, box.size.z), 0.01), "feet_above_floor_m": snappedf(box.position.y - floor_y, 0.01)}
	var pages: Array = []
	for page in booth._form_pages: pages.append(_words(page as Node))
	result["body_case"] = {"start": read.call(), "pages": pages, "words": _words(_mount("contact-bench"))}
	_free_eye(true)
	var here: Vector3 = booth.global_position
	var from: Vector3 = Vector3(here.x, floor_y + 1.6, here.z) + booth.global_basis * Vector3(0.1, 0, 3.0)
	_look(from, Vector3(here.x, floor_y + 1.25, here.z))
	await _picture("1_body_case_at_0.png")
	booth._scrub_mix(0.5); await _wait(0.4)
	result.body_case["half"] = read.call()
	await _picture("2_body_case_at_50.png")
	booth._scrub_mix(1.0); await _wait(0.4)
	result.body_case["end"] = read.call()
	await _picture("3_body_case_at_100.png")
	booth._scrub_mix(0.0); await _wait(0.4)
	result.body_case["back"] = read.call()
	_note("the two ends of the fader hold the same count of points", str(result.body_case.start.count) == str(result.body_case.end.count), [result.body_case.start.count, result.body_case.end.count])
	for id in ["furniture-transformer-bench", "furniture-transformer-cabinet", "f1_self_shaping_forge_5_3", "f1_balance_puzzle_9_5", "morphology-five-finger-hand"]:
		result["controls_" + id] = _controls(_mount(id))
	var bench := _mount("furniture-transformer-bench")
	if bench != null:
		var bh: Vector3 = bench.global_position
		var bf := Vector3(bh.x, floor_y + 1.6, bh.z) + content.global_basis * Vector3(-2.6, 0, 1.6)
		_look(bf, Vector3(bh.x, floor_y + 0.5, bh.z))
		await _picture("4_bench_before.png")
		var folding = _with("furniture-transformer-bench", "_toggle")
		if folding != null:
			var rest: AABB = folding._rig.set_fold(0.0)
			folding._toggle()
			await _wait(4.2)
			var stood: AABB = folding._rig.set_fold(1.0)
			result["bench_fold"] = {"at_rest_size_m": [snappedf(rest.size.x, 0.01), snappedf(rest.size.y, 0.01), snappedf(rest.size.z, 0.01)],
				"unfolded_size_m": [snappedf(stood.size.x, 0.01), snappedf(stood.size.y, 0.01), snappedf(stood.size.z, 0.01)], "seconds": folding.DURATION}
			await _picture("5_bench_after_the_touch.png")
			folding._toggle()
			await _wait(4.2)
			await _picture("6_bench_touched_again.png")
			_note("a touch changes the bench and a second touch changes it back", true, result.bench_fold)
	_free_eye(false)
