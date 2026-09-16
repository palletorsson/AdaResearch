extends SceneTree
const OUT := "res://doc/space/randomness-dna-2026-09-16/"
var hall := "Random_Definition"
var failures: Array[String] = []
var evidence: Array = []
var checks: Array = []

func check(condition: bool, message: String) -> void:
	checks.append({"check":message,"passed":condition})
	if not condition: failures.append(message)

func capture_state(em: Node3D, from: Vector3, target: Vector3, suffix: String) -> void:
	if not "--capture" in OS.get_cmdline_user_args(): return
	var camera := Camera3D.new(); em.add_child(camera); camera.fov = 78
	camera.global_position = from; camera.look_at(target)
	for i in range(12): camera.make_current(); await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+hall+"-"+suffix+".png")
	camera.queue_free()

func check_consoles(found: Dictionary, origin: Vector3) -> void:
	for key in found:
		var artifact: Node3D = found[key]
		var console: Node3D = artifact.find_child("ReachConsole",true,false)
		if console == null: continue
		var mark: Node3D = console.get_node("StandingPosition")
		var shoulder := mark.global_position+Vector3(0,1.25,0)
		var count := 0
		for button in console.find_children("Btn_*","Node3D",true,false):
			count += 1
			var reach: float = shoulder.distance_to(button.global_position)
			check(reach <= 0.80, "%s/%s reachable from one mark: %.3f m" % [key,button.name,reach])
			check(button.global_position.y-origin.y >= 0.80 and button.global_position.y-origin.y <= 1.50, "%s/%s hand height" % [key,button.name])
		check(count > 0,key+" has touch buttons on its compact console")

func exercise(found: Dictionary, player: Node3D, em: Node3D) -> void:
	for key in found:
		if key in ["random_removal_arena","random_doors"]: continue
		var artifact: Node3D = found[key]
		var console: Node3D = artifact.find_child("ReachConsole",true,false)
		if console == null: continue
		var before: Vector3 = console.global_position
		var buttons: Array = console.find_children("Btn_*","Node3D",true,false)
		for button in buttons:
			if not is_instance_valid(button):
				check(false,key+": rebuilding freed a console button"); break
			button.get_node("InteractableAreaButton").emit_signal("button_pressed",button)
			await create_timer(0.15).timeout
		check(is_instance_valid(console),key+": console survives every button action")
		if is_instance_valid(console):
			check(before.distance_to(console.global_position)<0.001,key+": controls stay at hand height after rebuilds")
			check(console.find_children("Btn_*","Node3D",true,false).size()==buttons.size(),key+": no missing or duplicated buttons after actions")
	if found.has("random_removal_arena"):
		var arena: Node3D = found.random_removal_arena
		check(absf(arena.global_position.y) < 0.05,"Arena cells restored to museum floor height")
		player.global_position = arena.to_global(Vector3(0,1.0,-float(arena.rows)/2.0+1.0))
		await create_timer(1.2).timeout
		var first: Dictionary = arena.get_state()
		check(first.removed == 1 and first.disabled_colliders == 1,"Entering removes one cell AND its collider")
		player.global_position.x += 0.8
		await create_timer(1.2).timeout
		var second: Dictionary = arena.get_state()
		check(second.removed == 2 and second.disabled_colliders == 2,"Walking requests a second removal")
		player.global_position.y += 30
		await physics_frame
		var index: int = second.last_removed
		var pos: Vector3 = arena.colliders[index].global_position
		var ray := PhysicsRayQueryParameters3D.create(pos+Vector3(0,0.7,0),pos-Vector3(0,0.7,0))
		check(em.get_world_3d().direct_space_state.intersect_ray(ray).is_empty(),"Removed cell has a real hole, not museum floor beneath it")
		var history: Array = second.removal_log.duplicate()
		arena.reset_arena(); await physics_frame
		check(arena.get_state().disabled_colliders == 0,"Replay restores every physical cell")
		arena.remover.remove_one(); await create_timer(1.0).timeout
		check(arena.get_state().last_removed == history[0],"Replay repeats the first draw")
		arena.remover.remove_one(); arena.reset_arena(); await create_timer(1.0).timeout
		check(arena.get_state().removed == 0 and arena.get_state().disabled_colliders == 0,"Reset cancels pending draw without losing support")
		if hall == "Random_Remove":
			for i in range(12):
				arena.remover.remove_one(); await create_timer(0.85).timeout
			await capture_state(em,arena.to_global(Vector3(0,5,-8)),arena.to_global(Vector3(0,-0.5,0)),"removing")
			check(arena.get_state().removed == 12,"Twelve removals leave twelve gaps")
			arena.reset_arena()
	if found.has("random_doors"):
		var doors: Node3D = found.random_doors
		var safe: int = doors.safe_door
		var unsafe: int = (safe+1)%3
		# Use the same area signal emitted by a VR hand touch.
		var console: Node3D = doors.find_child("ReachConsole",true,false)
		var button: Node = console.find_child("Btn_%d" % safe,true,false)
		button.get_node("InteractableAreaButton").emit_signal("button_pressed",button)
		await create_timer(1.05).timeout
		check(doors.state[safe] == "passage" and doors.locks[safe].disabled,"VR button opens the seeded safe passage and clears its collider")
		doors.choose(unsafe); await create_timer(2.5).timeout
		check(doors.state[unsafe] == "fire" and doors.fire_mesh[unsafe].visible,"Other door releases visible fire after its warning")
		check(not doors.fire[unsafe].get_node("CollisionShape3D").disabled,"Fire jet has an active hazard volume")
		check(is_equal_approx(doors.fire[unsafe].get_node("CollisionShape3D").shape.size.z,2.7),"Fire mesh and hurt volume reach 2.7 m")
		await capture_state(em,doors.to_global(Vector3(0,2,-6)),doors.to_global(Vector3(0,1.4,0)),"fire")
		var deaths: int = em.get("_deaths")
		player.global_position = doors.fire[unsafe].global_position
		await create_timer(0.25).timeout
		check(int(em.get("_deaths")) > deaths,"Entering fire jet invokes museum death")
		await create_timer(6.5).timeout
		check(not em.get("_dying"),"Museum respawn completes after fire")
		player.set_process(false); player.set_physics_process(false); player.global_position.y += 30
		doors.replay(); await physics_frame
		check(doors.safe_door == safe,"Door replay preserves the seeded assignment")
		check(doors.state == ["closed","closed","closed"],"Door replay closes all doors")
		doors.choose(unsafe); await create_timer(0.2).timeout; doors.replay(); await create_timer(1.8).timeout
		check(doors.state == ["closed","closed","closed"] and not doors.fire_mesh[unsafe].visible,"Replay cancels an in-flight door action")

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
	check_consoles(found,origin)
	if found.has("entropy_axiom"):
		var cloud: Node3D = found.entropy_axiom
		check(cloud.grid_size_x == cloud.grid_size_z and cloud.square_room,"Entropy field has square plan")
		check(cloud.multimesh_instance.multimesh.instance_count == 1280,"Square field holds 16 x 5 x 16 points")
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
			["hero", Vector3(hp.x,1.65,hp.z-(6.2 if hall=="Random_Mushrooms" else 2.6)),Vector3(hp.x,1.0,hp.z)]
		]
		var spatial: Dictionary = {"Random_Remove":["random_removal_arena",13],"Random_Game":["random_removal_arena",11],"Random_Entropy":["entropy_axiom",10],"Random_Walk":["random_walk_128",12],"Random_Mushrooms":["mushrooms",8]}
		if spatial.has(hall):
			var object: Node3D = found[spatial[hall][0]]
			var centre: Vector3 = object.global_position-origin
			var distance: float = float(spatial[hall][1])/2.0+2.0
			shots.append(["space",centre+(Vector3(-6,5,-9) if hall=="Random_Walk" else Vector3(0,2.0,-distance)),centre+Vector3(0,1.5,0)])
		if found.has("random_doors"):
			var centre: Vector3 = found.random_doors.global_position-origin
			shots.append(["doors",centre+Vector3(0,2.0,-6.0),centre+Vector3(0,1.5,0)])
		for shot in shots:
			cam.global_position = origin + shot[1]; cam.look_at(origin + shot[2])
			for i in range(15): cam.make_current(); await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(OUT+hall+"-"+shot[0]+".png")

	if found.has("silhouette_arrivals"):
		var arrivals: Node3D = found.silhouette_arrivals
		var sprite = load("res://commons/hazards/catalyst_foe/silhouette_sprite.gd")
		check(sprite.make_dressed_image(27183,800).get_data()==sprite.make_dressed_image(27183,800).get_data(),"Same body and wardrobe seeds repeat pixels")
		check(sprite.make_dressed_image(27183,800).get_data()!=sprite.make_dressed_image(27183,801).get_data(),"Wardrobe seed changes appearance")
		arrivals.automatic = false; arrivals.replay()
		for i in range(8): arrivals.arrive()
		check(arrivals.people.size()==6,"Population capped at six")
		var order: Array = arrivals.history.duplicate()
		check(order.size()==6 and arrivals.available.is_empty(),"Sampling exhausts six different positions")
		var old_dress: int = arrivals.dress_seed
		var old_rng: int = arrivals.rng.state
		var original: PackedByteArray = arrivals.people[0].material_override.albedo_texture.get_image().get_data()
		arrivals.change_forms()
		check(arrivals.history==order and arrivals.dress_seed==old_dress and arrivals.rng.state==old_rng,"FORMS retains arrivals, dress seed and arrival RNG")
		check(arrivals.people[0].material_override.albedo_texture.get_image().get_data()!=original,"FORMS produces a visibly different repertoire")
		await capture_state(em,arrivals.global_position+Vector3(0,1.7,-3.6),arrivals.global_position+Vector3(0,1,0),"branches")
		arrivals.change_forms()
		check(arrivals.people[0].material_override.albedo_texture.get_image().get_data()==original,"Switching FORMS back restores exact texture")
		arrivals.redress()
		check(arrivals.history==order,"Dress leaves occupied places unchanged")
		arrivals.replay()
		for i in range(6): arrivals.arrive()
		check(arrivals.history==order,"Replay repeats arrival order after redress")
		await capture_state(em,arrivals.global_position+Vector3(0,1.7,-3.6),arrivals.global_position+Vector3(0,1,0),"visitors")
	if found.has("random_walk_128"):
		for cell in [Vector2(2,17),Vector2(16,17),Vector2(5,10)]:
			var start: Vector3 = origin+Vector3(cell.x,0.3,cell.y)
			var hit := em.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(start,start-Vector3(0,1,0)))
			check(hit.is_empty(),"Moat is open at "+str(cell))
		for cell in [Vector2(9,10),Vector2(9,24),Vector2(4,17)]:
			var start: Vector3 = origin+Vector3(cell.x,0.3,cell.y)
			var hit := em.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(start,start-Vector3(0,1,0)))
			check(not hit.is_empty(),"Bridge or inner apron supported at "+str(cell))
	for key in ["textile_comparison","couture_comparison"]:
		if not found.has(key): continue
		var bench: Node3D = found[key]
		bench.reset()
		check(bench.specimens.size()==3,key+": three existing generators instantiated")
		if bench.textile:
			var a: Node3D = bench.specimens[0]
			for b in bench.specimens:
				check(b.weave_seed==41 and not b.weaving,"Textiles share seed and remain still")
				check(b._woven[0][0].get_meta("sample")==a._woven[0][0].get_meta("sample"),"Different alphabets use same first sample")
		else:
			bench.change_garment()
			for i in range(3): check(bench.specimens[i].seed==41+i and bench.specimens[i].garment=="crinoline","Garment changes while retaining seed")
		await create_timer(0.2).timeout
		await capture_state(em,bench.global_position+Vector3(0,2.1,-5.4),bench.global_position+Vector3(0,1,0),key)
	await exercise(found,player,em)
	finish({"floor_checks":floor_checks, "origin":str(origin)})

func finish(extra: Dictionary) -> void:
	var result := {"map":hall,"artifacts":evidence,"checks":checks,"failures":failures,"headset_verified":false}
	result.merge(extra)
	var f := FileAccess.open(OUT+hall+"-runtime.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(result,"  "));f.close()
	print("[randomness-staging] ", hall, " artifacts=", evidence.size(), " failures=", failures)
	quit(0 if failures.is_empty() else 1)
