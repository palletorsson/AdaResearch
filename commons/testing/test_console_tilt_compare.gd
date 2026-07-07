extends SceneTree
## Side-by-side comparison of console slant angles, so the ergonomic sweet spot
## can be chosen by eye. Builds one ControlConsole per tilt in a row, auto-frames.
##   godot --path . --xr-mode off --no-window --script res://commons/testing/test_console_tilt_compare.gd -- --shot=user://console_tilt_compare.png

const ControlConsoleScript = preload("res://commons/ui/control_console.gd")
const TILTS := [20.0, 35.0, 50.0]

var _shot := "user://console_tilt_compare.png"
var _root: Node3D
var _cam: Camera3D


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if str(a).begins_with("--shot="):
			_shot = str(a).split("=", true, 1)[1]

	_root = Node3D.new()
	get_root().add_child(_root)

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.40, 0.41, 0.44)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.72, 0.73, 0.76)
	env.ambient_light_energy = 1.0
	var we := WorldEnvironment.new(); we.environment = env
	_root.add_child(we)
	for rot in [Vector3(-45, 30, 0), Vector3(-30, -45, 0)]:
		var l := DirectionalLight3D.new()
		l.rotation_degrees = rot
		l.light_energy = 1.0 if rot.y == 30 else 0.5
		_root.add_child(l)

	var x := -1.3 * (TILTS.size() - 1) * 0.5
	for t in TILTS:
		var c = ControlConsoleScript.new()
		c.tilt_deg = float(t)
		c.demo_title = "%d°" % int(t)
		c.position = Vector3(x, 0.0, 0.0)
		_root.add_child(c)
		x += 1.3

	_cam = Camera3D.new()
	_cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	_root.add_child(_cam)
	_cam.current = true
	_run()


func _run() -> void:
	await process_frame
	await create_timer(0.9).timeout
	await process_frame
	var box := _world_aabb(_root)
	var focus := box.get_center()
	var diag: float = box.size.length()
	_cam.size = maxf(0.6, diag * 0.60)
	_cam.position = focus + Vector3(0.0, 0.32, 1.4).normalized() * maxf(1.0, diag)
	_cam.look_at(focus, Vector3.UP)
	await process_frame
	await create_timer(0.2).timeout
	await process_frame
	var img := get_root().get_viewport().get_texture().get_image()
	img.save_png(_shot)
	print("[console_tilt_compare] shot saved: %s" % _shot)
	quit()


func _world_aabb(node: Node) -> AABB:
	var box := AABB(); var first := true
	var stack: Array = [node]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is VisualInstance3D:
			var ab: AABB = (n as VisualInstance3D).get_aabb()
			ab = (n as Node3D).global_transform * ab
			if first: box = ab; first = false
			else: box = box.merge(ab)
		for c in n.get_children():
			stack.append(c)
	return box
