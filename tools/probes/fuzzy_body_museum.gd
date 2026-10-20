extends "res://tools/probes/model_disagreement_museum.gd"

func landing_checks() -> void:
	await super.landing_checks()
	camera.projection=Camera3D.PROJECTION_PERSPECTIVE
	var work:=find_scene("/fuzzy_body/fuzzy_body.gd")
	check("fuzzy study instantiated by actual museum map",work!=null)
	if work==null:return
	var source:PackedVector3Array=work.original.duplicate()
	check("hand control inherits the earlier point class",work.point.get_script().resource_path=="res://commons/artifacts/golden_mapping_lesson/point_body.gd")
	check("generated sphere retains a nonempty triangle source",source.size()>1000 and source.size()%3==0)
	var mu:Vector3=work.degrees(0)
	check("independent sets overlap and need not sum to one",mu.x>.5 and is_equal_approx(mu.x,mu.y) and mu.x+mu.y>1)
	check("AND uses minimum",is_equal_approx(mu.z,minf(mu.x,mu.y)))
	check("far left belongs only to left set",work.degrees(-4).is_equal_approx(Vector3(1,0,0)))
	check("far right belongs only to right set",work.degrees(4).is_equal_approx(Vector3(0,1,0)))
	work.strength=1
	var p:=Vector3(.3,.4,.5)
	var expected:Vector3=(p*.2+Vector3(.3*.65,.4*2.1+.15,.5*.85))/1.2
	check("single left rule matches independently calculated lift",work.transformed(p,Vector3(1,0,0)).is_equal_approx(expected))
	work.strength=0;work.select_mode(1)
	check("zero strength is exact source",work.output==source)
	work.strength=.85;work.select_mode(0)
	check("field view uses original geometry",work.output==source)
	work.select_mode(1)
	check("rules change vertices",work.output!=source)
	work.place_point(0);work.select_mode(2);work.threshold=0;work.rebuild()
	check("zero threshold retains every triangle",work.selected_count==work.triangle_count)
	var counts:Array=[]
	for cut in [0.0,.2,.4,.6,.8,1.0]:
		work.threshold=cut;work.rebuild();counts.append(work.selected_count)
	var monotone:=true
	for i in range(1,counts.size()):monotone=monotone and counts[i]<=counts[i-1]
	check("higher threshold never adds faces",monotone)
	check("empty selection is explicit and valid",work.selected_count==0 and not work.surface.visible and work.surface.mesh==null)
	observations.fuzzy_threshold_counts=counts
	var bounded:=true;var ranges:=true
	for width in [.15,.95,1.8]:
		work.width=width
		for x in [-.88,0.0,.88]:
			work.place_point(x)
			for s in [0.0,1.0]:
				work.strength=s;work.select_mode(1)
				for i in work.output.size():
					var v:Vector3=work.surface.to_global(work.output[i]);var room:Vector3=hall.global_basis.inverse()*(v-map_origin)
					bounded=bounded and v.is_finite() and room.x>3 and room.x<14 and room.z>39 and room.z<45 and room.y>.64 and room.y<5.2
					var m:Vector3=work.memberships[i];ranges=ranges and m.x>=0 and m.x<=1 and m.y>=0 and m.y<=1 and m.z>=0 and m.z<=1
	check("all sampled deformations stay finite and inside their installation",bounded)
	check("membership remains in zero to one",ranges)
	check("all operations retain source data",work.original==source)
	work.width=.95;work.strength=.85;work.threshold=.5;work.place_point(0);work.select_mode(1)
	var driver=load("res://commons/testing/wcn_desktop_driver.gd").new();museum.add_child(driver)
	var stand:Vector3=work.to_global(Vector3(0,0,4.3));driver.spawn(stand,museum)
	var lamp=driver.rig.get_node("Head/PlayerHeldLight");lamp._restore_environment();lamp.darken_environment=false;lamp._light.hide();lamp.set_process(false)
	await tick()
	for i in 3:
		var id:String=["FIELDS","RULES","CUT"][i]
		observations["fuzzy_pointer_"+id]=await driver.press(work.panel.buttons[id],stand);await tick()
		check("pointer selects fuzzy view "+id,work.mode==i)
	for i in 3:
		var id:String=["LEFT","CENTRE","RIGHT"][i]
		observations["fuzzy_pointer_"+id]=await driver.press(work.panel.buttons[id],stand);await tick()
		observations["fuzzy_sample_"+id]=work.centre_x
		check("pointer places sample "+id,is_equal_approx(work.centre_x,(i-1)*.78*1.7))
		await create_timer(.15).timeout
		check("placed sample survives physics synchronization "+id,absf(work.point.position.x-(i-1)*.78)<.001 and absf(work.centre_x-(i-1)*.78*1.7)<.001)
	work.place_point(0)
	driver.rig.global_position=work.to_global(Vector3(1.15,0,4.35));await tick()
	driver.aim_at(work.point.global_position);await driver.hover_target();await driver.click(MOUSE_BUTTON_RIGHT);await tick()
	check("desktop right-click carries the black point",driver.pointer.get("_held")==work.point and work.point.held())
	driver.aim_at(work.to_global(work.HOME+Vector3(-.65,0,0)))
	await create_timer(.25).timeout
	check("desktop carry changes the sphere sample",work.centre_x<-.2)
	await driver.click(MOUSE_BUTTON_RIGHT);await create_timer(.1).timeout
	check("desktop right-click releases the point",not work.point.held())
	driver.teardown();driver.queue_free();await tick()
	var origin:=XROrigin3D.new();root.add_child(origin);var controller:=XRController3D.new();origin.add_child(controller)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();controller.add_child(pickup)
	work.place_point(0);work.select_mode(1)
	controller.global_transform=work.point.global_transform;work.point.pick_up(pickup);await tick();await tick()
	controller.global_position+=work.global_basis.x*.5
	for i in 8:await tick()
	check("XRTools grip moves the inherited point and rule sample",work.point.is_picked_up() and work.centre_x>.5)
	var held_x:float=work.centre_x;work.place_point(-.78);await tick()
	check("preset refuses to teleport a held point",absf(work.centre_x-held_x)<.02)
	work.point.let_go(pickup,Vector3.ZERO,Vector3.ZERO)
	await create_timer(.15).timeout
	check("released point parks on its guide",not work.point.is_picked_up() and absf(work.point.position.y-work.HOME.y)<.01 and absf(work.point.position.z-work.HOME.z)<.01)
	check("point is within reach at the console",work.point.position.distance_to(Vector3(0,1.4,4.3))<1.1)
	for pair in [[work.panel.width_dial,"width"],[work.panel.force_dial,"strength"],[work.panel.cut_dial,"threshold"]]:
		var dial:Node3D=pair[0];var key:String=pair[1];var before:float=work.get(key)
		var joint:Node3D=dial.get_node("DialOrigin/InteractableHinge");var knob=joint.get_node("Handles/Handle1/InteractableHandle")
		controller.global_transform=knob.global_transform;knob.pick_up(pickup);await tick();await tick()
		controller.global_position=joint.global_position+(controller.global_position-joint.global_position).rotated(joint.global_basis.x.normalized(),-.65)
		for i in 6:await tick()
		check("XRTools hand turns fuzzy "+key,knob.is_picked_up() and absf(float(work.get(key))-before)>.035)
		knob.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await tick();await tick()
	origin.queue_free()
	var shape:=CapsuleShape3D.new();shape.radius=.25;shape.height=1.7
	var route:Array[Vector3]=[Vector3(3,0,32.5),Vector3(8.5,0,32.5),Vector3(8.5,0,36.1),Vector3(11,0,36.1),Vector3(11,0,38.4),Vector3(13,0,38.4),Vector3(13,0,46),Vector3(3,0,46),Vector3(3,0,59)]
	var clear:=true;var samples:=0;var blocked:Array=[]
	for i in range(route.size()-1):
		var a:=route[i];var b:=route[i+1];var n:=ceili(a.distance_to(b)/.15)
		for k in range(n+1):
			var q:=a.lerp(b,float(k)/n);var ok:=supported_clear(q,shape);clear=clear and ok;samples+=1
			if not ok and blocked.size()<12:blocked.append(xyz(q))
	check("new controls and both sides have supported capsule access",clear)
	observations.fuzzy_route_samples=samples;observations.fuzzy_blocked=blocked
	work.width=.95;work.strength=.85;work.threshold=.5;work.place_point(0);work.select_mode(1)
	await create_timer(.15).timeout
	check("comparison photographs begin at centred sample",absf(work.centre_x)<.001 and absf(work.point.position.x)<.001)
	var eye:Vector3=work.to_global(Vector3(-4.6,2.8,6.7));var target:Vector3=work.to_global(Vector3(0,3,-1))
	await snapshot("fuzzy-rules",eye,target,55)
	work.select_mode(0);await snapshot("fuzzy-fields",eye,target,55)
	work.select_mode(2);await snapshot("fuzzy-cut",eye,target,55)
	work.threshold=.68;work.sync_controls();work.rebuild();await snapshot("fuzzy-cut-high",eye,target,55)
	work.select_mode(1);work.place_point(-.78);await snapshot("fuzzy-left",eye,target,55)
	work.place_point(.78);await snapshot("fuzzy-right",eye,target,55)
	work.place_point(0);work.width=.15;work.sync_controls();work.rebuild();await snapshot("fuzzy-narrow",eye,target,55)
	work.width=1.8;work.sync_controls();work.rebuild();await snapshot("fuzzy-wide",eye,target,55)
	work.width=.95;work.threshold=.5;work.sync_controls();work.rebuild()
	await snapshot("fuzzy-console",work.to_global(Vector3(0,1.75,4.6)),work.panel.face.global_position,60)
	await snapshot("fuzzy-hand",work.to_global(Vector3(1.3,1.7,4.8)),work.to_global(work.HOME),50)
	await snapshot("fuzzy-hall",at(Vector3(17,4.5,33)),at(Vector3(16,2.8,46)),75)
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=40
	camera.global_position=at(Vector3(18,48,45));camera.look_at(at(Vector3(18,0,45)),Vector3.FORWARD);camera.current=true
	await create_timer(.4).timeout;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(folder+"fuzzy-above.png"))
	observations.fuzzy={"triangles":work.triangle_count,"source_preserved":work.original==source,"cell":[8,40],"scope":"Native Godot museum. Real supplied desktop pointer events; synthetic XRTools grip poses. No physical headset or Quest performance test. CUT selects whole triangles at their source centroids; it is not a smooth watertight solid."}
