extends Node3D

const OUT := "res://doc/space/transformation-alignment-2026-09-17/scale"
var camera: Camera3D

func _ready() -> void:
	run.call_deferred()

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var em: Node3D = load("res://commons/scenes/endless_museum.tscn").instantiate()
	var control := "res://ada_run/alignment-scale-capture-control.json"
	var f := FileAccess.open(control, FileAccess.WRITE)
	f.store_string(JSON.stringify({"first_chapter":"transformation", "first_map":"Trans_Scale", "grid_pack":1, "dollhouse":0})); f.close()
	em.set("EM_CONTROL", control)
	em.set("_overrides_path", control+".unused")
	em.set("_hand_path", control+".unused")
	em.set("_cartridge_read_enabled", false)
	em.set("_costume_on", false)
	em.set("start_chapter", "transformation"); em.set("start_map", "Trans_Scale")
	var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://commons/data/em_layout.json"))
	layout.get_or_add("stream", {})["bodies"] = 1; em.set("_layout",layout)
	add_child(em)
	await get_tree().create_timer(3).timeout
	em.set_process(false); em.set_physics_process(false); em.call("flush_stamps")
	for i in 80: await get_tree().process_frame
	var encounter: Node3D = em.find_child("DrinkMeEncounter",true,false)
	if encounter == null:
		push_error("Compact scale encounter absent"); get_tree().quit(1); return
	var player: CharacterBody3D = em.get("_player")
	player.hide()
	var walker_camera: Camera3D = em.get("_cam")
	if is_instance_valid(walker_camera):
		for child in walker_camera.get_children():
			if child is Timer: child.stop()
	camera = Camera3D.new(); camera.fov = 74; add_child(camera)
	await capture(encounter.to_global(Vector3(0,1.65,-1.8)), encounter.to_global(Vector3(0,1.6,0.5)), "entry-wall")
	await capture(encounter.to_global(Vector3(0,1.65,0.25)), encounter.to_global(Vector3(0.35,1.3,2.6)), "before")
	encounter.bottle.call("_take",player,null)
	for i in 6: await get_tree().physics_frame
	await capture(encounter.table.to_global(encounter.landings[0])+Vector3(0,1.6,0), encounter.room.to_global(Vector3(0.4,1,3.5)), "on-the-plate")
	await capture(encounter.room.to_global(Vector3(-1.7,2.7,0.6)), encounter.room.to_global(Vector3(0.3,1.1,2.3)), "expanded")
	await capture(encounter.room.to_global(Vector3(1.2,0,3.6))+Vector3.UP*1.6, encounter.witness.global_position+Vector3.UP*1.6, "two-doorways")
	get_tree().quit()

func capture(pos: Vector3, target: Vector3, title: String) -> void:
	camera.global_position = pos; camera.look_at(target)
	for i in 24:
		camera.make_current()
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUT+"/"+title+".png")
	print("[compact-scale-capture] ", title)
