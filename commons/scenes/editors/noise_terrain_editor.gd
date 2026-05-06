# noise_terrain_editor.gd — Terrain from noise displacement
#
# Generates a subdivided plane mesh and displaces vertices using
# FastNoiseLite Perlin noise. Camera starts high for overview.

extends BaseGeometryEditor

func _get_editor_name() -> String: return "Noise Terrain"

func _get_parameter_groups() -> Array:
	return [
		{"name": "Terrain", "params": [
			{"id": "resolution", "label": "Resolution", "min": 8.0, "max": 64.0, "step": 4.0, "default": 32.0},
			{"id": "size", "label": "Size", "min": 1.0, "max": 8.0, "step": 0.5, "default": 4.0},
			{"id": "height", "label": "Height", "min": 0.1, "max": 3.0, "step": 0.1, "default": 0.8},
		]},
		{"name": "Noise", "params": [
			{"id": "frequency", "label": "Frequency", "min": 0.01, "max": 0.3, "step": 0.01, "default": 0.05},
			{"id": "octaves", "label": "Octaves", "min": 1.0, "max": 8.0, "step": 1.0, "default": 4.0},
			{"id": "seed", "label": "Seed", "min": 0.0, "max": 9999.0, "step": 1.0, "default": 42.0},
		]},
	]

func _create_initial_geometry() -> void:
	orbit_pitch = 1.0
	orbit_dist = 5.0
	_set_defaults()
	_rebuild()

func _rebuild() -> void:
	_clear_content()
	var res: int = int(p("resolution", 32))
	var size: float = p("size", 4.0)
	var height: float = p("height", 0.8)

	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = p("frequency", 0.05)
	noise.fractal_octaves = int(p("octaves", 4))
	noise.seed = int(p("seed", 42))

	# Build plane
	var plane := PlaneMesh.new()
	plane.size = Vector2(size, size)
	plane.subdivide_width = res
	plane.subdivide_depth = res

	# Displace vertices
	var st := SurfaceTool.new()
	st.create_from(plane, 0)
	var array_mesh: ArrayMesh = st.commit()
	var mdt := MeshDataTool.new()
	if mdt.create_from_surface(array_mesh, 0) != OK:
		return
	for vi in mdt.get_vertex_count():
		var v: Vector3 = mdt.get_vertex(vi)
		v.y += noise.get_noise_2d(v.x * 10.0, v.z * 10.0) * height
		mdt.set_vertex(vi, v)
	var result := ArrayMesh.new()
	mdt.commit_to_surface(result)
	st = SurfaceTool.new()
	st.create_from(result, 0)
	st.generate_normals()
	result = st.commit()

	var mi := MeshInstance3D.new()
	mi.mesh = result
	mi.position = Vector3(0, -0.5, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.35, 0.55, 0.25)
	mat.roughness = 0.9
	mi.material_override = mat
	content_root.add_child(mi)

	if info_label:
		info_label.text = "Terrain | %dx%d verts | h=%.1f" % [res, res, height]
