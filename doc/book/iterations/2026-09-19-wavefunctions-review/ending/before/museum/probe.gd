extends SceneTree
var out:=""
var current:=false
var checks:Array=[]
var report:Dictionary={}
var frozen:GDScript
const HALL="WaveFunctions_Synthesis_Lab"
func _initialize()->void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out=arg.trim_prefix("--out=")
	current="--current" in OS.get_cmdline_user_args();run.call_deferred()
func check(ok:bool,message:String)->void:
	checks.append({"ok":ok,"message":message});print("ENDING-MUSEUM ","PASS " if ok else "FAIL ",message)
func press(demo:Node,index:int,cam:Camera3D)->void:
	var area=demo._panel.find_child("Btn_"+str(index),true,false).get_node("InteractableAreaButton")
	XRToolsPointerEvent.pressed(cam,area,area.global_position);XRToolsPointerEvent.released(cam,area,area.global_position)
	demo._process(0)
func run()->void:
	frozen=GDScript.new();frozen.source_code=FileAccess.get_file_as_string("res://doc/book/iterations/2026-09-19-wavefunctions-review/ending/frozen-museum.gd")
	check(frozen.reload()==OK,"frozen current loader compiles");frozen.take_over_path("res://commons/scenes/endless_museum.gd")
	var em=load("res://commons/scenes/endless_museum.tscn").instantiate()
	var ctl=out+"control.json";var f=FileAccess.open(ctl,FileAccess.WRITE);f.store_string(JSON.stringify({"first_chapter":"wavefunctions","dollhouse":0,"grid_pack":1}));f.close()
	em.set("EM_CONTROL",ctl);em.set("_overrides_path",ctl+".unused");em.set("_hand_path",ctl+".unused");em.set("start_chapter","wavefunctions");em.set("start_map",HALL)
	root.add_child(em);current_scene=em;await create_timer(2).timeout
	em.set_process(false);em.set_physics_process(false);em.flush_stamps()
	for timer in em.get("_cam").get_children():
		if timer is Timer:timer.stop()
	var player=em.get("_player");player.set_process(false);player.set_physics_process(false);em.get("_feel").set_process(false)
	em.get("_wardrobe").appearance_save_path="";em.get("_wardrobe").costume.visible=false
	var seg:Node3D
	for rec in em.get("_segments"):
		if rec.node.get_meta("em_map","")==HALL:seg=rec.node;break
	check(seg!=null,"actual Synthesis museum hall loads")
	check(em.get_script()==frozen,"actual museum uses frozen loader")
	if not seg:finish();return
	for rec in em.get("_vis_records"):
		var n=rec.get("node")
		if n is Node3D and is_instance_valid(n) and seg.is_ancestor_of(n):n.visible=true
	var demo:Node3D;var inventory:Array=[]
	for rec in em.get("_edit_records"):
		var n=rec.get("node")
		if n is Node3D and is_instance_valid(n) and seg.is_ancestor_of(n):
			inventory.append({"key":str(n.get_meta("artifact_lookup_name","")),"cell":rec.get("tile_cell",[]),"position":str(n.global_position),"scale":str(n.global_basis.get_scale())})
			if n.get_script()!=null and str(n.get_script().resource_path).ends_with("additive_wave_demo.gd"):demo=n
	check(demo!=null,"authored additive bench instantiates")
	if not demo:finish();return
	demo.set_process(false);demo._time=.125;demo._process(0)
	check(demo.stand=="bench" and demo.waveform=="sawtooth","actual authored token reaches bench and arrival recipe")
	check(demo.global_basis.get_scale().is_equal_approx(Vector3.ONE),"museum bench retains unit scale")
	check(demo.harmonic_sliders.size()==5 and demo.find_children("Readout","Label3D",true,false).size()==1,"five wired sliders and exactly one readout")
	var cam=Camera3D.new();em.add_child(cam);cam.fov=65
	press(demo,2,cam);check(demo.held,"desktop pointer HOLD freezes comparison")
	var arrival=demo.get_synthesis_state()
	check(arrival.preset==("ARRIVAL RECIPE" if current else "≈ Sawtooth Wave (all harmonics)"),"arrival recipe naming policy verified in museum")
	check(arrival.amplitudes==[1.0,.5,.333,.25,.2],"all five arrival coefficients remain unchanged")
	var eye=demo.to_global(Vector3(0,0,2.6));eye.y=1.7
	var target=demo.to_global(Vector3(0,1.45,.12))
	var query=PhysicsShapeQueryParameters3D.new();var capsule=CapsuleShape3D.new();capsule.radius=.22;capsule.height=1.6;query.shape=capsule;query.collision_mask=1;query.collide_with_areas=false;query.exclude=[player.get_rid()];query.transform.origin=Vector3(eye.x,1.05,eye.z)
	await physics_frame
	var hits=seg.get_world_3d().direct_space_state.intersect_shape(query,8)
	check(hits.is_empty(),"standing capture position admits capsule")
	var hit_names:Array=[]
	for hit in hits:hit_names.append(str(hit.collider.get_path()))
	report={"hall":HALL,"inventory":inventory,"arrival":arrival,"scale":str(demo.global_basis.get_scale()),"position":str(demo.global_position),"standing_hits":hit_names,"loaded_museum_sha256":frozen.source_code.sha256_text(),"headset_tested":false}
	await capture(cam,"arrival",eye,target)
	press(demo,1,cam)
	check(demo.harmonic_amplitudes==[1.0,0.0,0.0,0.0,0.0] and demo.preset_label.text=="Pure Sine Wave","desktop pointer H1 ALONE changes coefficients and reveals recognition")
	report.first_alone=demo.get_synthesis_state();await capture(cam,"first-alone",eye,target)
	press(demo,0,cam)
	check(demo.harmonic_amplitudes==[1.0,.5,.333,.25,.2] and demo.preset_label.text.contains("Sawtooth"),"desktop pointer BASELINE restores named finite recipe")
	report.restored=demo.get_synthesis_state();await capture(cam,"restored",eye,target)
	finish()
func capture(cam:Camera3D,name:String,at:Vector3,target:Vector3)->void:
	cam.global_position=at;cam.look_at(target);cam.make_current()
	for i in 10:await process_frame
	check(root.get_camera_3d()==cam,"capture camera active before draw: "+name)
	await RenderingServer.frame_post_draw
	check(root.get_camera_3d()==cam,"capture camera active after draw: "+name)
	root.get_texture().get_image().save_png(out+name+".png")
	var f=FileAccess.open(out+name+"-camera.json",FileAccess.WRITE);f.store_string(JSON.stringify({"position":str(at),"target":str(target),"fov":cam.fov,"viewport":str(root.size)},"  "));f.close()
func finish()->void:
	report.checks=checks;var f=FileAccess.open(out+"museum.json",FileAccess.WRITE);f.store_string(JSON.stringify(report,"  "));f.close()
	print("ENDING MUSEUM COMPLETE ",checks.size());quit(0 if checks.all(func(x):return x.ok) else 1)
