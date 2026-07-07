extends SceneTree
## Smoke test for the canonical ControlPanel with REAL controls (runtime-loaded
## so the XR autoloads are up — bare preload fails on XRToolsUserSettings).
## Builds title + two sliders + a button + a screen, screenshots.
##   godot --path . --xr-mode off --no-window --script res://commons/testing/test_control_panel.gd -- --shot=user://control_panel_test.png

const ControlPanelScript = preload("res://commons/ui/control_panel.gd")

var _shot := "user://control_panel_test.png"
var _panel: Node3D


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
	var we := WorldEnvironment.new()
	we.environment = env
	root.add_child(we)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 35, 0)
	sun.light_energy = 1.0
	root.add_child(sun)

	_panel = ControlPanelScript.new()
	_panel.title = "Stretch Bench"
	root.add_child(_panel)

	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 1.55
	cam.position = Vector3(0.0, 0.28, 1.6)
	cam.look_at(Vector3(0, -0.04, 0), Vector3.UP)
	root.add_child(cam)
	cam.current = true

	_run()


func _run() -> void:
	# Wait for autoloads + tree, then add the REAL canonical controls.
	await process_frame
	await process_frame
	await create_timer(0.4).timeout
	_panel.add_slider("SCALE k")
	_panel.add_slider("LENGTH")
	_panel.add_button("SNAP")
	_panel.add_screen("|k*v|", "1.48")
	await process_frame
	await create_timer(0.6).timeout
	await process_frame
	var img := get_root().get_viewport().get_texture().get_image()
	img.save_png(_shot)
	print("[control_panel_test] shot saved: %s" % _shot)
	quit()
