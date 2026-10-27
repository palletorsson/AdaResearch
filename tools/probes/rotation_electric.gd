extends "res://tools/probes/transformation_tower_probe.gd"
## Actual desktop and synthetic-XR lift, live-material death and checkpoint return.
const Y := -96.0
var observations:Dictionary={}

func artifact(id:String) -> Node3D:
	return game.building.content.exhibits["16/"+id].get_node("Artifact")

func wait_lift(platform:Node3D,top:bool) -> bool:
	for i in range(900):
		await frames(1)
		var target:Vector3=platform.target_position if top else platform.initial_position
		if platform.global_position.distance_to(target)<.01:
			if top and not platform.is_moving:return true
			if not top and platform.waiting_to_start and platform.start_timer>1.25:return true
	return false

func picture(name:String,at:Vector3,target:Vector3) -> void:
	var camera=Camera3D.new();camera.fov=72;game.add_child(camera);camera.current=true
	camera.global_position=at+Vector3.UP*Y;camera.look_at(target+Vector3.UP*Y)
	await frames(4);await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(name+".png"))
	camera.queue_free();game.camera.current=true

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out=arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(out)
	Source.use_main_tower=true;root.size=Vector2i(1600,1000)
	for mode in [false,true]:
		await start(mode)
		var tag:String="XR / " if mode else "Desktop / "
		check(tag+"main tower floor 16",game.trial_id.is_empty() and game.checkpoint==16)
		var control=artifact("angle-bands");var wide=artifact("z-wide")
		var narrow:Dictionary=control.bands.filter(func(b):return b.id=="Z")[0]
		check(tag+"one metre cubes and one metre pitch on both courses",control.cube_edge==1.0 and wide.cube_edge==1.0 and control.cube_pitch==1.0 and wide.cube_pitch==1.0)
		check(tag+"single and double retain six angles and 18 degree steps",control.rows==6 and wide.rows==6 and control.row_angle_step==18 and wide.row_angle_step==18 and narrow.cubes.size()==6 and wide.bands[0].cubes.size()==12)
		for row in range(6):
			var single:Node3D=narrow.cubes[row]
			for column in range(2):
				var cube:Node3D=wide.bands[0].cubes[row*2+column]
				check(tag+"row %d col %d exact one metre mesh/collider and angle" % [row,column],cube.get_child(0).mesh.size.is_equal_approx(Vector3.ONE) and cube.get_node("Body").get_child(0).shape.size.is_equal_approx(Vector3.ONE) and cube.global_basis.is_equal_approx(single.global_basis))
		for course in [narrow,wide.bands[0]]:
			var cube:Node3D=course.cubes[0]
			game.place_player(Vector3(cube.global_position.x,Y+3.56,cube.global_position.z));await frames(35)
			check(tag+course.id+" upper cubes stay safe",game.deaths==0 and game.health.get_health()>98 and game.body.is_on_floor())
		# Settle tracking outside the sheet before entering naturally. A direct
		# relocation from the high course can briefly put the head into it.
		game.place_player(Vector3(-4,Y+.05,-4.5));await frames(50)
		check(tag+"walk beneath the bed without a proximity kill",await move_to(Vector3(0,Y,-4.5),false,360) and game.deaths==0)
		game.place_player(Vector3(0,Y+2.65,-4.5))
		for i in range(120):
			await frames(1)
			if game.deaths>0:break
		check(tag+"real electric contact triggers death",game.deaths==1 and game.last_death=="Electrocuted under the rotation cubes")
		await frames(110)
		check(tag+"normal recovery returns to floor 16 with charge",not game.recovering and game.checkpoint==16 and game.health.get_health()>95 and absf(game.body.global_position.y-Y)<.2)
		var lift=artifact("gantry-tc");var platform=lift.platform
		check(tag+"tc source and original carry driver reused",lift.get_meta("source_utility")=="tc" and platform.get_script().get_base_script().resource_path.ends_with("transport_cube.gd"))
		game.place_player(Vector3(-9.6,Y+.05,4.5));await frames(25)
		check(tag+"tc returns for boarding",await wait_lift(platform,false))
		check(tag+"walk onto tc at the lower dock",await move_to(Vector3(-8,Y,4.5),false,150))
		for i in range(20):
			await frames(1)
			if platform.carried_player==game.body:break
		check(tag+"actual passenger attached",platform.carried_player==game.body)
		var feet:Vector3=game.body.global_position;var eye:Vector3=game.camera.global_position
		check(tag+"tc reaches the gantry",await wait_lift(platform,true))
		check(tag+"feet reach 3.5 metre landing",absf(game.body.global_position.y-Y-3.5)<.15)
		check(tag+"head carried once and upright",absf((game.camera.global_position.y-eye.y)-(game.body.global_position.y-feet.y))<.12 and game.camera.global_basis.y.dot(Vector3.UP)>.999)
		check(tag+"walk off onto safe gantry",await move_to(Vector3(-6.4,Y+3.5,4.5),false,150))
		check(tag+"ride and bank cause no extra deaths",game.deaths==1 and game.health.get_health()>90)
		observations[tag]={"death_reason":game.last_death,"lift_top":game.body.global_position.y-Y,"new_cube_edge":artifact("z-wide").cube_edge,"bed_height":artifact("rotation-electric").global_position.y-Y}
		if not mode:
			game.floor_stream.set_process(false);game.floor_stream.set_physics_process(false)
			var shown:Array[int]=[16];game.building.show_floor_window(shown)
			for key in game.building.content.roots:
				game.building.content.roots[key].visible=int(key)==16
			if game.desktop_help:game.desktop_help.visible=false
			await picture("01-electric-course",Vector3(-8,7.4,10),Vector3(0,2.6,0))
			await picture("02-one-metre-pair",Vector3(-3.8,5.15,-1.5),Vector3(1.8,3.05,-1.5))
			await picture("03-tc-gantry",Vector3(-12,5.3,9.5),Vector3(-6.5,2.2,3))
		game.queue_free();await frames(20)
		if mode:
			for tracker_node in [head,left,right]:XRServer.remove_tracker(tracker_node)
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"observations":observations,"scope":"Actual game, scripted desktop locomotion and synthetic XR trackers. Real Jolt contact, tc passenger carry, electrical death and recovery; not a physical-headset acceptance."},"  "))
	print("ROTATION_ELECTRIC_RESULT ",failed.size());quit(0 if failed.is_empty() else 1)
