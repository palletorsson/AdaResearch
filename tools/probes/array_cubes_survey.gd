extends "res://tools/probes/void_game_probe.gd"
## Survey (2026-11-04): every pick-up cube of floor 25 (Array) - its mount, the bottom of its body, its motion, and what
## stands under it. Writes <out>/cubes.json. Run once from a staged runtime (see the inventory runners).
const FLOOR := 25

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out = arg.trim_prefix("--out=")
	preload("res://commons/void/room_source.gd").use_main_tower = true
	load("res://commons/void/game.gd").requested_floor = FLOOR
	game = load("res://commons/void/void.tscn").instantiate(); game.force_xr = false
	root.add_child(game); current_scene = game; game.scene_loaded(); game.scene_visible()
	game.body.scripted_input = true
	await frames(180)
	var level: float = float(game.building.spec.levels[FLOOR])
	var space := game.get_world_3d().direct_space_state
	var rows := []
	for n in game.find_children("*", "Node3D", true, false):
		if n.get_script() == null or not str(n.get_script().resource_path).ends_with("pick_up_cube.gd"): continue
		var path := str(n.get_path())
		if not path.contains("/Content%d/" % FLOOR): continue
		var mesh: MeshInstance3D = n.find_child("CubeBaseMesh", true, false)
		var bb: AABB = mesh.global_transform * mesh.get_aabb() if mesh else AABB()
		var from := Vector3(n.global_position.x, bb.position.y - .01, n.global_position.z)
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * 4.0))
		rows.append({"mount": path.get_slice("/Content%d/" % FLOOR, 1).get_slice("/", 0), "at": [snappedf(n.global_position.x, .01), snappedf(n.global_position.y - level, .01), snappedf(n.global_position.z, .01)],
			"bottom": snappedf(bb.position.y - level, .01), "top": snappedf(bb.end.y - level, .01), "motion": str(n.get("motion")), "hold": str(n.get("hold")),
			"under": snappedf(hit.position.y - level, .01) if not hit.is_empty() else null, "under_what": str(hit.collider.get_path()).get_slice("/Content%d/" % FLOOR, 1).left(60) if not hit.is_empty() else ""})
	FileAccess.open(out.path_join("cubes.json"), FileAccess.WRITE).store_string(JSON.stringify(rows, "  "))
	print("[array_survey] %d cubes" % rows.size())
	quit(0)
