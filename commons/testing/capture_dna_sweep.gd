extends SceneTree
## DNA triptych capture — load an artifact, sweep ONE critical parameter through
## a list of values via apply_grid_config, capture each with a FIXED camera so
## only the artifact changes across the strip.
##   godot --xr-mode off --no-window --script res://commons/testing/capture_dna_sweep.gd -- \
##     --scene=res://commons/artifacts/stretch_bench/stretch_bench.tscn \
##     --param=k --values=-1,0,1 --out=user://dna/stretch_bench
## Output: <out>/<param>_<value>.png per value.

var _scene_path := ""
var _param := "k"
var _values: Array = []
var _out := "user://dna_sweep"
var _w := 700
var _h := 700
## Multiplier on the just-fits distance. 1.0 = the subject exactly fills the
## frame; larger backs off. Passed as --framing= so an artifact whose axis lives
## in fine detail can be shot tight, and one that needs its surroundings can be
## shot loose, without changing the artifact.
var _framing := 1.12


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		var eq := String(arg).find("=")
		if eq < 0: continue
		var key := String(arg).substr(0, eq).lstrip("-")
		var val := String(arg).substr(eq + 1)
		match key:
			"scene": _scene_path = val
			"param": _param = val
			"out": _out = val
			"framing":
				var f: float = float(val)
				if f > 0.05:
					_framing = f
			"values":
				for v in val.split(","):
					_values.append(float(v))
	if _scene_path == "" or _values.is_empty():
		push_error("capture_dna_sweep: --scene and --values are required")
		quit(1); return
	_run()


func _run() -> void:
	var packed: PackedScene = ResourceLoader.load(_scene_path)
	if packed == null:
		push_error("capture_dna_sweep: cannot load %s" % _scene_path)
		quit(1); return

	root.size = Vector2i(_w, _h)
	var scene_root := Node3D.new()
	root.add_child(scene_root)

	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.55, 0.62, 0.45)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.65, 0.67, 0.70)
	e.ambient_light_energy = 1.4
	env.environment = e
	scene_root.add_child(env)
	for rot in [Vector3(-40, 30, 0), Vector3(-30, -45, 0), Vector3(20, 180, 0)]:
		var l := DirectionalLight3D.new()
		l.rotation_degrees = rot
		l.light_energy = 1.2 if rot.y == 30 else 0.55
		scene_root.add_child(l)

	var cam := Camera3D.new()
	cam.fov = 45.0
	scene_root.add_child(cam)
	cam.current = true

	var artifact: Node = packed.instantiate()
	scene_root.add_child(artifact)
	for c in _all(artifact):
		if c is Camera3D: (c as Camera3D).current = false
	cam.current = true

	await process_frame
	await process_frame
	await create_timer(1.0).timeout

	# Frame ONCE on the artifact at its widest (sweep then settle), camera fixed.
	if artifact.has_method("apply_grid_config"):
		artifact.call("apply_grid_config", {_param: _values.max()})
	await process_frame
	var box := _aabb(artifact)
	var focus := box.get_center()

	# Fit the BOUNDING SPHERE, not the widest axis. max_dim * 1.5 is an
	# orthographic assumption and it under-frames small apparatus badly: the
	# line_interface sweep put a 30-pixel subject in a 700-pixel frame, so all
	# four values of an axis about LEGIBILITY were themselves illegible and the
	# sheet could not be told apart from an inert axis. A degenerate AABB used
	# to fall back to a flat 1.0 m, which is how that happened — an artifact
	# that builds its geometry deferred measures as nothing on the first frame.
	var radius: float = box.size.length() * 0.5
	var half_fov: float = deg_to_rad(cam.fov) * 0.5
	var dist: float = 0.0
	if radius > 0.0001:
		dist = (radius / max(0.05, sin(half_fov))) * _framing
	else:
		# Nothing measurable. Say so rather than guessing a metre and shipping a
		# sheet of specks that reads as a verdict.
		push_warning("capture_dna_sweep: AABB is degenerate for %s — the subject may "
			+ "build deferred; framing at a close default instead of measuring." % _scene_path)
		dist = 0.6 * _framing
	cam.global_position = focus + Vector3(sin(0.0), sin(0.1), cos(0.0)) * dist + Vector3(0, dist * 0.15, 0)
	cam.look_at(focus, Vector3.UP)
	print("capture_dna_sweep: aabb=%s radius=%.3f dist=%.3f (framing x%.2f)" % [
		box.size, radius, dist, _framing])

	var out_abs := ProjectSettings.globalize_path(_out)
	DirAccess.make_dir_recursive_absolute(out_abs)
	var saved := 0
	for v in _values:
		if artifact.has_method("apply_grid_config"):
			artifact.call("apply_grid_config", {_param: v})
		await process_frame
		await create_timer(0.5).timeout
		await process_frame
		var img := root.get_texture().get_image()
		if img:
			var tag := String.num(v, 2).replace("-", "neg").replace(".", "p")
			var path := out_abs.path_join("%s_%s.png" % [_param, tag])
			if img.save_png(path) == OK: saved += 1
	print("capture_dna_sweep: %d/%d saved to %s" % [saved, _values.size(), out_abs])
	quit(0)


func _aabb(node: Node) -> AABB:
	var box := AABB(); var first := true
	for n in _all(node):
		if n is VisualInstance3D:
			var ab: AABB = (n as VisualInstance3D).get_aabb()
			ab = (n as Node3D).global_transform * ab
			if first: box = ab; first = false
			else: box = box.merge(ab)
	return box


func _all(node: Node) -> Array:
	var out := [node]
	for c in node.get_children(): out.append_array(_all(c))
	return out
