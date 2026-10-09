extends RefCounted
# The same two functions used by the hall's descent landscape.
static func cost(p: Vector2, valleys: bool) -> float:
    if valleys:
        return 0.08 * pow(p.x * p.x - 4.0, 2) + 0.25 * p.y * p.y + 0.15 * p.x
    return 0.25 * p.length_squared()

static func gradient(p: Vector2, valleys: bool) -> Vector2:
    var h := 0.03
    var x := Vector2(h, 0)
    var y := Vector2(0, h)
    return Vector2(cost(p + x, valleys) - cost(p - x, valleys),
        cost(p + y, valleys) - cost(p - y, valleys)) / (2.0 * h)

static func plot(p: Vector2, valleys: bool) -> Vector3:
    return Vector3(p.x * 0.45, 0.9 + 0.12 * cost(p, valleys), p.y * 0.45)
