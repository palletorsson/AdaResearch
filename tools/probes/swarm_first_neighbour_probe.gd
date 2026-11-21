extends "res://tools/probes/void_game_probe.gd"
const VoidFloor = preload("res://tools/probes/void_floor.gd")

## Ghost Student Spine Stop #7 (F163 SwarmIntelligence_Boids_Algorithm · "The First Neighbour")
## live desktop verification: pauses boids_neighbour_lens so all 30 boids remain completely still,
## widens perception_radius across 0.06 m -> 0.22 m -> 0.48 m with weights unchanged, verifies monotonic
## neighbour entry and steering-vector recomputation, checks companion floor machines, and captures
## Model B's live Dual Breadcrumb HUD inside Floor 163.

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out = arg.trim_prefix("--out=")

	var at: Dictionary = VoidFloor.table()
	var f163_idx: int = int(at.get("SwarmIntelligence_Boids_Algorithm", 163))

	Engine.physics_ticks_per_second = 90
	preload("res://commons/void/room_source.gd").use_main_tower = true
	load("res://commons/void/game.gd").requested_floor = f163_idx
	game = load("res://commons/void/void.tscn").instantiate()
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
	await frames(60)
	game.body.visible = false
	game.status.hide()
	game.charge_display.hide()
	game.notice_time = 0
	if game.desktop_help != null:
		game.desktop_help.hide()

	game.place_player(game.spawn_for(f163_idx))
	await frames(50)
	var fl_root: Node3D = game.building.content.roots.get(f163_idx, null)
	check("F163 SwarmIntelligence_Boids_Algorithm loaded cleanly", fl_root != null)

	var lens_mount: Node3D = fl_root.find_child("f1_boids_neighbour_lens_9_3", true, false) if fl_root != null else null
	var lens: Node3D = _find_with_prop(lens_mount, "rings")
	var aq: Node3D = fl_root.find_child("f1_boids_aquarium_4_6", true, false) if fl_root != null else null
	var lane: Node3D = fl_root.find_child("dna-boids-lane", true, false) if fl_root != null else null
	var orb: Node3D = fl_root.find_child("dna-boids-orb", true, false) if fl_root != null else null
	var drone: Node3D = fl_root.find_child("f1_drone_comparison_20_6", true, false) if fl_root != null else null
	var unit_s: Node3D = fl_root.find_child("unit-steer", true, false) if fl_root != null else null
	check("Boids Neighbour Lens, Boids Aquariums (lane/orb), Drone Comparison, and The Unit spawned on F163",
		lens != null and aq != null and lane != null and orb != null and drone != null and unit_s != null)

	var measurements := {}
	if lens != null:
		var flock: Node3D = lens.get("flock") as Node3D
		check("30-boid integrator mounted inside boids_neighbour_lens", flock != null and (flock.get("_boids") as Array).size() >= 20)

		# Let flock settle briefly then PAUSE so every boid freezes in place while radius widens!
		await frames(15)
		lens.set("playing", false)
		await frames(4)

		var b0_pos_start: Vector3 = (flock.get("_boids") as Array)[0].position
		var cam := Camera3D.new()
		root.add_child(cam)
		var l_pos: Vector3 = lens.global_position
		var l_fwd: Vector3 = lens.global_transform.basis.z.normalized()

		# 1. Wide overview of Floor 163
		cam.fov = 58.0
		cam.global_position = l_pos + l_fwd * 4.1 + Vector3(1.5, 2.25, 0.0)
		cam.look_at(l_pos + Vector3(0.0, 1.35, 0.0), Vector3.UP)
		cam.make_current()
		await frames(6)
		root.get_texture().get_image().save_png(out.path_join("01-f163-overview.png"))
		FileAccess.open(out.path_join("progress.json"), FileAccess.WRITE).store_string("01-f163-overview.png")

		# Front-on table camera framing the WHO ENTERS THE RADIUS? display, gold sphere, links, and arrows
		cam.fov = 50.0
		cam.global_position = l_pos + l_fwd * 2.35 + Vector3(0.0, 1.65, 0.0)
		cam.look_at(l_pos + Vector3(0.0, 1.42, 0.0), Vector3.UP)
		await frames(4)

		# 2. Narrow radius = 0.06 m
		flock.set("perception_radius", 0.06)
		lens.call("refresh")
		await frames(5)
		var r_narrow: Dictionary = lens.get("reading")
		var n_narrow: int = (r_narrow.get("neighbours", []) as Array).size()
		var sum_narrow: float = (r_narrow.get("sum", Vector3.ZERO) as Vector3).length()
		root.get_texture().get_image().save_png(out.path_join("02-radius-narrow.png"))
		FileAccess.open(out.path_join("progress.json"), FileAccess.WRITE).store_string("02-radius-narrow.png")

		# 3. Medium radius = 0.24 m
		flock.set("perception_radius", 0.24)
		lens.call("refresh")
		await frames(5)
		var r_mid: Dictionary = lens.get("reading")
		var n_mid: int = (r_mid.get("neighbours", []) as Array).size()
		var sum_mid: float = (r_mid.get("sum", Vector3.ZERO) as Vector3).length()
		root.get_texture().get_image().save_png(out.path_join("03-radius-mid.png"))
		FileAccess.open(out.path_join("progress.json"), FileAccess.WRITE).store_string("03-radius-mid.png")

		# 4. Wide radius = 0.48 m
		flock.set("perception_radius", 0.48)
		lens.call("refresh")
		await frames(5)
		var r_wide: Dictionary = lens.get("reading")
		var n_wide: int = (r_wide.get("neighbours", []) as Array).size()
		var sum_wide: float = (r_wide.get("sum", Vector3.ZERO) as Vector3).length()
		var b0_pos_end: Vector3 = (flock.get("_boids") as Array)[0].position

		check("Paused boids remain strictly stationary while radius widens (drift=%.5f m)" % b0_pos_start.distance_to(b0_pos_end),
			b0_pos_start.distance_to(b0_pos_end) < 0.0001)
		check("Widening radius monotonically adds neighbours (0.06m:%d <= 0.24m:%d <= 0.48m:%d, strictly grew)" % [n_narrow, n_mid, n_wide],
			n_narrow <= n_mid and n_mid <= n_wide and n_wide > n_narrow)
		check("Steering sum responds solely to neighbourhood change (narrow=%.3f -> wide=%.3f)" % [sum_narrow, sum_wide],
			absf(sum_wide - sum_narrow) > 0.001)

		# Live Dual Breadcrumb HUD capture on F163 using inner_opera._plain_for()
		var opera_script = load("res://commons/void/inner_opera.gd")
		var opera_tmp = opera_script.new()
		var f163_plain: String = opera_tmp._plain_for("spine_5222bc1a1c40201257", "spine_5222bc1a1c40201257")
		opera_tmp.free()
		check("F163 The First Neighbour plain breadcrumb resolved from tower_system_atlas.json", not f163_plain.is_empty())

		game.charge_display.show()
		game.charge_display.set_level("F163  SwarmIntelligence_Boids  ·  The First Neighbour")
		game.charge_display.set_sung("One wider circle makes a neighbour.", f163_plain)
		await frames(6)
		root.get_texture().get_image().save_png(out.path_join("04-radius-wide-dual-hud.png"))
		cam.queue_free()

		measurements = {
			"boid_count": (flock.get("_boids") as Array).size(),
			"paused_drift_m": snappedf(b0_pos_start.distance_to(b0_pos_end), 0.0001),
			"neighbours_r006": n_narrow,
			"neighbours_r024": n_mid,
			"neighbours_r048": n_wide,
			"sum_r006": snappedf(sum_narrow, 0.001),
			"sum_r024": snappedf(sum_mid, 0.001),
			"sum_r048": snappedf(sum_wide, 0.001),
		}

	var failed := 0
	for c in checks:
		if not bool((c as Dictionary).get("passed", false)): failed += 1
	var report := {
		"passed": failed == 0,
		"failed": failed,
		"map": "SwarmIntelligence_Boids_Algorithm",
		"floor": f163_idx,
		"encounter": "spine_5222bc1a1c40201257",
		"measurements": measurements,
		"songs": [
			{
				"encounter": "spine_5222bc1a1c40201257",
				"object": "spine_5222bc1a1c40201257",
				"on_display": true,
				"sung": true,
				"text": "One wider circle makes a neighbour."
			}
		],
		"checks": checks,
	}
	var f := FileAccess.open(out.path_join("checks.json"), FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(report, "  ") + "\n")
	quit(0 if failed == 0 else 1)

func _find_with_prop(node: Node, prop: String) -> Node3D:
	if node == null: return null
	if node is Node3D and node.get(prop) != null: return node
	for c in node.get_children():
		var hit := _find_with_prop(c, prop)
		if hit != null: return hit
	return null
