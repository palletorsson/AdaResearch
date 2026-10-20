extends SceneTree
## Codex B11: phase geometry, live hostile flights, and native captures.
## Claude's independent biome_ladder_cover.gd is run separately and left unchanged.
const OUT := "res://ada_run/biome_transformation_cover/"
var checks: Array[Dictionary] = []
var flights: Array[Dictionary] = []
var world: Node3D
var minimum_gap := INF
var opening := {}

func _initialize() -> void: run.call_deferred()

func check(label: String, ok: bool) -> void:
	checks.append({"label": label, "pass": ok})
	print("[B11] ", "PASS " if ok else "FAIL ", label)

func run() -> void:
	create_timer(210).timeout.connect(func(): push_error("B11 timed out"); quit(2))
	DirAccess.make_dir_recursive_absolute(OUT)
	var capacity := root.get_node("CatalystCapabilityManager")
	capacity.progression_file = OUT + "isolated-capacity.json"
	var earned: bool = capacity.has_first_catalyst()
	world = load("res://commons/hazards/biome_ladder/ladder_world.tscn").instantiate()
	root.add_child(world); current_scene = world
	for i in range(600):
		await process_frame
		if world.is_map_ready(): break
	check("Standalone world ready", world.is_map_ready())
	world.walker.set_physics_process(false)
	world.walker.camera.make_current()
	if "--capture-only" in OS.get_cmdline_user_args():
		world.change_stage(1)
		await physics_frame; await physics_frame
		await transformation_photos()
		world.queue_free(); await process_frame
		quit(0); return
	for stage in range(4):
		world.change_stage(stage)
		await physics_frame; await physics_frame
		var arena: Node3D = world.arena
		for head in arena.heads: head.set_physics_process(false)
		arena.set_process(false)
		check("Stage %d six inherited tall shelters" % stage, arena.find_children("PrimitiveCover*", "", false, false).size() == 6)
		check("Stage %d outlined floor only before Arrays" % stage, (arena.get_node("LadderGround12x24").material_override is ShaderMaterial) == (stage < 2))
		if stage == 0:
			check("Primitives remains static", arena.motions.is_empty())
		else:
			var counts := [0, 0, 0]
			var assigned := true
			for motion in arena.motions:
				counts[motion.kind] += 1
				var mesh: Mesh = motion.view.mesh
				assigned = assigned and ((motion.kind == 0 and mesh is SphereMesh) or (motion.kind == 1 and mesh is BoxMesh) or (motion.kind == 2 and mesh is CylinderMesh))
			check("Stage %d each operation has a visible form" % stage, assigned and counts == [4, 2, 2])
		var fixed: Node3D = arena.get_node("PrimitiveCover_0_Left")
		var fixed_transform := fixed.transform
		var aligned := true
		var grounded := true
		var standing := true
		var passage := true
		var clear_pickups := true
		# Full cycle samples, with real physics queries after each update.
		for sample in range(32):
			await phase(TAU * sample / 32.0)
			for motion in arena.motions:
				var view: MeshInstance3D = motion.view
				var shape: CollisionShape3D = motion.shape
				aligned = aligned and view.global_transform.is_equal_approx(shape.global_transform)
				if motion.kind == 2:
					var bounds: AABB = view.global_transform * view.mesh.get_aabb()
					grounded = grounded and absf(bounds.position.y) < 0.002
					standing = standing and bounds.size.y >= 1.999
					# Query the actual collision top, not only matching transforms.
					var q := PhysicsRayQueryParameters3D.create(motion.body.global_position + Vector3.UP * 5, motion.body.global_position, 1)
					var hit := world.get_world_3d().direct_space_state.intersect_ray(q)
					aligned = aligned and not hit.is_empty() and hit.collider == motion.body and absf(hit.position.y - bounds.end.y) < 0.01
			var left: MeshInstance3D = arena.get_node("PrimitiveCover_2_Left").get_child(1)
			var right: MeshInstance3D = arena.get_node("PrimitiveCover_2_Right").get_child(1)
			var left_box: AABB = left.global_transform * left.mesh.get_aabb()
			var right_box: AABB = right.global_transform * right.mesh.get_aabb()
			minimum_gap = minf(minimum_gap, right_box.position.x - left_box.end.x)
			# A 1.8 m wide corridor, plus a normal visitor capsule at either edge.
			for x in [-0.6, 0.0, 0.6]:
				passage = passage and sweep_clear(Vector3(x, 1.05, 8.2), Vector3(0, 0, -18.2))
			for pickup in arena.pickups:
				clear_pickups = clear_pickups and sweep_clear(pickup.position + Vector3(0, 0.65, 0.8), Vector3(0, 0, -0.8))
		check("Stage %d entrance refuge stays fixed" % stage, fixed.transform.is_equal_approx(fixed_transform))
		check("Stage %d visible forms and physical tops agree across 32 phases" % stage, aligned)
		check("Stage %d scaling is floor anchored and at least standing height" % stage, grounded and standing)
		check("Stage %d 1.8 m central passage is clear throughout cycle" % stage, passage)
		check("Stage %d pickups remain approachable" % stage, clear_pickups)
		await live_flight("stage%d-refuge" % stage, 0, Vector3(-2.2, 0.12, 7.7), true, 0.0, stage > 0)
		await live_flight("stage%d-step-out" % stage, 0, Vector3(-3.5, 0.12, 7.7), false, 0.0, stage > 0)
		if stage == 1:
			for p in [-PI / 2, 0.0, PI / 2]:
				# The same known cover direction, including maximum-size hostile balls.
				await live_flight("cylinder-phase-%.2f" % p, 1, Vector3(1.4, 0.12, 1.8), true, p - 1.2, true)
			for p in [0.0, PI / 4, PI / 2]:
				await live_flight("turning-box-phase-%.2f" % p, 2, Vector3(-3.7, 0.12, -5.16), true, p - 2.4, true)
			await find_opening()
			await transformation_photos()
		else:
			await photograph("stage-%d" % stage, Vector3(0.3, 0.0, 8.2), Vector3(0, 1.1, -3), 0.0)
	world.queue_free(); await process_frame; await physics_frame
	check("Practice preserves earned museum ability", capacity.has_first_catalyst() == earned and capacity.first_catalyst.unlocked == earned)
	check("Narrowest sampled gap is at least 1.8 m", minimum_gap >= 1.8)
	var failures := checks.filter(func(c): return not c.pass).size()
	FileAccess.open(OUT + "report.json", FileAccess.WRITE).store_string(JSON.stringify({"passed": checks.size() - failures, "total": checks.size(), "minimum_gap_m": minimum_gap, "checks": checks, "flights": flights, "opening": opening, "source_sha256": FileAccess.get_sha256("res://commons/hazards/biome_ladder/ladder_encounter.gd")}, "\t"))
	print("B11 COVER ", checks.size() - failures, "/", checks.size(), " gap=", minimum_gap)
	quit(0 if failures == 0 else 1)

func phase(angle: float) -> void:
	world.arena.set_process(false)
	world.arena.clock = fposmod(angle, TAU) / 0.6
	await physics_frame; await physics_frame

func sweep_clear(from: Vector3, motion: Vector3) -> bool:
	var query := PhysicsShapeQueryParameters3D.new()
	var capsule := CapsuleShape3D.new(); capsule.radius = 0.3; capsule.height = 1.8
	query.shape = capsule; query.transform.origin = from; query.motion = motion
	query.collision_mask = 1; query.exclude = [world.walker.get_rid()]
	var space := world.get_world_3d().direct_space_state
	return space.intersect_shape(query, 1).is_empty() and space.cast_motion(query)[0] > 0.999

func live_flight(label: String, slot: int, at: Vector3, sheltered: bool, angle: float, grown: bool, moving := true) -> void:
	var arena: Node3D = world.arena
	arena.start_round()
	for head in arena.heads: head.set_physics_process(false)
	world.walker.position = at
	await phase(angle)
	arena.set_process(moving)
	var head: Node3D = arena.heads[slot]
	head.begin_telegraph(arena.to_local(head.target_position()))
	var ball: Node3D = head.throw_ball()
	check(label + " actual skull ball launched", ball != null)
	if ball == null: return
	if grown: ball.age = 6.0
	var record := {"label": label, "live_motion": moving, "grown": grown, "collided": false, "radius": 0.0, "impact": "", "player_hits": 0}
	ball.tree_exiting.connect(func():
		record.collided = ball.spent
		record.radius = ball.get_child(0).shape.radius
		record.impact = str(ball.global_position))
	for tick in range(800):
		await physics_frame
		if not is_instance_valid(ball): break
	record.player_hits = arena.player_hits; flights.append(record)
	check(label + " collision and expected protection", record.collided and record.player_hits == (0 if sheltered else 1))
	if grown: check(label + " maximum hostile radius exercised", is_equal_approx(float(record.radius), 0.198))
	arena.rest(); arena.set_process(false)

func path_clear(from: Vector3, to: Vector3) -> bool:
	var query := PhysicsShapeQueryParameters3D.new()
	var sphere := SphereShape3D.new(); sphere.radius = 0.198; query.shape = sphere
	query.transform.origin = from; query.motion = to - from; query.collision_mask = 1
	query.exclude = [world.walker.get_rid()]
	return world.get_world_3d().direct_space_state.cast_motion(query)[0] > 0.999

func find_opening() -> void:
	var head: Node3D = world.arena.heads[2]
	var chosen := Vector3.INF
	world.walker.position = Vector3(0, 0.12, 10.5)
	var candidates: Array[Vector3] = []
	await phase(-2.4) # Far box has yaw 0.
	for x in range(34, 46):
		for z in range(62, 81):
			var at := Vector3(-x / 10.0, 0.12, -z / 10.0)
			var aim := at + Vector3.UP * 1.65
			var start := head.global_position + head.global_position.direction_to(aim) * 0.42
			if path_clear(start, aim): candidates.append(at)
	await phase(PI / 4 - 2.4)
	for at in candidates:
		var aim := at + Vector3.UP * 1.65
		var start := head.global_position + head.global_position.direction_to(aim) * 0.42
		if not path_clear(start, aim):
			chosen = at
			opening = {"visitor": str(at), "head": 2, "open_yaw": 0, "screened_yaw": PI / 4}
			break
	check("Turning box opens and closes a full-size projectile path", not opening.is_empty())
	if opening.is_empty(): return
	await live_flight("opening-fixed-yaw0", 2, chosen, false, -2.4, true, false)
	await live_flight("opening-fixed-yaw45", 2, chosen, true, PI / 4 - 2.4, true, false)
	await photograph("opening-clear", chosen, head.global_position, -2.4)
	await photograph("opening-screened", chosen, head.global_position, PI / 4 - 2.4)

func transformation_photos() -> void:
	await photograph("after", Vector3(0.3, 0.0, 8.2), Vector3(0, 1.1, -3), 0.0)
	# Avoid a half-cycle pair: a square box looks identical after a 180-degree turn.
	await photograph("motion-a", Vector3(4.2, 0.0, 5.5), Vector3(-1, 1.1, -2.5), -2.4)
	await photograph("motion-b", Vector3(4.2, 0.0, 5.5), Vector3(-1, 1.1, -2.5), PI / 2 - 1.2)

func photograph(label: String, at: Vector3, look: Vector3, angle: float) -> void:
	if DisplayServer.get_name() == "headless": return
	world.arena.rest()
	world.walker.position = at
	world.walker.head.look_at(look)
	await phase(angle)
	for i in range(15): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT + label + ".png")
