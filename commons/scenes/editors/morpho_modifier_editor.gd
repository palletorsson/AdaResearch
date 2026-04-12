# morpho_modifier_editor.gd — Pick a base primitive then stack modifiers with live preview
extends BaseGeometryEditor


func _get_editor_name() -> String:
	return "Mesh Modifier"


func _get_parameter_groups() -> Array:
	return [
		{"name": "Primitive", "params": [
			{"id": "primitive_type", "label": "Primitive", "options": ["Sphere", "Cylinder", "Box", "Torus"], "default": 0.0},
			{"id": "radius", "label": "Radius", "min": 0.1, "max": 2.0, "step": 0.05, "default": 0.5},
			{"id": "height", "label": "Height", "min": 0.1, "max": 3.0, "step": 0.1, "default": 1.0},
			{"id": "sides", "label": "Sides", "min": 4.0, "max": 32.0, "step": 1.0, "default": 12.0},
		]},
		{"name": "Taper", "params": [
			{"id": "taper_amount", "label": "Amount", "min": 0.0, "max": 1.0, "step": 0.05, "default": 0.0},
		]},
		{"name": "Twist", "params": [
			{"id": "twist_degrees", "label": "Degrees", "min": -360.0, "max": 360.0, "step": 5.0, "default": 0.0},
		]},
		{"name": "Bend", "params": [
			{"id": "bend_angle", "label": "Angle", "min": -90.0, "max": 90.0, "step": 5.0, "default": 0.0},
		]},
		{"name": "Noise", "params": [
			{"id": "noise_strength", "label": "Strength", "min": 0.0, "max": 0.3, "step": 0.01, "default": 0.0},
			{"id": "noise_frequency", "label": "Frequency", "min": 0.1, "max": 3.0, "step": 0.1, "default": 0.5},
		]},
		{"name": "Wave", "params": [
			{"id": "wave_frequency", "label": "Frequency", "min": 0.0, "max": 10.0, "step": 0.5, "default": 0.0},
			{"id": "wave_amplitude", "label": "Amplitude", "min": 0.0, "max": 0.5, "step": 0.02, "default": 0.0},
		]},
		{"name": "Other", "params": [
			{"id": "spherize", "label": "Spherize", "min": 0.0, "max": 1.0, "step": 0.05, "default": 0.0},
			{"id": "inflate", "label": "Inflate", "min": -0.2, "max": 0.3, "step": 0.01, "default": 0.0},
		]},
	]


func _rebuild() -> void:
	_clear_content()

	# Create base primitive
	var ptype: int = int(p("primitive_type", 0))
	var r: float = p("radius", 0.5)
	var h: float = p("height", 1.0)
	var s: int = int(p("sides", 12))
	var mesh: Mesh = null

	match ptype:
		0: mesh = MorphoPrimitive.sphere(r, s, s / 2)
		1: mesh = MorphoPrimitive.cylinder(r * 0.3, r, h, s)
		2: mesh = MorphoPrimitive.box(Vector3(r, h, r))
		3: mesh = MorphoPrimitive.torus(r * 0.4, r)

	if not mesh:
		return

	# Apply modifiers in chain
	if absf(p("taper_amount")) > 0.01:
		var amt: float = p("taper_amount")
		mesh = MorphoModifier.taper(mesh, Vector3.UP,
			func(t: float) -> float: return 1.0 - t * amt)

	if absf(p("twist_degrees")) > 1.0:
		mesh = MorphoModifier.twist(mesh, Vector3.UP, p("twist_degrees"))

	if absf(p("bend_angle")) > 1.0:
		mesh = MorphoModifier.bend(mesh, Vector3.FORWARD, p("bend_angle"))

	if p("noise_strength") > 0.005:
		var noise := FastNoiseLite.new()
		noise.frequency = p("noise_frequency", 0.5)
		mesh = MorphoModifier.noise_displace(mesh, noise, p("noise_strength"))

	if p("wave_frequency") > 0.1 and p("wave_amplitude") > 0.005:
		mesh = MorphoModifier.wave(mesh, Vector3.RIGHT, Vector3.UP,
			p("wave_frequency"), p("wave_amplitude"))

	if p("spherize") > 0.01:
		mesh = MorphoModifier.spherize(mesh, p("spherize"))

	if absf(p("inflate")) > 0.005:
		mesh = MorphoModifier.inflate(mesh, p("inflate"))

	if mesh:
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.7, 0.75, 0.8)
		mat.roughness = 0.4
		mat.metallic = 0.1
		mi.material_override = mat
		content_root.add_child(mi)
