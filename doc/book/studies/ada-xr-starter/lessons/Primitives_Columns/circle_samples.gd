extends RefCounted
# Supplied circle sampler. Angles return in the Waves sequence.
static func make(sides: int, radius: float) -> Array[Vector3]:
    assert(sides >= 3 and radius > 0.0)
    var points: Array[Vector3] = []
    for side in range(sides):
        var angle := TAU * side / sides
        points.append(Vector3(cos(angle), 0, sin(angle)) * radius)
    return points
