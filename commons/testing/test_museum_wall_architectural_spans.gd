# Direct headless contract smoke test for the additive museum wall detail helper.
extends SceneTree

const Spans := preload("res://commons/artifacts/museum/museum_wall_architectural_spans.gd")

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var test_root := Node3D.new()
	get_root().add_child(test_root)
	var cases: Array[Dictionary] = []
	for family in ["solid", "feature", "service", "endcap"]:
		for width in range(1, 5):
			cases.append({"family": family, "width_cells": width, "flip": family == "endcap" and width % 2 == 0})
	for case in cases:
		var host := Node3D.new()
		test_root.add_child(host)
		var config: Dictionary = case.duplicate()
		config.merge({"height": 4.0, "finish": "uffizi_stone", "wear_state": "lived_in", "quality_tier": 2, "enable_collision": true, "seed": 4067})
		var report: Dictionary = Spans.decorate(host, config)
		_check(bool(report.get("supported", false)), "%s supported" % case["family"])
		_check(bool(report.get("exact_width_preserved", false)), "%s exact width" % case["family"])
		_check(bool(report.get("budget", {}).get("passes", false)), "%s draw budget" % case["family"])
		_check(int(report.get("allocations_in_process", -1)) == 0, "%s no process allocations" % case["family"])
		var detail_root := host.get_node_or_null("ArchitecturalSpanDetail") as Node3D
		_check(detail_root != null, "%s detail root" % case["family"])
		_check(int(report.get("surface_story_elements", 0)) >= _minimum_story_elements(str(case["family"])), "%s bounded surface story" % case["family"])
		if detail_root != null:
			var actual_bounds := _visual_bounds_x(detail_root)
			var half_width := float(case["width_cells"]) * 0.5
			_check(actual_bounds.x >= -half_width - 0.001 and actual_bounds.y <= half_width + 0.001, "%s actual mesh envelope" % case["family"])
			_check(detail_root.find_child(_story_witness(str(case["family"])), true, false) != null, "%s semantic story witness" % case["family"])
		if case["family"] in ["service", "endcap"]:
			_check(int(report.get("collision_shapes", 0)) == 1, "%s detail collision" % case["family"])
	var stone := Spans.create_pbr_material("stone", Color.WHITE, Vector2.ONE, 3)
	var bronze := Spans.create_pbr_material("bronze", Color.WHITE, Vector2.ONE, 3)
	_check(stone != null and bronze != null, "PBR material factory")
	_check(Spans.uv_variant(20, 0) != Spans.uv_variant(20, 1), "adjacent-cell UV variation")
	_check(not Spans.instance_uniforms_supported(), "zero instance-uniform contract")
	var caches: Dictionary = Spans.cache_report()
	_check(int(caches.get("uv_variant_limit", 0)) == 8, "bounded UV material variants")
	_check(int(caches.get("materials", 999)) <= 14, "architectural material cache <= 14")
	_check(int(caches.get("profile_meshes", 0)) > 0, "shared chamfer profile cache")
	print("MUSEUM_WALL_ARCHITECTURAL_SPANS_TEST failures=%d cache=%s" % [_failures, caches])
	test_root.queue_free()
	quit(0 if _failures == 0 else 1)


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: %s" % label)
	else:
		_failures += 1
		push_error("FAIL: %s" % label)


func _minimum_story_elements(family: String) -> int:
	return {"solid": 7, "feature": 6, "service": 7, "endcap": 7}.get(family, 0)


func _story_witness(family: String) -> String:
	return {
		"solid": "SolidDutchmanRepair",
		"feature": "FeatureInventoryPlaque",
		"service": "ServiceCabinetHinges",
		"endcap": "EndcapCornerRepairPlate",
	}.get(family, "")


func _visual_bounds_x(root: Node3D) -> Vector2:
	var bounds := {"min": INF, "max": -INF}
	_accumulate_visual_bounds(root, Transform3D.IDENTITY, bounds)
	return Vector2(float(bounds["min"]), float(bounds["max"]))


func _accumulate_visual_bounds(node: Node, parent_transform: Transform3D, bounds: Dictionary) -> void:
	var local_transform := Transform3D.IDENTITY
	if node is Node3D:
		local_transform = (node as Node3D).transform
	var world_transform := parent_transform * local_transform
	if node is MeshInstance3D:
		var mesh := (node as MeshInstance3D).mesh
		if mesh != null:
			_accumulate_aabb(mesh.get_aabb(), world_transform, bounds)
	elif node is MultiMeshInstance3D:
		var multimesh := (node as MultiMeshInstance3D).multimesh
		if multimesh != null and multimesh.mesh != null:
			for index in range(multimesh.instance_count):
				_accumulate_aabb(multimesh.mesh.get_aabb(), world_transform * multimesh.get_instance_transform(index), bounds)
	for child in node.get_children():
		_accumulate_visual_bounds(child, world_transform, bounds)


func _accumulate_aabb(aabb: AABB, transform: Transform3D, bounds: Dictionary) -> void:
	for x_side in [0.0, 1.0]:
		for y_side in [0.0, 1.0]:
			for z_side in [0.0, 1.0]:
				var local := aabb.position + Vector3(aabb.size.x * float(x_side), aabb.size.y * float(y_side), aabb.size.z * float(z_side))
				var x := (transform * local).x
				bounds["min"] = minf(float(bounds["min"]), x)
				bounds["max"] = maxf(float(bounds["max"]), x)
