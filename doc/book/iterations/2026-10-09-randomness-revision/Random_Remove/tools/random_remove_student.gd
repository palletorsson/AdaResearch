extends SceneTree

var checks: Array = []
var failures: Array = []
func _initialize() -> void: run.call_deferred()
func check(title: String, value: bool) -> void:
    checks.append({"name": title, "passed": value})
    if not value: failures.append(title)
    print("[removal-study] ", "PASS " if value else "FAIL ", title)

func expected_set(mode: String, side: int) -> Array[int]:
    var result: Array[int] = []
    for row in range(side):
        for column in range(side):
            var allowed := false
            match mode:
                "range": allowed = column in [2,3,4,5] and row in [2,3,4,5]
                "checker": allowed = (column + row) % 2 == 0
                "row": allowed = row == 3
                "column": allowed = column == 3
            if allowed: result.append(row * side + column)
    return result

func run() -> void:
    await process_frame
    var source: String
    var report: String
    var mode := "range"
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--lesson="): source = arg.trim_prefix("--lesson=")
        if arg.begins_with("--report="): report = arg.trim_prefix("--report=")
        if arg.begins_with("--mode="): mode = arg.trim_prefix("--mode=")
    var script = load(source)
    var lesson = script.new()
    lesson.position = Vector3(6,0,9)
    lesson.rotation.y = -PI/2
    root.add_child(lesson)
    var eligible := expected_set(mode,8)
    var positions: Array = []
    for cube in lesson.cubes: positions.append(cube.position)
    check("ready constructs 64 cubes and permanent slots", lesson.cubes.size()==64 and lesson.slots.size()==64)
    check("status exists and is initialized", not lesson.status.text.is_empty())
    check("point retains inherited pickup and action", lesson.point.has_method("pick_up") and lesson.point.has_method("action") and lesson.point.freeze)
    check("candidate addresses match independently specified region", lesson.candidates==eligible)
    check("new run starts with no history or last choice", lesson.history.is_empty() and lesson.last_address==-1 and lesson.last_offset==-1)
    var colours_match := true
    for i in range(64):
        var expected_colour: Color = lesson.AMBER if i in eligible else lesson.GREY
        colours_match = colours_match and lesson.cubes[i].visible and lesson.cubes[i].material_override.albedo_color==expected_colour
    check("every cube advertises its eligibility", colours_match)
    check("cube materials are independent", lesson.cubes[0].material_override!=lesson.cubes[1].material_override)
    check("cube bottoms clear the permanent plates", lesson.cubes[0].position.y-lesson.cubes[0].mesh.size.y/2 > lesson.slots[0].position.y+lesson.slots[0].mesh.size.y/2)
    var generator := RandomNumberGenerator.new()
    generator.seed = 42
    check("reset makes no random request", lesson.rng.state==generator.state)
    var pool := eligible.duplicate()
    var order: Array[int] = []
    var exact_choices := true
    var exact_bounds := true
    var deleted_from_list := true
    var visual_set := true
    for turn in range(eligible.size()):
        var offset := generator.randi_range(0,pool.size()-1)
        var address: int = pool[offset]
        pool.remove_at(offset)
        order.append(address)
        lesson.point.position.x = 0
        lesson.point.action()
        exact_choices = exact_choices and lesson.last_address==address and lesson.last_offset==offset
        exact_bounds = exact_bounds and lesson.rng.state==generator.state
        deleted_from_list = deleted_from_list and lesson.candidates==pool and lesson.history==order
        for i in range(64): visual_set = visual_set and lesson.cubes[i].visible==(i not in order)
    check("draw offset maps to the original cube address", exact_choices)
    check("each successful removal makes one correctly bounded request", exact_bounds)
    check("chosen address leaves candidates and joins ordered history", deleted_from_list)
    check("only selected cubes become invisible", visual_set)
    check("all and only eligible addresses are exhausted", lesson.candidates.is_empty() and lesson.history.size()==eligible.size())
    var seen: Dictionary = {}
    for address in lesson.history: seen[address]=true
    check("no removed address repeats", seen.size()==eligible.size())
    var stable := true
    for i in range(64): stable = stable and lesson.slots[i].visible and lesson.cubes[i].position==positions[i]
    check("slots and original cube positions survive removal", stable)
    check("empty status explains why drawing stops", lesson.status.text.contains("No eligible cubes remain"))
    var state: int = lesson.rng.state
    var empty_results := true
    for i in range(3): empty_results = empty_results and lesson.remove_one()==-1
    check("empty calls return the no-removal sentinel", empty_results)
    check("empty calls preserve generator and history", lesson.rng.state==state and lesson.history==order)
    await create_timer(0.1).timeout
    check("waiting makes no changes", lesson.rng.state==state and lesson.history==order)
    lesson.point.position.x = -0.9
    lesson.point.action()
    generator.seed = 42
    check("left action resets list history and generator", lesson.candidates==eligible and lesson.history.is_empty() and lesson.rng.state==generator.state)
    var all_visible := true
    for cube in lesson.cubes: all_visible = all_visible and cube.visible
    check("reset restores every display cube", all_visible)
    var replay: Array[int] = []
    for i in range(eligible.size()): replay.append(lesson.remove_one())
    check("reset reproduces the complete order", replay==order)
    lesson.point.position.x = 0.9
    lesson.point.action()
    check("right action increments seed and restores candidates", lesson.seed_value==43 and lesson.candidates==eligible and lesson.history.is_empty())
    generator.seed = 43
    check("next seed starts before any draw", lesson.rng.state==generator.state)
    var next_order: Array[int] = []
    for i in range(eligible.size()): next_order.append(lesson.remove_one())
    lesson.reset_run()
    var next_replay: Array[int] = []
    for i in range(eligible.size()): next_replay.append(lesson.remove_one())
    check("new seed is replayable without requiring novelty", next_order==next_replay)
    var other = script.new()
    other.side = 4
    other.seed_value = 731
    root.add_child(other)
    var small := expected_set(mode,4)
    check("four-by-four transfer builds 16 cells and the right subset", other.cubes.size()==16 and other.candidates==small)
    check("larger transfer cubes still clear the permanent plates", other.cubes[0].position.y-other.cubes[0].mesh.size.y/2 > other.slots[0].position.y+other.slots[0].mesh.size.y/2)
    var small_order: Array[int] = []
    for i in range(small.size()): small_order.append(other.remove_one())
    small_order.sort()
    check("smaller grid also exhausts precisely its eligible addresses", small_order==small and other.remove_one()==-1)
    check("instances own their candidate and history arrays", lesson.history==next_order and lesson.rng!=other.rng)
    var file := FileAccess.open(report,FileAccess.WRITE)
    file.store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"source":source,"mode":mode,"first_order":order,"engine":Engine.get_version_info(),"scope":"Exact printed files; authored variations; inherited action at specified local poses. No physical headset or independent reader."},"  "))
    file.close()
    lesson.free()
    other.free()
    quit(0 if failures.is_empty() else 1)
