## Multi-chamber capture for the three algorithm-trajectory rooms shipped
## 2026-05-22 (QFEP phase chamber, foundations crisis hall, monte carlo
## room).
##
## For each chamber, render the lab_room with the apparatus mounted and
## capture from 2 player-POV camera positions (wide and close).
##
## Run:
##   "/c/Users/palle/Desktop/Godot_v4.6-stable_win64.exe" --path . \
##     --xr-mode off --no-window \
##     --script res://commons/testing/capture_trajectory_chambers.gd -- \
##     --out=user://trajectory_chambers
extends SceneTree

const ROOM_SCENE: String = "res://commons/artifacts/lab_room/lab_room.tscn"

const CAPTURE_SIZE: Vector2i = Vector2i(1280, 1280)
const BG_COLOR: Color = Color(0.055, 0.055, 0.070)

var _output_dir: String = "user://trajectory_chambers"
var _viewport: SubViewport
var _camera: Camera3D
var _scene_holder: Node3D


func _initialize() -> void:
	for arg in OS.get_cmdline_args():
		if arg.begins_with("--out="):
			_output_dir = arg.split("=")[1]
	_run.call_deferred()


func _run() -> void:
	_viewport = SubViewport.new()
	_viewport.size = CAPTURE_SIZE
	_viewport.transparent_bg = false
	_viewport.own_world_3d = true
	var iso_world := World3D.new()

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = BG_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.58, 0.65)
	env.ambient_light_energy = 0.40
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.0
	env.tonemap_white = 1.15
	env.ssao_enabled = true
	env.ssao_intensity = 0.6
	env.ssao_radius = 0.7
	env.glow_enabled = true
	env.glow_intensity = 0.40
	env.glow_bloom = 0.12
	iso_world.environment = env

	_viewport.world_3d = iso_world
	_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport.msaa_3d = Viewport.MSAA_8X
	_viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
	_viewport.use_taa = false
	_viewport.use_debanding = true
	get_root().add_child(_viewport)

	_camera = Camera3D.new()
	_camera.fov = 60.0
	_camera.near = 0.05
	_camera.far = 100.0
	_camera.current = true
	_viewport.add_child(_camera)

	_scene_holder = Node3D.new()
	_viewport.add_child(_scene_holder)

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_output_dir))

	var chambers: Array = [
		{
			"id": "qfep_phase",
			"accent_color": Color(0.608, 0.365, 0.890),
			"signage_top": "QFEP PHASE CHAMBER",
			"signage_sub": "walk the phase diagram",
			"room_width": 9.0, "room_depth": 9.0, "room_height": 3.8,
			"light_warmth": 0.5, "light_energy": 0.85,
			"apparatus": "res://commons/artifacts/qfep_phase_apparatus/qfep_phase_apparatus.tscn",
			"shots": [
				{"id": "wide", "pos": Vector3(0.0, 1.85, 4.2), "look": Vector3(0.0, 1.1, -1.5)},
				{"id": "close", "pos": Vector3(1.8, 1.75, 2.0), "look": Vector3(-0.5, 1.1, -0.8)},
			],
		},
		{
			"id": "foundations_crisis",
			"accent_color": Color(0.902, 0.224, 0.275),
			"signage_top": "FOUNDATIONS CRISIS HALL",
			"signage_sub": "five known limits",
			"room_width": 8.0, "room_depth": 14.0, "room_height": 3.8,
			"light_warmth": 0.7, "light_energy": 0.75,
			"apparatus": "res://commons/artifacts/foundations_crisis_apparatus/foundations_crisis_apparatus.tscn",
			"shots": [
				{"id": "wide", "pos": Vector3(0.0, 1.85, 6.2), "look": Vector3(0.0, 1.0, -4.0)},
				{"id": "close", "pos": Vector3(0.5, 1.75, 1.0), "look": Vector3(-1.5, 1.2, -1.5)},
			],
		},
		{
			"id": "monte_carlo",
			"accent_color": Color(0.20, 0.55, 0.95),
			"signage_top": "MONTE CARLO ROOM",
			"signage_sub": "sample · walk · weigh · report",
			"room_width": 8.0, "room_depth": 8.0, "room_height": 3.8,
			"light_warmth": 0.6, "light_energy": 0.90,
			"apparatus": "res://commons/artifacts/monte_carlo_apparatus/monte_carlo_apparatus.tscn",
			"shots": [
				{"id": "wide", "pos": Vector3(0.0, 1.85, 3.5), "look": Vector3(0.0, 1.0, -1.2)},
				{"id": "close", "pos": Vector3(-1.8, 1.65, 1.4), "look": Vector3(0.3, 1.0, -0.8)},
			],
		},
	]

	var room_packed: PackedScene = load(ROOM_SCENE)
	if room_packed == null:
		push_error("Failed to load lab_room")
		quit(1)
		return

	for chamber in chambers:
		var apparatus_packed: PackedScene = load(chamber["apparatus"])
		if apparatus_packed == null:
			push_error("Failed to load apparatus %s" % chamber["apparatus"])
			continue

		var room: Node3D = room_packed.instantiate()
		room.set("accent_color", chamber["accent_color"])
		room.set("signage_top", chamber["signage_top"])
		room.set("signage_sub", chamber["signage_sub"])
		room.set("room_width", chamber["room_width"])
		room.set("room_depth", chamber["room_depth"])
		room.set("room_height", chamber["room_height"])
		room.set("light_warmth", chamber["light_warmth"])
		room.set("light_energy", chamber["light_energy"])
		room.set("mounted_artifact_scene", chamber["apparatus"])
		_scene_holder.add_child(room)
		await create_timer(0.20).timeout
		_fix_signage_orientation(room)

		for shot in chamber["shots"]:
			_camera.global_position = shot["pos"]
			_camera.look_at(shot["look"], Vector3.UP)
			await get_root().get_tree().process_frame
			await get_root().get_tree().process_frame
			var img: Image = _viewport.get_texture().get_image()
			var path: String = "%s/%s_%s.png" % [_output_dir, chamber["id"], shot["id"]]
			img.save_png(path)
			print("[%s] %s -> %s" % [chamber["id"], shot["id"], path])

		for child in _scene_holder.get_children():
			child.queue_free()
		await create_timer(0.10).timeout

	print("DONE — %d chambers captured" % chambers.size())
	quit(0)


func _fix_signage_orientation(room: Node3D) -> void:
	var signage_root: Node = room.find_child("SignageRoot", true, false)
	if signage_root != null and signage_root is Node3D:
		(signage_root as Node3D).rotation = Vector3.ZERO
