extends SceneTree
## Live Godot 4.6 verification probe for Act III Care Unit infrastructure:
##   F050 VFM_03_Motion          -> f50-dead-charger (wall_charger_dead: NO MAINS, snapped ceiling trunking, 0% charge)
##   F051 Vectors_Act3_Fields... -> f51-pill-battery (coin_pedestal: +15%)
##   F056 VFM_09_Legs            -> f56-power-cell (void_care_power_cell: +20%)
##   F058 Vectors_Act5_ForceAs.. -> f58-charging-stand (wall_charger: live CHARGING, intact HardwareSupply)
##   F060 FormFinding_Catenary   -> f60-pill-battery (coin_pedestal: +15%)

var out := "doc/book/iterations/2026-11-25-act3-care-infrastructure"
var checks: Array[Dictionary] = []
var failed: Array[String] = []
var game: Node

func _initialize() -> void:
	run.call_deferred()

func check(label: String, passed: bool, detail := "") -> void:
	checks.append({"name": label, "passed": passed, "detail": detail})
	if not passed:
		failed.append(label)
	print("[act3] ", "PASS " if passed else "FAIL ", label, (" :: " + detail if detail else ""))

func frames(count: int) -> void:
	for i in range(count):
		await physics_frame
	await process_frame

func _floor_index_for(map_name: String) -> int:
	for i in range(game.building.content.data.floors.size()):
		if str(game.building.content.data.floors[i].map) == map_name:
			return i
	return -1

func photograph(filename: String, at: Vector3, target: Vector3) -> void:
	var camera := Camera3D.new()
	game.add_child(camera)
	camera.global_position = at
	camera.look_at(target, Vector3.UP)
	camera.current = true
	if game.get("desktop_help") != null:
		game.desktop_help.hide()
	game.notice_time = 0
	await frames(8)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(filename))
	camera.queue_free()
	game.camera.current = true
	await frames(2)

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(out)
	check("isolated saves", OS.get_user_data_dir().contains("Ada Void Trial Test"))

	load("res://commons/void/room_source.gd").use_main_tower = true
	game = load("res://commons/void/void.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	if game.body.get("scripted_input") != null:
		game.body.scripted_input = true
		game.body.set_process_unhandled_input(false)
	game.scene_loaded()
	game.scene_visible()
	await frames(30)

	# 1. F050 VFM_03_Motion — Dead NO MAINS floor-plate charging stand
	var f50 := _floor_index_for("VFM_03_Motion")
	check("F050 VFM_03_Motion found at floor 50", f50 == 50, "idx=%d" % f50)
	game.place_player(game.spawn_for(f50))
	await frames(45)
	var dead_key := "%d/f50-dead-charger" % f50
	check("F050 dead charger spawned", game.building.content.props.has(dead_key))
	if game.building.content.props.has(dead_key):
		var dead_stand: Node3D = game.building.content.props[dead_key].get_node("Prefab")
		check("F050 dead stand has mains_online=false & powered=false", not dead_stand.mains_online and not dead_stand.powered)
		check("F050 dead stand builds BrokenMainsSupply (no intact HardwareSupply)", dead_stand.has_node("BrokenMainsSupply") and not dead_stand.has_node("HardwareSupply"))
		check("F050 dead stand keeps anonymous CHARGE title (zero branding)", dead_stand._readout.title == "CHARGE" and not dead_stand.has_node("SurfaceMark"))
		game.health.set_health(60.0)
		game.place_player(dead_stand.to_global(Vector3(0.0, 0.06, 0.76)))
		await frames(60)
		check("F050 stepping on dead plate depresses deck mechanically", dead_stand.plate_active and is_equal_approx(dead_stand.plate_deck.position.y, dead_stand.PLATE_PRESSED_Y))
		check("F050 dead stand reads NO MAINS and adds 0 charge", dead_stand._face().contains("NO MAINS") and is_equal_approx(game.health.get_health(), 60.0), "face=%s hp=%.1f" % [dead_stand._face().replace("\n", "/"), game.health.get_health()])
		if "--capture" in OS.get_cmdline_user_args():
			await photograph("f50_dead_charger.png", dead_stand.to_global(Vector3(1.9, 1.95, 3.4)), dead_stand.to_global(Vector3(0.0, 1.85, 0.0)))

	# 2. F051, F056, F060 portable cells
	for spec in [
		["Vectors_Act3_FieldsAndMotion", "f51-pill-battery"],
		["VFM_09_Legs", "f56-power-cell"],
		["FormFinding_Catenary", "f60-pill-battery"],
	]:
		var idx := _floor_index_for(spec[0])
		game.place_player(game.spawn_for(idx))
		await frames(40)
		var art_key := "%d/%s" % [idx, spec[1]]
		check("%s (%s) spawned on F%03d" % [spec[1], spec[0], idx], game.building.content.exhibits.has(art_key))

	# 3. F058 Vectors_Act5_ForceAsPlace — Working floor-plate charging stand (8 floors below F050)
	var f58 := _floor_index_for("Vectors_Act5_ForceAsPlace")
	check("F058 Vectors_Act5_ForceAsPlace found at floor 58", f58 == 58, "idx=%d" % f58)
	game.place_player(game.spawn_for(f58))
	await frames(45)
	var live_key := "%d/f58-charging-stand" % f58
	check("F058 live charger spawned", game.building.content.props.has(live_key))
	if game.building.content.props.has(live_key):
		var live_stand: Node3D = game.building.content.props[live_key].get_node("Prefab")
		check("F058 live stand has mains_online=true & intact HardwareSupply", live_stand.mains_online and live_stand.powered and live_stand.has_node("HardwareSupply"))
		game.health.set_health(60.0)
		game.place_player(live_stand.to_global(Vector3(0.0, 0.06, 0.76)))
		await frames(90)
		check("F058 live stand charges progressively on floor plate", game.health.get_health() > 65.0 and live_stand.plate_active and live_stand._face().contains("CHARGING"), "face=%s hp=%.1f" % [live_stand._face().replace("\n", "/"), game.health.get_health()])
		if "--capture" in OS.get_cmdline_user_args():
			await photograph("f58_live_charger.png", live_stand.to_global(Vector3(1.8, 1.75, 2.9)), live_stand.to_global(Vector3(0.0, 1.15, 0.2)))

	game.queue_free()
	await frames(5)
	FileAccess.open(out.path_join("checks.json"), FileAccess.WRITE).store_string(JSON.stringify({
		"passed": failed.is_empty(),
		"checks": checks,
		"failed": failed,
		"scope": "Act III Care Unit infrastructure: dead NO MAINS floor-plate stand on F050, portable cells on F051/F056/F060, working floor-plate stand on F058."
	}, "\t"))
	quit(0 if failed.is_empty() else 1)
