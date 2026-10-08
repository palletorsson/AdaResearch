extends SceneTree
const OUT := "res://doc/space/zoetrope-encounter-2026-09-17/"
func _initialize() -> void: run.call_deferred()
func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var lab: Node3D = load("res://commons/testing/transformation_sampling_lab.tscn").instantiate()
	root.add_child(lab)
	current_scene = lab
	await create_timer(0.5).timeout
	for node in lab.get_children():
		if node is CanvasLayer: node.hide()
	lab.study.seek(0.0)
	lab.focus(3)
	await shot("approach-zero")
	lab.study.seek(0.75)
	await shot("approach-turning")
	lab.show_overview()
	await shot("four-drums")
	lab.enter_walk()
	await create_timer(0.2).timeout
	await shot("eye-height")
	if lab.axial:
		lab.axial.seek(0.5)
		lab.focus_axial()
		lab.axial.set_envelope(true)
		await shot("axial-cube")
		lab.axial.set_shape("triangle")
		await shot("axial-triangle")
	quit()
func shot(title: String) -> void:
	for i in 8: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT+title+".png"))
	print("[zoetrope-render] ",title)
