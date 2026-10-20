# Count the endings; keep the paths

**Learning elements**

- Recursive paths and a stopping condition
- Counting possible outcomes
- Pruning a branch and its descendants
- Equal-weight entropy, in nats
- Keeping outcome identities as well as totals

We are in the E Term hall of Endless Museum. Find the existing branching fan. ONE holds one path, OPEN exposes eighty-one endings, and PRUNE closes some branches before they reach their last level. In F Term we changed a probability while the possible bit values stayed 0 and 1. Here we change the inventory of possibilities itself. The familiar sphere controls how many continuations each stage offers.

## What we carry

Continue in `res://doc/book/studies/qfep-lineage/` in the prepared Ada project. Keep `point_body.gd`, `line_skin.gd` and `bench.gd` unchanged from [F Term](../QFEP_F_Term/tutorial.md). Their complete printed sources are in [Euclid](../Euclid_Parallel/tutorial.md#carried-files-complete) and [Russell](../Russell_Paradox/tutorial.md). The bench supplies its initialized readout and buttons; the point retains pickup and release. XRTools and `res://commons/interactables/push_button.tscn` are supplied museum dependencies. We add no new sphere class.

Arrays and loops return as a record of branches. The earlier cylinder renderer draws each relation. KEEP returns as a copy of evidence. F Term's seeded sample is not reused as a probability distribution here: this fan enumerates possibilities, not observed journeys.

## Give every ending a path

Create `possibilities.gd`. Four stages are fixed. At each stage, `branch` is 1, 2 or 3. A path such as `0121` means choice 0, then 1, then 2, then 1; it is an address, not the number one hundred and twenty-one. The empty string is the root before any choice.

<!-- student-code:possibilities.gd -->
```gdscript
extends RefCounted
const LEVELS := 4
var branch := 1
var pruned := false
var leaves: Array[String] = []
var closures: Array[String] = []
var edges: Array[Dictionary] = []
var kept: Dictionary = {}
var _prune_parent := 0

func _init() -> void:
    rebuild()

func set_branch(value: int) -> void:
    branch = clampi(value,1,3)
    pruned = false
    rebuild()

func prune() -> void:
    branch = 3
    pruned = true
    rebuild()

func rebuild() -> void:
    leaves.clear()
    closures.clear()
    edges.clear()
    _prune_parent = 0
    grow("")

func grow(prefix: String) -> void:
    if prefix.length() == LEVELS:
        leaves.append(prefix)
        return
    var cutting := pruned and prefix.length() == 2
    var survivor := _prune_parent % branch
    if cutting: _prune_parent += 1
    for i in branch:
        var child := prefix + str(i)
        var closed := cutting and i != survivor
        edges.append({"from":prefix,"to":child,"closed":closed})
        if closed:
            closures.append(child)
        else:
            grow(child)

func reading() -> Dictionary:
    var n := leaves.size()
    var uncut := int(pow(branch,LEVELS))
    return {"branch":branch,"pruned":pruned,"leaves":n,
        "uncut_leaves":uncut,"closures":closures.size(),"removed_leaves":uncut-n,
        "entropy_nats":log(float(n)),"equal_weights":true}

func keep() -> void:
    kept = reading()
    kept["paths"] = leaves.duplicate()
    kept["closed_paths"] = closures.duplicate()
```

`grow` calls itself with a longer prefix. This is recursion: the same operation works on the next stage. Its stopping condition is length four. Only then is a path appended to `leaves`. Every recursive call adds one digit, so this finite tree must reach that stopping condition. With no pruning, its endings number 1⁴ = 1, 2⁴ = 16 or 3⁴ = 81. The code counts the actual generated endings; the power is kept separately as the uncut comparison.

Every edge records its starting prefix, destination and whether it is closed. PRUNE always selects the three-way tree. At depth two there are nine parents. Each keeps one of its three next branches; the other two receive closure caps. `_prune_parent % branch` cycles the surviving child through 0, 1 and 2 as those parents are visited. This matches the installed fan's authored rule. We stop recursing along a closed edge. Each of the eighteen closures removes three last-stage endings, so fifty-four disappear and twenty-seven remain. A cap is not a completed ending.

`reading()` reports H = ln(N), in **nats**, under an explicit assumption: all N retained endings have probability 1/N. It follows from −Σ p ln(p). With unequal probabilities we would need the probabilities and that full sum. The count alone is insufficient. This H is not a speed, a rate of motion, a measure of how widely objects scatter, or a score for freedom. One possible ending gives ln(1) = 0. Branch is clamped to 1..3 and our pruning always leaves paths, so this model never evaluates ln(0).

`keep()` retains both the reading and independent copies of the path and closure arrays. Calling `clear()` during the next rebuild cannot empty those copies. This record lasts for this run, not on disk. Two different sets could share one count; a retained list lets us ask which endings a count refers to.

## Make the branching rule visible

Create `e_term_study.gd`. We keep the same bench, point and cylinder renderer, using thinner cylinders for this dense diagram. The drawing alone is rebuilt when the discrete branch setting changes or PRUNE/OPEN is pressed. The sphere, readout and buttons survive every rebuild.

<!-- student-code:e_term_study.gd -->
```gdscript
extends "bench.gd"
const Possibilities = preload("possibilities.gd")
const LOW := 1.18
const TRAVEL := 0.48
var model := Possibilities.new()
var tips: Array[MeshInstance3D] = []
var caps: Array[MeshInstance3D] = []

func _ready() -> void:
    start("COUNT THE ENDINGS / KEEP THE PATHS", ["ONE","TWO","OPEN","PRUNE","KEEP"],
        [choose.bind(1),choose.bind(2),choose.bind(3),prune,keep_reading])
    readout.font_size = 28
    redraw()

func _process(_delta: float) -> void:
    if point.held():
        var fraction := clampf((to_local(point.global_position).y-LOW)/TRAVEL,0.0,1.0)
        var value := 1 + int(round(fraction*2.0))
        if value != model.branch:
            model.set_branch(value)
            redraw()

func choose(value: int) -> void:
    if point.held(): return
    model.set_branch(value)
    redraw()

func prune() -> void:
    if point.held(): return
    model.prune()
    redraw()

func keep_reading() -> void:
    if point.held(): return
    model.keep()
    show_reading()

func position_for(path: String) -> Vector3:
    if path.is_empty(): return Vector3(0,1.05,0.4)
    var index := 0
    for digit in path:
        index = index*model.branch + int(digit)
    var slots := int(pow(model.branch,path.length()))
    return Vector3(-1.0+2.0*(index+0.5)/slots,1.05+path.length()*0.11,0.4-path.length()*0.25)

func redraw() -> void:
    tips.clear()
    caps.clear()
    clear_drawing()
    block(drawing,Vector3(-1.17,LOW+TRAVEL/2,0),Vector3(0.018,TRAVEL,0.018),Color("526071"))
    label(drawing,"1 / 2 / 3 branches",Vector3(-1.12,1.08,0.25),18)
    block(drawing,position_for(""),Vector3.ONE*0.045,Color("be95ed"))
    for edge in model.edges:
        var a := position_for(edge.from)
        var b := position_for(edge.to)
        var line := LineSkin.new()
        (line.mesh as CylinderMesh).top_radius = 0.003
        (line.mesh as CylinderMesh).bottom_radius = 0.003
        drawing.add_child(line)
        line.show_segment(a,b-a,a.distance_to(b))
        if edge.closed:
            caps.append(block(drawing,b,Vector3(0.035,0.022,0.022),Color("ffb74d")))
        elif edge.to.length() == model.LEVELS:
            tips.append(block(drawing,b,Vector3.ONE*0.015,Color("50dbef")))
    point_home = Vector3(-1.17,LOW+(model.branch-1)*TRAVEL/2,0.22)
    if not point.held(): point.position = point_home
    show_reading()

func show_reading() -> void:
    var r := model.reading()
    readout.text = "%d branches / 4 stages / equal leaf weights\n%d endings / H %.3f nats\n%d closures / %d endings removed" % [
        r.branch,r.leaves,r.entropy_nats,r.closures,r.removed_leaves]
    if model.kept.is_empty():
        readout.text += "\nCyan = ending / amber = closed branch"
    else:
        readout.text += "\nKept %d endings / H %.3f nats" % [model.kept.leaves,model.kept.entropy_nats]
```

`position_for` reads the prefix as a base-`branch` address. For example, in the three-way tree, prefix `12` has index 1×3+2 = 5 among nine slots. Depth sets height and distance along the table. We always use slots from the full tree, including when pruning. A surviving ending therefore stays at the same position when its neighbours disappear. We do not spread the survivors out to conceal the gaps.

The root is violet, completed endings cyan and closure caps amber. A line receives the displacement `b-a` and its length separately, as in the earlier line lesson. Passing a normalized direction in place of that displacement would put its centre in the wrong place. These cylinders are visible relations, not physical constraints or colliders.

Hand height is measured in the bench's local frame. The same 0.48-metre travel now selects three settings: low = one continuation, middle = two, high = three. `round(fraction*2)` makes that discrete choice. A stationary hand does not continually rebuild the tree. Release the sphere before pressing buttons. PRUNE fixes the three-way tree; leaving the hand at the same high setting does not silently undo the cut. Press OPEN, or move to a different branch setting, to change it.

The working copy uses ONE, TWO and OPEN for repeatable manual comparisons, plus PRUNE and KEEP. The installed fan also has CYCLE; its animation is useful to watch, but is not needed in this small reconstruction.

## Build and investigate in the museum

Open `res://doc/book/studies/qfep-lineage/e_term.tscn` and press F6. The supplied `e_term_museum.gd` adapter loads the actual E hall and mounts this working copy in a checked bay. The museum supplies the player, lighting, original fan and button interaction. The scene and adapter are beside the lesson files. These are examples inside the prepared museum project, not standalone code for a project without those dependencies.

1. Press ONE. Follow its four edges and predict H before reading it. There is one ending, even though it takes four choices to reach it.
2. Use the sphere, without TWO, to select two continuations. Predict the number of endings, then check the sixteen cyan tips. In bits, ln(16)/ln(2) = 4; in nats the same equal-weight model gives about 2.773. The paths did not change with the unit.
3. Press OPEN, then KEEP. Select two ending addresses sharing a prefix, such as `0100` and `0101`. Trace where they diverge. KEEP retains all eighty-one addresses, not just 81.
4. Press PRUNE. Predict how eighteen caps could remove fifty-four endings. Inspect the three completions below one closed prefix in the retained list. Compare current `model.leaves` with `model.kept.paths`; no retained survivor should be a newly invented path.
5. Press OPEN. The same authored addresses return. Then explain what these controls cannot do: they cannot add a fourth choice, assign unequal probabilities, or recover an alternative the model never represented.

For an independent prediction, choose a closed prefix in `model.closures` before looking at the check code. Write its three missing completions on paper or in the editor. Show why none can be a current leaf. This asks you to use a path address rather than repeat the displayed count.

## Assert the reconstruction

Create `possibility_checks.gd`. The assertions compare actual path sets as well as totals. The prune test verifies that each cap removes exactly three prior endings, while OPEN restores the original ordered list.

<!-- student-code:possibility_checks.gd -->
```gdscript
extends RefCounted
const Possibilities = preload("possibilities.gd")

func run() -> void:
    var model := Possibilities.new()
    assert(model.leaves == ["0000"])
    assert(model.reading().entropy_nats == 0.0)
    model.set_branch(2)
    assert(model.leaves.size() == 16)
    assert(is_equal_approx(model.reading().entropy_nats,log(16.0)))
    assert(is_equal_approx(model.reading().entropy_nats/log(2.0),4.0))
    model.set_branch(3)
    assert(model.leaves.size() == 81)
    assert(model.edges.size() == 120)
    assert(is_equal_approx(model.reading().entropy_nats,log(81.0)))
    var unique := {}
    for path in model.leaves:
        unique[path] = true
        assert(path.length() == 4 and path.is_valid_int())
    assert(unique.size() == 81)
    model.keep()
    var full := model.leaves.duplicate()
    var kept := model.kept.duplicate(true)
    model.prune()
    assert(model.leaves.size() == 27 and model.closures.size() == 18)
    assert(model.reading().removed_leaves == 54)
    assert(is_equal_approx(model.reading().entropy_nats,log(27.0)))
    assert(model.kept == kept and model.kept.paths == full)
    for path in model.leaves:
        assert(path in full and path[2] == path[1])
    for closure in model.closures:
        var removed_here := 0
        for path in full:
            if path.begins_with(closure):
                removed_here += 1
                assert(not path in model.leaves)
        assert(closure.length() == 3 and removed_here == 3)
    model.set_branch(3)
    assert(model.leaves == full and model.closures.is_empty())
    model.set_branch(0)
    assert(model.branch == 1 and model.leaves.size() == 1)
    model.set_branch(12)
    assert(model.branch == 3 and model.leaves.size() == 81)
```

Run `python tools/test_qfep_e_term.py` from the project root. The supplied harness freshly extracts these three complete printed files and the three named inherited files. Godot runs these assertions, then synthetic point pickup/motion/release and button presses under a translated and rotated parent. A failed assertion or engine script error fails the run. A separate native museum check compares both models and counts actual leaf and closure meshes in the installed fan.

These tests validate the executable reconstruction and its available operations. They do not establish a learner's interpretation or headset comfort. The lesson's entropy assumption is tested as an assumption in this model, not as a finding about the world outside it.

## Carry onward

Keep the outcome inventory, the probability assumption and the retained record distinct. Lambda's hall next changes the weight given to a term. A weight can change a result without changing the counted endings; a spatial recommendation can also encode the author's preference. We will keep those two mappings explicit.

**Short instruction:** Carry PointBody + Bench + LineSkin. Enumerate four-stage path IDs; hand selects b=1/2/3. OPEN=81. PRUNE closes 18 third-stage branches, removes 54 endings, leaves 27. Fixed slots preserve survivor positions. KEEP copies IDs and counts. H=ln(N) nats assumes equal leaf weights. Assert path sets, caps, restoration, local hand control. No movement-rate or freedom claim. Next: weight a term.
