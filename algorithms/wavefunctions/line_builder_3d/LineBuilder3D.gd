extends Node3D

@export var point_scene: PackedScene
@export var line_material: ShaderMaterial
@export var point_count: int = 10
@export var point_spacing: float = 1.0

var points: Array[Node3D] = []
var mesh_instance: MeshInstance3D

func _ready() -> void:
	mesh_instance = $LineMesh
	_spawn_points()
	_update_line()

func _process(_delta):
	_update_line()  # dynamically rebuild as points move

func _spawn_points() -> void:
	var parent = $Points
	for i in range(point_count):
		var p = point_scene.instantiate()
		p.position = Vector3(i * point_spacing, 0, 0)
		parent.add_child(p)
		points.append(p)

func _update_line() -> void:
	if points.size() < 2:
		return

	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	st.set_material(line_material)

	for i in range(points.size()):
		var pos = points[i].global_position
		var uv_x = float(i) / float(points.size() - 1)
		st.set_uv(Vector2(uv_x, 0.0))
		st.add_vertex(pos + Vector3(0, 0.05, 0))  # top edge

		st.set_uv(Vector2(uv_x, 1.0))
		st.add_vertex(pos - Vector3(0, 0.05, 0))  # bottom edge

	var mesh = st.commit()
	mesh_instance.mesh = mesh

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

