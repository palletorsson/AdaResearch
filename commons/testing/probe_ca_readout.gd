extends SceneTree
## CA_Introduction's explorer (#study:neighbours #rule:90 #room:ring) and its readout, headless:
## what the witness plate says at generation 5 (Pascal mod 2), at 16 (all dead, the ring of 32
## cancelled), under #ring:odd at 20 (alive), and with the SEED pair (never Pascal). Writes
## ada_run/ca_ring/readout.json; exit 1 on a failed check.


func _init() -> void:
	var report := {"checks": [], "pass": true, "texts": {}}
	var e := await _explorer("")
	_step(e, 5)
	var t5 := _reading(e)
	report["texts"]["gen5"] = t5
	_check(report, "generation 5 reads Pascal's triangle", "PASCAL'S TRIANGLE MOD 2" in t5 and not "ALL DEAD" in t5)
	_step(e, 11)
	var t16 := _reading(e)
	report["texts"]["gen16"] = t16
	_check(report, "generation 16 on 32 cells: all dead, and why", "ALL DEAD SINCE GEN 16" in t16 and "RING OF 32" in t16 and int(e.get("cells_x")) == 32)
	e.call("toggle_seed")
	_step(e, 3)
	var tp := _reading(e)
	report["texts"]["pair3"] = tp
	_check(report, "the SEED pair never reads as Pascal", not "PASCAL" in tp)
	e.queue_free()
	await process_frame
	var odd := await _explorer("odd")
	_step(odd, 20)
	var t20 := _reading(odd)
	report["texts"]["odd20"] = t20
	_check(report, "#ring:odd: 33 cells, still alive at generation 20", int(odd.get("cells_x")) == 33 and not "ALL DEAD" in t20 and (odd.get("_current_row") as Array).has(true))
	var f := FileAccess.open(ProjectSettings.globalize_path("res://ada_run/ca_ring/readout.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(report))
	f.close()
	quit(0 if report["pass"] else 1)


func _explorer(ring: String) -> Node3D:
	var e: Node3D = load("res://commons/artifacts/ca_rule_explorer/ca_rule_explorer.tscn").instantiate()
	e.set_meta("config_study", "neighbours")
	e.set_meta("config_rule", 90)
	e.set_meta("config_room", "ring")
	if ring != "":
		e.set_meta("config_ring", ring)
	root.add_child(e)
	for i in 3:
		await process_frame
	return e


func _step(e: Node3D, n: int) -> void:
	for i in n:
		e.call("step")


func _reading(e: Node3D) -> String:
	var study: Node = e.get_node("NeighbourStudy")
	study.call("refresh")
	return (study.get("reading") as Label3D).text


func _check(report: Dictionary, what: String, ok: bool) -> void:
	report["checks"].append({"check": what, "pass": ok})
	if not ok:
		report["pass"] = false
