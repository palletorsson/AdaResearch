# 06 The Quad

In Primitives_Polythedra, you watched three triangular faces converge at a single vertex — a trihedron, a corner of space, volume beginning to form but not yet closed. The triangle is the GPU's atomic unit: three points, one plane, irreducible. Three triangles at a vertex give you a corner. Six give you a tetrahedron. But the triangle's rigidity is its defining constraint. Every face must be flat. Every surface becomes a tessellation of minimal units, rigid by construction.

The cube breaks from this. Eight vertices. Twelve edges. Six faces — not triangles, but quads. A quad is not atomic; it can be non-planar, flexible, deformable. It introduces a category of geometry that can be touched and perturbed without collapsing — a shape with agency baked into its structure.

This map assembles that cube from scratch, step by step, in front of you.

---

## Eight Points

The cube starts where everything starts: a point. Eight of them, arranged to mark the corners of a volume that doesn't yet exist.

The `animatedcubebuilder` constructs these first, in `create_vertex_spheres()`. Eight `Vector3` positions define the cube's corners at unit scale:

```gdscript
var vertices = [
    Vector3(-0.5, -0.5, -0.5),
    Vector3( 0.5, -0.5, -0.5),
    Vector3( 0.5,  0.5, -0.5),
    Vector3(-0.5,  0.5, -0.5),
    Vector3(-0.5, -0.5,  0.5),
    Vector3( 0.5, -0.5,  0.5),
    Vector3( 0.5,  0.5,  0.5),
    Vector3(-0.5,  0.5,  0.5),
]
```

Eight positions in 3D space. No edges yet. No faces. Just presence — the geometric minimum needed to imply a cube without constructing one.

This is what the sequence has been building toward. A point is `Vector3(x, y, z)`: position without extension. Here, eight points occupy positions that a cube would fill. The cube is already latent in their arrangement. The assembly reveals what is structurally implied.

The animation begins in `animate_vertices()`. Spheres appear at each corner — small, bright, marking existence in void. The mind draws the cube before the edges arrive.

---

## Twelve Edges

Connection transforms isolated points into topology. `create_edge_lines()` draws twelve line segments between the eight vertices — four along the bottom face, four along the top, four vertical. Each edge is a mesh built by `create_line_mesh()`:

```gdscript
func create_line_mesh(start: Vector3, end: Vector3) -> MeshInstance3D:
    var mesh = ImmediateMesh.new()
    mesh.surface_begin(Mesh.PRIMITIVE_LINES)
    mesh.surface_add_vertex(start)
    mesh.surface_add_vertex(end)
    mesh.surface_end()

    var mat = StandardMaterial3D.new()
    mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    mat.albedo_color = Color(0.9, 0.9, 1.0)

    var instance = MeshInstance3D.new()
    instance.mesh = mesh
    instance.material_override = mat
    return instance
```

`Mesh.PRIMITIVE_LINES` is the key. The GPU doesn't know about edges — it knows about vertices and primitives. A line is two vertices connected by the simplest possible primitive: no fill, no normal, just direction. The edge is topology made visible.

Twelve is not arbitrary. It is the minimum required to enclose a cube without redundancy. Remove one edge and the cube opens. Add one and you have a cycle that loops somewhere it doesn't need to go. Twelve is the exact number of constraints required to define a cube as a graph without over-determining it.

`animate_edges()` introduces these twelve sequentially, or in groups. What you see in the VR space is a wire frame emerging — the skeleton before the skin. At this stage, the cube has structure but no surface. It encloses space by implication, not by material fact.

---

## Triangles and the Face Problem

After edges, `create_triangle_meshes()` introduces faces — but not as quads. Under the hood, every face of the cube is two triangles. This is the GPU's requirement, not the cube's.

```gdscript
# Front face vertices: 0,1,2,3 (a planar quad)
# GPU requires triangles: split into (0,1,2) and (0,2,3)
# For a planar quad, both triangulations are equivalent
# For a non-planar quad, the diagonal determines the fold

func create_triangle_meshes():
    var surface_tool = SurfaceTool.new()
    surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    # Front face — two triangles sharing diagonal 0→2
    surface_tool.add_vertex(vertices[0])
    surface_tool.add_vertex(vertices[1])
    surface_tool.add_vertex(vertices[2])
    surface_tool.add_vertex(vertices[0])
    surface_tool.add_vertex(vertices[2])
    surface_tool.add_vertex(vertices[3])
    # ... remaining five faces
```

Here is the first moment where technical reality diverges from geometric ideal. A quad face — say, the front of the cube — is defined by four coplanar vertices. It's a flat square. But the GPU's rasterizer only fills triangles, so every quad is tessellated: split along a diagonal into two triangles, then rendered.

For a cube, this is invisible. All four vertices of each face are coplanar, so the diagonal creates no fold. The quad and its triangulated representation are identical. But this breaks for non-planar quads — the kind that appear in organic modeling, cloth simulation, terrain meshes. When a quad's four corners are not coplanar, the triangulation diagonal determines which fold you get. Geometry becomes contingent on an algorithm's arbitrary choice.

The cube hides this contingency. It is the cleanest possible quad surface: six faces, all perfectly planar. Later maps show what happens when planarity breaks.

---

## The Net: Two Dimensions Proving Three

The `polyhedron_nets_cube` artifact runs a different argument. It doesn't assemble the cube from vertices — it folds it from a flat pattern.

A net is a 2D unfolding of a 3D surface. Cut a cube along seven of its twelve edges and lay it flat. The result is a cross of six squares — the cube's faces rearranged into a plane. Fold it back and the cube re-emerges. `_create_cube_faces()` builds this from six `PlaneMesh` instances, each mounted on a hinge node:

```gdscript
func _create_cube_faces():
    var s = edge_length
    _cube_root = Node3D.new()
    add_child(_cube_root)

    # Center face — the base, never moves
    var center_face = _make_face(material)
    _cube_root.add_child(center_face)

    # Top face: hinge positioned at the fold line between center and top
    var top_hinge = Node3D.new()
    top_hinge.position = Vector3(0, 0, s * 0.5)
    _cube_root.add_child(top_hinge)

    var top_face = _make_face(material)
    top_face.position = Vector3(0, 0, s * 0.5)
    top_hinge.add_child(top_face)
    _cube_hinges["top"] = top_hinge
```

The hinge node is the key abstraction. Each face is parented to a hinge positioned at the fold line. When the hinge rotates, the face rotates around it. `_apply_fold()` drives all hinges simultaneously from a single `fold_progress` value:

```gdscript
func _apply_fold():
    var angle = deg_to_rad(90.0) * fold_progress
    if _cube_hinges.has("top"):
        _cube_hinges["top"].rotation.x = angle
    if _cube_hinges.has("bottom"):
        _cube_hinges["bottom"].rotation.x = -angle
    if _cube_hinges.has("left"):
        _cube_hinges["left"].rotation.z = angle
    if _cube_hinges.has("right"):
        _cube_hinges["right"].rotation.z = -angle
    if _cube_hinges.has("back"):
        # Back face must wait for the right face to clear — otherwise collision
        var back_progress = clamp((fold_progress - 0.15) / 0.85, 0.0, 1.0)
        _cube_hinges["back"].rotation.z = -deg_to_rad(90.0) * back_progress
```

`fold_progress` runs from 0.0 (flat net) to 1.0 (closed cube). Each face folds ninety degrees. The back face is delayed — `(fold_progress - 0.15) / 0.85` — because it must wait for the right face to begin moving, or they collide in space.

This sequencing is not an implementation detail. It encodes the order-dependency of folding: some faces cannot move until others are out of the way. Origami has the same constraint. The fold order is structural.

`_play_fold_animation()` drives the whole sequence through a Tween:

```gdscript
func _play_fold_animation():
    fold_progress = 0.0
    var tween = create_tween()
    tween.tween_interval(fold_delay)
    tween.tween_property(self, "fold_progress", 1.0, fold_duration) \
        .set_trans(Tween.TRANS_SINE) \
        .set_ease(Tween.EASE_IN_OUT)
```

`TRANS_SINE` with `EASE_IN_OUT` gives the fold a biological quality — it accelerates in, decelerates out. The faces arrive rather than snap. A linear fold reads as mechanical; a sine fold reads as intentional. The easing is a claim about how form comes into being.

---

## Volume and Enclosure

The net proves something the vertex assembly doesn't: the cube's surface is continuous. Six faces, properly folded, enclose a volume completely. No gaps. The surface is an exact boundary between inside and outside.

This is the cube's ontological claim. The tetrahedron from Primitives_Polythedra has four faces — the minimum for a closed 3D solid. The cube has six. It encloses more volume relative to its surface area, and its faces align perpendicular to the coordinate axes — which is why so much of 3D graphics defaults to cube-based reasoning. Bounding boxes, voxels, octrees, shadow maps, skyboxes. The cube is Cartesian space made solid.

It doesn't occur in nature. Crystals approach it; perfect cubes require manufacturing. It's a shape that belongs to mathematics and to machines.

When `create_final_mesh()` generates the completed solid, the construction scaffolding — the vertex spheres, the wire edges, the translucent triangles — gives way to an opaque mesh. The process disappears into the product. What you see in VR is a cube that wasn't there at the start of the animation and now is. Assembly as argument. The cube didn't arrive — it was built.

---

## The Dark Sphere as Invariant

The `dark_sphere` at grid position `(3,4)` — the center of the layout — stays constant while the cube assembles around it. Its `_process` loop is deliberate in its restraint:

```gdscript
func _process(delta: float) -> void:
    _time_elapsed += delta

    # Slow rotation with minimal wobble — never urgent
    if _sphere_mesh:
        _sphere_mesh.rotation.y += rotation_speed * delta
        _sphere_mesh.rotation.x = sin(_time_elapsed * 0.4) * 0.05

    # Sinusoidal emission pulse — barely perceptible
    if _sphere_material:
        var pulse_t := (sin(_time_elapsed * pulse_speed) + 1.0) * 0.5
        _sphere_material.emission_energy_multiplier = lerpf(pulse_min, pulse_max, pulse_t)
```

`rotation_speed` defaults to 0.15. `pulse_speed` to 1.2. `pulse_min` to 0.05. The sphere barely moves. Its emission barely fluctuates. It marks the inhabited space without competing for attention.

In VR, it serves a perceptual function: it provides a stable reference against which the cube's assembly registers as change. Without a fixed point, transformation is harder to perceive — the eye has nothing to compare against. The sphere is the invariant that makes the cube's becoming legible.

This is a design principle, not decoration. When building interactive geometry, you often need one element that doesn't change — not because it's unimportant, but because its constancy makes everything else readable. The sphere stays simple so the cube's structure can be felt against it.

---

## Interactive Constraint: Agency Within a System

The `animatedcubebuilder` includes grab handles — interactive points on the assembled cube that you can take in VR and pull. The cube doesn't collapse when you perturb it. It deforms within limits, then holds its new configuration.

This is the map's central argument.

A triangle is rigid. Three vertices, three edges — fully determined. You cannot deform a triangle without changing edge lengths or breaking connections. It is the minimal rigid polygon.

A quad is not rigid. Four vertices, four edges — one degree of freedom remains. In 2D, a quad can be sheared into a parallelogram without changing edge lengths. In 3D, a quad's four corners can be pulled out of plane, creating a saddle shape — a non-planar configuration that a triangle cannot express. The quad admits deformation.

The cube's faces are quads. When you grab a corner in the VR space and drag, you exercise that degree of freedom. The system constrains you — edges resist, opposite corners respond — but within those constraints, the shape yields. Agency is real; the system bounds it.

This is the QFEP signature of the map. The cube's enclosure is stable because its constraints are sufficient — but not over-determined. There is exactly enough structure to hold the shape, and exactly enough slack to allow touch. A perfectly rigid solid wouldn't feel interactive. A structureless volume wouldn't feel like a cube. The quad mesh sits at the productive edge between closure and openness — a local manifestation of λ ≈ 0.3–0.5: ordered enough to maintain identity, flexible enough to respond.

Later sequences return to this. Cloth simulation is a quad mesh under gravity and wind. Soft bodies are quad lattices with spring constraints. Physics engines for organics are built on the deformability this map introduces. The cube is the simplest possible introduction to geometry that yields.

---

## Toward Ignorance

Primitives_Ignorance, the next map, performs a reversal. After this sequence has built up a vocabulary — points, lines, triangles, tetrahedra, cubes — it asks you to unknow it. The primitive is no longer the simplest unit of geometry; it becomes the simplest unit of assumption.

The cube you assembled here is already a construct. Its perpendicularity to the coordinate axes, its equal-length edges, its planar faces — these are not properties of space. They are decisions. The cube is a specific solution to the problem of enclosure, not the only one.

The net shows this obliquely: there are eleven valid nets for a cube. Eleven different ways to unfold the same surface. The cube is not a unique unfolding; it is a family of decisions about where to cut. Primitives_Ignorance asks what happens when you stop treating those decisions as natural.

This map ends with a complete solid assembled in front of you. The next begins by asking whether you know what you're looking at.

---

## Possible Artifacts

**corner_constraint_visualizer** — Draws the manifold of valid positions for a single quad corner as you drag it, given that connected edges must maintain their length. Makes the deformation space of a quad legible as geometry rather than as behavior. The current map shows that quads flex; this would show exactly how.

**cube_stability_comparison** — Side-by-side display of a triangle, a quad, and a cube face under the same perturbation force. The triangle holds. The quad shears. The cube face deforms within its neighbors' constraints. The rigidity gradient from simplex to quad mesh is the map's core argument — it currently lives in the assembly animation and the grab handles, but not as explicit comparison.

**net_selection** — An interactable displaying all eleven valid cube nets laid flat, with the ability to fold any of them into the same cube. Currently only one net is shown. The eleven-net space makes the argument that the cube is not its unfolding but its result — the surface topology is invariant; its planar representation is not. This connects directly to Primitives_Ignorance's theme of assumption made visible.