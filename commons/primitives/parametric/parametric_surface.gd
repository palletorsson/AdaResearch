extends MeshInstance3D

@export_range(20, 200, 1) var u_resolution: int = 30
@export_range(20, 200, 1) var v_resolution: int = 30
@export_range(0.05, 2.0, 0.01) var surface_scale: float = 0.15
@export var auto_rotate: bool = true
@export var rotation_speed: float = 0.5

func _ready():
	generate_surface()
	_update_process_state()

func _notification(what):
	if what == Object.NOTIFICATION_EDITOR_PROPERTY_CHANGED:
		generate_surface()
		_update_process_state()

func _update_process_state():
	set_process(auto_rotate)

func _process(delta):
	if auto_rotate:
		rotation.y += rotation_speed * delta

func generate_surface():
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var columns := v_resolution + 1
	var rows := u_resolution + 1
	var u_max := TAU
	var v_max := TAU

	for i in range(rows):
		for j in range(columns):
			var u := i * u_max / float(u_resolution)
			var v := j * v_max / float(v_resolution)

			var x := cos(u) * (6.0 - 1.25 * sin(v - 3.0 * u))
			var y := (6.0 - 1.25 + sin(v - 3.0 * u)) * sin(u)
			var z := -cos(v - 3.0 * u) * (1.25 + sin(3.0 * v))

			st.set_uv(Vector2(i / float(u_resolution), j / float(v_resolution)))
			st.add_vertex(Vector3(x, y, z) * surface_scale)

	for i in range(u_resolution):
		for j in range(v_resolution):
			var current := i * (v_resolution + 1) + j
			var next := current + v_resolution + 1

			st.add_index(current)
			st.add_index(next)
			st.add_index(current + 1)

			st.add_index(current + 1)
			st.add_index(next)
			st.add_index(next + 1)

	st.generate_normals()
	st.generate_tangents()

	var generated_mesh := st.commit()
	if generated_mesh:
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(0.2, 0.6, 0.9)
		material.metallic = 0.4
		material.roughness = 0.2
		material.specular = 0.8
		generated_mesh.surface_set_material(0, material)
		mesh = generated_mesh

