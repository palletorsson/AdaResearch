extends SceneTree
var checks:Array=[]
var work:Node3D
var camera:Camera3D
var grid:Node3D
const OUT="res://ada_run/pivot_body/"
func _initialize()->void:run.call_deferred()
func check(label:String,value:bool)->void:
	checks.append({"name":label,"passed":value});print("[pivot] ","PASS " if value else "FAIL ",label)
func tick()->void:
	await physics_frame;await process_frame
func shot(id:String,eye:Vector3,target:Vector3)->void:
	camera.global_position=work.to_global(eye);camera.look_at(work.to_global(target));camera.current=true
	await create_timer(.4).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT+id+".png"))
func run()->void:
	var world:=Node3D.new();root.add_child(world);current_scene=world
	var env:=WorldEnvironment.new();var e:=Environment.new();e.background_mode=Environment.BG_COLOR;e.background_color=Color("b7c5c8")
	e.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;e.ambient_light_color=Color("d8e1e4");e.ambient_light_energy=.65;e.tonemap_mode=Environment.TONE_MAPPER_FILMIC
	env.environment=e;world.add_child(env)
	var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-45,-30,0);sun.light_energy=1.8;sun.shadow_enabled=true;world.add_child(sun)
	grid=load("res://commons/grid/grid_system.tscn").instantiate();grid.map_name="Ribbon_Randomness_02";grid.bare_world=true;world.add_child(grid)
	var deadline:=Time.get_ticks_msec()+65000
	while Time.get_ticks_msec()<deadline:
		for n in grid.find_children("*","Node3D",true,false):
			if n.get_script()!=null and str(n.get_script().resource_path).ends_with("/omoss/omoss.gd"):work=n;break
		if work!=null and is_instance_valid(work.creature):break
		await process_frame
	check("registered artifact loaded in existing Ribbon_Randomness_02 gallery",work!=null)
	if work==null:finish();return
	await create_timer(1.0).timeout
	camera=Camera3D.new();camera.fov=58;root.add_child(camera)
	work.set_process(false);work.act("RESET")
	var c=work.creature
	check("real skeleton has 25 named bones",c.skeleton.get_bone_count()==25)
	check("skin has 25 inverse bind matrices",c.skin_mesh.skin.get_bind_count()==25)
	check("skin resolves its actual skeleton",c.skin_mesh.get_node(c.skin_mesh.skeleton)==c.skeleton)
	check("one immutable mesh with 3344 vertices",c.vertices.size()==3344 and c.skin_mesh.mesh.get_surface_count()==1)
	var normalized:=true;var valid_indices:=true;var rest_error:=0.0
	for i in c.vertices.size():
		var total:=0.0
		for j in 4:
			total+=c.weights[i*4+j];valid_indices=valid_indices and c.bones[i*4+j]>=0 and c.bones[i*4+j]<25
		normalized=normalized and is_equal_approx(total,1.0)
		rest_error=maxf(rest_error,c.deformed_vertex(i).distance_to(c.vertices[i]))
	check("all bone weights sum to one",normalized)
	check("all vertex influences refer to existing bones",valid_indices)
	check("inverse bind reproduces all rest vertices",rest_error<.0001)
	var original:PackedVector3Array=c.skin_mesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].duplicate()
	var p:=Vector3(.5,.2,.1)
	work.set_pivot(Vector3(.4,.1,.15));work.turn=PI*.5;work.body_scale=1.2;work.update_body()
	var b:=Basis(Vector3.UP,PI*.5).scaled_local(Vector3.ONE*1.2)
	check("whole body rotates/scales about displaced centre",(c.transform*p).is_equal_approx(work.BODY_ORIGIN+work.pivot+b*(p-work.pivot)))
	check("point at pivot is fixed by whole-body transform",(c.transform*work.pivot).is_equal_approx(work.BODY_ORIGIN+work.pivot))
	check("whole-body rotation alone preserves local rest shape",c.deformed_vertex(1200).is_equal_approx(c.vertices[1200]))
	work.act("RESET");await tick()
	await shot("rest",Vector3(-3.5,2.0,6),Vector3(0,2.1,-.2))
	work.set_pivot(Vector3(.55,.2,0));work.turn=.5;work.limbs=.92;work.clock=3.1;work.update_body();await tick()
	var max_change:=0.0
	for i in c.vertices.size():max_change=maxf(max_change,c.deformed_vertex(i).distance_to(c.vertices[i]))
	check("bone transforms actually deform weighted surface",max_change>.3)
	check("deformation leaves original vertex buffer unchanged",original==c.skin_mesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX])
	var a:Vector3=c.deformed_vertex(1250)
	work.clock+=1;work.update_body();await tick()
	check("local clock moves the same creature",a.distance_to(c.deformed_vertex(1250))>.01)
	await shot("creature",Vector3(-3.2,2.35,5.5),Vector3(0,2.15,-.2))
	work.act("BONES");await tick()
	check("bone toggle shows actual hierarchy",c.overlay.visible and c.bone_markers.size()==25)
	await shot("bones",Vector3(-1.3,2.6,4.0),Vector3(0,2.30,-.45))
	work.act("BONES");work.act("CENTRE")
	check("centre returns proxy and pivot to origin",work.pivot==Vector3.ZERO and work.handle.position.is_equal_approx(work.HANDLE_ORIGIN))
	var owner:=Node3D.new();root.add_child(owner)
	var from:Vector3=work.handle.global_position
	work.handle.pointer_event(XRToolsPointerEvent.new(XRToolsPointerEvent.Type.PRESSED,owner,work.handle,from,from))
	work.handle.pointer_event(XRToolsPointerEvent.new(XRToolsPointerEvent.Type.MOVED,owner,work.handle,from+Vector3(.25,.1,0),from))
	work._process(0)
	check("desktop pointer moves the pivot",work.pivot.length()>.2)
	work.handle.pointer_event(XRToolsPointerEvent.new(XRToolsPointerEvent.Type.RELEASED,owner,work.handle,from,from))
	check("pointer release relinquishes ownership",work.handle.pointer_owner==null)
	owner.queue_free()
	var origin:=XROrigin3D.new();root.add_child(origin);var controller:=XRController3D.new();origin.add_child(controller)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();controller.add_child(pickup)
	controller.global_transform=work.handle.global_transform
	work.handle.pick_up(pickup);await tick();await tick()
	check("XRTools grip takes the pivot handle",work.handle.is_picked_up())
	controller.global_position+=Vector3(-.2,.1,.1)
	for i in 6:await tick()
	work._process(0)
	check("held pivot follows controller movement",work.pivot.z>.05)
	work.handle.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await tick()
	check("drop keeps handle frozen without gravity",not work.handle.is_picked_up() and work.handle.freeze)
	origin.queue_free()
	work.set_pivot(Vector3(100,100,100))
	check("pivot range remains bounded",work.pivot.length()<=.65001)
	for dial in [work.panel.turn_dial,work.panel.scale_dial,work.panel.limb_dial]:
		dial.set_normalized_value(.8);dial.hinge_moved.emit(0.0);await tick()
	check("native controls route rotation scale and limbs",is_equal_approx(work.turn,PI*.6) and is_equal_approx(work.body_scale,1.15) and is_equal_approx(work.limbs,.8))
	var stand:Vector3=work.to_global(Vector3(0,0,3))
	var driver=load("res://commons/testing/wcn_desktop_driver.gd").new();world.add_child(driver);driver.spawn(stand,world);await tick()
	driver.aim_at(work.handle.global_position)
	check("real desktop pointer can target pink grab point",await driver.hover_target()==work.handle)
	print("RESET POINTER ",await driver.press(work.panel.buttons["RESET"],stand));await tick()
	check("real pointer reset restores rest state",work.pivot==Vector3.ZERO and work.limbs==0 and work.body_scale==1 and work.clock==0 and not work.running)
	var reset_error:=0.0
	for i in c.vertices.size():reset_error=maxf(reset_error,c.deformed_vertex(i).distance_to(c.vertices[i]))
	check("reset restores entire skinned mesh",reset_error<.0001)
	await driver.press(work.panel.buttons["RUN"],stand);await tick()
	check("real pointer run toggles animation",work.running)
	work.set_process(true);await create_timer(.3).timeout;work.set_process(false)
	check("running advances local clock",work.clock>.1)
	print("ARTIFACT POSITION ",work.global_position," scale ",work.global_basis.get_scale())
	work.limbs=.65;work.turn=-.2;work.clock=2.0;work.set_pivot(Vector3(.3,.12,0));work.update_body()
	await shot("console",Vector3(0,1.8,3.0),Vector3(0,1.05,1.7))
	await shot("gallery",Vector3(-4,4.7,6),Vector3(0,1.9,-.45))
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=14
	camera.global_position=work.global_position+Vector3(0,20,0);camera.look_at(work.global_position,Vector3.FORWARD)
	await create_timer(.3).timeout;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT+"overhead.png"))
	finish()
func finish()->void:
	var failed=checks.filter(func(x):return not x.passed)
	var f:=FileAccess.open(OUT+"report.json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failed":failed,"scope":"Existing map via GridSystem. Native rendering, desktop pointer and simulated XRTools grip; not physical headset."},"\t"));f.close()
	quit(0 if failed.is_empty() else 1)
