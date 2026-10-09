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
