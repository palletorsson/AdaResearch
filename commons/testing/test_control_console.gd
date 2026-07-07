extends SceneTree
## Smoke test for ControlConsole — a CSG grey-metal cabinet with a Braun plate
## recessed in its slanted face. Real XR controls (runtime-loaded), then screenshot.
##   godot --path . --xr-mode off --no-window --script res://commons/testing/test_control_console.gd -- --shot=user://control_console_test.png

const ControlConsoleScript = preload("res://commons/ui/control_console.gd")

var _shot := "user://control_console_test.png"
var _console: Node3D


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if str(a).begins_with("--shot="):
			_shot = str(a).split("=", true, 1)[1]

	var root := Node3D.new()
	get_root().add_child(root)

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.40, 0.41, 0.44)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.72, 0.73, 0.76)
	env.ambient_light_energy = 1.0
	var we := WorldEnvironment.new(); we.environment = env
	root.add_child(we)
	for rot in [Vector3(-45, 30, 0), Vector3(-30, -45, 0)]:
		var l := DirectionalLight3D.new()
		l.rotation_degrees = rot
		l.light_energy = 1.0 if rot.y == 30 else 0.5
		root.add_child(l)

	_console = ControlConsoleScript.new()
	_console.auto_demo = false   # this test adds its own controls explicitly
	root.add_child(_console)

	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	root.add_child(cam)
	cam.current = true
	_cam = cam
	_run()


var _cam: Camera3D


func _run() -> void:
	await process_frame
	await create_timer(0.4).timeout
	_console.set_title("Stretch Bench")
	_console.add_slider("SCALE k")
	_console.add_button("SNAP")
	_console.add_readout("k = 1.00\n|k*v| = 1.48")
	await process_frame
	await create_timer(0.8).timeout
	await process_frame
	# Auto-frame the whole console on its world AABB (reliable, no guesswork).
	var box := _world_aabb(_console)
	var focus := box.get_center()
	var diag: float = box.size.length()
	_cam.size = maxf(0.6, diag * 0.78)
	_cam.position = focus + Vector3(0.5, 0.35, 1.4).normalized() * maxf(1.0, diag)
	_cam.look_at(focus, Vector3.UP)
	await process_frame
	await create_timer(0.2).timeout
	await process_frame
	var img := get_root().get_viewport().get_texture().get_image()
	img.save_png(_shot)
	print("[control_console_test] shot saved: %s" % _shot)
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
