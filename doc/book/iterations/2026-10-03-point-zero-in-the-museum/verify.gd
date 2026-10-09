extends "res://tools/probes/transformation_encounters.gd"
## Run printed function edits on the existing counter, only in this test process.
var panel: Node3D
var original_source: String
var original_transform: Transform3D
var original_parent: Node3D

func landing_checks() -> void:
    museum.flush_stamps()
    await create_timer(1.0).timeout
    panel = find_scene("/frame_counter_display.gd")
    check("existing museum frame counter loaded", panel != null)
    if panel == null: return
    original_source = panel.get_script().source_code.replace("\r", "")
    original_transform = panel.transform
    original_parent = panel.get_parent()
    observations["panel_world"] = xyz(panel.global_position)
    check("original panel counts engine frames since boot", panel.reading == "count" and panel.epoch == "boot" and abs(panel.label.text.to_int() - Engine.get_process_frames()) <= 1)
    check("label is code-created inside the existing console", panel.label is Label3D and panel.label.get_parent().get_parent() == panel)
    await picture("museum-counter")
    var lesson := FileAccess.get_file_as_string("res://commons/maps/Point_Zero/tutorial.md").replace("\r", "")
    var regex := RegEx.new()
    regex.compile("(?s)```gdscript\\n(.*?)```")
    var blocks: Array[String] = []
    for item in regex.search_all(lesson): blocks.append(item.get_string(1).replace("    ", "\t").strip_edges())
    check("lesson has the ready, process and once-only functions", blocks.size() == 3)
    if blocks.size() != 3: return
    check("printed ready function is the actual artifact function", original_source.contains(blocks[0]))
    var repeated := replace_function(original_source, "_process", blocks[1])
    if not install_source(repeated): return
    var first: int = panel.label.text.to_int()
    await create_timer(0.4).timeout
    check("printed process edit updates the same console", panel.label.text.to_int() > first and abs(panel.label.text.to_int() - Engine.get_process_frames()) <= 1)
    panel.set_process(false)
    var frame := Engine.get_process_frames()
    panel._process(0.0001)
    var short_text: String = panel.label.text
    panel._process(0.9)
    check("delta does not alter the total being read", short_text == str(frame) and panel.label.text == str(frame))
    panel.set_process(true)
    await picture("every-frame")
    var once := replace_function(repeated, "_process", "")
    once = replace_function(once, "_ready", blocks[2])
    if not install_source(once): return
    first = panel.label.text.to_int()
    frame = Engine.get_process_frames()
    await create_timer(0.4).timeout
    check("ready-only display keeps its initial reading", panel.label.text.to_int() == first)
    check("engine keeps processing while display is held", Engine.get_process_frames() > frame)
    check("ready reading includes frames before panel readiness", first > 0)
    check("removing process removes the recurring callback", not panel.has_method("_process"))
    await picture("read-once")
    var restored := replace_function(once, "_ready", blocks[0]) + "\n\n" + blocks[1] + "\n"
    if not install_source(restored): return
    await create_timer(0.3).timeout
    check("returning the assignment to process resumes updates", abs(panel.label.text.to_int() - Engine.get_process_frames()) <= 1)
    if not install_source(original_source): return
    await create_timer(0.2).timeout
    check("restored artifact retains the original readout", panel.caption.text == "Frames" and abs(panel.label.text.to_int() - Engine.get_process_frames()) <= 1)
    check("production source was never changed by the probe", FileAccess.get_file_as_string("res://commons/visualaid/frame_counter/frame_counter_display.gd").replace("\r", "") == original_source)

func replace_function(source: String, function_name: String, replacement: String) -> String:
    var start := source.find("func " + function_name + "(")
    assert(start >= 0)
    var end := source.find("\nfunc ", start + 1)
    if end < 0: end = source.length()
    return source.substr(0, start) + replacement + "\n\n" + source.substr(end)

func install_source(source: String) -> bool:
    var script := GDScript.new()
    script.source_code = source
    var valid := script.reload() == OK
    check("artifact with printed edit compiles", valid)
    if not valid: return false
    panel.free()
    panel = script.new()
    panel.transform = original_transform
    original_parent.add_child(panel)
    check("edited script creates its own existing-style display", panel.label != null and panel.label.get_parent().get_parent() == panel)
    return true

func picture(name: String) -> void:
    var target: Vector3 = panel.label.global_position
    await snapshot(name, target + Vector3(0.7, 0.15, -2.7), target, 60)

func finish() -> void:
    var report := {"room": map_id, "passed": failures.is_empty(), "checks": checks, "failures": failures, "observations": observations, "scope": "Printed function edits run in memory on the existing counter at its museum placement. No production script or map changes. Physical headset and beginner comprehension untested."}
    FileAccess.open(folder + "report.json", FileAccess.WRITE).store_string(JSON.stringify(report, "  "))
    print("POINT ZERO EXISTING COUNTER ", checks.size() - failures.size(), "/", checks.size())
    quit(0 if failures.is_empty() else 1)
