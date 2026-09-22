extends "res://commons/artifacts/timing_machines/machine_stage.gd"
## Six full-sized touch targets on the compact transparent desk from Recursion.
var kind := "growth"
var source: Node3D
var show_rule := false
func _ready() -> void:
	source = get_parent()
	scale = Vector3.ONE / source.scale
	_build_compact_console(["GROW", "ANGLE", "LENGTH", "FORKS", "RESET", "RULE"] if kind == "growth" else ["FORM", "STRATA", "REACH", "ENDS", "RESET", "RULE"], "01 / WHERE WILL IT GO?" if kind == "growth" else "02 / FIND THE LAST CALL")
	box(Vector3(0,0.007,0),Vector3(6.2,0.014,4.2),material("20343e"))
	var lamp := OmniLight3D.new()
	lamp.position = Vector3(0,3,1)
	lamp.light_energy = 1.3
	lamp.omni_range = 7
	add_child(lamp)
	begin()
	_use_hall_light.call_deferred()

func _use_hall_light() -> void:
	var hall: Node = source
	while hall != null and not hall.has_meta("em_map"): hall = hall.get_parent()
	if hall == null or str(hall.get_meta("em_map")) != "Fractal_RecursiveTrees": return
	for lamp in hall.find_children("*", "DirectionalLight3D", true, false): lamp.hide()
	if kind == "growth" and not hall.has_node("TreeHallLights"):
		var lights := Node3D.new()
		lights.name = "TreeHallLights"
		hall.add_child(lights)
		for z in [14.0,24.0]:
			var lamp := OmniLight3D.new()
			lamp.position = Vector3(8.5,5,z)
			lamp.light_color = Color("f3e6d6")
			lamp.light_energy = 2.4
			lamp.omni_range = 12
			lights.add_child(lamp)

func begin() -> void:
	show_rule = false
	if kind == "growth":
		source.auto_start = false
		source.max_depth = 4
		source.branch_count = 2
		source.initial_branch_length = 1.4
		source.initial_branch_thickness = 0.11
		source.length_reduction = 0.7
		source.branch_angle_min = 35
		source.branch_angle_max = 35
		source.add_randomness = false
		source.reset()
	else:
		source.apply_grid_config({"aftermath":"form"})
	refresh()

func act(id: String) -> void:
	if id == "RESET": begin(); return
	if id == "RULE": show_rule = not show_rule
	else:
		show_rule = false
		if kind == "growth":
			var level: int = mini(source.current_depth, 4)
			match id:
				"GROW":
					if level < 4: source.grow_generation()
				"ANGLE":
					var values := [15.0,35.0,65.0]
					source.branch_angle_min = values[(values.find(float(source.branch_angle_min))+1)%3]
					source.branch_angle_max = source.branch_angle_min
				"LENGTH":
					source.length_reduction = 0.85 if source.length_reduction < 0.8 and source.length_reduction > 0.6 else (0.5 if source.length_reduction > 0.8 else 0.7)
				"FORKS": source.branch_count = 3 if source.branch_count == 2 else 2
			if id != "GROW": source.rebuild_to(level)
		else:
			source.apply_grid_config({"aftermath":{"FORM":"form","STRATA":"strata","REACH":"envelope","ENDS":"apparatus"}[id]})
	refresh()

func refresh() -> void:
	if kind == "growth":
		readout.text = "branch(end, turned_dir, length * ratio)\nstop after 4 generations; at most 121 segments" if show_rule else "generation %d / 4 | %d segments\nturn %d deg | length x %.2f | %d forks" % [mini(source.current_depth,4),source.segment_count,source.branch_angle_min,source.length_reduction,source.branch_count]
	else:
		readout.text = "one fixed draw; three branching levels\ncolour / bounds / endpoints reveal this tree" if show_rule else "seed %d | %s\nFollow a fork to its last visible branch." % [source.random_seed,source.aftermath.to_upper()]

func _build_compact_console(ids: Array, title: String) -> void:
	# All six controls fit within one standing position. Keep the physical
	# button size; compact the spacing instead of shrinking the touch targets.
	var casing := material("263a44")
	box(Vector3(0, 0.95, 2.0), Vector3(1.12, 0.12, 0.44), casing, true)
	for x in [-0.42, 0.42]:
		box(Vector3(x, 0.445, 2.0), Vector3(0.08, 0.89, 0.30), casing, true)
	for i in ids.size():
		var id: String = ids[i]
		var column: int = i % 3
		var row: int = i / 3
		var button = PUSH.instantiate()
		button.position = Vector3((column - 1) * 0.32, 1.045, 1.88 + row * 0.23)
		button.rotation = Vector3.ZERO
		button.scale = Vector3.ONE * 1.15
		add_child(button)
		buttons[id] = button
		button.pressed.connect(act.bind(id))
		var caption := label(id, button.position + Vector3(0, 0.01, 0.09), 0.00065)
		caption.rotation_degrees.x = -70
	box(Vector3(0, 0.90, 2.235), Vector3(1.12, 0.15, 0.025), casing)
	label(title, Vector3(0, 0.90, 2.252), 0.00063)

	# A single transparent plane avoids the doubled opacity of a glass box.
	# Text keeps an opaque outline, so the exhibit is visible behind the panel
	# while the reading remains distinct from its changing background.
	var panel := Node3D.new()
	panel.name = "TextPanel"
	add_child(panel)
	panel.position = Vector3(0, 1.27, 1.58)
	panel.rotation_degrees.x = -35
	var glass := MeshInstance3D.new()
	glass.name = "Glass"
	var pane := QuadMesh.new()
	pane.size = Vector2(1.18, 0.36)
	glass.mesh = pane
	var tint := StandardMaterial3D.new()
	tint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	tint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	tint.cull_mode = BaseMaterial3D.CULL_DISABLED
	tint.albedo_color = Color(0.12, 0.25, 0.30, 0.14)
	glass.material_override = tint
	glass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	panel.add_child(glass)
	for y in [-0.19, 0.19]:
		box(Vector3(0, y, 0), Vector3(1.22, 0.016, 0.016), casing, false, panel)
	for x in [-0.60, 0.60]:
		box(Vector3(x, 0, 0), Vector3(0.016, 0.38, 0.016), casing, false, panel)
	for x in [-0.48, 0.48]:
		box(Vector3(x, 1.09, 1.70), Vector3(0.018, 0.22, 0.018), casing)
	readout = label(title, Vector3.ZERO, 0.0011)
	readout.font_size = 28
	readout.outline_size = 7
	readout.outline_modulate = Color(0.025, 0.04, 0.055, 0.95)
	readout.reparent(panel, false)
	readout.position = Vector3(0, 0, 0.009)
