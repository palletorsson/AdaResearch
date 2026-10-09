# Applied Ethics

Every classifier has an outside. Stage three live cases where the model commits, and show what the commitment costs.

Declare a case record.

```gdscript
class_name EthicsCase
extends Resource

@export var title: String = ""
@export var features: Dictionary = {}
@export var ground_truth: bool = false
@export var stakes: String = ""
```

Each case is a resource. Features drive the model; stakes name who bears the outcome. Keeping them on one object prevents drift.

Run the classifier.

```gdscript
func classify(case: EthicsCase) -> bool:
    var score := 0.0
    for key in case.features:
        score += float(case.features[key]) * weights.get(key, 0.0)
    return score > threshold
```

Linear model, deliberately simple. Complexity is not what makes ethics hard. The threshold is a choice the designer must defend.

Compute the confusion outcome.

```gdscript
func outcome(case: EthicsCase) -> String:
    var predicted := classify(case)
    if predicted and case.ground_truth: return "true_positive"
    if predicted and not case.ground_truth: return "false_positive"
    if not predicted and case.ground_truth: return "false_negative"
    return "true_negative"
```

Four outcomes, not two. False positives and false negatives are the outside of the classifier. The ethics lives there.

Render the outcome on a case plinth.

```gdscript
func label_case(plinth: Label3D, case: EthicsCase) -> void:
    var kind := outcome(case)
    plinth.text = "%s\n%s\n→ %s" % [case.title, case.stakes, kind]
    plinth.modulate = color_for_outcome(kind)
```

Each plinth holds a case, a stake, a verdict. The colour codes what kind of mistake was made, if any. The verdict is never just a number.

Colour the outcomes.

```gdscript
func color_for_outcome(kind: String) -> Color:
    match kind:
        "true_positive": return Color(0.2, 0.8, 0.3)
        "true_negative": return Color(0.5, 0.6, 0.5)
        "false_positive": return Color(0.9, 0.4, 0.2)
        "false_negative": return Color(0.8, 0.1, 0.1)
    return Color.WHITE
```

False negatives are the deepest red. A missed call costs more than a miscall when the stakes are unequal. Colour encodes that asymmetry.

Adjust the threshold live.

```gdscript
func _on_threshold_slider_moved(v: float) -> void:
    threshold = lerp(-1.0, 1.0, v)
    for plinth in case_plinths:
        label_case(plinth, plinth.get_meta("case"))
```

The slider is the moral dial. Moving it right reduces false positives and increases false negatives. There is no setting with neither.

Show the aggregate cost.

```gdscript
func aggregate_costs(cases: Array) -> Dictionary:
    var counts := {"fp": 0, "fn": 0}
    for c in cases:
        if outcome(c) == "false_positive": counts.fp += 1
        elif outcome(c) == "false_negative": counts.fn += 1
    return counts
```

The total FP/FN count updates on every slider move. The ethics is not in the model; it is in the choice of where to place the knob.

You have built a room where every classification is a commitment. Carry that framing into Paraconsistent Engineering, which turns contradiction from a fatal system state into an engineered affordance.
