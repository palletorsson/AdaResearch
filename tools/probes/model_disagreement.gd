extends SceneTree
const OUT:="res://ada_run/model_disagreement/"
var work:Node3D
var camera:Camera3D
var checks:Array=[]
var captures:Array=[]
func _initialize() -> void:run.call_deferred()
func check(label:String,ok:bool) -> void:
	checks.append({"name":label,"passed":ok});print("[disagreement] ","PASS " if ok else "FAIL ",label)
func tick() -> void:
	await physics_frame;await process_frame
func capture(id:String,eye:Vector3=Vector3.ZERO,target:Vector3=Vector3.ZERO) -> void:
	var box:AABB=work.rendered[0].global_transform*work.rendered[0].get_aabb()
	var centre:=box.get_center();var extent:=maxf(12,maxf(box.size.x,maxf(box.size.y,box.size.z)))
	camera.projection=Camera3D.PROJECTION_PERSPECTIVE;camera.fov=55
	camera.position=centre+Vector3(-extent*.8,extent*.55,extent*1.35) if eye==Vector3.ZERO else eye
	camera.look_at(centre if target==Vector3.ZERO else target);camera.current=true
	await create_timer(.25).timeout;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT+id+".png"))
	captures.append({"id":id,"mode":work.mode,"steps":work.steps,"amount":work.amount,"control":work.control,"status":work.status,"bound_size":str(box.size)})
	if id in ["source","precision","precision-control","clocks","clocks-control","feedback","feedback-control"]:
		var node:=Node3D.new();node.name="ModelDisagreement";node.transform=work.body.transform
		for item in work.rendered:node.add_child(item.duplicate())
		var doc:=GLTFDocument.new();var state:=GLTFState.new()
		var a:=doc.append_from_scene(node,state);var b:=doc.write_to_filesystem(state,OUT+id+".glb") if a==OK else FAILED
		check("native GLB "+id,a==OK and b==OK);node.free()
func finite_model() -> bool:
	for group in work.output:
		for p in group:
			if not p.is_finite():return false
	return true
func max_radius() -> float:
	var m:=0.0
	for group in work.output:
		for p in group:m=maxf(m,p.length())
	return m
func seam_gap() -> float:
	var gap:=0.0
	for i in range(1,8):
		var p:=Vector3((i-4)*1.2,2.6,0)
		gap=maxf(gap,(work.pose_at(work.samples[i])*p).distance_to(work.pose_at(work.samples[i-1])*p))
	return gap
func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var room=load("res://commons/artifacts/model_disagreement/preview.tscn").instantiate();root.add_child(room);current_scene=room
	await tick();work=room.work;work.set_process(false);camera=Camera3D.new();root.add_child(camera)
	var original:Array=work.original.duplicate(true);var reference=work.reference.get_child(0).mesh
	work.select_mode(0);check("source output matches retained record",work.output==original)
	var faces:=0
	for group in original:faces+=group.size()/3
	check("source contains triangles for eight bays",faces>1000 and work.original.size()>=3)
	await capture("source")
	check("float32 loses quarter metre at 2^24",is_zero_approx(work.remote_coordinate(.25,16777216.0)))
	check("float32 keeps two metres at 2^24",is_equal_approx(work.remote_coordinate(2.0,16777216.0),2.0))
	check("near-origin quarter metre survives",is_equal_approx(work.remote_coordinate(.25,0),.25))
	work.select_mode(1)
	check("precision uses declared large origin",is_equal_approx(work.distance_origin,8388608.0))
	check("quantization causes measured position error and collapsed faces",work.error_max>.1 and work.collapsed>0)
	var remote:Array=work.output.duplicate(true);await capture("precision",Vector3(-13,7,14),Vector3(0,1,-3))
	work.toggle_control();check("local reference avoids remote roundtrip",is_zero_approx(work.error_max) and work.output!=remote)
	await capture("precision-control",Vector3(-13,7,14),Vector3(0,1,-3))
	work.toggle_control();check("precision comparison is repeatable",work.output==remote)
	work.set_amount(0);check("zero origin preserves local model",work.error_max<.00001)
	work.set_amount(1);work.set_steps(32);check("extreme precision intervention stays finite",finite_model())
	work.select_mode(2)
	check("clock age spread equals declared 3.4 seconds",is_equal_approx(work.samples[0]-work.samples[-1],3.4))
	check("newest bay reads current logical time",is_equal_approx(work.samples[0],work.steps*.2))
	check("different timestamps separate a shared seam",seam_gap()>.1)
	await capture("clocks",Vector3(-14,8,15),Vector3(0,2,-3));await capture("clocks-ground",Vector3(-11,1.75,11),Vector3(0,3,-3))
	work.toggle_control();check("single shared time restores matching seams",seam_gap()<.00001)
	check("control preserves all eight timestamps equally",is_equal_approx(work.samples[0],work.samples[-1]))
	await capture("clocks-control",Vector3(-14,8,15),Vector3(0,2,-3))
	work.toggle_control();work.set_amount(0);check("zero skew also restores matching seams",seam_gap()<.00001)
	work.select_mode(3);check("feedback executes twenty-four passes",work.executed_passes==24 and not work.limited)
	var grown:Array=work.output.duplicate(true)
	check("feedback changes vertices substantially",max_radius()>10)
	var ground_ok:=true
	for s in original.size():
		for i in original[s].size():
			if original[s][i].y<=0:ground_ok=ground_ok and original[s][i]==work.output[s][i]
	check("feedback retains floor contact vertices",ground_ok)
	await capture("feedback",Vector3(-20,14,25),Vector3(6,5,-3));await capture("feedback-ground",Vector3(-12,1.75,14),Vector3(9,6,-3))
	work.toggle_control();check("control reads source rather than previous output",work.executed_passes==1 and work.output!=grown)
	var one_pass:Array=work.output.duplicate(true)
	work.set_steps(32);check("source-reading control does not accumulate",work.output==one_pass)
	await capture("feedback-control",Vector3(-20,14,25),Vector3(6,5,-3))
	work.toggle_control();work.set_amount(1)
	check("feedback limit retains a complete bounded pass",work.limited and work.executed_passes<32 and max_radius()<64)
	check("bounded feedback remains finite",finite_model())
	work.reset();check("feedback reset restores source",work.output==original and work.steps==0)
	work.set_amount(0);work.set_steps(32);check("zero deformation stays unchanged over many passes",work.output==original)
	work.select_mode(3);work.reset();work.toggle_play();work._process(.21)
	check("play advances logical step",work.steps==1)
	work.toggle_play();work._process(1);check("hold stops stepping",work.steps==1)
	work.panel.strength_dial.set_normalized_value(.4);work.panel.step_dial.set_normalized_value(.5);work.read_controls(0)
	check("native dials select condition and sixteen steps",is_equal_approx(work.amount,.4) and work.steps==16)
	check("source arrays and reference mesh remain unchanged",work.original==original and work.reference.get_child(0).mesh==reference)
	check("artifact owns no cameras or moving collision",work.find_children("*","Camera3D",true,false).is_empty() and work.body.find_children("*","CollisionObject3D",true,false).is_empty())
	var driver=load("res://commons/testing/wcn_desktop_driver.gd").new();room.add_child(driver);driver.spawn(Vector3(0,.03,12.3),room);await tick()
	await driver.press(work.panel.buttons["CLOCKS"],Vector3(0,.03,12.3));await tick()
	check("real desktop pointer selects clocks",work.mode==2)
	await driver.press(work.panel.buttons["CONTROL"],Vector3(0,.03,12.3));await tick()
	check("real desktop pointer restores shared time",work.control and seam_gap()<.00001)
	await driver.press(work.panel.buttons["RESET"],Vector3(0,.03,12.3));await tick()
	check("real desktop pointer resets logical time",work.steps==0 and not work.control)
	await driver.teardown();await tick();await tick()
	work.select_mode(3)
	await capture("console",Vector3(0,1.8,12.7),Vector3(0,.96,11))
	await capture("above",Vector3(8,34,8),Vector3(8,0,-3))
	var viewer=room.spawn_viewer();await tick();check("F6 player retains authored lighting",not viewer.get_node("Head/PlayerHeldLight").darken_environment)
	var failed=checks.filter(func(c):return not c.passed)
	var file:=FileAccess.open(OUT+"report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failed":failed,"captures":captures,"source_triangles":faces,"scope":"Actual float32 encode/decode, authored timestamp skew, bounded deformation feedback, native meshes and desktop pointer. No renderer race, hardware fault, physical headset or museum placement."},"\t"));file.close()
	quit(0 if failed.is_empty() else 1)
