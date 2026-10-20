extends SceneTree
## Controlled XRServer poses -> real controller trigger -> real projectile flight.
## Heads retain their normal physics processing, including movement and falling.
const OUT := "res://ada_run/biome_ladder_skull_hits/"
const Route := preload("res://commons/hazards/biome_ladder/route.gd")
var checks: Array[Dictionary] = []
var world: Node3D
var ability: Node3D
var rig: XROrigin3D
var trackers: Array[XRControllerTracker] = []
var sent: Array[Node3D] = []
var hit_body: Node3D
var label_prefix := ""

func _initialize() -> void: run.call_deferred()
func check(label: String, ok: bool) -> void:
	label = label_prefix + label
	checks.append({"label": label, "pass": ok})
	print("[skull-hit] ", "PASS " if ok else "FAIL ", label)

func observe(shot: Node3D) -> void:
	sent.append(shot)
	shot.projectile_hit.connect(func(body, _at): hit_body = body)

func aim(at: Vector3, target: Vector3) -> void:
	var basis := Basis.looking_at(at.direction_to(target))
	for i in range(2):
		var pose := Transform3D(basis, at + basis.x * (-0.10 if i == 0 else 0.10))
		trackers[i].set_pose("default", pose, Vector3.ZERO, Vector3.ZERO, 2)
	await create_timer(0.65).timeout

func fire() -> void:
	hit_body = null
	var count := sent.size()
	trackers[1].set_input("trigger_click", true)
	await physics_frame
	trackers[1].set_input("trigger_click", false)
	check("Tracked trigger sends one formed sphere", sent.size() == count + 1)
	await create_timer(0.65).timeout

func capture(name: String, head: Node3D) -> void:
	world.walker.camera.global_position = head.home_position + Vector3(1.4, 0.3, 2.8)
	world.walker.camera.look_at(head.home_position + Vector3(0, -0.7, 0))
	for i in range(4): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT + name + ".png")

func run() -> void:
	create_timer(110).timeout.connect(func(): push_error("Skull hit probe timed out"); quit(2))
	DirAccess.make_dir_recursive_absolute(OUT)
	var capacity := root.get_node("CatalystCapabilityManager")
	capacity.progression_file = OUT + "isolated-capacity.json"
	var earned: bool = capacity.has_first_catalyst()
	ability = capacity.first_catalyst
	ability.form_sent.connect(observe)
	world = load(Route.SCENE).instantiate(); root.add_child(world); current_scene = world
	for i in range(600):
		await process_frame
		if world.is_map_ready(): break
	world.walker.set_physics_process(false); world.walker.camera.make_current()
	# Exercise the VR branch of the shared ability, not the desktop adapter.
	ability.desktop_source = null
	for id in ["left_hand", "right_hand"]:
		var tracker := XRControllerTracker.new()
		tracker.type = XRServer.TRACKER_CONTROLLER; tracker.name = id
		tracker.set_pose("default", Transform3D.IDENTITY, Vector3.ZERO, Vector3.ZERO, 2)
		XRServer.add_tracker(tracker); trackers.append(tracker)
	rig = XROrigin3D.new(); rig.name = "ControlledTrackedHands"
	for id in ["left_hand", "right_hand"]:
		var controller := XRController3D.new(); controller.tracker = id; rig.add_child(controller)
	root.add_child(rig); rig.current = true
	for stage in range(Route.STAGES.size()):
		world.change_stage(stage); await physics_frame; await physics_frame
		var arena: Node3D = world.arena
		for mode in ["READY", "PLAY", "REST"]:
			label_prefix = "%s / %s / " % [Route.STAGES[stage].title, mode]
			arena.reset_round()
			if mode != "READY": arena.start_round()
			if mode == "REST": arena.rest()
			var head: CharacterBody3D = arena.heads[0]
			var height := head.global_position.y
			await aim(head.global_position + Vector3(0, 0, 2.5), head.global_position)
			check("Real XR hand discovery forms the sphere", ability._origin == rig and ability.formed)
			if stage == 0 and mode == "READY": await capture("before", head)
			# Re-aim at the moving head after discovery; do not freeze its physics.
			var close: Vector3 = head.global_position + Vector3(0, 0, 1.1)
			for i in range(2):
				trackers[i].set_pose("default", Transform3D(Basis.IDENTITY, close + Vector3(-0.10 if i == 0 else 0.10, 0, 0)), Vector3.ZERO, Vector3.ZERO, 2)
			await physics_frame; await physics_frame
			await fire()
			check("Projectile physically collides with skull", hit_body == head)
			check("One impact defeats the skull", head.destroyed and head.incoming_hits == 1)
			await create_timer(0.65).timeout
			check("Unmodified physics loop makes skull fall", head.fallen and head.global_position.y < height - 0.6)
			check("Defeated skull cannot shoot", head.destroyed and head.throw_ball() == null)
			if stage == 0 and mode == "READY": await capture("after", head)
			arena.reset_round(); await physics_frame
			check("RESET restores skull and collider", not head.destroyed and not head.fallen and head.incoming_hits == 0 and head.collision_layer == 2 and head.position.is_equal_approx(head.home_position))
	label_prefix = ""
	for tracker in trackers: XRServer.remove_tracker(tracker)
	rig.queue_free(); world.queue_free(); await process_frame; await physics_frame
	check("Exit restores earned ability", capacity.has_first_catalyst() == earned and ability.unlocked == earned)
	var failed := checks.filter(func(c): return not c.pass).size()
	FileAccess.open(OUT + "report.json", FileAccess.WRITE).store_string(JSON.stringify({"passed": checks.size()-failed, "total": checks.size(), "checks": checks, "source_sha256": FileAccess.get_sha256("res://commons/hazards/biome_ladder/ladder_skull.gd"), "scope": "Controlled XRServer input and actual projectile/physics; not a physical headset playtest."}, "\t"))
	print("SKULL HITS ", checks.size()-failed, "/", checks.size())
	quit(0 if failed == 0 else 1)
