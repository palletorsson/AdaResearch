extends "res://tools/probes/triangle_shaft_quad_probe.gd"
const Layout := preload("res://commons/void/trials/color_flashlight/close_lamps.gd")

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out=arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(out)
	for mode in ([true] if "--reach-only" in OS.get_cmdline_user_args() else [false,true]):
		load("res://commons/void/game.gd").requested_floor=26
		await start(mode)
		var tag := "Synthetic XR: " if mode else "Desktop: "
		var content: Node3D=game.building.content
		var board: Node3D=content.exhibits["26/lamps"].get_node("Artifact")
		var rooms: Node3D=content.exhibits["26/rooms"].get_node("Artifact")
		var groups: Array=[board,rooms.white_room,rooms.light_well]
		if not mode:
			game.body.hide();game.get_node("CareBody").hide()
			for layer in game.find_children("*","CanvasLayer",true,false): layer.hide()
			await photograph("soft-white-room",rooms.white_room.to_global(Vector3(0,1.65,3.45)),rooms.white_room.to_global(Vector3(0,2.05,5.3)))
			await photograph("soft-lightwell",rooms.light_well.to_global(Vector3(0,1.65,4.45)),rooms.light_well.to_global(Vector3(0,2.05,6.9)))
			await photograph("close-board-lamps",board.to_global(Vector3(0,1.65,1.1)),board.to_global(Vector3(0,2,-1.95)))
			game.body.show();game.get_node("CareBody").show()
		for group in groups:
			var lamps: Array=[]
			for name in ["RedFlashlight","GreenFlashlight","BlueFlashlight","WhiteFlashlight"]: lamps.append(group.get_node(name))
			var standing: Vector3=group.to_global(lamps[0].get_meta("void_lamp_standing_point"))+Vector3.UP*.06
			game.checkpoint=26;game.place_player(standing)
			if mode:
				var forward: Vector3=lamps[0].global_position-standing
				forward.y=0
				game.center_player_on(Transform3D(Basis.looking_at(forward.normalized()),standing))
			await frames(8)
			var fixed_feet: Vector3=game.body.global_position
			print("LAMP_REACH ",group.name," standing=",standing," body=",fixed_feet," camera=",game.camera.global_position," lamps=",lamps.map(func(l):return [l.global_position,l.global_position.distance_to(fixed_feet+Vector3.UP*1.2)]))
			check(tag+str(group.name)+" all handles within an 80 cm reach from one stance",lamps.all(func(l):return l.global_position.distance_to(fixed_feet+Vector3.UP*1.2)<.8))
			check(tag+str(group.name)+" four lamps span 90 cm",is_equal_approx(lamps[0].position.distance_to(lamps[3].position),.9))
			check(tag+str(group.name)+" beams have soft angular falloff",lamps.all(func(l):return is_equal_approx(l.get_node("SpotLight3D").spot_angle_attenuation,2.2)))
			if "--reach-only" in OS.get_cmdline_user_args(): continue
			for lamp in lamps:
				await input_grab(tag+str(group.name)+"/"+str(lamp.name)+": ",lamp,lamp.get_node("CollisionShape3D"),.25,.025)
				check(tag+"feet stay in place for "+str(group.name)+"/"+str(lamp.name),Vector2(game.body.global_position.x-fixed_feet.x,game.body.global_position.z-fixed_feet.z).length()<.15 and not game.recovering)
				if mode:right.set_input("grip",0.0)
				else:game.body.desktop_pointer._drop_held()
				await frames(5)
		check(tag+"shaft remains open beneath each room",[-10,10].all(func(x):return ray(Vector3(x,-155,0),Vector3(x,-156.5,0)).is_empty()))
		game.queue_free();await frames(12)
		if mode:
			for input_tracker in [head,left,right]:XRServer.remove_tracker(input_tracker)
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"scope":"Main floor 26. Native desktop and synthetic XR pickup of all twelve lamps from three fixed standing positions; geometry, shafts and beam settings. Physical headset not tested."},"  "))
	print("CLOSE_FLASHLIGHTS ",checks.size()," ",failed)
	quit(0 if failed.is_empty() else 1)
