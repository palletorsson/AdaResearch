extends "res://tools/probes/triangle_shaft_quad_probe.gd"
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out=arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(out)
	if "--endpoint-only" in OS.get_cmdline_user_args():
		await start(true)
		game.checkpoint=11
		game.place_player(Vector3(31.8,-64.94,.5))
		await frames(35)
		var okay := await move_to(Vector3(40.5,-65,.5),false,600)
		print("ENDPOINT_DIAGNOSTIC reached=",okay," feet=",game.body.global_position," velocity=",game.body.velocity," death=",game.last_death," recovering=",game.recovering," checkpoint=",game.checkpoint," health=",game.health.get_health())
		quit(0 if okay else 1)
		return
	var appearance_only := "--appearance-only" in OS.get_cmdline_user_args()
	for mode in [false,true]:
		await start(mode)
		if not xr: game.body.set_process_unhandled_input(false)
		game.checkpoint=11
		game.place_player(Vector3(-18.5,-65.94,4.4))
		await frames(45)
		var tag := "XR: " if xr else "Desktop: "
		var span: Node3D=game.building.content.exhibits["11/sky-walk"].get_node("Artifact")
		var portals: Node3D=span.get_node("RefinementPassage")
		check(tag+"no transport cube or docking boxes",not span.has_node("MovingPlatform") and not span.has_node("WestDock1") and span.find_children("*Transport*","Node3D",true,false).is_empty())
		check(tag+"twenty equal four-metre native tori",portals._portals.size()==20 and portals._portals.all(func(p):return p.scale.is_equal_approx(Vector3.ONE) and is_equal_approx(p.mesh.outer_radius,2.0) and is_equal_approx(p.mesh.inner_radius,1.55)))
		var spacing := true
		for i in range(1,20): spacing = spacing and is_equal_approx(portals._portals[i].global_position.distance_to(portals._portals[i-1].global_position),3.0)
		check(tag+"ring centres are three metres apart",spacing)
		check(tag+"all ring bodies fit between floor and ceiling",portals._portals.all(func(p):return p.position.y-p.mesh.outer_radius>=0 and p.position.y+p.mesh.outer_radius<5.64))
		check(tag+"resolution still increases",portals._portals[0].mesh.rings==3 and portals._portals[19].mesh.rings==22 and portals._portals[19].mesh.ring_segments==41)
		portals.select_next()
		check(tag+"all rings stay translucent pink on selection",portals._portals.all(func(p):return p.material_override is StandardMaterial3D and p.material_override.transparency==BaseMaterial3D.TRANSPARENCY_ALPHA and p.material_override.albedo_color.is_equal_approx(Color(Color("ff4f9a"),.78)) and not p.material_override.emission_enabled))
		var ordinary: Node3D=load("res://commons/primitives/combines/combine_portals.tscn").instantiate()
		ordinary.visible=false
		root.add_child(ordinary)
		check(tag+"original museum torus resource unchanged",is_equal_approx(ordinary._base_mesh.inner_radius,4) and is_equal_approx(ordinary._base_mesh.outer_radius,3))
		ordinary.free()
		# Sample a real bridge lane, not the original two-centimetre grid seam.
		check(tag+"static bridge fills former moving crossing",span.get_node("ShaftBridge1").bridge_length==7 and not ray(Vector3(10,-64,0),Vector3(10,-66,0)).is_empty())
		check(tag+"shaft remains open beside bridge",ray(Vector3(10,-65.5,2.5),Vector3(10,-66.5,2.5)).is_empty())
		if not appearance_only:
			check(tag+"ramp reaches bridge",await move_to(Vector3(-18.5,-65,.5),false,420))
			for x in [-10,0,7,10,13,23,32,40.5]:
				var reached := await move_to(Vector3(x,-65,.5),false,600)
				check(tag+"walk uninterrupted to x="+str(x),reached)
				if not reached: print("PORTAL_WALK_FAIL ",tag," feet=",game.body.global_position," death=",game.last_death," recovering=",game.recovering)
			check(tag+"last ring and arrivals stay aligned",is_equal_approx(portals._portals.back().global_position.x,38.5) and is_equal_approx(span.get_node("StrangeArrivals").global_position.x,38.5) and is_equal_approx(span.get_node("SkyLookout").global_position.x,40.5))
			check(tag+"whole crossing stays alive on Portals",game.deaths==0 and game.checkpoint==11)
			var arrivals: Node3D=span.get_node("StrangeArrivals")
			check(tag+"arrival pickups cannot collide with visitor body",arrivals.arrivals.all(func(b):return game.body in b.get_collision_exceptions()))
		if not xr:
			game.body.hide()
			game.get_node("CareBody").hide()
			for layer in game.find_children("*","CanvasLayer",true,false): layer.hide()
			await photograph("pink-rings-static-bridge",Vector3(-17.5,-63.9,.5),Vector3(40,-62.8,.5))
			await photograph("bridge-over-shaft",Vector3(5,-62.8,4),Vector3(12,-64.5,.5))
			await photograph("four-metre-pink-rings",Vector3(43,-61.8,8),Vector3(29,-64,.5))
		game.queue_free()
		await frames(12)
		if xr:
			for tracker_item in [head,left,right]: XRServer.remove_tracker(tracker_item)
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"scope":"Floor 11 desktop/synthetic-XR appearance and load check: equal 4 m tori, unit transforms, storey fit, 3 m centres, translucent pink. Appearance-only run does not repeat the previously passing full bridge walk. No physical headset."},"\t"))
	print("STATIC_PORTALS_RESULT ",checks.size()," ",failed)
	quit(0 if failed.is_empty() else 1)
