## One-off capture for quantum_dice — instantiates the scene directly so we
## can verify the geometry builds correctly without the catalog framing logic
## (which over-distances small artifacts).
extends SceneTree

const SCENE_PATH: String = "res://commons/primitives/dice/quantum_dice.tscn"
var _output_dir: String = "user://dice_demo"


func _initialize() -> void:
	for arg in OS.get_cmdline_args():
		if arg.begins_with("--out="):
			_output_dir = arg.split("=")[1]
	_run.call_deferred()


func _run() -> void:
	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.08, 0.09, 0.12)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.5, 0.5, 0.55)
	env.ambient_light_energy = 0.6
	env_node.environment = env
	get_root().add_child(env_node)

	var key_light := DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-35, 30, 0)
	key_light.light_energy = 1.4
	get_root().add_child(key_light)

	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-15, -110, 0)
	fill.light_energy = 0.5
	get_root().add_child(fill)

	var cam := Camera3D.new()
	cam.fov = 40.0
	cam.near = 0.01
	cam.current = true
	get_root().add_child(cam)

	# Spawn DEFAULT die (solid mode, fair weights)
	var scene = load(SCENE_PATH)
	if not scene:
		push_error("Failed to load quantum_dice scene")
		quit(1)
		return
	var die_a = scene.instantiate()
	die_a.position = Vector3(-0.35, 0, 0)   # left
	get_root().add_child(die_a)

	# Spawn QUANTUM die with loaded weights — needs property override post-instantiate
	var die_b = scene.instantiate()
	die_b.position = Vector3( 0.35, 0, 0)   # right
	die_b.quantum_mode = true
	die_b.face_weights = PackedFloat32Array([0.1, 0.2, 0.3, 0.5, 0.8, 2.0])  # loaded toward 6
	get_root().add_child(die_b)

	await create_timer(1.5).timeout

	# Frame both dice side-by-side
	var focus := Vector3(0, 0, 0)
	var distance := 1.4

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_output_dir))

	var angles := [
		{"name": "front",  "yaw": 0.0,      "pitch": 0.15},
		{"name": "side",   "yaw": 1.5708,   "pitch": 0.15},
		{"name": "top",    "yaw": 0.3,      "pitch": 1.0},
		{"name": "iso",    "yaw": 0.7,      "pitch": 0.45},
	]

	for entry in angles:
		var yaw_rad: float = entry["yaw"]
		var pitch_rad: float = entry["pitch"]
		cam.global_position = focus + Vector3(
			distance * sin(yaw_rad) * cos(pitch_rad),
			distance * sin(pitch_rad),
			distance * cos(yaw_rad) * cos(pitch_rad)
		)
		cam.look_at(focus, Vector3.UP)
		await create_timer(0.25).timeout
		var image := get_root().get_viewport().get_texture().get_image()
		var path := "%s/%s.png" % [_output_dir, entry["name"]]
		image.save_png(ProjectSettings.globalize_path(path))
		print("saved: %s" % path)
	print("DONE")
	quit(0)
