# Chamber QFEP — Technical

The culminating chamber hosts a qfep_calibrator that responds to the coherence of combined catalyst modes rather than to any single projection.

## Multi-Mode Catalyst

```gdscript
class_name QFEPCompositeCatalyst extends Node3D

var active_modes: Array = []  # e.g. ["forces", "chromatic", "fractal", "branching"]

func enable_mode(mode_name: String) -> void:
    if not mode_name in active_modes:
        active_modes.append(mode_name)

func fire_composite(aim: Vector3) -> void:
    for mode_name in active_modes:
        spawn_mode_projectile(mode_name, aim)
    emit_signal("composite_fired", active_modes.duplicate())
```

## QFEP Calibrator

The calibrator responds to mode coherence. A single mode produces no reaction; multiple modes in a tuned combination produce an extended response.

```gdscript
class_name QFEPCalibrator extends Node3D

@export var target_combination: Array = ["forces", "chromatic", "fractal"]
@export var activation_threshold: float = 0.8

var recent_compositions: Array = []

func on_composite_fired(active_modes: Array) -> void:
    recent_compositions.append({
        "modes": active_modes,
        "time": Time.get_ticks_msec() / 1000.0,
    })
    if recent_compositions.size() > 20:
        recent_compositions.pop_front()
    var alignment: float = compute_alignment_with_target(active_modes)
    if alignment > activation_threshold:
        respond_with_full_motion()

func compute_alignment_with_target(active_modes: Array) -> float:
    var intersection: int = 0
    for mode in active_modes:
        if mode in target_combination:
            intersection += 1
    var union: int = active_modes.size() + target_combination.size() - intersection
    return float(intersection) / max(union, 1)
```

## Formula Display

The science screen displays the QFEP formula and highlights each term as the corresponding mode activates.

```gdscript
class_name QFEPFormulaDisplay extends Node3D

@export var formula_text: String = "QFE = F - λE(S) + φΔE(S,t)"

func highlight_mode(mode_name: String) -> void:
    match mode_name:
        "forces": highlight_term("F")
        "chaos", "random": highlight_term("λE(S)")
        "transformation": highlight_term("φΔE(S,t)")

func highlight_term(term: String) -> void:
    # Find the term's position in the formula and flash it
    var start: int = formula_text.find(term)
    if start == -1: return
    # Apply a brief emission effect to that substring
    emit_signal("term_highlighted", term, start)
```

## Wave Composite

The screen collapses the composite into a single waveform whose shape encodes the active mode combination.

```gdscript
class_name QFEPWaveDisplay extends Node3D

func compose_waveform(active_modes: Array, time: float) -> float:
    var result: float = 0.0
    var weights := {"forces": 1.0, "chaos": 0.7, "chromatic": 0.5, "fractal": 0.6, "branching": 0.4, "transformation": 0.8, "swarm": 0.5, "cellular": 0.6}
    for mode_name in active_modes:
        var freq: float = 2.0 + hash(mode_name) % 3
        var amp: float = weights.get(mode_name, 0.5)
        result += amp * sin(freq * time * TAU)
    return result
```

## Befriended Creature Roster

All creatures befriended through earlier chambers appear in this chamber as companions.

```gdscript
class_name CreatureRoster extends Node3D

func populate_from_save_state() -> void:
    var save = GameState.save_data
    for creature_name in save.befriended_creatures:
        var creature_scene: PackedScene = load_creature_scene(creature_name)
        var instance = creature_scene.instantiate()
        instance.position = find_companion_position(creature_name)
        add_child(instance)
        instance.set_friendly_posture()
```

## Configuration Save

Each session's composite configurations are saved to the learner's profile, becoming part of their curriculum history.

```gdscript
func save_session_configs() -> void:
    var profile: LearnerProfile = GameState.profile
    profile.add_qfep_configuration({
        "modes": active_modes.duplicate(),
        "timestamp": Time.get_datetime_string_from_system(),
    })
    profile.save_to_disk()
```

## Complexity

Mode coherence computation is O(|modes|). Waveform composition is O(|modes|) per sample. The chamber's arithmetic is negligible compared to the creature animations it hosts.

## Within the Sequence

Chamber_QFEP is the curriculum's closing handoff — the formula becomes operable rather than studied.

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
