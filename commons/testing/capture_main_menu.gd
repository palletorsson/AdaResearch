## Render the main menu scene for before/after capture.
##
## Run:
##   "/c/Users/palle/Desktop/Godot_v4.6-stable_win64.exe" --path . \
##     --xr-mode off --no-window \
##     --script res://commons/testing/capture_main_menu.gd
extends SceneTree

const MENU_SCENE: String = "res://commons/scenes/main_menu/MainMenu3D.tscn"
const CAPTURE_SIZE: Vector2i = Vector2i(1280, 800)


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var vp := SubViewport.new()
	vp.size = CAPTURE_SIZE
	vp.own_world_3d = true
	var w := World3D.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.02, 0.03)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.65, 0.72)
	env.ambient_light_energy = 0.8
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 0.5
	env.glow_bloom = 0.15
	w.environment = env
	vp.world_3d = w
	vp.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.msaa_3d = Viewport.MSAA_4X
	vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
	get_root().add_child(vp)

	var key := DirectionalLight3D.new()
	key.light_energy = 0.9
	key.rotation_degrees = Vector3(-25, 15, 0)
	vp.add_child(key)

	var cam := Camera3D.new()
	cam.fov = 50.0
	cam.position = Vector3(0.0, 0.05, 2.5)
	cam.look_at(Vector3(0.0, 0.05, 0.0), Vector3.UP)
	cam.current = true
	vp.add_child(cam)

	var packed: PackedScene = load(MENU_SCENE)
	if packed == null:
		push_error("Could not load main menu scene")
		quit(1)
		return
	var menu: Node3D = packed.instantiate()
	vp.add_child(menu)

	# Give the menu several frames to wire up + the buttons to render their materials
	for i in range(20):
		await get_root().get_tree().process_frame
	await create_timer(0.6).timeout
	for i in range(6):
		await get_root().get_tree().process_frame

	var out_dir := "user://main_menu_test"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
	var img: Image = vp.get_texture().get_image()
	var ts: String = Time.get_datetime_string_from_system().replace(":","-")
	img.save_png(out_dir + "/menu_" + ts + ".png")
	img.save_png(out_dir + "/menu_latest.png")
	print("DONE - saved")
	quit(0)
