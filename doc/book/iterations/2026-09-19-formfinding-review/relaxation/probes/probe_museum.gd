extends SceneTree
var OUT := ""
var checks:=0
var failures:Array[String]=[]
var evidence:Dictionary={}
func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):OUT=a.trim_prefix("--out=")
	run.call_deferred()
func check(ok:bool,message:String) -> void:
	checks+=1
	if not ok:failures.append(message)
	print("RELAXATION ","PASS " if ok else "FAIL ",message)
func run() -> void:
	var em=load("res://commons/scenes/endless_museum.tscn").instantiate()
	var ctl=OUT+"museum-control.json";var f=FileAccess.open(ctl,FileAccess.WRITE);f.store_string(JSON.stringify({"first_chapter":"formfinding","dollhouse":0,"grid_pack":1}));f.close()
	em.set("EM_CONTROL",ctl);em.set("_overrides_path",ctl+".unused");em.set("_hand_path",ctl+".unused-hand");em.start_chapter="formfinding";em.start_map="FormFinding_Relaxation"
	root.add_child(em);current_scene=em;await create_timer(2).timeout
	em.set_process(false);em.set_physics_process(false);em.flush_stamps()
	var seg:Node3D
	for rec in em._segments:
		if rec.node.get_meta("em_map","")=="FormFinding_Relaxation":seg=rec.node;break
	check(seg!=null,"actual museum hall loaded")
	if not seg:finish();return
	var player=em._player;player.set_physics_process(false);em._feel.set_process(false);em._wardrobe.appearance_save_path="";em._wardrobe.costume.visible=false
	for rec in em._vis_records:
		var n=rec.get("node")
		if n is Node3D and is_instance_valid(n) and seg.is_ancestor_of(n):n.visible=true
	var objects:Dictionary={}
	for n in seg.find_children("*","Node",true,false):
		if n.has_meta("artifact_lookup_name"):objects[str(n.get_meta("artifact_lookup_name"))]=n
	evidence.player_global=str(player.global_position);evidence.segment_global=str(seg.global_position);evidence.artifacts={}
	for id in ["verlet_workbench","mass_spring_bench","frozen_glass_vessel","science_screen"]:
		check(objects.has(id),"retained "+id)
		if objects.has(id):evidence.artifacts[id]={"global":str(objects[id].global_position),"segment_local":str(seg.to_local(objects[id].global_position)),"scale":str(objects[id].global_basis.get_scale())}
	evidence.metadata_artifact_ids=objects.keys()
	check(["verlet_workbench","mass_spring_bench","frozen_glass_vessel","science_screen"].all(func(id):return objects.has(id)),"all four placed artifacts load")
	if not objects.has("verlet_workbench"):finish();return
	var ui:Node3D=objects.verlet_workbench
	if OUT.contains("paired-before"):
		var parent=ui.get_parent();var pose=ui.transform
		parent.remove_child(ui);ui.queue_free()
		ui=load("res://doc/book/iterations/2026-09-19-formfinding-review/relaxation/probes/legacy_verlet_workbench.gd").new()
		ui.name="VerletWorkbench";ui.transform=pose;parent.add_child(ui)
	var bench:Node3D=objects.mass_spring_bench
	evidence.bench_to_player=bench.global_position.distance_to(player.global_position)
	evidence.bench_to_player_horizontal=Vector2(bench.global_position.x,bench.global_position.z).distance_to(Vector2(player.global_position.x,player.global_position.z))
	var capsule=CapsuleShape3D.new();capsule.radius=.22;capsule.height=1.6
	var q=PhysicsShapeQueryParameters3D.new();q.shape=capsule;q.collision_mask=1;q.collide_with_areas=false;q.exclude=[player.get_rid()]
	await physics_frame
	for p in [Vector3(0,.85,1.1),Vector3(.5,.85,1.1),Vector3(-.5,.85,1.1),Vector3(1,.85,1.1),Vector3(1.5,.85,1.1)]:
		q.transform.origin=ui.to_global(p);var hits=seg.get_world_3d().direct_space_state.intersect_shape(q,5)
		evidence[str(p)]=hits.map(func(h):return str(h.collider.get_path()))
		check(hits.is_empty(),"clear standing console approach "+str(p))
	q.transform.origin=player.global_position+Vector3(0,.85,0)
	evidence.spawn_collision=seg.get_world_3d().direct_space_state.intersect_shape(q,8).map(func(h):return str(h.collider.get_path()))
	if OUT.contains("after"):
		check(ui.comparison,"museum token enables comparison")
		check(ui.buttons.size()==3,"three usable controls")
		var readouts=ui.find_children("*","Label3D",true,false).filter(func(label):return label.text.begins_with("VERLET /"))
		check(readouts.size()==1,"one live readout, no pre-tree duplicate")
		var cloths=ui.find_children("*","MeshInstance3D",true,false).filter(func(mesh):return mesh.mesh is ArrayMesh)
		check(cloths.size()==1,"one cloth mesh, no frozen overlay")
		ui.set_process(false);ui.set_physics_process(false);ui.act("RESET")
		for i in 60:ui._physics_process(1.0/60.0)
		ui._refresh_comparison()
	else:
		ui.set_process(false);ui._make_sim();ui._t=0.0
		for i in 60:ui._process(0.0166667)
	for n in em.find_children("*","Node",true,false):
		n.set_process(false);n.set_physics_process(false)
		if n is Timer:n.stop()
	var cam=Camera3D.new();cam.fov=57;em.add_child(cam)
	await shot(cam,ui.to_global(Vector3(0,1.65,3.0)),ui.to_global(Vector3(.2,1.02,0)),"workbench")
	await shot(cam,seg.to_global(Vector3(6,2.7,11)),seg.to_global(Vector3(6,1,6)),"hall")
	if OUT.contains("after"):
		ui.act("WIND")
		for i in 3:ui.act("PASSES")
		for passes in [1,4]:
			for i in 360:ui._physics_process(1.0/60)
			ui._refresh_comparison()
			var metrics=ui.comparison_metrics()
			evidence["comparison_"+str(passes)]={"passes":ui._sim.constraint_passes,"wind":ui.wind_enabled,"steps":ui.simulation_steps,"metrics":metrics}
			check(ui._sim.constraint_passes==passes and not ui.wind_enabled and ui.simulation_steps==420,"matched undriven budget study "+str(passes))
			await shot(cam,ui.to_global(Vector3(0,1.65,3.0)),ui.to_global(Vector3(.2,1.02,0)),"passes-"+str(passes))
			ui.act("PASSES")

	finish()
func shot(cam:Camera3D,pos:Vector3,target:Vector3,id:String) -> void:
	if DisplayServer.get_name()=="headless":return
	cam.global_position=pos;cam.look_at(target)
	for i in 15:cam.make_current();await process_frame
	cam.make_current()
	check(root.get_camera_3d()==cam,"camera current before draw "+id)
	await RenderingServer.frame_post_draw
	check(root.get_camera_3d()==cam,"camera current "+id)
	root.get_texture().get_image().save_png(OUT+id+".png")
	var f=FileAccess.open(OUT+id+"-camera.json",FileAccess.WRITE);f.store_string(JSON.stringify({"position":str(pos),"target":str(target),"fov":cam.fov},"  "));f.close()
func finish() -> void:
	var f=FileAccess.open(OUT+"museum-checks.json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":failures,"evidence":evidence,"headset_tested":false},"  "));f.close()
	print("RELAXATION COMPLETE ",checks," / ",failures.size());quit(0 if failures.is_empty() else 1)
