extends SceneTree
const Route := preload("res://commons/hazards/biome_ladder/route.gd")
const Ball := preload("res://commons/hazards/biome_ladder/change_ball.gd")
const OUT := "res://ada_run/biome_change/"
var world: Node3D
var arena: Node3D
var checks: Array[Dictionary] = []
var sent: Array[Node3D] = []
var contacts: Array[Node] = []

func _initialize() -> void: run.call_deferred()
func check(label: String, ok: bool) -> void:
	checks.append({"label": label, "pass": ok})
	print("[change] ", "PASS " if ok else "FAIL ", label)
func click() -> void:
	var event := InputEventMouseButton.new(); event.button_index = MOUSE_BUTTON_LEFT; event.pressed = true
	root.push_input(event); event = event.duplicate(); event.pressed = false; root.push_input(event)
func capture(file: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT + file + ".png")

func paint(at: Vector3) -> void:
	world.walker.position = at + Vector3(0, 2, 1)
	world.walker.head.look_at(at)
	await create_timer(0.4).timeout
	var count := sent.size(); click()
	check("Desktop input sends a catalyst form", sent.size() == count + 1)
	if sent.size() == count: return
	var ball: Node3D = sent.back()
	for i in range(200):
		await physics_frame
		if not is_instance_valid(ball) or ball.has_hit: break
	check("Catalyst reaches an actual receiver", is_instance_valid(ball) and ball.has_hit)

func run() -> void:
	create_timer(120).timeout.connect(func(): push_error("Change probe timeout"); quit(2))
	DirAccess.make_dir_recursive_absolute(OUT)
	var capacity: Node = root.get_node("CatalystCapabilityManager")
	capacity.progression_file = OUT + "isolated.json"
	var earned: bool = capacity.has_first_catalyst()
	Route.selected_stage = 4
	world = load(Route.SCENE).instantiate(); root.add_child(world); current_scene = world
	for i in range(600):
		await process_frame
		if world.is_map_ready(): break
	check("World ready", world.is_map_ready())
	world.walker.set_physics_process(false); world.walker.camera.make_current()
	world.walker.position = Vector3(4.6, 0.12, 11); world.walker.head.look_at(Vector3(4.6, 1.17, 9.6))
	await create_timer(0.4).timeout
	check("Desktop pointer can select Change", world.walker.desktop_pointer.has_hover_target())
	click(); await physics_frame; await physics_frame
	arena = world.arena
	check("Sixth console button opens Change", arena.stage == 5 and Route.selected_stage == 5)
	if arena.stage != 5: quit(1); return
	check("Route follows the actual Change to Forces boundary", Route.index_for_map("Flow_Field") == 5 and Route.STAGES[5].first == "Vectors_Act1_WhatAVectorIs")
	arena.set_process(false); arena.set_physics_process(false)
	for head in arena.heads: head.set_physics_process(false)
	check("Nine addressed heads, motion and pickups return", arena.heads.size() == 9 and arena.address_labels.size() == 9 and arena.motions.size() == 8 and arena.pickups.size() == 3)
	check("Only the centre column introduces field shots", arena.heads.filter(func(h): return h.uses_field()).map(func(h): return h.slot) == [1, 4, 7])
	check("Each floor tile carries an arrow", arena.direction_field.arrows.size() == 72)
	check("Untouched arrows prescribe forward motion", arena.direction_field.sample(Vector3(1, 3, 5)).is_equal_approx(Vector3.BACK))
	world.walker.position = Vector3(0, 0.12, 8.8); world.walker.head.look_at(Vector3(0, 1.0, 1))
	await capture("before")
	capacity.first_catalyst.form_sent.connect(func(s): sent.append(s))
	await paint(Vector3(1, 0.04, 3)); await paint(Vector3(1, 0.04, 5))
	check("Two hits retain two 18-tile motifs", arena.floor_tile_hits.size() == 36 and arena.floor_marks.size() == 36 and arena.floor_flashes.size() == 36)
	var direction := Vector3.BACK.rotated(Vector3.UP, deg_to_rad(22.5))
	check("The sampled direction follows the shot's tile rotation", arena.direction_field.sample(Vector3(1, 3, 5)).is_equal_approx(direction))
	check("Visible arrow and sampled vector agree", arena.direction_field.arrows[51].global_basis.z.normalized().is_equal_approx(direction))
	var old_rotation: Vector3 = arena.rotation
	arena.rotation.y = 0.35
	check("Sampling respects the arena reference frame", arena.direction_field.sample(arena.to_global(Vector3(1, 3, 5))).is_equal_approx(arena.global_basis * direction))
	arena.rotation = old_rotation
	var camera := Camera3D.new(); world.add_child(camera)
	camera.position = Vector3(7, 8, 13); camera.look_at(Vector3(0, 0, 1)); camera.fov = 55; camera.make_current()
	await capture("field-changed")
	# Painting was observed from above the floor. Return the real collision body
	# to the arrival before testing a clear flight through that former viewpoint.
	world.walker.position = arena.arrival
	await physics_frame; await physics_frame; await process_frame
	var target := Marker3D.new(); world.add_child(target); target.position = Vector3(0, 1.65, 10.5)
	var head: Node3D = arena.heads[1]; head.target_override = target; head.set_active(true)
	head.begin_telegraph(target.position)
	check("Field warning previews the sampled path", head.pending_path.size() == 29 and head.pending_path[-1].x > head.pending_path[0].x + 0.6)
	var ball: Node3D = head.throw_ball(); ball.set_physics_process(false)
	ball.surface_hit.connect(func(body, at): print("[change-contact] ", body.get_path(), " at ", at))
	check("Field ball retains tint, particles and speed", ball.trail != null and is_equal_approx(ball.speed, 1.8))
	var start: Vector3 = ball.position
	ball._physics_process(0.5)
	check("Field assigns direction without accelerating", (ball.position - start).is_equal_approx(direction * 0.9) and is_equal_approx(ball.speed, 1.8) and ball.target_sample_count == 0)
	ball._physics_process(0.9)
	if ball.spent:
		check("Phase-test flight stays clear of fixtures", false); quit(1); return
	check("Ball samples target exactly once when warning begins", ball.flight == Ball.Flight.WARNING and ball.target_sample_count == 1 and ball.sampled_target.is_equal_approx(target.position))
	var sampled: Vector3 = ball.sampled_target; var stopped: Vector3 = ball.position
	target.position += Vector3.RIGHT * 3.0
	ball._physics_process(0.4)
	check("Warning holds position and keeps the old target", ball.position.is_equal_approx(stopped) and ball.sampled_target == sampled and ball.target_sample_count == 1)
	check("Warning draws the committed destination", is_instance_valid(ball.turn_line) and ball.turn_line.visible)
	camera.position = Vector3(4, 3.5, 10.5); camera.look_at(Vector3(0, 2.1, 5)); camera.fov = 65
	await capture("turn-warning")
	ball._physics_process(0.5)
	check("After the signal the ball turns once", ball.flight == Ball.Flight.COMMITTED and ball.turn_count == 1 and ball.direction.is_equal_approx(ball.position.direction_to(sampled)))
	var committed: Vector3 = ball.direction; start = ball.position
	target.position -= Vector3.RIGHT * 6.0
	ball._physics_process(0.4)
	check("Committed shot stays straight despite later player movement", ball.direction.is_equal_approx(committed) and ball.target_sample_count == 1 and ball.turn_count == 1 and (ball.position - start).is_equal_approx(committed * 0.72))
	head.clear_shots(); await physics_frame
	# Normal engine-driven motion as well as deterministic phase checks.
	target.position = Vector3(0, 1.65, 10.5)
	ball = head.throw_ball()
	await ball.turn_announced
	check("Normal physics loop reaches the turn signal", ball.flight == Ball.Flight.WARNING and ball.target_sample_count == 1)
	target.position.x += 2
	await ball.turn_committed
	check("Normal physics loop commits the stored target", ball.turn_count == 1 and ball.sampled_target.x == 0)
	head.clear_shots(); await physics_frame
	var outside: Node3D = arena.heads[0]; outside.set_active(true); outside.begin_telegraph(target.position)
	var zigzag: Node3D = outside.throw_ball()
	check("Outer columns keep the zigzag with its announced floor landing", zigzag.waypoints.size() == 6 and zigzag.waypoints[-1].y < 0 and zigzag.get_script() != Ball)
	outside.clear_shots()
	await collision_checks()
	arena.rest()
	check("REST clears all field balls and keeps edited directions", head.projectiles.is_empty() and arena.floor_tile_hits.size() == 36 and arena.direction_field.sample(Vector3(1, 3, 5)).is_equal_approx(direction))
	arena.reset_round()
	check("RESET restores arrows and all earlier floor properties", arena.floor_tile_hits.is_empty() and arena.floor_marks.is_empty() and arena.direction_field.sample(Vector3(1, 3, 5)).is_equal_approx(Vector3.BACK))
	# A real form still drops a skull, including a head using the new projectile.
	world.walker.camera.make_current(); camera.queue_free(); world.walker.collision_layer = 0
	world.walker.position = head.position + Vector3(0, -1.65, 1.5); world.walker.head.look_at(head.position)
	await create_timer(0.4).timeout; click()
	for f in range(160):
		await physics_frame
		if head.destroyed: break
	check("Catalyst still defeats the new head type", head.destroyed)
	world.change_stage(4); await physics_frame; await physics_frame
	check("Returning to Tiling removes field behaviour", world.arena.stage == 4 and not is_instance_valid(world.arena.direction_field) and world.arena.heads.all(func(h): return not h.uses_field()))
	world.queue_free(); target.queue_free(); await process_frame; await physics_frame
	check("Leaving restores the earned hand ability", capacity.first_catalyst.unlocked == earned and capacity.has_first_catalyst() == earned)
	var passed := checks.filter(func(c): return c.pass).size()
	FileAccess.open(OUT + "report.json", FileAccess.WRITE).store_string(JSON.stringify({"passed": passed, "total": checks.size(), "checks": checks}, "\t"))
	print("CHANGE BIOME ", passed, "/", checks.size()); quit(0 if passed == checks.size() else 1)

func collision_checks() -> void:
	var first := Ball.new(); first.position = Vector3(0, 40, 0)
	first.field_sampler = func(p): return Vector3(sin(p.z) * 0.2, 0, 1).normalized()
	world.add_child(first); first.set_physics_process(false)
	var second := Ball.new(); second.position = first.position; second.field_sampler = first.field_sampler
	world.add_child(second); second.set_physics_process(false)
	first._physics_process(1.0); second._physics_process(0.5); second._physics_process(0.5)
	check("One elapsed interval and two halves follow the same sampled field", first.position.distance_to(second.position) < 0.001)
	first.queue_free(); second.queue_free()
	var cover := StaticBody3D.new(); cover.position = Vector3(0, 30, 1)
	var shape := CollisionShape3D.new(); var box := BoxShape3D.new(); box.size = Vector3(2, 2, 0.1)
	shape.shape = box; cover.add_child(shape); world.add_child(cover)
	await physics_frame; await physics_frame
	var ball := Ball.new(); ball.position = Vector3(0, 30, 0); ball.stage = 5
	ball.field_sampler = func(_p): return Vector3.BACK
	ball.surface_hit.connect(func(body, _at): contacts.append(body))
	world.add_child(ball); ball.set_physics_process(false); ball._physics_process(0.8)
	check("Field movement sweeps into solid cover", ball.spent and contacts.has(cover))
	await physics_frame
	cover.position.z = 4; await physics_frame; await physics_frame; contacts.clear()
	ball = Ball.new(); ball.position = Vector3(0, 30, 0); ball.stage = 5
	ball.field_sampler = func(_p): return Vector3.BACK
	ball.target_sampler = func(): return Vector3(0, 30, 8)
	ball.surface_hit.connect(func(body, _at): contacts.append(body))
	world.add_child(ball); ball.set_physics_process(false); ball._physics_process(3.5)
	check("One long tick preserves warning duration and committed collision", ball.spent and ball.turn_count == 1 and contacts.has(cover))
	cover.queue_free(); await physics_frame
	var player := CharacterBody3D.new(); player.collision_layer = 524288; player.position = Vector3(0, 30, 4)
	player.add_to_group("player_body")
	var boundary := CollisionShape3D.new(); var capsule := CapsuleShape3D.new(); capsule.radius = 0.3; capsule.height = 1.8
	boundary.shape = capsule; player.add_child(boundary); world.add_child(player)
	await physics_frame; await physics_frame
	contacts.clear(); ball = Ball.new(); ball.stage = 5; ball.position = Vector3(0, 30, 0)
	ball.field_sampler = func(_p): return Vector3.BACK
	ball.target_sampler = func(): return Vector3(0, 30, 8)
	ball.player_hit.connect(func(body): contacts.append(body))
	world.add_child(ball); ball.set_physics_process(false); ball._physics_process(3.5)
	check("Committed ball dispatches a real player-body collision", ball.spent and contacts == [player])
	player.queue_free(); await physics_frame
