# Give a difference a weight

**Learning elements**

- Earlier and later readings
- Signed difference and magnitude
- Elapsed interval and average rate
- Multiplication by a signed weight
- Keeping evidence separate from its label

We are inside Endless Museum's Phi Term hall. Move the installed PHI rail to equal distances on either side of zero. The particles change direction and colour. At equal magnitudes, their configured speed is equal; neither sign is given stronger motion. At zero, new emission stops. Particles already emitted can remain for their two-second lifetime. Meanwhile, the nearby transforming pattern continues its own waves.

Lambda separated a weight from a recommendation. Now we separate three more quantities: a difference between readings, the interval between them, and a weight applied to that difference. Continue with our sphere and bench. We will make the arithmetic visible without pretending the sphere controls every changing object in the room.

## What we carry

Work in `res://doc/book/studies/qfep-lineage/` in the prepared Ada project. Keep `point_body.gd`, `line_skin.gd` and `bench.gd` unchanged from the preceding halls. Their complete printed sources are [Euclid](../Euclid_Parallel/tutorial.md#carried-files-complete) and [Russell](../Russell_Paradox/tutorial.md). The point still provides pickup and release. Bench still initializes the table, labels, drawing node and supplied `res://commons/interactables/push_button.tscn` buttons. XRTools remains a project dependency.

From [Introduction](../QFEP_Introduction/tutorial.md) we keep the expression F − lambda×E + phi×Delta E. Its earlier console supplied a fixed Delta E = 0.3. Leave that console intact. This new small model studies only the last contribution and replaces the fixed change with two explicit readings. The lesson does not run Introduction's full score or reuse its 0..1-only setter for phi: this hall needs a signed weight from −1 to +1.

The pair begins at 0.20 and 0.70, with an authored interval of two seconds. These are supplied dimensionless values, chosen for comparison. They are not measurements of the nearby pattern, and they are not E Term's entropy ln(N). Computing entropy would still require a stated outcome set, probabilities and units. Restricting these exercise readings to 0..1 is a display contract, not a claim that entropy always has that range.

## Record the difference before interpreting it

Create `signed_change.gd`:

<!-- student-code:signed_change.gd -->
```gdscript
extends RefCounted
var earlier: float = 0.2
var later: float = 0.7
var interval: float = 2.0
var phi: float = 0.0
var kept: Dictionary = {}

func set_pair(first: float, second: float) -> bool:
    if not is_finite(first) or not is_finite(second): return false
    if first < 0.0 or first > 1.0 or second < 0.0 or second > 1.0: return false
    earlier = first
    later = second
    return true

func set_interval(seconds: float) -> bool:
    if not is_finite(seconds) or seconds <= 0.0: return false
    interval = seconds
    return true

func set_phi(value: float) -> bool:
    if not is_finite(value): return false
    phi = clampf(value, -1.0, 1.0)
    return true

func reverse_pair() -> void:
    set_pair(later, earlier)

func reading() -> Dictionary:
    var difference := later - earlier
    return {"earlier": earlier, "later": later, "interval": interval,
        "phi": phi, "difference": difference,
        "rate": difference / interval, "contribution": phi * difference}

func keep() -> void:
    kept = reading()
```

`later - earlier` gives a signed difference: 0.70 − 0.20 = +0.50. Dividing by the positive interval gives the average rate: +0.50 / 2 seconds = +0.25 per second. The rate says nothing about the detailed path between the observations. The value could have risen, fallen, and returned between them.

Our contribution is `phi * difference`, not `phi * rate`. At phi = +1 it is +0.50; at phi = −1 it is −0.50. If the other terms of an objective stayed fixed and we minimized that objective, the positive contribution would raise its cost. The sign alone cannot mean that the system rewards, welcomes or resists change. We would have to state what is being optimized and how the weight reaches a receiver.

`set_pair` validates both values before assigning either. An invalid pair cannot partly overwrite the old one. `set_interval` rejects zero, negative and non-finite intervals; it does not hide an invalid observation behind a tiny denominator. `set_phi` rejects non-finite input, then clamps the allowed range.

`reverse_pair` constructs the opposite comparison, 0.70 then 0.20, keeping time forward and the interval positive. It does not rewind an event in the world. `reading` returns a new dictionary containing the evidence, weight and results. KEEP retains that dictionary. Because all its entries are scalar values, later edits cannot mutate the retained record through nested references. It lasts for this run, as in our preceding benches.

## Give the carried point one job

Create `phi_study.gd`:

<!-- student-code:phi_study.gd -->
```gdscript
extends "bench.gd"
const SignedChange = preload("signed_change.gd")
const LOW := 1.12
const TRAVEL := 0.48
var model := SignedChange.new()
var labels_revealed := false

func _ready() -> void:
    start("PHI / GIVE A DIFFERENCE A WEIGHT",
        ["REVERSE", "2s / 4s", "KEEP", "ZERO PHI", "LABELS"],
        [reverse_pair, change_interval, keep, zero_phi, toggle_labels])
    redraw()

func _process(_delta: float) -> void:
    if point == null or not point.held(): return
    var fraction := clampf((to_local(point.global_position).y-LOW)/TRAVEL, 0.0, 1.0)
    model.set_phi(2.0*fraction-1.0)
    redraw()

func reverse_pair() -> void:
    if point.held(): return
    model.reverse_pair()
    redraw()

func change_interval() -> void:
    if point.held(): return
    model.set_interval(4.0 if model.interval == 2.0 else 2.0)
    redraw()

func keep() -> void:
    if point.held(): return
    model.keep()
    redraw()

func zero_phi() -> void:
    if point.held(): return
    model.set_phi(0.0)
    redraw()

func toggle_labels() -> void:
    if point.held(): return
    labels_revealed = not labels_revealed
    redraw()

func signed(value: float) -> String:
    # Avoid printing negative zero at this displayed precision.
    return "%+.3f" % (0.0 if absf(value) < 0.0005 else value)

func redraw() -> void:
    clear_drawing()
    var r := model.reading()
    point_home = Vector3(-1.17, LOW+(model.phi+1.0)*0.5*TRAVEL, 0.22)
    for i in 2:
        var value: float = model.earlier if i == 0 else model.later
        var x := -0.62+i*0.62
        block(drawing, Vector3(x,1.02+value*0.26,0),
            Vector3(0.22,maxf(value*0.52,0.002),0.22), Color("79c9df"))
        label(drawing, ("EARLIER" if i == 0 else "LATER")+" %.2f" % value,
            Vector3(x,1.06,0.36),16)
    var baseline := Vector3(0.82,1.40,0)
    segment(baseline-Vector3(0.22,0,0),baseline+Vector3(0.22,0,0))
    if not is_zero_approx(r.contribution):
        block(drawing, baseline+Vector3(0,r.contribution*0.20,0),
            Vector3(0.20,absf(r.contribution)*0.40,0.20), Color("f087b4"))
    label(drawing,"PHI x CHANGE",Vector3(0.82,1.06,0.36),16)
    var words := "Signed weight; no judgement supplied"
    if labels_revealed: words = "Earlier labels: RESIST (-) / EMBRACE (+)"
    var record := "KEEP: no record yet"
    if not model.kept.is_empty():
        record = "KEEP phi %+.2f / change %s / %.0fs / product %s" % [
            model.kept.phi,signed(model.kept.difference),model.kept.interval,signed(model.kept.contribution)]
    readout.text = "AUTHORED pair %.2f -> %.2f over %.0fs\nChange %s / average rate %s per s\nPHI %+.2f x change = %s\n%s\n%s" % [
        r.earlier,r.later,r.interval,signed(r.difference),signed(r.rate),
        r.phi,signed(r.contribution),record,words]
```

The sphere controls only phi. Its vertical travel is 0.48 metres in the bench's local frame. `to_local` lets the same script work when the bench moves or turns. The bottom maps to −1, the midpoint to zero, and the top to +1. On release, the inherited bench rests the same sphere at the corresponding height. No new pickup implementation is needed.

The two cyan columns show the supplied earlier and later readings. The pink bar grows above or below a horizontal zero marker according to their weighted difference. This is deliberately a different display from the installed rail's particles: a negative weight multiplied by a negative difference produces a positive contribution. Showing only the weight's direction would hide that relationship.

The five buttons operate after release:

- **REVERSE** swaps the supplied values, making the other comparison.
- **2s / 4s** changes the declared observation interval. The readings and difference stay fixed; the average rate changes. No actual timer is being slowed.
- **KEEP** retains readings, interval, phi, difference, rate and contribution.
- **ZERO PHI** suppresses the contribution without erasing the readings or their difference.
- **LABELS** shows or hides the older words RESIST and EMBRACE. It changes text only.

`redraw` rebuilds these few diagram meshes and labels, not the carried sphere, model or museum. Geometry is a view of the record; the record survives drawing again. The helper `signed` removes negative zero only at the displayed precision. It never rounds the stored values.

## Build and investigate in the museum

Open `res://doc/book/studies/qfep-lineage/phi.tscn` and press F6. The supplied `phi_museum.gd` adapter loads the existing hall and adds this learner bench in its checked bay. The scene and adapter are included alongside the lesson; the museum supplies the player, room and lighting. This working copy is not installed permanently in the normal map.

1. With the opening pair, lift the sphere to the top and release. Predict change +0.500, rate +0.250 per second and contribution +0.500. Press KEEP.
2. Move the sphere to the bottom. The two cyan columns should stay still, while the contribution goes below zero. Press LABELS. The same numbers acquire different words; the calculation does not change.
3. Press 2s / 4s. The difference remains +0.500 and its contribution remains −0.500. The average rate halves to +0.125 per second. KEEP still describes the original two-second comparison.
4. Press REVERSE. With phi still −1, the difference becomes −0.500 and the contribution becomes +0.500. Explain why the negative weight now produces a positive result. Press ZERO PHI: the contribution disappears, but the readings still differ.
5. Make your own test: set the initial pair in `signed_change.gd` to 0.10 and 0.90. Put the sphere three-quarters of the way up, giving phi = +0.5. Predict contribution +0.400. Change the interval to four seconds and predict the average rate separately. Reversing this pair should change both signs without changing their magnitudes. Restore the published defaults before running the supplied checks, which declare those defaults as fixtures.
6. Return to the installed rail. Compare phi = −0.5 and +0.5, then zero. Its particles show the weight, not our product. Use EARLIER LABELS / HIDE and watch the nearby pattern: it should continue its independent animation. The learner bench sends no values to that pattern or to the rail.

Equal endpoint readings would give zero difference and zero average rate. They would not establish that nothing happened between observations. Likewise phi = zero gives a zero contribution even when the readings differ. This distinction follows Trace's lesson: a retained record can answer only the questions for which it kept evidence.

## Assert the distinctions

Create `change_checks.gd`:

<!-- student-code:change_checks.gd -->
```gdscript
extends RefCounted
const SignedChange = preload("signed_change.gd")

func run() -> void:
    var model := SignedChange.new()
    var start := model.reading()
    assert(is_equal_approx(start.difference,0.5))
    assert(is_equal_approx(start.rate,0.25))
    assert(start.contribution == 0.0)
    assert(model.set_phi(1.0))
    assert(is_equal_approx(model.reading().contribution,0.5))
    model.keep()
    var record := model.kept.duplicate()
    model.set_phi(-1.0)
    assert(is_equal_approx(model.reading().contribution,-0.5))
    assert(model.earlier == start.earlier and model.later == start.later)
    model.set_interval(4.0)
    assert(is_equal_approx(model.reading().rate,0.125))
    assert(is_equal_approx(model.reading().difference,0.5))
    assert(is_equal_approx(model.reading().contribution,-0.5))
    model.reverse_pair()
    assert(is_equal_approx(model.reading().difference,-0.5))
    assert(is_equal_approx(model.reading().contribution,0.5))
    assert(model.interval == 4.0)
    assert(model.kept == record)
    var before := model.reading()
    assert(not model.set_interval(0.0) and not model.set_interval(-2.0))
    assert(not model.set_interval(INF) and not model.set_phi(NAN))
    assert(not model.set_pair(0.2,INF))
    assert(not model.set_pair(-0.2,0.7) and not model.set_pair(0.2,1.1))
    assert(model.reading() == before)
    model.set_phi(8.0)
    assert(model.phi == 1.0)
    model.set_phi(-8.0)
    assert(model.phi == -1.0)
    model.set_phi(0.5)
    model.set_pair(0.1,0.9)
    assert(is_equal_approx(model.reading().contribution,0.4))
    model.set_phi(0.0)
    assert(model.reading().contribution == 0.0 and is_equal_approx(model.reading().difference,0.8))
    model.set_pair(0.4,0.4)
    assert(model.reading().difference == 0.0 and model.reading().rate == 0.0)
    var copy := model.reading()
    copy.earlier = 42.0
    assert(model.earlier == 0.4)
```

Run `python tools/test_qfep_phi.py` from the project root. The supplied harness freshly extracts these three printed files and the three declared inherited files. Godot executes the assertions, then synthetic pickup, point movement and button signals under a translated and rotated parent. A separate rendered museum check compares the installed rail's signs, speeds, zero emission and labels, and verifies that the nearby pattern keeps its state across control events and continues afterward. Assertion failures and engine errors fail the run.

This is a reconstruction check, not evidence of independent student understanding or headset comfort. It establishes what the printed code actually does and which relationships it leaves unconnected.

## Carry onward

Keep the earlier reading, later reading and interval together. Keep the weight separate from those observations. In Edge of Chaos we will need this discipline when comparing evolving patterns: a different number of updates is not automatically a fair comparison over time.

**Short instruction:** Carry PointBody + LineSkin + Bench unchanged. New authored pair .2→.7, interval 2s, signed phi −1..1. Same sphere edits phi locally. Compute difference, average rate, weighted difference separately. REVERSE swaps values; INTERVAL changes rate only; ZERO PHI keeps difference; KEEP copies scalar record; LABELS text only. Print all new code and assert boundaries, sign products, independent controls, same point. Existing rail/pattern remain independent. No entropy measurement, moral sign or global coupling. Next: numerical evolution over equal time.
