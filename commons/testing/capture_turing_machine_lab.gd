## One-off capture for the Turing_Machine_Lab — player POV from inside.
##
## Loads the lab_room scene, applies the Turing-apparatus config from
## map_data.json, then captures from 4 viewpoints:
##   - player_pov : standing at spawn (back of room) looking at apparatus
##   - apparatus_close : standing close to the conveyor belt
##   - halt_button : standing at the back near the HALT podium
##   - exit_view : looking back at the entrance + exit sign
##
## Run:
##   "/c/Users/palle/Desktop/Godot_v4.6-stable_win64.exe" --path . \
##     --xr-mode off --no-window \
##     --script res://commons/testing/capture_turing_machine_lab.gd -- \
##     --out=user://turing_machine_lab
extends SceneTree

const ROOM_SCENE: String = "res://commons/artifacts/lab_room/lab_room.tscn"
const APPARATUS_SCENE: String = "res://commons/artifacts/turing_apparatus/turing_apparatus.tscn"

const CAPTURE_SIZE: Vector2i = Vector2i(1280, 1280)
const BG_COLOR: Color = Color(0.055, 0.055, 0.070)

var _output_dir: String = "user://turing_machine_lab"
var _viewport: SubViewport
var _camera: Camera3D


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
	env.ambient_light_color = Color(0.50, 0.55, 0.62)
	env.ambient_light_energy = 0.35
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.0
	env.tonemap_white = 1.15
	env.ssao_enabled = true
	env.ssao_intensity = 0.6
	env.ssao_radius = 0.7
	env.glow_enabled = true
	env.glow_intensity = 0.35
	env.glow_bloom = 0.10
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
	_camera.far = 80.0
	_camera.current = true
	_viewport.add_child(_camera)

	# Load and configure the lab_room with the Turing apparatus mounted
	var room_packed: PackedScene = load(ROOM_SCENE)
	if room_packed == null:
		push_error("Failed to load lab_room")
		quit(1)
		return
	var room: Node3D = room_packed.instantiate()
	# Apply Turing chamber DNA
	room.set("accent_color", Color(0.227, 0.482, 1.0))  # F_order blue
	room.set("signage_top", "TURING MACHINE LAB")
	room.set("signage_sub", "execute by walking")
	room.set("annotation_top", "M = (Q, Σ, Γ, δ, q0, F) — the chamber IS M")
	room.set("annotation_bottom", "belt = Γ*, panel = q, server rack = δ, button = HALT")
	room.set("room_width", 8.0)
	room.set("room_depth", 8.0)
	room.set("room_height", 3.8)
	room.set("mounted_artifact_scene", APPARATUS_SCENE)
	room.set("light_warmth", 0.9)  # cool light — Turing room is mechanical/clinical
	room.set("light_energy", 0.95)
	_viewport.add_child(room)

	# Fix lab_room signage rotation bug at capture time
	await create_timer(0.15).timeout
	_fix_signage_orientation(room)

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_output_dir))

	# ── Capture from 4 viewpoints ──────────────────────────────────
	var shots := [
		{
			"id": "player_pov",
			"camera_pos": Vector3(0.0, 1.7, 3.4),   # at +Z (back), standing at spawn
			"look_at":    Vector3(0.0, 1.3, -1.0),
			"notes": "Player POV from spawn — apparatus laid out front-to-back",
		},
		{
			"id": "apparatus_close",
			"camera_pos": Vector3(1.8, 1.65, 0.6),  # right side, closer to belt
			"look_at":    Vector3(-0.5, 1.0, -1.0),
			"notes": "Closer look at the belt-arm-rack triangle",
		},
		{
			"id": "halt_button",
			"camera_pos": Vector3(0.4, 1.65, -0.4),   # in front of the button podium
			"look_at":    Vector3(1.2, 1.0, -2.0),
			"notes": "The HALT button on its podium at the back",
		},
		{
			"id": "exit_view",
			"camera_pos": Vector3(0.0, 1.7, -0.5),   # standing in apparatus, looking back
			"look_at":    Vector3(0.0, 2.30, 2.50),  # the exit sign
			"notes": "Looking back at the exit sign — the return",
		},
	]

	for shot in shots:
		_camera.global_position = shot["camera_pos"]
		_camera.look_at(shot["look_at"], Vector3.UP)
		await get_root().get_tree().process_frame
		await get_root().get_tree().process_frame

		var img: Image = _viewport.get_texture().get_image()
		var path: String = "%s/%s.png" % [_output_dir, shot["id"]]
		img.save_png(path)
		print("[%s] %s -> %s" % [shot["id"], shot["notes"], path])

	print("DONE — 4 captures saved to %s" % _output_dir)
	quit(0)


func _fix_signage_orientation(room: Node3D) -> void:
	# Lab_room rotates signage_root 180° around Y assuming Label3D faces -Z,
	# but Label3D in Godot 4 defaults to +Z — this flips the text wrong way.
	var signage_root: Node = room.find_child("SignageRoot", true, false)
	if signage_root != null and signage_root is Node3D:
		(signage_root as Node3D).rotation = Vector3.ZERO
