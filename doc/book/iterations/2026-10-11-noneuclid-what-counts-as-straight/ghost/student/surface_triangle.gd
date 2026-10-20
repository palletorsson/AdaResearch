extends "triangle_record.gd"
## The same coordinate pairs; two different interpretations of position and edge.
var spherical := false

func corner(p: Vector2) -> Vector3:
    if spherical: return Vector3(p.x, 1.0, p.y).normalized()
    return Vector3(p.x, 0.0, p.y)

func tangent(a: Vector3, b: Vector3) -> Vector3:
    if spherical: return (b - a * a.dot(b)).normalized()
    return (b - a).normalized()

func measure() -> Dictionary:
    var flat := super.measure()
    # In this upper-hemisphere chart, collinear pairs also map to one great circle.
    if not spherical or not flat.valid: return flat
    var angles: Array[float] = []
    var total := 0.0
    for i in range(3):
        var a := corner(points[i])
        var u := tangent(a, corner(points[(i + 1) % 3]))
        var v := tangent(a, corner(points[(i + 2) % 3]))
        var angle := rad_to_deg(atan2(u.cross(v).length(), u.dot(v)))
        angles.append(angle)
        total += angle
    return {"valid": true, "angles": angles, "sum": total}

func edge(index: int, pieces: int = 24) -> Array[Vector3]:
    var a := corner(points[index])
    var b := corner(points[(index + 1) % 3])
    var samples: Array[Vector3] = []
    pieces = maxi(1, pieces)
    for i in range(pieces + 1):
        var p := a.lerp(b, float(i) / pieces)
        samples.append(p.normalized() if spherical else p)
    return samples
