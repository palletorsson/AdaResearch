extends "res://commons/artifacts/timing_machines/pg_workshop.gd"
## A fixed field domain; each step adds one of its existing weighted terms.
const TERMS := ["hillside", "overhung", "quarried", "arched", "compound"]
const ADDED := ["base height", "+ overhang term", "+ cave term", "+ arch term", "+ outcrop term"]
var term_index := 0
var field_root: Node3D
var held_caption: Label3D
var comparison_offset := Vector3.ZERO
var held_term := ""

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
			if is_instance_valid(n) and hall.is_ancestor_of(n) and rec.token == "marchingcubes_portal_landscape": field_root = n
		if field_root != null: break
		await get_tree().create_timer(0.1).timeout
	if field_root == null: push_error("Portal comparison needs its landscape"); return
	model = _script_node(field_root, "TerrainGeneratorOverhang.gd")
	if model == null: push_error("Portal comparison could not find the field generator"); return
	if model.waiting_for_compute: model.fetch_and_process_compute_data()
	if model.waiting_for_meshthread: model.create_mesh()
	model.set_process(false)
	model.continuous_update = false
	# Fixed for this lesson, before the first comparison. No per-state fitting.
	field_root.scale = Vector3.ONE * 0.02
	model.chunk_scale = 300.0
	model.apply_grid_config({"landform": "hillside"})
	model.material_override = material("ceab86")
	model.material_override.cull_mode = BaseMaterial3D.CULL_DISABLED
	for camera in field_root.find_children("*", "Camera3D", true, false): camera.current = false
	for old_label in field_root.find_children("*", "Label3D", true, false): old_label.hide()
	comparison_offset = (hall as Node3D).global_basis * Vector3(12, 0, 0)
	ids = ["TERMS", "HOLD", "CLEAR", "RESET", "RULE"]
	_build_compact_console(ids, "WHAT DID THIS TERM MAKE POSSIBLE?")
	rule_card = label("density = height - overhang - cave - arch + outcrop\nTERMS adds one weighted contribution at a time.\nCoordinates, level and sampling stay fixed.\nA name is an intention; look for its consequence.", Vector3(0, 2.15, 0.5), 0.001)
	rule_card.visible = false
	held_caption = Label3D.new()
	held_caption.text = "HOLD / keep an earlier surface here"
	held_caption.font_size = 40
	held_caption.pixel_size = 0.003
	held_caption.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	hall.add_child(held_caption)
	held_caption.global_position = field_root.global_position + comparison_offset + Vector3(0, -0.6, -3.4)
	for offset in [Vector3.ZERO, comparison_offset]:
		# Matching corner marks give both specimens the same frame of reference.
		for x in [-3.0, 3.0]:
			for z in [-3.0, 3.0]:
				var mark := box(Vector3.ZERO, Vector3(0.12, 0.08, 0.12), material("c2e3df"), false, hall)
				mark.global_position = field_root.global_position + offset + Vector3(x, -1.24, z)
	for at in [Vector3(8, 6, 10), Vector3(20, 6, 10)]:
		var light := OmniLight3D.new()
		light.position = at + Vector3(0, 0, int(em.get("VESTIBULE_H")))
		light.omni_range = 16
		light.light_energy = 3
		hall.add_child(light)
	ready_for_input = true
	refresh()

func actual_mesh() -> bool:
	return model != null and not model.use_fallback and model.rendering_device != null and model.mesh is ArrayMesh and model.num_triangles > 0

func act(id: String) -> void:
	if not ready_for_input or busy: return
	if id == "RULE":
		rule_card.visible = not rule_card.visible
		return
	if id == "CLEAR":
		_clear_held()
		refresh()
		return
	# A fallback plane is not evidence for the field experiment.
	if not actual_mesh():
		refresh()
		return
	busy = true
	match id:
		"TERMS":
			term_index = (term_index + 1) % TERMS.size()
			model.apply_grid_config({"landform": TERMS[term_index]})
		"HOLD":
			_clear_held()
			held = MeshInstance3D.new()
			held.mesh = model.mesh.duplicate(true)
			held.material_override = model.material_override.duplicate(true)
			add_child(held)
			held.global_transform = model.global_transform
			held.global_position += comparison_offset
			held_term = TERMS[term_index]
			held_caption.text = "HELD / " + held_term + "\nEarlier surface / no collision"
		"RESET":
			term_index = 0
			model.apply_grid_config({"landform": "hillside"})
	await get_tree().physics_frame
	busy = false
	refresh()

func _clear_held() -> void:
	if is_instance_valid(held):
		held.get_parent().remove_child(held)
		held.queue_free()
	held = null
	held_term = ""
	held_caption.text = "HOLD / keep an earlier surface here"

func refresh() -> void:
	if readout == null: return
	if not actual_mesh():
		readout.text = "FIELD COMPARISON UNAVAILABLE\nThis display needs the generated field surface.\nThe fallback landscape does not respond to TERMS."
		return
	readout.text = "%s / %s\nSame coordinates, level and 64 cells per axis\nHOLD keeps a comparison; RESET keeps that copy" % [TERMS[term_index].to_upper(), ADDED[term_index]]
