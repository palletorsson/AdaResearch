# Trans Pit — Technical

Three rooms stage translation, rotation, and scaling as lethal hazards. Each room has fire pits at height 1 and a transformation-driven obstacle that pushes the learner toward them.

## Translation Room

Pusher blocks translate along a fixed axis at configured speed and distance.

```gdscript
class_name PusherBlock extends StaticBody3D

@export var axis: Vector3 = Vector3.RIGHT
@export var distance: float = 4.0
@export var speed: float = 2.0
@export var pause_duration: float = 0.5

var start_position: Vector3
var phase: float = 0.0  # 0..1, 0 at start, 1 at end

enum State { MOVING_FORWARD, PAUSED_AT_END, MOVING_BACK, PAUSED_AT_START }
var state: State = State.MOVING_FORWARD
var time_in_state: float = 0.0

func _ready() -> void:
    start_position = global_position

func _physics_process(delta: float) -> void:
    time_in_state += delta
    match state:
        State.MOVING_FORWARD:
            phase = min(1.0, phase + delta * speed / distance)
            if phase >= 1.0: state = State.PAUSED_AT_END; time_in_state = 0.0
        State.PAUSED_AT_END:
            if time_in_state >= pause_duration: state = State.MOVING_BACK; time_in_state = 0.0
        State.MOVING_BACK:
            phase = max(0.0, phase - delta * speed / distance)
            if phase <= 0.0: state = State.PAUSED_AT_START; time_in_state = 0.0
        State.PAUSED_AT_START:
            if time_in_state >= pause_duration: state = State.MOVING_FORWARD; time_in_state = 0.0
    global_position = start_position + axis * distance * phase
```

## Rotation Room

A revolving wall rotates at constant angular velocity, sweeping the arena.

```gdscript
class_name RevolvingWall extends StaticBody3D

@export var angular_velocity: float = 1.0  # radians per second

func _physics_process(delta: float) -> void:
    rotate_y(angular_velocity * delta)
```

## Scaling Room

A grower block expands at a steady scale rate, shrinking the safe footprint.

```gdscript
class_name GrowerBlock extends StaticBody3D

@export var scale_rate: float = 0.2  # scale units per second
@export var max_scale: float = 3.0

var current_scale: float = 1.0

func _physics_process(delta: float) -> void:
    current_scale = min(max_scale, current_scale + scale_rate * delta)
    scale = Vector3.ONE * current_scale

func reset() -> void:
    current_scale = 1.0
    scale = Vector3.ONE
```

## Fire Hazard

Fire pits use the shared h:fire hazard code from the DangerZone utility registry. Contact with a fire pit triggers the DeathEffect sequence.

```gdscript
# DangerZone lookup
func hazard_at(coords: Vector2i) -> String:
    return utilities.get(coords, {}).get("hazard", "")

func _on_body_entered(body: Node) -> void:
    if body.is_in_group("learner"):
        if hazard_at(current_cell(body)) == "fire":
            DeathEffect.trigger(body, "fire")
```

## Room Layout

Each room is a small enclosed area with fire pits around its perimeter and the transformation obstacle in its centre or line of travel. The rooms are connected by short corridors so the learner can progress or retry.

## Complexity

Pusher and grower updates are O(1) per frame. The revolving wall is also O(1). Fire hazard checks are O(1) per body per frame. The whole map runs comfortably at VR frame rate.

## Within the Sequence

Trans_Pit converts the sequence's algebraic transformations into physical stakes. The learner has studied translation, rotation, and scaling as operations; this map makes the operations hazards when applied to inhabited space.

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

## Within the Curriculum

Trans_Pit is the Transformation sequence's stakes map. Other maps in the sequence introduce operations as observations; this map makes them hazards.