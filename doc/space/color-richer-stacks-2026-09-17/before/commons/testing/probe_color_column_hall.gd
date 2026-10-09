extends SceneTree
## Actual endless-museum placement, static transforms, and body-clearance checks.
const OUT := "res://doc/space/color-column-hall-2026-09-17/"
var checks: Array = []
var failures: Array[String] = []
var em: Node3D
var gs: Node3D
var walking_y: float
var placed: Array = []

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks.append({"passed":ok,"message":message})
	if not ok: failures.append(message)
	print("[column-hall] ", "PASS " if ok else "FAIL ",message)

func clear_walk(a: Vector3, b: Vector3) -> bool:
	var query := PhysicsShapeQueryParameters3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.25
	capsule.height = 1.6
	query.shape = capsule
	query.collision_mask = 1
	a.y = walking_y
	b.y = walking_y
	query.transform.origin = a
	query.motion = b - a
	var space := gs.get_world_3d().direct_space_state
	return space.intersect_shape(query,1).is_empty() and space.cast_motion(query)[0] > 0.999

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var ctl := OUT + "control.json"
	var file := FileAccess.open(ctl,FileAccess.WRITE)
	file.store_string(JSON.stringify({"first_chapter":"color","dollhouse":0,"grid_pack":1}))
	file.close()
	em = load("res://commons/scenes/endless_museum.tscn").instantiate()
	em.set("EM_CONTROL",ctl)
	em.set("_overrides_path",ctl+".unused")
	em.set("_hand_path",ctl+".unused-hand")
	em.set("start_chapter","color")
	em.set("start_map","Color_Context_Placed")
	root.add_child(em)
	current_scene = em
	await create_timer(1.0).timeout
	em.set_process(false)
	em.set_physics_process(false)
	em.call("flush_stamps")
	for rec: Dictionary in em.get("_segments"):
		if rec.node.get_meta("em_map","") == "Color_Context_Placed":
			gs = rec.node.get_node_or_null("SimGrid_Color_Context_Placed")
	check(gs != null,"current hall embeds its authored GridSystem")
	if gs == null:
		finish()
		return
	for frame in 3600:
		if gs.has_meta("stage_grid_ready"): break
		await process_frame
	check(gs.has_meta("stage_grid_ready"),"museum grid finishes building")
	for frame in 12: await physics_frame
	var artifacts: Array[Node3D] = []
	for n in gs.find_children("*","Node3D",true,false):
		if n.has_meta("artifact_lookup_name"):
			artifacts.append(n)
	check(artifacts.size() == 15,"all fifteen column-study instances are present (got %d)" % artifacts.size())
	var stacks := 0
	var copies := 0
	var poses: Dictionary = {}
	for n in artifacts:
		var token := str(n.get_meta("artifact_lookup_name"))
		placed.append({"token":token,"grid_position":str(gs.to_local(n.global_position)),"pose":n.get("pose") if token == "chroma_stack" else "translation"})
		check(token in ["chroma_stack","chroma_translation"],"hall contains only column studies: "+token)
		if token == "chroma_stack":
			stacks += 1
			poses[n.get("pose")] = true
			var pieces := 0
			for mi in n.get_children():
				if mi is MeshInstance3D and str(mi.name).begins_with("Element_"):
					pieces += 1
					var index := int(str(mi.name).split("_")[1])
					var expected_yaw := float(index) * PI / 8.0 if n.get("pose") in ["twist","combined"] else 0.0
					var expected_scale := 1.0 - float(index)*0.15 if n.get("pose") in ["taper","combined"] else 1.0
					check(is_equal_approx(mi.rotation.y,expected_yaw) and mi.scale.is_equal_approx(Vector3(expected_scale,1,expected_scale)),"fixed transform matches pose at "+str(n.name)+"/"+str(mi.name))
					var collision: CollisionShape3D = n.get_node("Body").get_child(index)
					check(is_equal_approx(collision.rotation.y,mi.rotation.y) and is_equal_approx(collision.shape.size.x,float(n.STACKS[n.get("stack")][index].w)*expected_scale),"collision shares the level's turn and width")
			check(pieces == 5,"column has five primitive pieces")
		else:
			for child in n.get_children():
				if str(child.name).begins_with("Copy_"): copies += 1
	check(stacks == 11 and copies == 16,"eleven single columns plus sixteen translated columns")
	check(poses.size() == 4,"aligned, twist, taper and combined poses all instantiate")
	var ray := PhysicsRayQueryParameters3D.create(gs.to_global(Vector3(11,20,3)),gs.to_global(Vector3(11,-5,3)),1)
	var hit := gs.get_world_3d().direct_space_state.intersect_ray(ray)
	check(not hit.is_empty(),"entrance has a supporting physical floor")
	if not hit.is_empty():
		walking_y = hit.position.y + 0.85
		check(clear_walk(gs.to_global(Vector3(11,0,1)),gs.to_global(Vector3(11,0,41))),"0.5 m wide body can traverse the entire central aisle")
		for n in artifacts:
			var plate: Node3D = n.get_node_or_null("Plate")
			check(plate != null,"study has a readable plate")
			if plate == null: continue
			check(plate.global_basis.z.normalized().dot(Vector3(0,0,-1)) > 0.99,"plate faces the entrance")
			var stance := plate.global_position + plate.global_basis.z.normalized() * 1.2
			var aisle := stance
			aisle.x = gs.to_global(Vector3(11,0,0)).x
			check(clear_walk(aisle,stance),"body can approach the plate from the aisle: "+str(n.name))
			if n.get_meta("artifact_lookup_name") == "chroma_stack":
				var ring := [Vector3(-1.25,0,-1.25),Vector3(1.25,0,-1.25),Vector3(1.25,0,1.25),Vector3(-1.25,0,1.25)]
				var passable := true
				for i in 4:
					passable = passable and clear_walk(n.global_position+ring[i],n.global_position+ring[(i+1)%4])
				check(passable,"body can walk around the column: "+str(n.name))
	if "--capture" in OS.get_cmdline_user_args():
		var cam := Camera3D.new()
		em.add_child(cam)
		cam.fov = 68
		var eye := gs.to_local(Vector3(gs.global_position.x,walking_y+0.85,gs.global_position.z)).y
		await capture(cam,Vector3(11,eye,2),Vector3(11,eye,25),"entrance")
		await capture(cam,Vector3(10,eye,14),Vector3(12,2.6,18),"static-transforms")
		await capture(cam,Vector3(11,eye,22),Vector3(11,2.2,29),"translated-columns")
		await capture(cam,Vector3(11,30,8),Vector3(11,0,23),"overview")
	finish()

func capture(cam:Camera3D,position:Vector3,target:Vector3,label:String) -> void:
	cam.global_position = gs.to_global(position)
	cam.look_at(gs.to_global(target))
	cam.make_current()
	for frame in 20:
		await process_frame
		cam.make_current()
	await RenderingServer.frame_post_draw
	print("[column-hall] CAPTURE ",label," camera=",cam.global_position," current=",root.get_camera_3d().name)
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT+label+".png"))

func finish() -> void:
	var file := FileAccess.open(OUT+"runtime-checks.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"placements":placed,"headset_tested":false},"  "))
	print("[column-hall] SUMMARY ",checks.size()," checks, ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
