## capture_config_sweep.gd — the DNA-sweep capturer: ONE Godot boot renders
## every parameter variant of one artifact, no code edits between variants.
##
## This is the props-dna-gallery loop generalised: vary an artifact by DATA
## (its @export knobs), batch-render the whole matrix, compare on a sheet.
## Each variant's params are set BEFORE add_child, so _ready() builds the body
## with them — no apply_grid_config rebuild needed, and one boot does them all.
##
## Reads a sweep spec JSON:
##   { "scene": "res://.../x.tscn",
##     "out_dir": "res://ada_run/sweep",
##     "variants": [ { "label": "rams_p0", "params": {"finish":"rams","plinth_height":0.0} }, ... ] }
##
## Run (via the watchdog, expecting <out_dir>/_done.txt):
##   godot --path . --xr-mode off --no-window \
##     --script res://commons/testing/capture_config_sweep.gd -- --spec=<abs/res path>

extends SceneTree

const RES := 760
const FOV := 34.0
const YAW := 0.62
const PITCH := -0.26
const PAD := 1.9
const SETTLE := 1.1

var _spec_path: String = ""


func _initialize() -> void:
	for raw in OS.get_cmdline_user_args():
		var a := String(raw).strip_edges()
		if a.begins_with("--spec="):
			_spec_path = a.substr(7)
	_run()


func _run() -> void:
	var spec: Dictionary = _load_json(_spec_path)
	var scene_path: String = str(spec.get("scene", ""))
	var out_dir: String = str(spec.get("out_dir", "res://ada_run/sweep"))
	var variants: Array = spec.get("variants", [])
	if not ResourceLoader.exists(scene_path):
		push_error("capture_config_sweep: scene missing: " + scene_path)
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(out_dir)

	var vp := SubViewport.new()
	vp.size = Vector2i(RES, RES)
	vp.msaa_3d = Viewport.MSAA_8X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	_stage(vp)
	var cam: Camera3D = vp.get_node("Cam")

	var packed_cache: Dictionary = {}   # scene path -> PackedScene (multi-scene sweeps)
	var shot := 0
	for v in variants:
		var variant: Dictionary = v
		var label: String = str(variant.get("label", "v%d" % shot))
		var params: Dictionary = variant.get("params", {})
		# a variant may name its own scene (cross-member sweeps); else the top one
		var vscene: String = str(variant.get("scene", scene_path))
		if not packed_cache.has(vscene):
			if not ResourceLoader.exists(vscene):
				print("MISS ", label, " (", vscene, ")")
				continue
			packed_cache[vscene] = load(vscene)
		var packed: PackedScene = packed_cache[vscene]

		var inst: Node = packed.instantiate()
		# Set every swept @export BEFORE add_child, so _ready() builds with it.
		for key in params.keys():
			var val: Variant = params[key]
			if key in inst:
				inst.set(key, val)
		vp.add_child(inst)
		await create_timer(SETTLE).timeout

		var aabb := _subtree_aabb(inst)
		var c := aabb.get_center()
		var radius: float = maxf(aabb.size.length() * 0.5, 0.2)
		var dist: float = radius / tan(deg_to_rad(FOV * 0.5)) * PAD
		var dir := Vector3(sin(YAW) * cos(PITCH), -sin(PITCH), cos(YAW) * cos(PITCH))
		cam.global_position = c + dir * dist
		cam.look_at(c, Vector3.UP)

		await process_frame
		await process_frame
		await create_timer(0.1).timeout
		vp.get_texture().get_image().save_png("%s/%s.png" % [out_dir, label])
		shot += 1
		print("SWEPT ", label)
		inst.queue_free()
		await process_frame

	var f := FileAccess.open(out_dir + "/_done.txt", FileAccess.WRITE)
	f.store_string("swept %d variants" % shot)
	f.close()
	print("config sweep: %d variants -> %s" % [shot, out_dir])
	quit(0)


func _stage(vp: SubViewport) -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.055, 0.055, 0.070)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.65, 0.72)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	vp.add_child(we)
	var key := DirectionalLight3D.new()
	key.light_energy = 1.25
	key.rotation_degrees = Vector3(-42, -35, 0)
	key.shadow_enabled = true
	vp.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.light_energy = 0.45
	fill.rotation_degrees = Vector3(-20, 130, 0)
	vp.add_child(fill)
	var cam := Camera3D.new()
	cam.name = "Cam"
	cam.fov = FOV
	vp.add_child(cam)


func _subtree_aabb(root_node: Node) -> AABB:
	var acc := AABB()
	var have := false
	var stack: Array = [root_node]
	while not stack.is_empty():
		var n = stack.pop_back()
		if n is MeshInstance3D:
			var mi := n as MeshInstance3D
			var wab: AABB = mi.global_transform * mi.get_aabb()
			acc = wab if not have else acc.merge(wab)
			have = true
		for ch in n.get_children():
			stack.append(ch)
	return acc if have else AABB(Vector3(-0.5, 0, -0.5), Vector3.ONE)


func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	return parsed if parsed is Dictionary else {}
