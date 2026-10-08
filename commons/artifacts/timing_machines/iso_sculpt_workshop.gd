extends "res://commons/artifacts/timing_machines/pg_workshop.gd"
## Repeatable edits and the existing controller brush share one field history.
const GAPS := [0.9, 0.65, 0.45]
const TARGET := Vector3(0, 0, 0.22)
var actions_taken := 0
var gap_index := 0
var rendered_revision := -1
var refresh_clock := 0.0
var held_label: Label3D
var target_mark: MeshInstance3D

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
			if is_instance_valid(n) and hall.is_ancestor_of(n) and rec.token == "mc_sculpt_vr": model = n
		if model != null: break
		await get_tree().create_timer(0.1).timeout
	if model == null: push_error("Sculpt workshop missing original brush"); return
	other = model.terrain_generator
	if other.waiting_for_compute: other.fetch_and_process_compute_data()
	if other.waiting_for_meshthread: other.create_mesh()
	other.set_process(false); other.continuous_update = false
	other.iso_level = 0.0
	model.set_process_input(false) # Global mouse clicks must not add random strokes.
	model.brush_radius = 0.25; model._update_brush_size()
	# Replace only this placement's tall legacy panel with the compact desk.
	model._control_panel.hide()
	for n in model._control_panel.find_children("*", "CollisionObject3D", true, false): n.collision_layer = 0; n.collision_mask = 0
	model._status_label.hide()
	other.material_override = material("7dccbf")
	ids = ["PAIR", "ADD", "ERASE", "HOLD", "RESET", "RULE"]
	_build_compact_console(ids, "ONE LOCAL EDIT / A NEW BOUNDARY")
	rule_card = label("ADD: smooth union of sphere fields\nERASE: max(field, -brush) at level zero\nOperations are evaluated in recorded order.\nPAIR replaces edits; RESET returns the wide pair.\n64 samples per axis; only the newest 500 edits remain.", Vector3(0, 2.15, 0.5), 0.001)
	rule_card.visible = false
	held_label = label("HOLD / earlier surface", Vector3(-4, 2, -3), 0.003)
	var marker_mesh := SphereMesh.new(); marker_mesh.radius = 0.04; marker_mesh.height = 0.08
	target_mark = MeshInstance3D.new(); target_mark.mesh = marker_mesh; target_mark.material_override = material("efac69", true)
	model.add_child(target_mark); target_mark.position = TARGET
	for z in [9, 20, 30]:
		for x in [6, 15]:
			var light := OmniLight3D.new(); light.position = Vector3(x, 6, z + int(em.get("VESTIBULE_H")))
			light.omni_range = 18; light.light_energy = 5; hall.add_child(light)
	_pair(); _rebuild()
	ready_for_input = true; refresh()

func _process(delta: float) -> void:
	if not ready_for_input or busy: return
	refresh_clock += delta
	if other.edit_revision != rendered_revision and refresh_clock >= 0.15:
		_rebuild(); refresh_clock = 0.0; refresh()

func _pair() -> void:
	other.clear_blobs()
	other.add_blob(Vector3(-GAPS[gap_index] / 2, 0, 0), 0.3)
	other.add_blob(Vector3(GAPS[gap_index] / 2, 0, 0), 0.3)
	model.blobs_painted = 2; model.erase_mode = false; model._update_brush_color()

func _rebuild() -> void:
	if other.rendering_device == null: return
	if other.waiting_for_compute: other.fetch_and_process_compute_data()
	if other.waiting_for_meshthread: other.create_mesh()
	other.run_compute(); other.fetch_and_process_compute_data(); other.create_mesh()
	rendered_revision = other.edit_revision

func act(id: String) -> void:
	if not ready_for_input or busy: return
	busy = true; actions_taken += 1
	match id:
		"PAIR": gap_index = (gap_index + 1) % GAPS.size(); _pair()
		"ADD", "ERASE":
			model.erase_mode = id == "ERASE"; model._update_brush_color()
			model._paint_at_position(TARGET)
		"HOLD":
			if other.mesh is ArrayMesh:
				if is_instance_valid(held): held.queue_free()
				held = MeshInstance3D.new(); held.mesh = other.mesh.duplicate(true)
				held.material_override = other.material_override.duplicate(true)
				add_child(held); held.global_transform = other.global_transform; held.global_position += Vector3(4, 0, 0)
				held_label.text = "HELD / %d recorded edits" % other.blobs_array.size()
		"RESET": gap_index = 0; _pair()
		"RULE": rule_card.visible = not rule_card.visible
	if rendered_revision != other.edit_revision: _rebuild()
	await get_tree().physics_frame
	busy = false; refresh()

func refresh() -> void:
	if readout == null: return
	readout.text = "Centres %.2f m apart / seed radii 0.30 m\n%s brush 0.25 m / %d recorded edits\nGold point: desk target. Controller trigger edits at your hand." % [GAPS[gap_index], "ERASE" if model.erase_mode else "ADD", other.blobs_array.size()]
