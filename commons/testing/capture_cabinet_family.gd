## capture_cabinet_family.gd
##
## ONE Godot boot → a front shot of every cabinet-family member. The slow part
## of improving these artifacts was one headless boot PER artifact (~12s each)
## plus a separate boot for the grammar probe. This shoots the whole canon in a
## single process, so the loop becomes: edit → one boot → read one contact
## sheet (tools/cabinet_bench.py tiles them) → repeat.
##
## Studio recipe matches the props-dna gallery rig so the shots read as a set.
##
## Run (via the watchdog):
##   python tools/godot_watchdog.py --expect=<dir> -- <godot> --path . \
##     --xr-mode off --no-window --script res://commons/testing/capture_cabinet_family.gd
##
## Writes: user://cabinet_family/<artifact>.png + _done.txt

extends SceneTree

const CANON := "res://commons/data/cabinet_grammar.json"
const OUT_DIR := "user://cabinet_family"
const RES := 900
const FOV := 34.0
const YAW := 0.62          # radians, three-quarter left
const PITCH := -0.26
const PAD := 1.9           # fit padding (bigger = more margin)
const SETTLE := 1.2        # let procedural _ready + physics settle


func _initialize() -> void:
	_run()


func _run() -> void:
	var canon: Dictionary = _load_json(CANON)
	var members: Array = canon.get("members", [])
	DirAccess.make_dir_recursive_absolute(OUT_DIR)

	var vp := SubViewport.new()
	vp.size = Vector2i(RES, RES)
	vp.transparent_bg = false
	vp.msaa_3d = Viewport.MSAA_8X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)

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
	cam.fov = FOV
	vp.add_child(cam)

	var shot := 0
	for m in members:
		var entry: Dictionary = m
		var scene_path: String = str(entry.get("scene", ""))
		var name: String = str(entry.get("artifact", "?"))
		if not ResourceLoader.exists(scene_path):
			print("MISS ", name, " (", scene_path, ")")
			continue
		var inst: Node = (load(scene_path) as PackedScene).instantiate()
		vp.add_child(inst)
		# procedural bodies build in _ready; settle physics artifacts too
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
		await create_timer(0.15).timeout
		var img := vp.get_texture().get_image()
		img.save_png("%s/%s.png" % [OUT_DIR, name])
		shot += 1
		print("SHOT ", name)
		inst.queue_free()
		await process_frame

	var f := FileAccess.open(OUT_DIR + "/_done.txt", FileAccess.WRITE)
	f.store_string("captured %d members\n" % shot)
	f.close()
	print("cabinet family: %d shots -> %s" % [shot, OUT_DIR])
	quit(0)


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
