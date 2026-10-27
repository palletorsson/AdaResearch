extends SceneTree
## Human play only: read the latest saved tower; keep tour/spawn state in memory.
const OUT := "res://ada_run/matter-studies-desktop/"
var game: Node3D
var index := 0
var busy := false
var caption: Label
var stops := [
	{"id":"matter-leaning-together","title":"LEANING TOGETHER / BRITTLE","tip":"Left click: light tap. Right click: hold / release.\nQ/E: roll · Z/X: tilt · Shift+Q/E: yaw."},
	{"id":"matter-friction-ramp","title":"LET GO / THE SLOPE","tip":"LESS / MORE: change angle. SURFACE: contact material.\nRELEASE: let gravity decide. RESET: try again."},
	{"id":"matter-friction-coast","title":"KEEP GOING / SAME PUSH","tip":"SAME PUSH: equal impulses on two contact surfaces.\nCompare their stopping distances. RESET: try again."},
	{"id":"matter-friction-pull","title":"ALMOST ENOUGH / HANGING WEIGHT","tip":"LESS / MORE: hanging mass. SURFACE: contact material.\nRELEASE: the weight pulls over shaft A. RESET: try again."}
]

class TourKeys extends Node:
	var launcher: SceneTree
	func _input(event: InputEvent) -> void:
		if not event is InputEventKey or not event.pressed or event.echo:return
		if event.keycode==KEY_F6:launcher.visit(launcher.index+1)
		elif event.keycode==KEY_F7:launcher.visit(launcher.index-1)
		elif event.keycode==KEY_F8:launcher.reset_current()
		else:return
		get_viewport().set_input_as_handled()

func _initialize() -> void:open_game.call_deferred()

func work() -> Node3D:
	return game.building.content.exhibits["46/"+str(stops[index].id)].get_node("Artifact")

func face_work() -> void:
	var delta: Vector3 = work().to_global(Vector3(0,1.15,0))-game.body.camera.global_position
	game.body.rotation.y = atan2(-delta.x,-delta.z)
	game.body.camera.rotation = Vector3(atan2(delta.y,Vector2(delta.x,delta.z).length()),0,0)

func visit(next: int) -> void:
	if busy:return
	busy = true;index = posmod(next,stops.size())
	var at: Vector3 = work().get_node("Controls").to_global(Vector3(0,0,1.5));at.y = game.building.spec.levels[46]+.06
	game.building.spec.get_or_add("spawn_points",{})["46"] = [at.x,.06,at.z]
	game.place_player(at);game.checkpoint = 46
	for n in 15:await physics_frame
	face_work();game.body.camera.make_current()
	caption.text = "%d / %d   %s\nF6: next · F7: previous · F8: reset this study\n%s"%[index+1,stops.size(),stops[index].title,stops[index].tip]
	DisplayServer.window_set_title("Ada / Floor 46 / "+str(stops[index].title)+" / F6 next")
	busy = false

func reset_current() -> void:
	if not busy and is_instance_valid(work()):work().reset_take()

func make_tour_ui() -> void:
	var layer := CanvasLayer.new();game.add_child(layer)
	var panel := PanelContainer.new();panel.mouse_filter = Control.MOUSE_FILTER_IGNORE;panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT);panel.offset_left = -515;panel.offset_right = -16;panel.offset_top = 18;panel.offset_bottom = 145;layer.add_child(panel)
	var style := StyleBoxFlat.new();style.bg_color = Color(.045,.035,.055,.92);style.border_color = Color("ee478f");style.border_width_left = 3
	style.content_margin_left = 14;style.content_margin_right = 14;style.content_margin_top = 12;style.content_margin_bottom = 12;panel.add_theme_stylebox_override("panel",style)
	caption = Label.new();caption.mouse_filter = Control.MOUSE_FILTER_IGNORE;caption.add_theme_color_override("font_color",Color("eee9dd"));caption.add_theme_font_size_override("font_size",17);panel.add_child(caption)
	var keys := TourKeys.new();keys.launcher = self;game.add_child(keys)

func open_game() -> void:
	load("res://commons/void/room_source.gd").use_main_tower = true
	game = load("res://commons/void/void.tscn").instantiate();game.force_xr = false;root.add_child(game);current_scene = game;game.scene_loaded();game.scene_visible()
	for n in 600:
		if game.building.content.exhibits.has("46/matter-leaning-together") and game.floor_stream.focus==46:break
		await physics_frame
	for n in 20:await physics_frame
	make_tour_ui();game.body.camera.fov = 85;await visit(0)
	game.body.set_process_unhandled_input(false);Input.mouse_mode = Input.MOUSE_MODE_VISIBLE;paused = true
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+"desktop-ready.png")
	var at: Vector3 = game.body.global_position
	FileAccess.open(OUT+"desktop-ready.json",FileAccess.WRITE).store_string(JSON.stringify({"ready":game.ready_for_play,"floor":game.checkpoint,"study":stops[index].id,"position":[at.x,at.y,at.z],"on_floor":game.body.is_on_floor(),"standing_cube_y":work().bodies.Cube.position.y,"parts_live":work().bodies.values().all(func(body):return not body.freeze),"studies":stops.map(func(stop):return stop.title)},"  "))
	while not FileAccess.file_exists(OUT+"launch-release.json"):await create_timer(.1,true).timeout
	face_work();game.body.set_process_unhandled_input(true);paused = false;Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	print("MATTER_STUDIES_DESKTOP_READY / human owns native session / F6 next / F7 previous / F8 reset")
