extends SceneTree
const Hall = preload("res://commons/artifacts/randomness_space/hall_seed.gd")
var failures: Array[String] = []
var room: Node3D
var exhibits := {}
func check(ok: bool, reason: String) -> void:
	if not ok: failures.append(reason); push_error(reason)
func _initialize() -> void: call_deferred("run")
func add_exhibit(id: String, path: String, config: Dictionary = {}) -> Node:
	var resource = load(path)
	if resource == null:
		check(false,"Load " + path); return null
	var node = resource.instantiate() if resource is PackedScene else resource.new()
	node.name = id
	for key in config: node.set_meta("config_"+key,config[key])
	if node.has_method("apply_grid_config"): node.apply_grid_config(config)
	room.add_child(node)
	node.set_process(false); node.set_physics_process(false)
	exhibits[id] = node
	return node
func seeds() -> Array:
	return [exhibits.touch.record.seed,exhibits.page.page_seed,exhibits.geiger.current.seed,
		exhibits.lava.model_seed,exhibits.window.current_seed(),exhibits.ride.route_seed,
		exhibits.crank.initial_seed,exhibits.slots.spin_seed,exhibits.bench.model.current.seed.to_int(),
		exhibits.sources.stream_seed,exhibits.film.active_seed]
func all_at(value: int, context: String) -> void:
	check(seeds().all(func(n): return int(n)==value),context+": "+str(seeds()))
func sample_outputs() -> Array:
	return [exhibits.touch.record.duplicate(true),exhibits.page._five_digits(),exhibits.geiger.current.events_us.duplicate(),
		exhibits.lava.current.sha256,exhibits.window.column_colors(0),exhibits.ride.destination,
		exhibits.slots._draw_index(),exhibits.bench.model.current.raw_values.duplicate(),
		exhibits.sources.trng_buffer.duplicate(),exhibits.film.values.duplicate()]
func run() -> void:
	room = Node3D.new(); room.set_meta("em_map","Random_Definition"); root.add_child(room)
	add_exhibit("touch","res://commons/artifacts/random_touch/random_touch.tscn")
	add_exhibit("page","res://algorithms/randomness/randomnumbergeneration/scenes/random_number_book_page_1955.tscn",{"row_stream":"true"})
	add_exhibit("geiger","res://commons/artifacts/geiger_counter/geiger_counter.gd")
	add_exhibit("lava","res://commons/artifacts/lava_entropy_wall/lava_entropy_wall.gd")
	add_exhibit("ride","res://commons/artifacts/random_return/random_return.gd",{"route_link":"seed_test"})
	add_exhibit("window","res://algorithms/randomness/seed_replay/seed_replay_demo.gd",{"movement_seed":"true","route_link":"seed_test","side":4,"atmosphere":"true","recorded_atmosphere":"true","comparison":"seed_witness","display":"wall","surface":"glass","mapping_study":"true"})
	add_exhibit("crank","res://algorithms/randomness/prng_crank_machine/prng_crank_machine.gd")
	add_exhibit("slots","res://algorithms/randomness/slot_machine/slot_machine.gd")
	add_exhibit("bench","res://commons/artifacts/seed_study/seed_study.gd")
	add_exhibit("sources","res://algorithms/randomness/trng_vs_prng/trng_vs_prng.tscn")
	add_exhibit("film","res://commons/artifacts/spine_films/more_motion/prng_register.gd")
	await process_frame
	all_at(435,"Fresh room")
	check(Hall.state(exhibits.window).participants.size()==11,"All eleven instruments bind to one hall")
	check(Hall.choose(exhibits.window,436),"Manual choice accepted")
	all_at(436,"Manual choice propagates")
	check(exhibits.window._column_seeds()==[436,436,437],"Stack derives its third seed without changing the hall")
	check(exhibits.window.column_colors(0)==exhibits.window.column_colors(1),"Same-seed replay matches after hall change")
	exhibits.window.cycle_mapping()
	all_at(436,"Local mapping leaves the hall seed unchanged")
	exhibits.window.reset_mapping()
	exhibits.window.apply_grid_config({"seed":435,"side":4})
	exhibits.lava.apply_grid_config({"seed":435,"emissive":false})
	exhibits.slots.apply_grid_config({"spin_seed":0})
	all_at(436,"Layout/config refresh cannot overwrite a chosen hall seed")
	check(Hall.choose(exhibits.window,0),"Zero is a valid explicit seed")
	all_at(0,"Zero retained, including private slot stream")
	check(exhibits.slots._rng!=null,"Zero does not switch to the global random source")
	check(exhibits.geiger.MODEL.valid(exhibits.geiger.current),"Zero Geiger record validates")
	check(exhibits.lava.MODEL.valid(exhibits.lava.current),"Zero lamp record validates")
	Hall.reset(exhibits.window)
	all_at(435,"Reset restores opening")
	var first := sample_outputs()
	Hall.reset(exhibits.window)
	check(first==sample_outputs(),"Reset replays independent instrument outputs")
	seed(123456)
	var expected_global := randi()
	seed(123456)
	Hall.reset(exhibits.window)
	exhibits.page._five_digits(); exhibits.slots._draw_index(); exhibits.sources.quantum_fluctuation()
	check(randi()==expected_global,"Hall instruments never consume or reseed the global stream")
	var journey = exhibits.window._journey
	for kind in ["clock","frame","system"]: journey.select_source(kind)
	journey.keep_clock(987654); journey.resample()
	check(not exhibits.window.request_atmospheric_seed(),"Fresh atmospheric request disabled")
	check(not Hall.choose(exhibits.window,729,{"provider":"system"}),"System entropy receipt rejected")
	all_at(435,"Disallowed acquisition leaves the room unchanged")
	var sampler = exhibits.window._movement_sampler
	sampler.begin_capture("desktop_movement")
	check(not Hall.choose(exhibits.window,123),"Changing the hall cannot interrupt an active recording")
	all_at(435,"Rejected change is atomic")
	for i in 40:
		sampler.accept_pose(Transform3D(Basis(Vector3.UP,i*.03),Vector3(i*.02,1,0)),i*17000,true)
	sampler.end_capture()
	var kept: Dictionary = exhibits.window._source_receipt.duplicate(true)
	check(kept.get("provider")=="movement" and kept.has("samples"),"Gesture receipt and samples preserved")
	all_at(int(kept.get("seed",-1)),"Gesture supplies the whole hall's new input")
	var gesture_outputs := sample_outputs()
	exhibits.window.replay()
	check(gesture_outputs==sample_outputs(),"Gesture seed replays deterministic outputs")
	check(exhibits.window._source_receipt==kept,"Replay preserves gesture provenance")
	var touch_kept: Dictionary = exhibits.touch.capture()
	exhibits.geiger.kept = exhibits.geiger.current.duplicate(true)
	exhibits.geiger.kept_baseline = exhibits.geiger.baseline.duplicate(true)
	var lamp_kept: Dictionary = exhibits.lava.current.duplicate(true)
	Hall.reset(exhibits.window)
	check(exhibits.geiger.replay(),"Saved Geiger comparison replays")
	check(exhibits.window._source_receipt==kept,"Geiger replay restores gesture provenance throughout hall")
	Hall.reset(exhibits.window)
	check(exhibits.lava.replay_record(lamp_kept),"Saved lamp capture replays")
	check(exhibits.window._source_receipt==kept,"Lamp replay restores gesture provenance throughout hall")
	Hall.reset(exhibits.window)
	check(exhibits.touch.restore(touch_kept),"Saved hand path replays")
	check(exhibits.window._source_receipt==kept,"Hand replay restores gesture provenance throughout hall")
	all_at(int(kept.seed),"Saved records restore one shared seed")
	var pointer := Node3D.new(); room.add_child(pointer)
	exhibits.ride.point.on_desktop_grab(pointer)
	check(not Hall.choose(exhibits.window,123),"Held body refuses reseeding")
	all_at(int(kept.seed),"Held-body refusal leaves every instrument unchanged")
	exhibits.ride.point.on_desktop_drop()
	exhibits.touch.points[0].on_desktop_grab(pointer)
	check(not Hall.choose(exhibits.window,123),"Held hand refuses reseeding")
	all_at(int(kept.seed),"Held-hand refusal leaves every instrument unchanged")
	exhibits.touch.points[0].on_desktop_drop()
	check(exhibits.film.validation().passed,"Register film shows correct arithmetic at the hall seed")
	check(exhibits.geiger.MODEL.valid(exhibits.geiger.current),"Geiger receipt remains reconstructible")
	check(exhibits.lava.MODEL.valid(exhibits.lava.current),"Lamp receipt remains reconstructible")
	exhibits.bench.activate(2)
	var kept_values: Array = exhibits.bench.model.kept.raw_values.duplicate()
	Hall.next(exhibits.window)
	exhibits.bench.activate(3)
	all_at(int(kept.seed),"48-value bench replay rejoins hall seed")
	check(exhibits.bench.model.current.raw_values==kept_values,"48-value replay keeps stored outcomes authoritative")
	var page = exhibits.page
	page._process(0.0); page._advance_stream(1.0)
	page._on_cell_touched(null,0,0)
	var selected: String = page._cells[0][0].text
	page._cascade_step(); page._advance_stream(1.0)
	check(page._cells[0][0].text==selected and not page._pinned,"Seeded falling page still flows around a selection")
	var other := Node3D.new(); other.set_meta("em_map","Random_Definition"); root.add_child(other)
	var late = load("res://commons/artifacts/geiger_counter/geiger_counter.gd").new()
	room.add_child(late)
	check(late.current.seed==Hall.current(exhibits.window),"Late instrument joins current seed")
	var fresh = load("res://commons/artifacts/geiger_counter/geiger_counter.gd").new()
	other.add_child(fresh)
	check(fresh.current.seed==435,"Another fresh room starts at 435")
	Hall.next(exhibits.window)
	check(fresh.current.seed==435,"Separate rooms do not change each other's seeds")
	var grid := Node3D.new(); grid.set_meta("hall_seed_scope",true); root.add_child(grid)
	var desktop = load("res://commons/artifacts/geiger_counter/geiger_counter.gd").new()
	desktop.set_meta("config_hall_seed","435"); grid.add_child(desktop)
	check(desktop.current.seed==435,"Desktop map-token metadata enables the same rule")
	room.queue_free(); other.queue_free(); grid.queue_free()
	await process_frame
	await process_frame
	print("RANDOM DEFINITION SEED: ","PASS" if failures.is_empty() else failures)
	quit(0 if failures.is_empty() else 1)
