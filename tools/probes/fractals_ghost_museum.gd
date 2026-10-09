extends "res://tools/probes/transformation_encounters.gd"
## Temporary mounting of the fresh submission in the existing Synthesis hall.
func landing_checks() -> void:
	museum.call("flush_stamps")
	await create_timer(0.5).timeout
	var stream = museum.get("_portal_stream")
	if stream != null:
		stream.set_process(false)
		stream.set_physics_process(false)
	var walker = museum.get("_player")
	if walker is Node3D:
		walker.hide()
		walker.set_process(false)
		walker.set_physics_process(false)
		walker.global_position = Vector3(0, -100, 0)
	var previous = museum.get("_cam")
	if previous is Node3D:
		previous.hide()
	camera.set_cull_mask_value(19, false)
	var wardrobe = museum.get("_wardrobe")
	if wardrobe != null and is_instance_valid(wardrobe.get("costume")):
		wardrobe.get("costume").hide()
	var spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OS.get_cmdline_user_args()[0]))
	var baseline_script = load(spec.original)
	var variant_script = load(spec.composition)
	check("Both fresh submitted entry scripts instantiate", baseline_script != null and variant_script != null and baseline_script.can_instantiate() and variant_script.can_instantiate())
	if baseline_script == null or variant_script == null:
		return
	var pair := Node3D.new()
	hall.add_child(pair)
	pair.position = Vector3(9.5, 0, 8.0)
	var baseline = baseline_script.new()
	var variant = variant_script.new()
	baseline.position = Vector3(-1.25, 0, 0)
	variant.position = Vector3(1.25, 0, 0)
	pair.add_child(baseline)
	pair.add_child(variant)
	for item in [[baseline, "ORIGINAL"], [variant, "GHOST STUDENT / COMPOSITION"]]:
		var caption := Label3D.new()
		caption.text = item[1]
		caption.font_size = 42
		caption.pixel_size = 0.002
		caption.outline_size = 6
		caption.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		caption.position = item[0].position + Vector3.UP * 2.7
		pair.add_child(caption)
	await create_timer(0.3).timeout
	check("Original and composition both make fifteen segments in the museum", baseline.segment_count == 15 and variant.segment_count == 15)
	check("Each temporary study stands on museum floor", not floor_at(baseline.global_position).is_empty() and not floor_at(variant.global_position).is_empty())
	check("Both studies retain their two PointBody grips", baseline.points.size() == 2 and variant.points.size() == 2)
	observations["placement"] = {"hall_local": [9.5, 0, 8.0], "offsets": [-1.25, 1.25], "temporary": true, "labels": "Evaluator captions; student source unchanged", "framing": "Moved the temporary pair inward after visual inspection found the first cameras outside the doorway. First framing preserved separately."}
	await snapshot("front", pair.to_global(Vector3(0, 1.7, -3.6)), pair.to_global(Vector3(0, 1.4, 0)), 75)
	await snapshot("oblique", pair.to_global(Vector3(3.1, 2.2, -3.0)), pair.to_global(Vector3(0, 1.35, 0)), 65)
	await snapshot("side", pair.to_global(Vector3(5.0, 1.9, 0.05)), pair.to_global(Vector3(0, 1.4, 0)), 53)
	observations["scope"] = "Two unedited learner studies temporarily mounted together in actual Fractal_Synthesis. Static geometry/view comparison; no new permanent artifact and no headset evaluation."
	pair.queue_free()
