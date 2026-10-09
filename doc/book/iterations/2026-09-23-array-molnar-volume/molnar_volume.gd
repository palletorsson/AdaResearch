extends "res://tools/probes/transformation_encounters.gd"
const WalkStudy = preload("res://tools/probes/body_book_illustrations.gd")
var completed:=false
var study:Node3D

func press_button(index:int) -> void:
	var area:Node3D=study.buttons[index].get_node("InteractableAreaButton")
	XRToolsPointerEvent.pressed(camera,area,area.global_position)
	XRToolsPointerEvent.released(camera,area,area.global_position)
	await create_timer(0.12).timeout

func set_slider(axis:int,value:float) -> void:
	var slider:Node3D=study.sliders[axis]
	var current:float=slider.get_normalized_value()
	var at:=slider.global_position
	var to:=at+slider.global_basis.x*(value-current)*0.14
	slider.pointer_event(XRToolsPointerEvent.new(XRToolsPointerEvent.Type.PRESSED,camera,slider,at,at))
	slider.pointer_event(XRToolsPointerEvent.new(XRToolsPointerEvent.Type.MOVED,camera,slider,to,at))
	slider.pointer_event(XRToolsPointerEvent.new(XRToolsPointerEvent.Type.RELEASED,camera,slider,to,to))
	await create_timer(0.85).timeout
	check("pointer controls axis "+str(axis)+" value "+str(value),absf(study.amount[axis]-value)<0.002)

func shot(title:String,eye:Vector3,aim:Vector3,fov:=52.0) -> void:
	await snapshot(title,study.to_global(eye),study.to_global(aim),fov)

func landing_checks() -> void:
	study=find_scene("/molnar_cube_study.gd")
	check("new study loaded in the actual Array hall",study!=null)
	if study==null:return
	var actor:CharacterBody3D=museum.get("_player")
	actor.set_process(false);actor.set_physics_process(false);actor.global_position=Vector3(-100,0,-100)
	var original:Array=study.cells.duplicate(true)
	check("64 fixed indexed sites",study.cells.size()==64)
	check("256 nested cubes use one shared frame mesh",study.frames.multimesh.instance_count==256 and study.frames.multimesh.mesh.get_surface_count()==1)
	check("all four layers initially visible",study.depth_layers==4 and study.frames.multimesh.visible_instance_count==256)
	await shot("museum-first-view",Vector3(3.8,2.8,5.5),Vector3(0,1.45,0),56)
	await press_button(1);await create_timer(0.9).timeout
	check("RESET button restores zero transforms",study.amount.is_zero_approx())
	check("no animation work when resting",not study.is_processing())
	await press_button(0)
	check("DEPTH cycles from four to one layer",study.depth_layers==1 and study.frames.multimesh.visible_instance_count==64)
	await shot("one-layer-order",Vector3(0,1.85,5),Vector3(0,1.85,0),39)
	await set_slider(1,0.7)
	check("rotation control leaves translation and scale zero",is_zero_approx(study.amount.x) and is_zero_approx(study.amount.z))
	await shot("one-layer-rotation",Vector3(0,1.85,5),Vector3(0,1.85,0),39)
	await set_slider(0,0.7);await set_slider(2,0.6)
	await shot("one-layer-combined",Vector3(0,1.85,5),Vector3(0,1.85,0),39)
	for layer in [2,3,4]:
		await press_button(0)
		check("depth layer "+str(layer)+" updates geometry and readout",study.depth_layers==layer and study.frames.multimesh.visible_instance_count==layer*64 and study.count_label.text.begins_with(str(layer*16)))
	await shot("volume-combined",Vector3(3.7,2.9,4.7),Vector3(0,1.7,0),48)
	await shot("volume-close",Vector3(2.7,2.55,3.3),Vector3(0,1.95,0),50)
	await shot("controls",Vector3(0,1.45,3.15),Vector3(0,1.10,1.90),49)
	check("addresses and assigned departures survive every control",study.cells==original)
	var deterministic:Transform3D=study.frame_pose(5,1)
	await press_button(1);await create_timer(0.9).timeout
	check("all slider values reset",study.sliders.all(func(sl):return absf(sl.get_normalized_value())<0.001))
	await set_slider(0,0.7);await set_slider(1,0.7);await set_slider(2,0.6)
	check("same settings recover the same object",study.frame_pose(5,1).is_equal_approx(deterministic))
	check("transparent faces follow outer frame",study.glass[5].transform.is_equal_approx(study.frame_pose(5,0)) and study.glass[5].material_override.albedo_color.a<0.1)
	var ids:Dictionary={}
	var fixed:=true
	for i in study.cells.size():
		ids[str(study.cells[i].address)]=true
		fixed=fixed and study.sites.multimesh.get_instance_transform(i).origin.is_equal_approx(study.cells[i].home)
	check("all 64 addresses unique and marker positions fixed",ids.size()==64 and fixed)
	# Bound every corner at maximum slider amounts; no growing geometry goes through the plinth.
	study.amount=Vector3.ONE;study.target_amount=Vector3.ONE;study._refresh()
	var lowest:=INF;var extent:=0.0
	for i in study.cells.size():
		for shell in 4:
			var pose:Transform3D=study.frame_pose(i,shell)
			for x in [-0.504,0.504]:
				for y in [-0.504,0.504]:
					for z in [-0.504,0.504]:
						var v:=pose*Vector3(x,y,z);lowest=minf(lowest,v.y);extent=maxf(extent,maxf(absf(v.x),absf(v.z)))
	check("maximum departure stays above plinth",lowest>0.418)
	check("maximum departure stays inside plinth footprint",extent<1.5)
	observations["bounds"]={"lowest":lowest,"horizontal_half_extent":extent}
	# Walk around the actual plinth; stop short of the map exit.
	var driver:=WalkStudy.WalkInput.new();driver.actor=actor;root.add_child(driver)
	actor.global_position=study.to_global(Vector3(0,0.05,2.65));actor.velocity=Vector3.ZERO
	for local:Vector3 in [Vector3(2.2,0,2.65),Vector3(2.2,0,-2.2),Vector3(-2.2,0,-2.2),Vector3(-2.2,0,2.65),Vector3(0,0,2.65)]:
		driver.target=study.to_global(local);driver.arrived=false;driver.active=true
		var started:=Time.get_ticks_msec()
		while not driver.arrived and Time.get_ticks_msec()-started<8000:await process_frame
		driver.active=false
		var contacts:Array=[]
		for c in actor.get_slide_collision_count():
			var collision:KinematicCollision3D=actor.get_slide_collision(c)
			contacts.append({"collider":str(collision.get_collider().get_path()),"normal":xyz(collision.get_normal())})
		observations["walk "+str(local)]={"feet":xyz(study.to_local(actor.global_position)),"contacts":contacts}
		check("actual body walks around to "+str(local),driver.arrived and study.to_local(actor.global_position).y>0.025)
		if not driver.arrived:break
	observations["study_world"]=xyz(study.global_position)
	observations["controls_height"] = study.sliders.map(func(sl):return sl.global_position.y-study.global_position.y)
	observations["node_count"]=study.find_children("*","",true,false).size()
	completed=true

func finish() -> void:
	check("study completed",completed)
	var result:Dictionary={"room":map_id,"checks":checks,"failures":failures,"observations":observations,"passed":failures.is_empty(),"scope":"Actual isolated Array museum: new artifact placement, supplied pointer events, fixed addresses and deterministic transforms, bounded geometry and actual-body circuit around the plinth. No headset/learner claim."}
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	print("MOLNAR VOLUME ",checks.size()-failures.size(),"/",checks.size())
	quit(0 if failures.is_empty() else 1)
