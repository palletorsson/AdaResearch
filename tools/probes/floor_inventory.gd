extends SceneTree
## WHICH WORKS STAND ON A FLOOR (the Void, 2026-11-12)
## A floor's record names its works. This reads, in the running tower, which of them have a mount, whether the
## mount holds anything that draws (a mesh instance with a mesh) and how large it stands, so a floor that looks
## empty can be told apart from a floor that is empty. No walk, no change.
##
##   godot --path <stage> --script res://tools/probes/floor_inventory.gd -- --no-bridges
##       --void-start-floor=<floor> --out=<dir> [--settle=<frames, default 600>]
##
## inventory.json: one row a work (id, artifact, mounted, meshes, visible meshes, world box, and for a work that
## does not draw the hidden nodes above it and its hidden children), and `passed` when
## every work is mounted and draws. arrival.png from the spawn point, above.png from under the ceiling.
var game: Node3D


func _initialize() -> void:
	run.call_deferred()


func _shot(cam: Camera3D, at: Vector3, target: Vector3, path: String) -> void:
	cam.global_position = at
	cam.look_at(target, Vector3.UP)
	cam.current = true
	for i in 4: await process_frame
	root.get_viewport().get_texture().get_image().save_png(path)
	cam.current = false


func run() -> void:
	var folder := ""
	var settle := 600
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): folder = arg.trim_prefix("--out=")
		if arg.begins_with("--settle="): settle = int(arg.trim_prefix("--settle="))
	DirAccess.make_dir_recursive_absolute(folder)
	load("res://commons/void/room_source.gd").use_main_tower = true
	game = load("res://commons/void/void.tscn").instantiate()
	root.add_child(game); current_scene = game
	game.body.scripted_input = true; game.body.set_process_unhandled_input(false)
	game.scene_loaded(); game.scene_visible()
	var floor: int = game.checkpoint
	var record: Dictionary = game.building.content.data.floors[floor]
	for i in settle: await physics_frame
	var level: float = float(game.building.spec.levels[floor]) + game.building.global_position.y
	var rows := []
	var all := true
	# where the tower thinks the visitor is: a floor that is not the stream's focus sleeps, and a sleeping floor is hidden
	var stream: Dictionary = game.floor_stream.summary() if game.get("floor_stream") != null else {}
	var stands := [snappedf(game.body.global_position.x, .01), snappedf(game.body.global_position.y - level, .01), snappedf(game.body.global_position.z, .01)]
	for a in record.artifacts:
		var key := str(floor) + "/" + str(a.id)
		var mount: Node3D = game.building.content.exhibits.get(key)
		var row := {"id": str(a.id), "artifact": str(a.artifact), "mounted": mount != null, "meshes": 0, "visible": 0}
		if mount != null:
			var box := AABB()
			var first := true
			for m in mount.find_children("*", "GeometryInstance3D", true, false):
				var has: bool = (m is MeshInstance3D and (m as MeshInstance3D).mesh != null) or m is MultiMeshInstance3D or m is CSGShape3D or m is Label3D
				if not has: continue
				row.meshes += 1
				if (m as Node3D).is_visible_in_tree(): row.visible += 1
				var at: Vector3 = (m as Node3D).global_position
				box = AABB(at, Vector3.ZERO) if first else box.expand(at)
				first = false
			row["centre"] = [snappedf(box.get_center().x, .1), snappedf(box.get_center().y - level, .1), snappedf(box.get_center().z, .1)]
			row["spread_m"] = [snappedf(box.size.x, .1), snappedf(box.size.y, .1), snappedf(box.size.z, .1)]
		if mount != null and int(row.visible) == 0:
			# what hides it: the hidden nodes from the mount up to the scene root, then the mount's own hidden children
			var above := []
			var n: Node = mount
			while n != null and n != root:
				if n is Node3D and not (n as Node3D).visible: above.append(str(n.get_path()))
				n = n.get_parent()
			var below := []
			for c in mount.get_children():
				if c is Node3D and not (c as Node3D).visible: below.append(str(c.name))
			row["hidden_above"] = above
			row["hidden_children"] = below
		if not row.mounted or int(row.visible) == 0: all = false
		rows.append(row)
	for layer in root.find_children("*", "CanvasLayer", true, false):      # the game's overlays, not a work's own layers
		if layer.get_viewport() == root: layer.hide()
	game.place_player(Vector3(-3.6, level + 0.3, 8.6))
	for i in 30: await physics_frame
	var cam := Camera3D.new()
	cam.fov = 80
	root.add_child(cam)
	await _shot(cam, Vector3(0, level + 1.6, 7.8), Vector3(0, level + 1.4, 0), folder.path_join("arrival.png"))
	await _shot(cam, Vector3(0, level + 5.3, 8.6), Vector3(0, level, -1.5), folder.path_join("above.png"))
	var result := {"floor": floor, "map": str(record.map), "passed": all, "checks": [{"check": "every work of the floor is mounted and draws", "ok": all, "works": rows.size()}], "works": rows,
		"stream_focus": stream.get("focus", -1), "floor_mode": stream.get("floors", {}).get(str(floor), ""), "body_at": stands}
	var file := FileAccess.open(folder.path_join("inventory.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("[floor_inventory] ", "PASSED" if all else "FAILED")
	quit()
