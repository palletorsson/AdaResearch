extends SceneTree

const REPORT := "res://doc/space/ignorance-focus-2026-09-16/capsule-return/geometry-checks.json"

func _initialize() -> void:
	var scene: PackedScene = load("res://commons/primitives/capsule/capsule.tscn")
	var exhibit: Node3D = scene.instantiate()
	var body: MeshInstance3D = exhibit.get_node("capsule")
	var mesh: CapsuleMesh = body.mesh
	var ring := section_vertices(mesh)
	var sixth: CapsuleMesh = mesh.duplicate()
	sixth.radial_segments = 6
	var five_step := rotation_error(ring, TAU / 5.0)
	var five_half := rotation_error(ring, PI)
	var six_half := rotation_error(section_vertices(sixth), PI)
	var angular_gaps: Array[float] = []
	var angles: Array[float] = []
	for p in ring:
		angles.append(p.angle())
	angles.sort()
	for i in angles.size():
		angular_gaps.append(rad_to_deg(fposmod(angles[(i + 1) % angles.size()] - angles[i], TAU)))
	var regular := true
	for angle in angular_gaps:
		regular = regular and absf(angle - 72.0) < 0.001
	var ridge := ring[0]
	var opposite_midpoint := false
	for a in ring:
		for b in ring:
			if a == b:
				continue
			if absf(a.distance_to(b) - 2.0 * mesh.radius * sin(PI / 5.0)) > 0.0001:
				continue
			var midpoint := (a + b) * 0.5
			if midpoint.normalized().dot(-ridge.normalized()) > 0.99999:
				opposite_midpoint = true
	body.call("_update_rotation", 4.0)
	var checks := {
		"Authored mesh has five radial segments and five rings": mesh.radial_segments == 5 and mesh.rings == 5,
		"Default facture retains authored geometry": exhibit.get("facture") == "cast",
		"Authored radius and height": is_equal_approx(mesh.radius, 0.25) and is_equal_approx(mesh.height, 1.0),
		"Extracted cross-section has five distinct corners": ring.size() == 5,
		"Angular intervals are equal at 72 degrees": regular,
		"72-degree rotation preserves cross-section corners": five_step < 0.0001,
		"180-degree rotation does not preserve cross-section corners": five_half > 0.1,
		"A ridge faces a side midpoint across the axis": opposite_midpoint,
		"Six-segment comparison passes the half-turn": six_half < 0.0001,
		"Actual spin driver reaches half-turn after four seconds": is_equal_approx(body.rotation_degrees.y, 180.0),
	}
	var report := {"checks": checks, "five_72_degree_error_m": five_step, "five_180_degree_error_m": five_half, "six_180_degree_error_m": six_half, "angular_gaps_degrees": angular_gaps}
	var file := FileAccess.open(REPORT, FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  ") + "\n")
	file.close()
	var failures := 0
	for label in checks:
		print("%s %s" % ["PASS" if checks[label] else "FAIL", label])
		if not checks[label]:
			failures += 1
	exhibit.free()
	quit(failures)

func section_vertices(mesh: CapsuleMesh) -> Array[Vector2]:
	var result: Array[Vector2] = []
	var vertices: PackedVector3Array = mesh.get_mesh_arrays()[Mesh.ARRAY_VERTEX]
	var side_y := 0.0
	for v in vertices:
		if absf(Vector2(v.x, v.z).length() - mesh.radius) < 0.00001:
			side_y = v.y
			break
	for v in vertices:
		if absf(v.y - side_y) > 0.00001:
			continue
		var p := Vector2(v.x, v.z)
		var duplicate := false
		for seen in result:
			if seen.distance_to(p) < 0.00001:
				duplicate = true
		if not duplicate:
			result.append(p)
	return result

func rotation_error(points: Array[Vector2], angle: float) -> float:
	var largest := 0.0
	for p in points:
		var nearest := INF
		for q in points:
			nearest = minf(nearest, p.rotated(angle).distance_to(q))
		largest = maxf(largest, nearest)
	return largest
