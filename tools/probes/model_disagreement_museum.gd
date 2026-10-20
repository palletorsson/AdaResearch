extends "res://tools/probes/transformation_encounters.gd"
var map_origin:=Vector3.ZERO
func at(p:Vector3)->Vector3:return map_origin+hall.global_basis*p
func supported_clear(p:Vector3,shape:CapsuleShape3D)->bool:
	var foot:=at(p);var query:=PhysicsShapeQueryParameters3D.new()
	query.shape=shape;query.collision_mask=1|4;query.transform.origin=foot+Vector3.UP*.88
	var hits:=hall.get_world_3d().direct_space_state.intersect_shape(query,4);var floor:=floor_at(foot)
	return hits.is_empty() and not floor.is_empty() and absf(floor.position.y-foot.y)<.05
func old_gallery_route(shape:CapsuleShape3D)->Array[Vector3]:
	# Find the actual route around existing installations, not a straight line
	# through their colliders. Every returned edge is checked at 0.125m below.
	var start:=Vector2i(21,1);var goal:=Vector2i(6,56)
	var queue:Array[Vector2i]=[start];var visited:Dictionary={start:start};var cursor:=0
	while cursor<queue.size():
		var cell:=queue[cursor];cursor+=1
		if cell==goal:break
		for direction in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			var next:Vector2i=cell+direction
			if next.x<1 or next.x>40 or next.y<1 or next.y>59 or visited.has(next):continue
			var a:=Vector3(cell.x*.5,0,cell.y*.5);var b:=Vector3(next.x*.5,0,next.y*.5);var ok:=true
			for i in range(1,5):ok=ok and supported_clear(a.lerp(b,i/4.0),shape)
			if ok:visited[next]=cell;queue.append(next)
	var path:Array[Vector3]=[]
	if not visited.has(goal):return path
	var cell:=goal
	while cell!=start:path.push_front(Vector3(cell.x*.5,0,cell.y*.5));cell=visited[cell]
	path.push_front(Vector3(start.x*.5,0,start.y*.5));return path
func landing_checks()->void:
	museum.call("flush_stamps");await create_timer(.8).timeout
	var player=museum.get("_player")
	if player is Node3D:player.hide();player.set_process(false);player.set_physics_process(false);player.global_position=Vector3(0,-100,0)
	camera.set_cull_mask_value(19,false)
	var wardrobe=museum.get("_wardrobe")
	if wardrobe!=null and is_instance_valid(wardrobe.get("costume")):wardrobe.get("costume").hide()
	for child in museum.get_children():
		if child is Node3D and child.has_meta("em_map") and child!=hall:child.hide()
	var work:=find_scene("/model_disagreement/model_disagreement.gd")
	check("model study instantiated by the real museum",work!=null)
	if work==null:return
	map_origin=work.global_position-hall.global_basis*Vector3(28.5,0,45.5)
	observations.map_origin=xyz(map_origin);observations.work_world=xyz(work.global_position)
	var inventory:Array=[]
	for rec in museum.get("_edit_records"):
		var node=rec.get("node")
		if is_instance_valid(node) and hall.is_ancestor_of(node):inventory.append({"token":rec.get("token",""),"position":xyz(node.global_position-map_origin)})
	observations.inventory=inventory
	for token in ["shader_05_patterns","dark_sphere","film_shader_repeat","camera_glitch_study","reference_pattern_garden","model_disagreement"]:
		check("placed artifact retained: "+token,inventory.any(func(r):return str(r.token).begins_with(token)))
	check("actual map config reaches installed model",work.museum_installation and is_equal_approx(work.exhibit_scale,.35))
	check("only display is scaled; controls retain native size",work.scale.is_equal_approx(Vector3.ONE) and work.panel.scale==Vector3.ONE and work.body.scale.is_equal_approx(Vector3.ONE*.35))
	check("no browser renderer or camera in the artifact",work.find_children("*","Camera3D",true,false).is_empty() and work.find_children("*","SubViewport",true,false).is_empty())
	check("deforming mesh does not block the visitor",work.body.find_children("*","CollisionObject3D",true,false).is_empty())
	var portals=hall.get_node_or_null("HallPortals")
	check("installed hall has onward portal",portals!=null and portals.has_node("NextHall"))
	if portals!=null and portals.has_node("NextHall"):
		var exit=portals.get_node("NextHall")
		check("onward doorway uses the authored far exit",not exit.get_meta("authored_exit",{}).get("invalid",false))
	check("museum continues to Queer Materials",museum.call("_peek_next_authored_map")=="Shader_11_QueerRubber")
	var original:Array=work.original.duplicate(true)
	var driver=load("res://commons/testing/wcn_desktop_driver.gd").new();museum.add_child(driver)
	var stand:=work.to_global(Vector3(0,0,12.3));driver.spawn(stand,museum)
	# The supplied test rig's torch changes the global environment on ready.
	# Restore the museum's lighting for every comparison, rather than photograph
	# one state in its temporary fog and another after the rig is removed.
	var lamp=driver.rig.get_node("Head/PlayerHeldLight")
	lamp._restore_environment();lamp.darken_environment=false;lamp._light.hide();lamp.set_process(false)
	await tick()
	for i in 4:
		var id:String=["SOURCE","PRECISION","CLOCKS","FEEDBACK"][i]
		observations["pointer_"+id]=await driver.press(work.panel.buttons[id],stand);await tick()
		check("museum pointer selects "+id,work.mode==i)
		if i==1:check("real precision conversion changes vertices",work.error_max>.1 and work.collapsed>0)
		if i==2:check("part clocks retain declared age difference",is_equal_approx(work.samples[0]-work.samples[-1],3.4))
		if i==3:check("feedback retains its twenty-four passes",work.executed_passes==24)
		await snapshot(id.to_lower(),work.to_global(Vector3(9,2.0,9)),work.to_global(Vector3(4,2,-3)),65)
		if i>0:
			await driver.press(work.panel.buttons["CONTROL"],stand);await tick()
			check("museum pointer selects corrected control "+id,work.control)
			if i==1:check("local coordinate control has zero measured error",is_zero_approx(work.error_max))
			if i==2:check("clock control uses shared time",is_equal_approx(work.samples[0],work.samples[-1]))
			if i==3:check("feedback control reads source once",work.executed_passes==1)
			await snapshot(id.to_lower()+"-control",work.to_global(Vector3(9,2.0,9)),work.to_global(Vector3(4,2,-3)),65)
	await driver.press(work.panel.buttons["RESET"],stand);await tick()
	check("reset restores source through installed button",work.steps==0 and work.output==original and not work.control)
	await driver.press(work.panel.buttons["STEP"],stand);await tick();check("step advances installed model",work.steps==1)
	await driver.press(work.panel.buttons["PLAY / HOLD"],stand);await create_timer(.5).timeout
	check("play advances inside the museum",work.playing and work.steps>=2)
	await driver.press(work.panel.buttons["PLAY / HOLD"],stand);await tick()
	var held:int=work.steps;await create_timer(.4).timeout;check("hold stops the installed model",not work.playing and work.steps==held)
	driver.teardown();driver.queue_free();await tick()
	# Real XRTools pickup/hinge path with synthetic controller poses, no headset claim.
	var origin:=XROrigin3D.new();root.add_child(origin);var controller:=XRController3D.new();origin.add_child(controller)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();controller.add_child(pickup)
	work.select_mode(3)
	var joint:Node3D=work.panel.strength_dial.get_node("DialOrigin/InteractableHinge")
	var knob=joint.get_node("Handles/Handle1/InteractableHandle")
	controller.global_transform=knob.global_transform;knob.pick_up(pickup);await tick();await tick()
	controller.global_position=joint.global_position+(controller.global_position-joint.global_position).rotated(joint.global_basis.x.normalized(),-.75)
	for i in 6:await tick()
	check("XRTools grip rotates installed condition dial",knob.is_picked_up() and absf(work.amount-.65)>.05)
	knob.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await tick();await tick()
	check("installed dial releases",not knob.is_picked_up());origin.queue_free()
	var bounded:=true
	for mode in [1,2,3]:
		work.select_mode(mode)
		for amount in [0.0,.5,1.0]:
			work.set_amount(amount)
			for step in [0,16,32]:
				work.set_steps(step)
				for group in work.output:
					for p in group:
						var room_point:Vector3=hall.global_basis.inverse()*(work.body.to_global(p)-map_origin)
						bounded=bounded and room_point.x>1 and room_point.x<35 and room_point.z>31 and room_point.z<60 and room_point.is_finite()
	check("all sampled extremes stay inside gallery floor bounds",bounded)
	check("all museum operations preserve original data",work.original==original)
	# A supported capsule route links the existing gallery, controls and far exit.
	var shape:=CapsuleShape3D.new();shape.radius=.25;shape.height=1.7
	var inherited_route:=old_gallery_route(shape)
	check("existing entrance connects around earlier artifacts",not inherited_route.is_empty())
	observations.inherited_route=inherited_route.map(func(p):return xyz(p))
	var points:Array[Vector3]=[Vector3(3,0,28),Vector3(10.5,0,28),Vector3(10.5,0,32.5),Vector3(28.5,0,32.5),Vector3(28.5,0,33.2),Vector3(28.5,0,32.5),Vector3(3,0,32.5),Vector3(3,0,59),Vector3(18.5,0,59),Vector3(18.5,0,61.3)]
	var clear:=true;var count:=0;var failures_at:Array=[]
	for n in range(points.size()-1):
		var a:=points[n];var b:=points[n+1];var samples:=ceili(a.distance_to(b)/.2)
		for i in range(samples+1):
			var foot:=at(a.lerp(b,float(i)/samples));var query:=PhysicsShapeQueryParameters3D.new()
			query.shape=shape;query.collision_mask=1|4;query.transform.origin=foot+Vector3.UP*.88
			var hits:=hall.get_world_3d().direct_space_state.intersect_shape(query,4);var floor:=floor_at(foot)
			var ok:bool=hits.is_empty() and not floor.is_empty() and absf(floor.position.y-foot.y)<.05
			clear=clear and ok;count+=1
			if not ok and failures_at.size()<12:failures_at.append({"point":xyz(foot-map_origin),"hits":str(hits),"floor":str(floor)})
	observations.route_samples=count;observations.blocked=failures_at
	check("camera gallery to model console and far exit has supported clear route",clear)
	work.select_mode(3)
	await snapshot("console",work.to_global(Vector3(0,1.7,12.5)),work.panel.face.global_position,62)
	await snapshot("gallery",at(Vector3(5,4,33)),at(Vector3(23,2,47)),70)
	await snapshot("connection",at(Vector3(10.5,1.7,28)),at(Vector3(17,2,44)),75)
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=68
	camera.global_position=at(Vector3(18,62,31));camera.look_at(at(Vector3(18,0,31)),Vector3.FORWARD);camera.current=true
	await create_timer(.4).timeout;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(folder+"above.png"))
	observations.scope="Actual Endless Museum room loader, installed map token, real desktop pointer and synthetic XRTools grip; no physical headset test. Movement route sampled with supported capsule clearance."
