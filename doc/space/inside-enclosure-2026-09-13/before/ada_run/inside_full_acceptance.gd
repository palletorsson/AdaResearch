func review_works(works: Dictionary, seg: Node3D, em: Node3D, cam: Camera3D, vest: int) -> void:
	var study: Node3D=works.noisesphere.get_node_or_null("WarpStudy")
	check(study!=null,"sphere builds the optional coordinate study")
	if study==null:return
	var foreign: Node3D=load("res://algorithms/randomness/noisesphere/noisesphere.tscn").instantiate();foreign.visible=false;get_tree().root.add_child(foreign)
	var old_mesh: MeshInstance3D=foreign.get_node("MeshInstance3D4")
	var old_material: Material=old_mesh.material_override
	check(not foreign.has_node("WarpStudy") and old_mesh.mesh is SphereMesh and old_mesh.scale.length()>40,"unconfigured legacy dome remains large and separate")
	check(study.spheres[0].material_override!=old_material and study.spheres[1].material_override!=old_material,"comparison owns its materials")
	check(study.base.seed==4 and study.base.noise_type==FastNoiseLite.TYPE_VALUE and study.base.fractal_type==FastNoiseLite.FRACTAL_NONE,"base generator contract is explicit")
	check(study.warp_x.seed==19 and study.warp_z.seed==47 and study.warp_x.fractal_type==FastNoiseLite.FRACTAL_NONE,"two coordinate offsets have explicit fixed seeds")
	var direct: Array=study.values[0].duplicate();var revision: int=study.revision;var orb_time: float=works.dark_sphere.get("_time_elapsed")
	await get_tree().create_timer(0.25).timeout
	check(study.revision==revision and study.values[0]==direct,"comparison stays still without any clock control")
	check(works.dark_sphere.get("_time_elapsed")>orb_time,"retained orb keeps its independent time")
	var original_shapes: Array=[]
	for c: CollisionShape3D in study.find_children("*","CollisionShape3D",true,false):original_shapes.append(c.shape.get_instance_id())
	measurements["cases"]=[]
	for index in range(4):
		study.strength_index=index;study.relief=false;study.refresh()
		var amount: float=study.strength();var rec: Dictionary=study.selected()
		var p:=Vector2(rec.p[0],rec.p[1]);var q:=Vector2(rec.q[0],rec.q[1])
		var expected:=p+amount*Vector2(study.warp_x.get_noise_2d(p.x,p.y),study.warp_z.get_noise_2d(p.x,p.y))
		check(q.is_equal_approx(expected) and is_equal_approx(rec.warped,study.base.get_noise_2d(q.x,q.y)),"selected address and evaluation agree at warp %.2f" % amount)
		check(study.values[0]==direct,"base plate is unchanged at warp %.2f" % amount)
		var vertices0: PackedVector3Array=study.spheres[0].mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		var vertices1: PackedVector3Array=study.spheres[1].mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		check(vertices0==vertices1,"SKIN keeps both sphere geometries identical at warp %.2f" % amount)
		var changed: int=0
		for j in range(direct.size()):
			if absf(direct[j]-study.values[1][j])>0.00001:changed+=1
		check((changed==0 and study.images[0].get_data()==study.images[1].get_data()) if index==0 else changed>direct.size()/2,"zero identity or changed output at warp %.2f" % amount)
		var c: Dictionary={"strength":amount,"selected":rec,"changed_samples":changed,"samples":direct.size(),"vertices":vertices0.size(),"probes":[]}
		for sample_i in range(5):study.sample_index=sample_i;c.probes.append(study.selected())
		study.sample_index=0;study._update_witness()
		study.images[0].save_png(OUT+"direct_%d.png" % index);study.images[1].save_png(OUT+"warped_%d.png" % index)
		measurements.cases.append(c)
		await shot(cam,study.to_global(Vector3(0,2.1,3.45)),study.to_global(Vector3(0,1.1,0.2)),"skin_%d" % index,90)
	study.strength_index=2;study.refresh()
	await shot(cam,study.to_global(Vector3(0,1.75,3.1)),study.get_node("Instrument").global_position,"instrument",96)
	await shot(cam,study.to_global(Vector3(0,1.75,3.5)),study.get_node("Instrument/Readout").global_position,"readout",80)
	var texture_before: PackedByteArray=study.images[1].get_data()
	var vertex_before: PackedVector3Array=study.spheres[1].mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	study.toggle_relief()
	check(study.images[1].get_data()==texture_before,"RELIEF preserves the field image")
	var va: Array=study.spheres[1].mesh.surface_get_arrays(0);var vv: PackedVector3Array=va[Mesh.ARRAY_VERTEX]
	var error: float=0
	for i in range(vv.size()):
		# SurfaceTool may reorder indexed vertices while rebuilding normals.
		# Recover the sample direction from each actual output vertex.
		var dir: Vector3=vv[i].normalized()
		var p:=Vector2(dir.x,dir.z)*3.0;var q: Vector2=study.address_at(p,study.strength())
		var radius: float=0.94+0.16*study.base.get_noise_2d(q.x,q.y)
		error=maxf(error,vv[i].distance_to(dir*radius))
	check(error<0.0001 and vv!=vertex_before,"RELIEF places every vertex from its warped sample")
	measurements["relief_max_error"]=error
	await shot(cam,study.to_global(Vector3(0,2.1,3.45)),study.to_global(Vector3(0,1.1,0.2)),"relief",90)
	study.zero_warp()
	check(study.spheres[0].mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]==study.spheres[1].mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX],"zero warp restores identical relief geometry")
	var after_shapes: Array=[]
	for c: CollisionShape3D in study.find_children("*","CollisionShape3D",true,false):after_shapes.append(c.shape.get_instance_id())
	check(original_shapes==after_shapes,"field and relief controls preserve staging collision")
	study.strength_index=2;study.relief=false;study.refresh()
	var before_field: Array=study.values[1].duplicate();var witness: Array=study._grid.mesh.surface_get_arrays(0)
	study.next_sample();var selected: Dictionary=study.selected();var pp:=Vector2(selected.p[0],selected.p[1]);var qq:=Vector2(selected.q[0],selected.q[1])
	check(study.values[1]==before_field,"SAMPLE moves the witness without changing the field")
	check(study._plate_markers[1].position.is_equal_approx(Vector3(-1.53,0.08,0.04)+study._plot(qq)),"pink marker locates q on the base plate")
	check(study._plate_markers[2].position.is_equal_approx(Vector3(0,0.08,0.03)+study._plot(pp)),"warped plate retains the original p address")
	check(witness[Mesh.ARRAY_VERTEX].size()==2306,"coordinate witness includes direct and displaced grids")
	var driver: Node=load("res://commons/testing/wcn_desktop_driver.gd").new();get_tree().root.add_child(driver)
	var controls: Node3D=study.get_node("Controls")
	var approach: Vector3=study.to_global(Vector3(2.62,0.10,2.25));driver.spawn(approach,em)
	for i in range(20):await get_tree().physics_frame
	approach=driver.rig.global_position;measurements["pointer"]=[]
	for entry in [[0,"WARP","strength_index"],[1,"SAMPLE","sample_index"],[2,"RELIEF","relief"],[3,"ZERO","strength_index"]]:
		var before: Variant=study.get(entry[2]);var rec: Dictionary=await driver.press(controls.find_child("Btn_%d" % entry[0],true,false),approach)
		var after: Variant=study.get(entry[2]);measurements.pointer.append({"control":entry[1],"before":before,"after":after,"hover":rec.hover})
		check(str(rec.hover).contains("InteractableAreaButton") and before!=after,"desktop pointer operates %s" % entry[1])
	check(seg.to_local(driver.rig.global_position).y>-0.1,"controls have a physical standing approach")
	driver.rig.global_position=seg.to_global(Vector3(1.5,0.12,2.1+vest));driver.rig.velocity=Vector3.ZERO
	for i in range(20):await get_tree().physics_frame
	var start: Vector3=seg.to_local(driver.rig.global_position)
	driver.aim_at(seg.to_global(Vector3(1.5,1.6,10+vest)));await driver.walk("ui_up",70)
	var end: Vector3=seg.to_local(driver.rig.global_position)
	measurements["apron_walk"]={"start":str(start),"end":str(end)}
	check(end.z>7.5+vest and end.y>-0.1,"desktop body walks the apron alongside the study")
	driver.rig.global_position=seg.to_global(Vector3(11.5,0.12,11.5+vest));driver.rig.velocity=Vector3.ZERO
	for i in range(20):await get_tree().physics_frame
	driver.aim_at(seg.to_global(Vector3(11.5,1.6,16+vest)));await driver.walk("ui_up",24)
	var turn: Vector3=seg.to_local(driver.rig.global_position)
	driver.aim_at(seg.to_global(Vector3(6,1.6,13.5+vest)));await driver.walk("ui_up",48)
	var exit_end: Vector3=seg.to_local(driver.rig.global_position)
	measurements["exit_walk"]={"turn":str(turn),"end":str(exit_end)}
	check(turn.z>13.0+vest and exit_end.x<8.5 and exit_end.y>-0.1,"desktop body follows the ground passage around the preserved exit wall")
	check(old_mesh.material_override==old_material and not foreign.has_node("WarpStudy"),"local controls leave the legacy dome untouched")
	measurements["museum_walk_severed"]=[]
	for r: Dictionary in em.get("_walk_severed"):
		if str(r.get("hall","")).contains(MAP):measurements.museum_walk_severed.append(r)
	check(measurements.museum_walk_severed.is_empty(),"museum route is connected")
	measurements["walk_diagnostic"]=[]
	for cell: Vector2i in em.get("_walk_cells"):
		if cell.y>=-4 and cell.y<=16:
			measurements.walk_diagnostic.append({"x":cell.x,"z":cell.y,"h":em.get("_walk_h").get(cell,0.0),"reachable":em.get("_reach").has(cell),"climb":em.get("_walk_climb").has(cell)})
	driver.teardown();foreign.queue_free();study.strength_index=2;study.relief=false;study.sample_index=0;study.refresh()
	await shot(cam,works.dark_sphere.global_position+seg.global_basis*Vector3(0,1.3,-1.7),works.dark_sphere.global_position+Vector3.UP*0.4,"orb")
