extends SceneTree
const OUT="res://doc/book/iterations/2026-10-10-player-costume-gallery/"
var checks: Array=[]
class ProgressStub extends Node:
	signal sequence_completed(sequence:String)
	func is_sequence_completed(_name:String)->bool:return false
func _initialize() -> void:call_deferred("run")
func check(ok: bool, title: String) -> void:
	checks.append({"passed":ok,"test":title});print("PASS " if ok else "FAIL ",title)
func photo(camera: Camera3D, title: String) -> void:
	for i in range(6):camera.make_current();await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+title+".png")
func run() -> void:
	root.size=Vector2i(1800,1200);root.msaa_3d=Viewport.MSAA_4X
	create_timer(150).timeout.connect(func():quit(98))
	var folder:="res://ada_run/player_costume_gallery/"
	var museum:Node3D=load(folder+"museum_snapshot.tscn").instantiate()
	museum.set("EM_CONTROL",folder+"control.json");museum.set("_hand_path",folder+"necklace_hand.json");museum.set("_overrides_path",folder+"em_overrides.json")
	museum.set("start_chapter","tiling");museum.set("start_map","Ribbon_Patterns_03");museum.set("plan_file",folder+"plan.json")
	root.add_child(museum);current_scene=museum
	var start:=Time.get_ticks_msec()
	while not bool(museum.get("_museum_core_ready")) and Time.get_ticks_msec()-start<65000:await process_frame
	museum.set("_lazy_pending",0);museum.set_process(false);museum.set_physics_process(false);museum.call("flush_stamps")
	await create_timer(1).timeout
	var walker:Camera3D=museum.get("_cam")
	if walker:
		for c in walker.get_children():
			if c is Timer:c.stop()
	var hall:Node3D
	for c in museum.get_children():
		if c is Node3D and str(c.get_meta("em_map",""))=="Ribbon_Patterns_03":hall=c
	check(hall!=null,"Actual final Tiling hall loads")
	var table:Node3D
	if hall:
		var deadline:=Time.get_ticks_msec()+20000
		while table==null and Time.get_ticks_msec()<deadline:
			for n in hall.find_children("*","Node3D",true,false):
				if n.scene_file_path=="res://commons/artifacts/garment_cutting_table/garment_cutting_table.tscn":table=n
			await process_frame
	check(table!=null,"Registered cutting table is installed in the live hall layout")
	if not table:quit(1);return
	# The existing museum stays loaded. Pose a real XR rig beside its wardrobe.
	var origin:=XROrigin3D.new();origin.name="CostumeReviewXR";root.add_child(origin)
	origin.global_transform=table.global_transform*Transform3D(Basis(Vector3.UP,PI),Vector3(.9,0,2.4))
	var head:=XRCamera3D.new();head.name="XRCamera3D";origin.add_child(head);head.position=Vector3(0,1.72,0)
	var left:=XRController3D.new();left.name="LeftHand";left.tracker=&"left_hand";origin.add_child(left);left.position=Vector3(-.40,1.10,-.12)
	var right:=XRController3D.new();right.name="RightHand";right.tracker=&"right_hand";origin.add_child(right);right.position=Vector3(.40,1.10,-.12)
	for pair in [[left,"left"],[right,"right"]]:
		var hand:Node3D=load("res://commons/body/hands/"+pair[1]+"_hand.tscn").instantiate()
		# Match base.tscn's root-script and hand-pose overrides.
		hand.set_script(load("res://addons/godot-xr-tools/hands/hand.gd"))
		hand.hand_blend_tree=load("res://addons/godot-xr-tools/hands/animations/"+pair[1]+"/hand_blend_tree.tres")
		hand.default_pose=load("res://addons/godot-xr-tools/hands/poses/pose_default_"+pair[1]+".tres")
		hand.hand_offset_mode=0
		pair[0].add_child(hand)
	# Use the production feature owner; keep its persistence in this report.
	var manager:=ProgressStub.new();root.add_child(manager)
	var custom:Node=load("res://commons/player/PlayerCustomization.gd").new();custom.costume_on_progress=false;origin.add_child(custom)
	await process_frame;await process_frame
	check(custom._activate_costume("costume"),"PlayerCustomization creates the XR wardrobe")
	var w:Node=custom._active_features.costume;w.appearance_save_path=OUT+"review-appearance.cfg";w.manager_path=manager.get_path()
	check(custom._activate_body_ik("body_arms"),"Production IK arms join the two controller hands")
	await process_frame;await process_frame
	check(w.wears_head(head) and w.costume._hand_l==left and w.costume._hand_r==right,"Costumes attach to this XR camera and both controllers")
	w.skirt_fabric={};w.choose_outfit("",false)
	if museum.get("_wardrobe") and museum.get("_wardrobe").costume:museum.get("_wardrobe").costume.visible=false
	var camera:=Camera3D.new();root.add_child(camera);camera.fov=39
	var Cloth=load("res://commons/artifacts/garment_cutting_table/cloth_record.gd")
	var looks:=["suit","aline","gown","pleated","latex_cathedral","chrome_orchid","holo_fan","pearl_rococo"]
	for key in looks:
		head.rotation=Vector3.ZERO;head.make_current()
		if key in ["suit","aline","gown","pleated"]:
			check(w.set_tailored_suit(Cloth.sample("houndstooth"),false,key),"Wear "+key+" on the VR player")
		else:check(w.choose_outfit(key,false),"Wear "+key+" on the VR player")
		for i in range(20):await process_frame
		# Same framing, pose, light and progression for every full-body photograph.
		camera.global_position=table.to_global(Vector3(1.8,1.3,6.1))
		camera.look_at(origin.global_position+Vector3(0,1.12,0));camera.fov=39
		await photo(camera,key+"-front")
		camera.global_position=table.to_global(Vector3(4.2,1.3,4.1))
		camera.look_at(origin.global_position+Vector3(0,1.12,0));camera.fov=39
		await photo(camera,key+"-side")
		# XRCamera renders a flat observer image with OpenXR disabled; pose is supplied.
		head.rotation_degrees.x=-65;head.fov=85
		await photo(head,key+"-down")
	check(w.worn().is_empty(),"Gallery does not grant curriculum progress")
	var passed:=true
	for c in checks:passed=passed and c.passed
	var f:=FileAccess.open(OUT+"checks.json",FileAccess.WRITE);f.store_string(JSON.stringify({"passed":passed,"checks":checks,"pose":"simulated XR nodes, no physical headset"},"\t"));f.close();quit(0 if passed else 1)
