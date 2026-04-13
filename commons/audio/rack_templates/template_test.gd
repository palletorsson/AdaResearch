extends Node3D

## Test scene for all RackTemplates — one of each template in a row.

const RackTemplatesScript = preload("res://commons/audio/rack_templates/RackTemplates.gd")

func _ready():
	# Environment
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.85, 0.82, 0.78)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(1, 1, 1)
	env.ambient_light_energy = 4.0
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	var light := DirectionalLight3D.new()
	light.light_energy = 2.5
	light.shadow_enabled = true
	light.transform = Transform3D.IDENTITY.looking_at(Vector3(-0.3, -0.5, -1), Vector3.UP)
	light.transform.origin = Vector3(0, 3, 2)
	add_child(light)

	var cam := Camera3D.new()
	cam.fov = 50
	cam.transform.origin = Vector3(0, 1.1, 1.5)
	cam.current = true
	add_child(cam)

	var x := -1.0
	var y := 1.1
	var gap := 0.45

	# 1. Fader Bank (4 faders)
	var faders := RackTemplatesScript.create_fader_bank(4, ["FREQ", "AMP", "DEC", "REL"])
	faders.transform.origin = Vector3(x, y, 0)
	add_child(faders)
	_label("FADER BANK 4", x, y - 0.22)
	x += gap

	# 2. Knob Panel (3 knobs)
	var knobs := RackTemplatesScript.create_knob_panel(3, ["ATK", "DEC", "REL"])
	knobs.transform.origin = Vector3(x, y, 0)
	add_child(knobs)
	_label("KNOB PANEL 3", x, y - 0.22)
	x += gap

	# 3. Parameter Panel (5 params)
	var params := RackTemplatesScript.create_parameter_panel(5, ["Sep", "Align", "Cohesion", "Speed", "Radius"], [0.5, 0.5, 0.5, 0.3, 0.4])
	params.transform.origin = Vector3(x, y, 0)
	add_child(params)
	_label("PARAM PANEL 5", x, y - 0.28)
	x += gap

	# 4. Button Grid (3x2)
	var buttons := RackTemplatesScript.create_button_grid(3, 2, ["SINE", "SAW", "SQR", "TRI", "PLAY", "STOP"])
	buttons.transform.origin = Vector3(x, y, 0)
	add_child(buttons)
	_label("BUTTON GRID", x, y - 0.22)
	x += gap

	# 5. Mixer Strip
	var strip := RackTemplatesScript.create_mixer_strip("CH1")
	strip.transform.origin = Vector3(x, y, 0)
	add_child(strip)
	_label("MIXER STRIP", x, y - 0.26)
	x += gap * 0.6

	# 6. Monitor + Faders
	var monitor := RackTemplatesScript.create_monitor_faders(3, ["H1", "H2", "H3"], "scope")
	monitor.transform.origin = Vector3(x, y, 0)
	add_child(monitor)
	_label("MONITOR+FADERS", x, y - 0.26)

	print("TemplateTest: 6 templates spawned")


func _label(text: String, x: float, y: float) -> void:
	var lbl := Label3D.new()
	lbl.text = text
	lbl.font_size = 22
	lbl.pixel_size = 0.0005
	lbl.modulate = Color(0.15, 0.15, 0.15)
	lbl.outline_size = 3
	lbl.outline_modulate = Color(0.9, 0.88, 0.83, 0.5)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.transform.origin = Vector3(x, y, 0.01)
	add_child(lbl)
