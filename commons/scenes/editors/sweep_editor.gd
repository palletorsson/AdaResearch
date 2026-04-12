# sweep_editor.gd — Generalized sweep: cross-section × path × radius × twist
# What glass tubes learn from math surfaces.
extends BaseGeometryEditor


func _get_editor_name() -> String:
	return "Generalized Sweep"


func _get_parameter_groups() -> Array:
	return [
		{"name": "Preset", "params": [
			{"id": "preset", "label": "Preset", "options": [
				"Custom", "Glass Tube", "Möbius Strip", "Seashell",
				"Torus Knot (2,3)", "Torus Knot (3,5)", "Helicoid",
				"Flask", "Spiral Horn", "Star Tube", "Pulsing Worm",
				"DNA Strand", "Figure Eight",
			], "default": 0.0},
		]},
		{"name": "Cross-Section", "params": [
			{"id": "profile", "label": "Profile", "options": [
				"Circle", "Ellipse", "Rectangle", "Line",
				"Star", "Triangle", "Hexagon", "Octagon",
			], "default": 0.0},
			{"id": "profile_detail", "label": "Detail", "min": 3.0, "max": 24.0, "step": 1.0, "default": 12.0},
			{"id": "profile_aspect", "label": "Aspect", "min": 0.1, "max": 2.0, "step": 0.05, "default": 1.0},
		]},
		{"name": "Path", "params": [
			{"id": "path_type", "label": "Path", "options": [
				"Line", "Circle", "Helix", "Torus Knot",
				"Log Spiral", "S-Bend", "Figure Eight",
			], "default": 0.0},
			{"id": "path_radius", "label": "Radius", "min": 0.1, "max": 3.0, "step": 0.05, "default": 1.0},
			{"id": "path_height", "label": "Height", "min": 0.0, "max": 4.0, "step": 0.1, "default": 1.5},
			{"id": "path_turns", "label": "Turns", "min": 0.5, "max": 6.0, "step": 0.5, "default": 2.0},
			{"id": "path_p", "label": "P (knot)", "min": 1.0, "max": 7.0, "step": 1.0, "default": 2.0},
			{"id": "path_q", "label": "Q (knot)", "min": 1.0, "max": 7.0, "step": 1.0, "default": 3.0},
		]},
		{"name": "Radius", "params": [
			{"id": "radius_type", "label": "Radius", "options": [
				"Constant", "Taper", "Exponential", "Pulse", "Bulge",
			], "default": 0.0},
			{"id": "radius_base", "label": "Base", "min": 0.01, "max": 0.5, "step": 0.01, "default": 0.08},
			{"id": "radius_end", "label": "End/Amount", "min": 0.01, "max": 0.5, "step": 0.01, "default": 0.02},
			{"id": "radius_freq", "label": "Frequency", "min": 1.0, "max": 10.0, "step": 0.5, "default": 5.0},
		]},
		{"name": "Twist", "params": [
			{"id": "twist", "label": "Degrees", "min": 0.0, "max": 720.0, "step": 10.0, "default": 0.0},
			{"id": "segments", "label": "Segments", "min": 12.0, "max": 128.0, "step": 4.0, "default": 48.0},
			{"id": "close_path", "label": "Close Loop", "options": ["Open", "Closed"], "default": 0.0},
		]},
	]


func _on_dropdown_changed(index: int, param_id: String) -> void:
	if param_id == "preset" and index > 0:
		_load_sweep_preset(index)
		return
	super._on_dropdown_changed(index, param_id)


func _load_sweep_preset(idx: int) -> void:
	# Reset to defaults
	var defaults: Dictionary = {
		"profile": 0.0, "profile_detail": 12.0, "profile_aspect": 1.0,
		"path_type": 0.0, "path_radius": 1.0, "path_height": 1.5,
		"path_turns": 2.0, "path_p": 2.0, "path_q": 3.0,
		"radius_type": 0.0, "radius_base": 0.08, "radius_end": 0.02, "radius_freq": 5.0,
		"twist": 0.0, "segments": 48.0, "close_path": 0.0,
	}
	for key: String in defaults:
		_params[key] = defaults[key]

	match idx:
		1:  # Glass Tube
			_params["path_type"] = 0.0; _params["radius_base"] = 0.1
			_params["path_height"] = 1.5
		2:  # Möbius Strip
			_params["profile"] = 2.0; _params["path_type"] = 1.0
			_params["twist"] = 180.0; _params["close_path"] = 1.0
			_params["radius_base"] = 0.4; _params["segments"] = 64.0
			_params["profile_aspect"] = 0.1
		3:  # Seashell
			_params["path_type"] = 4.0; _params["radius_type"] = 2.0
			_params["radius_base"] = 0.02; _params["path_turns"] = 4.0
			_params["segments"] = 96.0
		4:  # Torus Knot (2,3)
			_params["path_type"] = 3.0; _params["close_path"] = 1.0
			_params["radius_base"] = 0.05; _params["segments"] = 128.0
		5:  # Torus Knot (3,5)
			_params["path_type"] = 3.0; _params["close_path"] = 1.0
			_params["path_p"] = 3.0; _params["path_q"] = 5.0
			_params["radius_base"] = 0.04; _params["segments"] = 128.0
		6:  # Helicoid
			_params["profile"] = 3.0; _params["path_type"] = 2.0
			_params["twist"] = 1080.0; _params["segments"] = 96.0
			_params["path_radius"] = 0.01; _params["radius_base"] = 0.5
		7:  # Flask
			_params["radius_type"] = 4.0; _params["radius_base"] = 0.05
			_params["radius_end"] = 0.15; _params["profile_detail"] = 16.0
		8:  # Spiral Horn
			_params["path_type"] = 4.0; _params["radius_type"] = 1.0
			_params["radius_base"] = 0.08; _params["radius_end"] = 0.01
			_params["twist"] = 30.0; _params["segments"] = 96.0
		9:  # Star Tube
			_params["profile"] = 4.0; _params["path_type"] = 2.0
			_params["radius_base"] = 0.1; _params["path_radius"] = 0.5
		10:  # Pulsing Worm
			_params["path_type"] = 5.0; _params["radius_type"] = 3.0
			_params["radius_base"] = 0.08; _params["radius_end"] = 0.03
		11:  # DNA Strand
			_params["path_type"] = 2.0; _params["radius_base"] = 0.03
			_params["path_radius"] = 0.5; _params["path_turns"] = 3.0
		12:  # Figure Eight
			_params["path_type"] = 6.0; _params["radius_base"] = 0.06
			_params["close_path"] = 1.0; _params["segments"] = 96.0

	_sync_sliders_to_params()
	_needs_rebuild = true
	_rebuild_timer = 0.0


func _rebuild() -> void:
	_clear_content()

	# Build cross-section profile
	var profile_type: int = int(p("profile", 0))
	var detail: int = int(p("profile_detail", 12))
	var aspect: float = p("profile_aspect", 1.0)
	var profile: Array = []

	match profile_type:
		0: profile = MorphoSweep.profile_circle(detail)
		1: profile = MorphoSweep.profile_ellipse(detail, aspect)
		2: profile = MorphoSweep.profile_rectangle(1.0, aspect)
		3: profile = MorphoSweep.profile_line(1.0, detail)
		4: profile = MorphoSweep.profile_star(clampi(detail, 3, 12))
		5: profile = MorphoSweep.profile_polygon(3)
		6: profile = MorphoSweep.profile_polygon(6)
		7: profile = MorphoSweep.profile_polygon(8)

	# Build path curve
	var path_type: int = int(p("path_type", 0))
	var path_r: float = p("path_radius", 1.0)
	var path_h: float = p("path_height", 1.5)
	var path_turns: float = p("path_turns", 2.0)
	var path_func: Callable

	match path_type:
		0: path_func = MorphoSweep.path_line(Vector3.ZERO, Vector3(0, path_h, 0))
		1: path_func = MorphoSweep.path_circle(path_r)
		2: path_func = MorphoSweep.path_helix(path_r, path_h, path_turns)
		3: path_func = MorphoSweep.path_torus_knot(path_r, path_r * 0.4,
			int(p("path_p", 2)), int(p("path_q", 3)))
		4: path_func = MorphoSweep.path_log_spiral(0.15, path_turns)
		5: path_func = MorphoSweep.path_sbend(path_r, path_h)
		6: path_func = MorphoSweep.path_figure_eight(path_r)

	# Build radius function
	var rad_type: int = int(p("radius_type", 0))
	var rad_base: float = p("radius_base", 0.08)
	var rad_end: float = p("radius_end", 0.02)
	var rad_freq: float = p("radius_freq", 5.0)
	var radius_func: Callable

	match rad_type:
		0: radius_func = MorphoSweep.radius_constant(rad_base)
		1: radius_func = MorphoSweep.radius_taper(rad_base, rad_end)
		2: radius_func = MorphoSweep.radius_exponential(rad_base, 0.15)
		3: radius_func = MorphoSweep.radius_pulse(rad_base, rad_end, rad_freq)
		4: radius_func = MorphoSweep.radius_bulge(rad_base, rad_end)

	# Sweep
	var twist: float = p("twist", 0.0)
	var segs: int = int(p("segments", 48))
	var closed: bool = int(p("close_path", 0)) > 0

	var mesh: Mesh = MorphoSweep.sweep(profile, path_func, radius_func, twist, segs, closed)

	if mesh:
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.75, 0.82, 0.9)
		mat.roughness = 0.3
		mat.metallic = 0.15
		mat.cull_mode = BaseMaterial3D.CULL_BACK
		mi.material_override = mat
		content_root.add_child(mi)

	# Info
	var profile_names: Array[String] = ["Circle", "Ellipse", "Rectangle", "Line", "Star", "Triangle", "Hexagon", "Octagon"]
	var path_names: Array[String] = ["Line", "Circle", "Helix", "Torus Knot", "Log Spiral", "S-Bend", "Figure 8"]
	var rad_names: Array[String] = ["Constant", "Taper", "Exponential", "Pulse", "Bulge"]
	if info_label:
		var parts: PackedStringArray = [
			profile_names[clampi(profile_type, 0, 7)],
			path_names[clampi(path_type, 0, 6)],
			rad_names[clampi(rad_type, 0, 4)],
		]
		if twist > 0.1: parts.append("tw=%.0f°" % twist)
		if closed: parts.append("CLOSED")
		info_label.text = " × ".join(parts) + " | %d seg" % segs
