extends SceneTree

## Render one artifact config to a multi-angle PNG set. Mirror of
## render_substrate_config.gd / render_mesh_grammar.gd convention.
##
## Reads a JSON config, instantiates the artifact's .tscn, optionally
## applies parameter overrides via apply_grid_config(), captures from
## a single isometric angle (or multi-angle if --multi=true), saves PNGs.
##
## Usage:
##   godot --path . --xr-mode off --no-window \
##     --script res://commons/testing/render_artifact_config.gd -- \
##     --config=<path>.json --out=user://art_gallery/<id>.png

var _config_path: String = ""
var _out_path: String = "user://art_gallery/render.png"
var _multi: bool = false


func _initialize() -> void:
	for raw in OS.get_cmdline_user_args():
		var arg: String = String(raw).strip_edges()
		if not arg.begins_with("--"):
			continue
		var eq: int = arg.find("=")
		if eq <= 2:
			continue
		var key: String = arg.substr(2, eq - 2)
		var value: String = arg.substr(eq + 1).strip_edges()
		match key:
			"config": _config_path = value
			"out": _out_path = value
			"multi": _multi = value.to_lower() in ["1", "true", "yes"]
	if _config_path.is_empty():
		push_error("render_artifact_config: --config=<path> required")
		quit(1)
		return
	call_deferred("_run")


func _load_config() -> Dictionary:
	var f := FileAccess.open(_config_path, FileAccess.READ)
	if not f:
		return {}
	var raw: String = f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(raw)
	return parsed if parsed is Dictionary else {}


func _run() -> void:
	var cfg: Dictionary = _load_config()
	if cfg.is_empty():
		push_error("render_artifact_config: bad config %s" % _config_path)
		quit(1)
		return
	var cid: String = str(cfg.get("id", "untitled"))
	var scene_path: String = str(cfg.get("scene", ""))
	if scene_path.is_empty():
		push_error("render_artifact_config: config missing 'scene' field")
		quit(1)
		return
	print("render_artifact_config: id=%s scene=%s" % [cid, scene_path])

	# Build minimal scene
	var scene_root := Node3D.new()
	scene_root.name = "ArtifactRenderRoot"
	root.add_child(scene_root)

	# Environment
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	var bg: Array = cfg.get("background", [0.10, 0.10, 0.13])
	env.background_color = Color(float(bg[0]), float(bg[1]), float(bg[2]))
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.55, 0.6)
	env.ambient_light_energy = 0.7
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	scene_root.add_child(we)

	# Light
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-50, -45, 0)
	light.light_energy = 1.1
	scene_root.add_child(light)

	# Instantiate the artifact
	var packed: PackedScene = load(scene_path)
	if not packed:
		push_error("render_artifact_config: failed to load scene %s" % scene_path)
		quit(1)
		return
	var artifact: Node = packed.instantiate()
	scene_root.add_child(artifact)

	# Apply config params via apply_grid_config (Ada convention)
	if cfg.has("params") and artifact.has_method("apply_grid_config"):
		var p: Dictionary = cfg["params"]
		if p is Dictionary:
			artifact.call("apply_grid_config", p)

	# Wait so the artifact has a chance to build its own geometry in _ready.
	await create_timer(1.5).timeout
	await process_frame
	await process_frame

	# Compute artifact AABB for camera framing.
	var aabb: AABB = _compute_visual_aabb(artifact)
	var center: Vector3 = aabb.get_center()
	var size: float = max(aabb.size.x, max(aabb.size.y, aabb.size.z))
	if size < 0.1:
		size = 1.0  # fallback

	# Camera
	var camera := Camera3D.new()
	camera.current = true
	camera.fov = 45.0
	scene_root.add_child(camera)

	var angles: Array = [
		{"name": "front", "yaw": 0.4, "pitch": 0.35},
	]
	if _multi:
		angles = [
			{"name": "front", "yaw": 0.4, "pitch": 0.35},
			{"name": "left",  "yaw": 1.97, "pitch": 0.35},
			{"name": "right", "yaw": -1.17, "pitch": 0.35},
			{"name": "top",   "yaw": 0.001, "pitch": 1.45},
		]

	# Ensure output dir exists.
	var out_abs: String = ProjectSettings.globalize_path(_out_path)
	DirAccess.make_dir_recursive_absolute(out_abs.get_base_dir())

	for a in angles:
		var yaw: float = a["yaw"]
		var pitch: float = a["pitch"]
		var distance: float = size * 2.4
		var cam_pos := center + Vector3(
			cos(pitch) * sin(yaw) * distance,
			sin(pitch) * distance,
			cos(pitch) * cos(yaw) * distance,
		)
		camera.global_position = cam_pos
		camera.look_at(center, Vector3.UP)
		await create_timer(0.2).timeout
		await process_frame
		await process_frame
		var out_one: String = _out_path
		if _multi:
			# Replace the .png suffix with __<angle>.png
			out_one = _out_path.replace(".png", "__%s.png" % a["name"])
			DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_one).get_base_dir())
		var img: Image = root.get_viewport().get_texture().get_image()
		if not img:
			continue
		var err: int = img.save_png(out_one)
		if err != OK:
			push_error("save_png err=%d at %s" % [err, out_one])
		else:
			print("  -> %s" % out_one)

	quit(0)


func _compute_visual_aabb(node: Node) -> AABB:
	var combined := AABB()
	var first := true
	for child in node.find_children("*", "", true, false):
		if child is VisualInstance3D:
			var v: VisualInstance3D = child
			var local: AABB = v.get_aabb()
			# Transform to world space.
			var xf: Transform3D = v.global_transform
			var corners: Array[Vector3] = []
			for i in range(8):
				var p := local.position
				if (i & 1) != 0: p.x += local.size.x
				if (i & 2) != 0: p.y += local.size.y
				if (i & 4) != 0: p.z += local.size.z
				corners.append(xf * p)
			for c in corners:
				if first:
					combined = AABB(c, Vector3.ZERO)
					first = false
				else:
					combined = combined.expand(c)
	if first:
		# No VisualInstance3D found — fall back to a unit AABB at node's origin.
		var origin: Vector3 = (node as Node3D).global_position if node is Node3D else Vector3.ZERO
		return AABB(origin - Vector3.ONE, Vector3(2, 2, 2))
	return combined
