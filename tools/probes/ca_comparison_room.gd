extends "res://tools/probes/transformation_encounters.gd"
func landing_checks() -> void:
	museum.call("flush_stamps");await create_timer(.7).timeout
	var stream=museum.get("_portal_stream")
	if stream!=null:stream.set_process(false);stream.set_physics_process(false)
	var player=museum.get("_player")
	if player is Node3D:player.hide();player.set_process(false);player.set_physics_process(false);player.global_position=Vector3(0,-100,0)
	var old=museum.get("_cam")
	if old is Node3D:old.hide()
	camera.set_cull_mask_value(19,false)
	var wardrobe=museum.get("_wardrobe")
	if wardrobe!=null and is_instance_valid(wardrobe.get("costume")):wardrobe.get("costume").hide()
	for child in museum.get_children():
		if child is Node3D and child.has_meta("em_map") and child!=hall:child.hide()
	var work:=find_scene("/ca_rule_explorer.gd");var pyramid:=find_scene("/SierpinskiPyramid.gd")
	check("Installed explorer and pyramid found",work!=null and pyramid!=null)
	if work==null or pyramid==null:return
	work.auto_run=false;work.rule=90;work.seed_pair=false;work._reset()
	for i in 15:work.step()
	await tick();await create_timer(.2).timeout
	observations["work_local"]=xyz(hall.to_local(work.global_position));observations["pyramid_local"]=xyz(hall.to_local(pyramid.global_position))
	var inventory:Array=[]
	for item in hall.find_children("*","Node3D",true,false):
		if item.has_meta("artifact_lookup_name"):inventory.append({"key":item.get_meta("artifact_lookup_name"),"local":xyz(hall.to_local(item.global_position))})
	observations["inventory"]=inventory
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=29;camera.global_position=hall.to_global(Vector3(6.5,40,13));camera.look_at(hall.to_global(Vector3(6.5,0,13)),Vector3.FORWARD);camera.current=true
	await create_timer(.4).timeout;await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(ProjectSettings.globalize_path(folder+"overhead.png"))
	await snapshot("raised-oblique",hall.to_global(Vector3(28,30,34)),hall.to_global(Vector3(6.5,0,13)),58)
	camera.projection=Camera3D.PROJECTION_PERSPECTIVE
	await snapshot("entry",hall.to_global(Vector3(6.5,1.65,4.5)),hall.to_global(Vector3(7.2,1.3,14)),84)
	await snapshot("comparison",hall.to_global(Vector3(5.2,2.15,9.4)),hall.to_global(Vector3(8,1.2,15)),88)
	await snapshot("rear",hall.to_global(Vector3(6.5,1.65,17.8)),hall.to_global(Vector3(6.5,1.3,21.5)),80)
	if not folder.contains("/before/"):
		await interaction_checks(work,pyramid)
		check_routes()
		var learner=load("res://doc/book/iterations/2026-10-08-ca-two-ways-to-make/printed/comparison.gd").new();hall.add_child(learner);learner.position=Vector3(3.7,0,18.5);learner.rotation.y=PI
		for i in 15:learner.step()
		await tick();await snapshot("printed-study",learner.to_global(Vector3(-.1,2.7,3.2)),learner.to_global(Vector3(-.35,1.25,0)),68)
		learner.queue_free()
	observations["scope"]="Native museum above/inside; hidden player/neighbour halls for capture. No headset."

func interaction_checks(work:Node3D,pyramid:Node3D) -> void:
	var captions:=PackedStringArray()
	for label in hall.find_children("*","Label3D",true,false):captions.append(label.text)
	var all_text:=" ".join(captions).replace("\n"," ")
	check("Pyramid wall caption names its six-call configuration",all_text.contains("Six placements repeat") and not all_text.contains("Five copies of yourself"))
	check("Explorer wall caption follows the installed seed comparison",all_text.contains("Change the seed.") and all_text.contains("pyramid stays fixed"))
	var study=work.get_node("NeighbourStudy");var receiver:Node3D=study.floor_history;var hand=study.get_node_or_null("HandPoint")
	check("Comparison mounts existing carried inspector",hand!=null and hand.point!=null)
	var cubes:Array=[]
	for child in pyramid.get_children():
		if child is Node3D and not child.get_meta("pyramid_study",false):cubes.append(child.transform)
	check("Installed depth4 recipe retains1296 cube instances",pyramid.depth==4 and cubes.size()==1296)
	var state:Array=work._grid.duplicate(true);state.reverse()
	check("Floor reads exact chronological desk history",receiver.rendered==state)
	var colour_error:=0.0;var transforms:=true
	for y in 24:
		for x in 32:
			var xf:Transform3D=receiver.cells.get_instance_transform(y*32+x)
			if y<state.size():
				var expected:Color=work.alive_color if state[y][x] else work.dead_color
				var actual:Color=receiver.cells.get_instance_color(y*32+x)
				colour_error=maxf(colour_error,maxf(absf(actual.r-expected.r),maxf(absf(actual.g-expected.g),absf(actual.b-expected.b))))
				transforms=transforms and xf.origin.is_equal_approx(receiver.at(x,y)) and xf.basis.is_equal_approx(Basis.IDENTITY)
			else:transforms=transforms and is_zero_approx(xf.basis.determinant())
	observations["maximum_colour_channel_error"]=colour_error
	check("All recorded floor colours agree within one8bit channel step",colour_error<=1.0/255.0)
	check("Only recorded rows occupy the fixed floor addresses",transforms)
	work.step();study.refresh();check("Rule90 reaches an empty row at generation16",work.generation==16 and work._current_row.count(true)==0)
	work.seed_pair=false;work._reset();study.refresh()
	var origin:=XROrigin3D.new();root.add_child(origin);var controller:=XRController3D.new();origin.add_child(controller)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();controller.add_child(pickup)
	controller.global_position=hand.point.global_position;hand.point.pick_up(pickup);await tick();await tick()
	controller.global_position=hand.to_global(Vector3((15.5/32.0-.5)*work.board_size,.2,1.45));await tick();await tick();study.refresh()
	check("Held inspector chooses address15 without changing row",hand.point.held() and work.sample_cell==15 and work.generation==0 and work._current_row[16])
	check("Readout predicts the next occupied cell from differing neighbours",work.neighbourhood_readback().next==1 and study.reading.text.contains("NEXT: 1"))
	await snapshot("point-inspector",work.to_global(Vector3(-1.0,1.0,3.2)),work.to_global(Vector3(.4,.1,.35)),68)
	hand.point.action();await tick();study.refresh();check("Held trigger advances once and pauses the actual explorer",work.generation==1 and not work.auto_run and work._current_row[15] and work._current_row[17])
	hand.point.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await tick();await tick()
	check("Released point parks at selected address without stepping",not hand.point.held() and work.generation==1 and hand.point.position.is_equal_approx(Vector3((15.5/32.0-.5)*work.board_size,.2,1.45)))
	origin.queue_free();await tick()
	var seed_button=study.get_node("StudyControls").find_child("Btn_2",true,false).get_node("InteractableAreaButton")
	seed_button.button_pressed.emit(seed_button)
	check("Installed SEED control resets to adjacent pair",work.seed_pair and work.generation==0 and work._current_row.count(true)==2)
	var step_button=study.get_node("StudyControls").find_child("Btn_0",true,false).get_node("InteractableAreaButton")
	step_button.button_pressed.emit(step_button)
	check("Installed STEP control advances pair to four cells",work.generation==1 and work._current_row.count(true)==4)
	var unchanged:=true;var i:=0
	for child in pyramid.get_children():
		if child is Node3D and not child.get_meta("pyramid_study",false):unchanged=unchanged and child.transform==cubes[i];i+=1
	check("Point and seed actions leave every installed cube transform unchanged",unchanged and i==1296)
	work.seed_pair=false;work._reset()
	for gen in 30:work.step()
	study.refresh();state=work._grid.duplicate(true);state.reverse()
	check("Installed floor scrolls last24 rows and names range7to30",receiver.rendered==state and receiver.rendered.size()==24 and receiver.caption.text.contains("7–30"))
	work._reset();study.refresh();check("Replay clears history and receiver together",work.generation==0 and receiver.rendered.size()==1)
	for gen in 15:work.step()
	study.refresh()
	var walker:=CharacterBody3D.new();hall.add_child(walker)
	var shape:=CollisionShape3D.new();var capsule:=CapsuleShape3D.new();capsule.radius=.28;capsule.height=1.7;shape.shape=capsule;shape.position.y=.88;walker.add_child(shape)
	var start:Vector3=receiver.to_global(receiver.at(16,3));walker.global_position=Vector3(start.x,hall.global_position.y+.05,start.z)
	for frame in 160:
		await physics_frame;walker.velocity.x=0;walker.velocity.z=1;walker.velocity.y-=9.8/60;walker.move_and_slide()
	var ending:Vector3=hall.to_local(walker.global_position)
	check("A body walks across dark history cells on solid museum floor",walker.is_on_floor() and ending.z>hall.to_local(start).z+2.4 and absf(ending.y)<.08)
	check("Walking over image does not advance or edit history",work.generation==15 and receiver.rendered.size()==16)
	observations["body_end"]=xyz(ending);walker.queue_free();await tick()
	await snapshot("floor-and-pyramid",hall.to_global(Vector3(4.5,2.2,10.0)),hall.to_global(Vector3(8.5,1.3,15.9)),83)

func check_routes() -> void:
	var routes:Dictionary={
		"entry_to_point":[Vector2(6.5,4.5),Vector2(6.5,6.7),Vector2(3.5,6.7),Vector2(3.5,7.7)],
		"desk_to_history":[Vector2(3.5,7.7),Vector2(5.3,7.7),Vector2(5.3,11.5),Vector2(6.5,13.6)],
		"history_to_pyramid":[Vector2(6.5,13.6),Vector2(6.5,16.5)],
		"pyramid_to_exit":[Vector2(6.5,16.5),Vector2(6.5,21.2)]}
	var shape:=CapsuleShape3D.new();shape.radius=.28;shape.height=1.7;var results:Dictionary={}
	for label in routes:
		var points:Array=routes[label];var blocked:Array=[];var unsupported:Array=[];var samples:=0
		for i in range(1,points.size()):
			var a:Vector2=points[i-1];var b:Vector2=points[i];var count:=ceili(a.distance_to(b)/.15)
			for j in range(count+1):
				var p:=a.lerp(b,float(j)/count);var foot:=hall.to_global(Vector3(p.x,0,p.y))
				var query:=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.collision_mask=1;query.transform=Transform3D(Basis.IDENTITY,foot+Vector3.UP*.88)
				var hits:=hall.get_world_3d().direct_space_state.intersect_shape(query,8)
				if not hits.is_empty():blocked.append({"at":[p.x,p.y],"node":str(hits[0].collider.get_path())})
				var ground:=floor_at(foot)
				if ground.is_empty() or absf(ground.position.y-foot.y)>.03:unsupported.append([p.x,p.y])
				samples+=1
		results[label]={"samples":samples,"blocked":blocked,"unsupported":unsupported}
		check(label+": capsule clearance",blocked.is_empty());check(label+": continuous level floor",unsupported.is_empty())
	observations["routes"]=results
	var stream=museum.get("_portal_stream")
	check("Entry frame has supported approach",not stream.get("_entry").is_empty() and not stream.get("_entry").get("invalid",false))
	check("Exit frame has supported approach",not stream.get("_exit").is_empty() and not stream.get("_exit").get("invalid",false))
func finish() -> void:
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"observations":observations},"  "))
	print("CA COMPARISON ROOM ",checks.size()-failures.size(),"/",checks.size());quit(0 if failures.is_empty() else 1)
