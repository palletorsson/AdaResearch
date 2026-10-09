extends "res://tools/probes/forces_layout.gd"

func landing_checks() -> void:
	await super.landing_checks()
	camera.set_cull_mask_value(19,false)
	var wardrobe: Node=museum.get("_wardrobe")
	if wardrobe!=null and is_instance_valid(wardrobe.get("costume")):wardrobe.get("costume").visible=false
	var e=find_scene("/human_catapult.gd")
	check("Human catapult found in launch hall",e!=null)
	if e==null:return
	await snapshot("red-trajectory",e.to_global(Vector3(9,6,5)),e.to_global(Vector3(0,2,-5)),72)
	var walker: CharacterBody3D=museum.get("_player")
	var basket_local: Vector3=e.to_local(e._basket_world_pos())
	walker.global_position=e.to_global(Vector3(0,0.03,basket_local.z+2.5));walker.velocity=Vector3.ZERO
	var reached=false
	for i in range(240):
		var p=e.to_local(walker.global_position)
		var forward=e.global_basis*Vector3(0,0,-1.1)
		walker.velocity.x=forward.x;walker.velocity.z=forward.z
		walker.velocity.y=-0.1 if walker.is_on_floor() else walker.velocity.y-9.8/60
		walker.move_and_slide();await physics_frame
		if absf(p.z-basket_local.z)<0.15:reached=true;break
	walker.velocity=Vector3.ZERO
	observations.boarding={"player_local":xyz(e.to_local(walker.global_position)),"basket_local":xyz(basket_local),"collisions":[]}
	for i in range(walker.get_slide_collision_count()):
		var hit=walker.get_slide_collision(i)
		observations.boarding.collisions.append({"body":str(hit.get_collider().get_path()),"normal":xyz(hit.get_normal()),"position":xyz(e.to_local(hit.get_position())),"shape":hit.get_collider_shape()})
	observations.boarding.ramp={"pos":xyz(e.get_node("BoardingRamp").position),"rotation":xyz(e.get_node("BoardingRamp").rotation),"children":e.get_node("BoardingRamp").get_child_count()}
	print("BOARDING ",observations.boarding)
	check("Walk up the ramp and board without jumping or teleporting",reached and e._within_basket(walker))
	await snapshot("countdown",e.to_global(Vector3(2.6,1.85,4.7)),e._basket_world_pos()+Vector3.UP*1.1,77)
	var waited=0
	while e._launch_count==0 and waited<210:
		walker.velocity.y-=9.8/60;walker.move_and_slide();await physics_frame;waited+=1
	check("Boarding starts countdown and actually fires in museum",e._launch_count==1)
	if e._launch_count==0:return
	var start: Vector3=walker.global_position;var v: Vector3=e._shot_velocity;var peak=0.0;var miss=0.0
	for i in range(160):
		walker.velocity=e._flight_receiver.carry_velocity(walker,1.0/60,walker.velocity)
		walker.move_and_slide();e._flight_receiver.record_carry(walker);await physics_frame
		peak=maxf(peak,walker.global_position.y-start.y)
		if i<60:
			var t=float(i+1)/60
			miss=maxf(miss,walker.global_position.distance_to(start+v*t+Vector3.DOWN*4.9*t*t))
		if i==44:await snapshot("airborne",walker.global_position+Vector3.UP*1.6,walker.global_position+v.normalized()*12+Vector3.DOWN*2,82)
	var travelled: Vector3=e.global_basis.inverse()*(walker.global_position-start)
	check("Museum launch travels away over arm",travelled.z< -10 and peak>3)
	check("Museum first second agrees with red preview",miss<0.25)
	observations.catapult={"travel_local":xyz(travelled),"peak_rise":peak,"preview_error":miss,"yaw":e.global_rotation.y,"launches":e._launch_count}
	await snapshot("launch-and-landing",e.to_global(Vector3(7,5,4)),e.to_global(Vector3(0,2,-5)),74)
