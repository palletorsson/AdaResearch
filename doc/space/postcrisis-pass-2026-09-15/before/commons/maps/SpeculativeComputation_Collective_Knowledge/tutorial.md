# Collective Knowledge

Four reasoning agents, each with a different logic, share one question. Build a commons from systems that cannot individually complete themselves.

Declare an agent.

```gdscript
class_name LogicAgent
extends Node

@export var agent_name: String = ""
@export var logic_style: String = "classical"
@export var color: Color = Color.WHITE

func reason(question: String) -> Dictionary:
    return {"agent": agent_name, "claim": null, "confidence": 0.0}
```

The base class returns a null claim. Each subclass overrides `reason` with its own method. Logic_style is a declaration, not a reduction.

Subclass a classical reasoner.

```gdscript
class ClassicalAgent extends LogicAgent:
    func reason(q: String) -> Dictionary:
        var base := proof_search(q)
        return {"agent": agent_name, "claim": base.claim, "confidence": base.strength}
```

Classical proof search, bounded. It returns its best claim with a confidence. If the search fails, the claim is null and the confidence is zero.

Subclass a fuzzy reasoner.

```gdscript
class FuzzyAgent extends LogicAgent:
    func reason(q: String) -> Dictionary:
        var truth: float = fuzzy_eval(q)
        return {"agent": agent_name, "claim": truth > 0.5, "confidence": abs(truth - 0.5) * 2.0}
```

Fuzzy agents return values between zero and one. The claim is a thresholded projection. The confidence is the distance from ambivalence.

Run all agents on one question.

```gdscript
func collect_reports(q: String) -> Array:
    var reports: Array = []
    for agent in agents:
        reports.append(agent.reason(q))
    return reports
```

Every agent answers. No voting yet. The commons is the collection of answers, each stamped with its agent.

Read disagreements as data.

```gdscript
func disagreement_score(reports: Array) -> float:
    if reports.size() < 2: return 0.0
    var yes := 0
    var no := 0
    for r in reports:
        if r.claim == true: yes += 1
        elif r.claim == false: no += 1
    return min(yes, no) * 2.0 / float(reports.size())
```

Even agreement yields 1.0, full agreement yields 0.0. The score names the structure of disagreement without resolving it.

Render each report on a lectern.

```gdscript
func render_lectern(lectern: Node3D, report: Dictionary) -> void:
    var label := lectern.get_node("Label3D") as Label3D
    label.text = "%s\n%s (%.0f%%)" % [report.agent, str(report.claim), report.confidence * 100.0]
    label.modulate = report.get("color", Color.WHITE)
```

Four lecterns, four claims, four confidences. The learner walks between them and reads the commons as an architectural arrangement rather than a verdict.

Let the mediation stage observe without voting.

```gdscript
func mediate(reports: Array) -> Dictionary:
    return {
        "spread": disagreement_score(reports),
        "consensus": reports.filter(func(r): return r.claim == true).size(),
        "dissent": reports.filter(func(r): return r.claim == false).size(),
    }
```

The mediator reports structure, not resolution. The learner decides what the commons means. Gödel said single systems cannot contain themselves; the commons is how several such systems stay in relation.

You have built a four-lectern commons where incompleteness becomes collective. The next map, Rhizome Network, converts this non-hierarchy from a reasoning posture into a physical topology.
