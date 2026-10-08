extends SceneTree
var failures: Array[String] = []
var checks := 0
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)
	print("[ribbon-patterns] ", "PASS " if ok else "FAIL ", message)
func run() -> void:
	var map_name := "Ribbon_Patterns_01"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--map="): map_name = arg.trim_prefix("--map=")
	var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://commons/maps/"+map_name+"/map_data.json"))
	var em: Node3D = load("res://commons/scenes/endless_museum.tscn").instantiate()
	var ctl := "res://ada_run/ribbon-compact-"+map_name+"-control.json"
	em.set("EM_CONTROL",ctl);em.set("_overrides_path",ctl+".unused");em.set("_hand_path",ctl+".unused-hand")
	em.set("start_chapter","tiling");em.set("start_map",map_name)
	var f := FileAccess.open(ctl,FileAccess.WRITE);f.store_string(JSON.stringify({"first_chapter":"tiling","dollhouse":0,"grid_pack":1}));f.close()
	root.add_child(em);current_scene=em
	await create_timer(2).timeout
	em.set_process(false);em.set_physics_process(false);em.call("flush_stamps")
	var seg: Node3D
	for rec: Dictionary in em.get("_segments"):
		if rec.node.get_meta("em_map","")==map_name:seg=rec.node;break
	check(seg!=null,map_name+" is an active tiling hall")
	if seg:
		var player: CharacterBody3D = em.get("_player")
		player.set_physics_process(false)
		em.get("_feel").set_process(false)
		var wardrobe = em.get("_wardrobe")
		wardrobe.appearance_save_path = ""
		wardrobe.costume.visible = false
		var found: Dictionary = {}
		for n in seg.find_children("*","Node",true,false):
			if n.has_meta("artifact_lookup_name"):
				var key := str(n.get_meta("artifact_lookup_name"));found[key]=int(found.get(key,0))+1
		for row in source.layers.interactables:
			for raw in row:
				var key := str(raw).split(":")[0].split("#")[0].strip_edges()
				if key.is_empty(): continue
				check(int(found.get(key,0))==1,map_name+" places "+key+" exactly once")
		await physics_frame
		var capsule := CapsuleShape3D.new();capsule.radius=0.22;capsule.height=1.6
		var query := PhysicsShapeQueryParameters3D.new();query.shape=capsule;query.collide_with_areas=false;query.exclude=[player.get_rid()]
		var blocked: Array[int] = []
		for z in range(5,int(source.map_info.dimensions.depth)-5,2):
			query.transform=Transform3D(Basis.IDENTITY,seg.to_global(Vector3(int(source.map_info.dimensions.width)/2+0.5,1.1,z+4)))
			if not seg.get_world_3d().direct_space_state.intersect_shape(query,1).is_empty():blocked.append(z)
		check(blocked.is_empty(),map_name+" central aisle passes capsule sweep; blocked z="+str(blocked))
		if "--capture" in OS.get_cmdline_user_args():
			for rec in em.get("_vis_records"):
				var n = rec.get("node")
				if n is Node3D and is_instance_valid(n) and seg.is_ancestor_of(n):n.visible=true
			var cam := Camera3D.new();em.add_child(cam);cam.fov=65
			var mid := Vector3(float(source.map_info.dimensions.width)/2,0,float(source.map_info.dimensions.depth)/2+4)
			var extent := maxf(float(source.map_info.dimensions.width),float(source.map_info.dimensions.depth))
			cam.global_position=seg.to_global(mid+Vector3(-extent*0.45,extent*0.8,-extent*0.6));cam.look_at(seg.to_global(mid))
			for i in range(20): await process_frame;cam.make_current()
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://ada_run/compact_"+map_name+".png")
			cam.global_position=seg.to_global(Vector3(float(source.map_info.dimensions.width)/2,1.7,7))
			cam.look_at(seg.to_global(Vector3(float(source.map_info.dimensions.width)/2,1.7,19)))
			for i in 20:await process_frame;cam.make_current()
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://ada_run/compact_entry_"+map_name+".png")
	f=FileAccess.open("res://ada_run/compact_"+map_name+"_probe.json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":failures},"  "));f.close()
	quit(0 if failures.is_empty() else 1)
