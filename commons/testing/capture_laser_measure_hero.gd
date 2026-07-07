## One-off capture script for laser_measure — frames the handle from
## horizontal angles (the default capture_multi_angle pitches look down 20°,
## which misses the vertical handle). This script does a tight horizontal
## orbit and saves 4 hero shots.
##
## Run:
##   godot --path . --xr-mode off --no-window \
##     --script res://commons/testing/capture_laser_measure_hero.gd \
##     -- --out=user://laser_hero
##
## Output: <out>/{hero_front,hero_45,hero_side,hero_top}.png
extends SceneTree

const ARTIFACT_CATALOG_SCENE: String = "res://commons/artifacts/catalog/ArtifactCatalogDesktop3D.tscn"

var _output_dir: String = "user://laser_hero"


func _initialize() -> void:
	for arg in OS.get_cmdline_args():
		if arg.begins_with("--out="):
			_output_dir = arg.split("=")[1]
	# Kick off async work
	_run.call_deferred()


func _run() -> void:
	# Build a minimal scene (no catalog UI) — just lighting + environment + artifact.
	# This avoids the catalog's left-panel + bottom-comment-box from cluttering the captures.

	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.08, 0.09, 0.12)   # dark slate
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.5, 0.5, 0.55)
	env.ambient_light_energy = 0.45
	env_node.environment = env
	get_root().add_child(env_node)

	var key_light := DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-35, 30, 0)
	key_light.light_energy = 1.4
	key_light.light_color = Color(1.0, 0.95, 0.85)
	get_root().add_child(key_light)

	var fill_light := DirectionalLight3D.new()
	fill_light.rotation_degrees = Vector3(-15, -110, 0)
	fill_light.light_energy = 0.5
	fill_light.light_color = Color(0.7, 0.8, 1.0)
	get_root().add_child(fill_light)

	var cam := Camera3D.new()
	cam.fov = 35.0   # narrower FOV for tighter framing
	cam.near = 0.01  # close near plane so body isn't clipped
	cam.current = true
	get_root().add_child(cam)

	# Spawn artifact directly at world origin (no catalog wrapper)
	var artifact_scene = load("res://commons/primitives/laser_measure/grab_laser_measure.tscn")
	if not artifact_scene:
		push_error("Failed to load laser_measure scene")
		quit(1)
		return
	var artifact = artifact_scene.instantiate()
	artifact.position = Vector3(0, 1.0, 0)
	get_root().add_child(artifact)

	# Hide grab-point indicators + the grab_stick base's magenta debug box.
	# These are dev/preview affordances, not part of the artifact's visual identity.
	for child_name in ["GrabPointHandLeft", "GrabPointHandRight", "HighlightRing", "MeshInstance3D"]:
		var gp = artifact.get_node_or_null(child_name)
		if gp and gp is Node3D:
			gp.visible = false

	# Settle physics + ready
	await create_timer(2.0).timeout

	var focus := Vector3(0, 1.0, 0)
	# Body is at world (0, 1, 0) — handle is along Z, so look from horizontal
	# angles around the Y axis. Distance close enough for body (12 cm) to fill
	# ~40% of frame at fov 35°.
	#   visible width at d=0.5 m, fov 35° ≈ 0.32 m, so 12 cm body ≈ 38% ✓
	var distance := 0.5
	var angles := [
		{"name": "hero_front",  "yaw": 0.0,    "pitch": 0.0,    "dist": distance,                            "focus_off": Vector3.ZERO},
		{"name": "hero_45",     "yaw": 0.785,  "pitch": 0.15,   "dist": distance,                            "focus_off": Vector3.ZERO},
		{"name": "hero_side",   "yaw": 1.5708, "pitch": 0.0,    "dist": distance,                            "focus_off": Vector3.ZERO},
		{"name": "hero_top",    "yaw": 0.0,    "pitch": 1.4,    "dist": distance,                            "focus_off": Vector3.ZERO},
		# LCD close-up: look straight DOWN at the handle's top face, very close,
		# focus shifted slightly toward the butt-end where the LCD sits.
		{"name": "hero_lcd",    "yaw": 0.0,    "pitch": 1.5707, "dist": 0.18,                                "focus_off": Vector3(0, 0, 0.015)},
	]

	# Output dir
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_output_dir))

	for entry in angles:
		var yaw_rad: float = entry["yaw"]
		var pitch_rad: float = entry["pitch"]
		var d: float = entry.get("dist", distance)
		var focus_off: Vector3 = entry.get("focus_off", Vector3.ZERO)
		var this_focus := focus + focus_off
		var cam_pos := this_focus + Vector3(
			d * sin(yaw_rad) * cos(pitch_rad),
			d * sin(pitch_rad),
			d * cos(yaw_rad) * cos(pitch_rad)
		)
		cam.global_position = cam_pos
		cam.look_at(this_focus, Vector3.UP)
		await create_timer(0.25).timeout

		var image := get_root().get_viewport().get_texture().get_image()
		var path := "%s/%s.png" % [_output_dir, entry["name"]]
		image.save_png(ProjectSettings.globalize_path(path))
		print("  saved: %s" % path)

	print("DONE — 4 hero shots saved to %s" % _output_dir)
	quit(0)
