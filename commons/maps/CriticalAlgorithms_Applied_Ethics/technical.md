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
