extends SceneTree
## capture_time_strip.gd — the temporal probe. A sibling of capture_config_sweep.gd
## where the swept axis is TIME.
##
## The whole stage-2 loop produces stills, and a still cannot hold a rate. info_board
## exposed this first: all five of its exports are durations, so sweeping them yielded
## six identical tiles that looked like a finished experiment and answered nothing. The
## sweep was told to sort time-domain axes last and report `time_domain_only` rather
## than pretend — an honest dead end, but still a dead end.
##
## This is the way out. One artifact, held still, photographed at N moments across a
## window. Anything whose argument is a rate, a decay, an accumulation or a LAG becomes
## evaluable the way a spatial axis already is: as a row you can look along.
##
## The camera is framed ONCE, from the AABB at t=0, and never moves again. That is the
## point — if the camera re-framed per shot, motion in the subject would be cancelled by
## motion in the observer and the strip would be flat for the wrong reason.
##
## Run (via the watchdog, expecting <out_dir>/_done.txt):
##   godot --path . --xr-mode off --no-window --script res://commons/testing/capture_time_strip.gd \
##       -- --spec=res://ada_run/time_strip_spec.json

# EXACTLY the sweep rig's camera (capture_config_sweep.gd). Not approximately: a time
# strip and a parameter sweep of the same artifact have to be readable side by side,
# and they cannot be if one shows the front and the other the back. The first version
# of this probe used yaw 180 and photographed galton_board from behind for ten seconds.
const RES := 900
const FOV := 34.0
const YAW := 0.62
const PITCH := -0.26
const PAD := 1.9
const SETTLE := 0.35

var _spec_path: String = "res://ada_run/time_strip_spec.json"


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--spec="):
			_spec_path = a.split("=", 1)[1]
	_run()


func _run() -> void:
	var spec: Dictionary = _load_json(_spec_path)
	var scene_path: String = str(spec.get("scene", ""))
	var out_dir: String = str(spec.get("out_dir", "res://ada_run/time_strip"))
	var params: Dictionary = spec.get("params", {})
	var frames: int = int(spec.get("frames", 6))
	var window: float = float(spec.get("window_s", 6.0))
	var label: String = str(spec.get("label", "t"))
	if not ResourceLoader.exists(scene_path):
		push_error("capture_time_strip: scene missing: " + scene_path)
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

	var inst: Node = (load(scene_path) as PackedScene).instantiate()
	for key in params.keys():
		if key in inst:
			inst.set(key, params[key])
	vp.add_child(inst)
	await create_timer(SETTLE).timeout

	# FRAME ONCE. A camera that re-frames per shot cancels the subject's own motion.
	var aabb := _subtree_aabb(inst)
	var c := aabb.get_center()
	var radius: float = maxf(aabb.size.length() * 0.5, 0.2)
	var dist: float = radius / tan(deg_to_rad(FOV * 0.5)) * PAD
	var dir := Vector3(sin(YAW) * cos(PITCH), -sin(PITCH), cos(YAW) * cos(PITCH))
	cam.global_position = c + dir * dist
	cam.look_at(c, Vector3.UP)

	var step: float = window / float(maxi(frames - 1, 1))
	var shot := 0
	for i in range(frames):
		if i > 0:
			# let the artifact RUN. _process keeps ticking because the subviewport is
			# in the tree; the probe simply waits and then looks.
			await create_timer(step).timeout
		await process_frame
		await process_frame
		var t: float = step * float(i)
		vp.get_texture().get_image().save_png(
			"%s/%s__t-%05.2f.png" % [out_dir, label, t])
		shot += 1
		print("STRIP %s t=%.2f" % [label, t])

	inst.queue_free()
	await process_frame
	var f := FileAccess.open(out_dir + "/_done.txt", FileAccess.WRITE)
	f.store_string("strip %d frames over %.2fs" % [shot, window])
	f.close()
	print("time strip: %d frames -> %s" % [shot, out_dir])
	quit()


func _stage(vp: SubViewport) -> void:
	var cam := Camera3D.new()
	cam.name = "Cam"
	cam.fov = FOV
	vp.add_child(cam)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-42, 148, 0)
	key.light_energy = 1.5
	vp.add_child(key)
	var fill := OmniLight3D.new()
	fill.position = Vector3(1.4, 2.0, 1.6)
	fill.light_energy = 1.1
	fill.omni_range = 12.0
	vp.add_child(fill)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.55, 0.62, 0.55)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.62, 0.66, 0.62)
	e.ambient_light_energy = 0.85
	env.environment = e
	vp.add_child(env)


func _subtree_aabb(root_node: Node) -> AABB:
	var out := AABB()
	var have := false
	var stack: Array = [root_node]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is MeshInstance3D:
			var mi: MeshInstance3D = n
			var wab: AABB = mi.global_transform * mi.get_aabb()
			if have:
				out = out.merge(wab)
			else:
				out = wab
				have = true
		for c in n.get_children():
			stack.append(c)
	return out if have else AABB(Vector3.ZERO, Vector3.ONE)


func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	var j := JSON.new()
	if j.parse(f.get_as_text()) != OK:
		return {}
	return j.data if typeof(j.data) == TYPE_DICTIONARY else {}
