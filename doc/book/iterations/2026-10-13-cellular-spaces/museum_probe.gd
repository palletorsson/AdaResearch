extends "res://tools/probes/transformation_encounters.gd"

func _initialize() -> void:
	var spec: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OS.get_cmdline_user_args()[0]))
	# Keep the museum output sandbox; substitute only this study's derived plan.
	var file:=FileAccess.open(str(spec.run)+"plan.json",FileAccess.WRITE)
	file.store_string(FileAccess.get_file_as_string("res://commons/artifacts/cellular_spaces/museum_plan.json"))
	file.close()
	run.call_deferred()

func landing_checks() -> void:
	museum.call("flush_stamps")
	await create_timer(0.5).timeout
	var space:=find_scene("/cellular_space.gd")
	check("cellular space exists in museum",space!=null)
	if space==null:return
	var data: Dictionary=space.data
	check("requested geometry variant loaded",data.variant==("womb" if map_id.ends_with("Womb") else "commons"))
	var faces: PackedVector3Array=space.skin.mesh.get_faces()
	var shape: ConcavePolygonShape3D=space.wall_body.get_child(0).shape
	check("collision uses the exact visible triangles",faces==shape.get_faces() and shape.backface_collision)
	check("mesh is finite and below 50000 triangles",faces.size()>0 and faces.size()/3<50000 and space.skin.get_aabb().size.is_finite())
	var capsule:=CapsuleShape3D.new()
	capsule.radius=0.23;capsule.height=1.7
	var query:=PhysicsShapeQueryParameters3D.new()
	query.shape=capsule;query.collision_mask=1;query.margin=0.015
	var physics:=space.get_world_3d().direct_space_state
	var blocked: Array=[]
	var legs:=0
	for route in data.routes:
		for i in range(route.size()-1):
			var a: Array=route[i];var b: Array=route[i+1]
			var start:=space.to_global(Vector3(a[0],0.90,a[2]))
			var end:=space.to_global(Vector3(b[0],0.90,b[2]))
			query.transform=Transform3D(space.global_basis,start)
			query.motion=end-start
			var sweep:=physics.cast_motion(query)
			if sweep[0]<0.999:blocked.append({"route":legs,"a":a,"b":b,"safe_fraction":sweep[0]})
			legs+=1
	check("1.7m capsule traverses every planned passage",blocked.is_empty())
	observations["blocked"]=blocked
	observations["swept_segments"]=legs
	# Test initial overlaps as well: cast_motion does not report pre-existing contact.
	var overlapped: Array=[]
	for centre in data.centres:
		query.transform=Transform3D(space.global_basis,space.to_global(Vector3(centre[0],0.90,centre[2])))
		query.motion=Vector3.ZERO
		if not physics.intersect_shape(query,4).is_empty():overlapped.append(centre)
	check("all room centres fit the standing capsule",overlapped.is_empty())
	observations["overlapped_centres"]=overlapped
	for centre in data.centres:
		var at:=space.to_global(Vector3(centre[0],0.5,centre[2]))
		var ray:=PhysicsRayQueryParameters3D.create(at,at-Vector3.UP,1)
		var hit:=physics.intersect_ray(ray)
		check("solid floor under centre "+str(centre),not hit.is_empty())
	if data.variant=="womb":
		check("enclosure has height and width for bodily space",space.skin.get_aabb().size.y>5 and space.skin.get_aabb().size.x>9)
		var roof:=physics.intersect_ray(PhysicsRayQueryParameters3D.create(space.to_global(Vector3(0,1.7,0)),space.to_global(Vector3(0,8,0)),1))
		check("ceiling is physically present above visitor",not roof.is_empty() and roof.collider==space.wall_body)
		await snapshot("womb-entry",space.to_global(Vector3(0,1.7,-8.8)),space.to_global(Vector3(0,2.2,0)),72)
		await snapshot("womb-inside",space.to_global(Vector3(-1.8,1.7,-3.5)),space.to_global(Vector3(2.7,2.4,2.6)),78)
		await snapshot("womb-ceiling",space.to_global(Vector3(0,1.6,0)),space.to_global(Vector3(-1.3,5,1.4)),76)
	else:
		check("six shared walls are omitted in central four cells",data.removed.size()==6)
		check("at least sixteen cell passages exist",data.doors.size()>=16)
		check("all sixteen floor sites remain identifiable",data.centres.size()==16)
		await snapshot("cells-entry",space.to_global(Vector3(-1.8,1.7,-8.9)),space.to_global(Vector3(-1.8,1.9,-3.5)),74)
		await snapshot("cells-middle",space.to_global(Vector3(-2.4,1.7,-2.1)),space.to_global(Vector3(3.9,2.0,2.6)),86)
		await snapshot("cells-side",space.to_global(Vector3(-5.3,1.7,-1.8)),space.to_global(Vector3(1.0,1.8,1.1)),78)
	observations["triangle_count"]=faces.size()/3
	observations["scope"]="Actual isolated museum, exact mesh/collision comparison, capsule sweeps and start-overlap tests. Desktop captures; no physical Quest comfort/performance validation."
