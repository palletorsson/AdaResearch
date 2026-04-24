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

## Testing the Engine

A test suite for the paraconsistent inference engine checks that classical inferences remain sound when the knowledge base is consistent, and that inference continues without explosion when contradictions are present.

```gdscript
func run_tests() -> void:
    assert(query("unrelated_fact") == BelnapLogic.Value.NEITHER)
    assert_fact("P", BelnapLogic.Value.TRUE, "sensor_A")
    assert(query("P") == BelnapLogic.Value.TRUE)
    assert_fact("P", BelnapLogic.Value.FALSE, "sensor_B")
    assert(query("P") == BelnapLogic.Value.BOTH)
    assert(query("Q") == BelnapLogic.Value.NEITHER)
```
