extends "res://tools/probes/account_hand_before.gd"
func landing_checks()->void:
	await super.landing_checks()
	var h=study.hand_account
	check("Portable account installed",h!=null)
	if h==null:return
	check("Exact exportable printed host remains the base",study.get_script().get_base_script().resource_path.ends_with("/population_account_walk/study.gd"))
	check("Control grip uses same PointBody",h.point.get_script()==study.points.values()[0].get_script())
	check("Grip is outside55 initial organisms",study.points.size()==55 and not study.points.values().has(h.point))
	check("Same 51cm bodies with matching grab shapes",is_equal_approx(study.points.values()[0].get_child(1).shape.radius,.255))
	var routes={"through field":[Vector2(0,7.7),Vector2(0,-7.7)],"take account":[Vector2(0,7.7),Vector2(-.7,7.7)],"far control bank":[Vector2(0,-7.7),Vector2(3.1,-7.7)]}
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
	check("Four buttons follow tilted panel",h.buttons.all(func(b):return is_equal_approx(b.global_basis.y.dot(Vector3.UP),cos(deg_to_rad(25)))))
	check("Initial account displays50prey5predators and zero gaps",h.cells[0].text=="50" and h.cells[1].text=="5" and h.cells[12].text=="0" and h.cells[13].text=="0")
	await snapshot("dock",study.to_global(Vector3(-.45,1.9,7.9)),study.to_global(Vector3(-.7,1.3,6.6)),75)
	var before=state_record()
	for i in range(120):h._process(.01)
	check("Repeated panel reads leave bodies, records and RNG unchanged",state_record()==before)
	var pointer:=Node3D.new();root.add_child(pointer)
	h.point.on_desktop_grab(pointer);await create_timer(.1).timeout
	var carried_at:Vector3=study.to_global(Vector3(2.5,1.1,2.5));h.point.global_position=carried_at;await create_timer(.1).timeout
	check("Carried account is not a held organism",not study.any_held() and study.model.tick==0)
	h.point.action();await create_timer(.15).timeout
	check("Grip trigger advances existing ecosystem",study.playing and study.model.tick>0)
	h.point.action();var kept:int=study.model.tick;await create_timer(.1).timeout
	check("Second trigger pauses without restart",not study.playing and study.model.tick==kept)
	h.buttons[2].pressed.emit();await create_timer(.1).timeout
	check("Remote restart clears account with organisms",study.model.tick==0 and study.points.size()==55 and study.account.events.is_empty() and study.show_supply)
	var body=study.model.prey_list[0];var id:int=body.get_instance_id();var p=study.points[id]
	p.on_desktop_grab(pointer);await create_timer(.1).timeout;p.action();p.global_position=study.to_global(Vector3(1.8,1.4,0));await create_timer(.15).timeout
	check("Holding point selects initial arrival on account",study.witness==id and "PREY / INITIAL" in h.selected_words.text and "HELD" in h.state_words.text)
	check("Hand relocation keeps identity/history and correct model coordinate",body.position.distance_to(study.record(study.to_local(p.global_position)))<.001 and study.account.events.is_empty() and body.get_meta("arrival")=="initial")
	h.buttons[1].pressed.emit();h.buttons[2].pressed.emit()
	check("Holding organism blocks step and restart",study.model.tick==0 and study.points[id]==p)
	p.on_desktop_drop(pointer);await create_timer(.1).timeout;h.buttons[1].pressed.emit();await create_timer(.1).timeout
	check("Release steps same organism and account still balances",study.model.tick==1 and study.points[id]==p and full_account_matches())
	# Replay real ecology for30 model seconds; do not create presentation-only arrivals.
	study.restart()
	var first_supply:=0
	for i in range(1800):
		study.model.advance(study.PERIOD)
		if first_supply==0 and study.account.total("prey","supplied")>0:first_supply=study.model.tick
		if i%60==0:await tick()
	study.paint();await tick();await create_timer(.1).timeout
	check("Natural run records losses and supplied arrivals",study.account.total("prey","loss")>0 and study.account.total("prey","supplied")>0)
	check("Full account reconciles both actual populations",full_account_matches() and h.cells[12].text=="0" and h.cells[13].text=="0")
	var supplied:Array=study.bodies().filter(func(b):return b.get_meta("arrival")=="supplied")
	check("Natural supplied bodies survive for inspection",not supplied.is_empty())
	observations.first_supply_tick=first_supply;observations.model_seconds=30;observations.live_supplied=supplied.size()
	observations.cumulative_supplied=study.account.total("prey","supplied")+study.account.total("predator","supplied")
	if supplied.is_empty():return
	body=supplied[0];id=body.get_instance_id();p=study.points[id]
	p.on_desktop_grab(pointer);await create_timer(.1).timeout;p.action();p.global_position=study.to_global(Vector3(3.25,1.1,1.7));await create_timer(.15).timeout
	check("Selected naturally supplied body keeps its gold ring",p.get_child_count()>=3 and "SUPPLIED" in h.selected_words.text)
	check("Selected health is read from the actual organism",h.selected_words.text.ends_with("health %.2f"%body.health))
	var history=study.account.events.duplicate(true);var ids=study.points.keys();var positions=study.bodies().map(func(b):return b.position)
	await pad_photo("full-account",h)
	h.buttons[3].pressed.emit();await create_timer(.1).timeout
	check("Filtering is available while organism is held",not study.show_supply and "SUPPLY OMITTED / bodies remain" in h.state_words.text)
	check("Filtering preserves exact event history and live identities",study.account.events==history and study.points.keys()==ids and study.bodies().map(func(b):return b.position)==positions)
	var displayed:=true
	for col in range(2):
		var species:String=["prey","predator"][col];var actual:int=study.model.prey_list.size() if col==0 else study.model.predator_list.size()
		displayed=displayed and h.cells[6+col].text=="omitted" and h.cells[8+col].text==str(study.account.expected(species,false)) and h.cells[10+col].text==str(actual) and h.cells[12+col].text==str(study.account.total(species,"supplied"))
	check("Omitted-row gap equals cumulative supply for each species",displayed)
	check("Omitting row leaves gold ring visible",p.get_child_count()>=3 and p.visible)
	await pad_photo("omitted-account",h)
	await snapshot("support-in-room",study.to_global(Vector3(5.8,5.5,5.9)),study.to_global(Vector3(0,.8,0)),78)
	study.get_node("Record-1").pressed.emit();await create_timer(.1).timeout
	check("Original bank restores full portable account",study.show_supply and h.cells[12].text=="0" and h.cells[13].text=="0" and h.buttons[3].is_selected())
	check("Restore also leaves all event records intact",study.account.events==history)
	p.on_desktop_drop(pointer);await create_timer(.1).timeout
	study.get_node("Run1").pressed.emit();await create_timer(.1).timeout
	check("Original Run is visible on portable control",study.playing and h.buttons[0].is_selected())
	h.buttons[0].pressed.emit();check("Portable Run pauses original-bank playback",not study.playing)
	h.buttons[2].pressed.emit();await create_timer(.1).timeout
	check("Restart restores baseline and full record display",study.model.tick==0 and study.account.events.is_empty() and study.points.size()==55 and h.cells[0].text=="50" and h.cells[12].text=="0" and study.show_supply)
	h.point.on_desktop_drop(pointer);await create_timer(2).timeout
	check("Released account remains nearby briefly",h.point.global_position.distance_to(carried_at)<.001)
	h.point.on_desktop_grab(pointer);await create_timer(5.1).timeout
	check("Regrab cancels return",h.point.global_position.distance_to(carried_at)<.001)
	h.point.on_desktop_drop(pointer);await create_timer(5.2).timeout
	check("Dropped account docks after five seconds",h.point.position.distance_to(h.DOCK)<.001 and h.point.rotation.is_zero_approx())
	var xr:=XROrigin3D.new();root.add_child(xr);var hand:=XRController3D.new();xr.add_child(hand)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();hand.add_child(pickup)
	hand.global_position=h.point.global_position;h.point.pick_up(pickup);await tick()
	check("Actual XRTools near-grab attaches account",h.point.is_picked_up())
	hand.global_position+=Vector3(.3,.15,0);await tick()
	check("XR hand moves same control body",h.point.position.distance_to(h.DOCK)>.2)
	h.point.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await tick()
	check("XR release keeps account available",not h.point.held())
	observations.headset_tested=false;observations.production_lesson_unchanged=true;pointer.queue_free();xr.queue_free()
func pad_photo(name:String,h:Node3D)->void:
	await snapshot(name,h.point.to_global(Vector3(.02,.8,.5)),h.panel.to_global(Vector3(0,.07,-.54)),74)
func full_account_matches()->bool:
	return study.account.expected("prey")==study.model.prey_list.size() and study.account.expected("predator")==study.model.predator_list.size()
func state_record()->Dictionary:
	return {"events":study.account.events.duplicate(true),"tick":study.model.tick,"rng":study.model._rng.state,"bodies":study.bodies().map(func(b):return [b.get_instance_id(),b.position,b.velocity,b.health]),"food":study.model.food_list.map(func(f):return f.position)}
