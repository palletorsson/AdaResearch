extends "res://tools/probes/colony_hand_before.gd"
func landing_checks()->void:
	await super.landing_checks()
	var h=study.hand_control
	check("Portable control is installed beside the existing study",h!=null)
	if h==null:return
	var atlas:=find_scene("/ant_scale_atlas.gd")
	check("The existing three-model comparison atlas remains",atlas!=null and atlas.views.size()==3 and atlas.model.v2!=null)
	check("Control grip uses the same PointBody class",h.point.get_script()==study.points[0].get_script())
	check("Control grip is outside the colony's 24 records",study.points.size()==24 and not study.points.has(h.point))
	var routes={"centre passage":[Vector2(0,7.3),Vector2(0,-7.3)],"to hand control":[Vector2(0,7.3),Vector2(-1.2,7.3)],"into ant gallery":[Vector2(0,0),Vector2(-10,0),Vector2(-10,1.25),Vector2(-18,1.25)]}
	var shape:=CapsuleShape3D.new();shape.radius=.24;shape.height=1.7;observations.routes={}
	for name in routes:
		var blocked:Array=[];var unsupported:Array=[];var count:=0;var points:Array=routes[name]
		for i in range(points.size()-1):
			var a:Vector2=points[i];var b:Vector2=points[i+1];var steps:=ceili(a.distance_to(b)/.12)
			for j in range(steps+1):
				var xy:=a.lerp(b,float(j)/maxi(steps,1));var p:Vector3=study.to_global(Vector3(xy.x,0,xy.y));count+=1
				if floor_at(p).is_empty():unsupported.append([xy.x,xy.y])
				var q:=PhysicsShapeQueryParameters3D.new();q.shape=shape;q.collision_mask=1;q.transform.origin=p+Vector3.UP*.9
				var hits:=hall.get_world_3d().direct_space_state.intersect_shape(q)
				if not hits.is_empty():blocked.append({"at":[xy.x,xy.y],"body":str(hits[0].collider.get_path())})
		check(name+": floor",unsupported.is_empty());check(name+": clearance",blocked.is_empty())
		observations.routes[name]={"samples":count,"unsupported":unsupported,"blocked":blocked}
	check("Pad buttons face upward at the dock",h.buttons.all(func(b):return b.global_basis.y.dot(Vector3.UP)>.999))
	await snapshot("dock",study.to_global(Vector3(-1.1,1.8,7.35)),study.to_global(Vector3(-1.2,1.2,6.15)),68)
	var pointer:=Node3D.new();root.add_child(pointer)
	study.restart();h.point.on_desktop_grab(pointer);await create_timer(.1).timeout
	var held_at:Vector3=study.to_global(Vector3(3.9,1.16,1.35))
	h.point.global_position=held_at;await create_timer(.1).timeout
	check("Carried remote reaches the field without changing model state",h.point.global_position.distance_to(held_at)<.001 and study.model.steps==0 and not study.any_held())
	h.point.action();await create_timer(.2).timeout
	check("Grip trigger runs the existing colony",study.playing and study.model.steps>0)
	h.point.action();var kept:int=study.model.steps;await create_timer(.2).timeout
	check("Second grip trigger pauses without resetting",not study.playing and study.model.steps==kept)
	h.buttons[3].pressed.emit();await create_timer(.1).timeout
	check("Remote Clear All resets both fields",study.model.steps==0 and study.model.home.count(0.0)==256 and study.model.food.count(0.0)==256)
	var selected=study.points[5];var identity:int=selected.get_instance_id()
	selected.on_desktop_grab(pointer);await create_timer(.1).timeout;selected.action()
	selected.global_position=study.to_global(study.place(study.Colony.FOOD));await create_timer(.15).timeout
	check("Selecting an agent changes the portable readout",study.witness==5 and "Point 5 / SEARCH" in h.state_words.text and "FOOD" in h.read_words.text and "HOME" in h.write_words.text)
	check("Readout names the held-agent pause","HELD" in h.state_words.text)
	h.buttons[1].pressed.emit();h.buttons[2].pressed.emit();h.buttons[3].pressed.emit()
	check("Portable controls preserve held-agent protections",study.model.steps==0 and study.model.positions[5].distance_to(study.Colony.FOOD)<.001)
	selected.on_desktop_drop(pointer);await create_timer(.15).timeout
	await pad_photo("search",h)
	h.buttons[1].pressed.emit();await create_timer(.15).timeout
	check("Portable One Tick switches the same sphere at food",study.model.steps==1 and study.model.carrying[5] and study.cargo[5].visible and selected.get_instance_id()==identity)
	check("Read and leave channels visibly reverse","HOME" in h.read_words.text and "FOOD" in h.write_words.text and "RETURN" in h.state_words.text)
	check("Channel colours match the actual floor legend",h.read_words.modulate==study.BLUE and h.write_words.modulate==study.ROSE)
	var expected:String="L %.2f   F %.2f   R %.2f"%[study.model.sense(5,study.Colony.TURN,true),study.model.sense(5,0,true),study.model.sense(5,-study.Colony.TURN,true)]
	check("Portable readings equal current model samples",h.samples.text==expected)
	await pad_photo("returning",h)
	selected.on_desktop_grab(pointer);await create_timer(.1).timeout
	selected.global_position=study.to_global(study.place(study.Colony.HOME));await create_timer(.15).timeout
	selected.on_desktop_drop(pointer);await create_timer(.15).timeout;h.buttons[1].pressed.emit();await create_timer(.1).timeout
	check("Home delivers once and switches the remote back",study.model.delivered==1 and not study.model.carrying[5] and "FOOD" in h.read_words.text)
	h.buttons[1].pressed.emit();check("Another tick cannot duplicate that delivery",study.model.delivered==1)
	study.restart()
	for i in range(260):study.single_step()
	var home=study.model.home.duplicate();var food=study.model.food.duplicate();var deliveries:int=study.model.delivered
	h.buttons[2].pressed.emit();await create_timer(.1).timeout
	check("Remote Replace keeps both exact fields and count",study.model.home==home and study.model.food==food and study.model.delivered==deliveries and study.model.steps==260 and study.model.carrying.count(false)==24)
	check("Original end control still operates the same model",not study.playing)
	study.get_node("Run-1").pressed.emit();await create_timer(.2).timeout
	check("Original Run is reflected on portable status",study.playing and study.model.steps>260 and h.buttons[0].is_selected())
	h.buttons[0].pressed.emit();check("Portable Run can pause original end control",not study.playing)
	h.point.on_desktop_drop(pointer);await create_timer(2).timeout
	check("Released pad stays available briefly",h.point.global_position.distance_to(held_at)<.001)
	h.point.on_desktop_grab(pointer);await create_timer(5.1).timeout
	check("Regrabbing cancels the return timer",h.point.global_position.distance_to(held_at)<.001)
	h.point.on_desktop_drop(pointer);await create_timer(5.2).timeout
	check("Dropped remote docks after five seconds",h.point.position.distance_to(h.DOCK)<.001 and h.point.rotation.is_zero_approx())
	var xr:=XROrigin3D.new();root.add_child(xr);var hand:=XRController3D.new();xr.add_child(hand)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();hand.add_child(pickup)
	hand.global_position=h.point.global_position;h.point.pick_up(pickup);await tick()
	check("Remote also attaches through real XRTools near-grab",h.point.is_picked_up())
	hand.global_position+=Vector3(.3,.15,0);await tick()
	check("XR hand moves the same control body",h.point.position.distance_to(h.DOCK)>.2)
	h.point.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await tick()
	check("XR release leaves the control available",not h.point.held())
	observations.headset_tested=false;observations.natural_deliveries=deliveries
	observations.production_lesson_unchanged=true;pointer.queue_free();xr.queue_free()
func pad_photo(name:String,h:Node3D)->void:
	await snapshot(name,h.point.to_global(Vector3(.02,.6,.5)),h.point.to_global(Vector3(0,.07,-.36)),72)
