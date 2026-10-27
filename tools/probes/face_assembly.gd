extends "res://tools/probes/sine_yoke.gd"
## Targeted real carry/drop and XRTools grip tests, plus exact shared edges.
var pointer: Node3D
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out=arg.trim_prefix("--out=")
	Source.use_main_tower=true
	scene=Node3D.new();root.add_child(scene);current_scene=scene
	var building:Node3D=load("res://commons/void/architecture.gd").new()
	building.stream_content=true;scene.add_child(building)
	var draft:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(out.path_join("draft-rooms.json")))
	for i in [5,7]:building.content.data.floors[i]=draft.floors[i];building.content.load_floor(i)
	var shown:Array[int]=[5,7];building.show_floor_window(shown)
	root.size=Vector2i(1440,900)
	var env:=WorldEnvironment.new();env.environment=Environment.new()
	env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("30383f")
	env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color("d9e2e8");env.environment.ambient_light_energy=.38
	env.environment.tonemap_mode=Environment.TONE_MAPPER_FILMIC;scene.add_child(env)
	var light:=DirectionalLight3D.new();light.rotation_degrees=Vector3(-40,-30,0);light.light_energy=.9;light.shadow_enabled=true;scene.add_child(light)
	camera=Camera3D.new();camera.name="Camera3D";camera.fov=48;scene.add_child(camera)
	pointer=load("res://commons/scenes/DesktopInteractionPointer.gd").new();scene.add_child(pointer)
	await tick(30)
	check("standard 42m floors and both shafts retained",building.spec.width==42 and building.spec.shafts.size()==2)
	var tri:Node3D=building.content.exhibits["5/triangle-edge-assembly"].get_node("Artifact")
	var square:Node3D=building.content.exhibits["7/square-edge-assembly"].get_node("Artifact")
	check("TriangleTable retained at the visitor's saved position",tri.global_position.distance_to(Vector3(0,-30,-4))<.001 and not building.content.exhibits["5/assembly"].has_node("Artifact/TriangleTable"))
	check("twelve true triangle panels and twelve square panels",tri.pieces.size()==12 and square.pieces.size()==12 and tri.polygon.size()==3 and square.polygon.size()==4)
	await photo("01-triangle-folds",tri.to_global(Vector3(2.8,2.4,3.2)),tri.to_global(Vector3(0,.9,0)))
	await photo("02-square-faces",square.to_global(Vector3(2.8,2.4,3.2)),square.to_global(Vector3(0,.9,0)))
	for table in [tri,square]:
		await exercise(table)
		await stock_trial(table)
	await diamond(tri)
	# Actual editor poses, and isolated panel copies, rebuild without ghost bodies.
	var copied:Node3D=load("res://commons/artifacts/face_assembly/square_assembly.tscn").instantiate()
	copied.position=Vector3(3,-42,6);scene.add_child(copied)
	copied.apply_grid_config({"only_parts":["Square00"],"parts":{"Square00":{"position":[.2,1.2,.1],"rotation":[20,30,40]}}})
	await tick(4)
	check("isolated editable square frees omitted support and other colliders",copied.pieces.size()==1 and copied.find_children("*","RigidBody3D",true,false).size()==1 and not copied.has_node("Support") and not copied.has_node("Controls"))
	var kept:Transform3D=copied.pieces[0].global_transform;await tick(5)
	check("copied square keeps its editor pose at negative floor",copied.pieces[0].global_transform.is_equal_approx(kept) and copied.pieces[0].rotation_degrees.distance_to(Vector3(20,30,40))<.001)
	copied.refill_if_empty();copied.request_stock();await tick(3)
	check("an isolated editor face never becomes a stock dispenser",copied.pieces.size()==1)
	check("all faces support and controls are separately editable",tri.part_defaults.size()==14 and square.part_defaults.size()==14)
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"observations":observations,"scope":"Native desktop carry/drop and synthetic XRTools pickup/controller poses. Exact edge transforms, box/tetra closure, editor part isolation. Not physical-headset or full human playthrough acceptance."},"\t"))
	print("FACE_ASSEMBLY_RESULT ",failed.size());quit(0 if failed.is_empty() else 1)

func stock_trial(table:Node3D) -> void:
	var label:String="Triangle stock: " if table.sides==3 else "Square stock: "
	table.reset();await prepare_faces(table)
	var built:=true;var no_early_refill:=true
	for i in range(1,12):
		var best:Dictionary={};var front:float=-INF
		# Grow a real flat patch along its leading free edge, using the same
		# carry/release path as a player. No invented links or usage flags.
		for target in i:
			for edge in table.sides:
				if not table.edge_free(table.pieces[target],edge):continue
				var pose:Transform3D=table.joined_pose(0,table.pieces[target],edge,0)
				if table.overlaps_face(table.pieces[i],pose):continue
				if pose.origin.z>front:
					front=pose.origin.z;best={"target":target,"edge":edge}
		if best.is_empty():built=false;break
		built=(await desktop_join(table,i,best.target,best.edge,0)) and built
		if i<11:no_early_refill=no_early_refill and table.pieces.size()==12
	check(label+"stock stays unchanged while loose faces remain",no_early_refill)
	check(label+"using all twelve faces automatically supplies six more",built and table.pieces.size()==18 and table.loose_count()==6)
	var forms:Array[Transform3D]=[]
	for i in 12:forms.append(table.pieces[i].global_transform)
	await tick(12)
	check(label+"deferred refill runs once, not every frame",table.pieces.size()==18)
	table.buttons.stock.pressed.emit();await tick(5)
	var preserved:=true
	for i in 12:preserved=preserved and table.pieces[i].global_transform.is_equal_approx(forms[i])
	check(label+"MORE FACES adds another six without moving the built form",table.pieces.size()==24 and preserved)
	var clear:=true
	for panel in table.pieces:
		if not panel.get_meta("assembly_stock",false):continue
		var collider:CollisionShape3D=panel.get_children().filter(func(c):return c is CollisionShape3D)[0]
		var q:=PhysicsShapeQueryParameters3D.new();q.shape=collider.shape
		q.transform=panel.global_transform;q.exclude=[panel.get_rid()];q.collision_mask=7;q.margin=.001
		clear=clear and scene.get_world_3d().direct_space_state.intersect_shape(q,1).is_empty()
	check(label+"replacement stock occupies clear spaces rather than existing faces",clear)
	# New faces retain production XRTools pickup and release.
	var origin:=XROrigin3D.new();scene.add_child(origin)
	var hand:=XRController3D.new();origin.add_child(hand)
	var pickup:Node3D=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();hand.add_child(pickup)
	var fresh:Node3D=table.pieces[12];hand.global_transform=fresh.global_transform
	fresh.pick_up(pickup);await tick(3)
	check(label+"new stock is really grabbable through XRTools",fresh.is_picked_up())
	hand.global_position+=Vector3(0,.5,1);await tick(8)
	fresh.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await tick(4)
	check(label+"new stock can be moved and released like an original face",not fresh.is_picked_up() and fresh.freeze and fresh.global_position.distance_to(table.to_global(Vector3(.05,.845,-.34)))>.3)
	origin.queue_free();await tick(2)
	# A visitor can build over the entire stock area. Never place new panels
	# through that obstruction; leave the form intact and ask for a clear space.
	var block:=StaticBody3D.new();block.collision_layer=1;block.collision_mask=0
	var collider:=CollisionShape3D.new();var shape:=BoxShape3D.new();shape.size=Vector3(2,1.4,1.6);collider.shape=shape;block.add_child(collider)
	table.add_child(block);block.position=Vector3(.55,1.25,0);await tick(3)
	var count:int=table.pieces.size();table.buttons.stock.pressed.emit();await tick(4)
	check(label+"blocked stock space preserves the form and requests clearance",table.pieces.size()==count and table.feedback.text.begins_with("Clear a space"))
	block.free();await tick(2)
	table.buttons.reset.pressed.emit();await tick(3)
	check(label+"START OVER removes extra stock and restores the twelve authored faces",table.pieces.size()==12 and table.pieces.all(func(p):return not p.get_meta("assembly_stock",false)))

func prepare_faces(table:Node3D) -> void:
	table.links.clear()
	for i in table.pieces.size():
		table.pieces[i].position=Vector3(-1.3+i*.6,2.5,2.5);table.sync(table.pieces[i])
	table.pieces[0].position=Vector3(-.6,1.05,0);table.sync(table.pieces[0])
	await tick(3)

func desktop_join(table:Node3D,index:int,target:int,edge:int,angle:float) -> bool:
	table.set_fold(angle)
	var panel:Node3D=table.pieces[index]
	pointer._grab_held(panel)
	var goal:Transform3D=table.joined_pose(0,table.pieces[target],edge,angle)
	panel.global_basis=goal.basis
	camera.global_basis=Basis.IDENTITY;camera.global_position=goal.origin+Vector3(.012,.009,1.5)
	pointer._hold_distance=1.5
	await tick(32)
	var candidate:Dictionary=table.nearest_edge(panel)
	print("FACE_DROP_DIAGNOSTIC ",table.sides,"/",index," target ",target,"/",edge," angle ",angle," goal ",goal.origin," actual ",panel.global_position," candidate ",candidate.get("target_edge",-1)," overlap ",table.overlaps_face(panel,goal)," held ",panel.held())
	pointer._drop_held();await tick(4)
	print("FACE_DROP_AFTER ",panel.global_transform," goal ",goal," links ",table.links.size())
	return panel.global_transform.is_equal_approx(goal)

func exercise(table:Node3D) -> void:
	var label:String="Triangle: " if table.sides==3 else "Square: "
	await prepare_faces(table)
	var max_error:=0.0
	for angle in [-120.0,-90.0,-70.528779366,-30.0,0.0,30.0,60.0,70.528779366,90.0,109.471220634,150.0]:
		for a in table.sides:
			for b in table.sides:
				var pose:Transform3D=table.joined_pose(a,table.pieces[0],b,angle)
				var p:Vector3=pose*table.polygon[a]
				var q:Vector3=table.pieces[0].to_global(table.polygon[(b+1)%table.sides])
				max_error=maxf(max_error,p.distance_to(q))
				p=pose*table.polygon[(a+1)%table.sides];q=table.pieces[0].to_global(table.polygon[b])
				max_error=maxf(max_error,p.distance_to(q))
	check(label+"every edge pair and signed fold shares both exact endpoints",max_error<.0001)
	observations[label+"maximum_edge_error_metres"]=max_error
	check(label+"desktop carry release snaps onto selected fold",await desktop_join(table,1,0,0,60 if table.sides==3 else 90))
	var before:int=table.links.size();pointer._grab_held(table.pieces[1]);await tick(1)
	check(label+"lifting a joined panel detaches its links",before>0 and table.links.is_empty())
	# The original roll controls must survive the carry update.
	var key:=InputEventKey.new();key.physical_keycode=KEY_E;key.pressed=true
	table.pieces[1]._input(key);var rolled:Basis=table.pieces[1].global_basis
	await tick(5)
	check(label+"desktop roll remains after carry frames",table.pieces[1].global_basis.is_equal_approx(rolled))
	camera.global_position=table.to_global(Vector3(0,3,5));await tick(20);pointer._drop_held();await tick(3)
	check(label+"distant release does not magnetize",table.links.is_empty())
	# Restore a corner, then test the real XRTools driver with supplied poses.
	await prepare_faces(table)
	var origin:=XROrigin3D.new();scene.add_child(origin)
	var controller:=XRController3D.new();origin.add_child(controller)
	var pickup:Node3D=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();controller.add_child(pickup)
	var panel:Node3D=table.pieces[1];controller.global_transform=panel.global_transform
	panel.pick_up(pickup);await tick(3)
	check(label+"real XRTools grip owns the face",panel.is_picked_up())
	var goal:Transform3D=table.joined_pose(0,table.pieces[0],0,60 if table.sides==3 else 90)
	table.set_fold(60 if table.sides==3 else 90)
	controller.global_transform=goal;await tick(12)
	panel.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await tick(6)
	check(label+"XRTools release uses the same edge snap",panel.global_transform.is_equal_approx(goal) and not panel.is_picked_up() and table.links.size()==1)
	origin.queue_free();await tick(3)
	# Build a full tetrahedron or box using the same desktop carry/drop.
	await prepare_faces(table)
	var formed:=true
	for i in range(1,table.sides+1):formed = (await desktop_join(table,i,0,i-1,109.471220634 if table.sides==3 else 90)) and formed
	if table.sides==4:formed = (await desktop_join(table,5,1,2,90)) and formed
	var expected:=6 if table.sides==3 else 12
	check(label+"closed shell has all unique edges paired",formed and table.links.size()==expected)
	observations[label+"closed_shell_links"]=table.links.size()
	await photo("03-triangle-enclosed" if table.sides==3 else "04-square-enclosed",table.to_global(Vector3(1.5,1.9,2.3)),table.to_global(Vector3(-.3,1.2,0)))
	# Duplicate occupied face is refused, not an invisible extra connection.
	check(label+"already joined edges have no free slots",not table.edge_free(table.pieces[0],0))
	var duplicate:Transform3D=table.pieces[0].global_transform
	check(label+"coincident panel is rejected by real collision query",table.overlaps_face(table.pieces[10],duplicate))
	var saved:Transform3D=table.transform
	table.position+=Vector3(.2,.3,-.1);table.rotation_degrees=Vector3(12,73,4)
	var moved_error:=0.0
	for link in table.links:
		var a:Vector3=link.a.to_global(table.polygon[link.ea])
		var b:Vector3=link.b.to_global(table.polygon[(link.eb+1)%table.sides])
		moved_error=maxf(moved_error,a.distance_to(b))
	check(label+"whole moved tilted assembly retains shared edges",moved_error<.0001)
	table.transform=saved
	table.reset();await tick(4)
	var restored:=true
	for p in table.pieces:restored=restored and p.transform.is_equal_approx(table.homes[str(p.name)])
	check(label+"start over restores the editable starting poses",restored)
	table.buttons.more.pressed.emit();var angle:float=table.fold_degrees
	table.buttons.reverse.pressed.emit()
	check(label+"physical buttons change next fold and reverse its side",angle!=0 and is_equal_approx(table.fold_degrees,-angle))
	table.buttons.solid.pressed.emit()
	check(label+"solid preset selects the exact closing fold",is_equal_approx(table.fold_degrees,70.528779366 if table.sides==3 else 90.0))
	check(label+"smaller panels have 32cm edges",is_equal_approx(table.polygon[0].distance_to(table.polygon[1]),.32))
	check(label+"all loose starting faces are within 40cm of the front edge",table.pieces.all(func(p):return not table.links.all(func(link):return link.a!=p and link.b!=p) or .8-p.position.z<.4))
	check(label+"all controls can be reached from the near edge",table.buttons.values().all(func(b):return b.position.z>=.4 and b.position.y<1.0))

func same_triangle(table:Node3D,pose:Transform3D,vertices:Array) -> bool:
	for vertex in table.polygon:
		var p:Vector3=pose*vertex
		if not vertices.any(func(v):return p.distance_to(v)<.0001):return false
	return true

func diamond(table:Node3D) -> void:
	await prepare_faces(table)
	# Eight faces of a regular octahedron, independently derived from six axis vertices.
	var r:float=table.EDGE/sqrt(2.0)
	var canonical:Array[Vector3]=[Vector3(r,0,0),Vector3(0,r,0),Vector3(0,0,r)]
	var centre:Vector3=(canonical[0]+canonical[1]+canonical[2])/3
	var x:Vector3=(canonical[1]-canonical[0]).normalized()
	var z:Vector3=(canonical[2]-centre).normalized()
	var local:Basis=Basis(x,z.cross(x),z)
	var transform:Transform3D=table.pieces[0].global_transform*Transform3D(local.inverse(),-(local.inverse()*centre))
	var targets:Array=[]
	for sx in [-1,1]:
		for sy in [-1,1]:
			for sz in [-1,1]:
				var face:Array=[transform*Vector3(sx*r,0,0),transform*Vector3(0,sy*r,0),transform*Vector3(0,0,sz*r)]
				if not same_triangle(table,table.pieces[0].global_transform,face):targets.append(face)
	var built:=1;var formed:=true
	while not targets.is_empty():
		var choice:Dictionary={}
		for target in built:
			for edge in 3:
				if not table.edge_free(table.pieces[target],edge):continue
				var pose:Transform3D=table.joined_pose(0,table.pieces[target],edge,70.528779366)
				for face in targets:
					if same_triangle(table,pose,face):choice={"target":target,"edge":edge,"face":face};break
				if not choice.is_empty():break
			if not choice.is_empty():break
		if choice.is_empty():formed=false;break
		formed=(await desktop_join(table,built,choice.target,choice.edge,70.528779366)) and formed
		targets.erase(choice.face);built+=1
	check("Diamond: eight faces close all twelve edges using production carry and release",formed and built==8 and table.links.size()==12)
	var vertices:Array[Vector3]=[]
	for i in built:
		for vertex in table.polygon:
			var v:Vector3=table.pieces[i].to_global(vertex)
			if not vertices.any(func(p):return p.distance_to(v)<.0001):vertices.append(v)
	check("Diamond: six unique vertices and Euler V-E+F=2",vertices.size()==6 and vertices.size()-table.links.size()+built==2)
	await photo("05-diamond-built",table.to_global(Vector3(1.2,1.9,2.0)),table.to_global(Vector3(-.5,1.2,0)))
