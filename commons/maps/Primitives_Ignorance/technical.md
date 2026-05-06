# 07 Ignorance

The gallery inscription appears before anything else: *Let no one ignorant of geometry enter here.* Plato wrote it above the Academy door. Here it floats at grid position (4,8), above a dark sphere that barely emits light. This is the entrance condition.

The inscription is a trap. If you believe you already know geometry, you will walk through this space misreading everything. The sphere LOD comparison will look like a display. The octahedron puzzle will look like a toy. The capsule will look like a pill. What this map actually asks is harder: can you encounter these objects as if for the first time, without the confidence that pre-empts discovery?

In Point_Animatedcube you dragged corners of a mesh and watched the cube deform — direct mechanical contact with geometry, vertices as handles, edges as spring constraints. The geometry was responsive. Here the geometry is installed. You cannot break these objects. But you can misread them.

## Resolution Is a Parameter, Not a Property

The first thing you encounter at rows 11, 13, and 15 is three spheres: `sphere_high`, `sphere_mid`, `sphere_low`. They occupy the same position in the type taxonomy — all three are instances of `SphereMesh`. They differ only in their subdivision counts.

```gdscript
# sphere_high: 32 rings, 32 radial_segments
var mesh_high = SphereMesh.new()
mesh_high.radius = 0.3
mesh_high.height = 0.6
mesh_high.rings = 32
mesh_high.radial_segments = 32

# sphere_low: 8 rings, 8 radial_segments
var mesh_low = SphereMesh.new()
mesh_low.radius = 0.3
mesh_low.height = 0.6
mesh_low.rings = 8
mesh_low.radial_segments = 8
```

Walk around them. At reading distance `sphere_high` reads as smooth. `sphere_low` reads as a faceted polyhedron. They are the same mathematical object — the unit sphere — rendered at different computational costs. What you perceive as smoothness is a budget decision. Godot's renderer interpolates normals across triangle faces, which softens the seams, but the underlying tessellation is always visible at close range or in silhouette.

`radial_segments` divides the sphere longitudinally — the vertical slices. `rings` divides it latitudinally — the horizontal bands. Together they determine the triangle count: approximately `radial_segments × rings × 2` triangles per sphere. A `sphere_high` at 32×32 carries roughly 2000 triangles. A `sphere_low` at 8×8 carries roughly 128. The difference is visible. The cost is real.

This matters beyond aesthetics. Every triangle is processed by the GPU per frame. A scene with a thousand `sphere_high` instances costs fifteen times more than the same scene with `sphere_low`. Real-time 3D is always a negotiation between fidelity and performance. The sphere that looks "right" is the one that spends triangles efficiently.

The ignorance the map names here is the assumption that a smooth sphere is a primitive — something given, not constructed. It is not given. Someone chose 32. Someone else chose 8. That choice has consequences. Knowing geometry means knowing the choice was made.

## The Capsule: A Cylinder Made Safe

At x=7, rows 11–15, a capsule sits alongside the star and truncated tetrahedron. It looks unremarkable. `capsule_radials_rings.gd` reveals what it actually is:

```gdscript
func _build_capsule() -> void:
    var capsule_mesh = CapsuleMesh.new()
    capsule_mesh.radius = radius
    capsule_mesh.height = height
    capsule_mesh.radial_segments = radial_segments
    capsule_mesh.rings = rings

    _mesh_instance = MeshInstance3D.new()
    _mesh_instance.mesh = capsule_mesh
    _mesh_instance.material_override = GridMaterialFactory.make(base_color)
    add_child(_mesh_instance)
    _create_collision()
```

The capsule is a cylinder with hemispherical caps. The caps are the engineered part. A pure cylinder has sharp circular edges at each end — edges where the surface normal is discontinuous. If you slide a physics body along a wall and it catches on the corner of a cylinder, that discontinuity is why. Hemispherical caps are differentiable at every point on their surface. No sharp edges. No discontinuous normals. Character controllers in physics engines slide over geometry without snagging because every contact point on their surface has a well-defined outward normal.

```gdscript
func _create_collision() -> void:
    var static_body = StaticBody3D.new()
    static_body.name = "CapsuleCollision"
    add_child(static_body)

    var collision = CollisionShape3D.new()
    var shape = CapsuleShape3D.new()
    shape.radius = radius
    shape.height = height
    collision.shape = shape
    static_body.add_child(collision)
```

`CapsuleShape3D` in Godot uses an analytical formulation — it computes exact distance to the capsule surface mathematically, not against triangle geometry. This makes capsule collision detection faster and more stable than mesh collision at comparable visual fidelity. The shape is designed around a use case: a body that needs to move without snagging. The form follows the function so completely that "capsule" has become a genre — the default shape for VR hands, character bodies, bullets in flight.

The `#config` syntax in the map data configures this object at placement:

```gdscript
func _parse_config_string(config_str: String) -> void:
    var parts = config_str.split(":")
    if parts.size() >= 1 and parts[0].is_valid_int():
        radial_segments = max(3, int(parts[0]))  # min 3: triangular cross-section
    if parts.size() >= 2 and parts[1].is_valid_int():
        rings = max(1, int(parts[1]))
```

`radial_segments = 3` produces a triangular prism with round caps. `radial_segments = 4` produces a square-capped capsule. The same mesh primitive becomes unrecognizable at low subdivisions. The capsule only "looks like a capsule" above roughly 8 segments.

## The Torus: Two Circles, One Object

`torus_radials_rings` at row 23 shares the configurable structure with the capsule — the same `#config` syntax, the same `apply_grid_config()` interface, the same logic of parameterized construction.

```gdscript
func _build_torus() -> void:
    var torus_mesh = TorusMesh.new()
    torus_mesh.inner_radius = inner_radius
    torus_mesh.outer_radius = outer_radius
    torus_mesh.rings = rings
    torus_mesh.ring_segments = ring_segments

    _mesh_instance = MeshInstance3D.new()
    _mesh_instance.mesh = torus_mesh
    _mesh_instance.name = "TorusMesh"
    _mesh_instance.material_override = GridMaterialFactory.make(base_color, {
        "wireframe_color": wireframe_color,
        "wireframe_width": 2.5,
        "wireframe_brightness": 3.0
    })
    add_child(_mesh_instance)
```

`rings` divides the path — the main circle that the tube travels around. `ring_segments` divides the tube cross-section. A torus with `ring_segments = 4` has a square tube. With `ring_segments = 3`, a triangular one. The tube is itself a circle, parameterized independently of the outer path.

A point on the torus surface is specified by two angles: one for position along the main circle, one for position around the tube. The parameter space is a flat unit square with both pairs of opposite edges identified — wrap the top to the bottom and the left to the right. This topology has a name: genus-1 surface. You cannot flatten a torus into a plane without cutting it. You cannot flatten a sphere without tearing it either, but the reason is different. The sphere has no hole; the torus has exactly one.

```gdscript
# Torus surface parameterization (for reference):
# (θ, φ) → ((R + r·cos(φ))·cos(θ),
#            (R + r·cos(φ))·sin(θ),
#             r·sin(φ))
# where R = outer_radius, r = inner_radius
# θ ∈ [0, 2π]: position around the main circle
# φ ∈ [0, 2π]: position around the tube
```

At low `rings` and `ring_segments`, the wireframe overlay makes this parameterization visible — quads wrapping around two independent circular directions simultaneously. The next map, Primitives_Portals, extends this directly: a sequence of tori with increasing `ring_segments`, watching the discrete polygon count approach the ideal circle. That map asks what a limit is. This one asks what the parameterization is.

## Platonic Solids: Constructed, Not Found

`platonic_grabbables` at (3,4) contains all five: tetrahedron, cube, octahedron, dodecahedron, icosahedron. Three grabbable copies of each. Plato believed these were the atoms of reality — fire is tetrahedra, earth is cubes, air is octahedra. The mysticism is instructive: it shows how desperately humans have wanted geometry to be fundamental, not constructed.

Grab the octahedron. The source is explicit about what it is:

```gdscript
func _octahedron_geometry() -> Dictionary:
    var scale := octahedron_scale
    var vertices: Array[Vector3] = [
        Vector3(0, 0.5, 0) * scale * 2.0,   # top
        Vector3(0, -0.5, 0) * scale * 2.0,  # bottom
        Vector3(0.5, 0, 0) * scale * 2.0,   # right
        Vector3(-0.5, 0, 0) * scale * 2.0,  # left
        Vector3(0, 0, 0.5) * scale * 2.0,   # front
        Vector3(0, 0, -0.5) * scale * 2.0   # back
    ]
    var faces: Array = [
        [0, 4, 2], [0, 2, 5], [0, 5, 3], [0, 3, 4],
        [1, 2, 4], [1, 5, 2], [1, 3, 5], [1, 4, 3]
    ]
```

Six vertices. Eight faces. Each vertex sits at ±0.5 on exactly one axis. The octahedron is the set of all points where |x| + |y| + |z| = constant — the L1 unit ball, as opposed to the L2 unit ball (the round sphere, where x² + y² + z² = constant). This is the dual of the cube: take the cube's six face-centers and connect them, you get these six vertices. The cube has 6 faces and 8 vertices. The octahedron has 8 faces and 6 vertices. Face-vertex duality, exact.

`grab_octahedron.gd` exposes this through interaction — pressing the controller button toggles between materials, making the 8-face structure legible against the wireframe grid. Pressing the button doesn't change what the object is. It changes what you can see. This is not a metaphor for epistemology. It is epistemology: the same structure, different representation, different understanding.

## The Snap Octahedron Puzzle: Topology Through Assembly

At (4,17), the `snap_octahedron_puzzle` asks you to do what the static display already shows — but actively. Six floating points must be placed at their target positions to complete the shape.

```gdscript
func _on_octahedron_formed(points: Array) -> void:
    var our_points_count = 0
    for point in points:
        if point in snap_points:
            our_points_count += 1

    if our_points_count == 6:
        _complete_puzzle()
```

The six target positions are the same six vertices from `_octahedron_geometry()`: ±1 on each axis. Assembling the octahedron by placing its vertices teaches the topology before the topology is named. You learn the shape through its construction, not its description. Walking to a grab_octahedron support block at (2,17) or (6,17), picking it up, carrying it to the target — these are epistemic acts. The position is already known to the system. The understanding comes from making it yourself.

This is knowledge as contact, not code. The snap puzzle is not a test of whether you remember the vertex positions. It is the process through which you internalize them.

## Truncation, Stars, and the Shape Vocabulary

The `truncatedtetrahedron` at x=7 demonstrates a topological operation rather than a parameterization. A regular tetrahedron has 4 vertices. Cut each corner and you replace each vertex with a new triangular face:

```gdscript
var vertices = [
    # Original tetrahedron vertices, pulled inward
    Vector3(0.2, 0.2, 0.2),
    Vector3(-0.2, -0.2, 0.2),
    Vector3(-0.2, 0.2, -0.2),
    Vector3(0.2, -0.2, -0.2),
    # New vertices at each truncated corner
    Vector3(0.1, 0.1, -0.1),
    Vector3(-0.1, -0.1, -0.1),
    Vector3(-0.1, 0.1, 0.1),
    Vector3(0.1, -0.1, 0.1)
]
```

Truncation is a functor: it maps solids to solids systematically. Every vertex becomes a face. The number of sides on the new face equals the original vertex valence. A tetrahedron, where every vertex meets 3 edges, produces triangular truncation faces. An octahedron, where every vertex meets 4 edges, produces square truncation faces. The Archimedean solids — the semi-regular polyhedra between the Platonic extremes — are mostly products of this and related operations. The taxonomy of shapes is small; the space of derived shapes is large.

The `star_primitive` at the same row encodes a different lesson: non-convex geometry. A star cannot be defined as a convex hull of its vertices — the indentations require explicit face definitions. Any algorithm that assumes convexity will fail on a star. This is not a theoretical concern: collision detection, shadow casting, and boolean operations all have convex-optimized fast paths. The star is a reminder that convexity is a special case, not a default.

## Repetition as Construction

The `prism_block` strip at row 21 and the `diamonds` centerpiece at (4,25) demonstrate the same principle at different scales: repetition with incremental variation produces structural complexity from simple rules.

The diamonds stack rotating octahedra — `unit_count` instances, each offset by `unit_height`, each rotated by `rotation_offset` from the previous. One object, one transformation, applied N times. The tower is a transformation sequence collapsed into a single artifact. You cannot separate "the diamond pattern" from "the repetition rule."

```gdscript
# The pattern diamonds.gd encodes:
var unit_count: int        # how many
var unit_size: float       # base scale
var unit_height: float     # vertical offset per unit
var rotation_offset: float # rotation increment per unit (degrees)
```

This is what procedural generation means at its simplest: one object, one transformation, applied N times. The L-system lesson later in the sequence will extend this to branching, context-sensitivity, and recursive depth. But the seed is already here: repetition with incremental variation produces visual complexity from simple rules.

The `dark_sphere` at (4,8) marks inhabited space without asserting itself. It pulses:

```gdscript
func _process(delta: float) -> void:
    _time_elapsed += delta
    if _sphere_mesh:
        _sphere_mesh.rotation.y += rotation_speed * delta
    if _sphere_material:
        var pulse_t := (sin(_time_elapsed * pulse_speed) + 1.0) * 0.5
        _sphere_material.emission_energy_multiplier = lerpf(pulse_min, pulse_max, pulse_t)
```

Sinusoidal emission between 0.05 and 0.35, period controlled by `pulse_speed = 1.2`. Slow enough to read as breathing. Fast enough to register as alive. Some things in a space exist not to be used but to be sensed. The dark sphere is a mood, not a lesson. But the mood is part of the map's argument: not everything present is present for your use.

## What Primitives Are

The gallery inscription is not a credential check. It is a warning about smuggled certainties. Plato's geometry was deductive — it began with axioms and derived truths that could not be otherwise. Computational geometry begins with choices: how many triangles, which topology, what parameterization. These choices are not arbitrary, but they are not necessary either.

A primitive, in computational terms, is not the simplest possible thing. It is a stable foundation for further construction — something whose behavior is well-understood and whose cost is predictable. `CapsuleMesh`, `SphereMesh`, `TorusMesh` are primitives not because they are elementary but because they are reliable. The choice of what counts as a primitive encodes assumptions about what matters: smooth normals matter for character controllers, so the capsule is primitive; topological genus matters for texture mapping, so the distinction between sphere and torus is primitive; resolution flexibility matters for level-of-detail systems, so the subdivision parameter is exposed.

The Platonic solids persist because they encode something true about symmetry — not atoms of matter, but a complete classification of all possible face-regular convex polyhedra. There are exactly five. That finitude is remarkable. But knowing that fact is different from knowing the vertex arrays, the face indices, and the collision shapes that make each one computable.

The next map, Primitives_Portals, will push on the torus specifically — watching discrete ring counts approach the ideal circle as a limit process. That map is about approximation and infinity. This one is the prerequisite: understanding that "smooth" and "round" are not properties of an object but properties of the parameterization you chose to apply to it.

---

## Possible Artifacts

**resolution_slider_sphere** — A sphere with a live integer slider for `radial_segments` and `rings`, showing in real-time how increasing both parameters transitions from a faceted solid to apparent smoothness. Would make explicit that resolution is a continuous parameter, not a categorical difference. The three static LOD spheres imply a before/after; the slider shows the continuous space between them.

**dual_solid_visualizer** — Two objects side by side — a cube and its dual octahedron — with a visualization of the face-center-to-vertex correspondence: small spheres at cube face centers, lines connecting to octahedron vertices. Teaches duality as a structural relationship rather than a coincidence of vertex counts. Currently learners must infer this from holding the static objects; the visualization would make the mapping explicit.

**truncation_slider** — A tetrahedron with a float parameter (0.0 = regular tetrahedron, 1.0 = fully truncated). The corners gradually become triangular faces as the parameter increases, the original faces become hexagons. Would make truncation legible as a continuous operation rather than a discrete replacement — bridging the static `truncatedtetrahedron` display to the procedural generation logic that underlies the Archimedean family.