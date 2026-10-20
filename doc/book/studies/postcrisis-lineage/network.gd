extends RefCounted
var points: Array[Vector3] = []
var edges: Array[Vector2i] = []
var active: Array[bool] = []
var samples: Array[Vector3] = []
var links := 3

func seed_samples(seed_value: int = 47) -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = seed_value
    samples.clear()
    for i in 24:
        var angle := rng.randf_range(0,TAU)
        var radius := rng.randf_range(0.32,0.8) if i>=2 else 0.04
        samples.append(Vector3(cos(angle)*radius,1.28,sin(angle)*radius*0.7))
    replay()

func replay() -> void:
    points.assign(samples.slice(0,2))
    active.assign([true,true])
    edges.clear()

func grow() -> bool:
    if points.size() >= samples.size() or false in active: return false
    points.append(samples[points.size()])
    active.append(true)
    rewire(links)
    return true

func rewire(count: int) -> void:
    links = clampi(count,1,3)
    edges.clear()
    for i in range(2,points.size()):
        var earlier: Array = range(i)
        earlier.sort_custom(func(a,b): return points[i].distance_squared_to(points[a]) < points[i].distance_squared_to(points[b]))
        for j in mini(links,i): edges.append(Vector2i(i,earlier[j]))

func neighbours(index: int) -> Array[int]:
    var result: Array[int] = []
    if index<0 or index>=active.size() or not active[index]: return result
    for edge in edges:
        var other := edge.y if edge.x==index else (edge.x if edge.y==index else -1)
        if other>=0 and active[other]: result.append(other)
    return result

func components() -> int:
    var seen: Dictionary = {}
    var total := 0
    for i in points.size():
        if not active[i] or seen.has(i): continue
        total += 1
        var todo: Array = [i]
        while not todo.is_empty():
            var current: int = todo.pop_back()
            if seen.has(current): continue
            seen[current] = true
            todo.append_array(neighbours(current))
    return total
