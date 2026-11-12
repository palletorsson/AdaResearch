extends SceneTree
## IS THE ARRIVAL CLEAR (the Void, 2026-11-12)
## A visitor lands at (0, 7.8) looking north. Read in the running tower, with its own walker: how far the nearest
## collider stands straight ahead at eye height (a ray), how far the nearest DRAWN mesh stands in a body-wide lane
## (a mesh need not collide), and how far a body gets walking three metres north.
##
##   godot --path <stage> --script res://tools/probes/arrival_clear.gd -- --no-bridges
##       --void-start-floor=<floor> --out=<dir> [--need=<metres clear ahead, default 2.5>]
##
## arrival.json: checks with what was read. arrival.png from the spawn point.
var game: Node3D


func _initialize() -> void:
	run.call_deferred()


func run() -> void:
	var folder := ""
	var need := 2.5
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): folder = arg.trim_prefix("--out=")
		if arg.begins_with("--need="): need = float(arg.trim_prefix("--need="))
	DirAccess.make_dir_recursive_absolute(folder)
	load("res://commons/void/room_source.gd").use_main_tower = true
	game = load("res://commons/void/void.tscn").instantiate()
	root.add_child(game); current_scene = game
	game.body.scripted_input = true; game.body.set_process_unhandled_input(false)
	game.scene_loaded(); game.scene_visible()
	var floor: int = game.checkpoint
	var record: Dictionary = game.building.content.data.floors[floor]
	for i in 600: await physics_frame
	var level: float = float(game.building.spec.levels[floor]) + game.building.global_position.y
	var body: CharacterBody3D = game.body
	var checks := []
	for layer in root.find_children("*", "CanvasLayer", true, false):      # the game's overlays, not a work's own layers
		if layer.get_viewport() == root: layer.hide()
	game.place_player(Vector3(-3.6, level + 0.3, 8.6))
	for i in 30: await physics_frame
	var cam := Camera3D.new()
	cam.fov = 80
	root.add_child(cam)
	cam.global_position = Vector3(0, level + 1.6, 7.8)
	cam.look_at(Vector3(0, level + 1.5, 0), Vector3.UP)
	cam.current = true
	for i in 4: await process_frame
	root.get_viewport().get_texture().get_image().save_png(folder.path_join("arrival.png"))
	cam.current = false
	# straight ahead at eye height, and at knee height
	var space := body.get_world_3d().direct_space_state
	var ahead := INF
	for h in [1.5, 0.5]:
		var q := PhysicsRayQueryParameters3D.create(Vector3(0, level + h, 7.8), Vector3(0, level + h, -9.0))
		q.exclude = [body.get_rid()]
		var hit := space.intersect_ray(q)
		if not hit.is_empty(): ahead = minf(ahead, 7.8 - float(hit.position.z))
	checks.append({"check": "no collider within %.1f m straight ahead of the arrival" % need, "ok": ahead >= need, "nearest_ahead_m": snappedf(ahead, .01) if ahead < INF else null})
	# what a visitor SEES is a mesh, and a mesh need not collide (found on Shader_12_PinkExtravaganza: a cube 0.4 m
	# ahead that a body walks through). The nearest drawn mesh in a body-wide lane north of the eye; a mesh the eye is
	# inside (a dome, a room) is where the visitor is, not what stands in the way.
	var eye := Vector3(0, level + 1.6, 7.8)
	var lane := AABB(Vector3(-0.6, level + 0.3, -9.0), Vector3(1.2, 1.9, 16.6))
	var seen := INF
	var what := ""
	for m in game.building.content.roots[floor].find_children("*", "MeshInstance3D", true, false):
		var mesh_node := m as MeshInstance3D
		if mesh_node.mesh == null or not mesh_node.is_visible_in_tree(): continue
		var box: AABB = mesh_node.global_transform * mesh_node.mesh.get_aabb()
		if box.has_point(eye) or not box.intersects(lane) or box.size.y < 0.3: continue
		var d: float = 7.8 - minf(box.end.z, 7.6)
		if d < seen:
			seen = d
			what = str(mesh_node.get_path()).get_slice("/Content%d/" % floor, 1)
	checks.append({"check": "no mesh stands within %.1f m straight ahead of the arrival" % need, "ok": seen >= need, "nearest_mesh_m": snappedf(seen, .01) if seen < INF else null, "mesh": what})
	game.place_player(Vector3(0, level + 0.3, 7.8))
	for i in 40: await physics_frame
	var from: float = body.global_position.z
	for i in 150:
		if body.global_position.z < 4.8: break
		body.look_at(Vector3(0, body.global_position.y, -9), Vector3.UP)
		body.drive = Vector2(0, -1)
		await physics_frame
	body.drive = Vector2.ZERO
	for i in 20: await physics_frame
	var went: float = from - body.global_position.z
	checks.append({"check": "a body walks north from the arrival", "ok": went >= minf(need, 2.5) and int(game.checkpoint) == floor, "walked_m": snappedf(went, .01)})
	game.place_player(Vector3(-3.6, level + 0.3, 8.6))
	var result := {"floor": floor, "map": str(record.map), "checks": checks, "passed": checks.all(func(c): return c.ok)}
	var file := FileAccess.open(folder.path_join("arrival.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("[arrival_clear] ", "PASSED" if result.passed else "FAILED")
	quit()
