# Generative — another phrase from the same hands

## Learning elements

- Carry PointBody, both hand traces and their shared clock.
- Separate a recorded take, its learned mean and a generated sample.
- Fit variation from whole paired performances.
- Use a seed to repeat a comparison; change the examples to change the model.
- Inspect a generated result without treating it as another teaching observation.

## What we carry into this room

The sphere in Sequence Memory could recognise and replay a phrase. Here it produces a variation. We keep the same PointBody, pickup, head-relative coordinates, four-second capture, beat and airborne paths. The sphere follows their midpoint; that response is still authored.

In the hall, the large generator/discriminator exhibit illustrates an adversarial exchange. Its moving losses are scripted. Our side study fits a small statistical generator from your own performances. It does not implement the diagram's GAN, a VAE or diffusion. Learning a distribution does not require all three.

Keep the six files from [Perception](../ML_Perception/tutorial.md) and [Sequence Memory](../ML_Sequence_Memory/tutorial.md) in the same folder: point_body.gd, pose_learner.gd, pose_study.gd, movement_learner.gd, phrase_library.gd and sequence_study.gd. Add the two complete files below. generative_study.gd extends sequence_study.gd; its inherited ready function makes the same sphere. The A/B code stays carried, but this lesson uses one family of phrases.

Run res://doc/book/studies/ml-lineage/Generative.tscn inside Ada. The supplied generative_museum.gd mounts the study in the actual Generative hall. Camera, light, XR Tools tracking/pickup and RackTemplates buttons are supplied museum infrastructure. This lesson preview leaves the existing diagram in place. Class and saved data carry across halls; a live node is not yet transferred between hall loads.

## Begin with your saved movement

In Sequence Memory, select ONE and SAVE. Here IMPORT reads that file without altering it. Or CAPTURE at least three separate takes here. The familiar three-second count-in leads into eight beats at 120 BPM. Move both hands for the full four seconds. Tracking loss or a long frame discards the whole take. STOP discards a pending performance; SOUND toggles the click.

Use variations of one recognisable phrase: for example, open outward, lift, draw inward and settle. Change the width or height slightly between takes while keeping their timing comparable. Three takes is an exercise minimum. It gives a very narrow account of possible movement.

FIT reads those complete takes. Now compare:

| Control | What produces the paths? |
| --- | --- |
| SOURCE | Your first recording, interpolated onto the display's 41 times. No new performance is generated. |
| MEAN | The average of the teaching takes at each time. Nobody necessarily performed it exactly. |
| DRAW | The learned mean plus a sampled combination of the differences found in your takes. |

Pink remains left; cyan remains right. The two tips travel together on the same clock. As before, this is a bounded miniature, not a full-size instruction to put your hands there. Capture hides the preview. No generated movement drives the player's body.

Press DRAW twice. With the same fitted data, amount and seed, it repeats the sample. NEXT changes the seed and draws again. LESS and MORE change the variation amount in steps of 0.25, from 0 to 1. At zero the generated result is the mean. The display names the result; randomness alone is not evidence of improvement.

SAVE stores source takes in user://ada_student_generation_takes_v1.json; LOAD restores them. IMPORT reads user://ada_student_phrase_v1.json from the previous hall. A successful load, added take or UNDO invalidates this generator: FIT again. Invalid files leave the current data intact. Generated paths are never added to teaching. The seed/amount and candidate are session controls, not saved in this small version. To repeat a result later, record them along with the source file and Godot version.

## What FIT learns

The resampler from Sequence Memory gives each take 41 rows of six numbers. Average each coordinate separately at each time to obtain the mean. Then subtract the mean from each whole take. The resulting array is that take's **residual**: how both hands differed throughout the phrase.

To generate, draw one normally distributed coefficient per residual. Keep that coefficient fixed across every time and both hands. Multiply each residual by its coefficient, add them, then add the mean. We reuse normal randomness from the earlier sequence; we do not scatter fresh independent noise at every point.

That shared coefficient matters. If the examples associate a wider left-hand arc with a higher right hand, their residuals retain that relationship. Independent jitter would lose it. If every teaching take is identical, all residuals are zero: changing the seed cannot create variation the model never observed.

The amount controls distance from the mean. Dividing the residual sum by the square root of (number of takes minus one) gives a precise statistical construction: before preview filtering, at amount 1 its expected covariance equals the sample covariance of the aligned takes. Covariance records which coordinates vary together, including across hands and times. At amount 0.5 the variance is one quarter as large. You can follow the loops without building a covariance matrix.

This is a fitted Gaussian trajectory model. The Gaussian choice and the amount are our decisions; the mean and correlated directions come from data. It can combine and extrapolate observed differences, but cannot learn a new direction of variation from nothing. Unlike recognition, FIT does not impose the previous matching tolerance. Mixing unrelated phrases can therefore produce an unhelpful average. Start with one family and inspect what happens.

## How large is its possibility space?

Each resampled phrase contains 41 × 6 = 246 numbers. But N teaching takes do not supply N independent residual directions: their deviations from the mean add to zero, so one can be written using the others. The generator can therefore vary in **at most N−1 independent directions** around the mean. Three takes give at most two; twelve give at most eleven. Repeated or dependent examples can give fewer. This is the rank limit of this empirical model, not a limit on every kind of generative system.

Use that fact as an experiment. Teach only wider and narrower versions of one phrase, then change the seed repeatedly. Does a new seed introduce a different order of movements? It cannot invent a direction absent from these residuals. Teach a different timed variation deliberately, refit, and compare again. More randomness and a richer set of examples are different changes.

## What a sample does not establish

A normal distribution has tails. The code retains the raw result and withholds its preview if a coordinate leaves the existing range or either hand lacks the exercise's minimum movement. It does not clip the data or secretly redraw until a pleasant sample appears. These are display policies, not a test of beauty, bodily feasibility or dance quality. Filtering also changes the distribution of the previews you see.

A path that differs from all recordings is evidence of a new numerical sample. It does not settle originality, intention or value. The large adversarial diagram asks a further question: what if another learned model supplies the judgement? Here there is no trained critic; inspect the result yourself.

## Complete new learner

Read fit first: it reuses resample, calculates the mean and keeps each complete residual. Then read compose: one coefficient stays attached to each residual. draw supplies those coefficients with its own seeded random generator, so other museum randomness cannot alter the comparison. Godot documents seeded sequences and normally distributed randfn values; reproducibility across engine versions is not promised. [Godot RandomNumberGenerator](https://docs.godotengine.org/en/4.4/classes/class_randomnumbergenerator.html)

<!-- student-code:phrase_generator.gd -->
```gdscript
extends RefCounted
## Fit a Gaussian distribution over complete, aligned, paired hand paths.
const Movement = preload("movement_learner.gd")
var mean: Array = []
var residuals: Array = []
var trained := false
var message := "Fit at least three whole takes."

func clear() -> void:
    mean.clear(); residuals.clear(); trained=false

func fit(takes: Array) -> bool:
    clear()
    if takes.size()<3 or takes.size()>Movement.MAX_TAKES:
        message="Need 3 to 12 complete takes."; return false
    var aligned: Array=[]
    for take in takes:
        if not Movement.valid_take(take):
            message="Incomplete or invalid take."; return false
        var rows: Array=Movement.resample(take)
        if Movement.hand_motion(rows,0)<0.07 or Movement.hand_motion(rows,1)<0.07:
            message="Each teaching take must move both hands."; return false
        aligned.append(rows)
    for i in Movement.STEPS:
        var row: Array=[0.0,0.0,0.0,0.0,0.0,0.0]
        for take: Array in aligned:
            for j in 6: row[j]+=float(take[i][j])/aligned.size()
        mean.append(row)
    for take: Array in aligned:
        var difference: Array=[]
        for i in Movement.STEPS:
            var row: Array=[]
            for j in 6: row.append(float(take[i][j])-float(mean[i][j]))
            difference.append(row)
        residuals.append(difference)
    trained=true; message="Mean and joint variation fitted."
    return true

func draw(sample_seed: int, amount: float) -> Dictionary:
    if not trained or not is_finite(amount) or amount<0 or amount>1: return {}
    var rng:=RandomNumberGenerator.new()
    rng.seed=sample_seed
    var weights: Array=[]
    for _take in residuals: weights.append(rng.randfn(0,1))
    return compose(weights,amount)

func compose(weights: Array, amount: float) -> Dictionary:
    if not trained or weights.size()!=residuals.size(): return {}
    if not is_finite(amount) or amount<0 or amount>1: return {}
    for value in weights:
        if not (value is int or value is float) or not is_finite(float(value)): return {}
    var rows: Array=mean.duplicate(true)
    var factor:=amount/sqrt(float(residuals.size()-1))
    # ONE coefficient per WHOLE residual, shared by both hands and all times.
    for k in residuals.size():
        for i in Movement.STEPS:
            for j in 6: rows[i][j]+=factor*float(weights[k])*float(residuals[k][i][j])
    var inside:=true
    for row: Array in rows: inside=inside and Movement.valid_x(row)
    var moving:=Movement.hand_motion(rows,0)>=0.07 and Movement.hand_motion(rows,1)>=0.07
    # Keep raw output inspectable; do not clip, retry or call it a dance score.
    return {"rows":rows,"weights":weights.duplicate(),"amount":amount,
        "previewable":inside and moving,
        "reason":"Ready to preview." if inside and moving else "Outside coordinate or two-hand-motion policy; preview withheld."}
```

## Extend the existing study

The host replaces the panel and the meaning of a completed take. Recording, interruption, timing, the sphere and drawing stay inherited. show_rows borrows the old playback format only; setting its display flag does not fit a recogniser.

<!-- student-code:generative_study.gd -->
```gdscript
extends "sequence_study.gd"
## Carry the sphere, tracked capture, beat and two airborne paths.
const Generator=preload("phrase_generator.gd")
const GENERATION_FILE:="user://ada_student_generation_takes_v1.json"
var generator:=Generator.new()
var sample_seed:=1
var amount:=0.5
var generated:Dictionary={}
var display_phrase:=Movement.new()

func _ready() -> void:
    super._ready()
    remove_child(panel); panel.free()
    var rows:Array=[]; var commands:Array=[]
    for names in [["CAPTURE","FIT","SOURCE"],["MEAN","DRAW","NEXT"],["LESS","MORE","IMPORT"],["UNDO","SAVE","LOAD"],["SOUND","STOP"]]:
        var row:Array=[]
        for word in names:
            row.append({"type":"button","label":word}); commands.append(word)
        rows.append(row)
    panel=Rack.create_panel("SAME PHRASE / ANOTHER POSSIBILITY",rows)
    panel.position=Vector3(0,0.75,0.8); panel.rotation_degrees.x=-30
    panel.scale=Vector3.ONE*2; add_child(panel)
    for i in commands.size():
        var button=panel.find_child("Btn_%d"%i,true,false).get_node("InteractableAreaButton")
        button.button_pressed.connect(func(_area):command(commands[i]))
    mode="TEACH"; message="IMPORT saved ONE or CAPTURE 3 takes, then FIT."
    refresh()

func invalidate_generation() -> void:
    generator.clear(); generated.clear(); replay_time=-1
    display_phrase.invalidate()

func complete_phrase() -> void:
    var take:=pending.duplicate(true)
    stop()
    if one.add_example(take): invalidate_generation()
    message=one.message

func command(which:String) -> void:
    if which=="STOP": stop(); message="Stopped; no partial take kept."; draw_phrase(); refresh(); return
    if which=="SOUND": sound=not sound; refresh(); return
    if capturing: return
    stop()
    if which=="CAPTURE": mode="TEACH"; begin_phrase()
    elif which=="FIT":
        generated.clear(); generator.fit(one.examples); message=generator.message
    elif which=="SOURCE":
        generated.clear()
        if not one.examples.is_empty():
            show_rows(Movement.resample(one.examples[0]))
            message="SOURCE / first recorded take, resampled for display."
        else: message="Record or import a take first."
    elif which=="MEAN": preview(0.0)
    elif which=="DRAW": preview(amount)
    elif which=="NEXT": sample_seed+=1; preview(amount)
    elif which=="LESS": amount=maxf(0,amount-0.25); preview(amount)
    elif which=="MORE": amount=minf(1,amount+0.25); preview(amount)
    elif which=="UNDO":
        if one.undo(): invalidate_generation()
        message=one.message
    elif which=="SAVE":
        message="Saved source takes separately." if one.save_file(GENERATION_FILE)==OK else "Save failed."
    elif which in ["LOAD","IMPORT"]:
        var path:=ONE_FILE if which=="IMPORT" else GENERATION_FILE
        if one.load_file(path):
            invalidate_generation(); message="Source takes loaded. FIT before generating."
        else: message="Missing/invalid source file; current model kept."
    draw_phrase(); refresh()

func preview(strength:float) -> void:
    generated=generator.draw(sample_seed,strength)
    if generated.is_empty(): message="FIT valid teaching takes first."; return
    message=generated.reason
    if generated.previewable:
        show_rows(generated.rows)
        message="MEAN / no variation" if strength==0 else "GENERATED / seed %d / amount %.2f"%[sample_seed,strength]

func show_rows(rows:Array) -> void:
    display_phrase.prototype=rows.duplicate(true)
    display_phrase.trained=true # Playback adapter, not a fitted recogniser.
    replay_model=display_phrase; replay_time=0; last_beat=-999

func refresh() -> void:
    readout.text="A PHRASE VARIED / %d source takes\n"%one.examples.size()
    readout.text+="Fitted %s / seed %d / amount %.2f\n"%["YES" if generator.trained else "NO",sample_seed,amount]
    readout.text+=message+"\nSOURCE = recording / MEAN = fit / DRAW = sample\n"
    readout.text+="8 beats / 120 BPM / sound "+("ON" if sound else "OFF")
```

## Make an independent comparison

Before changing anything, predict which operation should move the mean and which should only change the sample. Keep the seed fixed, add a deliberately higher version of the same phrase, FIT and DRAW again. Inspect both MEAN and DRAW. Now keep the data fixed and use NEXT: the mean must stay put. Finally try three copies of one take in the test fixture; no seed should produce a different path beyond rounding error.

For a relationship test, use fixtures where every left-hand height difference accompanies twice that difference in the right hand. The generated differences should retain the factor of two at every sampled time. This distinguishes a fitted joint generator from six independent noise sources.

The ghost reconstruction extracts all eight files from the three printed chapters. It tests the numerical construction, data changes, deterministic sampling, invalid input, unchanged teaching during generation, button signals and the same point in the native museum. Synthetic fixtures cannot establish that a person will enjoy or be able to perform the result. Try the phrase yourself and keep that observation separate.

Keep the original recordings and one specific comparison. The next hall returns to the A/B library saved in Sequence Memory; its IMPORT does not read this generator or its ONE file. In Synthesis we will declare an intention before a fresh attempt and examine the answer. A candidate and its evaluation need their own records.
