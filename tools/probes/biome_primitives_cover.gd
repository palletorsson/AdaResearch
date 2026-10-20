extends SceneTree
## Codex's cover evidence. Claude owns the separate biome_ladder_cover.gd probe.
const OUT := "res://ada_run/biome_primitives_cover/"
var checks: Array[Dictionary] = []
var trials: Array[Dictionary] = []
var world: Node3D
var saved_unlock := false

func _initialize() -> void: run.call_deferred()

func check(label: String, passed: bool) -> void:
	checks.append({"label": label, "pass": passed})
	print("[cover] ", "PASS " if passed else "FAIL ", label)

func run() -> void:
	create_timer(70).timeout.connect(func(): push_error("Cover probe timed out"); quit(2))
	DirAccess.make_dir_recursive_absolute(OUT)
	var capacity := root.get_node("CatalystCapabilityManager")
	capacity.progression_file = OUT + "isolated-capacity.json"
	saved_unlock = capacity.has_first_catalyst()
	load("res://commons/hazards/biome_ladder/route.gd").selected_stage = 0
	world = load("res://commons/hazards/biome_ladder/ladder_world.tscn").instantiate()
	root.add_child(world); current_scene = world
	for i in range(600):
		await process_frame
		if world.is_map_ready(): break
	check("Primitives standalone scene is ready", world.is_map_ready())
	world.walker.set_physics_process(false)
	world.walker.camera.make_current()
	await physics_frame; await physics_frame
	var space := world.get_world_3d().direct_space_state
	for i in range(3):
		var query := PhysicsRayQueryParameters3D.create(Vector3(0, 1.65, 8.2), world.arena.heads[i].global_position, 1)
		query.exclude = [world.walker.get_rid()]
		check("Head %d is visible from the centre at standing height" % i, space.intersect_ray(query).is_empty())
	var capsule := CapsuleShape3D.new(); capsule.radius = 0.3; capsule.height = 1.8
	var sweep := PhysicsShapeQueryParameters3D.new()
	sweep.shape = capsule; sweep.collision_mask = 1; sweep.exclude = [world.walker.get_rid()]
	sweep.transform.origin = Vector3(0, 1.05, 8.2)
	sweep.motion = Vector3(0, 0, -18.2)
	check("Player capsule has a clear central route through architecture", space.cast_motion(sweep)[0] > 0.999)
	check("Primitives retain the outlined white floor", world.arena.get_node("LadderGround12x24").material_override is ShaderMaterial)
	check("Cover stays static in Primitives", world.arena.motions.is_empty())
	await photograph("overview", Vector3(0.3, 0.05, 8.2), Vector3(0, 1.1, -3))
	await fire_at_player("box-protected", 0, Vector3(-2.2, 0.05, 7.7), true)
	await photograph("behind-box", Vector3(-2.2, 0.05, 7.7), Vector3(-3, 1.8, 3))
	await fire_at_player("box-step-out", 0, Vector3(-0.3, 0.05, 7.7), false)
	await photograph("step-out", Vector3(-0.3, 0.05, 7.7), Vector3(-3, 1.8, 3))
	await fire_at_player("cylinder-protected", 1, Vector3(1.4, 0.05, 1.6), true)
	await fire_at_player("cylinder-step-out", 1, Vector3(2.9, 0.05, 1.6), false)
	# B11 carries the same six shelters into the following stages.
	for stage in range(1, 4):
		world.change_stage(stage); await physics_frame
		check("Stage %d inherits six Primitives shelters" % stage, world.arena.find_children("PrimitiveCover*", "", false, false).size() == 6)
	world.queue_free(); await process_frame; await physics_frame
	check("Practice did not earn the museum ability", capacity.has_first_catalyst() == saved_unlock and capacity.first_catalyst.unlocked == saved_unlock)
	var failures := checks.filter(func(c): return not c.pass).size()
	FileAccess.open(OUT + "report.json", FileAccess.WRITE).store_string(JSON.stringify({"passed": checks.size() - failures, "total": checks.size(), "checks": checks, "trials": trials}, "\t"))
	print("PRIMITIVES COVER ", checks.size() - failures, "/", checks.size())
	quit(0 if failures == 0 else 1)

func fire_at_player(label: String, head_index: int, at: Vector3, protected: bool) -> void:
	world.arena.start_round()
	for head in world.arena.heads: head.set_physics_process(false)
	world.walker.position = at
	var head: CharacterBody3D = world.arena.heads[head_index]
	world.walker.head.look_at(head.global_position)
	await physics_frame; await physics_frame
	var target := at + Vector3.UP * 1.1
	var query := PhysicsRayQueryParameters3D.create(head.global_position, target, 1)
	query.exclude = [world.walker.get_rid()]
	var hit := world.get_world_3d().direct_space_state.intersect_ray(query)
	check(label + ": line of fire matches cover", not hit.is_empty() if protected else hit.is_empty())
	head.begin_telegraph(world.arena.to_local(target))
	head.advance(head.WINDUP + 0.01, target)
	check(label + ": skull launches its actual ball", head.projectiles.size() == 1)
	var ball: Node3D = head.projectiles.back()
	var evidence := {"label": label, "protected": protected, "collided": false, "impact": "", "player_hits": 0}
	ball.tree_exiting.connect(func():
		evidence.collided = ball.spent
		evidence.impact = str(ball.global_position))
	for tick in range(300):
		await physics_frame
		if not is_instance_valid(ball): break
	evidence.player_hits = world.arena.player_hits
	trials.append(evidence)
	check(label + ": shot reaches a real collision", evidence.collided)
	check(label + ": cover stops damage" if protected else label + ": exposed player is hit once", world.arena.player_hits == (0 if protected else 1))
	world.arena.reset_round()

func photograph(label: String, at: Vector3, look: Vector3) -> void:
	if DisplayServer.get_name() == "headless": return
	world.walker.position = at
	world.walker.head.look_at(look)
	for i in range(20): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT + label + ".png")
