# Headless test: load nature_layer.json and render the flora MultiMeshes
# Run: godot --path . --xr-mode off --no-window --script res://commons/testing/capture_flora_test.gd

extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var root_node := Node3D.new()
	root_node.name = "FloraTest"
	root.add_child(root_node)

	# Environment
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.06, 0.07, 0.1)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.5, 0.52, 0.58)
	env.ambient_light_energy = 0.8
	var we := WorldEnvironment.new()
	we.environment = env
	root_node.add_child(we)

	# Lights — strong key + fill for ground visibility
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, -30, 0)
	light.light_energy = 1.5
	light.light_color = Color(1.0, 0.98, 0.95)
	root_node.add_child(light)

	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-30, 150, 0)
	fill.light_energy = 0.6
	fill.light_color = Color(0.8, 0.85, 1.0)
	root_node.add_child(fill)

	# Camera
	var camera := Camera3D.new()
	camera.position = Vector3(7, 12, 8)
	camera.look_at(Vector3(7, 0, 8), Vector3.UP)
	camera.current = true
	camera.fov = 55
	root_node.add_child(camera)

	# Load nature_layer.json first (needed for ground mesh)
	var path := "res://commons/maps/Folding_Zoo/nature_layer.json"
	if not FileAccess.file_exists(path):
		print("No nature_layer.json found at %s" % path)
		quit(1)
		return

	var file := FileAccess.open(path, FileAccess.READ)
	var json := JSON.new()
	json.parse(file.get_as_text())
	file.close()
	var nature_data: Dictionary = json.data
	var layers: Dictionary = nature_data.get("layers", {})

	print("Loaded nature_layer.json: %d layers" % layers.size())

	# Build solid ground mesh from the ground + water layers
	var ground_mesh := _build_ground_mesh(layers, 14, 16)
	root_node.add_child(ground_mesh)

	# Flora type configs (simplified from FloraSpawner)
	var TYPES := {
		# Ground cover is now vertex-colored on the ground mesh — skip as MultiMesh
		"flowers": { "color": Color(0.9, 0.4, 0.6), "scale": 0.15, "y": 0.15, "mesh": "sphere" },
		"ferns": { "color": Color(0.2, 0.55, 0.2), "scale": 0.2, "y": 0.2, "mesh": "plane" },
		"mushrooms": { "color": Color(0.6, 0.35, 0.7), "scale": 0.12, "y": 0.1, "mesh": "sphere" },
		"reeds": { "color": Color(0.45, 0.55, 0.3), "scale": 0.06, "y": 0.35, "mesh": "box" },
		"tree": { "color": Color(0.2, 0.45, 0.15), "scale": 0.25, "y": 0.5, "mesh": "cylinder" },
		"bush": { "color": Color(0.25, 0.5, 0.2), "scale": 0.25, "y": 0.2, "mesh": "sphere" },
		"vine": { "color": Color(0.3, 0.5, 0.25), "scale": 0.05, "y": 0.3, "mesh": "box" },
		# Water is vertex-colored on the ground mesh — skip as MultiMesh
		"walker": { "color": Color(0.8, 0.6, 0.2), "scale": 0.1, "y": 0.15, "mesh": "sphere" },
		"flyer": { "color": Color(0.3, 0.6, 0.9), "scale": 0.08, "y": 0.5, "mesh": "sphere" },
		"crawler": { "color": Color(0.8, 0.3, 0.3), "scale": 0.08, "y": 0.08, "mesh": "sphere" },
	}

	# Collect instances per type
	var instances: Dictionary = {}
	for layer_name in layers:
		var grid: Array = layers[layer_name]
		for row_idx in grid.size():
			var row: Array = grid[row_idx]
			for col_idx in row.size():
				var cell: Dictionary = row[col_idx]
				var flora_type: String = cell.get("type", "none")
				var intensity: float = float(cell.get("intensity", 0))
				if flora_type == "none" or intensity < 0.05:
					continue
				if not instances.has(flora_type):
					instances[flora_type] = []
				instances[flora_type].append({
					"row": row_idx, "col": col_idx, "intensity": intensity
				})

	# Build MultiMeshes
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var total_instances := 0

	for flora_type in instances:
		var placements: Array = instances[flora_type]
		var config: Dictionary = TYPES.get(flora_type, {})
		if config.is_empty():
			continue

		var mesh: Mesh
		match config.get("mesh", "sphere"):
			"sphere":
				var s := SphereMesh.new()
				s.radius = 0.5; s.height = 1.0; s.radial_segments = 6; s.rings = 3
				mesh = s
			"box":
				mesh = BoxMesh.new()
			"plane":
				mesh = PlaneMesh.new()
			"cylinder":
				var c := CylinderMesh.new()
				c.top_radius = 0.3; c.bottom_radius = 0.1; c.height = 1.0; c.radial_segments = 5
				mesh = c
			_:
				mesh = SphereMesh.new()

		var mat := StandardMaterial3D.new()
		var color: Color = config.get("color", Color.WHITE)
		mat.albedo_color = color
		mat.roughness = 0.8
		if color.a < 1.0:
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.emission_enabled = true
		mat.emission = color * 0.15
		mat.emission_energy_multiplier = 0.4
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED

		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = mesh
		mm.instance_count = placements.size()

		var base_scale: float = config.get("scale", 0.1)
		var y_offset: float = config.get("y", 0.1)

		for i in placements.size():
			var p: Dictionary = placements[i]
			var x: float = float(p["col"]) + 0.5 + rng.randf_range(-0.2, 0.2)
			var z: float = float(p["row"]) + 0.5 + rng.randf_range(-0.2, 0.2)
			var y: float = y_offset
			var scale: float = base_scale * float(p["intensity"])

			var t := Transform3D.IDENTITY
			t = t.scaled(Vector3(scale, scale, scale))
			t = t.rotated(Vector3.UP, rng.randf() * TAU)
			t.origin = Vector3(x, y, z)
			mm.set_instance_transform(i, t)
			mm.set_instance_color(i, Color(
				color.r + rng.randf_range(-0.05, 0.05),
				color.g + rng.randf_range(-0.05, 0.05),
				color.b + rng.randf_range(-0.05, 0.05),
				color.a
			))

		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.material_override = mat
		mmi.name = "Flora_%s" % flora_type
		root_node.add_child(mmi)
		total_instances += placements.size()
		print("  %s: %d instances" % [flora_type, placements.size()])

	print("Total: %d flora instances across %d types" % [total_instances, instances.size()])

	# Wait for GPU to render frames
	print("Waiting for render...")


var _frame_count: int = 0

func _process(_delta: float) -> bool:
	_frame_count += 1
	if _frame_count == 60:
		var image := root.get_viewport().get_texture().get_image()
		image.save_png("user://artifact_shots/flora_landscape.png")
		print("Saved flora_landscape.png")
		quit(0)
	return false


func _build_ground_mesh(layers: Dictionary, w: int, d: int) -> MeshInstance3D:
	## Build one continuous ground mesh. Each vertex colored by biome type.
	## Slight height variation from noise. Water cells are lower and blue.
	var ground_grid: Array = layers.get("ground", [])
	var water_grid: Array = layers.get("water", [])

	var GROUND_COLORS := {
		"none": Color(0.18, 0.2, 0.25),
		"grass": Color(0.3, 0.6, 0.2),
		"moss": Color(0.2, 0.45, 0.15),
		"sand": Color(0.8, 0.7, 0.45),
		"stone": Color(0.55, 0.55, 0.55),
		"soil": Color(0.45, 0.3, 0.18),
	}
	var WATER_COLORS := {
		"puddle": Color(0.2, 0.4, 0.7),
		"stream": Color(0.15, 0.35, 0.75),
		"pond": Color(0.1, 0.3, 0.7),
	}

	var rng := RandomNumberGenerator.new()
	rng.seed = 12345

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Generate vertices in a grid, one per corner of each cell
	# (w+1) x (d+1) vertices
	var vertex_colors: Array = []
	var vertex_heights: Array = []

	for row in (d + 1):
		for col in (w + 1):
			# Sample nearest cell (clamp to grid bounds)
			var cr := mini(row, d - 1)
			var cc := mini(col, w - 1)

			# Get ground color
			var color := Color(0.12, 0.14, 0.18)
			var height: float = 0.0

			if cr < ground_grid.size() and cc < ground_grid[cr].size():
				var cell: Dictionary = ground_grid[cr][cc]
				var gtype: String = cell.get("type", "none")
				var intensity: float = float(cell.get("intensity", 0))
				var base_color: Color = GROUND_COLORS.get(gtype, GROUND_COLORS["none"])
				color = GROUND_COLORS["none"].lerp(base_color, intensity)

				# Stone is slightly higher
				if gtype == "stone":
					height = intensity * 0.15

			# Check water — overrides ground color, lowers height
			if cr < water_grid.size() and cc < water_grid[cr].size():
				var wcell: Dictionary = water_grid[cr][cc]
				var wtype: String = wcell.get("type", "none")
				var winternsity: float = float(wcell.get("intensity", 0))
				if wtype != "none" and winternsity > 0.05:
					var wcolor: Color = WATER_COLORS.get(wtype, Color(0.1, 0.2, 0.5))
					color = color.lerp(wcolor, winternsity * 0.8)
					height = -winternsity * 0.08  # Water is lower

			# Slight noise variation
			height += rng.randf_range(-0.02, 0.02)

			vertex_colors.append(color)
			vertex_heights.append(height)

	# Build triangles
	for row in d:
		for col in w:
			var i00 := row * (w + 1) + col
			var i10 := i00 + 1
			var i01 := (row + 1) * (w + 1) + col
			var i11 := i01 + 1

			var v00 := Vector3(float(col), vertex_heights[i00], float(row))
			var v10 := Vector3(float(col + 1), vertex_heights[i10], float(row))
			var v01 := Vector3(float(col), vertex_heights[i01], float(row + 1))
			var v11 := Vector3(float(col + 1), vertex_heights[i11], float(row + 1))

			# Triangle 1
			st.set_color(vertex_colors[i00]); st.set_normal(Vector3.UP); st.add_vertex(v00)
			st.set_color(vertex_colors[i01]); st.set_normal(Vector3.UP); st.add_vertex(v01)
			st.set_color(vertex_colors[i10]); st.set_normal(Vector3.UP); st.add_vertex(v10)
			# Triangle 2
			st.set_color(vertex_colors[i10]); st.set_normal(Vector3.UP); st.add_vertex(v10)
			st.set_color(vertex_colors[i01]); st.set_normal(Vector3.UP); st.add_vertex(v01)
			st.set_color(vertex_colors[i11]); st.set_normal(Vector3.UP); st.add_vertex(v11)

	st.generate_normals()

	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.name = "GroundMesh"

	# Unshaded material — vertex colors visible regardless of lighting
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mi.material_override = mat

	print("Ground mesh: %d x %d = %d cells" % [w, d, w * d])
	return mi


