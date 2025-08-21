#version 450

// Compute shader for GPU-accelerated marching cubes
// Based on Paul Bourke's implementation but optimized for Godot

local_size_x = 8,
local_size_y = 8,
local_size_z = 1;

// Input/Output buffers
layout(set = 0, binding = 0, std430) restrict readonly buffer DensityBuffer {
    float density_data[];
};

layout(set = 0, binding = 1, std430) restrict writeonly buffer VertexBuffer {
    vec3 vertices[];
};

layout(set = 0, binding = 2, std430) restrict writeonly buffer NormalBuffer {
    vec3 normals[];
};

layout(set = 0, binding = 3, std430) restrict writeonly buffer IndexBuffer {
    uint indices[];
};

layout(set = 0, binding = 4, std430) restrict buffer CounterBuffer {
    uint vertex_count;
    uint triangle_count;
};

// Uniforms
layout(set = 0, binding = 5, std430) uniform Params {
    ivec3 grid_size;        // Size of the density grid
    vec3 voxel_scale;       // Scale of each voxel
    vec3 grid_offset;       // Offset of the grid in world space
    float iso_level;        // Isosurface threshold
    uint max_vertices;      // Maximum vertices to generate
};

// Edge table for marching cubes (256 entries)
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

// Simplified triangle table (first 16 entries for demonstration)
const int triangle_table[16][16] = int[][](
    int[](-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1),  // 0
    int[](0, 8, 3, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1),     // 1
    int[](0, 1, 9, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1),     // 2
    int[](1, 8, 3, 9, 8, 1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1),        // 3
    int[](1, 2, 10, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1),    // 4
    int[](0, 8, 3, 1, 2, 10, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1),       // 5
    int[](9, 2, 10, 0, 2, 9, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1),       // 6
    int[](2, 8, 3, 2, 10, 8, 10, 9, 8, -1, -1, -1, -1, -1, -1, -1),         // 7
    int[](3, 11, 2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1),    // 8
    int[](0, 11, 2, 8, 11, 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1),      // 9
    int[](1, 9, 0, 2, 3, 11, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1),       // 10
    int[](1, 11, 2, 1, 9, 11, 9, 8, 11, -1, -1, -1, -1, -1, -1, -1),        // 11
    int[](3, 10, 1, 11, 10, 3, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1),     // 12
    int[](0, 10, 1, 0, 8, 10, 8, 11, 10, -1, -1, -1, -1, -1, -1, -1),       // 13
    int[](3, 9, 0, 3, 11, 9, 11, 10, 9, -1, -1, -1, -1, -1, -1, -1),        // 14
    int[](9, 8, 10, 10, 8, 11, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1)      // 15
);

// Edge vertex connections
const ivec2 edge_connections[12] = ivec2[](
    ivec2(0, 1), ivec2(1, 2), ivec2(2, 3), ivec2(3, 0),  // Bottom face
    ivec2(4, 5), ivec2(5, 6), ivec2(6, 7), ivec2(7, 4),  // Top face
    ivec2(0, 4), ivec2(1, 5), ivec2(2, 6), ivec2(3, 7)   // Vertical edges
);

// Cube vertex offsets
const ivec3 cube_offsets[8] = ivec3[](
    ivec3(0, 0, 0), ivec3(1, 0, 0), ivec3(1, 1, 0), ivec3(0, 1, 0),  // Bottom
    ivec3(0, 0, 1), ivec3(1, 0, 1), ivec3(1, 1, 1), ivec3(0, 1, 1)   // Top
);

// Get density at grid position
float get_density(ivec3 pos) {
    if (pos.x < 0 || pos.y < 0 || pos.z < 0 || 
        pos.x >= grid_size.x || pos.y >= grid_size.y || pos.z >= grid_size.z) {
        return 0.0; // Outside bounds = air
    }
    
    uint index = uint(pos.x + pos.y * grid_size.x + pos.z * grid_size.x * grid_size.y);
    return density_data[index];
}

// Interpolate vertex position on edge
vec3 interpolate_vertex(vec3 p1, vec3 p2, float d1, float d2) {
    if (abs(d1 - d2) < 0.00001) {
        return (p1 + p2) * 0.5;
    }
    
    float t = (iso_level - d1) / (d2 - d1);
    t = clamp(t, 0.0, 1.0);
    return mix(p1, p2, t);
}

// Convert grid position to world position
vec3 grid_to_world(ivec3 grid_pos) {
    return grid_offset + vec3(grid_pos) * voxel_scale;
}

void main() {
    ivec3 cube_pos = ivec3(gl_GlobalInvocationID.xyz);
    
    // Skip if out of bounds
    if (cube_pos.x >= grid_size.x - 1 || 
        cube_pos.y >= grid_size.y - 1 || 
        cube_pos.z >= grid_size.z - 1) {
        return;
    }
    
    // Get cube vertex positions and densities
    vec3 positions[8];
    float densities[8];
    
    for (int i = 0; i < 8; i++) {
        ivec3 vertex_pos = cube_pos + cube_offsets[i];
        positions[i] = grid_to_world(vertex_pos);
        densities[i] = get_density(vertex_pos);
    }
    
    // Calculate cube configuration
    uint cube_index = 0u;
    for (int i = 0; i < 8; i++) {
        if (densities[i] < iso_level) {
            cube_index |= (1u << i);
        }
    }
    
    // Skip if completely inside or outside
    if (cube_index == 0u || cube_index == 255u) {
        return;
    }
    
    // Get edge intersections
    uint edges = edge_table[cube_index];
    vec3 edge_vertices[12];
    bool edge_valid[12];
    
    for (int i = 0; i < 12; i++) {
        edge_valid[i] = false;
        if ((edges & (1u << i)) != 0u) {
            ivec2 edge_conn = edge_connections[i];
            vec3 p1 = positions[edge_conn.x];
            vec3 p2 = positions[edge_conn.y];
            float d1 = densities[edge_conn.x];
            float d2 = densities[edge_conn.y];
            
            if ((d1 < iso_level) != (d2 < iso_level)) {
                edge_vertices[i] = interpolate_vertex(p1, p2, d1, d2);
                edge_valid[i] = true;
            }
        }
    }
    
    // Generate triangles (simplified for first 16 configurations)
    if (cube_index < 16u) {
        for (int i = 0; i < 15; i += 3) {
            int e1 = triangle_table[cube_index][i];
            int e2 = triangle_table[cube_index][i + 1];
            int e3 = triangle_table[cube_index][i + 2];
            
            if (e1 == -1) break; // End of triangles
            
            if (edge_valid[e1] && edge_valid[e2] && edge_valid[e3]) {
                // Atomically get vertex indices
                uint base_vertex = atomicAdd(vertex_count, 3u);
                
                if (base_vertex + 2 < max_vertices) {
                    // Add vertices
                    vertices[base_vertex] = edge_vertices[e1];
                    vertices[base_vertex + 1] = edge_vertices[e2];
                    vertices[base_vertex + 2] = edge_vertices[e3];
                    
                    // Calculate normal
                    vec3 v1 = edge_vertices[e2] - edge_vertices[e1];
                    vec3 v2 = edge_vertices[e3] - edge_vertices[e1];
                    vec3 normal = normalize(cross(v1, v2));
                    
                    normals[base_vertex] = normal;
                    normals[base_vertex + 1] = normal;
                    normals[base_vertex + 2] = normal;
                    
                    // Add indices
                    uint triangle_idx = atomicAdd(triangle_count, 1u);
                    uint index_base = triangle_idx * 3u;
                    
                    indices[index_base] = base_vertex;
                    indices[index_base + 1] = base_vertex + 1;
                    indices[index_base + 2] = base_vertex + 2;
                }
            }
        }
    }
}
