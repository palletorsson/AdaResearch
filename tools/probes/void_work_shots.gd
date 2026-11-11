extends SceneTree
## Each work of one tower floor photographed where it stands, as the visitor meets it: the Void's own adapters,
## configs and scale applied (a standalone shot misses all three). One PNG per placement into --out.
## godot --path <stage> --script res://tools/probes/void_work_shots.gd -- --no-bridges --void-start-floor=N --out=<dir>
##   [--works=id,id] [--settle=600]  (settle = physics ticks after the floor is built)
##   [--from=front]  stand on the work's own +Z (where a facing-0 screen looks) instead of toward the room's middle
##   [--dist=2.5]  stand this far from the box centre (default: far enough to hold the whole box)
##   [--view=x,h,z:x,h,z;...]  extra pictures from a chosen eye to a chosen point (h = metres over the slab), saved as
##       view_1.png ...: the look from a lookout, down a gallery, across a shaft. With --works=none only these are taken.
var game: Node3D

func _initialize() -> void:
	shoot.call_deferred()

func _visual_aabb(node: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for n in node.find_children("*", "GeometryInstance3D", true, false):
		var g := n as GeometryInstance3D
		if not g.is_visible_in_tree() or g is Label3D or g.layers == 0:
			continue
		var local := g.get_aabb()
		if local.size.length() < 0.001 or local.size.length() > 60.0:
			continue
		var world := g.global_transform * local
		if first:
			box = world;first = false
		else:
			box = box.merge(world)
	return box

func shoot() -> void:
	var folder := ""
	var only: PackedStringArray = []
	var settle := 600
	var from_front := false
	var dist := -1.0
	var views: Array = []
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):folder = arg.trim_prefix("--out=")
		if arg.begins_with("--works="):only = arg.trim_prefix("--works=").split(",")
		if arg.begins_with("--settle="):settle = int(arg.trim_prefix("--settle="))
		if arg == "--from=front":from_front = true
		if arg.begins_with("--dist="):dist = float(arg.trim_prefix("--dist="))
		if arg.begins_with("--view="):
			for pair in arg.trim_prefix("--view=").split(";", false):
				var ends := pair.split(":")
				var a := ends[0].split(",");var b := ends[1].split(",")
				views.append([Vector3(float(a[0]), float(a[1]), float(a[2])), Vector3(float(b[0]), float(b[1]), float(b[2]))])
	DirAccess.make_dir_recursive_absolute(folder)
	load("res://commons/void/room_source.gd").use_main_tower = true
	game = load("res://commons/void/void.tscn").instantiate()
	root.add_child(game);current_scene = game
	game.body.scripted_input = true;game.body.set_process_unhandled_input(false)
	game.scene_loaded();game.scene_visible()
	var floor: int = game.checkpoint
	for i in 900:
		var record: Dictionary = game.building.content.data.floors[floor]
		if record.artifacts.all(func(a):return game.building.content.exhibits.has(str(floor)+"/"+a.id)):break
		await physics_frame
	for i in settle:await physics_frame
	for canvas in root.find_children("*", "CanvasLayer", true, false):canvas.hide()
	var base: float = game.building.spec.levels[floor]
	var cam := Camera3D.new();cam.fov = 60.0;cam.far = 200.0;root.add_child(cam);cam.current = true
	var report := []
	for item in game.building.content.data.floors[floor].artifacts:
		if not only.is_empty() and not only.has(str(item.id)):continue
		var mount: Node3D = game.building.content.exhibits.get(str(floor)+"/"+str(item.id))
		if mount == null:continue
		var box := _visual_aabb(mount)
		var c: Vector3 = box.get_center() if box.size.length() > 0.001 else mount.global_position
		var r: float = clampf(box.size.length() * 0.5, 0.25, 12.0)
		# Stand toward the room's middle from the work, turned 30 degrees, at a distance that holds the whole box.
		var out := Vector3(-c.x, 0, -c.z)
		if out.length() < 0.5:out = Vector3(0, 0, 1)
		out = out.normalized().rotated(Vector3.UP, deg_to_rad(30))
		if from_front:out = (mount.global_transform.basis.z * Vector3(1, 0, 1)).normalized().rotated(Vector3.UP, deg_to_rad(12))
		var d := r / tan(deg_to_rad(cam.fov * 0.5)) * 1.15
		if dist > 0.0:d = dist
		cam.global_position = c + out * d + Vector3(0, maxf(0.35 * d, 0.0), 0)
		cam.global_position.y = maxf(cam.global_position.y, base + 0.4)
		cam.look_at(c, Vector3.UP)
		for i in 4:await process_frame
		await RenderingServer.frame_post_draw
		var path := folder.path_join(str(item.artifact) + "__" + str(item.id) + ".png")
		root.get_texture().get_image().save_png(path)
		report.append({"id":item.id, "artifact":item.artifact, "center":[snappedf(c.x,.01),snappedf(c.y-base,.01),snappedf(c.z,.01)], "radius":snappedf(r,.01), "png":path})
	for n in views.size():
		var eye: Vector3 = views[n][0];var aim: Vector3 = views[n][1]
		cam.global_position = Vector3(eye.x, base + eye.y, eye.z)
		cam.look_at(Vector3(aim.x, base + aim.y, aim.z), Vector3.UP)
		for i in 4:await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(folder.path_join("view_%d.png" % (n + 1)))
	FileAccess.open(folder.path_join("works.json"), FileAccess.WRITE).store_string(JSON.stringify(report, "  "))
	print("VOID_WORK_SHOTS ", report.size())
	quit(0)
