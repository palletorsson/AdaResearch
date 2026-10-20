extends SceneTree
const Architecture = preload("res://commons/void/architecture.gd")
const Atmosphere = preload("res://commons/void/atmosphere.gd")
var out := "user://"

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out = arg.trim_prefix("--out=")
	root.size = Vector2i(1600, 1000)
	root.msaa_3d = Viewport.MSAA_4X
	var sky := Atmosphere.new()
	sky.animate_sky = false
	root.add_child(sky); sky.set_sky_time(180)
	var building := Architecture.new()
	building.stream_content = true
	root.add_child(building)
	for index in range(4): building.content.load_floor(index, true)
	var visible: Array[int] = [0, 1, 2, 3, 4, 5, 6]
	building.show_floor_window(visible)
	var camera := Camera3D.new()
	camera.fov = 75
	root.add_child(camera); camera.make_current()
	for i in range(35): await physics_frame
	var views := [
		["roof-next-landing", Vector3(0.8, 1.65, 8.8), Vector3(0.8, -6.0, 10.7)],
		["landing-into-point-one", Vector3(0.8, -4.35, 11.8), Vector3(0, -4.7, 1)],
		["next-cliff-staggered", Vector3(3.3, -4.35, 10.5), Vector3(7.5, -12, 10.6)],
		["tower-cliffs", Vector3(28, 4, 32), Vector3(0, -15, 0)]
	]
	for view in views:
		camera.position = view[1]; camera.look_at(view[2])
		for i in range(12): await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(out.path_join(view[0] + ".png"))
	building.queue_free(); camera.queue_free(); sky.queue_free()
	for i in range(12): await process_frame
	quit()
