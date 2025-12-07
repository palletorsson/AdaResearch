extends TerrainGeneratorBase

# Portal settings
@export var num_portals : int = 7
@export var portal_spacing : float = 250.0
@export var portal_radius : float = 40.0
@export var portal_minor_radius : float = 15.0
@export var portal_emergence_height : float = -20.0

func get_class_name() -> String:
	return "TerrainGeneratorUnifiedPortals"

func get_compute_shader_path() -> String:
	return "res://algorithms/proceduralgeneration/marchingcave/Compute/MarchingCubesPortalTerrain.glsl"

func get_params_array() -> Array:
	var params = super.get_params_array()
	# Portal params
	params.append(float(num_portals))
	params.append(portal_spacing)
	params.append(portal_radius)
	params.append(portal_minor_radius)
	params.append(portal_emergence_height)
	return params

func _create_fallback_mesh():
	print("TerrainGeneratorUnifiedPortals: Creating fallback combined mesh (terrain + simple toruses)...")
	# For now, just create terrain - proper fallback would need CSG
	_create_simple_terrain()
	print("✅ Fallback mesh created")

func _create_simple_terrain():
	# Simple flat plane
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var indices = PackedInt32Array()
	
	var size = chunk_scale * 0.6
	var segments = 60
	var step = size / segments
	
	for z in range(segments + 1):
		for x in range(segments + 1):
			var px = (x - segments / 2.0) * step
			var pz = (z - segments / 2.0) * step
			
			var height = sin(px * 0.02) * cos(pz * 0.02) * 10.0
			
			vertices.append(Vector3(px, height, pz))
			normals.append(Vector3.UP)
	
	for z in range(segments):
		for x in range(segments):
			var i0 = z * (segments + 1) + x
			var i1 = i0 + 1
			var i2 = (z + 1) * (segments + 1) + x
			var i3 = i2 + 1
			
			indices.append(i0)
			indices.append(i2)
			indices.append(i1)
			
			indices.append(i1)
			indices.append(i2)
			indices.append(i3)
	
	var mesh_arrays = []
	mesh_arrays.resize(Mesh.ARRAY_MAX)
	mesh_arrays[Mesh.ARRAY_VERTEX] = vertices
	mesh_arrays[Mesh.ARRAY_NORMAL] = normals
	mesh_arrays[Mesh.ARRAY_INDEX] = indices
	
	array_mesh.clear_surfaces()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_arrays)
	_create_collision()
