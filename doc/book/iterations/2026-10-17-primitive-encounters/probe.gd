extends "res://tools/probes/transformation_encounters.gd"
var pointer: Node3D
func landing_checks() -> void:
	museum.call("flush_stamps")
	await create_timer(1.0).timeout
	pointer=load("res://commons/scenes/DesktopInteractionPointer.gd").new()
	root.add_child(pointer);pointer.set_process(false);pointer.set_physics_process(false)
	pointer.set("_camera",camera)
	match map_id:
		"Point_One":await point_checks()
		"Point_Lines":await line_checks()
		"Point_Triangle_Context":await triangle_checks()
		"Primitives_Polythedra":await solid_checks()

func point_checks() -> void:
	var conditions:={}
	for n in hall.find_children("*","Node3D",true,false):
		if n.get_script()!=null and str(n.get_script().resource_path).ends_with("/point_condition.gd"):conditions[n.condition]=n
	check("visible and solid stations loaded",conditions.has("visible") and conditions.has("solid"))
	for key in ["visible","solid"]:
		if not conditions.has(key):return
		var station:Node3D=conditions[key]
		check(key+" has no small podium",not station.has_node("PointPlinth"))
		var centre:Vector3=station.point.global_position
		var ray:=PhysicsRayQueryParameters3D.create(centre+Vector3.LEFT*0.5,centre+Vector3.RIGHT*0.5,1)
		var hit:=hall.get_world_3d().direct_space_state.intersect_ray(ray)
		check(key+" sphere collision matches condition",hit.is_empty() if key=="visible" else not hit.is_empty())
		await snapshot(key,centre+Vector3(1.4,0.5,2.8),centre,55)
	check("large final pedestal retained",conditions.has("pedestal") and conditions.pedestal.has_node("Pedestal"))

func carry_release(body: Node3D, at: Vector3) -> void:
	pointer.call("_grab_held",body)
	await tick()
	body.global_position=at
	await tick()
	await tick()
	pointer.call("_drop_held")
	await tick()

func xr_grab(body: Node3D, stays_frozen: bool) -> void:
	var origin:=XROrigin3D.new();var controller:=XRController3D.new()
	origin.add_child(controller);root.add_child(origin)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate()
	controller.add_child(pickup);pickup.set_process(false);pickup.set_physics_process(false)
	pickup.global_position=body.global_position
	pickup._object_in_grab_area.append(body);pickup._pick_up_object(body);await tick()
	check("XR Tools driver grabs "+body.name,body.is_picked_up())
	pickup.drop_object();await tick()
	check("XR release restores intended physics "+body.name,not body.is_picked_up() and body.freeze==stays_frozen)
	origin.queue_free()

func walk_to(walker: CharacterBody3D, target: Vector3, budget: int = 190) -> bool:
	for i in budget:
		var toward:=Vector3(target.x-walker.global_position.x,0,target.z-walker.global_position.z)
		if toward.length()<0.12:return true
		var horizontal:=toward.normalized()*2.8
		walker.velocity=Vector3(horizontal.x,-2.0 if walker.is_on_floor() else walker.velocity.y-0.1635,horizontal.z)
		walker.move_and_slide();await physics_frame
	return false

func line_checks() -> void:
	var field:=find_scene("/pairing_field.gd")
	var black:=find_scene("/line_black_box.gd")
	check("pairing field and measurement monolith loaded",field!=null and black!=null)
	if field==null or black==null:return
	check("twelve smaller independent points",field.points.size()==12)
	var a:Node3D=field.points[0];var b:Node3D=field.points[1]
	check("points begin without connections",field.manager._connections.is_empty())
	await carry_release(a,b.global_position+Vector3(0.20,0,0))
	observations["point_release"]={"distance":a.global_position.distance_to(b.global_position),"range":a.snap_distance,"manager":a._registered_manager==field.manager,"connections":field.manager._connections.size()}
	check("desktop release connects nearby points",field.manager._connections.size()==1)
	await carry_release(a,b.global_position+Vector3(1.0,0.2,0))
	check("moving a joined point retains the line",field.manager._connections.size()==1)
	check("points remain suspended after release",a.freeze)
	await xr_grab(field.points[11],true)
	await snapshot("pairing-points",field.to_global(Vector3(0,2.0,4.5)),field.to_global(Vector3(0,1.0,0)),58)
	await snapshot("measurement-monolith",black.to_global(Vector3(6,4,-6)),black.to_global(Vector3(0,1.2,0)),60)
	var barriers:Array=[];var crosses:Array=[]
	for n in hall.find_children("*","Node3D",true,false):
		if n.get_script()==null:continue
		var path:=str(n.get_script().resource_path)
		if path.ends_with("/do_not_cross_barrier.gd"):barriers.append(n)
		if path.ends_with("/anamorphic_cross.gd"):crosses.append(n)
	check("ten queue barriers",barriers.size()==10)
	check("three damage crosses remain",crosses.size()==3)
	for b2 in barriers:check("queue tape has collision",b2.solid and b2.form=="tape" and b2._body!=null)
	if not barriers.is_empty():
		barriers.sort_custom(func(c,d):return c.global_position.z<d.global_position.z)
		observations["queue_positions"]=barriers.map(func(n):return xyz(n.global_position))
		var origin:=field.global_position-Vector3(13,0,3)
		await snapshot("queue",origin+Vector3(17,3.2,17),origin+Vector3(12,0.9,25),70)
		var walker:CharacterBody3D=museum.get("_player")
		walker.global_position=origin+Vector3(9,0.02,17);walker.velocity=Vector3.ZERO
		await tick()
		check("straight shortcut meets a barrier",not await walk_to(walker,origin+Vector3(9,0,19),55))
		walker.global_position=origin+Vector3(9,0.02,17);walker.velocity=Vector3.ZERO
		for p in [Vector2(18,17),Vector2(18,19),Vector2(8,19),Vector2(8,21),Vector2(18,21),Vector2(18,23),Vector2(8,23),Vector2(8,25),Vector2(18,25),Vector2(18,27),Vector2(12,27),Vector2(12,35.6)]:
			check("walk queue waypoint "+str(p),await walk_to(walker,origin+Vector3(p.x,0,p.y),280))
	if not crosses.is_empty():
		var x:Node3D=crosses[0]
		await snapshot("consequence-passage",x.global_position+Vector3(0,1.6,-3.0),x.global_position+Vector3(0,1.1,3),65)
	var gallery:=find_scene("/line_relations_gallery.gd")
	check("other line encounters follow consequence passage",gallery!=null and gallery.global_position.z>crosses[-1].global_position.z)
	if gallery!=null:await snapshot("line-gallery",gallery.global_position+Vector3(-8,5,-6),gallery.global_position+Vector3(0,1,0),65)

func triangle_checks() -> void:
	var table:=find_scene("/triangle_table.gd")
	check("assembly table loaded",table!=null)
	if table==null:return
	check("twelve triangular pieces",table.pieces.size()==12)
	var p:Node3D=table.pieces[0]
	await carry_release(p,table.to_global(Vector3(0,1.6,0)))
	check("released triangle retains construction height",p.freeze and absf(table.to_local(p.global_position).y-1.6)<0.03)
	pointer.call("_grab_held",p);await tick()
	var before:Basis=p.basis
	var key:=InputEventKey.new();key.physical_keycode=KEY_R;key.pressed=true
	p._input(key);await tick()
	check("desktop holding can tilt a triangle",not p.basis.is_equal_approx(before))
	pointer.call("_drop_held");await tick()
	check("all triangles have physical pickup volumes",table.pieces.all(func(n):return n is RigidBody3D and n.has_method("pick_up") and n.get_child_count()>1))
	await xr_grab(table.pieces[11],true)
	await snapshot("triangle-table",table.to_global(Vector3(2.6,2.4,3)),table.to_global(Vector3(0,0.9,0)),58)
	# Supplied placements test that the stock can actually close a pyramid.
	# This does not claim a visitor has yet discovered or assembled it.
	var v:=PackedVector3Array([Vector3(-0.23,0,-0.133),Vector3(0.23,0,-0.133),Vector3(0,0,0.265),Vector3(0,0.3756,0)])
	var faces:=[[0,2,1],[0,1,3],[1,2,3],[2,0,3]]
	for i in 4:
		var f:Array=faces[i]
		var a:Vector3=v[f[0]];var b:Vector3=v[f[1]];var c:Vector3=v[f[2]]
		var x:Vector3=(b-a).normalized();var z:Vector3=(c-(a+b)*0.5).normalized()
		var basis:=Basis(x,z.cross(x),z)
		var piece:Node3D=table.pieces[i]
		piece.transform=Transform3D(basis,(a+b+c)/3.0+Vector3(0,0.87,0))
	await tick();await tick()
	check("four placed faces hold a pyramid",table.pieces.slice(0,4).all(func(n):return n.freeze))
	await snapshot("triangle-pyramid",table.to_global(Vector3(1.3,1.9,1.6)),table.to_global(Vector3(0,1.03,0)),48)

func solid_checks() -> void:
	var alignments:Array=[]
	for n in hall.find_children("*","Node3D",true,false):
		if n.get_script()!=null and str(n.get_script().resource_path).ends_with("/align_solid.gd"):alignments.append(n)
	check("two vertex alignment encounters loaded",alignments.size()==2)
	for station in alignments:
		check(station.kind+" begins unfinished",not station.complete and station.solid_body==null)
		await snapshot(station.kind+"-unfinished",station.to_global(Vector3(2.2,2.1,3.2)),station.to_global(Vector3(0,1.2,0)),48)
		await carry_release(station.handle,station.to_global(station.target_position+Vector3(0.3,0,0)))
		check(station.kind+" rejects distant release",not station.complete)
		await carry_release(station.handle,station.to_global(station.target_position))
		await create_timer(0.8).timeout
		check(station.kind+" completes on near release",station.complete and station.solid_body!=null)
		if station.solid_body!=null:
			check(station.kind+" falls under gravity",not station.solid_body.freeze and station.to_local(station.solid_body.global_position).y<0.8)
			await carry_release(station.solid_body,station.to_global(Vector3(0.3,1.4,0)))
			check(station.kind+" remains grabbable after completion",not station.solid_body.freeze)
			await xr_grab(station.solid_body,false)
			await create_timer(0.6).timeout
			await snapshot(station.kind+"-complete",station.to_global(Vector3(2,1.7,3)),station.to_global(Vector3(0,0.4,0)),52)
	var palace:=find_scene("/wedge_palace.gd")
	check("symmetric wedge palace loaded",palace!=null)
	if palace!=null:
		for side in [-1,1]:
			for fraction in [0.1,0.5,0.9]:
				var at:=palace.to_global(Vector3(side*(5.0-fraction*3.0),0,0))
				var ray:=PhysicsRayQueryParameters3D.create(at+Vector3.UP*2,at-Vector3.UP,1)
				var hit:=hall.get_world_3d().direct_space_state.intersect_ray(ray)
				check("ramp surface "+str(side)+" "+str(fraction),not hit.is_empty() and absf(hit.position.y-palace.global_position.y-0.9*fraction)<0.03)
		await snapshot("wedge-palace",palace.to_global(Vector3(-7,5,-7)),palace.to_global(Vector3(0,0.5,0)),65)
		var walker:CharacterBody3D=museum.get("_player")
		for side in [-1,1]:
			walker.global_position=palace.to_global(Vector3(side*5.4,0.03,0));walker.velocity=Vector3.ZERO
			await tick()
			check("walk up side "+str(side),await walk_to(walker,palace.to_global(Vector3(side*0.8,0.9,0))))
			check("walker reaches raised platform "+str(side),walker.global_position.y-palace.global_position.y>0.8)
		check("walk down far wedge",await walk_to(walker,palace.to_global(Vector3(0,0,5.3))))
		var basin:=palace.to_global(Vector3(0,0,10))
		check("basin has solid floor",not floor_at(basin).is_empty())
		await snapshot("basin-and-rock-room",palace.to_global(Vector3(-2,5,5)),palace.to_global(Vector3(4,0.5,10)),66)
	var corner:=find_scene("/corner_tetrahedron.gd")
	if corner!=null:await snapshot("corner-tetrahedron",corner.to_global(Vector3(4,2.6,4)),corner.to_global(Vector3(0.8,0.8,0.8)),55)
