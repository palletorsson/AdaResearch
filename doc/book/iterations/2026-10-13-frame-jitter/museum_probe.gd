extends "res://doc/book/iterations/2026-10-13-one-seed-two-journeys/museum_probe.gd"

func landing_checks() -> void:
	await super.landing_checks()
	var demo := find_scene("/seed_replay_demo.gd")
	var ride := find_scene("/random_return.gd")
	if demo==null or ride==null:return
	var journey: Node=demo._journey
	var scope: Node3D=journey.jitter_scope
	check("frame scope installed beside the source console",scope!=null and scope.is_inside_tree())
	if scope==null:return
	check("scope approach has museum floor",not floor_at(scope.to_global(Vector3(0,0,0.9))).is_empty())
	scope.set_process(false)
	scope.resume_live()
	scope.observe_tick(1000)
	for i in range(35):scope.observe_tick(1000+(i+1)*10000)
	scope.redraw()
	check("constant intervals give a flat zero deviation",scope.intervals.size()==35 and is_equal_approx(scope.baseline_usec,10000) and is_zero_approx(scope.deviation_ms(34)))
	scope.observe_tick(1000+350000+17000)
	scope.redraw()
	check("a measured 7 ms delay remains a 7 ms deviation",is_equal_approx(scope.deviation_ms(35),7.0) and is_equal_approx(scope.baseline_usec,10000))
	check("automatic range includes the spike",scope.range_ms>=7.0 and scope.clipped==0)
	scope.range_index=2; scope.redraw()
	check("fixed 1 ms scale marks its clipped spike",scope.range_ms==1 and scope.clipped==1 and is_equal_approx(scope.plot_point(35).y,2.44))
	scope.controls.find_child("Btn_0",true,false).pressed.emit()
	var count: int=scope.intervals.size()
	scope.observe_tick(9900000)
	check("HOLD stops sampling without changing a seed",scope.mode=="HOLD" and scope.intervals.size()==count)
	var seed_before:int=demo.current_seed()
	var state_before:int=ride.rng.state
	scope.controls.find_child("Btn_2",true,false).pressed.emit()
	scope.controls.find_child("Btn_1",true,false).pressed.emit()
	check("REBASE uses actual readings without changing the seed or route RNG",is_equal_approx(scope.baseline_usec,(350000.0+17000.0)/36.0) and seed_before==demo.current_seed() and state_before==ride.rng.state)
	scope.controls.find_child("Btn_0",true,false).pressed.emit()
	scope.observe_tick(20000000);scope.observe_tick(20010000)
	check("resuming LIVE does not turn time on HOLD into a false spike",scope.mode=="LIVE" and scope.intervals.size()==1 and scope.intervals[0]==10000)
	for i in range(1000):scope.append_interval(10000)
	check("live history is bounded to 240 frames",scope.intervals.size()==240)
	scope.range_index=0
	scope.set_process(true)
	scope.resume_live()
	await create_timer(1.2).timeout
	check("live graph receives actual application frame readings",scope.intervals.size()>5 and scope.baseline_usec>0)
	journey.selected="frame";journey.resample();journey.set_process(false)
	journey.record_frame(123456)
	check("first capture callback anchors instead of including a partial frame",journey._frames.is_empty() and journey._frame_previous==123456)
	journey.record_frame(133456)
	check("next callback supplies a whole frame interval",journey._frames==[10000] and scope.intervals==[10000])
	# New sample flows through the production collector, not a drawn waveform.
	journey.selected="frame";journey.resample()
	var during_seed:int=demo.current_seed()
	scope.toggle_hold()
	check("HOLD cannot cancel seed capture",scope.mode=="RECORD" and journey.is_processing() and demo.current_seed()==during_seed)
	for i in range(600):
		if not journey.is_processing():break
		await process_frame
	var receipt:Dictionary=demo._source_receipt.duplicate(true)
	check("FRAMES keeps exactly the readings shown on the scope",receipt.get("provider","")=="frame" and receipt.get("sample_count",0)==120 and scope.intervals==receipt.get("intervals_usec",[]) and scope.mode=="KEPT")
	check("kept baseline is the mean of its recorded intervals",is_equal_approx(scope.baseline_usec,scope.mean(receipt.get("intervals_usec",[]))))
	var words:=PackedStringArray()
	for value in receipt.get("intervals_usec",[]):words.append(str(int(value)))
	var hash_bytes:PackedByteArray=("frame-intervals-v1\n"+",".join(words)).sha256_buffer()
	check("kept readings independently reproduce the displayed seed",int(hash_bytes.decode_u32(0)%1000)==demo.current_seed() and hash_bytes.hex_encode()==receipt.get("sha256",""))
	var destination:Vector3=ride.destination
	demo.replay()
	check("replay keeps frame trace and repeats the first destination",demo._source_receipt==receipt and scope.intervals==receipt.get("intervals_usec",[]) and scope.mode=="KEPT" and ride.destination==destination and not journey.is_processing())
	ride.advance(3.3)
	await snapshot("jitter-kept",scope.to_global(Vector3(0,1.99,2.25)),scope.to_global(Vector3(0,1.96,0)),64)
	await snapshot("jitter-room",ride.to_global(Vector3(3.2,3.4,7.0)),ride.to_global(Vector3(0.4,1.45,0.7)),78)
	await snapshot("jitter-console",ride.to_global(Vector3(2.0,1.72,4.5)),ride.to_global(Vector3(1.7,1.85,2.65)),91)
	scope.range_index=2;scope.redraw()
	await snapshot("jitter-magnified",scope.to_global(Vector3(0,1.99,2.25)),scope.to_global(Vector3(0,1.96,0)),64)
	scope.range_index=0
	scope.resume_live()
	await create_timer(1.1).timeout
	await snapshot("jitter-live",scope.to_global(Vector3(0,1.99,2.25)),scope.to_global(Vector3(0,1.96,0)),64)
	check("LIVE observation never resamples the kept seed",demo._source_receipt==receipt and scope.mode=="LIVE")
	journey.resample();await process_frame
	journey.select_source("movement")
	check("source change returns an unfinished frame trace to LIVE",scope.mode=="LIVE" and not journey.is_processing())
	observations["frame_scope_receipt"]=receipt
	observations["frame_scope_limitations"]="Measured application callback intervals in desktop Godot. Index-spaced plot. Baseline is measured, not a requested refresh rate. Scope affects the workload it observes. No Quest test or entropy estimate."
