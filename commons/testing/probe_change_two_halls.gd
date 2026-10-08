extends SceneTree
var failures: Array[String] = []
var checks := 0
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)
	print("[change-two-halls] ", "PASS " if ok else "FAIL ", message)
func run() -> void:
	var map_name := "Change_Intro"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--map="): map_name = arg.trim_prefix("--map=")
	var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://commons/maps/"+map_name+"/map_data.json"))
	var em: Node3D = load("res://commons/scenes/endless_museum.tscn").instantiate()
	var ctl := "res://ada_run/change-two-halls-"+map_name+"-control.json"
	em.set("EM_CONTROL",ctl);em.set("_overrides_path",ctl+".unused");em.set("_hand_path",ctl+".unused-hand")
	em.set("start_chapter","change");em.set("start_map",map_name)
	var f := FileAccess.open(ctl,FileAccess.WRITE);f.store_string(JSON.stringify({"first_chapter":"change","dollhouse":0,"grid_pack":1}));f.close()
	root.add_child(em);current_scene=em
	await create_timer(2).timeout
	em.set_process(false);em.set_physics_process(false);em.call("flush_stamps")
	var seg: Node3D
	for rec: Dictionary in em.get("_segments"):
		if rec.node.get_meta("em_map","")==map_name:seg=rec.node;break
	check(seg!=null,map_name+" is an active change hall")
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
				var parent = n.get_parent()
				var nested := false
				while parent != seg and parent != null:
					if parent.has_meta("artifact_lookup_name"): nested = true; break
					parent = parent.get_parent()
				if nested: continue
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
			var hits = seg.get_world_3d().direct_space_state.intersect_shape(query,8)
			if not hits.is_empty():
				blocked.append(z)
				for hit in hits: print("AISLE HIT ", z, " ", hit.collider.get_path())
		check(blocked.is_empty(),map_name+" central aisle passes capsule sweep; blocked z="+str(blocked))
		if map_name == "Change_Intro":
			var bridge
			for n in seg.find_children("*","Node",true,false):
				if n.get_meta("artifact_lookup_name","") == "ftc_bridge": bridge = n; break
			check(bridge != null and bridge.evidence == "longhand", "bridge exposes signed contributions and endpoint evidence")
			if bridge:
				check(absf(bridge._integrate_slope() - (bridge._curve_h(1.0)-bridge._curve_h(0.0))) < 0.001, "512-interval derivative sum agrees with endpoint difference")
				check(bridge._curve_slope(0.25)>0 and bridge._curve_slope(0.75)<0, "arch has positive and negative rate contributions")
		var lesson = seg.find_child("SharedFieldLesson",true,false)
		if map_name=="Flow_Field":
			check(lesson!=null,"flow lesson loads in the consolidated hall")
			if lesson:
				var b=lesson.painter
				b.set_process(false)
				check(not b.field_evolving and b._particles.size()==80,"eighty particles start under a held field")
				check(b._canvas_mesh.rotation_degrees.x==0,"canvas and particles share the XZ plane")
				var p=Vector2(0.03,0.02);var direction=b.field_direction(p)
				check(is_equal_approx(direction.length(),1.0),"noise-to-angle rule yields a unit direction")
				b._particles[0].x=p.x;b._particles[0].y=p.y
				var t:float=b._time;b._process(0.01)
				var actual=Vector2(b._particles[0].x,b._particles[0].y)
				check(actual.is_equal_approx(p+direction*b.particle_speed*0.01),"particle displacement uses the shared direction sampler")
				check(b._time==t,"holding field time leaves the field clock unchanged while particles move")
				var button=lesson.buttons.ARROWS.get_node("InteractableAreaButton")
				XRToolsPointerEvent.pressed(em.get("_cam"),button,button.global_position)
				XRToolsPointerEvent.released(em.get("_cam"),button,button.global_position)
				check(lesson.arrows.visible and lesson.arrows.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size()==144,"pointer reveals twenty-four three-line arrows")
				var vertices=lesson.arrows.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
				var first=Vector2(vertices[0].x,vertices[0].z)
				var arrow=Vector2(vertices[1].x-vertices[0].x,vertices[1].z-vertices[0].z).normalized()
				check(arrow.is_equal_approx(b.field_direction(first)),"drawn arrow agrees with the exact particle sampler at its address")
				lesson.act("FIELD TIME");b._process(0.1)
				check(b._time>t,"field-time control resumes field evolution")
				lesson.act("FIELD TIME")
				check(lesson.buttons.values().all(func(v):return v.global_position.y>0.65 and v.global_position.y<1.5),"added controls lie within standing reach")
				b.set_process(true)
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
			root.get_texture().get_image().save_png("res://ada_run/change_two_"+map_name+".png")
			cam.global_position=seg.to_global(Vector3(float(source.map_info.dimensions.width)/2,1.7,7))
			cam.look_at(seg.to_global(Vector3(float(source.map_info.dimensions.width)/2,1.7,19)))
			for i in 20:await process_frame;cam.make_current()
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://ada_run/change_two_entry_"+map_name+".png")
	f=FileAccess.open("res://ada_run/change_two_"+map_name+"_probe.json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":failures},"  "));f.close()
	quit(0 if failures.is_empty() else 1)
