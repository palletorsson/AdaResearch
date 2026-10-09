extends "res://tools/probes/transformation_encounters.gd"

func landing_checks() -> void:
	museum.flush_stamps()
	await create_timer(2.0).timeout
	for n in museum.find_children("*MushroomHand*", "Node3D", true, false): n.visible = false
	match map_id:
		"FormFinding_Annealing": await well_checks()
		"FormFinding_Relaxation": await cloth_checks()
		"FormFinding_Forge": await forge_checks()
		"FormFinding_Descent": await descent_checks()

func well_checks() -> void:
	var wells := find_scene("/max_q_basin_room.gd")
	check("two wells present inside museum", wells != null)
	if wells == null: return
	wells.set_process(false)
	check("interpretation waits for visitor", wells.reveal_on_request and not wells._interpretation_visible)
	var data: Array = []
	for n in wells.find_children("*", "MeshInstance3D", true, false):
		if not n.mesh is ArrayMesh: continue
		var a: Array = n.mesh.surface_get_arrays(0)
		if a[Mesh.ARRAY_VERTEX].size() != 310: continue
		var verts: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = a[Mesh.ARRAY_NORMAL]
		var inds: PackedInt32Array = a[Mesh.ARRAY_INDEX]
		var valid := true
		var tilted := 0
		for v in normals:
			valid = valid and v.is_finite() and absf(v.length()-1.0) < 0.0001
			if v.distance_to(Vector3.UP) > 0.01: tilted += 1
		check("finite unit normals well " + str(data.size()), valid)
		data.append({"vertices_sha256":verts.to_byte_array().hex_encode().sha256_text(),"indices_sha256":inds.to_byte_array().hex_encode().sha256_text(),"normals_sha256":normals.to_byte_array().hex_encode().sha256_text(),"tilted":tilted,"bounds":str(n.mesh.get_aabb()),"sample_normal":xyz(normals[31]),"transform":str(n.global_transform)})
	check("both original meshes retained",data.size()==2)
	observations["well_meshes"] = data
	observations["artifact_world"] = xyz(wells.global_position)
	observations["standing_eye"] = xyz(wells.to_global(Vector3(-2.65,1.7,0.10)))
	var use_profile := FileAccess.get_file_as_string("res://commons/artifacts/max_q_basin_room/max_q_basin_room.gd").contains("profile_slope")
	if use_profile:
		for d in data:check("profile normals follow the hollow",d.tilted==279 and d.sample_normal[0] < 0 and d.sample_normal[1]>0)
	else:
		for d in data:check("baseline confirms flat upward normals",d.tilted==0)
	await snapshot("deep-well",wells.to_global(Vector3(-2.65,1.7,0.10)),wells.to_global(Vector3(-1.45,0.48,0)),60)
	await snapshot("two-wells",wells.to_global(Vector3(-2.8,1.7,3.4)),wells.to_global(Vector3(-0.4,0.75,0)),66)
	wells._interpretation_button.pressed.emit()
	check("real INTERPRET button reveals the proposal",wells._interpretation_visible)
	wells._interpretation_button.pressed.emit()
	check("visitor can return to comparison",not wells._interpretation_visible)

func cloth_checks() -> void:
	var cloth := find_scene("/verlet_workbench.gd")
	var vessel := find_scene("/frozen_glass_vessel.gd")
	check("cloth and vessel exist in the loaded hall",cloth != null and vessel != null)
	if cloth==null or vessel==null:return
	cloth.set_process(false);cloth.set_physics_process(false)
	check("hall enables comparison",cloth.comparison)
	check("initial wind and four passes",cloth.wind_enabled and cloth._effective_passes()==4)
	cloth.buttons["WIND"].pressed.emit()
	check("WIND toggles off and resets to 60",not cloth.wind_enabled and cloth.simulation_steps==60)
	var cycle: Array = []
	for i in 3:
		cloth.buttons["PASSES"].pressed.emit()
		cycle.append(cloth._effective_passes())
	check("three presses reach one pass through eight and twelve",cycle==[8,12,1])
	for i in 360:cloth._physics_process(cloth.COMPARISON_STEP)
	var one: Dictionary = cloth.comparison_metrics()
	check("one-pass count is 420",cloth.simulation_steps==420)
	observations["one_pass"] = one
	await snapshot("cloth-one-pass",cloth.to_global(Vector3(0.4,1.7,2.4)),cloth.to_global(Vector3(0.45,1.12,0.10)),55)
	cloth.buttons["PASSES"].pressed.emit()
	check("next press selects four and resets",cloth._effective_passes()==4 and cloth.simulation_steps==60)
	for i in 360:cloth._physics_process(cloth.COMPARISON_STEP)
	var four: Dictionary = cloth.comparison_metrics()
	check("four-pass count is 420",cloth.simulation_steps==420)
	observations["four_pass"] = four
	check("extra passes reduce mean and worst error",four.mean_absolute_percent < one.mean_absolute_percent and four.worst_absolute_percent < one.worst_absolute_percent)
	check("one-pass figures reproduce",absf(one.mean_absolute_percent-1.409)<0.005 and absf(one.worst_absolute_percent-34.276)<0.01)
	check("four-pass figures reproduce",absf(four.mean_absolute_percent-0.359)<0.005 and absf(four.worst_absolute_percent-8.936)<0.01)
	await snapshot("cloth-four-pass",cloth.to_global(Vector3(0.4,1.7,2.4)),cloth.to_global(Vector3(0.45,1.12,0.10)),55)
	var mesh: MeshInstance3D = vessel.get_node("Vessel")
	var shape: CollisionShape3D = mesh.get_node("FrozenSkin/Surface")
	check("vessel has a two-sided closed collision surface",shape.shape is ConcavePolygonShape3D and shape.shape.backface_collision and not shape.disabled)
	var a: AABB = mesh.mesh.get_aabb()
	var center: Vector3 = a.get_center()
	var from: Vector3 = mesh.to_global(center+Vector3(a.size.x+0.3,0,0))
	var to: Vector3 = mesh.to_global(center-Vector3(a.size.x+0.3,0,0))
	var query := PhysicsRayQueryParameters3D.create(from,to,1)
	var hit: Dictionary = hall.get_world_3d().direct_space_state.intersect_ray(query)
	check("surface answers collision query",not hit.is_empty() and hit.collider==mesh.get_node("FrozenSkin"))
	observations["vessel_bounds"]=str(a)
	await snapshot("glass-keeps-a-boundary",vessel.to_global(Vector3(-0.8,1.7,1.9)),mesh.to_global(center),52)

func forge_checks() -> void:
	var forge := find_scene("/self_shaping_forge.gd")
	check("existing forge present in museum",forge != null)
	if forge==null:return
	forge.set_process(false)
	check("180 particles have authored destinations",forge._targets.size()==180 and forge._mm.instance_count==180)
	forge._t=0.75/forge.cycle_rate;forge._process(0)
	check("clock reaches raw phase",is_zero_approx(forge._q))
	await snapshot("forge-cloud",forge.to_global(Vector3(0,1.7,0.85)),forge.to_global(Vector3(0,0.63,0)),62)
	forge._t=0.25/forge.cycle_rate;forge._process(0)
	check("clock alone reaches MAX Q",is_equal_approx(forge._q,1) and forge._readout.text.contains("MAX Q"))
	var match_targets := true
	for i in 180:match_targets=match_targets and forge._mm.get_instance_transform(i).origin.is_equal_approx(forge._targets[i])
	check("formed body equals authored targets",match_targets)
	observations["period_seconds"]=1.0/forge.cycle_rate
	observations["forge_transform"]=str(forge.global_transform)
	observations["forge_children"]=[]
	for c in forge.get_children():
		if c is Node3D:observations["forge_children"].append({"name":str(c.name),"position":xyz(c.position),"visible":c.visible})
	await snapshot("forge-body",forge.to_global(Vector3(0,1.7,0.85)),forge.to_global(Vector3(0,0.63,0)),62)

	await snapshot("forge-side",forge.to_global(Vector3(1.15,1.7,0.25)),forge.to_global(Vector3(0,0.65,0)),62)
	await snapshot("forge-reverse",forge.to_global(Vector3(0,1.7,-1.2)),forge.to_global(Vector3(0,0.65,0)),62)

func descent_checks() -> void:
	var lab := find_scene("/descent_landscape_lab.gd")
	var well := find_scene("/gradient_descent_well.gd")
	for source in ["/descent_marble_toy.gd","/GradientDescentDemo.gd","/gradient_descent_well.gd","/settling_tremble.gd","/science_screen.gd"]:
		check("retained comparison present: "+source,find_scene(source)!=null)
	check("controlled landscape present",lab!=null)
	if lab==null or well==null:return
	lab.set_process(false)
	check("bowl cost is quarter of the sum",is_equal_approx(lab.cost(Vector2(2,3)),3.25))
	lab.buttons["SURFACE"].pressed.emit()
	var runs: Array = []
	for run in 2:
		if run==1:lab.buttons["START"].pressed.emit()
		for i in 161:
			if lab.status in ["SMALL SLOPE","LEFT FRAME","STEP LIMIT"]:break
			lab.buttons["STEP"].pressed.emit()
		runs.append({"cost":lab.cost(lab.point),"status":lab.status,"steps":lab.steps,"start":lab.start_index})
	check("two starts end at small slope",runs[0].status=="SMALL SLOPE" and runs[1].status=="SMALL SLOPE")
	check("recorded costs reproduce",absf(runs[0].cost+0.304)<0.001 and absf(runs[1].cost-0.295)<0.001)
	observations["descent_runs"]=runs
	well.set_process(false)
	well._label_timer=0;well._tick_labels(1)
	var expected: float=maxf(0.0,well._loss(well._m_pos[0])-well._global_min_loss)
	check("well LOSS display reports the current first marble",well._loss_label.text=="LOSS %.3f" % expected)
	observations["well_readout"]=well._loss_label.text
	await snapshot("descent-comparison",lab.to_global(Vector3(-2.4,1.7,-5.5)),lab.to_global(Vector3(0,0.7,0)),62)
