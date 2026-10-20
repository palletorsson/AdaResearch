# Change the guess; keep the grid

**Learning elements**

- Seeded samples and probability thresholds
- Constant predictors
- Counting observed mistakes
- Expected error and binary source entropy
- Holding the evidence fixed during a comparison

We are in the F Term hall of Endless Museum. Introduction kept the inputs behind a total. Here we keep the evidence behind a prediction. Start at the existing Shannon workbench: leave p near 0.9, press EXPECT 0, then EXPECT 1. The amber mistake marks change while the bits stay put. Our working copy reconstructs that experiment with the same sphere and bench, and a smaller 8-by-8 sample that we can inspect cell by cell.

## What we carry

Continue in `res://doc/book/studies/qfep-lineage/`, inside the prepared Ada project. Keep `point_body.gd`, `line_skin.gd` and `bench.gd` unchanged from [Introduction](../QFEP_Introduction/tutorial.md). Their printed sources remain [Euclid](../Euclid_Parallel/tutorial.md#carried-files-complete) and [Russell](../Russell_Paradox/tutorial.md). The sphere, initialized labels, button scene and local hand-height mapping are already familiar. We add a prediction model rather than modifying the previous four-input calculation.

Randomness gave us seeded draws; Arrays gave us indices and loops; Introduction gave us a retained reading. Each returns here for a specific comparison. There is no new point class. XRTools and `res://commons/interactables/push_button.tscn` remain supplied museum dependencies.

## Store a source, then choose a guess

Create `prediction.gd`. The seed produces 64 stored numbers once. A probability p turns each number into a bit. Moving p changes the threshold applied to those same numbers; it does not ask the generator for another sample. This lets you revisit a setting and recover its grid in this run.

<!-- student-code:prediction.gd -->
```gdscript
extends RefCounted
const SAMPLES := 64
const DRAW_SEED := 1234
var draws := PackedFloat32Array()
var p := 0.1
var prediction := 0
var kept: Dictionary = {}

func _init() -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = DRAW_SEED
    for i in SAMPLES: draws.append(rng.randf())

func set_probability(value: float) -> bool:
    if not is_finite(value): return false
    p = clampf(value, 0.0, 1.0)
    return true

func bits() -> PackedInt32Array:
    var result := PackedInt32Array()
    for draw in draws:
        result.append(int(p >= 1.0 or draw < p))
    return result

func entropy() -> float:
    if p <= 0.0 or p >= 1.0: return 0.0
    var q := 1.0 - p
    return -(p * log(p) + q * log(q)) / log(2.0)

func reading() -> Dictionary:
    var mistakes := 0
    for bit in bits():
        if bit != prediction: mistakes += 1
    return {"p": p, "prediction": prediction, "source_h": entropy(),
        "expected_error": p if prediction == 0 else 1.0-p,
        "mistakes": mistakes, "count": draws.size()}

func keep() -> void:
    kept = reading()
    kept["bits"] = bits()
```

`bits()` returns a fresh array: 1 when the stored draw is below p, otherwise 0. The explicit p = 1 case makes that certain source all ones even if a generator supplies the endpoint 1.0. At p = 0 every bit is zero. Intermediate values describe a probability, not a promise that a finite grid contains exactly p times 64 ones.

`prediction` is one constant guess, either 0 or 1, used for every cell. `reading()` counts its mismatches with the current bits. **Expected error** is different: under the source model, guessing 0 is wrong with probability p, while guessing 1 is wrong with probability 1−p. A predicted error rate of 10% does not require this particular sample to have exactly 6.4 mistakes; a count is an integer.

`entropy()` computes H(p) = −p log₂ p − (1−p) log₂(1−p), in bits per symbol. Godot's `log` is the natural logarithm, so dividing by `log(2.0)` converts to base two. The endpoint branch avoids taking log(0). H is zero for a certain source and one at p = 0.5. It is calculated from the chosen p, not estimated by counting the displayed grid, and it does not depend on our chosen predictor.

These are three different readings: source entropy, expected error for a particular guess, and observed mistakes in a finite sample. **None is named F in this code.** We are making a bounded prediction experiment in the F hall, not calculating variational free energy or proving that a predictable world is lifeless.

`keep()` stores a fresh reading and a fresh bit array. Later source or predictor edits do not overwrite them. This continues Introduction's habit of retaining what a score refers to. KEEP lasts for this run; it is not a disk save.

## Let the sphere control p

Create `f_term_study.gd`. The inherited `start` initializes the labels and sphere before we use them. The grid's boxes and amber marks are made once. Later changes recolour the boxes and show or hide the existing marks; we do not recreate geometry every time the hand moves.

<!-- student-code:f_term_study.gd -->
```gdscript
extends "bench.gd"
const Prediction = preload("prediction.gd")
const LOW := 1.18
const TRAVEL := 0.48
var model := Prediction.new()
var cells: Array[MeshInstance3D] = []
var marks: Array[MeshInstance3D] = []

func _ready() -> void:
    start("CHANGE THE GUESS / KEEP THE GRID", ["P .1", "P .9", "EXPECT 0", "EXPECT 1", "KEEP"],
        [set_p.bind(0.1), set_p.bind(0.9), expect.bind(0), expect.bind(1), keep_reading])
    readout.font_size = 28
    block(drawing, Vector3(-1.08,LOW+TRAVEL/2,0), Vector3(0.018,TRAVEL,0.018), Color("526071"))
    label(drawing, "p(1) / lift sphere", Vector3(-1.06,1.08,0.25),18)
    for i in model.SAMPLES:
        var at := Vector3(-0.48+(i%8)*0.17,1.015,-0.65+(i/8)*0.17)
        cells.append(block(drawing,at,Vector3(0.15,0.018,0.15),Color.WHITE))
        marks.append(block(drawing,at+Vector3(0,0.016,0.057),Vector3(0.12,0.01,0.016),Color("ffb74d")))
    redraw()

func _process(_delta: float) -> void:
    if point.held():
        var value := clampf((to_local(point.global_position).y-LOW)/TRAVEL,0.0,1.0)
        if not is_equal_approx(value,model.p):
            model.set_probability(value)
            redraw()

func set_p(value: float) -> void:
    if point.held(): return
    model.set_probability(value)
    redraw()

func expect(bit: int) -> void:
    if point.held(): return
    model.prediction = bit
    redraw()

func keep_reading() -> void:
    if point.held(): return
    model.keep()
    redraw()

func redraw() -> void:
    var outcomes := model.bits()
    for i in outcomes.size():
        cells[i].material_override.albedo_color = Color("50dbef") if outcomes[i]==1 else Color("17232e")
        marks[i].visible = outcomes[i] != model.prediction
    point_home = Vector3(-1.08,LOW+model.p*TRAVEL,0.22)
    if not point.held(): point.position = point_home
    var r := model.reading()
    readout.text = "p(1) %.2f / guess %d\nH %.3f bits/symbol / expected error %.1f%%\nObserved %d / %d (%.1f%%)" % [
        r.p,r.prediction,r.source_h,100.0*r.expected_error,r.mistakes,r.count,100.0*r.mistakes/r.count]
    if model.kept.is_empty():
        readout.text += "\nKEEP a reading; amber marks the mistakes"
    else:
        var k := model.kept
        readout.text += "\nKept p %.2f / guess %d / H %.3f\nKept mistakes %d / %d" % [k.p,k.prediction,k.source_h,k.mistakes,k.count]
```

Each flat tile is one observed bit: dark for 0, cyan for 1. An amber strip means that the bit differs from the selected guess. `% 8` finds a cell's column; integer division by 8 finds its row. The fixed grid uses 64 cells; the installed workbench normally uses 256. Comparing their mistake counts requires stating those different sample sizes.

Lift the familiar sphere to change p. As before, `to_local` places the hand in the bench's frame, and the 0.48-metre travel maps to 0..1. The P .1 and P .9 buttons make an exact paired comparison easy. Release the sphere before using a button, so a preset cannot compete with the held hand's position.

`expect` changes only the guess. Neither it nor KEEP regenerates `draws` or changes p. The number of visible amber marks must always equal `reading().mistakes`. When you switch guesses, every binary cell changes from right to wrong or wrong to right, so the two mistake counts add to 64. That is a useful invariant to test independently of the selected seed.

## Build and investigate in the hall

Open `res://doc/book/studies/qfep-lineage/f_term.tscn` and press F6. The supplied `f_term_museum.gd` adapter loads the existing F Term hall, with its player, lighting and original workbench, then mounts this learner copy in a checked bay. The adapter and scene are included beside your scripts. This lesson runs in that prepared museum project, not an empty project without its XRTools and button dependencies.

1. Press P .1 and EXPECT 0. Before reading the marks, predict whether few or many cells will disagree. Press KEEP.
2. Press P .9, keeping EXPECT 0. H should match the kept H, but expected error rises from 10% to 90%. Count some of the new amber marks. Similar entropy has not made these sources equally easy for this particular guess.
3. Leave p at .9 and press EXPECT 1. The bit colours must stay fixed while the amber marks reverse. The expected error falls to 10%. The observed count need not equal exactly 10% of 64.
4. Use the sphere to choose another probability, away from the two presets. Predict which constant guess should have fewer expected mistakes, then try both. Verify that their observed counts add to 64. Explain any difference between the expected rate and this finite count. At p = .5 their expected rates tie, even if their observed counts do not.

This is a chosen predictor. There is no training algorithm here. Choosing the better of two guesses on this sample is also not an independent test of performance on future samples. The object of the lesson is to change the expectation while holding the current evidence still.

## Assertions against the printed model

Create `prediction_checks.gd`. The four-draw fixture deliberately gives one mistake out of four at p = .1: its observed 25% is different from its expected 10%. This deterministic case tests the distinction without relying on a lucky random discrepancy.

<!-- student-code:prediction_checks.gd -->
```gdscript
extends RefCounted
const Prediction = preload("prediction.gd")

func run() -> void:
    var m := Prediction.new()
    var again := Prediction.new()
    assert(m.draws == again.draws and m.draws.size()==64)
    var saved_draws := m.draws.duplicate()
    m.set_probability(0.1)
    var low_h := m.entropy()
    assert(is_equal_approx(low_h,0.4689955936))
    assert(is_equal_approx(m.reading().expected_error,0.1))
    m.keep()
    var kept_bits: PackedInt32Array = m.kept.bits.duplicate()
    m.set_probability(0.9)
    assert(is_equal_approx(m.entropy(),low_h))
    assert(is_equal_approx(m.reading().expected_error,0.9))
    var fixed_bits := m.bits()
    var misses_zero: int = m.reading().mistakes
    m.prediction = 1
    assert(m.bits()==fixed_bits and m.draws==saved_draws)
    assert(misses_zero + m.reading().mistakes == 64)
    assert(is_equal_approx(m.reading().expected_error,0.1))
    assert(m.kept.p==0.1 and m.kept.prediction==0 and m.kept.bits==kept_bits)
    m.set_probability(0.5)
    assert(is_equal_approx(m.entropy(),1.0))
    m.draws = PackedFloat32Array([0.05,0.2,0.6,0.95])
    m.prediction = 0
    m.set_probability(0.1)
    assert(m.reading().mistakes==1 and m.reading().count==4)
    assert(not is_equal_approx(float(m.reading().mistakes)/4.0,m.reading().expected_error))
    m.draws = PackedFloat32Array([0.0,0.5,1.0])
    m.set_probability(0.0)
    assert(m.bits()==PackedInt32Array([0,0,0]) and m.entropy()==0.0)
    m.set_probability(1.0)
    assert(m.bits()==PackedInt32Array([1,1,1]) and m.entropy()==0.0)
    assert(m.set_probability(-1.0) and m.p==0.0)
    assert(m.set_probability(2.0) and m.p==1.0)
    assert(not m.set_probability(NAN) and m.p==1.0)
    assert(not m.set_probability(INF) and m.p==1.0)
```

From the project root, run `python tools/test_qfep_f_term.py`. The supplied harness extracts these three printed files and the same three inherited files, then runs Godot assertions and synthetic hand/button interactions. It checks visible marks against counted mistakes, unchanged bit colours when a guess changes, retained evidence, bounds, replay and the same sphere's identity. A script error or failed assertion fails the run. These checks do not establish headset comfort or an independent student's understanding.

## Carry onward

Keep the distinction between a source, a prediction and a particular observation. The next hall, E Term, changes the question: what alternatives did we allow into the model in the first place? Its branching fan counts endings. Entropy over those endings needs a stated probability assumption before the count can become an entropy value.

**Short instruction:** Carry PointBody + Russell Bench; seeded draws once, p thresholds same draws. One sphere edits p. Guess 0/1 changes marks only. Keep p, guess, H, expected error, observed count and bits distinct. Assert entropy symmetry, fixed evidence, complementary mistake counts, finite-sample mismatch. No F calculation or learned predictor. Carry explicit outcomes to E Term.
