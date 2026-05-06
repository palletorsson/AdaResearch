# Chamber Transformation — Technical

The chamber holds a miura_crawler creature that responds to the transformation catalyst by folding rather than taking damage.

## Catalyst Projection

The transformation catalyst fires a projectile tagged with a folding operator. On contact, the operator is applied to the creature's fold state.

```gdscript
class_name TransformationCatalyst extends Node3D

@export var fire_cooldown: float = 0.4
var time_since_fire: float = 0.0

func _process(delta: float) -> void:
    time_since_fire += delta

func fire(direction: Vector3) -> void:
    if time_since_fire < fire_cooldown: return
    time_since_fire = 0.0
    var projectile := FOLD_PROJECTILE_SCENE.instantiate()
    projectile.global_position = global_position
    projectile.linear_velocity = direction * 8.0
    projectile.operator = "fold"
    get_tree().root.add_child(projectile)
```

## Miura Crawler Fold State

The creature has a single state variable — fold_amount — that interpolates from 0 (fully unfolded) to 1 (fully folded flat). Each catalyst hit pushes the state toward 1.

```gdscript
class_name MiuraCrawler extends CharacterBody3D

@export var fold_decay_rate: float = 0.1  # per second; folds drift back to unfolded
@export var hit_fold_increment: float = 0.3

var fold_amount: float = 0.0

func _process(delta: float) -> void:
    fold_amount = max(0.0, fold_amount - fold_decay_rate * delta)
    update_mesh_for_fold(fold_amount)

func on_catalyst_hit(operator: String) -> void:
    if operator == "fold":
        fold_amount = min(1.0, fold_amount + hit_fold_increment)
```

## Miura Pattern Mesh Deformation

The Miura fold pattern is a tessellation of parallelograms that alternate their crease directions. As fold_amount increases, the pattern compresses along one axis.

```gdscript
func update_mesh_for_fold(amount: float) -> void:
    var vertices: PackedVector3Array = base_vertices.duplicate()
    var compression: float = 1.0 - amount * 0.8  # 20% of extent at fully folded
    for i in range(vertices.size()):
        var v := vertices[i]
        # Compress along the fold axis (y)
        v.y *= compression
        # Add crease displacement
        var crease_offset: float = amount * 0.3 * sin(v.x * PI)
        v.z += crease_offset
        vertices[i] = v
    mesh.surface_update_vertex_region(0, 0, vertices.to_byte_array())
```

## Science Screen Logging

Each fold event is logged as a scatter-plot entry: (fold_amount, time).

```gdscript
class_name TransformationScreen extends Node3D

var events: Array = []  # [{fold_amount, time, compression_ratio}]

func log_fold(amount: float, compression_ratio: float) -> void:
    events.append({
        "fold_amount": amount,
        "time": Time.get_ticks_msec() / 1000.0,
        "compression_ratio": compression_ratio,
    })
    redraw_scatter()
```

## Befriending

After sustained folded state (fold_amount above 0.8 for several seconds), the crawler enters a befriended state and follows the learner to subsequent chambers.

```gdscript
var sustained_fold_time: float = 0.0
@export var befriend_threshold: float = 3.0

func _process(delta: float) -> void:
    super(delta)
    if fold_amount > 0.8:
        sustained_fold_time += delta
    else:
        sustained_fold_time = max(0.0, sustained_fold_time - delta)
    if sustained_fold_time > befriend_threshold:
        befriend()
```

## Complexity

Projectile updates are O(active projectiles). Mesh deformation is O(vertex count) per fold update, but updates are infrequent (only on hit or passive decay). The chamber runs at full VR frame rate with several active projectiles.

## Within the Sequence

Chamber_Transformation is the first creature encounter in the curriculum. It establishes the catalyst-as-state-inducer pattern that every subsequent chamber extends.

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

## Catalyst Persistence

The transformation catalyst remains in the learner's kit after the chamber, available for the remainder of the curriculum. Other chambers accumulate similarly — catalysts, once collected, stay collected.