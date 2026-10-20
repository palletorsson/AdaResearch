extends RefCounted
var pieces: Array[Dictionary] = []
var previous: Array[Dictionary] = []
var sources: Dictionary = {}
var ever: Dictionary = {}
var additions := 0
var participations := 0
var revisions := 0
var version := 1

func add(source: String, at: Vector3) -> void:
    pieces.append({"source":source,"original":at,"pose":at,"disputed":false,"revision":0})
    additions += 1
    if not sources.has(source): participations += 1
    sources[source] = true
    ever[source] = true

func dispute(index: int) -> bool:
    if index < 0 or index >= pieces.size(): return false
    pieces[index].disputed = true
    return true

func revise(index: int, at: Vector3) -> bool:
    if index < 0 or index >= pieces.size() or not pieces[index].disputed: return false
    pieces[index].pose = at
    pieces[index].revision += 1
    pieces[index]["revised_by"] = "VISITOR"
    revisions += 1
    return true

func next_version() -> void:
    previous = pieces.duplicate(true)
    pieces.clear()
    sources.clear()
    version += 1
