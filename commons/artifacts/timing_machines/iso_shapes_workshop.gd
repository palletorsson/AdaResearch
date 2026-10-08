extends "res://commons/artifacts/timing_machines/pg_workshop.gd"
## A local museum desk for the existing GPU field repertoire.
var actions_taken := 0
var repertoire_index := 0
var level_index := 0
var comparisons: Array[MeshInstance3D] = []
var captions: Array[Label3D] = []
var floor_y := 0.0

func _bind() -> void:
	var hall: Node = get_parent()
	while hall != null and not hall.has_meta("em_map"): hall = hall.get_parent()
	if hall == null: return
	var em: Node = hall
	while em != null and not "_edit_records" in em: em = em.get_parent()
	if em == null: return
	for attempt in 100:
		for rec: Dictionary in em.get("_edit_records"):
			var n = rec.get("node")
			if is_instance_valid(n) and hall.is_ancestor_of(n) and rec.token == "mc_shapes_gallery": model = n
		if model != null: break
		await get_tree().create_timer(0.1).timeout
	if model == null: push_error("Shape gallery missing"); return
	floor_y = hall.global_position.y
	for camera in model.find_children("*", "Camera3D", true, false): camera.current = false
	ids = ["REPERTOIRE", "LEVEL", "HOLD", "CLEAR", "RESET", "RULE"]
	_build_compact_console(ids, "ONE EXTRACTOR / DIFFERENT DESCRIPTIONS")
	rule_card = label("Chair: min(seat, back, four legs)\nCup: min(max(-inside, outside), handle)\nLEVEL changes the whole field comparison.\nA recognizable chair is not a tested seat.\n64 cubed samples per object; narrow details can disappear.", Vector3(0, 2.15, 0.5), 0.001)
	rule_card.visible = false
	for n in generators():
		var at: Vector3 = hall.to_local(n.global_position)
		at.y = 0.125
		box(at, Vector3(4.5, 0.25, 4.5), material("34434c"), true, hall)
	for x in [-8, 8]: box(Vector3(x, 0.125, -3), Vector3(4.5, 0.25, 4.5), material("34434c"), true)
	for z in [9, 19, 31, 40]:
		for x in [8, 20]:
			var light := OmniLight3D.new()
			light.position = Vector3(x, 7, z + int(em.get("VESTIBULE_H")))
			light.omni_range = 18; light.light_energy = 4; hall.add_child(light)
	ready_for_input = true
	refresh()

func generators() -> Array:
	var result: Array = []
	if model != null:
		for n in model._owned:
			if is_instance_valid(n) and n is MeshInstance3D: result.append(n)
	return result

func actual_meshes() -> bool:
	var items := generators()
	if items.size() != 6: return false
	for n in items:
		if n.rendering_device == null or not n.mesh is ArrayMesh: return false
		if n.num_triangles == 0 and (n.counter_data_bytes == null or n.counter_data_bytes.decode_s32(0) != 0): return false
	return true

func act(id: String) -> void:
	if not ready_for_input or busy: return
	busy = true; actions_taken += 1
	match id:
		"REPERTOIRE":
			repertoire_index = (repertoire_index + 1) % 4
			model.apply_grid_config({"repertoire": model.ROSTERS.keys()[repertoire_index]})
		"LEVEL":
			level_index = (level_index + 1) % 4
			model.apply_grid_config({"likeness": model.ISO_LEVELS.keys()[level_index]})
		"HOLD":
			if actual_meshes(): _hold_pair()
		"CLEAR": _clear_pair()
		"RESET":
			repertoire_index = 0; level_index = 0
			model.apply_grid_config({"repertoire": "household", "likeness": "exact"})
		"RULE": rule_card.visible = not rule_card.visible
	await get_tree().process_frame
	busy = false; refresh()

func _clear_pair() -> void:
	for n in comparisons: n.queue_free()
	for n in captions: n.queue_free()
	comparisons.clear(); captions.clear()

func _hold_pair() -> void:
	_clear_pair()
	var items := generators()
	for i in 2:
		var original = items[[1, 4][i]]
		var copy := MeshInstance3D.new()
		copy.mesh = original.mesh.duplicate(true)
		copy.material_override = original.material_override.duplicate(true)
		copy.scale = Vector3.ONE * model.shape_scale
		copy.position = Vector3(-8 if i == 0 else 8, 2, -3)
		add_child(copy); comparisons.append(copy)
		copy.global_position.y = floor_y + 0.25 - copy.get_aabb().position.y * copy.global_basis.y.length()
		var caption := label("Held %s / level %.1f" % [model._shape_label(original.shape_type), model._iso_level()], copy.position + Vector3(0, 2.6, 0), 0.003)
		captions.append(caption)

func refresh() -> void:
	if readout == null or model == null: return
	var empty := 0
	for n in generators():
		n.global_position.y = floor_y + 0.25 - n.get_aabb().position.y * n.global_basis.y.length()
		if n.num_triangles == 0: empty += 1
	readout.text = "%s | level %.1f | 64 cubed samples each\n%s | %d held comparisons\nHOLD keeps middle-column objects; RESET keeps the held pair." % [model.repertoire, model._iso_level(), "%d surfaces / %d empty results" % [6 - empty, empty] if actual_meshes() else "GPU extraction unavailable: fallback is not evidence", comparisons.size()]
	for n in model._owned:
		if n is Label3D:
			var i: int = int(model._owned.find(n) / 2)
			var item = generators()[i]
			n.text = model._shape_label(item.shape_type) + (" / no surface" if item.num_triangles == 0 else "")
			n.global_position.y = item.global_position.y + item.get_aabb().end.y * item.global_basis.y.length() + 0.35
			n.pixel_size = 0.006
