extends SceneTree
## Load a .glb and screenshot it (AABB-framed). For viewing hand-edits exported
## from the console editor.
##   godot --path . --xr-mode off --no-window --script res://commons/testing/capture_glb.gd -- --file=X.glb --shot=user://glb.png

var _file := ""
var _shot := "user://glb.png"
var _camdir := Vector3(0.45, 0.32, 1.4)
var _cam: Camera3D


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		var s := str(a)
		if s.begins_with("--file="): _file = s.split("=", true, 1)[1]
		elif s.begins_with("--shot="): _shot = s.split("=", true, 1)[1]
		elif s.begins_with("--camdir="):
			var p := s.split("=", true, 1)[1].split(",")
			if p.size() == 3: _camdir = Vector3(float(p[0]), float(p[1]), float(p[2]))
	_run()


func _run() -> void:
	var root := Node3D.new(); get_root().add_child(root)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.40, 0.41, 0.44)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.72, 0.73, 0.76)
	env.ambient_light_energy = 1.0
	var we := WorldEnvironment.new(); we.environment = env; root.add_child(we)
	for r in [Vector3(-45, 30, 0), Vector3(-30, -45, 0)]:
		var l := DirectionalLight3D.new(); l.rotation_degrees = r
		l.light_energy = 1.0 if r.y == 30 else 0.5; root.add_child(l)

	var doc := GLTFDocument.new(); var state := GLTFState.new()
	if doc.append_from_file(_file, state) != OK:
		print("load failed"); quit(1); return
	var scene: Node = doc.generate_scene(state)
	root.add_child(scene)

	_cam = Camera3D.new(); _cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	root.add_child(_cam); _cam.current = true
	await process_frame
	await create_timer(0.5).timeout
	await process_frame
	var box := _aabb(scene)
	var focus := box.get_center(); var diag: float = maxf(0.3, box.size.length())
	_cam.size = diag * 1.05
	_cam.position = focus + _camdir.normalized() * diag * 1.5
	_cam.look_at(focus, Vector3.UP)
	await process_frame
	await create_timer(0.2).timeout
	await process_frame
	get_root().get_viewport().get_texture().get_image().save_png(_shot)
	print("[capture_glb] saved %s" % _shot)
	quit()


func _aabb(node: Node) -> AABB:
	var box := AABB(); var first := true; var stack: Array = [node]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is VisualInstance3D:
			var ab: AABB = (n as VisualInstance3D).get_aabb()
			ab = (n as Node3D).global_transform * ab
			if first: box = ab; first = false
			else: box = box.merge(ab)
		for c in n.get_children(): stack.append(c)
	return box
