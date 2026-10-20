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
