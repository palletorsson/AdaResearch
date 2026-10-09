extends SceneTree
var out:=""
var current:=false
var checks:Array=[]
var report:Dictionary={}
var frozen:GDScript
func _initialize()->void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):out=a.trim_prefix("--out=")
	current="--current" in OS.get_cmdline_user_args();run.call_deferred()
func check(ok:bool,message:String)->void:
	checks.append({"ok":ok,"message":message});print("RANDOM-END ","PASS " if ok else "FAIL ",message)
func signature(p:Node)->String:
	return JSON.stringify({"vertices":p.vertex_grid,"pheromone":p.pheromone_grid,"walkers":p.walkers,"rng":str(p._rng.state)}).sha256_text()
func run()->void:
	frozen=GDScript.new();frozen.source_code=FileAccess.get_file_as_string("res://doc/book/iterations/2026-09-19-randomness-review/ending/frozen-museum.gd")
	check(frozen.reload()==OK,"frozen current loader compiles");frozen.take_over_path("res://commons/scenes/endless_museum.gd")
	var em=load("res://commons/scenes/endless_museum.tscn").instantiate()
	var ctl=out+"control.json";var f=FileAccess.open(ctl,FileAccess.WRITE);f.store_string(JSON.stringify({"first_chapter":"randomness","dollhouse":0,"grid_pack":1}));f.close()
	em.set("EM_CONTROL",ctl);em.set("_overrides_path",ctl+".unused");em.set("_hand_path",ctl+".unused");em.set("start_chapter","randomness");em.set("start_map","Random_Pheromone")
	root.add_child(em);current_scene=em;await create_timer(2).timeout
	em.set_process(false);em.set_physics_process(false);em.flush_stamps()
	for timer in em.get("_cam").get_children():
		if timer is Timer:timer.stop()
	var player=em.get("_player");player.set_process(false);player.set_physics_process(false);em.get("_feel").set_process(false)
	em.get("_wardrobe").appearance_save_path="";em.get("_wardrobe").costume.visible=false
	var seg:Node3D
	for rec in em.get("_segments"):
		if rec.node.get_meta("em_map","")=="Random_Pheromone":seg=rec.node;break
	check(seg!=null,"restored authored Pheromone hall loads")
	check(em.get_script()==frozen,"actual scene uses frozen loader")
	if not seg:finish();return
	var p:Node3D;var inventory:Array=[]
	for rec in em.get("_edit_records"):
		var n=rec.get("node")
		if n is Node3D and is_instance_valid(n) and seg.is_ancestor_of(n) and rec.get("tile_cell",[]).size()==2:
			inventory.append({"key":str(n.get_meta("artifact_lookup_name","")),"cell":rec.tile_cell,"position":str(n.global_position),"scale":str(n.global_basis.get_scale()),"extent":str(em._extent_of(n))})
			if n.get_script()!=null and str(n.get_script().resource_path).ends_with("pheromone_terrain.gd"):p=n
	check(p!=null,"authored pheromone terrain instantiates")
	if not p:finish();return
	p.set_process(false)
	for rec in em.get("_vis_records"):
		var n=rec.get("node")
		if n is Node3D and is_instance_valid(n) and seg.is_ancestor_of(n):n.visible=true
	var cam=Camera3D.new();em.add_child(cam);cam.fov=70
	var eye=p.to_global(Vector3(0,0,4.1 if current else 12));eye.y=1.7
	var target=p.to_global(Vector3(0,.35 if current else .8,0))
	# Fixed world coordinates match the old20m survey even after the map move.
	var overview=Vector3(12.5,12,18.5);var overview_target=Vector3(5.5,0,5.5)
	var side=p.to_global(Vector3(3.1,0,2.3));side.y=1.7
	var query=PhysicsShapeQueryParameters3D.new();var capsule=CapsuleShape3D.new();capsule.radius=.22;capsule.height=1.6;query.shape=capsule;query.collision_mask=1;query.collide_with_areas=false;query.exclude=[player.get_rid()];query.transform.origin=Vector3(eye.x,1.05,eye.z)
	await physics_frame
	var hits=seg.get_world_3d().direct_space_state.intersect_shape(query,16);var hit_names:Array=[]
	for hit in hits:hit_names.append(str(hit.collider.get_path()))
	report={"inventory":inventory,"scale":str(p.global_basis.get_scale()),"origin":str(p.global_position),"extent":str(em._extent_of(p)),"standing_hits":hit_names,"loaded_museum_sha256":frozen.source_code.sha256_text(),"headset_tested":false}
	if current:
		check(hit_names.is_empty(),"standing capsule clears museum obstructions")
		var footprint=PhysicsShapeQueryParameters3D.new();var footprint_box=BoxShape3D.new();footprint_box.size=Vector3(4.8,1.2,4.8)
		footprint.shape=footprint_box;footprint.collision_mask=1;footprint.collide_with_areas=false;footprint.transform.origin=p.to_global(Vector3(0,.8,0));footprint.exclude=[player.get_rid()]
		for body in p.find_children("*","PhysicsBody3D",true,false):footprint.exclude.append(body.get_rid())
		var obstructions:Array=[]
		var obstruction_shapes:Array=[]
		for hit in seg.get_world_3d().direct_space_state.intersect_shape(footprint,64):
			obstructions.append(str(hit.collider.get_path()))
			var owner=hit.collider.shape_owner_get_owner(hit.collider.shape_find_owner(hit.shape))
			obstruction_shapes.append({"path":str(owner.get_path()),"extent":str(em._extent_of(owner)),"position":str(owner.global_position)})
		report.obstruction_shapes=obstruction_shapes
		report.footprint_obstructions=obstructions;check(obstructions.is_empty(),"whole4.8metre display clears other collision above floor")
		report.rendered_width=4.8;report.model_width=p.mesh_instance.get_meta("plane_width");report.model_segments=p.x_segments
		var controls:Array=[]
		for i in 5:
			var a=p._comparison_panel.find_child("Btn_"+str(i),true,false).get_node("InteractableAreaButton")
			controls.append({"index":i,"position":str(a.global_position),"height":a.global_position.y,"distance_from_standing_eye":a.global_position.distance_to(eye)})
			check(a.global_position.y>.75 and a.global_position.y<1.4,"control at standing reach height: "+str(i))
		report.controls=controls
		var field_rect=Rect2(Vector2(p.global_position.x-2.4,p.global_position.z-2.4),Vector2(4.8,4.8))
		var overlaps:Array=[]
		for rec in em.get("_edit_records"):
			var other=rec.get("node")
			if other is Node3D and is_instance_valid(other) and seg.is_ancestor_of(other) and other!=p and rec.get("tile_cell",[]).size()==2:
				var bound:AABB=em._extent_of(other)
				if field_rect.intersects(Rect2(Vector2(bound.position.x,bound.position.z),Vector2(bound.size.x,bound.size.z))):overlaps.append(str(other.get_meta("artifact_lookup_name","")))
		report.retained_artifact_overlaps=overlaps;check(overlaps.is_empty(),"display footprint clears retained secondary artifact extents")
		var blockers:Array=[]
		for i in 5:
			var a=p._comparison_panel.find_child("Btn_"+str(i),true,false).get_node("InteractableAreaButton")
			var ray=PhysicsRayQueryParameters3D.create(eye,a.global_position,1,[player.get_rid()]);ray.collide_with_areas=false
			var hit=seg.get_world_3d().direct_space_state.intersect_ray(ray)
			if not hit.is_empty() and hit.collider.get_parent()!=a.get_parent():blockers.append(str(hit.collider.get_path()))
		report.control_sightline_blockers=blockers;check(blockers.is_empty(),"five control sightlines clear solid museum geometry")
	if not current:
		p.walk_seed=190919;p.rule="trail";p._init_rng();p._initialize_grids();p._create_walkers()
		for i in 300:p._decay_pheromones(1.0/p.walk_speed);p._walk_step()
		p._update_mesh();p._update_info_label()
		report.attract_signature=signature(p)
		await capture(cam,"attract-standing",eye,target);await capture(cam,"attract-overview",overview,overview_target)
	else:
		check(p.comparison,"actual token enables comparison controls")
		check(p._comparison_steps==0,"comparison waits at reset before visitor steps")
		await capture(cam,"arrival-standing",eye,target)
		press(p,0,cam)
		for i in 15:press(p,3,cam)
		check(p._comparison_steps==300,"fifteen20-step presses yield300fixed steps")
		report.attract_signature=signature(p)
		await capture(cam,"attract-standing",eye,target);await capture(cam,"attract-overview",overview,overview_target)
		await capture(cam,"attract-side-standing",side,target)
		press(p,1,cam)
		check(p._comparison_steps==0 and p.rule=="avoid","AVOID resets chosen law and history")
		for i in 15:press(p,3,cam)
		report.avoid_signature=signature(p)
		check(report.avoid_signature!=report.attract_signature,"same-seed alternate law creates different history")
		await capture(cam,"avoid-standing",eye,target);await capture(cam,"avoid-overview",overview,overview_target)
		await capture(cam,"avoid-side-standing",side,target)
		press(p,4,cam);check(p._comparison_steps==0 and p.rule=="avoid","REPLAY resets current law without changing it")
		check(p._walker_markers.size()==4,"four position markers remain after repeated resets")
		check(report.attract_signature=="81625733333439f185d7b8084120884571e122325f4e6c5bac84da37ba9039c2","museum ATTRACT matches pre-change fixed-step fixture")
		check(report.avoid_signature=="b075a12c93e9ce4d0353cf1e89b05bd7b23598f1521cd44790405ee89d51d051","museum AVOID matches pre-change fixed-step fixture")
	finish()
func press(p:Node,index:int,cam:Camera3D)->void:
	var area=p._comparison_panel.find_child("Btn_"+str(index),true,false).get_node("InteractableAreaButton")
	XRToolsPointerEvent.pressed(cam,area,area.global_position);XRToolsPointerEvent.released(cam,area,area.global_position)
func capture(cam:Camera3D,name:String,at:Vector3,target:Vector3)->void:
	cam.global_position=at;cam.look_at(target);cam.make_current()
	for i in 8:await process_frame
	check(root.get_camera_3d()==cam,"capture camera active before draw: "+name);await RenderingServer.frame_post_draw;check(root.get_camera_3d()==cam,"capture camera active after draw: "+name)
	root.get_texture().get_image().save_png(out+name+".png")
	var f=FileAccess.open(out+name+"-camera.json",FileAccess.WRITE);f.store_string(JSON.stringify({"position":str(at),"target":str(target),"fov":cam.fov,"viewport":str(root.size),"standing":name.ends_with("standing")},"  "));f.close()
func finish()->void:
	report.checks=checks;var f=FileAccess.open(out+"museum.json",FileAccess.WRITE);f.store_string(JSON.stringify(report,"  "));f.close();quit(0 if checks.all(func(c):return c.ok) else 1)
