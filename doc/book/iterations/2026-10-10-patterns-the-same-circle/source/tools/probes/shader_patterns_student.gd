extends SceneTree
var checks:Array=[]
var source:String
var report:String
var variation:=false
var study:Node3D
var view:SubViewport
var repeats:Vector2
const SIDE:=192
func _initialize()->void:call_deferred("run")
func check(ok:bool,title:String)->void:
	checks.append({"passed":ok,"test":title});print("PASS " if ok else "FAIL ",title)
func read()->Image:
	for i in range(5):await process_frame
	await RenderingServer.frame_post_draw
	return view.get_texture().get_image()
func pixel(im:Image,p:Vector2)->float:
	return im.get_pixel(clampi(int(p.x*SIDE),0,SIDE-1),clampi(int(p.y*SIDE),0,SIDE-1)).r
func move(x:float,y:float=1.2)->void:
	study.control.global_position=study.to_global(Vector3(x,y,1.2));study.update_rule()
func difference(a:Image,b:Image)->float:
	var changed:=0
	for y in range(SIDE):
		for x in range(SIDE):
			if absf(a.get_pixel(x,y).r-b.get_pixel(x,y).r)>.15:changed+=1
	return float(changed)/(SIDE*SIDE)
func runs(im:Image,horizontal:bool)->Array[int]:
	var widths:Array[int]=[];var length:=0
	for i in range(SIDE):
		var p:=Vector2((i+.5)/SIDE,.5/repeats.y) if horizontal else Vector2(.5/repeats.x,(i+.5)/SIDE)
		if pixel(im,p)>.75:length+=1
		elif length>0:widths.append(length);length=0
	if length>0:widths.append(length)
	return widths
func run()->void:
	create_timer(65).timeout.connect(func():quit(98))
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--lesson="):source=arg.trim_prefix("--lesson=")
		if arg.begins_with("--report="):report=arg.trim_prefix("--report=")
		if arg=="--variation":variation=true
	repeats=Vector2(4,2) if variation else Vector2(3,3)
	var script=load(source)
	if script==null or not script.can_instantiate():quit(2);return
	study=script.new();study.position=Vector3(4,2,7);study.rotation=Vector3(.2,.7,0)
	root.add_child(study);study.set_process(false);await create_timer(.15).timeout;study.update_rule()
	check(study.control!=null and study.readout.is_inside_tree() and study.receivers.size()==2,"Printed program creates the inherited point, label and two receivers")
	check(is_equal_approx(study.radius,.30) and is_zero_approx(study.shift),"Translated and turned study retains local starting radius and shift")
	check(study.receivers.all(func(n):return n.material_override==study.material),"Wall and cube share one material")
	check(study.receivers[0].mesh.size==Vector2(2,2) and study.receivers[1].mesh.size==Vector2(.54,.54),"The two complete UV squares retain their metre sizes")
	var meshes:Array=[];var poses:Array=[];var shapes:Array=[]
	for n in study.find_children("*","MeshInstance3D",true,false):meshes.append(n.mesh);poses.append(n.transform)
	for n in study.find_children("*","CollisionShape3D",true,false):shapes.append(n.shape)
	check(shapes.size()==4,"Inherited wall, bench, cube and point collision exists")
	view=SubViewport.new();view.size=Vector2i(SIDE,SIDE);view.own_world_3d=true;view.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(view)
	var quad:=MeshInstance3D.new();var qm:=QuadMesh.new();qm.size=Vector2(2,2);quad.mesh=qm;quad.material_override=study.material;view.add_child(quad)
	var cam:=Camera3D.new();cam.projection=Camera3D.PROJECTION_ORTHOGONAL;cam.size=2;cam.position=Vector3(0,0,2);view.add_child(cam);cam.make_current()
	var original:=await read();original.save_png(report.get_base_dir()+"/repeated.png")
	var centres:=true;var corners:=true
	for y in int(repeats.y):
		for x in int(repeats.x):
			centres=centres and pixel(original,(Vector2(x,y)+Vector2(.5,.5))/repeats)>.75
			corners=corners and pixel(original,(Vector2(x,y)+Vector2(.02,.02))/repeats)<.3
	check(centres,"GPU: every declared cell centre receives ink")
	check(corners,"GPU: cell corners receive ground, without drawn borders")
	var across:=runs(original,true);var down:=runs(original,false)
	check(across.size()==int(repeats.x),"GPU: horizontal circle count follows repeat X")
	check(down.size()==int(repeats.y),"GPU: vertical circle count follows repeat Y")
	check(not across.is_empty() and not down.is_empty() and absf(float(across[0])/down[0]-repeats.y/repeats.x)<.07,"GPU: image aspect follows cell width divided by height")
	var count:=0
	for y in SIDE:
		for x in SIDE:
			if original.get_pixel(x,y).r>.75:count+=1
	check(absf(float(count)/(SIDE*SIDE)-PI*.30*.30)<.008,"GPU: repeated hard masks retain the expected ink coverage")
	var centre:=Vector2(.5,.5)/repeats
	move(1.15);var half:=await read()
	check(is_equal_approx(study.shift,.5),"Half a metre of local X becomes half a tile")
	check(pixel(half,centre)<.3,"GPU: half shift moves the original centre into background")
	check(pixel(half,Vector2(.02,.5)/repeats)>.75,"GPU: shifted circle crosses a cell boundary")
	half.save_png(report.get_base_dir()+"/half-shift.png")
	move(1.65);var full:=await read()
	check(difference(original,full)<.005,"GPU: full positive tile shift returns the whole image")
	move(-.35);var negative:=await read()
	check(difference(original,negative)<.005,"GPU: full negative shift also returns the image")
	move(.90);var quarter:=await read()
	check(pixel(quarter,Vector2(.25,.5)/repeats)>.75 and pixel(quarter,Vector2(.70,.5)/repeats)<.3,"GPU: positive lookup shift moves marks left")
	move(.40);var opposite:=await read()
	check(pixel(opposite,Vector2(.75,.5)/repeats)>.75 and pixel(opposite,Vector2(.30,.5)/repeats)<.3,"GPU: negative lookup shift moves marks right")
	move(.65,1.3);check(is_equal_approx(study.radius,.338) and is_zero_approx(study.shift),"Vertical motion retains the earned radius mapping independently of shift")
	move(.65,5);var large:=await read()
	check(is_equal_approx(study.radius,.46) and pixel(large,Vector2(.90,.5)/repeats)>.75,"GPU: inherited radius maximum enlarges the repeated circles")
	move(.65,-5);var small:=await read()
	check(is_equal_approx(study.radius,.08) and pixel(small,centre)>.75 and pixel(small,Vector2(.65,.5)/repeats)<.3,"GPU: inherited minimum retains small separate circles")
	move(.65);study.control.action();var soft:=await read()
	check(study.soft and is_equal_approx(study.material.get_shader_parameter("softness"),.045),"Inherited point action still sends edge width")
	var edge:=pixel(soft,Vector2(.80,.5)/repeats)
	check(edge>.25 and edge<.75,"GPU: repeated soft boundary contains intermediate colour")
	soft.save_png(report.get_base_dir()+"/soft.png")
	study.control.action();check(not study.soft,"Second point action restores hard edge")
	var returned:=await read();check(difference(original,returned)<.005,"Resetting inputs recovers the starting image")
	await create_timer(.12).timeout;var later:=await read()
	check(difference(returned,later)==0,"Fixed coordinates do not animate with time")
	quad.position.x+=.37;cam.position.x+=.37;var translated:=await read()
	check(difference(returned,translated)<.005,"GPU: UV pattern stays attached when its receiver and camera translate together")
	var retained:=true;var i:=0
	for n in study.find_children("*","MeshInstance3D",true,false):retained=retained and n.mesh==meshes[i] and n.transform==poses[i];i+=1
	i=0
	for n in study.find_children("*","CollisionShape3D",true,false):retained=retained and n.shape==shapes[i];i+=1
	check(retained,"Repetition and phase retain mesh count, placement and collision resources")
	await physics_frame
	var ray:=PhysicsRayQueryParameters3D.create(study.to_global(Vector3(0,1.6,.4)),study.to_global(Vector3(0,1.6,-.2)),1)
	check(not study.get_world_3d().direct_space_state.intersect_ray(ray).is_empty(),"The displayed pattern leaves its backing solid")
	var passed:bool=checks.all(func(c):return c.passed)
	var f:=FileAccess.open(report,FileAccess.WRITE);f.store_string(JSON.stringify({"passed":passed,"checks":checks,"variation":variation,"scope":"Exact printed primary continuation; GPU and synthetic control inputs. Optional saved-record appendix unchanged and not rerun here. No headset/human-learning claim."},"\t"));f.close()
	study.queue_free();view.queue_free();await process_frame;quit(0 if passed else 1)
