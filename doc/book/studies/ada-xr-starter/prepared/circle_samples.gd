extends RefCounted
## Supplied sampler. Input: 3..256 divisions and a positive radius in metres.
## Output: distinct ordered samples in the local XY plane, around the origin.
## The closing point is not repeated. The trigonometry is a later lesson.

static func points_on_circle(count: int, radius: float) -> Array[Vector3]:
    assert(count >= 3 and count <= 256, "Use 3 to 256 divisions in this study.")
    assert(radius > 0.0, "Use a positive radius.")
    var result: Array[Vector3] = []
    for i in range(count):
        var angle := TAU * float(i) / float(count)
        result.append(Vector3(cos(angle), sin(angle), 0.0) * radius)
    return result
