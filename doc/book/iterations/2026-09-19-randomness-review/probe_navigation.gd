extends SceneTree

const OUT = "res://doc/book/iterations/2026-09-19-randomness-review/navigation.json"
var checks: Array = []

func check(ok: bool, message: String) -> void:
	checks.append({"ok": ok, "message": message})

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	# Exercise production plan selection without constructing sixteen spaces.
	var script: Script = load("res://commons/scenes/endless_museum.gd")
	if script == null or not script.can_instantiate():
		push_error("Museum script is not instantiable; see current-source diagnostics")
		quit(2)
		return
	var em: Node3D = script.new()
	em.set("_plan_path", "res://ada_run/em_plan.json")
	em.call("_load_plan")
	var sequence: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://commons/maps/sequences/randomness.json"))
	var declared: Array = sequence.sequences.randomness.maps
	var owners_file: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://commons/data/map_authored.json"))
	var expected: Array = owners_file.randomness
	check(expected.size() == 16, "sixteen museum spaces including two biome interludes")
	check(expected.filter(func(n): return n in declared) == declared, "fourteen book chapters occur in declared order")
	var owners: Dictionary = em.get("_plan_owner")
	var key: String = str(owners.get("randomness", ""))
	check(not key.is_empty(), "Randomness has a museum plan owner")
	em.set("_museums", [{"key": key}])
	em.set("_pool", [{"sequence": "randomness"}])
	var route: Array = []
	var raw_exits: Array = []
	var holder := Node3D.new()
	for i in expected.size():
		var map_name: String = str(em.call("_peek_next_authored_map"))
		route.append(map_name)
		check(map_name == expected[i], "plan position %d selects %s" % [i + 1, expected[i]])
		check(str(em.call("_chapter_of_map", map_name)) == "randomness", "authored ownership for " + map_name)
		var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://commons/maps/%s/map_data.json" % expected[i]))
		for row: Array in data.layers.utilities:
			for cell in row:
				var spec := str(cell)
				if spec == "t" or spec.begins_with("t:"):
					raw_exits.append({"map": expected[i], "utility": spec})
					check(em.call("_stamp_utility", spec, Vector2i.ZERO, holder, 0) == null,
						"museum refuses legacy teleporter in " + str(expected[i]))
		var more: bool = em.call("_advance_pearl", key, "randomness")
		check(more == (i < expected.size() - 1), "cursor advance at " + str(expected[i]))
	check(holder.get_child_count() == 0, "no legacy teleporter nodes instantiated")
	check(route == expected, "all sixteen museum plan entries match authored route")
	check(str(em.call("_peek_next_authored_map")) == expected[0], "chapter cursor resets after final pearl")
	var failed := checks.filter(func(c): return not c.ok)
	var f := FileAccess.open(OUT, FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks": checks, "failures": failed, "route": route,
		"raw_exits": raw_exits, "scope": "Production plan selection and utility refusal; no physical portal crossing or full route walk", "headset_tested": false}, "  "))
	f.close()
	holder.free()
	em.free()
	print("RANDOMNESS_NAVIGATION ", checks.size(), " checks; failures=", failed.size())
	quit(0 if failed.is_empty() else 1)
