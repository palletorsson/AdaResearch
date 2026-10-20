extends SceneTree
const Cloth=preload("res://commons/artifacts/garment_cutting_table/cloth_record.gd")
const Panels=preload("res://commons/artifacts/garment_cutting_table/suit_panels.gd")
const Wardrobe=preload("res://commons/player/costume_wardrobe.gd")
const OUT="res://doc/book/iterations/2026-10-10-dresses-from-the-loom/"
var checks: Array=[]
class ProgressStub extends Node:
	signal sequence_completed(sequence: String)
	func is_sequence_completed(_s: String) -> bool:return false

func _initialize() -> void:call_deferred("run")
func check(ok: bool, title: String) -> void:
	checks.append({"passed":ok,"test":title});print("PASS " if ok else "FAIL ",title)
func press(table: Node, key: String) -> void:table.buttons[key].get_node("InteractableAreaButton").emit_signal("button_pressed",table.buttons[key])
func run() -> void:
	var Table=load("res://commons/artifacts/garment_cutting_table/garment_cutting_table.gd")
	var Studio=load("res://commons/artifacts/jacquard_weaver/jacquard_studio.gd")
	create_timer(70).timeout.connect(func():quit(98))
	var world:=Node3D.new();root.add_child(world);current_scene=world
	var cam:=Camera3D.new();world.add_child(cam);cam.position=Vector3(0,1.7,3);cam.make_current()
	var manager:=ProgressStub.new();world.add_child(manager)
	var w:=Wardrobe.new();w.mount_path=world.get_path();w.head_path=cam.get_path();w.manager_path=manager.get_path();w.appearance_save_path=OUT+"test-appearance.cfg";world.add_child(w)
	var table:Node3D=Table.new();table.cloth_path=OUT+"test-cloth.json";world.add_child(table);table.set_process(false)
	await process_frame;await process_frame
	w.choose_outfit("",false)
	var studio:Node3D=Studio.new();studio.cloth_save_path=table.cloth_path;world.add_child(studio);studio.loom.set_process(false)
	studio.loom.select_sample("optical");studio.loom.program.history[3].bits[0]=1-int(studio.loom.program.history[3].bits[0])
	check(studio.save_cloth(),"Loom saves committed optical cloth with an individual edited crossing")
	press(table,"LOAD LOOM")
	check(table.record.picks==studio.loom.program.history,"Cutting table loads the actual edited loom record")
	check(table.panels.size()==10 and table.phase=="layout","Ten named flat suit panels start on the table")
	check(not table.wear(),"Cannot wear an unfinished layout")
	press(table,"ASSEMBLE");check(table.phase=="layout","Cannot assemble before cutting")
	var record:Dictionary=table.record.duplicate(true)
	press(table,"CUT");table.advance(3)
	check(table.phase=="cutting" and table.completed==1,"CUT advances through individual pieces")
	var prior:float=table.elapsed;press(table,"PAUSE");table.advance(8)
	check(table.elapsed==prior,"PAUSE freezes the cutting operation")
	press(table,"PAUSE");table.advance(30)
	check(table.phase=="cut" and not table.bolt.visible,"Cutting completes and removes the unused cloth from the layout")
	press(table,"ASSEMBLE");table.advance(3)
	check(table.completed==1 and table.phase=="assembling" and table.panels[0].position==table.FIT,"Robot places completed panels while the next travels")
	check(table.panels[1].position!=Panels.table_position(1),"Second panel leaves its actual table position")
	press(table,"RESET");check(table.phase=="layout" and table.panels[0].position==Panels.table_position(0),"RESET during assembly returns every piece to the layout")
	press(table,"CUT");table.advance(20);press(table,"ASSEMBLE");table.advance(20)
	check(table.phase=="ready" and table.suit.visible and table.record==record,"Fitted suit retains all original crossing and yarn data")
	for i in range(10):
		var flat:=Panels.mesh(i,0).surface_get_arrays(0);var fit:=Panels.mesh(i,1).surface_get_arrays(0)
		check(flat[Mesh.ARRAY_TEX_UV]==fit[Mesh.ARRAY_TEX_UV],"Panel %d retains its cut cloth addresses during folding"%(i+1))
	check(table.wear() and w.costume.outfit_id=="tailored_suit","WEAR equips the current player's real wardrobe")
	check(w.costume.tailored_suit.visible and w.suit_cloth==record,"Player wears the same ten-panel suit and cloth snapshot")
	var image:=Cloth.image(record)
	check(image.get_width()==576 and image.get_height()==576,"Cloth appearance preserves the 96 by 96 recorded crossing layout")
	var hand:=Node3D.new();world.add_child(hand);hand.position=Vector3(-.6,1.5,2.5)
	w.costume.tailored_suit.follow(hand,null)
	check(w.costume.tailored_suit.sleeve_roots[0].transform!=Transform3D.IDENTITY,"Worn sleeve follows a moving hand")
	var save:=ConfigFile.new();check(save.load(w.appearance_save_path)==OK and save.get_value("appearance","suit_cloth")==record,"Saved outfit includes the complete cloth snapshot")
	var w2:=Wardrobe.new();w2.mount_path=world.get_path();w2.head_path=cam.get_path();w2.manager_path=manager.get_path();w2.appearance_save_path=w.appearance_save_path;world.add_child(w2)
	await process_frame;await process_frame
	check(w2.costume.outfit_id=="tailored_suit" and w2.suit_cloth==record,"Fresh wardrobe restores the suit and its cloth")
	w2.free()
	press(table,"CLOTH");check(w.suit_cloth==record,"Changing the table sample does not mutate the already worn suit")
	press(table,"TAKE OFF");check(w.costume.outfit_id=="" and not w.costume.tailored_suit.visible,"TAKE OFF restores the prior outfit")
	check(w.choose_outfit("chrome_orchid",false) and w.costume.drag_outfit.visible and not w.costume.tailored_suit.visible,"Existing wardrobe outfits still work after the suit")
	var bad:=record.duplicate(true);bad.picks[0].bits[0]=2
	check(not Cloth.valid(bad) and not w.set_tailored_suit(bad,false),"Invalid weave is rejected without changing the wardrobe")
	check(w.worn().is_empty(),"Making or wearing a suit grants no curriculum completion")

	table.set_record(record)

	# Use the real button signals, then wear and restore every supported dress.
	var hems:Array=[]
	for style in ["aline","gown","pleated"]:
		press(table,Panels.title(style))
		check(table.style==style and table.suit.style==style and table.suit.visible,"Shape button previews "+style)
		check(table.record.picks==record.picks,"Choosing "+style+" retains the loom record")
		check(table.panel_labels[6].text.contains("SKIRT"),style+" labels the new skirt pieces")
		check(w.costume.outfit_id=="chrome_orchid","Previewing "+style+" leaves the worn outfit alone")
		check(not table.wear(),style+" preview cannot be worn before assembly")
		var valid_uvs:=true
		for i in range(10):
			var a:=Panels.mesh(i,0,style).surface_get_arrays(0)
			var b:=Panels.mesh(i,1,style).surface_get_arrays(0)
			valid_uvs=valid_uvs and a[Mesh.ARRAY_TEX_UV]==b[Mesh.ARRAY_TEX_UV]
			for uv in a[Mesh.ARRAY_TEX_UV]:valid_uvs=valid_uvs and uv.x>=0 and uv.x<=1 and uv.y>=0 and uv.y<=1
		check(valid_uvs,style+" retains ten panel addresses inside the saved cloth")
		press(table,"CUT");table.advance(20);press(table,"ASSEMBLE");table.advance(20)
		check(table.wear() and w.suit_style==style and w.costume.tailored_suit.style==style,style+" is worn on the actual avatar")
		check(w.suit_cloth==record and w.costume.tailored_suit.record==record,style+" wears the original edited weave")
		var reload:=Wardrobe.new();reload.mount_path=world.get_path();reload.head_path=cam.get_path();reload.manager_path=manager.get_path();reload.appearance_save_path=w.appearance_save_path;world.add_child(reload)
		await process_frame;await process_frame
		check(reload.suit_style==style and reload.costume.tailored_suit.style==style and reload.suit_cloth==record,style+" and its cloth survive a fresh wardrobe")
		reload.free()
		hems.append(Panels.curved_point(6,.5,1,style).y)
		press(table,"TAKE OFF")
	check(hems[0]!=hems[1] and hems[1]!=hems[2] and hems[0]!=hems[2],"All three dresses have distinct hem lengths")
	var gown_r:=Panels.curved_point(6,.25,1,"gown")
	var pleat_r:=Panels.curved_point(6,.25,1,"pleated")
	check(not gown_r.is_equal_approx(pleat_r),"Pleats change the skirt geometry, not just its texture")
	# A visitor who already wears a different dress must get that full look back.
	w.set_tailored_suit(Cloth.sample("tartan"),true,"gown")
	table.set_record(record);table.select_style("aline")
	press(table,"CUT");table.advance(20);press(table,"ASSEMBLE");table.advance(20);table.wear()
	press(table,"PLEATED")
	check(w.suit_style=="aline" and w.suit_cloth==record,"Later shape edits do not mutate the worn dress")
	press(table,"TAKE OFF")
	check(w.suit_style=="gown" and w.costume.tailored_suit.style=="gown" and w.suit_cloth==Cloth.sample("tartan"),"TAKE OFF restores both the previous dress and its original cloth")
	check(not table.select_style("unknown") and not w.set_tailored_suit(record,false,"unknown"),"Unknown shapes cannot change the table or wardrobe")
	# Existing saves without a shape key keep the original suit.
	var legacy:=ConfigFile.new();legacy.set_value("appearance","outfit","tailored_suit");legacy.set_value("appearance","suit_cloth",record);legacy.save(OUT+"legacy.cfg")
	var old_w:=Wardrobe.new();old_w.mount_path=world.get_path();old_w.head_path=cam.get_path();old_w.manager_path=manager.get_path();old_w.appearance_save_path=OUT+"legacy.cfg";world.add_child(old_w)
	await process_frame;await process_frame
	check(old_w.suit_style=="suit" and old_w.costume.tailored_suit.style=="suit","Old saved suits load as suits")
	old_w.free()
	var passed:=true
	for c in checks:passed=passed and c.passed
	var f:=FileAccess.open(OUT+"tests.json",FileAccess.WRITE);f.store_string(JSON.stringify({"passed":passed,"checks":checks},"\t"));f.close()
	quit(0 if passed else 1)
