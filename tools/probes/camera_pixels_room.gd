extends "res://tools/probes/camera_glitch_room.gd"
func landing_checks()->void:
	await super.landing_checks()
	var work:=find_scene("/camera_glitch_study/CameraGlitchStudy.gd")
	if work==null:return
	var approach:=work.to_global(Vector3(.5,0,3.0))
	var driver=load("res://commons/testing/wcn_desktop_driver.gd").new();museum.add_child(driver);driver.spawn(approach,museum);await create_timer(.2).timeout
	observations.pointer_bank=await driver.press(work.buttons["PIXELS / FORM"],approach);await tick()
	check("real bank button selects pixel operations",work.pixel_mode and work.mode==0)
	observations.pointer_pixel_next=await driver.press(work.buttons["NEXT"],approach);await tick()
	check("next button selects wrong-row-width pixel operation",work.pixel_mode and work.mode==1)
	driver.teardown();driver.queue_free();await tick()
	camera.global_position=work.to_global(Vector3(-1.6,1.65,4.8));camera.look_at(work.to_global(Vector3(-.3,2,0)));camera.current=true
	work.home_camera();await create_timer(.5).timeout;await work.snapshot();work.paused=true;work.bind_images()
	var original: String=work.held_texture.get_image().get_data().hex_encode().sha256_text()
	work.held_texture.get_image().save_png(ProjectSettings.globalize_path(folder+"pixel-source.png"))
	var first_vertices:PackedVector3Array=work.receivers[0].mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	for mode in 10:
		work.mode=mode;work.amount=1;work.rebuild();await tick()
		var vertices:PackedVector3Array=work.receivers[0].mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		check("pixel %d keeps one unchanged flat receiver"%mode,work.receivers.size()==1 and vertices==first_vertices and vertices.size()==6)
		if mode==6:
			work.parked=false;work.handle.rotate_y(.4);work.paused=false;work.bind_images();await create_timer(.3).timeout
		await snapshot("pixels-%02d"%(mode+1),work.to_global(Vector3(-1.6,1.65,4.8)),work.to_global(Vector3(-.3,2,0)),74)
		if mode==6:
			check("past-block source and retained image differ",work.viewport.get_texture().get_image().get_data().hex_encode().sha256_text()!=original)
			work.home_camera();work.paused=true;work.bind_images()
	check("all ten pixel modes preserve the saved source",work.held_texture.get_image().get_data().hex_encode().sha256_text()==original)
	work.select(9);work.act("NEXT");check("pixel navigation wraps within its bank",work.mode==0 and work.pixel_mode)
	work.act("RESET");check("reset stays in pixel bank and restores amount/live",work.pixel_mode and work.mode==0 and is_equal_approx(work.amount,.8) and not work.paused)
	work.act("PIXELS / FORM");check("original spatial bank remains available",not work.pixel_mode and work.mode==0)
	await snapshot("pixel-controls",work.to_global(Vector3(.5,1.65,3)),work.to_global(Vector3(.5,.9,1.85)),74)
