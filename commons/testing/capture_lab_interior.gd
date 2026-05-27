## Capture the interior of a single lab built from a .lab.json file.
##
## Loads lab_room.tscn, applies the JSON's lab_room block as config_*
## metadata, lifts mounted_props in via lab_loader.gd, then captures
## four angles from INSIDE the lab at player eye-height:
##   - looking up (to see the procedural ceiling fixtures)
##   - back wall (signage, door, back window)
##   - front wall (front window)
##   - side (east wall + info screen)
##
## Run:
##   "/c/Users/palle/Desktop/Godot_v4.6-stable_win64.exe" --path . \
##     --xr-mode off --no-window \
##     --script res://commons/testing/capture_lab_interior.gd -- \
##     --lab=primitives_test --out=user://lab_interior
##
## Output: <out>/{angle}.png + manifest.json
extends SceneTree

const ROOM_SCENE_PATH: String = "res://commons/artifacts/lab_room/lab_room.tscn"
const LAB_LOADER_PATH: String = "res://commons/artifacts/lab_room/lab_loader.gd"

const CAPTURE_SIZE: Vector2i = Vector2i(1280, 800)
const BG_COLOR: Color = Color(0.055, 0.055, 0.070)
const EYE_HEIGHT: float = 1.6
const CAMERA_FOV: float = 70.0

var _lab_name: String = "primitives_test"
var _output_dir: String = "user://lab_interior"
var _viewport: SubViewport
var _camera: Camera3D


func _initialize() -> void:
	for arg in OS.get_cmdline_args():
		if arg.begins_with("--lab="):
			_lab_name = arg.split("=")[1]
		elif arg.begins_with("--out="):
			_output_dir = arg.split("=")[1]
	_run.call_deferred()


func _run() -> void:
	# Isolated viewport
	_viewport = SubViewport.new()
	_viewport.size = CAPTURE_SIZE
	_viewport.own_world_3d = true
	_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport.msaa_3d = Viewport.MSAA_4X

	var iso_world := World3D.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = BG_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.55, 0.60)
	env.ambient_light_energy = 0.45
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 0.6
	env.glow_enabled = true
	env.glow_intensity = 0.10
	env.ssao_enabled = true
	env.ssao_intensity = 0.4
	iso_world.environment = env
	_viewport.world_3d = iso_world
	get_root().add_child(_viewport)

	# Camera (positioned per-angle below).
	_camera = Camera3D.new()
	_camera.fov = CAMERA_FOV
	_camera.near = 0.05
	_camera.far = 80.0
	_camera.current = true
	_viewport.add_child(_camera)

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_output_dir))

	# Load lab JSON.
	var json_path := "res://commons/labs/%s.lab.json" % _lab_name
	if not FileAccess.file_exists(json_path):
		push_error("Lab JSON not found: %s" % json_path)
		quit(1)
		return
	var raw: String = FileAccess.get_file_as_string(json_path)
	var lab_data = JSON.parse_string(raw)
	if not (lab_data is Dictionary):
		push_error("Lab JSON parse failed")
		quit(1)
		return

	# Build the room from lab_room.tscn, applying JSON config to it.
	var scene: PackedScene = load(ROOM_SCENE_PATH)
	if scene == null:
		push_error("lab_room.tscn not found")
		quit(1)
		return
	var room: Node3D = scene.instantiate()

	# Set metadata BEFORE add_child() so lab_room.gd's _ready sees it.
	# It reads config_mounted_lab_json and runs LabLoader.load_into()
	# itself, then _lift_lab_room_block_into_meta() pulls the lab_room
	# block into config_* fields. Just point it at the JSON file.
	room.set_meta("config_mounted_lab_json", json_path)
	_viewport.add_child(room)

	# Wait for room to build itself (geometry + props).
	await create_timer(0.8).timeout

	# Room dimensions for camera framing — read from the JSON's lab_room
	# block (defaults match lab_room.gd's @export defaults).
	var lr: Dictionary = lab_data.get("lab_room", {})
	var room_w: float = float(lr.get("room_width", 8.0))
	var room_d: float = float(lr.get("room_depth", 7.0))
	var room_h: float = float(lr.get("room_height", 3.8))

	var entries: Array = []

	# 1. Looking UP at the ceiling — camera at chest height, tilted ~75°
	#    upward so the ceiling fills the frame. Use rotation_degrees
	#    directly (look_at with near-parallel target+up flips weirdly).
	_camera.position = Vector3(0.0, 1.2, 0.0)
	_camera.rotation_degrees = Vector3(75.0, 0.0, 0.0)
	await create_timer(0.15).timeout
	entries.append(_capture_to_png("ceiling_up"))
	# Reset rotation in case it leaks into next shots.
	_camera.rotation = Vector3.ZERO

	# 2. Back wall — signage, door, back window (signage_top is on -Z
	#    per lab_room.gd convention; camera near +Z back of room looking
	#    toward -Z).
	_camera.position = Vector3(0.0, EYE_HEIGHT, room_d * 0.35)
	_camera.look_at(Vector3(0.0, EYE_HEIGHT * 0.8, -room_d * 0.5), Vector3.UP)
	await create_timer(0.15).timeout
	entries.append(_capture_to_png("back_wall"))

	# 3. Front wall — front window. Camera near -Z front looking toward
	#    +Z back wall. Player turning around after entering through the
	#    south door.
	_camera.position = Vector3(0.0, EYE_HEIGHT, -room_d * 0.30)
	_camera.look_at(Vector3(0.0, EYE_HEIGHT * 0.8, room_d * 0.5), Vector3.UP)
	await create_timer(0.15).timeout
	entries.append(_capture_to_png("front_wall"))

	# 4. East wall (where info_screen lives) — stand left, look east.
	_camera.position = Vector3(-room_w * 0.30, EYE_HEIGHT, 0.0)
	_camera.look_at(Vector3(room_w * 0.5, EYE_HEIGHT * 0.8, 0.0), Vector3.UP)
	await create_timer(0.15).timeout
	entries.append(_capture_to_png("east_wall"))

	# Manifest.
	var manifest := {
		"version": 1,
		"lab": _lab_name,
		"room": {"width": room_w, "depth": room_d, "height": room_h},
		"capture_size": [CAPTURE_SIZE.x, CAPTURE_SIZE.y],
		"angles": entries,
	}
	var f := FileAccess.open("%s/manifest.json" % _output_dir, FileAccess.WRITE)
	f.store_string(JSON.stringify(manifest, "\t"))
	f.close()

	print("DONE — %d angles → %s" % [entries.size(), _output_dir])
	quit(0)


func _capture_to_png(name: String) -> Dictionary:
	var img: Image = _viewport.get_texture().get_image()
	if img == null:
		push_warning("Capture returned null for %s" % name)
		return {"name": name, "error": "null image"}
	var path := "%s/%s.png" % [_output_dir, name]
	img.save_png(path)
	print("  -> %s" % path)
	return {"name": name, "path": "%s.png" % name}


func _array_as_string(arr: Array) -> String:
	# lab_room.gd parses array configs from "x,y,z" strings.
	var parts: Array = []
	for v in arr:
		parts.append(str(v))
	return ",".join(parts)
