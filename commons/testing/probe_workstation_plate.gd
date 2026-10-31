extends Node3D
## THE BIG PLATE (Palle, 2026-10-31: "a 4 m surface - we can remove the 6-ball at that middle position; less geometry in
## the final build"). On the Quads station (tier 3): (A) the arc carries a 4 M QUAD stock; (B) laid from the origin on
## the floor plane by the bare hand it lays the frame - a joint at every metre along the four sides, one-metre rods
## between - and ONE quad of span 2: 15 points, 16 rods, 1 quad, and no joint at the centre (1, 0, 1); (C) with a free
## joint standing at the centre beforehand, the plate takes it away; with a rod on it, it stays; (D) the fitted copy
## seats the frame's joints under the plate; (E) one UNDO takes the whole lay back. Writes ada_run/workstation/plate.json.
## Run: godot --path . --xr-mode off --resolution 1280x800 res://commons/testing/probe_workstation_plate.tscn

const QUADS = preload("res://commons/artifacts/scaffold_workstation/quads.tscn")
const Arc = preload("res://commons/artifacts/scaffold_workstation/parts_arc.gd")

func _ready() -> void:
	var out_dir := ProjectSettings.globalize_path("res://ada_run/workstation");DirAccess.make_dir_recursive_absolute(out_dir)
	var cam := Camera3D.new();cam.position = Vector3(0, 1.6, 1.5);add_child(cam);cam.current = true
	var report := {"checks": []}
	var st: Node3D = QUADS.instantiate();st.set_meta("config_persist", false);add_child(st)
	for i in 6:
		await get_tree().process_frame
	var stock: Node3D = st.tools.get("quad_4")
	_check(report, "A arc: a 4 M QUAD stock on the rack, after QUAD", stock != null and Arc.ORDER.find("quad_4") == 6 and stock.get_child(0).mesh is BoxMesh and is_equal_approx((stock.get_child(0).mesh as BoxMesh).size.x, 2.0 * st.SCALE), {"stock": stock != null, "tools": st.tools.keys(), "tier": st.tier})
	# B - the lay, by the bare hand over the plate's centre
	var hand := Node3D.new();add_child(hand)
	st.select_tool("quad_4", hand)
	hand.global_position = st.bench.to_global(Vector3(1.0, 0, 1.0) * st.step())
	for i in 10:
		st._bare_brush(0.05)
	var recs: Array = st.model.records
	var n_pts: int = recs.filter(func(r): return r.kind == "point").size();var n_rods: int = recs.filter(func(r): return r.kind == "rod_short").size()
	var quads: Array = recs.filter(func(r): return r.kind == "quad")
	var no_centre: bool = not recs.any(func(r): return r.kind == "point" and Vector3(st.model.vec(r.at)).is_equal_approx(Vector3(1, 0, 1)))
	var one_plate: bool = quads.size() == 1 and float(quads[0].get("span", 1)) == 2.0 and quads[0].plane == [0, 2]
	_check(report, "B lay: the frame at every metre (15 joints, 16 one-metre rods) and ONE plate of span 2, nothing at the centre", n_pts == 15 and n_rods == 16 and one_plate and no_centre and recs.size() == 32, {"points": n_pts, "rods": n_rods, "quads": quads, "no_centre": no_centre, "n": recs.size()})
	var laid: Array = st.model.records.duplicate(true)
	# C - a free joint at the centre is taken away; a joint with a rod on it stays
	# a point must be a cardinal neighbour of one that stands: the centre is reached by a path along the side and in
	var path: Array = [[0.5, 0, 0], [1, 0, 0], [1, 0, 0.5], [1, 0, 1]]
	st.model.records.clear()
	for at in path:st.model.add({"kind": "point", "at": at}, 3)
	var planted: bool = st.model.records.size() == 4
	var ok_free: bool = st.model.add({"kind": "quad_4", "at": [0, 0, 0], "plane": [0, 2]}, 3)
	var gone: bool = planted and ok_free and not st.model.records.any(func(r): return r.kind == "point" and Vector3(st.model.vec(r.at)).is_equal_approx(Vector3(1, 0, 1)))
	st.model.records.clear()
	for at in path:st.model.add({"kind": "point", "at": at}, 3)
	var roded: bool = st.model.add({"kind": "rod_short", "at": [1, 0, 0.5], "end": [1, 0, 1]}, 3)
	var ok_held: bool = st.model.add({"kind": "quad_4", "at": [0, 0, 0], "plane": [0, 2]}, 3)
	var stays: bool = roded and ok_held and st.model.records.any(func(r): return r.kind == "point" and Vector3(st.model.vec(r.at)).is_equal_approx(Vector3(1, 0, 1)))
	_check(report, "C centre: a free joint at the centre is taken away by the plate; one with a rod on it stays", gone and stays, {"planted": planted, "gone": gone, "roded": roded, "stays": stays, "ok_held": ok_held, "records": st.model.records.duplicate(true)})
	# D - the fitted copy seats the frame's joints under the plate (flush caps), the plate spans 4 m
	st.model.records.assign(laid);st.redraw()
	var fitted: Array = st.geometry_records()
	var seated: int = fitted.filter(func(r): return r.kind == "point" and r.get("_seated", false)).size()
	var plate_box: AABB = AABB()
	for r in fitted:
		if r.kind == "quad":plate_box = st.shape_for(r, st.output_unit()).get_debug_mesh().get_aabb()
	_check(report, "D fitted: the frame's joints are seated under the plate; the plate's shape is 4 m across at the output unit", seated >= 12 and absf(plate_box.size.x - 2.0 * st.output_unit()) < .3 * st.output_unit(), {"seated": seated, "plate": plate_box.size})
	# E - undo
	st.undo()
	_check(report, "E undo: one UNDO takes the whole plate and its frame back", st.model.records.is_empty(), {"records": st.model.records.size()})
	var passed := 0
	for ch in report.checks:
		if ch.ok:passed += 1
	report["passed"] = passed;report["of"] = report.checks.size()
	var o := FileAccess.open(out_dir.path_join("plate.json"), FileAccess.WRITE);o.store_string(JSON.stringify(report, "  "));o.close()
	print("[probe_workstation_plate] %d/%d" % [passed, report.checks.size()])
	get_tree().quit(0 if passed == report.checks.size() else 1)

func _check(report: Dictionary, what: String, ok: bool, data: Dictionary) -> void:
	report.checks.append({"what": what, "ok": ok, "data": data})
	print("[probe_workstation_plate] %s  %s" % ["ok  " if ok else "FAIL", what])
