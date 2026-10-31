extends Node3D
## THE NECK STEP of the scaffold workstation (Palle, 2026-10-31: at Point One "the 6-ball neck to neck"; from Point
## Lines "a distance grid like now"). The Points station (points.tscn, tier 0) and the Lines station (lines.tscn,
## tier 1) each get a point half a step from the origin; (A) at Points the two joints stand collar to collar -
## centre to centre 2 x (.085 + .006) of the hand unit, the collar tips meeting - and the hand-grid lines follow;
## (B) at Lines they stand the half step apart as before; (C) BUILD at Points: the glass copy's two joints are
## collar to collar at the output unit too. Writes ada_run/workstation/neck.json.
## Run: godot --path . --xr-mode off --resolution 1280x800 res://commons/testing/probe_workstation_neck.tscn

const POINTS = preload("res://commons/artifacts/scaffold_workstation/points.tscn")
const LINES = preload("res://commons/artifacts/scaffold_workstation/lines.tscn")

func _ready() -> void:
	var out_dir := ProjectSettings.globalize_path("res://ada_run/workstation");DirAccess.make_dir_recursive_absolute(out_dir)
	var cam := Camera3D.new();cam.position = Vector3(0, 1.6, 1.5);add_child(cam);cam.current = true
	var env := WorldEnvironment.new();var e := Environment.new();e.background_mode = Environment.BG_COLOR;e.background_color = Color("2a2c33")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR;e.ambient_light_color = Color("d8d2c8");e.ambient_light_energy = .8;env.environment = e;add_child(env)
	var sun := DirectionalLight3D.new();sun.rotation_degrees = Vector3(-50, 30, 0);sun.light_energy = 1.1;add_child(sun)
	var report := {"checks": []}
	# A - the Points station
	var pts: Node3D = POINTS.instantiate();pts.set_meta("config_persist", false);add_child(pts)
	for i in 6:
		await get_tree().process_frame
	var added_a: bool = pts.model.add({"kind": "point", "at": [0.5, 0, 0]}, 0)
	pts.model.add({"kind": "point", "at": [1.0, 0, 0]}, 0);pts.model.add({"kind": "point", "at": [0.5, 0.5, 0]}, 0);pts.model.add({"kind": "point", "at": [0, 0, 0.5]}, 0)
	pts.redraw()
	await get_tree().process_frame
	# the picture: the model pad from the front, a little above - the grid lines and the points on them
	var pad: Vector3 = pts.bench.global_position
	cam.transform = Transform3D(Basis(), pad + Vector3(0.12, 0.16, 0.34)).looking_at(pad + Vector3(0.03, -0.04, 0.02));cam.fov = 38
	for i in 3:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir.path_join("points_station.png"))
	var placed_a: Node3D = pts.drawing.get_node_or_null("Placed0")
	var scale_a: float = pts.SCALE;var neck: float = 2 * (.085 + .006) * scale_a
	var at_a: Vector3 = placed_a.position if placed_a else Vector3.INF
	var collar_a: float = _collar_reach(placed_a)   # the far edge of a collar from the joint's centre, in metres
	var lines_a: Array = pts.bench.find_children("GridX*", "", true, false)
	var grid_a: float = absf(lines_a[1].position.z - lines_a[0].position.z) if lines_a.size() > 1 else INF
	var touch_a: bool = placed_a != null and absf(at_a.x - neck) < 1e-5 and absf(at_a.y) < 1e-6 and absf(at_a.z) < 1e-6 and absf(2 * collar_a - at_a.x) < 1e-4 and (lines_a.size() < 2 or absf(grid_a - neck * .5) < 1e-5)
	_check(report, "A points: the half-step neighbour stands collar to collar with the origin - centre to centre 2 x (.085 + .006) hand units, the collar tips meeting; the grid lines follow", added_a and touch_a, {"added": added_a, "at": at_a, "neck": neck, "collar_reach": collar_a, "grid_spacing": grid_a, "lattice": pts.lattice()})
	# C - BUILD: the glass copy keeps the touch at the output unit
	var built_c: bool = pts.build_copy()
	for i in 4:
		await get_tree().physics_frame
	var structure: Node3D = pts.output.get_node("Structure")
	var b0: Node3D = structure.get_node_or_null("Built0");var b1: Node3D = structure.get_node_or_null("Built1")
	var unit_c: float = pts.output_unit();var neck_c: float = 2 * (.085 + .006) * unit_c
	var apart_c: float = b0.position.distance_to(b1.position) if b0 and b1 else INF
	_check(report, "C build: the glass copy's two joints are collar to collar at the output unit", built_c and absf(apart_c - neck_c) < 1e-5, {"built": built_c, "apart": apart_c, "neck": neck_c, "unit": unit_c, "feedback": pts.feedback.text if pts.get("feedback") else ""})
	pts.queue_free()
	await get_tree().process_frame
	# B - the Lines station: the half step as before
	var lns: Node3D = LINES.instantiate();lns.set_meta("config_persist", false);add_child(lns)
	for i in 6:
		await get_tree().process_frame
	var added_b: bool = lns.model.add({"kind": "point", "at": [0.5, 0, 0]}, 1)
	lns.model.add({"kind": "point", "at": [1.0, 0, 0]}, 1);lns.model.add({"kind": "point", "at": [0.5, 0.5, 0]}, 1);lns.model.add({"kind": "point", "at": [0, 0, 0.5]}, 1)
	lns.redraw()
	await get_tree().process_frame
	var pad_b: Vector3 = lns.bench.global_position
	cam.transform = Transform3D(Basis(), pad_b + Vector3(0.12, 0.22, 0.5)).looking_at(pad_b + Vector3(0.05, -0.06, 0.02))
	for i in 3:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir.path_join("lines_station.png"))
	var placed_b: Node3D = lns.drawing.get_node_or_null("Placed0")
	var at_b: Vector3 = placed_b.position if placed_b else Vector3.INF
	_check(report, "B lines: at the Rods station the half-step neighbour stands the half step (.5 x SCALE) from the origin, as before", added_b and placed_b != null and absf(at_b.x - .5 * lns.SCALE) < 1e-6 and lns.lattice() == 1.0, {"added": added_b, "at": at_b, "half_step": .5 * lns.SCALE, "lattice": lns.lattice()})
	var passed := 0
	for ch in report.checks:
		if ch.ok:passed += 1
	report["passed"] = passed;report["of"] = report.checks.size()
	var o := FileAccess.open(out_dir.path_join("neck.json"), FileAccess.WRITE);o.store_string(JSON.stringify(report, "  "));o.close()
	print("[probe_workstation_neck] %d/%d" % [passed, report.checks.size()])
	get_tree().quit(0 if passed == report.checks.size() else 1)

## How far a joint's collars reach from its centre: the farthest collar disk's position plus half its height.
func _collar_reach(piece: Node3D) -> float:
	if piece == null:return INF
	var reach := 0.0
	for m in piece.find_children("*", "MeshInstance3D", true, false):
		if m.mesh is CylinderMesh:reach = maxf(reach, m.position.length() + (m.mesh as CylinderMesh).height / 2.0)
	return reach

func _check(report: Dictionary, what: String, ok: bool, data: Dictionary) -> void:
	report.checks.append({"what": what, "ok": ok, "data": data})
	print("[probe_workstation_neck] %s  %s" % ["ok  " if ok else "FAIL", what])
