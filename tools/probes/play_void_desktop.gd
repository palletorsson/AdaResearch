extends SceneTree
## Human-controlled main tower. No agent, scripted route or paused decisions.
var game: Node3D
var folder := ""
var start_override: Array=[]
var look_override: Array=[]

func _initialize() -> void:
	open_game.call_deferred()

func open_game() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--play-output="):folder=arg.trim_prefix("--play-output=")
		if arg.begins_with("--play-spawn="):start_override=Array(arg.trim_prefix("--play-spawn=").split(","))
		if arg.begins_with("--play-look-at="):look_override=Array(arg.trim_prefix("--play-look-at=").split(","))
	load("res://commons/void/room_source.gd").use_main_tower=true
	game=load("res://commons/void/void.tscn").instantiate()
	root.add_child(game);current_scene=game
	game.died.connect(func(reason):print("VOID_PLAY_DEATH ",JSON.stringify({"reason":reason,"position":[game.body.global_position.x,game.body.global_position.y,game.body.global_position.z],"charge":game.charge.get_charge(),"checkpoint":game.checkpoint,"stream":game.floor_stream.summary()})))
	game.body.scripted_input=true;game.body.set_process_unhandled_input(false)
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	game.scene_loaded();game.scene_visible()
	var floor: int=game.checkpoint
	for i in 240:
		var record: Dictionary=game.building.content.data.floors[floor]
		if record.artifacts.all(func(a):return game.building.content.exhibits.has(str(floor)+"/"+a.id)):break
		await physics_frame
	# Procedural recipe collision must be ready before handing the game over.
	for exhibit in game.building.content.exhibits.values():
		var item: Node=exhibit.get_node("Artifact")
		# Other artifacts' export hooks can freeze their physics or controls.
		# Only the static recipe adapter needs its asynchronous Boolean bake here.
		if item.get_script()!=null and item.get_script().resource_path=="res://commons/modular/recipe_area.gd":await item.prepare_editor_preview()
	if start_override.size()==3:
		var base: float=game.building.spec.levels[floor]
		game.place_player(Vector3(float(start_override[0]),base+float(start_override[1]),float(start_override[2])))
		if look_override.size()==3:
			var offset: Vector3=Vector3(float(look_override[0]),base+float(look_override[1]),float(look_override[2]))-game.camera.global_position
			game.body.rotation.y=atan2(-offset.x,-offset.z)
			game.camera.rotation=Vector3(atan2(offset.y,Vector2(offset.x,offset.z).length()),0,0)
	elif floor==14:
		var y: float=game.building.spec.levels[14]
		game.place_player(Vector3(16,y+.06,-8.3))
		var offset: Vector3=Vector3(16,y+2.5,-2)-game.camera.global_position
		game.body.rotation.y=atan2(-offset.x,-offset.z)
		game.camera.rotation=Vector3(atan2(offset.y,Vector2(offset.x,offset.z).length()),0,0)
	for i in 15:await physics_frame
	DisplayServer.window_set_title("Ada / Floor %d / %s"%[floor,game.building.content.data.floors[floor].title])
	game._notice("FLOOR %d / %s\nWASD: move · Mouse: look · Space: jump · Esc: release mouse"%[floor,game.building.content.data.floors[floor].title])
	await process_frame;await RenderingServer.frame_post_draw
	var image_path := folder.path_join("desktop-ready.png")
	root.get_texture().get_image().save_png(image_path)
	game.body.scripted_input=false;game.body.set_process_unhandled_input(true)
	Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
	var ready := {"ready":game.ready_for_play,"floor":floor,"grounded":game.body.is_on_floor(),
		"human_control":not game.body.scripted_input,"paused":paused,"model_b_brain_attached":false,
		"position":[game.body.global_position.x,game.body.global_position.y,game.body.global_position.z],"screenshot":image_path}
	FileAccess.open(folder.path_join("desktop-ready.json"),FileAccess.WRITE).store_string(JSON.stringify(ready,"  "))
	print("VOID_DESKTOP_READY ",JSON.stringify(ready))
