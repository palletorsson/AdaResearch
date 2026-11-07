extends "res://tools/probes/void_game_probe.gd"
const TimelineWalkLib := preload("res://commons/void/timeline_walk.gd")
## THE TIMELINE IN THE TOWER (2026-11-07): on each floor the main works carry their timeline numbers on the slab,
## and a floor without a hand-made route shows the walk in number order. Built in the actual tower from
## commons/data/artifact_timeline_walk.json and photographed from above (orthographic, under the slab overhead)
## and from the first stand. Run: python tools/test_timeline_walk.py [--floors=1,5,64]
var floors: Array = [1, 5, 64]
var shots := true
var settle := 200

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out = arg.trim_prefix("--out=")
		if arg == "--no-shots": shots = false
		if arg.begins_with("--settle="): settle = int(arg.trim_prefix("--settle="))
		if arg.begins_with("--floors="):
			floors = []
			for s in arg.trim_prefix("--floors=").split(","): floors.append(int(s))
	preload("res://commons/void/room_source.gd").use_main_tower = true
	load("res://commons/void/game.gd").requested_floor = int(floors[0])
	game = load("res://commons/void/void.tscn").instantiate(); game.force_xr = false
	root.add_child(game); current_scene = game; game.scene_loaded(); game.scene_visible(); game.set_process_unhandled_key_input(false)
	game.body.scripted_input = true; game.body.set_process_unhandled_input(false)
	await frames(120)
	var walk_file: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://commons/data/artifact_timeline_walk.json"))
	for f in floors:
		game.place_player(game.spawn_for(int(f))); await frames(settle)
		await check_floor(int(f), walk_file.floors.get(str(f), {}))
	finish()

func check_floor(f: int, expect: Dictionary) -> void:
	var content: Node3D = game.building.content.roots.get(f)
	var walk: Node3D = content.get_node_or_null("TimelineWalk") if content else null
	check("floor %d: the timeline walk is built (%s route)" % [f, expect.get("route", "none")], walk != null or expect.is_empty())
	if walk == null: return
	var stops := walk.find_children("Stop_*", "Node3D", false, false)
	check("floor %d: %d number captions for %d main works" % [f, stops.size(), expect.stops.size()], stops.size() == expect.stops.size())
	var first: Dictionary = expect.stops[0]
	var cap: Node3D = walk.get_node(TimelineWalkLib.stop_name(first))
	var to_work := Vector3(float(first.at[0]), 0, float(first.at[1])) - Vector3(cap.position.x, 0, cap.position.z)
	var top := -cap.global_basis.z; top.y = 0
	check("floor %d: #%d reads toward its work (%.0f deg off)" % [f, int(first.n), rad_to_deg(top.angle_to(to_work))], to_work.length() < .01 or top.angle_to(to_work) < .05)
	var exhibit: Node3D = game.building.content.exhibits.get("%d/%s" % [f, first.id])
	check("floor %d: #%d's work %s stands where the walk says" % [f, int(first.n), first.key], exhibit != null and Vector2(exhibit.position.x, exhibit.position.z).distance_to(Vector2(float(first.at[0]), float(first.at[1]))) < .05)
	# paint must lie ON what you walk on: a ray down at each stand finds the walking surface under the caption
	var space := game.get_world_3d().direct_space_state
	var buried := []
	for stop in expect.stops:
		var p := cap.get_parent().get_node(TimelineWalkLib.stop_name(stop)).global_position as Vector3
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(p + Vector3(0, 1.5, 0), p - Vector3(0, .5, 0)))
		if not hit.is_empty() and hit.position.y > p.y + .005: buried.append("#%d %.2f m under %s" % [int(stop.n), hit.position.y - p.y, hit.collider.name])
	check("floor %d: no caption lies under a walking surface %s" % [f, str(buried.slice(0, 4))], buried.is_empty())
	var lbl: Label3D = cap.get_node("Number")
	check("floor %d: the captions are visible (in tree %s, y %.3f over the slab, layers %d)" % [f, walk.is_visible_in_tree(), lbl.global_position.y - float(game.building.spec.levels[f]), lbl.layers], walk.is_visible_in_tree() and lbl.layers != 0)
	var lines := walk.find_children("Walk_*", "MeshInstance3D", false, false)
	if expect.route == "timeline":
		# a stop the walk cannot reach is a finding the page flags, not a fault of the drawing
		check("floor %d: the walk is drawn as derived (%d lines; unreached %s)" % [f, lines.size(), str(expect.get("unreached", []))], lines.size() == expect.get("lines", []).size())
	else:
		check("floor %d: a hand-made route keeps its own captions, no timeline line" % f, lines.is_empty())
	if DisplayServer.get_name() == "headless" or not shots: return
	var level: float = float(game.building.spec.levels[f])
	game.body.visible = false; game.status.hide(); game.charge_display.hide(); game.notice_time = 0
	if game.desktop_help != null: game.desktop_help.hide()
	var top_cam := Camera3D.new(); game.add_child(top_cam); top_cam.environment = game.atmosphere.environment
	top_cam.projection = Camera3D.PROJECTION_ORTHOGONAL; top_cam.keep_aspect = Camera3D.KEEP_WIDTH; top_cam.size = 44.0
	top_cam.global_position = Vector3(0, level + 5.2, 0); top_cam.look_at(Vector3(0, level, 0), Vector3.FORWARD); top_cam.near = .05; top_cam.far = 8.0
	top_cam.make_current(); await frames(8); await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join("floor%02d_walk_above.png" % f)); top_cam.queue_free()
	var eye := Camera3D.new(); game.add_child(eye); eye.environment = game.atmosphere.environment; eye.fov = 75
	var stand := Vector3(float(first.stand[0]), level, float(first.stand[1]))
	var at := Vector3(float(first.at[0]), level, float(first.at[1]))
	var back := (stand - at); back.y = 0; back = back.normalized() if back.length() > .01 else Vector3.BACK
	eye.global_position = stand + back * 1.2 + Vector3(0, 1.65, 0); eye.look_at(stand.lerp(at, .45) + Vector3(0, .3, 0))
	eye.make_current(); await frames(8); await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join("floor%02d_walk_eye.png" % f)); eye.queue_free()

func finish() -> void:
	FileAccess.open(out.path_join("checks.json"), FileAccess.WRITE).store_string(JSON.stringify({"passed": failed.is_empty(), "checks": checks, "failed": failed}, "  "))
	print("[timeline_walk] %d/%d checks pass" % [checks.size() - failed.size(), checks.size()])
	quit(0 if failed.is_empty() else 1)
