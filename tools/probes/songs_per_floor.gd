extends SceneTree
## How many songs does each floor of the tower sing? Read from the running game: the opera's own selection
## (inner_opera.by_floor, after the published trajectory and the opening trail's frames), counted for the works
## that stand on each floor now. Palle, 23 November 2026: "in some of map there is like more then 10 songs that
## is to many" - the limit is ten.
##
##   python tools/run_floor_probe.py Point_Animatedcube songs_per_floor.gd songs_per_floor.json <folder> --no-opening --opera-quiet

const LIMIT := 10

var folder := "res://ada_run/songs_per_floor"


func _initialize() -> void:
	run.call_deferred()


func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): folder = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(folder)
	load("res://commons/void/room_source.gd").use_main_tower = true
	var game: Node = load("res://commons/void/void.tscn").instantiate()
	if OS.get_cmdline_user_args().has("--xr"): game.force_xr = true
	root.add_child(game); current_scene = game
	if game.body.get("scripted_input") != null:
		game.body.scripted_input = true; game.body.set_process_unhandled_input(false)
	game.scene_loaded(); game.scene_visible()
	var index := int(game.checkpoint)
	var result := {"floor": index, "checks": [], "passed": false}
	for i in 900: await physics_frame
	var opera: Node = game.get_meta("inner_opera", null) as Node
	var checks: Array = result.checks
	if opera == null or not is_instance_valid(opera):
		checks.append({"check": "the opera is in the game", "ok": false})
		_done(result); return
	checks.append({"check": "the opera has its score", "ok": str(opera.get("score_error")).is_empty(), "error": str(opera.get("score_error"))})
	var floors: Array = game.building.content.data.floors
	var by_floor: Dictionary = opera.get("by_floor")
	var counts := {}
	var over := []
	var most := 0
	var sum := 0
	var singing := 0
	for i in floors.size():
		var here := {}
		for kind in ["artifacts", "copies", "props"]:
			for row: Dictionary in floors[i].get(kind, []): here[str(row.get("id", ""))] = true
		var songs := {}
		var wanted: Dictionary = by_floor.get(i, {})
		for target in wanted:
			if here.has(str(target).get_slice("/", 0)): songs[str(wanted[target])] = true
		counts[str(floors[i].map)] = songs.size()
		sum += songs.size()
		if songs.size() > 0: singing += 1
		most = maxi(most, songs.size())
		if songs.size() > LIMIT: over.append([i, str(floors[i].map), songs.size()])
	result["floors"] = floors.size()
	result["floors_that_sing"] = singing
	result["songs_in_all"] = sum
	result["most_on_one_floor"] = most
	result["counts"] = counts
	checks.append({"check": "no floor sings more than ten songs", "ok": over.is_empty(), "over": over})
	checks.append({"check": "the tower still sings", "ok": sum > 800 and singing > 150, "songs": sum, "floors": singing})
	# the floor the game stands on: what the opera has bound of it
	var bound: Dictionary = opera.get("bound")
	var here_bound := 0
	for key in bound:
		if str(key).begins_with("%d/" % index): here_bound += 1
	result["bound_on_this_floor"] = here_bound
	checks.append({"check": "this floor's songs are bound to what stands on it", "ok": here_bound > 0 and int(counts.get(str(floors[index].map), 0)) <= LIMIT, "bound_rows": here_bound, "songs": counts.get(str(floors[index].map), 0)})
	_done(result)


func _done(result: Dictionary) -> void:
	result.passed = (result.checks as Array).all(func(c): return c.ok)
	var file := FileAccess.open(folder.path_join("songs_per_floor.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "  "))
	file.close()
	quit()
