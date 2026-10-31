extends Node3D
## THE SAMPLES IN THE HALL (Palle, 2026-10-31: "at what level can I see the samples"): the principal-places hall
## (Void floor 210) builds four activities from its recipe - noise on the disco plate, random in the biome bath, the
## sine floor in the hanging basin, a noise wall on the bath's north wall - each fitted and rimmed where its place is.
## Writes ada_run/workstation/hall_activities.json. Run: godot --path . --xr-mode off --resolution 1280x800 res://commons/testing/probe_hall_activities.tscn

const HALL = preload("res://commons/void/trials/principal_places/places.tscn")

func _ready() -> void:
	var out_dir := ProjectSettings.globalize_path("res://ada_run/workstation");DirAccess.make_dir_recursive_absolute(out_dir)
	var cam := Camera3D.new();cam.position = Vector3(0, 12, 20);add_child(cam);cam.current = true
	var report := {"checks": []}
	var hall: Node3D = HALL.instantiate();add_child(hall)
	for i in 6:
		await get_tree().physics_frame
	var found := {}
	for c in hall.get_children():
		if c.has_meta("activity_artifact"):found[str(c.name)] = c
	var want := {"disco-plate_activity": [-14.0, 0.07, 0.0, 8.0, 8.0], "biome-plastic-bath_activity": [0.0, 3.0, 0.0, 10.0, 10.0], "hanging-steel-bath_activity": [14.0, 7.0, 0.0, 8.0, 8.0]}
	for id in want:
		var n: Node3D = found.get(id);var w: Array = want[id]
		var box: AABB = n.mesh_instance.mesh.get_aabb() if n else AABB()
		var ok: bool = n != null and n.fitted and n.position.is_equal_approx(Vector3(w[0], w[1], w[2])) and absf(box.size.x - w[3]) < .05 and absf(box.size.z - w[4]) < .05 and absf(box.position.y) < 1e-3
		_check(report, "%s: built at its place, fitted to %d x %d on its floor" % [id, int(w[3]), int(w[4])], ok, {"found": n != null, "at": n.position if n else null, "size": box.size})
	var wall: Node3D = found.get("biome-plastic-bath_activity_north")
	var wb: AABB = (wall.static_body.transform * wall.mesh_instance.mesh.get_aabb()) if wall else AABB()
	var wall_ok: bool = wall != null and wall.mount == "wall" and is_equal_approx(wall.rotation_degrees.y, 180.0) and absf(wb.size.x - 10.0) < .05 and absf(wb.size.y - 1.0) < .05 and absf(wb.position.y) < 1e-3
	_check(report, "north wall: the noise wall stands 10 m wide and 1 m high on the bath's north wall, facing in", wall_ok, {"found": wall != null, "box": wb, "yaw": wall.rotation_degrees.y if wall else null})
	var passed := 0
	for ch in report.checks:
		if ch.ok:passed += 1
	report["passed"] = passed;report["of"] = report.checks.size()
	var o := FileAccess.open(out_dir.path_join("hall_activities.json"), FileAccess.WRITE);o.store_string(JSON.stringify(report, "  "));o.close()
	print("[probe_hall_activities] %d/%d" % [passed, report.checks.size()])
	get_tree().quit(0 if passed == report.checks.size() else 1)

func _check(report: Dictionary, what: String, ok: bool, data: Dictionary) -> void:
	report.checks.append({"what": what, "ok": ok, "data": data})
	print("[probe_hall_activities] %s  %s" % ["ok  " if ok else "FAIL", what])
