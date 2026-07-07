extends SceneTree
## Headless smoke test for the canonical TextScreen: builds STAND / PAD / SCREEN
## side by side, lights them, screenshots, quits.
##   godot --path . --xr-mode off --no-window --script res://commons/testing/test_text_screen.gd -- --shot=user://text_screen_test.png

const TextScreenScript = preload("res://commons/ui/text_screen.gd")

var _frames := 60
var _shot := "user://text_screen_test.png"


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if str(a).begins_with("--shot="):
			_shot = str(a).split("=", true, 1)[1]

	var root := Node3D.new()
	get_root().add_child(root)

	# Environment — neutral studio grey.
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.40, 0.41, 0.44)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.7, 0.71, 0.74)
	env.ambient_light_energy = 1.0
	var we := WorldEnvironment.new()
	we.environment = env
	root.add_child(we)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 35, 0)
	sun.light_energy = 1.0
	root.add_child(sun)

	# Three modes.
	var stand = TextScreenScript.new()
	stand.mode = stand.Mode.STAND
	stand.set_text("MAGNITUDE", "|v| = sqrt(x^2 + y^2 + z^2)\nthe diagonal of the box")
	stand.position = Vector3(-0.7, 0, 0)
	root.add_child(stand)

	var pad = TextScreenScript.new()
	pad.mode = pad.Mode.PAD
	pad.set_text("VECTOR PAD", "a + b = (a.x+b.x, a.y+b.y)\ntip to tail")
	pad.position = Vector3(0.0, 0, 0)
	root.add_child(pad)

	var screen = TextScreenScript.new()
	screen.mode = screen.Mode.SCREEN
	screen.set_text("SCREEN", "framed, lit,\nintegrated")
	screen.position = Vector3(0.7, 1.0, 0)
	root.add_child(screen)

	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 2.5
	cam.position = Vector3(1.7, 1.25, 1.9)
	cam.look_at(Vector3(0, 0.62, 0), Vector3.UP)
	root.add_child(cam)
	cam.current = true


func _process(_d: float) -> bool:
	_frames -= 1
	if _frames <= 0:
		var img := get_root().get_viewport().get_texture().get_image()
		img.save_png(_shot)
		print("[text_screen_test] shot saved: %s" % _shot)
		quit()
	return false
