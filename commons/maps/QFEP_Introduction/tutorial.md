# Four inputs, one result

**Learning elements**

- Weighted expressions
- Input arrays and scalar results
- Copies of retained state
- Local coordinates for a hand control
- Assertions and the limits of a model

You are in the QFEP Introduction hall of Endless Museum. First use its existing balance workbench: move a rail, press KEEP, and look for a different arrangement with the same total. We will reconstruct that comparison on our small bench with the sphere we already know. We keep four numbers separately even when their calculation returns just one.

## What arrives from earlier halls

Continue in the prepared Ada museum project. Carry `point_body.gd` and `line_skin.gd` unchanged from [Euclid](../Euclid_Parallel/tutorial.md#carried-files-complete), and `bench.gd` from [Russell](../Russell_Paradox/tutorial.md). Euclid already carries the point construction from Points; Russell initializes the table, sphere, drawing container, labels and buttons. We are extending their behaviour, not rebuilding their geometry.

Place those three files beside the three new files printed below in `res://doc/book/studies/qfep-lineage/`. This is one script folder, with relative preloads. The supplied dependencies are `XRToolsPickable` and `res://commons/interactables/push_button.tscn`, both already in the museum project. A blank Godot project does not include them. The inherited bench gives us `start`, `block`, `label`, `clear_drawing`, `point`, `point_home` and an initialized `readout`; none is an unexplained scene reference.

## Keep the inputs

Create `balance.gd`. The array order is F, E, lambda, phi. For this console each input is dimensionless and bounded to 0..1. `CHANGE` is supplied as 0.3. It is not an observed change or a rate. The calculation follows the installed workbench: F minus lambda times E, plus phi times the fixed change.

<!-- student-code:balance.gd -->
```gdscript
extends RefCounted
## Dimensionless inputs for this console, ordered F, E, lambda, phi.
const CHANGE := 0.3
var values: Array[float] = [0.4, 0.2, 0.5, 0.5]
var kept: Array[float] = []

func total(parts: Array[float]) -> float:
    return parts[0] - parts[2] * parts[1] + parts[3] * CHANGE

func set_term(index: int, value: float) -> bool:
    if index < 0 or index >= values.size() or not is_finite(value):
        return false
    values[index] = clampf(value, 0.0, 1.0)
    return true

func keep() -> void:
    kept = values.duplicate()
```

`total` returns a number without changing its input. Multiplication makes lambda a weight: when it is zero, E contributes nothing to this total, even though E still has a value. `set_term` rejects a nonexistent slot or a nonfinite value and clamps a valid number to the rail's range. `keep` duplicates the array. Assigning `kept = values` would share the same array, so a later element edit could also rewrite the evidence you intended to retain. Numbers need only this shallow copy; nested mutable records would need more care.

There is no simulated organism behind these four inputs. QFEP is the project's research proposal, and this lesson makes its teaching expression inspectable. It does not compute variational free energy, measure entropy, detect a physical phase or decide what makes a life free. Those distinctions matter when we use the same letters in the following halls.

## Give the existing sphere a new job

Create `introduction_study.gd`. Attach it to a Node3D only through the supplied museum scene described below. There is one `_ready`: it calls the inherited bench constructor before using any label or point. TERM selects which input the sphere controls. Lift the sphere to increase that input; lower it to decrease it. The movement spans 0.48 metres, from local height 1.18 to 1.66 metres. Release before pressing a button.

<!-- student-code:introduction_study.gd -->
```gdscript
extends "bench.gd"
const Balance = preload("balance.gd")
const NAMES := ["F", "E", "LAMBDA", "PHI"]
const COLOURS := [Color("50bfff"), Color("ffa451"), Color("ed6472"), Color("be8bee")]
const LOW := 1.18
const TRAVEL := 0.48
var model := Balance.new()
var selected := 0

func _ready() -> void:
    start("FOUR INPUTS / ONE RESULT", ["TERM", "KEEP", "PAIR A", "PAIR B", "ZERO L"],
        [next_term, keep_reading, pair_a, pair_b, zero_lambda])
    readout.font_size = 32
    redraw()

func _process(_delta: float) -> void:
    if point.held():
        var local_hand := to_local(point.global_position)
        var value := clampf((local_hand.y - LOW) / TRAVEL, 0.0, 1.0)
        if not is_equal_approx(value, model.values[selected]):
            model.set_term(selected, value)
            redraw()

func next_term() -> void:
    if point.held(): return
    selected = (selected + 1) % 4
    redraw()

func keep_reading() -> void:
    if point.held(): return
    model.keep()
    redraw()

func pair_a() -> void:
    if point.held(): return
    model.values = [0.4, 0.2, 0.5, 0.5]
    redraw()

func pair_b() -> void:
    if point.held(): return
    model.values = [0.6, 0.6, 0.5, 0.5]
    redraw()

func zero_lambda() -> void:
    if point.held(): return
    model.set_term(2, 0.0)
    redraw()

func redraw() -> void:
    clear_drawing()
    for i in 4:
        var x := (i - 1.5) * 0.55
        var height: float = model.values[i] * TRAVEL
        block(drawing, Vector3(x, LOW+TRAVEL/2, -0.06),
            Vector3(0.018, TRAVEL, 0.018), Color("526071"))
        block(drawing, Vector3(x, LOW+height/2, 0),
            Vector3(0.13, maxf(height, 0.004), 0.08), COLOURS[i])
        label(drawing, "%s %.2f" % [NAMES[i], model.values[i]], Vector3(x, 1.06, 0.1), 18)
        if not model.kept.is_empty():
            block(drawing, Vector3(x, LOW+model.kept[i]*TRAVEL, 0.08),
                Vector3(0.21, 0.012, 0.02), Color("f1eadb"))
    point_home = Vector3((selected-1.5)*0.55, LOW+model.values[selected]*TRAVEL, 0.22)
    if not point.held(): point.position = point_home
    var reading := "%s: lift sphere 0..1 / fixed change 0.30\nF - L*E + PHI*0.30 = %.3f" % [NAMES[selected], model.total(model.values)]
    if model.kept.is_empty():
        reading += "\nKEEP preserves the four inputs"
    else:
        var kept_total: float = model.total(model.kept)
        var difference: float = model.total(model.values) - kept_total
        if absf(difference) < 0.0005: difference = 0.0
        reading += "\nKept %.3f / difference %+.3f" % [kept_total, difference]
    readout.text = reading
```

`to_local(point.global_position)` returns the hand's position in the bench's frame. Subtracting LOW and dividing by TRAVEL maps that height to 0..1. The clamp bounds the value, not the physical freedom of your hand. The same calculation works if the bench is moved or rotated in the museum. Horizontal hand movement does not change this particular input.

`redraw` replaces the small bars and their labels. It never replaces `point`. The coloured bar shows the current value; a pale horizontal mark shows the kept value. `point_home` changes to the selected bar's current height. The inherited bench returns the released sphere there. The buttons deliberately refuse to change the selected term or preset while you are holding it, so one gesture cannot unexpectedly switch meanings.

The display prints three decimal places. Differences smaller than half its last displayed unit appear as zero, avoiding a distracting negative zero from floating-point arithmetic. The stored inputs and calculation remain unchanged. Display precision is a choice about what the readout can show, not a proof that two arbitrary arrangements are identical.

## Run in this museum

Open `res://doc/book/studies/qfep-lineage/introduction.tscn` and press F6. This supplied scene uses `introduction_museum.gd` to load QFEP Introduction with the existing museum player, lighting and exhibits, then mounts your `introduction_study.gd` on a small bench beside them. The adapter is included in the study folder; it is museum setup, not a missing part of the calculation. The normal hall and its original workbench remain available. The lesson's KEEP lasts for this run; it is not a disk save.

1. The opening is PAIR A: `[0.4, 0.2, 0.5, 0.5]`, total 0.45. Press KEEP.
2. Press PAIR B: `[0.6, 0.6, 0.5, 0.5]`, total 0.45 again. The pale marks should still show A. The larger F contribution exactly compensates for the more negative weighted E contribution.
3. Press ZERO L, then TERM until E is selected. Predict what lifting the sphere will do. E and its bar should change; the total should stay fixed. Select LAMBDA and lift it above zero; now E has an effect again.
4. Without PAIR A or B, make a third arrangement with total 0.45. KEEP it, change one input, and explain which retained value accounts for the difference. This is the transfer task: the two supplied presets are examples, not the only solutions.

## Test the calculation

Create `balance_checks.gd`. These assertions check the retained values as well as the convenient total. The final case supplies one possible third arrangement; attempt the task above before reading it.

<!-- student-code:balance_checks.gd -->
```gdscript
extends RefCounted
const Balance = preload("balance.gd")

func run() -> void:
    var b := Balance.new()
    assert(is_equal_approx(b.total(b.values), 0.45))
    b.keep()
    b.set_term(0, 0.6)
    b.set_term(1, 0.6)
    assert(b.values != b.kept)
    assert(is_equal_approx(b.total(b.values), b.total(b.kept)))
    assert(b.kept == [0.4, 0.2, 0.5, 0.5])
    b.set_term(2, 0.0)
    var before := b.total(b.values)
    b.set_term(1, 0.9)
    assert(is_equal_approx(b.total(b.values), before))
    assert(is_equal_approx(b.values[1], 0.9))
    b.set_term(2, 0.5)
    assert(is_equal_approx(b.total(b.values), before-0.45))
    assert(b.set_term(0, 2.0) and b.values[0] == 1.0)
    assert(b.set_term(0, -1.0) and b.values[0] == 0.0)
    var retained := b.values.duplicate()
    assert(not b.set_term(-1, 0.2))
    assert(not b.set_term(4, 0.2))
    assert(not b.set_term(0, NAN))
    assert(not b.set_term(0, INF))
    assert(b.values == retained)
    b.set_term(0, 0.3)
    b.set_term(1, 0.0)
    assert(is_equal_approx(b.total(b.values), 0.45))
```

Run the supplied `tools/test_qfep_introduction.py` with Python from the project root. It reconstructs these three files from this tutorial and the three inherited files from their earlier chapters, then runs Godot against that fresh extraction. Its separate input harness moves the actual inherited sphere under a transformed parent and checks the buttons, release position and initialized readout. A failed assertion or Godot script error fails the run. The harness is a synthetic ghost student, not evidence that a person has completed the task in a headset.

## Carry onward

Keep the model, the sphere and the habit of retaining inputs alongside a result. In F Term we will stop supplying an arbitrary F rail and ask a narrower question with observable outcomes: how often does a predictor get a fixed sample wrong? A count of mistakes, its expectation and entropy will need separate names and records.

**Short instruction:** Continue inherited PointBody + Russell Bench. Reconstruct installed weighted expression; inputs F,E,L,PHI in [0,1], fixed change .3. One sphere edits selected local-height rail. KEEP copies tuple. Test equal totals/different tuples, zero weight, independent third tuple. No measured free energy, phase or moral score. Carry separate inputs and result to prediction study.
