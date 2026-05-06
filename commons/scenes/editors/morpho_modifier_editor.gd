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
		{"name": "Smooth", "params": [
			{"id": "smooth_iters", "label": "Iterations", "min": 0.0, "max": 10.0, "step": 1.0, "default": 0.0},
			{"id": "smooth_factor", "label": "Factor", "min": 0.1, "max": 1.0, "step": 0.05, "default": 0.5},
		]},
		{"name": "Generate", "params": [
			{"id": "mirror_axis", "label": "Mirror", "options": ["Off", "X", "Y", "Z"], "default": 0.0},
			{"id": "solidify", "label": "Solidify", "min": 0.0, "max": 0.2, "step": 0.005, "default": 0.0},
			{"id": "array_count", "label": "Array Count", "min": 1.0, "max": 8.0, "step": 1.0, "default": 1.0},
			{"id": "array_offset", "label": "Array Spacing", "min": 0.5, "max": 3.0, "step": 0.1, "default": 1.2},
			{"id": "screw_steps", "label": "Screw Steps", "min": 0.0, "max": 24.0, "step": 1.0, "default": 0.0},
			{"id": "screw_height", "label": "Screw Height", "min": 0.0, "max": 3.0, "step": 0.1, "default": 0.0},
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

	# Smooth (Laplacian)
	if int(p("smooth_iters")) > 0:
		mesh = MorphoModifier.smooth(mesh, int(p("smooth_iters")), p("smooth_factor", 0.5))

	# Mirror
	var mirror_axis: int = int(p("mirror_axis", 0))
	if mirror_axis > 0 and mesh:
		mesh = MorphoModifier.mirror(mesh, mirror_axis - 1)

	# Solidify
	if p("solidify") > 0.001 and mesh:
		mesh = MorphoModifier.solidify(mesh, p("solidify"))

	# Array
	if int(p("array_count", 1)) > 1 and mesh:
		var count: int = int(p("array_count"))
		var spacing: float = p("array_offset", 1.2)
		mesh = MorphoModifier.array_modifier(mesh, count, Vector3(spacing, 0, 0))

	# Screw
	if int(p("screw_steps")) > 0 and mesh:
		mesh = MorphoModifier.screw(mesh, Vector3.UP, int(p("screw_steps")),
			360.0, p("screw_height", 0.0))

	if mesh:
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.7, 0.75, 0.8)
		mat.roughness = 0.4
		mat.metallic = 0.1
		mi.material_override = mat
		content_root.add_child(mi)
