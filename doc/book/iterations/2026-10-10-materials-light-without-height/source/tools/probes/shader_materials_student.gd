extends SceneTree
var checks:Array=[]
var source:String
var report:String
var variation:=false
var study:Node3D
var view:SubViewport
var lamp:OmniLight3D
var repeats:Vector2
const SIDE:=256
func _initialize()->void:call_deferred("run")
func check(ok:bool,title:String)->void:
	checks.append({"passed":ok,"test":title});print("PASS " if ok else "FAIL ",title)
func read()->Image:
	for i in range(5):await process_frame
	await RenderingServer.frame_post_draw
	return view.get_texture().get_image()
func pixel(im:Image,p:Vector2)->Color:
	return im.get_pixel(clampi(int(p.x*SIDE),0,SIDE-1),clampi(int(p.y*SIDE),0,SIDE-1))
func move(x:float=.65,y:float=1.2)->void:
	study.control.global_position=study.to_global(Vector3(x,y,1.2))
	PhysicsServer3D.body_set_state(study.control.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,study.control.global_transform)
	study.update_rule()
func difference(a:Image,b:Image)->float:
	var total:=0.0
	for y in SIDE:
		for x in SIDE:
			var p:=a.get_pixel(x,y);var q:=b.get_pixel(x,y)
			total+=(absf(p.r-q.r)+absf(p.g-q.g)+absf(p.b-q.b))/3
	return total/(SIDE*SIDE)
func mode(n:int)->void:
	study.mode=n;study.material.set_shader_parameter("mode",n)
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
	check(study.control!=null and study.readout.is_inside_tree() and study.receivers.size()==2,"Printed program creates the inherited point, label and receivers")
	check(is_equal_approx(study.strength,.6) and is_equal_approx(study.roughness,.35) and study.mode==0,"Translated and turned study uses the local starting pose")
	check(study.receivers.all(func(n):return n.material_override==study.material) and study.control.surface.material_override==study.material,"Squares and the same grabbable point share the material")
	check(study.receivers[0].mesh.size==Vector2(2,2) and study.receivers[1].mesh.size==Vector2(.54,.54),"Two UV squares retain their physical sizes")
	var meshes:Array=[];var poses:Array=[];var shapes:Array=[]
	for n in study.find_children("*","MeshInstance3D",true,false):meshes.append(n.mesh);poses.append(n.transform)
	for n in study.find_children("*","CollisionShape3D",true,false):shapes.append(n.shape)
	check(shapes.size()==4,"Wall, bench, cube and point collision are present")
	var h:Image=study.maps.height.get_image();var n:Image=study.maps.normal.get_image()
	h.save_png(report.get_base_dir()+"/height-data.png");n.save_png(report.get_base_dir()+"/normal-data.png")
	check(h.get_size()==Vector2i(SIDE,SIDE) and n.get_size()==h.get_size(),"Both maps contain 256 by 256 samples")
	var centres:=true;var corners:=true
	for y in int(repeats.y):
		for x in int(repeats.x):
			centres=centres and pixel(h,(Vector2(x,y)+Vector2(.5,.5))/repeats).r>.99
			corners=corners and pixel(h,(Vector2(x,y)+Vector2(.02,.02))/repeats).r<.01
	check(centres and corners,"Generated height data has each declared circle and its surrounding ground")
	var flat_n:=pixel(n,Vector2(.5,.5)/repeats)
	check(absf(flat_n.r-.5)<.005 and absf(flat_n.g-.5)<.005 and flat_n.b>.99,"Level patch encodes the unperturbed normal")
	check(pixel(n,Vector2(.20,.5)/repeats).r<.4 and pixel(n,Vector2(.80,.5)/repeats).r>.6,"Encoded X normals lean outward from a raised circle")
	check(pixel(n,Vector2(.5,.20)/repeats).g>.6 and pixel(n,Vector2(.5,.80)/repeats).g<.4,"Encoded Y normals use upward green for downward image rows")
	view=SubViewport.new();view.size=Vector2i(SIDE,SIDE);view.own_world_3d=true;view.transparent_bg=true;view.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(view)
	var env:=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color.BLACK;env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_energy=0;view.add_child(env)
	var quad:=MeshInstance3D.new();var qm:=QuadMesh.new();qm.size=Vector2(2,2);quad.mesh=qm;quad.material_override=study.material;view.add_child(quad)
	var cam:=Camera3D.new();cam.projection=Camera3D.PROJECTION_ORTHOGONAL;cam.size=2;cam.position=Vector3(0,0,2);view.add_child(cam);cam.make_current()
	lamp=OmniLight3D.new();lamp.position=Vector3(-2,0,1);lamp.omni_range=8;lamp.light_energy=5;view.add_child(lamp)
	move(1.85,1.4);mode(0);var flat:=await read();flat.save_png(report.get_base_dir()+"/flat.png")
	mode(1);var bump:=await read();bump.save_png(report.get_base_dir()+"/height.png")
	check(difference(flat,bump)>.02,"GPU: height slopes change the light response")
	check(absf(pixel(bump,Vector2(.5,.5)/repeats).r-pixel(flat,Vector2(.5,.5)/repeats).r)<.004,"GPU: the level top has no slope and retains flat shading")
	mode(2);var normal:=await read();normal.save_png(report.get_base_dir()+"/normal.png")
	print("PARITY_MAE ",difference(bump,normal))
	check(difference(bump,normal)<.012,"GPU: encoded normals reproduce height-derived relief within interpolation tolerance")
	check(difference(flat,normal)>.02,"GPU: normal map differs from the flat reading")
	# The first circle lies left of centre. A lamp farther left must light its left slope.
	mode(1)
	var left:=pixel(bump,Vector2(.20,.5)/repeats).r;var right:=pixel(bump,Vector2(.80,.5)/repeats).r
	print("X light left/right ",left," / ",right)
	check(left>right+.04,"GPU: lamp on the left lights the left-facing slope")
	lamp.position=Vector3(0,2,1);var top:=await read()
	var above:=pixel(top,Vector2(.5,.20)/repeats).r;var below:=pixel(top,Vector2(.5,.80)/repeats).r
	print("Y light above/below ",above," / ",below)
	check(above>below+.04,"GPU: lamp above lights the upward-facing slope")
	check(difference(top,bump)>.02,"GPU: moving the light changes the relief")
	lamp.position=Vector3(-2,0,1);move(1.85,.9);mode(1);var zero_h:=await read();mode(2);var zero_n:=await read()
	print("ZERO strength ",study.strength," rough ",study.roughness," h ",difference(flat,zero_h)," n ",difference(flat,zero_n));zero_h.save_png(report.get_base_dir()+"/zero.png")
	check(is_zero_approx(study.strength) and difference(flat,zero_h)<.002 and difference(flat,zero_n)<.002,"GPU: zero strength returns both readings to the flat response")
	move(1.85,1.4);mode(1);var rough:=await read();move(-1.0,1.4);var smooth:=await read()
	check(is_equal_approx(study.roughness,.05) and difference(rough,smooth)>.001,"GPU: roughness changes light response independently of slope strength")
	move(5,5);check(is_equal_approx(study.strength,1) and is_equal_approx(study.roughness,.95),"Controls clamp at full relief and maximum roughness")
	move(-5,-5);check(is_zero_approx(study.strength) and is_equal_approx(study.roughness,.05),"Controls clamp at zero relief and minimum roughness")
	move();mode(0);study.control.action();check(study.mode==1,"Inherited point action selects the height reading")
	study.control.action();check(study.mode==2,"Second action selects the normal reading")
	study.control.action();check(study.mode==0,"Third action returns to flat")
	mode(1);var now:=await read();await create_timer(.12).timeout;var later:=await read()
	check(difference(now,later)==0,"Fixed inputs do not animate with time")
	lamp.light_energy=0;var dark:=await read();check(pixel(dark,Vector2(.20,.5)/repeats).r<.005,"GPU: relief adds no emission when illumination is removed")
	# Oblique view with background margins makes coverage a real silhouette test.
	lamp.light_energy=5;cam.size=3;cam.position=Vector3(.8,.5,3);cam.look_at(Vector3.ZERO)
	mode(0);var outline_flat:=await read();mode(1);var outline_height:=await read();mode(2);var outline_normal:=await read()
	var unchanged_alpha:=true;var covered:=0
	for y in SIDE:
		for x in SIDE:
			var a:float=outline_flat.get_pixel(x,y).a
			if a>.5:covered+=1
			unchanged_alpha=unchanged_alpha and is_equal_approx(a,outline_height.get_pixel(x,y).a) and is_equal_approx(a,outline_normal.get_pixel(x,y).a)
	check(unchanged_alpha and covered>1000 and covered<SIDE*SIDE*.9,"GPU: flat, height and normal readings retain the same oblique silhouette")
	var retained:=true;var i:=0
	for m in study.find_children("*","MeshInstance3D",true,false):retained=retained and m.mesh==meshes[i] and m.transform==poses[i];i+=1
	i=0
	for c in study.find_children("*","CollisionShape3D",true,false):retained=retained and c.shape==shapes[i];i+=1
	check(retained,"All modes and controls retain mesh poses and collision resources")
	check(h.get_data()==study.maps.height.get_image().get_data() and n.get_data()==study.maps.normal.get_image().get_data(),"Controls leave the prepared texture data intact")
	await physics_frame
	var ray:=PhysicsRayQueryParameters3D.create(study.to_global(Vector3(0,1.6,.4)),study.to_global(Vector3(0,1.6,-.2)),1)
	check(not study.get_world_3d().direct_space_state.intersect_ray(ray).is_empty(),"Apparent relief leaves the backing physically solid")
	var passed:bool=checks.all(func(c):return c.passed)
	var f:=FileAccess.open(report,FileAccess.WRITE);f.store_string(JSON.stringify({"passed":passed,"checks":checks,"variation":variation,"scope":"Exact printed files, GPU pixels and synthetic controls. Teacher-authored reconstruction; no independent learner or headset claim."},"\t"));f.close()
	study.queue_free();view.queue_free();await process_frame;quit(0 if passed else 1)
