
# Mesh generation utilities
class_name OrganicMeshGenerator
extends Node

func _ready():
	print("Organic mesh generator initialized")

func generate_organic_surface(size: Vector3, complexity: int) -> ArrayMesh:
	"""Generate organic surface using procedural techniques"""
	# This would integrate with your existing marching cubes system
	# from algorithms/spacetopology/marchingcubes/
	
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var uvs = PackedVector2Array()
	var indices = PackedInt32Array()
	
	# Generate vertices using noise
	var noise = FastNoiseLite.new()
	noise.frequency = 0.1
	
	for i in range(complexity):
		for j in range(complexity):
			var x = (float(i) / complexity - 0.5) * size.x
			var z = (float(j) / complexity - 0.5) * size.z
			var y = noise.get_noise_2d(x, z) * size.y * 0.2
			
			vertices.append(Vector3(x, y, z))
			normals.append(Vector3.UP)
			uvs.append(Vector2(float(i) / complexity, float(j) / complexity))
	
	# Generate indices for triangulation
	for i in range(complexity - 1):
		for j in range(complexity - 1):
			var v0 = i * complexity + j
			var v1 = i * complexity + j + 1
			var v2 = (i + 1) * complexity + j
			var v3 = (i + 1) * complexity + j + 1
			
			# Two triangles per quad
			indices.append_array([v0, v2, v1, v1, v2, v3])
	
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	
	var mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	
	return mesh
