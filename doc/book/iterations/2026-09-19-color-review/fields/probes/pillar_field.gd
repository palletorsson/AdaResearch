extends "res://doc/book/iterations/2026-09-19-color-review/fields/probes/recovery.gd"
var observations: Dictionary = {}
func run() -> void:
	await museum("Color_Pillar")
	var pillar: Node3D
	var atlas: Node3D
	for n in current_scene.find_children("*", "Node3D", true, false):
		if n.get_meta("artifact_lookup_name", "") == "pillarcolorcollection": pillar = n
		if n.get_meta("artifact_lookup_name", "") == "color_sets_overview": atlas = n
	check(pillar != null and atlas != null, "both primary field and named collections are present")
	if pillar == null or atlas == null: quit(1); return
	var samples := pillar.find_children("Pillar_*", "Node3D", false, false)
	check(samples.size() == 35, "five by seven actual pillar samples")
	var records: Array = []
	for n: Node3D in samples:
		var expected: Color = pillar.sample_space(n.position)
		var actual: Color = n.get_node("Column").material_override.albedo_color
		check(actual.is_equal_approx(expected), "%s material matches coordinate field" % n.name)
		check(n.get_node("SampleAddress").text.contains(expected.to_html(false)), "%s label agrees with material sample" % n.name)
		records.append({"node": n.name, "local": str(n.position), "hex": expected.to_html(false)})
	check(is_equal_approx(pillar.get_node("Pillar_0_0").scale.y * 4.0, 4.6), "pillar height is 4.6 metres")
	var floor: MeshInstance3D = pillar.get_node("ContinuousGradient")
	var arrays := floor.mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var uv_records: Array = []
	for i in range(vertices.size()):
		var p: Vector3 = floor.position + vertices[i]
		var expected_uv := Vector2(p.x / 12.8, p.z / 19.2)
		check(uvs[i].is_equal_approx(expected_uv), "floor UV corner %d samples the same x/z directions as pillars" % i)
		uv_records.append({"point": str(p), "uv": str(uvs[i]), "expected": str(expected_uv)})
	var sets := atlas.find_children("PaletteSet_*", "Node3D", false, false)
	check(sets.size() == 12, "twelve named palette groups on architectural wall")
	var stickers := atlas.find_children("Sticker_*", "RigidBody3D", true, false)
	check(stickers.size() > 0, "wall includes physical pickable swatches")
	check(stickers.all(func(n): return n.has_method("pick_up") and n.has_method("drop")), "every swatch carries the pick-up/drop contract")
	check(stickers.all(func(n): return n.get_node("Label").text.begins_with("#")), "each swatch has a hex/name label")
	observations = {"samples": records, "plane_corners": uv_records, "swatches": stickers.size(), "shader": floor.material_override.shader.code, "pillar_world": str(pillar.global_position), "gradient_world": str(floor.global_position)}
	var ray := PhysicsRayQueryParameters3D.create(pillar.to_global(Vector3(4.8, 2, 8)), pillar.to_global(Vector3(4.8, -2, 8)), 1)
	var hit: Dictionary = current_scene.get_world_3d().direct_space_state.intersect_ray(ray)
	observations["support_hit"] = str(hit)
	check(not hit.is_empty() and floor.global_position.y > hit.position.y, "continuous gradient sits above its physical supporting floor")
	var player: CharacterBody3D = current_scene.get("_player")
	var cam: Camera3D = current_scene.get("_cam")
	player.set_physics_process(false)
	current_scene.get("_feel").set_process(false)
	var field_eye: Vector3 = pillar.to_global(Vector3(4.8, 0, -4))
	field_eye.y = 1.2
	var field_target: Vector3 = pillar.to_global(Vector3(4.8, 0, 10))
	field_target.y = 0.0
	player.global_position += field_eye - cam.global_position
	cam.look_at(field_target)
	observations["field_camera"] = {"position": str(cam.global_position), "target": str(field_target), "fov": cam.fov, "viewport": str(root.size)}
	for i in range(25): current_scene.call("_cull_artifacts"); await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://doc/book/iterations/2026-09-19-color-review/fields/evidence/after/pillar-field-museum.png")
	player.global_position += atlas.to_global(Vector3(0, 1.7, 3)) - cam.global_position
	cam.look_at(atlas.to_global(Vector3(0, 1.55, 0)))
	for i in range(25): current_scene.call("_cull_artifacts"); await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://doc/book/iterations/2026-09-19-color-review/fields/evidence/after/palette-wall-museum.png")
	# Reconstruct the snapshotted old map token's sole changed parameter in
	# the same live museum. This holds camera, lighting and nearby artifacts
	# constant; it is a source-backed before-state replay, not another museum.
	var paired_records: Array = []
	var current_placement: Transform3D = pillar.transform
	var paired_eye := Vector3(24.8, 1.7, 4.0)
	var paired_target := Vector3(24.8, 0.5, 18.0)
	player.global_position += paired_eye - cam.global_position
	cam.fov = 70.0
	cam.look_at(paired_target)
	for state: String in ["before", "after"]:
		pillar.transform = current_placement
		if state == "before": pillar.position.y -= 0.5
		for i in range(25): current_scene.call("_cull_artifacts"); await process_frame
		await physics_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://doc/book/iterations/2026-09-19-color-review/fields/evidence/paired/pillar-field-" + state + ".png")
		paired_records.append({"state": state, "camera": str(cam.global_position), "target": str(paired_target), "fov": cam.fov, "pillar_y": pillar.global_position.y, "gradient_y": floor.global_position.y})
	pillar.transform = current_placement
	observations["paired_replay"] = paired_records
	var report := {"checks": checks, "failures": failures, "observations": observations, "headset_tested": false, "scope": "Actual museum field positions/materials/UV basis and swatch capability; human perception and tracked pickup not tested."}
	var f := FileAccess.open("res://doc/book/iterations/2026-09-19-color-review/fields/evidence/after/pillar-field-checks.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(report, "  "))
	print("PILLAR_FIELD ", JSON.stringify({"checks": checks, "failures": failures}))
	quit(0 if failures.is_empty() else 1)
