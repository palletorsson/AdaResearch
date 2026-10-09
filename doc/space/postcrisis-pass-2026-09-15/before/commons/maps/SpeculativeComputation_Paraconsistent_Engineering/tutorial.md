# Paraconsistent Engineering

A database that holds both P and not-P without collapsing into triviality. Build a logic engine that survives contradiction.

Declare the knowledge base.

```gdscript
class_name ParaKB
extends Node

var facts: Array[Dictionary] = []

func assert_fact(subject: String, predicate: String, value: bool, source: String) -> void:
    facts.append({"s": subject, "p": predicate, "v": value, "src": source})
```

Every fact carries its source. Contradictions are tagged rather than resolved. The source makes ex falso impossible: you cannot reason from conflicting sources as though they agreed.

Query a subject without collapsing.

```gdscript
func query(subject: String, predicate: String) -> Array:
    var hits: Array = []
    for f in facts:
        if f.s == subject and f.p == predicate:
            hits.append(f)
    return hits
```

The query returns every match, including disagreements. The caller, not the database, decides what to do with a split. Classical logic would have raised here.

Detect contradictions.

```gdscript
func contradictions() -> Array:
    var groups := {}
    for f in facts:
        var key := f.s + "/" + f.p
        if not groups.has(key): groups[key] = []
        groups[key].append(f)
    var out: Array = []
    for key in groups:
        var values := groups[key].map(func(f): return f.v)
        if true in values and false in values:
            out.append({"key": key, "facts": groups[key]})
    return out
```

Group by subject and predicate. If both true and false appear, the pair is a contradiction. They are logged, not deleted.

Continue inference on the consistent parts.

```gdscript
func consistent_facts() -> Array:
    var bad := {}
    for c in contradictions():
        bad[c.key] = true
    return facts.filter(func(f): return not bad.has(f.s + "/" + f.p))
```

The filter yields the inference-safe subset. Classical reasoning operates here. The contradictory pair is visible on its own spotlight.

Render the sphere of contradictions.

```gdscript
func update_sphere(mesh: MeshInstance3D) -> void:
    var c := contradictions()
    var scale := 1.0 + float(c.size()) * 0.1
    mesh.scale = Vector3.ONE * scale
    var material := mesh.get_active_material(0) as StandardMaterial3D
    material.emission_energy_multiplier = 0.5 + float(c.size()) * 0.2
```

The sphere grows with each held contradiction. Florensky's icon becomes a load-bearing indicator. The system glows brighter the more disagreement it survives.

Offer a provenance tooltip.

```gdscript
func tooltip_for(c: Dictionary) -> String:
    var lines: Array = []
    for f in c.facts:
        lines.append("%s → %s (%s)" % [str(f.v), f.src, f.p])
    return "\n".join(lines)
```

Each contradiction opens its sources. The engineer reads the disagreement as data, not as failure. The tool treats reality as multi-voiced.

Wire the live inference stage to the clean subset.

```gdscript
func infer_new_facts() -> void:
    var base := consistent_facts()
    for rule in inference_rules:
        var derived := rule.apply(base)
        for d in derived:
            assert_fact(d.s, d.p, d.v, "derived:" + rule.name)
```

Inference runs on the consistent subset and writes new facts back with a derivation source. The sphere does not explode. The database keeps working.

You have built a database that refuses to collapse under contradiction. The next map, Situated Computation, turns this refusal into a design constraint on how any system occupies its perspective.
