# Marching Cubes — Technical

## Core Algorithm

```gdscript
func marching_cubes(density_field: Array3D, threshold: float) -> ArrayMesh:
    var vertices = PackedVector3Array()
    var normals = PackedVector3Array()
    
    # March through each cube
    for x in range(density_field.size_x - 1):
        for y in range(density_field.size_y - 1):
            for z in range(density_field.size_z - 1):
                process_cube(x, y, z, density_field, threshold, vertices, normals)
    
    return build_mesh(vertices, normals)

func process_cube(x, y, z, field, threshold, vertices, normals):
    # Get density at 8 corners
    var corners = [
        field.get(x, y, z),
        field.get(x+1, y, z),
        field.get(x+1, y, z+1),
        field.get(x, y, z+1),
        field.get(x, y+1, z),
        field.get(x+1, y+1, z),
        field.get(x+1, y+1, z+1),
        field.get(x, y+1, z+1)
    ]
    
    # Build case index (8-bit number)
    var case_index = 0
    for i in range(8):
        if corners[i] > threshold:
            case_index |= (1 << i)
    
    # Skip if entirely inside or outside
    if case_index == 0 or case_index == 255:
        return
    
    # Get triangles from lookup table
    var triangles = TRIANGLE_TABLE[case_index]
    
    # Generate vertices on edges
    for tri in triangles:
        for edge in tri:
            var v = interpolate_edge(edge, corners, threshold)
            vertices.append(v + Vector3(x, y, z))
```

## Edge Interpolation

```gdscript
# Edge endpoints (corner indices)
const EDGE_VERTICES = [
    [0, 1], [1, 2], [2, 3], [3, 0],  # Bottom edges
    [4, 5], [5, 6], [6, 7], [7, 4],  # Top edges
    [0, 4], [1, 5], [2, 6], [3, 7]   # Vertical edges
]

func interpolate_edge(edge: int, corners: Array, threshold: float) -> Vector3:
    var v1 = CORNER_POSITIONS[EDGE_VERTICES[edge][0]]
    var v2 = CORNER_POSITIONS[EDGE_VERTICES[edge][1]]
    var d1 = corners[EDGE_VERTICES[edge][0]]
    var d2 = corners[EDGE_VERTICES[edge][1]]
    
    # Linear interpolation
    var t = (threshold - d1) / (d2 - d1)
    return v1.lerp(v2, t)
```

## Normal Calculation

```gdscript
func calculate_normal(pos: Vector3, field) -> Vector3:
    # Gradient of density field
    var epsilon = 0.01
    return Vector3(
        field.sample(pos.x + epsilon, pos.y, pos.z) - 
        field.sample(pos.x - epsilon, pos.y, pos.z),
        field.sample(pos.x, pos.y + epsilon, pos.z) - 
        field.sample(pos.x, pos.y - epsilon, pos.z),
        field.sample(pos.x, pos.y, pos.z + epsilon) - 
        field.sample(pos.x, pos.y, pos.z - epsilon)
    ).normalized()
```

## Density Functions

```gdscript
# Sphere
func sphere_density(pos: Vector3, center: Vector3, radius: float) -> float:
    return radius - pos.distance_to(center)

# Noise terrain
func terrain_density(pos: Vector3) -> float:
    return pos.y - noise.get_noise_3d(pos.x, 0, pos.z) * height_scale

# Metaball (multiple spheres that blend)
func metaball_density(pos: Vector3, balls: Array) -> float:
    var sum = 0.0
    for ball in balls:
        var d = pos.distance_to(ball.center)
        sum += ball.radius * ball.radius / (d * d + 0.0001)
    return sum - 1.0
```

## GPU Compute Shader (Godot 4)

```glsl
#[compute]
#version 450

layout(local_size_x = 8, local_size_y = 8, local_size_z = 8) in;

layout(set = 0, binding = 0, std430) buffer DensityBuffer {
    float densities[];
};

layout(set = 0, binding = 1, std430) buffer VertexBuffer {
    vec4 vertices[];
};

void main() {
    ivec3 pos = ivec3(gl_GlobalInvocationID.xyz);
    // Process cube at pos...
}
```
