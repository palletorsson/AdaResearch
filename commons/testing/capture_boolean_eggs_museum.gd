extends SceneTree
## Actual endless-museum assembly, private control/hand files, no gameplay save writes.
const OUT := "res://ada_run/boolean-eggs-museum/"
func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var em: Node3D = load("res://commons/scenes/endless_museum.tscn").instantiate()
	em.set("EM_CONTROL", OUT + "control.json")
	em.set("_overrides_path", OUT + "unused-overrides.json")
	em.set("_hand_path", OUT + "hand.json")
	em.set("start_chapter", "boolean_surfaces")
	em.set("start_map", "Boolean_Works")
	var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://commons/data/em_layout.json"))
	layout.get_or_add("stream", {})["bodies"] = 1
	em.set("_layout", layout)
	var control := FileAccess.open(OUT + "control.json", FileAccess.WRITE)
	control.store_string(JSON.stringify({"first_chapter":"boolean_surfaces", "dollhouse":0, "grid_pack":1}))
	control.close()
	root.add_child(em)
	current_scene = em
	await create_timer(1.0).timeout
	em.set_process(false)
	em.set_physics_process(false)
	em.call("flush_stamps")
	var player: Node = em.get("_player")
	if player != null:
		player.set_process(false)
		player.set_physics_process(false)
	var seg: Node3D
	for rec: Dictionary in em.get("_segments"):
		if rec.node.get_meta("em_map", "") == "Boolean_Works":
			seg = rec.node
			break
	if seg == null:
		push_error("Boolean_Works not built")
		quit(1)
		return
	for i in 30: await process_frame
	var eggs: Node3D
	for n in seg.find_children("*", "Node3D", true, false):
		if n.get_script() == load("res://commons/artifacts/kapoor_void_studies/boolean_eggs.gd"):
			eggs = n
			break
	if eggs == null:
		push_error("Eggs not spawned by actual museum registry")
		quit(1)
		return
	print("[eggs-museum] mounted at ", eggs.global_position, " scale ", eggs.global_basis.get_scale())
	var counts: Array[int] = []
	for n in eggs.get_children():
		if n is CSGCombiner3D:
			var meshes: Array = n.get_meshes()
			if meshes.size() != 2:
				push_error("Missing Boolean mesh")
				quit(1)
				return
			counts.append(meshes[1].get_faces().size() / 3)
	# Freeze the assembled world after deferred startup; its walker and timer
	# otherwise reclaim the eye or reset its position between captures.
	em.process_mode = Node.PROCESS_MODE_DISABLED
	em.set("_shot_path", "private-capture")
	for timer in em.find_children("*", "Timer", true, false):
		timer.stop()
	var camera := Camera3D.new()
	root.add_child(camera)
	em.set("_cam", camera)
	for overlay in root.find_children("*", "CanvasLayer", true, false):
		overlay.hide()
	camera.fov = 60
	for view in [
		["eggs-in-museum", Vector3(-0.2,1.7,7.1), Vector3(0,1.4,0)],
		["eggs-museum-cavity", Vector3(3.5,1.6,3.3), Vector3(2.28,1.0,0)]
	]:
		camera.global_position = eggs.to_global(view[1])
		camera.look_at(eggs.to_global(view[2]))
		for i in 12:
			em.call("_cull_artifacts")
			camera.make_current()
			await process_frame
		camera.make_current()
		if not eggs.is_visible_in_tree():
			push_error("Eggs are still culled at the capture eye")
			quit(1)
			return
		print("[eggs-museum] eye ",camera.global_position," target ",eggs.to_global(view[2]))
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OUT + view[0] + ".png")
		print("[eggs-museum] saved ", view[0])
	var report := FileAccess.open(OUT + "report.json", FileAccess.WRITE)
	report.store_string(JSON.stringify({"map":"Boolean_Works", "artifact":"boolean_eggs", "triangles":counts,
		"position":str(eggs.global_position),"scale":str(eggs.global_basis.get_scale()),
		"ground_hidden":not eggs.show_ground,"museum_mount":eggs.museum_mount,
		"scope":"Actual endless_museum assembly with private capture state; desktop, not headset."}, "\t"))
	report.close()
	quit(0)
