# validate_museum_wall_collision_truth.gd
# Executable collision/material truth audit for every declared museum-wall variant.
# Missing tags or unsupported behavior are hard failures; the runner never treats
# metadata declarations as a substitute for live physics queries.

extends SceneTree

const PIECE_SCENE := preload("res://commons/artifacts/museum/museum_wall_piece.tscn")
const QUALITY_PATH := "res://commons/data/museum_wall_aaa_quality.json"
const PHYSICS_PATH := "res://commons/data/museum_wall_physics_contract.json"
const OUTPUT_PATH := "res://ada_run/museum_aaa_pass/museum_wall_collision_truth_validation.json"
const PRIOR_LOG_PATH := "res://ada_run/museum_aaa_pass/museum_wall_collision_truth_engine.log"

const COVERAGE_SAMPLES_PER_VARIANT := 10000
const SWEEP_COUNT := 1000
const REBUILD_COUNT := 100
const MAX_RECORDED_FAILURES := 48

var _quality: Dictionary = {}
var _physics: Dictionary = {}
var _tests: Dictionary = {}
var _variant_metrics: Array[Dictionary] = []
var _visual_role_failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var source_paths := PackedStringArray([
		"res://commons/artifacts/museum/museum_wall_piece.gd",
		"res://commons/artifacts/museum/museum_wall_architectural_spans.gd",
		"res://commons/artifacts/museum/museum_wall_opening_spans.gd",
		QUALITY_PATH,
		PHYSICS_PATH,
		"res://commons/testing/validate_museum_wall_collision_truth.gd",
	])
	var source_hashes_at_start := _source_hashes(source_paths)
	_quality = _load_json(QUALITY_PATH)
	_physics = _load_json(PHYSICS_PATH)
	var variants := _declared_variants()
	var load_failures: PackedStringArray = []
	if _quality.is_empty():
		load_failures.append("quality contract did not parse")
	if _physics.is_empty():
		load_failures.append("physics contract did not parse")
	if variants.size() != 23:
		load_failures.append("V23 resolved to %d variants" % variants.size())
	var ct01_failures: PackedStringArray = []
	var ct02_failures: PackedStringArray = []
	var ct03_failures: PackedStringArray = []
	var ct05_failures: PackedStringArray = []
	var ct06_failures: PackedStringArray = []
	var ct07_failures: PackedStringArray = []
	var ct08_failures: PackedStringArray = []
	var ct09_failures: PackedStringArray = []
	if not load_failures.is_empty():
		for failure in load_failures:
			for target in [ct01_failures, ct02_failures, ct03_failures, ct05_failures, ct06_failures, ct07_failures, ct08_failures, ct09_failures]:
				_append_failure(target, "precondition: %s" % failure)
	var audited_bodies := 0
	var tagged_bodies := 0
	var coverage_queries := 0
	var reverse_queries := 0
	var sweep_total := 0
	var sweep_passed := 0
	var sweep_max_bracket_m := 0.0
	var observed_shape_counts: Dictionary = {}

	for variant in variants:
		var family := str(variant["family"])
		var width := int(variant["width"])
		var key := "%s_%dm" % [family, width]
		var piece: Node3D = await _spawn_piece(family, width, 0, true, 4067)
		if piece == null:
			_append_failure(ct01_failures, "%s did not instantiate" % key)
			continue

		var bodies := _nodes_of_type(piece, "body")
		var shapes := _nodes_of_type(piece, "shape")
		var rigid_bodies := _nodes_of_type(piece, "rigid")
		var body_audit := _audit_surface_bodies(bodies)
		audited_bodies += int(body_audit["body_count"])
		tagged_bodies += int(body_audit["exact_surface_tag_count"])
		for failure in body_audit["failures"]:
			_append_failure(ct01_failures, "%s: %s" % [key, failure])

		_visual_role_failures.clear()
		var visual_records := _declared_visual_aabbs(piece, family)
		for failure in _visual_role_failures:
			_append_failure(ct02_failures, "%s: %s" % [key, failure])
			_append_failure(ct03_failures, "%s: %s" % [key, failure])
		var coverage := _sample_mesh_to_collider(piece, visual_records, COVERAGE_SAMPLES_PER_VARIANT)
		coverage_queries += int(coverage["queries"])
		if not bool(coverage["passed"]):
			_append_failure(ct02_failures, "%s p95=%.4fm max=%.4fm misses=%d" % [key, float(coverage["p95_m"]), float(coverage["max_m"]), int(coverage["misses"])])

		var reverse := _sample_collider_to_mesh(shapes, visual_records, COVERAGE_SAMPLES_PER_VARIANT)
		reverse_queries += int(reverse["queries"])
		if not bool(reverse["passed"]):
			_append_failure(ct03_failures, "%s p95=%.4fm max=%.4fm misses=%d" % [key, float(reverse["p95_m"]), float(reverse["max_m"]), int(reverse["misses"])])

		var off_piece: Node3D = await _spawn_piece(family, width, 0, false, 4067)
		var disabled_bodies := _nodes_of_type(off_piece, "body").size()
		var disabled_shapes := _nodes_of_type(off_piece, "shape").size()
		if disabled_bodies != 0 or disabled_shapes != 0:
			_append_failure(ct05_failures, "%s collision=false left %d bodies/%d shapes" % [key, disabled_bodies, disabled_shapes])
		if bodies.is_empty() or shapes.is_empty():
			_append_failure(ct05_failures, "%s collision=true produced no collision" % key)
		if not bool(coverage["passed"]) or not bool(reverse["passed"]):
			_append_failure(ct05_failures, "%s cannot prove all required solids/no extras because bidirectional truth failed" % key)
		await _destroy_piece(off_piece)

		if not rigid_bodies.is_empty():
			_append_failure(ct06_failures, "%s has %d runtime rigid bodies" % [key, rigid_bodies.size()])
		var family_contract: Dictionary = (_physics.get("families", {}) as Dictionary).get(family, {})
		var authored_body_manifest: Variant = family_contract.get("collision_body_manifest", null)
		var authored_shape_manifest: Variant = family_contract.get("collision_shape_manifest", null)
		var observed_bodies_by_surface: Dictionary = {}
		var observed_shapes_by_surface: Dictionary = {}
		var observed_shape_types_by_surface: Dictionary = {}
		for body_node in bodies:
			if not body_node is StaticBody3D:
				continue
			var body := body_node as StaticBody3D
			var body_surface_id := _resolved_surface_id(body)
			observed_bodies_by_surface[body_surface_id] = int(observed_bodies_by_surface.get(body_surface_id, 0)) + 1
			for shape_node in _nodes_of_type(body, "shape"):
				var collision := shape_node as CollisionShape3D
				if collision == null or collision.shape == null:
					continue
				observed_shapes_by_surface[body_surface_id] = int(observed_shapes_by_surface.get(body_surface_id, 0)) + 1
				var type_set: Dictionary = observed_shape_types_by_surface.get(body_surface_id, {})
				type_set[collision.shape.get_class()] = true
				observed_shape_types_by_surface[body_surface_id] = type_set
		if authored_body_manifest == null:
			_append_failure(ct06_failures, "%s family has no authored collision_body_manifest" % family)
		if authored_shape_manifest == null:
			_append_failure(ct06_failures, "%s family has no authored collision_shape_manifest" % family)
		if authored_body_manifest is Dictionary and authored_shape_manifest is Dictionary:
			var body_manifest_dict: Dictionary = authored_body_manifest
			var shape_manifest_dict: Dictionary = authored_shape_manifest
			if not _same_dictionary_keys(body_manifest_dict, shape_manifest_dict):
				_append_failure(ct06_failures, "%s body/shape manifest zones differ" % family)
			for zone_value in body_manifest_dict:
				var zone := str(zone_value)
				var body_zone_spec: Dictionary = body_manifest_dict[zone] if body_manifest_dict[zone] is Dictionary else {}
				var shape_zone_spec: Dictionary = shape_manifest_dict.get(zone, {}) if shape_manifest_dict.get(zone, {}) is Dictionary else {}
				var zone_surface_id := str(body_zone_spec.get("surface_id", zone))
				var shape_surface_id := str(shape_zone_spec.get("surface_id", zone_surface_id))
				var minimum_bodies := int(body_zone_spec.get("min_bodies", 1))
				var maximum_bodies := int(body_zone_spec.get("max_bodies", -1))
				var minimum_shapes := int(shape_zone_spec.get("min_shapes", 1))
				var maximum_shapes := int(shape_zone_spec.get("max_shapes", -1))
				var allowed_types: Array = shape_zone_spec.get("allowed_types", [])
				var body_count := int(observed_bodies_by_surface.get(zone_surface_id, 0))
				var shape_count := int(observed_shapes_by_surface.get(shape_surface_id, 0))
				if zone_surface_id != shape_surface_id or maximum_bodies < minimum_bodies or maximum_shapes < minimum_shapes or allowed_types.is_empty():
					_append_failure(ct06_failures, "%s zone %s has invalid authored bounds" % [family, zone])
				elif body_count < minimum_bodies or body_count > maximum_bodies or shape_count < minimum_shapes or shape_count > maximum_shapes:
					_append_failure(ct06_failures, "%s zone %s observed %d bodies/%d shapes outside bodies[%d,%d] shapes[%d,%d]" % [key, zone, body_count, shape_count, minimum_bodies, maximum_bodies, minimum_shapes, maximum_shapes])
				var observed_types: Dictionary = observed_shape_types_by_surface.get(shape_surface_id, {})
				for observed_type_value in observed_types:
					if not allowed_types.has(str(observed_type_value)):
						_append_failure(ct06_failures, "%s zone %s uses undeclared shape type %s" % [key, zone, str(observed_type_value)])
			for observed_surface_value in observed_bodies_by_surface:
				var observed_surface := str(observed_surface_value)
				var declared := body_manifest_dict.has(observed_surface)
				if not declared:
					for declared_zone_value in body_manifest_dict:
						var declared_zone_spec: Dictionary = body_manifest_dict[declared_zone_value] if body_manifest_dict[declared_zone_value] is Dictionary else {}
						if str(declared_zone_spec.get("surface_id", str(declared_zone_value))) == observed_surface:
							declared = true
							break
				if not declared:
					_append_failure(ct06_failures, "%s contains undeclared surface body zone '%s'" % [key, observed_surface])
		elif authored_body_manifest != null or authored_shape_manifest != null:
			_append_failure(ct06_failures, "%s collision manifest has unsupported schema" % family)
		if not observed_shape_counts.has(family):
			observed_shape_counts[family] = shapes.size()
		elif int(observed_shape_counts[family]) != shapes.size():
			_append_failure(ct06_failures, "%s shape count scales with width (%d -> %d)" % [key, int(observed_shape_counts[family]), shapes.size()])

		var lod_result: Dictionary = await _audit_lod_collision(family, width)
		if not bool(lod_result["passed"]):
			_append_failure(ct07_failures, "%s: %s" % [key, str(lod_result["failure"])])

		var rebuild_signature_result: Dictionary = await _audit_three_rebuilds(piece, family, width)
		if not bool(rebuild_signature_result["passed"]):
			_append_failure(ct08_failures, "%s collision signature changed across seed/rebuild" % key)

		var target_sweeps := mini(ceili(float(SWEEP_COUNT) / float(variants.size())), SWEEP_COUNT - sweep_total)
		var sweep_result := _run_variant_sweeps(piece, family, width, target_sweeps, sweep_total)
		sweep_total += int(sweep_result["count"])
		sweep_passed += int(sweep_result["passed_count"])
		sweep_max_bracket_m = maxf(sweep_max_bracket_m, float(sweep_result["max_bracket_m"]))
		for failure in sweep_result["failures"]:
			_append_failure(ct09_failures, "%s: %s" % [key, failure])

		_variant_metrics.append({
			"variant": key,
			"bodies": bodies.size(),
			"shapes": shapes.size(),
			"tagged_bodies": int(body_audit["exact_surface_tag_count"]),
			"mesh_to_collider_p95_m": _round6(float(coverage["p95_m"])),
			"mesh_to_collider_max_m": _round6(float(coverage["max_m"])),
			"collider_to_mesh_p95_m": _round6(float(reverse["p95_m"])),
			"collider_to_mesh_max_m": _round6(float(reverse["max_m"])),
		})
		await _destroy_piece(piece)

	var labeled_result: Dictionary = await _run_labeled_rays()
	var ct04_failures: PackedStringArray = labeled_result["failures"]
	var rebuild_result: Dictionary = await _run_rebuild_leak_cycle(variants)
	var ct10_failures: PackedStringArray = rebuild_result["failures"]
	var source_hashes_at_end := _source_hashes(source_paths)
	var source_stable := source_hashes_at_start == source_hashes_at_end
	if not source_stable:
		_append_failure(ct10_failures, "source hashes changed while runner was executing; report is stale")

	_set_test("CT-01", ct01_failures.is_empty(), ct01_failures, {
		"bodies_audited": audited_bodies,
		"exact_surface_tags": tagged_bodies,
		"friction_tolerance": 0.02,
		"bounce_tolerance": 0.01,
	})
	_set_test("CT-02", ct02_failures.is_empty(), ct02_failures, {
		"samples_per_variant": COVERAGE_SAMPLES_PER_VARIANT,
		"bidirectional_ray_queries": coverage_queries,
		"p95_gate_m": 0.005,
		"max_gate_m": 0.012,
	})
	_set_test("CT-03", ct03_failures.is_empty(), ct03_failures, {
		"samples_per_variant": COVERAGE_SAMPLES_PER_VARIANT,
		"collider_surface_queries": reverse_queries,
		"p95_gate_m": 0.005,
		"max_gate_m": 0.012,
	})
	_set_test("CT-04", ct04_failures.is_empty(), ct04_failures, labeled_result["metrics"])
	_set_test("CT-05", ct05_failures.is_empty(), ct05_failures, {"variants_toggled": variants.size()})
	_set_test("CT-06", ct06_failures.is_empty(), ct06_failures, {
		"body_budget_interpretation": "one bounded StaticBody3D zone per PhysicsMaterial/surface route; zero RigidBody3D unless explicitly interactive",
		"matrix_conflict": "a single StaticBody3D cannot expose distinct PhysicsMaterial/metadata per CollisionShape3D in Godot 4.6, so literal one-body enforcement would contradict CT-01 and CT-04",
		"manifest_source": PHYSICS_PATH,
		"required_manifest_keys": ["families.<family>.collision_body_manifest", "families.<family>.collision_shape_manifest"],
		"observed_shape_counts": observed_shape_counts,
	})
	_set_test("CT-07", ct07_failures.is_empty(), ct07_failures, {"lods": [0, 1, 2], "voxel_pitch_m": 0.01, "proof": "exact primitive equality implies zero voxel disagreement"})
	_set_test("CT-08", ct08_failures.is_empty(), ct08_failures, {"rebuilds_per_variant": 3, "different_visual_seeds": true})
	if sweep_total != SWEEP_COUNT:
		_append_failure(ct09_failures, "executed %d of %d mandatory sweeps" % [sweep_total, SWEEP_COUNT])
	_set_test("CT-09", ct09_failures.is_empty(), ct09_failures, {
		"sweeps": sweep_total,
		"passed_sweeps": sweep_passed,
		"hand_sphere_radius_m": 0.1,
		"head_player_capsule_radius_m": 0.3,
		"safe_state_max_penetration_m": 0.0,
		"max_cast_bracket_m": _round6(sweep_max_bracket_m),
	})
	_set_test("CT-10", ct10_failures.is_empty(), ct10_failures, rebuild_result["metrics"])

	var passed_count := 0
	var failed_count := 0
	for test_id in _tests:
		if bool((_tests[test_id] as Dictionary)["passed"]):
			passed_count += 1
		else:
			failed_count += 1
	var report := {
		"schema": "ada-museum-wall-collision-truth-v1",
		"passed": failed_count == 0,
		"engine": Engine.get_version_info(),
		"source_hashes": source_hashes_at_end,
		"source_hashes_at_start": source_hashes_at_start,
		"source_stable": source_stable,
		"contract_consistency": {
			"issue": "round-2 CT-06 says one static body while CT-01/04 require body-level multi-surface PhysicsMaterial and ray routing",
			"godot_4_6_constraint": "PhysicsMaterial and collider metadata are CollisionObject3D properties, not CollisionShape3D properties",
			"resolution": "bounded authored collision_body_manifest with one static body zone per canonical surface; no unbounded body-per-decoration growth",
		},
		"tests_passed": passed_count,
		"tests_failed": failed_count,
		"tests": _tests,
		"variants": _variant_metrics,
	}
	_write_json(OUTPUT_PATH, report)
	print("MUSEUM_WALL_COLLISION_TRUTH=" + JSON.stringify(report))
	print("MUSEUM_WALL_COLLISION_TRUTH_TESTS=%d PASSED=%d FAILED=%d" % [_tests.size(), passed_count, failed_count])
	quit(0 if failed_count == 0 else 1)


func _spawn_piece(family: String, width: int, lod: int, collision: bool, seed: int) -> Node3D:
	var piece := PIECE_SCENE.instantiate() as Node3D
	if piece == null:
		return null
	piece.name = "CollisionTruth_%s_%dm_L%d" % [family, width, lod]
	piece.set("kind", family)
	piece.set("width_cells", width)
	piece.set("height", 4.0)
	piece.set("lod_level", lod)
	piece.set("enable_collision", collision)
	piece.set("detail_seed", seed)
	root.add_child(piece)
	await process_frame
	await physics_frame
	return piece


func _destroy_piece(piece: Node) -> void:
	if piece != null and is_instance_valid(piece):
		piece.queue_free()
	await process_frame
	await physics_frame


func _audit_surface_bodies(bodies: Array[Node]) -> Dictionary:
	var failures: PackedStringArray = []
	var exact_tags := 0
	var surfaces: Dictionary = _physics.get("surfaces", {})
	for node in bodies:
		if not node is CollisionObject3D:
			continue
		var body := node as CollisionObject3D
		var expected := _expected_surface_for_body(body)
		var surface_id := _resolved_surface_id(body)
		if surfaces.has(surface_id):
			exact_tags += 1
		else:
			failures.append("%s has invalid/missing surface_id '%s' (expected %s)" % [body.name, surface_id, expected])
			continue
		if surface_id != expected:
			failures.append("%s routes %s; expected %s" % [body.name, surface_id, expected])
		var surface: Dictionary = surfaces[surface_id]
		var material: PhysicsMaterial = null
		if body is StaticBody3D:
			material = (body as StaticBody3D).physics_material_override
		elif body is RigidBody3D:
			material = (body as RigidBody3D).physics_material_override
		if material == null:
			failures.append("%s has no PhysicsMaterial" % body.name)
		else:
			if absf(material.friction - float(surface["friction"])) > 0.02:
				failures.append("%s friction %.3f != %.3f" % [body.name, material.friction, float(surface["friction"])])
			if absf(material.bounce - float(surface["bounce"])) > 0.01:
				failures.append("%s bounce %.3f != %.3f" % [body.name, material.bounce, float(surface["bounce"])])
		for tag in ["impact", "decal", "breakability"]:
			if str(body.get_meta(tag, "")) != str(surface[tag]):
				failures.append("%s %s tag '%s' != '%s'" % [body.name, tag, str(body.get_meta(tag, "")), str(surface[tag])])
	return {"body_count": bodies.size(), "exact_surface_tag_count": exact_tags, "failures": failures}


func _expected_surface_for_body(body: CollisionObject3D) -> String:
	var lower := str(body.name).to_lower()
	if lower.contains("glass"):
		return "glass_laminated"
	if lower.contains("service"):
		return "painted_metal"
	if str(body.get_meta("surface_audio", "")) in ["stone", "bronze", "painted_metal", "glass_laminated", "rubber"]:
		return str(body.get_meta("surface_audio"))
	return "stone"


func _sample_mesh_to_collider(piece: Node3D, records: Array[Dictionary], sample_count: int) -> Dictionary:
	var errors: Array[float] = []
	var misses := 0
	var total_area := 0.0
	for record in records:
		total_area += float(record["area"])
	if total_area <= 0.0:
		return {"passed": false, "queries": 0, "misses": sample_count, "p95_m": 9999.0, "max_m": 9999.0}
	var exclusion_sets: Dictionary = {}
	var bodies := _nodes_of_type(piece, "body")
	for record in records:
		var target := str(record.get("collision_target", ""))
		if exclusion_sets.has(target):
			continue
		var excluded: Array[RID] = []
		for body_node in bodies:
			if body_node is CollisionObject3D and str(body_node.name) != target:
				excluded.append((body_node as CollisionObject3D).get_rid())
		exclusion_sets[target] = excluded
	var space := piece.get_world_3d().direct_space_state
	for index in range(sample_count):
		var record := _weighted_record(records, total_area, (float(index) + 0.5) / float(sample_count))
		var bounds: AABB = record["aabb"]
		var u := fposmod((float(index) + 1.0) * 0.61803398875, 1.0)
		var v := fposmod((float(index) + 1.0) * 0.41421356237, 1.0)
		var point := Vector3(lerpf(bounds.position.x, bounds.end.x, u), lerpf(bounds.position.y, bounds.end.y, v), bounds.end.z if index % 2 == 0 else bounds.position.z)
		var best := 9999.0
		for direction in [-1.0, 1.0]:
			var start := point + Vector3(0, 0, -direction * 1.0)
			var finish := point + Vector3(0, 0, direction * 1.0)
			var query := PhysicsRayQueryParameters3D.create(start, finish, 0x7FFFFFFF)
			query.collide_with_areas = false
			query.collide_with_bodies = true
			query.hit_from_inside = true
			query.exclude = exclusion_sets.get(str(record.get("collision_target", "")), [])
			var hit := space.intersect_ray(query)
			if not hit.is_empty():
				best = minf(best, Vector3(hit["position"]).distance_to(point))
		if best >= 9998.0:
			misses += 1
		errors.append(best)
	errors.sort()
	var p95 := errors[mini(errors.size() - 1, int(floor(float(errors.size()) * 0.95)))]
	var maximum := errors[-1]
	return {"passed": misses == 0 and p95 <= 0.005 and maximum <= 0.012, "queries": sample_count * 2, "misses": misses, "p95_m": p95, "max_m": maximum}


func _sample_collider_to_mesh(shapes: Array[Node], records: Array[Dictionary], sample_count: int) -> Dictionary:
	var collider_records: Array[Dictionary] = []
	var total_area := 0.0
	for node in shapes:
		var collision := node as CollisionShape3D
		if collision == null or not collision.shape is BoxShape3D or collision.disabled:
			continue
		# Area3D shapes are interaction/query volumes, not solid collision proxies.
		# Live CT rays and sweeps also set collide_with_areas=false, so including an
		# Area here would compare a non-blocking volume against visible structure.
		var owner := collision.get_parent()
		if not owner is PhysicsBody3D:
			continue
		var size := (collision.shape as BoxShape3D).size
		var local_bounds := AABB(-size * 0.5, size)
		var bounds: AABB = collision.global_transform * local_bounds
		var area := maxf(0.000001, bounds.size.x * bounds.size.y * 2.0 + bounds.size.x * bounds.size.z * 2.0 + bounds.size.y * bounds.size.z * 2.0)
		collider_records.append({"aabb": bounds, "area": area, "collision_target": str(owner.name)})
		total_area += area
	if collider_records.is_empty() or records.is_empty():
		return {"passed": false, "queries": 0, "misses": sample_count, "p95_m": 9999.0, "max_m": 9999.0}
	var errors: Array[float] = []
	var misses := 0
	for index in range(sample_count):
		var record := _weighted_record(collider_records, total_area, (float(index) + 0.5) / float(sample_count))
		var bounds: AABB = record["aabb"]
		var u := fposmod((float(index) + 1.0) * 0.754877666, 1.0)
		var v := fposmod((float(index) + 1.0) * 0.569840296, 1.0)
		var point := Vector3(lerpf(bounds.position.x, bounds.end.x, u), lerpf(bounds.position.y, bounds.end.y, v), bounds.end.z if index % 2 == 0 else bounds.position.z)
		var best := 9999.0
		for visual_record in records:
			if str(visual_record.get("collision_target", "")) == str(record.get("collision_target", "")):
				best = minf(best, _point_aabb_distance(point, visual_record["aabb"]))
		if best >= 9998.0:
			misses += 1
		errors.append(best)
	errors.sort()
	var p95 := errors[mini(errors.size() - 1, int(floor(float(errors.size()) * 0.95)))]
	var maximum := errors[-1]
	return {"passed": misses == 0 and p95 <= 0.005 and maximum <= 0.012, "queries": sample_count, "misses": misses, "p95_m": p95, "max_m": maximum}


func _declared_visual_aabbs(piece: Node3D, family: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var surfaces: Dictionary = _physics.get("surfaces", {})
	for node in _all_descendants(piece):
		if not node is MeshInstance3D:
			continue
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.mesh == null:
			continue
		var role := str(mesh_instance.get_meta("collision_role", ""))
		var surface_id := str(mesh_instance.get_meta("physics_surface_id", ""))
		var target := str(mesh_instance.get_meta("collision_target", ""))
		if role == "visual_only":
			if surface_id != "" or target != "":
				_append_failure(_visual_role_failures, "%s visual_only mesh has solid target/surface metadata" % mesh_instance.name)
			continue
		if role != "solid":
			_append_failure(_visual_role_failures, "%s mesh has missing/unknown collision_role '%s'" % [mesh_instance.name, role])
			continue
		if target == "" or not surfaces.has(surface_id):
			_append_failure(_visual_role_failures, "%s solid mesh has invalid surface '%s' or empty target" % [mesh_instance.name, surface_id])
			continue
		var target_node := piece.find_child(target, true, false)
		if not target_node is PhysicsBody3D:
			_append_failure(_visual_role_failures, "%s solid target '%s' is not a PhysicsBody3D" % [mesh_instance.name, target])
			continue
		if _resolved_surface_id(target_node as CollisionObject3D) != surface_id:
			_append_failure(_visual_role_failures, "%s surface '%s' does not match target '%s'" % [mesh_instance.name, surface_id, target])
			continue
		var bounds: AABB = mesh_instance.global_transform * mesh_instance.get_aabb()
		var area := maxf(0.000001, bounds.size.x * bounds.size.y)
		result.append({"name": str(mesh_instance.name), "aabb": bounds, "area": area, "physics_surface_id": surface_id, "collision_target": target})
	return result


func _weighted_record(records: Array[Dictionary], total_area: float, normalized: float) -> Dictionary:
	var target := clampf(normalized, 0.0, 0.999999) * total_area
	var cursor := 0.0
	for record in records:
		cursor += float(record["area"])
		if target <= cursor:
			return record
	return records[-1]


func _point_aabb_distance(point: Vector3, bounds: AABB) -> float:
	var closest := Vector3(
		clampf(point.x, bounds.position.x, bounds.end.x),
		clampf(point.y, bounds.position.y, bounds.end.y),
		clampf(point.z, bounds.position.z, bounds.end.z)
	)
	return point.distance_to(closest)


func _audit_lod_collision(family: String, width: int) -> Dictionary:
	var signatures: PackedStringArray = []
	var rid_sets: Array[PackedInt64Array] = []
	for lod in [0, 1, 2]:
		var piece: Node3D = await _spawn_piece(family, width, lod, true, 9001)
		signatures.append(_collision_signature(piece, false))
		var ids: PackedInt64Array = []
		for node in _nodes_of_type(piece, "shape"):
			var collision := node as CollisionShape3D
			if collision != null and collision.shape != null:
				ids.append(collision.shape.get_rid().get_id())
		ids.sort()
		rid_sets.append(ids)
		await _destroy_piece(piece)
	var same_geometry := signatures[0] == signatures[1] and signatures[1] == signatures[2]
	var same_resources := rid_sets[0] == rid_sets[1] and rid_sets[1] == rid_sets[2]
	return {"passed": same_geometry and same_resources, "failure": "LOD collision geometry/resources differ" if not same_geometry or not same_resources else "", "occupancy_disagreement_percent": 0.0 if same_geometry else 100.0}


func _audit_three_rebuilds(piece: Node3D, family: String, width: int) -> Dictionary:
	var signatures: PackedStringArray = []
	for rebuild in range(3):
		piece.call("apply_grid_config", {"kind": family, "width_cells": width, "lod_level": rebuild, "enable_collision": true, "detail_seed": 1111 + rebuild * 7919})
		await process_frame
		await physics_frame
		signatures.append(_collision_signature(piece, false))
	return {"passed": signatures[0] == signatures[1] and signatures[1] == signatures[2], "signatures": signatures}


func _collision_signature(piece: Node, include_rids: bool) -> String:
	var records: Array[Dictionary] = []
	for node in _nodes_of_type(piece, "shape"):
		var collision := node as CollisionShape3D
		if collision == null or collision.shape == null:
			continue
		var parent := collision.get_parent() as CollisionObject3D
		var record := {
			"body": str(parent.name) if parent != null else "",
			"shape": collision.shape.get_class(),
			"transform": _transform_key(collision.global_transform),
			"layer": parent.collision_layer if parent != null else 0,
			"mask": parent.collision_mask if parent != null else 0,
			"surface": _resolved_surface_id(parent) if parent != null else "",
		}
		if collision.shape is BoxShape3D:
			record["size"] = _vector_key((collision.shape as BoxShape3D).size)
		if include_rids:
			record["rid"] = collision.shape.get_rid().get_id()
		records.append(record)
	records.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return JSON.stringify(a) < JSON.stringify(b))
	return JSON.stringify(records)


func _run_variant_sweeps(piece: Node3D, family: String, width: int, count: int, offset: int) -> Dictionary:
	var failures: PackedStringArray = []
	var passed_count := 0
	var max_bracket := 0.0
	var clear := _opening_clear(piece)
	for local_index in range(count):
		var index := offset + local_index
		var use_capsule := index % 2 == 1
		var shape: Shape3D
		var y: float
		if use_capsule:
			var capsule := CapsuleShape3D.new()
			capsule.radius = 0.3
			capsule.height = 1.8
			shape = capsule
			y = 0.9
		else:
			var sphere := SphereShape3D.new()
			sphere.radius = 0.1
			shape = sphere
			y = 0.42 + fposmod(float(index) * 0.371, 2.4)
		var expect_hit := family != "portal" or local_index % 3 == 2
		var x := 0.0
		if family == "portal" and expect_hit:
			x = float(clear.x) * 0.5 + 0.13
		elif family != "portal":
			x = lerpf(-float(width) * 0.34, float(width) * 0.34, fposmod(float(index) * 0.618, 1.0))
		var from_z := -1.0 if index % 4 < 2 else 1.0
		var motion := Vector3(0, 0, -from_z * 2.0)
		var result := _cast_shape(piece, shape, Transform3D(Basis.IDENTITY, Vector3(x, y, from_z)), motion)
		var hit := float(result["safe_fraction"]) < 0.999999
		var bracket := float(result["bracket_m"])
		max_bracket = maxf(max_bracket, bracket)
		# cast_motion's safe fraction is a non-penetrating terminal transform;
		# safe/unsafe bracket width is diagnostic solver precision, not penetration.
		if hit == expect_hit:
			passed_count += 1
		else:
			_append_failure(failures, "sweep %d expected_hit=%s actual_hit=%s bracket=%.6f" % [index, expect_hit, hit, bracket])
	return {"count": count, "passed_count": passed_count, "max_bracket_m": max_bracket, "failures": failures}


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


func _run_labeled_rays() -> Dictionary:
	var failures: PackedStringArray = []
	var probes := 0
	var passed := 0
	for spec in [
		{"family": "solid", "width": 2, "label": "stone", "from": Vector3(0, 1.7, 0.8), "to": Vector3(0, 1.7, -0.8), "expected": "stone"},
		{"family": "feature", "width": 2, "label": "bronze", "from": Vector3(0, 2.85, 0.8), "to": Vector3(0, 2.85, -0.8), "expected": "bronze"},
		{"family": "service", "width": 2, "label": "painted_metal", "from": Vector3(-0.7, 1.1, 0.8), "to": Vector3(-0.7, 1.1, -0.8), "expected": "painted_metal"},
		{"family": "window", "width": 3, "label": "glass", "from": Vector3(0.23, 1.25, 0.8), "to": Vector3(0.23, 1.25, -0.8), "expected": "glass_laminated"},
		{"family": "portal", "width": 3, "label": "rubber", "from": Vector3(1.13, 1.5, 0.8), "to": Vector3(1.13, 1.5, -0.8), "expected": "rubber"},
		{"family": "portal", "width": 3, "label": "open", "from": Vector3(0, 1.5, 0.8), "to": Vector3(0, 1.5, -0.8), "expected": ""},
		{"family": "vitrine", "width": 3, "label": "cavity", "from": Vector3(0, 1.5, 0.19), "to": Vector3(0, 1.5, -0.2), "expected": ""},
	]:
		var piece: Node3D = await _spawn_piece(str(spec["family"]), int(spec["width"]), 0, true, 4067)
		var query := PhysicsRayQueryParameters3D.create(spec["from"], spec["to"], 0x7FFFFFFF)
		query.collide_with_areas = false
		query.collide_with_bodies = true
		query.hit_from_inside = true
		var hit := piece.get_world_3d().direct_space_state.intersect_ray(query)
		var actual := ""
		if not hit.is_empty():
			var collider := hit["collider"] as CollisionObject3D
			if collider != null:
				actual = _resolved_surface_id(collider)
		probes += 1
		if actual == str(spec["expected"]):
			passed += 1
		else:
			_append_failure(failures, "%s expected '%s' got '%s'" % [spec["label"], spec["expected"], actual])
		await _destroy_piece(piece)
	return {"failures": failures, "metrics": {"labeled_rays": probes, "correct": passed, "labels": ["stone", "bronze", "painted_metal", "rubber", "glass", "open", "cavity"]}}


func _run_rebuild_leak_cycle(variants: Array[Dictionary]) -> Dictionary:
	var failures: PackedStringArray = []
	var log_audit := _audit_prior_log(PRIOR_LOG_PATH)
	if not bool(log_audit["available"]):
		_append_failure(failures, "prior engine log missing; warning/error evidence is mandatory")
	elif int(log_audit["attributable_issues"]) > 0:
		_append_failure(failures, "prior engine log has %d museum-wall warnings/errors" % int(log_audit["attributable_issues"]))
	var piece: Node3D = await _spawn_piece("solid", 1, 0, true, 5050)
	var expected_signatures: Dictionary = {}
	var first_round_rids: Dictionary = {}
	var late_rids: Dictionary = {}
	var process_callback_nodes := 0
	for index in range(REBUILD_COUNT):
		var variant: Dictionary = variants[index % variants.size()]
		var family := str(variant["family"])
		var width := int(variant["width"])
		piece.call("apply_grid_config", {"kind": family, "width_cells": width, "lod_level": index % 3, "enable_collision": true, "detail_seed": 5050 + index * 17})
		await process_frame
		await physics_frame
		var key := "%s_%d" % [family, width]
		var signature := _collision_signature(piece, false)
		if not expected_signatures.has(key):
			expected_signatures[key] = signature
		elif str(expected_signatures[key]) != signature:
			_append_failure(failures, "rebuild %d changed normalized collision signature for %s" % [index, key])
		for node in _nodes_of_type(piece, "shape"):
			var collision := node as CollisionShape3D
			if collision != null and collision.shape != null:
				var rid_key := str(collision.shape.get_rid().get_id())
				if index < variants.size():
					first_round_rids[rid_key] = true
				elif not first_round_rids.has(rid_key):
					late_rids[rid_key] = true
		for node in _all_descendants(piece):
			if _owns_process_callback(node):
				process_callback_nodes += 1
	if expected_signatures.size() != variants.size():
		_append_failure(failures, "only %d/%d variant baselines were exercised" % [expected_signatures.size(), variants.size()])
	if not late_rids.is_empty():
		_append_failure(failures, "%d new collision shape RIDs appeared after warm-up corpus" % late_rids.size())
	if process_callback_nodes > 0:
		_append_failure(failures, "%d custom process/physics callbacks found across rebuilds" % process_callback_nodes)
	var before_cleanup_shapes := _nodes_of_type(piece, "shape").size()
	await _destroy_piece(piece)
	return {"failures": failures, "metrics": {
		"rebuilds": REBUILD_COUNT,
		"variant_baselines": expected_signatures.size(),
		"shape_rids_after_warmup": late_rids.size(),
		"final_live_shapes_before_cleanup": before_cleanup_shapes,
		"custom_process_callbacks": process_callback_nodes,
		"prior_log": log_audit,
	}}


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


func _opening_clear(piece: Node3D) -> Vector2:
	var contract := piece.get_node_or_null("PieceContract")
	if contract != null:
		var report: Dictionary = contract.get_meta("opening_report", {})
		if report.has("clear_opening_m"):
			return Vector2(report["clear_opening_m"])
	return Vector2(1.2, 2.1)


func _resolved_surface_id(body: CollisionObject3D) -> String:
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


func _declared_variants() -> Array[Dictionary]:
	var variants: Array[Dictionary] = []
	var families: Dictionary = _quality.get("families", {})
	for family_value in families:
		var family := str(family_value)
		var family_data: Dictionary = families[family]
		for width_value in family_data.get("widths", []):
			variants.append({"family": family, "width": int(width_value)})
	return variants


func _nodes_of_type(node: Node, requested: String) -> Array[Node]:
	var result: Array[Node] = []
	if node == null:
		return result
	for child in _all_descendants(node):
		match requested:
			"body":
				if child is StaticBody3D or child is AnimatableBody3D or child is RigidBody3D:
					result.append(child)
			"rigid":
				if child is RigidBody3D:
					result.append(child)
			"shape":
				if child is CollisionShape3D and child.get_parent() is CollisionObject3D:
					result.append(child)
	return result


func _all_descendants(node: Node) -> Array[Node]:
	var result: Array[Node] = []
	for child in node.get_children():
		result.append(child)
		result.append_array(_all_descendants(child))
	return result


func _owns_process_callback(node: Node) -> bool:
	var script := node.get_script() as Script
	if script == null:
		return false
	for method in script.get_script_method_list():
		if str(method.get("name", "")) in ["_process", "_physics_process"]:
			return true
	return false


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


func _transform_key(transform: Transform3D) -> String:
	return "%s|%s|%s|%s" % [_vector_key(transform.basis.x), _vector_key(transform.basis.y), _vector_key(transform.basis.z), _vector_key(transform.origin)]


func _vector_key(value: Vector3) -> String:
	return "%.6f,%.6f,%.6f" % [value.x, value.y, value.z]


func _same_dictionary_keys(first: Dictionary, second: Dictionary) -> bool:
	if first.size() != second.size():
		return false
	for key in first:
		if not second.has(key):
			return false
	return true


func _round6(value: float) -> float:
	return round(value * 1000000.0) / 1000000.0
