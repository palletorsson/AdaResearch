# A witness, then another choice

**Learning elements**

- Chosen finite prefixes
- Existential witnesses
- Validation
- A finite diagonal construction

**Short brief:** Carry PointBody and bench. Append chosen bits; waiting appends nothing. A stored 1 supplies a witness index. All stored zeros settle only the finite prefix. Validate before mutation; refuse overflow. Construct diagonal bits and test each disagreement. Preserve the prefix across view changes.

Escher checked a completed route. Here the record remains open to another choice. Gödel’s bounded miss also taught us to name the limit of a check: inspecting the stored prefix cannot decide every possible continuation.

The existing choice bench waits for a press; its row does not grow on the clock. Rebuild that behaviour with an eight-term working copy. The arrays and loops are familiar from Trace. A stored 1 at a named index witnesses “this prefix contains a 1.” No 1 in the entire stored prefix settles that finite question negatively. It does not settle whether an indefinitely continued sequence will ever contain a 1. NO WITNESS YET is an evidence status, not a third truth value.

Begin with 0, 0, 0. Wait. Nothing is appended. Press 1 and identify the zero-based index 3. `append_bit` validates both value and capacity before mutating the record. The ninth press is refused. Eight is a storage bound; it is not a completed infinity. The PointBody marks the next available slot, or the last slot when full. Its pickup is inherited; the bit buttons remain the only authors of this record.

Then visit the installed diagonal workbench. In the second exercise, DIAGONAL displays four binary rows and constructs d[i] = 1 − rows[i][i]. Every displayed row disagrees with d at a known index. The model validates a square nonempty array of integer bits before constructing the witness. The gold tiles mark those indices. This implements a finite diagonal stage. An infinite argument quantifies over every row of an arbitrary proposed list; rendering four rows is not rendering that infinity.

DIAGONAL changes the view without clearing the chosen prefix. A new 0 or 1 returns to the prefix. RESET clears the prefix and keeps the chosen view. The earlier arrays therefore survive a change of representation rather than being silently recreated.

## Continue inside the museum

Use the existing AdaResearch project with Godot 4.6 and its installed XR Tools. Save these files together under `res://doc/book/studies/foundations-lineage/`. Carry `point_body.gd` and `line_skin.gd` unchanged from Euclid / Non-Euclidean Spaces. Their class construction and pickup were already printed there. Carry `bench.gd` unchanged from Russell. It supplies only geometry, labels, the visible sphere and button wiring; the rule below remains new.

Run the supplied `brouwer.tscn` in that folder with F6. Its `brouwer_museum.gd` launcher opens **Brouwer_Intuitionism** with the existing museum player, room and lighting, then adds your working copy beside the original exhibits. The launcher, `commons/interactables/push_button.tscn` and XR setup are declared infrastructure. No autoload, label, camera or other node is assumed inside your new script: the printed bench creates its own nodes and connects the buttons. This is a session study; it does not replace an installed artifact or carry a live node across hall loads.

The bench synchronizes an unheld frozen sphere on physics ticks. All model positions are local to the unit-scale bench unless a world transform is explicitly passed. Its slab and thin-cylinder lines are visual guides, not a new walkable floor. Use the museum's existing locomotion and pointer/grab controls.

## Complete new files

Read the rule first, then its museum display. There is one `_ready` per script; inherited `start` constructs the bench once. Save each block as the filename above it.

### `witness.gd`

<!-- student-code:witness.gd -->
```gdscript
extends RefCounted
const CAPACITY := 8
var terms: Array[int] = []

func append_bit(bit: int) -> bool:
    if bit not in [0,1] or terms.size()>=CAPACITY: return false
    terms.append(bit)
    return true

func first_one() -> int:
    return terms.find(1)

func inspect_prefix() -> Dictionary:
    var index := first_one()
    return {"finite_contains_one":index>=0, "witness_index":index,
        "future_claim":"WITNESSED" if index>=0 else "NO WITNESS YET"}

func diagonal(rows: Array) -> Dictionary:
    if rows.is_empty(): return {"valid":false, "bits":[]}
    for row in rows:
        if not row is Array or row.size()!=rows.size(): return {"valid":false, "bits":[]}
        for bit in row:
            if not bit is int or bit not in [0,1]: return {"valid":false, "bits":[]}
    var bits: Array[int] = []
    for i in rows.size(): bits.append(1-int(rows[i][i]))
    return {"valid":true, "bits":bits}
```

### `brouwer_study.gd`

<!-- student-code:brouwer_study.gd -->
```gdscript
extends "bench.gd"
const Witness = preload("witness.gd")
var model := Witness.new()
var rows: Array = [[0,0,1,1],[1,0,1,0],[0,1,1,0],[1,1,0,1]]
var show_diagonal := false

func _ready() -> void:
    start("BROUWER / PRODUCE THE WITNESS", ["0", "1", "DIAGONAL", "RESET"],
        [choose.bind(0),choose.bind(1),diagonal,reset])
    refresh()

func choose(bit: int) -> void:
    if point.held(): return
    show_diagonal = false
    model.append_bit(bit)
    refresh()

func diagonal() -> void:
    if point.held(): return
    show_diagonal = not show_diagonal
    refresh()

func reset() -> void:
    if point.held(): return
    model.terms.clear()
    refresh()

func bit_at(bit: int, at: Vector3, marked: bool = false) -> void:
    block(drawing,at,Vector3(0.18,0.045,0.13),Color("d29d55") if bit else Color("618da9"))
    label(drawing,str(bit),at+Vector3.UP*0.09,19)
    if marked: block(drawing,at+Vector3(0,-0.015,0),Vector3(0.23,0.01,0.18),Color("ffda88"))

func refresh() -> void:
    clear_drawing()
    if show_diagonal:
        var d: Array = model.diagonal(rows).bits
        for y in rows.size():
            for x in rows[y].size():
                bit_at(rows[y][x],Vector3(-0.75+x*0.3,1.04,-0.48+y*0.21),x==y)
        for i in d.size(): bit_at(d[i],Vector3(-0.75+i*0.3,1.04,0.45))
        point_home=Vector3(0.95,1.18,0.45)
        readout.text="A finite diagonal witness\nNew row: %s\nRow i differs at position i."%str(d)
    else:
        for i in model.terms.size(): bit_at(model.terms[i],Vector3(-1.05+i*0.3,1.05,0))
        point_home=Vector3(-1.05+mini(model.terms.size(),7)*0.3,1.27,0)
        var report := model.inspect_prefix()
        readout.text="%d / %d stored; no automatic next bit\nFinite prefix has 1: %s; index %d\nContinuation: %s"%[
            model.terms.size(),model.CAPACITY,str(report.finite_contains_one),report.witness_index,report.future_claim]
```

## Predict, build, check

The array is the record of choices already made. The inspection loop searches that record for a 1 and returns its index as evidence. Validation runs before `append`, so rejected input cannot partly change the record. The diagonal loop has a different purpose: it constructs a new bit that differs from each row at its own indexed position.

Make eight zeros. Predict the finite answer and the continuation status separately. Clear, append three zeros and a 1, and return the witness index. Invalid values and a ninth append must leave the record unchanged.

For the diagonal variation, flip every diagonal entry of the supplied rows. Predict that every output bit flips too; assert disagreement with row i at position i for both versions. Supply a ragged array and refuse it. A displayed “constructed” flag without these checks would not establish the property.

The next hall retains incompatible reports. An absent witness and two opposed reports will be different data states, with different consequences.

Reference: [Joan Rand Moschovakis, Brouwer's Notion of Choice Sequence and Its Descendants](https://www.math.ucla.edu/~joan/Oslonewzoom2022handout.pdf). The finite binary bench is our teaching model.

The automated reconstruction tests extract the printed files, add only these declared carried dependencies and run native Godot assertions. They use synthetic interaction. They do not establish human learning or headset reach.
