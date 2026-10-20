extends SceneTree
## A new six-row source carried from glide into independent receiver recipes.
const SOURCE := [[0,1,2,0],[2,0,1,2],[1,2,0,1],[0,2,1,0],[2,1,0,2],[1,0,2,1]]
var checks: Array = []
var failures: Array = []

func _initialize() -> void:
    run.call_deferred()

func check(label: String, passed: bool) -> void:
    checks.append({"name": label, "passed": passed})
    if not passed: failures.append(label)
    print("[fresh transfer] ", "PASS " if passed else "FAIL ", label)

func select(s: Node3D, grid: Node3D, address: Vector2i) -> void:
    s.control.global_position = grid.to_global(Vector3(address.x * 0.32, 0.25, address.y * 0.32))
    s.choose(null)

func run() -> void:
    await process_frame
    var base := ""
    var report := ""
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--base="): base = arg.trim_prefix("--base=")
        if arg.begins_with("--report="): report = arg.trim_prefix("--report=")
    var glide = load(base + "/Symmetry_Seventeen/learner/printed/05_glide_reader.gd").new()
    glide.source = SOURCE.duplicate(true)
    glide.position = Vector3(9, 0, -4)
    glide.rotation.y = 0.73
    root.add_child(glide)
    glide.set_process(false)
    glide.cycle_rule()
    glide.cycle_rule()
    check("six rows compose into a three-row glide", glide.source_address(Vector2i(4,1)) == Vector2i(3,4) and glide.value_at(Vector2i(4,1)) == 2)
    check("negative address crosses into an odd block correctly", glide.source_address(Vector2i(-1,-1)) == Vector2i(0,2) and glide.value_at(Vector2i(-1,-1)) == 1)
    check("eight columns and six rows restore a source address", glide.source_address(Vector2i(4,1)) == glide.source_address(Vector2i(12,7)))
    var before: Array = []
    for address: Vector2i in glide.grid.cells: before.append(glide.value_at(address))
    select(glide, glide.grid, Vector2i(4,1))
    check("paint reaches the predicted source entry in a rotated host", glide.source[4][3] == 0 and glide.selected_address() == Vector2i(4,1))
    var changed: Array = []
    var i := 0
    for address: Vector2i in glide.grid.cells:
        if glide.value_at(address) != before[i]: changed.append(address)
        i += 1
    check("one edit changes exactly the two predicted visible copies", changed.size() == 2 and changed.has(Vector2i(4,1)) and changed.has(Vector2i(3,4)))
    glide.wall = true
    glide.width_index = 1
    glide.place_receiver()
    glide.control.global_position = glide.grid.to_global(Vector3(4 * 0.32, 0.25, 0.32))
    check("same address remains reachable after rotation and enlargement", glide.selected_address() == Vector2i(4,1) and glide.value_at(Vector2i(4,1)) == 0)

    var temple = load(base + "/Pattern_Temple/learner/printed/06_receivers.gd").new()
    # Explicit transfer in this rehearsal, not a claim of automatic inter-hall saving.
    temple.source = glide.source.duplicate(true)
    temple.position = Vector3(-7, 0, 6)
    temple.rotation.y = -0.51
    root.add_child(temple)
    temple.set_process(false)
    check("edited six-row source reaches both new receiver records", temple.value_at(0,Vector2i(4,1)) == 0 and temple.value_at(1,Vector2i(4,1)) == 0)
    temple.target = 1
    select(temple, temple.receivers[1], Vector2i(4,1))
    check("wall edit stays local", temple.value_at(1,Vector2i(4,1)) == 1 and temple.value_at(0,Vector2i(4,1)) == 0)
    temple.dress_all()
    check("copy from wall back to table transfers values", temple.value_at(0,Vector2i(4,1)) == 1)
    temple.target = 0
    select(temple, temple.receivers[0], Vector2i(4,1))
    check("later table edit leaves copied wall unchanged", temple.value_at(0,Vector2i(4,1)) == 2 and temple.value_at(1,Vector2i(4,1)) == 1)
    check("both receiving edits leave the earlier glide and initial template intact", glide.source[4][3] == 0 and temple.source[4][3] == 0 and SOURCE[4][3] == 2)
    temple.cycle_rule()
    check("changing table rule keeps records and wall rule", temple.recipes[0].rule == 0 and temple.recipes[1].rule == 2 and temple.recipes[0].source[4][3] == 2 and temple.value_at(0,Vector2i(4,1)) == 2)
    FileAccess.open(report, FileAccess.WRITE).store_string(JSON.stringify({"passed": failures.is_empty(), "checks": checks, "failures": failures, "scope": "New six-row, four-column source; explicit copy into next lesson; mathematical fixtures chosen before execution. Same assistant, not a blind student."}, "  "))
    glide.free()
    temple.free()
    quit(0 if failures.is_empty() else 1)
