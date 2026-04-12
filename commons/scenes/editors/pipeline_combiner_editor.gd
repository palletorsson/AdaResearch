# pipeline_combiner_editor.gd — The ultimate form-creation editor
#
# Combines 5 non-destructive stages into one pipeline:
#   Field → Skeleton → Surface → Modify → Populate
#
# Each stage has a type selector (0 = bypass) and 2-4 parameters.
# _rebuild() processes stages top-to-bottom, passing results downstream.
# The info_label shows the active pipeline as a → chain.

extends BaseGeometryEditor


func _get_editor_name() -> String:
	return "Pipeline Combiner"


func _get_parameter_groups() -> Array:
	return [
		{"name": "1. Field", "params": [
			{"id": "field_type", "label": "Field", "options": ["None", "Noise", "SDF Spheres", "Metaball"], "default": 0.0},
			{"id": "field_freq", "label": "Frequency", "min": 0.1, "max": 3.0, "step": 0.1, "default": 0.5},
			{"id": "field_strength", "label": "Strength", "min": 0.1, "max": 3.0, "step": 0.1, "default": 1.0},
		]},
		{"name": "2. Skeleton", "params": [
			{"id": "skel_type", "label": "Skeleton", "options": ["None", "Spine", "Spiral", "Star"], "default": 0.0},
			{"id": "skel_points", "label": "Points", "min": 2.0, "max": 16.0, "step": 1.0, "default": 6.0},
			{"id": "skel_length", "label": "Length", "min": 0.3, "max": 3.0, "step": 0.1, "default": 1.5},
			{"id": "skel_curve", "label": "Curvature", "min": 0.0, "max": 1.0, "step": 0.05, "default": 0.0},
		]},
		{"name": "3. Surface", "params": [
			{"id": "surf_type", "label": "Surface", "options": ["Auto", "Sweep", "Revolution", "Marching Cubes", "Primitive"], "default": 0.0},
			{"id": "surf_radius", "label": "Radius", "min": 0.02, "max": 0.5, "step": 0.01, "default": 0.1},
			{"id": "surf_sides", "label": "Sides", "min": 3.0, "max": 16.0, "step": 1.0, "default": 8.0},
			{"id": "surf_resolution", "label": "Resolution", "min": 8.0, "max": 32.0, "step": 4.0, "default": 16.0},
		]},
		{"name": "4. Modify", "params": [
			{"id": "mod_taper", "label": "Taper", "min": 0.0, "max": 1.0, "step": 0.05, "default": 0.0},
			{"id": "mod_twist", "label": "Twist", "min": -360.0, "max": 360.0, "step": 10.0, "default": 0.0},
			{"id": "mod_noise", "label": "Noise", "min": 0.0, "max": 0.3, "step": 0.01, "default": 0.0},
			{"id": "mod_wave_freq", "label": "Wave Freq", "min": 0.0, "max": 8.0, "step": 0.5, "default": 0.0},
			{"id": "mod_wave_amp", "label": "Wave Amp", "min": 0.0, "max": 0.3, "step": 0.01, "default": 0.0},
		]},
		{"name": "5. Populate", "params": [
			{"id": "pop_type", "label": "Populate", "options": ["None", "Radial", "Grid", "Scatter"], "default": 0.0},
			{"id": "pop_count", "label": "Count", "min": 1.0, "max": 12.0, "step": 1.0, "default": 6.0},
			{"id": "pop_radius", "label": "Radius/Spacing", "min": 0.3, "max": 3.0, "step": 0.1, "default": 1.0},
		]},
	]


func _rebuild() -> void:
	_clear_content()

	# ── Stage 1: FIELD ──────────────────────────────────────
	var field_func: Callable = Callable()  # empty = no field
	var field_type: int = int(p("field_type", 0))
	match field_type:
		1:  # Noise field
			var noise := FastNoiseLite.new()
			noise.frequency = p("field_freq", 0.5)
			var strength: float = p("field_strength", 1.0)
			field_func = func(pos: Vector3) -> float:
				return noise.get_noise_3d(pos.x, pos.y, pos.z) * strength
		2:  # SDF (two spheres smooth union)
			var r: float = p("field_strength", 1.0) * 0.5
			field_func = MorphoPrimitive.sdf_smooth_union(
				MorphoPrimitive.sdf_sphere(Vector3(0, 0.3, 0), r),
				MorphoPrimitive.sdf_sphere(Vector3(0, -0.3, 0), r * 0.7),
				r * 0.3
			)
		3:  # Metaball (3 spheres)
			var r: float = p("field_strength", 1.0) * 0.4
			var f: float = p("field_freq", 0.5)
			field_func = func(pos: Vector3) -> float:
				var d1: float = pos.distance_to(Vector3(0, 0.3, 0))
				var d2: float = pos.distance_to(Vector3(f * 0.5, -0.2, 0))
				var d3: float = pos.distance_to(Vector3(-f * 0.3, -0.1, f * 0.3))
				var val: float = r*r / maxf(d1*d1, 0.001) + r*r / maxf(d2*d2, 0.001) + r*r / maxf(d3*d3, 0.001)
				return -(val - 1.0)  # negative inside (SDF convention)

	# ── Stage 2: SKELETON ───────────────────────────────────
	var positions: Array[Vector3] = []
	var radii: Array[float] = []
	var skel_type: int = int(p("skel_type", 0))
	var skel_pts: int = int(p("skel_points", 6))
	var skel_len: float = p("skel_length", 1.5)
	var skel_curve: float = p("skel_curve", 0.0)
	match skel_type:
		1:  # Spine
			for i in skel_pts:
				var t: float = float(i) / maxf(skel_pts - 1.0, 1.0)
				positions.append(Vector3(sin(t * PI) * skel_curve * skel_len * 0.3, t * skel_len, 0))
				radii.append(lerpf(p("surf_radius", 0.1), p("surf_radius", 0.1) * 0.3, t))
		2:  # Spiral
			for i in skel_pts:
				var t: float = float(i) / maxf(skel_pts - 1.0, 1.0)
				var angle: float = t * TAU * 2.0
				var r: float = t * skel_len * 0.3
				positions.append(Vector3(cos(angle) * r, t * skel_len, sin(angle) * r))
				radii.append(lerpf(p("surf_radius", 0.1), p("surf_radius", 0.1) * 0.2, t))
		3:  # Star (radial branches from center)
			var branches: int = clampi(skel_pts, 3, 8)
			for bi in branches:
				var angle: float = TAU * float(bi) / float(branches)
				var dir := Vector3(cos(angle), 0.5, sin(angle)).normalized()
				positions.append(Vector3.ZERO)
				radii.append(p("surf_radius", 0.1))
				positions.append(dir * skel_len)
				radii.append(p("surf_radius", 0.1) * 0.3)

	# ── Stage 3: SURFACE ────────────────────────────────────
	var mesh: Mesh = null
	var surf_type: int = int(p("surf_type", 0))
	var surf_r: float = p("surf_radius", 0.1)
	var surf_sides: int = int(p("surf_sides", 8))
	var surf_res: int = int(p("surf_resolution", 16))

	# Auto-detect: if field exists, use marching cubes. If skeleton exists, use sweep. Else primitive.
	if surf_type == 0:  # auto
		if field_func.is_valid():
			surf_type = 3  # marching cubes
		elif positions.size() >= 2:
			surf_type = 1  # sweep
		else:
			surf_type = 4  # primitive

	match surf_type:
		1:  # Sweep along skeleton
			if positions.size() >= 2:
				if skel_type == 3:  # Star branches = individual tubes
					for i in range(0, positions.size() - 1, 2):
						var tube: Mesh = MorphoPrimitive.tube(positions[i], positions[i+1], radii[i], radii[i+1], surf_sides)
						if tube:
							var mi := MeshInstance3D.new()
							mi.mesh = tube
							content_root.add_child(mi)
					# Don't apply modifiers to individual branches (skip to populate)
					mesh = null
				else:
					mesh = MorphoPrimitive.multi_tube(positions, radii, surf_sides)
		2:  # Revolution (use radius as profile)
			var profile: Array = []
			for i in 8:
				var t: float = float(i) / 7.0
				profile.append(Vector2(surf_r * sin(t * PI), t * skel_len))
			mesh = MorphoPrimitive.revolution(profile, surf_sides)
		3:  # Marching cubes from field
			if field_func.is_valid():
				var bounds_size: float = p("field_strength", 1.0) * 2.0
				var bounds := AABB(Vector3(-1, -1, -1) * bounds_size, Vector3(2, 2, 2) * bounds_size)
				mesh = MorphoPrimitive.sdf_mesh(field_func, bounds, surf_res)
		4:  # Primitive sphere
			mesh = MorphoPrimitive.sphere(surf_r * 3.0, surf_sides, surf_sides / 2)

	# ── Stage 4: MODIFY ─────────────────────────────────────
	if mesh:
		if absf(p("mod_taper")) > 0.01:
			var amt: float = p("mod_taper")
			mesh = MorphoModifier.taper(mesh, Vector3.UP, func(t: float) -> float: return 1.0 - t * amt)
		if absf(p("mod_twist")) > 1.0:
			mesh = MorphoModifier.twist(mesh, Vector3.UP, p("mod_twist"))
		if p("mod_noise") > 0.005:
			var n := FastNoiseLite.new()
			n.frequency = 1.0
			mesh = MorphoModifier.noise_displace(mesh, n, p("mod_noise"))
		if p("mod_wave_freq") > 0.1 and p("mod_wave_amp") > 0.005:
			mesh = MorphoModifier.wave(mesh, Vector3.RIGHT, Vector3.UP, p("mod_wave_freq"), p("mod_wave_amp"))

	# ── Stage 5: POPULATE ───────────────────────────────────
	var pop_type: int = int(p("pop_type", 0))
	if mesh and pop_type > 0:
		var pop_count: int = int(p("pop_count", 6))
		var pop_r: float = p("pop_radius", 1.0)
		var transforms: Array = []
		match pop_type:
			1:  # Radial
				for i in pop_count:
					var angle: float = TAU * float(i) / float(pop_count)
					transforms.append(Transform3D(Basis.IDENTITY, Vector3(cos(angle) * pop_r, 0, sin(angle) * pop_r)))
			2:  # Grid
				var side: int = ceili(sqrt(float(pop_count)))
				var spacing: float = pop_r * 2.0 / float(side)
				for xi in side:
					for zi in side:
						if transforms.size() >= pop_count: break
						transforms.append(Transform3D(Basis.IDENTITY, Vector3((xi - side * 0.5) * spacing, 0, (zi - side * 0.5) * spacing)))
			3:  # Scatter (random in circle)
				for i in pop_count:
					var angle: float = randf() * TAU
					var r: float = randf() * pop_r
					transforms.append(Transform3D(Basis.IDENTITY.rotated(Vector3.UP, randf() * TAU), Vector3(cos(angle) * r, 0, sin(angle) * r)))

		var mmi := MorphoPrimitive.multimesh_scatter(mesh, transforms)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.7, 0.75, 0.8)
		mat.roughness = 0.4
		mat.metallic = 0.1
		mmi.material_override = mat
		content_root.add_child(mmi)
	elif mesh:
		# Single instance
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.7, 0.75, 0.8)
		mat.roughness = 0.4
		mat.metallic = 0.1
		mi.material_override = mat
		content_root.add_child(mi)

	# Info label: show active pipeline as → chain
	if info_label:
		var stages: PackedStringArray = []
		if field_type > 0: stages.append(["", "Noise", "SDF", "Metaball"][field_type])
		if skel_type > 0: stages.append(["", "Spine", "Spiral", "Star"][skel_type])
		stages.append(["Auto", "Sweep", "Revolution", "Marching", "Primitive"][clampi(surf_type, 0, 4)])
		if p("mod_taper") > 0.01 or absf(p("mod_twist")) > 1 or p("mod_noise") > 0.005:
			stages.append("Modified")
		if pop_type > 0: stages.append(["", "Radial", "Grid", "Scatter"][pop_type])
		info_label.text = "Pipeline: " + " → ".join(stages)
