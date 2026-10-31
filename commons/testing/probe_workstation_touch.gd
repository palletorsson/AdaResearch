extends Node3D
## TOUCH IS THE TOOL on the scaffold workstation (Palle, 2026-10-31): a hand within reach of a part on the arc makes it
## the current tool; the bare hand on a lit socket paints that part; the RUBBER on the arc erases the same way. A fake
## hand (a Node3D standing in for XR Tools' pickup) does the touching: (A) touching the POINT stock selects it and lights
## its sockets; (B) the hand held on the +X half-step socket for a fifth of a second adds a point there, nothing while
## the hand is on the arc; (C) touching the RUBBER makes it the tool and the hand on the point removes it; (D) UNDO
## brings the point back. Writes ada_run/workstation/touch.json.
## Run: godot --path . --xr-mode off --resolution 1280x800 res://commons/testing/probe_workstation_touch.tscn

const POINTS = preload("res://commons/artifacts/scaffold_workstation/points.tscn")

func _ready() -> void:
	var out_dir := ProjectSettings.globalize_path("res://ada_run/workstation");DirAccess.make_dir_recursive_absolute(out_dir)
	var cam := Camera3D.new();cam.position = Vector3(0, 1.6, 1.5);add_child(cam);cam.current = true
	var report := {"checks": []}
	var pts: Node3D = POINTS.instantiate();pts.set_meta("config_persist", false);add_child(pts)
	for i in 6:
		await get_tree().process_frame
	var hand := Node3D.new();hand.name = "FakeHand";add_child(hand)
	# A - touch the point stock
	var stock: Node3D = pts.tools["point"]
	hand.global_position = stock.global_position
	stock.request_highlight(hand, true)
	await get_tree().process_frame
	var lit: int = pts.sockets.get_child_count()
	_check(report, "A touch: the POINT stock touched is the tool; its sockets are lit; the stock stands a quarter larger", pts.tool_kind == "point" and pts.brush_hand == hand and lit > 0 and is_equal_approx(stock.get_child(0).scale.x, 1.8 * 1.25), {"tool": pts.tool_kind, "lit": lit, "scale": stock.get_child(0).scale.x})
	# B - the hand on the arc paints nothing; on the +X half-step socket it paints a point
	for i in 10:
		pts._bare_brush(0.05)
	var none_on_arc: bool = pts.model.records.is_empty()
	stock.request_highlight(hand, false)
	var socket: Vector3 = pts.bench.to_global(Vector3(0.5, 0, 0) * pts.step())
	hand.global_position = socket + Vector3(0.005, 0.005, 0)
	for i in 10:
		pts._bare_brush(0.05)
	var painted: bool = pts.model.records.size() == 1 and pts.model.records[0].kind == "point" and Vector3(pts.model.vec(pts.model.records[0].at)).is_equal_approx(Vector3(0.5, 0, 0))
	# staying put paints no second point; the next socket does
	for i in 10:
		pts._bare_brush(0.05)
	var once: bool = pts.model.records.size() == 1
	hand.global_position = pts.bench.to_global(Vector3(1.0, 0, 0) * pts.step())
	for i in 10:
		pts._bare_brush(0.05)
	var twice: bool = pts.model.records.size() == 2
	_check(report, "B paint: nothing while the hand is on the arc; on the +X half-step socket a point after a fifth of a second; staying put adds none; the next socket adds the next", none_on_arc and painted and once and twice, {"on_arc": none_on_arc, "painted": painted, "once": once, "twice": twice, "records": pts.model.records})
	# C - the rubber
	var rubber: Node3D = pts.tools["remove"]
	hand.global_position = rubber.global_position;rubber.request_highlight(hand, true)
	await get_tree().process_frame
	var rubber_tool: bool = pts.tool_kind == "remove"
	rubber.request_highlight(hand, false)
	hand.global_position = pts.bench.to_global(Vector3(1.0, 0, 0) * pts.step())
	for i in 10:
		pts._bare_brush(0.05)
	var removed: bool = pts.model.records.size() == 1
	_check(report, "C rubber: touching RUBBER makes it the tool; the hand on the second point removes it", rubber_tool and removed, {"tool": pts.tool_kind, "records": pts.model.records.size()})
	# D - undo brings it back
	pts.undo()
	_check(report, "D undo: the removed point is back", pts.model.records.size() == 2, {"records": pts.model.records.size()})
	var passed := 0
	for ch in report.checks:
		if ch.ok:passed += 1
	report["passed"] = passed;report["of"] = report.checks.size()
	var o := FileAccess.open(out_dir.path_join("touch.json"), FileAccess.WRITE);o.store_string(JSON.stringify(report, "  "));o.close()
	print("[probe_workstation_touch] %d/%d" % [passed, report.checks.size()])
	get_tree().quit(0 if passed == report.checks.size() else 1)

func _check(report: Dictionary, what: String, ok: bool, data: Dictionary) -> void:
	report.checks.append({"what": what, "ok": ok, "data": data})
	print("[probe_workstation_touch] %s  %s" % ["ok  " if ok else "FAIL", what])
