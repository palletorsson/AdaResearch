from pathlib import Path

adds = {
'CriticalAlgorithms_Applied_Ethics': """

## ROC and PR Curves

A receiver operating characteristic (ROC) curve plots true positive rate against false positive rate across every possible threshold. A precision-recall curve does the same for precision and recall. The area under the ROC curve (AUC) is a threshold-independent measure of classifier quality; AUC of 0.5 is random guessing, 1.0 is perfect classification.

```gdscript
func compute_roc_curve(scores: Array, labels: Array) -> Array:
    var points: Array = []
    for threshold in range(0, 101):
        var t: float = threshold / 100.0
        var tp: int = 0; var fp: int = 0; var fn: int = 0; var tn: int = 0
        for i in range(scores.size()):
            var pred: int = 1 if scores[i] > t else 0
            if pred == 1 and labels[i] == 1: tp += 1
            elif pred == 1 and labels[i] == 0: fp += 1
            elif pred == 0 and labels[i] == 1: fn += 1
            else: tn += 1
        var tpr: float = float(tp) / max(1, tp + fn)
        var fpr: float = float(fp) / max(1, fp + tn)
        points.append(Vector2(fpr, tpr))
    return points
```

## Refusal Protocol

Refusal is not a passive state. A refusing practitioner documents their reasoning, identifies the values that motivate the refusal, and proposes alternatives where possible. The map's refusal panel prompts the learner through a structured refusal workflow.
""",

'SpeculativeComputation_Paraconsistent_Engineering': """

## Resolution Strategies

When contradictions appear in a paraconsistent system, the engineering decision is what to do about them. Three common strategies: isolate (mark the contradiction and refuse to infer from it), resolve (use a separate rule to pick a winner), or defer (log the contradiction for human review).

```gdscript
func resolution_strategy(prop: String, values: Array, strategy: String) -> int:
    match strategy:
        "isolate": return BelnapLogic.Value.BOTH
        "resolve_by_source_priority":
            var priority_table := {"official": 3, "expert": 2, "crowd": 1}
            var best: int = -1; var best_val: int = BelnapLogic.Value.NEITHER
            for v in values:
                var pri: int = priority_table.get(v.source, 0)
                if pri > best: best = pri; best_val = v.value
            return best_val
        "defer": return BelnapLogic.Value.NEITHER  # wait for human
    return BelnapLogic.Value.BOTH
```

## Integration With Production

The paraconsistent stage in a production pipeline sits between data ingestion and downstream consumers. Consumers are expected to handle BOTH and NEITHER values explicitly, rather than assuming all data is classically true or false.

```gdscript
func downstream_consumer_guard(value: int, callback: Callable) -> void:
    match value:
        BelnapLogic.Value.TRUE: callback.call(true)
        BelnapLogic.Value.FALSE: callback.call(false)
        BelnapLogic.Value.BOTH: log_contradiction_for_review()
        BelnapLogic.Value.NEITHER: log_missing_evidence()
```
""",

'SpeculativeComputation_Situated_Computation': """

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
""",

'SpeculativeComputation_Collective_Knowledge': """

## Agent Communication

Agents in the commons do not communicate directly; the mediator is the only interface. Each agent receives the same query, runs its own inference, and returns a response. This keeps the agents' logics truly independent.

```gdscript
func mediator_broadcast(claim: String) -> Dictionary:
    var responses: Dictionary = {}
    for agent in agents:
        responses[agent.name] = agent.reason(claim, shared_kb)
    return responses
```

## Consensus Algorithms

If a commons does need to reach consensus — for downstream decision-making — a separate aggregation step can apply. Majority rule, weighted voting, and iterative deliberation are common options.

```gdscript
func weighted_majority(responses: Dictionary, weights: Dictionary) -> String:
    var vote_totals: Dictionary = {}
    for agent_name in responses:
        var weight: float = weights.get(agent_name, 1.0)
        var response: String = responses[agent_name]
        vote_totals[response] = vote_totals.get(response, 0.0) + weight
    var best: String = ""
    var best_total: float = -INF
    for response in vote_totals:
        if vote_totals[response] > best_total:
            best_total = vote_totals[response]
            best = response
    return best
```

## Disagreement as Signal

When agents disagree systematically on a class of claims, the disagreement pattern itself is informative. A claim that is TRUE under classical logic, UNCERTAIN under probability, and UNSATISFIABLE under constraints reveals something about the claim's structure that no single agent could have identified.
""",

'PostCrisis_Synthesis': """

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
""",
}

for m, add in adds.items():
    p = Path('commons/maps/' + m + '/technical.md')
    t = p.read_text(encoding='utf-8')
    p.write_text(t.rstrip() + add, encoding='utf-8')

# Also touch up AdvancedLaboratory with a small code block
lab = Path('commons/maps/AdvancedLaboratory_Lab_Equipment_Simulation/technical.md')
lab_add = """

## Valence Check Implementation

```gdscript
# MolecularDesigner valence check
func can_add_bond(atom: Atom, bond_type: int) -> bool:
    var current_bond_order: int = atom.total_bond_order()
    var max_bond_order: int = atom.valence_capacity()
    return current_bond_order + bond_type <= max_bond_order

# VSEPR angle lookup
const IDEAL_ANGLES := {
    2: 180.0,   # linear
    3: 120.0,   # trigonal planar
    4: 109.5,   # tetrahedral
    5: 90.0,    # trigonal bipyramidal
    6: 90.0,    # octahedral
}
```
"""
lab.write_text(lab.read_text(encoding='utf-8').rstrip() + lab_add, encoding='utf-8')

print('done')
