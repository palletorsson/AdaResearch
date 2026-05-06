# Chamber Foundations — Technical

The paradox_stalker creature exists in two overlapping ghost states. Only one inflicts damage; the other is undetectable from inside the chamber.

## Dual-State Creature

```gdscript
class_name ParadoxStalker extends CharacterBody3D

var ghost_a: ParadoxGhost
var ghost_b: ParadoxGhost
var lethal_ghost: ParadoxGhost  # one of the two, randomised per encounter

func _ready() -> void:
    ghost_a = spawn_ghost("a")
    ghost_b = spawn_ghost("b")
    lethal_ghost = ghost_a if randf() < 0.5 else ghost_b

func spawn_ghost(id: String) -> ParadoxGhost:
    var ghost := PARADOX_GHOST_SCENE.instantiate()
    ghost.ghost_id = id
    add_child(ghost)
    return ghost

func _physics_process(_delta: float) -> void:
    # Both ghosts move identically, so they remain visually indistinguishable
    var target := learner.global_position
    var direct_direction: Vector3 = (target - global_position).normalized()
    for ghost in [ghost_a, ghost_b]:
        ghost.velocity = direct_direction * 1.0
        ghost.move_and_slide()
```

## Damage Routing

Only the lethal ghost can damage the learner on contact.

```gdscript
class_name ParadoxGhost extends CharacterBody3D

@export var ghost_id: String = "a"

func _on_body_entered(body: Node) -> void:
    if not body.is_in_group("learner"): return
    var stalker: ParadoxStalker = get_parent()
    if self == stalker.lethal_ghost:
        DeathEffect.trigger(body, "paradox")
    else:
        # Pass-through; no effect
        pass
```

## No Catalyst

The learner has no catalyst in this chamber. The attempt to distinguish the ghosts is performed by firing existing catalysts from previous chambers; none distinguishes them, because no in-chamber test could.

```gdscript
# Catalyst hit routes to both ghosts
func on_any_catalyst_hit(hit_ghost: ParadoxGhost) -> void:
    # Regardless of which ghost was hit, the hit registers but does nothing identifying
    if randf() < 0.5:
        # Show a hit marker on ghost_a
        pass
    else:
        # Show a hit marker on ghost_b
        pass
```

## Science Screen — Converging Hit Rate

The screen plots a running hit-rate curve that converges to exactly 0.5 regardless of the learner's strategy.

```gdscript
class_name ParadoxScreen extends Node3D

var attempts: int = 0
var hits: int = 0
var hit_rate_curve: Array = []

func log_attempt(was_lethal_hit: bool) -> void:
    attempts += 1
    if was_lethal_hit:
        hits += 1
    hit_rate_curve.append(float(hits) / attempts)
    redraw_curve()
```

## Godelian Interpretation

The chamber's lesson is a limit rather than a skill. No in-chamber test resolves the paradox_stalker's identity because the distinguishing information is not in the chamber.

```gdscript
# An honest panel explains this
class_name HonestPanel extends Node3D

var explanation := ("The two ghosts are indistinguishable from any test you can run inside the chamber. "
    + "This is not a skill problem. No strategy raises the hit rate above 0.5. "
    + "Some questions cannot be answered from within the system that poses them.")
```

## Complexity

Ghost movement is O(1) per frame. Damage routing is O(1) per collision. The chamber's arithmetic is negligible.

## Within the Sequence

Chamber_Foundations closes Foundations Crisis by making incompleteness a body-level condition.

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

## No Save

Progress in this chamber is not recorded as a win. The learner's hit-rate curve is logged but not evaluated; incompleteness is the state the chamber establishes.

## No Catalyst Entry

Unlike other chambers, no new catalyst is added to the learner's kit on exit. The lesson is a constraint, not a new tool.