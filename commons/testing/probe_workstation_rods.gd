extends Node3D
## THE LONG RODS (Palle, 2026-10-31: "1, 2, 4, 8 m rods - a 6-ball at every metre, a faster way to build"). On the
## Lines station: (A) the arc carries a 4 M ROD stock, a chain of four one-metre rods with three joints between;
## (B) laid from the origin along +X by the bare hand it adds four points (every metre) and four one-metre rods -
## eight atomic records, no macro record; (C) laid again over the same line it is refused; across an existing 2 m
## rod it adds only what is missing; (D) UNDO takes the whole chain back in one step; (E) the 8 m rod is in the
## grammar but has no socket on this 6 m bench. Writes ada_run/workstation/rods.json.
## Run: godot --path . --xr-mode off --resolution 1280x800 res://commons/testing/probe_workstation_rods.tscn

const LINES = preload("res://commons/artifacts/scaffold_workstation/lines.tscn")
const Arc = preload("res://commons/artifacts/scaffold_workstation/parts_arc.gd")

func _ready() -> void:
	var out_dir := ProjectSettings.globalize_path("res://ada_run/workstation");DirAccess.make_dir_recursive_absolute(out_dir)
	var cam := Camera3D.new();cam.position = Vector3(0, 1.6, 1.5);add_child(cam);cam.current = true
	var report := {"checks": []}
	var st: Node3D = LINES.instantiate();st.set_meta("config_persist", false);add_child(st)
	for i in 6:
		await get_tree().process_frame
	var stock: Node3D = st.tools.get("rod_4")
	var chain_rods := 0;var chain_joints := 0
	if stock:
		for c in stock.get_child(0).get_children():
			if c is MeshInstance3D and c.mesh is BoxMesh:chain_rods += 1
			if c is MeshInstance3D and c.mesh is SphereMesh:chain_joints += 1
	_check(report, "A arc: a 4 M ROD stock on the rack - four one-metre rods, three joints between", stock != null and chain_rods == 4 and chain_joints == 3 and Arc.ORDER.find("rod_4") == 3, {"stock": stock != null, "rods": chain_rods, "joints": chain_joints})
	# B - laid from the origin along +X by the bare hand
	var hand := Node3D.new();add_child(hand)
	st.select_tool("rod_4", hand)
	hand.global_position = st.bench.to_global(Vector3(1.0, 0, 0) * st.step())   # the chain's centre: a to b = 0..2 units
	for i in 10:
		st._bare_brush(0.05)
	var recs: Array = st.model.records
	var pts: Array = recs.filter(func(r): return r.kind == "point");var rods: Array = recs.filter(func(r): return r.kind == "rod_short")
	var at_metres: bool = pts.size() == 4 and rods.size() == 4 and recs.size() == 8 and pts.map(func(r): return float(r.at[0])) == [0.5, 1.0, 1.5, 2.0]
	_check(report, "B lay: from the origin along +X the bare hand adds four points (every metre) and four one-metre rods - eight atomic records", at_metres, {"records": recs})
	# C - over the same line again: refused; across an existing 2 m rod: only the missing parts
	var again: bool = st.model.add({"kind": "rod_4", "at": [0, 0, 0], "end": [2, 0, 0]}, 1)
	st.model.add({"kind": "point", "at": [0, 0, 1]}, 1);st.model.add({"kind": "rod", "at": [0, 0, 0], "end": [0, 0, 1]}, 1)
	var n_before: int = st.model.records.size()
	var across: bool = st.model.add({"kind": "rod_4", "at": [0, 0, 0], "end": [0, 0, 2]}, 1)
	var added: Array = st.model.records.slice(n_before)
	var only_missing: bool = across and added.size() == 5 and added.filter(func(r): return r.kind == "point").size() == 3 and added.filter(func(r): return r.kind == "rod_short").size() == 2
	_check(report, "C smart: the same line again is refused; across an existing 2 m rod only the missing joints (3) and rods (2) are added", not again and only_missing, {"again": again, "across": across, "added": added})
	# D - undo: the chain laid by the hand went in as one edit
	st.model.records.assign(st.model.records.slice(0, 8));st.redraw()
	st.undo()
	_check(report, "D undo: one UNDO takes the whole four-metre chain back", st.model.records.is_empty(), {"records": st.model.records.size()})
	# E - the 8 m rod: in the grammar, no socket on a 6 m bench
	var eight_ok: bool = st.model.required_tier("rod_8") == 1 and st.model.is_macro("rod_8") and not st.tools.has("rod_8") and st.model.candidates("rod_8", 1).is_empty()
	_check(report, "E eight: rod_8 is in the grammar with no socket and no legal place on the 6 m bench", eight_ok, {"tools": st.tools.keys()})
	var passed := 0
	for ch in report.checks:
		if ch.ok:passed += 1
	report["passed"] = passed;report["of"] = report.checks.size()
	var o := FileAccess.open(out_dir.path_join("rods.json"), FileAccess.WRITE);o.store_string(JSON.stringify(report, "  "));o.close()
	print("[probe_workstation_rods] %d/%d" % [passed, report.checks.size()])
	get_tree().quit(0 if passed == report.checks.size() else 1)

func _check(report: Dictionary, what: String, ok: bool, data: Dictionary) -> void:
	report.checks.append({"what": what, "ok": ok, "data": data})
	print("[probe_workstation_rods] %s  %s" % ["ok  " if ok else "FAIL", what])
