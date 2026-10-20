extends "res://tools/probes/flow_room_before.gd"
var routes={
	"entry_to_hand_table":[Vector2(6.5,1.5),Vector2(7.5,1.5),Vector2(7.5,6.3),Vector2(4.5,6.3),Vector2(4.5,5.55)],
	"table_to_ecosystem":[Vector2(4.5,6.3),Vector2(3.5,6.3),Vector2(3.5,7.5)],
	"gallery_to_ant_comparison":[Vector2(7.5,6.3),Vector2(9.5,6.3),Vector2(9.5,4.3)],
	"gallery_to_crowd":[Vector2(7.5,6.3),Vector2(11.5,6.3),Vector2(13.5,6.3),Vector2(13.5,7.5)],
	"gallery_to_exit":[Vector2(4.5,6.3),Vector2(6.5,6.3),Vector2(6.5,8.5)]}
func landing_checks()->void:
	await super.landing_checks()
	var stream=museum.get("_portal_stream")
	check("Authored north entry has a clear supported frame",not stream.get("_entry").is_empty() and not stream.get("_entry").get("invalid",false))
	check("Authored south exit has a clear supported approach",not stream.get("_exit").is_empty() and not stream.get("_exit").get("invalid",false))
	var table:=find_scene("/flow_direction_table.gd")
	var ants:=find_scene("/ant_colony_table.gd")
	var eco:=find_scene("/ecosystem.gd")
	check("Original flow and crowd remain beside ant and ecosystem",table!=null and ants!=null and eco!=null and find_scene("/flow_crowd.gd")!=null)
	if ants==null:return
	check("Exactly one original Ant Colony V2 is running",hall.find_children("*","Node3D",true,false).filter(func(n):return n.get_script()!=null and n.get_script().resource_path.ends_with("/AntColonyV2.gd")).size()==1)
	check("Ant physics keeps 100 bodies and original 50m size",ants.model.ants.size()==100 and ants.model.colony.terrain_size==Vector2(50,50) and ants.model.colony.scale==Vector3.ONE)
	var private_world:World3D=ants.model.viewport.find_world_3d()
	var separate:bool=private_world!=hall.get_world_3d()
	for n in ants.model.viewport.find_children("*","VisualInstance3D",true,false):separate=separate and n.get_world_3d()==private_world
	check("All original ant visuals and physics are contained",separate and ants.model.colony.get_world_3d()==private_world)
	check("Table is 1.8m with live original viewport",ants.screen.mesh.size==Vector2(1.8,1.8) and ants.screen.material_override.albedo_texture==ants.model.viewport.get_texture())
	check("Original ecosystem sits on the 80cm plinth",absf(eco.global_position.y-origin.y-.8)<.05)
	var p:Vector3=ants.model.ants[0].position;var ticks:int=ants.model.ticks
	await create_timer(2).timeout
	check("Original colony advances through actual physics ticks",ants.model.ticks>ticks and ants.model.ants[0].position.distance_to(p)>.001)
	ants.pause_button.pressed.emit();var kept:String=ants.model.digest();await create_timer(.3).timeout
	check("Nearby button pauses colony without resetting its state",not ants.model.running and kept==ants.model.digest())
	ants.pause_button.pressed.emit();await create_timer(.2).timeout
	check("Nearby button resumes the same colony",ants.model.running and kept!=ants.model.digest())
	var capsule:=CapsuleShape3D.new();capsule.radius=.24;capsule.height=1.7
	var records:Dictionary={}
	for label in routes:
		var points:Array=routes[label];var blocked:Array=[];var unsupported:Array=[];var samples:=0
		for i in range(points.size()-1):
			var a:Vector2=points[i];var b:Vector2=points[i+1];var count:=ceili(a.distance_to(b)/.12)
			for j in range(count+1):
				var xy:=a.lerp(b,float(j)/maxi(count,1));var foot:=at(Vector3(xy.x,0,xy.y))
				var q:=PhysicsShapeQueryParameters3D.new();q.shape=capsule;q.collision_mask=1;q.transform.origin=foot+Vector3.UP*.9
				var hits:=hall.get_world_3d().direct_space_state.intersect_shape(q)
				if not hits.is_empty():blocked.append({"at":[xy.x,xy.y],"body":str(hits[0].collider.get_path())})
				var floor:=floor_at(foot)
				if floor.is_empty() or absf(floor.position.y-foot.y)>.03:unsupported.append([xy.x,xy.y])
				samples+=1
		check(label+": continuous floor",unsupported.is_empty())
		check(label+": standing capsule clearance",blocked.is_empty())
		records[label]={"samples":samples,"blocked":blocked,"unsupported":unsupported}
	observations.routes=records
	# Walk the connected route with a real CharacterBody and gravity.
	var walker:=CharacterBody3D.new();walker.collision_layer=0;walker.collision_mask=1
	var collision:=CollisionShape3D.new();collision.shape=capsule;collision.position.y=.86;walker.add_child(collision);root.add_child(walker)
	walker.global_position=at(Vector3(6.5,.01,1.5));await tick()
	var walked:=true
	for target:Vector2 in [Vector2(7.5,1.5),Vector2(7.5,6.3),Vector2(4.5,6.3),Vector2(6.5,6.3),Vector2(6.5,8.1)]:
		walked=(await walk_to(walker,at(Vector3(target.x,0,target.y)))) and walked
	check("CharacterBody walks entry to table to exit with gravity",walked and walker.is_on_floor())
	observations.walker_end=xyz(walker.global_position);walker.queue_free();await tick()
	await snapshot("ant-table",ants.to_global(Vector3(.3,2.3,2.5)),ants.to_global(Vector3(0,1,0)),65)
	await snapshot("ecosystem",at(Vector3(4.1,1.6,8.3)),eco.global_position+Vector3.UP*.25,62)
	observations.headset_tested=false

func walk_to(body:CharacterBody3D,goal:Vector3)->bool:
	for i in range(240):
		await physics_frame
		var delta:=goal-body.global_position;delta.y=0
		if delta.length()<.08:return true
		body.velocity.x=delta.normalized().x*3;body.velocity.z=delta.normalized().z*3
		body.velocity.y-=9.8/60.0;body.move_and_slide()
	return false
