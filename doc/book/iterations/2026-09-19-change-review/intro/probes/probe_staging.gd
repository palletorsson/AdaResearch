extends "res://doc/book/iterations/2026-09-19-change-review/intro/probes/base.gd"
var objects: Dictionary = {}
var info: Dictionary = {}

func run() -> void:
	var em: Node3D=load("res://commons/scenes/endless_museum.tscn").instantiate()
	var ctl:=OUT+"staging-control.json"
	em.set("EM_CONTROL",ctl);em.set("_overrides_path",ctl+".unused");em.set("_hand_path",ctl+".unused-hand")
	em.set("start_chapter","change");em.set("start_map","Change_Intro")
	var f:=FileAccess.open(ctl,FileAccess.WRITE);f.store_string(JSON.stringify({"first_chapter":"change","dollhouse":0,"grid_pack":1}));f.close()
	root.add_child(em);current_scene=em
	await create_timer(1).timeout
	em.set_process(false);em.set_physics_process(false);em.call("flush_stamps")
	var seg:Node3D
	for rec:Dictionary in em.get("_segments"):
		if rec.node.get_meta("em_map","")=="Change_Intro":seg=rec.node;break
	check(seg!=null,"actual Change_Intro museum segment loads")
	if seg==null:finish();return
	var grid:=Node3D.new();grid.name="ProbeSourceCoordinates";grid.position.z=4.0;seg.add_child(grid)
	for i in 30:await process_frame
	var player:CharacterBody3D=em.get("_player")
	player.set_physics_process(false);em.get("_feel").set_process(false)
	var wardrobe=em.get("_wardrobe");wardrobe.appearance_save_path="";wardrobe.costume.visible=false
	for n in seg.find_children("*","Node",true,false):
		if n.has_meta("artifact_lookup_name"):
			var par=n.get_parent();var nested:=false
			while par and par!=seg:
				if par.has_meta("artifact_lookup_name"):nested=true;break
				par=par.get_parent()
			if not nested:objects[str(n.get_meta("artifact_lookup_name"))]=n
	var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://commons/maps/Change_Intro/map_data.json"))
	var authored:Array=[]
	for row:Array in data.layers.interactables:
		for raw in row:
			var token:=str(raw).split(":")[0].split("#")[0].strip_edges()
			if not token.is_empty():
				authored.append(token)
				check(objects.has(token),"preserved artifact "+token)
	check(authored.size()==17 and authored.all(func(key):return objects.has(key)),"all 17 authored artifacts present")
	check(not seg.has_node("SimGrid_Change_Intro"),"ordinary authored museum transplant (no simulation-grid substitution)")
	for key in objects:
		var n:Node3D=objects[key]
		info[key]={"global_position":str(n.global_position),"grid_position":str(grid.to_local(n.global_position)),"scale":str(n.scale),"rotation":str(n.rotation_degrees)}
	var capsule:=CapsuleShape3D.new();capsule.radius=.22;capsule.height=1.6
	var q:=PhysicsShapeQueryParameters3D.new();q.shape=capsule;q.collision_mask=1;q.exclude=[player.get_rid()]
	await physics_frame
	var blocked:Array=[]
	for z in range(2,33):
		q.transform.origin=grid.to_global(Vector3(13.5,1.1,z+.5))
		if not grid.get_world_3d().direct_space_state.intersect_shape(q).is_empty():blocked.append(z)
	check(blocked.is_empty(),"central route clear for standing capsule: "+str(blocked))
	for key in ["tangent_slope_workbench","riemann_sum_workbench","ftc_bridge"]:
		var n:Node3D=objects[key]
		q.transform.origin=n.to_global(Vector3(0,.85,2))
		var hits=grid.get_world_3d().direct_space_state.intersect_shape(q)
		check(hits.is_empty(),key+" standing approach is clear")
		var start:=grid.to_global(Vector3(13.5,1.1,grid.to_local(q.transform.origin).z))
		q.transform.origin=start;q.motion=n.to_global(Vector3(0,.85,2))-start
		var result=grid.get_world_3d().direct_space_state.cast_motion(q)
		check(result[0]>.99,key+" lateral approach from central route is clear")
		q.motion=Vector3.ZERO
	var cam:=Camera3D.new();em.add_child(cam);cam.fov=74
	for rec in em.get("_vis_records"):
		var n=rec.get("node")
		if n is Node3D and is_instance_valid(n) and seg.is_ancestor_of(n):n.visible=true
	await capture(cam,grid.to_global(Vector3(13.5,1.7,-.5)),grid.to_global(Vector3(13.5,1.7,14)),"entry")
	await capture(cam,grid.to_global(Vector3(13.5,1.7,6.5)),grid.to_global(Vector3(20.5,1.5,9.5)),"sum_approach")
	await capture(cam,grid.to_global(Vector3(13.5,24,-8)),grid.to_global(Vector3(13.5,0,15)),"plan")
	for key in ["tangent_slope_workbench","riemann_sum_workbench"]:
		var n:Node3D=objects[key]
		await capture(cam,n.to_global(Vector3(.6,1.9,2.5)),n.to_global(Vector3(.5,1.5,0)),key)
	finish()

func finish() -> void:
	var f:=FileAccess.open(OUT+"staging-checks.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"failures":failures,"objects":info,"headset_tested":false},"  "));f.close()
	print("INTRO_STAGING ",checks," checks / ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
