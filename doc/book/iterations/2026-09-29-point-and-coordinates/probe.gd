extends "res://tools/probes/transformation_encounters.gd"

class SuppliedGrabber extends Node3D:
	var picked_up_ranged := false

func landing_checks() -> void:
	museum.flush_stamps()
	await create_timer(2.5).timeout
	if map_id == "Point_One": await point_checks()
	else: await coordinate_checks()

func stations() -> Dictionary:
	var found := {}
	for n in hall.find_children("*","Node3D",true,false):
		if n.get_script() != null and str(n.get_script().resource_path).ends_with("/point_condition.gd"):found[n.condition]=n
	return found

func point_checks() -> void:
	var points := stations()
	check("appearance hall has absent, visible, solid and pedestal",points.size()==4 and points.has("absent") and points.has("visible") and points.has("solid") and points.has("pedestal"))
	check("held point belongs to next hall",not points.has("held"))
	var switch := find_scene("/point_sun_switch.gd")
	check("wall switch placed",switch!=null)
	if switch == null or points.size()!=4: return
	check("sun uses existing museum floor without added plates",not switch.receivers.is_empty() and switch.receivers.all(func(mesh):return mesh.get_parent()==hall) and switch.find_children("ShadowReceiver_*","MeshInstance3D",true,false).is_empty())
	check("sun casts directional shadows",switch.sun is DirectionalLight3D and switch.sun.shadow_enabled)
	check("sun lights floor but only study bodies cast its shadows",switch.sun.light_cull_mask==(switch.STUDY_LAYER | switch.FLOOR_LAYER) and switch.sun.shadow_caster_mask==switch.STUDY_LAYER)
	check("global lights neither light study bodies nor cast their shadows",switch._other_lights.all(func(item): return not is_instance_valid(item.node.get_ref()) or ((item.node.get_ref().light_cull_mask | item.node.get_ref().shadow_caster_mask) & switch.STUDY_LAYER)==0))
	check("empty station contains no sphere",points.absent.point==null)
	check("visible and solid sphere radii match",is_equal_approx(points.visible.point.mesh.radius,points.solid.point.mesh.radius))
	for kind in ["visible","solid"]:
		var p: Vector3 = points[kind].point.global_position
		var ray := PhysicsRayQueryParameters3D.create(p+Vector3(0,0,-0.4),p+Vector3(0,0,0.4),1)
		var hit := hall.get_world_3d().direct_space_state.intersect_ray(ray)
		check(kind+" has correct collision",hit.is_empty() if kind=="visible" else not hit.is_empty())
	var eye: Vector3 = points.visible.global_position + Vector3(1.45,1.55,-2.1)
	var target: Vector3 = points.visible.global_position+Vector3(0.3,0.5,0)
	await snapshot("sun-on",eye,target,67)
	var pointer := Node3D.new();root.add_child(pointer)
	var p: Vector3 = switch.button.global_position
	XRToolsPointerEvent.pressed(pointer,switch.button,p)
	await tick()
	check("pointer press removes sun",not switch.enabled and not switch.sun.visible)
	check("fill and sphere remain",switch.fill.visible and points.visible.point.visible)
	check("physical boundary remains with sun removed",points.solid.get_node("PointCollision").collision_layer==1)
	await snapshot("sun-off",eye,target,67)
	XRToolsPointerEvent.released(pointer,switch.button,p)
	XRToolsPointerEvent.pressed(pointer,switch.button,p)
	XRToolsPointerEvent.released(pointer,switch.button,p)
	await create_timer(0.2).timeout
	check("second pointer press restores sun",switch.enabled and switch.sun.visible)
	switch.button._on_button_entered(pointer)
	check("near-hand entry uses same switch",not switch.enabled)
	switch.button._on_button_exited(pointer)
	switch.set_sun_enabled(true)
	pointer.queue_free()
	var approach: Vector3 = switch.global_position + switch.global_basis.z * 0.6
	check("wall switch has supported approach",not floor_at(approach).is_empty())
	check("door retained",find_scene("/point_corridor_door.gd")!=null)
	await snapshot("wall-switch",switch.to_global(Vector3(0,1.6,1.1)),switch.to_global(Vector3(0,1.32,0)),46)
	await snapshot("point-corridor",points.absent.global_position+Vector3(1.0,1.65,-0.9),points.solid.global_position+Vector3(0,1.0,0),67)
	await snapshot("pedestal",points.pedestal.global_position+Vector3(1.5,1.65,-2.9),points.pedestal.global_position+Vector3(0,1.05,0),55)
	observations["switch_world"]=xyz(switch.global_position)
	# Unloading a streamed study must restore shared lights, not strand them.
	var tracked: Array = switch._other_lights.duplicate()
	var floors: Array = switch._floor_surfaces.duplicate()
	switch.queue_free();await process_frame
	check("unloading restores shared light and floor masks",tracked.all(func(item):return not is_instance_valid(item.node.get_ref()) or (item.node.get_ref().light_cull_mask==item.mask and item.node.get_ref().shadow_caster_mask==item.casters)) and floors.all(func(item):return not is_instance_valid(item.node.get_ref()) or item.node.get_ref().layers==item.layers))

func coordinate_checks() -> void:
	var points := stations()
	check("Coordinates starts with held point only",points.size()==1 and points.has("held"))
	if not points.has("held"):return
	var held: Node3D = points.held.point
	check("actual production pickable is retained",held.has_method("pick_up") and held.has_method("let_go"))
	var frame: Node3D
	var cards: Array = []
	for n in hall.find_children("*","Node3D",true,false):
		if "external_point_id" in n and str(n.get("external_point_id"))=="point_one_main":frame=n
		if "readout_channel" in n and str(n.get("readout_channel"))=="point_one_main" and n.has_method("show_coordinates"):cards.append(n)
	check("frame and both cards moved together",frame!=null and cards.size()==2)
	if frame==null:return
	check("frame follows the actual held point",frame._find_point()==held)
	check("origin is at hall floor level",absf(frame.global_position.y-hall.global_position.y)<0.02)
	var pool: Array = hall.get_meta("em_pool_cells",[])
	check("L basin has eleven cells",pool.size()==11)
	var floor_hit := floor_at(frame.global_position+Vector3(0.12,0.02,0.12))
	check("basin has collision at floor level",not floor_hit.is_empty() and absf(floor_hit.position.y-hall.global_position.y)<0.03)
	check("Point Zero sign not copied into coordinate frame",frame.get_node_or_null("OriginSign")==null)
	var grabber := SuppliedGrabber.new();root.add_child(grabber)
	var home: Transform3D = held.global_transform
	grabber.global_transform=home;held.pick_up(grabber)
	grabber.global_position+=Vector3(0.4,0.15,0.25)
	for i in range(12):await physics_frame
	check("supplied grab carries the point",held.is_picked_up() and held.global_position.distance_to(home.origin)>0.3)
	for card in cards:
		var q: Vector3 = held.global_position if card.space=="world" else frame.to_local(held.global_position)
		check(card.space+" reports the same moved point",card.get_node("Value").text=="x = %.2f\ny = %.2f\nz = %.2f" % [q.x,q.y,q.z])
	var target := find_scene("/drag_point_target.gd")
	check("target retained",target!=null)
	if target!=null:
		grabber.global_position=target.global_position+Vector3(0,target.catch_height,0)
		for i in range(12):await physics_frame
		check("held point still triggers target",target._inside and target._fired)
	held.let_go(grabber,Vector3.ZERO,Vector3.ZERO)
	check("point can be released",not held.is_picked_up())
	held.global_transform=home;grabber.queue_free();await tick()
	await snapshot("held-point",points.held.global_position+Vector3(0.6,1.65,-1.55),points.held.global_position+Vector3(0,1.05,0),55)
	await snapshot("coordinates-basin",frame.global_position+Vector3(4,1.65,-4),frame.global_position+Vector3(0,0.25,-1),66)
	await snapshot("coordinate-arrival",points.held.global_position+Vector3(1,1.65,-0.8),frame.global_position+Vector3(0,1,0),70)
	observations["frame"]=xyz(frame.global_position)
	observations["held"]=xyz(held.global_position)
	observations["pool_cells"]=pool

func finish() -> void:
	var result := {"room":map_id,"checks":checks,"failures":failures,"observations":observations,"passed":failures.is_empty(),"scope":"Real museum render; native pointer and area event routes, pickup, coordinates, collision, basin and lighting. No headset or learner acceptance claimed."}
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	print("POINT SPLIT ",map_id," ",checks.size()-failures.size(),"/",checks.size())
	quit(0 if failures.is_empty() else 1)
