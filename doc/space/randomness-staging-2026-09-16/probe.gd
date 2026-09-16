extends SceneTree
const OUT := "res://doc/space/randomness-staging-2026-09-16/"
var hall := "Random_Definition"
var failures: Array[String] = []
var evidence: Array = []

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--map="): hall = arg.trim_prefix("--map=")
	run.call_deferred()

func artifacts(seg: Node3D, wanted: Array) -> Dictionary:
	var result: Dictionary = {}
	for n in seg.find_children("*", "Node3D", true, false):
		var key: String = n.get_meta("artifact_lookup_name", "")
		if key in wanted and not result.has(key): result[key] = n
	return result

func bounds(n: Node3D, origin: Vector3) -> Dictionary:
	var combined := AABB()
	var count := 0
	var shapes: Array = n.find_children("*", "VisualInstance3D", true, false)
	if n is VisualInstance3D: shapes.append(n)
	for item in shapes:
		if not item.is_visible_in_tree() or not (item is MeshInstance3D or item is MultiMeshInstance3D): continue
		if item is MeshInstance3D and item.mesh == null: continue
		if item is MultiMeshInstance3D and item.multimesh == null: continue
		var box: AABB = item.global_transform * item.get_aabb()
		combined = box if count == 0 else combined.merge(box)
		count += 1
	return {"min": [combined.position.x-origin.x, combined.position.y-origin.y, combined.position.z-origin.z],
		"max": [combined.end.x-origin.x, combined.end.y-origin.y, combined.end.z-origin.z], "meshes": count}

func run() -> void:
	var manifest: Array = JSON.parse_string(FileAccess.get_file_as_string(OUT + "manifest.json"))
	var room: Dictionary = {}
	for row: Dictionary in manifest:
		if row.map == hall: room = row
	var wanted: Array = []
	for p: Dictionary in room.placements: wanted.append(p.lookup)
	var ctl := OUT + hall + "-control.json"
	var file := FileAccess.open(ctl, FileAccess.WRITE)
	file.store_string(JSON.stringify({"first_chapter":"randomness", "dollhouse":0, "grid_pack":1})); file.close()
	var em: Node3D = load("res://commons/scenes/endless_museum.tscn").instantiate()
	em.set("EM_CONTROL", ctl); em.set("_overrides_path", ctl+".unused"); em.set("_hand_path", ctl+".unused-hand")
	em.set("start_chapter", "randomness"); em.set("start_map", hall)
	root.add_child(em); current_scene = em
	await create_timer(1.0).timeout
	em.set_process(false); em.set_physics_process(false); em.call("flush_stamps")
	var player: Node3D = em.get("_player")
	if player != null:
		player.set_process(false); player.set_physics_process(false); player.global_position.y += 30.0
	var seg: Node3D
	for record: Dictionary in em.get("_segments"):
		if record.node.get_meta("em_map", "") == hall: seg = record.node; break
	if seg == null:
		failures.append("Museum segment missing"); finish({}); return
	var found: Dictionary = {}
	for i in range(100):
		found = artifacts(seg, wanted)
		if found.size() == wanted.size(): break
		await create_timer(0.1).timeout
	for key in wanted:
		if not found.has(key): failures.append("Missing artifact: " + key)
	if not found.has(room.hero): finish({}); return
	await create_timer(1.0).timeout
	var hero: Node3D = found[room.hero]
	var hp: Dictionary = {}
	for placement: Dictionary in room.placements:
		if placement.lookup == room.hero: hp = placement; break
	var origin: Vector3 = hero.global_position - Vector3(hp.x, 0, hp.z)
	# Map museum floors are world Y=0 on this isolated first segment.
	origin.y = seg.global_position.y
	for key in found:
		var node: Node3D = found[key]
		evidence.append({"lookup":key, "path":str(node.get_path()), "position":str(node.global_position-origin),
			"yaw":node.global_rotation_degrees.y, "bounds":bounds(node, origin)})
	var floor_checks: Array = []
	var w := int(room.size.width); var d := int(room.size.depth)
	# Both doorway approaches and both bypass lanes must still have support.
	for cell in [Vector2(w/2,0),Vector2(w/2,d-1),Vector2(1,d/2),Vector2(w-2,d/2)]:
		var from := origin + Vector3(cell.x, 0.4, cell.y)
		var hit := em.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from, from-Vector3(0,2,0)))
		floor_checks.append({"cell":str(cell), "supported":not hit.is_empty()})
		if hit.is_empty(): failures.append("No floor at " + str(cell))
	if "--capture" in OS.get_cmdline_user_args():
		var cam := Camera3D.new(); em.add_child(cam); cam.fov = 78
		var shots: Array = [
			["arrival", Vector3(w/2.0,1.65,0.5), Vector3(hp.x,1.05,hp.z)],
			["overview", Vector3(w/2.0,5.5,1), Vector3(w/2.0,0.8,d*0.57)],
			["hero", Vector3(hp.x,1.65,hp.z-(4.6 if hall=="Random_Mushrooms" else 2.6)),Vector3(hp.x,1.0,hp.z)]
		]
		for shot in shots:
			cam.global_position = origin + shot[1]; cam.look_at(origin + shot[2])
			for i in range(15): cam.make_current(); await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(OUT+hall+"-"+shot[0]+".png")
	finish({"floor_checks":floor_checks, "origin":str(origin)})

func finish(extra: Dictionary) -> void:
	var result := {"map":hall,"artifacts":evidence,"failures":failures,"headset_verified":false}
	result.merge(extra)
	var f := FileAccess.open(OUT+hall+"-runtime.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(result,"  "));f.close()
	print("[randomness-staging] ", hall, " artifacts=", evidence.size(), " failures=", failures)
	quit(0 if failures.is_empty() else 1)
