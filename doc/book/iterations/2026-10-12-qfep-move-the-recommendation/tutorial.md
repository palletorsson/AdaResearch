# Move the recommendation; keep the surroundings

**Learning elements**

- Independent parameters and their effects
- Weighting a term without changing its input
- Mapping a scalar to a local position
- Keeping geometry fixed during a comparison
- Retaining and restoring a recommendation

We are inside Endless Museum's Lambda Spectrum hall. Walk through the installed contrast between repeated and dispersed forms. Then use LIT STRIP at its entrance. The bright strip moves; the cube rows keep their arrangement. RETURN restores the original recommendation. This is our next problem after E Term: available alternatives and the preference expressed about them are different things.

We will reconstruct the separation on our small bench. One control changes lambda in Introduction's calculation. Another moves a recommendation over an unchanged field of cubes. They use the same familiar sphere, but each writes to its own variable. Moving the light does not calculate the best route or reshape the field.

## What we carry

Continue in `res://doc/book/studies/qfep-lineage/` in the prepared Ada project. Keep `point_body.gd`, `line_skin.gd` and `bench.gd` from [E Term](../QFEP_E_Term/tutorial.md). Their printed sources remain [Euclid](../Euclid_Parallel/tutorial.md#carried-files-complete) and [Russell](../Russell_Paradox/tutorial.md). Also reuse the complete `balance.gd` printed in [QFEP Introduction](../QFEP_Introduction/tutorial.md). Its input order is F, E, lambda, phi; `total` returns F − lambda×E + phi×0.3. We do not rewrite that calculation.

The initialized bench, labels, pickup/release sphere, XRTools and `res://commons/interactables/push_button.tscn` keep their earlier roles. Transformation returns as a local position edit; Arrays returns as a fixed collection of cubes; Randomness supplies a seed used only during construction.

E Term's outcome set is not silently inserted into this calculation. The carried console still starts with its supplied dimensionless values [0.4, 0.2, 0.5, 0.5]. Its E = 0.2 is not ln(81), a new measurement from the hall, or an estimate of the cubes' entropy. E Term taught us to state what a number describes; that distinction travels even when the earlier path data is not needed by this exercise.

## Name two controls

Create `recommendation.gd`. `calculation` holds Introduction's model. `route` holds a separate recommendation between 0.20 and 0.80, matching the installed rail's bounds. The default route is 0.35; the carried calculation starts with lambda = 0.5. Different initial numbers help us see that they are not aliases.

<!-- student-code:recommendation.gd -->
```gdscript
extends RefCounted
const Balance = preload("balance.gd")
const MIN_ROUTE := 0.20
const MAX_ROUTE := 0.80
const HOME_ROUTE := 0.35
var calculation := Balance.new()
var route := HOME_ROUTE
var kept: Dictionary = {}

func set_weight(value: float) -> void:
    calculation.set_term(2,value)

func set_route(value: float) -> void:
    if is_finite(value): route = clampf(value,MIN_ROUTE,MAX_ROUTE)

func return_route() -> void:
    route = HOME_ROUTE

func strip_x(width: float) -> float:
    return (route-0.5)*width

func reading() -> Dictionary:
    var parts := calculation.values.duplicate()
    return {"parts":parts,"weight":parts[2],"route":route,
        "contribution":-parts[2]*parts[1],"total":calculation.total(parts)}

func keep() -> void:
    kept = reading()
```

`set_weight` edits only index 2 in the carried model. With E fixed at 0.2, increasing lambda from 0 to 1 changes −lambda×E from 0 to −0.2. F = 0.4 and phi×0.3 = 0.15 stay fixed, so the total falls from 0.55 to 0.35. At lambda = 0, E is still stored. Its weighted contribution has vanished; its value has not.

`set_route` changes only the recommendation. `strip_x(width)` maps it to a centred local X coordinate: (route − 0.5)×width. At 0.5 the strip is central. At 0.2 and 0.8 it sits 30% of the full width to either side of the centre. Our model uses a width of 1.8 metres; the installed artifact uses 7. The normalized setting can agree while the distances differ.

`return_route` restores only 0.35. It does not reset lambda, rebuild cubes or erase KEEP. `reading` copies the input array before returning it; `keep` retains that record alongside the recommendation. Later edits cannot rewrite the kept inputs through a shared array reference. As before, this is a record in memory for this run.

## Build once; move one strip

Create `lambda_study.gd`. We use familiar cube meshes for a small, static comparison field: six columns and four cubes per column. The seed creates progressively jittered positions and rotations once. These are authored visual differences, not measured entropy levels. This working copy isolates recommendation movement; the full museum artifact also contains moving forms and pulsing materials.

<!-- student-code:lambda_study.gd -->
```gdscript
extends "bench.gd"
const Recommendation = preload("recommendation.gd")
const LOW := 1.18
const TRAVEL := 0.48
const WIDTH := 1.8
const ROWS := [0.08,0.21,0.48,0.62,0.76,0.90]
var model := Recommendation.new()
var editing_weight := false
var cubes: Array[MeshInstance3D] = []
var strip: MeshInstance3D
var kept_strip: MeshInstance3D

func _ready() -> void:
    start("CHANGE A WEIGHT / MOVE A RECOMMENDATION",["WEIGHT","STRIP","KEEP","RETURN","ZERO L"],
        [select.bind(true),select.bind(false),keep_reading,return_route,zero_weight])
    readout.font_size = 27
    block(drawing,Vector3(0,1.0,0),Vector3(1.9,0.025,1.3),Color("263442"))
    strip = block(drawing,Vector3(0,1.025,0),Vector3(0.36,0.015,1.3),Color("4dedad"))
    kept_strip = block(drawing,Vector3(0,1.04,0),Vector3(0.012,0.015,1.3),Color("ffb74d"))
    var rng := RandomNumberGenerator.new()
    rng.seed = 46
    for fraction: float in ROWS:
        for row in 4:
            var at := Vector3((fraction-0.5)*WIDTH,1.14,-0.48+row*0.3)
            at += Vector3(rng.randf_range(-1,1),rng.randf_range(0,1),rng.randf_range(-1,1))*fraction*0.07
            var colour := Color("9fc7f0").lerp(Color("fa5f69"),fraction)
            var cube := block(drawing,at,Vector3.ONE*0.12,colour)
            cube.rotation = Vector3(rng.randf(),rng.randf(),rng.randf())*fraction
            cubes.append(cube)
    block(drawing,Vector3(-1.17,LOW+TRAVEL/2,0),Vector3(0.018,TRAVEL,0.018),Color("526071"))
    label(drawing,"same sphere / two controls",Vector3(-1.05,1.06,0.35),16)
    redraw()

func _process(_delta: float) -> void:
    if point.held():
        var fraction := clampf((to_local(point.global_position).y-LOW)/TRAVEL,0.0,1.0)
        if editing_weight:
            model.set_weight(fraction)
        else:
            model.set_route(lerpf(model.MIN_ROUTE,model.MAX_ROUTE,fraction))
        redraw()

func select(weight: bool) -> void:
    if point.held(): return
    editing_weight = weight
    redraw()

func keep_reading() -> void:
    if point.held(): return
    model.keep()
    redraw()

func return_route() -> void:
    if point.held(): return
    model.return_route()
    redraw()

func zero_weight() -> void:
    if point.held(): return
    model.set_weight(0.0)
    redraw()

func redraw() -> void:
    strip.position.x = model.strip_x(WIDTH)
    kept_strip.visible = not model.kept.is_empty()
    if kept_strip.visible: kept_strip.position.x = (model.kept.route-0.5)*WIDTH
    var r := model.reading()
    var fraction: float = r.weight if editing_weight else inverse_lerp(model.MIN_ROUTE,model.MAX_ROUTE,r.route)
    point_home = Vector3(-1.17,LOW+fraction*TRAVEL,0.22)
    if not point.held(): point.position = point_home
    var contribution: float = 0.0 if is_zero_approx(r.contribution) else r.contribution
    readout.text = "Hand edits %s / L %.2f / strip %.2f\nE input %.2f / -L*E %+.3f / total %.3f\nForms stay fixed; green recommends" % [
        "WEIGHT" if editing_weight else "STRIP",r.weight,r.route,r.parts[1],contribution,r.total]
    if model.kept.is_empty():
        readout.text += "\nKEEP a comparison"
    else:
        readout.text += "\nKept L %.2f / strip %.2f / total %.3f" % [model.kept.weight,model.kept.route,model.kept.total]
```

`_ready` initializes the inherited bench, then builds all twenty-four cubes. `redraw` changes the green strip, retained amber marker, point home and text. It never calls the generator or edits a cube. The strip is a mesh without a collider. It can pass under a cube: the recommendation has moved, but the cube has not been cleared away.

WEIGHT and STRIP select what the same sphere edits. As in the preceding halls, `to_local` puts the hand in the bench's frame. A 0.48-metre vertical travel gives a fraction from 0 to 1. WEIGHT sends it to lambda directly; STRIP maps it to 0.20..0.80 with `lerpf`. On release, the sphere rests at the height representing the selected setting. Buttons wait for release, so a held hand does not compete with a preset.

KEEP records both values and the arithmetic result. Its amber line marks the earlier strip position. RETURN returns only the recommendation to 0.35; ZERO L sets only the arithmetic weight to zero. Neither rebuilds the forms. There is no control here that promises to make the middle objectively best.

## Build and investigate in the museum

Open `res://doc/book/studies/qfep-lineage/lambda.tscn` and press F6. The supplied `lambda_museum.gd` adapter loads the existing hall, with its player, lights and original walk-in artifact, and adds this working bench in a checked bay. The scene and adapter are included with the lesson. This is code for the prepared museum project, with the declared XRTools and button dependencies.

1. Leave the point in STRIP mode and press KEEP. Identify two neighbouring cubes. Lift the sphere to move the green recommendation towards 0.8. Watch those cubes: their positions, rotations and colours should stay fixed. The total should stay 0.450 too.
2. Release, press WEIGHT, then lift the sphere to lambda = 1. Predict the new contribution and total before reading them: −0.200 and 0.350. The green strip should remain where you placed it. ZERO L should give total 0.550 while the stored E input stays 0.20.
3. Press RETURN. The recommendation returns to 0.35; the weight you selected remains. The kept record still refers to the earlier pair. Identify exactly which values each button changes.
4. Make an independent comparison: select STRIP and place the sphere a quarter of the way up its travel. Predict route = 0.35 and x = −0.27 on this 1.8-metre field. Try three-quarters travel: route = 0.65 and x = +0.27. Verify that the cubes and score did not change. If those predictions fail, inspect which frame, width or interval you used.
5. Return to the full-size LIT STRIP rail. Try two different recommendations while attending to the same row. Its forms keep their own animation; moving the rail does not restart that animation or rebuild their arrangement. Describe what the light recommends, then what you would actually choose. The code can verify that one variable changed; it cannot decide what you should prefer.

The installed hall's configured `lambda_value` also shaped its original clearance and material emphasis. Its visitor rail now changes only `recommendation_position`. Our two-control working copy makes that independence explicit; it is not connected as a remote control to the installed hall. The miniature is a reconstruction of the comparison, not a replacement for walking through the full encounter.

## Assert what stays still

Create `recommendation_checks.gd`. The important checks cross the boundary between controls: moving a recommendation must not alter the calculation, and changing a weight must not move the recommendation. The remaining assertions cover retained evidence, bounds and the declared coordinate mapping.

<!-- student-code:recommendation_checks.gd -->
```gdscript
extends RefCounted
const Recommendation = preload("recommendation.gd")

func run() -> void:
    var model := Recommendation.new()
    assert(model.calculation.values == [0.4,0.2,0.5,0.5])
    assert(is_equal_approx(model.reading().total,0.45))
    model.keep()
    var kept := model.kept.duplicate(true)
    model.set_route(0.8)
    assert(model.kept == kept)
    assert(model.calculation.values == kept.parts)
    assert(is_equal_approx(model.reading().total,kept.total))
    assert(is_equal_approx(model.strip_x(7.0),2.1))
    assert(is_equal_approx(model.strip_x(1.8),0.54))
    model.set_weight(0.0)
    assert(model.route == 0.8)
    assert(model.calculation.values[1] == 0.2)
    assert(is_zero_approx(model.reading().contribution))
    assert(is_equal_approx(model.reading().total,0.55))
    model.set_weight(1.0)
    assert(is_equal_approx(model.reading().contribution,-0.2))
    assert(is_equal_approx(model.reading().total,0.35))
    model.return_route()
    assert(model.route == 0.35 and model.calculation.values[2] == 1.0)
    assert(model.kept == kept)
    model.set_route(-2.0)
    assert(model.route == 0.2)
    model.set_route(5.0)
    assert(model.route == 0.8)
    model.set_route(NAN)
    assert(model.route == 0.8)
    model.set_weight(NAN)
    assert(model.calculation.values[2] == 1.0)
    model.set_weight(-2.0)
    assert(model.calculation.values[2] == 0.0)
    model.set_weight(5.0)
    assert(model.calculation.values[2] == 1.0)
```

Run `python tools/test_qfep_lambda.py` from the project root. The supplied harness extracts all seven files from their printed sources, then runs Godot assertions and synthetic point/button interactions. It checks every cube's identity, transform and colour before and after the edits. A separate native run operates the installed LIT STRIP and RETURN controls, compares their mapping with this one, and checks that the surrounding rows are not rebuilt or recoloured and animation time is not reset. Failed assertions and engine errors fail the run.

Those checks establish the operations a learner can perform, not the learner's interpretation or headset comfort. The task is to make a controlled comparison possible. Whether the relocated light persuades someone is a further question for an encounter with a visitor.

## Carry onward

Keep parameter, effect and interpretation separate. A weight changes a contribution. A strip expresses a recommendation. A visitor may accept neither. Phi Term next adds an earlier and a later reading: a signed difference is not yet a rate until the elapsed interval is included.

**Short instruction:** Carry PointBody + Bench + LineSkin + Introduction Balance unchanged. One sphere selects WEIGHT or STRIP. Lambda edits arithmetic only; route maps .2..8 to local x; cubes built once. KEEP copies inputs/route; RETURN restores route only. Assert both directions of independence, zero weight, preserved cube transforms/colours, same point, local hand mapping. Existing hall animates independently. No entropy measurement or universal optimum. Next: difference versus rate.
