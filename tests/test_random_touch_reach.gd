extends SceneTree
var failures: Array[String] = []
func check(ok: bool, reason: String) -> void:
	if not ok: failures.append(reason); push_error(reason)
func _initialize() -> void: call_deferred("run")
func settle() -> void:
	for i in 6: await physics_frame
func run() -> void:
	var scene = load("res://commons/artifacts/random_touch/random_touch.tscn").instantiate()
	root.add_child(scene); scene.set_physics_process(false)
	var replay = scene.get_node("ReplayButton")
	var area = replay.get_node("InteractableAreaButton")
	check(is_equal_approx(replay.global_position.y,.72),"REPLAY centre is 72 cm above floor")
	var hit = area.get_node("CollisionShape3D")
	var reach_half: float = hit.shape.size.z/2
	check(hit.global_position.y-reach_half>=.6-0.00001 and hit.global_position.y+reach_half<=1.8,"Whole button touch target fits 0.6–1.8 m band")
	for lane in 5:
		var excursion: float = scene.Motion.Y_RANGE if lane==4 else 0
		check(scene.HOMES[lane].y-excursion-scene.TOUCH_RADIUS>=.6 and scene.HOMES[lane].y+excursion+scene.TOUCH_RADIUS<=1.8,"All bead travel and touch boundaries fit reach band")
	var origin := XROrigin3D.new(); origin.position.z=.6; root.add_child(origin)
	var camera := XRCamera3D.new(); camera.position.y=1.6; origin.add_child(camera)
	var controller := XRController3D.new(); controller.tracker="left_hand"; origin.add_child(controller)
	var hand = load("res://addons/godot-xr-tools/hands/scenes/collision/collision_hand.tscn").instantiate()
	hand.mode=1 # TELEPORT, the production museum hand configuration.
	controller.add_child(hand)
	# The palm collider sits 11 cm behind the controller's local origin.
	# Face the palm toward the panel, so it can touch from the front.
	controller.rotation.y=PI
	controller.global_position=Vector3(0,.77,.6)
	await settle()
	var presses := [0]
	replay.pressed.connect(func(): presses[0]+=1)
	scene.ink.record_span(scene.record,0,0,3)
	var head_start := camera.global_transform
	controller.global_position=Vector3(0,.77,.13)
	await settle()
	check(presses[0]==1 and area.pressed,"Real XR collision hand presses REPLAY from the front")
	check(scene.ink.marks[0].is_empty(),"Hand press reaches actual replay callback and clears ink")
	check(camera.global_transform==head_start,"Standing viewpoint 0.6 m away stays still")
	controller.global_position=Vector3(0,.77,.6)
	await settle()
	check(not area.pressed,"Withdrawing releases the button")
	controller.global_position=Vector3(.30,.77,.13)
	await settle()
	check(presses[0]==2,"Wide button can be pressed off centre")
	controller.rotation.y=0
	controller.global_position=Vector3(0,1.2,.6); await settle()
	for lane in 5:
		scene.act(0)
		controller.global_position=scene.points[lane].global_position+Vector3(0,.02,-.05)
		await settle(); scene._sync_hand()
		check(scene.active_lane==lane,"Compact row %d selects its nearest bead" % (lane+1))
		controller.global_position.z=.6
		scene._sync_hand(); scene.advance(2)
		await settle(); scene._sync_hand()
	scene.queue_free(); origin.queue_free(); await process_frame
	print("RANDOM TOUCH REACH: ","PASS" if failures.is_empty() else failures)
	quit(0 if failures.is_empty() else 1)
