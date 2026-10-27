extends "res://tools/probes/export_void_editor.gd"
## Export an isolated run of the real museum builder, not a plan reconstruction.

func collect(node: Node, inverse: Transform3D, target: Node3D, labels: Array) -> void:
	if node is MultiMeshInstance3D and node.is_visible_in_tree() and node.multimesh != null:
		var count: int = node.multimesh.instance_count if node.multimesh.visible_instance_count < 0 else node.multimesh.visible_instance_count
		if count > 256:
			print("[comparison-batch] ",node.name," instances=",count," vertices=",node.multimesh.mesh.surface_get_array_len(0) if node.multimesh.mesh is ArrayMesh else 0)
			batch_multimesh(node, inverse, target, count)
			return
	super.collect(node, inverse, target, labels)

func discover(node: Node, nodes: Array[Node3D], records: Array[Dictionary]) -> void:
	if node is Node3D and node in nodes: return
	if node is Node3D and node.has_meta("artifact_lookup_name"):
		var token := str(node.get_meta("artifact_lookup_name"))
		# A museum simulation is a real nested GridSystem. Its child exhibits
		# must stay independently inspectable rather than disappear into a shell.
		if not token.begins_with("simulation:"):
			var cell: Vector2i = node.get_meta("grid_cell",Vector2i(-1,-1))
			nodes.append(node)
			records.append({"token":token,"kind":"artifact","from":[cell.x,cell.y]})
			return
	for child in node.get_children(): discover(child,nodes,records)

func overhead(bounds: AABB) -> bool:
	return bounds.position.y >= 2.5 and bounds.size.y <= 1.0 and maxf(bounds.size.x,bounds.size.z) > 1.0

func subset(original: MultiMesh, indexes: Array[int]) -> MultiMesh:
	var result := MultiMesh.new()
	result.transform_format = MultiMesh.TRANSFORM_3D
	result.use_colors = original.use_colors
	result.use_custom_data = original.use_custom_data
	result.mesh = original.mesh
	result.instance_count = indexes.size()
	for i in indexes.size():
		result.set_instance_transform(i,original.get_instance_transform(indexes[i]))
		if original.use_colors: result.set_instance_color(i,original.get_instance_color(indexes[i]))
		if original.use_custom_data: result.set_instance_custom_data(i,original.get_instance_custom_data(indexes[i]))
	return result

func separate_roof(hall: Node3D, roof: Node3D) -> int:
	var count := 0
	var inverse := hall.global_transform.affine_inverse()
	for child: GeometryInstance3D in hall.find_children("*", "GeometryInstance3D", true, false):
		if not child.is_visible_in_tree(): continue
		if str(child.name) in ["Ceiling", "ArrisCeiling"]:
			child.reparent(roof,true)
			count += 1
		elif child is MultiMeshInstance3D and child.multimesh != null:
			var mm: MultiMesh = child.multimesh
			var kept: Array[int] = []
			var moved: Array[int] = []
			var n: int = mm.instance_count if mm.visible_instance_count < 0 else mm.visible_instance_count
			for i in n:
				var bounds: AABB = inverse*child.global_transform*mm.get_instance_transform(i)*mm.mesh.get_aabb()
				if overhead(bounds): moved.append(i)
				else: kept.append(i)
			if not moved.is_empty():
				var copy := MultiMeshInstance3D.new()
				copy.name = str(child.name)+"Roof"
				copy.multimesh = subset(mm,moved)
				copy.material_override = child.material_override
				roof.add_child(copy)
				copy.global_transform = child.global_transform
				child.multimesh = subset(mm,kept)
				count += moved.size()
		elif child is MeshInstance3D and child.mesh != null:
			if overhead(inverse*child.global_transform*child.mesh.get_aabb()):
				child.reparent(roof,true)
				count += 1
	return count

func run() -> void:
	var spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://comparison/spec.json"))
	var world := Node3D.new()
	world.name = "MuseumComparisonExport"
	root.add_child(world)
	current_scene = world
	var museum: Node3D = load("res://comparison/museum_snapshot.gd").new()
	museum.set("EM_CONTROL", "res://comparison/control.json")
	museum.set("_hand_path", "res://comparison/necklace_hand.json")
	museum.set("_overrides_path", "res://comparison/em_overrides.json")
	museum.set("start_chapter", spec.sequence)
	museum.set("start_map", spec.map)
	museum.set("plan_file", "res://commons/data/museum/em_plan.json")
	world.add_child(museum)
	var started := Time.get_ticks_msec()
	while not bool(museum.get("_museum_core_ready")) and Time.get_ticks_msec()-started < 150000:
		await process_frame
	if not bool(museum.get("_museum_core_ready")):
		push_error("Museum builder did not finish")
		quit(1)
		return
	museum.set("_lazy_pending", 0)
	museum.set_process(false)
	museum.set_physics_process(false)
	museum.call("flush_stamps")
	for i in 30: await process_frame
	var hall: Node3D = null
	for child in museum.get_children():
		if child is Node3D and str(child.get_meta("em_map", "")) == spec.map:
			hall = child
			break
	if hall == null:
		push_error("Requested museum hall not built: " + str(spec.map))
		quit(1)
		return
	var nodes: Array[Node3D] = []
	var records: Array[Dictionary] = []
	for record: Dictionary in museum.get("_edit_records"):
		var node: Node3D = record.get("node") as Node3D
		if record.get("seg") != hall or not is_instance_valid(node) or not node.is_visible_in_tree(): continue
		if str(record.get("kind", "artifact")) in ["plinth", "showing", "gate"]: continue
		if node in nodes: continue
		nodes.append(node)
		records.append(record)
	discover(hall,nodes,records)
	for source in nodes:
		if source.has_method("prepare_editor_preview"): await source.prepare_editor_preview()
	cache_soft_body_meshes(hall)
	museum.process_mode = Node.PROCESS_MODE_DISABLED
	await process_frame
	var items: Array = []
	for i in nodes.size():
		var source := nodes[i]
		var record := records[i]
		var pose: Transform3D = hall.global_transform.affine_inverse()*source.global_transform
		var config := {}
		for key in source.get_meta_list():
			if str(key).begins_with("config_"): config[str(key).trim_prefix("config_")] = source.get_meta(key)
		var key := str(spec.map)+"-museum-%d" % i
		items.append({"id":"museum-%d" % i,"artifact":str(record.get("token",source.get_meta("artifact_lookup_name",source.name))),"kind":str(record.get("kind","artifact")),"cell":record.get("from",[]),"position":[pose.origin.x,pose.origin.y,pose.origin.z],"rotation":[rad_to_deg(pose.basis.get_euler(EULER_ORDER_YXZ).x),rad_to_deg(pose.basis.get_euler(EULER_ORDER_YXZ).y),rad_to_deg(pose.basis.get_euler(EULER_ORDER_YXZ).z)],"scale":[pose.basis.get_scale().x,pose.basis.get_scale().y,pose.basis.get_scale().z],"configuration":config,"model":snapshot(source,key)})
		# Keep the remaining structure visible until every object was snapshotted.
	for source in nodes: source.hide()
	# Preserve the authored roof, but expose it as a switch for interior study.
	var roof := Node3D.new()
	roof.name = "ComparisonRoof"
	world.add_child(roof)
	roof.global_transform = hall.global_transform
	var roof_count := separate_roof(hall,roof)
	var roof_model := snapshot(roof,str(spec.map)+"-museum-roof")
	var structure_model := snapshot(hall,str(spec.map)+"-museum-structure")
	var key := str(hall.get_meta("em_chapter",spec.sequence))+"|"+str(hall.get_meta("em_pearl",""))
	var row: Dictionary = museum.get("_layout_walk").get(key,{})
	var rows: Array = row.get("cells",[])
	var width := 0
	for line in rows: width = maxi(width,len(line))
	var x0 := float(row.get("cell_x0",0))
	var entry := Vector3(7.5,1.65,1.5)
	var walker: Node3D = museum.get("_player")
	if is_instance_valid(walker): entry = hall.to_local(walker.global_position)+Vector3(0,1.65,0)
	var result := {"version":1,"map":spec.map,"sequence":spec.sequence,"hall":key,"built_at":Time.get_datetime_string_from_system(true)+"Z","ground_y":0,"entry":[entry.x,entry.y,entry.z],"width":width,"depth":rows.size(),"bounds":[x0,0,x0+width,rows.size()],"structure":structure_model,"roof":roof_model,"roof_nodes":roof_count,"objects":items,"failures":failures,"shader_material_previews":shader_count,"scope":"Actual current museum builder in isolated output/save paths. Full native structure and visible exhibits; static geometry, not browser physics. Authored roof can be hidden for study."}
	FileAccess.open(out.path_join("manifest.json"),FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	print("MUSEUM_COMPARISON_EXPORT ",JSON.stringify({"map":spec.map,"objects":items.size(),"roof_nodes":roof_count,"structure_meshes":structure_model.get("meshes",0),"failures":failures}))
	quit(0 if failures.is_empty() else 1)
