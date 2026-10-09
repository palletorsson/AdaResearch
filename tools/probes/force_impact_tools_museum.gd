extends "res://tools/probes/forces_layout.gd"

func landing_checks() -> void:
	await super.landing_checks()
	camera.set_cull_mask_value(19,false)
	var wardrobe: Node=museum.get("_wardrobe")
	if wardrobe!=null and is_instance_valid(wardrobe.get("costume")):wardrobe.get("costume").visible=false
	var bowling: Node3D
	for n in hall.find_children("*","Node3D",true,false):
		if n.get_script()!=null and str(n.get_script().resource_path).ends_with("/encounter.gd") and n.kind=="bowling":bowling=n;break
	var bag=find_scene("/punching_bag.gd")
	check("Club and punching bag are in the existing impulse hall",bowling!=null and bag!=null)
	if bowling==null or bag==null:return
	var rack=bowling.get_node("ImpactClubRack")
	check("Club sits beside the original bowling ball",rack.stick!=null and bowling.members.ball!=null)
	await snapshot("club-beside-bowling",bowling.to_global(Vector3(5.1,1.85,-12.0)),bowling.to_global(Vector3(2.5,1.2,-8.6)),67)
	await snapshot("hanging-bag",bag.to_global(Vector3(4.0,2.0,-5.1)),bag.to_global(Vector3(0.3,1.8,0)),64)
	var origin=XROrigin3D.new();origin.current=true;root.add_child(origin)
	var controller=XRController3D.new();origin.add_child(controller)
	var hand=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();controller.add_child(hand)
	bowling.reset();await create_timer(0.2).timeout
	var club=rack.stick;var ball: RigidBody3D=bowling.members.ball
	controller.global_transform=Transform3D(bowling.global_basis,bowling.to_global(Vector3(-0.60,0.44,-9.5)))
	club.global_transform=controller.global_transform;club.pick_up(hand)
	var peak=0.0;var initial=ball.global_position
	for i in range(100):
		controller.global_position=bowling.to_global(Vector3(-0.60,0.44,-9.5+0.018*(i+1)))
		await physics_frame;peak=maxf(peak,ball.linear_velocity.length())
	check("Held club contacts the production bowling sphere",peak>0.5 and ball.global_position.distance_to(initial)>0.4)
	await snapshot("club-sends-the-point",bowling.to_global(Vector3(-3.7,1.55,-11.8)),ball.global_position+Vector3(0,0.2,0.8),65)
	club.let_go(hand,Vector3.ZERO,Vector3.ZERO);await create_timer(0.2).timeout;rack.return_stick()
	controller.global_transform=Transform3D(bag.global_basis,bag.to_global(Vector3(0,1.55,-1.3)))
	bag._scan_hands();await create_timer(0.15).timeout
	var speed=0.0;var anchor_error=0.0
	for i in range(50):
		controller.global_position=bag.to_global(Vector3(0,1.55,-1.3+0.024*(i+1)))
		await physics_frame
		speed=maxf(speed,bag.bag.linear_velocity.length())
		anchor_error=maxf(anchor_error,bag.bag.to_global(bag.bag_anchor).distance_to(bag.to_global(bag.anchor_point)))
	check("Tracked hand strikes the production hanging bag",speed>0.25)
	check("The production bag stays at its suspension joint",anchor_error<0.08)
	await snapshot("after-the-punch",bag.to_global(Vector3(-1.2,1.7,-2.6)),bag.bag.global_position+Vector3.UP*0.2,67)
	origin.queue_free();await create_timer(0.1).timeout
	observations.impacts={"bowling_ball_speed":peak,"bag_speed":speed,"bag_joint_error":anchor_error}
