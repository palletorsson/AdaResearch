extends "res://tools/probes/void_game_probe.gd"
## THE COLOUR FLOORS SURVEYED (Palle, 2026-11-05: "test and curate other artifacts ... start from the color sequence
## ... how they fit into the room ... have presence, many work but others not fully"). Floors 30-37 in the actual Void:
## every mounted work measured - its meshes' world box (presence), visible meshes, bodies (can it be touched or walked
## into), labels (does it speak), its distance from the floor's route (is it met), whether it stands on slab, and how
## long it took to build - and photographed: each floor from two vantages, each work from 3 m, framed by its box.
## Report ada_run/color-survey/desktop/survey.json. Run: python tools/test_color_survey.py
const FLOORS := [30, 31, 32, 33, 34, 35, 36, 37]
var floors: Array = FLOORS

## The world box of a work's meshes: the local box of each mesh carried by its own global transform, merged.
func world_bounds(host: Node3D) -> AABB:
	var result := AABB(); var first := true
	for node in host.find_children("*", "GeometryInstance3D", true, false):
		if node.get_viewport() != host.get_viewport(): continue # a private filmed world (SubViewport) is not the work's footprint: the films measured 728 m tall
		var bounds: AABB
		if node is MeshInstance3D and node.mesh != null: bounds = node.mesh.get_aabb()
		elif node is MultiMeshInstance3D and node.multimesh != null: bounds = node.multimesh.get_aabb()
		elif node is CSGShape3D: bounds = node.get_aabb()
		else: continue
		if bounds.size.length() < .001: continue
		bounds = node.global_transform * bounds
		result = bounds if first else result.merge(bounds); first = false
	return result

## What is wrong with where a work stands, by the building's own numbers: past a slab edge, over a shaft, a column inside it.
func faults(b: AABB, level: float) -> Array:
	var spec = game.building.spec; var out_ := []
	var hw: float = float(spec.width) / 2.0; var hd: float = float(spec.depth) / 2.0
	if b.size.length() < .05: return ["no measurable mesh"]
	if b.size.x > 60.0 or b.size.z > 60.0: return ["box %.0f x %.0f m: a stage, not a footprint" % [b.size.x, b.size.z]]
	var over := []
	if b.position.x < -hw - .3: over.append("west %.1f" % (-hw - b.position.x))
	if b.end.x > hw + .3: over.append("east %.1f" % (b.end.x - hw))
	if b.position.z < -hd - .3: over.append("north %.1f" % (-hd - b.position.z))
	if b.end.z > hd + .3: over.append("south %.1f" % (b.end.z - hd))
	if not over.is_empty(): out_.append("past the edge: " + ", ".join(over))
	for shaft in spec.shafts:
		var sx := float(shaft.x); var hs := float(spec.shaft_width) / 2.0; var hz := float(spec.shaft_depth) / 2.0
		var ox := minf(b.end.x, sx + hs) - maxf(b.position.x, sx - hs); var oz := minf(b.end.z, hz) - maxf(b.position.z, -hz)
		if ox > .3 and oz > .3 and b.position.y < level + 2.5: out_.append("over shaft %s by %.1f x %.1f m" % [shaft.name, ox, oz])
	for x in spec.column_x:
		for z in spec.column_z:
			if b.position.x < x and b.end.x > x and b.position.z < z and b.end.z > z: out_.append("column (%d, %d) inside" % [x, z])
	return out_

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out = arg.trim_prefix("--out=")
		if arg.begins_with("--floors="):
			floors = []
			for s in arg.trim_prefix("--floors=").split(","): floors.append(int(s))
	Engine.physics_ticks_per_second = 90
	preload("res://commons/void/room_source.gd").use_main_tower = true
	load("res://commons/void/game.gd").requested_floor = floors[0]
	game = load("res://commons/void/void.tscn").instantiate(); game.force_xr = false
	root.add_child(game); current_scene = game; game.scene_loaded(); game.scene_visible(); game.set_process_unhandled_key_input(false)
	game.body.scripted_input = true; game.body.set_process_unhandled_input(false)
	await frames(90)
	var survey := {}
	for f in floors:
		var t0 := Time.get_ticks_msec()
		game.place_player(game.spawn_for(f)); await frames(240)
		var level: float = float(game.building.spec.levels[f])
		var data: Dictionary = game.building.content.data.floors[f]
		var route: Array = data.get("route", [])
		var rows := {}
		for key in game.building.content.exhibits:
			if not str(key).begins_with("%d/" % f): continue
			var mount: Node3D = game.building.content.exhibits[key]
			var art: Node = mount.get_node_or_null("Artifact") if mount else null
			var id := str(key).get_slice("/", 1)
			if art == null:
				rows[id] = {"mounted": false}; continue
			var b := mesh_bounds(art)
			var wb := world_bounds(art)
			var visuals := art.find_children("*", "VisualInstance3D", true, false).filter(func(v): return (v as Node3D).is_visible_in_tree())
			var bodies := art.find_children("*", "CollisionObject3D", true, false)
			var labels := art.find_children("*", "Label3D", true, false).filter(func(l): return (l as Node3D).is_visible_in_tree() and str((l as Label3D).text).strip_edges() != "")
			var pickables := bodies.filter(func(c): return c.has_signal("picked_up"))
			var lights := art.find_children("*", "Light3D", true, false)
			var near := INF
			for p in route:
				near = minf(near, Vector2(mount.global_position.x - float(p.position[0]), mount.global_position.z - float(p.position[1])).length())
			var under := game.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(mount.global_position + Vector3(0, .5, 0), mount.global_position + Vector3(0, -.6, 0), 1))
			rows[id] = {"mounted": true, "token": str(mount.get_meta("artifact", art.get_class())), "at": [snappedf(mount.global_position.x, .01), snappedf(mount.global_position.z, .01)],
				"size": [snappedf(b.size.x, .01), snappedf(b.size.y, .01), snappedf(b.size.z, .01)], "bottom_over_floor": snappedf(b.position.y - level, .01), "top_over_floor": snappedf(b.end.y - level, .01),
				"visuals": visuals.size(), "bodies": bodies.size(), "pickables": pickables.size(), "labels": labels.map(func(l): return str((l as Label3D).text).left(80)), "lights": lights.size(),
				"route_m": snappedf(near, .1) if near < INF else null,
				"world_box": [snappedf(wb.position.x, .01), snappedf(wb.position.z, .01), snappedf(wb.end.x, .01), snappedf(wb.end.z, .01)], "world_bottom": snappedf(wb.position.y - level, .01), "world_top": snappedf(wb.end.y - level, .01), "faults": faults(wb, level), "on_slab": not under.is_empty() and absf(under.position.y - level) < .1, "class": art.get_class(), "script": str(art.get_script().resource_path) if art.get_script() else ""}
			await _photo_work(f, level, id, mount, wb)   # the WORLD box: mesh_bounds() is in the work's own frame, so aiming by it shot the ceiling (52 of 65 flat, 11-10)
		survey[str(f)] = {"map": str(data.get("map", "")), "title": str(data.get("title", "")), "route_points": route.size(), "build_ms": Time.get_ticks_msec() - t0, "works": rows}
		await _photo_floor(f, level)
		FileAccess.open(out.path_join("survey.json"), FileAccess.WRITE).store_string(JSON.stringify(survey, "  ", false))
		check("floor %d %s: %d works surveyed" % [f, data.get("map", ""), rows.size()], true)
	FileAccess.open(out.path_join("checks.json"), FileAccess.WRITE).store_string(JSON.stringify({"passed": true, "checks": checks, "failed": failed}, "  "))
	print("[color_survey] %d floors" % floors.size())
	quit(0)

func _cam(fov: float) -> Camera3D:
	var camera := Camera3D.new(); game.add_child(camera); camera.fov = fov; camera.environment = game.atmosphere.environment
	camera.make_current()
	game.body.visible = false; game.status.hide(); game.charge_display.hide(); game.notice_time = 0
	if game.desktop_help != null: game.desktop_help.hide()
	return camera

func _shoot(camera: Camera3D, n: String) -> void:
	await frames(6); await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join("%s.png" % n))
	camera.queue_free()
	FileAccess.open(out.path_join("progress.json"), FileAccess.WRITE).store_string(n)

## Each work from 3 m (more for a large one), from the side that faces the hall's middle, at eye height or higher
## for a tall one, framed on its box's centre.
func _photo_work(f: int, level: float, id: String, mount: Node3D, b: AABB) -> void:
	if DisplayServer.get_name() == "headless": return
	var c := b.get_center()
	if b.size.length() < .05: c = mount.global_position + Vector3(0, 1.0, 0)
	var toward := Vector3(-c.x, 0, -c.z); toward.y = 0.0
	if toward.length() < 1.0: toward = Vector3(0, 0, 1)
	toward = toward.normalized()
	var dist := clampf(maxf(b.size.x, b.size.z) * 1.1 + 1.6, 3.0, 9.0)
	var eye_y := clampf(c.y + b.size.y * .25 + .6, level + 1.3, level + 4.8)
	var eye := c + toward * dist; eye.y = eye_y
	# A column or slab between the eye and the work photographs the column (the corner films, 11-10): turn around the
	# work until the line to its centre is clear - nothing hit, or only the work itself - from an eye not inside a body.
	var space := game.get_world_3d().direct_space_state
	var near_work := b.grow(.3)
	for turn in [0.0, .6, -.6, 1.2, -1.2, 1.8, -1.8, PI]:
		var e: Vector3 = c + toward.rotated(Vector3.UP, turn) * dist; e.y = eye_y
		var at_eye := PhysicsPointQueryParameters3D.new(); at_eye.position = e
		if not space.intersect_point(at_eye, 1).is_empty(): continue
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(e, c))
		if hit.is_empty() or near_work.has_point(hit.position):
			eye = e; break
	var camera := _cam(60.0)
	camera.global_position = eye; camera.look_at(c)
	await _shoot(camera, "%02d_%s" % [f, id.replace("/", "_").left(40)])

func _photo_floor(f: int, level: float) -> void:
	if DisplayServer.get_name() == "headless": return
	var views := [[Vector3(-19.0, 4.8, 8.4), Vector3(-4.0, 1.0, -1.0)], [Vector3(19.0, 4.8, -8.4), Vector3(4.0, 1.0, 1.0)], [Vector3(0.0, 5.2, 8.6), Vector3(0.0, 0.8, -2.0)]]
	for i in views.size():
		var camera := _cam(75.0)
		camera.global_position = views[i][0] + Vector3(0, level, 0); camera.look_at(views[i][1] + Vector3(0, level, 0))
		await _shoot(camera, "%02d__floor_%d" % [f, i])
