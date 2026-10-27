extends SceneTree
const ModelStorage = preload("res://tools/generated_storage.gd")
const OUT := "res://ada_run/architecture_variations/"
var checks: Array = []
var camera: Camera3D
var work: Node3D
func _initialize() -> void:run.call_deferred()
func check(label:String,passed:bool) -> void:
	checks.append({"name":label,"passed":passed});print("[architecture variations] ","PASS " if passed else "FAIL ",label)
func tick() -> void:
	await physics_frame;await process_frame
func shot(id:String,eye:Vector3,target:Vector3) -> void:
	camera.projection=Camera3D.PROJECTION_PERSPECTIVE;camera.fov=58
	camera.position=eye;camera.look_at(target);camera.current=true
	await create_timer(.3).timeout;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT+id+".png"))
	if id in ["source","curve","hinge","hinge-floor","field","stretch"]:
		var doc:=GLTFDocument.new();var state:=GLTFState.new()
		# glTF has no visibility flag: omit the hidden handle witness explicitly.
		var export_root:=Node3D.new();export_root.name="Arcade";export_root.transform=work.body.transform
		for child in work.body.get_children():
			if child is MeshInstance3D and child.visible:export_root.add_child(child.duplicate())
		var appended:=doc.append_from_scene(export_root,state)
		var written:=ModelStorage.write_gltf(doc,state,OUT+id+".glb") if appended==OK else FAILED
		check("exported native geometry: "+id,appended==OK and written==OK)
		export_root.free()
func positions() -> PackedVector3Array:
	var result:=PackedVector3Array()
	for item in work.rendered:
		for s in item.mesh.get_surface_count():
			var vertices:PackedVector3Array=item.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX]
			for p in vertices:result.append(item.transform*p)
	return result
func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var room=load("res://commons/artifacts/architecture_variations/preview.tscn").instantiate();root.add_child(room);current_scene=room
	await tick();work=room.work;work.set_process(false)
	camera=Camera3D.new();root.add_child(camera)
	var source:Array=work.original.duplicate(true)
	var reference_ids:Array=[]
	for item in work.reference.get_children():reference_ids.append(item.mesh.get_instance_id())
	check("reference keeps eight unchanged source bays",reference_ids.size()==8)
	check("model owns no camera or world environment",work.find_children("*","Camera3D",true,false).is_empty() and work.find_children("*","WorldEnvironment",true,false).is_empty())
	work.set_preset(0);await tick()
	var base:=positions()
	check("source is twelve repeated bays",work.rendered.size()==12)
	await shot("source",Vector3(-16,8,17),Vector3(0,2,-2))
	work.set_preset(1);await tick()
	check("curved court repeats eighteen bays",work.rendered.size()==18)
	var p:=Vector3(4,1,.5);var q:Vector3=work.warp(p)
	check("curve changes horizontal path and retains height",not q.is_equal_approx(p) and is_equal_approx(q.y,p.y))
	var r:float=work.count*work.L/(work.amount*TAU*.87)
	check("curved centreline has specified radius",is_equal_approx(Vector2(work.warp(Vector3(4,0,0)).x,work.warp(Vector3(4,0,0)).z-r).length(),r))
	work.amount=0;check("zero curve is identity",work.warp(p).is_equal_approx(p));work.set_preset(1)
	await shot("curve",Vector3(-15,10,19),Vector3(0,1.5,0))
	await shot("curve-inside",Vector3(0,1.7,1.0),Vector3(1,2,-3))
	work.set_preset(2);await tick()
	var seam:=0.0;var pivot:=Vector3(0,clampf((work.anchor.y+.4)*work.H/.9,0,work.H),0)
	for i in range(1,work.count):seam=maxf(seam,(work.joint_poses[i]*pivot).distance_to(work.joint_poses[i-1]*(Vector3(work.L,0,0)+pivot)))
	check("rigid folded bays share their selected hinge",seam<.0001)
	check("hinge transform preserves rigid lengths",work.joint_poses[-1].basis.is_equal_approx(work.joint_poses[-1].basis.orthonormalized()))
	await shot("hinge",Vector3(-16,8,18),Vector3(-2,4,-3))
	var before:Vector3=work.joint_poses[-1].origin
	work.anchor.y=-.4;work.rebuild()
	check("moving hinge changes arrangement without changing angle",before.distance_to(work.joint_poses[-1].origin)>1)
	await shot("hinge-floor",Vector3(-16,8,18),Vector3(-3,3,-3))
	work.set_preset(3);await tick()
	check("field is a bounded 108-bay array",work.rendered.size()==108)
	check("field instances share one mesh resource",work.rendered[0].mesh==work.rendered[-1].mesh)
	await shot("field",Vector3(-24,13,22),Vector3(0,3,-5))
	await shot("field-ground",Vector3(-14,1.75,3),Vector3(3,4,-7))
	work.set_preset(4);await tick()
	check("stretch leaves ground contact points unchanged",work.warp(Vector3(1,0,.3)).is_equal_approx(Vector3(1,0,.3)))
	check("stretch lifts local roof into a canopy",work.warp(Vector3(.8,work.H,0)).y>8)
	check("stretch influence vanishes outside its support",work.warp(Vector3(-10,work.H,0)).is_equal_approx(Vector3(-10,work.H,0)))
	var finite:=true
	for v in positions():finite=finite and v.is_finite()
	check("stretched positions remain finite",finite)
	var original_count:=0
	for group in work.original:original_count+=group.size()
	check("deformation retains triangle count",positions().size()==original_count*work.count)
	await shot("stretch",Vector3(-18,9,21),Vector3(1,4,-3))
	await shot("stretch-ground",Vector3(-7,1.75,5),Vector3(5,6,-3))
	var owner:=Node3D.new();root.add_child(owner);var from:Vector3=work.handle.global_position
	work.handle.pointer_event(XRToolsPointerEvent.new(XRToolsPointerEvent.Type.PRESSED,owner,work.handle,from,from))
	work.handle.pointer_event(XRToolsPointerEvent.new(XRToolsPointerEvent.Type.MOVED,owner,work.handle,from+Vector3(.2,.3,0),from));work._process(.1)
	check("desktop drag changes canopy anchor",work.anchor.is_equal_approx(Vector3(.2,.3,0)))
	work.handle.pointer_event(XRToolsPointerEvent.new(XRToolsPointerEvent.Type.RELEASED,owner,work.handle,from,from));owner.queue_free()
	var origin:=XROrigin3D.new();root.add_child(origin);var controller:=XRController3D.new();origin.add_child(controller)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();controller.add_child(pickup);controller.global_transform=work.handle.global_transform
	work.handle.pick_up(pickup);await tick();await tick()
	check("XRTools can grip the shared handle",work.handle.is_picked_up())
	controller.global_position+=Vector3(0,.1,0)
	for i in 6:await tick()
	work._process(.1);check("controller movement changes canopy anchor",work.anchor.y>.35)
	work.handle.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await tick()
	check("XR release preserves a frozen handle",work.handle.freeze and not work.handle.is_picked_up());origin.queue_free()
	work.handle.position=work.HOME+Vector3(50,50,50);work._process(.1)
	check("control limits bound the deformation",work.anchor.is_equal_approx(Vector3(.4,.5,.4)))
	work.panel.change_dial.set_normalized_value(.25);work.panel.count_dial.set_normalized_value(1);work.panel.change_dial.hinge_moved.emit(0.0);work._process(.1)
	check("native dials select amount and count",is_equal_approx(work.amount,.25) and work.count==24)
	work.set_preset(4)
	await shot("console",Vector3(0,2.0,10.6),Vector3(.25,1.05,8.8))
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=50;camera.position=Vector3(0,45,-3);camera.look_at(Vector3(0,0,-3),Vector3.FORWARD);camera.current=true
	await create_timer(.3).timeout;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT+"above.png"))
	var driver=load("res://commons/testing/wcn_desktop_driver.gd").new();room.add_child(driver);driver.spawn(Vector3(0,.03,10.1),room);await tick()
	await driver.press(work.panel.buttons["CURVE"],Vector3(0,.03,10.1));await tick()
	check("real desktop pointer activates curve",work.mode==1)
	await driver.press(work.panel.buttons["FIELD"],Vector3(0,.03,10.1));await tick()
	check("real desktop pointer activates field",work.mode==3)
	work.set_preset(0);check("reset reproduces source positions",positions()==base)
	var same:=true
	for i in source.size():same=same and source[i]==work.original[i]
	for i in reference_ids.size():same=same and reference_ids[i]==work.reference.get_child(i).mesh.get_instance_id()
	check("source record and reference meshes survive every operation",same)
	check("visual model has no stale collision shapes",work.body.find_children("*","CollisionObject3D",true,false).is_empty())
	await driver.teardown();await tick();await tick()
	var viewer:CharacterBody3D=room.spawn_viewer();await tick()
	check("F6 player preserves the courtyard daylight",not viewer.get_node("Head/PlayerHeldLight").darken_environment and not room.get_node("CourtyardEnvironment").environment.fog_enabled)
	var failed=checks.filter(func(c):return not c.passed)
	var f:=FileAccess.open(OUT+"report.json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failed":failed,"scope":"Native geometry and controls in a standalone museum courtyard. Simulated XR grip; no physical headset or Quest performance test. Architecture is visual, fixed courtyard supplies locomotion."},"\t"));f.close()
	quit(0 if failed.is_empty() else 1)
