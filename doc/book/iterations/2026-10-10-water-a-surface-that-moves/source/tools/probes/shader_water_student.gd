extends SceneTree
var checks:Array=[]
var source:String
var report:String
var variation:=false
var study:Node3D
var view:SubViewport
const SIDE:=256
func _initialize()->void:call_deferred("run")
func check(ok:bool,title:String)->void:
	checks.append({"passed":ok,"test":title});print("PASS " if ok else "FAIL ",title)
func read()->Image:
	for i in range(5):await process_frame
	await RenderingServer.frame_post_draw
	return view.get_texture().get_image()
func difference(a:Image,b:Image)->float:
	var total:=0.0
	for y in SIDE:
		for x in SIDE:
			var p:=a.get_pixel(x,y);var q:=b.get_pixel(x,y)
			total+=(absf(p.r-q.r)+absf(p.g-q.g)+absf(p.b-q.b))/3
	return total/(SIDE*SIDE)
func coverage(a:Image,b:Image)->int:
	var total:=0
	for y in SIDE:
		for x in SIDE:
			if (a.get_pixel(x,y).a>.5)!=(b.get_pixel(x,y).a>.5):total+=1
	return total
func move(x:float=.65,y:float=1.2)->void:
	study.control.global_position=study.to_global(Vector3(x,y,1.2));study.update_rule()
func mode(n:int)->void:
	# Mode-only GPU comparison holds the last input; real action is tested below/in the museum.
	study.mode=n;study.material.set_shader_parameter("mode",n)
func run()->void:
	create_timer(75).timeout.connect(func():quit(98))
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--lesson="):source=arg.trim_prefix("--lesson=")
		if arg.begins_with("--report="):report=arg.trim_prefix("--report=")
		if arg=="--variation":variation=true
	var script=load(source)
	if script==null or not script.can_instantiate():quit(2);return
	study=script.new();study.position=Vector3(4,2,7);study.rotation.y=.7;root.add_child(study);study.set_process(false)
	await create_timer(.15).timeout;study.update_rule()
	check(study.control!=null and study.readout.is_inside_tree() and study.surface.mesh is PlaneMesh,"Printed code creates its point, label, plane and support")
	check(is_equal_approx(study.relief,.15) and minf(study.phase,TAU-study.phase)<.00002 and study.mode==0,"Translated/turned host retains local starting controls")
	check(study.surface.mesh.size==Vector2(3,3),"Plane keeps the declared three-metre extent")
	var vertices:PackedVector3Array=study.surface.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	check(vertices.size()==(4 if variation else 2500),"Subdivision creates the declared number of vertices")
	check(study.surface.find_children("*","CollisionObject3D",true,false).is_empty(),"Water has no hidden collider")
	check(study.control.surface.material_override!=study.material,"Point retains a separate rigid surface material")
	var mesh:Mesh=study.surface.mesh;var bridge_pose:Transform3D=study.bridge.transform;var cube_pose:Transform3D=study.cube.transform
	var bridge_shape:Shape3D=study.bridge.get_child(1).shape
	check(study.surface.custom_aabb==AABB(Vector3(-1.5,-.25,-1.5),Vector3(3,.5,3)),"Rendering bounds cover the permitted displacement")
	check(study.surface.position.y+.25<study.bridge.position.y-.03 and study.surface.position.y-.25>.42,"Both displacement extremes fit between tray floor and glass underside")
	view=SubViewport.new();view.size=Vector2i(SIDE,SIDE);view.own_world_3d=true;view.transparent_bg=true;view.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(view)
	var env:=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color.BLACK;env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color.WHITE;env.environment.ambient_light_energy=.25;view.add_child(env)
	var light:=DirectionalLight3D.new();light.rotation_degrees=Vector3(-55,-30,0);view.add_child(light)
	var water:=MeshInstance3D.new();water.mesh=mesh;water.material_override=study.material;water.custom_aabb=study.surface.custom_aabb;view.add_child(water)
	var cam:=Camera3D.new();cam.projection=Camera3D.PROJECTION_ORTHOGONAL;cam.size=4;cam.position=Vector3(.4,1.2,4);view.add_child(cam);cam.look_at(Vector3.ZERO);cam.make_current()
	move(.65,1.4);mode(0);var colour:=await read();colour.save_png(report.get_base_dir()+"/colour.png")
	mode(1);var normal:=await read();normal.save_png(report.get_base_dir()+"/normal.png")
	check(difference(colour,normal)>.001,"GPU: vertex normals change the light response")
	check(coverage(colour,normal)==0,"GPU: normal-only mode retains the flat outline")
	mode(2);var height:=await read();height.save_png(report.get_base_dir()+"/height.png")
	print("HEIGHT_COVERAGE_CHANGE ",coverage(normal,height))
	check(coverage(normal,height)>10,"GPU: vertex displacement changes the outline")
	move(.65,.89);var zero:=await read();mode(1);var zero_normal:=await read()
	check(is_zero_approx(study.relief) and difference(colour,zero)<.002 and difference(colour,zero_normal)<.002,"GPU: zero relief restores flat normals and vertices while keeping pigment")
	move(.65,1.4);mode(2);var first:=await read();await create_timer(.15).timeout;var later:=await read()
	check(difference(first,later)==0,"GPU: held phase is unchanged by elapsed time")
	move(1.15,1.4);var half:=await read();check(difference(first,half)>.003,"GPU: a half-turn reads a different field")
	move(1.65,1.4);var full:=await read();check(difference(first,full)<.003,"GPU: one metre of sideways movement returns the circular field")
	move(-.35,1.4);var negative:=await read();check(difference(first,negative)<.003,"GPU: a negative full turn also returns the field")
	move(.65,1.4);mode(0);study.material.set_shader_parameter("octaves",1);var one:=await read();study.material.set_shader_parameter("octaves",4);var four:=await read()
	check(difference(one,four)>.001,"GPU: one and four scales differ at the same mesh density")
	study.material.set_shader_parameter("octaves",3)
	# Known boundary case: a normalized one-octave field must equal the source noise.
	# Instrument only the output; execute the printed field and noise functions unchanged.
	var diagnostic:=Shader.new();var code:String=study.material.shader.code
	code=code.replace("render_mode cull_disabled;","render_mode cull_disabled, unshaded;")
	code=code.substr(0,code.find("void fragment()"))+"void fragment(){ float a=0.5+0.5*field(position_xz); float b=noise2(position_xz+0.9*vec2(cos(phase),sin(phase))); ALBEDO=vec3(a,b,0.0); }"
	diagnostic.code=code
	var data:=ShaderMaterial.new();data.shader=diagnostic;data.set_shader_parameter("mode",0);data.set_shader_parameter("octaves",1);data.set_shader_parameter("phase",0.0);water.material_override=data
	var result:=await read();var error:=0.0;var count:=0
	for y in SIDE:
		for x in SIDE:
			var p:=result.get_pixel(x,y)
			if p.a>.5:error+=absf(p.r-p.g);count+=1
	check(count>1000 and error/count<.003,"GPU: normalized one-octave result equals its source noise")
	# Compare with the opposite mesh density under identical field, pose and lamp.
	water.material_override=study.material;mode(2);var current:=await read()
	var other:=PlaneMesh.new();other.size=Vector2(3,3);other.subdivide_width=48 if variation else 0;other.subdivide_depth=other.subdivide_width;water.mesh=other
	var alternate:=await read();alternate.save_png(report.get_base_dir()+"/other-resolution.png")
	check(difference(current,alternate)>.002 and coverage(current,alternate)>5,"GPU: two triangles cannot reproduce the densely sampled surface")
	move(.65,10);check(is_equal_approx(study.relief,.25),"High point motion clamps relief to a quarter metre")
	move(.65,-10);check(is_zero_approx(study.relief),"Low point motion clamps relief to zero")
	move();mode(0);study.control.action();check(study.mode==1,"First point action selects NORMAL")
	study.control.action();check(study.mode==2,"Second point action selects HEIGHT")
	study.control.action();check(study.mode==0,"Third point action returns to COLOUR")
	check(study.surface.mesh==mesh and study.surface.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]==vertices,"Shader controls leave the CPU mesh data intact")
	check(study.bridge.transform==bridge_pose and study.cube.transform==cube_pose and study.bridge.get_child(1).shape==bridge_shape,"Cube, glass placement and glass collider remain fixed")
	await physics_frame
	var ray:=PhysicsRayQueryParameters3D.create(study.to_global(Vector3(0,1.5,0)),study.to_global(Vector3(0,.2,0)),1)
	var hit:=study.get_world_3d().direct_space_state.intersect_ray(ray)
	check(not hit.is_empty() and hit.collider==study.bridge and absf(study.to_local(hit.position).y-1.07)<.002,"Physics ray meets the glass top, not the water")
	ray=PhysicsRayQueryParameters3D.create(study.to_global(Vector3(.8,1.5,0)),study.to_global(Vector3(.8,.2,0)),1)
	hit=study.get_world_3d().direct_space_state.intersect_ray(ray)
	check(not hit.is_empty() and absf(study.to_local(hit.position).y-.42)<.002,"Beside the glass, a ray passes through the water to the tray floor")
	var passed:bool=checks.all(func(c):return c.passed)
	var f:=FileAccess.open(report,FileAccess.WRITE);f.store_string(JSON.stringify({"passed":passed,"checks":checks,"variation":variation,"scope":"Exact printed continuation, GPU readback and teacher-authored controls. Diagnostic output preserves printed field/noise functions. No independent-student/headset claim."},"\t"));f.close()
	study.queue_free();view.queue_free();await process_frame;quit(0 if passed else 1)
