extends "res://tools/probes/transformation_encounters.gd"
const Pattern = preload("res://commons/artifacts/regularity/tiling_pattern.gd")
const Legacy = preload("res://doc/book/iterations/2026-09-28-tiling-rule-study/before/commons/artifacts/regularity/tiling_principles.gd")
var study: Node3D
var lab: Node3D
var completed := false

func press(button: Node3D) -> void:
	var area := button.get_node("InteractableAreaButton")
	XRToolsPointerEvent.pressed(camera, area, area.global_position)
	XRToolsPointerEvent.released(camera, area, area.global_position)
	await create_timer(0.12).timeout

func snapshot(title: String, eye: Vector3, target: Vector3, fov: float = 55.0) -> void:
	for node in root.find_children("*", "Node", true, false):
		if node.get_script() != null and str(node.get_script().resource_path).ends_with("/MushroomHand.gd"):
			node.show_desktop_count = false
			var hud: CanvasLayer = node.get("_hud")
			if hud != null: hud.visible = false
	await super.snapshot(title, eye, target, fov)

func desk_photo(title: String) -> void:
	await snapshot(title, lab.desk.to_global(Vector3(0, 1.65, 2.7)), lab.desk.to_global(Vector3(0, 2.0, 0)), 100)

func landing_checks() -> void:
	study = find_scene("/tiling_principles.gd")
	check("production tiling artifact loaded", study != null)
	if study == null: return
	lab = study.rule_study
	check("rule study is part of the placed artifact", lab != null)
	if lab == null: return
	var legacy := Legacy.new()
	var compatible := true
	for phase in 4:
		for exception in [false, true]:
			legacy.phase = phase; legacy.exception = exception
			for rule in 6:
				compatible = compatible and Pattern.image_for(rule, phase, exception).get_data() == legacy.texture_for(rule).get_image().get_data()
	legacy.free()
	check("all 48 original field states remain pixel-identical", compatible)
	if lab.applied: await press(lab.apply_button)
	check("undo produces identical before and after samples", lab.before.material_override.albedo_texture.get_image().get_data() == lab.local_texture.get_image().get_data())
	await desk_photo("rule-before")
	await press(lab.apply_button)
	check("actual APPLY button changes the instruction", lab.applied and lab.selected == 2)
	check("after differs from the unchanged reference", lab.before.material_override.albedo_texture.get_image().get_data() != lab.local_texture.get_image().get_data())
	check("address evaluation names one quarter-turn at 1,0", lab.cell_label.text.contains("= 1 quarter-turns"))
	await desk_photo("rule-after")
	await press(lab.cell_button)
	check("NEXT TILE advances to address 2,0 and evaluates two turns", lab.cell == Vector2i(2,0) and lab.cell_label.text.contains("= 2 quarter-turns"))
	for repeat in 15: await press(lab.cell_button)
	check("all 16 sample addresses are reachable and wrap", lab.cell == Vector2i(1,0))
	var consistent := true
	var start: int = lab.selected
	for family in 6:
		var small: Image = lab.result_image(4)
		var large: Image = lab.result_image(16)
		consistent = consistent and large.get_region(Rect2i(0,0,128,128)).get_data() == small.get_data()
		await press(lab.next_button)
	check("all six selected rules keep the 4x4 exactly within the 16x16", consistent)
	check("NEXT RULE cycles back through all six", lab.selected == start)
	while lab.selected != 5: await press(lab.next_button)
	var result: Image = lab.result_image(16)
	var base := Pattern.image_for(0, study.phase, false, 16, 16)
	var count := 0; var local_only := true
	for y in 512:
		for x in 512:
			if result.get_pixel(x,y) != base.get_pixel(x,y):
				count += 1
				local_only = local_only and x >= 96 and x < 128 and y >= 96 and y < 128
	check("one exception stays one cell in the larger field", count == 512 and local_only)
	observations["exception_pixels_changed"] = count
	await press(lab.apply_button)
	check("undo is reversible after cycling rules", lab.result_image(16).get_data() == base.get_data())
	var fixed: Array = []
	for field in study.surfaces: fixed.append(field.global_transform)
	study.turn_motif()
	check("old source turn also updates the study reference", lab.before.material_override.albedo_texture.get_image().get_data() == Pattern.image_for(0, 1, false, 4, 4).get_data())
	for repeat in 3: study.turn_motif()
	while lab.selected != 2: await press(lab.next_button)
	await press(lab.apply_button)
	if study.walls:
		check("eye chart has 25 pattern glyphs in five rows", lab.chart_samples.size() == 25)
		check("every glyph shares the exact same 4x4 texture", lab.chart_samples.all(func(n): return n.material_override.albedo_texture == lab.local_texture))
		check("physical glyph sizes decrease down the chart", lab.chart_samples[0].mesh.size.x > lab.chart_samples[1].mesh.size.x and lab.chart_samples[1].mesh.size.x > lab.chart_samples[4].mesh.size.x and is_equal_approx(lab.chart_samples[16].mesh.size.x, 0.21))
		await snapshot("eye-chart", lab.chart.to_global(Vector3(0, 1.65, 5.1)), lab.chart.to_global(Vector3(0,3.1,0)), 64)
		await press(lab.chart_button)
		check("wall button cycles the same rule at the desk", lab.selected == 3 and lab.applied and lab.title_label.text == "REFLECT")
		check("chart changes together at every size", lab.chart_samples.all(func(n): return n.material_override.albedo_texture == lab.local_texture))
		await snapshot("eye-chart-reflect", lab.chart.to_global(Vector3(0, 1.65, 5.1)), lab.chart.to_global(Vector3(0,3.1,0)), 64)
		var wall := find_scene("/wall_exception.gd")
		check("hinged wall still shares the sixth comparison field", wall != null and wall.study == study and wall.face.material_override.albedo_texture == study.surfaces[5].material_override.albedo_texture)
		var closed: Transform3D = wall.hinge.transform
		study.toggle_exception()
		check("original EXCEPTION changes wall pixels without opening it", wall.face.material_override.albedo_texture == study.surfaces[5].material_override.albedo_texture and wall.hinge.transform.is_equal_approx(closed))
		study.toggle_exception()
		await snapshot("wall-arrival", study.to_global(Vector3(0,1.65,-14)), study.to_global(Vector3(1.5,2.3,-9.5)), 83)
	else:
		check("new large floor field uses the computed 16x16", lab.field.material_override.albedo_texture.get_image().get_data() == lab.result_image(16).get_data())
		check("new floor pattern has no collision body", lab.field.find_children("*", "CollisionShape3D", true, false).is_empty())
		await snapshot("floor-and-rule", study.to_global(Vector3(0.5,1.65,-14)), study.to_global(Vector3(-0.2,0.8,-10.5)), 92)
		var hit := floor_at(study.to_global(Vector3(3.5,0,-11)))
		check("floor pattern retains hall support", not hit.is_empty())
	var retained := true
	for i in 6: retained = retained and study.surfaces[i].global_transform.is_equal_approx(fixed[i])
	check("existing six fields retain their transforms", retained)
	var approach: Vector3 = lab.desk.to_global(Vector3(0,0,1.6))
	check("reading desk approach has floor support", not floor_at(approach).is_empty())
	observations["desk_approach"] = xyz(approach)
	observations["button_world_heights"] = [lab.next_button.global_position.y, lab.apply_button.global_position.y, lab.cell_button.global_position.y]
	for path in ["tiling_principles.gd", "tiling_pattern.gd", "tiling_rule_study.gd"]:
		observations[path] = FileAccess.get_sha256("res://commons/artifacts/regularity/" + path)
	completed = true

func finish() -> void:
	check("encounter checks completed", completed)
	FileAccess.open(folder+"report.json", FileAccess.WRITE).store_string(JSON.stringify({"room":map_id,"checks":checks,"failures":failures,"observations":observations,"passed":failures.is_empty(),"scope":"Isolated production museum; native controls receive supplied pointer events. Staged eye-height cameras; pixel, collision and control checks. No headset, reach comfort or learner comprehension claim."},"  "))
	print("RULE STUDY ",checks.size()-failures.size(),"/",checks.size())
	quit(0 if failures.is_empty() else 1)
