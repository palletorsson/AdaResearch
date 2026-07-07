extends SceneTree
## Render control_console with a given DNA config (front + side) to debug a variant.
const ConsoleScript = preload("res://commons/ui/control_console.gd")
var _c: Node3D
var _cam: Camera3D
var _root: Node3D

func _initialize() -> void:
	_root = Node3D.new(); get_root().add_child(_root)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.40, 0.41, 0.44)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.72, 0.73, 0.76); env.ambient_light_energy = 1.0
	var we := WorldEnvironment.new(); we.environment = env; _root.add_child(we)
	for r in [Vector3(-45, 30, 0), Vector3(-30, -45, 0)]:
		var l := DirectionalLight3D.new(); l.rotation_degrees = r
		l.light_energy = 1.0 if r.y == 30 else 0.5; _root.add_child(l)

	_c = ConsoleScript.new()
	_c.apply_grid_config({"face_to_origin": true, "body_height": 0.4,
		"body_color": Color(0.62,0.63,0.65), "trim_color": Color(0.35,0.36,0.38)})
	_root.add_child(_c)

	_cam = Camera3D.new(); _cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	_root.add_child(_cam); _cam.current = true
	_run()

func _run() -> void:
	await process_frame
	await create_timer(0.9).timeout
	await process_frame
	await _shot(Vector3(0.0, 0.05, 1.4), "user://cc_dbg_front.png")
	await _shot(Vector3(1.5, 0.2, 0.4), "user://cc_dbg_side.png")
	quit()

func _shot(dir: Vector3, path: String) -> void:
	var box := _aabb(_c); var focus := box.get_center(); var diag: float = maxf(0.3, box.size.length())
	_cam.size = diag * 1.1
	_cam.position = focus + dir.normalized() * diag * 1.5
	_cam.look_at(focus, Vector3.UP)
	await process_frame; await create_timer(0.2).timeout; await process_frame
	get_root().get_viewport().get_texture().get_image().save_png(path)
	print("[dbg] saved %s" % path)

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
