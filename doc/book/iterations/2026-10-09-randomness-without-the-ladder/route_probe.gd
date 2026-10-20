extends SceneTree
## Exercise the real museum plan loader without building or modifying rooms.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: PackedScene = load("res://commons/scenes/endless_museum.tscn")
	var museum := scene.instantiate()
	museum.set("_portal_mode", true)
	museum.set("_plan_path", "res://commons/data/museum/em_plan.json")
	museum.call("_load_plan")
	var groups: Dictionary = museum.get("_plan_pearls")
	var route: Array[String] = []
	for rows in groups.values():
		for row in rows:
			if row.get("sequence") == "randomness":
				route.append(row.get("map", ""))
	var expected: Array = JSON.parse_string(FileAccess.get_file_as_string("res://commons/data/map_authored.json"))["randomness"]
	var passed := route == expected and route.size() == 15
	passed = passed and route[-1] == "Random_Game"
	passed = passed and route.has("Biome_Cage") and not route.has("Biome_Ladder_Randomness")
	print("RANDOMNESS_ROUTE ", JSON.stringify({"passed": passed, "route": route, "scope": "Actual plan loader; no rooms built, no headset traversal."}))
	museum.free()
	quit(0 if passed else 1)
