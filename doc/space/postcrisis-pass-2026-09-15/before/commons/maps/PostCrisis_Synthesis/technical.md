# PostCrisis Synthesis — Technical

The map is primarily architectural: a quiet room with miniature displays of the earlier maps, a central plinth with the closing sentence, and an exit panel. The technical content is the interaction layer that makes the miniatures clickable and the recap labels readable.

```gdscript
class_name MiniatureDisplay extends Node3D

@export var source_map_name: String = ""
@export var recap_text: String = ""

var is_hovered: bool = false

func _on_mouse_entered() -> void:
    is_hovered = true
    highlight()

func _on_mouse_exited() -> void:
    is_hovered = false
    unhighlight()

func _on_selected() -> void:
    if source_map_name != "":
        get_tree().change_scene_to_file("res://commons/maps/%s/map.tscn" % source_map_name)
```

## Recap Labels

Each miniature has an associated recap label that appears on hover. The labels are concise — one or two sentences — summarising the map's contribution to the arc.

```gdscript
class_name RecapLabel extends Label3D

func fade_in(duration: float = 0.3) -> void:
    modulate.a = 0.0
    visible = true
    var tween := create_tween()
    tween.tween_property(self, "modulate:a", 1.0, duration)

func fade_out(duration: float = 0.3) -> void:
    var tween := create_tween()
    tween.tween_property(self, "modulate:a", 0.0, duration)
    tween.finished.connect(func(): visible = false)
```

## Central Sentence Plinth

The plinth holds a short sentence in a clean typeface on a plain base. No ornament, no background gradient, no visual emphasis beyond simple contrast.

```gdscript
class_name SentencePlinth extends Node3D

@export var sentence: String = "The foundations crisis was not a failure but the moment the discipline admitted its own edges."
@export var font_size: int = 24
@export var text_color: Color = Color.WHITE

func _ready() -> void:
    $Label3D.text = sentence
    $Label3D.font_size = font_size
    $Label3D.modulate = text_color
```

## Exit Panel

The exit panel points forward rather than back. It lists recommended next maps, organised by what the learner might be most ready for.

```gdscript
class_name ExitPanel extends Node3D

@export var forward_options: Array = [
    {"title": "Graph Theory", "path": "GT_Foundations", "note": "Concrete mathematical tools for relation and structure"},
    {"title": "QFEP Laboratory", "path": "QFEP_Sandbox", "note": "The full framework made tunable"},
    {"title": "Archive", "path": "Gallery", "note": "Every artifact from the curriculum, browsable"},
]

func _ready() -> void:
    for option in forward_options:
        var entry := OPTION_BUTTON_SCENE.instantiate()
        entry.title = option.title
        entry.note = option.note
        entry.pressed.connect(func(): get_tree().change_scene_to_file(resolve_path(option.path)))
        add_child(entry)
```

## Ambient Lighting

The quiet room uses a low-key lighting setup: a single directional light at low intensity, plus soft indirect illumination from the environment. The lighting is deliberately subdued to produce a reflective rather than exhibition-like atmosphere.

```gdscript
func _ready() -> void:
    var world_env := WorldEnvironment.new()
    world_env.environment = preload("res://commons/environments/quiet_room.tres")
    add_child(world_env)
```

## Save State

Reaching this map triggers a save state update: the curriculum is noted as having reached its closing synthesis. Returning to this map from any future session preserves the session history, so the miniatures can display per-learner statistics (time spent, revisits) if desired.

```gdscript
func _ready() -> void:
    super()
    var save := get_tree().get_first_node_in_group("save_manager")
    save.mark_milestone("reached_postcrisis_synthesis", Time.get_datetime_string_from_system())
```

## Complexity

The map's interactions are all O(1) per frame. Rendering the miniatures is O(miniature count) per frame — typically fewer than a dozen. Scene transitions triggered by clicks are O(load time) for the target scene.

Within the sequence, Synthesis is the close and the handoff. The curriculum's argument — that post-crisis practice builds from admitted limits — lands as a modest bibliography rather than as a monument.

## Save-State Integration

The map records the learner's completion of the curriculum arc. A summary of their traversal — maps visited, artifacts engaged, befriended creatures, time spent — is written to a persistent profile.

```gdscript
class_name LearnerProfile

var visited_maps: Array
var befriended_creatures: Array
var time_in_curriculum: float
var milestones: Dictionary

func write_synthesis_complete() -> void:
    milestones["postcrisis_synthesis_complete"] = Time.get_datetime_string_from_system()
    save_to_disk()

func summary_statistics() -> Dictionary:
    return {
        "maps": visited_maps.size(),
        "creatures": befriended_creatures.size(),
        "hours": time_in_curriculum / 3600.0,
    }
```

## Exhibition Mode

The closing map supports an exhibition mode that replaces the miniatures with photographs or screenshots of a particular learner's journey. Other learners walking through can see what this learner spent time on.

```gdscript
class_name ExhibitionMode extends Node3D

@export var profile_path: String

func _ready() -> void:
    var profile: LearnerProfile = load(profile_path)
    for miniature in get_children():
        if miniature.source_map_name in profile.visited_maps:
            miniature.add_time_indicator(profile.time_per_map[miniature.source_map_name])
            miniature.add_creature_indicator(profile.creatures_befriended_here[miniature.source_map_name])
```

## Ambient Audio

A low ambient drone fills the room — a soft, slow-moving pad that does not distract but marks the space as distinct from the active-teaching maps. The drone is generated via the AirMusic station's generative system, running a long, slow phasing pattern.

```gdscript
func start_ambient_drone() -> void:
    var ambient_player := AudioStreamPlayer.new()
    ambient_player.stream = preload("res://audio/postcrisis_drone.ogg")
    ambient_player.volume_db = -20.0  # very quiet
    ambient_player.play()
    add_child(ambient_player)
```

## Exit Ritual

Leaving the map triggers a brief transition — fade to black, hold for a beat, fade in at the Lab. The transition marks the end of the formal arc and lets the learner land softly rather than cutting abruptly to the Lab's hub activity.
