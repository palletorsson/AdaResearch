# 06 The Quad

## From Three Points to Eight

In Primitives_Polythedra we met the trihedron: three triangular faces meeting at a single vertex, a corner of space that gestures at volume without completing it. A cube completes it. Eight vertices, twelve edges, six faces — the minimum structure that can contain.

This map shows that completion happening in real time. Four `animatedcubebuilder` instances run simultaneously at positions (2,4), (4,4), (2,8), and (4,8), each stepping through the same construction sequence: vertices first, then edges, then faces, then final mesh. Watching them in parallel makes something visible that a single instance obscures: the construction is a protocol. Every cube that has ever been built follows the same steps.

The sequence starts at the bottom of the scene hierarchy and works upward. Vertices are just positions — eight `Vector3` values at the corners of a unit cube:

```gdscript
var vertices: Array[Vector3] = [
    Vector3(-0.5, -0.5, -0.5),  # 0: left-bottom-back
    Vector3( 0.5, -0.5, -0.5),  # 1: right-bottom-back
    Vector3( 0.5,  0.5, -0.5),  # 2: right-top-back
    Vector3(-0.5,  0.5, -0.5),  # 3: left-top-back
    Vector3(-0.5, -0.5,  0.5),  # 4: left-bottom-front
    Vector3( 0.5, -0.5,  0.5),  # 5: right-bottom-front
    Vector3( 0.5,  0.5,  0.5),  # 6: right-top-front
    Vector3(-0.5,  0.5,  0.5),  # 7: left-top-front
]
```

These eight positions define the cube completely. Everything that follows — edges, faces, normals, UVs — is derived from them. The vertices are the only thing the cube _is_. The rest is how it _appears_.

## The Construction Sequence

The `animatedcubebuilder` steps through four stages: `animate_vertices`, `animate_edges`, `animate_triangles`, then `create_final_mesh`. Each stage reveals a different layer of the same structure.

Stage one: eight spheres placed at corners. The shape is already implied. You can read "cube" from eight arranged dots because the topology is latent in the geometry even before edges exist.

Stage two adds edges. Each edge is a line mesh connecting two vertices. The builder constructs them procedurally — a cylinder stretched between two points:

```gdscript
func create_line_mesh(start: Vector3, end: Vector3) -> MeshInstance3D:
    var direction = end - start
    var length = direction.length()
    var mesh = CylinderMesh.new()
    mesh.height = length
    mesh.top_radius = 0.01
    mesh.bottom_radius = 0.01
    var line = MeshInstance3D.new()
    line.mesh = mesh
    line.position = (start + end) * 0.5
    line.look_at(start, Vector3.UP)
    line.rotate_object_local(Vector3.RIGHT, PI * 0.5)
    return line
```

A cube has twelve edges. This function doesn't know that. It only knows two points. The topology — which vertices connect to which — is a separate fact encoded in an edge list, not in this function. Geometry and topology are always distinct, even when they appear merged.

Stage three adds triangle pairs as faces. Stage four collapses everything into a single optimized `ArrayMesh`. The individual edge and face objects disappear. What remains is indistinguishable from a cube built any other way.

## The Quad Is Two Triangles

Primitives_Polythedra worked entirely in triangles. The trihedron's faces are equilateral triangles — the GPU's native unit. A cube's faces are squares, and squares don't exist in the GPU's vocabulary.

Every rectangular face is two triangles:

```gdscript
# One face of a cube, as the GPU sees it
var face_verts: Array[Vector3] = [
    Vector3(-0.5, -0.5, 0),  # bottom-left
    Vector3( 0.5, -0.5, 0),  # bottom-right
    Vector3( 0.5,  0.5, 0),  # top-right
    Vector3(-0.5,  0.5, 0),  # top-left
]
# Triangle 1: bottom-left → bottom-right → top-right
# Triangle 2: bottom-left → top-right → top-left
var indices: Array[int] = [0, 1, 2,   0, 2, 3]
```

The quad is an abstraction that modeling software provides and the GPU discards. When you drag a corner vertex, both triangles sharing that vertex move. The face deforms as a unit, but it's still two independent triangle responses to one displacement.

`polyhedron_nets_cube` makes this explicit from another angle. It constructs each face as a `PlaneMesh` — Godot's quad primitive — before any folding occurs:

```gdscript
func _make_face(material: Material) -> MeshInstance3D:
    var mesh = PlaneMesh.new()
    mesh.size = Vector2(edge_length, edge_length)
    var face = MeshInstance3D.new()
    face.mesh = mesh
    face.material_override = material
    return face
```

Six calls to `_make_face`. Six squares. One cube waiting to happen.

## The Net and Its Hinges

The cube net is a cross: one center square, four squares extending from each cardinal edge, one more attached to an arm. Six faces, unfolded flat. The net is the cube's surface without its volume — topology preserved, spatial relations deferred.

`polyhedron_nets_cube` builds this with explicit hinge nodes, one per folding edge:

```gdscript
# Pivot lives at the shared edge between center and top face
var top_hinge = Node3D.new()
top_hinge.name = "TopHinge"
top_hinge.position = Vector3(0, 0, s * 0.5)
_cube_root.add_child(top_hinge)

# Face hangs from the pivot, extends outward
var top_face = _make_face(material)
top_face.position = Vector3(0, 0, s * 0.5)
top_hinge.add_child(top_face)
_cube_hinges["top"] = top_hinge
```

The hinge is at the edge. The face extends outward. Rotating the hinge rotates the face around that edge — exactly the motion of folding a physical net. The code structure mirrors the physical structure.

Folding is driven by a single float: `fold_progress`. At 0.0, flat. At 1.0, cube. `_apply_fold` reads that value and sets rotation on every hinge simultaneously:

```gdscript
func _apply_fold():
    if _cube_hinges.is_empty():
        return
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
        # Back face follows right — delayed so it closes last
        var back_progress = clamp((fold_progress - 0.15) / 0.85, 0.0, 1.0)
        var back_angle = deg_to_rad(90.0) * back_progress
        _cube_hinges["back"].rotation.z = -back_angle
```

The back face is delayed. `clamp((fold_progress - 0.15) / 0.85, 0.0, 1.0)` remaps the 0–1 range so back doesn't start moving until fold_progress reaches 0.15. The structural constraint of how a real net must fold — the back face can't close until the right arm has swung up — is encoded as a numeric offset in a lerp. Physics becomes arithmetic.

The animation is a tween over that one float:

```gdscript
func _play_fold_animation():
    fold_progress = 0.0
    var tween = create_tween()
    tween.tween_interval(fold_delay)
    tween.tween_property(self, "fold_progress", 1.0, fold_duration) \
        .set_trans(Tween.TRANS_SINE) \
        .set_ease(Tween.EASE_IN_OUT)
```

One property. Everything else follows from `_apply_fold`. This is what a well-designed setter does: isolate the state change so it propagates correctly regardless of what caused it.

## Volume and the Invariant Reference

The cube is the first shape in this sequence that encloses space. A point has position. A line has length. A triangle has area. A cube has volume — which means it has an inside. You can be inside a cube or outside it. That distinction doesn't exist for any primitive below it.

The `dark_sphere` at (3,4) serves as perceptual anchor for this. Its emission pulses on a sine curve. Its rotation wobbles slightly. It changes very little:

```gdscript
func _process(delta: float) -> void:
    _time_elapsed += delta
    if _sphere_mesh:
        _sphere_mesh.rotation.y += rotation_speed * delta
        _sphere_mesh.rotation.x = sin(_time_elapsed * 0.4) * 0.05
    if _sphere_material:
        var pulse_t := (sin(_time_elapsed * pulse_speed) + 1.0) * 0.5
        _sphere_material.emission_energy_multiplier = lerpf(pulse_min, pulse_max, pulse_t)
```

The X rotation wobble is `sin(_time_elapsed * 0.4) * 0.05` — barely perceptible on its own, but the slight motion makes it read as present rather than frozen. The sphere doesn't teach volume. It creates the perceptual conditions for the cubes to teach it.

Invariant references don't require complexity. The dark sphere works because it changes less than everything around it.

## Constraint as Interface

The fold mechanism demonstrates something beyond net-to-cube transformation. A hinge is a constraint — it allows rotation around one axis and prohibits all other motion. The cube corner grab handles work the same way: they allow translation along permitted degrees of freedom while the enclosure holds.

`fold_progress` is the parameter that expresses this. It doesn't say which face rotates or how much each hinge moves. It says only: "how folded is this?" The individual hinge behaviors are encoded separately. The learner interacts with one float. The geometry responds as a system.

The `apply_grid_config` function exposes this parameter publicly, letting the map file configure behavior without touching implementation:

```gdscript
func apply_grid_config(config_data: Dictionary) -> void:
    if config_data.has("fold_duration"):
        fold_duration = float(config_data.fold_duration)
    if config_data.has("fold_delay"):
        fold_delay = float(config_data.fold_delay)
    if config_data.has("auto_fold"):
        auto_fold = _parse_bool(config_data.auto_fold)
    if net_type == "cube" and auto_fold:
        _play_fold_animation()
```

Write `#fold_duration:6` in the map string and the net folds more slowly. The constraint structure stays the same. The timing changes. This is the difference between a parameter and a control — a parameter maps to intention ("how folded"), a control maps to action ("rotate this face"). Parameters are higher-abstraction interfaces over lower-level mechanisms.

## Motion Curves Are Statements

One detail in `_play_fold_animation` worth sitting with:

```gdscript
tween.tween_property(self, "fold_progress", 1.0, fold_duration) \
    .set_trans(Tween.TRANS_SINE) \
    .set_ease(Tween.EASE_IN_OUT)
```

`TRANS_SINE` means the fold doesn't move at constant speed. It accelerates at the start, decelerates at the end. `EASE_IN_OUT` applies this to both endpoints. The cube assembles with a breathiness that purely linear motion lacks.

This is not an aesthetic choice. Human perception of motion is nonlinear. A fold that arrives with the right deceleration reads as physically plausible — as if something with mass settled into position. The sine curve is a kinematic lie that produces a truer visual experience than the mathematically correct linear interpolation.

Every animation curve makes a claim about what kind of thing you're watching. `TRANS_SINE` + `EASE_IN_OUT` says: something soft, something with mass, something that belongs to physics. Not a data transaction. A physical event.

## Simultaneity and Protocol

The four `animatedcubebuilder` instances run synchronized. Watching four cubes assemble in parallel exposes what a single instance hides: each is doing the same thing, governed by the same functions, producing identical results. That's not a coincidence. It's how procedural construction works.

The builder doesn't store the cube — it generates it. `create_vertex_spheres`, `create_edge_lines`, `create_triangle_meshes`, `create_final_mesh` are called in sequence, driven by `_process(delta)`. Every frame tests where in the animation timeline the builder sits. The geometry emerges from time, not from a stored description.

This gap — between the data that drives construction and the visual state you see — is preparation for what comes next. In Primitives_Ignorance, the familiar shapes from this sequence (points, lines, cubes) are re-encountered as constructs rather than givens. The map asks whether formal mastery of the protocol means you understand what you've built. The cube you can fold and manipulate here is not the cube as concept. This map teaches you to make one. The next asks you to question it.

## Possible Artifacts

**vertex_displacement_demo** — A single cube where each corner vertex is grabbable, watching edge lengths and face angles change in real time as a vertex is displaced. The `animatedcubebuilder` shows construction; this shows deformation. The link between vertex position and face shape becomes tactile rather than observed.

**fold_manual** — An instance of `polyhedron_nets_cube` with `auto_fold: false` and a physical lever or slider driving `fold_progress` directly. The learner closes the net by hand. The delay in the back hinge — the constraint that prevents it from closing before the right arm has swung — becomes something felt, not watched.

**inside_out_cube** — A cube rendered with inverted normals, faces culled inward so only interior surfaces are visible. The learner steps into it. Inside/outside as an embodied distinction, not a diagrammatic one.