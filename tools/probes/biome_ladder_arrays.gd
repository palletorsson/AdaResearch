extends SceneTree
## Native geometry, collision and ordered volleys. Physical headset feel remains a playtest.
const Route := preload("res://commons/hazards/biome_ladder/route.gd")
const Ball := preload("res://commons/hazards/biome_ladder/ladder_ball.gd")
const OUT := "res://ada_run/biome_ladder_arrays/"
var checks: Array[Dictionary] = []
var world: Node3D
var contacts: Array[Node] = []
var automatic_shots: Array[int] = []

func _initialize() -> void: run.call_deferred()
func check(label: String, ok: bool) -> void:
	checks.append({"label": label, "pass": ok})
	print("[arrays] ", "PASS " if ok else "FAIL ", label)

func capture(file: String) -> void:
	if DisplayServer.get_name() == "headless": return
	for f in range(6): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT + file + ".png")

func run() -> void:
	create_timer(100).timeout.connect(func(): push_error("Arrays probe timed out"); quit(2))
	DirAccess.make_dir_recursive_absolute(OUT)
	root.get_node("CatalystCapabilityManager").progression_file = OUT + "isolated-capacity.json"
	Route.selected_stage = 2
	world = load(Route.SCENE).instantiate(); root.add_child(world); current_scene = world
	for f in range(600):
		await process_frame
		if world.is_map_ready(): break
	check("Ladder ready", world.is_map_ready())
	world.walker.set_physics_process(false)
	world.walker.collision_layer = 0
	world.walker.camera.make_current()
	world.walker.camera.global_position = Vector3(0, 1.7, 8.7)
	world.walker.camera.look_at(Vector3(0, 2.55, 3.5))
	var arena: Node3D = world.arena
	arena.set_process(false); arena.set_physics_process(false)
	for head in arena.heads: head.set_physics_process(false)
	check("Nine skulls and nine persistent labels", arena.heads.size() == 9 and arena.address_labels.size() == 9)
	var ids: Array[int] = []
	for i in range(9):
		var head: Node3D = arena.heads[i]
		ids.append(head.get_instance_id())
		check("Slot %d has stable address" % i, head.slot == i and head.array_controlled)
		var ray := PhysicsRayQueryParameters3D.create(Vector3(0, 1.7, 10.5), head.global_position, 1 | 2)
		var hit := world.get_world_3d().direct_space_state.intersect_ray(ray)
		check("Slot %d visible from arrival" % i, hit.get("collider") == head)
	await capture("array-ready")
	arena.start_round()
	for step in range(6):
		arena._begin_array_volley()
		var expected: Array[int] = []
		for n in range(3): expected.append(step * 3 + n if step < 3 else n * 3 + step - 3)
		check("Volley %d addresses the expected row or column" % step, arena.last_volley == expected)
		for head in arena.heads:
			var selected: bool = head.slot in expected
			check("Volley %d selects slot %d only when addressed" % [step, head.slot], (head.state == head.State.TELEGRAPH) == selected)
			if selected:
				var promised: PackedVector3Array = head.pending_path.duplicate()
				head.advance(head.WINDUP + 0.01, head.target_position())
				check("Slot %d fires its previewed ordered path" % head.slot, head.projectiles.size() == 1 and head.projectiles[0].waypoints == promised)
				head.projectiles[0].set_physics_process(false)
				head.projectiles[0]._physics_process(0.08)
				check("Path ball retains growth", head.projectiles[0].radius_factor > 1)
		if step == 1:
			await capture("row-volley")
			var original: Transform3D = world.walker.camera.global_transform
			world.walker.camera.global_position = Vector3(5.4, 4.5, 8.8)
			world.walker.camera.look_at(Vector3(-0.3, 2.3, 5.0))
			await capture("zigzag-paths")
			world.walker.camera.global_transform = original
		for head in arena.heads: head.clear_shots()
		await process_frame
	arena.rest()
	check("REST clears shots and path previews", arena.heads.all(func(h): return h.projectiles.is_empty() and not is_instance_valid(h.path_preview)))
	var middle: Node3D = arena.heads[4]
	var shot: RigidBody3D = load("res://commons/artifacts/ignorance_gallery/form_projectile.gd").new()
	shot.form = SphereMesh.new(); shot.form.radius = 0.07; shot.form.height = 0.14
	shot.position = middle.global_position + Vector3(0, 0, 0.8)
	shot.direction = Vector3.FORWARD; shot.speed = 3
	world.add_child(shot)
	for f in range(90):
		await physics_frame
		if middle.destroyed: break
	check("Actual catalyst collision empties the middle slot", middle.destroyed and arena.address_labels[4].text.contains("EMPTY"))
	middle.set_physics_process(true)
	for f in range(120): await physics_frame
	check("Defeated skull physically falls", middle.fallen and middle.position.y < 0.5)
	check("Vacancy does not remove or renumber neighbours", arena.heads.size() == 9 and arena.heads[5].slot == 5 and arena.heads[5].get_instance_id() == ids[5])
	await capture("array-vacancy")
	arena.start_round(); arena.set_physics_process(false)
	# RESUME preserves the vacant address; only RESET restores the board.
	check("RESUME keeps the existing vacancy", middle.destroyed)
	arena.volley_step = 1; arena._begin_array_volley()
	check("Row volley skips the vacant slot", arena.last_volley == [3, 5])
	arena.reset_round()
	check("RESET restores all nine occupants and labels", arena.heads.all(func(h): return not h.destroyed) and not arena.address_labels[4].text.contains("EMPTY") and arena.volley_step == 0)
	for head in arena.heads:
		var address: int = head.slot
		head.ball_sent.connect(func(_shot): automatic_shots.append(address))
		head.set_physics_process(true)
	arena.set_physics_process(true); arena.start_round()
	for f in range(90): await physics_frame
	check("Normal game loop fires only the first row after its warning", automatic_shots == [0, 1, 2])
	for f in range(288): await physics_frame
	check("Normal game loop advances to the second row", automatic_shots == [0, 1, 2, 3, 4, 5])
	arena.rest(); arena.set_physics_process(false)
	await refuge_checks(arena)
	await path_collision_checks()
	for stage in [3, 4]:
		world.change_stage(stage); await physics_frame; await physics_frame
		arena = world.arena
		check("Stage %d inherits nine addressed skulls" % stage, arena.heads.size() == 9 and arena.heads.all(func(h): return h.array_controlled))
		arena._transform_floor_tile(arena.floor_tile_bodies[0], Vector3.ZERO)
		arena._mark_pattern_floor(arena.floor_tile_bodies[0], Vector3.ZERO, Color.MAGENTA)
		check("Stage %d keeps scaling, turning and colour" % stage, arena.floor_tiles[0].scale.is_equal_approx(Vector3.ONE * 0.8) and is_equal_approx(arena.floor_tiles[0].rotation.y, deg_to_rad(22.5)) and arena.floor_marks[0] == Color.MAGENTA)
		if stage == 4: check("Tiling retains eighteen matching cells", arena.floor_tile_hits.size() == 18)
	world.queue_free(); await process_frame; await physics_frame
	var failed := checks.filter(func(c): return not c.pass).size()
	FileAccess.open(OUT + "report.json", FileAccess.WRITE).store_string(JSON.stringify({"passed": checks.size() - failed, "total": checks.size(), "checks": checks, "rendered": DisplayServer.get_name() != "headless"}, "\t"))
	print("ARRAYS ", checks.size() - failed, "/", checks.size())
	quit(0 if failed == 0 else 1)

func refuge_checks(arena: Node3D) -> void:
	var target := CharacterBody3D.new(); target.collision_layer = 524288
	target.add_to_group("player_body")
	var shape := CollisionShape3D.new(); var capsule := CapsuleShape3D.new()
	capsule.radius = 0.25; capsule.height = 1.8; shape.shape = capsule
	target.add_child(shape); world.add_child(target)
	target.position = Vector3(-4.35, 0.9, 7.9)
	await physics_frame; await physics_frame
	for head in arena.heads:
		head.set_physics_process(false); head.set_active(true)
		head.begin_telegraph(target.position + Vector3.UP * 0.7)
		var shot: Node3D = head.throw_ball(); shot.set_physics_process(false)
		contacts.clear(); shot.surface_hit.connect(func(body, _at): contacts.append(body))
		for f in range(600):
			shot._physics_process(0.02)
			if shot.spent: break
		check("Refuge stops a real zigzag from slot %d" % head.slot, not contacts.is_empty() and contacts[0] == arena.get_node("PrimitiveCover_0_Left"))
		head.clear_shots()
		await physics_frame
	target.queue_free(); arena.rest()

func path_collision_checks() -> void:
	# Isolated physical route: multiple edges in one tick, then a solid cover block.
	var ball := Ball.new(); ball.stage = 2; ball.position = Vector3(0, 30, 0)
	ball.waypoints = PackedVector3Array([ball.position, Vector3(1, 30, 0), Vector3(1, 30, 1), Vector3(0, 30, 1)])
	world.add_child(ball); ball.set_physics_process(false)
	ball._physics_process(1.25)
	check("A long tick traverses corners without cutting them", ball.global_position.is_equal_approx(Vector3(0.75, 30, 1)))
	ball.queue_free(); await physics_frame
	var cover := StaticBody3D.new(); cover.position = Vector3(1, 30, 0.7)
	var shape := CollisionShape3D.new(); var box := BoxShape3D.new(); box.size = Vector3(0.7, 1, 0.1)
	shape.shape = box; cover.add_child(shape); world.add_child(cover)
	await physics_frame; await physics_frame
	ball = Ball.new(); ball.stage = 2; ball.position = Vector3(0, 30, 0)
	ball.waypoints = PackedVector3Array([ball.position, Vector3(1, 30, 0), Vector3(1, 30, 2)])
	ball.surface_hit.connect(func(body, _at): contacts.append(body))
	world.add_child(ball); ball.set_physics_process(false)
	ball._physics_process(1.25)
	check("Swept zigzag hits cover on its second edge", contacts.has(cover) and ball.spent)
	cover.queue_free(); await physics_frame
