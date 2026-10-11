# Brouwer Intuitionism

**Revision status — legacy code sketch.** The fragments below are retained for inspection, not supplied as a complete runnable lesson. Required scene objects and helpers are missing. They have not passed the ghost-student reconstruction test. The installed choice bench appends a 0 or 1 only when you press a button; the diagonal workbench constructs a string differing from every displayed row. These are the reconstruction targets. The checklist and physical proof-block bench below are an earlier proposal, not the current room or a proof checker.

**Learning elements — proposed focus**

*The labels below set the revision focus; the existing lesson still needs alignment.*

- Finite prefixes
- Witnesses
- Open continuations

Inspect this older checklist proposal alongside the installed finite-prefix and diagonal studies. A recorded action and a mathematical proof require different validation.

Declare an intuitionistic proposition.

```gdscript
class_name Proposition
extends Resource

@export var name: String = ""
@export var constructed: bool = false
@export var steps: Array[String] = []
```

This resource records a name, a Boolean and strings. Flipping constructed records a program state; it does not make a proposition true or prove it.

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

This appends a string to a checklist. No inference rule is checked.

Validate the construction.

```gdscript
func validate(prop: Proposition) -> bool:
    for required in required_steps_for(prop.name):
        if not prop.steps.has(required):
            return false
    prop.constructed = true
    return true
```

The missing required_steps_for helper would supply a checklist. Testing string membership does not check order, dependencies or logical validity.

Report the stored construction status.

```gdscript
func attempt_lem(prop: Proposition) -> String:
    if prop.constructed:
        return "true"
    return "not yet constructed"
```

Not yet constructed is a status message, not a third truth value. Classical logic does not provide an algorithm deciding every proposition. This function implements neither classical nor intuitionistic logic.

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

This proposes instancing block scenes; it supplies no pickup, assembly or proof-validation behaviour. The installed hall instead lets the visitor choose bits and inspect a diagonal witness.

Refuse to finalize without all steps.

```gdscript
func _on_finalize_pressed(prop: Proposition) -> void:
    if validate(prop):
        lock_proof(prop)
    else:
        show_missing(prop)
```

Finalization either locks the proof or lists the missing steps. Errors are named, not silent. The rule is that claims require construction.

Intuitionistic logic still uses contradiction to establish negations; double-negation elimination is unavailable in general. Florensky Paraconsistent next distinguishes conflicting reports from the consequences they license.
<<</MAP>>>

Count constructed propositions on a tally.

```gdscript
func update_tally(label: Label3D) -> void:
    var built := 0
    for p in propositions:
        if p.constructed: built += 1
    label.text = "%d / %d constructed" % [built, propositions.size()]
```

The tally counts true constructed flags. Its reliability depends on validation that this sketch has not supplied.
