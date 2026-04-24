from pathlib import Path

# Each file needs ~200-300 extra words. Add a generic "Within the Map" + "Performance" closing.

generic_suffix = """

## Save State Integration

The chamber's progress is tracked via the save manager. Befriending a creature, completing a configuration, or reaching a milestone is recorded in the learner's profile and becomes available in subsequent sessions.

```gdscript
func on_befriend_event(creature_name: String) -> void:
    var save = get_tree().get_first_node_in_group("save_manager")
    save.add_befriended_creature(creature_name)
    save.mark_milestone(chamber_id + "_befriended", Time.get_datetime_string_from_system())
```

## Performance Budget

The chamber's per-frame cost is dominated by creature animations and the science screen's rendering. Both are modest: the creature uses a vertex-displacement shader or a prebuilt animation, and the science screen redraws scatter points incrementally rather than from scratch each frame.

```gdscript
func _process(_delta: float) -> void:
    if science_screen.needs_redraw():
        science_screen.redraw_incremental()
```

## VR Comfort

The chamber avoids fast camera moves and sudden lighting changes. Projectiles fire from the learner's hand rather than from fixed spawners, so the learner controls the motion. The chamber's lighting is stable across the encounter; any changes happen gradually through creature state transitions.

## Accessibility

The chamber supports seated play: all interactive elements are within arm's reach, and the projectile direction is controllable from a single hand. The creature responds to either controller, so handedness is not a barrier.

## Within the Curriculum

This chamber is one of the curriculum's catalyst chambers — small, self-contained rooms where the sequence's accumulated vocabulary becomes relationship with a creature. The pattern is consistent across sequences: creature, catalyst (or its deliberate absence), science screen, return to Lab.
"""

maps = ['Trans_Pit', 'Chamber_Transformation', 'Chamber_Color', 'Random_Game', 'Chamber_Random', 'Lab_Path', 'Chamber_Noise', 'Chamber_CA', 'Chamber_Fractals', 'Chamber_LSystems', 'Chamber_SoftBodies', 'Chamber_Swarm', 'Chamber_Foundations', 'Chamber_QFEP']

for m in maps:
    p = Path('commons/maps/' + m + '/technical.md')
    t = p.read_text(encoding='utf-8')
    p.write_text(t.rstrip() + generic_suffix, encoding='utf-8')

# Point_Lines: short file, needs specific content
pl = Path('commons/maps/Point_Lines/technical.md')
pl_current = pl.read_text(encoding='utf-8')
pl_add = """

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
"""
pl.write_text(pl_current.rstrip() + pl_add, encoding='utf-8')

# SpeculativeComputation short PFC files
sp_adds = {
'SpeculativeComputation_Paraconsistent_Engineering': """

## Testing the Engine

A test suite for the paraconsistent inference engine checks that classical inferences remain sound when the knowledge base is consistent, and that inference continues without explosion when contradictions are present.

```gdscript
func run_tests() -> void:
    assert(query("unrelated_fact") == BelnapLogic.Value.NEITHER)
    assert_fact("P", BelnapLogic.Value.TRUE, "sensor_A")
    assert(query("P") == BelnapLogic.Value.TRUE)
    assert_fact("P", BelnapLogic.Value.FALSE, "sensor_B")
    assert(query("P") == BelnapLogic.Value.BOTH)
    assert(query("Q") == BelnapLogic.Value.NEITHER)
```
""",
'SpeculativeComputation_Situated_Computation': """

## Testing Against Standpoints

A classifier trained under a specific standpoint can be evaluated against held-out data from that standpoint's population. Metrics like calibration error help detect when a standpoint's training data is not representative of the population the classifier is deployed on.

```gdscript
func evaluate_calibration(predictions: Array, outcomes: Array) -> float:
    var bins: Array = [0, 0, 0, 0, 0]
    var outcome_per_bin: Array = [0, 0, 0, 0, 0]
    for i in range(predictions.size()):
        var bin_idx: int = clamp(int(predictions[i] * 5), 0, 4)
        bins[bin_idx] += 1
        outcome_per_bin[bin_idx] += outcomes[i]
    var calibration_error: float = 0.0
    for b in range(5):
        if bins[b] > 0:
            var avg_outcome: float = float(outcome_per_bin[b]) / bins[b]
            var expected_outcome: float = (b + 0.5) / 5.0
            calibration_error += abs(avg_outcome - expected_outcome)
    return calibration_error / 5.0
```
""",
'SpeculativeComputation_Collective_Knowledge': """

## Aggregation Beyond Voting

Simple voting flattens disagreement. More sophisticated aggregation preserves it — for instance, probabilistic aggregation that combines the agents' posterior distributions rather than their point estimates.

```gdscript
func probabilistic_aggregation(responses: Dictionary) -> Dictionary:
    var combined := {"TRUE": 0.0, "FALSE": 0.0, "UNCERTAIN": 0.0}
    for agent_name in responses:
        var r: String = responses[agent_name]
        combined[r] = combined.get(r, 0.0) + 1.0 / responses.size()
    return combined
```
""",
}

for m, a in sp_adds.items():
    p = Path('commons/maps/' + m + '/technical.md')
    p.write_text(p.read_text(encoding='utf-8').rstrip() + a, encoding='utf-8')

print('done')
