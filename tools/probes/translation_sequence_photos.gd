extends "res://tools/probes/translation_sequence_probe.gd"

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out=arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(out)
	await start(true)
	game.place_player(game.spawn_for(3));await frames(45)
	game.atmosphere.animate_sky=false;game.atmosphere.set_sky_time(180)
	root.msaa_3d=Viewport.MSAA_4X
	game.get_node("XROrigin3D").hide()
	game.status.hide();game.notice_time=-1
	for layer in game.find_children("*","CanvasLayer",true,false):layer.hide()
	encounter=game.building.content.exhibits["3/sequence"].get_node("Artifact")
	# Real route poses, briefly paused to make the seven displacements legible.
	for index in range(7):
		var ride: Node3D=encounter.get_node(encounter.recipe.rides[index].id)
		ride.platform.set_physics_process(false)
		ride.platform.global_position=ride.to_global(ride.displacement*.45+Vector3(0,-.5,0))
		ride.platform.static_body.force_update_transform()
	await photograph("shaft-depth",Vector3(-10,Y+2.65,6),Vector3(-10,Y+.1,-2.5))
	await photograph("sideways",Vector3(-9,Y+2.65,-5.3),Vector3(5.5,Y+1,-4.5))
	await photograph("lift",Vector3(5.5,Y+2.65,-4.5),Vector3(7,Y+2.7,-1.5))
	await photograph("upper-shaft",Vector3(7.4,Y+5.15,-1.5),Vector3(9.5,Y+2.8,3.5))
	await photograph("diagonal",Vector3(-4.5,Y+1.65,-1.5),Vector3(10,Y+.3,2.5))
	await photograph("door-studies",Vector3(16.8,Y+1.65,3.6),Vector3(16.7,Y+1.45,0))
	await photograph("course-overview",Vector3(-11.9,Y+5.25,6.2),Vector3(2,Y-1.6,0))
	var visible_solids: Array = []
	for mesh in game.building.find_children("*", "MeshInstance3D", true, false):
		if mesh.mesh == null or not mesh.is_visible_in_tree(): continue
		var bounds: AABB = mesh.global_transform * mesh.get_aabb()
		if bounds.size.y > 1.0 and bounds.get_center().y > Y and bounds.get_center().y < Y+6:
			visible_solids.append({"path":str(mesh.get_path()),"bounds":str(bounds)})
	FileAccess.open(out.path_join("photo-notes.json"),FileAccess.WRITE).store_string(JSON.stringify({"source":"Actual Godot Mobile renderer, production trial floor 3.","poses":"Carriers paused at 45% of their real displacement for photographs; continuous gameplay tested separately.","physical_headset":"not tested","stream":game.floor_stream.summary(),"visible_solids":visible_solids},"\t"))
	await finish(true)
	quit()

func photograph(filename: String,at: Vector3,target: Vector3) -> void:
	var camera:=Camera3D.new()
	game.add_child(camera)
	camera.environment=game.atmosphere.environment
	camera.fov=95 if filename=="course-overview" else 78
	camera.global_position=at;camera.look_at(target);camera.make_current()
	await frames(3);await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(filename+".png"))
	camera.queue_free();game.camera.make_current()
