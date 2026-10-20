extends "res://tools/probes/pso_hand_before.gd"
func landing_checks()->void:
	await super.landing_checks()
	var h=study.hand_control
	check("Portable score panel installed",h!=null)
	if h==null:return
	check("Museum inherits exact exportable printed host",study.get_script().get_base_script().resource_path.ends_with("/particle_swarm_walk/study.gd"))
	check("Control grip uses carried PointBody",h.point.get_script()==study.points[0].get_script())
	check("24 candidates, control grip outside search",study.points.size()==24 and not study.points.has(h.point))
	check("Full-size 51cm spheres with matching grab shape",study.global_basis.get_scale().is_equal_approx(Vector3.ONE) and is_equal_approx(study.points[0].get_child(1).shape.radius,.255))
	check("Original optional comparisons retained",find_scene("/fitness_landscape_politics.gd")!=null and find_scene("/self_organization_principles.gd")!=null)
	var routes={"through field":[Vector2(0,7.3),Vector2(0,-10.8)],"take panel":[Vector2(0,7.7),Vector2(-.7,7.7)],"rear comparisons":[Vector2(0,-7.5),Vector2(-4,-7.5),Vector2(-4,-9)]}
	var shape:=CapsuleShape3D.new();shape.radius=.24;shape.height=1.7;observations.routes={}
	for name in routes:
		var blocked:Array=[];var unsupported:Array=[];var count:=0;var route:Array=routes[name]
		for i in range(route.size()-1):
			var a:Vector2=route[i];var b:Vector2=route[i+1];var steps:=ceili(a.distance_to(b)/.12)
			for j in range(steps+1):
				var xy:=a.lerp(b,float(j)/maxi(steps,1));var p:Vector3=study.to_global(Vector3(xy.x,0,xy.y));count+=1
				if floor_at(p).is_empty():unsupported.append([xy.x,xy.y])
				var q:=PhysicsShapeQueryParameters3D.new();q.shape=shape;q.collision_mask=1;q.transform.origin=p+Vector3.UP*.9
				var hits:=hall.get_world_3d().direct_space_state.intersect_shape(q)
				if not hits.is_empty():blocked.append({"at":[xy.x,xy.y],"body":str(hits[0].collider.get_path())})
		check(name+": floor",unsupported.is_empty());check(name+": clearance",blocked.is_empty())
		observations.routes[name]={"samples":count,"unsupported":unsupported,"blocked":blocked}
	check("All six buttons follow readable tilted panel",h.buttons.all(func(b):return is_equal_approx(b.global_basis.y.dot(Vector3.UP),cos(deg_to_rad(25)))))
	await snapshot("dock",study.to_global(Vector3(-.5,1.9,7.6)),study.to_global(Vector3(-.7,1.2,6.4)),75)
	# A second untouched instance proves the readout has no effect on simulation/RNG.
	study.change(0);study.restart()
	var reference=load("res://commons/artifacts/particle_swarm_walk/swarm.gd").new()
	var identical:=true
	for j in range(120):
		study.model.step();h._process(0);reference.step()
		identical=identical and study.model.positions==reference.positions and study.model.velocities==reference.velocities and study.model.best_positions==reference.best_positions and study.model.best_scores==reference.best_scores and study.model.random.state==reference.random.state
	check("Reading scores does not change 120 seeded iterations or RNG",identical)
	study.restart()
	var pointer:=Node3D.new();root.add_child(pointer)
	h.point.on_desktop_grab(pointer);await create_timer(.1).timeout
	var carried_at:Vector3=study.to_global(Vector3(4.6,1.1,-3.4));h.point.global_position=carried_at
	await create_timer(.1).timeout
	check("Control can be carried without becoming a held candidate",not study.any_held() and study.model.steps==0 and h.point.global_position.distance_to(carried_at)<.001)
	h.point.action();await create_timer(.25).timeout
	check("Control trigger runs the original model",study.playing and study.model.steps>=2)
	h.point.action();var kept:int=study.model.steps;await create_timer(.2).timeout
	check("Second trigger pauses and retains iteration",not study.playing and study.model.steps==kept)
	h.buttons[2].pressed.emit();await create_timer(.1).timeout
	check("Panel restart returns seeded initial records",study.model.steps==0 and study.model.best_positions==study.model.positions)
	var p=study.points[5];var identity:int=p.get_instance_id();var best:Vector2=study.model.best_positions[5];var score:float=study.model.best_scores[5]
	p.on_desktop_grab(pointer);await create_timer(.1).timeout;p.action();p.global_position=study.to_global(study.place(Vector2(6,6)));await create_timer(.15).timeout
	check("Held sphere selects same record on portable panel",study.witness==5 and "Point 5 / HELD" in h.state_words.text)
	check("Hand moves current position, not previous memory",study.model.positions[5].distance_to(Vector2(6,6))<.001 and study.model.best_positions[5]==best and study.model.best_scores[5]==score)
	check("Current displayed coordinate and score are exact to two decimals",h.current_words.text=="NOW (+6.00, +6.00)  score -72.00")
	check("Memory readout uses recorded location and score",h.personal_words.text=="MY BEST (%+.2f, %+.2f)  score %+.2f"%[best.x,best.y,score])
	h.buttons[1].pressed.emit();h.buttons[2].pressed.emit();h.buttons[4].pressed.emit();await create_timer(.1).timeout
	check("Hold blocks Step, Restart and objective change",study.model.steps==0 and study.model.objective==0 and study.model.positions[5].distance_to(Vector2(6,6))<.001)
	p.on_desktop_drop(pointer);await create_timer(.1).timeout
	await pad_photo("memory-kept",h)
	await snapshot("memory-in-room",study.to_global(Vector3(5.9,5.8,-4)),study.to_global(Vector3(1,.1,0)),78)
	h.buttons[1].pressed.emit();await create_timer(.1).timeout
	check("A worse candidate leaves its earlier best intact",study.model.steps==1 and study.model.best_positions[5]==best and study.model.best_scores[5]==score)
	check("Blue ring remains at the remembered coordinate",study.personal.position.distance_to(Vector3(best.x,.11,-best.y))<.001)
	p.on_desktop_grab(pointer);await create_timer(.1).timeout;p.global_position=study.to_global(study.place(Vector2.ZERO));await create_timer(.1).timeout
	p.on_desktop_drop(pointer);await create_timer(.1).timeout;h.buttons[1].pressed.emit();await create_timer(.1).timeout
	check("Release and Step evaluate the same hand-placed point",study.model.best_scores[5]==0 and study.model.best_positions[5].length()<.001 and p.get_instance_id()==identity)
	check("New best reaches group memory and gold ring",study.model.shared_score==0 and study.shared.position.distance_to(Vector3(0,.16,0))<.001)
	check("Portable memory colours match floor rings",h.personal_words.modulate==study.BLUE and h.shared_words.modulate==study.GOLD)
	check("Gold record is displayed from model",h.shared_words.text=="GROUP BEST (+0.00, +0.00)  score +0.00")
	await pad_photo("better-found",h)
	var positions=study.model.positions.duplicate();var velocities=study.model.velocities.duplicate();var step_count:int=study.model.steps;var rng:int=study.model.random.state
	h.buttons[4].pressed.emit();await create_timer(.1).timeout
	check("Remote Edge keeps current positions, velocities and iteration",study.model.objective==1 and study.model.positions==positions and study.model.velocities==velocities and study.model.steps==step_count)
	check("Objective switch starts new records without consuming randomness",study.model.best_positions==positions and study.model.best_scores[5]==study.model.score(positions[5]) and study.model.random.state==rng)
	check("Panel visibly selects new rule and explains larger wins",h.buttons[4].is_selected() and not h.buttons[3].is_selected() and "EDGE / larger wins" in h.state_words.text)
	check("Existing floor reflects new score",study.field.multimesh.get_instance_color(0).r>study.field.multimesh.get_instance_color(136).r)
	await pad_photo("rule-changed",h)
	for j in range(35):study.single_step()
	await snapshot("edge",study.to_global(Vector3(8,12,9)),study.to_global(Vector3(0,0,0)),66)
	h.buttons[5].pressed.emit();h.buttons[2].pressed.emit();await create_timer(.1).timeout
	check("Remote restart keeps RIDGE but resets iteration",study.model.objective==2 and study.model.steps==0 and "RIDGE" in h.state_words.text)
	for j in range(30):study.single_step()
	await snapshot("ridge",study.to_global(Vector3(8,12,9)),study.to_global(Vector3(0,0,0)),66)
	study.get_node("Center-1").pressed.emit();study.get_node("Run1").pressed.emit();await create_timer(.2).timeout
	check("Original banks still operate same portable status",study.model.objective==0 and study.playing and h.buttons[0].is_selected() and h.buttons[3].is_selected())
	h.buttons[0].pressed.emit();check("Portable run pauses original-bank playback",not study.playing)
	h.point.on_desktop_drop(pointer);await create_timer(2).timeout
	check("Dropped panel remains nearby briefly",h.point.global_position.distance_to(carried_at)<.001)
	h.point.on_desktop_grab(pointer);await create_timer(5.1).timeout
	check("Regrab prevents return",h.point.global_position.distance_to(carried_at)<.001)
	h.point.on_desktop_drop(pointer);await create_timer(5.2).timeout
	check("Dropped panel docks after five seconds",h.point.position.distance_to(h.DOCK)<.001 and h.point.rotation.is_zero_approx())
	var xr:=XROrigin3D.new();root.add_child(xr);var hand:=XRController3D.new();xr.add_child(hand)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();hand.add_child(pickup)
	hand.global_position=h.point.global_position;h.point.pick_up(pickup);await tick()
	check("Actual XRTools near-grab attaches panel",h.point.is_picked_up())
	hand.global_position+=Vector3(.3,.15,0);await tick()
	check("XR hand carries same panel body",h.point.position.distance_to(h.DOCK)>.2)
	h.point.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await tick()
	check("XR release leaves panel available",not h.point.held())
	observations.headset_tested=false;observations.production_lesson_unchanged=true
	pointer.queue_free();xr.queue_free()
func pad_photo(name:String,h:Node3D)->void:
	await snapshot(name,h.point.to_global(Vector3(.02,.72,.45)),h.panel.to_global(Vector3(0,.07,-.49)),74)
