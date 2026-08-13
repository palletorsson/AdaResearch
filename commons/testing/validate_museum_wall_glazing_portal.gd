# validate_museum_wall_glazing_portal.gd
# Live glazing, vitrine, and portal physics audit for the mandatory GLAZE/PORTAL
# corpora. Unsupported impact events or state behavior remain explicit failures.

extends SceneTree

const PIECE_SCENE := preload("res://commons/artifacts/museum/museum_wall_piece.tscn")
const PHYSICS_PATH := "res://commons/data/museum_wall_physics_contract.json"
const OUTPUT_PATH := "res://ada_run/museum_aaa_pass/museum_wall_glazing_portal_validation.json"
const PRIOR_LOG_PATH := "res://ada_run/museum_aaa_pass/museum_wall_glazing_portal_engine.log"
const MAX_RECORDED_FAILURES := 64


class ImpactCounter:
	extends RefCounted
	var count := 0
	var last_energy_j := 0.0

	func on_impact(energy_j: float) -> void:
		count += 1
		last_energy_j = energy_j


var _physics: Dictionary = {}
var _tests: Dictionary = {}
var _case_metrics: Array[Dictionary] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var source_paths := PackedStringArray([
		"res://commons/artifacts/museum/museum_wall_piece.gd",
		"res://commons/artifacts/museum/museum_wall_opening_spans.gd",
		PHYSICS_PATH,
		"res://commons/testing/validate_museum_wall_glazing_portal.gd",
	])
	var source_hashes_at_start := _source_hashes(source_paths)
	_physics = _load_json(PHYSICS_PATH)
	var gp01_failures: PackedStringArray = []
	var gp02_failures: PackedStringArray = []
	var gp03_failures: PackedStringArray = []
	var gp04_failures: PackedStringArray = []
	var gp05_failures: PackedStringArray = []
	var gp06_failures: PackedStringArray = []
	var gp07_failures: PackedStringArray = []
	var gp08_failures: PackedStringArray = []
	var gp09_failures: PackedStringArray = []
	var gp10_failures: PackedStringArray = []
	var glaze_cases := 0
	var routing_probes := 0
	var routing_correct := 0
	var fixed_sweeps := 0
	var fixed_sweeps_passed := 0
	var vitrine_sweeps := 0
	var vitrine_sweeps_passed := 0
	var portal_cases := 0
	var portal_clear_sweeps := 0
	var portal_clear_passed := 0
	var portal_negative_sweeps := 0
	var portal_negative_passed := 0
	var impact_events_observed := 0

	if _physics.is_empty():
		for failures in [gp01_failures, gp02_failures, gp03_failures, gp04_failures, gp05_failures, gp06_failures, gp07_failures, gp08_failures, gp09_failures, gp10_failures]:
			failures.append("physics contract did not parse")

	for family in ["window", "vitrine"]:
		for width in [2, 3, 4]:
			for lod in [0, 1, 2]:
				var key := "%s_%dm_lod%d" % [family, width, lod]
				var piece: Node3D = await _spawn_piece(family, width, lod)
				glaze_cases += 1
				var assembly := _find_opening_assembly(piece, family)
				var glass_body := _find_named(piece, "%sGlassCollision" % family.capitalize()) as StaticBody3D
				var structure_body := _find_named(piece, "%sStructureCollision" % family.capitalize()) as StaticBody3D
				if assembly == null or glass_body == null or structure_body == null:
					_append_failure(gp01_failures, "%s missing assembly/structure/distinct glass body" % key)
					await _destroy_piece(piece)
					continue
				var raw_surface := _surface_id(glass_body)
				if raw_surface != "glass_laminated":
					_append_failure(gp01_failures, "%s glass surface '%s' != glass_laminated" % [key, raw_surface])
				if glass_body == structure_body:
					_append_failure(gp01_failures, "%s glass collider is not distinct" % key)
				var center_without_glass := _ray_surface(piece, _glass_center(glass_body) + Vector3(0, 0, 0.8), _glass_center(glass_body) + Vector3(0, 0, -0.8), [glass_body.get_rid()])
				if center_without_glass != "":
					_append_failure(gp01_failures, "%s structural collider blocks center behind glass as '%s'" % [key, center_without_glass])

				var probes := _glaze_routing_probes(piece, family, width, glass_body)
				routing_probes += int(probes["count"])
				routing_correct += int(probes["correct"])
				for failure in probes["failures"]:
					_append_failure(gp02_failures, "%s: %s" % [key, failure])

				var thickness := _audit_glass_alignment(piece, family, glass_body)
				if not bool(thickness["passed"]):
					_append_failure(gp05_failures, "%s mid_delta=%.4fm thickness_delta=%.4fm visible=%.4fm collision=%.4fm" % [key, float(thickness["midplane_delta_m"]), float(thickness["thickness_delta_m"]), float(thickness["visible_thickness_m"]), float(thickness["collision_thickness_m"])])

				var impact := _audit_fixed_glass_impact(piece, family, glass_body)
				impact_events_observed += int(impact["event_count"])
				for failure in impact["failures"]:
					_append_failure(gp06_failures, "%s: %s" % [key, failure])

				if family == "window":
					var sweeps := _audit_fixed_window_sweeps(piece, glass_body)
					fixed_sweeps += int(sweeps["count"])
					fixed_sweeps_passed += int(sweeps["passed_count"])
					for failure in sweeps["failures"]:
						_append_failure(gp03_failures, "%s: %s" % [key, failure])
				else:
					var sweeps := _audit_vitrine_sweeps(piece, glass_body, structure_body)
					vitrine_sweeps += int(sweeps["count"])
					vitrine_sweeps_passed += int(sweeps["passed_count"])
					for failure in sweeps["failures"]:
						_append_failure(gp04_failures, "%s: %s" % [key, failure])

				_case_metrics.append({
					"case": key,
					"glass_surface": raw_surface,
					"visible_glass_thickness_m": _round6(float(thickness["visible_thickness_m"])),
					"collision_glass_thickness_m": _round6(float(thickness["collision_thickness_m"])),
					"midplane_delta_m": _round6(float(thickness["midplane_delta_m"])),
				})
				await _destroy_piece(piece)

	for width in [2, 3, 4]:
		for lod in [0, 1, 2]:
			var key := "portal_%dm_lod%d" % [width, lod]
			var piece: Node3D = await _spawn_piece("portal", width, lod)
			portal_cases += 1
			var geometry := _audit_portal_geometry(piece, width)
			for failure in geometry["failures"]:
				_append_failure(gp07_failures, "%s: %s" % [key, failure])
			var clear_sweeps := _audit_portal_clear_sweeps(piece, Vector2(geometry["measured_clear_m"]))
			portal_clear_sweeps += int(clear_sweeps["count"])
			portal_clear_passed += int(clear_sweeps["passed_count"])
			for failure in clear_sweeps["failures"]:
				_append_failure(gp08_failures, "%s: %s" % [key, failure])
			var negative := _audit_portal_negative_sweeps(piece, width, Vector2(geometry["measured_clear_m"]))
			portal_negative_sweeps += int(negative["count"])
			portal_negative_passed += int(negative["passed_count"])
			for failure in negative["failures"]:
				_append_failure(gp09_failures, "%s: %s" % [key, failure])
			var state := _audit_portal_state_contract(piece)
			for failure in state["failures"]:
				_append_failure(gp10_failures, "%s: %s" % [key, failure])
			_case_metrics.append({
				"case": key,
				"measured_clear_m": _vector2_json(Vector2(geometry["measured_clear_m"])),
				"visible_threshold_m": _round6(float(geometry["visible_threshold_m"])),
				"metadata_threshold_m": _round6(float(geometry["metadata_threshold_m"])),
				"leaf_nodes": int(state["leaf_nodes"]),
			})
			await _destroy_piece(piece)

	var log_audit := _audit_prior_log(PRIOR_LOG_PATH)
	if not bool(log_audit["available"]):
		_append_failure(gp10_failures, "prior engine log missing; state-cycle warning evidence is mandatory")
	elif int(log_audit["attributable_issues"]) > 0:
		_append_failure(gp10_failures, "prior engine log has %d museum-wall warnings/errors" % int(log_audit["attributable_issues"]))
	var source_hashes_at_end := _source_hashes(source_paths)
	var source_stable := source_hashes_at_start == source_hashes_at_end
	if not source_stable:
		_append_failure(gp10_failures, "source hashes changed while runner was executing; report is stale")

	_set_test("GP-01", gp01_failures.is_empty(), gp01_failures, {"glaze_cases": glaze_cases, "required_surface": "glass_laminated"})
	_set_test("GP-02", gp02_failures.is_empty(), gp02_failures, {"routing_probes": routing_probes, "correct": routing_correct, "probe_roles": ["center", "edge", "mullion_or_meeting_stile", "jamb", "apron", "backing"]})
	_set_test("GP-03", gp03_failures.is_empty(), gp03_failures, {"window_sweeps": fixed_sweeps, "passed": fixed_sweeps_passed, "directions": 2, "hand_radius_m": 0.15, "capsule_radius_m": 0.3, "capsule_height_m": 1.8})
	_set_test("GP-04", gp04_failures.is_empty(), gp04_failures, {"vitrine_sweeps": vitrine_sweeps, "passed": vitrine_sweeps_passed, "hand_radius_m": 0.1})
	_set_test("GP-05", gp05_failures.is_empty(), gp05_failures, {"midplane_gate_m": 0.003, "thickness_delta_gate_m": 0.004, "authored_range_m": [0.008, 0.03]})
	_set_test("GP-06", gp06_failures.is_empty(), gp06_failures, {"cases": glaze_cases, "below_threshold_events_observed": impact_events_observed, "required_events_per_case": 1})
	_set_test("GP-07", gp07_failures.is_empty(), gp07_failures, {"portal_cases": portal_cases, "min_clear_m": [1.2, 2.1], "max_threshold_m": 0.012, "metadata_delta_m": 0.005})
	_set_test("GP-08", gp08_failures.is_empty(), gp08_failures, {"clear_sweeps": portal_clear_sweeps, "passed": portal_clear_passed, "paths_per_shape_per_direction": 3, "hand_clearance_m": 0.1})
	_set_test("GP-09", gp09_failures.is_empty(), gp09_failures, {"negative_sweeps": portal_negative_sweeps, "passed": portal_negative_passed, "required_surface": "stone"})
	_set_test("GP-10", gp10_failures.is_empty(), gp10_failures, {"portal_cases": portal_cases, "leaf_present_policy": "1000 cycles", "leaf_absent_policy": "interaction=walkthrough and zero leaf nodes", "prior_log": log_audit})

	var passed_count := 0
	var failed_count := 0
	for test_id in _tests:
		if bool((_tests[test_id] as Dictionary)["passed"]):
			passed_count += 1
		else:
			failed_count += 1
	var report := {
		"schema": "ada-museum-wall-glazing-portal-v1",
		"passed": failed_count == 0,
		"engine": Engine.get_version_info(),
		"source_hashes": source_hashes_at_end,
		"source_hashes_at_start": source_hashes_at_start,
		"source_stable": source_stable,
		"tests_passed": passed_count,
		"tests_failed": failed_count,
		"tests": _tests,
		"cases": _case_metrics,
	}
	_write_json(OUTPUT_PATH, report)
	print("MUSEUM_WALL_GLAZING_PORTAL=" + JSON.stringify(report))
	print("MUSEUM_WALL_GLAZING_PORTAL_TESTS=%d PASSED=%d FAILED=%d" % [_tests.size(), passed_count, failed_count])
	quit(0 if failed_count == 0 else 1)


func _spawn_piece(family: String, width: int, lod: int) -> Node3D:
	var piece := PIECE_SCENE.instantiate() as Node3D
	piece.name = "GlazingPortal_%s_%dm_L%d" % [family, width, lod]
	piece.set("kind", family)
	piece.set("width_cells", width)
	piece.set("height", 4.0)
	piece.set("lod_level", lod)
	piece.set("enable_collision", true)
	piece.set("detail_seed", 17431)
	root.add_child(piece)
	await process_frame
	await physics_frame
	return piece


func _destroy_piece(piece: Node) -> void:
	if piece != null and is_instance_valid(piece):
		piece.queue_free()
	await process_frame
	await physics_frame


func _glaze_routing_probes(piece: Node3D, family: String, width: int, glass_body: StaticBody3D) -> Dictionary:
	var failures: PackedStringArray = []
	var visible := _glass_visual(piece, family)
	if visible == null:
		return {"count": 0, "correct": 0, "failures": PackedStringArray(["visible glass mesh missing"])}
	var bounds: AABB = visible.global_transform * visible.get_aabb()
	var center := bounds.get_center()
	var half := bounds.size * 0.5
	var center_x := center.x + minf(0.23, half.x * 0.33)
	var center_y := center.y - minf(0.27, half.y * 0.2)
	var opening_report := _opening_report(piece)
	var opening_center := Vector2(opening_report.get("opening_center_m", Vector2(0, center.y)))
	var opening_size := Vector2(opening_report.get("clear_opening_m", Vector2(bounds.size.x, bounds.size.y)))
	var seam_x := -float(width) * 0.5 + 1.0
	var probes: Array[Dictionary] = [
		{"role": "center", "from": Vector3(center_x, center_y, bounds.end.z + 0.5), "to": Vector3(center_x, center_y, bounds.position.z - 0.5), "expected": "glass_laminated", "exclude": []},
		{"role": "edge", "from": Vector3(center.x + half.x - 0.012, center_y, bounds.end.z + 0.5), "to": Vector3(center.x + half.x - 0.012, center_y, bounds.position.z - 0.5), "expected": "glass_laminated", "exclude": []},
		{"role": "mullion_or_meeting_stile", "from": Vector3(seam_x if family == "window" else 0.0, center.y, bounds.end.z + 0.5), "to": Vector3(seam_x if family == "window" else 0.0, center.y, bounds.position.z - 0.5), "expected": "painted_metal" if family == "window" else "bronze", "exclude": []},
		{"role": "jamb", "from": Vector3(opening_center.x + opening_size.x * 0.5 + 0.08, opening_center.y, 0.8), "to": Vector3(opening_center.x + opening_size.x * 0.5 + 0.08, opening_center.y, -0.8), "expected": "stone", "exclude": []},
		{"role": "apron", "from": Vector3(0, opening_center.y - opening_size.y * 0.5 - 0.1, 0.8), "to": Vector3(0, opening_center.y - opening_size.y * 0.5 - 0.1, -0.8), "expected": "stone", "exclude": []},
		{"role": "backing", "from": Vector3(center_x, center_y, bounds.position.z - 0.04), "to": Vector3(center_x, center_y, -0.7), "expected": "stone" if family == "vitrine" else "", "exclude": [glass_body.get_rid()]},
	]
	var correct := 0
	for probe in probes:
		var actual := _ray_surface(piece, probe["from"], probe["to"], probe["exclude"])
		if actual == str(probe["expected"]):
			correct += 1
		else:
			failures.append("%s expected '%s' got '%s'" % [probe["role"], probe["expected"], actual])
	return {"count": probes.size(), "correct": correct, "failures": failures}


func _audit_fixed_window_sweeps(piece: Node3D, glass_body: StaticBody3D) -> Dictionary:
	var failures: PackedStringArray = []
	var passed_count := 0
	var center := _glass_center(glass_body)
	var initial_transform := glass_body.global_transform
	var specs: Array[Dictionary] = []
	for direction in [-1.0, 1.0]:
		var sphere := SphereShape3D.new()
		sphere.radius = 0.15
		specs.append({"shape": sphere, "at": Vector3(center.x + 0.21, center.y - 0.22, direction), "motion": Vector3(0, 0, -direction * 2.0), "label": "hand"})
		var capsule := CapsuleShape3D.new()
		capsule.radius = 0.3
		capsule.height = 1.8
		specs.append({"shape": capsule, "at": Vector3(center.x + 0.21, 0.9, direction), "motion": Vector3(0, 0, -direction * 2.0), "label": "player"})
	for spec in specs:
		var result := _cast_shape(piece, spec["shape"], Transform3D(Basis.IDENTITY, spec["at"]), spec["motion"])
		# cast_motion's safe fraction is the last non-penetrating transform. The
		# safe/unsafe search bracket is diagnostic precision, not penetration.
		if float(result["safe_fraction"]) < 0.999999:
			passed_count += 1
		else:
			failures.append("%s sweep tunneled through fixed glazing" % spec["label"])
	if not glass_body.global_transform.is_equal_approx(initial_transform):
		failures.append("fixed laminated glass moved during sweeps")
	return {"count": specs.size(), "passed_count": passed_count, "failures": failures}


func _audit_vitrine_sweeps(piece: Node3D, glass_body: StaticBody3D, structure_body: StaticBody3D) -> Dictionary:
	var failures: PackedStringArray = []
	var passed_count := 0
	var center := _glass_center(glass_body)
	var visible := _glass_visual(piece, "vitrine")
	var bounds: AABB = visible.global_transform * visible.get_aabb()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.1
	var specs: Array[Dictionary] = [
		{"label": "glass_front", "at": Vector3(center.x, center.y, 1.0), "motion": Vector3(0, 0, -2.0), "expect_hit": true},
		{"label": "glass_back", "at": Vector3(center.x, center.y, -1.0), "motion": Vector3(0, 0, 2.0), "expect_hit": true},
		{"label": "frame", "at": Vector3(bounds.end.x + 0.04, center.y, 1.0), "motion": Vector3(0, 0, -2.0), "expect_hit": true},
		{"label": "shelf_content_from_front", "at": Vector3(center.x, center.y - 0.35, 1.0), "motion": Vector3(0, 0, -2.0), "expect_hit": true},
	]
	for spec in specs:
		var result := _cast_shape(piece, sphere, Transform3D(Basis.IDENTITY, spec["at"]), spec["motion"])
		var hit := float(result["safe_fraction"]) < 0.999999
		if hit == bool(spec["expect_hit"]):
			passed_count += 1
		else:
			failures.append("%s expected_hit=%s actual_hit=%s" % [spec["label"], spec["expect_hit"], hit])
	var glass_surface := _surface_id(glass_body)
	var frame_surface := _ray_surface(piece, Vector3(bounds.end.x + 0.04, center.y, 0.9), Vector3(bounds.end.x + 0.04, center.y, -0.9), [glass_body.get_rid()])
	if glass_surface != "glass_laminated" or frame_surface not in ["painted_metal", "bronze"]:
		failures.append("frame/glass routing not distinct (%s/%s)" % [frame_surface, glass_surface])
	var cavity_hit := _ray_surface(piece, Vector3(center.x, center.y, center.z - 0.05), Vector3(center.x, center.y, -0.18), [glass_body.get_rid(), structure_body.get_rid()])
	if cavity_hit != "":
		failures.append("vitrine cavity is replaced by front-plane blocker '%s'" % cavity_hit)
	return {"count": specs.size(), "passed_count": passed_count, "failures": failures}


func _audit_glass_alignment(piece: Node3D, family: String, glass_body: StaticBody3D) -> Dictionary:
	var visible := _glass_visual(piece, family)
	var shape_node := _first_collision_shape(glass_body)
	if visible == null or shape_node == null or not shape_node.shape is BoxShape3D:
		return {"passed": false, "midplane_delta_m": 9999.0, "thickness_delta_m": 9999.0, "visible_thickness_m": 0.0, "collision_thickness_m": 0.0}
	var visible_bounds: AABB = visible.global_transform * visible.get_aabb()
	var collision_size := (shape_node.shape as BoxShape3D).size
	var collision_bounds: AABB = shape_node.global_transform * AABB(-collision_size * 0.5, collision_size)
	var visible_thickness := visible_bounds.size.z
	var collision_thickness := collision_bounds.size.z
	var mid_delta := absf(visible_bounds.get_center().z - collision_bounds.get_center().z)
	var thickness_delta := absf(visible_thickness - collision_thickness)
	var passed := mid_delta <= 0.003 and thickness_delta <= 0.004 and visible_thickness >= 0.008 and visible_thickness <= 0.03
	return {"passed": passed, "midplane_delta_m": mid_delta, "thickness_delta_m": thickness_delta, "visible_thickness_m": visible_thickness, "collision_thickness_m": collision_thickness}


func _audit_fixed_glass_impact(piece: Node3D, family: String, glass_body: StaticBody3D) -> Dictionary:
	var failures: PackedStringArray = []
	var surface: Dictionary = (_physics.get("surfaces", {}) as Dictionary).get("glass_laminated", {})
	if bool(glass_body.get_meta("breakable", true)):
		failures.append("fixed laminated glazing declares breakable=true")
	var threshold := float(glass_body.get_meta("break_threshold_j", -1.0))
	if threshold <= 0.0:
		failures.append("break threshold metadata missing")
	if _surface_id(glass_body) != "glass_laminated":
		failures.append("impact route is not glass_laminated")
	if str(glass_body.get_meta("impact", "")) != str(surface.get("impact", "")):
		failures.append("impact tag does not match contract")
	if str(glass_body.get_meta("decal", "")) != str(surface.get("decal", "")):
		failures.append("decal tag does not match contract")
	if str(glass_body.get_meta("breakability", "")) != str(surface.get("breakability", "")):
		failures.append("breakability tag does not match contract")
	var hook := _find_named(piece, "%sGlassPhysicsHook" % family.capitalize())
	var event_count := 0
	var supports_event := hook != null and (hook.has_signal("impact") or hook.has_method("apply_impact") or hook.has_method("emit_impact"))
	if not supports_event:
		failures.append("below-threshold impact event API is unsupported; cannot prove exactly-once event")
	else:
		var before_transform := glass_body.global_transform
		var before_shape_count := _all_descendants(glass_body).filter(func(node: Node) -> bool: return node is CollisionShape3D).size()
		var counter := ImpactCounter.new()
		if hook.has_signal("impact"):
			hook.connect("impact", Callable(counter, "on_impact"))
		var probe_j := maxf(0.001, threshold * 0.5)
		if hook.has_method("apply_impact"):
			hook.call("apply_impact", probe_j)
		elif hook.has_method("emit_impact"):
			hook.call("emit_impact", probe_j)
		event_count = counter.count
		if event_count != 1:
			failures.append("below-threshold impact emitted %d events; exactly one required" % event_count)
		if not glass_body.global_transform.is_equal_approx(before_transform):
			failures.append("below-threshold impact displaced fixed glass")
		var after_shape_count := _all_descendants(glass_body).filter(func(node: Node) -> bool: return node is CollisionShape3D).size()
		if after_shape_count != before_shape_count:
			failures.append("below-threshold impact changed replacement collision")
	return {"failures": failures, "event_count": event_count, "threshold_j": threshold, "probe_j": maxf(0.001, threshold * 0.5)}


func _audit_portal_geometry(piece: Node3D, _width: int) -> Dictionary:
	var failures: PackedStringArray = []
	var assembly := _find_opening_assembly(piece, "portal")
	var report := _opening_report(piece)
	var metadata_clear := Vector2(report.get("clear_opening_m", Vector2.ZERO))
	var piers: Array[MeshInstance3D] = []
	var lintel: MeshInstance3D = null
	var threshold: MeshInstance3D = null
	var portal_mesh_names: PackedStringArray = []
	for node in _all_descendants(piece):
		if node is MeshInstance3D and str(node.name).to_lower().contains("portal"):
			portal_mesh_names.append(str(node.name))
		if node is MeshInstance3D and str(node.name).contains("PortalStructuralPier"):
			piers.append(node)
		elif node is MeshInstance3D and str(node.name).contains("PortalStructuralLintel"):
			lintel = node
		elif node is MeshInstance3D and str(node.name) == "PortalFlushThreshold":
			threshold = node
	# Godot gives duplicate runtime children generated names unless readable-name
	# insertion is requested. Recover the mirrored structural pier by exact visible
	# bounds/centre symmetry rather than trusting a node-name suffix.
	if piers.size() == 1:
		var reference := piers[0]
		var reference_bounds: AABB = reference.global_transform * reference.get_aabb()
		for node in _all_descendants(piece):
			if not node is MeshInstance3D or node == reference:
				continue
			var candidate := node as MeshInstance3D
			var candidate_bounds: AABB = candidate.global_transform * candidate.get_aabb()
			if candidate_bounds.size.is_equal_approx(reference_bounds.size) and absf(candidate_bounds.get_center().x + reference_bounds.get_center().x) <= 0.001 and absf(candidate_bounds.get_center().y - reference_bounds.get_center().y) <= 0.001:
				piers.append(candidate)
				break
	piers.sort_custom(func(a: MeshInstance3D, b: MeshInstance3D) -> bool: return a.global_position.x < b.global_position.x)
	var measured := Vector2.ZERO
	if piers.size() == 2 and lintel != null:
		var left_bounds: AABB = piers[0].global_transform * piers[0].get_aabb()
		var right_bounds: AABB = piers[1].global_transform * piers[1].get_aabb()
		var lintel_bounds: AABB = lintel.global_transform * lintel.get_aabb()
		measured = Vector2(right_bounds.position.x - left_bounds.end.x, lintel_bounds.position.y)
	else:
		failures.append("visible piers/lintel missing (piers=%d lintel=%s names=%s)" % [piers.size(), lintel != null, ",".join(portal_mesh_names)])
	var visible_threshold := 9999.0
	if threshold != null:
		var threshold_bounds: AABB = threshold.global_transform * threshold.get_aabb()
		visible_threshold = threshold_bounds.end.y
	else:
		failures.append("visible threshold missing")
	var metadata_threshold := float(assembly.get_meta("accessible_threshold_m", -1.0)) if assembly != null else -1.0
	if measured.x < 1.2 or measured.y < 2.1:
		failures.append("measured clear %.3fx%.3fm below 1.2x2.1m" % [measured.x, measured.y])
	if visible_threshold > 0.012:
		failures.append("visible threshold %.3fm exceeds 0.012m" % visible_threshold)
	if absf(metadata_clear.x - measured.x) > 0.005 or absf(metadata_clear.y - measured.y) > 0.005:
		failures.append("clear-opening metadata differs from visible geometry by >0.005m")
	if absf(metadata_threshold - visible_threshold) > 0.005:
		failures.append("threshold metadata differs from visible geometry by %.3fm" % absf(metadata_threshold - visible_threshold))
	var collision_threshold := _collision_threshold_height(piece, measured)
	if collision_threshold > 0.012:
		failures.append("collision threshold %.3fm exceeds 0.012m" % collision_threshold)
	return {"failures": failures, "measured_clear_m": measured, "metadata_clear_m": metadata_clear, "visible_threshold_m": visible_threshold, "metadata_threshold_m": metadata_threshold, "collision_threshold_m": collision_threshold}


func _audit_portal_clear_sweeps(piece: Node3D, clear: Vector2) -> Dictionary:
	var failures: PackedStringArray = []
	var passed_count := 0
	var count := 0
	for shape_kind in ["hand", "player"]:
		var shape: Shape3D
		var radius := 0.1
		var y := 1.0
		if shape_kind == "hand":
			var sphere := SphereShape3D.new()
			sphere.radius = 0.1
			shape = sphere
		else:
			var capsule := CapsuleShape3D.new()
			capsule.radius = 0.3
			capsule.height = 1.8
			shape = capsule
			radius = 0.3
			y = 0.9
		var edge_x := maxf(0.0, clear.x * 0.5 - radius - 0.1)
		for x in [0.0, -edge_x, edge_x]:
			for direction in [-1.0, 1.0]:
				count += 1
				var result := _cast_shape(piece, shape, Transform3D(Basis.IDENTITY, Vector3(x, y, direction)), Vector3(0, 0, -direction * 2.0))
				if float(result["safe_fraction"]) >= 0.999999:
					passed_count += 1
				else:
					failures.append("%s path x=%.3f direction=%.0f contacted structure" % [shape_kind, x, direction])
	return {"count": count, "passed_count": passed_count, "failures": failures}


func _audit_portal_negative_sweeps(piece: Node3D, width: int, clear: Vector2) -> Dictionary:
	var failures: PackedStringArray = []
	var passed_count := 0
	var count := 0
	var sphere := SphereShape3D.new()
	sphere.radius = 0.1
	var pier_x := (clear.x * 0.5 + float(width) * 0.5) * 0.5
	for probe in [
		{"label": "left_pier", "at": Vector3(-pier_x, 1.2, 1.0), "motion": Vector3(0, 0, -2.0)},
		{"label": "right_pier", "at": Vector3(pier_x, 1.2, 1.0), "motion": Vector3(0, 0, -2.0)},
		{"label": "lintel", "at": Vector3(0, clear.y + 0.2, 1.0), "motion": Vector3(0, 0, -2.0)},
		{"label": "left_pier_back", "at": Vector3(-pier_x, 1.2, -1.0), "motion": Vector3(0, 0, 2.0)},
		{"label": "right_pier_back", "at": Vector3(pier_x, 1.2, -1.0), "motion": Vector3(0, 0, 2.0)},
		{"label": "lintel_back", "at": Vector3(0, clear.y + 0.2, -1.0), "motion": Vector3(0, 0, 2.0)},
	]:
		count += 1
		var result := _cast_shape(piece, sphere, Transform3D(Basis.IDENTITY, probe["at"]), probe["motion"])
		var surface := _ray_surface(piece, probe["at"], Vector3(probe["at"]) + Vector3(probe["motion"]), [])
		if float(result["safe_fraction"]) < 0.999999 and surface == "stone":
			passed_count += 1
		else:
			failures.append("%s block=%s surface='%s'" % [probe["label"], float(result["safe_fraction"]) < 0.999999, surface])
	return {"count": count, "passed_count": passed_count, "failures": failures}


func _audit_portal_state_contract(piece: Node3D) -> Dictionary:
	var failures: PackedStringArray = []
	var assembly := _find_opening_assembly(piece, "portal")
	var leaf_nodes := 0
	for node in _all_descendants(piece):
		var lower := str(node.name).to_lower()
		if lower.contains("leaf") and not lower.contains("socket"):
			leaf_nodes += 1
	var interaction := str(assembly.get_meta("interaction", "")) if assembly != null else ""
	if leaf_nodes == 0:
		if interaction != "walkthrough":
			failures.append("zero-leaf portal lacks interaction=walkthrough metadata")
	else:
		failures.append("leaf detected but 1000-cycle closed/open/obstructed/reversal state API is unsupported")
	return {"failures": failures, "leaf_nodes": leaf_nodes, "interaction": interaction, "cycles_executed": 0}


func _cast_shape(piece: Node3D, shape: Shape3D, transform: Transform3D, motion: Vector3) -> Dictionary:
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = transform
	query.motion = motion
	query.margin = 0.0005
	query.collision_mask = 0x7FFFFFFF
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var fractions := piece.get_world_3d().direct_space_state.cast_motion(query)
	var safe := 1.0
	var unsafe := 1.0
	if fractions.size() >= 2:
		safe = float(fractions[0])
		unsafe = float(fractions[1])
	return {"safe_fraction": safe, "unsafe_fraction": unsafe, "bracket_m": absf(unsafe - safe) * motion.length()}


func _ray_surface(piece: Node3D, from: Vector3, to: Vector3, exclude: Array) -> String:
	var query := PhysicsRayQueryParameters3D.create(from, to, 0x7FFFFFFF, exclude)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.hit_from_inside = true
	var hit := piece.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return ""
	var collider := hit["collider"] as CollisionObject3D
	return _surface_id(collider)


func _surface_id(body: CollisionObject3D) -> String:
	if body == null:
		return ""
	var surfaces: Dictionary = _physics.get("surfaces", {})
	var first_declared := ""
	for key in ["physics_surface_id", "surface_id", "surface_type", "surface_audio"]:
		var value := str(body.get_meta(key, ""))
		if first_declared == "" and value != "":
			first_declared = value
		if surfaces.has(value):
			return value
	return first_declared


func _glass_visual(piece: Node3D, family: String) -> MeshInstance3D:
	return _find_named(piece, "WindowOuterLamination" if family == "window" else "VitrineLaminatedDoor") as MeshInstance3D


func _glass_center(body: StaticBody3D) -> Vector3:
	var shape := _first_collision_shape(body)
	return shape.global_position if shape != null else body.global_position


func _first_collision_shape(node: Node) -> CollisionShape3D:
	for child in _all_descendants(node):
		if child is CollisionShape3D:
			return child
	return null


func _find_opening_assembly(piece: Node3D, family: String) -> Node3D:
	var prefix := "%sOpeningSpan" % family.capitalize()
	for node in _all_descendants(piece):
		if node is Node3D and str(node.name).begins_with(prefix):
			return node
	return null


func _opening_report(piece: Node3D) -> Dictionary:
	var contract := piece.get_node_or_null("PieceContract")
	return contract.get_meta("opening_report", {}) if contract != null else {}


func _find_named(node: Node, target: String) -> Node:
	if node != null and str(node.name) == target:
		return node
	if node == null:
		return null
	for child in node.get_children():
		var found := _find_named(child, target)
		if found != null:
			return found
	return null


func _collision_threshold_height(piece: Node3D, clear: Vector2) -> float:
	var maximum := 0.0
	for node in _all_descendants(piece):
		if not node is CollisionShape3D or not (node as CollisionShape3D).shape is BoxShape3D:
			continue
		var shape := node as CollisionShape3D
		var size := (shape.shape as BoxShape3D).size
		var bounds: AABB = shape.global_transform * AABB(-size * 0.5, size)
		if bounds.position.y <= 0.012 and bounds.end.y > 0.0 and bounds.position.x < clear.x * 0.5 and bounds.end.x > -clear.x * 0.5:
			maximum = maxf(maximum, bounds.end.y)
	return maximum


func _audit_prior_log(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"available": false, "attributable_issues": 0, "sha256": ""}
	var text := file.get_as_text()
	var issues := 0
	for line in text.split("\n"):
		var stripped := str(line).strip_edges()
		var lower := stripped.to_lower()
		if lower.contains("museum_wall") and (stripped.begins_with("ERROR:") or stripped.begins_with("WARNING:")):
			issues += 1
	return {"available": true, "attributable_issues": issues, "sha256": FileAccess.get_sha256(path)}


func _all_descendants(node: Node) -> Array[Node]:
	var result: Array[Node] = []
	for child in node.get_children():
		result.append(child)
		result.append_array(_all_descendants(child))
	return result


func _set_test(id: String, passed: bool, failures: PackedStringArray, metrics: Dictionary) -> void:
	_tests[id] = {"passed": passed, "failures": Array(failures), "metrics": metrics}


func _append_failure(failures: PackedStringArray, message: String) -> void:
	if failures.size() < MAX_RECORDED_FAILURES:
		failures.append(message)


func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var value: Variant = JSON.parse_string(file.get_as_text())
	return value if value is Dictionary else {}


func _write_json(path: String, value: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(value) + "\n")


func _source_hashes(paths: PackedStringArray) -> Dictionary:
	var result := {}
	for path in paths:
		result[path] = FileAccess.get_sha256(path) if FileAccess.file_exists(path) else "missing"
	return result


func _vector2_json(value: Vector2) -> Array[float]:
	return [_round6(value.x), _round6(value.y)]


func _round6(value: float) -> float:
	return round(value * 1000000.0) / 1000000.0
