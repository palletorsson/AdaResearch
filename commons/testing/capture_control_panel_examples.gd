extends SceneTree
## Capture the canonical ControlPanel LAYOUT LIBRARY — a reference set of Dieter-
## Rams-styled panels (one button, one slider, two sliders + a button, …) so the
## box-model layout can be eye-checked and reused. Each is built, framed on its
## own AABB, captured. Real XR controls (runtime-loaded so autoloads are up).
##   godot --xr-mode off --no-window --script res://commons/testing/capture_control_panel_examples.gd -- --out=user://cp_examples

const ControlPanelScript = preload("res://commons/ui/control_panel.gd")

# Each example: id + the controls to add (kept declarative so it reads as a spec).
const EXAMPLES := [
	{"id": "1_button",            "title": ""},
	{"id": "1_slider",            "title": ""},
	{"id": "2_sliders",           "title": ""},
	{"id": "2_sliders_1_button",  "title": ""},
	{"id": "3_sliders_2_buttons", "title": "MIXER"},
	{"id": "with_text_display",   "title": "READOUT"},
	{"id": "with_joystick",       "title": "AIM"},
	{"id": "with_screen",         "title": "PANEL"},
]

var _out := "user://cp_examples"
var _root: Node3D
var _cam: Camera3D
var _i := 0


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("--out="):
			_out = String(a).split("=", true, 1)[1]
	_root = Node3D.new()
	get_root().add_child(_root)

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.40, 0.41, 0.44)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.72, 0.73, 0.76)
	env.ambient_light_energy = 1.0
	var we := WorldEnvironment.new(); we.environment = env
	_root.add_child(we)
	for rot in [Vector3(-45, 30, 0), Vector3(-30, -45, 0)]:
		var l := DirectionalLight3D.new()
		l.rotation_degrees = rot
		l.light_energy = 1.0 if rot.y == 30 else 0.5
		_root.add_child(l)

	_cam = Camera3D.new()
	_cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	_root.add_child(_cam)
	_cam.current = true
	_run()


func _build(example: Dictionary) -> Node3D:
	var p = ControlPanelScript.new()
	p.title = example["title"]
	_root.add_child(p)
	match example["id"]:
		"1_button":
			p.add_button("GO")
		"1_slider":
			p.add_slider("LEVEL")
		"2_sliders":
			p.add_slider("X"); p.add_slider("Y")
		"2_sliders_1_button":
			p.add_slider("GAIN"); p.add_slider("MIX"); p.add_button("SET")
		"3_sliders_2_buttons":
			p.add_slider("R"); p.add_slider("G"); p.add_slider("B")
			p.add_button("SAVE"); p.add_button("CLEAR")
		"with_text_display":
			p.add_slider("FREQ"); p.add_slider("AMP")
			var r = p.add_readout("440 Hz\nA = 0.50")
		"with_joystick":
			p.add_joystick("PAN"); p.add_slider("ZOOM")
		"with_screen":
			p.add_slider("CH"); p.add_button("SEND")
			p.add_screen("OUT", "OK")
	return p


func _run() -> void:
	await process_frame
	await create_timer(0.4).timeout
	var out_abs := ProjectSettings.globalize_path(_out)
	DirAccess.make_dir_recursive_absolute(out_abs)
	for example in EXAMPLES:
		var panel := _build(example)
		await process_frame
		await create_timer(0.5).timeout
		await process_frame
		# Frame the camera on this panel's AABB.
		var box := _aabb(panel)
		var focus := box.get_center()
		var diag: float = box.size.length()
		_cam.size = maxf(0.5, diag * 0.95)
		_cam.position = focus + Vector3(0.25, 0.18, 1.4)
		_cam.look_at(focus, Vector3.UP)
		await process_frame
		await create_timer(0.2).timeout
		await process_frame
		var img := get_root().get_viewport().get_texture().get_image()
		if img:
			img.save_png(out_abs.path_join("%s.png" % example["id"]))
		_root.remove_child(panel)
		panel.free()
		await process_frame
	print("capture_control_panel_examples: %d saved to %s" % [EXAMPLES.size(), out_abs])
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
