extends SceneTree
const OUT := "res://doc/book/iterations/2026-09-20-foundations-opening-review/"
var checks: Array = []
var evidence: Dictionary = {}
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void: checks.append({"ok":ok,"message":message})
func angle_sum(n: Node) -> float:
	var v: Array = n._triangle_vertices()
	return rad_to_deg(n._interior_angle(v[0],v[1],v[2])+n._interior_angle(v[1],v[0],v[2])+n._interior_angle(v[2],v[0],v[1]))
func run() -> void:
	var p: Node = load("res://commons/artifacts/euclid_postulates_plaque/euclid_postulates_plaque.tscn").instantiate()
	p.apply_grid_config({"lesson_controls":"on","current_postulate":0})
	root.add_child(p)
	check(p.current_postulate == 0 and p._lesson_controls != null,"configured plaque starts at first postulate with controls")
	for i in 4: p._lesson_controls.get_node("NEXT/InteractableAreaButton").button_pressed.emit(null)
	check(p.current_postulate == 4 and p.highlight_fifth,"wired NEXT reaches fifth with gold")
	p._lesson_controls.get_node("GOLD/InteractableAreaButton").button_pressed.emit(null)
	check(p.current_postulate == 4 and not p.highlight_fifth,"wired GOLD removes emphasis without changing the sentence")
	p._lesson_controls.get_node("NEXT/InteractableAreaButton").button_pressed.emit(null)
	check(p.current_postulate == 0,"fifth returns to first")
	p.apply_grid_config({"lesson_controls":"on"})
	check(p._lesson_controls.get_child_count()==4,"repeated configuration does not duplicate buttons")
	var legacy: Node = load("res://commons/artifacts/euclid_postulates_plaque/euclid_postulates_plaque.tscn").instantiate()
	root.add_child(legacy)
	check(legacy._lesson_controls==null,"other plaque placements remain opt-in")
	var n: Node = load("res://commons/artifacts/triangle_curvature_workbench/triangle_curvature_workbench.tscn").instantiate()
	n.apply_grid_config({"model":"sphere"})
	root.add_child(n)
	check(n._k==1.0,"pre-ready model configuration survives initialization")
	n.set_process(false)
	var sums: Array = []
	for idx in 3:
		n._slider.set_normalized_value(float(idx)/2.0)
		n._slider.slider_moved.emit(float(idx)/2.0)
		n._process(1.0)
		await process_frame
		check(n._k_index==idx,"physical slider selects model %d"%idx)
		var actual: float = angle_sum(n)
		var expected: float = 180.0
		if idx==0:
			# Independent hyperbolic law of cosines for an equilateral triangle.
			var radius := 0.55
			var cosh_side := 1.0+6.0*radius*radius/pow(1.0-radius*radius,2)
			expected=rad_to_deg(3.0*acos(cosh_side/(cosh_side+1.0)))
		if idx==2:
			# Independent spherical law of cosines; vertex colatitude 30 degrees.
			var side_cos := pow(cos(PI/6),2)+pow(sin(PI/6),2)*cos(TAU/3)
			expected=rad_to_deg(3.0*acos(side_cos/(1.0+side_cos)))
		check(absf(actual-expected)<0.001,"model %d agrees with independent angle formula"%idx)
		check(not "K =" in n._plate_readout.text,"readout names model rather than unsupported curvature magnitude")
		sums.append({"model":idx,"measured":actual,"oracle":expected,"display":n._plate_readout.text})
		var verts: Array = n._triangle_vertices()
		var edge: PackedVector3Array = n._edge_samples(verts[0],verts[1],24)
		check(edge[0].distance_to(verts[0])<0.002 and edge[-1].distance_to(verts[1])<0.002,"model %d edge reaches both vertices"%idx)
		var bounded := true
		for point in edge:
			if idx==0: bounded=bounded and Vector2(point.x,point.z).length()<n.surface_radius
			if idx==2: bounded=bounded and absf(point.length()-n.surface_radius)<0.00001
		check(bounded,"model %d edge stays on selected host"%idx)
		n.edge_segments=3
		check(absf(angle_sum(n)-actual)<0.00001,"measurement independent of rendering resolution")
		n.edge_segments=24
	evidence["angle_sums"]=sums
	n.apply_grid_config({"initial_k":-0.5})
	check(n._k==-1.0,"legacy negative magnitude selects disk")
	n.apply_grid_config({"model":"plane"})
	check(n._k==0.0 and absf(angle_sum(n)-180.0)<0.001,"return to plane repeats 180 degrees")
	await process_frame
	var count: int = n._triangle_root.get_child_count()
	for i in 8: n.apply_grid_config({"model":"sphere" if i%2==0 else "plane"})
	await process_frame
	check(n._triangle_root.get_child_count()==count,"repeated model changes do not accumulate displayed geometry")
	var failures: Array=[]
	for row in checks:
		if not row.ok: failures.append(row.message)
	var file=FileAccess.open(OUT+"model-checks.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"evidence":evidence},"  "))
	file.close()
	print("FOUNDATIONS_MODELS ",checks.size()," checks; failures ",failures)
	p.free();legacy.free();n.free()
	quit(0 if failures.is_empty() else 1)
