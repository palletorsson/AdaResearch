class_name Line3D
extends MeshInstance3D

## 3D Line Renderer for Nature of Code examples
## Creates cylindrical lines between points with customizable appearance

enum TEXTURE_MODE {
	TEXTURE_MODE_NONE = 0,
	TEXTURE_MODE_TILE = 1,
	TEXTURE_MODE_STRETCH = 2
}

@export var width: float = 0.01:
	set(value):
		width = value
		if is_node_ready():
			_rebuild_mesh()

@export var default_color: Color = Color(1.0, 0.7, 0.9, 1.0):
	set(value):
		default_color = value
		if material_override and material_override is StandardMaterial3D:
			material_override.albedo_color = value

@export var texture_mode: TEXTURE_MODE = TEXTURE_MODE.TEXTURE_MODE_NONE

var _points: Array[Vector3] = []
var _immediate_mesh: ImmediateMesh
var _rebuild_queued: bool = false

func _ready() -> void:
	_immediate_mesh = ImmediateMesh.new()
	mesh = _immediate_mesh
	set_process(true)

	if not material_override:
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = default_color
		mat.vertex_color_use_as_albedo = true
		material_override = mat

func _process(_delta: float) -> void:
	if _rebuild_queued:
		_rebuild_mesh_immediate()
		_rebuild_queued = false

func add_point(point: Vector3) -> void:
	_points.append(point)
	_queue_rebuild()

func remove_point(index: int) -> void:
	if index >= 0 and index < _points.size():
		_points.remove_at(index)
		_queue_rebuild()

func clear_points() -> void:
	_points.clear()
	_queue_rebuild()

func _queue_rebuild() -> void:
	_rebuild_queued = true

func _rebuild_mesh() -> void:
	_rebuild_mesh_immediate()

func get_point_count() -> int:
	return _points.size()

func get_point(index: int) -> Vector3:
	if index >= 0 and index < _points.size():
		return _points[index]
	return Vector3.ZERO

func set_point_position(index: int, position: Vector3) -> void:
	if index >= 0 and index < _points.size():
		_points[index] = position
		_queue_rebuild()

func _rebuild_mesh_immediate() -> void:
	if not _immediate_mesh:
		return

	_immediate_mesh.clear_surfaces()

	if _points.size() < 2:
		return

	_immediate_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	# Draw line segments between consecutive points
	for i in range(_points.size() - 1):
		_draw_line_segment(_points[i], _points[i + 1])

	_immediate_mesh.surface_end()

func _draw_line_segment(from: Vector3, to: Vector3) -> void:
	# Create a cylindrical line segment between two points
	var direction := (to - from).normalized()
	var length := from.distance_to(to)

	if length < 0.0001:
		return

	# Find perpendicular vectors
	var up := Vector3.UP
	if abs(direction.dot(up)) > 0.99:
		up = Vector3.RIGHT

	var right := direction.cross(up).normalized() * (width * 0.5)
	var forward := direction.cross(right).normalized() * (width * 0.5)

	# Create quad between points
	var p1 := from + right + forward
	var p2 := from + right - forward
	var p3 := from - right - forward
	var p4 := from - right + forward

	var p5 := to + right + forward
	var p6 := to + right - forward
	var p7 := to - right - forward
	var p8 := to - right + forward

	# Side 1
	_add_quad(p1, p2, p6, p5)
	# Side 2
	_add_quad(p2, p3, p7, p6)
	# Side 3
	_add_quad(p3, p4, p8, p7)
	# Side 4
	_add_quad(p4, p1, p5, p8)

func _add_quad(p1: Vector3, p2: Vector3, p3: Vector3, p4: Vector3) -> void:
	var color := default_color

	# First triangle
	_immediate_mesh.surface_set_color(color)
	_immediate_mesh.surface_add_vertex(p1)
	_immediate_mesh.surface_set_color(color)
	_immediate_mesh.surface_add_vertex(p2)
	_immediate_mesh.surface_set_color(color)
	_immediate_mesh.surface_add_vertex(p3)

	# Second triangle
	_immediate_mesh.surface_set_color(color)
	_immediate_mesh.surface_add_vertex(p1)
	_immediate_mesh.surface_set_color(color)
	_immediate_mesh.surface_add_vertex(p3)
	_immediate_mesh.surface_set_color(color)
	_immediate_mesh.surface_add_vertex(p4)
