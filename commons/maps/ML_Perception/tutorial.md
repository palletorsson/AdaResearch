# Perception — teach the same sphere

## Learning elements

- Represent two tracked hands with six coordinates.
- Keep one labelled example from one complete, steady take.
- Fit weights to examples; distinguish fitting from fresh testing.
- Separate a learned answer, an acceptance rule and an authored response.
- Save the model and continue with the same PointBody class.

## Already in the museum

Enter the learning bay to the right of the dance space, across the partition. The sphere, controls and room already exist. First try POSE there. We now reconstruct that capability with the PointBody class carried from the earlier lessons. Its mesh and pickup behaviour remain familiar. A narrow ring makes its rotation visible.

The preceding halls introduced selection, loss, clustering and changing network weights. Here those ideas acquire a task you can teach: decide which of three poses you mean. Positions and arrays return from Point and Trace; translation, rotation, scale and colour give the answer a visible effect. The sphere does not learn those effects. We write FLOAT, SPIN and STRETCH; the network learns which label your hand coordinates resemble.

Keep this lesson to POSE. HEIGHT, movement phrases and CHECK remain available in the full museum station, but are later extensions. A held pose contains no movement order. Sequence Memory will ask what we lose by keeping only a mean.

## Run in the supplied museum

Use the Ada Godot project and its existing XR setup. Open res://doc/book/studies/ml-lineage/Perception.tscn and run that scene. The supplied perception_museum.gd opens the actual Perception hall and mounts the learner script at its existing learning anchor. In this lesson preview it hides the full station; ordinary museum visits retain all modes. It does not alter your museum saves.

Place the three complete files below beside that launcher: point_body.gd, pose_learner.gd and pose_study.gd. PointBody is a revised version of the carried class, printed in full so this chapter can be reconstructed. Its radius grows from 0.085 to 0.14 metres and its collision mask changes from 0 to 196615 for the museum interaction layers; pickup remains XRToolsPickable with a frozen release. This version omits the earlier table's desktop grab adapter: the pose lesson records tracked XR hands. The host gives the surface a metallic finish and adds the orientation ring. These are explicit changes to the same point design, not a claim that the file is unchanged. The host uses the supplied RackTemplates.gd to create ten buttons and explicitly connects their signals. The museum supplies camera, lights, tracking and XR Tools pickup. These are declared infrastructure, not a hidden classifier. Desktop can display the lesson; recording your hands requires tracked XR controllers.

## Teach, test, then let it act

1. Face the console and press ALIGN. This keeps one horizontal reference direction until you align again. Hand positions are measured relative to the current head position in that fixed frame, divided by 0.65 metres. This scale is a design choice, not a measurement of your arm length.
2. In TEACH, choose A. A three-second countdown gives you time to move away from the button. Hold a comfortable pose for 0.65 seconds. The program averages the samples into **one** six-number example. Repeat with separate takes and small natural variation. Teach at least three takes for each of A, B and C. Choose visibly different poses; three examples is a minimum for running the exercise, not proof of sufficient data.
3. Press TRAIN. The same starting weights are fitted for 300 full-batch updates. The screen shows loss on the teaching examples. A falling value means a better fit to that sample.
4. TEST asks you to declare A, B or C before recording a fresh take. It displays what you meant and what the model predicted. No weights change. Try slightly different positions and an unfamiliar pose. A high softmax score is not calibrated certainty. Testing mistakes must remain visible rather than quietly entering training.
5. LIVE lets an accepted answer lasting a quarter-second act on the sphere: A floats, B spins, C stretches the visible mesh. Its pickup collider stays spherical. Losing tracking or moving outside the study's three-metre range idles the response. While you hold the sphere, pickup takes priority over scripted motion.
6. SAVE writes user://ada_student_pose_v1.json, separate from the museum's model files. LOAD starts a fresh evaluation session. A new teaching example invalidates the old fitted model and test records; train again. To begin an empty study, restart the scene; the saved file remains until you overwrite it with SAVE.

## Follow the calculation

The features() function returns six values in this order: left x, y, z; right x, y, z. Moving the whole measured arrangement together does not change these relative coordinates. Turning only your hands, swapping left and right, or changing the reference frame can change them. Finger shape, gaze, torso and intention are absent.

The learner is a **6 → 8 → 3** network. Each hidden unit adds six weighted inputs and a bias, then applies tanh. Each output adds eight weighted hidden values and a bias. Softmax turns the outputs into three scores summing to one. All three labels are choices you supplied.

| Stored parameters | Array entries | Count |
| --- | --- | --- |
| Input-to-hidden weights | 0–47 | 48 |
| Hidden biases | 48–55 | 8 |
| Hidden-to-output weights | 56–79 | 24 |
| Output biases | 80–82 | 3 |

Neural Networks fitted thirteen numbers to two coordinates and two labels. Here the representation has six coordinates and three labels, so we create a new 83-parameter model; we do not load the previous hall's thirteen weights. We carry its calculation and its distinction between querying and fitting. Softmax replaces the single sigmoid because this exercise chooses among three supplied alternatives.

There are 83 trainable numbers. Cross-entropy loss is minus the logarithm of the score for the given label. In gradient(), output error is the score minus the supplied target (one for the named class, zero for the others). Each weight's derivative multiplies that error by its input. Passing error through tanh also multiplies by one minus the squared hidden activation. The train_epoch() function averages those derivatives over the examples and subtracts RATE times the mean from the weights. Every derivative uses the old weights before any are updated.

Read the model in this order: add_example, forward, gradient, train_epoch, predict, test_example. Validation and persistence follow the same data contract; they are included so the printed files run without missing helpers.

Acceptance is a separate authored policy: highest score at least 0.70 **and** RMS distance to a teaching example at most 0.32. It can still accept an unfamiliar case or reject an intended one. The host's respond() then chooses a prewritten action. None of these thresholds is a measure of dance quality.


## Complete carried class

<!-- student-code:point_body.gd -->
```gdscript
extends XRToolsPickable

const RADIUS := 0.14

func _init() -> void:
    freeze = true
    freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
    release_mode = XRToolsPickable.ReleaseMode.FROZEN
    ranged_grab_method = XRToolsPickable.RangedMethod.NONE
    collision_layer = 4
    collision_mask = 196615

    var surface := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = RADIUS
    sphere.height = RADIUS * 2.0
    surface.mesh = sphere
    add_child(surface)

    var boundary := CollisionShape3D.new()
    var shape := SphereShape3D.new()
    shape.radius = RADIUS
    boundary.shape = shape
    add_child(boundary)
```


## Complete learner

<!-- student-code:pose_learner.gd -->
```gdscript
extends RefCounted
## Small real classifier: 6 hand coordinates -> 8 tanh units -> 3 softmax outputs.
## No guide poses, category templates or prerecorded scores enter this model.
const INPUTS := 6
const HIDDEN := 8
const CLASSES := 3
const PARAMETERS := 83
const MAX_PER_CLASS := 20
const EPOCHS := 300
const RATE := 0.20
const SCHEMA := "ada-hand-pose-1"
var weights := PackedFloat64Array()
var examples: Array = []
var tests: Array = []
var epoch := 0
var trained := false
var initial_loss := 0.0
var history: Array = []
var revision := 0

func _init() -> void:
	initialize(417)

func initialize(seed_value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	weights.resize(PARAMETERS)
	weights.fill(0.0)
	for j in HIDDEN:
		for i in INPUTS: weights[j * INPUTS + i] = rng.randf_range(-0.55, 0.55)
	for k in CLASSES:
		for j in HIDDEN: weights[56 + k * HIDDEN + j] = rng.randf_range(-0.55, 0.55)
	epoch = 0
	trained = false
	tests.clear()
	history.clear()
	initial_loss = loss()
	history.append(initial_loss)

static func valid_input(x: Array) -> bool:
	if x.size() != INPUTS: return false
	for v in x:
		if not (v is float or v is int) or not is_finite(float(v)) or absf(float(v)) > 4.0: return false
	return true

func counts() -> Array:
	var result := [0, 0, 0]
	for e: Dictionary in examples: result[int(e.label)] += 1
	return result

func add_example(x: Array, label: int) -> bool:
	if label < 0 or label >= CLASSES or not valid_input(x) or counts()[label] >= MAX_PER_CLASS: return false
	examples.append({"x": x.duplicate(), "label": label})
	revision += 1
	trained = false
	epoch = 0
	tests.clear()
	history.clear()
	return true

func can_train() -> bool:
	for amount in counts():
		if amount < 3: return false
	return true

func forward(x: Array) -> Dictionary:
	if not valid_input(x): return {}
	var hidden := PackedFloat64Array()
	for j in HIDDEN:
		var z := weights[48 + j]
		for i in INPUTS: z += weights[j * INPUTS + i] * float(x[i])
		hidden.append(tanh(z))
	var scores := PackedFloat64Array()
	for k in CLASSES:
		var z := weights[80 + k]
		for j in HIDDEN: z += weights[56 + k * HIDDEN + j] * hidden[j]
		scores.append(z)
	var largest := scores[0]
	for value in scores: largest = maxf(largest, value)
	var total := 0.0
	for k in CLASSES:
		scores[k] = exp(scores[k] - largest)
		total += scores[k]
	for k in CLASSES: scores[k] /= total
	return {"hidden": hidden, "scores": scores}

func gradient(x: Array, label: int) -> PackedFloat64Array:
	var result := PackedFloat64Array()
	result.resize(PARAMETERS)
	result.fill(0.0)
	var f := forward(x)
	if f.is_empty() or label < 0 or label >= CLASSES: return result
	var delta: PackedFloat64Array = f.scores.duplicate()
	delta[label] -= 1.0 # derivative of softmax + cross entropy
	for k in CLASSES:
		result[80 + k] = delta[k]
		for j in HIDDEN: result[56 + k * HIDDEN + j] = delta[k] * f.hidden[j]
	for j in HIDDEN:
		var hidden_delta := 0.0
		for k in CLASSES: hidden_delta += delta[k] * weights[56 + k * HIDDEN + j]
		hidden_delta *= 1.0 - f.hidden[j] * f.hidden[j] # tanh derivative
		result[48 + j] = hidden_delta
		for i in INPUTS: result[j * INPUTS + i] = hidden_delta * float(x[i])
	return result # all derivatives use the same, not-yet-updated weights

func example_loss(x: Array, label: int) -> float:
	return -log(maxf(1e-12, forward(x).scores[label]))

func loss() -> float:
	if examples.is_empty(): return 0.0
	var value := 0.0
	for e: Dictionary in examples: value += example_loss(e.x, int(e.label))
	return value / examples.size()

func train_epoch() -> void:
	if not can_train() or epoch >= EPOCHS: return
	var mean := PackedFloat64Array()
	mean.resize(PARAMETERS)
	mean.fill(0.0)
	for e: Dictionary in examples:
		var g := gradient(e.x, int(e.label))
		for p in PARAMETERS: mean[p] += g[p] / examples.size()
	for p in PARAMETERS: weights[p] -= RATE * mean[p]
	epoch += 1
	if epoch % 10 == 0: history.append(loss())
	trained = epoch == EPOCHS

func predict(x: Array) -> Dictionary:
	if not trained: return {}
	var f := forward(x)
	if f.is_empty(): return {}
	var best := 0
	for k in CLASSES:
		if f.scores[k] > f.scores[best]: best = k
	# A separate proximity policy. A softmax score alone cannot detect novelty.
	var distance := INF
	for e: Dictionary in examples:
		var squared := 0.0
		for i in INPUTS: squared += pow(float(x[i]) - float(e.x[i]), 2)
		distance = minf(distance, sqrt(squared / INPUTS))
	return {"label": best, "scores": f.scores, "distance": distance,
		"accepted": f.scores[best] >= 0.70 and distance <= 0.32}

func test_example(x: Array, expected: int) -> Dictionary:
	if expected < 0 or expected >= CLASSES: return {}
	var prediction := predict(x)
	if prediction.is_empty(): return {}
	var record := {"x": x.duplicate(), "expected": expected,
		"predicted": prediction.label, "accepted": prediction.accepted,
		"correct": prediction.label == expected, "revision": revision}
	tests.append(record)
	if tests.size() > 90: tests.pop_front()
	return record

func snapshot() -> Dictionary:
	return {"schema": SCHEMA, "weights": Array(weights), "examples": examples.duplicate(true),
		"tests": tests.duplicate(true), "epoch": epoch, "trained": trained,
		"initial_loss": initial_loss, "history": history.duplicate(), "revision": revision}

func restore(data: Variant) -> bool:
	if not data is Dictionary or data.get("schema") != SCHEMA: return false
	var w: Variant = data.get("weights")
	var rows: Variant = data.get("examples")
	var ep: Variant = data.get("epoch")
	if not w is Array or w.size() != PARAMETERS or not rows is Array or rows.size() > MAX_PER_CLASS * CLASSES: return false
	if not (ep is int or ep is float) or float(ep) != int(ep) or ep < 0 or ep > EPOCHS: return false
	if not data.get("trained") is bool: return false
	for v in w:
		if not (v is int or v is float) or not is_finite(float(v)) or absf(float(v)) > 1000.0: return false
	var amounts := [0, 0, 0]
	for row in rows:
		if not row is Dictionary or not row.get("x") is Array or not valid_input(row.x): return false
		var label: Variant = row.get("label")
		if not (label is int or label is float) or float(label) != int(label) or label < 0 or label >= CLASSES: return false
		amounts[int(label)] += 1
		if amounts[int(label)] > MAX_PER_CLASS: return false
	if data.trained:
		if int(ep) != EPOCHS: return false
		for n in amounts:
			if n < 3: return false
	weights = PackedFloat64Array(w)
	examples = rows.duplicate(true)
	epoch = int(ep)
	trained = data.trained
	# Re-open a saved model as a new evaluation session. Do not import stale claims.
	tests.clear()
	history.clear()
	initial_loss = loss()
	history.append(initial_loss)
	revision += 1
	return true

func save_file(path: String) -> Error:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null: return FileAccess.get_open_error()
	file.store_string(JSON.stringify(snapshot(), "  ", true, true))
	return file.get_error()

func load_file(path: String) -> bool:
	if not FileAccess.file_exists(path): return false
	return restore(JSON.parse_string(FileAccess.get_file_as_string(path)))
```


## Complete museum study

<!-- student-code:pose_study.gd -->
```gdscript
extends Node3D

const Learner = preload("pose_learner.gd")
const PointBody = preload("point_body.gd")
# Supplied museum interface; it creates and names every button used below.
const Rack = preload("res://commons/audio/rack_templates/RackTemplates.gd")
const SAVE_PATH := "user://ada_student_pose_v1.json"
var model := Learner.new()
var sphere: PointBody
var surface: MeshInstance3D
var material := StandardMaterial3D.new()
var readout := Label3D.new()
var panel: Node3D
var head: XRCamera3D
var left: XRController3D
var right: XRController3D
var facing := Basis.IDENTITY
var aligned := false
var mode := "TEACH"
var training := false
var capture_label := -1
var capture_time := 0.0
var sample_time := 0.0
var samples: Array = []
var candidate := -1
var dwell := 0.0
var response := -1
var clock := 0.0
var message := "TEACH: choose A, B or C. Hold after the countdown."

func _ready() -> void:
    sphere = PointBody.new()
    sphere.position = Vector3(0, 1.15, 0.15)
    add_child(sphere)
    surface = sphere.get_child(0) as MeshInstance3D
    material.albedo_color = Color(0.75, 0.78, 0.82)
    material.metallic = 0.65
    material.roughness = 0.18
    surface.material_override = material
    # A visible orientation mark: a perfectly plain sphere hides its own spin.
    var ring := MeshInstance3D.new()
    var torus := TorusMesh.new()
    torus.inner_radius = 0.142
    torus.outer_radius = 0.151
    ring.mesh = torus
    var mark := StandardMaterial3D.new()
    mark.albedo_color = Color(0.08, 0.08, 0.1)
    ring.material_override = mark
    surface.add_child(ring)
    var board := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = Vector3(2.6, 1.5, 0.06)
    board.mesh = box
    board.position = Vector3(0, 1.9, -0.4)
    var ink := StandardMaterial3D.new()
    ink.albedo_color = Color(0.018, 0.022, 0.035)
    board.material_override = ink
    add_child(board)
    readout.position = Vector3(0, 2.25, -0.35)
    readout.font_size = 26
    readout.pixel_size = 0.002
    readout.width = 1080
    readout.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    add_child(readout)
    var commands := ["A", "B", "C", "TEACH", "TRAIN", "TEST", "LIVE", "ALIGN", "SAVE", "LOAD"]
    var rows: Array = []
    for names in [["A", "B", "C"], ["TEACH", "TRAIN", "TEST"], ["LIVE", "ALIGN", "SAVE", "LOAD"]]:
        var row: Array = []
        for name in names: row.append({"type":"button", "label":name})
        rows.append(row)
    panel = Rack.create_panel("YOUR POSES / ONE SPHERE", rows)
    panel.position = Vector3(0, 0.85, 0.65)
    panel.rotation_degrees.x = -30
    panel.scale = Vector3.ONE * 2
    add_child(panel)
    for i in commands.size():
        var button = panel.find_child("Btn_%d" % i, true, false).get_node("InteractableAreaButton")
        button.button_pressed.connect(func(_area): command(commands[i]))
    bind_tracking()
    refresh()

func bind_tracking() -> void:
    for n in get_tree().root.find_children("*", "XRCamera3D", true, false): head = n; break
    for n in get_tree().root.find_children("*", "XRController3D", true, false):
        if n.tracker == &"left_hand": left = n
        if n.tracker == &"right_hand": right = n

func tracked() -> bool:
    if not is_instance_valid(head) or not is_instance_valid(left) or not is_instance_valid(right): return false
    var tracker := XRServer.get_tracker(&"head") as XRPositionalTracker
    if tracker == null: return false
    var pose := tracker.get_pose(&"default")
    return pose != null and pose.has_tracking_data and left.get_is_active() and right.get_is_active() and left.get_has_tracking_data() and right.get_has_tracking_data() and head.global_position.distance_to(global_position) < 3.0

func align() -> void:
    if not tracked(): return
    var forward := -head.global_basis.z
    forward.y = 0
    if forward.length_squared() < 0.01: return
    facing = Basis.looking_at(forward.normalized(), Vector3.UP)
    aligned = true

static func features(eye: Vector3, l: Vector3, r: Vector3, frame: Basis) -> Array:
    var a := frame.inverse() * (l - eye) / 0.65
    var b := frame.inverse() * (r - eye) / 0.65
    return [a.x, a.y, a.z, b.x, b.y, b.z]

func command(which: String) -> void:
    if training or capture_label >= 0: return
    bind_tracking()
    if which in ["A", "B", "C"]:
        if mode not in ["TEACH", "TEST"] or not tracked():
            message = "Choose TEACH or TEST; head and both hands must be tracked here."
        else:
            if not aligned: align()
            if aligned:
                capture_label = ["A", "B", "C"].find(which)
                capture_time = -3.0
                sample_time = 0
                samples.clear()
    elif which == "TRAIN":
        if model.can_train():
            model.initialize(417)
            training = true
            message = "Training on your examples."
        else: message = "Keep at least three separate takes for each label."
    elif which in ["TEST", "LIVE"]:
        if model.trained:
            mode = which
            if not aligned: align()
            message = "Use a fresh pose."
        else: message = "Teach all three labels, then TRAIN."
    elif which == "TEACH": mode = "TEACH"; message = "A new example requires training again."
    elif which == "ALIGN": align(); message = "Facing aligned." if aligned else "Tracking needed."
    elif which == "SAVE": message = "Saved student model." if model.save_file(SAVE_PATH) == OK else "Save failed."
    elif which == "LOAD":
        if model.load_file(SAVE_PATH):
            mode = "TEST" if model.trained else "TEACH"
            aligned = false
            message = "Loaded. Collect fresh tests."
        else: message = "No valid student save. Current model kept."
    response = -1; candidate = -1; dwell = 0
    refresh()

func _process(delta: float) -> void:
    clock += delta
    if training:
        for _i in 2: model.train_epoch()
        if model.trained:
            training = false; mode = "TEST"
            message = "Training complete. TEST a new take for each label."
    var valid := tracked() and aligned
    var x: Array = features(head.global_position, left.global_position, right.global_position, facing) if valid else []
    advance_capture(delta, x, valid)
    respond(delta, x, valid and mode == "LIVE" and not training)
    refresh()

func advance_capture(delta: float, x: Array, valid: bool) -> void:
    if capture_label < 0: return
    if not valid or not Learner.valid_input(x) or delta > 0.2 or delta < 0:
        capture_label = -1; samples.clear()
        message = "Interrupted take discarded. Choose A/B/C again."
        return
    capture_time += delta
    if capture_time < 0:
        message = "READY %d / arrange both hands" % ceili(-capture_time)
        return
    message = "HOLD / one whole take"
    sample_time += delta
    if sample_time >= 0.05:
        samples.append(x.duplicate()); sample_time = 0
    if capture_time < 0.65: return
    var label := capture_label
    capture_label = -1
    if samples.size() < 8:
        samples.clear(); message = "Too few samples. Repeat the whole take."; return
    var mean := [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
    for row: Array in samples:
        for i in 6: mean[i] += float(row[i]) / samples.size()
    var variance := 0.0
    for row: Array in samples:
        for i in 6: variance += pow(float(row[i]) - mean[i], 2) / (samples.size() * 6)
    samples.clear()
    if sqrt(variance) > 0.12:
        message = "That take moved too much. Hold the pose and try again."; return
    if mode == "TEACH":
        message = "One example kept. Move, then take another." if model.add_example(mean, label) else "Example limit reached."
    else:
        var result: Dictionary = model.test_example(mean, label)
        message = "Meant %s / predicted %s / %s" % [["A","B","C"][label], ["A","B","C"][result.predicted], "accepted" if result.accepted else "withheld"]

func respond(delta: float, x: Array, valid: bool) -> void:
    var prediction: Dictionary = model.predict(x) if valid else {}
    var next := int(prediction.label) if not prediction.is_empty() and prediction.accepted else -1
    if next != candidate: candidate = next; dwell = 0
    dwell += clampf(delta, 0, 0.1)
    response = candidate if candidate >= 0 and dwell >= 0.25 else -1
    if sphere.is_picked_up(): return
    sphere.position = Vector3(0, 1.15, 0.15)
    surface.rotation = Vector3.ZERO
    surface.scale = Vector3.ONE
    if response == 0: sphere.position.y += 0.1 + sin(clock * 2) * 0.08
    elif response == 1: surface.rotation = Vector3(clock * 1.8, clock, 0.3)
    elif response == 2: surface.scale.y = 1.25 + sin(clock * 3) * 0.35
    material.albedo_color = [Color(1,0.24,0.58),Color(0.15,0.84,1),Color(1,0.77,0.25)][response] if response >= 0 else Color(0.75,0.78,0.82)

func refresh() -> void:
    readout.text = "TEACH A SPHERE / %s\n" % mode
    readout.text += "Your takes: A %d / B %d / C %d\n" % model.counts()
    readout.text += "%s\nUpdates %d / loss %.3f\n" % [message, model.epoch, model.loss()]
    readout.text += "Fresh tests: %d / sphere: %s" % [model.tests.size(), ["FLOAT","SPIN","STRETCH"][response] if response >= 0 else "IDLE"]
```

## Change something and account for it

In a fresh session, give the same comfortable pose another label. After retraining, does its response follow the new label? Compare that with changing only FLOAT's height in respond(): one change alters the learned mapping; the other alters what we let its answer do. Explain the difference before running either experiment.

Then test a fresh take without pressing TRAIN. Confirm the number of teaching examples and weights stay fixed. Keep mistakes and withheld responses in your account. The in-memory test list retains only the latest 90 records; this small exercise is not a research evaluation archive. Loading a saved model deliberately starts a fresh list.

## Reconstruction check

Run python tools/test_ml_pose_lesson.py from the project root. It extracts these named code blocks into a separate folder, checks all 83 derivatives against numerical differences, fits synthetic examples, tests unseen fixture takes, permutes labels, checks persistence, constructs the point and label from scratch, and exercises real button signals with supplied XR trackers. It also checks interruption, test/training separation and the three visible responses. No production learner is imported to fill a gap.

Those are real Godot assertions using synthetic data. They establish executable behaviour and some invariants, not recognition accuracy across people, headset comfort or accessibility. This is an author-informed reconstruction, not an independent blind reader. Try your own examples in the museum next.

What travels onward is the same point class, a six-coordinate representation, a labelled dataset and a fitted model. Sequence Memory adds a new question: if both hands pass through the same places in a different order, should the answer stay the same?
