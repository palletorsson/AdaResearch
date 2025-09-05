# FixedGPUMarchingCubes.gd
# GPU-accelerated marching cubes using compute shaders
# Fixed for Godot 4.x compatibility

extends RefCounted
class_name FixedGPUMarchingCubes

# Rendering device and compute shader
var rd: RenderingDevice
var compute_shader: RID
var shader_file: RDShaderFile

# Buffer objects
var density_buffer: RID
var vertex_buffer: RID
var normal_buffer: RID
var index_buffer: RID
var counter_buffer: RID
var uniform_buffer: RID

# Parameters
var grid_size: Vector3i = Vector3i(64, 64, 64)
var voxel_scale: Vector3 = Vector3.ONE
var grid_offset: Vector3 = Vector3.ZERO
var iso_level: float = 0.5
var max_vertices: int = 2000000  # 2M vertices max

# Initialization
var is_initialized: bool = false

# Edge and triangle tables for marching cubes
var edge_table: PackedInt32Array
var triangle_table: PackedInt32Array

func _init():
	initialize_gpu_resources()
	setup_marching_cubes_tables()

func initialize_gpu_resources():
	"""Initialize GPU resources for compute shader"""
	rd = RenderingServer.create_local_rendering_device()
	
	if not rd:
		push_error("Failed to create local rendering device")
		is_initialized = false
		return
	
	# Load compute shader
	if not load_compute_shader():
		push_error("Failed to load compute shader")
		is_initialized = false
		return
	
	is_initialized = true
	print("FixedGPUMarchingCubes: GPU resources initialized successfully")

func load_compute_shader() -> bool:
	"""Load the marching cubes compute shader"""
	# Create shader source code
	var shader_source = create_compute_shader_source()
	
	# Create shader file
	shader_file = RDShaderFile.new()
	shader_file.set_source_code(RenderingDevice.SHADER_STAGE_COMPUTE, shader_source)
	
	# Compile shader
	var shader_spirv = shader_file.get_spirv()
	if not shader_spirv:
		push_error("Failed to compile compute shader")
		return false
	
	compute_shader = rd.shader_create_from_spirv(shader_spirv)
	if not compute_shader.is_valid():
		push_error("Failed to create compute shader")
		return false
	
	return true

func create_compute_shader_source() -> String:
	"""Create the compute shader source code"""
	return """
#version 450

// Local workgroup size
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

// Uniform buffer
layout(set = 0, binding = 0, std140) restrict readonly uniform Parameters {
	ivec3 grid_size;
	int padding1;
	vec3 voxel_scale;
	float padding2;
	vec3 grid_offset;
	float iso_level;
	uint max_vertices;
	uint padding3;
	uint padding4;
	uint padding5;
} params;

// Storage buffers
layout(set = 0, binding = 1, std430) restrict readonly buffer DensityBuffer {
	float density_data[];
};

layout(set = 0, binding = 2, std430) restrict writeonly buffer VertexBuffer {
	vec3 vertices[];
};

layout(set = 0, binding = 3, std430) restrict writeonly buffer NormalBuffer {
	vec3 normals[];
};

layout(set = 0, binding = 4, std430) restrict writeonly buffer IndexBuffer {
	uint indices[];
};

layout(set = 0, binding = 5, std430) restrict buffer CounterBuffer {
	uint vertex_count;
	uint triangle_count;
};

// Edge table (256 entries)
const uint edge_table[256] = uint[](
	0x0, 0x109, 0x203, 0x30a, 0x406, 0x50f, 0x605, 0x70c,
	0x80c, 0x905, 0xa0f, 0xb06, 0xc0a, 0xd03, 0xe09, 0xf00,
	0x190, 0x99, 0x393, 0x29a, 0x596, 0x49f, 0x795, 0x69c,
	0x99c, 0x895, 0xb9f, 0xa96, 0xd9a, 0xc93, 0xf99, 0xe90,
	0x230, 0x339, 0x33, 0x13a, 0x636, 0x73f, 0x435, 0x53c,
	0xa3c, 0xb35, 0x83f, 0x936, 0xe3a, 0xf33, 0xc39, 0xd30,
	0x3a0, 0x2a9, 0x1a3, 0xaa, 0x7a6, 0x6af, 0x5a5, 0x4ac,
	0xbac, 0xaa5, 0x9af, 0x8a6, 0xfaa, 0xea3, 0xda9, 0xca0,
	0x460, 0x569, 0x663, 0x76a, 0x66, 0x16f, 0x265, 0x36c,
	0xc6c, 0xd65, 0xe6f, 0xf66, 0x86a, 0x963, 0xa69, 0xb60,
	0x5f0, 0x4f9, 0x7f3, 0x6fa, 0x1f6, 0xff, 0x3f5, 0x2fc,
	0xdfc, 0xcf5, 0xfff, 0xef6, 0x9fa, 0x8f3, 0xbf9, 0xaf0,
	0x650, 0x759, 0x453, 0x55a, 0x256, 0x35f, 0x55, 0x15c,
	0xe5c, 0xf55, 0xc5f, 0xd56, 0xa5a, 0xb53, 0x859, 0x950,
	0x7c0, 0x6c9, 0x5c3, 0x4ca, 0x3c6, 0x2cf, 0x1c5, 0xcc,
	0xfcc, 0xec5, 0xdcf, 0xcc6, 0xbca, 0xac3, 0x9c9, 0x8c0,
	0x8c0, 0x9c9, 0xac3, 0xbca, 0xcc6, 0xdcf, 0xec5, 0xfcc,
	0xcc, 0x1c5, 0x2cf, 0x3c6, 0x4ca, 0x5c3, 0x6c9, 0x7c0,
	0x950, 0x859, 0xb53, 0xa5a, 0xd56, 0xc5f, 0xf55, 0xe5c,
	0x15c, 0x55, 0x35f, 0x256, 0x55a, 0x453, 0x759, 0x650,
	0xaf0, 0xbf9, 0x8f3, 0x9fa, 0xef6, 0xfff, 0xcf5, 0xdfc,
	0x2fc, 0x3f5, 0xff, 0x1f6, 0x6fa, 0x7f3, 0x4f9, 0x5f0,
	0xb60, 0xa69, 0x963, 0x86a, 0xf66, 0xe6f, 0xd65, 0xc6c,
	0x36c, 0x265, 0x16f, 0x66, 0x76a, 0x663, 0x569, 0x460,
	0xca0, 0xda9, 0xea3, 0xfaa, 0x8a6, 0x9af, 0xaa5, 0xbac,
	0x4ac, 0x5a5, 0x6af, 0x7a6, 0xaa, 0x1a3, 0x2a9, 0x3a0,
	0xd30, 0xc39, 0xf33, 0xe3a, 0x936, 0x83f, 0xb35, 0xa3c,
	0x53c, 0x435, 0x73f, 0x636, 0x13a, 0x33, 0x339, 0x230,
	0xe90, 0xf99, 0xc93, 0xd9a, 0xa96, 0xb9f, 0x895, 0x99c,
	0x69c, 0x795, 0x49f, 0x596, 0x29a, 0x393, 0x99, 0x190,
	0xf00, 0xe09, 0xd03, 0xc0a, 0xb06, 0xa0f, 0x905, 0x80c,
	0x70c, 0x605, 0x50f, 0x406, 0x30a, 0x203, 0x109, 0x0
);

// Cube vertex positions
const vec3 cube_verts[8] = vec3[](
	vec3(0, 0, 0), vec3(1, 0, 0), vec3(1, 1, 0), vec3(0, 1, 0),
	vec3(0, 0, 1), vec3(1, 0, 1), vec3(1, 1, 1), vec3(0, 1, 1)
);

// Edge connections
const ivec2 edge_connections[12] = ivec2[](
	ivec2(0, 1), ivec2(1, 2), ivec2(2, 3), ivec2(3, 0),
	ivec2(4, 5), ivec2(5, 6), ivec2(6, 7), ivec2(7, 4),
	ivec2(0, 4), ivec2(1, 5), ivec2(2, 6), ivec2(3, 7)
);

float get_density(ivec3 pos) {
	if (pos.x < 0 || pos.x >= params.grid_size.x ||
		pos.y < 0 || pos.y >= params.grid_size.y ||
		pos.z < 0 || pos.z >= params.grid_size.z) {
		return 0.0;
	}
	
	int index = pos.x + pos.y * params.grid_size.x + pos.z * params.grid_size.x * params.grid_size.y;
	return density_data[index];
}

vec3 interpolate_vertex(vec3 p1, vec3 p2, float v1, float v2) {
	if (abs(params.iso_level - v1) < 0.00001) return p1;
	if (abs(params.iso_level - v2) < 0.00001) return p2;
	if (abs(v1 - v2) < 0.00001) return p1;
	
	float t = (params.iso_level - v1) / (v2 - v1);
	return p1 + t * (p2 - p1);
}

void main() {
	ivec3 coord = ivec3(gl_GlobalInvocationID.xyz);
	
	// Check bounds
	if (coord.x >= params.grid_size.x - 1 || 
		coord.y >= params.grid_size.y - 1 || 
		coord.z >= params.grid_size.z - 1) {
		return;
	}
	
	// Get cube vertices
	float cube_values[8];
	vec3 cube_positions[8];
	
	for (int i = 0; i < 8; i++) {
		ivec3 vert_pos = coord + ivec3(cube_verts[i]);
		cube_values[i] = get_density(vert_pos);
		cube_positions[i] = params.grid_offset + vec3(vert_pos) * params.voxel_scale;
	}
	
	// Determine cube configuration
	uint cube_index = 0;
	for (int i = 0; i < 8; i++) {
		if (cube_values[i] < params.iso_level) {
			cube_index |= (1 << i);
		}
	}
	
	// Skip if cube is completely inside or outside
	if (cube_index == 0 || cube_index == 255) {
		return;
	}
	
	// Get edge list
	uint edges = edge_table[cube_index];
	if (edges == 0) return;
	
	// Calculate intersection points
	vec3 vert_list[12];
	bool edge_used[12];
	
	for (int i = 0; i < 12; i++) {
		edge_used[i] = false;
		if ((edges & (1 << i)) != 0) {
			edge_used[i] = true;
			ivec2 edge = edge_connections[i];
			vert_list[i] = interpolate_vertex(
				cube_positions[edge.x], cube_positions[edge.y],
				cube_values[edge.x], cube_values[edge.y]
			);
		}
	}
	
	// Generate triangles (simplified - would need full triangle table)
	// For now, generate basic triangles from edge intersections
	vec3 triangle_verts[15]; // Max 5 triangles * 3 vertices
	int triangle_count = 0;
	
	// Simple triangle generation based on edge pattern
	if (edge_used[0] && edge_used[1] && edge_used[8]) {
		triangle_verts[triangle_count * 3] = vert_list[0];
		triangle_verts[triangle_count * 3 + 1] = vert_list[1];
		triangle_verts[triangle_count * 3 + 2] = vert_list[8];
		triangle_count++;
	}
	
	// Add more triangle cases as needed...
	
	// Output vertices and indices
	for (int i = 0; i < triangle_count; i++) {
		uint base_vertex = atomicAdd(vertex_count, 3);
		
		if (base_vertex + 2 < params.max_vertices) {
			// Store vertices
			vertices[base_vertex] = triangle_verts[i * 3];
			vertices[base_vertex + 1] = triangle_verts[i * 3 + 1];
			vertices[base_vertex + 2] = triangle_verts[i * 3 + 2];
			
			// Calculate and store normals
			vec3 v1 = triangle_verts[i * 3 + 1] - triangle_verts[i * 3];
			vec3 v2 = triangle_verts[i * 3 + 2] - triangle_verts[i * 3];
			vec3 normal = normalize(cross(v1, v2));
			
			normals[base_vertex] = normal;
			normals[base_vertex + 1] = normal;
			normals[base_vertex + 2] = normal;
			
			// Store indices
			uint base_index = atomicAdd(triangle_count, 1) * 3;
			indices[base_index] = base_vertex;
			indices[base_index + 1] = base_vertex + 1;
			indices[base_index + 2] = base_vertex + 2;
		}
	}
}
"""

func setup_marching_cubes_tables():
	"""Setup the marching cubes lookup tables"""
	# Edge table - determines which edges are intersected (complete 256 entries)
	edge_table = PackedInt32Array([
		0x0, 0x109, 0x203, 0x30a, 0x406, 0x50f, 0x605, 0x70c,
		0x80c, 0x905, 0xa0f, 0xb06, 0xc0a, 0xd03, 0xe09, 0xf00,
		0x190, 0x99, 0x393, 0x29a, 0x596, 0x49f, 0x795, 0x69c,
		0x99c, 0x895, 0xb9f, 0xa96, 0xd9a, 0xc93, 0xf99, 0xe90,
		0x230, 0x339, 0x33, 0x13a, 0x636, 0x73f, 0x435, 0x53c,
		0xa3c, 0xb35, 0x83f, 0x936, 0xe3a, 0xf33, 0xc39, 0xd30,
		0x3a0, 0x2a9, 0x1a3, 0xaa, 0x7a6, 0x6af, 0x5a5, 0x4ac,
		0xbac, 0xaa5, 0x9af, 0x8a6, 0xfaa, 0xea3, 0xda9, 0xca0,
		0x460, 0x569, 0x663, 0x76a, 0x66, 0x16f, 0x265, 0x36c,
		0xc6c, 0xd65, 0xe6f, 0xf66, 0x86a, 0x963, 0xa69, 0xb60,
		0x5f0, 0x4f9, 0x7f3, 0x6fa, 0x1f6, 0xff, 0x3f5, 0x2fc,
		0xdfc, 0xcf5, 0xfff, 0xef6, 0x9fa, 0x8f3, 0xbf9, 0xaf0,
		0x650, 0x759, 0x453, 0x55a, 0x256, 0x35f, 0x55, 0x15c,
		0xe5c, 0xf55, 0xc5f, 0xd56, 0xa5a, 0xb53, 0x859, 0x950,
		0x7c0, 0x6c9, 0x5c3, 0x4ca, 0x3c6, 0x2cf, 0x1c5, 0xcc,
		0xfcc, 0xec5, 0xdcf, 0xcc6, 0xbca, 0xac3, 0x9c9, 0x8c0,
		0x8c0, 0x9c9, 0xac3, 0xbca, 0xcc6, 0xdcf, 0xec5, 0xfcc,
		0xcc, 0x1c5, 0x2cf, 0x3c6, 0x4ca, 0x5c3, 0x6c9, 0x7c0,
		0x950, 0x859, 0xb53, 0xa5a, 0xd56, 0xc5f, 0xf55, 0xe5c,
		0x15c, 0x55, 0x35f, 0x256, 0x55a, 0x453, 0x759, 0x650,
		0xaf0, 0xbf9, 0x8f3, 0x9fa, 0xef6, 0xfff, 0xcf5, 0xdfc,
		0x2fc, 0x3f5, 0xff, 0x1f6, 0x6fa, 0x7f3, 0x4f9, 0x5f0,
		0xb60, 0xa69, 0x963, 0x86a, 0xf66, 0xe6f, 0xd65, 0xc6c,
		0x36c, 0x265, 0x16f, 0x66, 0x76a, 0x663, 0x569, 0x460,
		0xca0, 0xda9, 0xea3, 0xfaa, 0x8a6, 0x9af, 0xaa5, 0xbac,
		0x4ac, 0x5a5, 0x6af, 0x7a6, 0xaa, 0x1a3, 0x2a9, 0x3a0,
		0xd30, 0xc39, 0xf33, 0xe3a, 0x936, 0x83f, 0xb35, 0xa3c,
		0x53c, 0x435, 0x73f, 0x636, 0x13a, 0x33, 0x339, 0x230,
		0xe90, 0xf99, 0xc93, 0xd9a, 0xa96, 0xb9f, 0x895, 0x99c,
		0x69c, 0x795, 0x49f, 0x596, 0x29a, 0x393, 0x99, 0x190,
		0xf00, 0xe09, 0xd03, 0xc0a, 0xb06, 0xa0f, 0x905, 0x80c,
		0x70c, 0x605, 0x50f, 0x406, 0x30a, 0x203, 0x109, 0x0
	])
	
	# Triangle table would be much larger (256 entries, each with up to 16 triangles)
	# For now using a simplified approach in the compute shader
	triangle_table = PackedInt32Array()

func setup_buffers(density_data: PackedFloat32Array) -> bool:
	"""Setup GPU buffers for marching cubes computation"""
	if not is_initialized:
		return false
	
	var grid_volume = grid_size.x * grid_size.y * grid_size.z
	
	# Validate density data size
	if density_data.size() != grid_volume:
		push_error("Density data size mismatch: expected %d, got %d" % [grid_volume, density_data.size()])
		return false
	
	# Create density buffer
	var density_bytes = density_data.to_byte_array()
	density_buffer = rd.storage_buffer_create(density_bytes.size())
	# FIXED: Use 4-parameter buffer_update (buffer, offset, size, data)
	rd.buffer_update(density_buffer, 0, density_bytes.size(), density_bytes)
	
	# Create vertex buffer (vec3 = 12 bytes per vertex)
	var vertex_buffer_size = max_vertices * 12
	vertex_buffer = rd.storage_buffer_create(vertex_buffer_size)
	
	# Create normal buffer (vec3 = 12 bytes per normal)
	var normal_buffer_size = max_vertices * 12
	normal_buffer = rd.storage_buffer_create(normal_buffer_size)
	
	# Create index buffer (uint = 4 bytes per index)
	var index_buffer_size = max_vertices * 4
	index_buffer = rd.storage_buffer_create(index_buffer_size)
	
	# Create counter buffer (2 uints = 8 bytes)
	var counter_data = PackedInt32Array([0, 0])  # vertex_count, triangle_count
	var counter_bytes = counter_data.to_byte_array()
	counter_buffer = rd.storage_buffer_create(counter_bytes.size())
	# FIXED: Use 4-parameter buffer_update (buffer, offset, size, data)
	rd.buffer_update(counter_buffer, 0, counter_bytes.size(), counter_bytes)
	
	# Create uniform buffer
	var uniform_data = create_uniform_data()
	uniform_buffer = rd.uniform_buffer_create(uniform_data.size())
	# FIXED: Use 4-parameter buffer_update (buffer, offset, size, data)
	rd.buffer_update(uniform_buffer, 0, uniform_data.size(), uniform_data)
	
	print("FixedGPUMarchingCubes: Buffers created successfully")
	return true

func create_uniform_data() -> PackedByteArray:
	"""Create uniform data for compute shader"""
	var data = PackedByteArray()
	
	# Pack all uniform data with proper alignment
	# ivec3 grid_size (16 bytes aligned)
	data.append_array(PackedInt32Array([grid_size.x, grid_size.y, grid_size.z, 0]).to_byte_array())
	
	# vec3 voxel_scale (16 bytes aligned)
	data.append_array(PackedFloat32Array([voxel_scale.x, voxel_scale.y, voxel_scale.z, 0.0]).to_byte_array())
	
	# vec3 grid_offset (16 bytes aligned)
	data.append_array(PackedFloat32Array([grid_offset.x, grid_offset.y, grid_offset.z, 0.0]).to_byte_array())
	
	# float iso_level + uint max_vertices + padding (16 bytes aligned)
	data.append_array(PackedFloat32Array([iso_level]).to_byte_array())
	data.append_array(PackedInt32Array([max_vertices, 0, 0]).to_byte_array())
	
	return data

func generate_mesh_gpu(density_data: PackedFloat32Array) -> ArrayMesh:
	"""Generate mesh using GPU compute shader"""
	if not is_initialized:
		push_error("GPU not initialized")
		return ArrayMesh.new()
	
	if not setup_buffers(density_data):
		push_error("Failed to setup buffers")
		return ArrayMesh.new()
	
	# Create uniform set
	var uniforms = []
	
	# Binding 0: Uniform buffer
	var params_uniform := RDUniform.new()
	params_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_UNIFORM_BUFFER
	params_uniform.binding = 0
	params_uniform.add_id(uniform_buffer)
	uniforms.append(params_uniform)
	
	# Binding 1: Density buffer (readonly)
	var density_uniform := RDUniform.new()
	density_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	density_uniform.binding = 1
	density_uniform.add_id(density_buffer)
	uniforms.append(density_uniform)
	
	# Binding 2: Vertex buffer (writeonly)
	var vertex_uniform := RDUniform.new()
	vertex_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	vertex_uniform.binding = 2
	vertex_uniform.add_id(vertex_buffer)
	uniforms.append(vertex_uniform)
	
	# Binding 3: Normal buffer (writeonly)
	var normal_uniform := RDUniform.new()
	normal_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	normal_uniform.binding = 3
	normal_uniform.add_id(normal_buffer)
	uniforms.append(normal_uniform)
	
	# Binding 4: Index buffer (writeonly)
	var index_uniform := RDUniform.new()
	index_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	index_uniform.binding = 4
	index_uniform.add_id(index_buffer)
	uniforms.append(index_uniform)
	
	# Binding 5: Counter buffer (read/write)
	var counter_uniform := RDUniform.new()
	counter_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	counter_uniform.binding = 5
	counter_uniform.add_id(counter_buffer)
	uniforms.append(counter_uniform)
	
	var uniform_set_rid = rd.uniform_set_create(uniforms, compute_shader, 0)
	
	# Dispatch compute shader
	var compute_list = rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, compute_shader)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set_rid, 0)
	
	# Calculate dispatch groups (8x8x1 local size)
	var groups_x = (grid_size.x + 7) / 8
	var groups_y = (grid_size.y + 7) / 8
	var groups_z = grid_size.z
	
	rd.compute_list_dispatch(compute_list, groups_x, groups_y, groups_z)
	rd.compute_list_end()
	rd.submit()
	rd.wait()
	
	print("FixedGPUMarchingCubes: GPU computation complete")
	
	# Read back results
	return create_mesh_from_gpu_results()

func create_mesh_from_gpu_results() -> ArrayMesh:
	"""Create ArrayMesh from GPU computation results"""
	
	# Read counter buffer to get actual vertex/triangle counts
	var counter_bytes = rd.buffer_get_data(counter_buffer)
	var counter_data = counter_bytes.to_int32_array()
	var vertex_count = counter_data[0]
	var triangle_count = counter_data[1]
	
	print("FixedGPUMarchingCubes: Generated %d vertices, %d triangles" % [vertex_count, triangle_count])
	
	if vertex_count == 0:
		print("FixedGPUMarchingCubes: No geometry generated")
		return ArrayMesh.new()
	
	# Read vertex buffer
	var vertex_bytes = rd.buffer_get_data(vertex_buffer)
	var vertices = PackedVector3Array()
	
	# Convert bytes to Vector3 array
	for i in range(vertex_count):
		var offset = i * 12  # 3 floats * 4 bytes
		var x = vertex_bytes.decode_float(offset)
		var y = vertex_bytes.decode_float(offset + 4)
		var z = vertex_bytes.decode_float(offset + 8)
		vertices.append(Vector3(x, y, z))
	
	# Read normal buffer
	var normal_bytes = rd.buffer_get_data(normal_buffer)
	var normals = PackedVector3Array()
	
	for i in range(vertex_count):
		var offset = i * 12
		var x = normal_bytes.decode_float(offset)
		var y = normal_bytes.decode_float(offset + 4)
		var z = normal_bytes.decode_float(offset + 8)
		normals.append(Vector3(x, y, z))
	
	# Read index buffer
	var index_bytes = rd.buffer_get_data(index_buffer)
	var indices = PackedInt32Array()
	
	for i in range(triangle_count * 3):
		var offset = i * 4
		var index = index_bytes.decode_u32(offset)
		indices.append(index)
	
	# Create mesh
	var mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	
	print("FixedGPUMarchingCubes: Mesh creation complete")
	return mesh

func cleanup():
	"""Clean up GPU resources"""
	if not is_initialized or not rd:
		return
	
	if density_buffer.is_valid():
		rd.free_rid(density_buffer)
	if vertex_buffer.is_valid():
		rd.free_rid(vertex_buffer)
	if normal_buffer.is_valid():
		rd.free_rid(normal_buffer)
	if index_buffer.is_valid():
		rd.free_rid(index_buffer)
	if counter_buffer.is_valid():
		rd.free_rid(counter_buffer)
	if uniform_buffer.is_valid():
		rd.free_rid(uniform_buffer)
	if compute_shader.is_valid():
		rd.free_rid(compute_shader)
	
	is_initialized = false
	print("FixedGPUMarchingCubes: GPU resources cleaned up")

# Helper function for terrain density
func create_terrain_density_field(size: Vector3i, world_bounds: AABB, terrain_height: float, noise: FastNoiseLite) -> PackedFloat32Array:
	"""Create a density field for terrain with given parameters"""
	var density_data = PackedFloat32Array()
	density_data.resize(size.x * size.y * size.z)
	
	for x in range(size.x):
		for y in range(size.y):
			for z in range(size.z):
				var world_pos = world_bounds.position + Vector3(
					float(x) / float(size.x - 1) * world_bounds.size.x,
					float(y) / float(size.y - 1) * world_bounds.size.y,
					float(z) / float(size.z - 1) * world_bounds.size.z
				)
				
				# Generate terrain density
				var terrain_surface = noise.get_noise_2d(world_pos.x, world_pos.z) * terrain_height
				var distance_to_surface = world_pos.y - terrain_surface
				
				# Smooth density function
				var density: float
				if distance_to_surface <= -2.0:
					density = 1.0  # Solid terrain
				elif distance_to_surface <= 2.0:
					# Smooth transition zone
					var t = (distance_to_surface + 2.0) / 4.0
					density = 1.0 - smoothstep(0.0, 1.0, t)
				else:
					density = 0.0  # Air
				
				var index = x + y * size.x + z * size.x * size.y
				density_data[index] = density
	
	return density_data

# Public API functions
func set_grid_parameters(size: Vector3i, scale: Vector3, offset: Vector3):
	"""Set grid parameters"""
	grid_size = size
	voxel_scale = scale
	grid_offset = offset

func set_iso_level(level: float):
	"""Set the iso level for surface extraction"""
	iso_level = level

func get_performance_info() -> Dictionary:
	"""Get performance information"""
	return {
		"is_gpu_available": is_initialized,
		"max_vertices": max_vertices,
		"grid_size": grid_size,
		"voxel_count": grid_size.x * grid_size.y * grid_size.z
	}

func _exit_tree():
	cleanup()
