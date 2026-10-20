extends SceneTree
## Exercise the shipped menu route, not the developer test launcher.
const OUT := "res://ada_run/encounter_pilot/Head_Arena_Menu/"
const STAGING := "res://commons/scenes/vr_staging.tscn"
const DESTINATION := "res://commons/hazards/catalyst_counterpart/biome_arena.tscn"
const PRESERVED := ["res://ada_run/em_control.json", "res://commons/data/museum/em_overrides.json", "res://ada_run/em_inventory.json", "res://ada_run/em_showing_cards.json", "res://ada_run/em_layout_walk.json", "res://ada_run/em_adoptions.json", "res://ada_run/em_live_footprints.json", "res://ada_run/em_pack_report.json"]
var checks: Array = []
var failures: Array = []
var revealed := false
var finished := false
var biome_records: Array = []

class SuppliedGrabber extends Node3D:
	var picked_up_ranged := false

func _initialize() -> void: run.call_deferred()

func check(label: String, passed: bool) -> void:
	checks.append({"name": label, "passed": passed})
	if not passed: failures.append(label)
	print("[menu-arena] ", "PASS " if passed else "FAIL ", label)

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	create_timer(90).timeout.connect(func(): check("menu round trip finishes in time", false); finish())
	var staging: Node3D = load(STAGING).instantiate()
	root.add_child(staging); current_scene = staging
	await create_timer(0.6).timeout
	var menu: Node3D = staging.get_node("MainMenu3D")
	var button: Node3D = menu.get_node("Buttons/HeadArenaButton")
	check("Head Arena is visible in the real game menu", button.is_visible_in_tree() and button.get_node("Label3D").text == "Head Arena")
	if OS.get_cmdline_user_args().has("--menu-only"):
		finish(); return
	await capture_menu(menu)
	var hashes: Dictionary = {}
	for path in PRESERVED: hashes[path] = FileAccess.get_sha256(path) if FileAccess.file_exists(path) else "missing"
	staging.scene_visible.connect(func(_scene, _data): revealed = true)
	button.pointer_entered()
	var began := Time.get_ticks_msec()
	while not revealed and Time.get_ticks_msec() - began < 65000: await process_frame
	check("normal pointer dwell loads and reveals the arena", revealed and staging.current_scene_path == DESTINATION)
	if not revealed or staging.current_scene == null: finish(); return
	var scene: Node3D = staging.current_scene
	var arena: Node3D = scene.arena
	check("destination supports the actual XR staging lifecycle", scene.is_xr_class("XRToolsSceneBase"))
	check("loading waits for one complete biome and its encounter", arena != null and scene.is_map_ready() and scene.habitats.size() == 1)
	if arena == null: finish(); return
	check("menu is hidden during play", not menu.visible)
	check("arena begins at rest", not arena.running and not arena.skull.active)
	check("both XR hands retain a pickup provider", scene.find_children("*", "XRToolsFunctionPickup", true, false).size() == 2)
	check("return control exists and is within reach above the soil", scene.menu_button != null and scene.menu_button.position.y - arena.height_at(scene.menu_button.position) < 1.5)
	check("arena uses the biome scene without museum architecture", scene.get_node_or_null("Museum") == null and arena.open_landscape)
	for habitat in scene.habitats:
		check("biome uses existing terrain and keeps recording off, seed " + str(habitat.seed), habitat.get_script().resource_path.ends_with("biome_object.gd") and habitat.record == "off" and habitat._patch.get_node("Ground").static_body != null)
		check_reviewed_biome(habitat)
	check("desktop preview has its own active player camera", scene._vr or root.get_camera_3d() == scene.walker.camera)
	check("biome camera overrides the hidden menu environment", root.get_camera_3d().environment == scene.environment)
	if not scene._vr:
		await create_timer(0.8).timeout
		check("desktop arrival is grounded and clear of the inactive XR capsule", scene.walker.is_on_floor() and scene.get_node("XROrigin3D").position.y < -50)
	await capture_arena(scene)
	await physics_frame
	var floor_point := arena.to_global(scene.spawn - Vector3.UP * 0.10)
	var floor_hit := arena.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(floor_point + Vector3.UP * 0.1, floor_point - Vector3.UP * 0.15, 1))
	check("arrival stands on the biome collider itself", not floor_hit.is_empty() and floor_hit.collider == arena.terrain.static_body)
	check("point is at hand height on the planted bank", is_equal_approx(arena.catalyst.position.y - arena.height_at(arena.catalyst.position), 1.18))
	var no_stage := true
	for node in arena.find_children("*", "MeshInstance3D", true, false):
		if node.mesh is BoxMesh and (node.mesh.size.x > 2.0 or node.mesh.size.z > 2.0): no_stage = false
	check("there is no flat stage or large backdrop around the encounter", no_stage and scene.find_child("ClearingGround", true, false) == null)
	var heights_match := true
	var min_ground := INF; var max_ground := -INF
	for x in [-3.25, -1.25, 0.25, 2.75]:
		for z in [-3.25, -1.25, 0.25, 2.75]:
			var p: Vector3 = arena.on_ground(Vector3(x, 0, z))
			var hit := arena.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(p + Vector3.UP * 0.03, p - Vector3.UP * 0.03, 1))
			heights_match = heights_match and not hit.is_empty() and hit.collider == arena.terrain.static_body and absf(hit.position.y - p.y) < 0.001
			min_ground = minf(min_ground, p.y); max_ground = maxf(max_ground, p.y)
	check("placement samples agree with the real terrain triangles", heights_match)
	check("encounter terrain retains its height differences", max_ground - min_ground > 0.4)
	await check_terrain_motion(arena)
	arena.start_button.pressed.emit()
	check("START activates the staged head", arena.running and arena.skull.active)
	arena.rest_button.pressed.emit()
	check("REST stops the staged head", not arena.running and not arena.skull.active)
	# Same trigger and projectile path, now against the head in the biome world.
	arena.skull.set_physics_process(false)
	var hand := SuppliedGrabber.new(); arena.add_child(hand)
	hand.position = arena.head_home + Vector3(0, 0, 2)
	arena.catalyst.global_transform = hand.global_transform
	arena.catalyst.pick_up(hand)
	arena.start_button.pressed.emit()
	for i in range(3):
		arena.skull.position = arena.head_home
		if i > 0: arena.skull.advance(2.6, hand.global_position)
		arena.catalyst.action_pressed.emit(arena.catalyst)
		await create_timer(0.7).timeout
		check("catalyst projectile interrupts the biome head " + str(i + 1), arena.round_hits == i + 1)
	check("third hit explodes the head and removes its collision", arena.completed and arena.skull.destroyed and not arena.skull.visual.visible and arena.skull.collision_layer == 0 and is_instance_valid(arena.skull.explosion))
	arena.catalyst.let_go(hand, Vector3.ZERO, Vector3.ZERO)
	hand.queue_free()
	arena.reset_button.pressed.emit()
	await create_timer(0.2).timeout
	check("RESET restores head and point on the terrain", arena.catalyst.global_position.distance_to(arena.catalyst.home.origin) < 0.001 and arena.skull.position.is_equal_approx(arena.head_home) and not arena.skull.destroyed and arena.skull.visual.visible and arena.skull.collision_layer == 2)
	if not scene._vr:
		scene.walker.position.y = -4
		scene._physics_process(0.0)
		check("fall recovery returns to the biome arrival and rests the head", scene.walker.position.is_equal_approx(scene.spawn) and not arena.running)
	for path in PRESERVED:
		var now := FileAccess.get_sha256(path) if FileAccess.file_exists(path) else "missing"
		check("practice preserves " + path.get_file(), hashes[path] == now)
	var old_id := staging.get_instance_id()
	scene.menu_button.pressed.emit()
	await process_frame
	await process_frame
	await create_timer(1.0).timeout
	check("MAIN MENU preserves the existing XR staging session", current_scene != null and current_scene.get_instance_id() == old_id and staging.current_scene == null and menu.visible)
	if current_scene != null and current_scene.scene_file_path == STAGING:
		var returned: Node3D = current_scene.get_node("MainMenu3D")
		check("Head Arena remains selectable after returning", returned.visible and not returned._entering_head_arena)
	finish()

func check_terrain_motion(arena: Node3D) -> void:
	var head: CharacterBody3D = arena.skull
	head.set_physics_process(false)
	var target: Vector3 = arena.on_ground(Vector3(1, 0, 2), 1.6)
	arena.set_operation(3)
	var clear_of_soil := true
	var stays_inside := true
	var start: Vector3 = head.position
	for i in range(180):
		head.advance(1.0 / 30.0, target)
		clear_of_soil = clear_of_soil and head.position.y - head.boundary.radius > arena.height_at(head.position) + 0.1
		stays_inside = stays_inside and head.travel_bounds.has_point(head.position)
		await physics_frame
	check("orbit and scaled collider remain above the soil and within the biome", clear_of_soil and stays_inside and head.position.distance_to(start) > 0.3)
	arena.start_round()
	head.advance(2.01, target)
	var destination: Vector3 = head.destination
	head.advance(0.1, target + Vector3(2, 0, 0))
	check("terrain encounter keeps its announced charge endpoint", destination.is_equal_approx(head.destination) and head.cue.visible)
	var before: Vector3 = head.position
	for i in range(90):
		head.advance(1.0 / 30.0, target)
		clear_of_soil = clear_of_soil and head.position.y - head.boundary.radius > arena.height_at(head.position) + 0.1
		await physics_frame
	check("head travels across the planted terrain without sinking through it", clear_of_soil and head.position.distance_to(before) > 0.5)
	arena.set_operation(1)

func check_reviewed_biome(habitat: Node3D) -> void:
	var state: Dictionary = habitat.get_state()
	var path := "res://ada_run/biome_rsi/gen_17/state_%s.json" % state.label
	var reference: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else {}
	var suffix := ", seed " + str(habitat.seed)
	check("biome is the last kept RSI generation" + suffix, state.generation == 17 and not reference.is_empty())
	if reference.is_empty(): return
	check("reviewed terrain and community DNA are retained" + suffix,
		same_values(state.dna, reference.dna) and same_values(state.community_dna, reference.community_dna)
		and habitat.stage == "full" and habitat.phase == 1.0 and habitat.foliage == "drawn")
	var counts_match := true
	for key in reference.counts:
		if not str(key).begins_with("ms_") and not same_values(state.counts.get(key), reference.counts[key]):
			counts_match = false
			print("[biome difference] ", state.label, " ", key, " actual=", state.counts.get(key), " reviewed=", reference.counts[key])
	check("all reviewed ecology counts survive arena placement" + suffix, counts_match)
	var residents_match: bool = state.residents.size() == reference.residents.size()
	for i in range(mini(state.residents.size(), reference.residents.size())):
		var resident: Dictionary = state.residents[i]
		var original: Dictionary = reference.residents[i]
		for key in ["artifact", "family", "body_seed", "dna", "position", "scale", "faces"]:
			if not same_values(resident.get(key), original.get(key)): residents_match = false
		residents_match = residents_match and habitat._patch.has_node(NodePath(resident.node))
	check("reviewed resident bodies and local placement are present" + suffix, residents_match)
	biome_records.append({"reference": path, "generation": state.generation, "dna": state.dna,
		"community_dna": state.community_dna, "counts": state.counts,
		"counts_match": counts_match, "residents_match": residents_match})

func same_values(actual: Variant, expected: Variant) -> bool:
	if (actual is float or actual is int) and (expected is float or expected is int):
		return absf(float(actual) - float(expected)) < 0.0001
	if actual is Dictionary and expected is Dictionary:
		if actual.size() != expected.size(): return false
		for key in expected:
			if not actual.has(key) or not same_values(actual[key], expected[key]): return false
		return true
	if actual is Array and expected is Array:
		if actual.size() != expected.size(): return false
		for i in expected.size():
			if not same_values(actual[i], expected[i]): return false
		return true
	return actual == expected

func capture_arena(scene: Node3D) -> void:
	if DisplayServer.get_name() == "headless": return
	var old := root.get_camera_3d()
	var camera := Camera3D.new(); root.add_child(camera); camera.make_current()
	camera.environment = scene.environment
	camera.position = scene.arena.on_ground(Vector3(0, 0, 4.8), 1.6)
	camera.look_at(scene.arena.head_home); camera.fov = 78
	await create_timer(0.4).timeout; await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + "biome-arena-entry.png"))
	camera.position = scene.arena.on_ground(Vector3(-2.6, 0, 4.35), 1.6)
	camera.look_at(scene.arena.on_ground(Vector3(-0.1, 0, -0.5), 1.2)); camera.fov = 74
	await create_timer(0.3).timeout; await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + "biome-arena-side.png"))
	camera.position = scene.arena.on_ground(Vector3(1.6, 0, 5.5), 1.6)
	camera.look_at(Vector3(1.6, scene.arena.console_ground + 1.22, 3.4)); camera.fov = 67
	await create_timer(0.3).timeout; await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + "biome-arena-controls.png"))
	camera.queue_free()
	if old != null: old.make_current()

func capture_menu(menu: Node3D) -> void:
	if DisplayServer.get_name() == "headless": return
	menu.get_node("MenuFollower").set_process(false)
	var old := root.get_camera_3d()
	var camera := Camera3D.new()
	root.add_child(camera)
	root.size = Vector2i(1440, 1000)
	camera.global_position = menu.to_global(Vector3(0, 0.1, 3.3))
	camera.look_at(menu.to_global(Vector3(0, 0.1, 0)))
	camera.fov = 51
	camera.make_current()
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + "menu.png"))
	camera.queue_free()
	if old != null: old.make_current()
	menu.get_node("MenuFollower").set_process(true)

func finish() -> void:
	if finished: return
	finished = true
	FileAccess.open(OUT + "report.json", FileAccess.WRITE).store_string(JSON.stringify({"passed": failures.is_empty(), "checks": checks, "failures": failures, "biomes": biome_records, "scope": "Real game menu, pointer dwell, staged arena and return. XR hardware poses are not supplied; headset comfort remains untested."}, "  "))
	print("HEAD ARENA MENU ", checks.size() - failures.size(), "/", checks.size())
	# The menu deliberately leaves two background preloads waiting for a later
	# selection. Consume those requests before this short-lived probe exits.
	for path in ["res://commons/scenes/lab.tscn", "res://commons/scenes/endless_museum_staged.tscn"]:
		while ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			await process_frame
		if ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_LOADED:
			ResourceLoader.load_threaded_get(path)
	if current_scene != null: current_scene.queue_free()
	await process_frame
	await process_frame
	quit(0 if failures.is_empty() else 1)
