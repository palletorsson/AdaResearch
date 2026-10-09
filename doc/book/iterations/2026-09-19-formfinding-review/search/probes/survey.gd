extends SceneTree
var out := ""
var hall := "FormFinding_Annealing"
var current := false
var capture_enabled := true
var checks: Array = []
var report: Dictionary = {}
var saved_labels := false
var saved_scripts: Array = []
var frozen_museum: GDScript
func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out=arg.trim_prefix("--out=")
		if arg.begins_with("--hall="):hall=arg.trim_prefix("--hall=")
	current="--current" in OS.get_cmdline_user_args()
	saved_labels="--saved-labels" in OS.get_cmdline_user_args()
	capture_enabled=not "--no-capture" in OS.get_cmdline_user_args()
	run.call_deferred()
func check(ok:bool,message:String) -> void:
	checks.append({"ok":ok,"message":message});print("SEARCH ","PASS " if ok else "FAIL ",message)
func labels(n:Node) -> Array:
	var result:Array=[]
	for l in n.find_children("*","Label3D",true,false):result.append(l.text)
	return result
func run() -> void:
	frozen_museum=GDScript.new();frozen_museum.source_code=FileAccess.get_file_as_string("res://doc/book/iterations/2026-09-19-formfinding-review/search/frozen-museum.gd");check(frozen_museum.reload()==OK,"frozen museum compiles");frozen_museum.take_over_path("res://commons/scenes/endless_museum.gd")
	if saved_labels:
		for path in ["algorithms/optimization/simulatedannealing/simulated_annealing_visualization.gd","commons/artifacts/impossible_end_table/impossible_end_table.gd"]:
			var saved:=GDScript.new();var regex:=RegEx.new();regex.compile("(?m)^class_name[^\\n]*\\n")
			saved.source_code=regex.sub(FileAccess.get_file_as_string("res://doc/book/iterations/2026-09-19-formfinding-review/search/before-source/"+path),"",true)
			check(saved.reload()==OK,"saved label source compiles: "+path)
			saved.take_over_path("res://"+path);saved_scripts.append(saved)
	var em=load("res://commons/scenes/endless_museum.tscn").instantiate()
	var ctl=out+"control.json";var f=FileAccess.open(ctl,FileAccess.WRITE);f.store_string(JSON.stringify({"first_chapter":"formfinding","dollhouse":0,"grid_pack":1}));f.close()
	em.set("EM_CONTROL",ctl);em.set("_overrides_path",ctl+".unused");em.set("_hand_path",ctl+".unused");em.set("start_chapter","formfinding");em.set("start_map",hall)
	root.add_child(em);current_scene=em;await create_timer(2).timeout
	em.set_process(false);em.set_physics_process(false);em.flush_stamps()
	# The museum's desktop-camera guard is a child Timer, not em._process.
	for child in em.get("_cam").get_children():
		if child is Timer:child.stop()
	var seg:Node3D
	for r in em.get("_segments"):
		if r.node.get_meta("em_map","")==hall:seg=r.node;break
	check(seg!=null,"actual authored museum hall loads")
	if not seg:finish();return
	var player=em.get("_player");player.set_physics_process(false);em.get("_feel").set_process(false)
	em.get("_wardrobe").appearance_save_path="";em.get("_wardrobe").costume.visible=false
	for rec in em.get("_vis_records"):
		var n=rec.get("node")
		if n is Node3D and is_instance_valid(n) and seg.is_ancestor_of(n):n.visible=true
	var nodes:Dictionary={};var inventory:Array=[]
	var wanted=["energy_landscape_bench","max_q_basin_room","simulated_annealing","impossible_end_table","science_screen"] if hall.ends_with("Annealing") else ["balance_puzzle","gradient_descent_optimizer","self_shaping_forge","science_screen"]
	for node in seg.find_children("*","Node3D",true,false):
		var key=str(node.get_meta("artifact_lookup_name",""))
		if key in wanted:
			nodes[key]=node
			node.set_process(false);node.set_physics_process(false)
			inventory.append({"token":key,"position":str(node.global_position),"rotation":str(node.rotation_degrees),"scale":str(node.global_basis.get_scale()),"extent":str(em._extent_of(node)),"labels":labels(node)})
	check(nodes.size()==wanted.size(),"all authored artifacts instantiate: "+str(nodes.size()))
	if saved_labels:
		check(nodes.simulated_annealing.get_script()==saved_scripts[0],"actual museum uses saved annealing label source")
		check(nodes.impossible_end_table.get_script()==saved_scripts[1],"actual museum uses saved end-table plaque source")
	report={"hall":hall,"inventory":inventory,"player_position":str(player.global_position),"headset_tested":false}
	var cam=Camera3D.new();em.add_child(cam);cam.fov=65
	var shape=CapsuleShape3D.new();shape.radius=.22;shape.height=1.6
	var query=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.collision_mask=1;query.exclude=[player.get_rid()];query.collide_with_areas=false
	var approaches:Array=[]
	for key in nodes:
		if key=="science_screen":continue
		var node=nodes[key]
		var d=3.3 if key=="max_q_basin_room" else 1.3
		var p=node.to_global(Vector3(0,0,d));p.y=1.05
		query.transform.origin=p;await physics_frame
		var hits=seg.get_world_3d().direct_space_state.intersect_shape(query,8)
		var names:Array=[]
		for hit in hits:names.append(str(hit.collider.get_path()))
		approaches.append({"token":key,"point":str(p),"hits":names})
	report["approaches"]=approaches
	var volume=BoxShape3D.new();volume.size=Vector3(5.08,2.0,5.08)
	var footprint=PhysicsShapeQueryParameters3D.new();footprint.shape=volume;footprint.collision_mask=1;footprint.collide_with_areas=false;footprint.exclude=[player.get_rid()]
	for body in nodes.max_q_basin_room.find_children("*","CollisionObject3D",true,false):footprint.exclude.append(body.get_rid())
	var candidates:Array=[]
	var obstacles:Array=[]
	for c in seg.get_node("Collision").get_children():
		if c is CollisionShape3D and c.shape is BoxShape3D:
			var bounds=c.global_transform*AABB(-c.shape.size*.5,c.shape.size)
			if bounds.end.y>.15:obstacles.append({"at":str(bounds.position),"size":str(bounds.size)})
	report["obstacles_above_floor"]=obstacles
	report["tile"]=seg.get_meta("em_tile",[])
	report["segment_position"]=str(seg.global_position)
	for z in range(2,10):
		for x in range(2,12):
			var p=Vector3(x+.5,1.1,z+.5);footprint.transform.origin=p
			var hits=seg.get_world_3d().direct_space_state.intersect_shape(footprint,16)
			var hitnames:Array=[]
			for hit in hits:hitnames.append(str(hit.collider.get_path()))
			var aabb=AABB(Vector3(p.x-2.54,.1,p.z-2.54),Vector3(5.08,2.0,5.08));var overlaps:Array=[]
			for key in nodes:
				if key!="max_q_basin_room" and aabb.intersects(em._extent_of(nodes[key])):overlaps.append(key)
			candidates.append({"cell":[x,z],"hits":hitnames,"authored_overlap":overlaps})
	report["candidates"]=candidates
	report["frozen_museum_sha256"]=em.get_script().source_code.sha256_text()
	finish()

func capture(cam:Camera3D,suffix:String,at:Vector3,target:Vector3) -> void:
	if not capture_enabled:return
	cam.global_position=at;cam.look_at(target);cam.make_current()
	for i in 12:await process_frame
	check(root.get_camera_3d()==cam,"capture camera active before draw: "+suffix)
	await RenderingServer.frame_post_draw
	check(root.get_camera_3d()==cam,"capture camera active after draw: "+suffix)
	root.get_texture().get_image().save_png(out+suffix+".png")
	var f=FileAccess.open(out+suffix+"-camera.json",FileAccess.WRITE);f.store_string(JSON.stringify({"position":str(at),"target":str(target),"fov":cam.fov,"viewport":str(root.size)},"  "));f.close()
func finish() -> void:
	report["checks"]=checks
	var f=FileAccess.open(out+"museum.json",FileAccess.WRITE);f.store_string(JSON.stringify(report,"  "));f.close()
	quit(0 if checks.all(func(x):return x.ok) else 1)
