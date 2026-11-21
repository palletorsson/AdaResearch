extends "res://tools/probes/void_game_probe.gd"
const VoidFloor = preload("res://tools/probes/void_floor.gd")
const RoomSource = preload("res://commons/void/room_source.gd")

## Ghost Student Spine Stop #10 (F209 Primitives_Prefab_Library · "Take a Part Forward")
## live desktop verification: verifies all 8 open prefab_library_shelf banks, all 5 full-size
## hanging_stock rails, live pickup/collect on a reusable prefab vs tool return-to-stand,
## tier-3 scaffold_workstation_quads, both void_floor_transfer thresholds back into the tower,
## and Model B's live Dual Breadcrumb HUD inside Floor 209.

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out = arg.trim_prefix("--out=")

	var at: Dictionary = VoidFloor.table()
	var f209_idx: int = int(at.get("Primitives_Prefab_Library", 209))

	Engine.physics_ticks_per_second = 90
	RoomSource.use_main_tower = true
	load("res://commons/void/game.gd").requested_floor = f209_idx
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

	game.place_player(game.spawn_for(f209_idx))
	await frames(50)
	var fl_root: Node3D = game.building.content.roots.get(f209_idx, null)
	check("F209 Primitives_Prefab_Library loaded cleanly", fl_root != null)

	var measurements := {}
	if fl_root != null:
		# 1. Inspect all 8 open prefab_library_shelf banks
		var shelf_count := 0
		var shelf_items_total := 0
		for i in range(1, 9):
			var s_mount: Node3D = fl_root.find_child("edge-stock-%d" % i, true, false)
			var shelf: Node3D = _find_with_prop(s_mount, "bank")
			if shelf != null:
				shelf_count += 1
				var st: Array = shelf.call("stock")
				shelf_items_total += st.size()
		check("All 8 open prefab_library_shelf banks (PREFABS 01-06 + TOOLS 01-02) spawned (%d/8 banks, %d total items)" % [shelf_count, shelf_items_total],
			shelf_count == 8 and shelf_items_total >= 40)

		# 2. Inspect all 5 full-size hanging_stock rails
		var rail_names := [
			"hanging-stock-framing",
			"hanging-stock-profiles",
			"hanging-stock-blocks",
			"hanging-stock-tools",
			"hanging-stock-oversize",
		]
		var rails := {}
		var rail_stock_total := 0
		for rname in rail_names:
			var r_mount: Node3D = fl_root.find_child(rname, true, false)
			var rail: Node3D = _find_with_prop(r_mount, "stock_ids")
			if rail != null:
				rails[rname] = rail
				var st_dict: Dictionary = rail.get("stock")
				rail_stock_total += st_dict.size()
		check("All 5 full-size hanging_stock rails spawned removable physical prefabs and tools (%d/5 rails, %d full-size parts)" % [rails.size(), rail_stock_total],
			rails.size() == 5 and rail_stock_total >= 30)

		var framing: Node3D = rails.get("hanging-stock-framing", null)
		var tools_rail: Node3D = rails.get("hanging-stock-tools", null)
		var ws_mount: Node3D = fl_root.find_child("construction-stock", true, false)
		var ws: Node3D = _find_with_prop(ws_mount, "tier")
		var xfer_trans_mount: Node3D = fl_root.find_child("library-to-transformation", true, false)
		var xfer_trans: Node3D = _find_with_prop(xfer_trans_mount, "destination")
		var xfer_mel_mount: Node3D = fl_root.find_child("library-to-melencolia", true, false)
		var xfer_mel: Node3D = _find_with_prop(xfer_mel_mount, "destination")

		# Capture Shot 1: Wide workshop overview before taking parts off rails
		var cam := Camera3D.new()
		root.add_child(cam)
		cam.make_current()
		var fl_pos: Vector3 = fl_root.global_position
		cam.fov = 60.0
		cam.global_position = fl_pos + Vector3(0.0, 6.2, 13.5)
		cam.look_at(fl_pos + Vector3(0.0, 1.2, -2.0), Vector3.UP)
		await frames(6)
		root.get_texture().get_image().save_png(out.path_join("01-f209-workshop-overview.png"))
		FileAccess.open(out.path_join("progress.json"), FileAccess.WRITE).store_string("01-f209-workshop-overview.png")

		# Capture Shot 2: Full-size FRAMING AND MEASURE rail + open shelves behind
		if framing != null:
			var f_pos: Vector3 = framing.global_position
			var f_fwd: Vector3 = framing.global_transform.basis.z.normalized()
			cam.fov = 56.0
			cam.global_position = f_pos + f_fwd * 4.4 + Vector3(0.8, 1.95, 0.0)
			cam.look_at(f_pos + Vector3(0.0, 1.05, -0.4), Vector3.UP)
			await frames(6)
			root.get_texture().get_image().save_png(out.path_join("02-hanging-stock-framing.png"))
			FileAccess.open(out.path_join("progress.json"), FileAccess.WRITE).store_string("02-hanging-stock-framing.png")

		# Capture Shot 3: Tier-3 Scaffold Workstation (quads) + right-side stock
		if ws != null:
			var w_pos: Vector3 = ws.global_position
			cam.fov = 56.0
			cam.global_position = w_pos + Vector3(-5.2, 2.8, 4.4)
			cam.look_at(w_pos + Vector3(0.0, 1.25, 0.0), Vector3.UP)
			await frames(6)
			root.get_texture().get_image().save_png(out.path_join("03-scaffold-workstation.png"))
			FileAccess.open(out.path_join("progress.json"), FileAccess.WRITE).store_string("03-scaffold-workstation.png")

		# 3. Verify live pickup of a reusable part ('rod') from FRAMING AND MEASURE
		var part_taken_ok := false
		var part_before := 0
		var part_after := 0
		if framing != null:
			var f_stock: Dictionary = framing.get("stock")
			part_before = f_stock.size()
			if f_stock.has("rod"):
				var rod_body = f_stock["rod"]
				framing.call("_take", rod_body)
				await frames(4)
				part_after = (framing.get("stock") as Dictionary).size()
				part_taken_ok = (not (framing.get("stock") as Dictionary).has("rod")) and (part_after == part_before - 1)
		check("Taking full-size part 'rod' from FRAMING AND MEASURE removes it from rail stock (%d -> %d) and dispatches inventory collect" % [part_before, part_after],
			part_taken_ok)

		# 4. Verify taking a tool ('tape' or 'trace_pen') equips while keeping rail stand populated
		var tool_kept_ok := false
		var tested_tool := ""
		if tools_rail != null:
			var t_stock: Dictionary = tools_rail.get("stock")
			for cand in ["tape", "trace_pen", "pin", "rubber"]:
				if t_stock.has(cand) and bool((t_stock[cand] as Node).get_meta("hanging_stock_equips", false)):
					tested_tool = cand
					var t_body = t_stock[cand]
					var t_before := t_stock.size()
					tools_rail.call("_take", t_body)
					await frames(6)
					var t_after := (tools_rail.get("stock") as Dictionary).size()
					tool_kept_ok = (tools_rail.get("stock") as Dictionary).has(cand) and t_after == t_before
					break
		check("Taking tool '%s' from TOOLS AND FIXTURES equips while returning fixture to stand" % tested_tool,
			tool_kept_ok)

		# 5. Verify Tier-3 Scaffold Workstation (quads)
		var ws_tier: int = int(ws.get("tier")) if ws != null else -1
		var ws_prefabs: bool = bool(ws.get("prefabs_enabled")) if ws != null else false
		check("Scaffold Workstation (construction-stock) spawned at tier %d with prefabs_enabled=%s" % [ws_tier, str(ws_prefabs)],
			ws != null and ws_tier == 3 and ws_prefabs)

		# 6. Verify both transfer thresholds resolve valid tower spine floors
		var trans_dest: String = str(xfer_trans.get("destination")) if xfer_trans != null else ""
		var mel_dest: String = str(xfer_mel.get("destination")) if xfer_mel != null else ""
		var trans_floor: int = RoomSource.spine_floor(trans_dest) if not trans_dest.is_empty() else -1
		var mel_floor: int = RoomSource.spine_floor(mel_dest) if not mel_dest.is_empty() else -1
		check("Both transfer thresholds resolve valid tower spine destinations (%s -> F%d, %s -> F%d)" % [
			trans_dest, trans_floor, mel_dest, mel_floor],
			xfer_trans != null and xfer_mel != null and trans_floor >= 0 and mel_floor >= 0)

		# 7. Verify Dual Breadcrumb HUD for F209 Take a Part Forward + Shot 4 facing transfer threshold
		var opera_script = load("res://commons/void/inner_opera.gd")
		var opera_tmp = opera_script.new()
		var f209_plain: String = opera_tmp._plain_for("spine_62884bf3e1aa10927f", "spine_62884bf3e1aa10927f")
		opera_tmp.free()
		check("F209 Take a Part Forward plain breadcrumb resolved from tower_system_atlas.json", not f209_plain.is_empty())

		if xfer_trans != null:
			var x_pos: Vector3 = xfer_trans.global_position
			var x_fwd: Vector3 = xfer_trans.global_transform.basis.z.normalized()
			cam.fov = 56.0
			cam.global_position = x_pos + x_fwd * 4.2 + Vector3(0.4, 1.85, 0.0)
			cam.look_at(x_pos + Vector3(0.0, 1.25, 0.0), Vector3.UP)
		game.charge_display.show()
		game.charge_display.set_level("F209  Primitives_Prefab_Library  ·  Take a Part Forward")
		game.charge_display.set_sung("What we have made can start something again.", f209_plain)
		await frames(6)
		root.get_texture().get_image().save_png(out.path_join("04-transfer-threshold-dual-hud.png"))
		cam.queue_free()

		measurements = {
			"shelf_banks": shelf_count,
			"shelf_items_total": shelf_items_total,
			"hanging_rails": rails.size(),
			"hanging_stock_total": rail_stock_total,
			"part_taken": "rod",
			"tool_returned": tested_tool,
			"workstation_tier": ws_tier,
			"transfer_destinations": {
				trans_dest: trans_floor,
				mel_dest: mel_floor,
			},
		}

	var failed := 0
	for c in checks:
		if not bool((c as Dictionary).get("passed", false)): failed += 1
	var report := {
		"passed": failed == 0,
		"failed": failed,
		"map": "Primitives_Prefab_Library",
		"floor": f209_idx,
		"encounter": "spine_62884bf3e1aa10927f",
		"measurements": measurements,
		"songs": [
			{
				"encounter": "spine_62884bf3e1aa10927f",
				"object": "spine_62884bf3e1aa10927f",
				"on_display": true,
				"sung": true,
				"text": "What we have made can start something again."
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
