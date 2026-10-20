extends "res://doc/book/iterations/2026-10-13-movement-becomes-a-seed/museum_probe.gd"

func route_samples(ride: Node3D, value: int) -> Array:
	var generator := RandomNumberGenerator.new()
	generator.seed=value
	var result: Array=[]
	for i in range(5):
		var a:=generator.randf_range(0,TAU)
		var d:=generator.randf_range(1.1,ride.MAX_RADIUS)
		result.append(Vector3(cos(a)*d,0,sin(a)*d))
	return result

func landing_checks() -> void:
	museum.call("flush_stamps")
	await create_timer(0.5).timeout
	var demo := find_scene("/seed_replay_demo.gd")
	var ride := find_scene("/random_return.gd")
	check("configured bench and travelling sphere installed",demo!=null and ride!=null)
	if demo==null or ride==null:return
	ride.enabled_motion=false
	var journey: Node=demo._journey
	check("matching hall link connects source bank to route",journey!=null and journey.ride==ride and ride.coordinator==journey)
	if journey==null or journey.ride==null:return
	# Retain prior desktop movement, XR tracking, grid and async race tests.
	await super.landing_checks()
	var sampler: Node3D=demo._movement_sampler
	var fixture: Dictionary=demo.capture_museum_state().duplicate(true)
	var saved_seed: int=demo.current_seed()
	check("movement release seeds both journey and grids",ride.route_seed==saved_seed and ride.source_name=="HAND RECORDING")
	var expected:=route_samples(ride,saved_seed)
	demo.replay()
	for i in range(5):
		check("independent RNG predicts route destination "+str(i+1),ride.destination.is_equal_approx(expected[i]))
		if i<4:ride.advance(ride.CYCLE_SECONDS)
	demo.replay()
	check("replay restores first trip and centre",ride.trip==1 and is_zero_approx(ride.clock) and ride.point.position.is_equal_approx(ride.CENTRE) and ride.destination.is_equal_approx(expected[0]))
	var state: int=ride.rng.state
	var destination: Vector3=ride.destination
	demo.toggle_extra_draw();demo.set_grid_side(8);demo.set_grid_side(4);demo.toggle_extra_draw()
	check("colour requests and grid resolution never consume travel RNG",ride.rng.state==state and ride.destination==destination)
	check("direction and distance match the commanded endpoint",is_equal_approx(ride.chosen_distance,ride.destination.length()) and is_equal_approx(ride.chosen_direction,fposmod(rad_to_deg(atan2(ride.destination.z,ride.destination.x)),360)))
	check("solid direction arrow reaches chosen endpoint",ride.direction_arrow.to_point.is_equal_approx(ride.destination+Vector3.UP*0.065))
	check("hand instrument moved beside travel controls",sampler.global_position.distance_to(ride.to_global(Vector3(-1.85,0,2.6)))<0.03)
	check("console and hand approach have floor",not floor_at(ride.to_global(Vector3(0.25,0,3.8))).is_empty() and not floor_at(ride.to_global(Vector3(-1.85,0,3.8))).is_empty())
	journey.source_buttons.fixed.pressed.emit()
	check("actual NUMBER button recalls a chosen seed",demo.current_seed()==42 and ride.route_seed==42 and journey.selected=="fixed")
	journey.source_buttons.movement.pressed.emit()
	check("HAND button recalls prior recording without collecting",demo.current_seed()==saved_seed and ride.route_seed==saved_seed and not sampler.collecting)
	journey.source_buttons.clock.pressed.emit()
	var clock_receipt: Dictionary=demo._source_receipt.duplicate(true)
	check("CLOCK button captures actual elapsed milliseconds",clock_receipt.provider=="clock" and int(clock_receipt.elapsed_msec)%1000==demo.current_seed() and ride.route_seed==demo.current_seed())
	journey.keep_clock(123456)
	check("clock modulo mechanism gives a known remainder",demo.current_seed()==456 and ride.route_seed==456)
	journey.source_buttons.system.pressed.emit()
	var system_receipt: Dictionary=demo._source_receipt.duplicate(true)
	check("SYSTEM button keeps cryptographic source bytes reduced to exhibit range",system_receipt.provider=="system" and int(system_receipt.raw_u32)%1000==demo.current_seed())
	journey.source_buttons.atmosphere.pressed.emit()
	check("AIR recalls saved atmosphere without a network request",demo.current_seed()==435 and ride.route_seed==435 and not demo._atmosphere_client.is_busy())
	journey.source_buttons.frame.pressed.emit()
	journey.set_process(false)
	journey._frame_previous=1000
	for i in range(120):journey.record_frame(1000+(i+1)*11111)
	var frame_receipt: Dictionary=demo._source_receipt.duplicate(true)
	check("even perfectly regular timing can supply a seed without an entropy claim",frame_receipt.provider=="frame" and frame_receipt.sample_count==120 and frame_receipt.intervals_usec[0]==11111 and journey.details.text.contains("entropy has not been measured"))
	journey.source_buttons.movement.pressed.emit()
	journey.source_buttons.frame.pressed.emit()
	check("switching back to FRAMES recalls saved intervals",demo._source_receipt==frame_receipt and not journey.is_processing())
	journey.resample()
	await create_timer(0.08).timeout
	check("production frame collector records actual callbacks",journey._frames.size()>0 and journey._frames.size()<120)
	journey.source_buttons.movement.pressed.emit()
	await create_timer(0.05).timeout
	check("switching source cancels in-progress frame capture",not journey.is_processing() and journey._frames.is_empty() and demo.current_seed()==saved_seed)
	check("HAND recalls the trace belonging to its kept seed",sampler.sample.samples==fixture.source_receipt.samples and sampler.readout.text.contains(str(saved_seed)))
	journey.selected="frame";journey.resample()
	demo.replay()
	check("REPLAY cancels an unfinished frame sample",not journey.is_processing() and journey.selected=="movement" and demo.current_seed()==saved_seed)
	# Save/restore all source receipts along with the active seed.
	var bank_saved: Dictionary=demo.capture_museum_state()
	journey.bank.clear()
	demo.restore_museum_state(bank_saved)
	check("visit restore preserves all six sources",journey.bank.size()==6 and ride.route_seed==saved_seed)
	# An ordinary replay never samples again, even while carrying.
	var pointer: Node3D=load("res://commons/scenes/DesktopInteractionPointer.gd").new()
	root.add_child(pointer);pointer._camera=camera;pointer.set_process(false)
	pointer._grab_held(ride.point)
	check("travelling sphere still uses desktop handhold",ride.point.held())
	var old: Vector3=ride.point.global_position
	journey.keep_clock(123456)
	check("new seed is visibly queued while riding",ride.route_seed==saved_seed and int(ride.pending_seed.value)==456 and ride.point.global_position.is_equal_approx(old) and ride.readout.text.contains("release"))
	journey.source_buttons.system.pressed.emit()
	var latest: int=demo.current_seed()
	pointer._drop_held()
	await tick()
	check("release applies latest source rather than stale queued value",ride.route_seed==latest and ride.pending_seed.is_empty() and ride.trip==1)
	pointer.queue_free()
	demo.restore_museum_state(bank_saved)
	journey.panel.find_child("Btn_7",true,false).pressed.emit()
	check("actual REPLAY button repeats journey and grids",ride.route_seed==saved_seed and ride.trip==1 and ride.destination.is_equal_approx(expected[0]) and demo.column_colors(0)==demo.column_colors(1))
	# A real capsule uses the same collision-aware carry callback as the museum.
	var body:=CharacterBody3D.new()
	var shape:=CollisionShape3D.new()
	var capsule:=CapsuleShape3D.new();capsule.radius=0.2;capsule.height=1.7
	shape.shape=capsule;body.add_child(shape);root.add_child(body)
	body.global_position=ride.to_global(Vector3(0,0.9,0.7))
	var hand:Node3D=load("res://commons/scenes/DesktopInteractionPointer.gd").new()
	body.add_child(hand);hand._camera=camera;hand.set_process(false)
	hand._grab_held(ride.point)
	var from:Vector3=body.global_position
	for i in range(70):
		ride.advance(1.0/60.0)
		ride._physics_process(1.0/60.0)
		body.velocity=ride.carry_velocity(body,1.0/60.0,body.velocity)
		body.move_and_slide()
		await physics_frame
	# Skip the initial 1.5-second pause before measuring the excursion.
	for i in range(100):
		ride.advance(1.0/60.0)
		ride._physics_process(1.0/60.0)
		body.velocity=ride.carry_velocity(body,1.0/60.0,body.velocity)
		body.move_and_slide()
		await physics_frame
	check("held sphere transports a colliding desktop capsule",Vector2(body.global_position.x-from.x,body.global_position.z-from.z).length()>0.2 and body.is_on_floor())
	hand._drop_held();ride._physics_process(1.0/60.0)
	check("release removes carry and horizontal velocity",ride.rider==null and is_zero_approx(body.velocity.x) and is_zero_approx(body.velocity.z))
	body.queue_free()
	demo.replay()
	# Fix the photographed phase; no sampling is represented as a human test.
	ride.advance(3.3)
	await snapshot("room",ride.to_global(Vector3(5.5,3.2,8.0)),ride.to_global(Vector3(-0.3,1.45,-0.7)),66)
	await snapshot("sources-and-hand",ride.to_global(Vector3(-0.5,1.72,4.35)),ride.to_global(Vector3(-0.6,1.65,2.8)),85)
	await snapshot("direction-and-distance",ride.to_global(Vector3(3.0,1.7,1.7)),ride.to_global(Vector3(0,1.7,-1.4)),66)
	await snapshot("shared-seed",demo.to_global(Vector3(-0.4,2.15,5.6)),demo.to_global(Vector3(-0.45,2.3,0)),59)
	journey.select_source("clock")
	ride.advance(3.3)
	await snapshot("clock-journey",ride.to_global(Vector3(3.0,1.7,1.7)),ride.to_global(Vector3(0,1.7,-1.4)),66)
	journey.select_source("atmosphere")
	ride.advance(3.3)
	await snapshot("air-journey",ride.to_global(Vector3(3.0,1.7,1.7)),ride.to_global(Vector3(0,1.7,-1.4)),66)
	journey.select_source("movement")
	observations["linked_seed"]=saved_seed
	observations["source_bank"]=bank_saved.source_bank
	observations["direction_degrees"]=ride.chosen_direction
	observations["distance_m"]=ride.chosen_distance
	observations["scope"]="Actual museum. Desktop controls and carry hooks; synthetic movement/XR inputs; real clock/system/frame collection. No physical Quest or entropy certification. Screenshots use labelled scripted movement fixture."

