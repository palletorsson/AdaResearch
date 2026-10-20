extends "res://doc/book/iterations/2026-10-13-four-by-four-seed/museum_probe.gd"
const Sample = preload("res://algorithms/randomness/seed_replay/movement_seed.gd")
const Client = preload("res://algorithms/randomness/seed_replay/atmospheric_seed.gd")

class StubClient extends "res://algorithms/randomness/seed_replay/atmospheric_seed.gd":
	var urls: Array[String] = []
	func _send(url: String) -> void: urls.append(url)
	func reply(body: String) -> void:
		_completed(HTTPRequest.RESULT_SUCCESS,200,PackedStringArray(),body.to_utf8_buffer())

func gesture(sampler: Node3D, count: int = 120) -> void:
	# A scripted fixture, deliberately not evidence of human entropy.
	for i in range(count):
		var t := i/20.0
		var pose := Transform3D(Basis.from_euler(Vector3(0.15*sin(t),0.3*cos(t),0.08*t)),Vector3(sin(t)*0.3,1.2+cos(t*1.7)*0.12,0.4+sin(t*0.7)*0.16))
		sampler.accept_pose(pose,(i+1)*16667,true)

func landing_checks() -> void:
	museum.call("flush_stamps")
	await create_timer(0.5).timeout
	var demo := find_scene("/seed_replay_demo.gd")
	check("movement bench installed in real museum",demo != null and demo._movement_sampler != null)
	if demo == null or demo._movement_sampler == null: return
	var sampler: Node3D = demo._movement_sampler
	sampler.set_process(false)
	var opening: Dictionary = demo.capture_museum_state()
	check("opening keeps actual atmospheric receipt 435",demo.current_seed() == 435 and opening.source_receipt.provider == "RANDOM.ORG" and not demo._atmosphere_client.is_busy())
	check("new sphere inherits PointBody pickup",sampler.point is RigidBody3D and sampler.point.get_script().resource_path.ends_with("/ignorance_gallery/point_body.gd") and sampler.point.get_script().get_base_script().resource_path.ends_with("/objects/pickable.gd"))
	await snapshot("arrival",demo.to_global(Vector3(-0.4,2.15,5.6)),demo.to_global(Vector3(-0.45,2.3,0)),59)
	# Load after autoload startup: XRTools player dependencies use its settings singleton.
	var pointer: Node3D = load("res://commons/scenes/DesktopInteractionPointer.gd").new()
	root.add_child(pointer)
	pointer._camera = camera
	pointer.set_process(false)
	pointer._grab_held(sampler.point)
	check("actual desktop grab hook starts capture",sampler.collecting and sampler.sample.source == "desktop_movement")
	var colours: PackedColorArray = demo.column_colors(0)
	var rng_state: int = demo._rng.state
	gesture(sampler)
	check("collecting never advances colour generator",demo._rng.state == rng_state and demo.column_colors(0) == colours and demo.current_seed() == 435)
	check("trace buffers show six changing channels",sampler._points.size() == 90 and sampler._rotations.size() == 90 and sampler.sample.changes == 119)
	pointer._drop_held()
	await tick()
	var saved: Dictionary = demo.capture_museum_state()
	var receipt: Dictionary = saved.source_receipt
	check("actual desktop release publishes movement seed",receipt.get("provider","") == "movement" and receipt.get("sample_count",0) == 120 and not sampler.collecting)
	check("movement provenance replaces atmosphere claim",demo._source_label.text.contains("Desktop movement") and not demo._source_label.text.contains("RANDOM.ORG"))
	check("movement seed remains in exposed 0-999 range",demo.current_seed() >= 0 and demo.current_seed() <= 999)
	check("both grids use the new seed",demo.column_colors(0) == demo.column_colors(1) and demo._large_seed.text == str(demo.current_seed()))
	check("release parks inherited sphere at its stand",sampler.point.position.is_equal_approx(sampler.HOME) and sampler.point.freeze)
	var decoded: Dictionary = JSON.parse_string(JSON.stringify(receipt))
	check("saved sample reconstructs seed and digest after JSON roundtrip",Sample.seed_for(decoded.source,decoded.samples) == int(decoded.seed) and Sample.digest_for(decoded.source,decoded.samples).hex_encode() == decoded.sha256)
	colours = demo.column_colors(0)
	var sample_count: int = sampler.sample.samples.size()
	demo.replay()
	check("replay reproduces colours without resampling",demo.column_colors(0) == colours and sampler.sample.samples.size() == sample_count and not sampler.collecting)
	demo.toggle_extra_draw()
	check("extra-draw comparison still works with movement seed",demo.column_colors(0) == colours and demo.column_colors(1) != colours)
	demo.restore_museum_state(saved)
	check("restore keeps receipt and exact paired colours",demo.capture_museum_state().source_receipt == receipt and demo.column_colors(0) == colours and demo.column_colors(1) == colours)
	await snapshot("movement-kept",demo.to_global(Vector3(-0.4,2.15,5.6)),demo.to_global(Vector3(-0.45,2.3,0)),59)
	await snapshot("movement-traces",sampler.to_global(Vector3(0.25,1.65,2.1)),sampler.to_global(Vector3(0,1.55,0.1)),50)
	observations["scripted_movement_receipt"] = receipt
	# Too-short and unchanged poses must not replace the already-kept picture.
	for amount in [1,29]:
		sampler.begin_capture("desktop_movement")
		gesture(sampler,amount)
		sampler.end_capture()
		check("short capture keeps previous seed: "+str(amount),demo.capture_museum_state().source_receipt == receipt)
	sampler.begin_capture("desktop_movement")
	for i in range(40):sampler.accept_pose(Transform3D.IDENTITY,i*16667,true)
	sampler.end_capture()
	check("timestamps alone are not labelled movement",demo.capture_museum_state().source_receipt == receipt)
	var pool := Sample.new()
	pool.start("xr_tracking")
	check("invalid tracking is rejected",not pool.add_pose(Transform3D.IDENTITY,0,false))
	check("degenerate transform is rejected",not pool.add_pose(Transform3D(Basis(Vector3.ZERO,Vector3.ZERO,Vector3.ZERO),Vector3.ZERO),1,true))
	check("nonfinite pose is rejected",not pool.add_pose(Transform3D(Basis.IDENTITY,Vector3(NAN,0,0)),2,true))
	check("valid pose starts bounded sample",pool.add_pose(Transform3D.IDENTITY,3,true))
	check("backward clock is rejected",not pool.add_pose(Transform3D.IDENTITY,2,true))
	for i in range(400): pool.add_pose(Transform3D(Basis.IDENTITY,Vector3(i*0.001,0,0)),10+i,true)
	check("buffer bounded at 300 accepted samples",pool.samples.size() == 300 and pool.finish().sample_count == 300)
	# Synthetic poses through the actual XR tracker API; no physical headset claim.
	var tracker := XRControllerTracker.new()
	tracker.name = &"/user/hand/left"
	tracker.type = XRServer.TRACKER_CONTROLLER
	XRServer.add_tracker(tracker)
	var origin := XROrigin3D.new()
	root.add_child(origin)
	var controller := XRController3D.new()
	controller.tracker = tracker.name
	controller.pose = &"grip"
	origin.add_child(controller)
	sampler.begin_capture("xr_tracking")
	tracker.set_pose(&"grip",Transform3D.IDENTITY,Vector3.ZERO,Vector3.ZERO,XRPose.XR_TRACKING_CONFIDENCE_LOW)
	check("low-confidence XR pose is skipped",not sampler.sample_controller(controller) and sampler.sample.samples.is_empty())
	tracker.set_pose(&"grip",Transform3D(Basis.IDENTITY,Vector3(0.1,1.2,0.2)),Vector3.ZERO,Vector3.ZERO,XRPose.XR_TRACKING_CONFIDENCE_HIGH)
	check("high-confidence XR pose is sampled",sampler.sample_controller(controller))
	await create_timer(0.002).timeout
	origin.position = Vector3(100,50,20)
	check("virtual locomotion excluded from movement sample",sampler.sample_controller(controller) and sampler.sample.changes == 0)
	tracker.invalidate_pose(&"grip")
	check("stale pose is not recycled after tracking loss",not sampler.sample_controller(controller) and sampler.sample.samples.size() == 2)
	sampler.cancel_capture()
	origin.queue_free()
	XRServer.remove_tracker(tracker)
	# Editing the seed wins over a pending capture.
	pointer._grab_held(sampler.point)
	gesture(sampler,40)
	demo.randomize_seed()
	var edited: int = demo.current_seed()
	pointer._drop_held()
	check("manual edit cancels pending movement receipt",not sampler.collecting and demo.current_seed() == edited and demo.capture_museum_state().source_receipt.is_empty())
	# Exercise the production carry/update path as well as the repeatable fixture.
	pointer._grab_held(sampler.point)
	for i in range(35):
		camera.position.x += 0.007
		pointer._process(0.02)
		sampler._process(0.02)
		await create_timer(0.002).timeout
	check("real desktop carry and sampler update accumulate movement",sampler.sample.samples.size() == 35 and sampler.sample.changes > 0)
	pointer._drop_held()
	check("production sampling publishes valid receipt",demo.capture_museum_state().source_receipt.get("sample_count",0) == 35)
	demo.randomize_seed()
	edited = demo.current_seed()
	# A late HTTP response cannot undo an in-progress or completed gesture.
	demo._atmosphere_client.queue_free()
	await tick()
	var fake := StubClient.new()
	demo.add_child(fake)
	demo._atmosphere_client = fake
	fake.received.connect(demo._receive_atmospheric_seed)
	fake.status_changed.connect(demo._show_seed_source)
	Client._retry_after_msec = 0
	check("atmospheric request can start when not holding",demo.request_atmospheric_seed())
	fake.reply("1000")
	pointer._grab_held(sampler.point)
	gesture(sampler,40)
	fake.reply("321")
	check("late network response respects ongoing capture",demo.current_seed() == edited)
	check("new network request waits for release",not demo.request_atmospheric_seed())
	pointer._drop_held()
	var calls := fake.urls.size()
	demo.replay()
	check("movement replay needs no network",fake.urls.size() == calls)
	var ordinary: Node = load("res://algorithms/randomness/seed_replay/seed_replay_demo.tscn").instantiate()
	root.add_child(ordinary)
	check("ordinary benches do not gain sampler",ordinary._movement_sampler == null and ordinary._atmosphere_client == null)
	ordinary.queue_free()
	pointer.queue_free()
	await super.landing_checks()
	demo.restore_museum_state(saved)
	observations["scope"] = "Real isolated museum; desktop grab/drop hooks, recorded fixture, synthetic XR tracking confidence and origin tests, mocked HTTP race. No network request sent. No physical headset/entropy measurement."
