extends SceneTree

var subject: Node3D
var passed := 0

func _initialize() -> void:
    call_deferred("_run")

func expect(condition: bool, name: String, detail: Dictionary = {}) -> bool:
    print("ASSERT " + JSON.stringify({"name": name, "passed": condition, "detail": detail}))
    if not condition:
        push_error(name)
        # Schedule exit before assert so a failed assertion cannot stall a test run.
        quit(1)
    assert(condition, name)
    passed += 1
    return condition

func _run() -> void:
    var args := OS.get_cmdline_user_args()
    var mode := args[1]
    var script = load("res://" + args[0])
    if not expect(script != null and script.can_instantiate(), "script loads"):
        return
    subject = script.new()
    root.add_child(subject) # Calls the tutorial's actual _ready().
    var label = subject.get("label")
    if not expect(is_instance_valid(label) and label is Label3D, "ready creates Label3D"):
        return
    if not expect(label.get_parent() == subject, "ready parents Label3D"):
        return
    if not expect(label.font_size == 96 and is_equal_approx(label.pixel_size, 0.005), "ready sets display size"):
        return
    var initial_text: String = label.text
    var previous_frame := Engine.get_process_frames()
    var previous_value := int(initial_text)
    var expected_text := "0" if mode == "repeated" else str(previous_frame)
    if not expect(initial_text == expected_text, "ready sets initial text", {"actual": initial_text, "expected": expected_text}):
        return

    # A startup callback can itself read frame zero, equal to the initial text.
    await process_frame
    for sample in range(1, 5):
        # process_frame is emitted before node _process callbacks. Two signals
        # guarantee the tutorial has received a real callback between samples.
        await process_frame
        await process_frame
        var frame := Engine.get_process_frames()
        var detail := {"sample": sample, "engine_frame": frame, "label_text": label.text}
        if not expect(frame > previous_frame, "engine advances " + str(sample), detail):
            return
        if mode == "repeated":
            var value := int(label.text)
            if not expect(label.text.is_valid_int() and absi(frame - value) <= 1, "label follows engine " + str(sample), detail):
                return
            if not expect(value > previous_value, "label advances " + str(sample), detail):
                return
            previous_value = value
        elif not expect(label.text == initial_text, "once label holds " + str(sample), detail):
            return
        previous_frame = frame

    print("RESULT " + JSON.stringify({"passed": passed, "mode": mode, "completed": true}))
    subject.free()
    quit(0)
