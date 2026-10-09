extends "res://doc/book/iterations/2026-09-19-forces-review/motion/probes/base.gd"
var details:Dictionary={}
func run() -> void:
	var map_name="Vectors_Act4a_KineticForces"
	var em=load("res://commons/scenes/endless_museum.tscn").instantiate()
	var ctl=OUT+"staging-control.json"
	var f=FileAccess.open(ctl,FileAccess.WRITE);f.store_string(JSON.stringify({"first_chapter":"forces","dollhouse":0,"grid_pack":1}));f.close()
	em.set("EM_CONTROL",ctl);em.set("_overrides_path",ctl+".unused");em.set("_hand_path",ctl+".unused-hand");em.set("start_chapter","forces");em.set("start_map",map_name)
	root.add_child(em);current_scene=em;await create_timer(2).timeout
	em.set_process(false);em.set_physics_process(false);em.call("flush_stamps")
	var seg:Node3D
	for rec in em.get("_segments"):
		if rec.node.get_meta("em_map","")==map_name:seg=rec.node;break
	check(seg!=null,"actual Kinetic museum segment loads")
	if not seg:finish();return
	var player=em.get("_player");player.set_physics_process(false);em.get("_feel").set_process(false)
	em.get("_wardrobe").appearance_save_path="";em.get("_wardrobe").costume.visible=false
	for rec in em.get("_vis_records"):
		var n=rec.get("node")
		if n is Node3D and is_instance_valid(n) and seg.is_ancestor_of(n):n.visible=true
	var objects:Dictionary={}
	for n in seg.find_children("*","Node",true,false):
		if n.has_meta("artifact_lookup_name"):objects[str(n.get_meta("artifact_lookup_name"))]=n
	var grid=Node3D.new();grid.position.z=4;seg.add_child(grid)
	var d=JSON.parse_string(FileAccess.get_file_as_string("res://commons/maps/"+map_name+"/map_data.json"))
	var authored:Array=[]
	for z in d.layers.interactables.size():
		for x in d.layers.interactables[z].size():
			var raw=str(d.layers.interactables[z][x]);var token=raw.split(":")[0].split("#")[0].strip_edges()
			if token.is_empty():continue
			authored.append(token)
			if OUT.contains("before") and token in ["sisyphus_mower","prop_carousel"]:
				check(not objects.has(token),"baseline registry omission reproduced: "+token)
			else:check(objects.has(token),"artifact retained: "+token)
			if objects.has(token):
				var n:Node3D=objects[token];details[token]={"authored_cell":[x,z],"global_position":str(n.global_position),"source_position":str(grid.to_local(n.global_position)),"scale":str(n.global_basis.get_scale())}
	check(authored.size()==8,"all eight authored artifacts retained")
	check(not seg.has_node("SimGrid_"+map_name),"ordinary museum transplant")
	var drag:Node3D=objects.drag_corridor;var mower:Node3D=objects.force_mower;var ring:Node3D=objects.centrifuge_ring
	details["encounter_order"]= "drag / mower / ring" if grid.to_local(mower.global_position).z<grid.to_local(ring.global_position).z else "drag / ring / mower"
	check(grid.to_local(drag.global_position).z<minf(grid.to_local(mower.global_position).z,grid.to_local(ring.global_position).z),"drag comes first")
	if OUT.contains("after"):
		check(grid.to_local(mower.global_position).z<grid.to_local(ring.global_position).z,"mower then ring matches book and primary order")
	var capsule=CapsuleShape3D.new();capsule.radius=.22;capsule.height=1.6
	var q=PhysicsShapeQueryParameters3D.new();q.shape=capsule;q.collision_mask=1;q.collide_with_areas=false;q.exclude=[player.get_rid()]
	await physics_frame
	for n in [mower,ring]:
		for p in [Vector3(3,1.1,0),Vector3(0,1.1,-3)]:
			q.transform.origin=n.to_global(p)
			check(seg.get_world_3d().direct_space_state.intersect_shape(q,1).is_empty(),str(n.name)+" lateral approach "+str(p))
	q.transform.origin=ring._controls.to_global(Vector3(0,1.1,5.4))
	# The control rig is identity; the console itself stands at local radius+1.
	check(seg.get_world_3d().direct_space_state.intersect_shape(q,1).is_empty(),"standing just beyond ring SPEED console is clear")
	check(mower.global_position.distance_to(ring.global_position)>10,"mower lawn and ring remain distinct encounters")
	ring.set_process(false);ring._phase=0;ring._advance();mower.set_process(false);mower.set_physics_process(false)
	var cam=Camera3D.new();cam.fov=70;em.add_child(cam)
	await capture(cam,grid.to_global(Vector3(15.5,25,18)),grid.to_global(Vector3(15.5,0,30)),"kinetic-plan")
	await capture(cam,grid.to_global(Vector3(15.5,1.7,19)),grid.to_global(Vector3(9.5,1.1,26)),"kinetic-approach")
	finish()
func finish() -> void:
	var f=FileAccess.open(OUT+"staging-checks.json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":failures,"details":details,"headset_tested":false},"  "));f.close()
	quit(0 if failures.is_empty() else 1)
