extends "res://tools/probes/hall_portal_navigation.gd"
## Same swept crossing / unload / return regression, plus real body locomotion.
## Terrain needs a route over measured heights, rather than a flat straight ray.
var assertion_count := 0

func check(ok: bool, message: String) -> void:
	assertion_count+=1
	super.check(ok,message)
	print("[passage] ","PASS " if ok else "FAIL ",message)

func check_landing(portal: Node3D, end: int, label: String) -> void:
	var expected: Vector3=portal._landings[end]
	var walker: CharacterBody3D=xr_body if is_instance_valid(xr_body) else museum.get("_player")
	var hall: Node3D=portal._current.node
	check(walker!=null,label+": real player body exists")
	check(walker.global_position.distance_to(expected)<0.25,label+": feet placed at arrival")
	for i in range(90):await physics_frame
	check(absf(walker.global_position.y-expected.y)<0.15,label+": settles under gravity")
	check(Vector2(walker.global_position.x-expected.x,walker.global_position.z-expected.z).length()<0.35,label+": no lateral drift")
	check(portal._supported(expected),label+": supported landing")
	var slabs=hall.get_node("HallPortals").find_children("LandingCollision","StaticBody3D",true,false)
	check(slabs.size()==2,label+": two solid thresholds")
	# Geometry sampling must not hit the observing player's own collider.
	portal.set_process(false)
	museum.set_physics_process(false)
	var body_processing:=walker.is_physics_processing()
	walker.set_physics_process(false)
	var parked:=walker.global_position
	walker.global_position=Vector3(-1000,0,-1000)
	await physics_frame;await physics_frame
	if end<0:
		var gate: Dictionary=museum.get("_gate")
		if not gate.is_empty():
			museum.call("_open_gate")
			museum.get("_mod_gate").call("step_open",gate,3.0)
			await physics_frame;await physics_frame
		var route:=find_route(portal,expected,hall)
		check(not route.is_empty(),label+": route from arrival into hall")
		walker.global_position=parked
		await physics_frame
		if not route.is_empty():
			check(await walk_route(walker,route),label+": body walks arrival route without jumping or teleporting")
	else:
		check(portal._exit.get("inward")==Vector3.FORWARD,"Exit faces the hall")
		check(portal._exit.get("cell")==Vector2i(6,13),"Exit clears the rear boundary wall")
		walker.global_position=parked
		await physics_frame
		# Down the 3 m wide ramp and back up. Only initial placement is supplied;
		# subsequent positions come from move_and_slide against live colliders.
		var down: Array[Vector3]=[Vector3(expected.x,expected.y,expected.z-4.0)]
		check(await walk_route(walker,down),"Actual body descends landing and ramp")
		var low:=walker.global_position
		check(low.y<0.65,"Ramp reaches the terrain floor")
		var up: Array[Vector3]=[expected]
		check(await walk_route(walker,up),"Actual body climbs ramp to doorway without jumping")
		check(absf(walker.global_position.y-1.0)<0.15,"Body reaches the one-metre landing")
	landing_checks.append({"stage":label,"expected":str(expected),"body_after_walk":str(walker.global_position),"assertions_so_far":assertion_count,"supplied":"scanner access and horizontal velocity; real gravity/collision; no physical headset"})
	portal._move_player(expected)
	walker.velocity=Vector3.ZERO
	walker.set_physics_process(body_processing)
	museum.set_physics_process(true)
	portal.set_process(true)

func find_route(portal: Node, start: Vector3, hall: Node3D) -> Array[Vector3]:
	var queue: Array[Vector2i]=[Vector2i.ZERO]
	var points: Dictionary={Vector2i.ZERO:start}
	var parents: Dictionary={}
	var visited: Dictionary={Vector2i.ZERO:true}
	var cursor:=0
	while cursor<queue.size() and cursor<2200:
		var here:=queue[cursor];cursor+=1
		var at: Vector3=points[here]
		if hall.to_local(at).z>=maxf(6.5,hall.to_local(start).z+1.0):
			var route: Array[Vector3]=[]
			while here!=Vector2i.ZERO:
				route.push_front(points[here]);here=parents[here]
			return route
		for offset in [Vector2i(0,1),Vector2i(1,0),Vector2i(-1,0),Vector2i(0,-1)]:
			var next: Vector2i=here+offset
			if visited.has(next) or absi(next.x)>24 or next.y<0 or next.y>32:continue
			visited[next]=true
			var p: Vector3=portal._nearest_floor(start+Vector3(next.x*0.125,2,next.y*0.125))
			if absf(p.y-at.y)>0.3 or not portal._supported(p):continue
			points[next]=p;parents[next]=here;queue.append(next)
	return []

func walk_route(body: CharacterBody3D, points: Array[Vector3]) -> bool:
	var began:=Time.get_ticks_msec()
	var bottom:=body.global_position.y-2.0
	for target in points:
		while Vector2(body.global_position.x-target.x,body.global_position.z-target.z).length()>0.045:
			if Time.get_ticks_msec()-began>18000 or body.global_position.y<bottom:return false
			await physics_frame
			var delta:=1.0/float(Engine.physics_ticks_per_second)
			var direction:=Vector3(target.x-body.global_position.x,0,target.z-body.global_position.z)
			var speed:=minf(1.6,direction.length()/delta)
			var horizontal:=direction.normalized()*speed
			body.velocity=Vector3(horizontal.x,body.velocity.y-9.8*delta,horizontal.z)
			body.move_and_slide()
	return true
