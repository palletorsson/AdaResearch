extends "res://commons/artifacts/timing_machines/pg_workshop.gd"
## The installed fields, a held mesh, and one explicitly bounded clearance test.
const PROBE_LAYER := 1 << 20
var actions_taken := 0
var intrusion_index := 0
var period_index := 0
var probe_index := 0
var probe_result: Dictionary = {}
var held_caption: Label3D
var probe_marks: Node3D
var floor_y := 0.0
const INTRUSION_ORDER := ["formula", "eroded", "drifting", "melted"]
const PERIOD_ORDER := ["sheet", "pair", "lattice", "weave"]
const RADII := [0.2, 0.35, 0.6]

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
			if is_instance_valid(n) and hall.is_ancestor_of(n) and rec.token in ["GyroidDemo", "mc_torus_sculpture"]: works[rec.token] = n
		if works.size() == 2: break
		await get_tree().create_timer(0.1).timeout
	if works.size() != 2: push_error("Gyroid comparison needs both original fields"); return
	model = _script_node(works.GyroidDemo, "TerrainGeneratorGyroid.gd")
	other = _script_node(works.mc_torus_sculpture, "TerrainGeneratorTorus.gd")
	floor_y = hall.global_position.y
	# Finish any old torus dispatch before stopping its redundant startup loop.
	if other.waiting_for_compute: other.fetch_and_process_compute_data()
	if other.waiting_for_meshthread: other.create_mesh()
	other.set_process(false)
	other.apply_grid_config({"intrusion": "formula"})
	model.apply_grid_config({"intrusion": "formula", "period": "sheet"})
	model.material_override = material("74c5c2")
	other.material_override = material("eeb063")
	for work in works.values():
		for camera in work.find_children("*", "Camera3D", true, false): camera.current = false
	ids = ["PERIOD", "INTRUSION", "HOLD", "PROBE", "RESET", "RULE"]
	_build_compact_console(ids, "A HOLE / A REPEATING PASSAGE")
	rule_card = label("g = sin(x)cos(y) + sin(y)cos(z) + sin(z)cos(x)\nThis specimen extracts g = 1, not g = 0.\nPERIOD scales the formula's coordinates.\nINTRUSION adds erosion, modulation and warp.\nPROBE tests one straight path, not all possible routes.", Vector3(0, 2.15, 0.5), 0.001)
	rule_card.visible = false
	label("TORUS / formula reference", Vector3(8, 2, -8), 0.004)
	label("GYROID / live field", Vector3(-7, 2, -8), 0.004)
	held_caption = label("HOLD: keep a previous field here", Vector3(-7, 2, -26), 0.004)
	for z in [10, 22, 34, 47]:
		for x in [8, 23]:
			var light := OmniLight3D.new(); light.position = Vector3(x, 8, z + int(em.get("VESTIBULE_H")))
			light.omni_range = 21; light.light_energy = 5; hall.add_child(light)
	await _settle()
	ready_for_input = true; refresh()

func actual_mesh(n) -> bool:
	return n.rendering_device != null and n.mesh is ArrayMesh and n.num_triangles > 0

func _settle() -> void:
	# Position, render, and collision remain distinct operations.
	for n in [model, other]:
		var a: AABB = n.global_transform * n.get_aabb()
		n.global_position.y += floor_y + 0.03 - a.position.y
	for child in model.get_children():
		if child is StaticBody3D: child.collision_layer |= PROBE_LAYER
	await get_tree().physics_frame
	await get_tree().physics_frame
	_run_probe()

func act(id: String) -> void:
	if not ready_for_input or busy: return
	busy = true; actions_taken += 1
	match id:
		"PERIOD":
			period_index = (period_index + 1) % 4
			model.apply_grid_config({"period": PERIOD_ORDER[period_index]})
		"INTRUSION":
			intrusion_index = (intrusion_index + 1) % 4
			model.apply_grid_config({"intrusion": INTRUSION_ORDER[intrusion_index]})
		"HOLD":
			if actual_mesh(model):
				if is_instance_valid(held): held.queue_free()
				held = MeshInstance3D.new(); held.mesh = model.mesh.duplicate(true)
				held.material_override = model.material_override.duplicate(true)
				add_child(held); held.global_transform = model.global_transform
				held.global_position += works.GyroidDemo.global_basis * Vector3(0, 0, 36)
				held_caption.text = "HELD / %s / %s / level 1" % [model.period, model.intrusion]
		"PROBE": probe_index = (probe_index + 1) % RADII.size()
		"RESET":
			intrusion_index = 0; period_index = 0; probe_index = 0
			model.apply_grid_config({"intrusion": "formula", "period": "sheet"})
		"RULE": rule_card.visible = not rule_card.visible
	await _settle()
	busy = false; refresh()

func probe_endpoints() -> Array[Vector3]:
	# Fixed horizontal test at head/torso height through the domain's centreline.
	var centre: Vector3 = works.GyroidDemo.global_position
	centre.y = floor_y + 1.0
	return [centre + Vector3(0, 0, -6), centre + Vector3(0, 0, 6)]

func _run_probe() -> void:
	var colliders: Array = []
	for n in model.get_children():
		if n is StaticBody3D and not n.is_queued_for_deletion():
			for shape in n.get_children():
				if shape is CollisionShape3D and shape.shape != null and not shape.disabled: colliders.append(n)
	probe_result = {"available": false, "radius": RADII[probe_index], "height": 1.7}
	if not actual_mesh(model) or colliders.is_empty():
		_draw_probe(); return
	var ends := probe_endpoints()
	var capsule := CapsuleShape3D.new(); capsule.radius = RADII[probe_index]; capsule.height = 1.7
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = capsule; query.transform = Transform3D(Basis.IDENTITY, ends[0]); query.collision_mask = PROBE_LAYER
	var space = get_world_3d().direct_space_state
	var overlaps: Array = space.intersect_shape(query)
	query.motion = ends[1] - ends[0]
	var fractions: PackedFloat32Array = space.cast_motion(query)
	var fraction: float = 0.0 if not overlaps.is_empty() else fractions[0]
	probe_result.merge({"available": true, "fraction": fraction, "initial_overlap": not overlaps.is_empty(), "clear": fraction >= 1.0}, true)
	_draw_probe()

func _draw_probe() -> void:
	if is_instance_valid(probe_marks): probe_marks.queue_free()
	probe_marks = Node3D.new(); add_child(probe_marks)
	var ends := probe_endpoints()
	var fraction: float = probe_result.get("fraction", 0.0)
	for i in 3:
		var marker := MeshInstance3D.new(); var sphere := SphereMesh.new(); sphere.radius = 0.1; sphere.height = 0.2
		marker.mesh = sphere; marker.material_override = material("f29c6b" if i == 2 else "f5e9b9", true)
		probe_marks.add_child(marker); marker.global_position = ends[i] if i < 2 else ends[0].lerp(ends[1], fraction)
		if i == 2: marker.visible = probe_result.available
	var rail := box(Vector3.ZERO, Vector3(0.025, 0.025, 12), material("f5e9b9", true), false, probe_marks)
	rail.global_position = (ends[0] + ends[1]) * 0.5

func refresh() -> void:
	if readout == null: return
	var result := "Collider unavailable: no clearance claim"
	if probe_result.available: result = "Straight probe: %.2f / 12 m clear" % (12.0 * probe_result.fraction)
	readout.text = "%s / %s | level 1 | 64 cubed samples\nCapsule radius %.2f m / height 1.70 m\n%s. Held copy is visual only." % [model.period, model.intrusion, RADII[probe_index], result]
