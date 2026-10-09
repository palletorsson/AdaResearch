# Wavefunctions Bernini — Technical

Baroque columns are generated procedurally by displacing cylinder vertices according to helical sine functions plus noise layers.

```gdscript
class_name BerniniColumn extends MeshInstance3D

@export var height: float = 5.0
@export var base_radius: float = 0.5
@export var twist_rate: float = 2.0          # revolutions per column
@export var swirl_amplitude: float = 0.2
@export var swirl_frequency: float = 6.0
@export var noise_scale: float = 0.05

func generate_mesh() -> ArrayMesh:
    var array_mesh := ArrayMesh.new()
    var surface_tool := SurfaceTool.new()
    surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    var rings: int = 64
    var sides: int = 24
    var noise := FastNoiseLite.new()
    for ring in range(rings + 1):
        var t: float = float(ring) / rings
        var y: float = t * height
        var angle_offset: float = twist_rate * TAU * t
        for side in range(sides + 1):
            var angle: float = float(side) / sides * TAU + angle_offset
            var radial_swirl: float = swirl_amplitude * sin(swirl_frequency * y)
            var current_radius: float = base_radius + radial_swirl
            var noise_offset: float = noise.get_noise_2d(angle, y) * noise_scale
            current_radius += noise_offset
            var x: float = cos(angle) * current_radius
            var z: float = sin(angle) * current_radius
            surface_tool.add_vertex(Vector3(x, y, z))
    # Generate triangle indices ...
    surface_tool.commit(array_mesh)
    return array_mesh
```

## Parameter Interactions

The twist_rate parameter produces the solomonic spiral — the defining feature of Bernini's Baldachin columns. A twist_rate of 2.0 produces two full revolutions from base to top; 1.0 produces a single twist; 0.5 produces a half-twist only.

The swirl_amplitude and swirl_frequency produce the secondary undulation along the column's length. Setting swirl_amplitude to zero produces a straight twisted column; higher values produce more organic sculpted forms.

## Mesh Complexity

A column with 64 rings and 24 sides has 1560 vertices and 3072 triangles. Ten columns fill the map; total geometry is about 15,000 vertices. Godot renders this comfortably at 60 fps.

## Normal Smoothing

Procedurally generated meshes need smoothed normals for consistent shading. Surface tool's `generate_normals` computes per-vertex normals by averaging adjacent face normals, producing smooth shading without visible facets.

```gdscript
surface_tool.generate_normals()
```

## LOD

Distant columns can use reduced mesh resolution. Godot 4's built-in MeshInstance3D.lod_bias controls automatic LOD switching. The map uses three LOD levels: full detail at close range, half detail at medium, quarter detail at long distance.

Within the sequence, Bernini applies wave mathematics to sculptural form. Cage will next withdraw oscillation to ask what remains.

## Solomonic Spiral Parameters

Bernini's Baldachin columns have specific proportions. Each column is about 20 metres tall, twisted through approximately 1.5 full revolutions. The map's twist_rate parameter defaults to 2.0 for visual clarity at room scale, but settings around 1.5 produce the historically accurate profile.

## Surface Normal Computation

Smooth shading on procedural geometry requires per-vertex normals. For a surface parameterised by (u, v), the normal is the cross product of the two partial derivatives:

```gdscript
func compute_normal_at(ring: int, side: int, rings: int, sides: int) -> Vector3:
    var t_current := float(ring) / rings
    var t_next := float(ring + 1) / rings
    var angle_current := float(side) / sides * TAU + twist_rate * TAU * t_current
    var angle_next := float(side + 1) / sides * TAU + twist_rate * TAU * t_current
    var p0 := vertex_at(t_current, angle_current)
    var p1 := vertex_at(t_next, angle_current)
    var p2 := vertex_at(t_current, angle_next)
    var du := p1 - p0
    var dv := p2 - p0
    return du.cross(dv).normalized()
```

## Tessellation-Free Approach

For extreme close-ups, mesh tessellation produces visible polygonal facets. A displacement shader can perform the column deformation on the GPU at rendering time, preserving smooth curvature at any zoom level.

```glsl
// Shader vertex displacement
vec3 displaced_vertex(vec3 base_vertex, float twist_rate) {
    float t = (base_vertex.y + HEIGHT * 0.5) / HEIGHT;
    float angle = base_vertex.x * TAU + twist_rate * TAU * t;
    float radius = BASE_RADIUS + SWIRL_AMPLITUDE * sin(SWIRL_FREQUENCY * base_vertex.y);
    return vec3(cos(angle) * radius, base_vertex.y, sin(angle) * radius);
}
```

## Material Properties

Bernini's bronze Baldachin is reflective and moderately rough — a physically-based material with metallic = 1.0 and roughness = 0.4. The map uses this exact material on the procedural columns for visual continuity with the historical reference.

## Reference Photograph Panel

A photograph of the Baldachin in Saint Peter's Basilica is displayed alongside the procedural column. The comparison makes the procedural reinterpretation visible as a decomposition of the baroque form into tunable parameters.

## Export Format

The generated column mesh can be exported as OBJ or GLTF for external rendering. Godot 4 supports mesh export via ResourceSaver; the map exposes a save-to-disk button for authors who want to use the procedural columns in other contexts.
