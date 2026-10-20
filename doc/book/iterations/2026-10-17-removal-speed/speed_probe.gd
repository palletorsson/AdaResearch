extends "res://doc/book/iterations/2026-10-16-entropy-button-reach/control_probe.gd"

# Parent supplies the actual museum and hand-layer probe. Both maps take this branch.
func cabinet_controls() -> void:
	var arena=find_scene("/removal_arena.gd")
	check("arena installed",arena!=null)
	if arena==null:return
	arena.set_physics_process(false)
	check("faster default and readable rate",arena.speed_multiplier==3.0 and arena.readout.text.contains("3.0x"))
	check("threefold shorter warning and walking interval",is_equal_approx(arena.warning_seconds(),0.8/3.0) and is_equal_approx(arena.walk_spacing(),0.2))
	var panel: Node3D=arena.speed_buttons[0].get_parent()
	var normal:=panel.global_basis.z.normalized()
	await exercise(arena.speed_buttons[1],arena,"FASTER",normal)
	check("hand and ray raise speed twice",arena.speed_multiplier==6.0)
	await exercise(arena.speed_buttons[0],arena,"SLOWER",normal)
	check("hand and ray lower speed twice",arena.speed_multiplier==3.0)
	await exercise(panel.find_child("Btn_2",true,false),arena,"REPLAY",normal)
	await snapshot("speed-controls",panel.to_global(Vector3(0,0.24,0.90)),panel.global_position,50)
	await snapshot("arena-with-speed",arena.to_global(Vector3(-4,5,-arena.rows/2.0-4)),arena.to_global(Vector3(0,1,-1)),68)
	var orders: Array=[]
	var elapsed: Array=[]
	for speed in [1.0,8.0]:
		arena.set_speed(speed);arena.reset_arena();await tick()
		var began:=Time.get_ticks_msec()
		for i in 6:
			arena.request_removal()
			var rng_state: int=arena.remover._rng.state
			var timing_state: int=arena.timing_rng.state
			arena.request_removal()
			check("busy request uses neither generator "+str(speed)+"/"+str(i),arena.remover._rng.state==rng_state and arena.timing_rng.state==timing_state)
			await create_timer(arena.warning_seconds()+0.06).timeout
			check("one warning removes one support "+str(speed)+"/"+str(i),arena.get_state().removed==i+1 and arena.get_state().disabled_colliders==i+1)
		orders.append(arena.remover.removal_log.duplicate());elapsed.append((Time.get_ticks_msec()-began)/1000.0)
	check("speed leaves seeded tile order unchanged",orders[0]==orders[1])
	check("8x actually finishes faster",elapsed[1]<elapsed[0]*0.45)
	observations["pace_seconds_for_six"]=elapsed
	observations["order"]=orders[0]
	arena.set_speed(1);arena.reset_arena()
	arena.request_removal()
	var index: int=arena.remover.last_selected_index
	var selection_state: int=arena.remover._rng.state
	var timing_state: int=arena.timing_rng.state
	var wait: float=arena.wait_left
	arena.set_speed(8)
	check("mid-warning adjustment keeps the chosen tile and RNG states",arena.remover.last_selected_index==index and arena.remover._rng.state==selection_state and arena.timing_rng.state==timing_state)
	check("pending interval is scaled without another sample",is_equal_approx(arena.wait_left,wait/8))
	await create_timer(0.2).timeout
	check("current warning is not cut short by speed change",arena.remover.get_state().busy and arena.get_state().disabled_colliders==0)
	await create_timer(0.7).timeout
	check("original warning completes once",arena.get_state().removed==1)
	arena.request_removal();arena.reset_arena();await create_timer(0.2).timeout
	check("REPLAY cancels pending removal and retains chosen speed",arena.speed_multiplier==8 and arena.get_state().removed==0 and arena.get_state().disabled_colliders==0)
	arena.set_speed(100);check("upper rate bounded",arena.speed_multiplier==8)
	arena.set_speed(-1);check("lower rate bounded",arena.speed_multiplier==0.5)
	arena.set_speed(NAN);check("invalid rate ignored",arena.speed_multiplier==0.5)
	# Stationary visitor: the coil mode's seeded wait must also accelerate.
	if arena.tesla_coils:
		var counts: Array=[]
		var walker: Node3D=museum.get("_player")
		for speed in [1.0,8.0]:
			arena.set_speed(speed);arena.reset_arena()
			walker.global_position=arena.to_global(Vector3(0,0.05,0))
			arena.set_physics_process(true)
			await create_timer(3.0).timeout
			arena.set_physics_process(false);counts.append(arena.get_state().removed)
		check("standing coil strikes accelerate too",counts[1]>counts[0]+2)
		observations["standing_removals_in_three_seconds"]=counts
		walker.global_position=arena.to_global(Vector3(0,0.05,-arena.rows/2.0-2))
	arena.set_speed(3);arena.reset_arena();await tick()
	check("final replay restores the entire floor",arena.get_state().remaining==arena.columns*arena.rows and arena.get_state().disabled_colliders==0)
	observations["configuration"]={"columns":arena.columns,"rows":arena.rows,"coils":arena.tesla_coils,"default_speed":arena.speed_multiplier}
