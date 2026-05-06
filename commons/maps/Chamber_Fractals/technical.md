# Chamber Fractals — Technical

The fractal catalyst fires branching projectiles; the fractal_hydra regrows heads recursively. Neither system has a natural stopping point.

## Branching Projectile

```gdscript
class_name FractalProjectile extends RigidBody3D

@export var branch_depth: int = 2
@export var branch_angle: float = 20.0  # degrees
@export var branches_per_hit: int = 4

func on_hit(collision: KinematicCollision3D) -> void:
    if branch_depth <= 0:
        queue_free()
        return
    spawn_branches(collision.get_normal())
    queue_free()

func spawn_branches(normal: Vector3) -> void:
    var parent_dir: Vector3 = linear_velocity.normalized()
    for i in range(branches_per_hit):
        var child := FRACTAL_PROJECTILE_SCENE.instantiate()
        var offset_angle: float = TAU * i / branches_per_hit
        var axis: Vector3 = normal
        var direction: Vector3 = parent_dir.rotated(axis, offset_angle)
        direction = direction.rotated(axis.cross(parent_dir).normalized(), deg_to_rad(branch_angle))
        child.linear_velocity = direction * linear_velocity.length() * 0.7
        child.branch_depth = branch_depth - 1
        child.global_position = global_position
        get_tree().root.add_child(child)
```

## Fractal Hydra

Each head is a child node; cutting a head removes it and spawns two new heads in nearby positions.

```gdscript
class_name FractalHydra extends CharacterBody3D

var heads: Array = []

func _ready() -> void:
    for i in range(3):
        spawn_head()

func on_head_cut(head: Node3D) -> void:
    heads.erase(head)
    head.queue_free()
    # Regrow two new heads
    for _i in range(2):
        spawn_head_near(head.global_position)

func spawn_head() -> void:
    var head := HYDRA_HEAD_SCENE.instantiate()
    head.global_position = global_position + Vector3(randf_range(-1, 1), randf_range(0.5, 2), randf_range(-1, 1))
    head.cut.connect(_on_head_cut.bind(head))
    heads.append(head)
    add_child(head)

func spawn_head_near(position: Vector3) -> void:
    var head := HYDRA_HEAD_SCENE.instantiate()
    head.global_position = position + Vector3(randf_range(-0.5, 0.5), randf_range(-0.5, 0.5), randf_range(-0.5, 0.5))
    head.cut.connect(_on_head_cut.bind(head))
    heads.append(head)
    add_child(head)
```

## Science Screen — Depth Axis

The scatter plot tracks catalyst branch depth and hydra head count over time. Both curves tend to increase.

```gdscript
class_name FractalScreen extends Node3D

var projectile_depths: Array = []
var hydra_head_counts: Array = []
var timestamps: Array = []

func log_state(proj_depth: int, head_count: int) -> void:
    var t: float = Time.get_ticks_msec() / 1000.0
    timestamps.append(t)
    projectile_depths.append(proj_depth)
    hydra_head_counts.append(head_count)
    redraw_curves()
```

## Depth-Limited Termination

Both systems have implicit depth limits to prevent infinite recursion. The catalyst's branch_depth defaults to 2 (each shot produces 4 + 16 = 20 branches total). The hydra's heads do not grow indefinitely; a cap of 20 simultaneous heads prevents the scene from overwhelming the physics engine.

```gdscript
@export var max_hydra_heads: int = 20

func on_head_cut(head: Node3D) -> void:
    heads.erase(head)
    head.queue_free()
    var new_head_count: int = min(2, max_hydra_heads - heads.size())
    for _i in range(new_head_count):
        spawn_head_near(head.global_position)
```

## Complexity

Projectile branching is O(branches_per_hit^depth); at depth 2 and 4 branches, that is up to 16 final projectiles per shot. Hydra head management is O(heads). The chamber caps counts to keep per-frame cost bounded.

## Within the Sequence

Chamber_Fractals stages infinite regress as a combat problem the learner cannot win by finishing.

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

## Victory Condition

The chamber has no victory state. Both systems grow indefinitely within their caps, and the session ends when the learner chooses to leave.