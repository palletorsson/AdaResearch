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
