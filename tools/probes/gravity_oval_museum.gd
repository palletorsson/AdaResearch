extends "res://tools/probes/forces_layout.gd"

func landing_checks() -> void:
	await super.landing_checks()
	camera.set_cull_mask_value(19, false)
	var wardrobe: Node = museum.get("_wardrobe")
	if wardrobe != null and is_instance_valid(wardrobe.get("costume")): wardrobe.get("costume").visible = false
	var e = find_scene("/gravity_oval.gd")
	check("Walk-in gravity oval loaded in Fields", e != null)
	if e == null: return
	await snapshot("whole-oval", e.to_global(Vector3(8, 5, -13)), e.to_global(Vector3(0, 5.5, 0)), 67)
	await snapshot("step-into-the-stream", e.to_global(Vector3(-5.5, 1.75, -5)), e.to_global(Vector3(-2.3, 4.5, 0)), 80)
	# The actual museum walking body traverses the field through its carry API.
	var body: CharacterBody3D = museum.get("_player")
	body.global_position = e.to_global(Vector3(-2.6, 0.2, -1.1))
	body.velocity = Vector3.ZERO
	var start_angle = atan2((e.to_local(body.global_position).y + 0.7 - 5.7)/4.5, e.to_local(body.global_position).x/2.8)
	var previous = start_angle
	var turns = 0.0
	var peak = 0.0
	var lowest_after = 99.0
	var top_capture = false
	var down_capture = false
	for i in range(1000):
		if e._point_inside(body.global_position):
			body.velocity = e.carry_velocity(body, 1.0/60, body.velocity)
			body.move_and_slide()
			e.record_carry(body)
		await physics_frame
		var p = e.to_local(body.global_position)
		var angle = atan2((p.y+0.7-5.7)/4.5,p.x/2.8)
		turns += wrapf(angle-previous,-PI,PI); previous=angle
		peak = maxf(peak,p.y)
		if i>450: lowest_after=minf(lowest_after,p.y)
		if p.y>8 and not top_capture:
			top_capture=true
			await snapshot("over-the-top", body.global_position+Vector3.UP*1.65, e.to_global(Vector3(2.5,5.2,0)), 85)
		if top_capture and p.x>1.8 and p.y<5.5 and not down_capture:
			down_capture=true
			await snapshot("coming-down", body.global_position+Vector3.UP*1.65, e.to_global(Vector3(0,1.3,0)), 82)
	check("Museum player rises above eight metres", peak>8)
	check("Museum player crosses, descends and starts another circuit", -turns>TAU*1.3 and lowest_after<2)
	check("The scene keeps all 24 bodies without recovery", e.bodies.size()==24 and e.recovered==0)
	observations.oval={"player_turns":-turns/TAU,"peak_height":peak,"return_height":lowest_after,"bodies":e.bodies.size(),"recoveries":e.recovered}
	await snapshot("floating-prefabs", e.to_global(Vector3(6,7,-6)), e.to_global(Vector3(0,5,0)), 85)
