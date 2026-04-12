# reaction_diffusion_editor.gd — Gray-Scott reaction-diffusion heightfield
# Runs the Gray-Scott system on a 2D grid, then extrudes as a colored heightfield mesh.
extends BaseGeometryEditor

# Presets: [name, feed, kill]
const PRESETS: Array[Array] = [
	["Coral",   0.055, 0.062],
	["Mitosis", 0.0367, 0.0649],
	["Fingers", 0.037, 0.06],
	["Spots",   0.025, 0.05],
	["Waves",   0.018, 0.051],
	["Maze",    0.029, 0.057],
	["Bubbles", 0.012, 0.047],
	["Worms",   0.078, 0.061],
]


func _get_editor_name() -> String:
	return "Reaction Diffusion"


func _get_parameter_groups() -> Array:
	return [
		{"name": "Preset", "params": [
			{"id": "preset", "label": "Preset", "options": ["Coral", "Mitosis", "Fingers", "Spots", "Waves", "Maze", "Bubbles", "Worms"], "default": 2.0},
		]},
		{"name": "Rates", "params": [
			{"id": "feed_rate", "label": "Feed Rate", "min": 0.01, "max": 0.08, "step": 0.001, "default": 0.037},
			{"id": "kill_rate", "label": "Kill Rate", "min": 0.04, "max": 0.07, "step": 0.001, "default": 0.06},
		]},
		{"name": "Simulation", "params": [
			{"id": "grid_size", "label": "Grid Size", "min": 16.0, "max": 64.0, "step": 2.0, "default": 48.0},
			{"id": "steps", "label": "Steps", "min": 50.0, "max": 1000.0, "step": 10.0, "default": 300.0},
		]},
		{"name": "Display", "params": [
			{"id": "height_scale", "label": "Height Scale", "min": 0.0, "max": 1.0, "step": 0.05, "default": 0.3},
		]},
	]


func _on_param_changed(value: float, param_id: String) -> void:
	super._on_param_changed(value, param_id)
	# When preset changes, sync feed/kill sliders
	if param_id == "preset":
		var preset_idx: int = clampi(int(value), 0, PRESETS.size() - 1)
		var preset_data: Array = PRESETS[preset_idx]
		_params["feed_rate"] = preset_data[1] as float
		_params["kill_rate"] = preset_data[2] as float
		_sync_sliders_to_params()


func _rebuild() -> void:
	_clear_content()

	var preset_idx: int = clampi(int(p("preset", 2)), 0, PRESETS.size() - 1)
	var feed: float = p("feed_rate", 0.037)
	var kill: float = p("kill_rate", 0.06)
	var grid_size: int = clampi(int(p("grid_size", 48)), 16, 64)
	var steps: int = clampi(int(p("steps", 300)), 50, 1000)
	var height_scale: float = p("height_scale", 0.3)

	# Diffusion rates
	var du: float = 0.21
	var dv: float = 0.105
	var dt: float = 1.0

	# ── 1. Initialize grids ──────────────────────────────────
	var u_grid: Array[float] = []
	var v_grid: Array[float] = []
	u_grid.resize(grid_size * grid_size)
	v_grid.resize(grid_size * grid_size)

	for i in u_grid.size():
		u_grid[i] = 1.0
		v_grid[i] = 0.0

	# Seed center 5x5 patch with V=1.0
	var cx: int = grid_size / 2
	var cz: int = grid_size / 2
	for dz in range(-2, 3):
		for dx in range(-2, 3):
			var sx: int = cx + dx
			var sz: int = cz + dz
			if sx >= 0 and sx < grid_size and sz >= 0 and sz < grid_size:
				v_grid[sz * grid_size + sx] = 1.0

	# ── 2. Simulation ────────────────────────────────────────
	var new_u: Array[float] = []
	var new_v: Array[float] = []
	new_u.resize(grid_size * grid_size)
	new_v.resize(grid_size * grid_size)

	for _step in steps:
		for z in grid_size:
			for x in grid_size:
				var idx: int = z * grid_size + x

				# Neighbors with wrapping
				var xl: int = (x - 1 + grid_size) % grid_size
				var xr: int = (x + 1) % grid_size
				var zu: int = (z - 1 + grid_size) % grid_size
				var zd: int = (z + 1) % grid_size

				var u_val: float = u_grid[idx]
				var v_val: float = v_grid[idx]

				var lap_u: float = (
					u_grid[z * grid_size + xl] +
					u_grid[z * grid_size + xr] +
					u_grid[zu * grid_size + x] +
					u_grid[zd * grid_size + x] -
					4.0 * u_val
				)
				var lap_v: float = (
					v_grid[z * grid_size + xl] +
					v_grid[z * grid_size + xr] +
					v_grid[zu * grid_size + x] +
					v_grid[zd * grid_size + x] -
					4.0 * v_val
				)

				var reaction: float = u_val * v_val * v_val
				new_u[idx] = u_val + (du * lap_u - reaction + feed * (1.0 - u_val)) * dt
				new_v[idx] = v_val + (dv * lap_v + reaction - (feed + kill) * v_val) * dt

		# Swap buffers
		for i in u_grid.size():
			u_grid[i] = clampf(new_u[i], 0.0, 1.0)
			v_grid[i] = clampf(new_v[i], 0.0, 1.0)

	# ── 3. Build heightfield mesh ────────────────────────────
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var mesh_scale: float = 1.5 / float(grid_size)
	var half_extent: float = float(grid_size) * mesh_scale * 0.5

	# Color gradient: dark blue (V=0) → bright yellow (V=1)
	var color_low := Color(0.08, 0.1, 0.35)
	var color_high := Color(1.0, 0.92, 0.2)

	for z in range(grid_size - 1):
		for x in range(grid_size - 1):
			var i00: int = z * grid_size + x
			var i10: int = z * grid_size + x + 1
			var i01: int = (z + 1) * grid_size + x
			var i11: int = (z + 1) * grid_size + x + 1

			var v00: float = v_grid[i00]
			var v10: float = v_grid[i10]
			var v01: float = v_grid[i01]
			var v11: float = v_grid[i11]

			var p00 := Vector3(float(x) * mesh_scale - half_extent, v00 * height_scale, float(z) * mesh_scale - half_extent)
			var p10 := Vector3(float(x + 1) * mesh_scale - half_extent, v10 * height_scale, float(z) * mesh_scale - half_extent)
			var p01 := Vector3(float(x) * mesh_scale - half_extent, v01 * height_scale, float(z + 1) * mesh_scale - half_extent)
			var p11 := Vector3(float(x + 1) * mesh_scale - half_extent, v11 * height_scale, float(z + 1) * mesh_scale - half_extent)

			var c00: Color = color_low.lerp(color_high, v00)
			var c10: Color = color_low.lerp(color_high, v10)
			var c01: Color = color_low.lerp(color_high, v01)
			var c11: Color = color_low.lerp(color_high, v11)

			# Triangle 1: 00, 10, 01
			var n1: Vector3 = (p10 - p00).cross(p01 - p00).normalized()
			if n1.length_squared() < 0.0001:
				n1 = Vector3.UP
			st.set_normal(n1)
			st.set_color(c00)
			st.add_vertex(p00)
			st.set_normal(n1)
			st.set_color(c10)
			st.add_vertex(p10)
			st.set_normal(n1)
			st.set_color(c01)
			st.add_vertex(p01)

			# Triangle 2: 10, 11, 01
			var n2: Vector3 = (p11 - p10).cross(p01 - p10).normalized()
			if n2.length_squared() < 0.0001:
				n2 = Vector3.UP
			st.set_normal(n2)
			st.set_color(c10)
			st.add_vertex(p10)
			st.set_normal(n2)
			st.set_color(c11)
			st.add_vertex(p11)
			st.set_normal(n2)
			st.set_color(c01)
			st.add_vertex(p01)

	var mesh: ArrayMesh = st.commit()

	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.7
	mat.metallic = 0.15

	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	content_root.add_child(mi)

	var preset_name: String = PRESETS[preset_idx][0] as String
	info_label.text = "%s | f=%.4f k=%.4f | %dx%d | %d steps" % [
		preset_name, feed, kill, grid_size, grid_size, steps
	]
