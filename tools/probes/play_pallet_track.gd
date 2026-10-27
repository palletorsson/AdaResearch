extends SceneTree
## Human play launch: latest saved tower, no changes to the shared arrangement.
const OUT := "res://ada_run/pallet-desktop/"
var game: Node3D
var track: Node3D
var study_id := "pallet-hand-workshop"
func _initialize() -> void:open_game.call_deferred()
func face_track() -> void:
	var delta: Vector3 = track.to_global(Vector3(0,.80,0))-game.body.camera.global_position
	game.body.rotation.y = atan2(-delta.x,-delta.z)
	game.body.camera.rotation = Vector3(atan2(delta.y,Vector2(delta.x,delta.z).length()),0,0)
func open_game() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--pallet-study-id="):study_id = arg.trim_prefix("--pallet-study-id=")
	load("res://commons/void/room_source.gd").use_main_tower = true
	game = load("res://commons/void/void.tscn").instantiate();game.force_xr = false
	root.add_child(game);current_scene = game;game.scene_loaded();game.scene_visible()
	for i in 600:
		if game.building.content.exhibits.has("12/"+study_id) and game.floor_stream.focus==12:break
		await physics_frame
	for i in 20:await physics_frame
	track = game.building.content.exhibits["12/"+study_id].get_node("Artifact")
	var at: Vector3 = track.to_global(Vector3(0,.06,1.75))
	game.building.spec.get_or_add("spawn_points",{})["12"] = [at.x,.06,at.z]
	game.place_player(at);game.checkpoint = 12
	for i in 12:await physics_frame
	game.body.camera.fov = 85;game.body.set_process_unhandled_input(false);face_track();game.body.camera.make_current()
	DisplayServer.window_set_title("Ada / Floor 12 / Pallet OR / two paths" if study_id=="pallet-or-workshop" else "Ada / Floor 12 / Pallet AND track + TRUE cone")
	game._notice("FLOOR 12 / MATERIAL SUPPORT AND\nRight click: grab / release a block. X Y Z: turn held wood.\nLeft click BALL: release. Bridge both gaps to hit TRUE. RESET restores the study.\nWASD: walk. Mouse: look. Esc: release mouse.")
	if study_id=="pallet-or-workshop":game._notice("FLOOR 12 / MATERIAL SUPPORT OR\nRight click: grab / release a support. X Y Z: turn held wood.\nBALL releases both balls. Either supported lane can hit TRUE. RESET restores the study.\nWASD: walk. Mouse: look. Esc: release mouse.")
	paused = true;await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+"desktop-ready.png")
	FileAccess.open(OUT+"desktop-ready.json",FileAccess.WRITE).store_string(JSON.stringify({"ready":game.ready_for_play,"floor":game.checkpoint,"position":[game.body.global_position.x,game.body.global_position.y,game.body.global_position.z],"on_floor":game.body.is_on_floor(),"track_height":track.track_height,"wood_parts":track.pieces.size(),"has_cone":track.has_node("TrueCone"),"logic_grammar":track.logic_grammar,"study":track.study} ,"  "))
	while not FileAccess.file_exists(OUT+"launch-release.json"):await create_timer(.1,true).timeout
	face_track();game.body.set_process_unhandled_input(true);paused = false
	print("PALLET_DESKTOP_READY / human owns the native session")
