extends SceneTree
const Route := preload("res://commons/hazards/biome_ladder/route.gd")
const WORLD := "res://commons/hazards/biome_ladder/ladder_world.tscn"
var checks: Array[Dictionary] = []
var rendered := false
const OUT := "res://ada_run/biome_ladder_play"

func _initialize() -> void: run.call_deferred()
func check(label: String, ok: bool) -> void:
	checks.append({"label": label, "pass": ok})
	print("[ladder] ", "PASS " if ok else "FAIL ", label)

func run() -> void:
	rendered = DisplayServer.get_name() != "headless"
	DirAccess.make_dir_recursive_absolute(OUT)
	var capacity := root.get_node("CatalystCapabilityManager")
	capacity.progression_file = OUT + "/isolated-capacity.json"
	var earned: bool = capacity.has_first_catalyst()
	# Load the XR scene only after autoloads exist (XRToolsUserSettings, GameManager).
	var world: Node3D = load(WORLD).instantiate(); root.add_child(world); current_scene = world
	for i in range(300):
		if world.is_map_ready(): break
		await process_frame
	check("Standalone world and player ready", world.is_map_ready())
	check("Practice supplies hand form without saving unlock", capacity.first_catalyst.unlocked and capacity.has_first_catalyst() == earned)
	check("Ladder is twice the prior 12m length", world.arena.get_node("LadderGround12x24").mesh.size == Vector3(12, 0.24, 24))
	for stage in range(Route.STAGES.size()):
		world.change_stage(stage)
		await physics_frame; await process_frame
		var arena: Node3D = world.arena
		check("Stage %d carries the learned head count" % stage, arena.heads.size() == (9 if stage >= 2 else 3))
		check("Stage %d learned landscape motion" % stage, arena.motions.is_empty() == (stage == 0))
		var col: Color = arena.floor_materials[1].albedo_color
		check("Stage %d colour gate" % stage, (absf(col.r - col.g) < 0.001 and absf(col.g - col.b) < 0.001) == (stage < 3))
		arena.start_round()
		var head: CharacterBody3D = arena.heads[0]
		head.set_physics_process(false)
		var before: Vector3 = head.position
		head.advance(0.5, Vector3(0, 1.5, 8))
		check("Stage %d skull movement gate" % stage, head.position.is_equal_approx(before) == (stage == 0))
		head.begin_telegraph(Vector3(0, 1.5, 8)); head.advance(head.WINDUP + 0.01, Vector3(0, 1.5, 8))
		check("Stage %d skull fires slow ball" % stage, head.projectiles.size() == 1 and is_equal_approx(head.projectiles[0].speed, 1.8))
		var ball: Node3D = head.projectiles[0]
		ball.set_physics_process(false); ball._physics_process(0.2)
		check("Stage %d ball growth gate" % stage, (ball.radius_factor > 1.0) == (stage >= 1))
		check("Stage %d collider follows visible radius" % stage, is_equal_approx(ball.get_child(0).shape.radius, 0.09 * ball.radius_factor))
		check("Stage %d particles gate" % stage, is_instance_valid(ball.trail) == (stage >= 3))
		if stage >= 2:
			check("Stage %d indexed row" % stage, is_equal_approx(arena.heads[0].home_position.z, arena.heads[2].home_position.z) and arena.heads[2].slot == 2)
		# Exercise the actual catalyst projectile and collision dispatch.
		var shot: RigidBody3D = load("res://commons/artifacts/ignorance_gallery/form_projectile.gd").new()
		shot.form = SphereMesh.new(); shot.form.radius = 0.07; shot.form.height = 0.14
		shot.position = head.global_position + Vector3(0, 0, 0.65); shot.direction = Vector3.FORWARD; shot.speed = 3
		world.add_child(shot)
		for tick in range(90):
			await physics_frame
			if head.destroyed: break
		check("Stage %d real catalyst collision defeats head" % stage, head.destroyed)
		if is_instance_valid(shot): shot.queue_free()
		var high: float = head.position.y
		head.advance(0.2, Vector3.ZERO)
		check("Stage %d defeated head falls and cannot shoot" % stage, head.position.y < high and head.throw_ball() == null)
		arena.reset_round()
		check("Stage %d reset restores heads" % stage, not head.destroyed and head.position.is_equal_approx(head.home_position))
		if rendered:
			world.walker.set_physics_process(false)
			world.walker.camera.global_position = Vector3(0.3, 1.65, 8.2)
			world.walker.camera.look_at(Vector3(0, 1.1, -3))
			world.walker.camera.make_current()
			for f in range(12): await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(OUT + "/stage-%d.png" % stage)
		arena.rest()
		check("Stage %d rest clears hostile shots" % stage, arena.heads.all(func(h): return h.projectiles.is_empty()))
	world.queue_free(); await process_frame; await physics_frame
	check("Practice exit restores earned ability", capacity.first_catalyst.unlocked == earned)
	var failures := checks.filter(func(c): return not c.pass).size()
	var file := FileAccess.open(OUT + "/report.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks": checks, "passed": checks.size() - failures, "total": checks.size(), "rendered": rendered}, "\t")); file.close()
	print("BIOME LADDER ", checks.size() - failures, "/", checks.size())
	quit(0 if failures == 0 else 1)
