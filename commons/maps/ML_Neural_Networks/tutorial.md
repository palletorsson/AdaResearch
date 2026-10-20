# Neural Networks — what a weight keeps

## Learning elements

- Supplied labels versus a cluster index
- Weighted sums, biases and function composition
- Transient activations versus retained parameters
- A two-input, three-hidden-unit, one-output network
- Binary cross-entropy and the chain rule
- Full-batch gradient descent; numerical gradient checks
- Training examples versus separate check examples
- Target leakage and the limits of a high score

## The same sphere, a different question

Classification kept observations fixed while you moved one centre. Here the familiar PointBody marks **an input**, not a parameter. Moving it changes the activations and output of a network while its weights stay fixed. Press STEP to change weights. This separation is the lesson: trying a new input is not training.

We remain inside Endless Museum. The existing large network is useful for following connections across layers. Its training example needs care, however: it has four inputs, and the last two already encode its two desired outputs in reverse order. That display cannot establish that a network learned the two-input exclusive-or relation without being given the answer. Its own readout and the lower disclosure panel now name that leakage and show which inputs contain which targets. Our reconstruction uses only the two independent coordinates. A familiar sphere or diagram does not imply that the internal model or its evidence has stayed the same.

The four training positions occupy the corners of a square. The supplied labels are 1 at opposite-sign corners and 0 at same-sign corners. A single straight boundary in these two coordinates cannot separate those diagonal pairs. Three tanh units provide a nonlinear intermediate representation. We fit thirteen numbers; we do not write the label rule inside forward(). FLIP reverses the labels and restarts the same initial weights, making the choice of answers visible.

Carry `point_body.gd` unchanged from `doc/book/studies/ml-classification/point_body.gd`. Keep its sphere, collision shape and pickup behaviour. Create the two complete files below beside it. The old clustering host is replaced, not added as another `_ready()`. One PointBody instance remains throughout this lesson; a new hall load still creates a new scene instance.

**Supplied infrastructure:** Godot 4.6, Ada's museum/player rig and XR Tools, plus `res://commons/audio/rack_templates/RackTemplates.gd` for spatial buttons. Their `InteractableAreaButton.button_pressed` signals are connected explicitly. No network helper is supplied or imported.

Run `res://doc/book/studies/ml-network/Network.tscn`. Its supplied `network_museum.gd` opens ML_Neural_Networks and mounts this study on checked floor. The launcher contains no training code. For your own folder, copy the carried file, save the two printed scripts together, and point the launcher's `LESSON` preload to your `network_study.gd`. The museum supplies camera, light and tracking. Model state is session-only.

## First try an input; then fit

1. Before training, move the black sphere across the left table. The two displayed input values, three hidden activations and output change. Inspect w0: it stays fixed. Height is not a feature.
2. EXAMPLE moves the sphere to another training position. The small dots retain their supplied labels. A displayed p(1) of 0.8 means the network's class-1 score is 0.8; it is not evidence that this system is 80 percent reliable.
3. STEP makes one full-batch update using all four training examples. Keep the input still and watch the values change. The readout gives current training loss, w0 and its last update. The other twelve parameters change too, even though one is singled out for inspection.
4. TRAIN toggles repeated fitting, ten updates per rendered frame, up to 1000. This controls viewing speed; each mathematical update still uses rate 0.5. Grabbing the sphere pauses training. Put it down before pressing controls.
5. CHECK evaluates four distinct interior positions, with declared targets, without adding them to training. Compare this check loss with training loss. These fixed check cases informed selection of the starting parameters, so they are development evidence, not an untouched independent test set.
6. RESET repeats the initial parameters while keeping the selected labels and input. FLIP reverses every training/check label and resets the weights. Fit again with the same coordinates. A correct answer here is correct relative to the labels we supplied.

## 1. A complete small learner

Save as `tiny_network.gd`. Each hidden unit multiplies x1 and x2 by its two weights, adds a bias, and applies tanh. The output combines the three hidden values with three more weights and a bias, then applies sigmoid. The output is bounded between zero and one.

| Parameters | Entries | Count |
| --- | --- | --- |
| Input-to-hidden weights, pairs for h0/h1/h2 | 0–5 | 6 |
| Hidden biases | 6–8 | 3 |
| Hidden-to-output weights | 9–11 | 3 |
| Output bias | 12 | 1 |

These initial values are fixed, small and different, not pre-trained. We selected a repeatable start after checking both label conventions: an earlier start fitted one convention but stalled on the reverse. Nonlinear fitting can get stuck, and these four check positions have therefore informed development; they are not an untouched evaluation set. Identical zero initialization would make the hidden units indistinguishable in this symmetric problem. Fixed values let RESET repeat an experiment. START contains parameters; data contains inputs; labels contains desired answers. No target is an input to forward().

<!-- student-code:tiny_network.gd -->
```gdscript
extends RefCounted
const START = [0.69,-0.73,0.91,-0.52,-0.53,0.25,0.59,-0.35,-0.55,-0.07,0.14,-0.1,-0.05]
const RATE := 0.5
const LIMIT := 1000
var weights := PackedFloat64Array(START)
var data := PackedVector2Array([Vector2(-0.8,-0.8),Vector2(-0.8,0.8),Vector2(0.8,-0.8),Vector2(0.8,0.8)])
var labels := PackedInt32Array([0,1,1,0])
var fresh := PackedVector2Array([Vector2(-0.6,-0.7),Vector2(-0.6,0.7),Vector2(0.6,-0.7),Vector2(0.6,0.7)])
var flipped := false
var epoch := 0
var last_change := 0.0

func reset() -> void:
    weights = PackedFloat64Array(START)
    epoch = 0
    last_change = 0.0

func flip_labels() -> void:
    flipped = not flipped
    for i in labels.size(): labels[i] = 1-labels[i]
    reset()

func forward(x: Vector2) -> Dictionary:
    var hidden := PackedFloat64Array()
    for j in 3:
        hidden.append(tanh(weights[2*j]*x.x+weights[2*j+1]*x.y+weights[6+j]))
    var z := weights[12]
    for j in 3: z += weights[9+j]*hidden[j]
    var probability: float
    if z >= 0: probability = 1.0/(1.0+exp(-z))
    else: probability = exp(z)/(1.0+exp(z))
    return {"hidden":hidden,"z":z,"p":probability}

func example_loss(x: Vector2, target: int) -> float:
    var z: float = forward(x).z
    return maxf(z,0.0)-target*z+log(1.0+exp(-absf(z)))

func loss() -> float:
    var total := 0.0
    for i in data.size(): total += example_loss(data[i],labels[i])
    return total/data.size()

func gradient(x: Vector2, target: int) -> PackedFloat64Array:
    var g := PackedFloat64Array(); g.resize(13); g.fill(0.0)
    var f := forward(x)
    var d: float = f.p-target
    g[12] = d
    for j in 3:
        g[9+j] = d*f.hidden[j]
        var dh: float = d*weights[9+j]*(1.0-f.hidden[j]*f.hidden[j])
        g[6+j] = dh
        g[2*j] = dh*x.x
        g[2*j+1] = dh*x.y
    return g

func train_epoch() -> bool:
    if epoch >= LIMIT: return false
    var mean := PackedFloat64Array(); mean.resize(13); mean.fill(0.0)
    for i in data.size():
        var g := gradient(data[i],labels[i])
        for p in 13: mean[p] += g[p]/data.size()
    last_change = -RATE*mean[0]
    for p in 13: weights[p] -= RATE*mean[p]
    epoch += 1
    return true

func check_fresh() -> Dictionary:
    var total := 0.0
    var correct := 0
    var scores: Array = []
    for i in fresh.size():
        var f := forward(fresh[i]); scores.append(f.p)
        total += example_loss(fresh[i],labels[i])
        if int(f.p >= 0.5) == labels[i]: correct += 1
    return {"loss":total/fresh.size(),"correct":correct,"scores":scores}
```

For a target y of 0 or 1 and an output p, binary cross-entropy is `-y*log(p) - (1-y)*log(1-p)`. `example_loss()` computes the equivalent expression from the output sum z, avoiding logarithms of probabilities rounded to zero. The stable sigmoid branches also avoid an overflowing exponential for large negative sums. This numerical arrangement changes neither the task nor its target.

Follow `gradient()` from the output backwards. For sigmoid with this loss, the derivative with respect to z is `p-y`. An output weight's derivative is that error times the hidden activation it multiplies. To reach a hidden unit, multiply by its outgoing weight, then by `1-h*h`, the derivative of tanh. Finally multiply by the corresponding input for each incoming weight. A bias has an implicit input of one. Backpropagation is this chain of derivatives; gradient descent is the subsequent parameter update. They are different operations.

`train_epoch()` averages all four examples' derivatives before changing **any** weight. Thus every derivative refers to the same parameter state. Only after accumulation do we subtract RATE times the mean. Updating outgoing weights before computing hidden derivatives would mix states. The previous manuscript did that and omitted activation derivatives; this complete version replaces the sketch.

One forward calculation returns new hidden values and a score. It does not change the weights. `check_fresh()` also leaves weights, epoch and training data untouched. Its targets come from the matching order of the four supplied check positions and labels, not from the network's answer. No human data enters this exercise.

## 2. Make the calculation visible in the hall

Save as `network_study.gd`. The left table contains the supplied observations and carried input point. The right diagram shows the actual forward calculation for that point. Thin cylinders represent weights: colour shows sign, width shows magnitude with a visual cap. Node numbers show activations. These are separate visual encodings. Biases participate in the printed model but have no separate wire in this compact diagram.

<!-- student-code:network_study.gd -->
```gdscript
extends Node3D
const Model = preload("tiny_network.gd")
const PointBody = preload("point_body.gd")
const Rack = preload("res://commons/audio/rack_templates/RackTemplates.gd")
const ZERO = Color("f18caa")
const ONE = Color("64dad5")
var model := Model.new()
var point: PointBody
var probe := Vector2(-0.8,-0.8)
var example := 0
var running := false
var was_held := false
var check_result: Dictionary = {}
var drawing := Node3D.new()
var readout := Label3D.new()

func _ready() -> void:
    add_child(drawing)
    box(Vector3(-1.05,0.86,0),Vector3(1.8,0.06,1.8))
    box(Vector3(0.8,1.65,-0.8),Vector3(2.2,1.95,0.04))
    box(Vector3(0,2.9,-0.85),Vector3(4,0.6,0.04))
    readout.position = Vector3(0,2.9,-0.8); readout.font_size = 25
    readout.pixel_size = 0.0025; add_child(readout)
    point = PointBody.new(); add_child(point)
    var words := ["STEP","TRAIN","RESET","EXAMPLE","CHECK","FLIP"]
    var rows: Array = []
    for r in 2:
        var row: Array = []
        for c in 3: row.append({"type":"button","label":words[r*3+c]})
        rows.append(row)
    var panel := Rack.create_panel("FIT / PROBE",rows)
    panel.position = Vector3(0,1.05,1.2); panel.rotation_degrees.x = -30
    panel.scale = Vector3.ONE*2; add_child(panel)
    for mesh in panel.find_children("*","MeshInstance3D",true,false):
        var m := mesh.material_override as BaseMaterial3D
        if m != null:
            m = m.duplicate(); m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
            mesh.material_override = m
    for i in words.size():
        var button = panel.find_child("Btn_%d"%i,true,false).get_node("InteractableAreaButton")
        button.button_pressed.connect(func(_area):command(words[i]))
    redraw()

func material(colour: Color) -> StandardMaterial3D:
    var m := StandardMaterial3D.new(); m.albedo_color = colour
    m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    return m

func box(where: Vector3, size: Vector3) -> void:
    var node := MeshInstance3D.new(); var mesh := BoxMesh.new(); mesh.size = size
    node.mesh = mesh; node.position = where
    node.material_override = material(Color("18202b")); add_child(node)

func place(p: Vector2, height: float = 1.03) -> Vector3:
    return Vector3(-1.05+p.x*0.78,height,p.y*0.78)

func label(text: String, where: Vector3, size: int = 22) -> void:
    var node := Label3D.new(); node.text = text; node.position = where
    node.font_size = size; node.pixel_size = 0.002; drawing.add_child(node)

func dot(where: Vector3, colour: Color, radius: float = 0.06) -> void:
    var mesh := SphereMesh.new(); mesh.radius = radius; mesh.height = radius*2
    mesh.radial_segments = 16; mesh.rings = 8
    var node := MeshInstance3D.new(); node.mesh = mesh; node.position = where
    node.material_override = material(colour); drawing.add_child(node)

func wire(a: Vector3, b: Vector3, weight: float) -> void:
    var d := b-a
    var mesh := CylinderMesh.new(); mesh.height = d.length(); mesh.radial_segments = 8
    mesh.top_radius = 0.006+0.004*minf(absf(weight),4); mesh.bottom_radius = mesh.top_radius
    var node := MeshInstance3D.new(); node.mesh = mesh; node.position = (a+b)*0.5
    node.quaternion = Quaternion(Vector3.UP,d.normalized())
    node.material_override = material(ONE if weight>=0 else ZERO); drawing.add_child(node)

func redraw() -> void:
    for child in drawing.get_children(): drawing.remove_child(child); child.queue_free()
    for i in model.data.size():
        dot(place(model.data[i],0.94),ONE if model.labels[i]==1 else ZERO,0.032)
        label(str(model.labels[i]),place(model.data[i],1.16))
    label("INPUTS x1 / x2\nSmall dots: supplied labels",Vector3(-1.05,1.5,-0.75))
    var f := model.forward(probe)
    var inputs := [Vector3(0,1.9,-0.7),Vector3(0,1.25,-0.7)]
    var hidden := [Vector3(0.75,2.2,-0.7),Vector3(0.75,1.6,-0.7),Vector3(0.75,1,-0.7)]
    var output := Vector3(1.5,1.6,-0.7)
    for j in 3:
        for i in 2: wire(inputs[i],hidden[j],model.weights[2*j+i])
        wire(hidden[j],output,model.weights[9+j])
    for i in 2:
        var value: float = probe[i]
        dot(inputs[i],ONE if value>=0 else ZERO)
        label("x%d %.2f"%[i+1,value],inputs[i]+Vector3(0,0.17,0.02))
    for j in 3:
        var value: float = f.hidden[j]
        dot(hidden[j],(ONE if value>=0 else ZERO).darkened(0.6*(1-absf(value))))
        label("h%d %.2f"%[j,value],hidden[j]+Vector3(0,0.17,0.02))
    dot(output,ZERO.lerp(ONE,f.p),0.09)
    label("p(1) %.3f"%f.p,output+Vector3(0,0.24,0.02))
    label("Wire colour: sign / width: |weight|\nNode values: this input's activations",Vector3(0.8,0.77,-0.7),18)
    var heldout := "CHECK: four separate positions not yet measured"
    if not check_result.is_empty(): heldout = "CHECK loss %.4f / %d of 4 correct"%[check_result.loss,check_result.correct]
    readout.text = "%s / epoch %d / train loss %.4f / labels flipped %s\nw0 %.4f / last update %+.5f\n%s"%[
        "TRAINING" if running else "PAUSED",model.epoch,model.loss(),model.flipped,model.weights[0],model.last_change,heldout]
    if not point.held(): point.global_position = to_global(place(probe))

func command(word: String) -> void:
    if point.held(): return
    var was_running := running; running = false
    match word:
        "STEP": model.train_epoch(); check_result.clear()
        "TRAIN": running = not was_running and model.epoch<Model.LIMIT
        "RESET": model.reset(); check_result.clear()
        "EXAMPLE": example = (example+1)%model.data.size(); probe = model.data[example]
        "CHECK": check_result = model.check_fresh()
        "FLIP": model.flip_labels(); check_result.clear()
    redraw()

func _physics_process(_delta: float) -> void:
    if not point.held(): point.global_position = to_global(place(probe))

func _process(_delta: float) -> void:
    if point.held():
        running = false; was_held = true
        var hand := to_local(point.global_position)
        probe = Vector2(clampf((hand.x+1.05)/0.78,-1,1),clampf(hand.z/0.78,-1,1))
        redraw()
    elif was_held:
        was_held = false; redraw()
    elif running:
        check_result.clear()
        for i in 10:
            if not model.train_epoch(): running = false; break
        redraw()
```

The host converts the held sphere's world position into its local frame, then reads the table's x/z coordinates. One input unit occupies 0.78 metres; both coordinates are bounded to [-1, 1]. Height, controller rotation and velocity are absent. Upon release, the sphere returns to display height. `_physics_process()` keeps the unheld rigid body's position synchronized across physics ticks, carrying the fix established in Classification.

The held sphere changes `probe`, not `data`, `labels` or `weights`. Buttons are ignored while it is held. STEP, RESET and FLIP clear the previous CHECK readout; TRAIN clears it when updates start. EXAMPLE and hand movement only change the input, so a check of the unchanged model remains valid. The readout never silently presents an old check as evidence for new weights.

## Build, then investigate

Before running the first forward pass at `(-0.8, -0.8)`, calculate h0: `tanh((0.69 * -0.8) + (-0.73 * -0.8) + 0.59) = tanh(0.622)`, about 0.55252. The complete pass gives p(1) about 0.46547, although its supplied target is 0. It happens to fall on the correct side of 0.5. One correct untrained answer does not establish a successful fit.

Now change the input while keeping weights fixed. Explain why activations change and w0 does not. Return to that input and STEP. Explain why the prediction can now change without moving the point. Repeat with a different connection by inspecting its array entry before and after an update.

Our reconstruction tests every analytic derivative against a central difference, returning to Gradient Landscape's numerical method: perturb one parameter by +epsilon and -epsilon, measure that example's loss, and divide the difference by twice epsilon. Restore the parameter each time. This independent check can catch a missing tanh derivative or an update using already-changed weights. It is a code test, not the training method used in the lesson.

After 1000 updates with the printed start and original labels, training loss should be about 0.00504; the four printed check positions give about 0.00740 and four correct thresholded answers. These are reproducible results on eight authored positions. They establish neither a general success rate nor good behaviour everywhere in the square. At the untrained centre `(0,0)`, inspect how decisive the fitted score can look despite having no example there. A smooth field of answers is not a field of equally strong evidence.

As an independent change, FLIP, fit again, and verify the opposite answers at the same corners. Then, in your model copy, change just one corner label and predict which training error should initially increase. Refit before evaluating separate cases whose expected answers you have stated. Do not use the model's own predictions as correct targets for its test.

**Run the reconstruction:** `python tools/test_ml_network_lesson.py` extracts the two marked code blocks, adds the declared PointBody, and runs native Godot assertions. It checks all thirteen derivatives at multiple parameter/input states, an independent forward calculation, one update against numerical derivatives, fitting both label conventions, fixed check cases that never enter training, controls, point identity and delayed physics synchronization. The separate museum probe mounts these extracted files in the actual hall. These synthetic checks do not establish headset comfort or independent-reader comprehension.

## What travels onward

A forward pass changes activations. Fitting changes retained weights. The feature representation and supplied answers come before either operation. In Perception we expand this same structure to six hand coordinates, eight tanh units and three softmax outputs. Its cross-entropy gradient still starts with score minus supplied target, and all parameter derivatives must use the same old weights. The Perception chapter prints the complete larger model; no hidden dependency on this small example is introduced.

The familiar sphere then acquires an authored response to a learned label. This lesson prepares the separation: input representation, fitted mapping, acceptance policy and what the object does with an answer.

References for the calculus and independent checks: Stanford's [backpropagation notes](https://cs231n.github.io/optimization-2/) and [gradient-checking guidance](https://cs231n.github.io/neural-networks-3/). The original museum source is `algorithms/machinelearning/neuralnetworkvisualization/neural_network_visualization.gd`; inspect its `generate_training_data()` to see the extra answer-bearing inputs.

AI-short: Carry Classification PointBody; now query input, not centre/weight. Print 2→3 tanh→1 sigmoid, 13 parameters; four two-coordinate corner inputs, explicit binary targets; fixed asymmetric start. Forward does not fit. BCE stable logits; d=p-y; tanh chain; average gradients before any update. STEP/TRAIN/RESET/EXAMPLE/CHECK/FLIP. No target in input. Fixed check positions excluded from fit; scores not certainty. Test all gradients numerically, independent forward/update, changed labels, signals, native delayed body sync. Original four-input exhibit leaks targets; retain and disclose. Next six-hand-coordinate pose model.
