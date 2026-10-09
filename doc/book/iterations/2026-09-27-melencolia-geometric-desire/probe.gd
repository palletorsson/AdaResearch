extends "res://tools/probes/transformation_encounters.gd"

func landing_checks() -> void:
	museum.flush_stamps();await create_timer(1.0).timeout
	var tableau := find_scene("/EngravingScene.gd")
	check("engraving tableau in actual museum",tableau!=null)
	if tableau==null:return
	observations["tableau_position"]=xyz(tableau.global_position)
	var large: Array=[]
	for n in museum.find_children("*","MeshInstance3D",true,false):
		var mesh_node:=n as MeshInstance3D
		if mesh_node.mesh==null:continue
		var box:AABB=mesh_node.global_transform*mesh_node.get_aabb()
		if box.size.length()>5 and box.get_center().distance_to(tableau.global_position)<30:
			large.append({"path":str(mesh_node.get_path()),"size":xyz(box.size),"centre":xyz(box.get_center())})
	observations["large_geometry"]=large
	var bounds:AABB
	var first:=true
	for n in tableau.find_children("*","MeshInstance3D",true,false):
		var box:AABB=(tableau.global_transform.affine_inverse()*n.global_transform)*n.get_aabb()
		if first:bounds=box;first=false
		else:bounds=bounds.merge(box)
	observations["tableau_bounds"]={"size":xyz(bounds.size),"centre":xyz(bounds.get_center())}
	check("full scale",tableau.scale.is_equal_approx(Vector3.ONE))
	for title in ["Architecture","Polyhedron","Melencolia","PuttoAndMillstone","RestingDog","Ladder","Scales","Hourglass","MagicSquare","Bell","GroundTools","DistantHorizon","Sphere"]:
		check("placed "+title,tableau.groups.has(title))
	var faces: Array=tableau.solid.face_polygons
	var vertices: Array[Vector3]=[]
	var edges: Dictionary={}
	var pentagons:=0;var triangles:=0;var planar:=true;var normals:=true
	for face: Array in faces:
		if face.size()==5:pentagons+=1
		if face.size()==3:triangles+=1
		var n: Vector3=(face[1]-face[0]).cross(face[2]-face[0]).normalized()
		var ids: Array[int]=[]
		for v:Vector3 in face:
			if absf((v-face[0]).dot(n))>0.0001:planar=false
			var id:=-1
			for i in range(vertices.size()):
				if v.distance_to(vertices[i])<0.0001:id=i;break
			if id<0:id=vertices.size();vertices.append(v)
			ids.append(id)
		for i in range(ids.size()):
			var key:="%d:%d"%[mini(ids[i],ids[(i+1)%ids.size()]),maxi(ids[i],ids[(i+1)%ids.size()])]
			edges[key]=int(edges.get(key,0))+1
		if n.dot(face[0])<=0:normals=false
	check("six pentagons and two triangular caps",pentagons==6 and triangles==2 and faces.size()==8)
	check("all solid faces planar",planar)
	check("solid oriented outwards",normals)
	check("twelve unique vertices and eighteen edges",vertices.size()==12 and edges.size()==18)
	check("closed two-manifold edges",edges.values().all(func(v):return v==2))
	for i in range(4):
		var row_sum:=0;var col_sum:=0
		for j in range(4):row_sum+=tableau.NUMBERS[i][j];col_sum+=tableau.NUMBERS[j][i]
		check("magic row and column "+str(i),row_sum==34 and col_sum==34)
	check("magic diagonals",16+10+7+1==34 and 13+11+6+4==34)
	for p in [Vector3(0,0,3.0),Vector3(-3.65,0,0),Vector3(3.7,0,0)]:
		var world:Vector3=tableau.to_global(p)
		var hit:=floor_at(world)
		check("walk-around platform "+str(p),not hit.is_empty() and absf(hit.position.y-world.y)<0.04)
	check("no service tray through the composition",hall.find_child("CableTray",true,false)==null)
	var walker:=CharacterBody3D.new();walker.collision_layer=0;walker.collision_mask=1
	var c:=CollisionShape3D.new();var capsule:=CapsuleShape3D.new();capsule.radius=.28;capsule.height=1.6;c.shape=capsule;c.position.y=.8
	walker.add_child(c);root.add_child(walker)
	var routes=[
		[Vector3(-3.65,.03,3.1),Vector3(0,0,-6.3)],
		[Vector3(3.7,.03,3.1),Vector3(0,0,-6.3)],
		[Vector3(-3.65,.03,3.1),Vector3(7.35,0,0)],
		[Vector3(-3.65,.03,-3.2),Vector3(7.35,0,0)]]
	for i in range(routes.size()):
		walker.global_position=tableau.to_global(routes[i][0]);await physics_frame
		var hit:=walker.move_and_collide(tableau.global_basis*routes[i][1])
		check("body-width walk around tableau %d"%i,hit==null)
		check("walk %d ends on supported platform"%i,not floor_at(walker.global_position).is_empty())
	# Test the real ramp colliders with gravity, not a teleport to a higher floor.
	walker.floor_snap_length=.3
	walker.floor_max_angle=deg_to_rad(50)
	for row in [[Vector3(5.5,1.03,12.3),14.65,2.0],[Vector3(9.5,2.03,23.4),26.55,0.0]]:
		walker.global_position=row[0];walker.velocity=Vector3.ZERO
		for i in range(360):
			await physics_frame
			walker.velocity.z=1.2
			walker.velocity.y-=9.8/60.0
			walker.move_and_slide()
			if walker.global_position.z>=float(row[1]):break
		observations["ramp_"+str(row[0])]=xyz(walker.global_position)
		var contacts:Array=[]
		for i in range(walker.get_slide_collision_count()):
			var col:=walker.get_slide_collision(i)
			contacts.append({"collider":str(col.get_collider().get_path()),"normal":xyz(col.get_normal()),"position":xyz(col.get_position())})
		observations["contacts_"+str(row[0])]=contacts
		check("ramp reaches "+str(row[1]),walker.global_position.z>=float(row[1])-.1 and absf(walker.global_position.y-float(row[2]))<.12)
	walker.queue_free()
	await snapshot("tableau-front",tableau.to_global(Vector3(0,2.5,7.3)),tableau.to_global(Vector3(0,2.4,0)),57)
	await snapshot("tableau-walk",tableau.to_global(Vector3(-3.7,1.7,3.2)),tableau.to_global(Vector3(.25,1.65,0)),72)
	await snapshot("tools-and-body",tableau.to_global(Vector3(-.6,1.7,3.3)),tableau.to_global(Vector3(.3,1.35,.5)),72)
	await snapshot("number-and-stone",tableau.to_global(Vector3(-3.5,2.0,.4)),tableau.to_global(Vector3(.1,2.7,-1)),78)
	await snapshot("hall",Vector3(9.5,2.7,11.5),tableau.to_global(Vector3(0,2.2,0)),64)

func finish() -> void:
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"observations":observations,"passed":failures.is_empty(),"scope":"Actual museum scene, closed-solid topology, printed square, body-width routes and ramps under gravity. Headset experience and Quest performance untested."},"  "))
	print("DURER ENCOUNTER ",checks.size()-failures.size(),"/",checks.size())
	quit(0 if failures.is_empty() else 1)
