extends SceneTree
const Route := preload("res://commons/hazards/biome_ladder/route.gd")
const OUT := "res://ada_run/biome_tiling_feedback/"
var checks: Array[Dictionary] = []
var world: Node3D
var arena: Node3D
var shots: Array[Node3D] = []

func _initialize() -> void: run.call_deferred()
func check(label: String, ok: bool) -> void:
	checks.append({"label": label, "pass": ok})
	print("[feedback] ", "PASS " if ok else "FAIL ", label)

func capture(file: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT + file + ".png")

func walk_to(target: Vector3) -> bool:
	var walker: CharacterBody3D = world.walker
	walker.position = arena.arrival; walker.velocity = Vector3.ZERO
	await physics_frame
	for f in range(650):
		var offset := Vector3(target.x - walker.position.x, 0, target.z - walker.position.z)
		if offset.length() < 0.9: return true
		walker.velocity = offset.normalized() * 2.5 + Vector3.DOWN * 2.0
		walker.move_and_slide(); await physics_frame
	return false

func run() -> void:
	create_timer(180).timeout.connect(func(): push_error("Feedback probe timeout"); quit(2))
	DirAccess.make_dir_recursive_absolute(OUT)
	root.get_node("CatalystCapabilityManager").progression_file = OUT + "isolated.json"
	Route.selected_stage = 4
	world = load(Route.SCENE).instantiate(); root.add_child(world); current_scene = world
	for f in range(600):
		await process_frame
		if world.is_map_ready(): break
	check("World ready", world.is_map_ready())
	arena = world.arena
	world.walker.set_physics_process(false); world.walker.camera.make_current()
	arena.set_process(false); arena.set_physics_process(false)
	for head in arena.heads: head.set_physics_process(false)
	var xr_body: PhysicsBody3D = world.get_node("XROrigin3D/PlayerBody")
	check("Desktop ignores only paint tiles", arena.floor_tile_bodies.all(func(t): return t in world.walker.get_collision_exceptions()) and arena.floor_body not in world.walker.get_collision_exceptions())
	check("XR body shares the same walking floor", arena.floor_tile_bodies.all(func(t): return t in xr_body.get_collision_exceptions()) and arena.floor_body not in xr_body.get_collision_exceptions())
	var ability: Node3D = root.get_node("CatalystCapabilityManager").first_catalyst
	ability.form_sent.connect(func(s): shots.append(s))
	world.walker.position = Vector3(0, 0.12, 10.5)
	world.walker.head.look_at(Vector3(-1, 0.04, 9))
	await create_timer(0.35).timeout
	var event := InputEventMouseButton.new(); event.button_index = MOUSE_BUTTON_LEFT; event.pressed = true
	root.push_input(event); event = event.duplicate(); event.pressed = false; root.push_input(event)
	for f in range(120):
		await physics_frame
		if arena.floor_tile_hits.size() > 0: break
	check("Real desktop shot repeats the tile operation", shots.size() == 1 and arena.floor_tile_hits.size() == 18)
	check("All 18 copies flash in the same frame", arena.floor_flashes.size() == 18 and arena.floor_flashes.keys().all(func(i): return arena.flash_views[i].visible and is_equal_approx(arena.floor_flashes[i], arena.FLASH_SECONDS)))
	check("Other motif addresses do not flash", arena.flash_views.filter(func(v): return v.visible).size() == 18)
	world.walker.position = Vector3(0.3, 0.12, 8.2); world.walker.head.look_at(Vector3(0, 0, -2))
	await capture("flash-standing")
	var camera := Camera3D.new(); world.add_child(camera)
	camera.position = Vector3(10, 12, 16); camera.look_at(Vector3(0, 0, -1)); camera.make_current()
	await capture("flash-overview"); camera.queue_free(); world.walker.camera.make_current()
	var marks: Dictionary = arena.floor_marks.duplicate()
	arena._update_flashes(arena.FLASH_SECONDS + 0.01)
	check("Flash fades without losing paint or transforms", arena.floor_flashes.is_empty() and arena.flash_views.all(func(v): return not v.visible) and arena.floor_marks == marks and arena.floor_tile_hits.size() == 18)
	# Reproduce the old obstruction by removing only this fix, in the probe.
	for tile in arena.floor_tile_bodies: world.walker.remove_collision_exception_with(tile)
	check("Old tile-edge obstruction reproduced", not await walk_to(Vector3(3.2, 1.48, 9.6)))
	arena.set_walking_body(world.walker)
	for button in arena.get_children().filter(func(c): return c.has_method("_relay")):
		check("Walk reaches " + str(button.label), await walk_to(button.position))
	# A ray still meets a paint tile: collision has not been disabled for shots.
	var hit := world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(-1, 1, 9), Vector3(-1, -1, 9), 1))
	check("Projectile mask still sees a changed tile", hit.get("collider") == arena.floor_tile_bodies[62])
	arena.reset_round()
	check("RESET clears flash and marks", arena.floor_flashes.is_empty() and arena.floor_marks.is_empty())
	world.change_stage(3); await physics_frame
	check("Next stage binds its new tile colliders", world.arena.floor_tile_bodies.all(func(t): return t in world.walker.get_collision_exceptions()))
	world.queue_free(); await process_frame
	var passed := checks.filter(func(c): return c.pass).size()
	var f := FileAccess.open(OUT + "report.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"passed": passed, "total": checks.size(), "checks": checks}, "\t")); f.close()
	print("TILING FEEDBACK ", passed, "/", checks.size()); quit(0 if passed == checks.size() else 1)
