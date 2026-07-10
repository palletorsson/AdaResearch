# capture_wrapper_fit.gd — the QA that matters: each wrapper WITH its artifact
# mounted, closeup. Not the map — the fit. Pairs come from the integration
# declarations (one representative instance per housed family). Output:
# ../ada_encyclopedia/public/wrapper-fit/<family>__<artifact>.png + manifest
# (GalleryView convention -> /wrapper-fit page, verdicts enabled).
#   godot --path . --xr-mode off --no-window --script res://commons/testing/capture_wrapper_fit.gd
extends SceneTree

const CubeLib := preload("res://commons/grid/CubeWrapperLibrary.gd")

const CAPTURE_SIZE: Vector2i = Vector2i(1024, 1024)
const BG_COLOR: Color = Color(0.055, 0.055, 0.070)
const CAMERA_FOV: float = 32.0
const CAMERA_YAW: float = 0.55
const CAMERA_PITCH: float = -0.30
const FRAME_PADDING: float = 1.9

# (family, artifact) pairs — representative instance per housed declaration.
# Known headless-hangers must NOT appear here (the CA runners class).
const PAIRS := [
	["frame", "grid2d_life"],
	["gridglass", "grid3d_bfs"],
	["shadowbox", "profile_sine"],
	["shadowbox", "example_8_4_cantor_set_vr"],
	["openframe", "example_8_6_recursive_tree_vr"],
	["pedestal", "galton_board"],
	["tank", "particle_fountain"],
	["cage", "random_walk_leash"],
	["podium", "living_paper_random_walk"],
	["table_display_1m", "ca_screen"],
	["table_display_1m", "albers_relief"],
	["table_display_2m", "buren_col_01_01"],
	["podium", "grab_sphere_E"],
	["plinth", "crystalcluster"],
	["podium", "living_paper_life"],
]

var _viewport: SubViewport
var _camera: Camera3D
var _holder: Node3D
var _entries: Array = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var out_dir := ProjectSettings.globalize_path("res://").path_join("../ada_encyclopedia/public/wrapper-fit")
	DirAccess.make_dir_recursive_absolute(out_dir)

	_viewport = SubViewport.new()
	_viewport.size = CAPTURE_SIZE
	_viewport.own_world_3d = true
	var iso_world := World3D.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = BG_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.65, 0.72)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.0
	env.tonemap_white = 1.15
	env.ssao_enabled = true
	env.ssao_intensity = 0.5
	env.glow_enabled = true
	env.glow_intensity = 0.40
	env.glow_bloom = 0.12
	iso_world.environment = env
	_viewport.world_3d = iso_world
	_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport.msaa_3d = Viewport.MSAA_8X
	_viewport.use_debanding = true
	get_root().add_child(_viewport)

	var key := DirectionalLight3D.new()
	key.light_energy = 1.25
	key.light_color = Color(1.0, 0.97, 0.92)
	key.rotation_degrees = Vector3(-35, 25, 0)
	key.shadow_enabled = true
	_viewport.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.light_energy = 0.45
	fill.light_color = Color(0.85, 0.90, 1.0)
	fill.rotation_degrees = Vector3(-15, -120, 0)
	_viewport.add_child(fill)
	var rim := DirectionalLight3D.new()
	rim.light_energy = 0.60
	rim.rotation_degrees = Vector3(-80, 180, 0)
	_viewport.add_child(rim)

	_camera = Camera3D.new()
	_camera.fov = CAMERA_FOV
	_camera.near = 0.02
	_camera.far = 80.0
	_camera.current = true
	_viewport.add_child(_camera)
	_holder = Node3D.new()
	_viewport.add_child(_holder)

	var lib := CubeLib.new()
	for pair in PAIRS:
		var fam: String = pair[0]
		var art: String = pair[1]
		var node: Node3D = lib.build(fam)
		_holder.add_child(node)
		var scene_path := _find_scene(art)
		var mounted := false
		if scene_path != "":
			var packed = load(scene_path)
			if packed != null:
				var inst = packed.instantiate()
				if inst is Node3D:
					node.add_child(inst)
					lib.fit_artifact(inst, fam, _load_metrics(art))
					mounted = true
		await create_timer(0.35).timeout

		var aabb: AABB = _combined_aabb(node)
		var center: Vector3 = aabb.position + aabb.size * 0.5
		var max_dim: float = max(aabb.size.x, max(aabb.size.y, aabb.size.z))
		# artifacts with stray far-flung nodes (labels, particles) inflate the
		# AABB — clamp so the WRAPPER stays the subject; overshoot is itself
		# a legible fit-finding in the frame
		max_dim = clampf(max_dim, 1.0, 4.0)
		var dist: float = max_dim * FRAME_PADDING + 0.5
		var offset := Vector3(
			sin(CAMERA_YAW) * cos(CAMERA_PITCH),
			-sin(CAMERA_PITCH),
			cos(CAMERA_YAW) * cos(CAMERA_PITCH)
		) * dist
		_camera.global_position = center + offset
		_camera.look_at(center, Vector3.UP)
		for i in 4:
			await process_frame
		var img: Image = _viewport.get_texture().get_image()
		var fname := fam + "__" + art + ".png"
		img.save_png(out_dir.path_join(fname))
		print("captured ", fname, mounted if true else "")
		_entries.append({"id": fam + "__" + art,
			"image": "/wrapper-fit/" + fname,
			"label": art, "subtitle": "in " + fam,
			"notes": ("mounted at " + str(lib.mount_point(fam))) if mounted else "MOUNT FAILED — scene not found",
			"prop": fam})
		for child in _holder.get_children():
			child.queue_free()
		await create_timer(0.05).timeout

	var manifest := {
		"version": 1,
		"description": "Wrapper fit — each housed family with a representative artifact mounted at its mount_point. The QA that matters: does the artifact sit right in its housing? Scale, pose, clearance. Verdict the misfits; fix the library or the declaration, not the room.",
		"entries": _entries,
	}
	var f := FileAccess.open(out_dir.path_join("manifest.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(manifest, "\t"))
	f.close()
	print("DONE — %d wrapper-fit pairs" % _entries.size())
	quit(0)


func _load_metrics(lookup: String) -> Dictionary:
	var f := FileAccess.open("res://commons/data/artifact_metrics.json", FileAccess.READ)
	if f == null:
		return {}
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if parsed is Dictionary:
		var mm = parsed.get("metrics", {})
		if mm is Dictionary and mm.has(lookup):
			return mm[lookup]
	return {}


func _find_scene(lookup: String) -> String:
	var dir := DirAccess.open("res://commons/artifacts/registry/")
	if dir == null:
		return ""
	dir.list_dir_begin()
	var f := dir.get_next()
	while f != "":
		if f.ends_with(".json"):
			var file := FileAccess.open("res://commons/artifacts/registry/" + f, FileAccess.READ)
			if file:
				var parsed = JSON.parse_string(file.get_as_text())
				if parsed is Dictionary and parsed.get("artifacts", {}).has(lookup):
					return str(parsed["artifacts"][lookup].get("scene", ""))
		f = dir.get_next()
	return ""


func _combined_aabb(node: Node3D) -> AABB:
	var aabb := AABB()
	var first := true
	var stack: Array = [node]
	while not stack.is_empty():
		var cur = stack.pop_back()
		if cur is VisualInstance3D:
			var a: AABB = cur.global_transform * cur.get_aabb()
			if first:
				aabb = a
				first = false
			else:
				aabb = aabb.merge(a)
		for child in cur.get_children():
			stack.append(child)
	return aabb
