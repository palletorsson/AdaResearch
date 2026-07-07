# capture_tutorial_walls.gd — batch-capture the tutorial wall for every map
# that has a tutorial.md. One Godot run, one front shot per map, boards only
# (example_count=0 keeps headless safe: no sim artifacts get instantiated).
#
#   python tools/godot_watchdog.py --expect="<user>/tutorial_walls/manifest.json" -- \
#     <godot exe> --path . --xr-mode off --no-window \
#     --script res://commons/testing/capture_tutorial_walls.gd -- --limit=0
#
# Output: user://tutorial_walls/<Map>.png + manifest.json
extends SceneTree

const WALL_SCENE := "res://commons/artifacts/tutorial_wall/tutorial_wall.tscn"
const OUT_DIR := "user://tutorial_walls"

var _limit := 0   # 0 = all

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--limit="):
			_limit = int(arg.split("=")[1])
	call_deferred("_run")

func _run() -> void:
	var maps := _maps_with_tutorials()
	if _limit > 0:
		maps = maps.slice(0, _limit)
	print("capture_tutorial_walls: %d maps" % maps.size())

	# stage: env + lights + camera, one wall reused via apply_grid_config
	var stage := Node3D.new()
	root.add_child(stage)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.12, 0.12, 0.16)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.5, 0.5, 0.55)
	env.ambient_light_energy = 0.7
	var we := WorldEnvironment.new()
	we.environment = env
	stage.add_child(we)
	var cam := Camera3D.new()
	cam.current = true
	cam.fov = 45.0
	stage.add_child(cam)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-40, -25, 0)
	light.light_energy = 1.1
	stage.add_child(light)

	var packed: PackedScene = load(WALL_SCENE)
	var wall: Node3D = packed.instantiate()
	stage.add_child(wall)

	# front-on framing: wall is ~4m wide, 2.6m tall, faces +Z
	cam.global_position = Vector3(0, 1.35, 4.6)
	cam.look_at(Vector3(0, 1.35, 0))

	var abs_dir := ProjectSettings.globalize_path(OUT_DIR)
	if not DirAccess.dir_exists_absolute(abs_dir):
		DirAccess.make_dir_recursive_absolute(abs_dir)

	var done: Array = []
	for m in maps:
		wall.apply_grid_config({"map": m, "example_count": 0})
		await process_frame
		await process_frame
		await process_frame
		var img: Image = root.get_texture().get_image()
		if img:
			var path := abs_dir.path_join("%s.png" % m)
			if img.save_png(path) == OK:
				done.append(m)
				print("  ok %s" % m)

	var f := FileAccess.open(OUT_DIR + "/manifest.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"count": done.size(), "maps": done}, " "))
	f.close()
	print("capture_tutorial_walls: saved %d walls -> %s" % [done.size(), abs_dir])
	quit()

func _maps_with_tutorials() -> Array:
	var out: Array = []
	var dir := DirAccess.open("res://commons/maps")
	if dir == null:
		return out
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if dir.current_is_dir() and not name.begins_with("."):
			if FileAccess.file_exists("res://commons/maps/%s/tutorial.md" % name):
				out.append(name)
		name = dir.get_next()
	out.sort()
	return out
