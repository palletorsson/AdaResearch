# Chamber Color — Technical

The chamber's kaleidocycle_enemy responds to the chromatic catalyst. Red, blue, green, and yellow each trigger a different state transition on the creature's cycling attack faces.

## Chromatic Catalyst

```gdscript
class_name ChromaticCatalyst extends Node3D

@export var current_hue: Color = Color.RED
@export var fire_cooldown: float = 0.3

var time_since_fire: float = 0.0

func _process(delta: float) -> void:
    time_since_fire += delta

func cycle_hue() -> void:
    const HUE_CYCLE := [Color.RED, Color.BLUE, Color.GREEN, Color.YELLOW]
    var i: int = HUE_CYCLE.find(current_hue)
    current_hue = HUE_CYCLE[(i + 1) % HUE_CYCLE.size()]
    update_visual()

func fire(direction: Vector3) -> void:
    if time_since_fire < fire_cooldown: return
    time_since_fire = 0.0
    var projectile := HUE_PROJECTILE_SCENE.instantiate()
    projectile.hue = current_hue
    projectile.global_position = global_position
    projectile.linear_velocity = direction * 10.0
    get_tree().root.add_child(projectile)
```

## Kaleidocycle Creature

The kaleidocycle cycles through four attack faces. Each face is associated with a colour vulnerability and a colour that settles it.

```gdscript
class_name KaleidocycleEnemy extends CharacterBody3D

enum Face { FIRE, ICE, SPIKE, SHIELD }
const FACE_HUES: Dictionary = {
    Face.FIRE: Color.RED,
    Face.ICE: Color.BLUE,
    Face.SPIKE: Color.GREEN,
    Face.SHIELD: Color.YELLOW,
}

var current_face: int = Face.FIRE
@export var cycle_interval: float = 2.0

var time_since_cycle: float = 0.0

func _process(delta: float) -> void:
    time_since_cycle += delta
    if time_since_cycle >= cycle_interval:
        time_since_cycle = 0.0
        current_face = (current_face + 1) % 4
        update_visual_for_face()

func on_projectile_hit(hue: Color) -> void:
    var expected_hue: Color = FACE_HUES[current_face]
    var match_strength: float = hue_alignment(hue, expected_hue)
    if match_strength > 0.8:
        on_face_triggered()
    else:
        on_mismatch()
```

## Hue Alignment

The alignment between two colours is computed from their HSV distance.

```gdscript
func hue_alignment(a: Color, b: Color) -> float:
    var a_hsv := rgb_to_hsv(a)
    var b_hsv := rgb_to_hsv(b)
    var hue_dist: float = min(abs(a_hsv.x - b_hsv.x), 1.0 - abs(a_hsv.x - b_hsv.x))
    return 1.0 - hue_dist * 2.0
```

## Science Screen Chromatic Axis

Events are scattered on a one-dimensional chromatic axis showing which hues hit which faces.

```gdscript
class_name ColorScienceScreen extends Node3D

var events: Array = []

func log_hit(hue: Color, face: int, success: bool) -> void:
    events.append({
        "hue_angle": rgb_to_hsv(hue).x * 360.0,
        "face": face,
        "success": success,
        "time": Time.get_ticks_msec() / 1000.0,
    })
    redraw_scatter()
```

## Miura Observer

A befriended miura_crawler from a previous chamber watches from the corner. Its presence is passive — it registers the learner's progress but does not intervene.

## Complexity

Projectile updates are O(1) each. Cycle scheduling is O(1) per creature. The hue-alignment check is O(1) per hit. The whole chamber runs at full VR frame rate with many active projectiles.

## Within the Sequence

Chamber_Color completes the Color sequence's argument that colour is a channel for communication rather than a property of objects.

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

## Befriended Miura

A miura_crawler befriended in Chamber_Transformation appears in this chamber as a witness. Its presence confirms the chamber's non-hostile mode even to a learner encountering colour combat for the first time.

## Chromatic Axis Layout

The science screen's chromatic axis is logarithmic rather than linear, approximating human perceptual hue discrimination more faithfully.