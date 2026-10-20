extends SceneTree
## Real XR node types and production wardrobe; deterministic poses, no headset.
const OUT="res://doc/book/iterations/2026-10-10-dresses-on-the-vr-player/"
const Cloth=preload("res://commons/artifacts/garment_cutting_table/cloth_record.gd")
const Wardrobe=preload("res://commons/player/costume_wardrobe.gd")
var checks:Array=[]
class ProgressStub extends Node:
	signal sequence_completed(sequence:String)
	func is_sequence_completed(_name:String)->bool:return false
func _initialize()->void:call_deferred("run")
func check(ok:bool,title:String)->void:
	checks.append({"passed":ok,"test":title});print("PASS " if ok else "FAIL ",title)
func press(table:Node,key:String)->void:
	table.buttons[key].get_node("InteractableAreaButton").emit_signal("button_pressed",table.buttons[key])
func run()->void:
	create_timer(60).timeout.connect(func():quit(98))
	var world:=Node3D.new();root.add_child(world);current_scene=world
	var manager:=ProgressStub.new();world.add_child(manager)
	var desktop:=Camera3D.new();world.add_child(desktop);desktop.position=Vector3(0,1.7,2);desktop.make_current()
	var dw:=Wardrobe.new();dw.mount_path=world.get_path();dw.head_path=desktop.get_path();dw.manager_path=manager.get_path();dw.appearance_save_path=OUT+"desktop.cfg";world.add_child(dw)
	var Mirror=load("res://commons/artifacts/super_drag_mirror/super_drag_mirror.gd")
	var mirror:Node3D=Mirror.new();world.add_child(mirror)
	await process_frame;await process_frame;await process_frame
	dw.choose_outfit("",false)
	mirror._process(0)
	check(mirror.viewer==desktop,"Mirror initially follows desktop visitor")
	var origin:=XROrigin3D.new();origin.name="XROrigin3D";world.add_child(origin)
	var head:=XRCamera3D.new();head.name="XRCamera3D";origin.add_child(head);head.position=Vector3(0,1.7,2)
	var left:=XRController3D.new();left.name="LeftHand";left.tracker=&"left_hand";origin.add_child(left);left.position=Vector3(-.32,1.25,1.65)
	var right:=XRController3D.new();right.name="RightHand";right.tracker=&"right_hand";origin.add_child(right);right.position=Vector3(.32,1.25,1.65)
	var Customization=load("res://commons/player/PlayerCustomization.gd")
	var custom:Node=Customization.new();custom.costume_on_progress=false;origin.add_child(custom)
	await process_frame;await process_frame
	check(custom._activate_costume("costume"),"Production PlayerCustomization mounts a wardrobe on the VR rig")
	var w:Node=custom._active_features.costume
	# The production _start is deferred; route its save before it runs.
	w.appearance_save_path=OUT+"vr-appearance.cfg";w.manager_path=manager.get_path()
	await process_frame;await process_frame
	w.choose_outfit("",false);head.make_current()
	check(w.wears_head(head) and w.costume._hand_l==left and w.costume._hand_r==right,"Wardrobe binds the actual XRCamera3D and both XRController3D nodes")
	var Table=load("res://commons/artifacts/garment_cutting_table/garment_cutting_table.gd")
	var table:Node3D=Table.new();table.cloth_path=OUT+"unused-cloth.json";world.add_child(table);table.set_process(false)
	table.set_record(Cloth.sample("optical"))
	check(table.wardrobe()==w,"WEAR resolves the active VR player even with a desktop wardrobe present")
	for key in ["A-LINE","GOWN","PLEATED"]:
		press(table,key);press(table,"CUT");table.advance(20);press(table,"ASSEMBLE");table.advance(20);press(table,"WEAR")
		check(w.costume.outfit_id=="tailored_suit" and w.suit_style==table.style and w.costume.tailored_suit.visible,key+" button wears the garment on the VR player")
		check(dw.costume.outfit_id=="","VR dressing leaves the desktop visitor unchanged: "+key)
	var costume:Node3D=w.costume;costume.set_process(false)
	for i in range(60):costume._process(1.0/60)
	check(costume.tailored_suit.global_position.distance_to(head.global_position+Vector3(0,-.15,0))<.002,"Dress follows the headset position below the neck")
	check((costume.tailored_suit.panels[6].layers & head.cull_mask)!=0,"Dress is visible to the headset camera when looking down")
	var before:Transform3D=costume.tailored_suit.sleeve_roots[0].transform
	left.position+=Vector3(-.25,.25,-.25)
	for i in range(60):costume._process(1.0/60)
	check(not costume.tailored_suit.sleeve_roots[0].transform.is_equal_approx(before),"A moving XR controller moves the worn sleeve")
	left.position=Vector3(-.32,1.25,1.65)
	for yaw in [PI*.5,-PI*.5,PI]:
		origin.rotation.y=yaw
		for i in range(150):costume._process(1.0/60)
		var forward:Vector3=-costume._torso.global_basis.z.normalized()
		var expected:Vector3=-head.global_basis.z.normalized()
		check(forward.dot(expected)>.999,"Garment faces with the VR rig after yaw "+str(snappedf(rad_to_deg(yaw),1)))
	origin.rotation.y=0;origin.position=Vector3(0,0,.2)
	for i in range(150):costume._process(1.0/60)
	mirror._process(0)
	check(mirror.viewer==head and mirror._wardrobe==w,"Mirror switches to the headset and its wardrobe")
	check(mirror.viewport.world_3d==world.get_world_3d() and (mirror.reflection.cull_mask & costume.tailored_suit.panels[6].layers)!=0,"Mirror sees the actual worn dress in the shared world")
	check(mirror.readout.text.contains("PLEATED"),"Mirror names the tailored dress worn by the VR player")
	press(table,"TAKE OFF")
	check(w.costume.outfit_id=="" and not costume.tailored_suit.visible,"TAKE OFF restores the VR player's previous outfit")
	check(w.worn().is_empty(),"VR outfit choices do not grant curriculum progress")
	var passed:=true
	for c in checks:passed=passed and c.passed
	var f:=FileAccess.open(OUT+"tests.json",FileAccess.WRITE);f.store_string(JSON.stringify({"passed":passed,"checks":checks},"\t"));f.close()
	quit(0 if passed else 1)
