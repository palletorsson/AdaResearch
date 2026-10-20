extends "res://tools/probes/void_triangle_probe.gd"

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out=arg.trim_prefix("--out=")
	var before := "--baseline" in OS.get_cmdline_user_args()
	await start(false)
	game.atmosphere.animate_sky=false
	game.atmosphere.set_sky_time(180)
	for shot in [
		[0,"roof",Vector3(3,1.65,-2),Vector3(-11,4.5,9),75],
		[1,"point-one",Vector3(0,-4.35,6.8),Vector3(0,-4.6,-1.7),78],
		[1,"future",Vector3(2.2,-4.35,-.7),Vector3(-1.4,-4.1,-4.8),75],
		[2,"coordinates",Vector3(-1.6,-10.35,-2.1),Vector3(.3,-11.0,-.1),74],
		[5,"triangle",Vector3(13.5,-28.35,6.5),Vector3(18.1,-27.8,-.5),86],
		[6,"polyhedra",Vector3(-.8,-34.35,-.1),Vector3(-.5,-34.5,-5),83]
	]:
		await visit(shot[0])
		if shot[0]==6:
			var monitor: Node3D=game.building.content.exhibits["6/boundaries"].get_node("Artifact/UnfoldingMonitor")
			monitor.discover_source();monitor.observe(.25)
			monitor.stage.running=false;monitor.stage.playhead=14;monitor.stage.refresh();monitor.refresh_once()
		await photograph(("before-" if before else "evening-")+shot[1]+".png",shot[2],shot[3],shot[4])
		check("Captured "+shot[1],FileAccess.file_exists(out.path_join(("before-" if before else "evening-")+shot[1]+".png")))
	if not before: await lighting_contract()
	game.queue_free();await frames(15)
	if not before:
		await start(true)
		check("XR camera uses the evening environment",game.camera is XRCamera3D and game.camera.environment==game.atmosphere.environment and game.atmosphere.lighting_mode==1)
		check("XR uses standard depth fog with clear near landings",game.atmosphere.environment.fog_depth_begin==6 and not game.atmosphere.environment.volumetric_fog_enabled)
		game.queue_free();await frames(10)
		for tracker in [head,left,right]: XRServer.remove_tracker(tracker)
	FileAccess.open(out.path_join("before-checks.json" if before else "checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"scope":"Actual Mobile-rendered tower and synthetic XR camera. No physical headset performance measurement."},"\t"))
	quit(0 if failed.is_empty() else 1)

func visit(index: int) -> void:
	game._set_enabled(true)
	game.checkpoint=index;game.place_player(game.spawn_for(index))
	await frames(45)
	var deadline := Time.get_ticks_msec()+15000
	while not game.building.content.pending.is_empty() and Time.get_ticks_msec()<deadline:
		OS.delay_msec(5);await frames(1)
	game._set_enabled(false)
	await frames(10)

func lighting_contract() -> void:
	var atmosphere: Node3D=game.atmosphere
	var env: Environment=atmosphere.environment
	check("Evening is the default and keeps a dim readable ambient",atmosphere.lighting_mode==1 and env.ambient_light_energy>=.15 and env.ambient_light_energy<.4)
	check("Sun no longer overpowers work lights",atmosphere.get_node("WarmSun").light_energy<.3)
	check("Slow sky still uses incremental 128px reflections",atmosphere.cycle_seconds==720 and env.sky.process_mode==Sky.PROCESS_MODE_INCREMENTAL and env.sky.radiance_size==Sky.RADIANCE_SIZE_128)
	var noise: Texture2D=atmosphere.sky_material.get_shader_parameter("cloud_noise")
	atmosphere.set_sky_time(0);var rose: Color=env.fog_light_color
	atmosphere.set_sky_time(360)
	check("Evening fog changes gently with the same procedural sky",not env.fog_light_color.is_equal_approx(rose) and atmosphere.sky_material.get_shader_parameter("cloud_noise")==noise)
	atmosphere.set_sky_time(720)
	check("Evening cycle closes without a colour jump",env.fog_light_color.is_equal_approx(rose))
	atmosphere.set_lighting_mode(0)
	check("Daylight remains available for comparison",is_equal_approx(env.ambient_light_energy,.55) and is_equal_approx(atmosphere.get_node("WarmSun").light_energy,1.1))
	atmosphere.set_lighting_mode(1);atmosphere.set_sky_time(180)
	await visit(1)
	var active := 0
	for node in game.building.content.roots[1].find_children("WorkBeam","SpotLight3D",true,false):
		if node.is_visible_in_tree(): active+=1
	check("Point One work lights are active",active>=2)
	var at := Vector3(0,-4.35,6.8)
	var target := Vector3(0,-4.6,-1.7)
	await photograph("lights-on.png",at,target,78)
	for node in game.building.content.roots[1].find_children("WorkBeam","SpotLight3D",true,false): node.hide()
	await photograph("lights-off.png",at,target,78)
	for node in game.building.content.roots[1].find_children("WorkBeam","SpotLight3D",true,false): node.show()
	await visit(2)
	check("Leaving a floor removes its work-light contribution",not game.building.content.props["1/point-work-light"].get_node("Prefab/WorkBeam").is_visible_in_tree())
	await visit(1)
	check("Returning restores the same work light",game.building.content.props["1/point-work-light"].get_node("Prefab/WorkBeam").is_visible_in_tree())
