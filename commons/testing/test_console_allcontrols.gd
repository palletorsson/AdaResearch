extends SceneTree
## Generalization check: a ControlConsole with one of EVERY control type
## (slider, dial, joystick, button) + readout — verifies the seating (controls
## flush on the plate) holds across all canonical interactables, not just the
## slider+button of the stretch-bench console.
##   godot --path . --xr-mode off --no-window --script res://commons/testing/test_console_allcontrols.gd

const ControlConsoleScript = preload("res://commons/ui/control_console.gd")

var _console: Node3D
var _cam: Camera3D


func _initialize() -> void:
	var root := Node3D.new()
	get_root().add_child(root)
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

	_console = ControlConsoleScript.new()
	_console.auto_demo = false
	root.add_child(_console)
	_console.set_title("All Controls")
	_console.add_slider("SLIDE")
	_console.add_dial("DIAL")
	_console.add_joystick("STICK")
	_console.add_button("PUSH")
	_console.add_readout("ready")

	_cam = Camera3D.new(); _cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	root.add_child(_cam); _cam.current = true
	_run(root)


func _run(root: Node3D) -> void:
	await process_frame
	await create_timer(1.0).timeout
	await process_frame
	# Side profile (shows the seating gap) then front.
	await _shot(root, Vector3(1.6, 0.25, 0.35), "user://allcontrols_side.png")
	await _shot(root, Vector3(0.4, 0.3, 1.4), "user://allcontrols_front.png")
	quit()


func _shot(root: Node3D, dir: Vector3, path: String) -> void:
	var box := _world_aabb(_console)
	var focus := box.get_center()
	var diag: float = maxf(0.4, box.size.length())
	_cam.size = diag * 1.05
	_cam.position = focus + dir.normalized() * diag * 1.6
	_cam.look_at(focus, Vector3.UP)
	await process_frame
	await create_timer(0.2).timeout
	await process_frame
	get_root().get_viewport().get_texture().get_image().save_png(path)
	print("[allcontrols] saved %s" % path)


func _world_aabb(node: Node) -> AABB:
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
