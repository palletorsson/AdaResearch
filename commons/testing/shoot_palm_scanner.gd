extends SceneTree

## One-off: render the palm_scanner from a few angles straight to the
## encyclopedia public folder (NOT the Godot repo) so we can look at it.
##   godot --path . --xr-mode off --script res://commons/testing/shoot_palm_scanner.gd
##
## Writes <enc>/public/artifact-gallery/captures/palm_scanner/<angle>.png
## and prints a [shoot] line per file with the absolute path + byte size.

const SCANNER := "res://commons/artifacts/palm_scanner/palm_scanner.tscn"
const OUT_DIR := "C:/Users/palle/Documents/GitHub/ada_encyclopedia/public/artifact-gallery/captures/palm_scanner"
const W := 1280
const H := 960


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)

	var root := get_root()
	# Neutral studio environment so the dark panel reads.
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.16, 0.17, 0.2)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.7, 0.72, 0.78)
	env.ambient_light_energy = 1.1
	we.environment = env
	root.add_child(we)

	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-42, -38, 0)
	key.light_energy = 1.4
	root.add_child(key)

	var scanner: Node3D = load(SCANNER).instantiate()
	# Match the deployed lab config so we shoot what the player actually sees.
	scanner.set("scan_active", true)
	scanner.set("mounting", "podium")
	root.add_child(scanner)

	# Let it build + settle.
	for i in range(40):
		await process_frame

	# Aim at the scan plate (podium plate sits ~1.1 m up).
	var target := Vector3(0.0, 1.0, 0.0)

	var cam := Camera3D.new()
	cam.fov = 42.0
	root.add_child(cam)
	cam.make_current()

	var shots := {
		"front":      Vector3(0.0,  1.15,  2.4),
		"three_q":    Vector3(1.7,  1.45,  2.0),
		"left":       Vector3(-2.3, 1.15,  0.6),
		"hand_reach": Vector3(0.55, 1.35,  0.85),
	}

	for angle in shots.keys():
		cam.global_position = shots[angle]
		cam.look_at(target, Vector3.UP)
		for i in range(4):
			await process_frame
		var img: Image = get_root().get_texture().get_image()
		var path := "%s/%s.png" % [OUT_DIR, angle]
		var err := img.save_png(path)
		var sz := 0
		if FileAccess.file_exists(path):
			var f := FileAccess.open(path, FileAccess.READ)
			if f:
				sz = f.get_length()
				f.close()
		print("[shoot] %-12s err=%s  %d bytes  %s" % [angle, err, sz, path])

	print("[shoot] DONE -> %s" % OUT_DIR)
	quit(0)
