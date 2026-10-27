extends "res://tools/probes/rotation_electric.gd"
## Visual-only follow-up to the completed real-input/contact receipt.
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out=arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(out);Source.use_main_tower=true;root.size=Vector2i(1600,1000)
	await start(false)
	game.place_player(Vector3(-6.4,Y+3.55,4.5));await frames(30)
	check("unmodified tc boarding collision",artifact("gantry-tc").platform.static_body.get_node("CollisionShape3D").shape.size.is_equal_approx(Vector3(2,1,2)))
	check("same 3.5m transport route",is_equal_approx(artifact("gantry-tc").platform.move_distance,3.5))
	game.floor_stream.set_process(false);game.floor_stream.set_physics_process(false)
	var shown:Array[int]=[16];game.building.show_floor_window(shown)
	for key in game.building.content.roots:game.building.content.roots[key].visible=int(key)==16
	if game.desktop_help:game.desktop_help.visible=false
	await picture("01-electric-course",Vector3(-8,7.4,10),Vector3(0,2.6,0))
	await picture("02-one-metre-pair",Vector3(-3.8,5.15,-1.5),Vector3(1.8,3.05,-1.5))
	check("tc visible at its upper dock",await wait_lift(artifact("gantry-tc").platform,true))
	await picture("03-tc-gantry",Vector3(-12,5.3,9.5),Vector3(-7,2.4,3.7))
	FileAccess.open(out.path_join("capture-checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"scope":"Native visual capture after tc cyan finish; transport shape and route unchanged. Full physics/death tests are in the parent checks.json."},"  "))
	print("ROTATION_VISUAL_RESULT ",failed.size());quit(0 if failed.is_empty() else 1)
