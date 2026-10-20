extends SceneTree
var checks:Array=[]
var source:String
var report:String
var variation:=false
var study:Node3D
var view:SubViewport
func _initialize()->void:call_deferred("run")
func check(ok:bool,title:String)->void:
	checks.append({"passed":ok,"test":title});print("PASS " if ok else "FAIL ",title)
func read()->Image:
	for i in range(5):await process_frame
	await RenderingServer.frame_post_draw
	return view.get_texture().get_image()
func pixel(image:Image,uv:Vector2)->float:
	return image.get_pixel(clampi(int(uv.x*128),0,127),clampi(int(uv.y*128),0,127)).r
func height(y:float)->void:
	study.control.global_position=study.to_global(Vector3(.65,y,1.2));study.update_rule()
func run()->void:
	create_timer(60).timeout.connect(func():quit(98))
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--lesson="):source=arg.trim_prefix("--lesson=")
		if arg.begins_with("--report="):report=arg.trim_prefix("--report=")
		if arg=="--variation":variation=true
	var script=load(source)
	if script==null or not script.can_instantiate():quit(2);return
	study=script.new();study.position=Vector3(4,2,7);study.rotation=Vector3(.2,.7,0)
	root.add_child(study);study.set_process(false);await create_timer(.15).timeout;study.update_rule()
	check(study.control!=null and study.readout.is_inside_tree() and study.receivers.size()==2,"Printed program creates its point, readout and two receivers")
	check(study.control.position.is_equal_approx(Vector3(.65,1.2,1.2)),"Carried point retains its local start after physics")
	check(is_equal_approx(study.radius,.30),"Initial radius uses the translated and turned study's local height")
	check(study.receivers.all(func(n):return n.material_override==study.material),"Both receivers share the one constructed material")
	check(study.receivers[0].mesh.size==Vector2(2,2) and study.receivers[1].mesh.size==Vector2(.54,.54),"Square receivers retain distinct physical sizes")
	var meshes:Array=[];var transforms:Array=[];var shapes:Array=[]
	for n in study.find_children("*","MeshInstance3D",true,false):meshes.append(n.mesh);transforms.append(n.transform)
	for n in study.find_children("*","CollisionShape3D",true,false):shapes.append(n.shape)
	check(shapes.size()==4,"Printed wall, bench, cube and point have explicit collision")
	view=SubViewport.new();view.size=Vector2i(128,128);view.own_world_3d=true;view.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(view)
	var quad:=MeshInstance3D.new();var qm:=QuadMesh.new();qm.size=Vector2(2,2);quad.mesh=qm;quad.material_override=study.material;view.add_child(quad)
	var cam:=Camera3D.new();cam.projection=Camera3D.PROJECTION_ORTHOGONAL;cam.size=2;cam.position=Vector3(0,0,2);view.add_child(cam);cam.make_current()
	var centre:=Vector2(.35,.65) if variation else Vector2(.5,.5)
	var image:=await read()
	check(pixel(image,centre)>.75,"GPU: declared centre receives ink")
	check(pixel(image,Vector2(.99,.99))<.3,"GPU: distant corner receives ground")
	check(pixel(image,centre+Vector2(.40,0))<.3,"GPU: address beyond radius .30 begins outside")
	# Area and centroid detect an incorrect size, off-centre lookup or inverted rule.
	var total:=0;var sum:=Vector2.ZERO
	for y in range(128):
		for x in range(128):
			if image.get_pixel(x,y).r>.75:total+=1;sum+=Vector2((x+.5)/128.0,(y+.5)/128.0)
	check(absf(float(total)/16384.0-PI*.30*.30)<.008,"GPU: hard ink area agrees with radius .30")
	check(total>0 and (sum/maxi(total,1)).distance_to(centre)<.012,"GPU: circle centroid follows the declared centre")
	image.save_png(report.get_base_dir()+"/hard.png")
	height(1.3);check(is_equal_approx(study.radius,.338),"Ten centimetres of local rise adds .038 radius")
	height(5);check(is_equal_approx(study.radius,.46),"Radius clamps at .46")
	image=await read();check(pixel(image,centre+Vector2(.40,0))>.75,"GPU: same address enters when the point enlarges the radius")
	check(pixel(image,Vector2(.99,.99))<.3,"GPU: corner stays outside the enlarged circle")
	height(-5);image=await read();check(is_equal_approx(study.radius,.08),"Radius clamps at .08")
	check(pixel(image,centre+Vector2(.15,0))<.3 and pixel(image,centre)>.75,"GPU: minimum radius retains a smaller visible mark")
	height(1.2);study.control.action();image=await read()
	check(study.soft,"The inherited point action toggles the edge")
	check(is_equal_approx(study.material.get_shader_parameter("softness"),.045),"Action sends softness to the named uniform")
	var edge:=pixel(image,centre+Vector2(.30,0))
	check(edge>.25 and edge<.75,"GPU: soft boundary contains an intermediate value")
	check(pixel(image,centre)>.75 and pixel(image,Vector2(.99,.99))<.3,"GPU: soft mode preserves centre and distant ground")
	image.save_png(report.get_base_dir()+"/soft.png")
	study.control.action();image=await read();var before:=image.get_data()
	check(not study.soft,"Second action restores hard edge")
	await create_timer(.12).timeout;image=await read()
	check(image.get_data()==before,"With fixed inputs the rendered image does not vary with time")
	var retained:=true;var i:=0
	for n in study.find_children("*","MeshInstance3D",true,false):retained=retained and n.mesh==meshes[i] and n.transform==transforms[i];i+=1
	i=0
	for n in study.find_children("*","CollisionShape3D",true,false):retained=retained and n.shape==shapes[i];i+=1
	check(retained,"Input changes retain all mesh, placement and collision resources")
	await physics_frame
	var query:=PhysicsRayQueryParameters3D.create(study.to_global(Vector3(0,1.6,.4)),study.to_global(Vector3(0,1.6,-.2)),1)
	check(not study.get_world_3d().direct_space_state.intersect_ray(query).is_empty(),"Backing remains solid behind the displayed circle")
	var passed:bool=checks.all(func(c):return c.passed)
	var f:=FileAccess.open(report,FileAccess.WRITE);f.store_string(JSON.stringify({"passed":passed,"checks":checks,"variation":variation,"scope":"Exact printed code; native compatibility GPU and synthetic point action/position. No production study import, human learning or physical headset claim."},"\t"));f.close()
	study.queue_free();view.queue_free();await process_frame;quit(0 if passed else 1)
