extends "res://commons/artifacts/timing_machines/machine_stage.gd"
## Opt-in Living encounter: raw genes, compiled grammar, held and placed bodies.
const SEED := 481
const HELD := Vector3(2, 0.78, -2.5)
const PLANTED := Vector3(0, 0.035, -8)
var sculptor: Node3D
var gene_index := 0
var held: Node3D
var planted: Node3D
var held_dna: CritterDNA
var planted_dna: CritterDNA
var notice := "HOLD a tree. Does every Depth change grow it?"
var current_label: Label3D
var held_label: Label3D
var plant_label: Label3D

func _ready() -> void:
	sculptor = get_parent()
	sculptor.preview_position = Vector3(-2, 0.78, -2.5)
	sculptor.render_seed = SEED
	_build_compact_console(["GENE", "LESS", "MORE", "HOLD", "PLANT", "RESET"], "LIVING / WHAT COUNTS AS A CHANGE?")
	var stone := material("304148")
	for x in [-2, 2]:
		box(Vector3(x, 0.375, -2.5), Vector3(2.3, 0.75, 2.3), stone, true)
	current_label = label("EDITING", Vector3(-2, 0.5, -1.33), 0.0009)
	held_label = label("HOLD / leave a witness", Vector3(2, 0.5, -1.33), 0.0009)
	box(PLANTED-Vector3(0,0.025,0), Vector3(3.5, 0.02, 3.5), material("345e58"))
	plant_label = label("PLANT / one specimen here", Vector3(0, 0.55, -6.1), 0.0011)
	label("GENES BECOME INSTRUCTIONS", Vector3(0, 3.9, -3.5), 0.0019)
	label("THE EARLIER COLLECTION
other grammars / authored terrain", Vector3(0, 3.5, -11), 0.0016)
	if sculptor._control_panel:
		sculptor._control_panel.position = Vector3(3.7, 1.02, 1)
		box(Vector3(3.7, 0.94, 1), Vector3(0.8, 0.1, 0.6), stone, true)
		box(Vector3(3.7, 0.45, 1), Vector3(0.18, 0.9, 0.3), stone, true)
		label("ALL EIGHT GENES / original sliders + RANDOM", Vector3(3.7, 1.7, 0.65), 0.00075)
	# The original thin preview disk has no collision; move it under the new preview.
	for child in sculptor.get_children():
		if child is MeshInstance3D and child.mesh is CylinderMesh: child.position = Vector3(-2, 0.76, -2.5)
	sculptor.rebuilt.connect(refresh)
	sculptor.dna_exported.connect(_plant_snapshot)
	reset_design()
	for at in [Vector3(-4, 4, -3), Vector3(4, 4, -3), Vector3(0, 4, -9)]:
		var light := OmniLight3D.new();light.position=at;light.omni_range=12;light.light_energy=3;add_child(light)
	# Support the preserved coral over its original void address.
	box(Vector3(-3, 0.40, -14), Vector3(0.9, 0.8, 0.9), stone, true)

func reset_design() -> void:
	sculptor._dna = CritterDNA.random_kingdom(0, SEED)
	var values := {"segments":4.0,"symmetry":2.0,"branch_angle":30.0,"branch_decay":0.7,
		"leaf_density":0.0,"part_curve":0.0,"part_twist":0.0,"phyllotaxis":0.5,
		"scale":2.0,"part_length":2.0,"part_width":0.3,"root_type":0.0,"inflorescence":0.0}
	for key in values: sculptor._dna.set(key, values[key])
	sculptor._sync_sliders_from_dna()
	sculptor._rebuild_queued = false
	gene_index = 0
	notice = "Reset editing tree; held and planted copies remain."
	sculptor._rebuild_tree()

func act(id: String) -> void:
	match id:
		"GENE":
			gene_index = (gene_index + 1) % sculptor.GENE_SLIDERS.size()
			notice = "One gene at a time. Compare with HOLD."
		"LESS", "MORE":
			var gene: String = sculptor.GENE_SLIDERS[gene_index][0]
			var span: Array = sculptor.GENE_RANGE[gene]
			var n := inverse_lerp(float(span[0]), float(span[1]), float(sculptor._dna.get(gene)))
			n = snappedf(n + (0.025 if id == "MORE" else -0.025), 0.025)
			sculptor.set_gene_normalized(gene, n)
			sculptor._sync_sliders_from_dna()
			notice = "Edit queued / rebuilding after 0.3 seconds."
		"HOLD":
			sculptor.flush_preview()
			held = _copy_body(held, HELD)
			held_dna = sculptor._dna.duplicate(true) as CritterDNA
			held_label.text = "HELD / depth %.2f / %d generations" % [held_dna.segments, TreeMorphology._dna_to_lsystem_params(held_dna).generations]
			notice = "Held geometry and DNA stay unchanged."
		"PLANT": sculptor._on_export_dna()
		"RESET": reset_design()
	refresh()

func _copy_body(old: Node3D, at: Vector3) -> Node3D:
	if is_instance_valid(old): remove_child(old);old.queue_free()
	var body := sculptor._tree_root.duplicate() as Node3D
	body.position = at;body.scale = Vector3.ONE;add_child(body)
	return body

func _plant_snapshot(snapshot: CritterDNA) -> void:
	planted_dna = snapshot
	planted = _copy_body(planted, PLANTED)
	plant_label.text = "PLACED / depth %.2f / %d generations\nPLANT replaces this specimen" % [snapshot.segments, TreeMorphology._dna_to_lsystem_params(snapshot).generations]
	notice = "Placed a snapshot here; later edits leave it alone."
	refresh()

func readings() -> Dictionary:
	var params := TreeMorphology._dna_to_lsystem_params(sculptor._dna)
	var system := TreeMorphology._create_lsystem_from_dna(sculptor._dna, params)
	var sentence := system.get_sentence()
	var commands := sentence.count("F") + sentence.count("S")
	return {"generations":params.generations, "forks":params.fork_count, "commands":commands,
		"sentence":sentence,"budget":TreeMorphology.LOD_MAX_BRANCHES[2]}

func refresh() -> void:
	if readout == null: return
	if not sculptor._rebuild_queued and notice.begins_with("Edit queued"):
		notice = "Compare the raw gene, generations and held body."
	var data := readings()
	var def: Array = sculptor.GENE_SLIDERS[gene_index]
	readout.text = "%s %.3f | %d generations | %d forks\n%d F/S commands / drawing budget %d\n%s" % [def[1],float(sculptor._dna.get(def[0])),data.generations,data.forks,data.commands,data.budget,notice]
	current_label.text = "EDITING / depth %.2f / %d generations" % [sculptor._dna.segments,data.generations]

func _build_compact_console(ids: Array, title: String) -> void:
	# All six controls fit within one standing position. Keep the physical
	# button size; compact the spacing instead of shrinking the touch targets.
	var casing := material("263a44")
	box(Vector3(0, 0.95, 2.0), Vector3(1.12, 0.12, 0.44), casing, true)
	for x in [-0.42, 0.42]:
		box(Vector3(x, 0.445, 2.0), Vector3(0.08, 0.89, 0.30), casing, true)
	for i in ids.size():
		var id: String = ids[i]
		var column: int = i % 3
		var row: int = i / 3
		var button = PUSH.instantiate()
		button.position = Vector3((column - 1) * 0.32, 1.045, 1.88 + row * 0.23)
		button.rotation = Vector3.ZERO
		button.scale = Vector3.ONE * 1.15
		add_child(button)
		buttons[id] = button
		button.pressed.connect(act.bind(id))
		var caption := label(id, button.position + Vector3(0, 0.01, 0.09), 0.00065)
		caption.rotation_degrees.x = -70
	box(Vector3(0, 0.90, 2.235), Vector3(1.12, 0.15, 0.025), casing)
	label(title, Vector3(0, 0.90, 2.252), 0.00063)

	# A single transparent plane avoids the doubled opacity of a glass box.
	# Text keeps an opaque outline, so the exhibit is visible behind the panel
	# while the reading remains distinct from its changing background.
	var panel := Node3D.new()
	panel.name = "TextPanel"
	add_child(panel)
	panel.position = Vector3(0, 1.27, 1.58)
	panel.rotation_degrees.x = -35
	var glass := MeshInstance3D.new()
	glass.name = "Glass"
	var pane := QuadMesh.new()
	pane.size = Vector2(1.18, 0.36)
	glass.mesh = pane
	var tint := StandardMaterial3D.new()
	tint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	tint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	tint.cull_mode = BaseMaterial3D.CULL_DISABLED
	tint.albedo_color = Color(0.12, 0.25, 0.30, 0.14)
	glass.material_override = tint
	glass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	panel.add_child(glass)
	for y in [-0.19, 0.19]:
		box(Vector3(0, y, 0), Vector3(1.22, 0.016, 0.016), casing, false, panel)
	for x in [-0.60, 0.60]:
		box(Vector3(x, 0, 0), Vector3(0.016, 0.38, 0.016), casing, false, panel)
	for x in [-0.48, 0.48]:
		box(Vector3(x, 1.09, 1.70), Vector3(0.018, 0.22, 0.018), casing)
	readout = label(title, Vector3.ZERO, 0.0011)
	readout.font_size = 28
	readout.outline_size = 7
	readout.outline_modulate = Color(0.025, 0.04, 0.055, 0.95)
	readout.reparent(panel, false)
	readout.position = Vector3(0, 0, 0.009)
