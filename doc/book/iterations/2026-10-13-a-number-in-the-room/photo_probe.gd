extends "res://tools/probes/transformation_encounters.gd"
func landing_checks() -> void:
	museum.call("flush_stamps")
	await create_timer(0.5).timeout
	var demo := find_scene("/seed_replay_demo.gd")
	check("saved 435 appears on arrival", demo != null and demo.current_seed() == 435 and demo._large_seed.text == "435")
	if demo == null: return
	check("panels agree before discard", demo.column_colors(0) == demo.column_colors(1))
	await snapshot("opening-435",demo.to_global(Vector3(0,2.2,4.6)),demo.to_global(Vector3(0,2.5,0)),58)
	var left: PackedColorArray = demo.column_colors(0)
	demo.toggle_extra_draw()
	check("only right colours change", demo.column_colors(0) == left and demo.column_colors(1) != left)
	await snapshot("one-draw-later",demo.to_global(Vector3(0,2.2,4.6)),demo.to_global(Vector3(0,2.5,0)),58)
	check("photos needed no network", not demo._atmosphere_client.is_busy())
	observations["scope"] = "Actual museum, saved response 435, same camera for both pictures. No new atmospheric request."
