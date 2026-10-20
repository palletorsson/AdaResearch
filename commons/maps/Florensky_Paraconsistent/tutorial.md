# Two reports, stated consequences

**Learning elements**

- Independent support
- four information states
- explicit consequence rules
- a countermodel to explosion

At the installed gate, OPEN and CLOSED are independent reports. Both leaves can remain visible; neither supplies evidence for the alarm Q. First reconstruct that store. Then make a small additional step in the student copy: define precisely how negation, conjunction and disjunction combine the reports. This extension is a tiny propositional semantics, not a claim that the installed gate already implements a proof engine or that Florensky proposed this particular logic.

Each Vector2i has two binary components: support for and support against. (0,0) means neither, (1,0) for only, (0,1) against only, and (1,1) both. These are independent flags, not probabilities summing to one. Negation swaps them. For conjunction, positive support requires both positives; negative support needs either negative. Disjunction reverses those AND/OR requirements. A result is designated when its positive component is 1. The code implements the negation/conjunction/disjunction fragment of Dunn–Belnap four-valued semantics; it has no implication connective, quantifiers or proof-search procedure.

Test the consequence claim “P and not P license any Q.” At P=(1,1), both premises are designated. At Q=(0,0), Q is not designated. `explosion_counterexample` enumerates all sixteen assignments of P and Q until it finds that countermodel. This establishes failure of that consequence for these defined tables. It does not establish the truth of both reports about an actual door.

P FOR and P AGAINST toggle the independent components. Q FOR adds a separate report about Q; holding both P reports never performs that action. CLEAR empties both records. The sphere remains the familiar held object; releasing it returns it to the bench rather than resolving a report.

## Continue inside the museum

Use the existing AdaResearch project with Godot 4.6 and its installed XR Tools. Save these files together under `res://doc/book/studies/foundations-lineage/`. Carry `point_body.gd` and `line_skin.gd` unchanged from Euclid / Non-Euclidean Spaces. Their class construction and pickup were already printed there. Carry `bench.gd` unchanged from Russell. It supplies only geometry, labels, the visible sphere and button wiring; the rule below remains new.

Run the supplied `florensky.tscn` in that folder with F6. Its `florensky_museum.gd` launcher opens **Florensky_Paraconsistent** with the existing museum player, room and lighting, then adds your working copy beside the original exhibits. The launcher, `commons/interactables/push_button.tscn` and XR setup are declared infrastructure. No autoload, label, camera or other node is assumed inside your new script: the printed bench creates its own nodes and connects the buttons. This is a session study; it does not replace an installed artifact or carry a live node across hall loads.

The bench synchronizes an unheld frozen sphere on physics ticks. All model positions are local to the unit-scale bench unless a world transform is explicitly passed. Its slab and thin-cylinder lines are visual guides, not a new walkable floor. Use the museum's existing locomotion and pointer/grab controls.

## Complete new files

Read the rule first, then its museum display. There is one `_ready` per script; inherited `start` constructs the bench once. Save each block as the filename above it.

### `reports.gd`

<!-- student-code:reports.gd -->
```gdscript
extends RefCounted
# Pair (support-for, support-against); each component is independently 0 or 1.
var p := Vector2i.ZERO
var q := Vector2i.ZERO

func neg(a: Vector2i) -> Vector2i:
    return Vector2i(a.y,a.x)

func both(a: Vector2i,b: Vector2i) -> Vector2i:
    return Vector2i(mini(a.x,b.x),maxi(a.y,b.y))

func either(a: Vector2i,b: Vector2i) -> Vector2i:
    return Vector2i(maxi(a.x,b.x),mini(a.y,b.y))

func supported(a: Vector2i) -> bool:
    return a.x==1

func describe(a: Vector2i) -> String:
    if a==Vector2i(1,1): return "BOTH REPORTS"
    if a==Vector2i(1,0): return "FOR ONLY"
    if a==Vector2i(0,1): return "AGAINST ONLY"
    return "NO SUPPORT"

func explosion_counterexample() -> Dictionary:
    for positive in [0,1]:
        for negative in [0,1]:
            var premise := Vector2i(positive,negative)
            for q_positive in [0,1]:
                for q_negative in [0,1]:
                    var conclusion := Vector2i(q_positive,q_negative)
                    if supported(premise) and supported(neg(premise)) and not supported(conclusion):
                        return {"found":true,"p":premise,"q":conclusion}
    return {"found":false}
```

### `florensky_study.gd`

<!-- student-code:florensky_study.gd -->
```gdscript
extends "bench.gd"
const Reports = preload("reports.gd")
var model := Reports.new()

func _ready() -> void:
    start("FLORENSKY / KEEP THE REPORTS DISTINCT", ["P FOR", "P AGAINST", "Q FOR", "CLEAR"],
        [toggle.bind(0),toggle.bind(1),toggle.bind(2),reset])
    refresh()

func toggle(which: int) -> void:
    if point.held(): return
    if which==0: model.p.x=1-model.p.x
    elif which==1: model.p.y=1-model.p.y
    elif which==2: model.q.x=1-model.q.x
    refresh()

func reset() -> void:
    if point.held(): return
    model.p=Vector2i.ZERO
    model.q=Vector2i.ZERO
    refresh()

func refresh() -> void:
    clear_drawing()
    for i in 3:
        var at := Vector3(-0.8+i*0.8,1.1,0)
        var present: bool = [model.p.x,model.p.y,model.q.x][i]==1
        block(drawing,at,Vector3(0.45,0.16 if present else 0.025,0.45),Color("bd9fd0") if present else Color("445464"))
        label(drawing,["P","not P","Q"][i],at+Vector3.UP*0.2)
    point_home=Vector3(0,1.2,0.48)
    readout.text="P: %s | Q: %s\nP and not P: %s\nTwo reports do not add support for Q."%[
        model.describe(model.p),model.describe(model.q),model.describe(model.both(model.p,model.neg(model.p)))]
```

## Predict, build, check

Predict all four states of P before pressing the buttons. Hold both reports while Q has no support. Then add Q's own positive report: explain what changed and who supplied it. Negating a pair twice must return the original pair. Check the two De Morgan laws over all sixteen input pairs and conjunction elimination: whenever a conjunction is designated, each conjunct is designated.

Compare this with Brouwer's status “no witness yet.” Our four-valued semantics is an explicit choice for combining reports. It does not turn constructive uncertainty into a third or fourth truth value, and it has no connection to quantum amplitudes. The synthesis will keep these scopes attached to their results.

Reference: [Sutcliffe, Pelletier and Hazen, Making Belnap's Useful Four-Valued Logic Useful](https://cdn.aaai.org/ocs/17599/17599-77711-1-PB.pdf), Table 1. Our pair representation implements the basic tables, not the paper's additional conditional connectives.

The automated reconstruction tests extract the printed files, add only these declared carried dependencies and run native Godot assertions. They use synthetic interaction. They do not establish human learning or headset reach.
