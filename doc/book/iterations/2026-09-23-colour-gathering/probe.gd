extends "res://tools/probes/transformation_encounters.gd"
var completed:=false
var columns:Dictionary={}
func elements(n:Node3D) -> Array[MeshInstance3D]:
	var result:Array[MeshInstance3D]=[]
	for c in n.get_children():
		if c is MeshInstance3D and str(c.name).begins_with("Element_"):result.append(c)
	return result
func landing_checks() -> void:
	root.size=Vector2i(1440,960)
	var grid:Node3D=hall.get_node_or_null("SimGrid_Color_Context_Placed")
	check("authored grid present",grid!=null)
	if grid==null:return
	for frame in 3600:
		if grid.has_meta("stage_grid_ready"):break
		await process_frame
	check("grid completed",grid.has_meta("stage_grid_ready"))
	for frame in 15:await physics_frame
	var chroma:Array[Node3D]=[]
	var dna:Dictionary={}
	for n in grid.find_children("*","Node3D",true,false):
		if n.get_meta("artifact_lookup_name","")=="chroma_stack":chroma.append(n)
		if n.get_meta("artifact_lookup_name","")=="color_dna_stack":dna[n.study]=n
	check("fifteen stack studies and eight gallery studies",chroma.size()==15 and dna.size()==8)
	chroma.sort_custom(func(a,b):return grid.to_local(a.global_position).z<grid.to_local(b.global_position).z)
	for n in chroma:
		if n.stack=="bauhaus" and n.pose=="aligned" and not columns.has(n.rule):columns[n.rule]=n
	var rules:Array[String]=["one","by_shape","by_height","by_neighbour"]
	check("all four opening rules placed",rules.all(func(rule):return columns.has(rule)))
	if not rules.all(func(rule):return columns.has(rule)):return
	var original:=elements(columns.one)
	for rule in rules:
		var n:Node3D=columns[rule]
		var meshes:=elements(n)
		var same:=meshes.size()==5
		var paints:Array=[]
		for i in meshes.size():
			same=same and meshes[i].transform.is_equal_approx(original[i].transform) and meshes[i].mesh.get_aabb().is_equal_approx(original[i].mesh.get_aabb()) and meshes[i].mesh.get_class()==original[i].mesh.get_class()
			paints.append(meshes[i].get_surface_override_material(0).albedo_color)
		check(rule+" preserves the same five forms and local transforms",same)
		var unique:Array=[]
		for c:Color in paints:
			if not unique.any(func(other):return c.is_equal_approx(other)):unique.append(c)
		check(rule+" distinct assigned colours",unique.size()=={"one":1,"by_shape":2,"by_height":5,"by_neighbour":2}[rule])
		observations[rule]={"position":xyz(grid.to_local(n.global_position)),"colours":paints.map(func(c):return c.to_html())}
		camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=5.7
		await snapshot("rule-"+rule,n.to_global(Vector3(0.8,2.5,2.8)),n.to_global(Vector3(0,2.2,0)),50)
	camera.projection=Camera3D.PROJECTION_PERSPECTIVE
	await snapshot("hall-entrance",grid.to_global(Vector3(11,2.0,2)),grid.to_global(Vector3(11,3,27)),70)
	var rainbow:Node3D=dna.kras_rainbow
	var before:Transform3D=rainbow.global_transform
	await snapshot("rainbow-near",rainbow.to_global(Vector3(2.3,1.65,3.7)),rainbow.to_global(Vector3(0,3.2,0)),78)
	await snapshot("rainbow-around",rainbow.to_global(Vector3(-3.7,1.65,-2.3)),rainbow.to_global(Vector3(0,3.2,0)),78)
	check("rainbow remains fixed between two camera positions",rainbow.global_transform.is_equal_approx(before))
	check("rainbow and combined studies retain authored heights",is_equal_approx(rainbow.part_bounds[-1].end.y,6.2) and is_equal_approx(dna.rainbow_crown.part_bounds[-1].end.y,7.2) and is_equal_approx(dna.memphis_beacon.part_bounds[-1].end.y,7.4))
	await snapshot("whole-configurations",grid.to_global(Vector3(11,3.3,45)),grid.to_global(Vector3(11,3.7,53)),87)
	for path in ["commons/artifacts/chroma_stack/chroma_stack.gd","commons/artifacts/color_dna_stack/color_dna_stack.gd","commons/artifacts/color_dna_stack/studies.json","commons/primitive_grammar/primitive_stack.gd"]:observations[path]=FileAccess.get_sha256("res://"+path)
	completed=true
func finish() -> void:
	check("focused comparison completed",completed)
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"room":map_id,"checks":checks,"failures":failures,"observations":observations,"passed":failures.is_empty(),"scope":"Isolated production museum. Native renders of placed columns, same local camera for four rules, material/geometry and fixed-pose checks. No walking, grabbing, headset or learner test. No artifact or placement change."},"  "))
	print("COLOUR GATHERING ",checks.size()-failures.size(),"/",checks.size())
	quit(0 if failures.is_empty() else 1)
