extends "res://doc/book/iterations/2026-09-29-line-black-box/probe.gd"

const Router = preload("res://commons/interactables/artifact_reactions/router.gd")

func landing_checks() -> void:
	museum.flush_stamps()
	await create_timer(3.0).timeout
	var player: Node3D = museum.get("_player")
	if player != null:
		player.set_physics_process(false)
		player.global_position += Vector3.UP * 20
	var barrier := find_scene("/do_not_cross_barrier.gd")
	var reaction := Router.receiver(barrier)
	check("barrier has shared reaction", reaction != null)
	observations["barrier"] = str(barrier.get_path())
	await snapshot("barrier-before",barrier.to_global(Vector3(0,1.6,3.0)),barrier.to_global(Vector3(0,0.75,0)))
	var demo := find_scene("/line_demo.gd")
	demo.manager.create_connection(demo.get_node("SnapPoint1"),demo.get_node("SnapPoint2"))
	await tick()
	await tick()
	check("barrier root is hidden", not barrier.is_visible_in_tree())
	var live: Array = []
	for n in barrier.find_children("*","CollisionObject3D",true,false):
		if n.collision_layer != 0 or n.collision_mask != 0: live.append(str(n.get_path()))
	check("all barrier colliders disabled",live.is_empty())
	observations["remaining_barrier_colliders"]=live
	await snapshot("barrier-broken",barrier.to_global(Vector3(0,1.6,3.0)),barrier.to_global(Vector3(0,0.75,0)))
	if reaction: reaction.restore()
	demo.manager.break_connection(demo.get_node("SnapPoint1"),demo.get_node("SnapPoint2"))
	demo.manager.create_connection(demo.get_node("SnapPoint1"),demo.get_node("SnapPoint2"))
	await tick()
	check("reconnecting opens a restored barrier again",barrier.is_broken())
	player.global_position = barrier.global_position+Vector3(0,0.05,0)
	await tick()
	reaction._remaining = 0.01
	await create_timer(0.15).timeout
	check("barrier waits for layer-1 museum visitor",reaction.is_destroyed)
	player.global_position += Vector3.UP*20
	await create_timer(0.7).timeout
	check("barrier returns after visitor clears it",not reaction.is_destroyed)
	if reaction: reaction.restore()
	var laser := find_scene("/laser_measure.gd")
	laser.set_process(false)
	laser.lethal = false
	var pointer := Node3D.new()
	pointer.set_script(load("res://commons/scenes/DesktopInteractionPointer.gd"))
	root.add_child(pointer)
	pointer.set_process(false)
	pointer.set_physics_process(false)
	pointer._grab_held(laser.get_parent())
	check("desktop pickup recognised by laser",laser._reaction_is_wielded())
	var gallery := find_scene("/line_relations_gallery.gd")
	await snapshot("line-room",gallery.to_global(Vector3(-1,1.65,-6.0)),gallery.to_global(Vector3(1,1.25,3.0)),85)
	var rod: Node3D = gallery.lines[0]
	var rod_reaction := Router.receiver(rod)
	var surface: Node3D = rod_reaction.surfaces[0].body.get_ref()
	var centre: Vector3 = rod.to_global(Vector3(0.65,0,0))
	laser.raycast.global_transform = Transform3D(Basis.IDENTITY,centre+Vector3(0,0,0.4))
	laser.raycast.look_at(centre)
	await tick()
	laser.perform_measurement()
	observations["rod_ray"]={"collider":str(laser.raycast.get_collider()),"collider_path":str(laser.raycast.get_collider().get_path()) if laser.raycast.is_colliding() else "none","wanted":str(rod.get_path()),"surface":str(surface.get_path()),"centre":xyz(centre),"ray_origin":xyz(laser.raycast.global_position),"burns":laser.burns,"wielded":laser._reaction_is_wielded()}
	check("real laser ray hits a grabbable rod",Router.receiver(laser.raycast.get_collider())==rod_reaction)
	for i in range(40): laser.perform_measurement()
	check("held desktop beam destroys whole rod",rod_reaction.is_destroyed and not rod.is_visible_in_tree())
	await snapshot("rod-broken",gallery.to_global(Vector3(-8,1.65,-2.5)),rod.global_position)
	rod_reaction.restore()
	# Each of the twenty bodies keeps its production collider and receiver.
	# Isolate it spatially while testing the real ray, so neighbours cannot
	# legitimately intercept a shot meant for the next rod.
	for item in gallery.lines:
		var pose: Transform3D = item.global_transform
		item.global_transform = Transform3D(Basis.IDENTITY,Vector3(0,30,0))
		PhysicsServer3D.body_set_state(item.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,item.global_transform)
		laser.raycast.global_transform = Transform3D(Basis.IDENTITY,Vector3(0,30,0.5))
		await tick()
		for i in range(40):laser.perform_measurement()
		var receiver := Router.receiver(item)
		check("held ray breaks gallery rod: "+str(item.name),receiver.is_destroyed and not item.is_visible_in_tree())
		receiver.restore()
		item.global_transform = pose
		PhysicsServer3D.body_set_state(item.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,pose)
	pointer._drop_held()
	check("dropping laser clears wield state",not laser._reaction_is_wielded())
	laser.raycast.global_transform = Transform3D(Basis.IDENTITY,centre+Vector3(0,0,0.4))
	laser.raycast.look_at(centre)
	for i in range(42): laser.perform_measurement()
	check("parked laser cannot erase rod",not rod_reaction.is_destroyed)
	var grabber := SuppliedGrabber.new(); root.add_child(grabber)
	grabber.global_transform = laser.get_parent().global_transform
	laser.get_parent().pick_up(grabber)
	check("XR pickup still recognised",laser._reaction_is_wielded())
	for i in range(42): laser.perform_measurement()
	check("XR held ray destroys same study",rod_reaction.is_destroyed)
	laser.get_parent().let_go(grabber,Vector3.ZERO,Vector3.ZERO)
	rod_reaction.restore()
	grabber.queue_free()
	observations["reactions"]=get_nodes_in_group("artifact_reactions").size()
	observations["laser_world"]=xyz(laser.global_position)
	pointer.queue_free()
	await corridor_checks(player)
	await line_checks()

func corridor_checks(player: Node3D) -> void:
	var crosses: Array[Node3D] = []
	var pluses: Array[Node3D] = []
	for n in hall.find_children("*","Node3D",true,false):
		if n.get_script() == null: continue
		var path: String = n.get_script().resource_path
		if path.ends_with("/anamorphic_cross.gd"): crosses.append(n)
		if path.ends_with("/health_cross.gd"): pluses.append(n)
	crosses.sort_custom(func(a,b):return a.global_position.z<b.global_position.z)
	pluses.sort_custom(func(a,b):return a.global_position.z<b.global_position.z)
	check("three X and three + gates placed",crosses.size()==3 and pluses.size()==3)
	if crosses.size()!=3 or pluses.size()!=3:return
	await snapshot("corridor",crosses[0].global_position+Vector3(0.55,1.65,-2.3),pluses[2].global_position+Vector3(0,1.2,0),67)
	var gm := root.get_node("GameManager")
	var start_health: float = gm.get_health()
	gm.set_health(100.0)
	gm.set_process(false)
	var readings: Array = []
	for i in range(3):
		player.global_position = crosses[i].global_position+Vector3(0,0.02,0)
		await create_timer(0.2).timeout
		var hurt: float = gm.get_health()
		check("X %d damages actual museum Walker"%i,hurt<100)
		player.global_position = pluses[i].global_position+Vector3(0,0.02,0)
		await create_timer(0.2).timeout
		check("+ %d restores health"%i,gm.get_health()>hurt and pluses[i].is_spent())
		check("+ %d produces sound and burst"%i,pluses[i]._feedback.bursts==1 and pluses[i]._feedback.audio.stream.data.size()>1000)
		readings.append([hurt,gm.get_health()])
	observations["health_pairs"] = readings
	player.global_position += Vector3.UP*20
	gm.set_health(start_health)
	gm.set_process(true)

func finish() -> void:
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"observations":observations},"  "))
	quit(0 if failures.is_empty() else 1)
