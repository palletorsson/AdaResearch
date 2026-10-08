extends SceneTree
var checks := 0
var failures: Array[String] = []
var observations: Dictionary = {}
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok: failures.append(message)
	print("[rotation-study] ","PASS " if ok else "FAIL ",message)

func walk(world: Node3D, start: Vector3, direction: Vector3, distance: float) -> Dictionary:
	var walker := CharacterBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius=0.22
	shape.height=1.6
	collision.shape=shape
	collision.position.y=0.8
	walker.add_child(collision)
	walker.floor_snap_length=0.15
	world.add_child(walker)
	walker.global_position=start+Vector3.UP*0.02
	var lowest := start.y
	var stalled := 0
	var previous := 0.0
	var stop_reason := "time_budget"
	for i in range(ceili(distance/2*60)*3):
		await physics_frame
		walker.velocity=direction*2+Vector3.UP*(walker.velocity.y-9.8/60)
		walker.move_and_slide()
		lowest=minf(lowest,walker.position.y)
		var progress := (walker.global_position-start).dot(direction)
		stalled=stalled+1 if progress-previous<0.001 else 0
		previous=progress
		if progress>=distance:
			stop_reason="arrived"; break
		if stalled>60:
			stop_reason="blocked"; break
		if walker.position.y<start.y-3:
			stop_reason="fell"; break
	var travel := (walker.global_position-start).dot(direction)
	var result := {"travel":travel,"lowest":lowest,"y":walker.position.y,"stop_reason":stop_reason,"reached":travel>=distance-0.1 and lowest>start.y-1.5}
	walker.queue_free()
	await physics_frame
	return result

func run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	current_scene=world
	var grid: Node3D=load("res://commons/grid/grid_system.tscn").instantiate()
	grid.map_name="Trans_Rotation"
	grid.bare_world=true
	grid.skip_player_spawn=true
	grid.position.y=-0.5
	var ready:=[false]
	grid.build_finished.connect(func():ready[0]=true,CONNECT_ONE_SHOT)
	world.add_child(grid)
	for i in range(2400):
		if ready[0]:break
		await process_frame
	check(ready[0],"actual rotation grid built")
	var wall: Node3D
	var arrays: Node3D
	for n in grid.find_children("*","Node3D",true,false):
		if n.get_script()==load("res://commons/artifacts/rotation_studies/wall_crossings.gd"):wall=n
		if n.get_script()==load("res://commons/artifacts/rotation_studies/array_compare.gd"):arrays=n
	check(wall!=null and arrays!=null,"two distinct studies instantiated")
	if wall==null or arrays==null:quit(1);return
	wall.set_process(false)
	check(wall.global_position.is_equal_approx(Vector3(25,0,14)),"blade study seated at source grid origin")
	check(arrays.global_position.is_equal_approx(Vector3(25,0,33)),"array study seated at source grid origin")
	check(wall.global_basis.get_scale().is_equal_approx(Vector3.ONE) and arrays.global_basis.get_scale().is_equal_approx(Vector3.ONE),"studies retain full scale")
	check(wall.find_children("Bank*","Node3D",true,false).is_empty(),"all static banks belong to the grid, no added platforms")
	var structure: Dictionary = {}
	for n in grid.find_children("*","MultiMeshInstance3D",true,false):
		var poses: Array[Transform3D]=[]
		if n.multimesh!=null:
			for i in range(n.multimesh.instance_count):poses.append(n.multimesh.get_instance_transform(i))
		structure[n]={"transform":n.transform,"instances":poses}
	wall.set_crossing_pose()
	await physics_frame
	for station: Dictionary in wall.stations:
		check(station.panel.position.is_zero_approx(),str(station.id)+" blade rotates around its middle")
		var direction:=Vector3.RIGHT if station.id=="Z" else Vector3.BACK
		var start: Vector3=station.node.to_global(-direction*4.5)
		var result: Dictionary=await walk(world,start,direction,10)
		observations["blade_"+str(station.id)]=result
		var expected_y:=0.0 if station.id=="Y" else 3.0
		check(result.reached and absf(result.y-expected_y)<0.04,str(station.id)+" centre blade reaches grid landing at y="+str(expected_y))
		print("[blade walk] ",station.id," ",result)
	var centres: Array[Vector3]=[]
	for band: Dictionary in arrays.bands:
		for cube: Node3D in band.cubes:centres.append(cube.global_position)
	check(centres.size()==160,"four actual 4 by 10 cube arrays")
	arrays.row_angle_step=0
	arrays.apply_gradient()
	await physics_frame
	for band: Dictionary in arrays.bands:
		var start: Vector3=band.node.to_global(Vector3(-1,0,-1.4))
		var result: Dictionary=await walk(world,start,Vector3.BACK,23)
		observations["flat_"+str(band.id)]=result
		check(result.reached,str(band.id)+" unrotated control is traversable along +z")
	arrays.row_angle_step=10
	arrays.apply_gradient()
	await physics_frame
	for band: Dictionary in arrays.bands:
		var start: Vector3=band.node.to_global(Vector3(-1,0,-1.4))
		var result: Dictionary=await walk(world,start,Vector3.BACK,23)
		observations["gradient_"+str(band.id)]=result
		print("[gradient walk] ",band.id," ",result)
	check(observations.gradient_X.stop_reason=="blocked","increasing x tilt obstructs forward walking, rather than merely taking longer")
	check(observations.gradient_Y.reached,"y turns preserve a forward route at this spacing")
	check(observations.gradient_Z.travel>observations.gradient_X.travel,"ridges along z allow more forward progress than transverse x slopes")
	var index:=0
	var all_centres_fixed:=true
	var matching_collision:=true
	for band: Dictionary in arrays.bands:
		for cube: Node3D in band.cubes:
			all_centres_fixed=all_centres_fixed and cube.global_position.is_equal_approx(centres[index])
			var body: Node3D=cube.get_node("Body")
			matching_collision=matching_collision and body.global_basis.is_equal_approx(cube.global_basis)
			index+=1
	check(all_centres_fixed,"all 160 cube centres stay fixed across the angle changes")
	check(matching_collision,"every rotated cube carries its matching physical collision")
	for node: Node3D in structure:
		var unchanged: bool=node.transform==structure[node].transform
		for i in range(structure[node].instances.size()):unchanged=unchanged and node.multimesh.get_instance_transform(i).is_equal_approx(structure[node].instances[i])
		check(unchanged,"surrounding grid and its individual cubes stay fixed")
	var f:=FileAccess.open("res://ada_run/rotation_studies_checks.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"failures":failures,"observations":observations},"  "))
	print("[rotation-study] ",checks," checks; ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
