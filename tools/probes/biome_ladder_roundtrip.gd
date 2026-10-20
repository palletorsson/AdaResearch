extends SceneTree
const OUT := "res://ada_run/biome_ladder_play/roundtrip/"
const DESTINATION := "res://commons/hazards/biome_ladder/ladder_world.tscn"
var checks: Array = []
var failures: Array = []
var deaths := 0
var finished := false
var arena_reveals := 0

func _initialize() -> void: run.call_deferred()
func check(label: String, passed: bool) -> void:
	checks.append({"name": label, "passed": passed})
	if not passed: failures.append(label)
	print("[combat] ", "PASS " if passed else "FAIL ", label)

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	create_timer(100).timeout.connect(func(): check("combat/death/return completes in time", false); finish())
	var capacity: Node = root.get_node("CatalystCapabilityManager")
	capacity.progression_file = OUT + "test-save.json"
	capacity.reset_progression()
	var staging: Node3D = load("res://commons/scenes/vr_staging.tscn").instantiate()
	root.add_child(staging); current_scene = staging
	staging.scene_visible.connect(func(_scene, _data):
		if staging.current_scene_path == DESTINATION: arena_reveals += 1)
	await create_timer(0.7).timeout
	staging.get_node("MainMenu3D/Buttons/BiomeLadderButton").pointer_entered()
	while arena_reveals < 1: await process_frame
	await create_timer(1.0).timeout
	var scene: Node3D = staging.current_scene
	var arena: Node3D = scene.arena
	var skull: CharacterBody3D = arena.heads[0]
	var game: Node = root.get_node("GameManager")
	game.player_died.connect(func(_at): deaths += 1)
	game.register_player(scene.walker)
	var ability: Node3D = capacity.first_catalyst
	check("fresh-save arena supplies the hand ability for practice", ability.unlocked and not capacity.has_first_catalyst())
	ability.set_physics_process(false)
	skull.set_physics_process(false)
	arena.start_round()
	# The earned hand form, not the separate held test catalyst, hits the real head.
	for i in range(1):
		var mid := skull.global_position + Vector3(0, 0, 1.7)
		ability.update_hands(Transform3D(Basis.IDENTITY, mid + Vector3(-0.1,0,0)), Transform3D(Basis.IDENTITY, mid + Vector3(0.1,0,0)), true, true, 0.2)
		ability._cooldown = 0.0
		var shot: RigidBody3D = ability.send_form(Vector3.FORWARD)
		check("formed ball is a real projectile " + str(i + 1), shot != null)
		await create_timer(0.28 if i == 2 else 0.55).timeout
		check("one projectile counts one skull hit " + str(i + 1), skull.incoming_hits == i + 1)
	check("one sphere drops the skull without leaving a blocker", skull.destroyed and skull.collision_layer == 0)
	await capture("explosion")
	arena.reset_round()
	check("reset restores the head with zero damage", not skull.destroyed and skull.incoming_hits == 0 and skull.collision_layer == 2)
	ability._hide_all()
	arena.start_round()
	for other in arena.heads:
		other.set_physics_process(false)
	# Launch at the actual player's capsule. Each hit traverses physics, the skull
	# signal, arena health accounting and GameManager; no direct damage invocation.
	for i in range(3):
		var target: Vector3 = scene.walker.global_position + Vector3.UP * 1.1
		skull.global_position = target + Vector3(0, 0, -2.0)
		skull.begin_telegraph(arena.to_local(target))
		skull.advance(skull.WINDUP + 0.01, target)
		check("warning completes and skull fires autonomously " + str(i + 1), skull.projectiles.size() == 1)
		await create_timer(1.4).timeout
		check("player registers exactly one hit " + str(i + 1), arena.player_hits == i + 1)
		if i < 2: check("player survives hit " + str(i + 1), game.get_health() > 0 and deaths == 0)
	check("third hit reaches the real death system once", deaths == 1 and game._death_sequence_running and arena.player_dead and not arena.running)
	check("death remembers this encounter destination", game.get_meta("encounter_return_scene", "") == DESTINATION)
	var began := Time.get_ticks_msec()
	while staging.current_scene_path != "res://commons/scenes/death_scene_staged.tscn" and Time.get_ticks_msec() - began < 15000: await process_frame
	check("death effect reaches the staged death scene", staging.current_scene_path == "res://commons/scenes/death_scene_staged.tscn")
	while arena_reveals < 2 and Time.get_ticks_msec() - began < 45000: await process_frame
	check("continue returns to the same biome through staging", staging.current_scene_path == DESTINATION and staging.current_scene != null and staging.current_scene.is_map_ready())
	check("practice hand ability returns after death without earning museum progression", not capacity.has_first_catalyst() and capacity.first_catalyst.unlocked)
	check("return restores full health and consumes return address", is_equal_approx(game.get_health(), game.max_player_health) and not game.has_meta("encounter_return_scene"))
	if staging.current_scene_path == DESTINATION:
		check("new round begins safe with intact head", not staging.current_scene.arena.running and not staging.current_scene.arena.heads[0].destroyed)
		staging.current_scene.return_to_menu()
	await create_timer(1.0).timeout
	check("menu is still usable after death roundtrip", staging.current_scene == null and staging.get_node("MainMenu3D").visible)
	check("leaving practice restores the unearned museum ability state", not capacity.first_catalyst.unlocked and not capacity.has_first_catalyst())
	finish()

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + label + ".png"))

func finish() -> void:
	if finished: return
	finished = true
	FileAccess.open(OUT + "report.json", FileAccess.WRITE).store_string(JSON.stringify({"passed": failures.is_empty(), "checks": checks, "failures": failures}, "  "))
	print("COMBAT ", checks.size() - failures.size(), "/", checks.size())
	for path in ["res://commons/scenes/lab.tscn", "res://commons/scenes/endless_museum_staged.tscn"]:
		while ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS: await process_frame
		if ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_LOADED: ResourceLoader.load_threaded_get(path)
	quit(0 if failures.is_empty() else 1)
