extends "res://tools/probes/void_game_probe.gd"
## Exercise the real sky clock and capture known phases in the actual tower.

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out=arg.trim_prefix("--out=")
	await start(false)
	game._set_enabled(false)
	var sky: Node3D=game.atmosphere
	check("tower defaults to evening",sky.lighting_mode==1)
	# The original daylight palette remains an explicit comparison preset.
	sky.set_lighting_mode(0)
	sky.set_process(false)
	sky.set_sky_time(0)
	var material: ShaderMaterial=sky.sky_material
	var noise: Texture2D=material.get_shader_parameter("cloud_noise")
	check("active tower camera uses the animated environment",game.camera.environment==sky.environment)
	check("twelve-minute cycle and incremental 128px reflections",sky.cycle_seconds==720 and sky.environment.sky.process_mode==Sky.PROCESS_MODE_INCREMENTAL and sky.environment.sky.radiance_size==Sky.RADIANCE_SIZE_128)
	sky._process(0.5)
	check("no sky uniform update between one-second ticks",is_zero_approx(material.get_shader_parameter("cycle_phase")))
	sky._process(0.5)
	check("elapsed time advances the real shader phase",is_equal_approx(material.get_shader_parameter("cycle_phase"),TAU/720))
	var rose: Color=sky.environment.fog_light_color
	sky.set_sky_time(360)
	check("mid-cycle reaches violet and matching distant fog",is_equal_approx(material.get_shader_parameter("cycle_phase"),PI) and sky.environment.fog_light_color==Color("bcb0de") and sky.environment.fog_light_color!=rose)
	check("procedural noise texture is reused while sky changes",material.get_shader_parameter("cloud_noise")==noise)
	sky.set_sky_time(720)
	check("cycle returns exactly to its starting state",is_zero_approx(material.get_shader_parameter("cycle_phase")) and sky.environment.fog_light_color==Color("d4b5cf"))
	sky.animate_sky=false;sky._process(60)
	check("still sky option holds its phase",is_zero_approx(material.get_shader_parameter("cycle_phase")))
	check("VR depth fog leaves near jump edges clear",sky.environment.fog_mode==Environment.FOG_MODE_DEPTH and sky.environment.fog_depth_begin==6.0 and not sky.environment.volumetric_fog_enabled)
	if "--capture" in OS.get_cmdline_user_args(): await pictures()
	game.queue_free();await frames(3)
	await start(true)
	check("XR camera receives the same sky and fog",game.camera is XRCamera3D and game.camera.environment==game.atmosphere.environment and game.atmosphere.animate_sky)
	game.queue_free();await frames(3)
	for item in [head,left,right]: XRServer.remove_tracker(item)
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"scope":"Real Godot clock, rendered Mobile sky and synthetic XR camera binding; no physical headset performance test."},"\t"))
	quit(0 if failed.is_empty() else 1)

func pictures() -> void:
	game.status.hide();game.notice_time=-1
	for layer in game.find_children("*","CanvasLayer",true,false): layer.hide()
	root.msaa_3d=Viewport.MSAA_4X
	var cam:=Camera3D.new();root.add_child(cam);cam.environment=game.atmosphere.environment;cam.make_current();cam.fov=75
	for shot in [
		["roof",Vector3(3,1.65,-2),Vector3(-11,4.5,9)],
		["trace",Vector3(-12.7,-22.2,6),Vector3(-16.5,-22.85,0.8)],
		["tower",Vector3(34,15,37),Vector3(0,-5,0)]
	]:
		cam.position=shot[1];cam.look_at(shot[2])
		for phase in [0,180,360]:
			game.atmosphere.set_sky_time(float(phase));await frames(40);await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(out.path_join("%s-%d.png"%[shot[0],phase]))
	cam.queue_free();await frames(2)
