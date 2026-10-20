extends "res://tools/probes/void_triangle_probe.gd"

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out=arg.trim_prefix("--out=")
	var capture_only := "--capture-only" in OS.get_cmdline_user_args()
	if not capture_only:
		await triangle_contract()
		await desktop_descent()
	await construction_contract()
	await frames(120)
	FileAccess.open(out.path_join("capture-checks.json" if capture_only else "checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"scope":"Native Godot; geometry taken from the actual meshes, native movement and synthetic XR. Not a physical headset test."},"\t"))
	quit(0 if failed.is_empty() else 1)

func construction_contract() -> void:
	await start(false)
	game.checkpoint=5;game.place_player(game.spawn_for(5));await frames(90)
	var cubicle: Node3D=game.building.content.exhibits["5/drawing"].get_node("Artifact/PythagorasFloor")
	var area: Node3D=cubicle.get_parent()
	check("same seven-metre footprint now has three proof walls and an open front",cubicle.WIDTH==7 and cubicle.walls.size()==3 and cubicle.proofs.size()==6)
	var identities: Array=[]
	for i in range(6):
		var proof: Node3D=cubicle.proofs[i]
		var identity: Array=[]
		for piece in proof.pieces: identity.append(piece.get_instance_id())
		identities.append(identity)
		var total: float=proof.a*proof.a+proof.b*proof.b
		check("wall diagram %d tiles the exact same square"%i,valid_tiling(proof,total) and proof.split==(i%2==1))
		check("wall diagram %d remains square and upright"%i,proof.scale.is_equal_approx(Vector3.ONE*.5) and is_equal_approx(proof.rotation.x,PI/2) and proof.diagram_only and not proof.has_node("Controls"))
	check("cubicle stays below the next slab",area._mesh_bounds(cubicle,cubicle).end.y<5.64)
	var world: World3D=game.get_world_3d()
	var inside:=cubicle.to_global(Vector3(3.5,1.6,3.5))
	var front:=cubicle.to_global(Vector3(3.5,1.6,8))
	check("cubicle entrance is open at standing height",world.direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(inside,front,1)).is_empty())
	var solid:=true
	for toward in [Vector3(3.5,1.6,-1),Vector3(-1,1.6,3.5),Vector3(8,1.6,3.5)]:
		var hit:=world.direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(inside,cubicle.to_global(toward),1))
		solid=solid and not hit.is_empty() and hit.collider in cubicle.walls
	check("all three proof surfaces are actual walls",solid)
	var monitor_bounds: AABB=area.global_transform*area._mesh_bounds(area.get_node("FaceMonitor"),area)
	var monitor_clear:=true
	for wall in cubicle.walls:
		var bounds: AABB=wall.global_transform*AABB(Vector3(0,0,-.12),Vector3(7,3.9,.12))
		monitor_clear=monitor_clear and not bounds.intersects(monitor_bounds)
	check("drawing monitor clears the proof wall at the entrance",monitor_clear)
	check("floor information board leaves the proof walls clear",game.building.detail_root(5).get_node("FloorSign").position.x>7 and game.building.detail_root(5).get_node("FloorSign").position.z>7)
	if "--capture" in OS.get_cmdline_user_args():
		await photograph("proof-c.png",Vector3(0,-24.8,1.3),Vector3(0,-28.2,-4.6))
		await photograph("proof-walk.png",Vector3(0,-28.35,-.25),Vector3(0,-28.1,-5.8),95)
	cubicle.buttons.swap.get_node("InteractableAreaButton").button_pressed.emit(null)
	await frames(30)
	check("one real button rearranges all six wall proofs",cubicle.swapped and cubicle.proofs.all(func(p): return p.moving))
	cubicle.swap()
	check("a second press waits for the moving triangles",cubicle.swapped)
	await frames(130)
	var unchanged:=true
	for i in range(6):
		var proof: Node3D=cubicle.proofs[i]
		for j in range(4): unchanged=unchanged and proof.pieces[j].get_instance_id()==identities[i][j]
		check("swapped wall diagram %d preserves its areas"%i,not proof.moving and proof.split==(i%2==0) and valid_tiling(proof,proof.a*proof.a+proof.b*proof.b))
	check("wall rearrangement keeps the same twenty-four triangle objects",unchanged)
	if "--capture" in OS.get_cmdline_user_args():
		await photograph("proof-ab.png",Vector3(0,-24.8,1.3),Vector3(0,-28.2,-4.6))
	cubicle.swap();await frames(10)
	cubicle.buttons.reset.get_node("InteractableAreaButton").button_pressed.emit(null);await frames(150)
	var restored: bool=not cubicle.swapped
	for i in range(6): restored=restored and not cubicle.proofs[i].moving and cubicle.proofs[i].split==(i%2==1)
	check("reset during movement restores every paired proof",restored)
	var holder: Node3D=game.building.content.exhibits["5/arrival"].get_node("Artifact")
	var succession := true
	var previous_end := -INF
	for title in ["EastBracing","EastBracing2","EastBracing3"]:
		var brace: Node3D=holder.get_node(title)
		check(title+" has three physical I-section braces",brace.members.size()==3 and brace.members[0].get_child_count()==4 and brace.members[0] is StaticBody3D)
		var bounds: AABB=holder._mesh_bounds(brace,holder)
		bounds=holder.global_transform*bounds
		# Check the real model envelope: three separate bays, full-height,
		# inside the slab, below the next slab and clear of the column faces.
		succession=succession and bounds.position.x>18.0 and bounds.end.x<19.55 and bounds.position.z>previous_end and bounds.position.z>=-9 and bounds.end.z<=9 and bounds.size.y>5 and bounds.end.y<=-24.36
		for member in brace.members:
			var member_bounds: AABB=holder.global_transform*holder._mesh_bounds(member,holder)
			succession=succession and member_bounds.end.x<19.55
		previous_end=bounds.end.z
	check("three wall-sized triangles fit in succession along the east edge",succession)
	check("proof controls are at reachable height",cubicle.status.global_position.y > -29.2 and cubicle.status.global_position.y < -28.5)
	var original: Transform3D=cubicle.transform
	area.apply_grid_config({"parts":{"PythagorasFloor":{"position":[-3.25,0,-6.8],"rotation":[0,90,0]}}})
	check("editor moves the complete proof cubicle",is_equal_approx(cubicle.rotation_degrees.y,90) and valid_tiling(cubicle.proofs[0],25))
	cubicle.transform=original
	var copy: Node3D=load("res://commons/void/triangle_drawing.tscn").instantiate()
	game.add_child(copy)
	copy.apply_grid_config({"only_parts":["PythagorasFloor"]})
	await frames(5)
	var other: Node3D=copy.get_node("PythagorasFloor")
	check("editor copy owns independent proof walls",copy.get_child_count()==1 and other.proofs.size()==6 and other.proofs[0].pieces[0]!=cubicle.proofs[0].pieces[0])
	copy.queue_free();await frames(5)
	await sign_contract()
	if "--capture" in OS.get_cmdline_user_args():
		await photograph("bracing.png",Vector3(15,-24.6,0),Vector3(18.9,-27.5,0),110.0)
		await photograph("assembly.png",Vector3(.65,-28.35,7.5),Vector3(0,-29.05,5.3),65.0)
		await photograph("folded-strip.png",Vector3(-14,-28.35,-.8),Vector3(-16,-28.8,-4.5),75.0)
		await photograph("pink-sign.png",Vector3(-17,-28.45,-5.0),Vector3(-17,-28.6,-7.2),85.0)
	game.queue_free();await frames(15)

func sign_contract() -> void:
	var area: Node3D=game.building.content.exhibits["5/surfaces"].get_node("Artifact")
	var sign: Node3D=area.get_node("PinkTriangle")
	var names: Array=["PinkTriangle","PinkTriangleDown","PinkTriangleLeft","PinkTriangleRight"]
	var directions: Array=[0,2,3,1]
	for i in range(4):
		var variant: Node3D=area.get_node(names[i])
		check("separate sign variant "+names[i],variant.direction==directions[i] and area.part_defaults.has(names[i]))
		var bounds: AABB=variant.global_transform*area._mesh_bounds(variant,variant)
		check("sign clears the two west columns "+names[i],bounds.position.x> -19.55 and bounds.end.x< -14.45)
	var field: MeshInstance3D=sign.face.get_node("Field")
	check("pink sign has a one-metre round plate on a floor-standing post",field.mesh is CylinderMesh and is_equal_approx(field.mesh.top_radius,.5) and is_equal_approx(sign.global_position.y,-30) and sign.get_node("Post") is StaticBody3D)
	check("turn button faces the player in front of the sign",sign.turn_button.basis.y.dot(Vector3.BACK)>.999)
	var pole: Transform3D=sign.get_node("Post").global_transform
	var plate: Transform3D=field.global_transform
	var symbol: MeshInstance3D=sign.face.get_node("PinkTriangle")
	var point: Vector3=symbol.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX][0]
	# First press = right; inspect the actual tip, in the plate's XY plane.
	for i in range(4):
		sign.turn_button.get_node("InteractableAreaButton").button_pressed.emit(null)
		sign.turn_button.get_node("InteractableAreaButton").button_released.emit(null)
		await frames(2)
		var tip: Vector3=symbol.transform*point
		var direction_xy:=Vector2(tip.x,tip.y).normalized()
		var targets := [Vector2(1,0),Vector2(0,-1),Vector2(-1,0),Vector2(0,1)]
		check("pink sign button points "+["right","down","left","up"][i],direction_xy.dot(targets[i])>.999 and sign.direction==(i+1)%4)
	check("turning the symbol leaves the plate and post upright",sign.get_node("Post").global_transform.is_equal_approx(pole) and field.global_transform.is_equal_approx(plate))
	var copy: Node3D=load("res://commons/void/triangle_surfaces.tscn").instantiate()
	game.add_child(copy)
	copy.apply_grid_config({"only_parts":["PinkTriangle"]})
	await frames(5)
	var other: Node3D=copy.get_node("PinkTriangle")
	other.apply_grid_config({"direction":3})
	check("editor copy keeps the whole sign and independent direction",copy.get_child_count()==1 and other.get_node("Post")!=sign.get_node("Post") and other.direction==3 and sign.direction==0)
	copy.queue_free();await frames(5)

func mesh_polygon(proof: Node3D, mesh: MeshInstance3D) -> PackedVector2Array:
	var polygon := PackedVector2Array()
	for point in mesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
		var local: Vector3=proof.to_local(mesh.to_global(point))
		polygon.append(Vector2(local.x,local.z))
	return Geometry2D.convex_hull(polygon)

func polygon_area(polygon: PackedVector2Array) -> float:
	var area := 0.0
	for i in range(polygon.size()): area+=polygon[i].cross(polygon[(i+1)%polygon.size()])
	return absf(area)*.5

func square_valid(polygon: PackedVector2Array, side: float) -> bool:
	# Convex hull closes by repeating the first point.
	if polygon.size()!=5:return false
	for i in range(4):
		var edge:=polygon[(i+1)%4]-polygon[i]
		var next:=polygon[(i+2)%4]-polygon[(i+1)%4]
		if absf(edge.length()-side)>.002 or absf(edge.dot(next))>.002:return false
	return true

func valid_tiling(proof: Node3D, uncovered: float) -> bool:
	# Inspect rendered vertices, independently of the pose/formula functions.
	var polygons: Array[PackedVector2Array]=[]
	var remaining := 0.0
	for piece in proof.pieces:
		var polygon:=mesh_polygon(proof,piece.get_child(0))
		if absf(polygon_area(polygon)-proof.a*proof.b/2)>.002:return false
		polygons.append(polygon)
	var region: Node3D=proof.regions[1] if proof.split else proof.regions[0]
	for node in region.get_children():
		if node is MeshInstance3D:
			var polygon:=mesh_polygon(proof,node)
			remaining+=polygon_area(polygon);polygons.append(polygon)
	if absf(remaining-uncovered)>.002:return false
	var total := 0.0
	for i in range(polygons.size()):
		total+=polygon_area(polygons[i])
		for p in polygons[i]:
			if p.x<-.002 or p.y<-.002 or p.x>7.002 or p.y>7.002:return false
		for j in range(i):
			for intersection in Geometry2D.intersect_polygons(polygons[i],polygons[j]):
				if polygon_area(intersection)>.002:return false
	return absf(total-49)<.002
