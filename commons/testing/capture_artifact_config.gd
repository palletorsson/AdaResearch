extends SceneTree

## Capture ONE artifact scene rendered with an optional DNA config, to a PNG.
## Reusable across auto-research galleries (crates/boxes, etc.).
##   godot --path . --xr-mode off --no-window \
##     --script res://commons/testing/capture_artifact_config.gd -- \
##     --scene=res://commons/artifacts/crate/crate.tscn \
##     --config=<abs-or-res path to entry .json> --out=<png> [--size=1024]
##
## The config file may be the DNA dict directly, or an entry object with a
## "dna" sub-dict (and optionally a "scene" key that overrides --scene).

var _scene_path: String = ""
var _config_path: String = ""
var _out_path: String = ""
var _size: int = 1024


func _initialize() -> void:
	for raw in OS.get_cmdline_user_args():
		var arg := String(raw).strip_edges()
		if arg.begins_with("--scene="):
			_scene_path = arg.substr(8)
		elif arg.begins_with("--config="):
			_config_path = arg.substr(9)
		elif arg.begins_with("--out="):
			_out_path = arg.substr(6)
		elif arg.begins_with("--size="):
			var v := arg.substr(7)
			if v.is_valid_int():
				_size = clampi(int(v), 256, 2048)
	if _out_path.is_empty():
		push_error("capture_artifact_config: --out is required")
		quit(1)
		return
	_run.call_deferred()


func _load_entry() -> Dictionary:
	if _config_path.is_empty():
		return {}
	var path := _config_path
	if path.begins_with("res://"):
		path = ProjectSettings.globalize_path(path)
	var f := FileAccess.open(path, FileAccess.READ)
	if not f:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	return parsed if parsed is Dictionary else {}


func _run() -> void:
	var entry := _load_entry()
	var dna: Dictionary = {}
	if entry.has("dna") and entry["dna"] is Dictionary:
		dna = entry["dna"]
	elif not entry.has("scene"):
		dna = entry            # the file IS the DNA dict
	if entry.has("scene") and String(entry["scene"]) != "":
		_scene_path = String(entry["scene"])
	if _scene_path.is_empty():
		push_error("capture_artifact_config: no --scene and none in config")
		quit(1)
		return

	root.content_scale_size = Vector2i(_size, _size)
	root.size = Vector2i(_size, _size)

	var scene := Node3D.new()
	scene.name = "ArtifactCapture"
	root.add_child(scene)

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.10, 0.11, 0.14)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.60, 0.62, 0.66)
	env.ambient_light_energy = 0.9
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	scene.add_child(we)

	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-46, -38, 0)
	key.light_energy = 1.35
	key.shadow_enabled = true
	scene.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-14, 132, 0)
	fill.light_energy = 0.4
	scene.add_child(fill)

	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(24, 24)
	ground.mesh = plane
	var gmat := StandardMaterial3D.new()
	gmat.albedo_color = Color(0.13, 0.14, 0.16)
	gmat.roughness = 0.95
	ground.material_override = gmat
	scene.add_child(ground)

	var art: Node = load(_scene_path).instantiate()
	scene.add_child(art)
	if not dna.is_empty() and art.has_method("apply_grid_config"):
		art.apply_grid_config(dna)

	await process_frame
	await process_frame
	await process_frame
	await process_frame

	var aabb := _combined_aabb(art)
	var focus := aabb.get_center()
	ground.position.y = aabb.position.y - 0.02
	var w := maxf(aabb.size.x, 0.4)
	var h := maxf(aabb.size.y, 0.4)
	var dp := maxf(aabb.size.z, 0.4)
	var max_dim := maxf(w, maxf(h, dp))

	var camera := Camera3D.new()
	camera.current = true
	camera.fov = 36.0
	scene.add_child(camera)
	var dist := max_dim * 1.5 + 0.8
	camera.global_position = focus + Vector3(dist * 0.62, h * 0.45 + max_dim * 0.42, dist)
	camera.look_at(focus, Vector3.UP)

	await process_frame
	await process_frame

	var image := root.get_texture().get_image()
	if image == null:
		push_error("capture_artifact_config: no image")
		quit(1)
		return
	var abs_out := _out_path
	if abs_out.begins_with("user://") or abs_out.begins_with("res://"):
		abs_out = ProjectSettings.globalize_path(abs_out)
	DirAccess.make_dir_recursive_absolute(abs_out.get_base_dir())
	var err := image.save_png(abs_out)
	if err != OK:
		push_error("capture_artifact_config: save failed %d" % err)
		quit(1)
		return
	print("capture_artifact_config: saved %s" % abs_out)
	quit(0)


func _combined_aabb(node: Node) -> AABB:
	var total := AABB()
	var first := true
	var stack: Array = [node]
	while not stack.is_empty():
		var current = stack.pop_back()
		if current is MeshInstance3D and current.mesh:
			var a: AABB = current.global_transform * current.get_aabb()
			if first:
				total = a
				first = false
			else:
				total = total.merge(a)
		for child in current.get_children():
			stack.append(child)
	if first:
		return AABB(Vector3(-0.5, 0, -0.5), Vector3(1, 1, 1))
	return total
