extends SceneTree
const OUT := "res://doc/space/transformation-sampling-2026-09-17/"

func _initialize() -> void: run.call_deferred()

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var lab: Node3D = load("res://commons/testing/transformation_sampling_lab.tscn").instantiate()
	root.add_child(lab)
	current_scene = lab
	await create_timer(0.5).timeout
	# Hide the fixture's desktop toolbar in evidence images; physical controls remain.
	for node in lab.get_children():
		if node is CanvasLayer: node.hide()
	lab.study.seek(0.5)
	await shot("overview")
	for i in 4:
		lab.focus(i)
		await shot(["translate","rotate","scale","combine"][i])
	lab.focus(1)
	lab.study.set_mark(true)
	lab.study.seek(1.5)
	await shot("rotation-marked")
	lab.study.set_shape("asymmetric")
	await shot("rotation-asymmetric")
	lab.study.set_shape("sphere")
	await shot("rotation-sphere")
	quit()

func shot(title: String) -> void:
	for i in 8: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT+title+".png"))
	print("[sampling-render] ",title)
