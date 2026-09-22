extends "res://commons/artifacts/timing_machines/machine_stage.gd"
## Uses the original primitive builder, estimates, selection and mutation kernel.
const GP = preload("res://algorithms/proceduralgeneration/growth_systems/genetic_programming/GeneticProgramming.gd")
var model: Node3D
var held: Node3D
var held_genome
var target_index := 0
var targets := [8.0, 16.0, 32.0]
var notice := "HOLD a body. Change TARGET. Who becomes first?"
var cards: Node3D
var rule_visible := false
var rule_card: Label3D

func _ready() -> void:
	_build_compact_console(["TARGET", "STEP", "RING", "HOLD", "RESET", "RULE"], "WHAT DOES THE SCORE NOTICE?")
	model.auto_evolve=false;model.population_size=6;model.elitism_count=2
	model.genome_type=0;model.genome_complexity=3;model.fitness_function=0
	model.show_population=true;model.show_best_only=false;model.arrange_in_grid=true;model.spacing=4.0
	model.position=Vector3(4,0,-4);model.rotation.y=PI
	box(Vector3(0,0.008,-6),Vector3(12,0.016,8),material("263b43"))
	label("SIX CANDIDATES / ONE SCORE",Vector3(0,4.3,-8),0.0017)
	box(Vector3(-4.7,0.55,0),Vector3(2.4,1.1,2.0),material("334653"),true)
	label("HELD / BEFORE THE NEXT DECISION",Vector3(-4.7,0.78,1.1),0.00085)
	rule_card=label("estimate = sum of counted primitive contributions\nscore = 100 / (1 + abs(estimate - target))\nBoxes, spheres, cylinders count. Torus is omitted.\nThis estimate is not measured union volume.",Vector3(0,2.8,0.5),0.00115)
	rule_card.visible=false
	reset_population()
	_build_ramp.call_deferred()
	for at in [Vector3(-6,5,-4),Vector3(6,5,-4),Vector3(0,5,-10)]:
		var light:=OmniLight3D.new();light.position=at;light.omni_range=15;light.light_energy=3;add_child(light)

func reset_population() -> void:
	model.clear_population();model.population.clear()
	model.current_generation=0;model.fitness_history.clear();target_index=0;model.target_volume=targets[0]
	# Fixed, inspectable data; resetting this lesson does not reseed global RNG.
	for i in 6:
		var g=GP.Genome.new();g.id=i
		var size: float=[0.7,1.0,1.25,1.5,1.75,2.0][i]
		g.genes.append(GP.Gene.new("box",{"position":Vector3(0,size*0.5,0),"rotation":Vector3.ZERO,"scale":Vector3.ONE*size}))
		model.population.append(g)
	model.evaluate_population();model.visualize_population();refresh()

func act(id: String) -> void:
	match id:
		"TARGET":
			target_index=(target_index+1)%targets.size();model.target_volume=targets[target_index]
			model.evaluate_population();model.visualize_population()
			notice="Same genes, different target. Ranking can change."
		"STEP":
			if model.current_generation>=model.max_generations:
				notice="Generation limit reached. HOLD a witness; RESET starts another run."
			else:
				model.evolve_generation();notice="Two elites copied; four offspring selected, crossed and possibly mutated."
		"RING":
			var g=model.best_genome;var ring_index: int=-1
			for i in g.genes.size():
				if g.genes[i].gene_type=="torus":ring_index=i;break
			if ring_index>=0:g.genes.remove_at(ring_index)
			else:g.genes.append(GP.Gene.new("torus",{"position":Vector3(0,1.8,0),"rotation":Vector3.ZERO,"scale":Vector3.ONE*1.4}))
			model.evaluate_population();model.visualize_population()
			notice="The body changes; this volume estimator does not count the ring."
		"HOLD":
			if is_instance_valid(held):remove_child(held);held.queue_free()
			held_genome=model.best_genome.duplicate_genome()
			held=model.build_phenotype(held_genome);held.position=Vector3(-4.7,1.1,0);add_child(held)
			notice="One independent copy remains while the population changes."
		"RESET":reset_population();notice="Six opening boxes restored; the held witness remains."
		"RULE":rule_visible=not rule_visible;rule_card.visible=rule_visible
	refresh()

func signature(g) -> Array:
	var result: Array=[]
	for gene in g.genes:result.append([gene.gene_type,gene.parameters.duplicate(true)])
	return result

func refresh() -> void:
	if is_instance_valid(cards):cards.get_parent().remove_child(cards);cards.queue_free()
	cards=Node3D.new();model.add_child(cards)
	for child in model.get_children():
		if child is Label3D:child.hide()
	# Population positions show rank; labels identify it explicitly. Scores remain estimates.
	for i in model.population.size():
		var g=model.population[i];var at: Vector3=g.phenotype.position
		var l:=Label3D.new();l.text="RANK %d / estimate %.3f\nscore %.2f / %d parts" % [i+1,model.estimate_volume(g),g.fitness,g.genes.size()]
		l.position=at+Vector3(0,0.35,-1.35);l.rotation.y=PI;l.pixel_size=0.0011;l.font_size=30;cards.add_child(l)
		box(at+Vector3(0,0.35,-1.30),Vector3(2.8,0.42,0.05),material("20303c"),false,cards)
		for mesh in g.phenotype.get_children():
			if mesh is MeshInstance3D:
				var m: StandardMaterial3D=mesh.material_override.duplicate()
				m.albedo_color=Color("dcaccb") if i==0 else Color("82c4c8")
				mesh.material_override=m
	readout.text="TARGET %.0f | generation %d | population %d\nbest estimate %.3f / score %.2f\n%s" % [model.target_volume,model.current_generation,model.population.size(),model.estimate_volume(model.best_genome),model.best_genome.fitness,notice]

func _build_ramp() -> void:
	var hall: Node=get_parent()
	while hall!=null and not hall.has_meta("em_map"):hall=hall.get_parent()
	if hall==null or str(hall.get_meta("em_map"))!="PG_Genetic_Evolution":return
	# A closed convex wedge climbs from x=1 to the retained deck at x=4.
	# Segment-local Z includes the museum vestibule (read from its owner).
	var museum: Node=hall.get_parent()
	while museum!=null and not "VESTIBULE_H" in museum:museum=museum.get_parent()
	if museum==null:return
	var v: float=float(museum.get("VESTIBULE_H"))
	var points:=PackedVector3Array([Vector3(1,0,25+v),Vector3(4,0,25+v),Vector3(4,2,25+v),Vector3(1,0,27+v),Vector3(4,0,27+v),Vector3(4,2,27+v)])
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for indices in [[0,2,1],[3,4,5],[0,3,5],[0,5,2],[1,2,5],[1,5,4],[0,1,4],[0,4,3]]:
		for i in indices:st.add_vertex(points[i])
	st.generate_normals();var mesh:=MeshInstance3D.new();mesh.name="ObservationRamp";mesh.mesh=st.commit()
	var mat:=material("9badb3");mat.cull_mode=BaseMaterial3D.CULL_DISABLED;mesh.material_override=mat;hall.add_child(mesh)
	var body:=StaticBody3D.new();body.name="ObservationRampSupport";hall.add_child(body)
	var collision:=CollisionShape3D.new();var shape:=ConvexPolygonShape3D.new();shape.points=points;collision.shape=shape;body.add_child(collision)
	for at in [Vector3(7.5,4,24+v),Vector3(11.5,4,30+v)]:
		var light:=OmniLight3D.new();light.position=at;light.omni_range=12;light.light_energy=2.5;hall.add_child(light)

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
