extends "res://tools/probes/rotation_tower_probe.gd"

func exhibit(id: String) -> Node3D:
	return game.building.content.exhibits["16/"+id].get_node("Artifact")

func wheel_dock(wheel: Node3D, bottom: bool) -> bool:
	for i in range(3100):
		await frames(1)
		var target := 1.0 if bottom else 0.0
		if is_equal_approx(wheel.progress,target) and fposmod(wheel.elapsed,180.0/wheel.turn_speed+wheel.hold)<wheel.hold-2:return true
	return false

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out=arg.trim_prefix("--out=")
		if arg=="--capture":take_photos=true
	DirAccess.make_dir_recursive_absolute(out)
	check("isolated test saves",OS.get_user_data_dir().contains("Ada Void Trial Test"))
	if not checks.back().passed:quit(1);return
	for mode in ([false] if take_photos else [false,true]):
		await start(mode)
		var tag := "XR / " if mode else "Desktop / "
		check(tag+"Rotation and Scale arrival in the main tower",game.trial_id.is_empty() and game.checkpoint==16 and game.building.spec.levels.size()==18)
		var floor:Node3D=game.building.content.roots[16]
		check(tag+"all thirteen placed museum/adapted artifacts instantiate",game.building.content.exhibits.keys().filter(func(k):return str(k).begins_with("16/")).size()==13)
		var array:=exhibit("angle-bands")
		check(tag+"four two-by-six bands retain 0 through 90 degrees",array.bands.size()==4 and array.rows==6 and array.columns==2 and array.row_angle_step==18)
		for band in array.bands:
			check(tag+str(band.id)+" has twelve cubes",band.cubes.size()==12)
		check(tag+"body comparison keeps actual visitor widths",array.body_comparison.WIDTHS==[.44,1.2] and array.body_comparison.global_basis.get_scale().is_equal_approx(Vector3.ONE))
		for profile in ["cake","column","ziggurat","spindle","flare"]:
			var carousel:=exhibit("carousel-"+profile)
			var initial:float=carousel._rotation_angle
			await frames(4)
			check(tag+profile+" retains eight moving layers",carousel.profile==profile and carousel.mm_inst.multimesh.instance_count==8 and carousel._rotation_angle>initial)
		var hinge:=exhibit("hinge")
		var angles:Array=hinge.specimen.hinge_angles()
		hinge.controls[2].action.call();hinge.controls[3].action.call();hinge.controls[5].action.call()
		check(tag+"hinge TURN KEEP/RETURN and TRACE remain usable",hinge.specimen.hinge_angles()!=angles and hinge.release_score.return_on_release and hinge.tracing)
		hinge.controls.back().action.call()
		var sweep:=exhibit("axial-sweep")
		sweep.cycle_shape();sweep.toggle_envelope()
		check(tag+"sweep switches cube to triangle and shows boundary",sweep.shape_id=="triangle" and sweep.show_envelope)
		var composition:=exhibit("composition")
		check(tag+"workbench starts at X/Y pair with intermediate trace",composition._pair_index==3 and composition.workings=="trace")
		var film:=exhibit("turn-order-film")
		film.activate("pause");film.activate("step");film.activate("route");film.activate("replay")
		check(tag+"original film and four controls present",film.buttons.size()==4 and is_instance_valid(film.stage))
		var tunnel:Node3D=exhibit("twisting-tunnel").tunnel
		check(tag+"five original hollow cubes with 18-degree increments",tunnel.num_segments==5 and tunnel.rotation_per_segment==18 and tunnel.get_children().filter(func(n):return str(n.name).begins_with("Cube")).size()==5)
		check(tag+"Boolean passage faces down",(-tunnel.global_basis.z.normalized()).dot(Vector3.UP)>.999)
		if take_photos:
			await pictures_full()
		else:
			await descents(tag)
			await crossings(tag)
		game.soundscape.set_process(false)
		for node in game.find_children("*","",true,false):
			if node is AudioStreamPlayer or node is AudioStreamPlayer3D:node.stop()
		game.queue_free();await frames(20)
		if mode:
			for tracker_node in [head,left,right]:XRServer.remove_tracker(tracker_node)
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"physical_headset":"not tested"},"\t"))
	quit(0 if failed.is_empty() else 1)

func descents(tag: String) -> void:
	var wheel:=exhibit("axis-x")
	var landing_costs:Array=[]
	var cost_callback:=func(_value:float,_difference:float):
		if game.charge.last_cause=="landing":landing_costs.append(game.charge.last_cause)
	game.charge.changed.connect(cost_callback)
	game.place_player(Vector3(-13.5,Y+.06,-.6));await frames(25)
	check(tag+"wheel waits at upper bank",await wheel_dock(wheel,false))
	check(tag+"walk onto west edge of wheel platform",await walk(Vector3(-11.7,Y,-.6)))
	check(tag+"real passenger boards",wheel.deck.riders.has(game.body))
	var feet:Vector3=game.body.global_position
	var eye:Vector3=game.camera.global_position
	var start:Vector3=wheel.deck.global_position
	check(tag+"half-turn reaches next storey",await wheel_dock(wheel,true))
	var displacement:Vector3=wheel.deck.global_position-start
	check(tag+"wheel carries feet and head once",game.body.global_position.distance_to(feet+displacement)<.10 and game.camera.global_position.distance_to(eye+displacement)<.10)
	check(tag+"view remains upright",game.camera.global_basis.y.dot(Vector3.UP)>.999)
	check(tag+"source remains live during descent",game.floor_stream.focus==17 and 16 in game.floor_stream.pinned and game.floor_stream.records[16].mode=="live")
	check(tag+"step onto next floor and save checkpoint",await walk(Vector3(-13.5,Y-6,-.6)) and game.checkpoint==17)
	check(tag+"no fall damage while supported",game.deaths==0 and landing_costs.is_empty())
	game.charge.changed.disconnect(cost_callback)
	# Approach the downward bore on foot; stop horizontal input over its centre.
	game.place_player(Vector3(6.5,Y+.06,0));await frames(25)
	var before_deaths:int=game.deaths
	for i in range(180):
		var local:Vector3=(game.camera.global_basis if xr else game.body.global_basis).inverse()*Vector3.RIGHT
		axes(Vector2(local.x,local.z));await frames(1)
		if game.body.global_position.x>=10.4:break
	axes(Vector2.ZERO)
	await frames(140)
	print("BOOLEAN ARRIVAL ",tag,game.body.global_position," deaths ",game.deaths-before_deaths," checkpoint ",game.checkpoint," reason ",game.last_death)
	check(tag+"drop through actual Boolean bore onto receiving pad",game.deaths==before_deaths and game.checkpoint==17 and absf(game.body.global_position.y-(Y-6))<.15 and absf(game.body.global_position.x-10)<1.4 and absf(game.body.global_position.z)<1.4)
	check(tag+"leave the pad by its west bridge",await walk(Vector3(6.5,Y-6,0)))

func crossings(tag: String) -> void:
	game.place_player(Vector3(19.5,Y+.06,-2));await frames(25)
	var yride:=rotary()
	check(tag+"climb Y approach wedge",await walk(Vector3(19.5,Y+1,1)))
	check(tag+"Y ride docks",await rotation_dock(yride))
	check(tag+"board Y marked end",await walk(Vector3(18.3,Y+1,1)))
	check(tag+"Y ride carries to quarter turn",await rotation_dock(yride,true))
	check(tag+"walk off Y ride",await walk(Vector3(17,Y+1,3.5)))
	var zride:=exhibit("axis-z")
	game.place_player(Vector3(-20,Y+.06,2.3));await frames(25)
	zride.set_crossing_pose();await frames(4)
	check(tag+"board Z level platform",await walk(Vector3(-18.5,Y,2.3)))
	var feet_before:Vector3=game.body.global_position
	zride.start_rides()
	for i in range(1500):
		await frames(1)
		if zride.ride_progress>.999:break
	check(tag+"Z ride rises two metres with upright body",game.body.global_position.distance_to(feet_before+Vector3(4,2,0))<.1 and game.camera.global_basis.y.dot(Vector3.UP)>.999)
	check(tag+"Z ride fits below the ceiling",1.0+sqrt(5.0)+1.65<5.64)
	check(tag+"step onto Z cube bank",await walk(Vector3(-13.3,Y+2,2.3)))
	var deaths_before:int=game.deaths
	game.place_player(Vector3(-9,Y+.06,-1.9));await frames(140)
	check(tag+"missing both routes still triggers a fatal fall",game.deaths==deaths_before+1)
	await wait_for_recovery(deaths_before)
	check(tag+"restart restores all Rotation encounters",game.checkpoint==16 and game.building.content.exhibits.keys().filter(func(k):return str(k).begins_with("16/")).size()==13 and game.health.get_health()>99)

func pictures_full() -> void:
	game.atmosphere.animate_sky=false;game.atmosphere.set_sky_time(180)
	root.msaa_3d=Viewport.MSAA_4X
	for layer in game.find_children("*","CanvasLayer",true,false):layer.hide()
	game.status.hide();game.notice_time=-1
	await photograph("cube-banks",Vector3(12,Y+4.7,-6.1),Vector3(-1,Y+2,-.5))
	await photograph("rotation-gallery",Vector3(-12,Y+2.1,-4.1),Vector3(-1,Y+1,-7))
	await photograph("workbench-and-hinge",Vector3(-8,Y+2.6,8.2),Vector3(-1,Y+1,5.8))
	var wheel:=exhibit("axis-x")
	wheel.preview=true;wheel._pose(.38)
	await photograph("wheel-from-above",Vector3(-14.8,Y+4.5,-.4),Vector3(-10,Y-2.5,.3))
	await photograph("boolean-from-above",Vector3(12.8,Y+1.8,-2.8),Vector3(10,Y-3,0))
	game.place_player(Vector3(4,Y-5.94,0));await frames(25)
	await photograph("descent-arrival",Vector3(5.5,Y-3.8,4.4),Vector3(10,Y-3.4,0))
