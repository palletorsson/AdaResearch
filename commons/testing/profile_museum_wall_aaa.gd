extends SceneTree

const RUN_SCENE := preload("res://commons/artifacts/museum/museum_wall_run.tscn")
const ARCHITECTURAL_SPANS := preload("res://commons/artifacts/museum/museum_wall_architectural_spans.gd")
const OUTPUT_PATH := "res://ada_run/museum_aaa_pass/museum_wall_aaa_static_profile.json"
const RUN_SPEC := "endcap:1|service:2|feature:4|window:3|vitrine:3|solid:2|endcap:1"
const RUN_COUNT := 8


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var started_usec := Time.get_ticks_usec()
	var corpus := Node3D.new()
	corpus.name = "RepresentativeEndlessWallCorpus"
	root.add_child(corpus)
	for index in range(RUN_COUNT):
		var run: Node3D = RUN_SCENE.instantiate()
		run.set("run_spec", RUN_SPEC)
		run.set("detail_seed", 4067 + index * 104729)
		run.set("enable_collision", true)
		run.position = Vector3(0.0, 0.0, float(index) * 7.0)
		corpus.add_child(run)
	await process_frame
	await process_frame
	var build_ms := float(Time.get_ticks_usec() - started_usec) / 1000.0

	var metrics := {
		"schema": "ada-museum-wall-static-profile-v1",
		"date": Time.get_datetime_string_from_system(),
		"corpus": {"runs": RUN_COUNT, "length_m": RUN_COUNT * 16, "spec": RUN_SPEC},
		"build_ms": snappedf(build_ms, 0.01),
		"nodes": _count_nodes(corpus),
		"mesh_instances": _count_type(corpus, "MeshInstance3D"),
		"multimesh_draws": _count_type(corpus, "MultiMeshInstance3D"),
		"multimesh_subinstances": _count_multimesh_subinstances(corpus),
		"render_draw_nodes": _count_type(corpus, "MeshInstance3D") + _count_type(corpus, "MultiMeshInstance3D"),
		"static_bodies": _count_type(corpus, "StaticBody3D"),
		"collision_shapes": _count_type(corpus, "CollisionShape3D"),
		"unique_collision_shape_resources": _unique_collision_shape_count(corpus),
		"lights": _count_type(corpus, "Light3D"),
		"transparent_meshes": _count_transparent(corpus),
		"unique_mesh_resources": _unique_resource_count(corpus, true),
		"unique_material_resources": _unique_resource_count(corpus, false),
		"frame_callbacks": _count_frame_callbacks(corpus),
		"architectural_cache": ARCHITECTURAL_SPANS.cache_report(),
		"vr_90hz_certified": false,
		"vr_90hz_note": "Static structural profile only; certification requires a representative museum capture on each declared VR target."
	}
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(metrics) + "\n")
	print("MUSEUM_WALL_AAA_STATIC_PROFILE=" + JSON.stringify(metrics))
	quit(0)


func _count_nodes(node: Node) -> int:
	var count := 1
	for child in node.get_children():
		count += _count_nodes(child)
	return count


func _count_type(node: Node, class_type: String) -> int:
	var count := 1 if node.is_class(class_type) else 0
	for child in node.get_children():
		count += _count_type(child, class_type)
	return count


func _count_transparent(node: Node) -> int:
	var count := 0
	if node is MeshInstance3D:
		var material := (node as MeshInstance3D).material_override as StandardMaterial3D
		if material != null and material.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
			count += 1
	elif node is MultiMeshInstance3D:
		var multi_material := (node as MultiMeshInstance3D).material_override as StandardMaterial3D
		if multi_material != null and multi_material.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
			count += 1
	for child in node.get_children():
		count += _count_transparent(child)
	return count


func _unique_resource_count(node: Node, meshes: bool) -> int:
	var ids := {}
	_collect_resource_ids(node, meshes, ids)
	return ids.size()


func _collect_resource_ids(node: Node, meshes: bool, ids: Dictionary) -> void:
	if node is MeshInstance3D:
		var mesh_node := node as MeshInstance3D
		var resource: Resource = mesh_node.mesh if meshes else mesh_node.material_override
		if resource != null:
			ids[resource.get_instance_id()] = true
	elif node is MultiMeshInstance3D:
		var multi_node := node as MultiMeshInstance3D
		var multi_resource: Resource = multi_node.multimesh.mesh if meshes and multi_node.multimesh != null else multi_node.material_override
		if multi_resource != null:
			ids[multi_resource.get_instance_id()] = true
	for child in node.get_children():
		_collect_resource_ids(child, meshes, ids)


func _count_multimesh_subinstances(node: Node) -> int:
	var count := 0
	if node is MultiMeshInstance3D and (node as MultiMeshInstance3D).multimesh != null:
		count += (node as MultiMeshInstance3D).multimesh.instance_count
	for child in node.get_children():
		count += _count_multimesh_subinstances(child)
	return count


func _unique_collision_shape_count(node: Node) -> int:
	var ids := {}
	_collect_collision_shape_ids(node, ids)
	return ids.size()


func _collect_collision_shape_ids(node: Node, ids: Dictionary) -> void:
	if node is CollisionShape3D and (node as CollisionShape3D).shape != null:
		ids[(node as CollisionShape3D).shape.get_instance_id()] = true
	for child in node.get_children():
		_collect_collision_shape_ids(child, ids)


func _count_frame_callbacks(node: Node) -> int:
	var count := 0
	var script := node.get_script() as Script
	if script != null:
		for method in script.get_script_method_list():
			if str(method.get("name", "")) in ["_process", "_physics_process"]:
				count += 1
	for child in node.get_children():
		count += _count_frame_callbacks(child)
	return count
