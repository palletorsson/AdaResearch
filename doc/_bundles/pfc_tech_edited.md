<<<ADA_BUNDLE>>>
sequence: postfoundationscrisis
file: technical.md
maps: 5
skipped_passing: 3
created: 2026-04-24T01:40:00
only_failing: true
diff_mode: false
with_context: true
<<</ADA_BUNDLE>>>

<<<MAP: CriticalAlgorithms_Applied_Ethics>>>
# Applied Ethics — Technical

Three case-study stations run live classifiers on anonymised decision tasks. Each station exposes a simple classifier, a feature set, and a decision output, plus intervention controls that let the learner adjust the classifier's behaviour and see the downstream effects.

```gdscript
class_name ClassifierStation extends Node3D

@export var case_data: Array = []  # list of {features: Array, true_label: int}
@export var threshold: float = 0.5
@export var feature_weights: Array = []  # float per feature

var predictions: Array = []  # predicted labels for the cases

func classify_all() -> void:
    predictions.clear()
    for case in case_data:
        var score: float = 0.0
        for i in range(case.features.size()):
            score += case.features[i] * feature_weights[i]
        score = sigmoid(score)
        predictions.append(1 if score > threshold else 0)

func sigmoid(x: float) -> float:
    return 1.0 / (1.0 + exp(-x))
```

## Calibration Slider

The threshold slider adjusts where the classifier commits to a positive prediction. Moving it changes the false-positive and false-negative rates across the case set.

```gdscript
func _on_threshold_changed(new_threshold: float) -> void:
    threshold = new_threshold
    classify_all()
    update_consequence_readout()
```

## Feature Re-Weighting

Each feature has its own weight slider. Zeroing a feature removes its contribution from the prediction, which simulates removing that data source from the classifier.

```gdscript
func _on_feature_weight_changed(feature_index: int, new_weight: float) -> void:
    feature_weights[feature_index] = new_weight
    classify_all()
    update_consequence_readout()
```

## Downstream Consequence

The consequence readout tracks how many cases in each demographic group receive positive versus negative outcomes. This exposes disparate impact: if the classifier systematically disadvantages a group, the readout shows it.

```gdscript
func compute_group_outcomes() -> Dictionary:
    var outcomes: Dictionary = {}
    for i in range(case_data.size()):
        var group: String = case_data[i].group
        var pred: int = predictions[i]
        outcomes[group] = outcomes.get(group, {"positive": 0, "negative": 0})
        if pred == 1:
            outcomes[group].positive += 1
        else:
            outcomes[group].negative += 1
    return outcomes
```

## Confusion Matrix

A standard evaluation tool for classifiers. Four counts: true positives, false positives, true negatives, false negatives. Derived metrics (precision, recall, F1) are computed from these.

```gdscript
func confusion_matrix() -> Dictionary:
    var tp := 0; var fp := 0; var tn := 0; var fn := 0
    for i in range(case_data.size()):
        var pred: int = predictions[i]
        var truth: int = case_data[i].true_label
        if pred == 1 and truth == 1: tp += 1
        elif pred == 1 and truth == 0: fp += 1
        elif pred == 0 and truth == 0: tn += 1
        elif pred == 0 and truth == 1: fn += 1
    return {"tp": tp, "fp": fp, "tn": tn, "fn": fn}

func precision_recall_f1(cm: Dictionary) -> Dictionary:
    var precision: float = 0.0 if cm.tp + cm.fp == 0 else float(cm.tp) / (cm.tp + cm.fp)
    var recall: float = 0.0 if cm.tp + cm.fn == 0 else float(cm.tp) / (cm.tp + cm.fn)
    var f1: float = 0.0 if precision + recall == 0 else 2 * precision * recall / (precision + recall)
    return {"precision": precision, "recall": recall, "f1": f1}
```

## Annotated Excerpts

A small library of practitioner excerpts is displayed on a wall. Each excerpt is a short paragraph with a named attribution and a link to a deeper reading.

```gdscript
class_name ExcerptDisplay extends Node3D

var excerpts: Array = [
    {"title": "On disparate impact", "author": "Barocas & Selbst", "text": "A facially neutral classifier can still produce disparate impact..."},
    {"title": "On refusal", "author": "Simone Browne", "text": "The refusal to participate is a form of epistemic labor..."},
    {"title": "On audit", "author": "Ajunwa", "text": "Algorithmic audit requires access to the model and its training data..."},
]

func cycle_excerpt() -> void:
    current_index = (current_index + 1) % excerpts.size()
    update_display()
```

## Complexity

Classification is O(N·F) per re-classify for N cases and F features. The map uses fewer than 100 cases per station, so the full reclassification runs in milliseconds even at interactive slider rates.

Within the sequence, Applied_Ethics operationalises the bias visualiser's diagnosis. SpeculativeComputation_Paraconsistent_Engineering will next take the contradiction-tolerance approach further.

<<<MAP: SpeculativeComputation_Paraconsistent_Engineering>>>
# Paraconsistent Engineering — Technical

A spherical rig holds a knowledge base with deliberate contradictions. A four-valued logic (Belnap's FOUR: true, false, both, neither) lets inference continue past contradictions without trivialising.

```gdscript
class_name BelnapLogic

enum Value { NEITHER = 0, TRUE = 1, FALSE = 2, BOTH = 3 }

static func conjunction(a: int, b: int) -> int:
    # Truth table for AND in four-valued logic
    const TABLE := [
        [0, 0, 2, 2],  # NEITHER & {NEITHER, TRUE, FALSE, BOTH}
        [0, 1, 2, 3],
        [2, 2, 2, 2],
        [2, 3, 2, 3],
    ]
    return TABLE[a][b]

static func disjunction(a: int, b: int) -> int:
    const TABLE := [
        [0, 1, 0, 3],
        [1, 1, 1, 1],
        [0, 1, 2, 3],
        [3, 1, 3, 3],
    ]
    return TABLE[a][b]

static func negation(a: int) -> int:
    const TABLE := [0, 2, 1, 3]  # NEITHER, FALSE, TRUE, BOTH
    return TABLE[a]
```

## Knowledge Base

The knowledge base is a dictionary mapping propositions to their truth values. Contradictions appear when the same proposition is asserted as both true and false by different sources; the value becomes BOTH rather than producing a logical explosion.

```gdscript
class_name KnowledgeBase

var facts: Dictionary = {}  # proposition -> Value
var sources: Dictionary = {}  # proposition -> list of (source_name, claimed_value)

func assert_fact(proposition: String, value: int, source: String) -> void:
    if not proposition in sources:
        sources[proposition] = []
    sources[proposition].append([source, value])
    var existing: int = facts.get(proposition, BelnapLogic.Value.NEITHER)
    facts[proposition] = combine(existing, value)

func combine(existing: int, new_val: int) -> int:
    # Information ordering: NEITHER < {TRUE, FALSE} < BOTH
    if existing == new_val: return existing
    if existing == BelnapLogic.Value.NEITHER: return new_val
    if new_val == BelnapLogic.Value.NEITHER: return existing
    return BelnapLogic.Value.BOTH  # any disagreement yields BOTH
```

## Inference Engine

The paraconsistent inference engine evaluates queries against the knowledge base. A query returns one of the four values, reflecting the evidential state of the proposition.

```gdscript
func query(proposition: String) -> int:
    return facts.get(proposition, BelnapLogic.Value.NEITHER)

func query_with_rules(expression: String) -> int:
    # Parse the expression and evaluate it under Belnap logic
    # e.g. "P AND NOT Q"
    var tokens := tokenize(expression)
    return evaluate_tokens(tokens)
```

Classical inference would crash when encountering a BOTH value; paraconsistent inference continues and propagates the BOTH through subsequent operations.

## Production Pipeline

A small sensor-fusion pipeline demonstrates the paraconsistent machinery in practice. Two sensors report values for the same quantity; their disagreement is marked rather than resolved arbitrarily.

```gdscript
class_name SensorFusion

var readings: Dictionary = {}  # sensor_id -> reading

func fuse() -> Dictionary:
    # For each quantity, check whether sensors agree
    var fused: Dictionary = {}
    var all_quantities := collect_quantities()
    for q in all_quantities:
        var values: Array = []
        for sensor_id in readings:
            if q in readings[sensor_id]:
                values.append(readings[sensor_id][q])
        fused[q] = {
            "values": values,
            "agreement": all_equal(values),
            "fused_value": mean(values) if all_equal(values) else "CONFLICT"
        }
    return fused
```

## Complexity

Conjunction, disjunction, and negation are O(1) with precomputed truth tables. Fact assertion is O(1) with dictionary storage. Query resolution is O(|expression|) for an expression with |expression| operators. Sensor fusion is O(Q·S) for Q quantities and S sensors.

Within the sequence, Paraconsistent_Engineering makes contradiction a first-class engineering concern. SpeculativeComputation_Situated_Computation will next extend the posture to standpoint-awareness.

<<<MAP: SpeculativeComputation_Situated_Computation>>>
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

<<<MAP: SpeculativeComputation_Collective_Knowledge>>>
# Collective Knowledge — Technical

Four reasoning agents run side-by-side, each with its own inference engine. A mediation station collects their outputs and computes a shared-commons report.

```gdscript
class_name ClassicalAgent extends Node

func reason(claim: String, kb: KnowledgeBase) -> String:
    # Classical two-valued logic, crashes on contradiction
    if has_contradiction(kb): return "INCONSISTENT"
    var value: bool = evaluate_classical(claim, kb)
    return "TRUE" if value else "FALSE"

class_name ParaconsistentAgent extends Node

func reason(claim: String, kb: KnowledgeBase) -> String:
    # Four-valued Belnap logic, tolerates contradiction
    var value: int = evaluate_paraconsistent(claim, kb)
    return ["NEITHER", "TRUE", "FALSE", "BOTH"][value]

class_name ProbabilisticAgent extends Node

func reason(claim: String, evidence: Array) -> String:
    var prior: float = 0.5
    var posterior: float = bayesian_update(prior, evidence)
    if posterior > 0.9: return "LIKELY_TRUE"
    elif posterior < 0.1: return "LIKELY_FALSE"
    else: return "UNCERTAIN"

class_name ConstraintAgent extends Node

func reason(claim: String, constraints: Array) -> String:
    var solution := constraint_solver(constraints)
    if solution == null: return "UNSATISFIABLE"
    return "CONSISTENT_WITH_SOLUTION"
```

## Mediation

The central mediator collects the agents' outputs and combines them without requiring consensus.

```gdscript
class_name Mediator extends Node

@export var agents: Array  # list of agent nodes

func query_all(claim: String) -> Dictionary:
    var responses: Dictionary = {}
    for agent in agents:
        responses[agent.name] = agent.reason(claim, shared_kb)
    return responses

func commons_support(claim: String) -> String:
    var responses := query_all(claim)
    var positive_count := 0
    var negative_count := 0
    for agent_name in responses:
        var r: String = responses[agent_name]
        if r in ["TRUE", "LIKELY_TRUE", "CONSISTENT_WITH_SOLUTION"]:
            positive_count += 1
        elif r in ["FALSE", "LIKELY_FALSE", "UNSATISFIABLE"]:
            negative_count += 1
    if positive_count > negative_count and positive_count > 0:
        return "COMMONS_SUPPORTS"
    elif negative_count > positive_count and negative_count > 0:
        return "COMMONS_REJECTS"
    else:
        return "COMMONS_DIVIDED"
```

## Agreement and Disagreement

The display shows per-claim agreement patterns. Some claims are unanimous; others split the agents. The splits are the interesting data — they identify where the different logics produce genuinely different answers.

```gdscript
func find_informative_claims(claim_set: Array) -> Array:
    var informative: Array = []
    for claim in claim_set:
        var responses := query_all(claim)
        var unique_values := {}
        for r in responses.values():
            unique_values[r] = true
        if unique_values.size() > 1:
            informative.append({"claim": claim, "responses": responses})
    return informative
```

## Coverage Measurement

A coverage panel tracks which claims each agent can settle and which the commons can settle. Claims unreachable by any single agent but reachable by the commons are highlighted as additive gains.

```gdscript
func compute_coverage(claim_set: Array) -> Dictionary:
    var coverage: Dictionary = {}
    for claim in claim_set:
        var settled_by: Array = []
        for agent in agents:
            if agent.reason(claim, shared_kb) not in ["UNKNOWN", "NEITHER", "UNCERTAIN"]:
                settled_by.append(agent.name)
        coverage[claim] = settled_by
    return coverage
```

## Complexity

Each agent's cost is specific to its inference method. Classical logic: O(|kb|) to check consistency, O(|claim|) to evaluate. Paraconsistent: same. Probabilistic: O(|evidence|) for Bayesian update. Constraint: depends on the solver, typically O(exp(variables)) worst case but practical instances run in milliseconds.

The mediator's cost is the sum of its agents' costs plus O(agents) for aggregation.

Within the sequence, Collective_Knowledge implements the commons-of-incomplete-systems argument. PostCrisis_Synthesis will next close the sequence with a handoff.

<<<MAP: PostCrisis_Synthesis>>>
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
