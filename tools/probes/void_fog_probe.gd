# void_fog_probe.gd
# Full-project regression: the real autoloads must leave the Void's air alone.
# Uses the gameplay camera, not a separate screenshot camera.
extends Node

var game: Node3D
var output := "user://"
var checks: Array[Dictionary] = []
var baseline := false
var capture := false

func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): output = arg.trim_prefix("--out=")
		if arg == "--baseline": baseline = true
		if arg == "--capture": capture = true
	# Construct before NatureRenderer's deferred boot, just like running F6.
	game = load("res://commons/void/void.tscn").instantiate()
	add_child(game)
	game.body.scripted_input = true
	run.call_deferred()

func check(label: String, passed: bool) -> void:
	checks.append({"name": label, "passed": passed})
	print("[void-fog] ", "PASS " if passed else "FAIL ", label)

func run() -> void:
	var nature: Node = get_node("/root/NatureRenderer")
	await get_tree().create_timer(3.0).timeout
	game.scene_loaded()
	game.scene_visible()
	var env: Environment = game.camera.environment
	var startup := {"fog_enabled": env.fog_enabled, "fog_density": env.fog_density,
		"nature_bound_to_tower": nature._env == env,
		"vegetation_density": get_node("/root/EcosystemManager").get_vegetation_density(),
		"renderer": RenderingServer.get_current_rendering_method()}
	print("[void-fog] startup ", JSON.stringify(startup))
	if baseline:
		if capture: await picture("before.png")
		FileAccess.open(output.path_join("before.json"), FileAccess.WRITE).store_string(JSON.stringify(startup, "\t"))
		get_tree().quit()
		return
	check("actual gameplay camera remains current after scene callbacks", get_viewport().get_camera_3d() == game.camera)
	check("full-project nature autoload sees the actual tower environment", nature._initialized and nature._env == env)
	check("fog survives deferred autoload startup", env.fog_enabled and is_equal_approx(env.fog_density, 1.0))
	check("near landing remains outside fog and far frame fades", env.fog_depth_begin == 6.0 and env.fog_depth_end == 30.0)
	game.atmosphere.animate_sky = false
	game.atmosphere.set_sky_time(180.0)
	var pink: Color = env.fog_light_color
	var ambient: Color = env.ambient_light_color
	var authored_energy: float = env.ambient_light_energy
	check("default evening keeps its authored ambient level",game.atmosphere.lighting_mode==1 and is_equal_approx(authored_energy,0.24))
	for density in [0.0, 0.7]:
		# Exercise the real controller without altering/saving ecosystem progress.
		nature._update_fog(density)
		nature._update_sky(density)
		await get_tree().create_timer(2.2).timeout
		check("ecosystem density %s cannot disable or recolour the tower" % density,
			env.fog_enabled and is_equal_approx(env.fog_density, 1.0)
			and env.fog_light_color.is_equal_approx(pink)
			and env.ambient_light_color.is_equal_approx(ambient)
			and is_equal_approx(env.ambient_light_energy, authored_energy))
	# Scenes that use ecosystem weather must retain the original behaviour.
	var normal := Environment.new()
	nature._env = normal
	nature._update_fog(0.7)
	nature._update_sky(0.7)
	await get_tree().create_timer(2.2).timeout
	check("unowned biome environment still receives weather and ambient light",
		normal.fog_enabled and is_equal_approx(normal.fog_density, lerpf(0.05, 0.01, 0.7))
		and is_equal_approx(normal.ambient_light_energy, lerpf(0.3, 0.6, 0.7)))
	nature._update_fog(0.0)
	check("unowned biome can still turn off fog", not normal.fog_enabled)
	nature._env = env
	game.atmosphere.set_sky_time(360.0)
	check("tower retains its slowly changing violet evening", env.fog_light_color.is_equal_approx(Color("4b4b6b")))
	if capture:
		await picture("after.png")
		# Pause movement and lean the real player camera over the rim to expose
		# the deeper floors. The matched before/after pair keeps its old view.
		game.camera.position.x = -0.9
		game.camera.look_at(Vector3(-10.0, -44.0, 0.0))
		await get_tree().create_timer(0.2).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(output.path_join("shaft-down.png"))
	var passed := checks.all(func(item: Dictionary) -> bool: return item.passed)
	FileAccess.open(output.path_join("checks.json"), FileAccess.WRITE).store_string(JSON.stringify({
		"passed": passed, "startup": startup, "checks": checks,
		"scope": "Full project autoloads and real desktop gameplay camera; not physical headset verification."}, "\t"))
	get_tree().quit(0 if passed else 1)

func picture(filename: String) -> void:
	game.place_player(Vector3(-7.0, -23.94, 0.0))
	game.body.enabled = false
	game.set_physics_process(false)
	game.notice_time = -1
	game.status.hide()
	for layer in game.find_children("*", "CanvasLayer", true, false): layer.hide()
	game.atmosphere.animate_sky = false
	game.atmosphere.set_sky_time(180.0)
	game.camera.look_at(Vector3(-10.0, -44.0, 0.0))
	get_viewport().msaa_3d = Viewport.MSAA_4X
	await get_tree().create_timer(2.0).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(output.path_join(filename))
