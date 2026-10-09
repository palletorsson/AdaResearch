extends "res://tools/probes/transformation_encounters.gd"
## Supplied physical walks through the existing Body encounters, in an isolated museum.
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
		actor.velocity.x = movement.x; actor.velocity.z = movement.z
		actor.velocity.y -= 9.8 * delta
		actor.move_and_slide()
		if offset.length() < 0.06 and actor.is_on_floor():
			arrived=true; active=false;actor.velocity=Vector3.ZERO

var completed := false
var actor: CharacterBody3D
var driver: WalkInput
var wall: Node3D
var carve: Node3D
var field: Node3D

func walk_to(target: Vector3, label: String) -> bool:
	driver.target=target;driver.arrived=false;driver.active=true
	var start:=Time.get_ticks_msec()
	while not driver.arrived and Time.get_ticks_msec()-start < 12000:
		await process_frame
	driver.active=false
	check(label,driver.arrived)
	observations[label]={"arrived":driver.arrived,"feet":xyz(actor.global_position),"target":xyz(target)}
	return driver.arrived

func park() -> void:
	actor.global_position = Vector3(-100,0,-100)
	actor.velocity=Vector3.ZERO
	await create_timer(1.8).timeout

func pose_photo(study: Node3D, name: String, eye: Vector3, target: Vector3, fov:=62.0) -> void:
	await snapshot(name,study.to_global(eye),study.to_global(target),fov)

func check_block_bases(stage: String) -> void:
	var errors: Array=[]
	for i in field._count:
		var body: Node3D=field._bodies[i]
		var bottom: float=body.global_position.y-field._shapes[i].size.y*body.global_basis.get_scale().y*0.5
		errors.append(bottom)
		check(stage+" block "+str(i)+" base stays on the deck",absf(bottom)<0.005)
		check(stage+" block "+str(i)+" mesh and collision agree",field._meshes[i].size.is_equal_approx(field._shapes[i].size))
	observations[stage+"_block_bases_world_y"]=errors

func landing_checks() -> void:
	wall=find_scene("/approach_wall.gd");carve=find_scene("/carve_grid.gd");field=find_scene("/approach_scale.gd")
	actor=museum.get("_player")
	check("all three existing encounters and museum body loaded",wall!=null and carve!=null and field!=null and actor!=null)
	if wall==null or carve==null or field==null or actor==null:return
	actor.set_process(false);actor.set_physics_process(false)
	driver=WalkInput.new();driver.actor=actor;root.add_child(driver)
	for shape in actor.find_children("*","CollisionShape3D",true,false):
		if shape.shape is CapsuleShape3D:observations["actual_body"]={"width":2*shape.shape.radius,"height":shape.shape.height,"offset":xyz(shape.position)}
	observations["anchors"]={"wall":xyz(wall.global_position),"carve":xyz(carve.global_position),"field":xyz(field.global_position)}
	await park()
	check("slats close without a nearby body",wall.openness()<0.01)
	await pose_photo(wall,"slats-before",Vector3(-1.7,2.4,-4.0),Vector3(0,1.4,0))
	actor.global_position=wall.to_global(Vector3(0,0.04,-3.4))
	if not await walk_to(wall.to_global(Vector3(0,0,-0.85)),"walk to slat opening"):return
	await create_timer(0.65).timeout
	check("natural proximity opens slats",wall.openness()>0.5)
	await pose_photo(wall,"slats-near",Vector3(-1.7,2.4,-4.0),Vector3(0,1.4,0))
	if not await walk_to(wall.to_global(Vector3(0,0,3.5)),"walk through slats and leave reach"):return
	await create_timer(1.7).timeout
	check("slats return after the walk",wall.openness()<0.01)
	await pose_photo(wall,"slats-after",Vector3(-1.7,2.4,-4.0),Vector3(0,1.4,0))
	await park()
	check("lattice has not yet lost cells",carve._carved==0)
	await pose_photo(carve,"lattice-before",Vector3(1.0,2.7,-4.0),Vector3(0,0.6,0),64)
	actor.global_position=carve.to_global(Vector3(0,0.04,-2.6))
	if not await walk_to(carve.to_global(Vector3(0,0,2.7)),"walk through lattice without bypass"):return
	var removed: int = carve._carved
	check("walking removed cells",removed>0)
	observations["removed_cells"]=removed;observations["total_cells"]=carve._count
	await park()
	check("cut stays after the body leaves",carve._carved==removed)
	await pose_photo(carve,"lattice-after",Vector3(1.0,2.7,-4.0),Vector3(0,0.6,0),64)
	check("scaling field starts full",Array(field._shown).min()>0.99)
	check_block_bases("initial")
	await pose_photo(field,"blocks-before",Vector3(1.0,3.2,-4.5),Vector3(0,0.5,0),67)
	actor.global_position=field.to_global(Vector3(0.75,0.04,-3.2))
	if not await walk_to(field.to_global(Vector3(0.75,0,0)),"walk between shrinking blocks"):return
	await create_timer(0.8).timeout
	check("natural approach reduces blocks",Array(field._shown).min()<0.6)
	observations["near_factors"]=Array(field._shown)
	check_block_bases("near")
	await pose_photo(field,"blocks-near",Vector3(1.0,3.2,-4.5),Vector3(0,0.5,0),67)
	if not await walk_to(field.to_global(Vector3(0.75,0,4.5)),"walk out of block sensing range"):return
	await create_timer(2).timeout
	check("all blocks regain their size",Array(field._shown).min()>0.99)
	check_block_bases("returned")
	await pose_photo(field,"blocks-after",Vector3(1.0,3.2,-4.5),Vector3(0,0.5,0),67)
	check("lattice alone still retains the changed occupancy",carve._carved==removed)
	completed=true

func finish() -> void:
	check("all three encounter comparisons completed",completed)
	var result: Dictionary={"room":map_id,"checks":checks,"failures":failures,"observations":observations,"passed":failures.is_empty(),"scope":"Actual isolated museum, actual museum CharacterBody3D with supplied physics-tick walking input. Body placed at each separate encounter's approach; movement through each gate uses move_and_slide. Selected elevated cameras for book illustrations. No headset or learner test."}
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	print("BODY ILLUSTRATIONS ",checks.size()-failures.size(),"/",checks.size())
	quit(0 if failures.is_empty() else 1)
