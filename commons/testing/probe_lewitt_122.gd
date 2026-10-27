extends SceneTree
## Tutorial_3D's open study, mode 4: open_rules.gd enumerates LeWitt's incomplete open cubes
## (the list goes to ada_run/address_rules/lewitt_gd.json for tools/address_rules_crosscheck.py
## --lewitt to compare with the lab's), builds the 122 as bars, and the station script that offers
## the 122 button still loads. Exit 1 when a check fails.


func _init() -> void:
	var report := {"checks": [], "pass": true}
	var Open := load("res://commons/artifacts/spine_studies/open_rules.gd")
	var masks: Array = Open.incomplete_open_cubes()
	report["masks"] = masks
	_check(report, "the enumeration finds %d (LeWitt found 122)" % masks.size(), masks.size() == 122)
	var study: Node3D = Open.new()
	root.add_child(study)
	await process_frame
	var default_records: int = (study.get("records") as Array).size()
	study.set("mode", 4)
	study.call("rebuild")
	await process_frame
	var records: Array = study.get("records")
	var bars: int = int(study.get("total_edges"))
	var expected_bars := 0
	for m in masks:
		for i in 12: expected_bars += (int(m) >> i) & 1
	_check(report, "mode 4 builds 122 cubes with %d bars, one per kept edge" % bars, records.size() == 122 and bars == expected_bars)
	study.set("mode", 0)
	study.call("rebuild")
	await process_frame
	_check(report, "mode 0 rebuilds as before (%d records)" % (study.get("records") as Array).size(), (study.get("records") as Array).size() == default_records)
	_check(report, "station.gd, which offers the 122 button, loads", load("res://commons/artifacts/spine_studies/station.gd") != null)
	var f := FileAccess.open(ProjectSettings.globalize_path("res://ada_run/address_rules/lewitt_gd.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(report))
	f.close()
	quit(0 if report["pass"] else 1)


func _check(report: Dictionary, what: String, ok: bool) -> void:
	report["checks"].append({"check": what, "pass": ok})
	if not ok:
		report["pass"] = false
