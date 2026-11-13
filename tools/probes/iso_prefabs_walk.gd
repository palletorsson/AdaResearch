extends SceneTree
## THE TWENTY ISOSURFACE PREFABS, WALKED AND PLAYED (Boolean_Verbs, the boolean floor; 2026-11-13)
## Read in the running tower with its own walker and real rigid balls (rubber ball r 0.11, trace ball r 0.14 - the
## kit's sizes), against tools/iso_prefabs.py's checks:
##   every piece mounted, drawn, with collision;
##   a body walks THROUGH the tunnel, the crossing (south door, room, east door), into the dome and out, through the
##   thresholds' door - and not through the wall beside it;
##   a body walks OVER the hump bridge, the mound, the stones, the stile's smoothed half - and is stopped by the stile's
##   plain union of steps (connected, not passable); UP the spiral ramp to a metre and back down; up the gutter ramp;
##   the gyroid screen and the boulder stop a body;
##   a rubber ball rolls under the thresholds' wall and through the bridge's culvert, a trace ball does not pass the
##   mousehole; the sieve lets a rubber ball through and keeps a trace ball above it; three balls leave the funnel one
##   by one; a ball let go at the top of the chute ends in the basin; a trace ball dropped in the pipe tee leaves by an
##   end; a ball runs down the gutter; the basin keeps a ball;
##   the die, thrown, lands flat on a face; the cast, dropped over the mould, settles in its cup;
##   the landing's way off is still clear.
##
##   godot --path <stage> --script res://tools/probes/iso_prefabs_walk.gd -- --no-bridges --void-start-floor=<161> --out=<dir>
##
## iso.json: one check each, with what was read; pictures of the two wings, the yard, inside the dome, the ramp's top.
const PREFIX := "iso-"
var game: Node3D
var body: CharacterBody3D
var level := 0.0
var floor_index := 0
var works := {}
var eye: SubViewport
var cam: Camera3D
var balls: Array[RigidBody3D] = []


func _initialize() -> void:
	run.call_deferred()


func _shot(at: Vector3, target: Vector3, path: String) -> void:
	cam.global_position = at
	cam.look_at(target, Vector3.UP)
	for i in 8: await process_frame
	eye.get_texture().get_image().save_png(path)


func _w(form: String) -> Node3D:
	return works.get(form)


func _at(form: String, x: float, z: float, y: float = 0.0) -> Vector3:
	return _w(form).to_global(Vector3(x, y, z))


func _local(form: String, p: Vector3) -> Vector3:
	return _w(form).to_local(p)


func _place(p: Vector3) -> void:
	game.place_player(Vector3(p.x, level + 0.12, p.z))
	for i in 30: await physics_frame


## Walk a path of points without stopping between them; returns the highest the feet rose and whether the last point
## was reached. A body that does not move for 80 ticks has been stopped.
func _path(points: Array, speed: float = 0.5, near: float = 0.22, ticks_max: int = 2400) -> Dictionary:
	var top := -1.0
	var still := 0
	var last := body.global_position
	var i := 0
	for tick in ticks_max:
		if i >= points.size(): break
		var target: Vector3 = points[i]
		var flat := Vector2(body.global_position.x, body.global_position.z).distance_to(Vector2(target.x, target.z))
		if flat < (0.1 if i == points.size() - 1 else near):
			i += 1
			continue
		body.look_at(Vector3(target.x, body.global_position.y, target.z), Vector3.UP)
		body.drive = Vector2(0, -speed)
		await physics_frame
		top = maxf(top, body.global_position.y - level)
		if body.global_position.distance_to(last) < 0.002: still += 1
		else: still = 0
		last = body.global_position
		if still > 80: break
	body.drive = Vector2.ZERO
	for t in 12: await physics_frame
	return {"reached": i >= points.size(), "top": snappedf(top, 0.01), "end": body.global_position}


func _line(form: String, a: Vector2, b: Vector2, n: int = 8) -> Array:
	var out := []
	for k in n + 1:
		var p := a.lerp(b, float(k) / float(n))
		out.append(_at(form, p.x, p.y))
	return out


func _ball(radius: float, at: Vector3, velocity: Vector3 = Vector3.ZERO) -> RigidBody3D:
	var b := RigidBody3D.new()
	var shape := CollisionShape3D.new()
	var s := SphereShape3D.new()
	s.radius = radius
	shape.shape = s
	b.add_child(shape)
	var mesh := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = radius
	sm.height = radius * 2.0
	mesh.mesh = sm
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.85, 0.12, 0.15) if radius < 0.12 else Color(0.2, 0.35, 0.9)
	mesh.material_override = m
	b.add_child(mesh)
	b.mass = 0.08 if radius < 0.12 else 0.14
	var pm := PhysicsMaterial.new()
	pm.friction = 0.7
	pm.bounce = 0.35 if radius < 0.12 else 0.1
	b.physics_material_override = pm
	b.continuous_cd = true
	game.add_child(b)
	b.global_position = at
	b.linear_velocity = velocity
	balls.append(b)
	return b


func _clear_balls() -> void:
	for b in balls:
		if is_instance_valid(b): b.queue_free()
	balls.clear()
	await physics_frame


func _wait(seconds: float) -> void:
	for i in int(seconds * 60.0): await physics_frame


func run() -> void:
	var folder := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): folder = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(folder)
	load("res://commons/void/room_source.gd").use_main_tower = true
	game = load("res://commons/void/void.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.body.scripted_input = true
	game.body.set_process_unhandled_input(false)
	game.scene_loaded()
	game.scene_visible()
	floor_index = game.checkpoint
	var record: Dictionary = game.building.content.data.floors[floor_index]
	var checks := []
	var result := {"floor": floor_index, "map": str(record.map), "checks": checks, "passed": false}
	var ids := []
	for item in record.artifacts:
		if str(item.id).begins_with(PREFIX): ids.append(str(item.id))
	for i in 2400:
		var all := true
		for id in ids:
			if not game.building.content.exhibits.has("%d/%s" % [floor_index, id]): all = false
		if all: break
		await physics_frame
	for id in ids:
		var mount: Node3D = game.building.content.exhibits.get("%d/%s" % [floor_index, id])
		var work: Node3D = mount.get_node_or_null("Artifact") if mount != null else null
		if work != null and work.has_method("state"): works[str(work.form)] = work
	for i in 240: await physics_frame
	level = float(game.building.spec.levels[floor_index]) + game.building.global_position.y
	body = game.body
	eye = SubViewport.new()
	eye.size = Vector2i(1280, 800)
	eye.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(eye)
	cam = Camera3D.new()
	cam.fov = 70
	eye.add_child(cam)
	cam.current = true
	var drawn := {}
	for form in works:
		var s: Dictionary = works[form].state()
		drawn[form] = [int(s.triangles), int(s.collision_triangles), bool(s.rigid)]
	var whole: bool = works.size() == 20 and drawn.values().all(func(v): return v[0] > 1000 and (v[1] > 300 or v[2]))
	checks.append({"check": "all twenty mounted, drawn, with collision (a hull for the rigid two)", "ok": whole, "count": works.size(), "drawn": drawn})
	if works.size() < 20:
		_finish(folder, result)
		return
	# pictures of the yard
	await _shot(Vector3(-17.0, level + 2.3, 8.7), Vector3(-17.0, level + 0.8, -4.0), folder.path_join("west_wing.png"))
	await _shot(Vector3(17.0, level + 2.3, 8.7), Vector3(17.0, level + 0.6, -4.0), folder.path_join("east_wing.png"))
	await _shot(Vector3(-11.0, level + 4.6, 8.2), Vector3(-17.0, level + 0.5, -3.0), folder.path_join("yard_west.png"))
	await _shot(Vector3(11.0, level + 4.6, 8.2), Vector3(17.0, level + 0.4, -3.0), folder.path_join("yard_east.png"))
	await _shot(Vector3(-5.8, level + 1.7, -3.6), Vector3(-10.5, level + 0.3, -7.2), folder.path_join("intersection.png"))
	await _shot(Vector3(5.8, level + 1.7, 3.8), Vector3(10.0, level + 0.4, 7.0), folder.path_join("field.png"))

	# ---- walking THROUGH ----
	await _place(_at("tunnel", -2.4, 0))
	var r := await _path([_at("tunnel", -1.0, 0), _at("tunnel", 1.0, 0), _at("tunnel", 2.4, 0)])
	checks.append({"check": "a body walks through the tunnel", "ok": r.reached, "end_local": _local("tunnel", r.end)})
	await _place(_at("crossing", 0, 2.4))
	r = await _path([_at("crossing", 0, 1.0), _at("crossing", 0, 0), _at("crossing", 1.0, 0), _at("crossing", 2.4, 0)])
	checks.append({"check": "a body walks in by the crossing's south door, through its room, out by the east door", "ok": r.reached, "end_local": _local("crossing", r.end)})
	await _place(_at("dome", 0, 2.6))
	r = await _path([_at("dome", 0, 1.4), _at("dome", 0, 0)])
	await _shot(_at("dome", 0.9, -0.9, 1.5), _at("dome", -0.2, 1.9, 1.0), folder.path_join("inside_dome.png"))
	var r2 := await _path([_at("dome", 0, 1.4), _at("dome", 0, 2.6)])
	checks.append({"check": "a body walks into the dome to its middle and out again", "ok": r.reached and r2.reached, "in": _local("dome", r.end), "out": _local("dome", r2.end)})
	await _place(_at("thresholds", -0.7, 1.2))
	r = await _path([_at("thresholds", -0.7, 0), _at("thresholds", -0.7, -1.2)])
	await _place(_at("thresholds", 0.85, 1.2))
	r2 = await _path([_at("thresholds", 0.85, 0), _at("thresholds", 0.85, -1.2)])
	var stopped: Vector3 = _local("thresholds", r2.end)
	checks.append({"check": "a body passes the thresholds' door, and the wall beside it stops a body", "ok": r.reached and not r2.reached and stopped.z > 0.15,
		"door": _local("thresholds", r.end), "wall_stopped_at": stopped})

	# ---- walking OVER and UP ----
	await _place(_at("hump_bridge", -2.6, 0))
	r = await _path(_line("hump_bridge", Vector2(-2.0, 0), Vector2(2.6, 0)))
	checks.append({"check": "a body walks over the hump bridge (it rose >= 0.35 m)", "ok": r.reached and float(r.top) >= 0.35, "top": r.top})
	await _place(_at("mound", -2.3, 0))
	r = await _path(_line("mound", Vector2(-1.6, 0), Vector2(2.3, 0)))
	checks.append({"check": "a body walks over the mound (it rose >= 0.6 m)", "ok": r.reached and float(r.top) >= 0.6, "top": r.top})
	await _place(_at("stones", -2.5, 0))
	r = await _path(_line("stones", Vector2(-1.9, 0), Vector2(2.6, 0)))
	checks.append({"check": "a body walks over the stones", "ok": r.reached and float(r.top) >= 0.12, "top": r.top})
	await _place(_at("stile", -2.7, 0.5))
	r = await _path(_line("stile", Vector2(-2.2, 0.5), Vector2(2.7, 0.5), 10))
	await _place(_at("stile", -2.7, -0.5))
	r2 = await _path(_line("stile", Vector2(-2.2, -0.5), Vector2(2.7, -0.5), 10))
	checks.append({"check": "the stile: the smoothed half lets a body over, the plain union of steps stops it", "ok": r.reached and float(r.top) >= 0.6 and not r2.reached and float(r2.top) < 0.1,
		"smooth_top": r.top, "union_stopped_at": _local("stile", r2.end), "union_top": r2.top})
	var up := []
	for k in 41: up.append(_at("spiral_ramp", cos(deg_to_rad(-20.0 + 7.6 * k)), sin(deg_to_rad(-20.0 + 7.6 * k))))
	await _place(_at("spiral_ramp", cos(deg_to_rad(-34.0)) * 1.0, sin(deg_to_rad(-34.0)) * 1.0))
	r = await _path(up, 0.45, 0.3)
	var at_top: float = body.global_position.y - level
	await _shot(body.global_position + Vector3(0, 1.55, 0), Vector3(-8.0, level, 0.0), folder.path_join("spiral_top.png"))
	var down := up.duplicate()
	down.reverse()
	r2 = await _path(down, 0.45, 0.3)
	checks.append({"check": "a body walks up the spiral ramp to a metre and back down to the floor", "ok": r.reached and at_top >= 0.9 and r2.reached and body.global_position.y - level < 0.1,
		"top": snappedf(at_top, 0.01), "back_at": snappedf(body.global_position.y - level, 0.01)})
	await _place(_at("gutter_ramp", -1.9, 0.45))
	r = await _path(_line("gutter_ramp", Vector2(-1.4, 0.45), Vector2(1.25, 0.45)))
	checks.append({"check": "a body walks up the gutter ramp's lane (it rose >= 0.6 m)", "ok": r.reached and float(r.top) >= 0.6, "top": r.top})
	await _place(_at("gyroid_screen", 0, 1.2))
	r = await _path([_at("gyroid_screen", 0, -1.2)])
	await _place(_at("boulder", -1.5, 0))
	r2 = await _path([_at("boulder", 1.5, 0)])
	checks.append({"check": "the gyroid screen and the boulder stop a body", "ok": not r.reached and not r2.reached, "screen": _local("gyroid_screen", r.end), "boulder": _local("boulder", r2.end)})
	game.place_player(Vector3(0, level + 0.3, 8.9))

	# ---- balls ----
	var across: Vector3 = (_at("thresholds", 0.85, -1.0) - _at("thresholds", 0.85, 1.0)).normalized() * 2.0
	var rb := _ball(0.11, _at("thresholds", 0.85, 1.0, 0.11), across)
	await _wait(2.5)
	var rubber_at := _local("thresholds", rb.global_position)
	await _clear_balls()
	var tb := _ball(0.14, _at("thresholds", 0.85, 1.0, 0.14), across)
	await _wait(2.5)
	var trace_at := _local("thresholds", tb.global_position)
	checks.append({"check": "a rubber ball rolls under the thresholds' wall; a trace ball does not", "ok": rubber_at.z < -0.3 and trace_at.z > 0.15,
		"rubber": rubber_at, "trace": trace_at})
	await _clear_balls()
	rb = _ball(0.11, _at("hump_bridge", 0, 1.0, 0.11), (_at("hump_bridge", 0, -1.0) - _at("hump_bridge", 0, 1.0)).normalized() * 2.0)
	await _wait(2.5)
	checks.append({"check": "a rubber ball rolls through the bridge's culvert", "ok": _local("hump_bridge", rb.global_position).z < -0.65, "ball": _local("hump_bridge", rb.global_position)})
	await _clear_balls()
	rb = _ball(0.11, _at("sieve", 0.0, 0.0, 1.5))
	tb = _ball(0.14, _at("sieve", -0.48, 0.16, 1.5))
	var lowest := 9.0
	for i in 240:
		await physics_frame
		var lt := _local("sieve", tb.global_position)
		if absf(lt.x) < 0.7 and absf(lt.z) < 0.45: lowest = minf(lowest, lt.y)
	checks.append({"check": "the sieve lets a rubber ball through and keeps a trace ball above it", "ok": _local("sieve", rb.global_position).y < 0.25 and lowest > 0.55,
		"rubber": _local("sieve", rb.global_position), "trace_lowest_over_plate": snappedf(lowest, 0.01), "trace": _local("sieve", tb.global_position)})
	await _clear_balls()
	var out_times := []
	var dropped := []
	for k in 3: dropped.append(_ball(0.11, _at("funnel", 0.25 * cos(k * 2.1), 0.25 * sin(k * 2.1), 1.55 + 0.25 * k)))
	var passed := {}
	var through := {}                       # how far from the axis each ball was as it left the spout (y 0.6)
	for i in 900:
		await physics_frame
		for k in 3:
			var lp := _local("funnel", dropped[k].global_position)
			if not through.has(k) and lp.y < 0.6: through[k] = snappedf(Vector2(lp.x, lp.z).length(), 0.001)
			if not passed.has(k) and lp.y < 0.5: passed[k] = i
		if passed.size() == 3: break
	var times: Array = passed.values()
	times.sort()
	var apart: bool = times.size() == 3 and times[1] > times[0] and times[2] > times[1]
	var in_throat: bool = through.size() == 3 and through.values().all(func(r): return float(r) < 0.16)
	checks.append({"check": "three balls poured into the funnel leave THROUGH its throat, one at a time", "ok": times.size() == 3 and apart and in_throat,
		"frames_out": times, "off_axis_at_spout": through})
	await _clear_balls()
	var chute: Node3D = _w("chute")
	rb = _ball(0.11, chute.to_global(Vector3(-1.2, 1.1, 0)))
	var fell_out := false                   # under the channel while still over the chute: through its wall
	for i in 300:
		await physics_frame
		var lc: Vector3 = chute.to_local(rb.global_position)
		if lc.x > -1.4 and lc.x < 1.3 and lc.y < 0.5: fell_out = true
	var in_basin := _local("basin", rb.global_position)
	await _shot(_at("basin", -1.6, -1.4, 1.5), _at("basin", 1.0, 0, 0.4), folder.path_join("chute_basin.png"))
	checks.append({"check": "a ball let go at the top of the chute runs IN it all the way and ends in the basin", "ok": not fell_out and absf(in_basin.x) < 0.75 and absf(in_basin.z) < 0.75 and in_basin.y < 0.5,
		"ball_in_basin_frame": in_basin, "fell_through_the_chute": fell_out})
	await _clear_balls()
	tb = _ball(0.14, _at("pipe_tee", 0, 0, 1.55))
	await _wait(4.0)
	var lt2 := _local("pipe_tee", tb.global_position)
	checks.append({"check": "a trace ball dropped in the pipe tee leaves by one of its ends", "ok": absf(lt2.x) > 0.85 and lt2.y < 0.3, "ball": lt2})
	await _clear_balls()
	rb = _ball(0.11, _at("gutter_ramp", 1.3, 0, 0.75 * (1.3 + 1.5) / 3.0 + 0.05))
	await _wait(3.5)
	checks.append({"check": "a ball let go at the top of the gutter runs down it and off the low end", "ok": _local("gutter_ramp", rb.global_position).x < -1.4, "ball": _local("gutter_ramp", rb.global_position)})
	await _clear_balls()
	rb = _ball(0.11, _at("basin", 0.3, 0.2, 0.9))
	await _wait(4.0)
	var kept := _local("basin", rb.global_position)
	checks.append({"check": "the basin keeps a ball dropped into it", "ok": kept.y < 0.5 and Vector2(kept.x, kept.z).length() < 0.75, "ball": kept})
	await _clear_balls()

	# ---- rigid: the die and the cast ----
	var die_body := (_w("die").body() as RigidBody3D)
	var faces := []
	var rng := RandomNumberGenerator.new()
	rng.seed = 161
	for throw in 12:
		die_body.freeze = false
		die_body.global_position = _at("die", 0, 0, 1.4)
		die_body.global_basis = Basis.from_euler(Vector3(rng.randf() * TAU, rng.randf() * TAU, rng.randf() * TAU))
		die_body.linear_velocity = Vector3(rng.randf_range(-0.3, 0.3), rng.randf_range(0.5, 1.5), rng.randf_range(-0.3, 0.3))
		die_body.angular_velocity = Vector3(rng.randf_range(-8, 8), rng.randf_range(-8, 8), rng.randf_range(-8, 8))
		var settled := 0
		for i in 900:
			await physics_frame
			if die_body.linear_velocity.length() < 0.03 and die_body.angular_velocity.length() < 0.05: settled += 1
			else: settled = 0
			if settled > 40: break
		var b := die_body.global_transform.basis
		var axes := {"1": b.y, "6": -b.y, "2": b.x, "5": -b.x, "3": b.z, "4": -b.z}
		var best := "1"
		for key in axes:
			if axes[key].dot(Vector3.UP) > axes[best].dot(Vector3.UP): best = key
		faces.append({"up": best, "flat_within_deg": snappedf(rad_to_deg(acos(clampf(axes[best].dot(Vector3.UP), -1, 1))), 0.1)})
	var distinct := {}
	for f in faces: distinct[f.up] = true
	checks.append({"check": "the die, thrown twelve times, lands each time flat on a face, and on at least four different ones", "ok": faces.all(func(f): return float(f.flat_within_deg) < 8.0) and distinct.size() >= 4,
		"faces": faces, "distinct": distinct.size()})
	var cast_body := (_w("cast").body() as RigidBody3D)
	var cup: Vector3 = _at("mould", 0, 0, 0.5)
	cast_body.freeze = false
	cast_body.global_position = cup + Vector3(0, 0.45, 0)
	cast_body.rotation = Vector3(0.15, 0.4, -0.1)
	cast_body.linear_velocity = Vector3.ZERO
	cast_body.angular_velocity = Vector3.ZERO
	for i in 360: await physics_frame
	var sat: Vector3 = cast_body.global_position - cup
	await _shot(cup + Vector3(0.9, 1.1, 0.9), cup, folder.path_join("cast_in_mould.png"))
	checks.append({"check": "the cast, dropped over the mould, settles in its cup (its lowest point under the mould's top)", "ok": Vector2(sat.x, sat.z).length() < 0.06 and sat.y < -0.25,
		"offset_from_cup_top": sat})
	# the landing's way off
	game.place_player(Vector3(-7.8, level + 0.3, 1.9))
	for i in 40: await physics_frame
	r = await _path([Vector3(-5.9, level, 1.9)])
	checks.append({"check": "a body landing on the soft landing still steps off east", "ok": r.reached, "end": r.end})
	game.place_player(Vector3(0, level + 0.3, 7.8))
	result["passed"] = checks.all(func(c): return c.ok)
	_finish(folder, result)


func _finish(folder: String, result: Dictionary) -> void:
	var file := FileAccess.open(folder.path_join("iso.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("[iso_prefabs_walk] ", "PASSED" if result.passed else "FAILED")
	quit()
