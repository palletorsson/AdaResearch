extends Node3D

## CSG Case Test — using RackTemplates.create_csg_case()

const RackTpl = preload("res://commons/audio/rack_templates/RackTemplates.gd")

func _ready():
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

	var cam := Camera3D.new()
	cam.fov = 50
	cam.transform.origin = Vector3(0.1, 0.25, 1.2)
	cam.current = true
	add_child(cam)
	cam.look_at(Vector3(0, 0.04, -0.06), Vector3.UP)

	# ── Row 1: Empty CSG cases (no panel) — just the boolean shape ──
	var x := -0.5
	var gap := 0.35

	# Dark 35°
	var c1 := RackTpl.create_csg_case(0.22, 0.16, 0.14, 35.0, null,
		Color(0.12, 0.12, 0.12))
	c1.transform.origin = Vector3(x, 0, 0)
	add_child(c1)
	_label("DARK 35", x, -0.04)
	x += gap

	# Wood 30°
	var c2 := RackTpl.create_csg_case(0.22, 0.18, 0.16, 30.0, null,
		Color(0.55, 0.38, 0.22))
	c2.transform.origin = Vector3(x, 0, 0)
	add_child(c2)
	_label("WOOD 30", x, -0.04)
	x += gap

	# Dark 45°
	var c3 := RackTpl.create_csg_case(0.20, 0.20, 0.12, 45.0, null,
		Color(0.20, 0.18, 0.15))
	c3.transform.origin = Vector3(x, 0, 0)
	add_child(c3)
	_label("DARK 45", x, -0.04)
	x += gap

	# Wall 0°
	var c4 := RackTpl.create_csg_case(0.24, 0.16, 0.04, 0.0, null,
		Color(0.12, 0.12, 0.12))
	c4.transform.origin = Vector3(x, 0, 0)
	add_child(c4)
	_label("WALL 0", x, -0.04)

	# ── Row 2: CSG cases WITH panels ─────────────────────────────────
	x = -0.35
	var y2 := -0.28

	# Desktop + frameless synth panel (controls only, no backing mesh)
	var p1 := RackTpl.create_panel("CSG SYNTH", [
		[{"type": "slider_h", "label": "FREQ", "default": 0.5}, {"type": "slider_h", "label": "RES", "default": 0.3}],
		[{"type": "button", "label": "PLAY"}, {"type": "button", "label": "RST"}],
	], true)  # frameless = true
	var c5 := RackTpl.create_csg_case(0.24, 0.18, 0.16, 35.0, p1,
		Color(0.12, 0.12, 0.12))
	c5.transform.origin = Vector3(x, y2, 0)
	add_child(c5)
	_label("CSG + FRAMELESS", x, y2 - 0.06)
	x += 0.45

	# Wood + frameless lab panel
	var p2 := RackTpl.create_panel("WOOD LAB", [
		[{"type": "histogram", "label": "DATA"}],
		[{"type": "knob", "label": "GAIN"}, {"type": "knob", "label": "FREQ"}],
	], true)  # frameless = true
	var c6 := RackTpl.create_csg_case(0.28, 0.22, 0.18, 30.0, p2,
		Color(0.55, 0.38, 0.22))
	c6.transform.origin = Vector3(x, y2, 0)
	add_child(c6)
	_label("WOOD + PANEL", x, y2 - 0.06)

	print("CSGCaseTest: 6 cases built (4 empty + 2 with panels)")


func _label(text: String, lx: float, ly: float) -> void:
	var lbl := Label3D.new()
	lbl.text = text
	lbl.font_size = 18
	lbl.pixel_size = 0.0005
	lbl.modulate = Color(0.15, 0.15, 0.15)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.transform.origin = Vector3(lx, ly, 0.01)
	add_child(lbl)
