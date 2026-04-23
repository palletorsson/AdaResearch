# 09 Melencolia

## The Final Primitive

The primitives sequence ends here. Twelve maps: from a point with no extension, through lines, triangles, cubes, portals, and topological transformations — arriving at this, a map named after Dürer's 1514 engraving, *Melencolia I*. The winged figure in that engraving sits surrounded by every tool of geometry and measurement — compass, scale, hourglass, magic square, polyhedron — and stares into the distance. Thinking.

The tools are complete. The thinking is not.

In Primitives_Portals we saw the circle approached from the outside — discrete rings whose count pushed toward the irrational limit of π. The curve was never reached; approximation was the lesson. Melencolia takes that same motif and grounds it: not the limit of a sequence, but the limit of what tools alone can deliver.

Every primitive in this map is a closed form. The pyramid. The torus. The truncated rhombohedron. The magic square. Each is structurally complete. None of them tells you what to build next.

---

## Five Vertices, One Form

The map opens with four static pyramids at the corners of the space — positions (1,1), (5,1), (1,5), and (5,5). These are `pyramid` fixtures, their geometry built at runtime by `pyramid.gd`.

A square pyramid has five vertices: four base corners and one apex. `_create_pyramid_vertices()` encodes them exactly:

```gdscript
func _create_pyramid_vertices() -> Array[Vector3]:
    var vertices: Array[Vector3] = []
    var half_base := base_size * 0.5
    vertices.append_array([
        Vector3(-half_base, 0, -half_base),  # back-left
        Vector3(half_base, 0, -half_base),   # back-right
        Vector3(half_base, 0, half_base),    # front-right
        Vector3(-half_base, 0, half_base),   # front-left
        Vector3(0, pyramid_height, 0)        # apex
    ])
    return vertices
```

Five positions. Then `_create_pyramid_faces()` describes how those positions connect:

```gdscript
func _create_pyramid_faces() -> Array:
    return [
        [0, 2, 1],  # base triangle 1
        [0, 3, 2],  # base triangle 2
        [0, 1, 4],  # back side
        [1, 2, 4],  # right side
        [2, 3, 4],  # front side
        [3, 0, 4]   # left side
    ]
```

Six triangles total: two for the square base, four lateral faces. These face indices are invariant — the same integers regardless of `pyramid_height` or `base_size`. What changes with those parameters is only the *embedding* of the topology in 3D space. The face list describes connectivity. The vertex positions describe shape. They are separate concerns.

`_rebuild_pyramid()` calls both, then hands them to `PrimitiveMeshBuilder`:

```gdscript
func _rebuild_pyramid() -> void:
    var geometry := _pyramid_geometry()
    var material = GridMaterialFactory.make(base_color)
    _mesh_instance = PrimitiveMeshBuilder.build_mesh_instance(
        geometry["vertices"],
        geometry["faces"],
        { "name": "Pyramid", "material": material }
    )
    add_child(_mesh_instance)
```

The grid shader from `GridMaterialFactory.make()` makes face normals visible as surface orientation — the four lateral faces read as distinct planes rather than a continuous silhouette. Four corner pyramids teach by repetition: same face list, same result, four times over. Topology and geometry are separate. The pyramid's identity is in the indices; its presence is in the vectors.

---

## Proportion as Meaning

At the center cluster around (3,3), a `pyramidlong` stands beside a `cube_scene`. Same vertex count as the corner pyramids — five positions, the same face list structure — but with `pyramid_height: float = 2.8` against a base of 0.8×0.8. Proportion has changed. Topology has not.

`pyramidlong.gd` runs the same SurfaceTool pattern:

```gdscript
func create_pyramid():
    var st = SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var vertices = create_pyramid_vertices()
    var faces = create_pyramid_faces()
    for face in faces:
        add_triangle_with_normal(st, vertices, face)
    var mesh_instance = MeshInstance3D.new()
    mesh_instance.mesh = st.commit()
    apply_queer_material(mesh_instance, base_color)
    add_child(mesh_instance)
```

Identical algorithm. But `pyramid_height = 2.8` against a 0.8 base makes the output read as a spire — an obelisk, a monument — where the corner pyramids read as stable mounds. The same six face indices, the same five vertex slots, produce an entirely different spatial character.

Proportion is a dimension of meaning that the topology cannot encode. A face list is indifferent to aspect ratio. The `cube_scene` beside the long pyramid stages the contrast explicitly: a cube's uniform proportions against the vertical excess of the pyramid. What you see in the center of the map is a claim: that the most basic parameter of a shape, its dimensional ratio, changes phenomenological character completely, while leaving the underlying structure intact.

---

## Building by Hand: The Snap Puzzle

The `snap_pyramid_puzzle` at (3,1) shifts the relationship from observation to construction.

Five ghost snap points mark target positions in space — four base corners, one apex — rendered as pink-emissive transparent targets by `_apply_puzzle_materials()` in `snap_pyramid_puzzle.gd`. You pick up snap-point objects from elsewhere in the map and bring them into alignment with those targets. When all five are placed, `_on_pyramid_formed()` fires:

```gdscript
func _on_pyramid_formed(points: Array) -> void:
    var our_points_count = 0
    for point in points:
        if point in snap_points:
            our_points_count += 1
    if our_points_count == 5:
        _complete_puzzle()
```

The completion check is exact. Five points. All matching. The puzzle doesn't care about the order you placed them, or the path you took — only that the final configuration is achieved. `_complete_puzzle()`, defined in the parent class `SnapPointPuzzleBase`, handles the reward logic.

The detection pattern is set intersection: `snap_points` is this puzzle's required positions; `points` is the global list of currently-connected snap objects. The loop counts overlap. If overlap equals the required count, the shape exists.

This generalizes directly. `SnapTetrahedronPuzzle` checks for 4 points; `SnapOctahedronPuzzle` checks for 6. The specific polyhedron is encoded in the target positions, not in the detection algorithm. Any convex polyhedron becomes a completion-detection problem: define the required positions, count the matches, fire when they converge.

The puzzle is the map's fulcrum. Everything the primitives sequence has taught — vertex positions, face connectivity, the distinction between topology and geometry — here requires your body. You cannot understand the pyramid's five-vertex structure by reading the array. You have to navigate to each position and snap the point into place. Understanding is enacted.

---

## Dürer's Problem

The `durer_scene` at (3,12) contains the objects from Melencolia I itself: a truncated rhombohedron and a 4×4 magic square. Both are real artifacts from the engraving, built in GDScript.

`DurerPolyhedron.gd` constructs the rhombohedron in `_generate_durer_solid()` — a rhombohedron stretched along the Y axis, then truncated at two vertices, yielding 8 faces: 6 irregular pentagons and 2 equilateral triangles:

```gdscript
func _generate_durer_solid() -> ArrayMesh:
    var st = SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var s = size
    var h = 1.5 * s
    var w = 1.0 * s
    # Top triangular face
    var t0 = Vector3(0, h * 1.1, -w * 0.4)
    var t1 = Vector3(w * 0.7, h * 0.95, w * 0.35)
    var t2 = Vector3(-w * 0.7, h * 0.95, w * 0.35)
    # ... middle rings, pentagon faces, triangulation
    st.generate_normals()
    return st.commit()
```

Pentagon faces cannot be passed to the GPU as-is — the rasterizer only accepts triangles. `_add_pentagon()` performs fan triangulation from the first vertex:

```gdscript
func _add_pentagon(st: SurfaceTool, verts: Array):
    for i in range(1, verts.size() - 1):
        _add_triangle(st, verts[0], verts[i], verts[i + 1])
```

Fan triangulation works for any convex polygon: fix one vertex, draw edges to every non-adjacent vertex, fill the resulting triangles. It fails for concave polygons — a limitation this solid doesn't hit, but the algorithm's constraint is worth noting. Every rendering pipeline eventually hits the triangle as its irreducible unit.

The magic square in `MagicSquare.gd` places 16 numbers in a 4×4 grid where every row, column, and diagonal sums to 34:

```
16  3  2 13
 5 10 11  8
 9  6  7 12
 4 15 14  1
```

`_create_cell()` highlights the bottom-center cells:

```gdscript
if row == 3 and (col == 1 or col == 2):
    text_color = Color(1.0, 0.85, 0.3)  # Gold
```

Those cells contain 15 and 14. The year: 1514. A number-theoretic structure that encodes its own date of composition.

The Dürer solid is the most complex primitive in this sequence. Its faces are neither squares nor equilateral triangles; its construction requires vertex positions derived from proportional analysis of the original engraving. It sits in this map as an existence proof: that geometric forms can carry historical specificity, that a vertex array can hold a cultural object.

---

## The Torus and Radial Distribution

The elevated tier at (3,10) holds the `diamondtoruscollection` — seven diamonds hanging from a torus ring via thin cylinders. Their positions are computed by `create_hanging_arrangement()`:

```gdscript
for i in range(diamond_count):
    var angle = (i / float(diamond_count)) * 2.0 * PI
    
    var torus_position = Vector3(
        cos(angle) * torus_radius,
        0,
        sin(angle) * torus_radius
    )
    
    var diamond_position = Vector3(
        cos(angle) * torus_radius,
        -cylinder_length,
        sin(angle) * torus_radius
    )
```

`(i / float(diamond_count)) * 2.0 * PI` divides the full circle into equal arcs. When `diamond_count` is 7, each diamond sits at 51.4° from its neighbor. When it's 6, exactly 60°. The formula is indifferent to the count — it distributes whatever you give it, evenly.

This is the pattern behind regular polygons, clock faces, the hexagonal lattice of a honeycomb. The torus is the form whose symmetry group allows equal radial distribution: there is no preferred starting position on a circle. `torus_radius: float = 2.0` sets the circumference; `cylinder_length: float = 1.0` controls how far each diamond descends.

Walk around the collection and the spacing holds from every angle. From directly above, the diamonds form a regular polygon — the torus makes the polygon's vertices visible as hanging objects in 3D space. The elevated placement is not decorative; standing at floor level, you look up at the arrangement. Radial symmetry is embodied by being inside it.

---

## The Hollow Frame: Absence as Structure

The `bigframe` — a `boxbeam` — appears in this map as a threshold geometry. Its construction reveals something the solid primitives obscure.

A solid box needs 8 vertices. A hollow frame — a portal you can walk through — requires 16: four outer corners and four inner corners on both front and back faces. `boxbeam.gd` names this explicitly:

```gdscript
var scaled_vertices = [
    # Front outer (0-3)
    Vector3(-half_w - t, -half_h - t, half_d),
    Vector3(half_w + t, -half_h - t, half_d),
    Vector3(half_w + t, half_h + t, half_d),
    Vector3(-half_w - t, half_h + t, half_d),
    # Front inner (4-7)
    Vector3(-half_w, -half_h, half_d),
    Vector3(half_w, -half_h, half_d),
    Vector3(half_w, half_h, half_d),
    Vector3(-half_w, half_h, half_d),
    # Back outer (8-11), Back inner (12-15)
    # ...
]
```

Where `t` is `thickness`. The sixteen faces connect outer-to-inner on front, outer-to-inner on back, front-outer-to-back-outer, front-inner-to-back-inner. The opening — the walkable aperture — is not in the vertex list. It is the gap between the inner corners. The frame's identity is its negative space.

This is the first primitive in the sequence whose essential characteristic is what it excludes rather than what it encloses. A cube encloses volume. A pyramid terminates in a point. The frame frames an absence. The geometry describes a boundary around nothing.

The `dark_sphere` at (2,5) completes this atmospheric logic. It pulses between `pulse_min: float = 0.05` and `pulse_max: float = 0.35` emission at `pulse_speed: float = 1.2`, rotating slowly with a slight wobble on X. Its `_process()` drives the oscillation every frame but changes very little — it serves as the perceptual anchor, the reference body against which the other elements read. Not all objects in a space need to teach. Some need to stabilize perception.

---

## The Axioms Display

The `code_display` at (3,13) renders `melencolia_axioms` — tutorial text loaded via `codeDisplay.gd`'s `set_tutorial()` method. `apply_grid_config()` receives the configuration from the grid system and routes it to the library:

```gdscript
func apply_grid_config(config_data: Dictionary) -> void:
    if config_data.has("tutorial"):
        var tutorial_key = str(config_data.tutorial).strip_edges()
        set_tutorial(tutorial_key)
```

`set_tutorial()` calls into `TutorialTextLibrary`, which loads the content from `tutorial_text.json`. The axioms themselves are stored in that file and are not listed in this map's artifact metadata — their propositional content exists outside the geometry.

This is intentional. Some knowledge is transmitted as proposition rather than manipulation. The axioms display acknowledges that not everything can be demonstrated by moving objects in space. The pixel renders text; text carries the things that geometry cannot carry directly.

---

## What Comes Next

This is the last map in the primitives sequence. Every operation performed across these twelve lessons — building vertex arrays, defining face indices, constructing meshes via `SurfaceTool`, computing radial positions, detecting topological completion — has been purely positional. Points placed in space. Edges connecting them. Faces enclosing volume.

The transformations sequence asks a different question: what happens when these objects move, rotate, and scale? Not what a shape is, but what it does under change. The vertex positions you've been placing throughout this sequence become inputs to transformation matrices. The same pyramid you built here becomes a different lesson once it starts moving — rotation reveals which symmetries it has, scaling tests which proportions hold, translation asks what stays invariant under displacement.

That question changes the kind of understanding required. A vertex array tells you where something is. A transformation tells you where it goes. Melencolia marks the boundary between those two regimes. The tools are present. The forms are complete.

Build anyway.

---

## Possible Artifacts

**vertex_position_readout** — No artifact in this map allows the learner to examine the raw Vector3 coordinates of any primitive. A hover-triggered display showing each vertex position for the pyramid, the Dürer solid, or the torus collection would close the gap between seeing the form and knowing its numbers. The axiom "five vertices define a pyramid" becomes verifiable rather than stated.

**durer_proportions_slider** — `DurerPolyhedron.gd` exposes `size: float` and `rotate_slowly: bool` but no live parameter adjustment is present in this map. A grabbable slider controlling the `size` export — rebuilding the solid in real time via the existing `set_size()` setter — would let the learner see how the proportional logic of the engraving's original solid changes under scaling. The artifact has the infrastructure; it needs a control surface.

**axiom_label_cluster** — The `code_display` at (3,13) shows the melencolia axioms only when approached directly. A cluster of floating `Label3D` nodes showing the key axioms spatially — positioned near the artifacts they describe — would make propositional content as spatially present as geometric form. Currently, the axioms are legible only at one point; the geometry can be seen from anywhere in the map.