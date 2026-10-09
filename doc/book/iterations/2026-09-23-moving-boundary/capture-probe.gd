extends "res://tools/probes/transformation_encounters.gd"
## Actual isolated hall; frozen native figure poses, then a supplied physical door crossing.
class WalkInput extends Node:
	var actor: CharacterBody3D
	var target := Vector3.ZERO
	var active := false
	var arrived := false
	func _physics_process(delta: float) -> void:
		if not active: return
		var offset := target - actor.global_position
		offset.y = 0
		var movement := offset.normalized() * minf(1.5, offset.length() / maxf(delta,0.0001))
		actor.velocity.x=movement.x;actor.velocity.z=movement.z;actor.velocity.y-=9.8*delta
		actor.move_and_slide()
		if offset.length()<0.06 and actor.is_on_floor():
			arrived=true;active=false;actor.velocity=Vector3.ZERO

var completed:=false
var actor: CharacterBody3D
var driver: WalkInput
var door: Node3D
var growers: Array[Node3D]=[]

func walk_to(target: Vector3, label: String) -> bool:
	driver.target=target;driver.arrived=false;driver.active=true
	var start:=Time.get_ticks_msec()
	while not driver.arrived and Time.get_ticks_msec()-start<12000:await process_frame
	driver.active=false
	check(label,driver.arrived)
	observations[label]={"arrived":driver.arrived,"feet":xyz(actor.global_position),"target":xyz(target)}
	return driver.arrived

func pose_photo(study: Node3D, title: String, eye: Vector3, aim: Vector3, fov:=62.0) -> void:
	await snapshot(title,study.to_global(eye),study.to_global(aim),fov)

func landing_checks() -> void:
	door=find_scene("/transformation_airlock.gd")
	for n in hall.find_children("*","Node3D",true,false):
		if n.get_script()!=null and str(n.get_script().resource_path).ends_with("/grower_block.gd"):growers.append(n)
	actor=museum.get("_player")
	check("three growers, final door and actual museum body loaded",growers.size()==3 and door!=null and actor!=null)
	if growers.size()!=3 or door==null or actor==null:return
	actor.set_process(false);actor.set_physics_process(false)
	actor.global_position=Vector3(-100,0,-100);actor.velocity=Vector3.ZERO
	driver=WalkInput.new();driver.actor=actor;root.add_child(driver)
	for shape in actor.find_children("*","CollisionShape3D",true,false):
		if shape.shape is CapsuleShape3D:observations["actual_body"]={"width":2*shape.shape.radius,"height":shape.shape.height,"offset":xyz(shape.position)}
	observations["door_world"]=xyz(door.global_position)
	observations["grower_world"]=growers.map(func(g):return xyz(g.global_position))
	for g in growers:
		g._time=0;g._update_size()
		check("grower configuration "+str(g.name),g.anchor=="floor" and is_equal_approx(g.min_scale,0.3) and is_equal_approx(g.max_scale,3.5) and is_equal_approx(g.grow_speed,0.15))
	var start_pos:=actor.global_position
	await create_timer(3.34).timeout
	check("all cubes grow without visitor approach",growers.all(func(g):return g._box_shape.size.x>3.45))
	check("stationary visitor was not moved",actor.global_position.is_equal_approx(start_pos))
	for g in growers:g.set_physics_process(false)
	var middle:Node3D=growers[1]
	for sample in [[0.0,"small"],[PI,"large"]]:
		for g in growers:
			g._time=sample[0];g._update_size()
			var base:float=g._mesh.global_position.y-g._box_shape.size.y*0.5
			check(str(sample[1])+" grower base "+str(g.name),absf(base-g.global_position.y)<0.005)
			check(str(sample[1])+" mesh matches collision "+str(g.name),g._mesh.mesh.size.is_equal_approx(g._box_shape.size) and g._mesh.global_position.is_equal_approx(g._col_shape.global_position))
		await pose_photo(middle,"growers-"+str(sample[1]),Vector3(0,2.0,-4.0),Vector3(0,1.0,0),78)
	door.set_physics_process(false)
	for sample in [[0.0,"closed"],[0.52,"turning"],[1.0,"open"]]:
		door.progress=sample[0];door._apply_pose()
		await tick()
		var op:Vector3=door.operation_values()
		observations["door_"+str(sample[1])] = {"progress":sample[0],"operations":xyz(op)}
		for i in 2:
			check(str(sample[1])+" physical leaf unit scale "+str(i),door._leaves[i].basis.get_scale().is_equal_approx(Vector3.ONE))
			var factor:float=lerpf(1.0,0.34,op.z)
			check(str(sample[1])+" visible physical leaf size "+str(i),door._shapes[i].points[0].is_equal_approx(door._vertices[i][0]*factor) and door._visuals[i].scale.is_equal_approx(Vector3.ONE*factor))
		await pose_photo(door,"door-"+str(sample[1]),Vector3(0,1.7,-5.2),Vector3(0,1.7,0),70)
	# Restore its ordinary proximity controller before supplying a real approach.
	door.progress=0;door._apply_pose();door._empty_time=4;door.set_physics_process(true)
	actor.global_position=door.to_global(Vector3(0,0.04,-5.35));actor.velocity=Vector3.ZERO
	await create_timer(0.4).timeout
	check("door stays closed outside sensor",is_zero_approx(door.progress))
	if not await walk_to(door.to_global(Vector3(0,0,-3.5)),"walk into door approach"):return
	await create_timer(5.0).timeout
	check("normal proximity opens door fully",is_equal_approx(door.progress,1.0))
	var held:=actor.global_position
	await create_timer(3.2).timeout
	check("door holds while body waits",is_equal_approx(door.progress,1.0))
	check("door never relocates waiting body",held.is_equal_approx(actor.global_position))
	if not await walk_to(door.to_global(Vector3(0,0,1.1)),"walk through actual open door"):return
	if not await walk_to(door.to_global(Vector3(0,0,-2.0)),"return through same opening"):return
	actor.global_position=Vector3(-100,0,-100);actor.velocity=Vector3.ZERO
	await create_timer(2.6).timeout
	check("door waits before empty close",is_equal_approx(door.progress,1.0))
	await create_timer(5.5).timeout
	check("door returns closed after vacancy",is_zero_approx(door.progress))
	completed=true

func finish() -> void:
	check("capture and interaction study completed",completed)
	var result:Dictionary={"room":map_id,"checks":checks,"failures":failures,"observations":observations,"passed":failures.is_empty(),"scope":"Isolated production museum. Selected frozen figure poses; ordinary grower clock with visitor parked; supplied actual-body approach, crossing and return through the final door. Not a full hall, headset or learner test."}
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	print("MOVING BOUNDARY ",checks.size()-failures.size(),"/",checks.size())
	quit(0 if failures.is_empty() else 1)
