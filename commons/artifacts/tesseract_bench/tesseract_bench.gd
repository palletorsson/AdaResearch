extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name TesseractBench

## @identity
## name: Tesseract Bench
## tier: medium
## concept: Higher-dimensional generation
## truth: a shadow of a cube cast from a space you can't stand in.

@export var bench_top_y: float = 0.85
@export var view_w: float = 3.0           # 4D camera distance for perspective projection
@export var size_scale: float = 0.55      # overall size of the projected tesseract
@export var spin_speed: float = 0.5       # radians/sec in the x-w plane

var _vertices_4d: Array[Vector4] = []
var _edges: Array = []                    # Array[Vector2i] vertex index pairs
var _edge_meshes: Array[MeshInstance3D] = []
var _vertex_nodes: Array[MeshInstance3D] = []
var _hub: Node3D = null
var _angle: float = 0.0
var _inner_mat: StandardMaterial3D = null
var _outer_mat: StandardMaterial3D = null
var _vert_mat: StandardMaterial3D = null


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()


func _build() -> void:
	_vertices_4d.clear()
	_edges.clear()
	_edge_meshes.clear()
	_vertex_nodes.clear()
	_angle = 0.0

	# Bench base
	var base_mat := _steel_mat(Color(0.14, 0.15, 0.2))
	add_child(_box(Vector3(0.0, bench_top_y * 0.5, 0.0), Vector3(1.1, bench_top_y, 1.1), base_mat))

	# Label
	add_child(_billboard_label("TESSERACT", Vector3(0.0, bench_top_y + 1.05, 0.0), 22, Color(0.85, 0.85, 1.0)))

	# 16 vertices (±1)^4
	for ix in range(2):
		for iy in range(2):
			for iz in range(2):
				for iw in range(2):
					var x: float = -1.0 if ix == 0 else 1.0
					var y: float = -1.0 if iy == 0 else 1.0
					var z: float = -1.0 if iz == 0 else 1.0
					var w: float = -1.0 if iw == 0 else 1.0
					_vertices_4d.append(Vector4(x, y, z, w))

	# 32 edges: vertex pairs differing in exactly one coordinate
	for i in range(_vertices_4d.size()):
		for j in range(i + 1, _vertices_4d.size()):
			if _hamming4(_vertices_4d[i], _vertices_4d[j]) == 1:
				_edges.append(Vector2i(i, j))

	# Materials: inner cube (w<0) brighter, outer cube dimmer
	_inner_mat = _glow_mat(Color(0.6, 0.9, 1.0), 2.0)
	_outer_mat = _glow_mat(Color(0.35, 0.45, 0.7), 0.8)
	_vert_mat = _glow_mat(Color(1.0, 1.0, 1.0), 2.2)

	# Hub holds the projected tesseract, floating above the bench
	_hub = Node3D.new()
	_hub.name = "TesseractHub"
	_hub.position = Vector3(0.0, bench_top_y + 0.55, 0.0)
	add_child(_hub)

	# Vertex spheres
	for i in range(_vertices_4d.size()):
		var node: MeshInstance3D = _sphere(Vector3.ZERO, 0.018, _vert_mat)
		_hub.add_child(node)
		_vertex_nodes.append(node)

	# Edge cylinders (start with placeholder; positions set each frame)
	for e in _edges:
		var pair: Vector2i = e
		var inner: bool = (_vertices_4d[pair.x].w < 0.0 and _vertices_4d[pair.y].w < 0.0)
		var mat: StandardMaterial3D = _inner_mat if inner else _outer_mat
		var seg: MeshInstance3D = _cylinder_between(Vector3(-0.01, 0, 0), Vector3(0.01, 0, 0), 0.006, mat)
		_hub.add_child(seg)
		_edge_meshes.append(seg)

	_update_projection()


func _hamming4(a: Vector4, b: Vector4) -> int:
	var d: int = 0
	if not is_equal_approx(a.x, b.x):
		d += 1
	if not is_equal_approx(a.y, b.y):
		d += 1
	if not is_equal_approx(a.z, b.z):
		d += 1
	if not is_equal_approx(a.w, b.w):
		d += 1
	return d


func _project(v4: Vector4) -> Vector3:
	# rotate in the x-w plane
	var ca: float = cos(_angle)
	var sa: float = sin(_angle)
	var x: float = v4.x * ca - v4.w * sa
	var w: float = v4.x * sa + v4.w * ca
	# perspective project 4D -> 3D
	var denom: float = view_w - w
	if absf(denom) < 0.001:
		denom = 0.001
	var k: float = 1.0 / denom
	return Vector3(x * k, v4.y * k, v4.z * k) * size_scale * view_w


func _update_projection() -> void:
	# update vertex positions
	var projected: Array[Vector3] = []
	for i in range(_vertices_4d.size()):
		var p: Vector3 = _project(_vertices_4d[i])
		projected.append(p)
		if i < _vertex_nodes.size():
			_vertex_nodes[i].position = p
	# update edges
	for ei in range(_edges.size()):
		var pair: Vector2i = _edges[ei]
		var a: Vector3 = projected[pair.x]
		var b: Vector3 = projected[pair.y]
		var seg: MeshInstance3D = _edge_meshes[ei]
		var mesh := seg.mesh as CylinderMesh
		if mesh != null:
			mesh.height = maxf(a.distance_to(b), 0.001)
		seg.transform = Transform3D(_basis_y_to(b - a), (a + b) * 0.5)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_angle += spin_speed * delta
	_update_projection()
