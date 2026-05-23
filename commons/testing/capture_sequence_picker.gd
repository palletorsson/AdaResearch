## Render the picker at two scroll positions to verify all phase colors.
extends SceneTree

const PICKER_SCENE: String = "res://commons/scenes/2din3dui/sequence_picker_3d.tscn"
const CAPTURE_SIZE: Vector2i = Vector2i(960, 1280)


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var vp := SubViewport.new()
	vp.size = CAPTURE_SIZE
	vp.own_world_3d = true
	var w := World3D.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.07, 0.07, 0.09)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.65, 0.68, 0.75)
	env.ambient_light_energy = 0.85
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	w.environment = env
	vp.world_3d = w
	vp.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.msaa_3d = Viewport.MSAA_4X
	get_root().add_child(vp)

	var key := DirectionalLight3D.new()
	key.light_energy = 1.0
	key.rotation_degrees = Vector3(-30, 20, 0)
	vp.add_child(key)

	var cam := Camera3D.new()
	cam.fov = 35.0
	cam.position = Vector3(0.0, 1.0, 1.85)
	cam.look_at(Vector3(0.0, 1.0, 0.0), Vector3.UP)
	cam.current = true
	vp.add_child(cam)

	var packed: PackedScene = load(PICKER_SCENE)
	var picker: Node3D = packed.instantiate()
	vp.add_child(picker)
	for i in range(10):
		await get_root().get_tree().process_frame
	await create_timer(0.5).timeout

	var out_dir := "user://sequence_picker_test"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))

	# Capture top
	var img: Image = vp.get_texture().get_image()
	img.save_png(out_dir + "/picker_top.png")
	print("saved top")

	# Scroll to ~halfway through the list and capture again
	var scroll: ScrollContainer = picker.find_child("Scroll", true, false) as ScrollContainer
	if scroll != null:
		scroll.scroll_vertical = 700  # scroll down ~7 cards worth
		await get_root().get_tree().process_frame
		await create_timer(0.3).timeout
		for i in range(6):
			await get_root().get_tree().process_frame
		img = vp.get_texture().get_image()
		img.save_png(out_dir + "/picker_mid.png")
		print("saved mid")
		# Scroll to bottom
		scroll.scroll_vertical = 1600
		await get_root().get_tree().process_frame
		await create_timer(0.3).timeout
		for i in range(6):
			await get_root().get_tree().process_frame
		img = vp.get_texture().get_image()
		img.save_png(out_dir + "/picker_bottom.png")
		print("saved bottom")
	else:
		print("Scroll node not found — only top captured")

	print("DONE")
	quit(0)
