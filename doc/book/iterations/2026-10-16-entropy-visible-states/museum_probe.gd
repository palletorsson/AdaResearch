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
		var normal: Vector3=board.global_basis.z
		var p: Vector3=board.global_position+normal*0.95;p.y=exhibit.global_position.y
		check("wall text has standing floor "+str(kind),not floor_at(p).is_empty())
		check("wall text has clear approach "+str(kind),clear_person(p))
		var back:=PhysicsRayQueryParameters3D.create(board.global_position+normal*0.05,board.global_position-normal*0.15,1)
		check("explanation mounted on existing wall "+str(kind),not hall.get_world_3d().direct_space_state.intersect_ray(back).is_empty())
		await snapshot("wall-"+str(kind+1),board.global_position+normal*1.6,board.global_position,67)
		var height:=1.65
		var distance: float=[4.9,4.9,5.5,5.0,4.6,4.6,5.2][kind]
		await snapshot(IDS[kind],exhibit.to_global(Vector3(0,height,distance)),exhibit.to_global(Vector3(0,0.65,0)),108 if kind in [2,3,6] else 95)
		for i in exhibit.versions.size():
			var copy: Node3D=exhibit.versions[i]
			var approach: Vector3=copy.to_global(Vector3(0,0,2.0 if kind==6 else (1.5 if kind in [0,1,5] else 1.25)))
			check("copy approach supported %d:%d" % [kind,i],not floor_at(approach).is_empty())
			check("copy approach clear %d:%d" % [kind,i],clear_person(approach))
	var first: Node3D=stations[0]
	var origin: Vector3=first.global_position-Vector3(4.5,0,6.5)
	await snapshot("paired-chairs",origin+Vector3(9.5,1.65,1.6),origin+Vector3(9.5,0.7,6.5),110)
	check("centre doorway permanently clear",clear_person(stations[3].global_position))
	for cell in [Vector2(9.5,1.5),Vector2(16.5,11.5),Vector2(16.5,24.5),Vector2(16.5,35.5),Vector2(9.5,44.5),Vector2(9.5,55.5)]:
		var p: Vector3=origin+Vector3(cell.x,0,cell.y)
		check("passage floor "+str(cell),not floor_at(p).is_empty())
		check("passage clear "+str(cell),clear_person(p))
	root.size=Vector2i(1050,1600);camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=62
	await snapshot("aerial",origin+Vector3(9.5,50,28.5),origin+Vector3(9.5,0,28.51),50)
	observations.scope="Simultaneous normal-scale versions, absent interfaces, mounted wall texts, supported clear approaches and open passage. Headset and learning remain human checks."
