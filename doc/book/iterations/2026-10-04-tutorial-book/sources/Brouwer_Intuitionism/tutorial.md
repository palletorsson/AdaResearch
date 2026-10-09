# Brouwer Intuitionism

No existence without construction. Build a room where claims are only valid if the learner assembles them step by step.

Declare an intuitionistic proposition.

```gdscript
class_name Proposition
extends Resource

@export var name: String = ""
@export var constructed: bool = false
@export var steps: Array[String] = []
```

A proposition has a name and a record of construction. It is not true until `constructed` flips. Proof is assembly, not assertion.

Instantiate a construction bench.

```gdscript
func begin_construction(prop: Proposition) -> void:
    prop.constructed = false
    prop.steps.clear()
    bench.display(prop)
```

The bench resets every time a proposition begins. No carryover from a previous proof. Each construction starts cold.

Append a step.

```gdscript
func add_step(prop: Proposition, step: String) -> void:
    prop.steps.append(step)
    bench.display(prop)
```

Each step is a text operation the learner performs. The display updates so the learner sees the proof growing in front of them.

Validate the construction.

```gdscript
func validate(prop: Proposition) -> bool:
    for required in required_steps_for(prop.name):
        if not prop.steps.has(required):
            return false
    prop.constructed = true
    return true
```

Required steps are listed per proposition. Missing any means the proposition stays unconstructed. No proof by absence.

Reject law of excluded middle.

```gdscript
func attempt_lem(prop: Proposition) -> String:
    if prop.constructed:
        return "true"
    return "not yet constructed"
```

Classical logic returns either "true" or "false" for every proposition. Brouwer's room returns "not yet constructed" instead of "false". The third option is the whole point.

Light the proposition when constructed.

```gdscript
func _on_prop_constructed(prop: Proposition) -> void:
    var light: OmniLight3D = lights[prop.name]
    light.light_energy = 2.5
    construction_chime.play()
```

Constructed propositions glow. Unbuilt ones stay dim. The room is a topology of what the learner has actually made.

Offer a palette of building blocks.

```gdscript
func present_blocks(panel: Node3D) -> void:
    for block_name in block_library:
        var block := preload("res://commons/artifacts/foundations/proof_block.tscn").instantiate()
        block.set_name(block_name)
        panel.add_child(block)
```

Blocks are physical. The learner assembles proofs by moving blocks onto the bench. Construction is a bodily act.

Refuse to finalize without all steps.

```gdscript
func _on_finalize_pressed(prop: Proposition) -> void:
    if validate(prop):
        lock_proof(prop)
    else:
        show_missing(prop)
```

Finalization either locks the proof or lists the missing steps. Errors are named, not silent. The rule is that claims require construction.

You have built without proving by contradiction. The next map, Florensky Paraconsistent, accepts contradictions without collapse.
<<</MAP>>>

Count constructed propositions on a tally.

```gdscript
func update_tally(label: Label3D) -> void:
    var built := 0
    for p in propositions:
        if p.constructed: built += 1
    label.text = "%d / %d constructed" % [built, propositions.size()]
```

The tally rises only when propositions are actually built. Claims without construction do not count. The tally is a running honesty check.
