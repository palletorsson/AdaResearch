extends "res://tools/probes/transformation_encounters.gd"
const IDS=["entropy_chairs_shannon","entropy_chairs_boltzmann","entropy_chairs_description","entropy_door_dynamics","entropy_cooling_cup","entropy_frosted_chair","entropy_ball_pit"]

func clear_person(p: Vector3) -> bool:
	var shape:=CapsuleShape3D.new();shape.radius=0.22;shape.height=1.6
	var query:=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.collision_mask=1
	query.transform=Transform3D(Basis(),p+Vector3.UP*0.85)
	return hall.get_world_3d().direct_space_state.intersect_shape(query).is_empty()

func landing_checks() -> void:
	root.size=Vector2i(1600,1050);museum.call("flush_stamps");await create_timer(0.5).timeout
	var stations: Dictionary={}
	for node in hall.find_children("*","Node3D",true,false):
		if node.get_script()!=null and str(node.get_script().resource_path).ends_with("ordinary_entropies/comparison.gd"):stations[node.kind]=node
	check("all seven installed comparison exhibits",stations.size()==7)
	if stations.size()!=7:return
	for kind in 7:
		var exhibit: Node3D=stations[kind]
		if kind==3:exhibit.automatic=false;exhibit.advance_doors(8)
		check("everyday scale "+str(kind),exhibit.scale.is_equal_approx(Vector3.ONE))
		check("no interfaces "+str(kind),exhibit.find_children("*","Area3D",true,false).is_empty())
		var board: Node3D=exhibit.wall_text
		check("information has its own full-height support "+str(kind),board.get_node_or_null("FloorToTopBacking")!=null)
		var normal: Vector3=board.global_basis.z
		var p: Vector3=board.global_position+normal*0.95;p.y=exhibit.global_position.y
		check("wall text has standing floor "+str(kind),not floor_at(p).is_empty())
		check("wall text has clear approach "+str(kind),clear_person(p))
		var back:=PhysicsRayQueryParameters3D.create(board.global_position+normal*0.05,board.global_position-normal*0.15,1)
		check("explanation mounted on existing wall "+str(kind),not hall.get_world_3d().direct_space_state.intersect_ray(back).is_empty())
		await snapshot("wall-"+str(kind+1),board.global_position+normal*1.6,board.global_position,67)
		var height:=1.65
		var distance: float=[4.9,4.9,5.5,5.0,4.6,4.6,5.2][kind]
		if kind==2:
			await snapshot(IDS[kind],exhibit.to_global(Vector3(-6.5,1.65,3.3)),exhibit.to_global(Vector3(0,0.7,0)),95)
		else:await snapshot(IDS[kind],exhibit.to_global(Vector3(0,height,distance)),exhibit.to_global(Vector3(0,0.65,0)),108 if kind in [3,6] else 95)
		for i in exhibit.versions.size():
			var copy: Node3D=exhibit.versions[i]
			var approach: Vector3=copy.to_global(Vector3(0,0,3.1 if kind in [3,6] else (1.5 if kind in [0,1,5] else 1.25)))
			check("copy approach supported %d:%d" % [kind,i],not floor_at(approach).is_empty())
			check("copy approach clear %d:%d" % [kind,i],clear_person(approach))
	var doors: Node3D=stations[3]
	check("door wall installed",doors.get_node_or_null("DoorWall")!=null)
	for x in [-7.0,-2.25,2.25,7.0]:
		var ray:=PhysicsRayQueryParameters3D.create(doors.to_global(Vector3(x,1,0.5)),doors.to_global(Vector3(x,1,-0.5)),1)
		check("solid wall between openings "+str(x),not hall.get_world_3d().direct_space_state.intersect_ray(ray).is_empty())
	for step in 9:
		doors.advance_doors(step);await physics_frame
		for z in [-2.5,0,2.5]:check("centre passage clear step %d at %s" % [step,z],clear_person(doors.to_global(Vector3(0,0,z))))
	await snapshot("doors-in-wall",doors.to_global(Vector3(0,1.65,6.0)),doors.to_global(Vector3(0,1.05,0)),110)
	var cups: Node3D=stations[4]
	cups.automatic=false;cups._process(0)
	await snapshot("coffee-table",cups.to_global(Vector3(0,1.65,1.45)),cups.to_global(Vector3(0,0.8,0)),85)
	await snapshot("coffee-above",cups.to_global(Vector3(0,2.65,1.2)),cups.to_global(Vector3(0,0.8,0)),62)
	for i in 5:
		var copy: Node3D=cups.versions[i]
		var p: Vector3=copy.position
		check("cup inspection has floor "+str(i),not floor_at(cups.to_global(Vector3(p.x,0,0.95))).is_empty())
		check("cup inspection clear "+str(i),clear_person(cups.to_global(Vector3(p.x,0,0.95))))
		await snapshot("cup-"+str(i+1),copy.to_global(Vector3(0,1.18,0.19)),copy.to_global(Vector3(0,0.86,0)),52)
	var glass: Node3D=stations[5]
	await snapshot("five-panes",glass.to_global(Vector3(0,1.65,5.4)),glass.to_global(Vector3(0,0.8,0)),105)
	for i in 5:
		var copy: Node3D=glass.versions[i]
		await snapshot("glass-"+str(i+1),copy.to_global(Vector3(0,1.05,2.3)),copy.to_global(Vector3(0,0.8,0)),53)

	for i in 3:
		var copy: Node3D=stations[6].versions[i]
		await snapshot("guess-"+str(i+1),copy.to_global(Vector3(0,2.0,3.2)),copy.to_global(Vector3(0,0.8,0)),65)
	var reference: Node3D=null
	for node in hall.find_children("*","Node3D",true,false):
		if node.get_script()!=null and str(node.get_script().resource_path).ends_with("ordinary_entropies/chair_reference.gd"):reference=node
	check("wall reference installed",reference!=null)
	if reference!=null:
		check("reference uses full-size chair",reference.get_node("ReferenceChair").scale.is_equal_approx(Vector3.ONE))
		check("reference approach supported",not floor_at(reference.to_global(Vector3(0,0,1.2))).is_empty())
		check("reference approach clear",clear_person(reference.to_global(Vector3(0,0,1.2))))
		await snapshot("chair-reference",reference.to_global(Vector3(0,1.6,2.3)),reference.to_global(Vector3(0,1.05,0)),68)
	var first: Node3D=stations[0]
	var origin: Vector3=first.global_position-Vector3(4.5,0,6.5)
	await snapshot("paired-chairs",origin+Vector3(9.5,1.65,1.6),origin+Vector3(9.5,0.7,6.5),110)
	check("centre doorway permanently clear",clear_person(stations[3].global_position))
	for cell in [Vector2(9.5,1.5),Vector2(16.5,11.5),Vector2(16.5,35.5),Vector2(9.5,44.5),Vector2(9.5,55.5)]:
		var p: Vector3=origin+Vector3(cell.x,0,cell.y)
		check("passage floor "+str(cell),not floor_at(p).is_empty())
		check("passage clear "+str(cell),clear_person(p))
	root.size=Vector2i(1050,1600);camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=62
	await snapshot("aerial",origin+Vector3(9.5,50,28.5),origin+Vector3(9.5,0,28.51),50)
	observations.scope="Simpler colour-guess trays and a wall chair reference. Five cups on one table, five frosted panes, visible chance tickets and doors embedded in a solid partition. Clear central passage checked through every driven step; room views and closeups captured. Headset and understanding remain human checks."
