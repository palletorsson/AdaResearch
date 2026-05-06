extends SceneTree

## Smoke test — render ONE BotanicalFlower variant, save to a known
## location, exit. Use this to debug the gallery lab before running 60.

const BotanicalFlowerScene := preload("res://commons/flora/botanical_flower.tscn")

const CONFIG_PATH := "C:/Users/palle/Documents/GitHub/ada_encyclopedia/public/botanical-flower-gallery/bf_composite_disk_01.json"
const OUT_PATH := "user://bf_smoke.png"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	print("[bf_smoke] start")

	# Build a minimal scene root.
	var root_3d := Node3D.new()
	get_root().add_child(root_3d)
	print("[bf_smoke] root added")

	# Environment.
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.92, 0.92, 0.95)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_BG
	env.ambient_light_energy = 0.6
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	root_3d.add_child(world_env)
	print("[bf_smoke] env added")

	# Sun.
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 35, 0)
	sun.light_energy = 1.5
	root_3d.add_child(sun)
	print("[bf_smoke] sun added")

	# Camera — add to tree FIRST, then position + look_at (look_at
	# requires being in the tree, otherwise it silently fails and the
	# camera stays pointing at -Z).
	var camera := Camera3D.new()
	camera.fov = 35.0
	root_3d.add_child(camera)
	camera.global_position = Vector3(0.6, 0.4, 0.6)
	camera.look_at(Vector3(0.0, 0.2, 0.0), Vector3.UP)
	camera.current = true
	print("[bf_smoke] camera added at %s, looking at (0, 0.2, 0)" % camera.global_position)

	# Read config.
	print("[bf_smoke] reading config: %s" % CONFIG_PATH)
	var f := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if f == null:
		push_error("[bf_smoke] cannot open config: %s" % CONFIG_PATH)
		quit(1); return
	var raw := f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(raw)
	if not (parsed is Dictionary):
		push_error("[bf_smoke] bad JSON")
		quit(1); return
	var cfg: Dictionary = parsed
	print("[bf_smoke] config keys: %s" % cfg.keys())

	# Convert RGB lists to Color.
	for k in ["stem_color", "leaf_color", "petal_color", "sepal_color",
			  "stamen_color", "pistil_color"]:
		if cfg.has(k):
			var v = cfg[k]
			if v is Array and v.size() >= 3:
				cfg[k] = Color(float(v[0]), float(v[1]), float(v[2]))
				print("[bf_smoke]   converted %s -> Color" % k)

	# Spawn flower.
	var flower := BotanicalFlowerScene.instantiate()
	root_3d.add_child(flower)
	print("[bf_smoke] flower instantiated, configuring...")
	flower.configure(cfg)
	print("[bf_smoke] configure done, rebuilding...")
	flower.rebuild()
	print("[bf_smoke] rebuild done; flower has %d children (geometry)" % flower.get_child_count())

	# Wait a few frames + a moment for build.
	await create_timer(0.5).timeout
	await process_frame
	await process_frame

	# Capture.
	var img: Image = root.get_viewport().get_texture().get_image()
	if img == null:
		push_error("[bf_smoke] viewport image is null")
		quit(1); return
	var save_err := img.save_png(OUT_PATH)
	if save_err != OK:
		push_error("[bf_smoke] save_png failed: %s" % save_err)
		quit(1); return

	var globalized := ProjectSettings.globalize_path(OUT_PATH)
	print("[bf_smoke] DONE: %s" % globalized)
	quit(0)
