extends "res://tools/probes/transformation_encounters.gd"

func landing_checks() -> void:
	root.size=Vector2i(1600,1050);museum.call("flush_stamps");await create_timer(0.5).timeout
	var jars:=find_scene("/ordinary_entropies/jar_states.gd")
	var ruin:=find_scene("/randomness_space/entropy_ruin_physics.gd")
	check("both revised installations present",jars!=null and ruin!=null)
	if jars==null or ruin==null:return
	jars.set_process(false);jars.restart();ruin.restore()
	observations.jar_world=xyz(jars.global_position);observations.ruin_world=xyz(ruin.global_position)
	var capsule:=CapsuleShape3D.new();capsule.radius=0.22;capsule.height=1.6
	for x in [-2.13,-0.71,0.71,2.13]:
		var approach:=jars.to_global(Vector3(x,0,1.25))
		var hit:=floor_at(approach)
		check("supported jar approach "+str(x),not hit.is_empty() and absf(hit.position.y-jars.global_position.y)<0.03)
		var query:=PhysicsShapeQueryParameters3D.new();query.shape=capsule;query.collision_mask=1
		query.transform=Transform3D(Basis.IDENTITY,approach+Vector3.UP*0.85)
		check("clear jar approach "+str(x),hall.get_world_3d().direct_space_state.intersect_shape(query).is_empty())
	# An orthographic inspection view keeps the shared support and all four starts visible.
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=7.1
	await snapshot("jars-plinth",jars.to_global(Vector3(0,2.9,4.5)),jars.to_global(Vector3(0,1.35,0)),65)
	camera.projection=Camera3D.PROJECTION_PERSPECTIVE
	await snapshot("jar-detail",jars.to_global(Vector3(-1.6,1.7,1.3)),jars.to_global(Vector3(-2.13,1.6,0)),62)
	check("four columns still stand before removal",[82,93,104,115].all(func(id):return ruin.pieces[id].body.position.y>3.0))
	await snapshot("ruin-intact",ruin.to_global(Vector3(-0.8,2.5,-6)),ruin.to_global(Vector3(0,1.6,0)),65)
	await snapshot("column-corrected",ruin.to_global(Vector3(-2.0,1.8,-1.9)),ruin.to_global(Vector3(-0.8,1.7,-0.1)),53)
	# Use the installed button rather than a replacement control.
	ruin.controls["ONE STONE"].pressed.emit()
	check("installed button selects one support",ruin.history.size()==1 and ruin.extracting>=0 and not ruin.running)
	var chosen: int=ruin.history[0];observations.selected_stone=chosen
	await create_timer(0.2).timeout
	await snapshot("ruin-pulling",ruin.to_global(Vector3(-0.8,2.5,-6)),ruin.to_global(Vector3(0,1.6,0)),65)
	await create_timer(3).timeout
	check("ONE STONE releases a dynamic stone",not ruin.pieces[chosen].body.freeze and ruin.extracting<0)
	check("one support has consequences for other bodies",ruin.pieces.filter(func(p):return p.body.position.distance_to(p.home.origin)>0.18).size()>1)
	await snapshot("ruin-fallen",ruin.to_global(Vector3(-0.8,2.5,-6)),ruin.to_global(Vector3(0,1.6,0)),65)
	ruin.controls["RESTORE"].pressed.emit();await create_timer(1.5).timeout
	check("installed RESTORE rebuilds standing columns",[82,93,104,115].all(func(id):return ruin.pieces[id].body.position.y>3.0))
	# Supplied XRTools hand: ownership, movement, release and reset guard.
	var rig:=XROrigin3D.new();var head:=XRCamera3D.new();head.name="Camera";rig.add_child(head)
	var hand:=XRController3D.new();hand.name="LeftHand";rig.add_child(hand)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();hand.add_child(pickup);root.add_child(rig)
	var stone: RigidBody3D=ruin.pieces[85].body
	hand.global_transform=stone.global_transform;await tick();stone.pick_up(pickup);await tick()
	check("XR hand can own a supporting drum",stone.is_picked_up())
	var start:=hand.global_position
	var target:=start+ruin.global_basis*Vector3(0,0,-1.1)
	for i in 45:
		hand.global_position=start.lerp(target,float(i+1)/45);await physics_frame
	await tick()
	check("support follows the supplied hand",stone.global_position.distance_to(target)<0.05)
	var held:=stone.global_position;ruin.restore()
	check("RESTORE never takes the stone from the hand",stone.is_picked_up() and stone.global_position.distance_to(held)<0.01)
	stone.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await create_timer(1.5).timeout
	check("XR release lets stone fall",not stone.freeze and not stone.is_picked_up() and stone.position.y<0.6)
	rig.queue_free();await tick()
	# Same guard for the existing desktop pickup protocol.
	var player:=CharacterBody3D.new();root.add_child(player)
	var eye:=Camera3D.new();player.add_child(eye);eye.global_position=ruin.to_global(Vector3(0,1.6,-2.2))
	var pointer=load("res://commons/scenes/em/em_desktop_pointer.gd").new();pointer.cam=eye;player.add_child(pointer)
	pointer.set_process(false);pointer.set_physics_process(false)
	pointer._grab_held(stone);var desktop_held:=stone.global_transform;ruin.restore()
	check("desktop hold also blocks RESTORE",stone.has_meta("capability_desktop_held") and stone.global_transform.is_equal_approx(desktop_held))
	pointer._drop_held();await tick()
	check("desktop release restores physics",not stone.freeze)
	player.queue_free();ruin.restore();await create_timer(1.5).timeout
	check("columns stand after both pickup modes",[82,93,104,115].all(func(id):return ruin.pieces[id].body.position.y>3.0))
	observations.scope="Native installed hall; geometry, button signals, supplied XRTools hand, desktop pickup and contact. Physical headset comfort and visitor interpretation remain untested."
