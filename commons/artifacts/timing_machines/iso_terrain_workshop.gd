extends "res://commons/artifacts/timing_machines/pg_workshop.gd"
## Compare an unchanged height field with its volumetric contributions.
const INTERIORS := ["none", "undercut", "caverned", "warren"]
const TERMS := ["hillside", "overhung", "quarried", "arched", "compound"]
const SAMPLES := 25
var actions_taken := 0
var interior_index := 0
var term_index := 0
var column_index := 0
var columns: Array = []
var column_marks: Node3D
var column_note := ""
var held_caption: Label3D

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
			if is_instance_valid(n) and hall.is_ancestor_of(n) and rec.token in ["mc_flat_landscape", "mc_overhang_landscape"]: works[rec.token] = n
		if works.size() == 2: break
		await get_tree().create_timer(0.1).timeout
	if works.size() != 2: push_error("Terrain desk needs both original landscapes"); return
	model = _script_node(works.mc_flat_landscape, "TerrainGeneratorFlat.gd")
	other = _script_node(works.mc_overhang_landscape, "TerrainGeneratorOverhang.gd")
	# The generic token parser clamps small scales to 0.05. These large-domain
	# specimens need a local display scale of 0.02 to fit separate six-metre bays.
	for work in works.values(): work.scale = Vector3.ONE * 0.02
	for n in [model, other]:
		if n.waiting_for_compute: n.fetch_and_process_compute_data()
		if n.waiting_for_meshthread: n.create_mesh()
		n.set_process(false); n.continuous_update = false
	other.chunk_scale = 300.0
	model.apply_grid_config({"interior": "none"})
	other.apply_grid_config({"landform": "hillside"})
	model.material_override = material("71c8c2")
	other.material_override = material("e8b169")
	for work in works.values():
		for camera in work.find_children("*", "Camera3D", true, false): camera.current = false
		for old_label in work.find_children("*", "Label3D", true, false): old_label.hide()
	ids = ["INTERIOR", "TERMS", "HOLD", "COLUMN", "RESET", "RULE"]
	_build_compact_console(ids, "ONE HEIGHT / MORE THAN ONE BOUNDARY")
	rule_card = label("LEFT: density = (height(x,z) - y) / 30 - k * cave(x,y,z)\nk: 0 / 0.3 / 0.4 / 0.8; level stays zero.\nRIGHT: height, then overhang / cave / arch / outcrop terms.\nCOLUMN counts mesh crossings at selected x,z positions.\nSeveral crossings do not certify a walkable passage.", Vector3(0, 2.15, 0.5), 0.001)
	rule_card.visible = false
	label("ONE FIELD / vary its interior", Vector3(4.5, 2.5, -6), 0.003)
	label("COMPOSED FIELD / add terms", Vector3(-5.5, 2.5, -6), 0.003)
	held_caption = label("HOLD / earlier left surface", Vector3(4.5, 2.5, -16), 0.003)
	for z in [10, 22, 37]:
		for x in [7, 22]:
			var light := OmniLight3D.new(); light.position = Vector3(x, 7, z + int(em.get("VESTIBULE_H")))
			light.omni_range = 20; light.light_energy = 4; hall.add_child(light)
	_scan_columns(); _show_column()
	ready_for_input = true; refresh()

func actual_mesh(n) -> bool:
	return n.rendering_device != null and n.mesh is ArrayMesh and n.num_triangles > 0

func act(id: String) -> void:
	if not ready_for_input or busy: return
	busy = true; actions_taken += 1
	match id:
		"INTERIOR":
			interior_index = (interior_index + 1) % INTERIORS.size()
			model.apply_grid_config({"interior": INTERIORS[interior_index]})
			_scan_columns()
		"TERMS":
			term_index = (term_index + 1) % TERMS.size()
			other.apply_grid_config({"landform": TERMS[term_index]})
		"HOLD":
			if actual_mesh(model):
				if is_instance_valid(held): held.queue_free()
				held = MeshInstance3D.new(); held.mesh = model.mesh.duplicate(true)
				held.material_override = model.material_override.duplicate(true)
				add_child(held); held.global_transform = model.global_transform; held.global_position += works.mc_flat_landscape.global_basis * Vector3(0, 0, 500)
				held_caption.text = "HELD / " + model.interior
		"COLUMN": column_index += 1
		"RESET":
			interior_index = 0; term_index = 0
			model.apply_grid_config({"interior": "none"}); other.apply_grid_config({"landform": "hillside"})
			_scan_columns()
		"RULE": rule_card.visible = not rule_card.visible
	_show_column()
	await get_tree().physics_frame
	busy = false; refresh()

func _scan_columns() -> void:
	columns.clear(); column_index = 0
	if not actual_mesh(model): return
	# Rasterise triangle projections into a fixed 25x25 test lattice. No collider
	# or analytic field substitute: these are crossings of the extracted mesh.
	var mesh_box: AABB = model.mesh.get_aabb()
	var step_x: float = model.chunk_scale / (SAMPLES + 1)
	var start: float = -model.chunk_scale * 0.5 + step_x
	var buckets: Array = []
	for i in SAMPLES * SAMPLES: buckets.append([])
	var v: PackedVector3Array = model.mesh.get_faces()
	for i in range(0, v.size(), 3):
		var a: Vector3 = v[i]; var b: Vector3 = v[i+1]; var c: Vector3 = v[i+2]
		var det: float = (b.z-c.z)*(a.x-c.x)+(c.x-b.x)*(a.z-c.z)
		if absf(det) < 0.000001: continue
		var xmin := maxi(0, int(ceil((minf(a.x,minf(b.x,c.x))-start)/step_x)))
		var xmax := mini(SAMPLES-1, int(floor((maxf(a.x,maxf(b.x,c.x))-start)/step_x)))
		var zmin := maxi(0, int(ceil((minf(a.z,minf(b.z,c.z))-start)/step_x)))
		var zmax := mini(SAMPLES-1, int(floor((maxf(a.z,maxf(b.z,c.z))-start)/step_x)))
		for zi in range(zmin,zmax+1):
			for xi in range(xmin,xmax+1):
				var x := start+xi*step_x; var z := start+zi*step_x
				var u := ((b.z-c.z)*(x-c.x)+(c.x-b.x)*(z-c.z))/det
				var w := ((c.z-a.z)*(x-c.x)+(a.x-c.x)*(z-c.z))/det
				if u >= -0.00001 and w >= -0.00001 and u+w <= 1.00001: buckets[zi*SAMPLES+xi].append(u*a.y+w*b.y+(1-u-w)*c.y)
	for zi in SAMPLES:
		for xi in SAMPLES:
			var hits: Array = buckets[zi*SAMPLES+xi]; hits.sort()
			var unique: Array = []
			for y in hits:
				if unique.is_empty() or absf(y-unique.back()) > 0.001: unique.append(y)
			if not unique.is_empty(): columns.append({"x":start+xi*step_x,"z":start+zi*step_x,"hits":unique,"bottom":mesh_box.position.y-5,"top":mesh_box.end.y+5})
	columns.sort_custom(func(a,b): return a.hits.size() > b.hits.size())

func _show_column() -> void:
	if is_instance_valid(column_marks): column_marks.queue_free()
	column_marks = Node3D.new(); add_child(column_marks)
	if columns.is_empty(): column_note = "Column unavailable: no generated mesh."; return
	var col: Dictionary = columns[column_index % columns.size()]
	var low: Vector3 = model.to_global(Vector3(col.x,col.bottom,col.z))
	var high: Vector3 = model.to_global(Vector3(col.x,col.top,col.z))
	var bar := box(Vector3.ZERO,Vector3(0.012,high.distance_to(low),0.012),material("ffe39d",true),false,column_marks)
	bar.global_position = (low+high)*0.5
	for y in col.hits:
		var dot := box(Vector3.ZERO,Vector3(0.09,0.035,0.09),material("fff3c8",true),false,column_marks)
		dot.global_position = model.to_global(Vector3(col.x,y,col.z))
	column_note = "Column x %.1f / z %.1f: %d mesh crossings" % [col.x,col.z,col.hits.size()]

func refresh() -> void:
	if readout == null: return
	readout.text = "LEFT %s / RIGHT %s\n%s\n25 x 25 sampled columns; HOLD keeps the left surface behind it." % [INTERIORS[interior_index],TERMS[term_index],column_note]
