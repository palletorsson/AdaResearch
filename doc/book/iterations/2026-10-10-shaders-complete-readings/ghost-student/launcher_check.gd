extends SceneTree
## Supplied launcher contract, separate from the student's independent probes.
class MuseumFixture extends Node3D:
    var EM_CONTROL: String = ""
    var start_chapter: String = ""
    var start_map: String = ""

var checks: Array = []

func check(label: String, passed: bool) -> void:
    checks.append({"test": label, "passed": passed})

func _initialize() -> void:
    call_deferred("run")

func run() -> void:
    var cases := {
        "shaping": "Shader_01_Shaping", "patterns": "Shader_05_Patterns",
        "materials": "Shader_11_QueerRubber", "water": "Shader_09_FBM",
        "pink": "Shader_12_PinkExtravaganza", "state": "Shader_10_ReactionDiffusion"
    }
    var fixture := {"first_chapter": "color", "first_map": "Color", "resume_eye": [1,2,3],
        "resume_hall": "Color", "resume_yaw": 1, "resume_pitch": 2, "travel": true,
        "dollhouse": 1, "grid_pack": 0, "reader_preference": "keep me"}
    var source := "user://shader_ghost_launcher_fixture.json"
    var output := "user://shader_ghost_launcher_output.json"
    var f := FileAccess.open(source, FileAccess.WRITE)
    f.store_string(JSON.stringify(fixture)); f.close()
    var original := FileAccess.get_file_as_string(source)
    for key in cases:
        var launcher = load("res://doc/book/studies/shaders-lineage/" + key + "_museum.gd")
        var has_configure: bool = launcher.has_method("configure")
        check(key + ": isolated lesson launch configuration exists", has_configure)
        if not has_configure: continue
        var museum := MuseumFixture.new()
        museum.EM_CONTROL = source
        launcher.configure(museum, output)
        var settings = JSON.parse_string(FileAccess.get_file_as_string(output))
        check(key + ": requested chapter and map override saved travel", settings.get("first_chapter") == "shaders" and settings.get("first_map") == cases[key])
        check(key + ": stale eye/pose/travel removed", not settings.has("resume_eye") and not settings.has("resume_hall") and not settings.has("resume_yaw") and not settings.has("resume_pitch") and not settings.has("travel"))
        check(key + ": full-size room and grid enabled", settings.get("dollhouse") == 0 and settings.get("grid_pack") == 1)
        check(key + ": other preferences retained", settings.get("reader_preference") == "keep me")
        check(key + ": original saved control untouched", FileAccess.get_file_as_string(source) == original)
        check(key + ": museum uses isolated control and requested hall", museum.EM_CONTROL == output and museum.start_chapter == "shaders" and museum.start_map == cases[key])
        museum.free()
    var passed := true
    for c in checks: if not c.passed: passed = false
    var report := "res://doc/book/iterations/2026-10-10-shaders-ghost-student/launcher-check.json"
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--report="): report = arg.trim_prefix("--report=")
    var result := FileAccess.open(report, FileAccess.WRITE)
    result.store_string(JSON.stringify({"passed":passed,"checks":checks,"scope":"Supplied launcher configuration only; no scene or rendering claim."},"  ")); result.close()
    print("SHADER_LAUNCHER_CHECK ", passed, " / ", checks.size())
    quit(0 if passed else 1)
