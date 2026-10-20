extends SceneTree
const OUT := "res://doc/book/iterations/2026-10-17-ten-print-dressing/"
const PrintRecord = preload("res://commons/artifacts/ten_print_textile/print_record.gd")
const Cloth = preload("res://commons/artifacts/garment_cutting_table/cloth_record.gd")
const Wardrobe = preload("res://commons/player/costume_wardrobe.gd")
var checks: Array = []
class ProgressStub extends Node:
	signal sequence_completed(sequence: String)
	func is_sequence_completed(_name: String) -> bool:return false
func _initialize() -> void:call_deferred("run")
func check(ok: bool, title: String) -> void:
	checks.append({"passed":ok,"test":title});print("PASS " if ok else "FAIL ",title)
func press(studio: Node, key: String) -> void:
	studio.buttons[key].get_node("InteractableAreaButton").emit_signal("button_pressed",studio.buttons[key])
	await process_frame;await process_frame
func run() -> void:
	create_timer(90).timeout.connect(func():quit(98))
	var a:=PrintRecord.make(41);var b:=PrintRecord.make(42)
	check(PrintRecord.valid(a) and Cloth.valid(a),"Print record accepted by shared cloth/wardrobe contract")
	check(a==PrintRecord.make(41) and a.samples!=b.samples,"Same seed replays; another seed changes draws")
	for field in ["mark","palette","repeat","columns","samples"]:
		var bad:=a.duplicate(true);bad[field]=-1
		check(not PrintRecord.valid(bad),"Invalid "+field+" rejected")
	var bad:=a.duplicate(true);bad.samples[0]=NAN
	check(not PrintRecord.valid(bad),"Nonfinite sample rejected")
	var hashes: Array=[]
	for i in 3:
		var sample:=a.duplicate(true);sample.mark=i
		hashes.append(Cloth.image(sample).get_data().hex_encode().sha256_text())
	check(hashes[0]!=hashes[1] and hashes[1]!=hashes[2],"Same stored draws produce three distinct printed surfaces")
	check(Cloth.save_record(a,OUT+"cloth.json") and Cloth.load_record(OUT+"cloth.json")==a,"Printed cloth round trips through disk")
	var woven:=Cloth.sample("tartan")
	check(Cloth.valid(woven) and Cloth.image(woven).get_width()==576,"Existing Jacquard cloth remains valid and renderable")
	var world:=Node3D.new();root.add_child(world);current_scene=world
	var manager:=ProgressStub.new();world.add_child(manager)
	var desktop:=Camera3D.new();world.add_child(desktop);desktop.position=Vector3(0,1.7,-3);desktop.make_current()
	var dw:=Wardrobe.new();dw.mount_path=world.get_path();dw.head_path=desktop.get_path();dw.manager_path=manager.get_path();dw.appearance_save_path=OUT+"desktop.cfg";world.add_child(dw)
	var origin:=XROrigin3D.new();world.add_child(origin)
	var head:=XRCamera3D.new();head.name="XRCamera3D";origin.add_child(head);head.position=Vector3(3.2,1.7,-.2);head.rotation.y=PI
	var left:=XRController3D.new();left.name="LeftHand";left.tracker=&"left_hand";origin.add_child(left);left.position=Vector3(2.9,1.2,.1)
	var right:=XRController3D.new();right.name="RightHand";right.tracker=&"right_hand";origin.add_child(right);right.position=Vector3(3.5,1.2,.1)
	var custom:Node=load("res://commons/player/PlayerCustomization.gd").new();custom.costume_on_progress=false;origin.add_child(custom)
	await process_frame;await process_frame
	check(custom._activate_costume("costume"),"Production VR customization activates")
	var w:Node=custom._active_features.costume
	w.appearance_save_path=OUT+"vr.cfg";w.manager_path=manager.get_path()
	await process_frame;await process_frame
	w.set_tailored_suit(woven,false,"gown");dw.choose_outfit("",false);head.make_current()
	var studio:Node3D=load("res://commons/artifacts/randomness_space/textile_comparison.tscn").instantiate()
	studio.save_path=OUT+"kept.json";world.add_child(studio)
	await process_frame;await process_frame
	check(studio.specimens.size()==3 and studio.preview.panels.size()==10,"Three draped mesh swatches and ten-panel dress constructed")
	check(studio.wardrobe()==w,"Studio resolves active XR wearer rather than desktop wardrobe")
	var draws:Array=studio.record.samples.duplicate()
	await press(studio,"PIXEL");await press(studio,"PALETTE");await press(studio,"REPEAT")
	check(studio.record.mark==2 and studio.record.palette==1 and studio.record.repeat==2,"Real selection receivers change fabric settings")
	check(draws==studio.record.samples,"Mark, palette and repeat edits retain every stored draw")
	check(studio.preview.record==studio.record,"Fitting uses selected full record")
	await press(studio,"KEEP")
	var kept:Dictionary=studio.record.duplicate(true)
	await press(studio,"SEED +")
	check(studio.record.samples!=draws,"Seed control makes different cloth")
	await press(studio,"REPLAY")
	check(studio.record==kept,"Replay restores saved design, samples and seed")
	for i in 3:
		await press(studio,"WEAR")
		check(w.suit_style==studio.STYLES[i] and w.suit_cloth==studio.record,"WEAR applies exact print on "+studio.STYLES[i])
		check(w.costume.tailored_suit.visible and w.costume.tailored_suit.record==studio.record,"Worn mesh has same print on "+studio.STYLES[i])
		await press(studio,"SHAPE")
	check(dw.costume.outfit_id=="","XR dressing leaves desktop visitor alone")
	var worn:Dictionary=w.suit_cloth.duplicate(true)
	await press(studio,"SEED +")
	check(w.suit_cloth==worn and studio.preview.record!=worn,"Later studio edits cannot repaint the worn snapshot")
	var saved:=ConfigFile.new();var saved_ok:=saved.load(OUT+"vr.cfg")==OK
	check(saved_ok and saved.get_value("appearance","suit_cloth")==worn,"Wardrobe persists complete printed cloth")
	var fresh_mount:=Node3D.new();world.add_child(fresh_mount)
	var fresh_head:=Camera3D.new();fresh_mount.add_child(fresh_head)
	var fresh:=Wardrobe.new();fresh.mount_path=fresh_mount.get_path();fresh.head_path=fresh_head.get_path()
	fresh.manager_path=manager.get_path();fresh.appearance_save_path=OUT+"vr.cfg";fresh_mount.add_child(fresh)
	await process_frame;await process_frame
	check(fresh.suit_cloth==worn and fresh.costume.tailored_suit.record==worn,"Fresh wardrobe reconstructs saved print on actual dress meshes")
	fresh_mount.queue_free();await process_frame
	for i in 90:w.costume._process(1.0/60)
	var before:Transform3D=w.costume.tailored_suit.sleeve_roots[0].transform
	left.position+=Vector3(-.2,.25,.2)
	for i in 30:w.costume._process(1.0/60)
	check(not w.costume.tailored_suit.sleeve_roots[0].transform.is_equal_approx(before),"Tracked hand pose moves the printed sleeve")
	studio.mirror._process(0)
	check(studio.mirror.viewer==head and studio.mirror._wardrobe==w,"Mirror follows active head and wardrobe")
	check(studio.mirror.viewport.world_3d==world.get_world_3d(),"Mirror renders actual world, not a mannequin substitute")
	check(studio.mirror.viewport.render_target_update_mode!=SubViewport.UPDATE_DISABLED,"Mirror active inside dressing alcove")
	check((studio.mirror.reflection.cull_mask&w.costume.tailored_suit.panels[6].layers)!=0,"Reflection includes worn dress geometry")
	await press(studio,"TAKE OFF")
	check(w.suit_style=="gown" and w.suit_cloth==woven,"TAKE OFF restores previous dress and original woven cloth")
	check(w.worn().is_empty(),"Clothing choices grant no curriculum progress")
	var structure:Node3D=load("res://commons/artifacts/ten_print_structure/ten_print_structure.tscn").instantiate()
	world.add_child(structure)
	check(structure.slab_height()<=.045 and structure.slab_thickness()>=.08,"Floor print uses low broad mesh strokes")
	check(structure.get_node("CellBeds").multimesh.instance_count==400,"Each large-print address has its own visible cell bed")
	var cell_count:int=structure.get_cells().size()
	check(cell_count==400,"Readability changes preserve all printed choices")
	var field:Node3D=load("res://algorithms/randomness/generative/tenprintantmaze/ten_print_maze_3d.tscn").instantiate()
	field.impression="character";field.animate=false;field.maze_seed=41;world.add_child(field);field.set_process(false)
	var bits:Array=field.maze.duplicate(true);var nav:Array=field.nav_grid.duplicate(true)
	check(field.character_frames.multimesh.instance_count==400,"Character frames are one 400-instance draw batch")
	check(field.wall_nodes[0].get_child(0).mesh==field.wall_nodes[99].get_child(0).mesh,"All 100 glyphs share one mesh resource")
	field.apply_grid_config({"impression":"stroke"})
	check(field.maze==bits and field.nav_grid==nav and not is_instance_valid(field.character_frames),"Switching to legacy strokes preserves bits and navigation; removes frames")
	field.apply_grid_config({"impression":"character"})
	check(field.maze==bits and field.nav_grid==nav and field.character_frames.multimesh.instance_count==400,"Switching back rebuilds visible cells without rerolling")
	var passed:=true
	for c in checks:passed=passed and c.passed
	var f:=FileAccess.open(OUT+"tests.json",FileAccess.WRITE);f.store_string(JSON.stringify({"passed":passed,"checks":checks},"\t"));f.close()
	quit(0 if passed else 1)
