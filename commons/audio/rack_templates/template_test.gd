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
	cam.fov = 55
	cam.transform.origin = Vector3(0, -0.4, 6.0)
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

	# ── Row 2: New templates ──────────────────────────────────────────
	var x2 := -1.0
	var y2 := y - 0.55

	# 7. Shader Panel (4 uniforms + code snippet)
	var shader := RackTemplatesScript.create_shader_panel(
		4, ["TIME", "SCALE", "EDGE_0", "EDGE_1"],
		[0.5, 0.6, 0.3, 0.8],
		"smoothstep(e0, e1, uv.x)"
	)
	shader.transform.origin = Vector3(x2, y2, 0)
	add_child(shader)
	_label("SHADER PANEL", x2, y2 - 0.24)
	x2 += gap

	# 8. Gauge Meter (VU-style needle + trim knob)
	var gauge := RackTemplatesScript.create_gauge_meter("LEVEL", "TRIM")
	gauge.transform.origin = Vector3(x2, y2, 0)
	add_child(gauge)
	_label("GAUGE METER", x2, y2 - 0.18)
	x2 += gap * 0.7

	# 9. Preset Bar (4 presets + slider)
	var presets := RackTemplatesScript.create_preset_bar(
		["BEATS", "SYNC", "WEAK", "CHAOS"],
		[], "COUPLING", 0.4
	)
	presets.transform.origin = Vector3(x2, y2, 0)
	add_child(presets)
	_label("PRESET BAR", x2, y2 - 0.14)
	x2 += gap

	# 10. Experiment Panel (3 sections: Elbow, Converge, Outlier)
	var experiment := RackTemplatesScript.create_experiment_panel([
		{
			"title": "ELBOW",
			"sliders": [
				{"label": "K_MIN", "default": 0.2},
				{"label": "K_MAX", "default": 0.8},
			],
			"buttons": ["RUN"],
		},
		{
			"title": "CONVERGE",
			"sliders": [
				{"label": "THRESH", "default": 0.1},
				{"label": "MAX_IT", "default": 0.5},
			],
			"buttons": ["ANALYZE"],
		},
		{
			"title": "OUTLIER",
			"sliders": [
				{"label": "COUNT", "default": 0.25},
				{"label": "DIST", "default": 0.4},
			],
			"buttons": ["DETECT"],
		},
	])
	experiment.transform.origin = Vector3(x2, y2, 0)
	add_child(experiment)
	_label("EXPERIMENT", x2, y2 - 0.24)

	# ── Row 3: Direct create_panel with mixed types ─────────────────
	var x3 := -1.0
	var y3 := y2 - 0.55

	# 11. CA Rule Explorer — sliders + preset buttons in one panel
	var ca_panel := RackTemplatesScript.create_panel("CA RULE EXPLORER", [
		[
			{"type": "slider_h", "label": "RULE", "default": 0.43},
			{"type": "slider_h", "label": "SPEED", "default": 0.5},
		],
		[
			{"type": "button", "label": "30"},
			{"type": "button", "label": "90"},
			{"type": "button", "label": "110"},
			{"type": "button", "label": "184"},
			{"type": "button", "label": "RST"},
		],
	])
	ca_panel.transform.origin = Vector3(x3, y3, 0)
	add_child(ca_panel)
	_label("MIXED: CA RULES", x3, y3 - 0.16)
	x3 += gap

	# 12. Audio channel — fader + knob + monitor in one panel
	var audio_panel := RackTemplatesScript.create_panel("AUDIO CH", [
		[{"type": "monitor", "label": "", "mode": "scope"}],
		[
			{"type": "slider_v", "label": "VOL"},
			{"type": "knob", "label": "PAN"},
			{"type": "slider_v", "label": "SEND"},
		],
		[
			{"type": "button", "label": "MUTE"},
			{"type": "button", "label": "SOLO"},
		],
	])
	audio_panel.transform.origin = Vector3(x3, y3, 0)
	add_child(audio_panel)
	_label("MIXED: AUDIO", x3, y3 - 0.22)
	x3 += gap

	# 13. Shader with gauge — sliders + code + gauge in one panel
	var shader_gauge := RackTemplatesScript.create_panel("SHADER LAB", [
		[
			{"type": "slider_h", "label": "FREQ", "default": 0.5},
			{"type": "slider_h", "label": "AMP", "default": 0.7},
		],
		[{"type": "code", "text": "sin(uv.x * freq) * amp", "label": ""}],
		[
			{"type": "gauge", "label": "OUTPUT"},
			{"type": "knob", "label": "TRIM"},
		],
	])
	shader_gauge.transform.origin = Vector3(x3, y3, 0)
	add_child(shader_gauge)
	_label("MIXED: SHADER+GAUGE", x3, y3 - 0.24)
	x3 += gap

	# 14. Terrain sculpt — sliders + two named buttons
	var terrain := RackTemplatesScript.create_panel("TERRAIN", [
		[
			{"type": "slider_h", "label": "THRESH", "default": 0.5},
			{"type": "slider_h", "label": "SCALE", "default": 0.3},
			{"type": "slider_h", "label": "OCTAVES", "default": 0.5},
		],
		[
			{"type": "button", "label": "SEED"},
			{"type": "button", "label": "RESET"},
		],
	])
	terrain.transform.origin = Vector3(x3, y3, 0)
	add_child(terrain)
	_label("MIXED: TERRAIN", x3, y3 - 0.18)

	# ── Row 4: Visualization elements ────────────────────────────────
	var x4 := -1.2
	var y4 := y3 - 0.55

	# 15. ML Dashboard — histogram + sliders
	var ml_panel := RackTemplatesScript.create_panel("ML DASHBOARD", [
		[
			{"type": "histogram", "label": "DISTRIBUTION"},
			{"type": "spectrum", "label": "FEATURES"},
		],
		[
			{"type": "slider_h", "label": "LEARN RATE", "default": 0.3},
			{"type": "slider_h", "label": "EPOCHS", "default": 0.5},
		],
		[
			{"type": "button", "label": "TRAIN"},
			{"type": "button", "label": "RESET"},
		],
	])
	ml_panel.transform.origin = Vector3(x4, y4, 0)
	add_child(ml_panel)
	_label("VIZ: ML DASHBOARD", x4, y4 - 0.22)
	x4 += 0.55

	# 16. CA Lab — matrix + graph side by side
	var ca_lab := RackTemplatesScript.create_panel("AUTOMATA LAB", [
		[
			{"type": "matrix", "label": "CELLS", "cols": 10, "rows_count": 10},
			{"type": "graph", "label": "NETWORK"},
		],
		[
			{"type": "slider_h", "label": "RULE", "default": 0.43},
			{"type": "button", "label": "STEP"},
		],
	])
	ca_lab.transform.origin = Vector3(x4, y4, 0)
	add_child(ca_lab)
	_label("VIZ: AUTOMATA", x4, y4 - 0.20)
	x4 += 0.50

	# 17. Oscilloscope — phase + spectrum
	var osc_panel := RackTemplatesScript.create_panel("OSCILLOSCOPE", [
		[
			{"type": "phase", "label": "LISSAJOUS"},
			{"type": "spectrum", "label": "FFT"},
		],
		[
			{"type": "knob", "label": "FREQ A"},
			{"type": "knob", "label": "FREQ B"},
			{"type": "knob", "label": "PHASE"},
		],
	])
	osc_panel.transform.origin = Vector3(x4, y4, 0)
	add_child(osc_panel)
	_label("VIZ: OSCILLOSCOPE", x4, y4 - 0.20)
	x4 += 0.50

	# 18. All viz types in one panel
	var all_viz := RackTemplatesScript.create_panel("ALL VISUALIZATIONS", [
		[
			{"type": "histogram", "label": "HIST"},
			{"type": "spectrum", "label": "SPEC"},
			{"type": "phase", "label": "PHASE"},
		],
		[
			{"type": "matrix", "label": "MATRIX", "cols": 6, "rows_count": 6},
			{"type": "graph", "label": "GRAPH"},
			{"type": "monitor", "label": "SCOPE", "mode": "scope"},
		],
	])
	all_viz.transform.origin = Vector3(x4, y4, 0)
	add_child(all_viz)
	_label("VIZ: ALL TYPES", x4, y4 - 0.20)

	# ── Row 5: Case housings ─────────────────────────────────────────
	var x5 := -1.2
	var y5 := y4 - 0.65

	# 19. Wall-mounted panel
	var wall_panel := RackTemplatesScript.create_panel("WALL SYNTH", [
		[
			{"type": "knob", "label": "OSC"},
			{"type": "knob", "label": "FILT"},
			{"type": "knob", "label": "RES"},
		],
		[
			{"type": "slider_h", "label": "CUTOFF", "default": 0.6},
		],
	])
	var wall_case := RackTemplatesScript.create_case("wall", wall_panel)
	wall_case.transform.origin = Vector3(x5, y5, 0)
	add_child(wall_case)
	_label("CASE: WALL", x5, y5 - 0.18)
	x5 += 0.55

	# 20. Desktop stand (35° tilt)
	var desk_panel := RackTemplatesScript.create_panel("DESK CONTROLLER", [
		[
			{"type": "slider_h", "label": "FREQ", "default": 0.5},
			{"type": "slider_h", "label": "AMP", "default": 0.7},
			{"type": "slider_h", "label": "PHASE", "default": 0.3},
		],
		[
			{"type": "button", "label": "PLAY"},
			{"type": "button", "label": "STOP"},
			{"type": "button", "label": "REC"},
		],
	])
	var desk_case := RackTemplatesScript.create_case("desktop", desk_panel)
	desk_case.transform.origin = Vector3(x5, y5, 0)
	add_child(desk_case)
	_label("CASE: DESKTOP", x5, y5 - 0.18)
	x5 += 0.55

	# 21. Studio wooden case (Moog style)
	var studio_panel := RackTemplatesScript.create_panel("STUDIO", [
		[
			{"type": "histogram", "label": "SPECTRUM"},
			{"type": "monitor", "label": "WAVE", "mode": "scope"},
		],
		[
			{"type": "slider_v", "label": "CH1"},
			{"type": "slider_v", "label": "CH2"},
			{"type": "slider_v", "label": "CH3"},
			{"type": "slider_v", "label": "MAIN"},
		],
	])
	var studio_case := RackTemplatesScript.create_case("studio", studio_panel)
	studio_case.transform.origin = Vector3(x5, y5, 0)
	add_child(studio_case)
	_label("CASE: STUDIO", x5, y5 - 0.18)
	x5 += 0.60

	# 22. Rack frame (19" style)
	var rack_panel := RackTemplatesScript.create_panel("RACK UNIT", [
		[
			{"type": "gauge", "label": "LEVEL"},
			{"type": "knob", "label": "GAIN"},
			{"type": "knob", "label": "PAN"},
			{"type": "button", "label": "BYPASS"},
		],
	])
	var rack_case := RackTemplatesScript.create_case("rack", rack_panel)
	rack_case.transform.origin = Vector3(x5, y5, 0)
	add_child(rack_case)
	_label("CASE: RACK", x5, y5 - 0.18)

	# ── Row 6: Grid-fitted cases ─────────────────────────────────────
	var x6 := -1.0
	var y6 := y5 - 0.75

	# 23. Shelf-fitted panel
	var shelf_panel := RackTemplatesScript.create_panel("SHELF SYNTH", [
		[
			{"type": "slider_h", "label": "FREQ", "default": 0.5},
			{"type": "slider_h", "label": "RES", "default": 0.3},
		],
		[{"type": "button", "label": "PLAY"}, {"type": "button", "label": "RST"}],
	])
	var shelf_case := RackTemplatesScript.create_fitted_case(RackTemplatesScript.shelf_slot(), shelf_panel)
	shelf_case.transform.origin = Vector3(x6, y6, 0)
	add_child(shelf_case)
	_label("GRID: SHELF", x6, y6 - 0.08)
	x6 += 0.7

	# 24. Wall-fitted panel
	var wall_fitted_panel := RackTemplatesScript.create_panel("WALL DISPLAY", [
		[{"type": "histogram", "label": "DATA"}],
		[
			{"type": "slider_h", "label": "RANGE", "default": 0.6},
		],
	])
	var wall_fitted := RackTemplatesScript.create_fitted_case(RackTemplatesScript.wall_slot(), wall_fitted_panel)
	wall_fitted.transform.origin = Vector3(x6, y6, 0)
	add_child(wall_fitted)
	_label("GRID: WALL", x6, y6 - 0.08)
	x6 += 0.7

	# 25. Floor pedestal
	var pedestal_panel := RackTemplatesScript.create_panel("FLOOR LAB", [
		[{"type": "monitor", "label": "SCOPE", "mode": "scope"}],
		[
			{"type": "knob", "label": "GAIN"},
			{"type": "knob", "label": "FREQ"},
		],
		[{"type": "button", "label": "RESET"}],
	])
	var pedestal := RackTemplatesScript.create_fitted_case(RackTemplatesScript.floor_pedestal_slot(), pedestal_panel)
	pedestal.transform.origin = Vector3(x6, y6, 0)
	add_child(pedestal)
	_label("GRID: PEDESTAL", x6, y6 - 0.08)

	print("TemplateTest: 25 templates (6+4+4+4+4+3 grid-fitted)")


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
