extends SceneTree
## Proposes where an opera view frame could stand for works that have none. For each work named in the
## targets file, on the floor the game starts on: measures the work's drawn bounds, stands a frame between the
## work and the place its coin marks, at eye height, and checks that a visitor one metre behind the frame has
## an unbroken line to the work. If the line is broken it tries other sides. Changes nothing: the poses go to a
## file, in the floor's own coordinates and in the form tools/opera_frame_editor.py saves.
##
##   godot --path . --xr-mode off --script res://tools/probes/propose_frames.gd -- \
##       --void-start-floor=<n> --no-opening --opera-quiet --out=<dir> --targets=<file.json>
##
## targets file: {"<song id>": {"path": "<row>/Artifact[/Part]", "start": [x, y, z], "reach": <metres, optional>}}
## <dir>/proposed_frames.json: {"passed", "checks", "poses": {"<song id>": {"position", "rotation", "width", "height", "clear", ...}}}

var game: Node
var folder := "res://ada_run/propose_frames"


func _initialize() -> void:
	run.call_deferred()


func _arr(v: Vector3) -> Array:
	return [snappedf(v.x, 0.001), snappedf(v.y, 0.001), snappedf(v.z, 0.001)]


# The work's drawn bounds in the floor's coordinates, leaving out anything hidden or absurdly large.
func _bounds(host: Node3D, node: Node3D) -> AABB:
	var box := AABB()
	var first := true
	var meshes: Array[Node] = node.find_children("*", "MeshInstance3D", true, false)
	if node is MeshInstance3D: meshes.append(node)
	for mesh: MeshInstance3D in meshes:
		if not mesh.is_visible_in_tree() or mesh.mesh == null: continue
		var local: AABB = (host.global_transform.affine_inverse() * mesh.global_transform) * mesh.get_aabb()
		if local.get_longest_axis_size() > 14.0: continue
		box = local if first else box.merge(local)
		first = false
	if first: box = AABB(host.to_local(node.global_position) - Vector3(0.3, 0.0, 0.3), Vector3(0.6, 1.2, 0.6))
	return box


func run() -> void:
	var targets_file := ""
	var index := 0
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): folder = arg.trim_prefix("--out=")
		if arg.begins_with("--targets="): targets_file = arg.trim_prefix("--targets=")
		if arg.begins_with("--void-start-floor="): index = int(arg.get_slice("=", 1))
	DirAccess.make_dir_recursive_absolute(folder)
	var targets: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(targets_file))
	load("res://commons/void/room_source.gd").use_main_tower = true
	game = load("res://commons/void/void.tscn").instantiate()
	root.add_child(game); current_scene = game
	game.body.scripted_input = true; game.body.set_process_unhandled_input(false)
	game.scene_loaded(); game.scene_visible()
	for i in 700: await physics_frame
	game.body.set_physics_process(false)
	var host: Node3D = game.building.content.roots[index]
	var space := host.get_world_3d().direct_space_state
	var poses := {}
	var checks := []
	for song: String in targets:
		var spec: Dictionary = targets[song]
		var node := host.get_node_or_null(NodePath(str(spec.path))) as Node3D
		if node == null:
			# a part that is not a direct child by that name: look for it anywhere under the row
			var parts := str(spec.path).split("/")
			var row := host.get_node_or_null(NodePath(parts[0])) as Node3D
			if row != null and parts.size() > 1: node = row.find_child(parts[parts.size() - 1], true, false) as Node3D
			if node == null and row != null: node = row
		if node == null:
			checks.append({"check": "the work for %s stands on this floor" % song, "ok": false, "path": spec.path})
			continue
		var box := _bounds(host, node)
		var centre := box.get_center()
		var size := maxf(box.size.x, box.size.z)
		var start := Vector3(spec.start[0], 0.0, spec.start[2])
		var away := Vector3(start.x - centre.x, 0.0, start.z - centre.z)
		if away.length() < 0.3: away = Vector3(-centre.x, 0.0, 7.8 - centre.z)
		if away.length() < 0.3: away = Vector3(0, 0, 1)
		away = away.normalized()
		var reach := clampf(size * 0.75 + 1.3, 1.7, 5.5)
		if spec.has("reach"): reach = float(spec.reach)
		var aim := Vector3(centre.x, clampf(centre.y, 0.5, 2.2), centre.z)
		var chosen := {}
		for turn in [0.0, 35.0, -35.0, 70.0, -70.0, 110.0, -110.0, 180.0]:
			var side := away.rotated(Vector3.UP, deg_to_rad(turn))
			var at := Vector3(centre.x, 0.0, centre.z) + side * reach
			at.y = 1.45
			var eye_local := at + side * 1.0
			eye_local.y = 1.6
			# is there floor to stand on, and is the line from the eye to the work unbroken?
			var eye_world := host.to_global(eye_local)
			var ground := space.intersect_ray(PhysicsRayQueryParameters3D.create(eye_world, eye_world + Vector3.DOWN * 2.2))
			var sight := space.intersect_ray(PhysicsRayQueryParameters3D.create(eye_world, host.to_global(aim)))
			var clear: bool = sight.is_empty()
			if not clear:
				var struck: Node = sight.collider
				var reached: Vector3 = sight.position
				clear = struck == node or node.is_ancestor_of(struck) \
					or eye_world.distance_to(reached) > eye_world.distance_to(host.to_global(aim)) - maxf(size * 0.6, 0.5)
			if chosen.is_empty() or (clear and not ground.is_empty()):
				var basis := Basis.looking_at(aim - at, Vector3.UP)
				chosen = {"position": _arr(at), "rotation": _arr(basis.get_euler() * 180.0 / PI), "width": 1.1, "height": 0.7,
					"clear": clear, "ground_under_the_visitor": not ground.is_empty(), "turned_from_the_coin_side_deg": turn,
					"metres_from_the_work": snappedf(reach, 0.01), "work_centre": _arr(centre), "work_size_m": _arr(box.size), "node": str(host.get_path_to(node))}
				if clear and not ground.is_empty(): break
		poses[song] = chosen
		checks.append({"check": "a frame for %s with an unbroken line to the work and floor under the visitor" % song,
			"ok": bool(chosen.clear) and bool(chosen.ground_under_the_visitor), "turned": chosen.turned_from_the_coin_side_deg})
	var result := {"floor": index, "poses": poses, "checks": checks, "passed": checks.all(func(c): return c.ok)}
	var file := FileAccess.open(folder.path_join("proposed_frames.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "  "))
	file.close()
	quit(0 if result.passed else 1)
