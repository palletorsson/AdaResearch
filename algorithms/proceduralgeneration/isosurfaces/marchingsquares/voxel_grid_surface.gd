# voxel_grid_surface.gd - Manages surface mesh
extends MeshInstance3D

var vertices: PackedVector3Array = []
var triangles: PackedInt32Array = []
var corners_min: PackedInt32Array = []
var corners_max: PackedInt32Array = []
var x_edges_min: PackedInt32Array = []
var x_edges_max: PackedInt32Array = []
var y_edge_min: int = 0
var y_edge_max: int = 0

func initialize(resolution: int):
	mesh = ArrayMesh.new()
	corners_min = PackedInt32Array()
	corners_max = PackedInt32Array()
	x_edges_min = PackedInt32Array()
	x_edges_max = PackedInt32Array()
	
	corners_min.resize(resolution + 1)
	corners_max.resize(resolution + 1)
	x_edges_min.resize(resolution)
	x_edges_max.resize(resolution)

func clear():
	vertices.clear()
	triangles.clear()

func apply():
	if vertices.size() == 0:
		return
	
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = triangles
	
	mesh.clear_surfaces()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

func cache_first_corner(voxel: Voxel):
	corners_max[0] = vertices.size()
	vertices.append(Vector3(voxel.position.x, voxel.position.y, 0))

func cache_next_corner(i: int, voxel: Voxel):
	corners_max[i + 1] = vertices.size()
	vertices.append(Vector3(voxel.position.x, voxel.position.y, 0))

func cache_x_edge(i: int, voxel: Voxel):
	x_edges_max[i] = vertices.size()
	var p = voxel.get_x_edge_point()
	vertices.append(Vector3(p.x, p.y, 0))

func cache_y_edge(voxel: Voxel):
	y_edge_max = vertices.size()
	var p = voxel.get_y_edge_point()
	vertices.append(Vector3(p.x, p.y, 0))

func prepare_cache_for_next_cell():
	y_edge_min = y_edge_max

func prepare_cache_for_next_row():
	var swap = corners_min
	corners_min = corners_max
	corners_max = swap
	swap = x_edges_min
	x_edges_min = x_edges_max
	x_edges_max = swap

# Triangle/Quad/Pentagon/Hexagon methods
func add_triangle(a: int, b: int, c: int):
	triangles.append(a)
	triangles.append(b)
	triangles.append(c)

func add_quad(a: int, b: int, c: int, d: int):
	triangles.append(a)
	triangles.append(b)
	triangles.append(c)
	triangles.append(a)
	triangles.append(c)
	triangles.append(d)

func add_pentagon(a: int, b: int, c: int, d: int, e: int):
	triangles.append(a)
	triangles.append(b)
	triangles.append(c)
	triangles.append(a)
	triangles.append(c)
	triangles.append(d)
	triangles.append(a)
	triangles.append(d)
	triangles.append(e)

# Case-specific methods  
func add_triangle_a(i: int):
	add_triangle(corners_min[i], y_edge_min, x_edges_min[i])

func add_triangle_b(i: int):
	add_triangle(x_edges_min[i], corners_max[i], y_edge_max)

func add_triangle_c(i: int):
	add_triangle(y_edge_min, corners_min[i + 1], x_edges_max[i])

func add_triangle_d(i: int):
	add_triangle(x_edges_max[i], y_edge_max, corners_max[i + 1])

func add_quad_a(i: int):
	add_quad(corners_min[i], y_edge_min, y_edge_max, corners_max[i])

func add_quad_b(i: int):
	add_quad(x_edges_min[i], corners_max[i], corners_max[i + 1], x_edges_max[i])

func add_quad_c(i: int):
	add_quad(y_edge_min, corners_min[i + 1], corners_max[i + 1], y_edge_max)

func add_quad_d(i: int):
	add_quad(x_edges_min[i], corners_min[i], corners_min[i + 1], x_edges_max[i])

func add_quad_e(i: int):
	add_quad(corners_min[i], corners_min[i + 1], corners_max[i + 1], corners_max[i])

func add_pentagon_a(i: int):
	add_pentagon(corners_min[i], corners_min[i + 1], x_edges_max[i], y_edge_max, corners_max[i])

func add_pentagon_b(i: int):
	add_pentagon(x_edges_min[i], corners_max[i], corners_max[i + 1], y_edge_max, corners_min[i])

func add_pentagon_c(i: int):
	add_pentagon(y_edge_min, corners_min[i + 1], corners_max[i + 1], x_edges_max[i], corners_min[i])

func add_pentagon_d(i: int):
	add_pentagon(corners_max[i + 1], corners_max[i], y_edge_max, x_edges_min[i], corners_min[i + 1])
