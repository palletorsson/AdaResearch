extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var em: Node3D = load("res://commons/scenes/endless_museum.gd").new()
	em.set("_plan_path", "res://ada_run/em_plan.json")
	em.call("_load_plan")
	var sequence: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://commons/maps/sequences/foundationscrisis.json"))
	var declared: Array = sequence.sequences.foundationscrisis.maps
	var expected: Array = declared.filter(func(m): return m != "Florensky_Paraconsistent")
	var owners: Dictionary = em.get("_plan_owner")
	var key: String = str(owners.get("foundationscrisis", ""))
	em.set("_museums", [{"key": key}])
	em.set("_pool", [{"sequence": "foundationscrisis"}])
	var checks: Array = []
	var route: Array = []
	checks.append({"ok": expected.size() == 7 and not key.is_empty(), "message": "seven currently authored halls; Florensky restoration pending"})
	for i in expected.size():
		var chosen: String = str(em.call("_peek_next_authored_map"))
		route.append(chosen)
		checks.append({"ok": chosen == expected[i], "message": "select " + str(expected[i])})
		checks.append({"ok": str(em.call("_chapter_of_map", chosen)) == "foundationscrisis", "message": "owner for " + chosen})
		var more: bool = em.call("_advance_pearl", key, "foundationscrisis")
		checks.append({"ok": more == (i < expected.size() - 1), "message": "advance from " + chosen})
	checks.append({"ok": str(em.call("_peek_next_authored_map")) == expected[0], "message": "chapter cursor resets after final hall"})
	var failed := checks.filter(func(c): return not c.ok)
	var f := FileAccess.open("res://doc/book/iterations/2026-09-20-foundations-opening-review/navigation.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks": checks, "failures": failed, "route": route, "pending_missing_hall":"Florensky_Paraconsistent", "scope": "Production plan selection; not a physical portal-crossing test", "headset_tested": false}, "  "))
	f.close()
	em.free()
	print("GT_NAVIGATION ", checks.size(), " checks; failures=", failed.size())
	quit(0 if failed.is_empty() else 1)
