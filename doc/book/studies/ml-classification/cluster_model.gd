extends RefCounted
var data := PackedVector2Array()
var centres := PackedVector2Array()
var groups := PackedInt32Array()
var k := 3
var dataset := 0
var next_assignment := true
var rounds := 0
var status := "ASSIGN NEXT"

func _init() -> void:
    set_data(0)

func set_data(choice: int) -> void:
    dataset = posmod(choice, 3)
    data.clear()
    match dataset:
        0:
            for centre: Vector2 in [Vector2(-0.8,-0.6), Vector2(0.8,-0.6), Vector2(0,0.7)]:
                for offset: Vector2 in [Vector2(-0.1,0),Vector2(0.1,0),Vector2(0,-0.15),Vector2(0,0.15)]:
                    data.append(centre+offset)
        1:
            for radius: float in [0.35, 0.85]:
                for i in 12:
                    var angle := TAU*i/12.0
                    data.append(Vector2(cos(angle),sin(angle))*radius)
        2:
            for z in 5:
                for x in 5: data.append(Vector2(x-2,z-2)*0.4)
    reset(k)

func reset(count: int) -> void:
    k = clampi(count, 2, 4)
    var start := PackedVector2Array([Vector2(-0.6,-0.3), Vector2(0,0.1), Vector2(0.6,0.3), Vector2(0,-0.8)])
    centres = start.slice(0,k)
    invalidate()

func invalidate() -> void:
    groups.clear()
    next_assignment = true
    rounds = 0
    status = "ASSIGN NEXT"

func nearest(p: Vector2) -> int:
    var winner := 0
    var best := p.distance_squared_to(centres[0])
    for j in range(1,centres.size()):
        var distance := p.distance_squared_to(centres[j])
        if distance < best: # Equal distances retain the lower index.
            best = distance
            winner = j
    return winner

func assign() -> bool:
    if not next_assignment: return false
    groups.clear()
    for p in data: groups.append(nearest(p))
    next_assignment = false
    status = "ASSIGNED / MEAN NEXT"
    return true

func move_means() -> bool:
    if next_assignment: return false
    for j in centres.size():
        var sum := Vector2.ZERO
        var count := 0
        for i in data.size():
            if groups[i] == j:
                sum += data[i]
                count += 1
        if count > 0: centres[j] = sum/count
    rounds += 1
    next_assignment = true
    status = "MEANS MOVED / ASSIGN NEXT"
    return true

func score() -> float:
    var total := 0.0
    for i in groups.size():
        total += data[i].distance_squared_to(centres[groups[i]])
    return total

func move_centre(index: int, where: Vector2) -> void:
    centres[index] = Vector2(clampf(where.x,-1,1),clampf(where.y,-1,1))
    invalidate()
