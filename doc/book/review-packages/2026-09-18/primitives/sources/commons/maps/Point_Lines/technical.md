# Point Lines - Technical Tutorial

Point_Lines expands the line primitive into system behavior.

## From Single Relation to Rule Set

A single line relation is local. Multiple lines require constraints:

- parallelism (shared direction)
- perpendicularity (orthogonal relation)
- proportional scaling
- projection/perspective convergence

## Constraint Example: Parallel Lines

```gdscript
var a0: Vector3
var a1: Vector3
var b0: Vector3
var b1: Vector3

var dir_a: Vector3 = (a1 - a0).normalized()
var dir_b: Vector3 = (b1 - b0).normalized()
var parallel_score: float = abs(dir_a.dot(dir_b))
# close to 1.0 => near parallel
```

Puzzle artifacts operationalize this by letting players drag endpoints until constraints are satisfied.

## Measurement Lane Pattern

Rows 12-14 pair visual line segments with measurement devices:

- line object for geometric relation
- laser measure for numeric distance readout
- stepped cube scale references

This dual channel (visual + numerical) helps anchor metric intuition.

## Perspective and Scale

Late-map artifacts (`perspective_lines`, `scale_lines`, `dgrid`) shift from local line editing to representational systems where lines organize how space is read.

## Implementation Notes

- Keep interactable rows dimension-consistent across all layers.
- Prefer explicit artifact staging zones over dense clustering.
- Validate map grammar after any placement edits.

## Key Takeaway

Point_Lines is where lines stop being isolated edges and become a framework for indexing, measuring, and projecting space.

## Sample Grid Generation

```gdscript
class_name LineGrid extends Node3D

@export var grid_size: Vector2i = Vector2i(8, 8)
@export var spacing: float = 1.0

func _ready() -> void:
    for y in range(grid_size.y):
        for x in range(grid_size.x):
            var point := POINT_SCENE.instantiate()
            point.position = Vector3(x, 0, y) * spacing
            add_child(point)
            if x + 1 < grid_size.x:
                connect_line(Vector2i(x, y), Vector2i(x + 1, y))
            if y + 1 < grid_size.y:
                connect_line(Vector2i(x, y), Vector2i(x, y + 1))

func connect_line(a: Vector2i, b: Vector2i) -> void:
    var line := LINE_SCENE.instantiate()
    line.start = Vector3(a.x, 0, a.y) * spacing
    line.end = Vector3(b.x, 0, b.y) * spacing
    add_child(line)
```

## Line Rendering

A line is drawn as a thin cylinder stretched between its endpoints.

```gdscript
class_name Line3D extends MeshInstance3D

@export var thickness: float = 0.02
var start: Vector3
var end: Vector3

func _ready() -> void:
    var cylinder := CylinderMesh.new()
    cylinder.top_radius = thickness
    cylinder.bottom_radius = thickness
    cylinder.height = start.distance_to(end)
    mesh = cylinder
    position = (start + end) / 2.0
    look_at(end, Vector3.UP)
    rotate_object_local(Vector3.RIGHT, PI / 2)
```

## Complexity

Line rendering is O(V) for V vertices in the grid, O(E) for E edges. For an 8×8 grid that is 64 points and 112 edges, which Godot renders effortlessly.

## Multi-Point Relations

Two points define a line. Three define a triangle. Four define a tetrahedron in 3D. The map's grid of points is the simplest possible demonstration that multiple points carry relational structure the individual points do not.

## Variants

Alternative representations include radial lines from a common centre, curves through sequences of points, and polylines that thread through the grid. The grid layout is the simplest but the sequence explores richer layouts in Point_Trace and Point_Line_Grid.

## Within the Sequence

Point_Lines is the second map in Primitives — the moment where multiplicity first enters the curriculum. The next map, Point_Line, formalises the binary relation that closure will later extend to polygons and meshes.

## Interaction Model

The learner can grab any point and move it. Connected lines update their endpoints accordingly, so moving a point translates into deformation of the surrounding structure. This makes the grid a live rather than static demonstration.

```gdscript
func _on_point_grabbed(point: Node3D, controller: XRController3D) -> void:
    while controller.is_grabbing():
        point.global_position = controller.global_position
        for line in point.connected_lines:
            line.update_endpoints()
        await get_tree().process_frame
```

## Line Thickness

Line rendering uses a minimum screen-space thickness so distant lines remain visible. A shader scales the cylinder's radius inversely with distance from the camera, producing consistent apparent thickness regardless of distance.

## Persistence

Point positions are not saved; each visit regenerates the grid from scratch. Grabbing and moving a point is a live interaction rather than an authoring workflow.

## Alternative Renderings

The sequence's later maps extend the line primitive into curves, traces, and tetrahedral meshes. Point_Lines' straight-line implementation is the baseline every later extension builds on.

## Performance

The map's grid is small enough that all rendering and interaction costs are trivial. For larger grids the geometry batches into MultiMeshInstance3D and scales to hundreds of thousands of instances on modern hardware. The map deliberately stays small because the concept being taught is multiplicity of points and their linear connections, and only a handful of examples is needed for the concept to land cleanly.


## Encounter reference, 15 September 2026

[Companion notes for the current book passage](encounter-reference.md) retain instrument settings, recording distinctions and code excerpts moved out of the main reading.


## Repeated proof and the ruler bench — 16 September 2026

The secondary `line_proof_pair` instantiates the existing plus puzzle twice through a scoped subclass, `commons/artifacts/line_proof_pair/repeatable_plus.gd`. It remains available as an optional comparison after the current book's simpler endpoint lesson. Both copies start at `stock=scattered`; A selects `proof=relation` and B `proof=invariant`. Both display the same reference targets. The subclass overrides completion with a current verdict, so changing the endpoints can revoke acceptance and success never hides or locks the handles. Ordinary plus puzzle scenes retain their previous completion behaviour.

The move buttons add one common world-space displacement to all four endpoints, obtained from a local vector through the puzzle's basis. The reference targets stay put. This preserves segment direction vectors and coincident midpoints while changing endpoint positions relative to the targets. Target proximity is checked from current geometry, not cached snap flags.

The geometric checks are approximate. `GeometryUtils.are_perpendicular` compares `abs(dir_a.dot(dir_b)) < 0.26`, with normalized directions; this value is a dot-product threshold, not an angle in radians. Midpoints must be within 0.05 m, and target membership uses the line's 0.08 m snap tolerance. The paired subclass rejects degenerate segments before testing their directions.

The restored `two_point_ruler` placement uses `#block_base_y:0.75`. This builds a supporting bench and raises the subject and witness while presenting the pickable ruler at the front. The default remains zero for existing placements. Holding the tip inside the subject's padded bounds and pressing its action reads the pale subject's mesh width in world metres. The same action separately tweens the witness scale by 0.72, bounded to 0.18–2.4. Leaving the subject re-arms the action; pressing away from it is refused.

The workshop uses private camera worlds. Its first camera is orthographic, and its four-line camera orbits automatically. Moving the visitor around a flat monitor does not move these cameras. Visitor camera control and an angle-only proof comparison are proposals for a later pass.
