@tool
extends XRToolsPickable

## Grabbable pyramid for assembly line puzzle

@export var pyramid_color: Color = Color(1.0, 0.8, 0.2)
@export var pyramid_height: float = 0.1
@export var base_size: float = 0.1

var _mesh_instance: MeshInstance3D

func _ready() -> void:
	super()
	_create_pyramid_mesh()

	if not Engine.is_editor_hint():
		set_process(true)

func _create_pyramid_mesh() -> void:
	if _mesh_instance:
		_mesh_instance.queue_free()

	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.name = "MeshInstance3D"
	_mesh_instance.mesh = _build_pyramid_array_mesh()

	var mat = StandardMaterial3D.new()
	mat.albedo_color = pyramid_color
	mat.emission_enabled = true
	mat.emission = pyramid_color
	mat.emission_energy_multiplier = 0.3
	_mesh_instance.material_override = mat

	add_child(_mesh_instance)

func _build_pyramid_array_mesh() -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var half = base_size * 0.5
	var h = pyramid_height

	# Base vertices
	var v0 = Vector3(-half, 0, -half)
	var v1 = Vector3(half, 0, -half)
	var v2 = Vector3(half, 0, half)
	var v3 = Vector3(-half, 0, half)
	var apex = Vector3(0, h, 0)

	# Base (two triangles)
	st.add_vertex(v0)
	st.add_vertex(v2)
	st.add_vertex(v1)

	st.add_vertex(v0)
	st.add_vertex(v3)
	st.add_vertex(v2)

	# Side faces
	st.add_vertex(v0)
	st.add_vertex(v1)
	st.add_vertex(apex)

	st.add_vertex(v1)
	st.add_vertex(v2)
	st.add_vertex(apex)

	st.add_vertex(v2)
	st.add_vertex(v3)
	st.add_vertex(apex)

	st.add_vertex(v3)
	st.add_vertex(v0)
	st.add_vertex(apex)

	st.generate_normals()
	return st.commit()

func set_pyramid_color(color: Color) -> void:
	pyramid_color = color
	if _mesh_instance and _mesh_instance.material_override:
		_mesh_instance.material_override.albedo_color = color
		_mesh_instance.material_override.emission = color
