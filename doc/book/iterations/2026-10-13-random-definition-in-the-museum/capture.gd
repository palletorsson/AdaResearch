extends "res://tools/probes/transformation_encounters.gd"

func landing_checks() -> void:
	museum.call("flush_stamps")
	await create_timer(0.7).timeout
	var demo := find_scene("/seed_replay_demo.gd")
	var textile := find_scene("/dna_comparison.gd")
	var book := find_scene("/random_number_book_page_1995.gd")
	check("current hall contains seed bench, textiles and number page", demo != null and textile != null and book != null)
	if demo == null or textile == null or book == null: return
	observations["artifact_positions"] = {"seed":xyz(demo.global_position),"textile":xyz(textile.global_position),"book":xyz(book.global_position)}
	demo.restore_museum_state({"seed":42,"extra_on":false,"side":8})
	await tick()
	var kept: PackedColorArray = demo.column_colors(0)
	check("matching grids before extra draw", kept == demo.column_colors(1))
	await snapshot("seed-before",demo.to_global(Vector3(0,2.0,4.4)),demo.to_global(Vector3(0,1.9,0)),53)
	demo.toggle_extra_draw()
	await tick()
	check("one discarded draw changes only the right grid",demo.column_colors(0)==kept and demo.column_colors(1)!=kept)
	await snapshot("seed-after",demo.to_global(Vector3(0,2.0,4.4)),demo.to_global(Vector3(0,1.9,0)),53)
	await snapshot("seed-in-room",demo.to_global(Vector3(-2.4,1.65,5.0)),demo.to_global(Vector3(0,1.7,0)),65)
	await snapshot("textile-front",textile.to_global(Vector3(0,1.65,-5.5)),textile.to_global(Vector3(0,1.0,0)),55)
	await snapshot("textile-back",textile.to_global(Vector3(0,1.65,5.5)),textile.to_global(Vector3(0,1.0,0)),55)
	await snapshot("number-page-front",book.to_global(Vector3(0,0,-8)),book.global_position,51)
	await snapshot("number-page-back",book.to_global(Vector3(0,0,8)),book.global_position,51)
	observations["scope"]="Fresh Godot renders of existing Endless Museum hall. Seed state set through artifact API; no geometry or materials changed. Not headset captures."

func finish() -> void:
	var result := {"room":map_id,"checks":checks,"failures":failures,"observations":observations,"passed":failures.is_empty()}
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	print("RANDOM DEFINITION PHOTOGRAPHS ",checks.size()-failures.size(),"/",checks.size())
	quit(0 if failures.is_empty() else 1)
