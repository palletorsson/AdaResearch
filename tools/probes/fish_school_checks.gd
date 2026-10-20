extends SceneTree
var checks:Array=[]
var failures:Array=[]
func _initialize() -> void: run.call_deferred()
func check(label:String,ok:bool) -> void:
	checks.append({"name":label,"passed":ok})
	print("FISH ","PASS " if ok else "FAIL ",label)
	if not ok:failures.append(label)
func run() -> void:
	var scene=load("res://commons/artifacts/fish_school/fish_school.tscn")
	if scene==null:quit(1);return
	var room:=Node3D.new();root.add_child(room)
	room.position=Vector3(31,4,-20);room.rotation.y=.7
	var school=scene.instantiate();room.add_child(school)
	await process_frame
	school.playing=false;school._physics_process(0.0)
	check("72 fish reuse the existing Boid class",school.boids.size()==72 and school.boids[0] is Boid)
	check("PointBody is the carried XRToolsPickable",school.point.has_method("pick_up") and school.point.get_script().resource_path.ends_with("particle_swarm_walk/point_body.gd"))
	check("Unheld point adds exactly zero steering",school.steering_at(school.to_global(Vector3(-2,1,0)),Vector3.ONE)==Vector3.ZERO)
	var pointer:=Node3D.new();root.add_child(pointer)
	school.point.on_desktop_grab(pointer)
	var at:Vector3=school.point.global_position+room.global_basis*Vector3(-2,0,0)
	var toward:Vector3=(school.point.global_position-at).normalized()
	var gather:Vector3=school.steering_at(at,Vector3.ZERO)
	check("Pickup activates attraction in transformed world coordinates",gather.dot(toward)>0)
	school.point.action()
	check("Actual pickable action switches to scatter",school.scatter)
	var flee:Vector3=school.steering_at(at,Vector3.ZERO)
	check("Scatter points away from the held sphere",flee.dot(toward)<0)
	check("External steering is bounded",flee.length()<=school.HAND_FORCE and gather.length()<=school.HAND_FORCE)
	check("Coincident fish never divides by zero",school.steering_at(school.point.global_position,Vector3.ONE)==Vector3.ZERO)
	check("Fish outside eight metres get no hand term",school.steering_at(school.point.global_position+Vector3.UP*8.01,Vector3.ONE)==Vector3.ZERO)
	school.point.action_release()
	check("Trigger release returns to gather",not school.scatter)
	var fish=school.boids[0]
	var ids:Array=[]
	for b in school.boids:ids.append(b.get_instance_id())
	# Isolate the production hand term on a fish; the real integrator must use it.
	var saved:Array=[fish.alignment_weight,fish.cohesion_weight,fish.separation_weight,fish.boundary_weight,fish.min_speed]
	fish.alignment_weight=0;fish.cohesion_weight=0;fish.separation_weight=0;fish.boundary_weight=0;fish.min_speed=0
	fish.global_position=at;fish.velocity=Vector3.ZERO
	fish._physics_process(1.0/60)
	check("Production Boid integration moves toward sphere",fish.velocity.dot(toward)>0)
	school.point.action();fish.global_position=at;fish.velocity=Vector3.ZERO
	fish._physics_process(1.0/60)
	check("Production Boid integration moves away in scatter",fish.velocity.dot(toward)<0)
	fish.alignment_weight=saved[0];fish.cohesion_weight=saved[1];fish.separation_weight=saved[2];fish.boundary_weight=saved[3];fish.min_speed=saved[4]
	school.point.on_desktop_drop(pointer);school._physics_process(0.0)
	check("Dropping clears scatter and all hand steering",not school.scatter and school.steering_at(at,Vector3.ZERO)==Vector3.ZERO)
	school.point.global_position+=Vector3(5,-10,1)
	school._physics_process(2.0)
	check("Dropped sphere returns to reachable home",school.point.global_position.is_equal_approx(school.to_global(school.HOME)))
	var finite:=true;var speeds:=true;var bounds:=true
	for step in range(1200):
		for b in school.boids:
			b._physics_process(1.0/60)
			finite=finite and b.global_position.is_finite() and b.velocity.is_finite()
			speeds=speeds and b.velocity.length()<=b.max_speed+.001
			var local:Vector3=school.boundary.to_local(b.global_position)
			bounds=bounds and absf(local.x)<7 and absf(local.y)<3.5 and absf(local.z)<6.5
	check("20 seconds of full school stays finite",finite)
	check("Speed caps hold through full flock integration",speeds)
	check("School turns near its own translated boundary",bounds)
	check("Interaction reuses fish identities",school.boids[0].get_instance_id()==ids[0] and school.boids.size()==ids.size())
	var legacy=load("res://algorithms/emergentsystems/boidflocking/boid.tscn").instantiate();root.add_child(legacy)
	legacy.set_physics_process(false)
	check("Original Boid keeps world boundary and no hand source",legacy.boundary_frame==null and legacy.steering_source==null and legacy.boundary_margin==5.0)
	FileAccess.open("res://ada_run/fish_school_checks.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"scope":"Production Boid integrator, synthetic desktop pickup and real action signals; physical headset untested."},"  "))
	quit(0 if failures.is_empty() else 1)
