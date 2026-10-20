extends "res://tools/probes/sampling_room.gd"
func vertices(vessel:Node3D)->PackedVector3Array:return vessel._mi.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
func faces(vessel:Node3D)->PackedInt32Array:return vessel._mi.mesh.surface_get_arrays(0)[Mesh.ARRAY_INDEX]
func same_recipe(a:Node,b:Node)->bool:
	return a.radius==b.radius and a.rings==b.rings and a.segments==b.segments and a.stiffness==b.stiffness and a.damping==b.damping and a.pin_top_fraction==b.pin_top_fraction and a.preinflate==b.preinflate and a.gravity_y==b.gravity_y
func landing_checks()->void:
	museum.call("flush_stamps");await create_timer(1).timeout
	var stream=museum.get("_portal_stream")
	if stream!=null:stream.set_process(false);stream.set_physics_process(false)
	var player=museum.get("_player")
	if player is Node3D:player.hide();player.set_process(false);player.set_physics_process(false);player.global_position=Vector3(0,-100,0)
	camera.set_cull_mask_value(19,false)
	var attributes:=CameraAttributesPractical.new();attributes.exposure_multiplier=.28;camera.attributes=attributes
	var desk=find_scene("/timing_machines/soft_workshop.gd")
	map_origin=desk.global_position-hall.global_basis*Vector3(11.5,0,5.5)
	var stations:Dictionary={}
	for node in hall.find_children("*","Node3D",true,false):
		if node.get_script()!=null and str(node.get_script().resource_path).ends_with("soft_snapshot_gallery.gd"):stations[node.study]=node
	check("Three permanent registered stations loaded",stations.size()==3)
	if stations.size()!=3:return
	check("Original primary exhibits still bind",desk.ready_for_input and desk.model!=null and desk.other!=null)
	var time=stations.time;var gravity=stations.gravity;var skin=stations.skin
	check("Time row has four different stops including initial sphere",time.sample_steps==[0,10,40,200] and time.specimens.size()==4)
	check("Time specimens retain one recipe and connectivity",time.specimens.all(func(v):return same_recipe(v,time.specimens[0]) and is_zero_approx(v.gravity_x) and faces(v)==faces(time.specimens[0])))
	check("Different stops actually make different positions",vertices(time.specimens[0])!=vertices(time.specimens[2]) and vertices(time.specimens[2])!=vertices(time.specimens[3]))
	check("Force row has opposite pulls at one stop",gravity.gravity_values==[-2.0,0.0,2.0] and gravity.sample_steps==[200,200,200])
	check("Force changes geometry while preserving construction",gravity.specimens.all(func(v):return same_recipe(v,gravity.specimens[0]) and faces(v)==faces(gravity.specimens[0])) and vertices(gravity.specimens[0])!=vertices(gravity.specimens[1]))
	check("Skin and wire copies use identical saved vertices and faces",vertices(skin.specimens[0])==vertices(skin.specimens[1]) and faces(skin.specimens[0])==faces(skin.specimens[1]))
	var wire_count:int=skin.wires[1].multimesh.instance_count
	check("Triangle edges are batched solid cylinders",wire_count>500 and skin.wires[1].multimesh.mesh is CylinderMesh)
	var edge_points:PackedVector3Array=vertices(skin.specimens[1]);var endpoint_error:=0.0
	for i in wire_count:
		var transform:Transform3D=skin.wires[1].multimesh.get_instance_transform(i)
		for end in [-0.5,0.5]:
			var p:Vector3=transform.origin+transform.basis.y*end;var nearest:=INF
			for v in edge_points:nearest=minf(nearest,v.distance_to(p))
			endpoint_error=maxf(endpoint_error,nearest)
	check("Every cylinder endpoint lands on a saved vertex",endpoint_error<.00001)
	observations.wire_endpoint_error=endpoint_error
	observations.wire_edges=wire_count
	var total:=0
	for station in stations.values():
		total+=station.specimens.size()
		check("Every "+station.study+" specimen retains contact skin",station.specimens.all(func(v):return v._mi.get_node_or_null("FrozenSkin/Surface")!=null))
		check("Every "+station.study+" shape sits on its plinth",station.specimens.all(func(v):return is_equal_approx(v.position.y+v._mi.position.y+v._mi.mesh.get_aabb().position.y,.42)))
	check("Nine added sculptures in the existing room",total==9)
	await snapshot("above",map_at(Vector3(15,54,8)),map_at(Vector3(15,0,18)),62)
	await snapshot("arrival",map_at(Vector3(15.5,1.65,1)),map_at(Vector3(15.5,1.5,21)),65)
	await snapshot("time-row",time.to_global(Vector3(6.4,3.2,7.2)),time.to_global(Vector3(0,1.4,0)),57)
	await snapshot("gravity-row",gravity.to_global(Vector3(4.8,2.8,6)),gravity.to_global(Vector3(0,1.5,0)),57)
	await snapshot("skin-and-edges",skin.to_global(Vector3(3.2,2.5,5.4)),skin.to_global(Vector3(0,1.4,0)),53)
	var driver=load("res://commons/testing/wcn_desktop_driver.gd").new();museum.add_child(driver)
	observations.controls=[]
	for station in stations.values():
		var approach:Vector3=station.to_global(Vector3(0,.01,3.4))
		check(station.study+" approach has support and clearance",hits(approach).is_empty() and not floor_at(approach).is_empty())
		driver.spawn(approach,museum);await create_timer(.1).timeout
		for id in ["CHANGE","RESET"]:
			var before:int=station.builds
			var result:Dictionary=await driver.press(station.buttons[id],approach);await create_timer(.1).timeout
			var effect:bool=station.builds>before if station.study!="skin" else station.variant==(1 if id=="CHANGE" else 0)
			check(station.study+" real pointer "+id,effect and str(result.get("hover","")) not in ["","none","null","nothing"])
			observations.controls.append({"study":station.study,"id":id,"pointer":result,"effect":effect})
		check(station.study+" rebuild leaves only current specimen set",station.display.get_children().filter(func(c):return c.get_script()!=null and str(c.get_script().resource_path).ends_with("frozen_glass_vessel.gd")).size()==station.specimens.size())
		await driver.teardown();await tick()
	driver.queue_free()
	var saved:PackedVector3Array=vertices(skin.specimens[1]).duplicate();var rid:RID=skin.specimens[1]._mi.get_node("FrozenSkin").get_rid()
	skin.act("CHANGE");skin.act("CHANGE")
	check("Wire-only view retains exact geometry and contact body",not skin.specimens[1]._mi.visible and skin.wires[1].visible and vertices(skin.specimens[1])==saved and skin.specimens[1]._mi.get_node("FrozenSkin").get_rid()==rid)
	await snapshot("edges-only",skin.to_global(Vector3(3.2,2.5,5.4)),skin.to_global(Vector3(0,1.4,0)),53)
	skin.act("RESET")
	var origin:=XROrigin3D.new();root.add_child(origin);var hand:=XRController3D.new();origin.add_child(hand)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();hand.add_child(pickup)
	hand.global_position=gravity.point.global_position;gravity.point.pick_up(pickup);await tick();await tick()
	var old:int=gravity.builds
	hand.global_position=gravity.to_global(gravity.home+Vector3(.75,0,0));await tick();await tick()
	check("Held point previews lateral pull without repeated reconstruction",is_equal_approx(gravity.pull,3.0) and gravity.builds==old and gravity.point.is_picked_up())
	gravity.point.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await tick();await tick()
	check("Hand release reconstructs opposite pulls once",gravity.gravity_values==[-3.0,0.0,3.0] and gravity.builds==old+1 and gravity.point.position.is_equal_approx(gravity.home))
	await snapshot("hand-pull",gravity.to_global(Vector3(4.8,2.8,6)),gravity.to_global(Vector3(0,1.5,0)),57)
	gravity.act("RESET")
	for station in [time,skin]:
		hand.global_position=station.point.global_position;station.point.pick_up(pickup);await tick();station.point.action();await tick()
		check(station.study+" inherited point trigger changes example",station.variant==1)
		station.point.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await tick();station.act("RESET")
	origin.queue_free();await tick()
	var route:=[Vector3(15.5,0,.5),Vector3(15.5,0,4.5),Vector3(27,0,4.5),Vector3(27,0,46.5),Vector3(15.5,0,46.5),Vector3(15.5,0,47.5)]
	var blocked:Array=[];var gaps:Array=[];var samples:=0
	for j in range(route.size()-1):
		var a:Vector3=route[j];var b:Vector3=route[j+1];var steps:=ceili(a.distance_to(b)/.25)
		for k in steps+1:
			var p:Vector3=a.lerp(b,float(k)/steps);var at:=map_at(p+Vector3.UP*.01);samples+=1
			if not hits(at).is_empty():blocked.append({"at":xyz(p),"colliders":hits(at)})
			if floor_at(at).is_empty():gaps.append(xyz(p))
	observations.route={"samples":samples,"blocked":blocked,"gaps":gaps}
	check("Added exhibits preserve outer route clearance",blocked.is_empty())
	check("Outer route remains supported",gaps.is_empty())
	observations.scope="Real museum and desktop pointer; synthetic XRTools hand input. No physical headset or Quest performance claim."
	completed=true
