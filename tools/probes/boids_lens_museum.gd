extends "res://tools/probes/boids_lens_before.gd"
func agent_state(f:Node)->Array:
	var result:Array=[]
	for b in f._boids:result.append([b.position,b.velocity])
	return result
func landing_checks()->void:
	await super.landing_checks()
	var h:=find_scene("/boids_neighbour_lens.gd")
	check("Neighbour lens is installed",h!=null)
	if h==null:return
	check("Original thirty-boid controls remain the model",h.flock._boids.size()==30 and h.flock.get_script().resource_path.ends_with("/flocking_controls.gd"))
	check("Original large flock, aquarium, fish and drones remain",find_scene("/boid_manager.gd").get_boids().size()==100 and find_scene("/boids_aquarium.gd")!=null and find_scene("/fish_school.gd").boids.size()==72 and find_scene("/drone_comparison.gd")!=null)
	check("Original west observation balcony remains",hall.get_node_or_null("ObservationBalcony")!=null)
	var stream=museum.get("_portal_stream")
	check("Authored entry and exit are valid",not stream.get("_entry").get("invalid",false) and not stream.get("_exit").get("invalid",false))
	var routes={
		"entry to controls":[Vector2(6.5,1.5),Vector2(6.5,5.5),Vector2(9.5,5.5),Vector2(9.5,4.85)],
		"both hand controls":[Vector2(8.78,4.8),Vector2(10.22,4.8)],
		"to drone court":[Vector2(9.5,5.5),Vector2(13.8,5.5),Vector2(13.8,6.5)],
		"to west balcony":[Vector2(6.5,5.5),Vector2(6.5,10.7),Vector2(.5,10.7),Vector2(-4.8,10.7)],
		"to exit":[Vector2(6.5,5.5),Vector2(6.5,11.5)]}
	var shape:=CapsuleShape3D.new();shape.radius=.24;shape.height=1.7
	observations.routes={}
	for name in routes:
		var blocked:Array=[];var unsupported:Array=[];var count:=0;var points:Array=routes[name]
		for i in range(points.size()-1):
			var a:Vector2=points[i];var b:Vector2=points[i+1];var steps:=ceili(a.distance_to(b)/.12)
			for j in range(steps+1):
				var xy:=a.lerp(b,float(j)/maxi(steps,1));var p:=at(Vector3(xy.x,0,xy.y));count+=1
				if floor_at(p).is_empty():unsupported.append([xy.x,xy.y])
				var q:=PhysicsShapeQueryParameters3D.new();q.shape=shape;q.collision_mask=1;q.transform.origin=p+Vector3.UP*.9
				var hits:=hall.get_world_3d().direct_space_state.intersect_shape(q)
				if not hits.is_empty():blocked.append({"at":[xy.x,xy.y],"body":str(hits[0].collider.get_path())})
		check(name+": floor",unsupported.is_empty());check(name+": clearance",blocked.is_empty())
		observations.routes[name]={"samples":count,"unsupported":unsupported,"blocked":blocked}
	check("Point and pause are at reachable heights",h.point.global_position.y-origin.y>1 and h.point.global_position.y-origin.y<1.3 and h.pause_button.global_position.y-origin.y>1)
	check("Existing slider panel is above its solid table",h.flock._control_panel.global_position.y-origin.y>1.1)
	# At visitor height, the same pickup/action methods used by desktop input.
	camera.global_position=h.to_global(Vector3(0,1.7,1.6));camera.look_at(h.to_global(Vector3(0,1.4,0)))
	var pointer:=Node3D.new();root.add_child(pointer)
	h.point.on_desktop_grab(pointer);await create_timer(.15).timeout
	h.point.action();await create_timer(.15).timeout
	check("Held point trigger pauses the live model",not h.playing)
	var kept:=agent_state(h.flock)
	h.point.global_position=h.to_global(h.HOME+Vector3(-.4,0,0));await create_timer(.2).timeout
	var small:int=h.reading.neighbours.size();var small_radius:float=h.flock.perception_radius
	await snapshot("narrow",h.to_global(Vector3(.1,2.15,1.8)),h.to_global(Vector3(0,1.35,.1)),65)
	h.point.global_position=h.to_global(h.HOME+Vector3(.4,0,0));await create_timer(.2).timeout
	var large:int=h.reading.neighbours.size()
	check("Held point spans the original radius range",small_radius==.05 and h.flock.perception_radius==.5)
	check("Widening includes more neighbours in the same frozen scatter",large>small and agent_state(h.flock)==kept)
	check("Visible links equal the reported neighbourhood",h.links.multimesh.visible_instance_count==large)
	check("The radius rings are centred on the highlighted body",h.rings.all(func(r):return r.position==h.flock._boids[0].position and r.scale.is_equal_approx(Vector3.ONE*.5)))
	await snapshot("wide",h.to_global(Vector3(.1,2.15,1.8)),h.to_global(Vector3(0,1.35,.1)),65)
	var arrow_ok:=true;var vectors:Array=h.reading.parts.duplicate();vectors.append(h.reading.sum)
	for i in range(4):
		var v:Vector3=vectors[i]
		if v.length()>.0001:arrow_ok=arrow_ok and h.shafts[i].basis.y.normalized().dot(v.normalized())>.999
	check("Solid arrows point along the current requests",arrow_ok)
	h.flock._sep_slider.set_normalized_value(0);h.flock._sep_slider.slider_moved.emit(Vector3.ZERO);await create_timer(.1).timeout
	check("Original SEP slider removes only its preview request while paused",h.reading.parts[0]==Vector3.ZERO and not h.shafts[0].visible and agent_state(h.flock)==kept)
	await snapshot("separation-off",h.to_global(Vector3(.1,2.15,1.8)),h.to_global(Vector3(0,1.35,.1)),65)
	h.flock.separation_weight=1.5;h.point.on_desktop_drop(pointer);await create_timer(1.7).timeout
	check("Drop docks the same point and keeps radius and pause",h.point.position.distance_to(h.HOME)<.01 and h.flock.perception_radius==.5 and not h.playing)
	h.pause_button.pressed.emit();await create_timer(.5).timeout
	check("Nearby button resumes the same flock",h.playing and agent_state(h.flock)!=kept and h.flock._boids.size()==30)
	await snapshot("hand-controls",h.to_global(Vector3(-.4,1.75,1.7)),h.to_global(Vector3(0,1.1,.55)),68)
	observations.radius_comparison={"small":small,"large":large,"positions_and_velocities_kept":true}
	observations.headset_tested=false;pointer.queue_free()
