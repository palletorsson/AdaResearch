extends "res://tools/probes/ca_room_layout.gd"
## Native before/after views, then physical clearance at the new connections.
func landing_checks() -> void:
	await super.landing_checks()
	camera.projection=Camera3D.PROJECTION_PERSPECTIVE
	await snapshot("rug-connection",hall.to_global(Vector3(8.8,1.65,8.5)),hall.to_global(Vector3(4.5,.6,8.5)),72)
	await snapshot("lower-gallery",hall.to_global(Vector3(6.4,1.65,15.5)),hall.to_global(Vector3(3.5,1.2,18.5)),78)
	await snapshot("network-room",hall.to_global(Vector3(9,1.65,18.5)),hall.to_global(Vector3(10.5,1,16.5)),76)
	var shape:=CapsuleShape3D.new()
	shape.radius=.28; shape.height=1.7
	var routes: Dictionary={
		"entrance_to_row":[Vector2(6.5,3.5),Vector2(6.5,4.5),Vector2(8.5,4.5),Vector2(8.5,8.5)],
		"row_to_rug":[Vector2(8.5,8.5),Vector2(6.4,8.5)],
		"rug_to_gallery":[Vector2(6.4,8.5),Vector2(6.4,15.5)],
		"network_to_gallery":[Vector2(8.8,16.5),Vector2(5.5,16.5)],
		"showcase_approach":[Vector2(6.4,15.5),Vector2(6.4,20.5),Vector2(3.5,20.5)],
		"gallery_to_exit":[Vector2(6.4,20.5),Vector2(6.4,22.5)]}
	var results: Dictionary={}
	var final_layout:=not folder.contains("/before/")
	for label in routes:
		var points: Array=routes[label]
		var blocked: Array=[]
		var unsupported: Array=[]
		var samples:=0
		for i in range(1,points.size()):
			var a: Vector2=points[i-1];var b: Vector2=points[i]
			var count:=ceili(a.distance_to(b)/.15)
			for j in range(count+1):
				var p:=a.lerp(b,float(j)/float(count))
				var foot:=hall.to_global(Vector3(p.x,0,p.y))
				var query:=PhysicsShapeQueryParameters3D.new()
				query.shape=shape;query.collision_mask=1
				query.transform=Transform3D(Basis.IDENTITY,foot+Vector3.UP*.88)
				var hits:=hall.get_world_3d().direct_space_state.intersect_shape(query,8)
				if not hits.is_empty():
					var body: CollisionObject3D=hits[0].collider
					var owner_id:=body.shape_find_owner(hits[0].shape)
					var shape_node: Node3D=body.shape_owner_get_owner(owner_id)
					blocked.append({"local":[p.x,p.y],"collider":str(body.get_path()),"shape":str(shape_node.get_path()),"shape_world":xyz(shape_node.global_position),"shape_size":xyz(shape_node.shape.size) if shape_node.shape is BoxShape3D else []})
				var floor_hit:=floor_at(foot)
				if floor_hit.is_empty() or absf(floor_hit.position.y-foot.y)>.03: unsupported.append([p.x,p.y])
				samples+=1
		results[label]={"samples":samples,"blocked":blocked,"unsupported":unsupported}
		if final_layout:
			check(label+": 0.56m capsule clearance",blocked.is_empty())
			check(label+": continuous level floor",unsupported.is_empty())
	observations["routes"]=results
	observations["scope"]="Actual museum before/after layout: identical elevated and visitor-height cameras. Sampled 0.56m-wide, 1.7m-tall capsule clearance against layer 1 every <=0.15m, with floor ray at each sample. Not a headset walk, dynamic artifact avoidance or teleport certification."
	if final_layout:
		var stream: Node= museum.get("_portal_stream")
		check("Authored entry has supported frame",not stream.get("_entry").is_empty() and not stream.get("_entry").get("invalid",false))
		check("Authored exit has supported approach",not stream.get("_exit").is_empty() and not stream.get("_exit").get("invalid",false))
		var work:=find_scene("/ca_rule_explorer.gd")
		var study=work.get_node("NeighbourStudy")
		var generation: int=work.generation
		work.step();study.refresh()
		check("Relayout retains board/ring shared update",work.generation==generation+1 and study.room_ring.rendered==work._grid)
		check("Hand reader remains at reachable height",study.get_node("HandPoint").point.global_position.y-hall.global_position.y>1 and study.get_node("HandPoint").point.global_position.y-hall.global_position.y<1.5)
		var network:=find_scene("/LineNetworkCA.gd")
		var figure: Node3D=hall.get_node_or_null("DreamBody0")
		check("Decorative figure retained away from network",figure!=null and network!=null and figure.global_position.distance_to(network.global_position)>4)
		check("Showcase moved into open gallery",find_scene("/ca_showcase.gd").position.distance_to(Vector3(3.5,0,18.5))<.01)

func finish() -> void:
	var result: Dictionary={"room":map_id,"checks":checks,"failures":failures,"observations":observations,"passed":failures.is_empty(),"scope":observations.get("scope","Museum layout load check")}
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	print("CA ROOM CONNECTIONS ",checks.size()-failures.size(),"/",checks.size())
	quit(0 if failures.is_empty() else 1)
