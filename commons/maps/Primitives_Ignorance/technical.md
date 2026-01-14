# Primitives Ignorance - Technical Tutorial

## Spheres as Triangle Approximations

Spheres in computational geometry are **not primitive** - they're approximated using triangular meshes at varying resolutions:

```gdscript
# Low resolution sphere (icosahedron-based)
var sphere_low = SphereMesh.new()
sphere_low.radial_segments = 8
sphere_low.rings = 4
# Result: ~64 triangles - visibly faceted

# Medium resolution
var sphere_mid = SphereMesh.new()
sphere_mid.radial_segments = 16
sphere_mid.rings = 8
# Result: ~256 triangles - somewhat smooth

# High resolution
var sphere_high = SphereMesh.new()
sphere_high.radial_segments = 32
sphere_high.rings = 16
# Result: ~1024 triangles - appears smooth
```

**Key insight**: No matter the resolution, it's always triangles. True mathematical sphere (infinite points) cannot be represented exactly.

## The Five Platonic Solids

```gdscript
# All five regular convex polyhedra
enum PlatonicSolid {
    TETRAHEDRON,   # 4 triangular faces
    CUBE,          # 6 square faces (12 triangles when rendered)
    OCTAHEDRON,    # 8 triangular faces
    DODECAHEDRON,  # 12 pentagonal faces (60 triangles when rendered)
    ICOSAHEDRON    # 20 triangular faces
}
```

These are the only perfectly regular convex polyhedra possible - a geometrically exhaustive set.

## Octahedron Structure

```gdscript
# Regular octahedron vertices
var vertices = [
    Vector3( 1,  0,  0),  # +X
    Vector3(-1,  0,  0),  # -X
    Vector3( 0,  1,  0),  # +Y
    Vector3( 0, -1,  0),  # -Y
    Vector3( 0,  0,  1),  # +Z
    Vector3( 0,  0, -1)   # -Z
]

# 8 triangular faces
# 12 edges
# 6 vertices
# Dual of cube (vertices ↔ faces)
```

## Capsule as Compound Primitive

```gdscript
# Capsule = Cylinder + 2 Hemispheres
var capsule = CapsuleMesh.new()
capsule.radius = 0.5
capsule.height = 2.0

# Equivalent to:
# - Cylinder (middle section)
# - Sphere top half (cap)
# - Sphere bottom half (cap)
```

Capsule demonstrates **compound primitives** - complex forms built from simpler ones.

## Procedural Rocks: Breaking Regularity

```gdscript
# Rough rock through vertex displacement
func generate_rough_rock(base_mesh: SphereMesh) -> ArrayMesh:
    var surface_tool = SurfaceTool.new()
    surface_tool.create_from(base_mesh, 0)

    var array_mesh = surface_tool.commit()
    var arrays = array_mesh.surface_get_arrays(0)
    var vertices = arrays[ArrayMesh.ARRAY_VERTEX]

    # Displace vertices randomly
    for i in range(vertices.size()):
        var noise_offset = randf_range(-0.3, 0.3)
        vertices[i] += vertices[i].normalized() * noise_offset

    arrays[ArrayMesh.ARRAY_VERTEX] = vertices
    var rough_mesh = ArrayMesh.new()
    rough_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
    return rough_mesh
```

Organic forms require **breaking symmetry** - controlled randomness, noise, displacement.

## Key Takeaway

Primitives (point, line, triangle, cube) are **limited vocabulary**. They excel at:
- Regular, symmetric forms
- Discrete, faceted geometry
- Axis-aligned structures

They struggle with:
- True curves (only approximations)
- Organic irregularity (requires dense triangulation + noise)
- Smooth surfaces (always faceted at some scale)

The gallery reveals: Computational geometry is **triangular approximation all the way down**.
