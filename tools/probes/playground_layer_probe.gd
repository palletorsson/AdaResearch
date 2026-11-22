extends SceneTree
## Live Godot 4.6 verification & visual capture probe for the 26-Sequence
## General Intellect Playground Layer:
##   1. F7 Point_Animatedcube Package -> walk over grants +25% Health & Battery + drops HealthCross
##   2. F8 Primitives_Ignorance Proximity Bomb -> detonates when approached & drains battery
##   3. Power Coin -> adds +8% Battery Power to the unit
##   4. F7 strict monochrome / zero spoilers vs F33 Color+Arrays+Objects vs F209 Full Atelier
##   5. F209 live Array 1D/2D/3D, Panel Patterns, Random Walk Generator, Spiky Basin,
##      Configurable Smooth Noise Basin, Placeable Package/Coin/Bomb/JumpPad/Iso4x4, and 1:1 VR Visor view!

const OUT_DIR := "res://doc/book/iterations/2026-11-22-general-intellect-playground-layer"

var _results: Array[Dictionary] = []
var _failed := 0


func _initialize() -> void:
	call_deferred("_run")


func _check(label: String, ok: bool, detail: String = "") -> void:
	if not ok:
		_failed += 1
	print("[%s] %s%s" % ["PASS" if ok else "FAIL", label, (" — " + detail) if not detail.is_empty() else ""])
	_results.append({"label": label, "ok": ok, "detail": detail})


func _frames(n: int) -> void:
	for _i in n:
		await process_frame


func _phys(n: int) -> void:
	for _i in n:
		await physics_frame


func _shot(cam: Camera3D, pos: Vector3, look: Vector3, filename: String) -> void:
	cam.current = true
	cam.global_position = pos
	cam.look_at(look, Vector3.UP)
	await _frames(8)
	await RenderingServer.frame_post_draw
	var img: Image = root.get_viewport().get_texture().get_image()
	var full: String = ProjectSettings.globalize_path(OUT_DIR + "/" + filename)
	DirAccess.make_dir_recursive_absolute(full.get_base_dir())
	img.save_png(full)
	print("SHOT ", filename, " bytes=", FileAccess.get_file_as_bytes(full).size())


func _run() -> void:
	var abs_out := ProjectSettings.globalize_path(OUT_DIR)
	DirAccess.make_dir_recursive_absolute(abs_out)

	var Layer: Script = load("res://commons/artifacts/scaffold_workstation/playground_layer.gd")
	var spec: Dictionary = Layer.call("spec")
	_check("1A playground_layer.json loads all 26 sequences & 8 arcs",
		(spec.get("sequences", []) as Array).size() == 26 and (spec.get("arcs", []) as Array).size() == 8,
		"sequences=%d arcs=%d" % [(spec.get("sequences", []) as Array).size(), (spec.get("arcs", []) as Array).size()])

	var c7: Dictionary = Layer.call("capabilities_for_floor", 7)
	var c13: Dictionary = Layer.call("capabilities_for_floor", 13)
	var c33: Dictionary = Layer.call("capabilities_for_floor", 33)
	var c209: Dictionary = Layer.call("capabilities_for_floor", 209)
	_check("1B Sequence progression gates strictly by floor (F7 -> F13 -> F33 -> F209)",
		not bool(c7.kinetic_objects) and bool(c13.kinetic_objects) and not bool(c13.color_palettes)
		and bool(c33.arrays) and bool(c33.color_palettes) and not bool(c33.random_walk)
		and bool(c209.random_walk) and bool(c209.noise_surface) and bool(c209.iso_cutouts))

	# ── Boot live Void Tower at F209 ──
	Engine.physics_ticks_per_second = 90
	load("res://commons/void/room_source.gd").use_main_tower = true
	load("res://commons/void/game.gd").requested_floor = 209
	var game: Node = load("res://commons/void/void.tscn").instantiate()
	game.force_xr = false
	root.add_child(game)
	current_scene = game
	game.scene_loaded()
	game.scene_visible()
	game.set_process_unhandled_key_input(false)
	game.body.scripted_input = true
	game.body.set_process_unhandled_input(false)
	if game.get("soundscape") != null:
		game.soundscape.process_mode = Node.PROCESS_MODE_DISABLED
	await _frames(45)
	game.body.visible = false
	game.status.hide()
	game.charge_display.hide()
	game.notice_time = 0
	if game.desktop_help != null:
		game.desktop_help.hide()

	var content: Node = game.building.content
	var hp: Node = get_first_node_in_group("void_health")
	var cam := Camera3D.new()
	cam.fov = 54.0
	cam.far = 160.0
	root.add_child(cam)

	# ── Test 2: F7 Point_Animatedcube Package (Health + Battery Power Up) & Zero-Spoiler Studio ──
	game.place_player(game.spawn_for(7))
	content.call("load_floor", 7, true)
	await _frames(18)
	var f7_root: Node3D = content.roots[7]
	var pkg_mount: Node3D = f7_root.get_node_or_null("animatedcube-health-package")
	var pkg: Node3D = pkg_mount.get_node_or_null("Artifact") if pkg_mount != null else null
	var ws7_mount: Node3D = f7_root.get_node_or_null("scaffold-workstation")
	var ws7_ctrl: Node3D = ws7_mount.get_node("Artifact").get("studio_ctrl") if ws7_mount != null else null
	var ws7_layers: int = int((ws7_ctrl.call("get_layer_state") as Dictionary).get("layer_tile_count", -1)) if ws7_ctrl != null else -1
	_check("2A F007 Studio Workstation keeps zero sequence-layer spoilers (layer_tiles=%d)" % ws7_layers,
		ws7_ctrl != null and ws7_layers == 0)

	if pkg_mount != null:
		await _shot(cam, pkg_mount.to_global(Vector3(-1.4, 1.45, 2.3)), pkg_mount.to_global(Vector3(0.0, 0.45, 0.0)), "01-f07-animatedcube-package.png")

	var had_pkg: bool = pkg != null
	var hp_before_pkg: float = 55.0
	if hp != null:
		hp.call("set_charge", hp_before_pkg, "probe_setup")
	if pkg != null and pkg.has_method("collect"):
		pkg.call("collect")
		await _frames(6)
	var hp_after_pkg: float = float(hp.call("get_charge")) if hp != null else 0.0
	var dropped_cross: Node = pkg_mount.get_node_or_null("DroppedHealthPowerUp") if pkg_mount != null else null
	_check("2B F007 Package grants +25%% Health & Battery (%.1f -> %.1f) and drops HealthPowerUp" % [hp_before_pkg, hp_after_pkg],
		had_pkg and is_equal_approx(hp_after_pkg, 80.0) and dropped_cross != null)

	# ── Test 3: F8 Primitives_Ignorance Proximity Bomb ──
	game.place_player(game.spawn_for(8))
	content.call("load_floor", 8, true)
	await _frames(18)
	var f8_root: Node3D = content.roots[8]
	var bomb_mount: Node3D = f8_root.get_node_or_null("ignorance-proximity-bomb")
	var bomb: Node3D = bomb_mount.get_node_or_null("Artifact") if bomb_mount != null else null
	if bomb_mount != null:
		await _shot(cam, bomb_mount.to_global(Vector3(1.8, 1.55, 2.5)), bomb_mount.to_global(Vector3(0.0, 0.45, 0.0)), "02-f08-ignorance-bomb.png")

	var boom_fired := {"ok": false, "reason": ""}
	if bomb != null:
		bomb.connect("exploded", func(reason: String):
			boom_fired.ok = true
			boom_fired.reason = reason
		)
		if hp != null:
			hp.call("set_charge", 90.0, "probe_setup")
		# Wait for arm_delay (1.0s) and move Model B right beside the bomb (0.7m < proximity_radius 1.85m).
		bomb.set("age", 2.0)
		game.body.global_position = bomb_mount.global_position + Vector3(0.65, 0.06, 0.0)
		for _step in 110:
			await physics_frame
			if boom_fired.ok:
				break
	var hp_after_bomb: float = float(hp.call("get_charge")) if hp != null else 90.0
	_check("3A F008 Primitives_Ignorance Proximity Bomb blows up when approached (reason=%s, battery 90 -> %.1f)" % [str(boom_fired.reason), hp_after_bomb],
		bomb != null and bool(boom_fired.ok) and hp_after_bomb < 90.0)

	# ── Test 4: Power Coin Battery Power Recharge ──
	var coin_scene: PackedScene = load("res://commons/void/coin_pickup.tscn")
	var coin := coin_scene.instantiate() as Node3D
	coin.set_meta("config_battery_boost", 8.0)
	f8_root.add_child(coin)
	await _frames(2)
	if hp != null:
		hp.call("set_charge", 60.0, "probe_setup")
	coin.call("collect")
	await _frames(3)
	var hp_after_coin: float = float(hp.call("get_charge")) if hp != null else 0.0
	_check("4A Power Coin recharges Model B unit battery (+8%%: 60.0 -> %.1f)" % hp_after_coin,
		is_equal_approx(hp_after_coin, 68.0))
	if is_instance_valid(coin):
		coin.queue_free()

	# ── Test 5: F33 Color_Grid_Pallet Mid-Progression Studio Check ──
	game.place_player(game.spawn_for(33))
	content.call("load_floor", 33, true)
	await _frames(16)
	var f33_root: Node3D = content.roots[33]
	var ws33_ctrl: Node3D = f33_root.get_node("scaffold-workstation/Artifact").get("studio_ctrl") as Node3D
	var st33: Dictionary = ws33_ctrl.call("get_layer_state")
	_check("5A F033 unlocks Objects + Arrays + Spray + Palettes (tiles=%d), locks Random/Noise/Iso" % int(st33.layer_tile_count),
		int(st33.layer_tile_count) == 5 and bool(st33.capabilities.arrays) and not bool(st33.capabilities.random_walk))

	# ── Test 6: F209 Full General Intellect Playground Atelier ──
	game.place_player(game.spawn_for(209))
	content.call("load_floor", 209, true)
	await _frames(18)
	var f209_root: Node3D = content.roots[209]
	var ws209_mount: Node3D = f209_root.get_node("construction-stock")
	var ws209: Node3D = ws209_mount.get_node("Artifact")
	var st209: Node3D = ws209.get("studio_ctrl") as Node3D
	var ls0: Dictionary = st209.call("get_layer_state")
	_check("6A F209 Full Atelier exposes all 16 Sequence Layer tiles across 2 terraced rows (tiles=%d)" % int(ls0.layer_tile_count),
		int(ls0.layer_tile_count) == 16)

	# Close-up of the upgraded F209 console showing Near Template Strip + Far Palette Strip + Rear Sequence Layer Strip!
	await _shot(cam, ws209_mount.to_global(Vector3(-0.22, 1.98, 1.48)), ws209_mount.to_global(Vector3(-0.18, 1.02, -0.25)), "03-f209-layer-console-closeup.png")

	# Test 1D Array Mode + Panel Pattern + Random Walk Generator!
	var arr_next: String = str(st209.call("cycle_array_mode"))
	var pat_next: String = str(st209.call("cycle_panel_pattern"))
	var rw_plan: Dictionary = st209.call("generate_random_walk", 2026)
	await _frames(8)
	var structure: Node3D = ws209.output.get_node("Structure")
	var has_pkg := structure.find_child("LiveObj_package", true, false) != null
	var has_coin := structure.find_child("LiveObj_coin", true, false) != null
	var has_bomb := structure.find_child("LiveObj_bomb", true, false) != null
	var has_pad := structure.find_child("LiveObj_jump_pad", true, false) != null
	var has_iso := structure.find_child("LiveObj_iso_cutout", true, false) != null
	_check("6B Array(%s), Pattern(%s), Random Walk(%d bays) spawns live Package/Coin/Bomb/JumpPad/Iso4x4" % [arr_next, pat_next, int(rw_plan.get("steps", 0))],
		arr_next == "1d" and pat_next == "checker" and has_pkg and has_coin and has_bomb and has_pad and has_iso)

	await _shot(cam, ws209_mount.to_global(Vector3(-2.8, 2.55, 3.6)), ws209_mount.to_global(Vector3(0.0, 1.05, -2.6)), "04-f209-random-walk-with-objects.png")

	# Test Randomness Spiky Basin Surface (with physical walkable collider inside 1:4 glass box!)
	var ok_spikes: bool = bool(st209.call("set_basin_surface", "spikes"))
	await _frames(8)
	var spike_col: Node = st209.get("glass_basin").find_child("SurfaceCollider", true, false)
	_check("6C Randomness Hard-to-Walk Spiky Basin builds 1:16 miniature + 1:4 physical trimesh collider",
		ok_spikes and spike_col != null)
	await _shot(cam, ws209_mount.to_global(Vector3(2.8, 2.55, 2.8)), ws209_mount.to_global(Vector3(0.0, 0.85, -3.6)), "05-f209-basin-spikes.png")

	# Test Configurable Walkable Smooth Noise Surface!
	var ok_noise: bool = bool(st209.call("set_basin_surface", "noise", {"generator": "simplex", "octaves": 4, "amplitude": 0.92, "frequency": 0.28, "seed": 77}))
	await _frames(8)
	var noise_col: Node = st209.get("glass_basin").find_child("SurfaceCollider", true, false)
	var ncfg: Dictionary = (st209.call("get_layer_state") as Dictionary).get("noise_config", {})
	_check("6D Noise Walkable Smooth Surface configures cleanly (gen=%s oct=%d amp=%.2f) + trimesh collider" % [
		str(ncfg.get("generator", "")), int(ncfg.get("octaves", 0)), float(ncfg.get("amplitude", 0.0))],
		ok_noise and noise_col != null and int(ncfg.get("octaves", 0)) == 4)
	await _shot(cam, ws209_mount.to_global(Vector3(2.8, 2.55, 2.8)), ws209_mount.to_global(Vector3(0.0, 0.85, -3.6)), "06-f209-basin-smooth-noise.png")

	# Step inside at 1:1 scale via the VR Visor and photograph the complete General Intellect Playground from eye level!
	var entered: bool = ws209.visit.enter()
	await _frames(10)
	_check("6E VR Visor steps into 1:1 General Intellect Playground cleanly", entered and ws209.visit.active)
	game.camera.make_current()
	game.camera.fov = 66.0
	await _frames(8)
	await RenderingServer.frame_post_draw
	var vr_img: Image = root.get_viewport().get_texture().get_image()
	vr_img.save_png(ProjectSettings.globalize_path(OUT_DIR + "/07-f209-vr-1to1-general-intellect.png"))
	ws209.visit.restore()
	await _frames(4)

	var report := {
		"passed": _results.size() - _failed,
		"failed": _failed,
		"total": _results.size(),
		"checks": _results,
	}
	var rf := FileAccess.open(ProjectSettings.globalize_path(OUT_DIR + "/report.json"), FileAccess.WRITE)
	if rf != null:
		rf.store_string(JSON.stringify(report, "\t"))
		rf.close()

	print("SUMMARY: %d/%d PASS, %d FAIL" % [report.passed, report.total, report.failed])
	quit(0 if _failed == 0 else 1)
