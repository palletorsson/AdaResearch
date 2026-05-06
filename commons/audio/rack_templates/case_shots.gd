extends Node3D

## Renders one case at a time for blog screenshots.
## Launch with: --script-arg=wall|desktop|studio|rack|shelf|wall_fitted|pedestal

const RackTpl = preload("res://commons/audio/rack_templates/RackTemplates.gd")

var _shot_index := 0
var _shots := []
var _timer := 0.0

func _ready():
	# Environment
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.72, 0.70, 0.66)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(1, 1, 1)
	env.ambient_light_energy = 3.5
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	var light := DirectionalLight3D.new()
	light.light_energy = 2.5
	light.shadow_enabled = true
	light.transform = Transform3D.IDENTITY.looking_at(Vector3(-0.3, -0.5, -1), Vector3.UP)
	light.transform.origin = Vector3(0, 3, 2)
	add_child(light)

	var fill := DirectionalLight3D.new()
	fill.light_energy = 0.8
	fill.transform = Transform3D.IDENTITY.looking_at(Vector3(0.5, -0.2, 1), Vector3.UP)
	fill.transform.origin = Vector3(-1, 1, -1)
	add_child(fill)

	# Camera
	var cam := Camera3D.new()
	cam.name = "ShotCamera"
	cam.fov = 35
	cam.current = true
	add_child(cam)

	# Define all shots
	_shots = [
		{"name": "case-wall", "builder": "_build_wall_shot", "cam_pos": Vector3(0.12, 0.08, 0.4), "cam_target": Vector3(0, 0.04, 0)},
		{"name": "case-desktop", "builder": "_build_desktop_shot", "cam_pos": Vector3(0.15, 0.12, 0.35), "cam_target": Vector3(0, 0.05, -0.04)},
		{"name": "case-studio", "builder": "_build_studio_shot", "cam_pos": Vector3(0.15, 0.14, 0.38), "cam_target": Vector3(0, 0.06, -0.05)},
		{"name": "case-rack", "builder": "_build_rack_shot", "cam_pos": Vector3(0.12, 0.08, 0.4), "cam_target": Vector3(0, 0.04, 0)},
		{"name": "grid-shelf", "builder": "_build_shelf_fitted", "cam_pos": Vector3(0.18, 0.18, 0.5), "cam_target": Vector3(0, 0.1, -0.05)},
		{"name": "grid-wall", "builder": "_build_wall_fitted", "cam_pos": Vector3(0.15, 0.3, 0.45), "cam_target": Vector3(0, 0.25, 0)},
		{"name": "grid-pedestal", "builder": "_build_pedestal_fitted", "cam_pos": Vector3(0.2, 0.2, 0.55), "cam_target": Vector3(0, 0.15, -0.05)},
	]

	_show_shot(0)
	_shot_index = 0
	_timer = 0.0


func _show_shot(idx: int) -> void:
	# Clear previous
	for child in get_children():
		if child.name.begins_with("Shot_"):
			child.queue_free()

	if idx >= _shots.size():
		print("CaseShots: All %d shots ready" % _shots.size())
		return

	var shot = _shots[idx]
	var container := Node3D.new()
	container.name = "Shot_%s" % shot["name"]
	add_child(container)

	call(shot["builder"], container)

	var cam: Camera3D = get_node("ShotCamera")
	cam.transform.origin = shot["cam_pos"]
	cam.look_at(shot["cam_target"], Vector3.UP)

	print("CaseShots: Showing %s (%d/%d)" % [shot["name"], idx + 1, _shots.size()])


func _process(delta: float) -> void:
	_timer += delta
	# Every 1 second: save current, advance to next
	if _timer > 1.0 and _shot_index < _shots.size():
		_save_screenshot()
		_shot_index += 1
		if _shot_index < _shots.size():
			_show_shot(_shot_index)
		else:
			_copy_to_blog()
			print("CaseShots: ALL DONE - %d shots saved" % _shots.size())
		_timer = 0.0


func _copy_to_blog() -> void:
	var user_dir: String = OS.get_user_data_dir() + "/case_shots/"
	var blog_dir: String = ProjectSettings.globalize_path("res://").get_base_dir() + "/ada_encyclopedia/public/blog/"
	for shot in _shots:
		var src: String = user_dir + str(shot["name"]) + ".png"
		var dst: String = blog_dir + "2026-04-14-" + str(shot["name"]) + ".png"
		var err: int = DirAccess.copy_absolute(src, dst)
		if err == OK:
			print("CaseShots: Copied %s -> %s" % [shot["name"], dst])
		else:
			print("CaseShots: FAILED to copy %s (err=%d)" % [shot["name"], err])


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE or event.keycode == KEY_RIGHT:
			_shot_index = (_shot_index + 1) % _shots.size()
			_show_shot(_shot_index)
		elif event.keycode == KEY_LEFT:
			_shot_index = (_shot_index - 1 + _shots.size()) % _shots.size()
			_show_shot(_shot_index)
		elif event.keycode == KEY_S:
			_save_screenshot()


func _save_screenshot() -> void:
	var shot = _shots[_shot_index]
	var img := get_viewport().get_texture().get_image()
	var path := "user://case_shots/%s.png" % shot["name"]
	DirAccess.make_dir_recursive_absolute("user://case_shots")
	img.save_png(path)
	print("CaseShots: Saved %s" % path)


# ── Individual case builders ─────────────────────────────────────────

func _build_wall_shot(parent: Node3D) -> void:
	var panel := RackTpl.create_panel("WALL SYNTH", [
		[{"type": "knob", "label": "OSC"}, {"type": "knob", "label": "FILT"}, {"type": "knob", "label": "RES"}],
		[{"type": "slider_h", "label": "CUTOFF", "default": 0.6}],
	])
	var cased := RackTpl.create_case("wall", panel)
	parent.add_child(cased)


func _build_desktop_shot(parent: Node3D) -> void:
	var panel := RackTpl.create_panel("DESK CTRL", [
		[{"type": "slider_h", "label": "FREQ", "default": 0.5}, {"type": "slider_h", "label": "AMP", "default": 0.7}],
		[{"type": "button", "label": "PLAY"}, {"type": "button", "label": "STOP"}],
	])
	var cased := RackTpl.create_case("desktop", panel)
	parent.add_child(cased)


func _build_studio_shot(parent: Node3D) -> void:
	var panel := RackTpl.create_panel("STUDIO MIX", [
		[{"type": "histogram", "label": "LEVELS"}],
		[{"type": "slider_v", "label": "CH1"}, {"type": "slider_v", "label": "CH2"}, {"type": "slider_v", "label": "MAIN"}],
	])
	var cased := RackTpl.create_case("studio", panel)
	parent.add_child(cased)


func _build_rack_shot(parent: Node3D) -> void:
	var panel := RackTpl.create_panel("RACK UNIT", [
		[{"type": "gauge", "label": "LEVEL"}, {"type": "knob", "label": "GAIN"}, {"type": "knob", "label": "PAN"}, {"type": "button", "label": "BYPASS"}],
	])
	var cased := RackTpl.create_case("rack", panel)
	parent.add_child(cased)


func _build_shelf_fitted(parent: Node3D) -> void:
	var panel := RackTpl.create_panel("SHELF SYNTH", [
		[{"type": "slider_h", "label": "FREQ", "default": 0.5}, {"type": "slider_h", "label": "RES", "default": 0.3}],
		[{"type": "button", "label": "PLAY"}, {"type": "button", "label": "RST"}],
	])
	var cased := RackTpl.create_fitted_case(RackTpl.shelf_slot(), panel)
	parent.add_child(cased)


func _build_wall_fitted(parent: Node3D) -> void:
	var panel := RackTpl.create_panel("WALL DISPLAY", [
		[{"type": "histogram", "label": "DATA"}],
		[{"type": "slider_h", "label": "RANGE", "default": 0.6}],
	])
	var cased := RackTpl.create_fitted_case(RackTpl.wall_slot(), panel)
	parent.add_child(cased)


func _build_pedestal_fitted(parent: Node3D) -> void:
	var panel := RackTpl.create_panel("FLOOR LAB", [
		[{"type": "monitor", "label": "SCOPE", "mode": "scope"}],
		[{"type": "knob", "label": "GAIN"}, {"type": "knob", "label": "FREQ"}],
		[{"type": "button", "label": "RESET"}],
	])
	var cased := RackTpl.create_fitted_case(RackTpl.floor_pedestal_slot(), panel)
	parent.add_child(cased)
