extends "res://commons/artifacts/timing_machines/machine_stage.gd"
## Opt-in museum instrument: finite intervals, their record, and bodily gaps.
var kind := "intervals"
var source: Node3D
var show_rule := false
var history := true

func _ready() -> void:
	source = get_parent()
	_build_compact_console(["NEXT","BACK","HISTORY","GHOST","RESET","RULE"] if kind == "intervals" else ["CUT","LESS","DEPTH","LATEST","RESET","RULE"], "01 / MORE PIECES, LESS?" if kind == "intervals" else "02 / A GAP FOR WHOM?")
	begin()
	_use_hall_light.call_deferred()

func begin() -> void:
	show_rule = false
	history = true
	if kind == "intervals":
		source.lesson_enabled = true
		source.auto_start = false
		source.tick = "limit"
		source.build_mode = "grow"
		source.initial_bar_length = 6.0
		source.bar_thickness = 0.12
		source.vertical_spacing = 0.45
		source.removal = "gone"
		set_stage(0)
	else:
		source.base_width = 9.0
		source.block_height = 2.2
		source.vertical_offset = 0.0
		source.block_thickness = 2.0
		set_stage(1)

func set_stage(level: int) -> void:
	if kind == "intervals":
		source.reset()
		for i in range(clampi(level,0,5)): source.step()
	else:
		source.max_depth = clampi(level,1,3)
		source.reset_pagoda()
		source._status_label.hide()
	apply_visibility()
	refresh()

func apply_visibility() -> void:
	var level: int = source.current_iteration if kind == "intervals" else source.max_depth
	var pieces: Array = source.get_children() if kind == "intervals" else source._blocks
	for piece in pieces:
		if not piece.has_meta("cantor_level"): continue
		var included: bool = history or int(piece.get_meta("cantor_level")) == level
		piece.visible = included
		if piece is CollisionObject3D:
			piece.collision_layer = 1 if included else 0
			piece.collision_mask = 1 if included else 0

func act(id: String) -> void:
	if id == "RESET": begin(); return
	if id == "RULE": show_rule = not show_rule; refresh(); return
	show_rule = false
	var level: int = source.current_iteration if kind == "intervals" else source.max_depth
	match id:
		"NEXT", "CUT": set_stage(level+1)
		"BACK", "LESS": set_stage(level-1)
		"HISTORY", "LATEST": history = not history; apply_visibility()
		"GHOST":
			source.removal = "ghost" if source.removal == "gone" else "gone"
			set_stage(level)
		"DEPTH":
			source.block_thickness = {1.0:2.0,2.0:4.0,4.0:1.0}.get(float(source.block_thickness),2.0)
			set_stage(level)
	refresh()

func refresh() -> void:
	if kind == "intervals":
		var kept := 0.0
		for bar in source.current_bars: kept += source.get_bar_length(bar)
		readout.text = "third = length / 3; keep left + right\nEach press removes a third of what remains." if show_rule else "cut %d / 5 | %d pieces | %.3f m kept\nhistory %s | removed %s" % [source.current_iteration,source.current_bars.size(),kept,"on" if history else "off",source.removal]
	else:
		var info: Dictionary = source.get_level_info(source.max_depth)
		readout.text = "interval -> box(width, height, depth)\nA visible gap still has to admit this body." if show_rule else "cut %d / 3 | %d lower blocks | %.3f m kept\n%.1f m deep | %s" % [source.max_depth,info.block_count,info.total_width,source.block_thickness,"history above" if history else "latest only"]

func _use_hall_light() -> void:
	var hall: Node = source
	while hall != null and not hall.has_meta("em_map"): hall = hall.get_parent()
	if hall == null or str(hall.get_meta("em_map")) != "Fractal_CantorSet": return
	for lamp in hall.find_children("*","DirectionalLight3D",true,false): lamp.hide()
	if kind != "intervals" or hall.has_node("CantorHallLights"): return
	var lights := Node3D.new()
	lights.name = "CantorHallLights"
	hall.add_child(lights)
	for at in [Vector3(5.5,4,7),Vector3(13.5,4,9),Vector3(9.5,9,17),Vector3(9.5,5,23)]:
		var lamp := OmniLight3D.new()
		lamp.position = at
		lamp.light_energy = 2.5
		lamp.omni_range = 11
		lamp.light_color = Color("f3e6d6")
		lights.add_child(lamp)

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
