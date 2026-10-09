extends SceneTree
var OUT := ""
var checks := 0
var failures: Array[String] = []
var evidence: Dictionary = {}
func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): OUT = a.trim_prefix("--out=")
	run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)
	print("MIDDLE ", "PASS " if ok else "FAIL ", message)
func run() -> void:
	var map_name := "Random_Mushrooms" if OUT.contains("mushroom") else ("Random_Rotate_Random_XYZ" if OUT.contains("rotate") else "Random_Walk")
	var em = load("res://commons/scenes/endless_museum.tscn").instantiate()
	var ctl = OUT + "museum-control.json"
	var f = FileAccess.open(ctl, FileAccess.WRITE)
	f.store_string(JSON.stringify({"first_chapter":"randomness", "dollhouse":0, "grid_pack":1})); f.close()
	em.EM_CONTROL = ctl; em._overrides_path = ctl + ".unused"; em._hand_path = ctl + ".unused-hand"
	em.start_chapter = "randomness"; em.start_map = map_name
	root.add_child(em); current_scene = em
	await create_timer(2).timeout
	em.set_process(false); em.set_physics_process(false); em.flush_stamps()
	var seg: Node3D
	for rec in em._segments:
		if rec.node.get_meta("em_map", "") == map_name: seg = rec.node; break
	check(seg != null, "actual museum hall loaded: " + map_name)
	if not seg: finish(); return
	em._player.set_physics_process(false); em._feel.set_process(false)
	em._wardrobe.appearance_save_path = ""; em._wardrobe.costume.visible = false
	for rec in em._vis_records:
		var n = rec.get("node")
		if n is Node3D and is_instance_valid(n) and seg.is_ancestor_of(n): n.visible = true
	var objects: Dictionary = {}
	for n in seg.find_children("*", "Node", true, false):
		if n.has_meta("artifact_lookup_name"): objects[str(n.get_meta("artifact_lookup_name"))] = n
	evidence.artifact_ids = objects.keys(); evidence.spawn = str(seg.to_local(em._player.global_position))
	for n in em.find_children("*", "Node", true, false):
		n.set_process(false); n.set_physics_process(false)
		if n is Timer: n.stop()
	var cam := Camera3D.new(); cam.fov = 57; em.add_child(cam)
	if map_name == "Random_Walk":
		check(objects.has("random_walk_terrarium"), "terrarium loaded")
		if not objects.has("random_walk_terrarium"): finish(); return
		var ui = objects.random_walk_terrarium
		ui.set_walk_seed(777); ui.walk_mode = 2
		for i in 300: ui._process(1.0/30.0)
		ui._update_logbook(); ui._update_stats()
		evidence.state = ui.get_logbook_state()
		check(ui._total_steps == 300, "matched300step capture")
		check(objects.has("random_walk_128") and objects.has("random_draw_dot"), "both book companions retained")
		await shot(cam, ui.to_global(Vector3(-.18,1.65,2.1)), ui.to_global(Vector3(-.18,1.04,.12)), "instrument")
	elif map_name == "Random_Mushrooms":
		var capsule := CapsuleShape3D.new(); capsule.radius = .22; capsule.height = 1.6
		var q := PhysicsShapeQueryParameters3D.new(); q.shape = capsule; q.collision_mask = 1
		q.exclude = [em._player.get_rid()]; q.collide_with_areas = false
		await physics_frame
		evidence.stations = {}
		for id in ["mushrooms", "silhouette_arrivals", "couture_comparison"]:
			check(objects.has(id), "book encounter loaded: " + id)
			if not objects.has(id): continue
			var ui: Node3D = objects[id]
			var mark = ui.find_child("StandingPosition",true,false)
			check(mark != null, "standing marker: " + id)
			if not mark: continue
			q.transform.origin = mark.global_position + Vector3(0,.85,0)
			var hits = seg.get_world_3d().direct_space_state.intersect_shape(q,8)
			evidence.stations[id] = {"origin":str(seg.to_local(ui.global_position)),"standing":str(seg.to_local(mark.global_position)),"standing_z":seg.to_local(mark.global_position).z,"collision":hits.map(func(h):return str(h.collider.get_path()))}
			check(hits.is_empty(), "standing approach clear: " + id)
			if id == "mushrooms": ui.set_population_seed(777)
			if id == "silhouette_arrivals":
				ui.automatic = false; ui.replay()
				for i in 6: ui.arrive()
				ui.redress(); ui.change_forms()
				var body_bounds: AABB
				for i in ui.people.size():
					var person: MeshInstance3D=ui.people[i]
					var bounds: AABB=(seg.global_transform.affine_inverse()*person.global_transform)*person.mesh.get_aabb()
					body_bounds=bounds if i==0 else body_bounds.merge(bounds)
				evidence.arrival_body_bounds=str(body_bounds)
				if OUT.contains("after"):
					check((body_bounds.position.x>12.49 or body_bounds.position.z>19.51) and body_bounds.end.x<16.01,"arrival bodies stay outside garden glass and inside hall wall")
			await shot(cam, mark.global_position + Vector3(0,1.65,0) + mark.global_basis.z * .9, ui.global_position + Vector3(0,1,0), id)
		if OUT.contains("after"):
			check(evidence.stations.mushrooms.standing_z < evidence.stations.silhouette_arrivals.standing_z and evidence.stations.silhouette_arrivals.standing_z < evidence.stations.couture_comparison.standing_z,"book approach order: bed, arrivals, couture")
		await shot(cam, seg.to_global(Vector3(8.5,16,9)), seg.to_global(Vector3(8.5,0,15)), "hall-plan")
	else:
		check(objects.has("random_decay_multimesh"), "decay artifact loaded")
		if not objects.has("random_decay_multimesh"): finish(); return
		var ui = objects.random_decay_multimesh
		evidence.layers = []
		var layer_i := 0
		for layer in ui._layers:
			var mm: MultiMesh = layer.multimesh
			var layer_node: Node3D = ui.get_node(["DecayLayer_Cubes","DecayLayer_Prisms"][layer_i])
			var bounds: AABB
			for i in mm.instance_count:
				var box: AABB = (seg.global_transform.affine_inverse() * layer_node.global_transform * mm.get_instance_transform(i)) * mm.mesh.get_aabb()
				bounds = box if i == 0 else bounds.merge(box)
			evidence.layers.append({"count":mm.instance_count,"bounds":str(bounds),"speed_scale":layer.speed_scale})
			if OUT.contains("after"):
				check(bounds.position.x >= .99 and bounds.end.x <= 12.01, "stack fits within hall walls")
				check(absf(bounds.position.y)<.001, "initial stack rests at floor")
			layer_i += 1
		evidence.root = str(seg.to_local(ui.global_position))
		await shot(cam, seg.to_global(Vector3(6,4,7)), seg.to_global(Vector3(6,3,14)), "stacks")
		if OUT.contains("after"):
			var capsule := CapsuleShape3D.new();capsule.radius=.22;capsule.height=1.6
			var q := PhysicsShapeQueryParameters3D.new();q.shape=capsule;q.collision_mask=1;q.exclude=[em._player.get_rid()]
			q.transform.origin=ui.to_global(Vector3(0,.85,-2))
			await physics_frame
			var hits=ui.get_world_3d().direct_space_state.intersect_shape(q,8)
			check(hits.is_empty(),"fitted console standing approach clear")
			evidence.control_hits=hits.map(func(h):return str(h.collider.get_path()))
			await shot(cam,ui.to_global(Vector3(0,1.65,-2.25)),ui.to_global(Vector3(0,1.05,0)),"controls")
	finish()
func shot(cam: Camera3D, pos: Vector3, target: Vector3, id: String) -> void:
	if DisplayServer.get_name() == "headless": return
	cam.global_position = pos; cam.look_at(target)
	for i in 15: cam.make_current(); await process_frame
	cam.make_current(); check(root.get_camera_3d() == cam, "camera current before " + id)
	await RenderingServer.frame_post_draw
	check(root.get_camera_3d() == cam, "camera current after " + id)
	root.get_texture().get_image().save_png(OUT + id + ".png")
	var f = FileAccess.open(OUT + id + "-camera.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"position":str(pos),"target":str(target),"fov":cam.fov}, "  ")); f.close()
func finish() -> void:
	var f = FileAccess.open(OUT + "museum-checks.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"failures":failures,"evidence":evidence,"headset_tested":false}, "  ")); f.close()
	print("MIDDLE COMPLETE ", checks, " / ", failures.size()); quit(0 if failures.is_empty() else 1)
