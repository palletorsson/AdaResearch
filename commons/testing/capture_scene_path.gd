extends SceneTree

## Capture any scene by file path — for interactables and other
## non-registry artifacts. Loads <scene_path>, frames camera by AABB,
## captures 4 angles. Output: <out>/{front,left,right,top}.png.
##
## Usage:
##   godot --xr-mode off --no-window \
##     --script res://commons/testing/capture_scene_path.gd -- \
##     --scene=res://commons/interactables/slider_horizontal.tscn \
##     --out=user://interaction_dna_out/slider_horizontal

# Angles tuned for panel-mounted interactables (sliders, dials, joysticks,
# levers). Their key feature is the FACE of the panel — circular knob,
# track and handle, ball-and-stem — which only reads correctly when the
# camera is mostly head-on. Earlier 3/4 angles (yaw=0.4, pitch=0.4) made
# dials look like extruded blobs because the rotation axis was hidden.
const ARTIFACT_ANGLES: Array[Dictionary] = [
	{ "name": "front",  "yaw": 0.0,    "pitch": 0.1   },  # nearly head-on, slight downward
	{ "name": "left",   "yaw": 0.6,    "pitch": 0.2   },  # 3/4 from left
	{ "name": "right",  "yaw": -0.6,   "pitch": 0.2   },  # 3/4 from right
	{ "name": "side",   "yaw": 1.5708, "pitch": 0.06  },  # true left profile — reads depth/height
	{ "name": "top",    "yaw": 0.001,  "pitch": 1.2   },  # mostly down, not straight
]

var _scene_path: String = ""
var _output_dir: String = "user://capture_scene_out"
var _wait_seconds: float = 1.5
var _width: int = 512
var _height: int = 512


func _initialize() -> void:
	_parse_args()
	if _scene_path.is_empty():
		push_error("capture_scene_path: --scene=res://... is required")
		quit(1)
		return

	var packed: PackedScene = ResourceLoader.load(_scene_path)
	if not packed:
		push_error("capture_scene_path: failed to load %s" % _scene_path)
		quit(1)
		return

	root.size = Vector2i(_width, _height)

	var scene_root := Node3D.new()
	scene_root.name = "CaptureRoot"
	root.add_child(scene_root)

	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.55, 0.62, 0.45, 1.0)  # sage green, matches other captures
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.65, 0.67, 0.70, 1.0)
	e.ambient_light_energy = 1.4   # brighter ambient so dark glossy materials show form
	env.environment = e
	scene_root.add_child(env)

	# Three-point lighting: key from upper-front-right, fill from upper-left,
	# rim from behind to separate dark glossy knobs from background.
	var key_light := DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-40.0, 30.0, 0.0)
	key_light.light_energy = 1.2
	scene_root.add_child(key_light)

	var fill_light := DirectionalLight3D.new()
	fill_light.rotation_degrees = Vector3(-30.0, -45.0, 0.0)
	fill_light.light_energy = 0.6
	scene_root.add_child(fill_light)

	var rim_light := DirectionalLight3D.new()
	rim_light.rotation_degrees = Vector3(20.0, 180.0, 0.0)
	rim_light.light_energy = 0.5
	scene_root.add_child(rim_light)

	var camera := Camera3D.new()
	camera.fov = 45.0
	scene_root.add_child(camera)
	camera.current = true

	var artifact: Node = packed.instantiate()
	if not artifact or not (artifact is Node3D):
		push_error("capture_scene_path: scene root is not Node3D — %s" % _scene_path)
		quit(1)
		return
	scene_root.add_child(artifact)

	# Disable any cameras the artifact created (so our orbit camera wins).
	_disable_cameras_recursive(artifact)
	camera.current = true

	# Let _ready run.
	await process_frame
	await process_frame
	await process_frame
	await create_timer(_wait_seconds).timeout
	await process_frame

	# AABB for framing.
	var aabb: AABB = _get_combined_aabb(artifact as Node3D)
	var orbit_focus: Vector3 = Vector3.ZERO
	var base_distance: float = 1.0

	if aabb.size.length() > 0:
		orbit_focus = aabb.get_center()
		var max_dim: float = max(aabb.size.x, max(aabb.size.y, aabb.size.z))
		base_distance = max_dim * 1.4
	else:
		# Empty AABB — fall back.
		base_distance = 0.5

	var output_abs: String = ProjectSettings.globalize_path(_output_dir)
	DirAccess.make_dir_recursive_absolute(output_abs)

	var saved: int = 0
	for angle_def in ARTIFACT_ANGLES:
		var angle_name: String = angle_def["name"]
		var yaw: float = float(angle_def["yaw"])
		var pitch: float = float(angle_def["pitch"])

		var cam_offset := Vector3(
			sin(yaw) * cos(pitch),
			sin(pitch),
			cos(yaw) * cos(pitch)
		) * base_distance
		camera.global_position = orbit_focus + cam_offset
		camera.look_at(orbit_focus, Vector3.UP)

		await process_frame
		await process_frame
		await create_timer(0.1).timeout
		await process_frame

		var img: Image = root.get_texture().get_image()
		if img == null:
			continue
		var path: String = output_abs.path_join("%s.png" % angle_name)
		if img.save_png(path) == OK:
			saved += 1

	print("capture_scene_path: %d/%d saved to %s" % [saved, ARTIFACT_ANGLES.size(), output_abs])
	quit(0)


func _parse_args() -> void:
	for arg in OS.get_cmdline_user_args():
		var eq: int = arg.find("=")
		if eq < 0:
			continue
		var key: String = arg.substr(0, eq).lstrip("-")
		var val: String = arg.substr(eq + 1)
		match key:
			"scene": _scene_path = val
			"out", "output": _output_dir = val


func _disable_cameras_recursive(node: Node) -> void:
	if node is Camera3D:
		(node as Camera3D).current = false
	for child in node.get_children():
		_disable_cameras_recursive(child)


func _get_combined_aabb(root_node: Node3D) -> AABB:
	var combined := AABB()
	var first := true
	for n in _walk(root_node):
		if n is VisualInstance3D:
			var ab: AABB = (n as VisualInstance3D).get_aabb()
			# Transform to world space.
			var xform: Transform3D = (n as Node3D).global_transform
			ab = xform * ab
			if first:
				combined = ab
				first = false
			else:
				combined = combined.merge(ab)
	return combined


func _walk(node: Node) -> Array:
	var out := [node]
	for c in node.get_children():
		out.append_array(_walk(c))
	return out
