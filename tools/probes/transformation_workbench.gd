extends "res://tools/probes/void_transfer_probe.gd"
## Targeted curation checks: the built tower, real colliders and placed motion.
## This does not test buttons/grabs or claim physical-headset acceptance.
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out=arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(out)
	Source.use_main_tower=true
	var scene:=Node3D.new();root.add_child(scene);current_scene=scene
	var building:Node3D=load("res://commons/void/architecture.gd").new()
	building.stream_content=true;scene.add_child(building)
	for floor in [15,16,18,19]:building.content.load_floor(floor)
	await frames(45)
	check("standard 42 by 18 metre storeys retained",building.spec.width==42 and building.spec.depth==18 and building.spec.storey_height==6)
	var grid:Node3D=building.content.roots[15].get_node("Construction")
	check("both original and mirrored carriers built",grid.carriers.has("SuspendedPlatform") and grid.carriers.has("Mirror-SuspendedPlatform"))
	for x in [-6.5,0.0,6.5]:
		var y:float=building.spec.levels[15]
		var query:=PhysicsRayQueryParameters3D.create(Vector3(x,y+3.3,6),Vector3(x,y+2.6,6),1)
		var hit:Dictionary=building.get_world_3d().direct_space_state.intersect_ray(query)
		check("connecting bridge has collision at "+str(x),not hit.is_empty() and absf(hit.position.y-(y+3))<.03)
	var row:Node3D=building.content.exhibits["16/angle-bands"].get_node("Artifact")
	var centres:Array=[]
	for band in row.bands:
		for cube in band.cubes:centres.append(cube.global_position)
	check("four six-angle walking strips make 24 full-size cubes",centres.size()==24 and row.bands.size()==4 and row.bands[0].node.scale.is_equal_approx(Vector3.ONE))
	check("rotation compares parallel physical routes",row.tower_walkways and not row.tower_row and row.columns==1)
	check("each strip preserves the original two-metre pitch",row.bands[0].cubes[0].global_position.distance_to(row.bands[0].cubes[1].global_position)>1.99)
	check("source body-width comparison is present",row.show_body_comparison and row.body_comparison!=null)
	for floor in [18,19]:
		for entry in building.content.data.floors[floor].artifacts:
			var node:Node3D=building.content.exhibits["%d/%s"%[floor,entry.id]].get_node("Artifact")
			var boxes:Array=[];geometry(node,boxes)
			check("F%d/%s keeps real geometry"%[floor,entry.id],not boxes.is_empty())
			if boxes.is_empty():continue
			var bounds:AABB=boxes[0]
			for box in boxes:bounds=bounds.merge(box)
			measured.append({"floor":floor,"id":entry.id,"min":[bounds.position.x,bounds.position.y-building.spec.levels[floor],bounds.position.z],"max":[bounds.end.x,bounds.end.y-building.spec.levels[floor],bounds.end.z]})
			check("F%d/%s stays inside floor perimeter"%[floor,entry.id],bounds.position.x>=-21.01 and bounds.end.x<=21.01 and bounds.position.z>=-9.01 and bounds.end.z<=9.01)
			check("F%d/%s fits below ceiling"%[floor,entry.id],bounds.end.y-building.spec.levels[floor]<=5.65)
			if entry.artifact=="pusher_block":
				check(entry.id+" travel turns with the placed source",(node._end_pos-node._start_pos).is_equal_approx(node.global_basis.orthonormalized()*node.push_axis.normalized()*node.push_distance))
			if entry.artifact=="grower_block":check(entry.id+" retains floor-anchored physical scaling",node.anchor=="floor" and node._box_shape.size.is_equal_approx(node._mesh.mesh.size))
	FileAccess.open(out.path_join("native.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"bounds":measured,"scope":"Actual tower geometry/collision/motion placement; no input-mechanics or physical-headset acceptance."},"  "))
	print("TRANSFORMATION_WORKBENCH ",failed)
	building.queue_free();await frames(2);quit(0 if failed.is_empty() else 1)
