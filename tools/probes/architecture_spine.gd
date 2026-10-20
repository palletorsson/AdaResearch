extends SceneTree
const OUT="res://ada_run/architecture_spine/"
var checks:Array=[]
var work:Node3D
var camera:Camera3D
func _initialize()->void:run.call_deferred()
func check(label:String,passed:bool)->void:
	checks.append({"name":label,"passed":passed});print("[architecture] ","PASS " if passed else "FAIL ",label)
func tick()->void:
	await physics_frame;await process_frame
func shot(id:String,eye:Vector3,target:Vector3)->void:
	camera.global_position=eye;camera.look_at(target);camera.current=true
	await create_timer(.25).timeout;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT+id+".png"))
func seam_error()->float:
	var error:=0.0;var p:=Vector3(0,work.pivot_height,0)
	for i in range(1,work.COUNT):
		error=maxf(error,work.joints[i].to_global(p).distance_to(work.joints[i-1].to_global(Vector3(work.LENGTH,work.pivot_height,0))))
	return error
func run()->void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var room=load("res://commons/artifacts/architecture_spine/preview.tscn").instantiate();root.add_child(room);current_scene=room
	await tick();work=room.work;work.set_process(false)
	camera=Camera3D.new();camera.fov=56;root.add_child(camera)
	check("eight bays form one parent-child chain",work.joints.size()==8 and work.joints[7].get_parent()==work.joints[6])
	check("architecture owns no camera or environment",work.find_children("*","Camera3D",true,false).is_empty() and work.find_children("*","WorldEnvironment",true,false).is_empty())
	var rest:Array=[];var parts:Array=[]
	for j in work.joints:rest.append(j.global_transform)
	for m in work.original_meshes:parts.append([m.get_instance_id(),m.mesh.get_instance_id(),m.transform])
	var aligned:=true
	for i in 8:aligned=aligned and work.joints[i].position.is_equal_approx(Vector3.ZERO if i==0 else Vector3(work.LENGTH,0,0))
	check("rest pose is a straight repeated corridor",aligned and is_equal_approx(work.joints[7].global_position.x,3.6))
	check("floor hinges coincide at rest",seam_error()<.0001)
	await shot("passage",Vector3(-11,5.0,11.5),Vector3(0,2,-1.4))
	work.preset("FOLD");await tick()
	check("fold changes route into a vertical assembly",work.joints[7].global_position.y>5)
	check("floor hinge line stays joined while folding",seam_error()<.0001)
	var rigid:=true
	for j in work.joints:rigid=rigid and j.global_basis.is_equal_approx(j.global_basis.orthonormalized())
	check("folding alone preserves rigid bays",rigid)
	await shot("fold-floor",Vector3(-10.4,6.8,12),Vector3(-2,3.4,-1.6))
	var end_before:Vector3=work.joints[7].global_position
	work.set_pivot_height(work.HEIGHT);await tick()
	check("roof hinge line stays joined after moving centres",seam_error()<.0001)
	check("same angles with another centre produce another placement",work.joints[7].global_position.distance_to(end_before)>2)
	var floor_gap:float=work.joints[1].global_position.distance_to(work.joints[0].to_global(Vector3(work.LENGTH,0,0)))
	check("roof pivot exposes a gap at floor seam",floor_gap>.5)
	await shot("fold-roof",Vector3(-12,8,15),Vector3(-1,5,-1.6))
	await shot("hinge-detail",Vector3(-6,2.2,2.8),Vector3(-4.5,2.5,-2.2))
	work.preset("SLIP");await tick()
	check("explicit separation breaks shared hinge positions",seam_error()>.6)
	await shot("separated",Vector3(-11,6,12),Vector3(-.5,2.6,-1.4))
	work.preset("PASSAGE");work.ratio=.90;work.update_assembly();await tick()
	check("scale ratio compounds along hierarchy",is_equal_approx(work.joints[7].global_basis.get_scale().x,pow(.9,7)))
	check("scaling about shared hinges preserves their connection",seam_error()<.0001)
	await shot("diminishing",Vector3(-10,3.8,8.5),Vector3(-1.5,1.8,-1.4))
	var unchanged:=true
	for i in parts.size():
		var m=work.original_meshes[i];unchanged=unchanged and m.get_instance_id()==parts[i][0] and m.mesh.get_instance_id()==parts[i][1] and m.transform.is_equal_approx(parts[i][2])
	check("all states reuse original mesh parts and local transforms",unchanged)
	work.preset("RESET");await tick()
	var restored:=true
	for i in 8:restored=restored and work.joints[i].global_transform.is_equal_approx(rest[i])
	check("reset restores entire hierarchy",restored and work.separation==0 and work.ratio==1 and work.pivot_height==0)
	work.set_pivot_height(100);check("hinge height bounded to roof",work.pivot_height==work.HEIGHT)
	work.set_pivot_height(-10);check("hinge height bounded to floor",work.pivot_height==0)
	var owner:=Node3D.new();root.add_child(owner);var from:Vector3=work.handle.global_position
	work.handle.pointer_event(XRToolsPointerEvent.new(XRToolsPointerEvent.Type.PRESSED,owner,work.handle,from,from))
	work.handle.pointer_event(XRToolsPointerEvent.new(XRToolsPointerEvent.Type.MOVED,owner,work.handle,from+Vector3(0,.325,0),from));work._process(0)
	check("desktop handle moves shared centres halfway to roof",is_equal_approx(work.pivot_height,1.3))
	work.handle.pointer_event(XRToolsPointerEvent.new(XRToolsPointerEvent.Type.RELEASED,owner,work.handle,from,from))
	check("desktop release clears handle owner",work.handle.pointer_owner==null);owner.queue_free()
	var origin:=XROrigin3D.new();root.add_child(origin);var controller:=XRController3D.new();origin.add_child(controller)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();controller.add_child(pickup);controller.global_transform=work.handle.global_transform
	work.handle.pick_up(pickup);await tick();await tick()
	check("XRTools grip owns architecture handle",work.handle.is_picked_up())
	controller.global_position+=Vector3(0,.13,0)
	for i in 6:await tick()
	work._process(0);check("held controller changes hinge height",work.pivot_height>1.7)
	work.handle.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await tick()
	check("released handle stays in place",work.handle.freeze and not work.handle.is_picked_up());origin.queue_free()
	for dial in [work.panel.bend_dial,work.panel.gap_dial,work.panel.scale_dial]:dial.set_normalized_value(.5);dial.hinge_moved.emit(0.0)
	check("native dials set angle separation and scale",is_equal_approx(work.bend_degrees,5) and is_equal_approx(work.separation,.6) and is_equal_approx(work.ratio,.98))
	var driver=load("res://commons/testing/wcn_desktop_driver.gd").new();room.add_child(driver);var stand:=Vector3(0,.01,5.0);driver.spawn(stand,room);await tick()
	driver.aim_at(work.handle.global_position)
	check("actual desktop ray reaches handle",await driver.hover_target()==work.handle)
	await driver.press(work.panel.buttons["RESET"],stand);await tick()
	check("actual desktop button resets architecture",work.bend_degrees==0 and work.separation==0 and work.ratio==1 and work.pivot_height==0)
	await driver.press(work.panel.buttons["FOLD"],stand);await tick()
	check("actual desktop button folds corridor",work.bend_degrees==24)
	check("moving model has no stale static colliders",work.source.find_children("*","CollisionObject3D",true,false).is_empty())
	await shot("control",Vector3(.0,2.2,6),Vector3(-.2,1.08,3.65))
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=24
	camera.position=Vector3(0,24,0);camera.look_at(Vector3.ZERO,Vector3.FORWARD);camera.current=true
	await create_timer(.25).timeout;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT+"above.png"))
	var failed=checks.filter(func(c):return not c.passed)
	var f:=FileAccess.open(OUT+"report.json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failed":failed,"scope":"Standalone research room; rigid Node3D hierarchy, desktop controls and simulated XR pickup. Not walkable architecture, headset or structural physics."},"\t"));f.close()
	quit(0 if failed.is_empty() else 1)
