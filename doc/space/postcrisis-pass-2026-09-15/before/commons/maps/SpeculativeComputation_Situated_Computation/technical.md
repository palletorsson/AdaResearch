# Situated Computation — Technical

Three viewing platforms render the same dataset from three standpoints. Each platform applies a different set of rendering conventions to the shared underlying data.

```gdscript
class_name StandpointViewer extends Node3D

@export var dataset_name: String = "urban_survey"
@export var standpoint: String = "ground_level"  # or "aerial", "community"

var dataset: Resource  # shared across all platforms

func render_for_standpoint() -> void:
    match standpoint:
        "ground_level": render_first_person()
        "aerial": render_birds_eye()
        "community": render_oblique_with_annotations()
```

## Ground-Level View

A first-person camera at human height. Occlusion by foreground objects is preserved; distance is foreshortened by perspective.

```gdscript
func render_first_person() -> void:
    camera.projection = Camera3D.PROJECTION_PERSPECTIVE
    camera.fov = 75
    camera.position = Vector3(0, 1.7, 0)
    camera.rotation = Vector3.ZERO  # looking forward
    enable_shadows(true)
```

## Aerial View

A nadir-pointing camera at high altitude. Occlusion is reduced; spatial extent is clarified.

```gdscript
func render_birds_eye() -> void:
    camera.projection = Camera3D.PROJECTION_PERSPECTIVE
    camera.fov = 60
    camera.position = Vector3(0, 80, 0)
    camera.look_at(Vector3.ZERO, Vector3.FORWARD)
    enable_shadows(false)  # shadows obscure aerial detail
```

## Community-Vantage View

An oblique camera at a position chosen by a local informant. Annotations from community members are overlaid on features that the aerial view missed.

```gdscript
func render_oblique_with_annotations() -> void:
    camera.projection = Camera3D.PROJECTION_PERSPECTIVE
    camera.fov = 70
    camera.position = community_vantage_position
    camera.look_at(dataset.focal_point, Vector3.UP)
    overlay_annotations(dataset.community_annotations)
```

## Annotation Store

Annotations are stored as text tags attached to world positions. Each annotation has an author, a timestamp, and a visibility flag.

```gdscript
class_name Annotation

@export var position: Vector3
@export var text: String
@export var author: String
@export var created_at: String

var visible_from_standpoints: Array = []  # which standpoints show this annotation
```

## Standpoint-Aware Classifier

A second station trains a classifier conditional on a chosen standpoint. The standpoint affects which features are included, how they are weighted, and what the training labels emphasise.

```gdscript
class_name StandpointClassifier extends Node

@export var standpoint: String
@export var feature_priorities: Dictionary  # feature -> weight multiplier
@export var label_emphasis: Dictionary  # class -> weight in training loss

func train(dataset: Array) -> Dictionary:
    var model: Dictionary = {"weights": {}}
    for case in dataset:
        for feature_name in case.features:
            var priority: float = feature_priorities.get(feature_name, 1.0)
            var weight_update: float = priority * loss_gradient(case, model)
            model.weights[feature_name] = model.weights.get(feature_name, 0.0) + weight_update
    return model
```

## Accounting Pass

The annotation practice accumulates a structured record of what each standpoint shows and hides. A final pass emits a combined account — partial, located, accountable.

```gdscript
func emit_combined_account() -> Dictionary:
    return {
        "ground_level_visible": ground_level_annotations,
        "aerial_visible": aerial_annotations,
        "community_visible": community_annotations,
        "combined_positive": union_of_observations(),
        "known_gaps": intersection_of_blind_spots(),
    }
```

## Complexity

Each standpoint renders independently with Godot's built-in scene graph — O(triangles in view). Annotation display is O(visible annotations) per frame. The combined account computation is O(standpoints × observations per standpoint).

Within the sequence, Situated_Computation makes standpoint an explicit parameter. Collective_Knowledge will next turn plural standpoints into a shared reasoning commons.

## Annotation Workflows

Community annotations are added through a dedicated workflow that records author attribution, timestamp, and intent. Annotations cannot be retroactively edited by other parties — the audit trail is preserved.

```gdscript
class_name AnnotationWorkflow

func add_annotation(author: String, world_position: Vector3, text: String, intent: String) -> Annotation:
    var annotation := Annotation.new()
    annotation.author = author
    annotation.position = world_position
    annotation.text = text
    annotation.intent = intent
    annotation.created_at = Time.get_datetime_string_from_system()
    annotation.hash = compute_hash(author + text + intent + annotation.created_at)
    annotation_store.append(annotation)
    return annotation
```

## Standpoint Selection

Selecting a standpoint is a political act and the map treats it as such. The standpoint picker exposes not just options but a brief justification for each, and learners are prompted to articulate their choice.

```gdscript
class_name StandpointPicker extends Control

@export var standpoints: Dictionary = {
    "ground_level": "Human-scale perception. Privileges proximity and occlusion.",
    "aerial": "Survey perspective. Privileges extent and aggregation.",
    "community": "Local expertise. Privileges historical and relational knowledge.",
}

func _on_standpoint_selected(name: String) -> void:
    emit_signal("standpoint_chosen", name, standpoints[name])
```

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
