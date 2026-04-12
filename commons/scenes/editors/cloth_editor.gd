# cloth_editor.gd — Pre-baked cloth drape from spring-mass physics
# Runs N verlet integration steps synchronously in _rebuild(),
# renders the final frozen form as ArrayMesh.
extends BaseGeometryEditor


func _get_editor_name() -> String:
	return "Cloth"


func _get_parameter_groups() -> Array:
	return [
		{"name": "Cloth", "params": [
			{"id": "resolution", "label": "Resolution", "min": 4.0, "max": 16.0, "step": 1.0, "default": 8.0},
			{"id": "size", "label": "Size", "min": 0.5, "max": 3.0, "step": 0.1, "default": 1.5},
		]},
		{"name": "Physics", "params": [
			{"id": "stiffness", "label": "Stiffness", "min": 10.0, "max": 500.0, "step": 5.0, "default": 100.0},
			{"id": "damping", "label": "Damping", "min": 0.5, "max": 20.0, "step": 0.5, "default": 5.0},
			{"id": "gravity", "label": "Gravity", "min": 0.0, "max": 15.0, "step": 0.1, "default": 9.8},
			{"id": "wind", "label": "Wind", "min": 0.0, "max": 8.0, "step": 0.1, "default": 1.5},
		]},
		{"name": "Simulation", "params": [
			{"id": "pin_mode", "label": "Pin Mode (0-2)", "min": 0.0, "max": 2.0, "step": 1.0, "default": 1.0},
			{"id": "sim_steps", "label": "Sim Steps", "min": 10.0, "max": 150.0, "step": 5.0, "default": 60.0},
		]},
	]


func _rebuild() -> void:
	_clear_content()

	var res: int = clampi(int(p("resolution", 8)), 4, 16)
	var size_val: float = p("size", 1.5)
	var stiffness_val: float = p("stiffness", 100.0)
	var damping_val: float = p("damping", 5.0)
	var gravity_val: float = p("gravity", 9.8)
	var wind_val: float = p("wind", 1.5)
	var pin_mode: int = clampi(int(p("pin_mode", 1)), 0, 2)
	var sim_steps: int = clampi(int(p("sim_steps", 60)), 10, 150)

	var spacing: float = size_val / float(res)
	var count: int = res + 1

	# ── 1. Create particle grid ──────────────────────────────
	var positions: Array[Vector3] = []
	var velocities: Array[Vector3] = []
	var pinned: Array[bool] = []
	positions.resize(count * count)
	velocities.resize(count * count)
	pinned.resize(count * count)

	for z in count:
		for x in count:
			var idx: int = z * count + x
			var px: float = float(x) * spacing - size_val * 0.5
			var pz: float = float(z) * spacing - size_val * 0.5
			positions[idx] = Vector3(px, 1.0, pz)
			velocities[idx] = Vector3.ZERO
			pinned[idx] = false

	# ── 2. Pin particles ─────────────────────────────────────
	if pin_mode == 0:
		# Corners
		pinned[0] = true
		pinned[res] = true
		pinned[res * count] = true
		pinned[res * count + res] = true
	elif pin_mode == 1:
		# Top row (z=0)
		for x in count:
			pinned[x] = true
	else:
		# Center point
		var center: int = (count / 2) * count + (count / 2)
		pinned[center] = true

	# ── 3. Create springs ────────────────────────────────────
	# Each spring: [idx_a, idx_b, rest_length]
	var springs: Array = []
	for z in count:
		for x in count:
			var idx: int = z * count + x
			# Cardinal neighbors
			if x < res:
				var neighbor: int = z * count + x + 1
				springs.append([idx, neighbor, positions[idx].distance_to(positions[neighbor])])
			if z < res:
				var neighbor: int = (z + 1) * count + x
				springs.append([idx, neighbor, positions[idx].distance_to(positions[neighbor])])
			# Diagonal neighbors
			if x < res and z < res:
				var neighbor: int = (z + 1) * count + x + 1
				springs.append([idx, neighbor, positions[idx].distance_to(positions[neighbor])])
			if x > 0 and z < res:
				var neighbor: int = (z + 1) * count + x - 1
				springs.append([idx, neighbor, positions[idx].distance_to(positions[neighbor])])

	# ── 4. Physics loop ──────────────────────────────────────
	var forces: Array[Vector3] = []
	forces.resize(count * count)

	for _step in sim_steps:
		# Reset forces
		for i in forces.size():
			forces[i] = Vector3.ZERO

		# Apply gravity and wind to unpinned particles
		for i in positions.size():
			if pinned[i]:
				continue
			forces[i] += Vector3(0.0, -gravity_val * 0.001, 0.0)
			forces[i] += Vector3(wind_val * 0.001, 0.0, 0.0)

		# Spring forces
		for spring: Array in springs:
			var a: int = spring[0] as int
			var b: int = spring[1] as int
			var rest: float = spring[2] as float
			var delta: Vector3 = positions[b] - positions[a]
			var dist: float = delta.length()
			if dist < 0.0001:
				continue
			var direction: Vector3 = delta / dist
			var force: Vector3 = stiffness_val * (dist - rest) * direction
			forces[a] += force
			forces[b] -= force

		# Integrate
		for i in positions.size():
			if pinned[i]:
				continue
			velocities[i] += forces[i]
			velocities[i] *= (1.0 - damping_val * 0.01)
			positions[i] += velocities[i] * 0.016

	# ── 5. Build mesh ────────────────────────────────────────
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	for z in res:
		for x in res:
			var i00: int = z * count + x
			var i10: int = z * count + x + 1
			var i01: int = (z + 1) * count + x
			var i11: int = (z + 1) * count + x + 1

			var p00: Vector3 = positions[i00]
			var p10: Vector3 = positions[i10]
			var p01: Vector3 = positions[i01]
			var p11: Vector3 = positions[i11]

			# UV coordinates
			var uv00 := Vector2(float(x) / float(res), float(z) / float(res))
			var uv10 := Vector2(float(x + 1) / float(res), float(z) / float(res))
			var uv01 := Vector2(float(x) / float(res), float(z + 1) / float(res))
			var uv11 := Vector2(float(x + 1) / float(res), float(z + 1) / float(res))

			# Triangle 1: 00, 10, 01
			var n1: Vector3 = (p10 - p00).cross(p01 - p00).normalized()
			if n1.length() < 0.001:
				n1 = Vector3.UP
			st.set_normal(n1)
			st.set_uv(uv00)
			st.add_vertex(p00)
			st.set_normal(n1)
			st.set_uv(uv10)
			st.add_vertex(p10)
			st.set_normal(n1)
			st.set_uv(uv01)
			st.add_vertex(p01)

			# Triangle 2: 10, 11, 01
			var n2: Vector3 = (p11 - p10).cross(p01 - p10).normalized()
			if n2.length() < 0.001:
				n2 = Vector3.UP
			st.set_normal(n2)
			st.set_uv(uv10)
			st.add_vertex(p10)
			st.set_normal(n2)
			st.set_uv(uv11)
			st.add_vertex(p11)
			st.set_normal(n2)
			st.set_uv(uv01)
			st.add_vertex(p01)

	var mesh: ArrayMesh = st.commit()

	# Material: warm fabric, double-sided, slight transparency
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.85, 0.55, 0.35, 0.92)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.roughness = 0.9
	mat.metallic = 0.0

	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	content_root.add_child(mi)

	var pin_names: Array[String] = ["corners", "top_edge", "center"]
	info_label.text = "Cloth %dx%d | pin=%s | %d steps" % [res, res, pin_names[pin_mode], sim_steps]
